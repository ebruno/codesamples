#!/usr/bin/env tcsh
# generate_junit_report.tcsh - Generate JUnit XML report from test logs and exit codes
# Usage: tcsh generate_junit_report.tcsh [-l logs_dir] [-o output_file] [-h]
#
# Reads test log files (t001.log through t007.log) and companion exit code
# files (T001.exit through T007.exit) to determine pass/fail status.
# Also reads per-test timing files (T001.time through T007.time).

# Defaults
set logs_dir = "logs"
set output_file = "reports/regression_report_junit.xml"

# Parse options using switch (tcsh idiom)
# NOTE: tcsh shift only shifts by 1, not by N like bash
while ( $#argv > 0 )
switch ( $1 )
case -l:
if ( $#argv > 1 ) then
set logs_dir = $2
shift
shift
else
echo "ERROR: -l requires an argument" >&2
exit 1
endif
breaksw
case -o:
if ( $#argv > 1 ) then
set output_file = $2
shift
shift
else
echo "ERROR: -o requires an argument" >&2
exit 1
endif
breaksw
case -h:
echo "Usage: tcsh generate_junit_report.tcsh [-l logs_dir] [-o output_file]"
echo "  -l logs_dir   Directory containing test log files (default: logs)"
echo "  -o output_file Output JUnit XML file path (default: reports/regression_report_junit.xml)"
echo "  -h            Display this help"
exit 0
default:
echo "Usage: tcsh generate_junit_report.tcsh [-l logs_dir] [-o output_file]" >&2
exit 1
endsw
end

# Ensure output directory exists
set output_dir = `dirname "$output_file"`
mkdir -p "$output_dir"

# Test descriptions (authoritative mapping)
set test_desc_001 = "Exact match with input"
set test_desc_002 = "Stress test (1 slot, 1 byte)"
set test_desc_003 = "All chars uppercase"
set test_desc_004 = "Input < 1 slot (fast EOF)"
set test_desc_005 = "Pipeline stop (Fatal Error)"
set test_desc_006 = "Pipeline continues (Non-fatal)"
set test_desc_007 = "Bit-inverted output"

# Expected exit codes per test (authoritative mapping)
set expected_001 = 0
set expected_002 = 0
set expected_003 = 0
set expected_004 = 0
set expected_005 = 1
set expected_006 = 0
set expected_007 = 0

# Start XML document (attributes populated at end)
set total_tests = 0
set total_failures = 0
set total_errors = 0
set total_time_ms = 0

# Write test results to temp file (header written after loop with actual values)
printf '' > "${output_file}.results"

# Process each test in order T001 through T007
foreach test_num ( 001 002 003 004 005 006 007 )
set test_id = "T${test_num}"

# Get test description (use if/else — tcsh switch case labels are glob patterns)
if ( $test_num == "001" ) then
set description = "$test_desc_001"
else if ( $test_num == "002" ) then
set description = "$test_desc_002"
else if ( $test_num == "003" ) then
set description = "$test_desc_003"
else if ( $test_num == "004" ) then
set description = "$test_desc_004"
else if ( $test_num == "005" ) then
set description = "$test_desc_005"
else if ( $test_num == "006" ) then
set description = "$test_desc_006"
else if ( $test_num == "007" ) then
set description = "$test_desc_007"
else
set description = "Unknown test case"
endif

# Skip if no log file exists for this test
set log_file = "${logs_dir}/t${test_num}.log"
if ( ! -f "$log_file" ) then
continue
endif

# Determine exit code (companion .exit file takes precedence)
# Check both uppercase T001.exit and lowercase t001.exit (Makefile uses lowercase)
set exit_code = 0
set exit_code_file = "${logs_dir}/${test_id}.exit"
if ( ! -f "$exit_code_file" ) then
set exit_code_file = "${logs_dir}/${test_id:l}.exit"
endif
if ( -f "$exit_code_file" ) then
set exit_code = `cat "$exit_code_file"`
endif

# Get execution time in milliseconds (companion .time file)
# Check both uppercase and lowercase
set exec_time_ms = 0
set time_file = "${logs_dir}/${test_id}.time"
if ( ! -f "$time_file" ) then
set time_file = "${logs_dir}/${test_id:l}.time"
endif
if ( -f "$time_file" ) then
set exec_time_ms = `cat "$time_file"`
endif

# Convert to seconds for JUnit (with millisecond precision) — tcsh @ operator
@ exec_time_sec_s = $exec_time_ms / 1000
@ exec_time_sec_ms = $exec_time_ms % 1000
set exec_time_sec = `printf "%d.%03d" $exec_time_sec_s $exec_time_sec_ms`
@ total_time_ms = $total_time_ms + $exec_time_ms

# Determine pass/fail based on expected exit code (use if/else — tcsh switch case labels are glob patterns)
if ( $test_num == "001" ) then
set expected = $expected_001
else if ( $test_num == "002" ) then
set expected = $expected_002
else if ( $test_num == "003" ) then
set expected = $expected_003
else if ( $test_num == "004" ) then
set expected = $expected_004
else if ( $test_num == "005" ) then
set expected = $expected_005
else if ( $test_num == "006" ) then
set expected = $expected_006
else if ( $test_num == "007" ) then
set expected = $expected_007
else
set expected = 0
endif

if ( "$exit_code" == "$expected" ) then
# Test passed - write to results temp file
printf '  <testcase name="%s" classname="ringbuffer.test" time="%s">\n' "$test_id" "$exec_time_sec" >> "${output_file}.results"
printf '  </testcase>\n' >> "${output_file}.results"
else
# Test failed - capture error output from log (tcsh builtins, no grep/head)
set error_output = "Unknown failure"
# Read first 5 lines using sed (allowed in Makefile recipes)
set line1 = `sed -n '1p' "$log_file"`
set line2 = `sed -n '2p' "$log_file"`
set line3 = `sed -n '3p' "$log_file"`
set line4 = `sed -n '4p' "$log_file"`
set line5 = `sed -n '5p' "$log_file"`

# Build error output from non-empty lines (use $#var > 0 for length check)
if ( $#line1 > 0 ) then
set error_output = "$line1"
endif
if ( $#line2 > 0 ) then
set error_output = "${error_output} ${line2}"
endif
if ( $#line3 > 0 ) then
set error_output = "${error_output} ${line3}"
endif
if ( $#line4 > 0 ) then
set error_output = "${error_output} ${line4}"
endif
if ( $#line5 > 0 ) then
set error_output = "${error_output} ${line5}"
endif

# Escape XML special characters in error output
# NOTE: tcsh lacks native string replacement; using sed (allowed per .bionic tcsh exception)
set escaped_output = "$error_output"
echo "$escaped_output" | sed "s/\&/\\&amp;/g" > /tmp/_esc.tmp
mv /tmp/_esc.tmp "$escaped_output"
echo "$escaped_output" | sed "s/</\\&lt;/g" > /tmp/_esc.tmp
mv /tmp/_esc.tmp "$escaped_output"
echo "$escaped_output" | sed "s/>/\\&gt;/g" > /tmp/_esc.tmp
mv /tmp/_esc.tmp "$escaped_output"

printf '  <testcase name="%s" classname="ringbuffer.test" time="%s">\n' "$test_id" "$exec_time_sec" >> "${output_file}.results"
printf '    <failure message="Test %s failed (exit code: %s)">%s</failure>\n' "$test_id" "$exit_code" "$escaped_output" >> "${output_file}.results"
printf '  </testcase>\n' >> "${output_file}.results"
@ total_failures++
endif

@ total_tests++
end

# Close XML document with summary attributes
@ total_time_sec_s = $total_time_ms / 1000
@ total_time_sec_ms = $total_time_ms % 1000
set total_time_sec = `printf "%d.%03d" $total_time_sec_s $total_time_sec_ms`

# Write final XML with actual values (no sed/awk needed)
printf '<?xml version="1.0" encoding="UTF-8"?>\n' > "$output_file"
printf '<testsuites name="Ringbuffer Test Suite" tests="%s" failures="%s" errors="%s" time="%s">\n' "$total_tests" "$total_failures" "$total_errors" "$total_time_sec" >> "$output_file"
cat "${output_file}.results" >> "$output_file"
rm -f "${output_file}.results"

printf '  <system-out>Total execution time: %sms</system-out>\n' "$total_time_ms" >> "$output_file"
printf '</testsuites>\n' >> "$output_file"

echo "JUnit report generated: $output_file"
echo "Total tests: $total_tests, Failures: $total_failures, Total time: ${total_time_ms}ms"
