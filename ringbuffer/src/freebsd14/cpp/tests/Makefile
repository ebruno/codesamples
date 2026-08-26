include ../version.mk

# OS name for registry lookup
OS_NAME = freebsd14

# Project root (workspace top-level directory)
PROJECT_ROOT_DIR := $(abspath $(CURDIR)/../../../..)

CXX := clang++
CXXFLAGS = -std=c++20 -O3 -I.. -I../src/freebsd14/cpp -pthread
# FreeBSD/ELF: use $ORIGIN for RPATH (not @executable_path which is macOS)
LDFLAGS = -Wl,-rpath,'$$ORIGIN/../lib' -lpthread

RM = rm -rf

UTILS_PROMPT_DIR = ../../../../prompts/common/cpp/utils/bin
UTILS_BIN_DIR = utils/bin

BIN_DIR = bin
LIB_DIR = ../lib
LOG_DIR = logs
REPORT_DIR = reports

# Library build rules (static-only — FreeBSD 14 RPATH limitation)
STATIC_LIB = ${LIB_DIR}/libswtr_ringbuffer.a

# Library build rule (invoked when library is missing)
${STATIC_LIB}:
	@echo "Building C++ library..."
	${MAKE} -C .. all

.PHONY: build-cpp
build-cpp:
	@if [ -f ../UNSUPPORTED.md ]; then echo "C++ unsupported on this platform — skipping C++ build"; else \
		if [ ! -f ${STATIC_LIB} ]; then echo "Building C++ library..."; make -C .. all; else echo "C++ library already present."; fi; \
	fi

all: test001_staticlib

test001_staticlib: src/test001.cpp
	@mkdir -p ${BIN_DIR}
	${CXX} ${CXXFLAGS} src/test001.cpp ${LIB_DIR}/libswtr_ringbuffer.a -o ${BIN_DIR}/test001_staticlib

deploy_utils:
	@echo "Utils already present from tar extraction"

container:
	@echo "Container not used for FreeBSD native build"

verify: build-cpp deploy_utils all
	@mkdir -p ${LOG_DIR} ${REPORT_DIR}
	@echo "Compiler:" > ${REPORT_DIR}/compiler_version.txt
	@clang++ -v >> ${REPORT_DIR}/compiler_version.txt 2>&1 || true
	@echo "Linker:" >> ${REPORT_DIR}/compiler_version.txt
	@ld -v >> ${REPORT_DIR}/compiler_version.txt 2>&1 || true
	@echo "Running Test Matrix..."
	@${BIN_DIR}/test001_staticlib -o ${LOG_DIR}/t001_out.txt -l ${LOG_DIR}/t001.log data/inputs/test001.txt; echo $$? > ${LOG_DIR}/t001.exit
	@diff -q ${LOG_DIR}/t001_out.txt data/expected/t001_out.txt > /dev/null 2>&1 && echo "T001: PASS (output match)" || echo "T001: FAIL (output mismatch)"
	@${BIN_DIR}/test001_staticlib -s 1 -b 1 -o ${LOG_DIR}/t002_out.txt -l ${LOG_DIR}/t002.log data/inputs/test001.txt; echo $$? > ${LOG_DIR}/t002.exit
	@diff -q ${LOG_DIR}/t002_out.txt data/expected/t002_out.txt > /dev/null 2>&1 && echo "T002: PASS (output match)" || echo "T002: FAIL (output mismatch)"
	@${BIN_DIR}/test001_staticlib -b 10 -t 1 -o ${LOG_DIR}/t003_out.txt -l ${LOG_DIR}/t003.log data/inputs/test001.txt; echo $$? > ${LOG_DIR}/t003.exit
	@diff -q ${LOG_DIR}/t003_out.txt data/expected/t003_out.txt > /dev/null 2>&1 && echo "T003: PASS (output match)" || echo "T003: FAIL (output mismatch)"
	@${BIN_DIR}/test001_staticlib -o ${LOG_DIR}/t004_out.txt -l ${LOG_DIR}/t004.log data/inputs/test001.txt; echo $$? > ${LOG_DIR}/t004.exit
	@diff -q ${LOG_DIR}/t004_out.txt data/expected/t004_out.txt > /dev/null 2>&1 && echo "T004: PASS (output match)" || echo "T004: FAIL (output mismatch)"
	@/usr/local/bin/bash -c '${BIN_DIR}/test001_staticlib -e 1 -o ${LOG_DIR}/t005_out.txt -l ${LOG_DIR}/t005.log data/inputs/test001.txt; echo $$? > ${LOG_DIR}/t005.exit'
	@cat ${LOG_DIR}/t005.exit | grep -q '1' && echo 'T005: PASS (exit code 1 as expected)' || echo 'T005: FAIL (unexpected exit code)'
	@${BIN_DIR}/test001_staticlib -e 2 -o ${LOG_DIR}/t006_out.txt -l ${LOG_DIR}/t006.log data/inputs/test001.txt; echo $$? > ${LOG_DIR}/t006.exit
	@diff -q ${LOG_DIR}/t006_out.txt data/expected/t006_out.txt > /dev/null 2>&1 && echo "T006: PASS (output match)" || echo "T006: FAIL (output mismatch)"
	@${BIN_DIR}/test001_staticlib -t 2 -o ${LOG_DIR}/t007_out.txt -l ${LOG_DIR}/t007.log data/inputs/test001.txt; echo $$? > ${LOG_DIR}/t007.exit
	@diff -q ${LOG_DIR}/t007_out.txt data/expected/t007_out.txt > /dev/null 2>&1 && echo "T007: PASS (output match)" || echo "T007: FAIL (output mismatch)"
	@echo "Generating JUnit report..."
	@../../../../prompts/common/cpp/utils/bin/generate_junit_report.tcsh -l ${LOG_DIR} -o ${REPORT_DIR}/regression_report_junit.xml
	@echo "Verification complete."

clean:
	rm -rf ${BIN_DIR}/* ${LOG_DIR}/*
	rm -f *.o ${BIN_DIR}/*.o *~ #*#

# Probe OS/compiler availability (manual use only — not called by other rules)
.PHONY: probe-os

PROBE_LANG = cpp

probe-os:
	@echo "Probing compiler availability for ${OS_NAME}/${PROBE_LANG}..."
	@${PROJECT_ROOT_DIR}/utils/bin/probe_targets.sh ${OS_NAME} ${PROBE_LANG} $(CXX)

dist-clean: clean
	rm -rf ${LOG_DIR} ${REPORT_DIR}
