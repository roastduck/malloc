#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <assert.h>
#include "alloc.h"

#define HEADER_SZ 12
#define MIN_BLOCK 16

// In pure C, inline only work with -O2
// So fixture.h must only be included once

void *allocateAndFill(int size, char data)
{
    void *ret = allocate(size);
    memset(ret, data, size);
    return ret;
}

void deallocateAndCheck(void *p, int size, char data)
{
    for (int i = 0; i < size; i++)
        assert(*((char*)p + i) == data);
    deallocate(p);
}

