# Sample of using pointers and malloc.
Reads HTTP 1.1 headers from stdin and just retains the Set-Cookie keys.

Compile using 

    make

make test01 and make test02 run a set HTTP 1.1 headers though stdin.

This has been tested on MacOS X, CentOS 7.4 and Ubuntu 18.04

## Prompt Assembly for Refactoring

This module includes Makefile rules to assemble LLM prompts for refactoring 
the source code to ANSI C23 standards with automatic fallback 
to C17/C18 if C23 is not supported by the environment.
These rules utilize scripts located in the parent directory.

### Assemble Prompts
To generate text files containing the system and user prompts for all source files in this module:
`make refactor`

### Run Prompt Engine
To print the assembled prompts directly to the console for verification:
`make run_prompt`

## Direct Script Usage

You can also run the prompt assembly tools directly from this directory by referencing the scripts in the parent folder:

### Shell/Zsh Scripts
These scripts generate `.txt` files for the specified source files.
- **Bash**: `../assemble_prompt.sh <file1> [file2 ...]`
- **Zsh**: `../assemble_prompt.zsh <file1> [file2 ...]`
- **Dry Run**: Use the `-n` flag to see what would happen without creating files.

### Python Prompt Engine
This tool assembles the prompts and prints the configuration, system, and user prompts directly to standard output.
- **Run**: `python3 ../prompt_engine.py <file1> [file2 ...]`
- **Dry Run**: Use the `-n` or `--dry-run` flag to see which files would be processed.
