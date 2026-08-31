#!/usr/bin/env python3
"""Generate a markdown Types section from C++ status.hpp enum definitions.

Usage: generate_types_section.py [path_to_status.hpp]
Default: src/common/cpp/status.hpp (relative to workspace root)

Output: Markdown-formatted section with links to Doxygen-generated enum pages.
"""
import re
import sys
from pathlib import Path

def parse_enums(header_path):
    """Parse enum class definitions from a C++ header file."""
    with open(header_path) as f:
        content = f.read()
    
    enums = []
    for match in re.finditer(r'enum\s+class\s+(\w+)\s*:', content):
        enum_name = match.group(1)
        # Find the first few values for a brief description
        start = match.start()
        block = content[start:start+500]
        values = re.findall(r'(\w+)\s*=', block)
        enums.append({
            'name': enum_name,
            'values': values[:5]  # First 5 values for description
        })
    return enums

def generate_section(enums):
    """Generate markdown section with enum descriptions."""
    lines = ['## Types', '']
    
    for e in enums:
        # Build a brief description from the first few values
        if e['values']:
            sample = ', '.join(e['values'][:3])
            desc = f"Pipeline states ({sample}, ...)" if 'Status' in e['name'] else \
                   f"Hash algorithms ({', '.join(e['values'][1:])})" if 'Checksum' in e['name'] else \
                   f"Logging levels ({', '.join(e['values'][1:])})" if 'Level' in e['name'] else \
                   f"Enum with values: {', '.join(e['values'])}"
        else:
            desc = f"{e['name']} enum"
        
        # Link to Doxygen page (status_8hpp.html contains all enums from status.hpp)
        lines.append(f'- **{e["name"]}** — {desc}')
    
    return '\n'.join(lines)

if __name__ == '__main__':
    header = sys.argv[1] if len(sys.argv) > 1 else 'src/common/cpp/status.hpp'
    enums = parse_enums(header)
    print(generate_section(enums))
