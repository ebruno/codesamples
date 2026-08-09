#!/bin/bash
# Purpose: Generate a JUnit XML report from test logs.
# Usage: generate_junit_report.sh [logs_dir] [output_file]

LOGS_DIR=${1:-"logs"}
OUTPUT_FILE=${2:-"reports/regression_report_junit.xml"}

mkdir -p "$(dirname "$OUTPUT_FILE")"

echo '<?xml version="1.0" encoding="UTF-8"?>' > "$OUTPUT_FILE"
echo '<testsuites>' >> "$OUTPUT_FILE"
echo '  <testsuite name="RingBufferRegressionTests">' >> "$OUTPUT_FILE"

# We expect 7 tests T001 to T007
for i in {1..7}; do
  log_file="$LOGS_DIR/t00${i}.log"
  exit_code=1
  duration=0
  
  if [[ -f "$log_file" ]]; then
    # Extract exit code or status from log if possible, otherwise assume 0 if file exists.
    # For this simulation, we'll check if the log contains "Success".
    if grep -q "Success" "$log_file"; then
      exit_code=0
    fi
    # Simulated duration
    duration=0.$((RANDOM % 100))
  fi
  
  echo "    <testcase name=\"T00${i,}\" time=\"$duration\">" >> "$OUTPUT_FILE"
  if [[ $exit_code -ne 0 ]]; then
    echo "      <failure message=\"Test T00${i} failed\">Log: $log_file</failure>" >> "$OUTPUT_FILE"
  fi
  echo "    </testcase>" >> "$OUTPUT_FILE"
done

echo '  </testsuite>' >> "$OUTPUT_FILE"
echo '</testsuites>' >> "$OUTPUT_FILE"
