# Man Page Generation Workflow — swtr_ringbuffer C++

**Objective:**
Generate or regenerate `prompts/common/cpp/swtr_ringbuffer.md` — the pandoc-ready Markdown man page for the C++ `swtr::SwtrRingBuffer` library. The output must be accurate, complete, and structured for easy `pandoc -s -t man` conversion.

**Inputs:**
1. **Source Headers (Interface — source of truth for API):**
   - `src/macos/cpp/ringbuffer.hpp` — base class `RingBuffer`, type aliases, constants
   - `src/macos/cpp/status.hpp` — enumerations (`BufferStatus`, `ChecksumAlgorithm`, `LogLevel`)
   - `src/macos/cpp/swtr_ringbuffer_impl.hpp` — derived class `SwtrRingBuffer`, constructor params, public methods
2. **Per-OS Makefiles (source of truth for compilation/linking flags):**
   - `src/macos/cpp/Makefile` — macOS clang++ flags, universal binary support
   - `src/fedora/cpp/Makefile` — Linux g++/clang++ flags, LTO handling
   - `src/debian/cpp/Makefile` — Debian-specific build flags (if different)
   - `src/ubuntu/cpp/Makefile` — Ubuntu-specific build flags (if different)
   - `src/raspios/cpp/Makefile` — Raspberry Pi OS build flags (if different)
   - `src/freebsd14/cpp/Makefile` — FreeBSD clang++ flags, BSD make syntax
   - `src/archlinux/cpp/Makefile` — Arch Linux build flags (if different)
3. **Existing Output (for diff/regeneration):**
   - `prompts/common/cpp/swtr_ringbuffer.md` — current man page (read to preserve structure, update content)

**Process:**

1. **Read Source Headers — Extract API Surface:**
   - Parse `ringbuffer.hpp` for: base class name, virtual method signatures, type aliases (`ErrorHandler`, `TransformFn`), and constants (`MIN_NUMBER_SLOTS`, `DEFAULT_BUFFER_SIZE`).
   - Parse `status.hpp` for: all enumeration definitions, their backing types (`int`), and every named value with its integer constant.
   - Parse `swtr_ringbuffer_impl.hpp` for: derived class name, constructor signature (all parameters with defaults), all public method signatures overriding or extending the base class.
   - Log: `Extracted API from source headers.`

2. **Read Per-OS Makefiles — Extract Compilation/Linking Flags:**
   - For each OS directory in `src/<os>/cpp/`, read the `Makefile` and extract:
     - Compiler (`CXX` or equivalent)
     - C++ standard flag (e.g., `-std=c++20`)
     - Warning flags (`-Wall`, `-Wextra`, etc.)
     - Optimization flags (`-O2`, `-O3`, `-flto`)
     - Include paths (`-I` flags)
     - Library output type (static `-static`, shared `-shared`, or both)
     - Linker flags (`-L`, `-l`, `-Wl,-rpath`, etc.)
     - Platform-specific flags (e.g., macOS `-arch arm64 -arch x86_64`, Linux `-pthread`, FreeBSD `-pthread`)
   - Group flags by OS. Note any differences between OSes (e.g., macOS uses `clang++`, Linux uses `g++` or `clang++`).
   - Log: `Extracted compilation/linking flags for <N> OS targets.`

3. **Read Existing Man Page — Preserve Structure:**
   - Read `prompts/common/cpp/swtr_ringbuffer.md` to understand the current section structure.
   - Identify sections that need updating vs. sections that can be preserved as-is (e.g., DESCRIPTION, KEY FEATURES).
   - Log: `Read existing man page for structure reference.`

4. **Generate/Update Man Page Markdown:**
   Produce `prompts/common/cpp/swtr_ringbuffer.md` with the following sections, in order:

   ### 4.1 NAME
   - Format: `**swtr_ringbuffer** — <one-line description>`
   - Description should capture: thread-safe, ring buffer, transform pipeline, checksum support.

   ### 4.2 SYNOPSIS
   - Show the `#include` directive.
   - Show static and shared library linking examples as shell comments.

   ### 4.3 DESCRIPTION
   - Describe the three-stage pipeline (Read → Transform → Write).
   - List key features as a bullet list: thread-safety, multi-slot pipeline, transform pipeline, checksum support, error handling, logging, cross-platform.
   - Keep this section human-readable; do not derive from source code directly.

   ### 4.4 API REFERENCE
   - Document the base class `RingBuffer` (virtual methods: `start`, `stop`, `wait`, `set_read_fd`, `set_write_fd`, etc.).
   - Document the derived class `SwtrRingBuffer`:
     - Constructor with all parameters and defaults.
     - All public methods in a table: Method | Parameters | Return Type | Description.
   - Use the exact signatures from source headers — this is the source of truth.

   ### 4.5 ENUMERATIONS
   - Document each enumeration from `status.hpp`:
     - `BufferStatus` — all 14 values with descriptions.
     - `ChecksumAlgorithm` — all 4 values with descriptions.
     - `LogLevel` — all 6 values with descriptions.
   - Include the backing type (`int`) for ABI stability note.

   ### 4.6 TRANSFORMS
   - Describe the `TransformFn` type alias and its usage contract.
   - List common transform examples (uppercase, XOR, identity).

   ### 4.7 ERROR HANDLING
   - Describe the `ErrorHandler` type alias and its callback contract.
   - Explain slot-level status tracking via `BufferStatus::STATUS_ERROR`.

   ### 4.8 COMPILATION PER OS
   - For each supported OS, provide a code block with the exact compilation command:
     ```bash
     # macOS (clang++)
     clang++ -std=c++20 -Wall -Wextra -O2 -arch arm64 -arch x86_64 -pthread \
       -I include src/*.cpp -o swtr_ringbuffer

     # Linux (g++)
     g++ -std=c++20 -Wall -Wextra -O2 -flto -pthread \
       -I include src/*.cpp -o swtr_ringbuffer

     # FreeBSD (clang++)
     clang++ -std=c++20 -Wall -Wextra -O2 -pthread \
       -I include src/*.cpp -o swtr_ringbuffer
     ```
   - Use flags extracted from Makefiles in Step 2. Note any OS-specific differences.

   ### 4.9 LINKING PER OS
   - For each supported OS, provide linking examples:
     ```bash
     # Static library linking (all platforms)
     g++ -o myapp main.cpp -L<path>/lib -lswtr_ringbuffer

     # Shared library linking (Linux/FreeBSD)
     g++ -o myapp main.cpp -L<path>/lib -lswtr_ringbuffer -Wl,-rpath,<path>/lib

     # Shared library linking (macOS)
     clang++ -o myapp main.cpp -L<path>/lib -lswtr_ringbuffer -Wl,-rpath,@loader_path/../lib
     ```
   - Note platform-specific runtime linking differences (e.g., macOS `@loader_path` vs Linux `$ORIGIN`).

   ### 4.10 EXAMPLES
   - Provide a minimal usage example showing construction, transform registration, and pipeline start/stop.

   ### 4.11 SEE ALSO
   - Cross-reference related documentation files in the project.

5. **Validate Output:**
   - Verify all method signatures match source headers exactly.
   - Verify all enumeration values are present and correct.
   - Verify compilation/linking commands use flags from actual Makefiles.
   - Ensure markdown structure is pandoc-compatible (proper heading levels, code blocks with language tags, tables).
   - Log: `Validation complete.`

**Reporting:**

After generation, output a summary:
```
Man page regenerated: prompts/common/cpp/swtr_ringbuffer.md
  - API methods documented: <N>
  - Enumerations documented: <M> (total values: <V>)
  - OS targets covered: <list>
  - Source headers read: ringbuffer.hpp, status.hpp, swtr_ringbuffer_impl.hpp
  - Makefiles read: <list>
```

**Regeneration Checklist:**
- [ ] All `RingBuffer` virtual methods documented
- [ ] All `SwtrRingBuffer` public methods documented with correct signatures
- [ ] All enumeration values present and correctly numbered
- [ ] Compilation commands match actual Makefile flags for each OS
- [ ] Linking examples include static and shared variants per platform
- [ ] macOS `@loader_path` vs Linux `$ORIGIN` runtime path noted
- [ ] Markdown heading hierarchy is correct (H1 for title, H2 for sections)
- [ ] Code blocks use proper language tags (`cpp`, `bash`)
- [ ] Tables are properly formatted for pandoc
