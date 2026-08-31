#!/usr/bin/env bash
# aggregate_junit.sh - Merge all per-OS JUnit XML reports into a single aggregated report
# Usage: ./utils/bin/aggregate_junit.sh [workspace_root]
#
# Scans reports/<lang>/per_os/*_regression_report_junit.xml files and merges them
# into reports/junit/aggregated.xml with os/lang attributes on each <testcase>.
# Also generates reports/junit/aggregated.html for browser viewing.

set -euo pipefail

WORKSPACE="${1:-.}"
REPORTS_DIR="$WORKSPACE/reports"
JUNIT_DIR="$REPORTS_DIR/junit"

# Create output directory
mkdir -p "$JUNIT_DIR"

OUTPUT_XML="$JUNIT_DIR/aggregated.xml"
OUTPUT_HTML="$JUNIT_DIR/aggregated.html"

echo "=== Aggregating JUnit reports ==="
echo "Workspace: $WORKSPACE"

# Collect all JUnit files with their language and OS into a JSON manifest
MANIFEST=$(mktemp)
trap 'rm -f "$MANIFEST"' EXIT

echo '[' > "$MANIFEST"
first=true
for lang in python java cpp; do
    per_os_dir="$REPORTS_DIR/$lang/per_os/junit"
    if [ -d "$per_os_dir" ]; then
        for junit_file in "$per_os_dir"/*_regression_report_junit.xml; do
            if [ -f "$junit_file" ]; then
                # Extract OS from filename: <os>_regression_report_junit.xml
                bname=$(basename "$junit_file")
                os_tag="${bname%%_regression_report_junit.xml}"

                if [ "$first" = true ]; then
                    first=false
                else
                    echo ',' >> "$MANIFEST"
                fi
                # Write JSON entry (no trailing comma)
                printf '  {"file": "%s", "lang": "%s", "os": "%s"}' "$junit_file" "$lang" "$os_tag" >> "$MANIFEST"
                echo "  Found: $junit_file (lang=$lang, os=$os_tag)"
            fi
        done
    fi
done
echo '' >> "$MANIFEST"
echo ']' >> "$MANIFEST"

if ! python3 -c "import json; d=json.load(open('$MANIFEST')); exit(0 if len(d)>0 else 1)"; then
    echo "No JUnit XML files found. Nothing to aggregate."
    # Create empty aggregated file
    cat > "$OUTPUT_XML" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="ringbuffer_aggregated" tests="0" failures="0" errors="0">
</testsuites>
EOF
    echo "Created empty aggregated.xml"
    exit 0
fi

# Merge all JUnit files using Python (handles XML properly)
export OUTPUT_XML
export OUTPUT_HTML
export MANIFEST_PATH="$MANIFEST"

python3 << 'PYTHON_SCRIPT'
import xml.etree.ElementTree as ET
from datetime import datetime
import sys
import os
import json

# Read manifest of JUnit files to aggregate
manifest_path = os.environ.get('MANIFEST_PATH', '')

with open(manifest_path) as f:
    manifest = json.load(f)

# Create root testsuites element
root = ET.Element('testsuites')
root.set('name', 'ringbuffer_aggregated')

total_tests = 0
total_failures = 0
total_errors = 0

for entry in manifest:
    junit_file = entry['file']
    lang = entry['lang']
    os_tag = entry['os']

    try:
        tree = ET.parse(junit_file)
        file_root = tree.getroot()

        # Get testsuites attributes from this file
        if file_root.tag == 'testsuites':
            file_tests = int(file_root.get('tests', 0))
            file_failures = int(file_root.get('failures', 0))
            file_errors = int(file_root.get('errors', 0))
        else:
            file_tests = 0
            file_failures = 0
            file_errors = 0

        total_tests += file_tests
        total_failures += file_failures
        total_errors += file_errors

        # Create a testsuite element for this OS/lang combination
        ts = ET.SubElement(root, 'testsuite')
        ts.set('name', f'{lang}_{os_tag}')
        ts.set('tests', str(file_tests))
        ts.set('failures', str(file_failures))
        ts.set('errors', str(file_errors))
        ts.set('timestamp', datetime.now().strftime('%Y-%m-%dT%H:%M:%S'))
        ts.set('os', os_tag)
        ts.set('lang', lang)

        # Copy all testcase elements from this file
        for testsuite in file_root:
            if testsuite.tag == 'testsuite':
                for testcase in testsuite:
                    if testcase.tag == 'testcase':
                        # Add os and lang attributes
                        testcase.set('os', os_tag)
                        testcase.set('lang', lang)
                        ts.append(testcase)

    except Exception as e:
        print(f"WARNING: Failed to parse {junit_file}: {e}", file=sys.stderr)

# Update root attributes
root.set('tests', str(total_tests))
root.set('failures', str(total_failures))
root.set('errors', str(total_errors))

# Write output XML with proper formatting
output_path = os.environ.get('OUTPUT_XML', 'reports/junit/aggregated.xml')
tree = ET.ElementTree(root)
ET.indent(tree, space="  ")
tree.write(output_path, encoding='unicode', xml_declaration=True)

print(f"Aggregated {len(manifest)} JUnit files into {output_path}")
print(f"Total: {total_tests} tests, {total_failures} failures, {total_errors} errors")
PYTHON_SCRIPT

# Generate HTML report from XML using Python (no external deps)
python3 << 'PYTHON_HTML'
import xml.etree.ElementTree as ET
import os

output_path = os.environ.get('OUTPUT_XML', 'reports/junit/aggregated.xml')
html_path = os.environ.get('OUTPUT_HTML', 'reports/junit/aggregated.html')

try:
    tree = ET.parse(output_path)
    root = tree.getroot()

    total_tests = int(root.get('tests', 0))
    total_failures = int(root.get('failures', 0))
    total_errors = int(root.get('errors', 0))

    html = []
    html.append('<!DOCTYPE html>')
    html.append('<html><head>')
    html.append('<title>Ringbuffer JUnit Report</title>')
    html.append('<style>')
    html.append('body { font-family: monospace; margin: 20px; }')
    html.append('table { border-collapse: collapse; width: 100%; }')
    html.append('th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }')
    html.append('th { background-color: #4CAF50; color: white; }')
    html.append('.pass { color: green; }')
    html.append('.fail { color: red; font-weight: bold; }')
    html.append('.summary { background-color: #f0f0f0; padding: 15px; margin-bottom: 20px; border-radius: 5px; }')
    html.append('</style>')
    html.append('</head><body>')
    html.append('<h1>Ringbuffer JUnit Report</h1>')
    html.append(f'<div class="summary">')
    html.append(f'<strong>Total:</strong> {total_tests} tests, ')
    html.append(f'<span class="pass">{total_tests - total_failures - total_errors} passed</span>, ')
    html.append(f'<span class="fail">{total_failures + total_errors} failed</span>')
    html.append(f'</div>')

    # Group by OS
    os_groups = {}
    for ts in root:
        if ts.tag == 'testsuite':
            os_tag = ts.get('os', 'unknown')
            lang = ts.get('lang', 'unknown')
            if os_tag not in os_groups:
                os_groups[os_tag] = []
            os_groups[os_tag].append((ts, lang))

    for os_tag in sorted(os_groups.keys()):
        html.append(f'<h2>{os_tag}</h2>')
        html.append('<table>')
        html.append('<tr><th>Language</th><th>Test</th><th>Status</th><th>Time</th><th>Report</th></tr>')

        for ts, lang in os_groups[os_tag]:
            for tc in ts:
                if tc.tag == 'testcase':
                    name = tc.get('name', '?')
                    time_val = tc.get('time', '0.001')
                    has_failure = any(c.tag == 'failure' for c in tc)
                    status_class = 'fail' if has_failure else 'pass'
                    status_text = 'FAIL' if has_failure else 'PASS'

                    html.append(f'<tr>')
                    html.append(f'<td>{lang}</td>')
                    html.append(f'<td class="{status_class}">{name}</td>')
                    html.append(f'<td>{status_text}</td>')
                    html.append(f'<td>{time_val}s</td>')
                    report_md = f'{lang}/per_os/{os_tag}_regression.md'
                    html.append(f'<td><a href="{report_md}">Full report</a></td>')
                    html.append(f'</tr>')

        html.append('</table>')

    html.append('</body></html>')

    with open(html_path, 'w') as f:
        f.write('\n'.join(html))

    print(f"HTML report generated: {html_path}")
except Exception as e:
    print(f"WARNING: Failed to generate HTML report: {e}", file=sys.stderr)
PYTHON_HTML

echo ""
echo "=== Aggregation complete ==="
echo "XML: $OUTPUT_XML"
if [ -f "$OUTPUT_HTML" ]; then
    echo "HTML: $OUTPUT_HTML (open in browser)"
fi
