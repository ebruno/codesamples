#!/usr/bin/env bash
# generate_junit_report.sh - Generate JUnit XML report from test logs and exit codes
# Usage: generate_junit_report.sh [-l logs_dir] [-o output_file] [-h]
#
# Reads test log files (t001.log through t007.log) and companion exit code
# files (T001.exit through T007.exit) to determine pass/fail status.
# Also reads per-test timing files (T001.time through T007.time).
#
# Exit code files contain a single integer: 0 = pass, non-zero = fail.

set -euo pipefail

# Version check (Bash 5.0+)
major=${BASH_VERSION%%.*}
minor=${BASH_VERSION#*.}
minor=${minor%%.*}  # Extract only the numeric minor version
if (( major < 5 || (major == 5 && minor < 0) )); then
    echo "ERROR: Bash version 5.0 or higher is required (current: $BASH_VERSION)" >&2
    exit 1
fi

# Defaults
logs_dir="logs"
output_file="reports/regression_report_junit.xml"

# Parse options
while getopts "l:o:h" opt; do
    case $opt in
        l) logs_dir=$OPTARG ;;
        o) output_file=$OPTARG ;;
        h) echo "Usage: generate_junit_report.sh [-l logs_dir] [-o output_file]"
           echo "  -l logs_dir   Directory containing test log files (default: logs)"
           echo "  -o output_file Output JUnit XML file path (default: reports/regression_report_junit.xml)"
           echo "  -h            Display this help message"
           exit 0 ;;
        *) echo "Usage: generate_junit_report.sh [-l logs_dir] [-o output_file]" >&2; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

# Ensure output directory exists
output_dir=$(dirname "$output_file")
mkdir -p "$output_dir"

# Test descriptions (authoritative mapping)
declare -A test_descriptions=(
    [T001]="Exact match with input"
    [T002]="Stress test (1 slot, 1 byte)"
    [T003]="All chars uppercase"
    [T004]="Input < 1 slot (fast EOF)"
    [T005]="Pipeline stop (Fatal Error)"
    [T006]="Pipeline continues (Non-fatal)"
    [T007]="Bit-inverted output"
)

# Expected exit codes per test (T005 expects exit code 1 for fatal error)
declare -A expected_exit_codes=(
    [T001]=0
    [T002]=0
    [T003]=0
    [T004]=0
    [T005]=1
    [T006]=0
    [T007]=0
)

# Start XML document
cat > "$output_file" << 'HEADER'
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="Ringbuffer Test Suite" tests="" failures="" errors="" time="">
HEADER

total_tests=0
total_failures=0
total_errors=0
total_time_ms=0

# Process each test in order T001 through T007
for test_num in 001 002 003 004 005 006 007; do
    test_id="T${test_num}"
    
    # Skip if no log file exists for this test
    log_file="$logs_dir/t${test_num}.log"
    if [ ! -f "$log_file" ]; then
        continue
    fi
    
    # Get test description
    description="${test_descriptions[$test_id]:-Unknown test case}"
    
    # Determine exit code (companion .exit file takes precedence)
    exit_code_file="$logs_dir/${test_id}.exit"
    if [ -f "$exit_code_file" ]; then
        exit_code=$(cat "$exit_code_file")
    else
        # Fallback: check log for error patterns
        if grep -q "ERROR:" "$log_file" 2>/dev/null || grep -q "FAIL" "$log_file" 2>/dev/null; then
            exit_code=1
        else
            exit_code=0
        fi
    fi
    
    # Get execution time in milliseconds (companion .time file)
    time_file="$logs_dir/${test_id}.time"
    exec_time_ms="0"
    if [ -f "$time_file" ]; then
        exec_time_ms=$(cat "$time_file")
    fi
    
    # Convert to seconds for JUnit (with millisecond precision)
    exec_time_sec=$(awk "BEGIN {printf \"%.3f\", $exec_time_ms / 1000}")
    total_time_ms=$((total_time_ms + exec_time_ms))
    
    # Determine pass/fail based on expected exit code
    expected_exit="${expected_exit_codes[$test_id]:-0}"
    if [ "$exit_code" -eq "$expected_exit" ]; then
        # Test passed
        cat >> "$output_file" << EOF
  <testcase name="$test_id" classname="ringbuffer.test" time="$exec_time_sec">
  </testcase>
EOF
    else
        # Test failed - capture error output from log
        error_output=$(grep "ERROR:" "$log_file" 2>/dev/null | head -5 || echo "")
        if [ -z "$error_output" ]; then
            error_output=$(head -5 "$log_file" 2>/dev/null || echo "Unknown failure")
        fi
        # Escape XML special characters in error output
        escaped_output=$(echo "$error_output" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' | tr '\n' ' ')
        
        cat >> "$output_file" << EOF
  <testcase name="$test_id" classname="ringbuffer.test" time="$exec_time_sec">
    <failure message="Test $test_id failed (exit code: $exit_code)">${escaped_output}</failure>
  </testcase>
EOF
        total_failures=$((total_failures + 1))
    fi
    
    total_tests=$((total_tests + 1))
done

# Close XML document with summary attributes
cat >> "$output_file" << EOF
  <system-out>Total execution time: ${total_time_ms}ms</system-out>
</testsuites>
EOF

echo "JUnit report generated: $output_file"
echo "Total tests: $total_tests, Failures: $total_failures, Total time: ${total_time_ms}ms"
