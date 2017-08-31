# main.s

.include "linux.s"
.include "list_spec.s"

.section .data
brk:
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
    cmpl $32, %ecx
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
    movl %eax, %edx

    # Get a least 8 bytes for a header
    movl $SYS_BRK, %eax
    movl $ND_SENTINEL_SZ, %ebx
    int $LINUX_SYSCALL
    movl %eax, brk

    # Insert the full 2G space into list
    pushl $31
    pushl %edx
    call prepend_list
    addl $8, %esp

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

    movl PRB_ARG_LEVEL(%ebp), %ebx
    movl %ebx, %ecx
prep_find_avail_loop:
    pushl %ecx
    call pop_list
    popl %ecx
    testl %eax, %eax
    jnz end_prep_find_avail_loop
    incl %ecx
    jmp prep_find_avail_loop
end_prep_find_avail_loop:

prep_main_loop:
    cmpl %ecx, %ebx
    je end_prep_main_loop
    decl %ecx
    movl $16, %edx
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
.equ ALC_ARG_ADDR, 8
.equ ALC_ARG_SIZE, 12
allocate:
    pushl %ebp
    movl %esp, %ebp
    pushl %ebx

    # Initialize in the first run
    cmpl $0, brk
    jne initialized
    call init
initialized:

    # level = bsr(size - 1) + 1 - 4
    movl ALC_ARG_SIZE(%ebp), %ebx
    addl $ND_HEADER_SZ - 1, %ebx
    bsrl %ebx, %ebx
    subl 3, %ebx
    pushl %ebx
    call prepare_blk
    addl $4, %esp

    addl %eax, %ebx
    cmpl brk, %ebx
    jg all_brk_already_alloced
    movl %eax, %edx
    movl $SYS_BRK, %eax
    # %ebx already set
    int $LINUX_SYSCALL
    movl %eax, brk
    movl %edx, %eax
all_brk_already_alloced:

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
    movl $0, ND_NEXT(%ebx)
    movl $0, ND_PREV(%ebx)

dealloc_loop:
    # %eax = buddy = addr ^ (4 << level)
    movl ND_LEVEL(%ebx), %ecx
    movl $4, %eax
    shll %cl, %eax
    xorl %ebx, %eax 
    # x->next != 0 means available
    cmp $0, ND_NEXT(%eax)
    je end_dealloc_loop
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

    popl %ebx
    leave
    ret

