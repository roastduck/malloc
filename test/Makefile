SRC = $(wildcard *.c)
EXE = $(SRC:%.c=%_exe)

all : $(EXE)

%_exe : %.c ../include/alloc.h ../lib/liballoc.so fixture.h
	gcc $< -o $@ -m32 -I ../include -L ../lib -lalloc -ggdb
