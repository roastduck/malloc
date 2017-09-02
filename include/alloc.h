#ifndef MALLOC_H_
#define MALLOC_H_

#ifdef __cplusplus
extern "C" {
#endif

/** Allocate a new memory block
 *  @param size : Bytes number of the block
 *  @return : Address
 */
extern void *allocate(int size);

/** Deallocate a memory block
 *  @param addr : Address
 */
extern void deallocate(void *addr);

#ifdef __cplusplus
}
#endif

#endif // MALLOC_H_

