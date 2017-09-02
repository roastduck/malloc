# list.s

.include "list_spec.s"

.section .bss
    # Each block of the i-th list has 2 ^ (i + 4) bytes (16B * 2^i)
    # Each item of this array is a header sentinel (8 bytes)
    # Largest i = 31 (2GB)
    .comm available, (32 - 4) * ND_SENTINEL_SZ

    # And we should have trailer sentinels
    .comm trailer, (32 - 4) * ND_SENTINEL_SZ

.section .text
.globl pick_node
.type pick_node, @function
# Pick a node from linked list
.equ PCK_ARG_NODE, 8
pick_node:
    pushl %ebp
    movl %esp, %ebp

    movl PCK_ARG_NODE(%ebp), %eax
    movl ND_PREV(%eax), %ecx
    movl ND_NEXT(%eax), %edx
    movl $0, ND_PREV(%eax)
    movl $0, ND_NEXT(%eax)
    movl %edx, ND_NEXT(%ecx)
    movl %ecx, ND_PREV(%edx)

    leave
    ret

.type insert_node, @function
# Insert a node after a specific node
.equ INS_ARG_NODE, 8
.equ INS_ARG_AFTER, 12
insert_node:
    pushl %ebp
    movl %esp, %ebp

    movl INS_ARG_NODE(%ebp), %eax
    movl INS_ARG_AFTER(%ebp), %ecx
    movl ND_NEXT(%ecx), %edx
    movl %eax, ND_NEXT(%ecx)
    movl %eax, ND_PREV(%edx)
    movl %ecx, ND_PREV(%eax)
    movl %edx, ND_NEXT(%eax)

    leave
    ret

.globl pop_list
.type pop_list, @function
# Pick and return the first item from a list of specific size level
# If the list is empty, return 0
.equ POP_ARG_LEVEL, 8
pop_list:
    pushl %ebp
    movl %esp, %ebp

    movl POP_ARG_LEVEL(%ebp), %ecx
    movl ND_NEXT + available(, %ecx, ND_SENTINEL_SZ), %ecx

    # If this is already trailer
    xorl %eax, %eax
    cmpl $0, ND_NEXT(%ecx)
    je pop_list_ret

    pushl %ecx
    call pick_node
    popl %eax

pop_list_ret:
    leave
    ret

.globl prepend_list
.type prepend_list, @function
# Prepend an item to a list of specific size level
# This function has no need to own a stack frame
# Just modify the parameter and jump to insert_node
.equ PPD_ARG_NODE, 8
.equ PPD_ARG_LEVEL, 12
prepend_list:
    movl PPD_ARG_LEVEL - 4(%esp), %eax
    movl PPD_ARG_NODE - 4(%esp), %ecx
    movl %eax, ND_LEVEL(%ecx)
    leal available(, %eax, ND_SENTINEL_SZ), %eax
    movl %eax, PPD_ARG_LEVEL - 4(%esp)
    jmp insert_node

