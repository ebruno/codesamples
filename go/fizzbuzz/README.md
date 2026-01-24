# fizzbuzz #
Fizzbuzz written in go.
Process the numbers 1 - 100.
Writes fizz when the number is modulo 3
Writes buzz when the number is modulo 5
Writes fizzbuzz when the number is both modulo 3 and 5
Otherwise just writes the number.

## Tested environments ##

 * Fedora 43 bazel 9
 * MacOS 26 bazel 8

## Build fizzbuzz  ##

Either make or bazel can be used to build the sample application.

### Using make ###

	  make

to clean up the directory

	  make clean|dist-clean

### Using bazel ###

	. ./setup_bazel_env.sh
	bazel build //:fizzbuzz

to clean up the directory:

    ./clean_bazel.sh

### Run fuzzbuzz build by make ###

	  ./fuzzbuzz

### Run fuzzbuzz build by bazel ###

	bazel run //:fizzbuzz

## Sample Output

	  1
	  2
	  fizz
	  4
	  buzz
	  fizz
	  7
	  8
	  fizz
	  buzz
	  11
	  fizz
	  13
	  14
	  fizzbuzz
	  16
	  17
	  fizz
	  19
	  buzz
	  fizz
	  22
	  23
	  fizz
	  buzz
	  26
	  fizz
	  28
	  29
	  fizzbuzz
	  31
	  32
	  fizz
	  34
	  buzz
	  fizz
	  37
	  38
	  fizz
	  buzz
	  41
	  fizz
	  43
	  44
	  fizzbuzz
	  46
	  47
	  fizz
	  49
	  buzz
	  fizz
	  52
	  53
	  fizz
	  buzz
	  56
	  fizz
	  58
	  59
	  fizzbuzz
	  61
	  62
	  fizz
	  64
	  buzz
	  fizz
	  67
	  68
	  fizz
	  buzz
	  71
	  fizz
	  73
	  74
	  fizzbuzz
	  76
	  77
	  fizz
	  79
	  buzz
	  fizz
	  82
	  83
	  fizz
	  buzz
	  86
	  fizz
	  88
	  89
	  fizzbuzz
	  91
	  92
	  fizz
	  94
	  buzz
	  fizz
	  97
	  98
	  fizz
	  buzz
