#!/usr/bin/env bash
# generate_junit_report.sh - Generate JUnit XML report for Python regression tests
# Handles both Concurrent and Pure Python harness results
# Log file naming: t001_concurrent.log, T001_concurrent.exit, t001_pure.log, T001_pure.exit
# Usage: generate_junit_report.sh [-l logs_dir] [-o output_file] [-h]

set -euo pipefail

# Version check (Bash 5.0+)
major=${BASH_VERSION%%.*}
minor=${BASH_VERSION#*.}
minor=${minor%%.*}
if (( major < 5 || (major == 5 && minor < 0) )); then
    echo "ERROR: Bash version 5.0 or higher is required (current: $BASH_VERSION)" >&2
    exit 1
fi

# Defaults
logs_dir="logs"
output_file="reports/python/per_os/python_regression_report_junit.xml"

# Parse options
while getopts "l:o:h" opt; do
    case $opt in
        l) logs_dir=$OPTARG ;;
        o) output_file=$OPTARG ;;
        h) echo "Usage: generate_junit_report.sh [-l logs_dir] [-o output_file]"
           echo "  -l logs_dir   Directory containing test log files (default: logs)"
           echo "  -o output_file Output JUnit XML file path (default: reports/python/per_os/python_regression_report_junit.xml)"
           echo "  -h            Display this help"
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

# Expected exit codes per test (authoritative mapping)
declare -A test_expected_exit=(
    [T001]=0
    [T002]=0
    [T003]=0
    [T004]=0
    [T005]=1
    [T006]=0
    [T007]=0
)

# Harness types to check (order matters for report ordering)
harnesses=("concurrent" "pure")

# Start XML document
cat > "$output_file" << 'HEADER'
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="Python Ringbuffer Test Suite" tests="__TOTAL_TESTS__" failures="__TOTAL_FAILURES__" errors="__TOTAL_ERRORS__" time="__TOTAL_TIME__">
HEADER

total_tests=0
total_failures=0
total_errors=0
total_time_ms=0

# Process each harness type, then each test number
for harness in "${harnesses[@]}"; do
    # Check if any log files exist for this harness
    has_logs=false
    for test_num in 001 002 003 004 005 006 007; do
        if [ -f "$logs_dir/t${test_num}_${harness}.log" ]; then
            has_logs=true
            break
        fi
    done
    
    # Skip harness if no logs found (e.g., concurrent skipped on FreeBSD 14)
    if [ "$has_logs" = false ]; then
        continue
    fi
    
    for test_num in 001 002 003 004 005 006 007; do
        test_id="T${test_num}"
        log_file="$logs_dir/t${test_num}_${harness}.log"
        
        # Skip if no log file for this test
        if [ ! -f "$log_file" ]; then
            continue
        fi
        
        total_tests=$((total_tests + 1))
        
        # Get test description with harness suffix
        description="${test_descriptions[$test_id]:-Unknown} (${harness})"
        
        # Determine exit code (companion .exit file takes precedence)
        exit_code_file="$logs_dir/${test_id}_${harness}.exit"
        if [ -f "$exit_code_file" ]; then
            exit_code=$(cat "$exit_code_file")
        else
            # Fallback: check log for error patterns (bash builtins only)
            exit_code=0
            while IFS= read -r line || [[ -n "$line" ]]; do
                if [[ "$line" == *"ERROR:"* ]] || [[ "$line" == *"FAIL"* ]]; then
                    exit_code=1
                    break
                fi
            done < "$log_file" 2>/dev/null || true
        fi
        
        # Get execution time in milliseconds (companion .time file)
        time_file="$logs_dir/${test_id}_${harness}.time"
        exec_time_ms="0"
        if [ -f "$time_file" ]; then
            exec_time_ms=$(cat "$time_file")
        fi
        
        # Convert to seconds for JUnit (with millisecond precision) — bash printf, no awk
        exec_time_sec=$(printf "%d.%03d" "$((exec_time_ms / 1000))" "$((exec_time_ms % 1000))")
        total_time_ms=$((total_time_ms + exec_time_ms))
        
        # Determine pass/fail based on expected exit code
        expected_exit="${test_expected_exit[$test_id]:-0}"
        
        # Build test case name with harness suffix
        testcase_name="${test_id}_${harness}"
        
        if [ "$exit_code" -eq "$expected_exit" ]; then
            # Test passed
            cat >> "$output_file" << EOF
  <testcase name="$testcase_name" classname="ringbuffer.python.${harness}" time="$exec_time_sec">
  </testcase>
EOF
        else
            # Test failed
            total_failures=$((total_failures + 1))
            
            # Capture error output from log (bash builtins, no grep/head)
            error_output=""
            _line_count=0
            while IFS= read -r line || [[ -n "$line" ]]; do
                if [[ "$line" == *"ERROR:"* ]] && [[ -z "$error_output" ]]; then
                    error_output="$line"
                fi
                if (( _line_count < 5 )); then
                    [[ -z "$error_output" ]] && error_output="${error_output:+$error_output
}$line"
                fi
                (( _line_count++ )) || true
            done < "$log_file" 2>/dev/null || true
            
            # Escape XML special characters (bash parameter expansion)
            error_output="${error_output//&/&amp;}"
            error_output="${error_output//</&lt;}"
            error_output="${error_output//>/&gt;}"
            
            cat >> "$output_file" << EOF
  <testcase name="$testcase_name" classname="ringbuffer.python.${harness}" time="$exec_time_sec">
    <failure message="Expected exit code $expected_exit, got $exit_code" type="AssertionError">
${error_output}
    </failure>
  </testcase>
EOF
        fi
    done
done

# Close XML document with totals substituted
cat >> "$output_file" << EOF
</testsuites>
EOF

# Replace placeholders with actual totals (bash builtins only, no sed)
# Read file into variable, do parameter expansion, write back
_report_content=$(cat "$output_file")
_report_content="${_report_content//__TOTAL_TESTS__/$total_tests}"
_report_content="${_report_content//__TOTAL_FAILURES__/$total_failures}"
_report_content="${_report_content//__TOTAL_ERRORS__/0}"
total_time_sec=$(printf "%d.%03d" "$((total_time_ms / 1000))" "$((total_time_ms % 1000))")
_report_content="${_report_content//__TOTAL_TIME__/$total_time_sec}"
echo "$_report_content" > "$output_file"

echo "JUnit report generated: $output_file"
echo "Total tests: $total_tests, Failures: $total_failures, Total time: ${total_time_sec}s"
