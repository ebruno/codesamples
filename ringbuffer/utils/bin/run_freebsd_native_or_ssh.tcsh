#!/usr/bin/env tcsh
# run_freebsd_native_or_ssh.tcsh — FreeBSD 14 native and SSH build/test runner
# Usage: tcsh run_freebsd_native_or_ssh.tcsh <ringbuffer_path> <os_name> [mode]
#   mode: "cpp" (default, build), "test-cpp",
#         "python-build", "python-test",
#         "java-build", "java-test"

set ringbuffer_path = "$1"
set os_name = "$2"
set mode = "cpp"
if ( $#argv >= 3 ) then
    set mode = "$3"
endif

# C++ build (default) — uses src/<os>/cpp/ per-OS source
if ( "$mode" == "cpp" ) then
    cd ${ringbuffer_path}/src/${os_name}/cpp ; make clean ; make all
endif

# C++ tests — uses src/<os>/cpp/tests/ per-OS test directory
if ( "$mode" == "test-cpp" ) then
    cd ${ringbuffer_path}/src/${os_name}/cpp ; make clean
    cd ${ringbuffer_path}/src/${os_name}/cpp/tests ; make clean ; make verify
endif

# Python build — uses src/common/python/ source, src/freebsd14/python/ Makefile
if ( "$mode" == "python-build" ) then
    cd ${ringbuffer_path}/src/freebsd14/python ; make clean ; make all
endif

# Python tests — uses src/freebsd14/python/ source, src/freebsd14/python/tests/ Makefile (BSD make)
if ( "$mode" == "python-test" ) then
    cd ${ringbuffer_path}/src/freebsd14/python ; make clean
    cd ${ringbuffer_path}/src/freebsd14/python/tests ; make clean ; make verify
endif

# Java build — uses src/common/java/ source, src/freebsd14/java/ Makefile
if ( "$mode" == "java-build" ) then
    cd ${ringbuffer_path}/src/freebsd14/java ; make clean ; make all
endif

# Java tests — uses src/freebsd14/java/ Makefile (BSD make, Maven native)
if ( "$mode" == "java-test" ) then
    cd ${ringbuffer_path}/src/freebsd14/java ; make clean ; make test
endif

# Future language modes (C, Go, Rust) — add when implemented:
# if ( "$mode" == "c-build" ) then ...
# if ( "$mode" == "test-c" ) then ...
# if ( "$mode" == "go-build" ) then ...
# if ( "$mode" == "test-go" ) then ...
# if ( "$mode" == "rust-build" ) then ...
# if ( "$mode" == "test-rust" ) then ...
