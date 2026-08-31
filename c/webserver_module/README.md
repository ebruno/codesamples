# HTTP Header Parser

Reads HTTP 1.1 headers from stdin and retains only the `Set-Cookie` keys.
Demonstrates pointer usage and `malloc`.

## Build

```bash
make
```

## Test

```bash
make test01
make test02
```

Both tests pipe a set of HTTP 1.1 headers through stdin.

## Tested Environments

- macOS 26
- Debian 13
- Fedora 43

## Prompt Assembly for Refactoring

This module includes Makefile rules to assemble LLM prompts for refactoring
the source code to ANSI C23 standards with automatic fallback
to C17/C18 if C23 is not supported by the environment.

### Assemble Prompts

```bash
make refactor
```

### Run Prompt Engine

```bash
make run_prompt
```

## Direct Script Usage

Scripts are located in the parent [`c/`](../) directory.

- **Bash**: `../assemble_prompt.sh <file1> [file2 ...]`
- **Zsh**: `../assemble_prompt.zsh <file1> [file2 ...]`
- **Python**: `python3 ../prompt_engine.py <file1> [file2 ...]`

Use `-n` for a dry run with any of the above.
