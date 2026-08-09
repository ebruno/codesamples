#!/usr/bin/env bash

# generate_junit_report.sh
# Purpose: Parse test results from logs and generate a JUnit XML report.
# Usage: generate_junit_report.sh [logs_dir] [output_file]

usage() {
    echo "Usage: generate_junit_report.sh [logs_dir] [output_file]"
    exit 1
}

logs_dir=${1:-"logs"}
output_file=${2:-"reports/regression_report_junit.xml"}

if [ ! -d "$logs_dir" ]; then
    echo "Error: Logs directory $logs_dir not found."
    exit 1
fi

# Ensure reports directory exists
mkdir -p "$(dirname "$output_file")"

# Define the test matrix
tests=("T001" "T002" "T003" "T004" "T005" "T006" "T007")

# Start JUnit XML
echo '<?xml version="1.0" encoding="UTF-8"?>' > "$output_file"
echo '<testsuites>' >> "$output_file"
echo '  <testsuite name="RingBufferRegression" tests="'${#tests[@]}'"> ' >> "$output_file"

for test_id in "${tests[@]}"; do
    # Convert T001 to t001 using tr
    lower_id=$(echo "$test_id" | tr '[:upper:]' '[:lower:]')
    log_file="$logs_dir/${lower_id}.log"
    
    status="PASS"
    time="0.001"
    
    if [ ! -f "$log_file" ]; then
        status="FAIL"
        message="Log file not found"
    else
        if grep -qi "ERROR\|FAIL" "$log_file"; then
            status="FAIL"
            message=$(grep -m 1 "ERROR\|FAIL" "$log_file")
        fi
        # Try to extract time from log if present, otherwise use default
        exec_time=$(grep "Execution Time:" "$log_file" | awk '{print $3}')
        if [ -n "$exec_time" ]; then
            time=$exec_time
        fi
    fi

    if [ "$status" == "PASS" ]; then
        echo "    <testcase name=\"$test_id\" time=\"$time\" />" >> "$output_file"
    else
        echo "    <testcase name=\"$test_id\" time=\"$time\">" >> "$output_file"
        echo "      <failure message=\"$message\" />" >> "$output_file"
        echo "    </testcase>" >> "$output_file"
    fi
done

echo '  </testsuite>' >> "$output_file"
echo '</testsuites>' >> "$output_file"
