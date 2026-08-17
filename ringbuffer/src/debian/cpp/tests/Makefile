include ../version.mk

# Compiler settings
CXX = g++
CXXFLAGS = -std=c++20 -O3 -Wall -Wextra -I..
LDFLAGS = 
RM = rm -rf

# Directories
SRC_DIR = src
BIN_DIR = bin
DATA_DIR = data
LOGS_DIR = logs
REPORTS_DIR = reports
UTILS_DIR = utils

# Test binary names
TEST_STATIC = $(BIN_DIR)/test001_staticlib
TEST_DYNAMIC = $(BIN_DIR)/test001_dynamiclib

# Library paths
LIB_DIR = ../lib
STATIC_LIB = $(LIB_DIR)/libswtr_ringbuffer.a
SHARED_LIB = $(LIB_DIR)/libswtr_ringbuffer.so

# Container settings
CONTAINER_IMAGE = ringbuffer_debian_test
DOCKERFILE = containers/fedora/Dockerfile

# Detect Container Runtime
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    CONTAINER_CMD = container
else
    CONTAINER_CMD = podman
endif

# Compiler auto-detection: Linux order is g++ first, then clang++
ifeq ($(UNAME_S),Darwin)
  ALL_COMPILERS := clang++ g++
else
  ALL_COMPILERS := g++ clang++
endif

# Filter to only distinct compilers (skip if same binary)
DISTINCT_COMPILERS := $(foreach COMP,$(ALL_COMPILERS),\
  $(if $(filter $(COMP),$(DISTINCT_COMPILERS)),,$(shell if [ -x "$(COMP)" ] && ! $(COMP) --version 2>/dev/null | grep -q "clang"; then echo "$(COMP)"; fi)))

.PHONY: all static dynamic clean dist-clean container container-clean verify validate-data deploy-utils test-all

all: static dynamic

static: $(TEST_STATIC)
dynamic: $(TEST_DYNAMIC)

# Static linking test binary
$(TEST_STATIC): $(SRC_DIR)/test001.cpp
	@mkdir -p $(BIN_DIR)
	$(CXX) $(CXXFLAGS) $< -o $@ \
		$(STATIC_LIB)

# Dynamic linking test binary
$(TEST_DYNAMIC): $(SRC_DIR)/test001.cpp
	@mkdir -p $(BIN_DIR)
	$(CXX) $(CXXFLAGS) $< -o $@ \
		-L$(LIB_DIR) -lswtr_ringbuffer \
		-Wl,-rpath,$(abspath $(LIB_DIR))

# Per-compiler test binaries
define PER_COMPILER_TEST_TARGETS
test001_staticlib_$(1): $(SRC_DIR)/test001.cpp
	@mkdir -p $(BIN_DIR)
	$(1) $(CXXFLAGS) $< -o $(BIN_DIR)/test001_staticlib_$(1) \
		$(STATIC_LIB)

test001_dynamiclib_$(1): $(SRC_DIR)/test001.cpp
	@mkdir -p $(BIN_DIR)
	$(1) $(CXXFLAGS) $< -o $(BIN_DIR)/test001_dynamiclib_$(1) \
		-L$(LIB_DIR) -lswtr_ringbuffer \
		-Wl,-rpath,$(abspath $(LIB_DIR))
endef

$(foreach COMP,$(DISTINCT_COMPILERS),$(eval $(call PER_COMPILER_TEST_TARGETS,$(COMP))))

# Deploy authoritative utility scripts from prompts
deploy-utils:
	@echo "Deploying authoritative utility scripts..."
	@if [ -d "../../../../prompts/common/cpp/utils/bin" ]; then \
		for script in ../../../../prompts/common/cpp/utils/bin/*; do \
			if [ -f "$$script" ]; then \
				cp -f "$$script" "$(UTILS_DIR)/bin/"; \
				echo "  Deployed: $$(basename $$script)"; \
			fi; \
		done; \
	else \
		echo "  Authoritative scripts directory not mounted in container — using existing scripts in $(UTILS_DIR)/bin/"; \
	fi

# Validate test data
validate-data:
	@echo "Validating test data..."
	@if [ -d "$(DATA_DIR)/inputs" ]; then \
		for f in $(DATA_DIR)/inputs/test*.txt; do \
			if [ -f "$$f" ]; then \
				echo "Validating $$f..."; \
				$(UTILS_DIR)/bin/verify_test_data.sh "$$f" || exit 1; \
			fi; \
		done; \
	else \
		echo "ERROR: $(DATA_DIR)/inputs directory not found"; \
		exit 1; \
	fi
	@echo "Test data validation passed"

# Run verification (artifact check + test matrix)
verify: static dynamic validate-data deploy-utils
	@mkdir -p $(LOGS_DIR) $(REPORTS_DIR)
	@echo "=== Artifact Verification ==="
	@file -L $(STATIC_LIB) | grep -q "current ar archive" && echo "Static library: OK" || (echo "Static library: FAIL"; exit 1)
	@file -L $(SHARED_LIB) | grep -q "shared object" && echo "Shared library: OK" || (echo "Shared library: FAIL"; exit 1)
	@readelf -d $(SHARED_LIB) | grep -q "SONAME.*libswtr_ringbuffer.so" && echo "SONAME: OK" || (echo "SONAME: FAIL"; exit 1)
	@size $(SHARED_LIB) | tail -1 | awk '{total=$$1+$$2+$$3; print "Binary size: " total " bytes (text=" $$1 ", data=" $$2 ", bss=" $$3 ")"}'
	@echo ""
	@echo "=== Audit Trail ==="
	@$(CXX) -v > $(REPORTS_DIR)/compiler_version.txt 2>&1 || true
	@ld -v >> $(REPORTS_DIR)/compiler_version.txt 2>&1 || true
	@echo "Compiler and linker versions captured"
	@echo ""
	@echo "=== Test Matrix Execution ==="
	@start_time=$$(date '+%Y-%m-%d %H:%M:%S %z'); \
	echo "Start Time: $$start_time"; \
	for test_id in T001 T002 T003 T004 T005 T006 T007; do \
		test_start=$$(date +%s%N); \
		echo "Running $$test_id..."; \
		case $$test_id in \
			T001) $(TEST_STATIC) -s 4 -b 4096 -t 0 -e 0 $(DATA_DIR)/inputs/test001.txt > $(DATA_DIR)/expected/t001.out 2> $(LOGS_DIR)/t001.log ;; \
			T002) $(TEST_STATIC) -s 1 -b 1 -t 0 -e 0 $(DATA_DIR)/inputs/test001.txt > $(DATA_DIR)/expected/t002.out 2> $(LOGS_DIR)/t002.log ;; \
			T003) $(TEST_STATIC) -s 4 -b 10 -t 1 -e 0 $(DATA_DIR)/inputs/test001.txt > $(DATA_DIR)/expected/t003.out 2> $(LOGS_DIR)/t003.log ;; \
			T004) $(TEST_STATIC) -s 4 -b 4096 -t 0 -e 0 $(DATA_DIR)/inputs/test001.txt > $(DATA_DIR)/expected/t004.out 2> $(LOGS_DIR)/t004.log ;; \
			T005) $(TEST_STATIC) -s 4 -b 4096 -t 0 -e 1 $(DATA_DIR)/inputs/test001.txt > $(DATA_DIR)/expected/t005.out 2> $(LOGS_DIR)/t005.log ;; \
			T006) $(TEST_STATIC) -s 4 -b 4096 -t 0 -e 2 $(DATA_DIR)/inputs/test001.txt > $(DATA_DIR)/expected/t006.out 2> $(LOGS_DIR)/t006.log ;; \
			T007) $(TEST_STATIC) -s 4 -b 4096 -t 2 -e 0 $(DATA_DIR)/inputs/test001.txt > $(DATA_DIR)/expected/t007.out 2> $(LOGS_DIR)/t007.log ;; \
		esac; \
		test_exit=$$?; \
		echo "$$test_exit" > $(LOGS_DIR)/$$test_id.exit; \
		test_end=$$(date +%s%N); \
		test_time_ms=$$(( (test_end - test_start) / 1000000 )); \
		echo "$$test_time_ms" > $(LOGS_DIR)/$$test_id.time; \
	done; \
	end_time=$$(date '+%Y-%m-%d %H:%M:%S %z'); \
	echo "End Time: $$end_time"; \
	echo ""; \
	echo "=== Generating JUnit Report ==="; \
	$(UTILS_DIR)/bin/generate_junit_report.sh -l $(LOGS_DIR) -o $(REPORTS_DIR)/regression_report_junit.xml || echo "WARNING: JUnit report generation failed"; \
	echo ""; \
	echo "=== Generating Regression Report ==="; \
	{ \
		echo "# Regression Verification Report - Debian"; \
		echo "**Date:** $$start_time"; \
		echo "**Start Time:** $$start_time"; \
		echo "**End Time:** $$end_time"; \
		echo ""; \
		echo "## Audit Trail"; \
		cat $(REPORTS_DIR)/compiler_version.txt 2>/dev/null || echo "Version capture unavailable"; \
		echo ""; \
		echo "## Test Results"; \
		echo "| Test ID | Description | Result | Execution Time (ms) | Note |"; \
		echo "| :--- | :--- | :--- | :--- | :--- |"; \
		for test_id in T001 T002 T003 T004 T005 T006 T007; do \
			exit_code=0; \
			if [ -f "$(LOGS_DIR)/$$test_id.exit" ]; then exit_code=$$(cat $(LOGS_DIR)/$$test_id.exit); fi; \
			time_ms="N/A"; \
			if [ -f "$(LOGS_DIR)/$$test_id.time" ]; then time_ms=$$(cat $(LOGS_DIR)/$$test_id.time); fi; \
			case $$test_id in \
				T001) desc="Exact match with input" ;; \
				T002) desc="Stress test (1 slot, 1 byte)" ;; \
				T003) desc="All chars uppercase" ;; \
				T004) desc="Input < 1 slot (fast EOF)" ;; \
				T005) desc="Pipeline stop (Fatal Error)" ;; \
				T006) desc="Pipeline continues (Non-fatal)" ;; \
				T007) desc="Bit-inverted output" ;; \
			esac; \
			case $$test_id in \
				T005) expected_exit=1 ;; \
			*) expected_exit=0 ;; \
			esac; \
			if [ "$$exit_code" -eq "$$expected_exit" ]; then result="PASS"; else result="FAIL"; fi; \
			echo "| $$test_id | $$desc | $$result | $$time_ms | exit=$$exit_code |"; \
		done; \
	} > $(REPORTS_DIR)/regression_report.md; \
	echo "Regression report generated: $(REPORTS_DIR)/regression_report.md"

# ============================================================================
# Multi-compiler test cycle: test-all
# Runs verify with each available compiler using per-compiler binaries.
# ============================================================================

test-all: test-report-init
	@$(foreach COMP,$(DISTINCT_COMPILERS),\
		echo "=== Testing with $(COMP) ==="; \
		$(MAKE) test001_staticlib_$(COMP); \
		$(MAKE) verify-with-CXX=$(COMP); \
		$(MAKE) append-test-report COMP=$(COMP); \
		echo ""; \
	)
	@echo "=== Multi-compiler test complete ==="

verify-with-CXX: validate-data deploy-utils
	@mkdir -p $(LOGS_DIR) $(REPORTS_DIR)
	@echo "=== Artifact Verification ==="
	@file -L $(STATIC_LIB) | grep -q "current ar archive" && echo "Static library: OK" || (echo "Static library: FAIL"; exit 1)
	@file -L $(SHARED_LIB) | grep -q "shared object" && echo "Shared library: OK" || (echo "Shared library: FAIL"; exit 1)
	@readelf -d $(SHARED_LIB) | grep -q "SONAME.*libswtr_ringbuffer.so" && echo "SONAME: OK" || (echo "SONAME: FAIL"; exit 1)
	@size $(SHARED_LIB) | tail -1 | awk '{total=$$1+$$2+$$3; print "Binary size: " total " bytes (text=" $$1 ", data=" $$2 ", bss=" $$3 ")"}'
	@echo ""
	@echo "=== Audit Trail ==="
	@$(CXX) -v > $(REPORTS_DIR)/compiler_version_$(CXX).txt 2>&1 || true
	@ld -v >> $(REPORTS_DIR)/compiler_version_$(CXX).txt 2>&1 || true
	@echo "Compiler and linker versions captured"
	@echo ""
	@echo "=== Test Matrix Execution with $(CXX) ==="
	@start_time=$$(date '+%Y-%m-%d %H:%M:%S %z'); \
	echo "Start Time: $$start_time"; \
	for test_id in T001 T002 T003 T004 T005 T006 T007; do \
		test_start=$$(date +%s%N); \
		echo "Running $$test_id..."; \
		case $$test_id in \
			T001) $(BIN_DIR)/test001_staticlib_$(CXX) -s 4 -b 4096 -t 0 -e 0 $(DATA_DIR)/inputs/test001.txt > $(DATA_DIR)/expected/t001.out 2> $(LOGS_DIR)/t001.log ;; \
			T002) $(BIN_DIR)/test001_staticlib_$(CXX) -s 1 -b 1 -t 0 -e 0 $(DATA_DIR)/inputs/test001.txt > $(DATA_DIR)/expected/t002.out 2> $(LOGS_DIR)/t002.log ;; \
			T003) $(BIN_DIR)/test001_staticlib_$(CXX) -s 4 -b 10 -t 1 -e 0 $(DATA_DIR)/inputs/test001.txt > $(DATA_DIR)/expected/t003.out 2> $(LOGS_DIR)/t003.log ;; \
			T004) $(BIN_DIR)/test001_staticlib_$(CXX) -s 4 -b 4096 -t 0 -e 0 $(DATA_DIR)/inputs/test001.txt > $(DATA_DIR)/expected/t004.out 2> $(LOGS_DIR)/t004.log ;; \
			T005) $(BIN_DIR)/test001_staticlib_$(CXX) -s 4 -b 4096 -t 0 -e 1 $(DATA_DIR)/inputs/test001.txt > $(DATA_DIR)/expected/t005.out 2> $(LOGS_DIR)/t005.log ;; \
			T006) $(BIN_DIR)/test001_staticlib_$(CXX) -s 4 -b 4096 -t 0 -e 2 $(DATA_DIR)/inputs/test001.txt > $(DATA_DIR)/expected/t006.out 2> $(LOGS_DIR)/t006.log ;; \
			T007) $(BIN_DIR)/test001_staticlib_$(CXX) -s 4 -b 4096 -t 2 -e 0 $(DATA_DIR)/inputs/test001.txt > $(DATA_DIR)/expected/t007.out 2> $(LOGS_DIR)/t007.log ;; \
		esac; \
		test_exit=$$?; \
		echo "$$test_exit" > $(LOGS_DIR)/$$test_id.exit; \
		test_end=$$(date +%s%N); \
		test_time_ms=$$(( (test_end - test_start) / 1000000 )); \
		echo "$$test_time_ms" > $(LOGS_DIR)/$$test_id.time; \
	done; \
	end_time=$$(date '+%Y-%m-%d %H:%M:%S %z'); \
	echo "End Time: $$end_time"; \
	echo ""; \
	echo "=== Generating JUnit Report ==="; \
	$(UTILS_DIR)/bin/generate_junit_report.sh -l $(LOGS_DIR) -o $(REPORTS_DIR)/regression_report_junit.xml || echo "WARNING: JUnit report generation failed"; \
	echo ""; \
	echo "=== Generating Regression Report ==="; \
	{ \
		echo "# Regression Verification Report - Debian ($(CXX))"; \
		echo "**Date:** $$start_time"; \
		echo "**Start Time:** $$start_time"; \
		echo "**End Time:** $$end_time"; \
		echo ""; \
		echo "## Audit Trail"; \
		cat $(REPORTS_DIR)/compiler_version_$(CXX).txt 2>/dev/null || echo "Version capture unavailable"; \
		echo ""; \
		echo "## Test Results"; \
		echo "| Test ID | Description | Result | Execution Time (ms) | Note |"; \
		echo "| :--- | :--- | :--- | :--- | :--- |"; \
		for test_id in T001 T002 T003 T004 T005 T006 T007; do \
			exit_code=0; \
			if [ -f "$(LOGS_DIR)/$$test_id.exit" ]; then exit_code=$$(cat $(LOGS_DIR)/$$test_id.exit); fi; \
			time_ms="N/A"; \
			if [ -f "$(LOGS_DIR)/$$test_id.time" ]; then time_ms=$$(cat $(LOGS_DIR)/$$test_id.time); fi; \
			case $$test_id in \
				T001) desc="Exact match with input" ;; \
				T002) desc="Stress test (1 slot, 1 byte)" ;; \
				T003) desc="All chars uppercase" ;; \
				T004) desc="Input < 1 slot (fast EOF)" ;; \
				T005) desc="Pipeline stop (Fatal Error)" ;; \
				T006) desc="Pipeline continues (Non-fatal)" ;; \
				T007) desc="Bit-inverted output" ;; \
			esac; \
			case $$test_id in \
				T005) expected_exit=1 ;; \
			*) expected_exit=0 ;; \
			esac; \
			if [ "$$exit_code" -eq "$$expected_exit" ]; then result="PASS"; else result="FAIL"; fi; \
			echo "| $$test_id | $$desc | $$result | $$time_ms | exit=$$exit_code |"; \
		done; \
	} > $(REPORTS_DIR)/regression_report_$(CXX).md; \
	echo "Regression report generated: $(REPORTS_DIR)/regression_report_$(CXX).md"

test-report-init:
	@mkdir -p reports
	@echo "# Test Report" > reports/test_report.md
	@echo "" >> reports/test_report.md
	@echo "**Generated:** $$(date '+%Y-%m-%d %H:%M:%S %z')" >> reports/test_report.md
	@echo "" >> reports/test_report.md

append-test-report:
	@mkdir -p reports
	@echo "## $(COMP)" >> reports/test_report.md
	@echo "" >> reports/test_report.md
	@echo "**Compiler:** $$( $(COMP) --version | head -1 )" >> reports/test_report.md
	@echo "" >> reports/test_report.md
	@if [ -f "$(REPORTS_DIR)/compiler_version_$(COMP).txt" ]; then \
		echo "**Compiler Info:**"; cat $(REPORTS_DIR)/compiler_version_$(COMP).txt >> reports/test_report.md; \
	else \
		echo "**Compiler Info:** N/A" >> reports/test_report.md; \
	fi
	@echo "" >> reports/test_report.md

# Clean test artifacts
clean:
	@$(RM) -r $(BIN_DIR)/* 2>/dev/null || true
	@$(RM) *.o 2>/dev/null || true
	@$(RM) -r $(LOGS_DIR)/* 2>/dev/null || true
	@$(RM) "*~" "#*#" 2>/dev/null || true

# Full cleanup
dist-clean: clean
	@$(RM) -r $(LOGS_DIR) 2>/dev/null || true
	@$(RM) -r $(REPORTS_DIR) 2>/dev/null || true

# Container management
container:
	@echo "Checking test container..."
ifeq ($(UNAME_S),Darwin)
	@echo "macOS host detected — checking Apple Container service..."
	@if ! $(CONTAINER_CMD) system status 2>/dev/null | grep -q "status.*running"; then \
		echo "Starting Apple Container service..."; \
		$(CONTAINER_CMD) system start; \
		sleep 5; \
		$(CONTAINER_CMD) system status 2>/dev/null | grep -q "status.*running" || (echo "ERROR: Container service failed to start" && exit 1); \
	else \
		echo "Apple Container service is running."; \
	fi
endif
	@if ! $(CONTAINER_CMD) image ls --quiet | grep -q $(CONTAINER_IMAGE); then \
		echo "Image $(CONTAINER_IMAGE) not found. Building..."; \
		timeout 600 $(CONTAINER_CMD) build -t $(CONTAINER_IMAGE) -f $(DOCKERFILE) .; \
	else \
		image_created=$$($(CONTAINER_CMD) image inspect $(CONTAINER_IMAGE) 2>/dev/null | grep -o '"creationDate" *: *"[^"]*"' | head -1 | cut -d'"' -f4); \
		if [ -n "$$image_created" ]; then \
			dockerfile_mtime=$$(stat -c %Y $(DOCKERFILE) 2>/dev/null || stat -f %m $(DOCKERFILE) 2>/dev/null); \
			version_mtime=$$(stat -c %Y ../version.mk 2>/dev/null || stat -f %m ../version.mk 2>/dev/null); \
			image_mtime=$$(date -d "$$image_created" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "$$image_created" +%s 2>/dev/null); \
			if [ -n "$$dockerfile_mtime" ] && [ "$$dockerfile_mtime" -gt "$$image_mtime" ]; then \
				echo "Image $(CONTAINER_IMAGE) is stale (Dockerfile newer). Rebuilding..."; \
				timeout 600 $(CONTAINER_CMD) build -t $(CONTAINER_IMAGE) -f $(DOCKERFILE) .; \
			elif [ -n "$$version_mtime" ] && [ "$$version_mtime" -gt "$$image_mtime" ]; then \
				echo "Image $(CONTAINER_IMAGE) is stale (version.mk newer). Rebuilding..."; \
				timeout 600 $(CONTAINER_CMD) build -t $(CONTAINER_IMAGE) -f $(DOCKERFILE) .; \
			else \
				echo "Image $(CONTAINER_IMAGE) is up to date. Skipping build."; \
			fi; \
		else \
			echo "Image $(CONTAINER_IMAGE) metadata unavailable. Rebuilding..."; \
			timeout 600 $(CONTAINER_CMD) build -t $(CONTAINER_IMAGE) -f $(DOCKERFILE) .; \
		fi; \
	fi
	@echo "Container environment ready."

container-clean:
	@echo "Removing test container image..."
	@$(CONTAINER_CMD) image rm -f $(CONTAINER_IMAGE) || true
	@echo "Container environment cleaned."
