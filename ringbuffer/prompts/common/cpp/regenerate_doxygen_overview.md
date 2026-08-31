# Regenerate Doxygen Main Page from README.md

**Objective:** Update `prompts/common/cpp/swtr_ringbuffer_overview.md` to reflect the current state of `README.md`, then regenerate Doxygen HTML output.

## Workflow

```
User: "regenerate the swtr_ringbuffer man page"
Agent: Reads prompts/common/cpp/regenerate_doxygen_overview.md → reads README.md → regenerates swtr_ringbuffer_overview.md
```

## Steps

1. **Read** `README.md` and extract the following sections:
   - Library description (first paragraph)
   - "What It Does" section — pipeline architecture explanation
   - "Core Features" list
   - Platform support table (update any changes in OS/language status)
   - Architecture overview (class hierarchies — verify against current source)
   - Quick example code snippet

2. **Compare** with existing `prompts/common/cpp/swtr_ringbuffer_overview.md` and update any sections that have drifted from `README.md`.

3. **Preserve** the Doxygen `/** @mainpage ... */` wrapper — do not remove it.

4. **Regenerate** Doxygen output:
   ```bash
   cd prompts/common/cpp && doxygen Doxyfile
   cd ../../../src/common/java && doxygen Doxyfile
   ```

5. **Verify** the output:
   - `docs/ringbuffer/cpp/html/index.html` — title should be "swtr_ringbuffer C++: Ringbuffer Library"
   - `docs/ringbuffer/java/html/index.html` — title should be "swtr_ringbuffer Java: Ringbuffer Library"
   - Both should contain the updated overview content

## Notes

- The overview is a **curated subset** of README.md — not the full document. Exclude LLM development methodology, prompt patterns, and project-process content.
- The overview lives in `prompts/common/cpp/` (source location), not in `docs/`.
- Doxygen picks it up via the `INPUT` + `FILE_PATTERNS = *.md` settings in both Doxyfiles.
