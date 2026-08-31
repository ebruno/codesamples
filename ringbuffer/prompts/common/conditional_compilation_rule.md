# Conditional Compilation Rule

**Purpose:** When a platform lacks a C++ or C feature available on other platforms, use `#ifdef` blocks to provide an alternative implementation for that OS **only**. Never modify the common code path or "down-rev" features for all other platforms.

## The Rule

1. **Target-Only Downgrade:** When adding conditional compilation for a new OS port, wrap only the affected code in an `#ifdef` block for that specific OS (e.g., `#if defined(__FreeBSD__)`). The alternative implementation applies **only** to that OS.

2. **Preserve All Other Platforms:** Do NOT modify, remove, or degrade code paths for any other platform. The common (non-`#ifdef`) path remains the canonical implementation for all platforms that support it.

3. **Byte-Identical Where Possible:** The non-conditional code path must remain byte-identical across all platforms. Conditional blocks are the exception, not the rule.

4. **Apply to Both C and C++:** This rule applies equally to C (`#ifdef __FreeBSD__`) and C++ source files.

## Example (Correct)

```cpp
#if defined(__FreeBSD__)
// FreeBSD lacks std::jthread / stop_token — use atomic<bool> + std::thread
std::atomic<bool> stop_flag_{false};
void worker() { while (!stop_flag_.load()) { /* ... */ } }
#else
// All other platforms: use std::jthread with stop_token
void worker(std::stop_token st) { while (!st.stop_requested()) { /* ... */ } }
#endif
```

## Example (Incorrect)

```cpp
// WRONG: Down-revving ALL platforms because FreeBSD lacks a feature
void worker() { /* simplified version for all OSes */ }  // loses stop_token on macOS/Linux
```

## Origin

Learned during FreeBSD 14 porting. The library must support platforms with older C++ standards without degrading the experience on newer-platform hosts.
