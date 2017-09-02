#include <assert.h>
#include <stdio.h>
#include <unistd.h>
#include "alloc.h"

#define HEADER_SZ 12

int main()
{
    void *brk = (void*)((int)(sbrk(0) + 0xfff) & -0x1000);
    char *p = allocate(1);
    *p = 'a';
    assert(p == brk + HEADER_SZ);
    return 0;
}

