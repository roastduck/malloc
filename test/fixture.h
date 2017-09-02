#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <assert.h>
#include "alloc.h"

#define HEADER_SZ 12
#define MIN_BLOCK 16

// In pure C, inline only work with -O2
// So fixture.h must only be included once

void *allocateAndFill(int size)
{
    void *ret = allocate(size);
    memset(ret, 0, size);
    return ret;
}

