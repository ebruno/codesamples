## fizzbuzz ##
Fizzbuzz written in C.
Process the numbers 1 - 100.
Writes fizz when the number is modulo 3
Writes buzz when the number is modulo 5
Writes fizzbuzz when the number is both modulo 3 and 5
Otherwise just writes the number.

## Build fizzbuzz ##

      make

to clean up the directory

      make clean|dist-clean

## Run fuzzbuzz ##

      ./fuzzbuzz

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

## Prompt Assembly for Refactoring

The project includes tools to assemble LLM prompts for refactoring C code to ANSI C23 standards.
If ANSI C23 is not support in the environment automatically role back to C17/C18.

Copy the fizzbuzz.c_orig file to fizzbuzz.c to test the LLM refactoring functionality.

### Assemble Prompts
To generate text files containing the system and user prompts for each source file:
`make refactor`

### Run Prompt Engine
To print the assembled prompts directly to the console for verification:
`make run_prompt`

## Direct Script Usage

You can also run the prompt assembly tools directly:

### Shell/Zsh Scripts
These scripts generate `.txt` files for each provided source file.
- **Bash**: `./assemble_prompt.sh <file1> [file2 ...]`
- **Zsh**: `./assemble_prompt.zsh <file1> [file2 ...]`
- **Dry Run**: Use the `-n` flag to see what would happen without creating files.

### Python Prompt Engine
This tool assembles the prompts and prints the configuration, system, and user prompts directly to standard output.
- **Run**: `python3 prompt_engine.py <file1> [file2 ...]`
- **Dry Run**: Use the `-n` or `--dry-run` flag to see which files would be processed.

## Prompts Directory Structure

The `prompts/` directory contains the resources needed to guide an LLM in refactoring code:

- `configs/`: LLM configuration files and settings.
- `examples/`: Sample refactoring inputs and outputs to provide context and few-shot examples.
- `system/`: System personas and behavioral guidelines (e.g., the Senior C Developer role) that define the AI's expertise and constraints.
- `templates/`: Markdown templates for user prompts, including placeholders for source code substitution.
