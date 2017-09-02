#include "fixture.h"

int main()
{
    void *brk = (void*)((int)(sbrk(0) + 0xfff) & -0x1000);
    char *p = allocate(1);
    deallocate(p);
    p = allocate(1);
    *p = 'a';
    assert(p == brk + HEADER_SZ);
    return 0;
}

