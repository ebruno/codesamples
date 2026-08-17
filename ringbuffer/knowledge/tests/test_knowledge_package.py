#!/usr/bin/env python3
"""Regression tests for the LLM knowledge package.

Validates that the knowledge package is consistent, well-formed, and
matches the actual ringbuffer source code. Run from the project root:

    python3 knowledge/tests/test_knowledge_package.py
"""

import hashlib
import json
import os
import re
import sys
from pathlib import Path


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Resolve paths regardless of where the script is invoked from
_script_dir = Path(__file__).resolve().parent  # knowledge/tests/
if _script_dir.name == "tests" and (_script_dir.parent / "manifest.json").exists():
    KNOWLEDGE_DIR = _script_dir.parent  # knowledge/
else:
    KNOWLEDGE_DIR = Path(__file__).resolve().parent.parent / "knowledge"

# Source directories to scan for actual API signatures
# Derive project root from knowledge dir (parent of knowledge/)
PROJECT_ROOT = KNOWLEDGE_DIR.parent
SOURCE_DIRS = [
    PROJECT_ROOT / "src" / "macos" / "cpp",
    PROJECT_ROOT / "src" / "common" / "java" / "swtr",
    PROJECT_ROOT / "src" / "common" / "python",
]

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def read_file(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def read_json(path: Path) -> dict | list:
    return json.loads(read_file(path))


def scan_source_for_symbols(source_dirs: list[Path]) -> dict[str, set[str]]:
    """Scan all source dirs for class/method/enum definitions.

    Returns a dict mapping language -> set of symbol names found.
    """
    symbols: dict[str, set[str]] = {"cpp": set(), "java": set(), "python": set()}

    for src_dir in source_dirs:
        if not src_dir.is_dir():
            continue

        lang = "cpp" if "cpp" in str(src_dir) else \
               "java" if "java" in str(src_dir) else \
               "python"

        for fpath in src_dir.rglob("*"):
            if not fpath.is_file():
                continue

            try:
                content = read_file(fpath)
            except (UnicodeDecodeError, OSError):
                continue  # Skip binary files (.dylib, .a, etc.)

            if lang == "cpp":
                # Match class/struct definitions: class Foo { or struct Bar {
                for m in re.finditer(r'(?:class|struct)\s+(\w+)', content):
                    symbols[lang].add(m.group(1))
                # Match enum class definitions: enum class Foo : int {
                for m in re.finditer(r'enum\s+class\s+(\w+)\s*:', content):
                    symbols[lang].add(m.group(1))

            elif lang == "java":
                # Match class/interface/enum definitions
                for m in re.finditer(r'(?:public\s+)?(?:class|interface|enum)\s+(\w+)', content):
                    symbols[lang].add(m.group(1))

            elif lang == "python":
                # Match class definitions: class Foo(RingBuffer): or class Foo(ABC):
                for m in re.finditer(r'class\s+(\w+)', content):
                    symbols[lang].add(m.group(1))

    return symbols


def scan_source_for_enum_values(source_dirs: list[Path]) -> dict[str, dict[str, set[int]]]:
    """Scan source for enum values and their integer assignments.

    Returns: { language: { EnumName: {value1, value2, ...} } }
    """
    enum_values: dict[str, dict[str, set[int]]] = {
        "cpp": {}, "java": {}, "python": {}
    }

    for src_dir in source_dirs:
        if not src_dir.is_dir():
            continue

        lang = "cpp" if "cpp" in str(src_dir) else \
               "java" if "java" in str(src_dir) else \
               "python"

        for fpath in src_dir.rglob("*"):
            if not fpath.is_file():
                continue

            try:
                content = read_file(fpath)
            except (UnicodeDecodeError, OSError):
                continue  # Skip binary files

            if lang == "cpp":
                # Parse enum class blocks: enum class Foo : int { A = 0, B = 1 }
                for m in re.finditer(
                    r'enum\s+class\s+(\w+)\s*:\s*\w+\s*\{([^}]+)\}',
                    content, re.DOTALL
                ):
                    enum_name = m.group(1)
                    body = m.group(2)
                    values = set()
                    for val_m in re.finditer(r'(\w+)\s*=\s*(\d+)', body):
                        values.add(int(val_m.group(2)))
                    if enum_name not in enum_values[lang]:
                        enum_values[lang][enum_name] = values
                    else:
                        enum_values[lang][enum_name].update(values)

            elif lang == "java":
                # Parse enum blocks: public enum Foo { A(0), B(1) }
                for m in re.finditer(
                    r'(?:public\s+)?enum\s+(\w+)\s*\{([^}]+)\}',
                    content, re.DOTALL
                ):
                    enum_name = m.group(1)
                    body = m.group(2)
                    values = set()
                    for val_m in re.finditer(r'(\w+)\s*\(\s*(\d+)\s*\)', body):
                        values.add(int(val_m.group(2)))
                    if enum_name not in enum_values[lang]:
                        enum_values[lang][enum_name] = values
                    else:
                        enum_values[lang][enum_name].update(values)

            elif lang == "python":
                # Parse int-based enum: class Foo(int, Enum): A = 0, B = 1
                for m in re.finditer(
                    r'class\s+(\w+)\s*\([^)]*Enum[^)]*\):',
                    content
                ):
                    enum_name = m.group(1)
                    # Find the class body (next non-empty lines until next class or def at same indent)
                    idx = content.find(f"class {enum_name}")
                    if idx == -1:
                        continue
                    # Simple approach: find all = assignments in the class body
                    class_start = idx
                    # Find next top-level definition or end of file
                    rest = content[class_start:]
                    lines = rest.split("\n")
                    class_lines = []
                    for line in lines[1:]:  # skip the 'class' line itself
                        stripped = line.lstrip()
                        if not stripped:
                            continue
                        # If we hit a new top-level class/def, stop
                        if re.match(r'^(class |def )', stripped):
                            break
                        class_lines.append(line)

                    body = "\n".join(class_lines)
                    values = set()
                    for val_m in re.finditer(r'(\w+)\s*=\s*(\d+)', body):
                        values.add(int(val_m.group(2)))
                    if enum_name not in enum_values[lang]:
                        enum_values[lang][enum_name] = values
                    else:
                        enum_values[lang][enum_name].update(values)

    return enum_values


def scan_source_for_methods(source_dirs: list[Path]) -> dict[str, set[str]]:
    """Scan source for method/function signatures.

    Returns: { language: set of method names }
    """
    methods: dict[str, set[str]] = {"cpp": set(), "java": set(), "python": set()}

    for src_dir in source_dirs:
        if not src_dir.is_dir():
            continue

        lang = "cpp" if "cpp" in str(src_dir) else \
               "java" if "java" in str(src_dir) else \
               "python"

        for fpath in src_dir.rglob("*"):
            if not fpath.is_file():
                continue

            content = read_file(fpath)

            if lang == "cpp":
                # Match virtual methods: virtual void start() = 0; or virtual BufferStatus get_status(...)
                for m in re.finditer(
                    r'virtual\s+\w+[\s*&]+\w+\s+(\w+)\s*\(',
                    content
                ):
                    methods[lang].add(m.group(1))

            elif lang == "java":
                # Match public methods: void start(); or BufferStatus getStatus(...)
                for m in re.finditer(
                    r'(?:public|void|int|boolean|BufferStatus|ChecksumAlgorithm|LogLevel|OutputStream)\s+(\w+)\s*\(',
                    content
                ):
                    methods[lang].add(m.group(1))

            elif lang == "python":
                # Match method definitions: def start(self) -> None: or @abstractmethod def ...
                for m in re.finditer(
                    r'def\s+(\w+)\s*\(',
                    content
                ):
                    methods[lang].add(m.group(1))

    return methods


# ---------------------------------------------------------------------------
# Test functions — each returns (passed: bool, message: str)
# ---------------------------------------------------------------------------


def test_01_knowledge_dir_exists() -> tuple[bool, str]:
    """Knowledge directory exists."""
    if KNOWLEDGE_DIR.is_dir():
        return True, "knowledge/ directory exists"
    return False, f"knowledge/ directory not found at {KNOWLEDGE_DIR}"


def test_02_manifest_json_valid() -> tuple[bool, str]:
    """manifest.json is valid JSON with required fields."""
    manifest_path = KNOWLEDGE_DIR / "manifest.json"
    if not manifest_path.exists():
        return False, "manifest.json not found"

    try:
        data = read_json(manifest_path)
    except json.JSONDecodeError as e:
        return False, f"manifest.json is not valid JSON: {e}"

    required = ["name", "version", "ringbuffer_version", "languages"]
    missing = [f for f in required if f not in data]
    if missing:
        return False, f"manifest.json missing fields: {missing}"

    rv = data.get("ringbuffer_version", {})
    for field in ["major", "minor", "subversion", "build_id"]:
        if field not in rv:
            return False, f"ringbuffer_version missing '{field}'"

    return True, f"manifest.json valid (version={data['version']})"


def test_03_manifest_checksums_match() -> tuple[bool, str]:
    """manifest.json file checksums match actual files."""
    manifest_path = KNOWLEDGE_DIR / "manifest.json"
    data = read_json(manifest_path)

    stored_checksums = data.get("files", {})
    if not stored_checksums:
        return False, "manifest.json has no file checksums (run update.sh first)"

    mismatches = []
    for rel_path, expected_hash in stored_checksums.items():
        full_path = KNOWLEDGE_DIR / rel_path
        if not full_path.exists():
            mismatches.append(f"  {rel_path}: file missing")
            continue

        actual_hash = hashlib.sha256(full_path.read_bytes()).hexdigest()
        if actual_hash != expected_hash:
            mismatches.append(f"  {rel_path}: checksum mismatch")

    if mismatches:
        return False, f"Checksum mismatches ({len(mismatches)}):\n" + "\n".join(mismatches)

    return True, f"All {len(stored_checksums)} file checksums match"


def test_04_modelfile_valid() -> tuple[bool, str]:
    """Modelfile has valid structure (FROM + SYSTEM instructions)."""
    modelfile_path = KNOWLEDGE_DIR / "Modelfile"
    if not modelfile_path.exists():
        return False, "Modelfile not found"

    content = read_file(modelfile_path)
    lines = [l.strip() for l in content.split("\n") if l.strip()]

    has_from = any(l.startswith("FROM ") for l in lines)
    has_system = any(l.startswith("SYSTEM") or '"""' in l for l in lines)

    if not has_from:
        return False, "Modelfile missing FROM instruction"
    if not has_system:
        return False, "Modelfile missing SYSTEM instruction"

    # Check FROM references a Qwen model
    from_match = re.search(r'FROM\s+(\S+)', content)
    if from_match:
        base_model = from_match.group(1)
        if "qwen" not in base_model.lower():
            return False, f"FROM references non-Qwen model: {base_model}"

    return True, f"Modelfile valid (FROM={from_match.group(1) if from_match else 'N/A'})"


def test_05_system_prompt_version_matches_manifest() -> tuple[bool, str]:
    """System prompt version string matches manifest.json."""
    manifest = read_json(KNOWLEDGE_DIR / "manifest.json")
    expected_version = manifest["version"]

    # Check system-prompt.md
    prompt_path = KNOWLEDGE_DIR / "system-prompt.md"
    if not prompt_path.exists():
        return False, "system-prompt.md not found"

    prompt_content = read_file(prompt_path)
    version_match = re.search(r'## Version:\s*(\S+)', prompt_content)
    if not version_match:
        return False, "system-prompt.md missing '## Version:' line"

    if version_match.group(1) != expected_version:
        return False, (f"Version mismatch: manifest={expected_version}, "
                       f"system-prompt.md={version_match.group(1)}")

    # Check Modelfile
    modelfile_path = KNOWLEDGE_DIR / "Modelfile"
    mf_content = read_file(modelfile_path)
    mf_version_match = re.search(r'## Version:\s*(\S+)', mf_content)
    if mf_version_match and mf_version_match.group(1) != expected_version:
        return False, (f"Version mismatch: manifest={expected_version}, "
                       f"Modelfile={mf_version_match.group(1)}")

    return True, f"Version consistent across all files: {expected_version}"


def test_06_instruction_dataset_valid_jsonl() -> tuple[bool, str]:
    """Instruction dataset is valid JSONL with required fields."""
    train_path = KNOWLEDGE_DIR / "instruction-dataset" / "train.jsonl"
    eval_path = KNOWLEDGE_DIR / "instruction-dataset" / "eval.jsonl"

    total_lines = 0
    errors = []

    for path in [train_path, eval_path]:
        if not path.exists():
            errors.append(f"{path.relative_to(KNOWLEDGE_DIR)}: file missing")
            continue

        for i, line in enumerate(path.read_text().split("\n"), start=1):
            if not line.strip():
                continue
            total_lines += 1
            try:
                data = json.loads(line)
            except json.JSONDecodeError as e:
                errors.append(f"{path.name}:{i}: invalid JSON — {e}")
                continue

            if "messages" not in data:
                errors.append(f"{path.name}:{i}: missing 'messages' field")
                continue

            for j, msg in enumerate(data["messages"]):
                if "role" not in msg:
                    errors.append(f"{path.name}:{i}: message[{j}] missing 'role'")
                if "content" not in msg:
                    errors.append(f"{path.name}:{i}: message[{j}] missing 'content'")

    if errors:
        return False, f"Dataset errors ({len(errors)}):\n" + "\n".join(errors)

    return True, f"Instruction dataset valid ({total_lines} lines across train + eval)"


def test_07_instruction_dataset_covers_all_languages() -> tuple[bool, str]:
    """Instruction dataset includes examples for all three languages."""
    train_path = KNOWLEDGE_DIR / "instruction-dataset" / "train.jsonl"
    if not train_path.exists():
        return False, "train.jsonl not found"

    content = train_path.read_text().lower()
    languages_found = []
    for lang in ["cpp", "java", "python"]:
        if lang in content:
            languages_found.append(lang)

    expected = {"cpp", "java", "python"}
    missing = expected - set(languages_found)

    if missing:
        return False, f"Instruction dataset missing examples for: {missing}"

    return True, "Instruction dataset covers all languages (C++, Java, Python)"


def test_08_api_references_exist() -> tuple[bool, str]:
    """API reference files exist for all implemented languages."""
    api_dir = KNOWLEDGE_DIR / "api-reference"
    if not api_dir.is_dir():
        return False, "api-reference/ directory missing"

    expected = {"cpp.md", "java.md", "python.md"}
    actual = {f.name for f in api_dir.iterdir() if f.is_file()}
    missing = expected - actual

    if missing:
        return False, f"Missing API reference files: {missing}"

    # Check each file has content
    empty = []
    for f in api_dir.iterdir():
        if f.is_file() and len(f.read_text()) < 50:
            empty.append(f.name)

    if empty:
        return False, f"API reference files too short (<50 chars): {empty}"

    return True, "All API reference files present and non-empty"


def test_09_examples_exist_for_all_languages() -> tuple[bool, str]:
    """Example files exist for all three languages."""
    examples_dir = KNOWLEDGE_DIR / "examples"
    if not examples_dir.is_dir():
        return False, "examples/ directory missing"

    expected = {"basic.cpp", "basic.java", "basic.py",
                "advanced.cpp", "advanced.java", "advanced.py"}
    actual = {f.name for f in examples_dir.iterdir() if f.is_file()}
    missing = expected - actual

    if missing:
        return False, f"Missing example files: {missing}"

    # Check each file has content
    empty = []
    for f in examples_dir.iterdir():
        if f.is_file() and len(f.read_text()) < 20:
            empty.append(f.name)

    if empty:
        return False, f"Example files too short (<20 chars): {empty}"

    return True, "All example files present and non-empty"


def test_10_api_refs_match_source_symbols() -> tuple[bool, str]:
    """API reference files mention symbols that actually exist in source."""
    # Get actual symbols from source
    source_symbols = scan_source_for_symbols(SOURCE_DIRS)

    # Get symbols mentioned in API references
    api_dir = KNOWLEDGE_DIR / "api-reference"
    all_mentioned: dict[str, set[str]] = {"cpp": set(), "java": set(), "python": set()}

    for fpath in api_dir.rglob("*.md"):
        content = read_file(fpath)

        # Extract class/struct names from markdown (## Class Name, ```class Foo```)
        for m in re.finditer(r'(?:class|struct)\s+(\w+)', content):
            lang = "cpp" if "cpp.md" in fpath.name else \
                   "java" if "java.md" in fpath.name else \
                   "python"
            all_mentioned[lang].add(m.group(1))

        # Extract enum names from markdown
        for m in re.finditer(r'enum\s+(?:class\s+)?(\w+)', content):
            lang = "cpp" if "cpp.md" in fpath.name else \
                   "java" if "java.md" in fpath.name else \
                   "python"
            all_mentioned[lang].add(m.group(1))

    # Cross-check: every mentioned symbol should exist in source
    mismatches = []
    for lang in ["cpp", "java", "python"]:
        actual = source_symbols.get(lang, set())
        mentioned = all_mentioned.get(lang, set())

        # Filter out common false positives (std::, ::, etc.)
        mentioned_clean = {s for s in mentioned if not s.startswith("std::") and len(s) > 2}

        missing = mentioned_clean - actual
        if missing:
            mismatches.append(f"  {lang}: {len(missing)} symbols in docs but not in source: "
                              f"{', '.join(sorted(missing)[:10])}")

    if mismatches:
        return False, f"API reference/source mismatch ({len(mismatches)} issues):\n" + "\n".join(mismatches)

    return True, "API reference symbols match source code"


def test_11_enum_values_consistent_across_languages() -> tuple[bool, str]:
    """Enum values (BufferStatus, ChecksumAlgorithm, LogLevel) are consistent across languages."""
    enum_values = scan_source_for_enum_values(SOURCE_DIRS)

    # Check BufferStatus values
    cpp_bs = enum_values["cpp"].get("BufferStatus", set())
    java_bs = enum_values["java"].get("BufferStatus", set())
    python_bs = enum_values["python"].get("BufferStatus", set())

    if cpp_bs and java_bs and python_bs:
        if cpp_bs != java_bs or cpp_bs != python_bs:
            return False, (f"BufferStatus values inconsistent:\n"
                          f"  C++   = {sorted(cpp_bs)}\n"
                          f"  Java  = {sorted(java_bs)}\n"
                          f"  Python= {sorted(python_bs)}")

    # Check ChecksumAlgorithm values
    cpp_ca = enum_values["cpp"].get("ChecksumAlgorithm", set())
    java_ca = enum_values["java"].get("ChecksumAlgorithm", set())
    python_ca = enum_values["python"].get("ChecksumAlgorithm", set())

    if cpp_ca and java_ca and python_ca:
        if cpp_ca != java_ca or cpp_ca != python_ca:
            return False, (f"ChecksumAlgorithm values inconsistent:\n"
                          f"  C++   = {sorted(cpp_ca)}\n"
                          f"  Java  = {sorted(java_ca)}\n"
                          f"  Python= {sorted(python_ca)}")

    # Check LogLevel values
    cpp_ll = enum_values["cpp"].get("LogLevel", set())
    java_ll = enum_values["java"].get("LogLevel", set())
    python_ll = enum_values["python"].get("LogLevel", set())

    if cpp_ll and java_ll and python_ll:
        if cpp_ll != java_ll or cpp_ll != python_ll:
            return False, (f"LogLevel values inconsistent:\n"
                          f"  C++   = {sorted(cpp_ll)}\n"
                          f"  Java  = {sorted(java_ll)}\n"
                          f"  Python= {sorted(python_ll)}")

    return True, "Enum values consistent across all languages"


def test_12_patterns_exist() -> tuple[bool, str]:
    """Pattern documentation files exist."""
    patterns_dir = KNOWLEDGE_DIR / "patterns"
    if not patterns_dir.is_dir():
        return False, "patterns/ directory missing"

    expected = {"logging-guide.md", "checksumming.md"}
    actual = {f.name for f in patterns_dir.iterdir() if f.is_file()}
    missing = expected - actual

    if missing:
        return False, f"Missing pattern files: {missing}"

    # Check each file has content
    empty = []
    for f in patterns_dir.iterdir():
        if f.is_file() and len(f.read_text()) < 50:
            empty.append(f.name)

    if empty:
        return False, f"Pattern files too short (<50 chars): {empty}"

    return True, "All pattern files present and non-empty"


def test_13_scripts_exist_and_executable() -> tuple[bool, str]:
    """Shell scripts exist in both bash and zsh variants."""
    expected_scripts = [
        "update.sh", "update.zsh",
        "build_model.sh", "build_model.zsh"
    ]

    missing = []
    for script in expected_scripts:
        path = KNOWLEDGE_DIR / script
        if not path.exists():
            missing.append(script)

    if missing:
        return False, f"Missing scripts: {missing}"

    # Check shebangs
    issues = []
    for script in expected_scripts:
        path = KNOWLEDGE_DIR / script
        content = read_file(path)
        first_line = content.split("\n")[0]

        if script.endswith(".sh") and "#!/usr/bin/env bash" not in first_line:
            issues.append(f"{script}: expected '#!/usr/bin/env bash', got '{first_line}'")
        elif script.endswith(".zsh") and "#!/usr/bin/env zsh" not in first_line:
            issues.append(f"{script}: expected '#!/usr/bin/env zsh', got '{first_line}'")

    if issues:
        return False, f"Shebang issues:\n" + "\n".join(issues)

    return True, "All scripts present with correct shebangs"


def test_14_system_prompt_mentions_all_languages() -> tuple[bool, str]:
    """System prompt includes quick-start examples for all three languages."""
    prompt_path = KNOWLEDGE_DIR / "system-prompt.md"
    content = read_file(prompt_path).lower()

    languages_found = []
    for lang in ["cpp", "java", "python"]:
        if lang in content:
            languages_found.append(lang)

    expected = {"cpp", "java", "python"}
    missing = expected - set(languages_found)

    if missing:
        return False, f"System prompt missing language references: {missing}"

    # Check for code blocks
    cpp_blocks = content.count("```cpp")
    java_blocks = content.count("```java")
    python_blocks = content.count("```python")

    if cpp_blocks == 0:
        return False, "System prompt missing C++ code block"
    if java_blocks == 0:
        return False, "System prompt missing Java code block"
    if python_blocks == 0:
        return False, "System prompt missing Python code block"

    return True, f"System prompt covers all languages (C++:{cpp_blocks}, Java:{java_blocks}, Python:{python_blocks})"


def test_15_api_refs_mention_key_methods() -> tuple[bool, str]:
    """API reference files mention key methods (start, stop, wait/awaitTermination)."""
    api_dir = KNOWLEDGE_DIR / "api-reference"

    # Key lifecycle methods to check
    key_methods = {
        "cpp": ["start", "stop", "wait"],
        "java": ["start", "stop", "awaitTermination"],
        "python": ["start", "stop", "wait"]
    }

    issues = []
    for fpath in api_dir.rglob("*.md"):
        content = read_file(fpath)

        lang = "cpp" if "cpp.md" in fpath.name else \
               "java" if "java.md" in fpath.name else \
               "python"

        expected = key_methods.get(lang, [])
        for method in expected:
            # Check if the method name appears (as a word boundary)
            pattern = rf'\b{method}\b'
            if not re.search(pattern, content):
                issues.append(f"  {fpath.name}: missing method '{method}'")

    if issues:
        return False, f"API reference missing key methods:\n" + "\n".join(issues)

    return True, "API references mention all key lifecycle methods"


# ---------------------------------------------------------------------------
# Test runner
# ---------------------------------------------------------------------------

ALL_TESTS = [
    ("01", "Knowledge directory exists", test_01_knowledge_dir_exists),
    ("02", "manifest.json valid JSON with required fields", test_02_manifest_json_valid),
    ("03", "manifest.json checksums match actual files", test_03_manifest_checksums_match),
    ("04", "Modelfile valid (FROM + SYSTEM)", test_04_modelfile_valid),
    ("05", "System prompt version matches manifest", test_05_system_prompt_version_matches_manifest),
    ("06", "Instruction dataset valid JSONL", test_06_instruction_dataset_valid_jsonl),
    ("07", "Instruction dataset covers all languages", test_07_instruction_dataset_covers_all_languages),
    ("08", "API reference files exist for all languages", test_08_api_references_exist),
    ("09", "Example files exist for all languages", test_09_examples_exist_for_all_languages),
    ("10", "API references match source symbols", test_10_api_refs_match_source_symbols),
    ("11", "Enum values consistent across languages", test_11_enum_values_consistent_across_languages),
    ("12", "Pattern documentation files exist", test_12_patterns_exist),
    ("13", "Shell scripts exist with correct shebangs", test_13_scripts_exist_and_executable),
    ("14", "System prompt mentions all languages with code blocks", test_14_system_prompt_mentions_all_languages),
    ("15", "API references mention key lifecycle methods", test_15_api_refs_mention_key_methods),
]


def run_tests() -> int:
    """Run all tests. Returns 0 if all pass, 1 otherwise."""
    print("=" * 72)
    print("LLM Knowledge Package — Regression Tests")
    print("=" * 72)
    print()

    passed = 0
    failed = 0
    results = []

    for num, name, test_fn in ALL_TESTS:
        try:
            ok, msg = test_fn()
        except Exception as e:
            ok = False
            msg = f"Exception: {e}"

        status = "PASS" if ok else "FAIL"
        results.append((num, name, status, msg))

        if ok:
            passed += 1
            print(f"  [{num}] {status}: {name}")
        else:
            failed += 1
            print(f"  [{num}] {status}: {name}")
            for line in msg.split("\n"):
                print(f"         {line}")

    print()
    print("=" * 72)
    print(f"Results: {passed} passed, {failed} failed, {len(ALL_TESTS)} total")
    print("=" * 72)

    return 1 if failed > 0 else 0


if __name__ == "__main__":
    sys.exit(run_tests())
