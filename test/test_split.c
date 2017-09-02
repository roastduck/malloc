#include "fixture.h"

int main()
{
    void *brk = (void*)((int)(sbrk(0) + 0xfff) & -0x1000);
    char *p1a = allocateAndFill(MIN_BLOCK - HEADER_SZ);
    char *p2 = allocateAndFill(2 * MIN_BLOCK - HEADER_SZ);
    char *p1b = allocateAndFill(MIN_BLOCK - HEADER_SZ);
    assert(p1a == brk + HEADER_SZ);
    assert(p1b == brk + MIN_BLOCK + HEADER_SZ);
    assert(p2 == brk + 2 * MIN_BLOCK + HEADER_SZ);

    return 0;
}

