#!/usr/bin/env tcsh
# generate_junit_report.tcsh - Generate JUnit XML report for Python regression tests
# Handles both Concurrent and Pure Python harness results
# Log file naming: t001_concurrent.log, T001_concurrent.exit, t001_pure.log, T001_pure.exit
# Usage: generate_junit_report.tcsh [-l logs_dir] [-o output_file]

set logs_dir = "logs"
set output_file = "reports/python/per_os/python_regression_report_junit.xml"

# Parse options (tcsh has no getopts, use goto/labels for loop)
set parse_done = 0
parse_loop:
    if ( $#argv < 1 ) goto parse_end
    set opt = "$argv[1]"
    switch ( $opt )
        case "-l":
            set logs_dir = "$argv[2]"
            shift argv; shift argv
            breaksw
        case "-o":
            set output_file = "$argv[2]"
            shift argv; shift argv
            breaksw
        case "-h":
            echo "Usage: generate_junit_report.tcsh [-l logs_dir] [-o output_file]"
            echo "  -l logs_dir   Directory containing test log files (default: logs)"
            echo "  -o output_file Output JUnit XML file path"
            exit 0
        default:
            set parse_done = 1
    endsw
    if ( ! $parse_done ) goto parse_loop
parse_end:

# Ensure output directory exists
set output_dir = `dirname "$output_file"`
if ( ! -d "$output_dir" ) then
    mkdir -p "$output_dir"
endif

# Counters
set total_tests = 0
set total_failures = 0
set total_time_ms = 0

# Expected exit codes per test (T005 expects 1, all others expect 0)
set test_expected_exit = ( 0 0 0 0 1 0 0 )

# Harness types to check (order matters for report ordering)
set harnesses = ( concurrent pure )

# Create XML template file using unquoted heredoc (tcsh doesn't support quoted markers)
cat > /tmp/junit_template.xml << TMPL
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="__NAME__" tests="__TOTAL_TESTS__" failures="__TOTAL_FAILURES__" errors="0" time="__TOTAL_TIME__">
</testsuites>
TMPL

# Create test case template files using unquoted heredoc
cat > /tmp/junit_testcase_pass.xml << TMPL
  <testcase name="__TESTCASE_NAME__" classname="ringbuffer.python.__HARNESS__" time="__TIME_STR__">
  </testcase>
TMPL

cat > /tmp/junit_testcase_fail.xml << TMPL
  <testcase name="__TESTCASE_NAME__" classname="ringbuffer.python.__HARNESS__" time="__TIME_STR__">
    <failure message="Expected exit code __EXPECTED__, got __ACTUAL__" type="AssertionError">
__ERROR_OUTPUT__
    </failure>
  </testcase>
TMPL

# Process each harness type, then each test number
foreach harness ( $harnesses )
    # Check if any log files exist for this harness
    set has_logs = 0
    foreach test_num ( 001 002 003 004 005 006 007 )
        if ( -f "${logs_dir}/t${test_num}_${harness}.log" ) then
            set has_logs = 1
            break
        endif
    end

    # Skip harness if no logs found (e.g., concurrent skipped on FreeBSD 14)
    if ( ! $has_logs ) then
        continue
    endif

    foreach test_num ( 001 002 003 004 005 006 007 )
        # Get index (test_num - 1) for array access — tcsh arrays are 1-indexed
        @ idx = $test_num - 1

        set test_id = "T${test_num}"
        set log_file = "${logs_dir}/t${test_num}_${harness}.log"

        # Skip if no log file for this test
        if ( ! -f "$log_file" ) then
            continue
        endif

        @ total_tests++

        # Determine pass/fail based on expected exit code
        set expected_exit = $test_expected_exit[$idx]

        # Build test case name with harness suffix
        set testcase_name = "${test_id}_${harness}"

        # Determine exit code (companion .exit file takes precedence)
        set exit_code_file = "${logs_dir}/${test_id}_${harness}.exit"
        if ( -f "$exit_code_file" ) then
            set exit_code = `cat "$exit_code_file"`
        else
            # Fallback: check log for error patterns (tcsh has no grep, use builtin)
            set exit_code = 0
            if ( -f "$log_file" ) then
                foreach line ( `cat "$log_file"` )
                    if ( $line =~ *ERROR:* || $line =~ *FAIL* ) then
                        set exit_code = 1
                        break
                    endif
                end
            endif
        endif

        # Get execution time in milliseconds (companion .time file)
        set exec_time_ms = 0
        set time_file = "${logs_dir}/${test_id}_${harness}.time"
        if ( -f "$time_file" ) then
            set exec_time_ms = `cat "$time_file"`
        endif

        # Convert to seconds for JUnit (with millisecond precision) — tcsh @ arithmetic
        # NOTE: ${var:03d} is tcsh 6.24+ only; FreeBSD 14 has tcsh 6.22 — use printf
        @ exec_time_sec_int = $exec_time_ms / 1000
        @ exec_time_ms_frac = $exec_time_ms % 1000
        set time_str = `printf "%d.%03d" $exec_time_sec_int $exec_time_ms_frac`

        if ( $exit_code == $expected_exit ) then
            # Test passed — read template, replace placeholders with sed, append to output
            cat /tmp/junit_testcase_pass.xml | \
                sed "s/__TESTCASE_NAME__/$testcase_name/g" | \
                sed "s/__HARNESS__/$harness/g" | \
                sed "s/__TIME_STR__/$time_str/g" >> "$output_file"
        else
            # Test failed
            @ total_failures++

            # Capture error output from log (tcsh builtin, no grep/head)
            set error_output = ""
            set line_count = 0
            if ( -f "$log_file" ) then
                foreach line ( `cat "$log_file"` )
                    if ( $line =~ *ERROR:* && "$error_output" == "" ) then
                        set error_output = "$line"
                    endif
                    if ( $line_count < 5 ) then
                        if ( "$error_output" == "" ) then
                            set error_output = "$line"
                        else
                            set error_output = "${error_output}
${line}"
                        endif
                    endif
                    @ line_count++
                end
            endif

            # Escape XML special characters using sed (tcsh exception: external tools allowed)
            set error_output = `echo "$error_output" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'`

            # Read template, replace placeholders with sed, append to output
            cat /tmp/junit_testcase_fail.xml | \
                sed "s/__TESTCASE_NAME__/$testcase_name/g" | \
                sed "s/__HARNESS__/$harness/g" | \
                sed "s/__TIME_STR__/$time_str/g" | \
                sed "s/__EXPECTED__/$expected_exit/g" | \
                sed "s/__ACTUAL__/$exit_code/g" | \
                sed "s|__ERROR_OUTPUT__|$error_output|g" >> "$output_file"
        endif

        @ total_time_ms += $exec_time_ms
    end
end

# Copy template to output, then replace totals using sed (tcsh exception: external tools allowed)
cp /tmp/junit_template.xml "$output_file"

# Calculate total time in seconds
@ total_time_sec_int = $total_time_ms / 1000
@ total_time_ms_frac = $total_time_ms % 1000
set total_time_str = `printf "%d.%03d" $total_time_sec_int $total_time_ms_frac`

# Replace placeholders with actual totals using sed
sed -i '' "s/__TOTAL_TESTS__/$total_tests/g" "$output_file"
sed -i '' "s/__TOTAL_FAILURES__/$total_failures/g" "$output_file"
sed -i '' "s/__TOTAL_TIME__/$total_time_str/g" "$output_file"

# Clean up temp files
rm -f /tmp/junit_template.xml /tmp/junit_testcase_pass.xml /tmp/junit_testcase_fail.xml

echo "JUnit report generated: $output_file"
echo "Total tests: $total_tests, Failures: $total_failures, Total time: ${total_time_str}s"
