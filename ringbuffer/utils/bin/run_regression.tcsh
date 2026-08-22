#!/usr/bin/env tcsh
# run_regression.tcsh — Execute regression tests on FreeBSD 14 via SSH
# This script runs ON THE REMOTE FreeBSD host using tcsh (the default shell)
# Usage: tcsh run_regression.tcsh <os> verify|build [image_override]

set target_os = "$1"
set action = "$2"

if ( "$target_os" == "" || "$action" == "" ) then
    echo "Usage: tcsh run_regression.tcsh <os> verify|build"
    exit 1
endif

if ( "$target_os" != "freebsd14" ) then
    echo "ERROR: This script only supports freebsd14. Got: $target_os"
    exit 1
endif

if ( "$action" != "verify" && "$action" != "build" ) then
    echo "ERROR: Unsupported action '$action'. Use 'verify' or 'build'"
    exit 1
endif

set remote_base = "$HOME/ringbuffer"
set os_dir = "${remote_base}/src/${target_os}/cpp"
set tests_dir = "${os_dir}/tests"

echo "============================================="
echo "Ringbuffer Regression Runner (FreeBSD 14)"
echo "  Target OS: ${target_os}"
echo "  Action:    ${action}"
echo "============================================="

# Validate directories exist
if ( ! -d "${os_dir}" ) then
    echo "ERROR: ${os_dir} does not exist."
    exit 1
endif

if ( ! -d "${tests_dir}" ) then
    echo "ERROR: ${tests_dir} does not exist."
    exit 1
endif

# Step 1: make clean in parent directory (library)
echo ""
echo "=== Cleaning C++ library ==="
cd "${os_dir}"
/usr/bin/make clean

# Step 2: make clean in tests directory
echo ""
echo "=== Cleaning test artifacts ==="
cd "${tests_dir}"
/usr/bin/make clean

# Step 3: Run make verify (auto-builds library via build-cpp target)
echo ""
echo "=== Running regression tests ==="
cd "${tests_dir}"
/usr/bin/make verify

set rc = $status

echo ""
if ( ${rc} == 0 ) then
    echo "=== FreeBSD 14 regression PASSED ==="
else
    echo "=== FreeBSD 14 regression FAILED (exit code ${rc}) ==="
endif

exit ${rc}
