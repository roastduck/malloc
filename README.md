# Malloc

伙伴系统（Buddy System）内存分配机制的x86-32 Linux实现

## 特性

- 内存申请和释放的复杂度均为O(log n)，其中n为内存总大小；
- brk系统调用内部是按页分配的，但它的返回值依然是不对齐的。本实现中手动将brk按4KB对齐，避免重复的系统调用；
- 已分裂的内存块在释放后可以合并，并且内部的内存块大小均为二的幂，避免过度碎片化；

## 算法

将内存块分为4B、8B、16B、……、2G等级别，大小均为二的幂，例如申请6K内存时实际分配为8K。将每个级别的空闲内存块组织成链表，以便在O(1)时间获取一个特定大小的空闲块、确认没有该大小的空闲块，或是将一个新产生的空闲内存块加入链表。

每次申请内存时，直接从列表中获取相应大小的内存块，标记为已占用（从链表中摘取）并返回。若当前没有某个特定大小的内存块，就从较大的块中分裂而得，每次申请最多分裂O(log n)次，故申请时间为O(log n)。若当前最大的块也不能满足要求，就移动brk创建更大（两倍大）的块，若把此算法想象成树形结构，就是向上移动树根。移动brk时是按4K对齐的，避免冗余系统调用。

释放内存时，将该内存块标记为可用（插入回链表），并检查被释放的块能否和它的“伙伴”合并为原来的大块，每次释放最多合并O(log n)次，故释放时间也为O(log n)。

## 使用

函数接口请见`include/alloc.h`中的C接口。

动态链接库(.so)已编译置于`lib/`下，若要手动编译该库，可执行`cd src && make`。链接`lib/alloc.so`即可使用，注意此为动态链接库，执行时可能需要设置`LD_LIBRARY_PATH`。具体编译命令可参考测试代码。

## 测试

已通过的若干测试位于`test/`中。可执行`cd test && make`编译所有测试并通过`./run_all_test.sh`执行所有测试。具体测试如下：

- `test_allocate1byte`：分配1字节；
- `test_reallocate1byte`：分配1字节并释放改字节后，原来的空间可以被回收使用；
- `test_largerthan1page`：可以正确处理申请内存大于4KB的情况；
- `test_split`：大块的内存可以被分割成小块内存使用（此测试不是很直观，但所有的内存块都是从最大的块中分割而得的）；
- `test_merge`：曾被分割的内存块被释放后还可以作为整体使用；
- `test_lotsofoperations`：测试连续多个随机操作，并验证数据完整性。

注意：为了避免测试中的冗余代码，各测试是通过`fixture.h`间接调用本库函数的，请注意查看。

## 代码结构

代码位于`src/`中，大多数函数位于`main.s`，`list.s`处理链表相关操作，`list_spec.s`声明了链表所需数据类型中的偏移量和元信息。具体函数作用请参见代码中注释。