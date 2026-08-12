# Zig-Zag Test Data Pattern

**Pattern Name:** zigzag  
**Version:** 1.0.0  

## Template String

```
ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>
```

Length: 48 characters. This is the authoritative ground truth — all script variants MUST use this exact string with no modifications, additions, or omissions.

## Line Format

```
[4-digit sequence] [space] [48-char payload] [space] [4-digit sequence]
```

- **Prefix:** Characters 1–4 are a zero-padded 4-digit sequence number (e.g., `0001`, `0002`). Character 5 is a single space.
- **Payload:** Characters 6–53 are the template string with one character replaced by a space (zig-zag position).
- **Suffix:** Character 54 is a single space. Characters 55–58 are the same zero-padded sequence number as the prefix.
- **Total Line Length:** Exactly 58 characters (excluding the trailing newline).

## Validation Regex

```
^[0-9]{4} .{47} [0-9]{4}$
```

Every line in every test data file MUST match this regex. The validator script (`verify_test_data.sh`) enforces this constraint.

## Zig-Zag Position Logic

For line number `n`:

1. If `n == 1`, no space is inserted — the payload is the raw template string.
2. If `n > 1`:
   - Let `L` be the length of the template string (48).
   - Calculate `idx = n - 2`.
   - Calculate `cycle = 2 * (L - 1)` = 94.
   - Calculate `off = idx % cycle`.
   - If `off < L - 1` (i.e., `off < 47`), then the space index is `i = off + 1`.
   - Otherwise, the space index is `i = cycle - off`.

This causes the space to zig-zag from position 2 through position 48 and back, repeating every 94 lines.

## Python Reference Implementation (Ground Truth)

The following Python function is the authoritative reference. All shell script variants MUST produce byte-identical output:

```python
def generate_zigzag_line(n: int) -> str:
    """Generate a single zig-zag test data line for line number n."""
    template = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>"
    prefix = f"{n:04d} "
    suffix = f" {n:04d}"

    if n == 1:
        return prefix + template + suffix

    L = len(template)
    idx = n - 2
    cycle = 2 * (L - 1)
    off = idx % cycle

    if off < L - 1:
        i = off + 1
    else:
        i = cycle - off

    chars = list(template)
    chars[i] = ' '
    return prefix + ''.join(chars) + suffix
```

## Test File Line Counts

| Test ID | Input File    | Lines |
|---------|---------------|-------|
| T001    | test001.txt   | 25    |
| T002    | test002.txt   | 50    |
| T003    | test003.txt   | 75    |
| T004    | test004.txt   | 100   |
| T005    | test005.txt   | 150   |
| T006    | test006.txt   | 200   |
| T007    | test007.txt   | 250   |

## JUnit Test Matrix

| Test ID | Description                    | Transform | Error Mode | Expected Exit Code |
|---------|--------------------------------|-----------|------------|-------------------|
| T001    | Exact match with input         | 0 (none)  | 0          | 0                 |
| T002    | Stress test (1 slot, 1 byte)   | 0 (none)  | 0          | 0                 |
| T003    | All chars uppercase            | 1 (upper) | 0          | 0                 |
| T004    | Input < 1 slot (fast EOF)      | 0 (none)  | 0          | 0                 |
| T005    | Pipeline stop (Fatal Error)    | 0 (none)  | 1          | 1                 |
| T006    | Pipeline continues (Non-fatal) | 0 (none)  | 2          | 0                 |
| T007    | Bit-inverted output            | 2 (XOR)   | 0          | 0                 |

## Sample Output (First 3 Lines)

```
0001 ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<> 0001
0002 ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<> 0002
0003 A CDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<> 0003
```

Line 1: no space inserted (raw template).  
Line 2: no space inserted (n=2, idx=0, off=0, i=1 → position 2 is 'B', replaced with space... wait — let me verify).

Actually for n=2: idx=0, cycle=94, off=0, 0 < 47 → i = 1. Position 1 (0-based) in the template is 'B'. So line 2 should have a space at position 1:

```
0002 A CDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<> 0002
```

Line 3: idx=1, off=1, 1 < 47 → i = 2. Position 2 is 'C':

```
0003 AB DEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<> 0003
```

## File Location

This pattern file is the single source of truth for test data generation. It is referenced by:
- `ringbuffer/prompts/common/testing/create_scripts.md` — generates the utility scripts from this pattern.
- `ringbuffer/prompts/common/cpp/testing.md` — references the same pattern for test data generation requirements.
- `ringbuffer/prompts/<os>/cpp/testing.md` — platform-specific testing specs reference this common pattern.

## License

All code and documentation in the Ringbuffer project is covered under the BSD 3-Clause License.
