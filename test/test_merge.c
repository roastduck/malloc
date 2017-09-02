#include "fixture.h"

int main()
{
    void *brk = (void*)((int)(sbrk(0) + 0xfff) & -0x1000);
    char *p1a = allocateAndFill(MIN_BLOCK - HEADER_SZ);
    char *p1b = allocateAndFill(MIN_BLOCK - HEADER_SZ);
    assert(p1a == brk + HEADER_SZ);
    assert(p1b == brk + 2 * MIN_BLOCK + HEADER_SZ);
    // This is a special case: When move_root triggered, find_avail_loop is already looking for doubled size
    deallocate(p1a);
    deallocate(p1b);
    char *p2 = allocateAndFill(2 * MIN_BLOCK - HEADER_SZ);
    assert(p2 == brk + HEADER_SZ);

    return 0;
}

