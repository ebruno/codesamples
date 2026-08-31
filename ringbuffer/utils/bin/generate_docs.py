#!/usr/bin/env python3
"""Generate Doxygen documentation with automated Types section insertion.

Usage: generate_docs.py [status_hpp_path]
Default: src/common/cpp/status.hpp (relative to workspace root)

Steps:
1. Remove existing docs/ringbuffer/ directory
2. Generate Types section from status.hpp
3. Insert Types section into overview markdown before "## Quick Example"
4. Run Doxygen for C++ and Java
5. Restore original overview markdown
6. Clean up temp files
"""
import re
import sys
import subprocess
from pathlib import Path

def parse_enums(header_path):
    """Parse enum class definitions from a C++ header file."""
    with open(header_path) as f:
        content = f.read()
    
    enums = []
    for match in re.finditer(r'enum\s+class\s+(\w+)\s*:', content):
        enum_name = match.group(1)
        start = match.start()
        block = content[start:start+500]
        values = re.findall(r'(\w+)\s*=', block)
        enums.append({
            'name': enum_name,
            'values': values[:5]
        })
    return enums

def generate_types_section(enums):
    """Generate markdown section with enum descriptions."""
    lines = ['## Types', '']
    
    for e in enums:
        if e['values']:
            sample = ', '.join(e['values'][:3])
            desc = f"Pipeline states ({sample}, ...)" if 'Status' in e['name'] else \
                   f"Hash algorithms ({', '.join(e['values'][1:])})" if 'Checksum' in e['name'] else \
                   f"Logging levels ({', '.join(e['values'][1:])})" if 'Level' in e['name'] else \
                   f"Enum with values: {', '.join(e['values'])}"
        else:
            desc = f"{e['name']} enum"
        
        lines.append(f'- **{e["name"]}** — {desc}')
    
    return '\n'.join(lines)

def insert_types_section(overview_path, types_section):
    """Insert Types section into overview before '## Quick Example'."""
    with open(overview_path) as f:
        content = f.read()
    
    # Save original for restoration
    backup_path = str(overview_path) + '.backup'
    with open(backup_path, 'w') as f:
        f.write(content)
    
    # Insert before "## Quick Example"
    marker = '## Quick Example'
    if marker in content:
        # Only insert if not already present
        types_marker = '## Types'
        if types_marker not in content:
            content = content.replace(marker, types_section + '\n\n---\n\n' + marker)
    
    with open(overview_path, 'w') as f:
        f.write(content)

def restore_overview(overview_path):
    """Restore original overview from backup."""
    backup_path = str(overview_path) + '.backup'
    if Path(backup_path).exists():
        with open(backup_path) as f:
            content = f.read()
        with open(overview_path, 'w') as f:
            f.write(content)
        Path(backup_path).unlink()

def run_doxygen(directory):
    """Run Doxygen in the specified directory."""
    result = subprocess.run(
        ['doxygen', 'Doxyfile'],
        cwd=directory,
        capture_output=True,
        text=True
    )
    if result.returncode != 0:
        print(f"ERROR: Doxygen failed in {directory}:")
        print(result.stderr)
        sys.exit(1)

if __name__ == '__main__':
    workspace = Path.cwd()
    header = Path(sys.argv[1]) if len(sys.argv) > 1 else workspace / 'src/common/cpp/status.hpp'
    overview = workspace / 'prompts/common/cpp/.docs/swtr_ringbuffer_overview.md'
    
    print("Fixing up documentation...")
    
    # Step 1: Generate Types section
    print("Step 1: Generating Types section...")
    enums = parse_enums(header)
    types_section = generate_types_section(enums)
    
    # Step 2: Insert Types section into overview
    print("Step 2: Inserting Types section into overview...")
    insert_types_section(overview, types_section)
    
    # Step 3: Regenerate C++ docs with Types section
    print("Step 3: Regenerating C++ documentation...")
    run_doxygen(workspace / 'prompts/common/cpp')
    
    # Step 4: Restore original overview
    print("Step 4: Restoring original overview...")
    restore_overview(overview)
    
    print("Documentation fix-up complete.")
