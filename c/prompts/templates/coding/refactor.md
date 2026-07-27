---
model: gpt-4o
temperature: 0.2
version: 1.0
tags: [c, refactor, optimization]
---

# Task
Please refactor the provided C code to improve its maintainability, readability, and performance.

# Requirements
1. **C23/C17 Compliance:** Update legacy patterns to C23 standards (e.g., `nullptr`, `bool`, `auto`). If C23 features would prevent the code from compiling in a standard environment, fallback to C17/C18 standards.
2. **Naming:** Ensure variables follow a consistent `snake_case` naming convention.
3. **Complexity:** Optimize loops and memory access patterns for better performance.
4. **Documentation:** Include a header comment in the source file specifying the C standard finally used (C23 or C17/C18), the compiler version, and a list of any C23 features omitted due to the fallback. All functions must have Doxygen-style comments.
5. **Output:** Provide the full updated source code and a brief bulleted list of the specific improvements made.

# Source Code to Refactor:
```c
{{CODE}}
```
