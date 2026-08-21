# Python tests Makefile — single entry point: verify
# Pattern matches C/C++ tests/Makefile structure

REPORT_DIR = reports
LOG_DIR = logs
UTILS_BIN_DIR = utils/bin

.PHONY: all clean dist-clean test verify deploy_utils

# Build the C++ shared library (if available)
all:
	@echo "Building Python test environment..."
	@if [ -f ../Makefile ]; then \
		make -C .. build 2>&1 | tail -5; \
	else \
		echo "No parent Makefile found — using Pure Python only"; \
	fi

# Deploy utility scripts for report generation
deploy_utils:
	@mkdir -p $(UTILS_BIN_DIR)
	@test -f ../../prompts/common/cpp/utils/bin/generate_junit_report.sh && cp ../../prompts/common/cpp/utils/bin/generate_junit_report.sh $(UTILS_BIN_DIR)/ && echo "Deployed generate_junit_report.sh" || true

# Single entry point for verify_build and run_regression
# `make test` delegates to `verify` — matches C/C++ pattern
test: verify

# Build + run all tests + generate reports (called by `make test`)
verify: deploy_utils all
	@mkdir -p $(LOG_DIR) $(REPORT_DIR)/python/per_os
	@echo "Running Python Test Matrix (T001-T007)..."
	@PASS=0; FAIL=0;\
	for t in 1 2 3 4 5 6 7; do\
		TNUM=$$(printf "T00%d" $$t);\
		echo "  Running Concurrent $$TNUM...";\
		echo 'Hello, World! This is a test input for the ringbuffer pipeline.' | \
			python3 ../test_ringbuffer.py $$t > $(LOG_DIR)/$$TNUM_concurrent_out.txt 2>&1;\
		EXIT=$$?;\
		if [ $$EXIT -ne 0 ]; then\
			echo "    FAIL: Concurrent $$TNUM (exit code $$EXIT)";\
			FAIL=$$((FAIL+1));\
		else\
			echo "    PASS: Concurrent $$TNUM";\
			PASS=$$((PASS+1));\
		fi;\
	done;\
	echo "Running Pure Python Test Matrix (T001-T007)...";\
	for t in 1 2 3 4 5 6 7; do\
		TNUM=$$(printf "T00%d" $$t);\
		echo "  Running Pure Python $$TNUM...";\
		echo 'Hello, World! This is a test input for the ringbuffer pipeline.' | \
			python3 ../test_ringbuffer_pure.py $$t > $(LOG_DIR)/$$TNUM_pure_out.txt 2>&1;\
		EXIT=$$?;\
		if [ $$EXIT -ne 0 ]; then\
			echo "    FAIL: Pure Python $$TNUM (exit code $$EXIT)";\
			FAIL=$$((FAIL+1));\
		else\
			echo "    PASS: Pure Python $$TNUM";\
			PASS=$$((PASS+1));\
		fi;\
	done;\
	echo "Results: $$PASS passed, $$FAIL failed";\
	if [ $$FAIL -ne 0 ]; then echo "VERIFICATION FAILED"; exit 1; fi
	@echo "Generating reports..."
	@./utils/bin/generate_junit_report.sh -o $(REPORT_DIR)/python/per_os/python_regression_report_junit.xml
	@echo "Verification complete."

clean:
	@rm -rf $(LOG_DIR)/* $(REPORT_DIR)/* utils/bin

dist-clean: clean
	@rm -rf $(LOG_DIR) $(REPORT_DIR) utils/bin
