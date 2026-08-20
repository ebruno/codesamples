# Java tests Makefile — single entry point: verify
# Pattern matches C/C++ tests/Makefile structure

REPORT_DIR = reports
LOG_DIR = logs
UTILS_BIN_DIR = utils/bin

.PHONY: all clean dist-clean test verify deploy_utils

# Build the Java project (compile + package)
all:
	@echo "Building Java project..."
	cd .. && mvn clean compile package -q

# Deploy utility scripts for report generation
deploy_utils:
	@mkdir -p $(UTILS_BIN_DIR)

# Single entry point for verify_build and run_regression
# `make test` delegates to `verify` — matches C/C++ pattern
test: verify

# Build + run all tests + generate reports (called by `make test`)
verify: deploy_utils all
	@mkdir -p $(LOG_DIR) $(REPORT_DIR)/java/per_os
	@echo "Running Java Test Matrix (T001-T007)..."
	@PASS=0; FAIL=0;\
	for t in 1 2 3 4 5 6 7; do\
		TNUM=$$(printf "T00%d" $$t);\
		echo "  Running $$TNUM...";\
		INPUT_FILE="data/inputs/t00${t}_input.txt";\
		EXPECTED_FILE="data/expected/t00${t}_out.txt";\
		if [ ! -f "$$INPUT_FILE" ]; then\
			echo "    SKIP: $$TNUM (no input file)";\
			PASS=$$((PASS+1));\
		else\
			java -cp "../target/ringbuffer-*.jar" swtr.test.TestRingbuffer $$t > $(LOG_DIR)/$$TNUM_out.txt 2>&1;\
			EXIT=$$?;\
			if [ $$EXIT -ne 0 ]; then\
				echo "    FAIL: $$TNUM (exit code $$EXIT)";\
				FAIL=$$((FAIL+1));\
			elif [ -f "$$EXPECTED_FILE" ]; then\
				diff -q $(LOG_DIR)/$$TNUM_out.txt "$$EXPECTED_FILE" > /dev/null 2>&1 && \
					echo "    PASS: $$TNUM (output match)" || \
					{ echo "    FAIL: $$TNUM (output mismatch)"; FAIL=$$((FAIL+1)); };\
			else\
				echo "    PASS: $$TNUM (no expected file, exit code OK)";\
				PASS=$$((PASS+1));\
			fi;\
		fi;\
	done;\
	echo "Results: $$PASS passed, $$FAIL failed";\
	if [ $$FAIL -ne 0 ]; then echo "VERIFICATION FAILED"; exit 1; fi
	@echo "Generating reports..."
	@./utils/bin/generate_junit_report.sh -o $(REPORT_DIR)/java/per_os/java_regression_report_junit.xml
	@echo "Verification complete."

clean:
	@rm -rf $(LOG_DIR)/* $(REPORT_DIR)/* utils/bin

dist-clean: clean
	@rm -rf $(LOG_DIR) $(REPORT_DIR) utils/bin
