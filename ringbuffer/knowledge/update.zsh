#!/usr/bin/env zsh
# update.zsh — Regenerates LLM knowledge package from source headers
#
# Usage: ./knowledge/update.zsh [-i | -b <number>]
#   MAJOR/MINOR/SUBVERSION are read from knowledge/version.mk (independent of ringbuffer)
#
# Flags:
#   -i                     Increment BUILD_ID in version.mk only (no regeneration, no tarball).
#   -b <number>            Use this BUILD_ID for regeneration and tarball (no version.mk change).
#
# Examples:
#   ./knowledge/update.zsh -i                       # Bump BUILD_ID in version.mk only
#   ./knowledge/update.zsh -b 5                     # Build with BUILD_ID=5 (no version.mk change)
#   ./knowledge/update.zsh                          # Use current BUILD_ID from version.mk as-is

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Read version from knowledge/version.mk (independent of ringbuffer) ---
VERSION_MK="$SCRIPT_DIR/version.mk"
if [[ ! -f "$VERSION_MK" ]]; then
    echo "ERROR: $VERSION_MK not found. Run this from the project root." >&2
    exit 1
fi

# Parse version.mk (uses Makefile syntax: VAR = value, not shell export)
while IFS= read -r line; do
    case "$line" in
        MAJOR\ *) MAJOR="${line#MAJOR = }" ;;
        MINOR\ *) MINOR="${line#MINOR = }" ;;
        SUBVERSION\ *) SUBVERSION="${line#SUBVERSION = }" ;;
        BUILD_ID\ *) CURRENT_BUILD_ID="${line#BUILD_ID = }" ;;
    esac
done < "$VERSION_MK"
CURRENT_BUILD_ID="${CURRENT_BUILD_ID:-0}"

# --- Parse flags (getopts) ---
INCREMENT_BUILDID=0
EXPLICIT_BUILD_ID=""
REFRESH_README=0
SCRIPT_NAME="$(basename "$0")"

# --- Usage ---
usage() {
    cat >&2 <<EOF
Usage: $SCRIPT_NAME [-i | -b <number> | -r]
  MAJOR/MINOR/SUBVERSION are read from knowledge/version.mk (independent of ringbuffer)

Flags:
  -i                     Increment BUILD_ID in version.mk only (no regeneration, no tarball).
  -b <number>            Use this BUILD_ID for regeneration and tarball (no version.mk change).
  -r                     Refresh README.md to point at latest .tar.gz in releases/.

Examples:
  $SCRIPT_NAME -i                       # Bump BUILD_ID in version.mk only
  $SCRIPT_NAME -b 5                     # Build with BUILD_ID=5 (no version.mk change)
  $SCRIPT_NAME -r                       # Update README.md to latest tarball in releases/
  $SCRIPT_NAME                          # Use current BUILD_ID from version.mk as-is
EOF
    exit 1
}

while getopts ":hib:r" opt; do
    case "$opt" in
        h)
            usage
            ;;
        i)
            if [[ -n "$EXPLICIT_BUILD_ID" ]] || [[ $REFRESH_README -eq 1 ]]; then
                echo "ERROR: -i is mutually exclusive with other flags." >&2
                exit 1
            fi
            INCREMENT_BUILDID=1
            ;;
        b)
            if [[ $INCREMENT_BUILDID -eq 1 ]] || [[ $REFRESH_README -eq 1 ]]; then
                echo "ERROR: -b is mutually exclusive with other flags." >&2
                exit 1
            fi
            EXPLICIT_BUILD_ID="$OPTARG"
            ;;
        r)
            if [[ $INCREMENT_BUILDID -eq 1 ]] || [[ -n "$EXPLICIT_BUILD_ID" ]]; then
                echo "ERROR: -r is mutually exclusive with other flags." >&2
                exit 1
            fi
            REFRESH_README=1
            ;;
        :)
            echo "ERROR: -b requires a number argument." >&2
            exit 1
            ;;
        *)
            usage
            ;;
    esac
done

# --- Refresh README.md to latest tarball ---
if [[ $REFRESH_README -eq 1 ]]; then
    RELEASE_DIR="$SCRIPT_DIR/releases"
    if [[ ! -d "$RELEASE_DIR" ]]; then
        echo "ERROR: $RELEASE_DIR directory not found." >&2
        exit 1
    fi
    # Find all tarballs, extract BUILD_ID, sort numerically, pick highest
    LATEST_TARBALL=""
    LATEST_ID=0
    for f in "$RELEASE_DIR"/swtr-ringbuffer-knowledge-*.tar.gz; do
        [[ -f "$f" ]] || continue
        basename_f=$(basename "$f")
        # Extract BUILD_ID from filename: v1.0.0-build-5.tar.gz → 5
        build_num="${basename_f##*-build-}"
        build_num="${build_num%.tar.gz}"
        if [[ "$build_num" =~ ^[0-9]+$ ]] && (( build_num > LATEST_ID )); then
            LATEST_ID=$build_num
            LATEST_TARBALL="$f"
        fi
    done
    if [[ -z "$LATEST_TARBALL" ]]; then
        echo "ERROR: No tarballs found in $RELEASE_DIR." >&2
        exit 1
    fi
    LATEST_FILENAME=$(basename "$LATEST_TARBALL")
    # Update README.md
    _tmpfile=$(mktemp)
    while IFS= read -r line; do
        if [[ "$line" == *"swtr-ringbuffer-knowledge-"*".tar.gz"* ]]; then
            line="${line//swtr-ringbuffer-knowledge-*.tar.gz/$LATEST_FILENAME}"
        fi
        printf '%s\n' "$line"
    done < "$PROJECT_ROOT/README.md" > "$_tmpfile"
    if [[ -s "$PROJECT_ROOT/README.md" ]] && [[ "$(tail -c 1 "$PROJECT_ROOT/README.md" | wc -l)" -eq 0 ]]; then
        truncate -s -1 "$_tmpfile"
    fi
    mv "$_tmpfile" "$PROJECT_ROOT/README.md"
    echo "Updated README.md to point at $LATEST_FILENAME (BUILD_ID=$LATEST_ID)"
    exit 0
fi

# --- Determine BUILD_ID ---
if [[ $INCREMENT_BUILDID -eq 1 ]]; then
    # Increment mode: read, increment, write back, exit
    (( CURRENT_BUILD_ID++ )) || true
    _tmp_mk=$(mktemp)
    while IFS= read -r line; do
        case "$line" in
            BUILD_ID\ *) line="BUILD_ID = $CURRENT_BUILD_ID" ;;
        esac
        printf '%s\n' "$line"
    done < "$VERSION_MK" > "$_tmp_mk"
    mv "$_tmp_mk" "$VERSION_MK"
    echo "BUILD_ID incremented to $CURRENT_BUILD_ID in version.mk"
    exit 0
elif [[ -n "$EXPLICIT_BUILD_ID" ]]; then
    # Explicit BUILD_ID: use it but do NOT write to version.mk
    NEW_BUILD_ID="$EXPLICIT_BUILD_ID"
else
    # Default: use current value from version.mk as-is (no increment)
    NEW_BUILD_ID="$CURRENT_BUILD_ID"
fi

FULL_VERSION="${MAJOR}.${MINOR}.${SUBVERSION}-build-${NEW_BUILD_ID}"

echo "=== Regenerating LLM Knowledge Package ==="
echo "Version: $FULL_VERSION (MAJOR=$MAJOR, MINOR=$MINOR, SUBVERSION=$SUBVERSION, BUILD_ID=$NEW_BUILD_ID)"

# --- Update manifest.json ---
echo "Updating knowledge/manifest.json..."
cat > "$SCRIPT_DIR/manifest.json" <<EOF
{
  "name": "swtr-ringbuffer-knowledge",
  "version": "$FULL_VERSION",
  "languages": ["cpp", "java", "python"],
  "compatible_with": [
    "qwen3.6-35b-a3b",
    "qwen2.5-14b-instruct",
    "qwen2.5-7b-instruct"
  ],
  "distribution": {
    "system_prompt": "Modelfile — wraps any Qwen model, instant to use",
    "fine_tuned": "swtr-ringbuffer-qwen2.5-14b-v${MAJOR}.${MINOR}.${SUBVERSION}-build-${NEW_BUILD_ID}.gguf — QLoRA fine-tuned, zero-context inference",
    "download": {
      "current": "[Download Archive](knowledge/releases/swtr-ringbuffer-knowledge-v${MAJOR}.${MINOR}.${SUBVERSION}-build-${NEW_BUILD_ID}.tar.gz)",
      "older_versions": "Look in \`knowledge/releases/\` for older versions."
    }
  },
  "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "files": {}
}
EOF

# --- Update system-prompt.md version string (zsh parameter expansion, no sed) ---
echo "Updating knowledge/system-prompt.md..."
_tmpfile=$(mktemp)
while IFS= read -r line; do
    if [[ "$line" =~ ^Version:\ [0-9.]*-build-[0-9]+ ]]; then
        line="Version: $FULL_VERSION"
    fi
    printf '%s\n' "$line"
done < "$SCRIPT_DIR/system-prompt.md" > "$_tmpfile"
if [[ -s "$SCRIPT_DIR/system-prompt.md" ]] && [[ "$(tail -c 1 "$SCRIPT_DIR/system-prompt.md" | wc -l)" -eq 0 ]]; then
    truncate -s -1 "$_tmpfile"
fi
mv "$_tmpfile" "$SCRIPT_DIR/system-prompt.md"

# --- Update Modelfile version string (zsh parameter expansion, no sed) ---
echo "Updating knowledge/Modelfile..."
_tmpfile=$(mktemp)
while IFS= read -r line; do
    if [[ "$line" =~ ^v[0-9.]*-build-[0-9]+ ]]; then
        line="v$FULL_VERSION"
    fi
    if [[ "$line" =~ ^Version:\ [0-9.]*-build-[0-9]+ ]]; then
        line="Version: $FULL_VERSION"
    fi
    printf '%s\n' "$line"
done < "$SCRIPT_DIR/Modelfile" > "$_tmpfile"
if [[ -s "$SCRIPT_DIR/Modelfile" ]] && [[ "$(tail -c 1 "$SCRIPT_DIR/Modelfile" | wc -l)" -eq 0 ]]; then
    truncate -s -1 "$_tmpfile"
fi
mv "$_tmpfile" "$SCRIPT_DIR/Modelfile"

# --- Update .gen_state.json ---
echo "Updating knowledge/.gen_state.json..."
cat > "$SCRIPT_DIR/.gen_state.json" <<EOF
{
  "version": "$FULL_VERSION",
  "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "source_version": {
    "major": $MAJOR,
    "minor": $MINOR,
    "subversion": $SUBVERSION
  },
  "files": {}
}
EOF

# --- Compute SHA-256 checksums for all knowledge files ---
echo "Computing file checksums..."
CHECKSUMS=""
for f in "$SCRIPT_DIR"/Modelfile "$SCRIPT_DIR"/system-prompt.md \
         "$SCRIPT_DIR"/api-reference/*.md \
         "$SCRIPT_DIR"/examples/*.* \
         "$SCRIPT_DIR"/patterns/*.md; do
    if [[ -f "$f" ]]; then
        HASH=$(sha256sum "$f")
        HASH="${HASH%% *}"  # Extract hash (zsh builtin, no awk)
        REL_PATH="${f#$SCRIPT_DIR/}"
        CHECKSUMS="$CHECKSUMS\n    \"$REL_PATH\": \"$HASH\""
    fi
done

# Update manifest.json with checksums
if command -v python3 &>/dev/null; then
    python3 -c "
import json, hashlib, os

script_dir = '$SCRIPT_DIR'
manifest_path = os.path.join(script_dir, 'manifest.json')

with open(manifest_path) as f:
    manifest = json.load(f)

files = {}
for root, dirs, filenames in os.walk(script_dir):
    for fn in filenames:
        if fn.endswith('.json') or fn == '.gen_state.json':
            continue
        full_path = os.path.join(root, fn)
        rel_path = os.path.relpath(full_path, script_dir)
        with open(full_path, 'rb') as f:
            files[rel_path] = hashlib.sha256(f.read()).hexdigest()

manifest['files'] = files
with open(manifest_path, 'w') as f:
    json.dump(manifest, f, indent=2)
    f.write('\n')
"
fi

echo ""

# =========================================================================
# Build/Setup Guide Extraction
# =========================================================================
echo "Generating build guide from test Makefiles and README..."

BUILD_GUIDE="$SCRIPT_DIR/patterns/build-guide.md"

# Extract the C++ build recipes from the macOS test Makefile (reference platform)
MACOS_TEST_MAKEFILE="$PROJECT_ROOT/src/macos/cpp/tests/Makefile"
STATIC_CMD=""
DYNAMIC_CMD=""
if [[ -f "$MACOS_TEST_MAKEFILE" ]]; then
    while IFS= read -r line; do
        if [[ "$line" =~ test001_staticlib:.*cpp ]]; then
            read -r _skip_mkdir
            read -r next_line
            STATIC_CMD="${next_line#	}"
        fi
        if [[ "$line" =~ test001_dynamiclib:.*cpp ]]; then
            read -r _skip_mkdir
            read -r next_line
            DYNAMIC_CMD="${next_line#	}"
        fi
    done < "$MACOS_TEST_MAKEFILE"
fi

# Extract README example (first cpp block only)
README_EXAMPLE=""
README_BUILD=""
if [[ -f "$PROJECT_ROOT/README.md" ]]; then
    in_example=0
    found_example=0
    while IFS= read -r line; do
        if (( ! found_example )) && [[ "$line" == '```cpp' ]]; then
            in_example=1
            continue
        fi
        if (( in_example )) && [[ "$line" == '```' ]]; then
            in_example=0
            found_example=1
        elif (( in_example )); then
            README_EXAMPLE+="$line"$'\n'
        fi
        if [[ "$line" =~ ^Build\ with: ]]; then
            README_BUILD="${line#Build with: }"
            README_BUILD="${README_BUILD#\`}"
            README_BUILD="${README_BUILD%\`}"
        fi
    done < "$PROJECT_ROOT/README.md"
fi

# Write build-guide with QUOTED heredoc (no shell expansion) + placeholder substitution
cat > "$BUILD_GUIDE" <<'BUILDEOF'
# Build Guide — Using the Ringbuffer Library

> Auto-generated from project test Makefiles and README.md.
> Version: __FULL_VERSION__

## C++

### Minimal Example (macOS)

Create a file `main.cpp`:

```cpp
__README_EXAMPLE__```

Build with:
```bash
__README_BUILD__
```

### Static Linking (macOS)

Link directly against the static library — no runtime path needed:

```bash
__STATIC_CMD__
```

### Dynamic Linking (macOS)

Link against the shared library with @rpath for runtime resolution:

```bash
__DYNAMIC_CMD__
```

### Platform-Specific Notes

| Platform | Compiler | Shared Lib | Linker Flag |
|----------|----------|------------|-------------|
| macOS | clang++ | `.dylib` | `-Wl,-rpath,@loader_path/../lib` |
| Linux (GNU) | g++ | `.so` | `-Wl,-rpath,$ORIGIN/../lib` |
| FreeBSD 14 | clang++ | static only | no rpath — use static library |

## Java

### Maven Project Setup

Add to your `pom.xml`:

```xml
<dependency>
    <groupId>swtr</groupId>
    <artifactId>ringbuffer</artifactId>
    <version>__MAJOR__.__MINOR__.__SUBVERSION__</version>
</dependency>
```

Build: `mvn compile package`

JAR output: `target/ringbuffer-__MAJOR__.__MINOR__.__SUBVERSION__.jar`

## Python

### Pure Python Mode

No compilation needed — pure Python implementation:

```python
from swtr_ringbuffer_pure import SwtrRingBuffer, BufferStatus

rb = SwtrRingBuffer(num_slots=4, buffer_size=4096)
rb.set_read_fd(0)
rb.set_write_fd(1)
rb.start()
rb.wait()
```

### Concurrent Mode (ctypes)

Requires the C++ shared library (`libswtr_ringbuffer.so` / `.dylib`) to be built first.
The library must be in `src/<os>/cpp/lib/` or on `LD_LIBRARY_PATH` / `DYLD_LIBRARY_PATH`.

```python
from swtr_ringbuffer import SwtrRingBuffer, BufferStatus
# Same API, backed by C++ library via ctypes
```
BUILDEOF

# Substitute placeholders with actual values via Python (avoids shell escaping issues)
_py_subst=$(mktemp)
export FULL_VERSION README_EXAMPLE README_BUILD STATIC_CMD DYNAMIC_CMD MAJOR MINOR SUBVERSION BUILD_GUIDE
cat > "$_py_subst" <<'PYEOF'
import os

with open(os.environ['BUILD_GUIDE'], 'r') as f:
    content = f.read()

content = content.replace('__FULL_VERSION__', os.environ['FULL_VERSION'])
content = content.replace('__README_EXAMPLE__', os.environ['README_EXAMPLE'])
content = content.replace('__README_BUILD__', os.environ['README_BUILD'])
content = content.replace('__STATIC_CMD__', os.environ['STATIC_CMD'])
content = content.replace('__DYNAMIC_CMD__', os.environ['DYNAMIC_CMD'])
content = content.replace('__MAJOR__', os.environ['MAJOR'])
content = content.replace('__MINOR__', os.environ['MINOR'])
content = content.replace('__SUBVERSION__', os.environ['SUBVERSION'])

with open(os.environ['BUILD_GUIDE'], 'w') as f:
    f.write(content)
PYEOF
python3 "$_py_subst"
rm -f "$_py_subst"
echo "  Wrote $BUILD_GUIDE"

# =========================================================================
# Extract LM Studio system prompt from Modelfile
# =========================================================================
echo "Extracting LM Studio system prompt..."
LMS_PROMPT="$SCRIPT_DIR/lms-system-prompt.txt"
LMS_MODEL=""
if [[ -f "$SCRIPT_DIR/Modelfile" ]]; then
    in_system=0
    :> "$LMS_PROMPT"
    while IFS= read -r line; do
        # Extract FROM line for model name
        if [[ "$line" =~ ^FROM\  ]]; then
            LMS_MODEL="${line#FROM }"
        fi
        # Start capturing: SYSTEM """ may have content on same line
        if [[ "$line" =~ ^SYSTEM\ \"\"\"(.*) ]]; then
            in_system=1
            _rest="${match[1]}"
            if [[ -n "$_rest" ]]; then
                printf '%s\n' "$_rest" >> "$LMS_PROMPT"
            fi
            continue
        fi
        # Stop at closing """ on its own line
        if (( in_system )) && [[ "$line" == '"""' ]]; then
            in_system=0
        elif (( in_system )); then
            printf '%s\n' "$line" >> "$LMS_PROMPT"
        fi
    done < "$SCRIPT_DIR/Modelfile"
    echo "  Wrote $LMS_PROMPT (model: ${LMS_MODEL:-unknown})"
fi

# Convert Ollama model name (colons) to LM Studio format (hyphens)
LMS_MODEL="${LMS_MODEL//:/-}"

# Create/update lms-chat wrapper script
LMS_CHAT="$SCRIPT_DIR/lms-chat.zsh"
cat > "$LMS_CHAT" <<'LMSCHAT'
#!/usr/bin/env zsh
# lms-chat.zsh — Convenience wrapper to chat with the ringbuffer knowledge model via LM Studio
#
# Usage:
#   ./lms-chat.zsh                    Interactive chat
#   ./lms-chat.zsh "your question"    One-shot, prints response and exits

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROMPT_FILE="$SCRIPT_DIR/lms-system-prompt.txt"

# Read model name from lms-model.txt, or use default
MODEL_FILE="$SCRIPT_DIR/lms-model.txt"
if [[ -f "$MODEL_FILE" ]]; then
    MODEL="$(<"$MODEL_FILE")"
else
    echo "ERROR: lms-model.txt not found. Run update.zsh first." >&2
    exit 1
fi

if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "ERROR: lms-system-prompt.txt not found. Run update.zsh first." >&2
    exit 1
fi

SYSTEM_PROMPT="$(<"$PROMPT_FILE")"

if [[ $# -ge 1 ]]; then
    # One-shot mode
    lms chat "$MODEL" -s "$SYSTEM_PROMPT" -p "$1"
else
    # Interactive mode
    echo "Starting interactive chat with ringbuffer knowledge..."
    echo "Model: $MODEL"
    echo ""
    lms chat "$MODEL" -s "$SYSTEM_PROMPT"
fi
LMSCHAT
chmod +x "$LMS_CHAT"

# Also create the bash version
cat > "$SCRIPT_DIR/lms-chat.sh" <<'LMSCHATSH'
#!/usr/bin/env bash
# lms-chat.sh — Convenience wrapper to chat with the ringbuffer knowledge model via LM Studio
#
# Usage:
#   ./lms-chat.sh                    Interactive chat
#   ./lms-chat.sh "your question"    One-shot, prints response and exits

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_FILE="$SCRIPT_DIR/lms-system-prompt.txt"

MODEL_FILE="$SCRIPT_DIR/lms-model.txt"
if [[ -f "$MODEL_FILE" ]]; then
    MODEL="$(<"$MODEL_FILE")"
else
    echo "ERROR: lms-model.txt not found. Run update.zsh first." >&2
    exit 1
fi

if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "ERROR: lms-system-prompt.txt not found. Run update.zsh first." >&2
    exit 1
fi

SYSTEM_PROMPT="$(<"$PROMPT_FILE")"

if [[ $# -ge 1 ]]; then
    lms chat "$MODEL" -s "$SYSTEM_PROMPT" -p "$1"
else
    echo "Starting interactive chat with ringbuffer knowledge..."
    echo "Model: $MODEL"
    echo ""
    lms chat "$MODEL" -s "$SYSTEM_PROMPT"
fi
LMSCHATSH
chmod +x "$SCRIPT_DIR/lms-chat.sh"

# Write model name file
LMS_MODEL_FILE="$SCRIPT_DIR/lms-model.txt"
if [[ -n "${LMS_MODEL:-}" ]]; then
    printf '%s\n' "$LMS_MODEL" > "$LMS_MODEL_FILE"
else
    printf '%s\n' "qwen3.6-35b-a3b-mlx" > "$LMS_MODEL_FILE"
fi
echo "  Created lms-chat wrapper scripts"

# =========================================================================
# Append build/setup Q&A pairs to instruction dataset
# =========================================================================
echo "Appending build/setup Q&A pairs to instruction dataset..."

# Write Python script to temp file (no -c, no escaping issues)
_py=$(mktemp)
export README_EXAMPLE README_BUILD STATIC_CMD DYNAMIC_CMD MAJOR MINOR SUBVERSION
cat > "$_py" <<'PYEOF'
import json, os

train_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'instruction-dataset', 'train.jsonl')
if 'TRAIN_FILE' in os.environ:
    train_file = os.environ['TRAIN_FILE']
else:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    train_file = os.path.join(script_dir, 'instruction-dataset', 'train.jsonl')

qa_pairs = [
    {
        'messages': [
            {'role': 'system', 'content': 'You are a ringbuffer expert. The library implements a 3-stage pipeline (read\u2192transform\u2192write) with atomic slot state machines.'},
            {'role': 'user', 'content': 'How do I create a minimal C++ project that uses the ringbuffer on macOS? Show me the code and the build command.'},
            {'role': 'assistant', 'content': 'Create a file `main.cpp`:\n\n```cpp\n' + os.environ['README_EXAMPLE'] + '```\n\nBuild with:\n\n```bash\n' + os.environ['README_BUILD'] + '\n```\n\nThis links against the shared library. The `-I` flag points to the headers, `-L` to the library directory, and `-lswtr_ringbuffer` links the library. On macOS, add `-Wl,-rpath,@loader_path/../lib` so the binary finds the dylib at runtime.'}
        ]
    },
    {
        'messages': [
            {'role': 'system', 'content': 'You are a ringbuffer expert. The library implements a 3-stage pipeline (read\u2192transform\u2192write) with atomic slot state machines.'},
            {'role': 'user', 'content': 'What is the difference between static and dynamic linking for the ringbuffer C++ library?'},
            {'role': 'assistant', 'content': '**Static linking** links libswtr_ringbuffer.a directly into your binary \u2014 no runtime dependency, larger binary, no rpath needed:\n\n```bash\n' + os.environ['STATIC_CMD'] + '\n```\n\n**Dynamic linking** links against libswtr_ringbuffer.dylib (macOS) or .so (Linux) \u2014 smaller binary, shared library must be present at runtime:\n\n```bash\n' + os.environ['DYNAMIC_CMD'] + '\n```\n\nDynamic requires rpath so the binary can find the library at runtime. On macOS: `-Wl,-rpath,@loader_path/../lib`. On Linux: `-Wl,-rpath,$ORIGIN/../lib`. FreeBSD 14 does not support rpath/$ORIGIN \u2014 static library only.'}
        ]
    },
    {
        'messages': [
            {'role': 'system', 'content': 'You are a ringbuffer expert. The library implements a 3-stage pipeline (read\u2192transform\u2192write) with atomic slot state machines.'},
            {'role': 'user', 'content': 'How do I set up a Java project with Maven that uses the ringbuffer library?'},
            {'role': 'assistant', 'content': 'Add the ringbuffer dependency to your `pom.xml`:\n\n```xml\n<dependency>\n    <groupId>swtr</groupId>\n    <artifactId>ringbuffer</artifactId>\n    <version>' + os.environ['MAJOR'] + '.' + os.environ['MINOR'] + '.' + os.environ['SUBVERSION'] + '</version>\n</dependency>\n```\n\nBuild with Maven:\n\n```bash\nmvn compile package\n```\n\nThe JAR is at `target/ringbuffer-' + os.environ['MAJOR'] + '.' + os.environ['MINOR'] + '.' + os.environ['SUBVERSION'] + '.jar`. Import in your code:\n\n```java\nimport swtr.SwtrRingBuffer;\nimport swtr.BufferStatus;\nimport swtr.TransformFunction;\n```'}
        ]
    },
    {
        'messages': [
            {'role': 'system', 'content': 'You are a ringbuffer expert. The library implements a 3-stage pipeline (read\u2192transform\u2192write) with atomic slot state machines.'},
            {'role': 'user', 'content': 'How do I use the ringbuffer in Python? What is the difference between pure and concurrent mode?'},
            {'role': 'assistant', 'content': '**Pure Python mode** \u2014 no compilation needed, works everywhere:\n\n```python\nfrom swtr_ringbuffer_pure import SwtrRingBuffer, BufferStatus\n\nrb = SwtrRingBuffer(num_slots=4, buffer_size=4096)\nrb.set_read_fd(0)\nrb.set_write_fd(1)\nrb.start()\nrb.wait()\n```\n\n**Concurrent mode** \u2014 uses the C++ library via ctypes, faster but requires the shared library to be built first:\n\n```python\nfrom swtr_ringbuffer import SwtrRingBuffer, BufferStatus\n# Same API \u2014 backed by C++ library\n```\n\nThe C++ library (`libswtr_ringbuffer.dylib` on macOS, `.so` on Linux) must be in `src/<os>/cpp/lib/` or on the library path. Concurrent mode is skipped on FreeBSD 14 (RPATH limitation) and Raspios (C++ unsupported).'}
        ]
    },
]

# Read existing entries
entries = []
if os.path.exists(train_file):
    with open(train_file) as f:
        for line in f:
            line = line.strip()
            if line:
                entries.append(json.loads(line))

# Check for duplicates by question text
seen_questions = set()
for e in entries:
    for msg in e.get('messages', []):
        if msg['role'] == 'user':
            seen_questions.add(msg['content'])

# Append new entries that are not duplicates
added = 0
for qa in qa_pairs:
    question = qa['messages'][1]['content']
    if question not in seen_questions:
        entries.append(qa)
        added += 1

with open(train_file, 'w') as f:
    for e in entries:
        f.write(json.dumps(e) + '\n')

print(f'  Appended {added} new Q&A pairs (total: {len(entries)})')
PYEOF

# Run the Python script with env vars (no -c, no escaping issues)
TRAIN_FILE="$SCRIPT_DIR/instruction-dataset/train.jsonl" \
    README_EXAMPLE="$README_EXAMPLE" \
    README_BUILD="$README_BUILD" \
    STATIC_CMD="$STATIC_CMD" \
    DYNAMIC_CMD="$DYNAMIC_CMD" \
    MAJOR="$MAJOR" \
    MINOR="$MINOR" \
    SUBVERSION="$SUBVERSION" \
    python3 "$_py"
rm -f "$_py"

# =========================================================================
# Create release tarball
# =========================================================================
echo "Creating release tarball..."

RELEASE_DIR="$SCRIPT_DIR/releases"
mkdir -p "$RELEASE_DIR"
TARBALL="swtr-ringbuffer-knowledge-v${MAJOR}.${MINOR}.${SUBVERSION}-build-${NEW_BUILD_ID}.tar.gz"
TARBALL_PATH="$RELEASE_DIR/$TARBALL"

# Create tarball excluding releases/, .DS_Store, and .gen_state.json files
tar czf "$TARBALL_PATH" \
    --exclude='releases/' \
    --exclude='.DS_Store' \
    --exclude='.gen_state.json' \
    -C "$SCRIPT_DIR" \
    .

TARBALL_SIZE=$(du -h "$TARBALL_PATH" | cut -f1)
echo "  Created: $TARBALL"
echo "  Size:    $TARBALL_SIZE"

# --- Update README.md Distribution Paths table ---
echo "Updating README.md download link..."
_tmpfile=$(mktemp)
while IFS= read -r line; do
    if [[ "$line" == *"swtr-ringbuffer-knowledge-"*".tar.gz"* ]]; then
        line="${line//swtr-ringbuffer-knowledge-*.tar.gz/$TARBALL}"
    fi
    printf '%s\n' "$line"
done < "$PROJECT_ROOT/README.md" > "$_tmpfile"
if [[ -s "$PROJECT_ROOT/README.md" ]] && [[ "$(tail -c 1 "$PROJECT_ROOT/README.md" | wc -l)" -eq 0 ]]; then
    truncate -s -1 "$_tmpfile"
fi
mv "$_tmpfile" "$PROJECT_ROOT/README.md"
echo "  Updated README.md Distribution Paths table to $TARBALL"

# --- Keep only the 3 most recent tarballs ---
echo "Cleaning old release tarballs (keeping latest 3)..."
TARBALL_COUNT=0
for f in "$RELEASE_DIR"/swtr-ringbuffer-knowledge-*.tar.gz; do
    [[ -f "$f" ]] || continue
    (( TARBALL_COUNT++ )) || true
done
if [[ $TARBALL_COUNT -gt 3 ]]; then
    # Sort by BUILD_ID numerically, delete oldest beyond 3
    KEPT=0
    for f in $(for t in "$RELEASE_DIR"/swtr-ringbuffer-knowledge-*.tar.gz; do
        [[ -f "$t" ]] || continue
        bn=$(basename "$t")
        bid="${bn##*-build-}"
        bid="${bid%.tar.gz}"
        echo "$bid $t"
    done | sort -rn | awk '{print $2}'); do
        (( KEPT++ )) || true
        if [[ $KEPT -gt 3 ]]; then
            rm -f "$f"
            echo "  Removed: $(basename "$f")"
        fi
    done
fi
echo "  Kept $(( TARBALL_COUNT > 3 ? 3 : TARBALL_COUNT )) of $TARBALL_COUNT tarball(s)"

echo ""
echo "=== Done ==="
echo "Knowledge package updated to version: $FULL_VERSION"
echo "  Release tarball: knowledge/releases/$TARBALL ($TARBALL_SIZE)"
echo ""
echo "Next steps:"
echo "  1. Review generated files in knowledge/"
echo "  2. Run ./knowledge/build_model.sh to fine-tune (optional)"
echo "  3. Commit and push to GitLab"
