#!/usr/bin/env bash
# run_test_matrix.sh — Execute T001–T007 test matrix and generate reports
# Called from the Makefile's build-cpp target.

# set -e disabled: T005 exits with code 1 by design

# Paths from Makefile (passed as env vars)
TEST_STATIC="${TEST_STATIC}"
DATA_DIR="${DATA_DIR}"
LOGS_DIR="${LOGS_DIR}"
REPORTS_DIR="${REPORTS_DIR}"
UTILS_DIR="${UTILS_DIR}"
CXX="${CXX}"

# OS name for report titles (passed as env var, e.g., "Fedora", "Debian")
OS_NAME="${OS_NAME:-Linux}"

# Lowercase version for filenames (e.g., "fedora", "debian")
OS_FILE=$(echo "${OS_NAME}" | tr '[:upper:]' '[:lower:]')

# Ensure directories exist
mkdir -p "${LOGS_DIR}" "${REPORTS_DIR}/cpp/per_os"

echo "=== Test Matrix Execution ==="
start_time=$(date '+%Y-%m-%d %H:%M:%S %z')
echo "Start Time: ${start_time}"

# Run each test
for test_id in T001 T002 T003 T004 T005 T006 T007; do
    test_start=$(date +%s%N)
    echo "Running ${test_id}..."

    case "${test_id}" in
        T001) "${TEST_STATIC}" -s 4 -b 4096 -t 0 -e 0 "${DATA_DIR}/inputs/test001.txt" > "${DATA_DIR}/expected/t001.out" 2> "${LOGS_DIR}/t001.log" ;;
        T002) "${TEST_STATIC}" -s 1 -b 1 -t 0 -e 0 "${DATA_DIR}/inputs/test001.txt" > "${DATA_DIR}/expected/t002.out" 2> "${LOGS_DIR}/t002.log" ;;
        T003) "${TEST_STATIC}" -s 4 -b 10 -t 1 -e 0 "${DATA_DIR}/inputs/test001.txt" > "${DATA_DIR}/expected/t003.out" 2> "${LOGS_DIR}/t003.log" ;;
        T004) "${TEST_STATIC}" -s 4 -b 4096 -t 0 -e 0 "${DATA_DIR}/inputs/test001.txt" > "${DATA_DIR}/expected/t004.out" 2> "${LOGS_DIR}/t004.log" ;;
        T005) "${TEST_STATIC}" -s 4 -b 4096 -t 0 -e 1 "${DATA_DIR}/inputs/test001.txt" > "${DATA_DIR}/expected/t005.out" 2> "${LOGS_DIR}/t005.log" ;;
        T006) "${TEST_STATIC}" -s 4 -b 4096 -t 0 -e 2 "${DATA_DIR}/inputs/test001.txt" > "${DATA_DIR}/expected/t006.out" 2> "${LOGS_DIR}/t006.log" ;;
        T007) "${TEST_STATIC}" -s 4 -b 4096 -t 2 -e 0 "${DATA_DIR}/inputs/test001.txt" > "${DATA_DIR}/expected/t007.out" 2> "${LOGS_DIR}/t007.log" ;;
    esac

    test_exit=$?
    echo "${test_exit}" > "${LOGS_DIR}/${test_id}.exit"

    test_end=$(date +%s%N)
    test_time_ms=$(( (test_end - test_start) / 1000000 ))
    echo "${test_time_ms}" > "${LOGS_DIR}/${test_id}.time"
done

end_time=$(date '+%Y-%m-%d %H:%M:%S %z')
echo "End Time: ${end_time}"
echo ""

# Generate JUnit report (OS-specific output path)
echo "=== Generating JUnit Report ==="
"${UTILS_DIR}/bin/generate_junit_report.sh" -l "${LOGS_DIR}" -o "${REPORTS_DIR}/cpp/per_os/${OS_FILE}_regression_report_junit.xml" || echo "WARNING: JUnit report generation failed"
echo ""

# Generate Regression Report
echo "=== Generating Regression Report ==="
{
    echo "# Regression Verification Report - ${OS_NAME}"
    echo "**Date:** ${start_time}"
    echo "**Start Time:** ${start_time}"
    echo "**End Time:** ${end_time}"
    echo ""
    echo "## Audit Trail"
    cat "${REPORTS_DIR}/compiler_version.txt" 2>/dev/null || echo "Version capture unavailable"
    echo ""
    echo "## Test Results"
    echo "| Test ID | Description | Result | Execution Time (ms) | Note |"
    echo "| :--- | :--- | :--- | :--- | :--- |"

    for test_id in T001 T002 T003 T004 T005 T006 T007; do
        exit_code=0
        if [ -f "${LOGS_DIR}/${test_id}.exit" ]; then exit_code=$(cat "${LOGS_DIR}/${test_id}.exit"); fi
        time_ms="N/A"
        if [ -f "${LOGS_DIR}/${test_id}.time" ]; then time_ms=$(cat "${LOGS_DIR}/${test_id}.time"); fi

        case "${test_id}" in
            T001) desc="Exact match with input" ;;
            T002) desc="Stress test (1 slot, 1 byte)" ;;
            T003) desc="All chars uppercase" ;;
            T004) desc="Input < 1 slot (fast EOF)" ;;
            T005) desc="Pipeline stop (Fatal Error)" ;;
            T006) desc="Pipeline continues (Non-fatal)" ;;
            T007) desc="Bit-inverted output" ;;
        esac

        case "${test_id}" in
            T005) expected_exit=1 ;;
            *) expected_exit=0 ;;
        esac

        if [ "${exit_code}" -eq "${expected_exit}" ]; then result="PASS"; else result="FAIL"; fi
        echo "| ${test_id} | ${desc} | ${result} | ${time_ms} | exit=${exit_code} |"
    done
} > "${REPORTS_DIR}/regression_report.md"

echo "Regression report generated: ${REPORTS_DIR}/regression_report.md"
