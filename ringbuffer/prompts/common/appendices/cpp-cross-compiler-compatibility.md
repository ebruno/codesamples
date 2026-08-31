# C++ Cross-Compiler Compatibility (clang++ ↔ g++)

> **Purpose:** This appendix documents the ABI compatibility between clang++ and g++, standard library behavior across platforms, and C++ version caveats. It is reference material for toolchain decisions — not a quick-reference card.
>
> **Quick rule:** On macOS, clang++ is the primary supported compiler. g++ support is best-effort — see Section 9 of `prompts/common/cpp/session_hints.md` for the operational summary.

---

## 1. macOS Standard Library Reality

| Compiler | Default Library | Headers Available? | Status |
|----------|----------------|--------------------|--------|
| **clang++** (Apple/Xcode) | `libc++` | ✅ Yes — shipped with Xcode/Apple CLT | Works out of the box |
| **Homebrew g++** | `libstdc++` | ❌ No — Apple deprecated libstdc++ headers on macOS 10.14+ | May fail to compile |

**Why g++ fails on modern macOS:**
Homebrew's `g++` defaults to `libstdc++`, but Apple removed the C++ standard library headers for libstdc++ starting with macOS 10.14 (Mojave). When g++ tries to compile code that includes `<atomic>`, `<vector>`, `<string>`, etc., it cannot find them in the libstdc++ include path.

**Workarounds (not guaranteed):**
- Install `libc++-dev` via Homebrew: `brew install libc++-dev` — provides headers for both libraries
- Pass `-stdlib=libc++` to g++: `g++ -stdlib=libc++ ...` — but Homebrew g++ may not link against libc++ correctly

**Ringbuffer policy:** Do **not** force `-stdlib=` in CXXFLAGS. Let each compiler use its default:
- clang++ → `libc++` (works)
- g++ → `libstdc++` (may fail on modern macOS — this is acceptable, documented in session hints)

---

## 2. Linux Standard Library Behavior

On Linux, **both clang++ and g++ default to `libstdc++`** (GNU's C++ standard library). This means:

- **ABI-compatible by default:** A library built with clang++ links against the same `libstdc++` as a program built with g++.
- **No `-stdlib` flag needed:** Neither compiler requires explicit standard library selection on Linux.
- **No header issues:** `libstdc++` headers are shipped with the system C++ compiler packages on all major Linux distributions.

**Exception:** If you explicitly pass `-stdlib=libc++` to clang++ on Linux, it will use LLVM's libc++ instead. This is ABI-incompatible with g++ and should be avoided unless you control both the library and all consumers.

---

## 3. C++ Standard Compatibility Matrix

| C++ Standard | clang++ ↔ g++ Compatibility | Major Caveat |
|--------------|----------------------------|--------------|
| **C++03 / Legacy** | ✅ Perfect | None — layouts were simple (often Copy-On-Write for `std::string`) |
| **C++11 / 14 / 17** | ✅ Perfect (with matching ABI macro) | Ensure both compilers use the same `_GLIBCXX_USE_CXX11_ABI` setting (modern default: `1`). Mismatch causes `undefined reference to std::__cxx11::basic_string` errors. |
| **C++20 / 23 / 26** | ⚠️ High for traditional code; ❌ breaks with C++ Modules | Traditional templates, concepts, ranges, and coroutines work fine. **C++20 Modules** (`.pcm` from clang++ vs `.gcm` from g++) use completely different internal binary formats and are **not interchangeable**. |

### The Great Shift (C++11 Dual ABI)

The C++11 standard introduced strict complexity rules that forced standard libraries to change how `std::string` and `std::list` were laid out in memory (shifting to Short String Optimization). To avoid breaking older software, GNU's `libstdc++` shipped a **Dual ABI**: the old layout and the new C++11 layout coexist.

**The catch:** If clang++ builds your library with the old layout macro (`-D_GLIBCXX_USE_CXX11_ABI=0`) and g++ compiles the app with the new layout (`-D_GLIBCXX_USE_CXX11_ABI=1`), linking will fail with undefined reference errors pointing to `std::__cxx11::basic_string`.

**Solution:** As long as both compilers are set to the same ABI macro version (modern systems default to `1`), they are perfectly compatible. The Ringbuffer Makefile does not set this macro explicitly, so both compilers use the system default (which is `1` on all modern systems).

---

## 4. Windows Compatibility Notes

Mixing MinGW (g++) and LLVM (clang++) on Windows can trigger subtle ABI edge cases:

| Factor | MinGW g++ | LLVM clang++ (MSVCRT) |
|--------|-----------|----------------------|
| **Thread model** | POSIX (default) or Win32 | Win32 (default) or POSIX |
| **Exception handling** | DWARF or SJLJ | SEH (default) or DWARF |
| **Compatibility** | Different thread models or exception handling mechanisms cause runtime crashes when mixing objects compiled with different settings |

**Rule for Windows:** If you must mix compilers on Windows, ensure both use the same thread model (`-mthreads`) and exception handling mechanism (`-fexceptions` / `-EHsc`). This is rarely a concern for the Ringbuffer project since Windows is not a target platform.

---

## 5. Safe Integration Workflow

If you need to build a library with one compiler and link it into an application built with another, follow these guidelines:

### Step 1: Ensure Matching Standard Library
```bash
# On Linux (both default to libstdc++ — no action needed)
clang++ -O3 -shared -fPIC my_lib.cpp -o libmy_lib.so
g++ -O3 main.cpp -L. -lmy_lib -o my_app

# On macOS (force clang++ to use libstdc++ if g++ is the consumer)
clang++ -O3 -shared -fPIC -stdlib=libstdc++ my_lib.cpp -o libmy_lib.so
g++ -O3 main.cpp -L. -lmy_lib -o my_app
```

### Step 2: Ensure Matching C++ Standard
```bash
# Both must use the same -std flag
clang++ -std=c++20 ...   # library
g++  -std=c++20 ...      # application
```

### Step 3: Ensure Matching ABI Macro (Linux C++11+)
```bash
# Verify both compilers use the same default:
clang++ -dM -E - < /dev/null | grep _GLIBCXX_USE_CXX11_ABI
g++  -dM -E - < /dev/null | grep _GLIBCXX_USE_CXX11_ABI
# Both should output: #define _GLIBCXX_USE_CXX11_ABI 1
```

---

## 6. Summary Checklist for Mixing Standards

| C++ Standard | Toolchain Compatibility | Major Caveat |
|--------------|------------------------|--------------|
| C++03 / Legacy | ✅ Perfect | None |
| C++11 / 14 / 17 | ✅ Perfect (with matching `_GLIBCXX_USE_CXX11_ABI`) | Ensure both compilers use the same ABI macro (modern default: `1`) |
| C++20 / 23 / 26 | ⚠️ High for traditional code; ❌ breaks with C++ Modules | C++20 modules (.pcm vs .gcm) are compiler-specific and not interchangeable |

---

## 7. Ringbuffer-Specific Implications

1. **macOS builds:** clang++ is the primary supported compiler (produces universal binaries). g++ support is best-effort — if it compiles, the resulting library is ABI-compatible with clang++. If g++ fails due to missing libstdc++ headers, this is an **INFO/WARNING** in the build report, not a failure.

2. **Linux builds:** Both clang++ and g++ default to `libstdc++`. No `-stdlib` flag needed. ABI-compatible by default.

3. **Multi-compiler Makefile targets:** The `all-all` target builds with both compilers sequentially (clang++ first on macOS, g++ first on Linux). Each build is independent — the resulting libraries are not mixed.

4. **No `-stdlib` in CXXFLAGS:** The Ringbuffer Makefile does not force a standard library. Each compiler uses its default, which is the correct behavior for each platform.
