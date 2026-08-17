#!/usr/bin/env zsh

# generate_junit_report.zsh - Generate JUnit XML report from test logs and exit codes
# Usage: generate_junit_report.zsh [-l logs_dir] [-o output_file] [-h]
#
# Reads test log files (t001.log through t007.log) and companion exit code
# files (T001.exit through T007.exit) to determine pass/fail status.
# Also reads per-test timing files (T001.time through T007.time).
#
# Exit code files contain a single integer: 0 = pass, non-zero = fail.

# Version Check
major=${ZSH_VERSION%%.*}
minor=${ZSH_VERSION#*.}
minor=${minor%%.*}

if (( major < 5 || ( major == 5 && minor < 8 ) )); then
    echo "Error: Zsh version 5.8 or higher is required." >&2
    exit 1
fi

usage() {
    echo "Usage: $(basename $0) [-l logs_dir] [-o output_file]"
    echo "  -l logs_dir   Directory containing test log files (default: logs)"
    echo "  -o output_file Output JUnit XML file path (default: reports/regression_report_junit.xml)"
    echo "  -h            Display this help message"
    exit 0
}

# Defaults
logs_dir="logs"
output_file="reports/regression_report_junit.xml"

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        -l) logs_dir=$2; shift 2 ;;
        -o) output_file=$2; shift 2 ;;
        -h) usage ;;
        *) echo "Error: Unknown option $1" >&2; exit 1 ;;
    esac
done

# Ensure output directory exists
output_dir=${output_file:h}
mkdir -p "$output_dir"

# Test descriptions (authoritative mapping)
local -A test_descriptions=(
    [T001]="Exact match with input"
    [T002]="Stress test (1 slot, 1 byte)"
    [T003]="All chars uppercase"
    [T004]="Input < 1 slot (fast EOF)"
    [T005]="Pipeline stop (Fatal Error)"
    [T006]="Pipeline continues (Non-fatal)"
    [T007]="Bit-inverted output"
)

# Expected exit codes per test (authoritative mapping)
# T005 expects exit=1 (fatal error mode); all others expect exit=0
local -A test_expected_exit=(
    [T001]=0
    [T002]=0
    [T003]=0
    [T004]=0
    [T005]=1
    [T006]=0
    [T007]=0
)

# Start XML document (attributes populated at end)
{
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<testsuites name="Ringbuffer Test Suite" tests="__TOTAL_TESTS__" failures="__TOTAL_FAILURES__" errors="__TOTAL_ERRORS__" time="__TOTAL_TIME__">'
} > "$output_file"

total_tests=0
total_failures=0
total_errors=0
total_time_ms=0

# Process each test in order T001 through T007
for test_num in 001 002 003 004 005 006 007; do
    test_id="T${test_num}"
    
    # Skip if no log file exists for this test
    log_file="${logs_dir}/t${test_num}.log"
    if [[ ! -f "$log_file" ]]; then
        continue
    fi
    
    # Get test description
    description="${test_descriptions[$test_id]:-Unknown test case}"
    
    # Determine exit code (companion .exit file takes precedence)
    exit_code_file="${logs_dir}/${test_id}.exit"
    if [[ -f "$exit_code_file" ]]; then
        exit_code=$(<"$exit_code_file")
    else
        # Fallback: check log for error patterns
        if grep -q "ERROR:" "$log_file" 2>/dev/null || grep -q "FAIL" "$log_file" 2>/dev/null; then
            exit_code=1
        else
            exit_code=0
        fi
    fi
    
    # Get execution time in milliseconds (companion .time file)
    time_file="${logs_dir}/${test_id}.time"
    exec_time_ms=0
    if [[ -f "$time_file" ]]; then
        exec_time_ms=$(<"$time_file")
    fi
    
    # Convert to seconds for JUnit (with millisecond precision)
    exec_time_sec=$(printf "%.3f" "$exec_time_ms / 1000")
    total_time_ms=$((total_time_ms + exec_time_ms))
    
    # Determine pass/fail based on expected exit code
    expected_exit="${test_expected_exit[$test_id]:-0}"
    if [[ "$exit_code" -eq "$expected_exit" ]]; then
        # Test passed
        {
            echo "  <testcase name=\"$test_id\" classname=\"ringbuffer.test\" time=\"$exec_time_sec\">"
            echo "  </testcase>"
        } >> "$output_file"
    else
        # Test failed - capture error output from log
        local error_output=""
        if grep -q "ERROR:" "$log_file" 2>/dev/null; then
            error_output=$(grep "ERROR:" "$log_file" | head -5)
        else
            error_output=$(head -5 "$log_file")
        fi
        # Escape XML special characters in error output
        local escaped_output="${error_output//&/\&amp;}"
        escaped_output="${escaped_output//</\&lt;}"
        escaped_output="${escaped_output//>/\&gt;}"
        escaped_output="${escaped_output//$'\n'/ }"
        
        {
            echo "  <testcase name=\"$test_id\" classname=\"ringbuffer.test\" time=\"$exec_time_sec\">"
            echo "    <failure message=\"Test $test_id failed (exit code: $exit_code)\">${escaped_output}</failure>"
            echo "  </testcase>"
        } >> "$output_file"
        total_failures=$((total_failures + 1))
    fi
    
    total_tests=$((total_tests + 1))
done

# Close XML document with summary attributes
total_time_sec=$(printf "%.3f" "$total_time_ms / 1000")

# Replace placeholder values in the header with actual totals
sed -i '' "s/__TOTAL_TESTS__/$total_tests/; s/__TOTAL_FAILURES__/$total_failures/; s/__TOTAL_ERRORS__/$total_errors/; s/__TOTAL_TIME__/$total_time_sec/" "$output_file"

{
    echo "  <system-out>Total execution time: ${total_time_ms}ms</system-out>"
    echo '</testsuites>'
} >> "$output_file"

echo "JUnit report generated: $output_file"
echo "Total tests: $total_tests, Failures: $total_failures, Total time: ${total_time_ms}ms"
