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
# Java uses Maven Surefire for JUnit XML — no custom generate_junit_report.sh needed
verify: deploy_utils all
	@mkdir -p $(LOG_DIR) $(REPORT_DIR)/java/per_os
	@echo "Running Java Test Matrix (T001-T007)..."
	@# The Maven build already runs all tests via Surefire — verify the results
	@if [ -f ../target/surefire-reports/TEST-swtr.test.TestRingbuffer.xml ]; then \
		echo "Parsing Surefire results..."; \
		FAILURES=$$(grep -o 'failures="[0-9]*"' ../target/surefire-reports/TEST-swtr.test.TestRingbuffer.xml 2>/dev/null | grep -o '[0-9]*' | head -1); \
		ERRORS=$$(grep -o 'errors="[0-9]*"' ../target/surefire-reports/TEST-swtr.test.TestRingbuffer.xml 2>/dev/null | grep -o '[0-9]*' | head -1); \
		FAILURES=$${FAILURES:-0}; \
		ERRORS=$${ERRORS:-0}; \
		if [ "$${FAILURES}" -eq 0 ] && [ "$${ERRORS}" -eq 0 ]; then \
			echo "    All Java tests passed"; \
		else \
			echo "    FAILURES: $$FAILURES, ERRORS: $$ERRORS"; \
			echo "VERIFICATION FAILED"; exit 1; \
		fi; \
	else \
		echo "WARNING: No Surefire report found — check Maven build output above"; \
	fi
	@echo "Generating reports..."
	@if [ -f ../target/surefire-reports/TEST-swtr.test.TestRingbuffer.xml ]; then \
		cp ../target/surefire-reports/TEST-swtr.test.TestRingbuffer.xml $(REPORT_DIR)/java/per_os/java_regression_report_junit.xml; \
		echo "Copied Surefire JUnit report to $(REPORT_DIR)/java/per_os/java_regression_report_junit.xml"; \
	else \
		echo "WARNING: No Surefire report to copy"; \
	fi
	@echo "Verification complete."

clean:
	@rm -rf $(LOG_DIR)/* $(REPORT_DIR)/* utils/bin

dist-clean: clean
	@rm -rf $(LOG_DIR) $(REPORT_DIR) utils/bin
