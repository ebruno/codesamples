# Test Data Patterns

This directory contains the authoritative pattern specifications for test data generation. Each `.md` file defines a complete pattern that is used by:

- `ringbuffer/prompts/common/testing/create_scripts.md` — generates utility scripts from the pattern
- `ringbuffer/prompts/common/cpp/testing.md` — references the pattern for test data requirements
- Each platform's `ringbuffer/prompts/<os>/cpp/testing.md` — inherits the common pattern

## Adding a New Pattern

1. Copy the template below (starting from `---`) into a new file: `ringbuffer/prompts/common/testing/patterns/<name>.md`
2. Replace all placeholder values with your pattern's actual data.
3. Ensure the Python reference implementation is correct — it is the ground truth for all shell variants.
4. Run `ringbuffer/prompts/common/testing/create_scripts.md` to generate the utility scripts.

## Existing Patterns

| Pattern | File | Description |
|---------|------|-------------|
| zigzag | `zigzag.md` | Zig-zag space replacement pattern (default) |

---

# Pattern File Template

Copy everything below this line to create a new pattern file. Replace all `<placeholder>` values with your actual data.

```markdown
# <Pattern Name> Test Data Pattern

**Pattern Name:** <name>  
**Version:** 1.0.0  

## Template String

```
<48-character template string>
```

Length: 48 characters. This is the authoritative ground truth — all script variants MUST use this exact string with no modifications, additions, or omissions.

## Line Format

```
[<prefix_format>] [<space_separator>] [<payload>] [<space_separator>] [<suffix_format>]
```

- **Prefix:** <description of prefix format, e.g., "Characters 1–4 are a zero-padded 4-digit sequence number (e.g., `0001`, `0002`). Character 5 is a single space.">
- **Payload:** <description of payload, e.g., "Characters 6–53 are the template string with one character replaced by a space (zig-zag position).">
- **Suffix:** <description of suffix format, e.g., "Character 54 is a single space. Characters 55–58 are the same zero-padded sequence number as the prefix.">
- **Total Line Length:** Exactly <N> characters (excluding the trailing newline).

## Validation Regex

```
<regex pattern>
```

Every line in every test data file MUST match this regex. The validator script (`verify_test_data.sh`) enforces this constraint.

## <Position/Transformation> Logic

<Describe the algorithm for transforming the template string per line. Include:
- What changes from line to line (e.g., which character is replaced)
- The mathematical formula or step-by-step procedure
- Edge cases (e.g., line 1 has no transformation)

For example:
> For line number `n`:
> 1. If `n == 1`, no space is inserted — the payload is the raw template string.
> 2. If `n > 1`:
>    - Let `L` be the length of the template string (48).
>    - Calculate `idx = n - 2`.
>    - Calculate `cycle = 2 * (L - 1)`.
>    - Calculate `off = idx % cycle`.
>    - If `off < L - 1`, then the space index is `i = off + 1`.
>    - Otherwise, the space index is `i = cycle - off`.

## Python Reference Implementation (Ground Truth)

The following Python function is the authoritative reference. All shell script variants MUST produce byte-identical output:

```python
def generate_<name>_line(n: int) -> str:
    """Generate a single test data line for line number n."""
    template = "<48-character template string>"
    prefix = f"<prefix_format>"
    suffix = f"<suffix_format>"

    if <edge_case_condition>:
        return prefix + template + suffix

    # ... transformation logic here ...

    return prefix + payload + suffix
```

## Test File Line Counts

| Test ID | Input File    | Lines |
|---------|---------------|-------|
| T001    | test001.txt   | <N>   |
| T002    | test002.txt   | <N>   |
| T003    | test003.txt   | <N>   |
| T004    | test004.txt   | <N>   |
| T005    | test005.txt   | <N>   |
| T006    | test006.txt   | <N>   |
| T007    | test007.txt   | <N>   |

## JUnit Test Matrix

| Test ID | Description                    | Transform | Error Mode | Expected Exit Code |
|---------|--------------------------------|-----------|------------|-------------------|
| T001    | <description>                  | <N>       | <N>        | <0 or 1>          |
| T002    | <description>                  | <N>       | <N>        | 0                 |
| T003    | <description>                  | <N>       | <N>        | 0                 |
| T004    | <description>                  | <N>       | <N>        | 0                 |
| T005    | <description>                  | <N>       | <N>        | <0 or 1>          |
| T006    | <description>                  | <N>       | <N>        | 0                 |
| T007    | <description>                  | <N>       | <N>        | 0                 |

## Sample Output (First 3 Lines)

```
<line 1 output>
<line 2 output>
<line 3 output>
```

## File Location

This pattern file is the single source of truth for test data generation. It is referenced by:
- `ringbuffer/prompts/common/testing/create_scripts.md` — generates the utility scripts from this pattern.
- `ringbuffer/prompts/common/cpp/testing.md` — references the same pattern for test data generation requirements.
- `ringbuffer/prompts/<os>/cpp/testing.md` — platform-specific testing specs reference this common pattern.

## License

All code and documentation in the Ringbuffer project is covered under the BSD 3-Clause License.
```
