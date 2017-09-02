ASM = main.s list.s
OBJ = $(ASM:%.s=../build/%.o)
LIB = ../lib/liballoc.so

../build/%.o : %.s
	as --32 $^ -o $@

$(LIB) : $(OBJ)
	ld --shared $^ -o $@ -m elf_i386

