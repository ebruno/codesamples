# BSD Make-compatible Makefile for FreeBSD 14 Python regression testing
# Uses BSD make syntax (no $(shell), no ifeq/else)

SHELL = /bin/sh

# OS name for registry lookup
OS_NAME = freebsd14

.PHONY: all clean dist-clean test verify deploy_utils probe-os

# Directories
UTILS_PROMPT_DIR = ../../../../prompts/common/python/utils/bin
UTILS_BIN_DIR = utils/bin
LOG_DIR = logs
REPORT_DIR = reports/python/per_os

# Test harnesses
TEST_CONCURRENT = ../test_ringbuffer.py
TEST_PURE = ../test_ringbuffer_pure.py

all: verify

deploy_utils:
	@mkdir -p ${UTILS_BIN_DIR}
	@test -f ${UTILS_PROMPT_DIR}/generate_junit_report.tcsh && cp ${UTILS_PROMPT_DIR}/generate_junit_report.tcsh ${UTILS_BIN_DIR}/ && echo "Deployed generate_junit_report.tcsh" || true

test: verify

verify: deploy_utils
	@mkdir -p ${LOG_DIR} ${REPORT_DIR}
	@echo "Building C++ shared library..."
	@cd ../../cpp && make shared
	@mkdir -p ../lib
	@rm -f ../lib/libswtr_ringbuffer.so
	@ln -s ../../cpp/lib/libswtr_ringbuffer.so ../lib/libswtr_ringbuffer.so
	@echo 0 > ${LOG_DIR}/_conc_fail
	@echo 0 > ${LOG_DIR}/_pure_fail
	@echo ""
	@echo "=== Concurrent harness ==="
	-@for t in 1 2 3 4 5 6 7; do \
		TNUM=$$(printf "T00%d" $$t); \
		echo "  $$TNUM..."; \
		echo "Hello, World! This is a test input for the ringbuffer pipeline." | \
			python3 ${TEST_CONCURRENT} $$t > ${LOG_DIR}/t$${TNUM#T}_concurrent.log 2>&1; \
		EXIT=$$?; \
		echo $$EXIT > ${LOG_DIR}/$${TNUM}_concurrent.exit; \
		if [ "$$TNUM" = "T005" ]; then \
			if [ $$EXIT -eq 1 ]; then \
				echo "    PASS: Concurrent $$TNUM (expected exit code 1)"; \
			else \
				echo "    FAIL: Concurrent $$TNUM (expected exit 1, got $$EXIT)"; \
				FAIL=$$(cat ${LOG_DIR}/_conc_fail); echo $$((FAIL+1)) > ${LOG_DIR}/_conc_fail; \
			fi; \
		elif [ $$EXIT -ne 0 ]; then \
			echo "    FAIL: Concurrent $$TNUM"; \
			FAIL=$$(cat ${LOG_DIR}/_conc_fail); echo $$((FAIL+1)) > ${LOG_DIR}/_conc_fail; \
		else \
			echo "    PASS: Concurrent $$TNUM"; \
		fi; \
	done
	@echo "=== Pure Python harness ==="
	-@for t in 1 2 3 4 5 6 7; do \
		TNUM=$$(printf "T00%d" $$t); \
		echo "  $$TNUM..."; \
		echo "Hello, World! This is a test input for the ringbuffer pipeline." | \
			python3 ${TEST_PURE} $$t > ${LOG_DIR}/t$${TNUM#T}_pure.log 2>&1; \
		EXIT=$$?; \
		echo $$EXIT > ${LOG_DIR}/$${TNUM}_pure.exit; \
		if [ "$$TNUM" = "T005" ]; then \
			if [ $$EXIT -eq 1 ]; then \
				echo "    PASS: Pure Python $$TNUM (expected exit code 1)"; \
			else \
				echo "    FAIL: Pure Python $$TNUM (expected exit 1, got $$EXIT)"; \
				FAIL=$$(cat ${LOG_DIR}/_pure_fail); echo $$((FAIL+1)) > ${LOG_DIR}/_pure_fail; \
			fi; \
		elif [ $$EXIT -ne 0 ]; then \
			echo "    FAIL: Pure Python $$TNUM"; \
			FAIL=$$(cat ${LOG_DIR}/_pure_fail); echo $$((FAIL+1)) > ${LOG_DIR}/_pure_fail; \
		else \
			echo "    PASS: Pure Python $$TNUM"; \
		fi; \
	done
	@echo ""
	@CONC_FAIL=$$(cat ${LOG_DIR}/_conc_fail); \
	PURE_FAIL=$$(cat ${LOG_DIR}/_pure_fail); \
	CONC_PASS=$$((7 - CONC_FAIL)); \
	PURE_PASS=$$((7 - PURE_FAIL)); \
	echo "Concurrent: $$CONC_PASS/7 passed"; \
	echo "Pure Python: $$PURE_PASS/7 passed"; \
	if [ $$CONC_FAIL -ne 0 ] || [ $$PURE_FAIL -ne 0 ]; then \
		echo "=== SOME TESTS FAILED ==="; exit 1; \
	fi; \
	echo "=== All tests passed ==="
	@echo "Generating reports..."
	@./utils/bin/generate_junit_report.tcsh -l ${LOG_DIR} -o ${REPORT_DIR}/python_regression_report_junit.xml
	@echo "Verification complete."

clean:
	@rm -rf ${LOG_DIR}/* ${REPORT_DIR}/* utils/bin
	@rm -rf utils

dist-clean: clean
	@rm -rf ${LOG_DIR} ${REPORT_DIR}

probe-os:
	@echo "Probing Python availability for ${OS_NAME}..."
	@python3 --version 2>/dev/null || echo "Python3 not found"
