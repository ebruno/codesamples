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
# Python-specific versions are in prompts/common/python/utils/bin/
# In containers, prompts is mounted at /prompts
PROMPTS_PYTHON_UTILS = ../../../../prompts/common/python/utils/bin
CONTAINER_PROMPTS_PYTHON = /prompts/common/python/utils/bin
deploy_utils:
	@mkdir -p $(UTILS_BIN_DIR)
	@if [ -f $(CONTAINER_PROMPTS_PYTHON)/generate_junit_report.sh ]; then cp $(CONTAINER_PROMPTS_PYTHON)/generate_junit_report.sh $(UTILS_BIN_DIR)/ && echo "Deployed generate_junit_report.sh"; elif [ -f $(PROMPTS_PYTHON_UTILS)/generate_junit_report.sh ]; then cp $(PROMPTS_PYTHON_UTILS)/generate_junit_report.sh $(UTILS_BIN_DIR)/ && echo "Deployed generate_junit_report.sh"; else echo "WARNING: generate_junit_report.sh not found"; fi
	@if [ -f $(CONTAINER_PROMPTS_PYTHON)/generate_junit_report.tcsh ]; then cp $(CONTAINER_PROMPTS_PYTHON)/generate_junit_report.tcsh $(UTILS_BIN_DIR)/ && echo "Deployed generate_junit_report.tcsh"; elif [ -f $(PROMPTS_PYTHON_UTILS)/generate_junit_report.tcsh ]; then cp $(PROMPTS_PYTHON_UTILS)/generate_junit_report.tcsh $(UTILS_BIN_DIR)/ && echo "Deployed generate_junit_report.tcsh"; else echo "WARNING: generate_junit_report.tcsh not found"; fi

# Single entry point for verify_build and run_regression
# `make test` delegates to `verify` — matches C/C++ pattern
test: verify

# Build + run all tests + generate reports (called by `make test`)
# Log file naming: t001_concurrent.log, T001_concurrent.exit (matches generate_junit_report expectations)
verify: deploy_utils all
	@mkdir -p $(LOG_DIR) $(REPORT_DIR)/python/per_os
	@echo "Running Python Test Matrix (T001-T007)..."
	@PASS=0; FAIL=0;\
	for t in 1 2 3 4 5 6 7; do\
		TNUM=$$(printf "T00%d" $$t);\
		echo "  Running Concurrent $$TNUM...";\
		echo 'Hello, World! This is a test input for the ringbuffer pipeline.' | \
			python3 ../test_ringbuffer.py $$t > $(LOG_DIR)/t$${TNUM#T}_concurrent.log 2>&1;\
		EXIT=$$?;\
		echo $$EXIT > $(LOG_DIR)/$${TNUM}_concurrent.exit;\
		if [ "$$TNUM" = "T005" ]; then\
			if [ $$EXIT -eq 1 ]; then\
				echo "    PASS: Concurrent $$TNUM (expected exit code 1)";\
				PASS=$$((PASS+1));\
			else\
				echo "    FAIL: Concurrent $$TNUM (expected exit code 1, got $$EXIT)";\
				FAIL=$$((FAIL+1));\
			fi;\
		elif [ $$EXIT -ne 0 ]; then\
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
			python3 ../test_ringbuffer_pure.py $$t > $(LOG_DIR)/t$${TNUM#T}_pure.log 2>&1;\
		EXIT=$$?;\
		echo $$EXIT > $(LOG_DIR)/$${TNUM}_pure.exit;\
		if [ "$$TNUM" = "T005" ]; then\
			if [ $$EXIT -eq 1 ]; then\
				echo "    PASS: Pure Python $$TNUM (expected exit code 1)";\
				PASS=$$((PASS+1));\
			else\
				echo "    FAIL: Pure Python $$TNUM (expected exit code 1, got $$EXIT)";\
				FAIL=$$((FAIL+1));\
			fi;\
		elif [ $$EXIT -ne 0 ]; then\
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
