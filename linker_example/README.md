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

Examples are in src\_c [README.md](src_c/README.md)
