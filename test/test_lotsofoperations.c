#include "fixture.h"

void *ptr[10];
int size[10];

int main()
{
    int id;
    id = 0, ptr[id] = allocateAndFill(size[id] = 534, id);
    id = 1, ptr[id] = allocateAndFill(size[id] = 18315, id);
    id = 2, ptr[id] = allocateAndFill(size[id] = 4, id);
    id = 3, ptr[id] = allocateAndFill(size[id] = 648, id);
    id = 0, deallocateAndCheck(ptr[id], size[id], id);
    id = 1, deallocateAndCheck(ptr[id], size[id], id);
    id = 4, ptr[id] = allocateAndFill(size[id] = 1, id);
    id = 4, deallocateAndCheck(ptr[id], size[id], id);
    id = 2, deallocateAndCheck(ptr[id], size[id], id);
    id = 5, ptr[id] = allocateAndFill(size[id] = 978945, id);
    id = 6, ptr[id] = allocateAndFill(size[id] = 3153101, id);
    id = 6, deallocateAndCheck(ptr[id], size[id], id);
    id = 7, ptr[id] = allocateAndFill(size[id] = 65, id);
    id = 3, deallocateAndCheck(ptr[id], size[id], id);
    id = 5, deallocateAndCheck(ptr[id], size[id], id);
    id = 8, ptr[id] = allocateAndFill(size[id] = 594864, id);
    id = 9, ptr[id] = allocateAndFill(size[id] = 4864, id);
    id = 7, deallocateAndCheck(ptr[id], size[id], id);
    id = 9, deallocateAndCheck(ptr[id], size[id], id);
    id = 8, deallocateAndCheck(ptr[id], size[id], id);
    return 0;
}

