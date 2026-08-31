## FizzBuzz

FizzBuzz written in C++20.
Process the numbers 1 - 100.
Writes fizz when the number is modulo 3
Writes buzz when the number is modulo 5
Writes fizzbuzz when the number is both modulo 3 and 5
Otherwise just writes the number.

## Build

```bash
make
```

To clean up the directory:

```bash
make clean
make dist-clean
```

## Run

```bash
./fizzbuzz
```

## Sample Output

```text
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
  ...
  97
  98
  fizz
  buzz
```

## Using the AI Prompts

Copy the file fizzbuzz.cpp.orig to fizzbuzz.cpp and then use the AI tools to see it update the source code.
The LLM used was Gemma 4 31B QAT

## Assemble Prompts

The `assemble_prompt.sh` and `assemble_prompt.zsh` scripts are used to create prompts for LLMs to refactor C++ files. They combine a system prompt and a template with the content of the specified files.

Usage:
      ./assemble_prompt.sh [-n] [-h] <file1> [file2 ...]
      ./assemble_prompt.zsh [-n] [-h] <file1> [file2 ...]

Options:
- `-h`: Display help message.
- `-n`: Dry run (explains what would be done without creating files).

Example:
      ./assemble_prompt.sh fizzbuzz.cpp

## Prompt Engine

The `prompt_engine.py` script is a Python-based version of the prompt assembler. It not only combines the system and template prompts but also parses YAML configuration frontmatter from the template and prints the assembled prompt directly to the console.

Usage:
      python3 prompt_engine.py <file1> [file2 ...]

Options:
- `-n`, `--dry-run`: Dry run (explains what would be done without assembling).

Example:
      python3 prompt_engine.py fizzbuzz.cpp

## Prompts Directory

The `c++/prompts/` directory is a structured library of prompts designed to standardize how LLMs are used for C++ development tasks, specifically refactoring.

### Directory Structure and Contents:

- **`system/`**: Contains "Persona" prompts that define the role the LLM should assume.
    - `senior-cpp-dev.md`: Defines a persona as a world-class Senior C++ Software Engineer expert in C++20/23, high-performance systems, and the C++ Core Guidelines. It emphasizes efficiency, modernity (concepts, ranges, `std::format`), and safety.

- **`templates/`**: Contains reusable prompt templates with placeholders.
    - **`coding/refactor.md`**: A template for refactoring tasks. It includes:
        - **YAML Frontmatter**: Metadata such as the recommended model (`gpt-4o`), temperature (`0.2`), and tags.
        - **Task Instructions**: Specific requirements for C++20 compliance, `snake_case` naming, and the use of `std::ranges`.
        - **Placeholder**: A `{{CODE}}` marker where the target source code is inserted by tools like `assemble_prompt.sh` or `prompt_engine.py`.

- **`configs/`**: Stores model hyperparameters.
    - `model_settings.yaml`: Defines different profiles (e.g., `coding` for high determinism and `brainstorming` for higher creativity) including model choice, temperature, and token limits.

- **`examples/`**: Provides reference implementations.
    - `coding/refactor_cpp.json`: Likely a JSON representation of a completed prompt/response pair for refactoring.

### How it's used:
The `assemble_prompt` scripts and `prompt_engine.py` in the `c++` root directory use this folder to combine a **System Prompt** (from `system/`) with a **Template** (from `templates/`), substituting the actual C++ source code into the template to create a final prompt ready for an LLM.

