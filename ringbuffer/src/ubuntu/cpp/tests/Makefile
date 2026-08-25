include ../version.mk

# OS name for registry lookup
OS_NAME = ubuntu

# Project root (workspace top-level directory)
PROJECT_ROOT_DIR := $(abspath $(CURDIR)/../../../..)

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

# Container settings (minimal — host script orchestrates)
CONTAINER_IMAGE = ringbuffer_ubuntu_test
DOCKERFILE = containers/ubuntu/Dockerfile
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    CONTAINER_CMD = container
else
    CONTAINER_CMD = podman
endif

# Container name for exec-based workflow (single running instance)
CONTAINER_NAME = ringbuffer_ubuntu_test_work

# Container-aware execution: when host != target OS, run inside container
ifeq ($(UNAME_S),Darwin)
    # macOS host — execute all build/test steps inside the container
    CONTAINER_RUN_OPTS = -v $(abspath ../../../../):/app/ringbuffer -w /app/ringbuffer/ubuntu/cpp/tests
    CONTAINER_EXEC = $(CONTAINER_CMD) exec -i $(CONTAINER_NAME)
else
    # Linux host — run natively (no container needed for tests)
    CONTAINER_RUN_OPTS =
    CONTAINER_EXEC =
endif

# Compilers available in the container (g++ first, then clang++)
.PHONY: all static dynamic clean dist-clean verify verify-single validate-data deploy-utils test-all

all: static dynamic

static: $(TEST_STATIC)
dynamic: $(TEST_DYNAMIC)

# Library build rules (invoked when library is missing)
$(STATIC_LIB): ../Makefile
	@echo "Building C++ library..."
	$(MAKE) -C .. all

$(SHARED_LIB): ../Makefile
	@echo "Building C++ library..."
	$(MAKE) -C .. all

# Static linking test binary
$(TEST_STATIC): $(SRC_DIR)/test001.cpp $(STATIC_LIB)
	@mkdir -p $(BIN_DIR)
	$(CXX) $(CXXFLAGS) $< -o $@ \
		$(STATIC_LIB)

# Dynamic linking test binary
$(TEST_DYNAMIC): $(SRC_DIR)/test001.cpp $(SHARED_LIB)
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

# Top-level verify: clean + single-compiler verification (called by run_regression.sh)
verify: verify-single
# Single-compiler verification (runs natively — inside container or on Linux host)
verify-single: static dynamic build-cpp validate-data deploy-utils

# Build C++ library (always rebuild with current CXX for multi-compiler support)
build-cpp:
	@if [ -f ../UNSUPPORTED.md ]; then echo "C++ unsupported on this platform — skipping C++ build"; else \
		echo "Building C++ library with $(CXX)..."; \
		$(MAKE) -C .. all CXX=$(CXX); \
	fi
	@mkdir -p $(LOGS_DIR) $(REPORTS_DIR)
	@if [ -f ../UNSUPPORTED.md ]; then \
		echo "=== Artifact Verification ==="; \
		echo "C++ unsupported — library checks skipped (see ../UNSUPPORTED.md)"; \
		echo ""; \
	else \
		echo "=== Artifact Verification ==="; \
		file -L $(STATIC_LIB) | grep -q "current ar archive" && echo "Static library: OK" || (echo "Static library: FAIL"; exit 1); \
		file -L $(SHARED_LIB) | grep -q "shared object" && echo "Shared library: OK" || (echo "Shared library: FAIL"; exit 1); \
		readelf -d $(SHARED_LIB) | grep -q "SONAME.*libswtr_ringbuffer.so" && echo "SONAME: OK" || (echo "SONAME: FAIL"; exit 1); \
		size $(SHARED_LIB) | tail -1 | awk '{total=$$1+$$2+$$3; print "Binary size: " total " bytes (text=" $$1 ", data=" $$2 ", bss=" $$3 ")"}'; \
		echo ""; \
	fi
	@echo "=== Audit Trail ==="
	@$(CXX) -v > $(REPORTS_DIR)/compiler_version.txt 2>&1 || true
	@ld -v >> $(REPORTS_DIR)/compiler_version.txt 2>&1 || true
	@echo "Compiler and linker versions captured"
	@echo ""
	@if [ -f ../UNSUPPORTED.md ]; then \
		echo "C++ unsupported on this platform — test matrix skipped (see ../UNSUPPORTED.md)"; \
	else \
		TEST_STATIC=$(TEST_STATIC) DATA_DIR=$(DATA_DIR) LOGS_DIR=$(LOGS_DIR) REPORTS_DIR=$(REPORTS_DIR) UTILS_DIR=$(UTILS_DIR) CXX=$(CXX) OS_NAME=Ubuntu $(UTILS_DIR)/bin/run_test_matrix.sh; \
	fi

# Clean: remove all build artifacts including parent library (needed for multi-compiler)
clean:
	@$(MAKE) -C .. clean 2>/dev/null || true
	@$(RM) $(BIN_DIR) 2>/dev/null || true
	@rm -f $(LOGS_DIR)/*.log $(LOGS_DIR)/*.exit $(LOGS_DIR)/*.time 2>/dev/null || true
	@rm -f $(REPORTS_DIR)/regression_report.md $(REPORTS_DIR)/compiler_version.txt 2>/dev/null || true
	@rm -rf $(REPORTS_DIR)/cpp/per_os 2>/dev/null || true

# Probe OS/compiler availability (manual use only — not called by other rules)
.PHONY: probe-os

PROBE_LANG = cpp

probe-os:
	@echo "Probing compiler availability for $(OS_NAME)/$(PROBE_LANG)..."
	@$(PROJECT_ROOT_DIR)/utils/bin/probe_targets.sh $(OS_NAME) $(PROBE_LANG) $(CXX)

dist-clean: clean
	@$(RM) $(LOGS_DIR) 2>/dev/null || true
	@$(RM) $(REPORTS_DIR) 2>/dev/null || true
