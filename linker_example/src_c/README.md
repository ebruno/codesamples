# Demonstration of function sections #

Modern compilers GCC/Clang support compiling source files with multiple functions
with unique sections with in the object file, verses a single section with is the default.
This allows tighter/smaller binaries will linking applications statically.

For GCC and Clang the compiler flag is

  * -ffunction-sections
  * -fdata-sections

These should be used together to get the smallest binary.

For GCC and Clang the linker flag is

	* --gc-sections (on Linux/most systems)
	* --print-gc-sections (this will print what is removed)


The main goal of using this option (usually in combination with
the linker flag --gc-sections) is to enable "dead code elimination".
The linker can then identify and remove any function sections that
are not referenced by the program, resulting in a smaller final executable file.

Not including functions that are not used by application also improves security.


## Building the samples ##

In order to build the samples use the following commands

  * make dist-clean all;

  or

  * make -f Makefile_sections dist-clean all;

  or

  * make -f Makefile_dll dist-clean all;

## Sample build not using function sections ##

	make -f Makefile dist-clean all
	make[1]: Entering directory 'codesamples/linker_example/src_c'
	make[1]: Leaving directory 'codesamples/linker_example/src_c'
	make[1]: Entering directory 'codesamples/linker_example/src_c'
	make[1]: Leaving directory 'codesamples/linker_example/src_c'
	gcc  -c lremove_char.c -o lremove_char.o
	gcc  -c remove_char.c -o remove_char.o
	gcc  -c rremove_char.c -o rremove_char.o
	gcc  -c all_in_one.c -o all_in_one.o
	Note when the functions are compiled separately
	the binary is smaller.
	-rwxrwxr-x 1 ebruno ebruno 16288 Feb 26 19:32 demo_allinone
	-rwxrwxr-x 1 ebruno ebruno 16144 Feb 26 19:32 demo_separate


## Sample build using function sections ##

	make -f Makefile_sections dist-clean all
	make[1]: Entering directory 'codesamples/linker_example/src_c'
	make[1]: Leaving directory 'codesamples/linker_example/src_c'
	make[1]: Entering directory 'codesamples/linker_example/src_c'
	make[1]: Leaving directory 'codesamples/linker_example/src_c'
	gcc -ffunction-sections -fdata-sections -c lremove_char.c -o lremove_char.o
	gcc -ffunction-sections -fdata-sections -c remove_char.c -o remove_char.o
	gcc -ffunction-sections -fdata-sections -c rremove_char.c -o rremove_char.o
	gcc -ffunction-sections -fdata-sections -c all_in_one.c -o all_in_one.o
	gcc -o demo_separate main.o -Lcodesamples/linker_example/src_c -lswtrstrlib -Wl,--gc-sections,--print-gc-sections,-Map=demo_separate.map
	/usr/bin/ld: removing unused section '.rodata.cst4' in file '/usr/lib/gcc/x86_64-linux-gnu/14/../../../x86_64-linux-gnu/Scrt1.o'
	/usr/bin/ld: removing unused section '.data' in file '/usr/lib/gcc/x86_64-linux-gnu/14/../../../x86_64-linux-gnu/Scrt1.o'
	gcc -o demo_allinone main.o -Lcodesamples/linker_example/src_c -lall_in_one -Wl,--gc-sections,--print-gc-sections,-Map=demo_allinone.map
	/usr/bin/ld: removing unused section '.rodata.cst4' in file '/usr/lib/gcc/x86_64-linux-gnu/14/../../../x86_64-linux-gnu/Scrt1.o'
	/usr/bin/ld: removing unused section '.data' in file '/usr/lib/gcc/x86_64-linux-gnu/14/../../../x86_64-linux-gnu/Scrt1.o'
	/usr/bin/ld: removing unused section '.text.swtrstrlib_strip_char' in file 'codesamples/linker_example/src_c/liball_in_one.a(all_in_one.o)'
	/usr/bin/ld: removing unused section '.text.swtrstrlib_right_remove_char' in file 'codesamples/linker_example/src_c/liball_in_one.a(all_in_one.o)'
	Note when the functions are compiled separately or in single source unit
	the binary is the same size.
	-rwxrwxr-x 1 ebruno ebruno 16032 Feb 26 16:10 demo_allinone
	-rwxrwxr-x 1 ebruno ebruno 16032 Feb 26 16:10 demo_separate

### Sample build of dll/shared library ###

	make -f Makefile_dll dist-clean all
	make[1]: Entering directory 'codesamples/linker_example/src_c'
	make[1]: Leaving directory 'codesamples/linker_example/src_c'
	make[1]: Entering directory 'codesamples/linker_example/src_c'
	make[1]: Leaving directory 'codesamples/linker_example/src_c'
	gcc  -fPIC  -c lremove_char.c -o lremove_char.o
	gcc  -fPIC  -c remove_char.c -o remove_char.o
	gcc  -fPIC  -c rremove_char.c -o rremove_char.o
	gcc  -fPIC  -c all_in_one.c -o all_in_one.o
	Note with a dll/shared library there is no size difference.
	-rwxrwxr-x 1 ebruno ebruno 16112 Feb 26 19:33 demo_allinone_dll
	-rwxrwxr-x 1 ebruno ebruno 16112 Feb 26 19:33 demo_separate_dll


## Looking at the map files ##

### Not using function sections ###

When compiling the functions separately only the lremove_char function is pulled in.

	codesamples/linker_example/src_c/libswtrstrlib.a(lremove_char.o)
							  main.o (swtrstrlib_left_remove_char)

	.text          0x000000000000120b       0xad codesamples/linker_example/src_c/libswtrstrlib.a(lremove_char.o)
				   0x000000000000120b                swtrstrlib_left_remove_char

	.eh_frame      0x0000000000002118       0x20 codesamples/linker_example/src_c/libswtrstrlib.a(lremove_char.o)
											0x38 (size before relaxing)
	.note.GNU-stack
				   0x000000000000213c        0x0 codesamples/linker_example/src_c/libswtrstrlib.a(lremove_char.o)

	.data          0x0000000000004028        0x0 codesamples/linker_example/src_c/libswtrstrlib.a(lremove_char.o)

	.bss           0x0000000000004029        0x0 codesamples/linker_example/src_c/libswtrstrlib.a(lremove_char.o)

	.comment       0x000000000000001f       0x20 codesamples/linker_example/src_c/libswtrstrlib.a(lremove_char.o)

When compiling the functions together as a single source module all the functions in the object are pulled in..

	codesamples/linker_example/src_c/liball_in_one.a(all_in_one.o)
							  main.o (swtrstrlib_left_remove_char)
	.text          0x000000000000121b      0x1c3 codesamples/linker_example/src_c/liball_in_one.a(all_in_one.o)
				   0x000000000000121b                swtrstrlib_left_remove_char
				   0x00000000000012c8                swtrstrlib_strip_char
				   0x000000000000135f                swtrstrlib_right_remove_char



### Using function sections ###

When compiling the functions separately only the lremove_char function is pulled in.

	codesamples/linker_example/src_c/libswtrstrlib.a(lremove_char.o)
							  main.o (swtrstrlib_left_remove_char)


	.text          0x0000000000000000        0x0 codesamples/linker_example/src_c/libswtrstrlib.a(lremove_char.o)
	.data          0x0000000000000000        0x0 codesamples/linker_example/src_c/libswtrstrlib.a(lremove_char.o)
	.bss           0x0000000000000000        0x0 codesamples/linker_example/src_c/libswtrstrlib.a(lremove_char.o)

	.text.swtrstrlib_left_remove_char
				   0x000000000000120b       0xad codesamples/linker_example/src_c/libswtrstrlib.a(lremove_char.o)
				   0x000000000000120b                swtrstrlib_left_remove_char
	.eh_frame      0x0000000000002110       0x20 codesamples/linker_example/src_c/libswtrstrlib.a(lremove_char.o)
											0x38 (size before relaxing)

When compiling the functions together as a single source module again only the lremove_function is pulled in.

	codesamples/linker_example/src_c/liball_in_one.a(all_in_one.o)
							  main.o (swtrstrlib_left_remove_char)

	Discarded input sections

	.text.swtrstrlib_strip_char
					0x0000000000000000       0x97 codesamples/linker_example/src_c/liball_in_one.a(all_in_one.o)
	.text.swtrstrlib_right_remove_char
					0x0000000000000000       0x7f codesamples/linker_example/src_c/liball_in_one.a(all_in_one.o)

	 Linker script and memory map

	 .text.swtrstrlib_left_remove_char
					0x000000000000120b       0xad codesamples/linker_example/src_c/liball_in_one.a(all_in_one.o)
					0x000000000000120b                swtrstrlib_left_remove_char
