# main.s

.include "linux.s"
.include "list_spec.s"

.section .data
base:
    .long 0
# DO NOT name it to `brk`
heaptop:
    .long 0
root_level:
    .long 0

.section .text
.type init, @function
init:
    pushl %ebp
    movl %esp, %ebp
    pushl %ebx

    # Initialize linked lists
    movl $available, %eax
    movl $trailer, %ebx
    xorl %ecx, %ecx
init_list_loop:
    movl $0, ND_PREV(%eax)
    movl %ebx, ND_NEXT(%eax)
    movl %eax, ND_PREV(%ebx)
    movl $0, ND_NEXT(%ebx)
    cmpl $31 - 4, %ecx
    je end_init_list_loop
    addl $ND_SENTINEL_SZ, %eax
    addl $ND_SENTINEL_SZ, %ebx
    incl %ecx
    jmp init_list_loop
end_init_list_loop:

    # Get brk value
    movl $SYS_BRK, %eax
    xorl %ebx, %ebx
    int $LINUX_SYSCALL
    # Brk align with 4K internally, but that value doesn't return
    addl $0xfff, %eax
    andl $-0x1000, %eax
    movl %eax, base

    # Insert unit block to start with
    movl $SYS_BRK, %eax
    movl $ND_MIN_SIZE, %ebx
    addl base, %ebx
    addl $0xfff, %ebx
    andl $-0x1000, %ebx
    int $LINUX_SYSCALL
    movl %eax, heaptop
    pushl $0
    pushl base
    call prepend_list
    addl $8, %esp

    popl %ebx
    leave
    ret

.type move_root, @function
# Move up root to ensure `root_level` >= level required
.equ MVR_ARG_LEVEL, 8
move_root:
    pushl %ebp
    movl %esp, %ebp
    pushl %ebx

    # Move brk to be 2 * required
    movl MVR_ARG_LEVEL(%ebp), %ecx
    movl $ND_MIN_SIZE * 2, %ebx
    shll %cl, %ebx
    addl base, %ebx
    cmpl %ebx, heaptop
    jge mvr_already_enough
    movl $SYS_BRK, %eax
    addl $0xfff, %ebx
    andl $-0x1000, %ebx
    int $LINUX_SYSCALL
    movl %eax, heaptop
mvr_already_enough:

    # Create new blocks
    movl root_level, %ecx
    movl $ND_MIN_SIZE, %ebx
    shll %cl, %ebx
mvr_newblk_loop:
    testl $-1, base
    jz mvr_not_merge
    movl base, %edx
    cmpl %ecx, ND_LEVEL(%edx)
    jne mvr_not_merge
    # Merge
    # Pick from original list
    pushl %ecx
    pushl base
    call pick_node
    addl $4, %esp
    popl %ecx
    # Add to new list (iterator increased)
    incl %ecx
    shll $1, %ebx
    pushl %ecx
    pushl base
    call prepend_list
    add $4, %esp
    popl %ecx
mvr_not_merge:
    # Not merge
    # Add to new list
    movl base, %edx
    addl %ebx, %edx
    pushl %ecx
    pushl %edx
    call prepend_list
    addl $4, %esp
    popl %ecx
    # Increase iterator
    incl %ecx
    shll $1, %ebx
mvr_create_next_loop:
    cmpl %ecx, MVR_ARG_LEVEL(%ebp)
    # %ecx <= arg, not <
    jne mvr_newblk_loop

    popl %ebx
    leave
    ret

.type prepare_blk, @function
# Prepare a block with a specific size level
.equ PRB_ARG_LEVEL, 8
prepare_blk:
    pushl %ebp
    movl %esp, %ebp
    pushl %ebx

    # Find a block to split
    movl PRB_ARG_LEVEL(%ebp), %ebx
    movl %ebx, %ecx
prep_find_avail_loop:
    cmpl %ecx, root_level
    jge prep_not_moving_root
    pushl %ecx
    call move_root
    popl %ecx
prep_not_moving_root:
    pushl %ecx
    call pop_list
    popl %ecx
    testl %eax, %eax
    jnz end_prep_find_avail_loop
    incl %ecx
    jmp prep_find_avail_loop
end_prep_find_avail_loop:

    # Split down
prep_main_loop:
    cmpl %ecx, %ebx
    je end_prep_main_loop
    decl %ecx
    movl $ND_MIN_SIZE, %edx
    shll %cl, %edx
    addl %eax, %edx
    movl %ecx, ND_LEVEL(%edx)
    pushl %eax
    # Param #2
    pushl %ecx
    # Param #1
    pushl %edx
    call prepend_list
    addl $4, %esp
    popl %ecx
    popl %eax
    jmp prep_main_loop
end_prep_main_loop:
    movl %ebx, ND_LEVEL(%eax)

    popl %ebx
    leave
    ret

.globl allocate
.type allocate, @function
.equ ALC_ARG_SIZE, 8
allocate:
    pushl %ebp
    movl %esp, %ebp
    pushl %ebx

    # Initialize in the first run
    cmpl $0, base
    jne initialized
    call init
initialized:

    # level = bsr(size - 1) + 1 - ND_LEVEL_OFFSET
    movl ALC_ARG_SIZE(%ebp), %ebx
    addl $ND_HEADER_SZ - 1, %ebx
    bsrl %ebx, %ebx
    subl $ND_LEVEL_OFFSET - 1, %ebx
    pushl %ebx
    call prepare_blk
    addl $4, %esp

    addl $ND_HEADER_SZ, %eax

    popl %ebx
    leave
    ret

.globl deallocate
.type deallocate, @function
.equ DAL_ARG_ADDR, 8
deallocate:
    pushl %ebp
    movl %esp, %ebp
    pushl %ebx

    movl DAL_ARG_ADDR(%ebp), %ebx
    subl $ND_HEADER_SZ, %ebx

dealloc_loop:
    # %eax = buddy = ((addr - base) ^ (16 << level)) + base
    movl ND_LEVEL(%ebx), %ecx
    movl $ND_MIN_SIZE, %eax
    shll %cl, %eax
    movl %ebx, %edx
    subl base, %edx
    xorl %edx, %eax
    addl base, %eax
    # x->next == 0 means not available
    cmp $0, ND_NEXT(%eax)
    je end_dealloc_loop
    # x->level != level means not mergeable
    cmp ND_LEVEL(%eax), %ecx
    jne end_dealloc_loop
    # Delete buddy with higher address and set %ebx to be with lower address
    movl %eax, %edx
    orl %ebx, %edx
    andl %eax, %ebx
    pushl %edx
    call pick_node
    addl $4, %esp
    incl ND_LEVEL(%ebx)
    jmp dealloc_loop
end_dealloc_loop:

    pushl ND_LEVEL(%ebx)
    pushl %ebx
    call prepend_list
    addl $8, %esp

    popl %ebx
    leave
    ret

