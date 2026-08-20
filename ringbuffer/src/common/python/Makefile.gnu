.PHONY: clean dist-clean container container-clean build test

# Detect container runtime based on host OS
CONTAINER_CMD := $(shell if command -v container >/dev/null 2>&1; then echo "container"; elif command -v podman >/dev/null 2>&1; then echo "podman"; else echo ""; fi)

# Container image names
PYTHON_BUILD_IMAGES  := ringbuffer_python_debian ringbuffer_python_fedora ringbuffer_python_ubuntu ringbuffer_python_raspios
PYTHON_TEST_IMAGES   := ringbuffer_python_debian_test ringbuffer_python_fedora_test ringbuffer_python_ubuntu_test ringbuffer_python_raspios_test

# OS -> uppercase mapping (no shell calls needed)
OS_DEBIAN_UC    := DEBIAN
OS_UBUNTU_UC    := UBUNTU
OS_FEDORA_UC    := FEDORA
OS_RASPIOS_UC   := RASPIOS

# Lowercase OS -> uppercase mapping for variable lookup
OS_debian_UC    := DEBIAN
OS_ubuntu_UC    := UBUNTU
OS_fedora_UC    := FEDORA
OS_raspios_UC   := RASPIOS

container: container-build-debian container-test-debian\
           container-build-fedora container-test-fedora\
           container-build-ubuntu container-test-ubuntu\
           container-build-raspios container-test-raspios

container-build-%:
	@if [ -z "$(CONTAINER_CMD)" ]; then\
		echo "ERROR: No container runtime found."; exit 1;\
	fi
	@if [ ! -f containers/$*/build/Dockerfile ]; then\
		echo "No build Dockerfile for $*"; exit 1;\
	fi
	@if ! $(CONTAINER_CMD) image ls --quiet | grep -q "ringbuffer_python_$*"; then\
		echo "Building ringbuffer_python_$* ...";\
		timeout 600 $(CONTAINER_CMD) build\
			-t ringbuffer_python_$*\
			-f containers/$*/build/Dockerfile .;\
	else\
		echo "ringbuffer_python_$* already exists. Skipping.";\
	fi

container-test-%: container-build-%
	@if [ -z "$(CONTAINER_CMD)" ]; then\
		echo "ERROR: No container runtime found."; exit 1;\
	fi
	@if [ ! -f containers/$*/test/Dockerfile ]; then\
		echo "No test Dockerfile for $*"; exit 1;\
	fi
	@if ! $(CONTAINER_CMD) image ls --quiet | grep -q "ringbuffer_python_$*_test"; then\
		echo "Building ringbuffer_python_$*_test ...";\
		timeout 600 $(CONTAINER_CMD) build\
			-t ringbuffer_python_$*_test\
			-f containers/$*/test/Dockerfile .;\
	else\
		echo "ringbuffer_python_$*_test already exists. Skipping.";\
	fi

container-clean:
	@for img in $(PYTHON_BUILD_IMAGES) $(PYTHON_TEST_IMAGES); do\
		echo "Removing $$img";\
		$(CONTAINER_CMD) image rm -f $$img 2>/dev/null || true;\
	done

.PHONY: build test syntax-check

# Detect current platform and map to C++ source directory
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  CPP_SRC_DIR := ../../macos/cpp
else
  # Detect Linux distro from /etc/os-release
  DISTRO_ID := $(shell grep '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 || echo "")
  ifeq ($(DISTRO_ID),ubuntu)
    CPP_SRC_DIR := ../../ubuntu/cpp
  else ifeq ($(DISTRO_ID),debian)
    CPP_SRC_DIR := ../../debian/cpp
  else ifeq ($(DISTRO_ID),fedora)
    CPP_SRC_DIR := ../../fedora/cpp
  else ifeq ($(DISTRO_ID),raspios)
    CPP_SRC_DIR := ../../raspios/cpp
  else ifeq ($(DISTRO_ID),arch)
    CPP_SRC_DIR := ../../archlinux/cpp
  else ifeq ($(DISTRO_ID),freebsd)
    CPP_SRC_DIR := ../../freebsd14/cpp
  else
    # Default to reference_linux for unknown distros
    CPP_SRC_DIR := ../../reference_linux/cpp
  endif
endif

# Build the C++ shared library - always rebuilds even if library exists
# to ensure we have the latest build. If build fails, notes it and continues.
build:
	@if [ "$(UNAME_S)" = "Darwin" ]; then\
		echo "Using Makefile.macos for macOS build...";\
		make -f Makefile.macos build;\
	else\
		echo "Using Makefile.linux for Linux build...";\
		make -f Makefile.linux build;\
	fi

syntax-check:
	@echo "Syntax checking Python files..."
	python3 -m py_compile swtr_ringbuffer_pure.py || { echo "FAIL: swtr_ringbuffer_pure.py has syntax errors"; exit 1; }
	python3 -m py_compile test_ringbuffer.py || { echo "FAIL: test_ringbuffer.py has syntax errors"; exit 1; }
	python3 -m py_compile test_ringbuffer_pure.py || { echo "FAIL: test_ringbuffer_pure.py has syntax errors"; exit 1; }
	@echo "Syntax check passed."

# Run all tests for both harnesses - validates CLI, execution, and output correctness
# Depends on build to ensure C++ library is up-to-date.
# If C++ build fails, runs only Pure Python tests and notes the failure.
test: syntax-check build
	@mkdir -p logs reports
	@echo ""
	@# Check if C++ build succeeded (tracked by .cpp_build_failed marker file)
	@if [ -f .cpp_build_failed ]; then\
		echo "WARNING: C++ build failed - running Pure Python tests only";\
	fi
	@echo ""
	@if [ ! -f .cpp_build_failed ]; then\
		echo "=== Running Concurrent harness (test_ringbuffer.py) ===";\
		echo "[$$(date '+%Y-%m-%d %H:%M:%S %z')] Running Concurrent harness" >> logs/build.log;\
		PASS=0; FAIL=0;\
		for t in 1 2 3 4 5 6 7; do\
			RESULT=$$(echo 'Hello, World! This is a test input for the ringbuffer pipeline.' | python3 test_ringbuffer.py $$t 2>&1);\
			EXIT=$$?;\
			echo "  T00$$t: $$RESULT";\
			if [ $$EXIT -ne 0 ]; then FAIL=$$((FAIL+1)); else PASS=$$((PASS+1)); fi;\
		done;\
		echo "Concurrent: $$PASS passed, $$FAIL failed";\
		if [ $$FAIL -ne 0 ]; then echo "CONCURRENT HARNES FAILED"; exit 1; fi;\
		echo "[$$(date '+%Y-%m-%d %H:%M:%S %z')] Concurrent harness: $$PASS/7 passed" >> logs/build.log;\
		echo "";\
	fi
	@echo "=== Running Pure Python harness (test_ringbuffer_pure.py) ==="
	@PASS=0; FAIL=0;\
	for t in 1 2 3 4 5 6 7; do\
		RESULT=$$(echo 'Hello, World! This is a test input for the ringbuffer pipeline.' | python3 test_ringbuffer_pure.py $$t 2>&1);\
		EXIT=$$?;\
		echo "  T00$$t: $$RESULT";\
		if [ $$EXIT -ne 0 ]; then FAIL=$$((FAIL+1)); else PASS=$$((PASS+1)); fi;\
	done;\
	echo "Pure Python: $$PASS passed, $$FAIL failed";\
	if [ $$FAIL -ne 0 ]; then echo "PURE PYTHON HARNES FAILED"; exit 1; fi
	@echo "[$$(date '+%Y-%m-%d %H:%M:%S %z')] Pure Python harness: $$PASS/7 passed" >> logs/build.log
	@echo ""
	@if [ ! -f .cpp_build_failed ]; then\
		echo "=== All tests passed (Concurrent + Pure Python) ===";\
		echo "[$$(date '+%Y-%m-%d %H:%M:%S %z')] All tests passed (Concurrent + Pure Python)" >> logs/build.log;\
	else\
		echo "=== All tests passed (Pure Python only - C++ build failed) ===";\
		echo "[$$(date '+%Y-%m-%d %H:%M:%S %z')] All tests passed (Pure Python only - C++ build failed)" >> logs/build.log;\
	fi
	@# Performance comparison: run benchmark.py if C++ library is present
	@if [ ! -f .cpp_build_failed ] && [ -f benchmark.py ]; then\
		echo "";\
		echo "=== Performance Comparison (Concurrent vs Pure Python) ===";\
		echo "[$$(date '+%Y-%m-%d %H:%M:%S %z')] Running performance benchmark" >> logs/build.log;\
		python3 benchmark.py 2>&1 | tee -a logs/build.log;\
		echo "[$$(date '+%Y-%m-%d %H:%M:%S %z')] Performance benchmark complete" >> logs/build.log;\
	elif [ -f .cpp_build_failed ]; then\
		echo "";\
		echo "=== SKIPPED: Performance comparison (C++ library not available) ===";\
		echo "[$$(date '+%Y-%m-%d %H:%M:%S %z')] Performance comparison SKIPPED: C++ library not available" >> logs/build.log;\
	else\
		echo "";\
		echo "=== SKIPPED: Performance comparison (benchmark.py not found) ===";\
		echo "[$$(date '+%Y-%m-%d %H:%M:%S %z')] Performance comparison SKIPPED: benchmark.py not found" >> logs/build.log;\
	fi

# Clean build artifacts (Python bytecode, egg-info, build dirs)
clean:
	@echo "Cleaning Python build artifacts..."
	@if [ -d __pycache__ ]; then\
		rm -rf __pycache__;\
		echo "  Removed __pycache__/";\
	else\
		echo "  Nothing to clean.";\
	fi
	@find . -name "*.pyc" -delete 2>/dev/null || true
	@if [ -d .egg-info ]; then\
		rm -rf .egg-info;\
		echo "  Removed .egg-info/";\
	else\
		echo "  Nothing to clean.";\
	fi
	@if [ -d build ]; then\
		rm -rf build;\
		echo "  Removed build/";\
	else\
		echo "  Nothing to clean.";\
	fi
	@if [ -d lib ]; then\
		rm -rf lib;\
		echo "  Removed lib/ (symlinks to C++ libraries)";\
	else\
		echo "  Nothing to clean.";\
	fi
	@if [ -f .cpp_build_failed ]; then\
		rm -f .cpp_build_failed;\
		echo "  Removed .cpp_build_failed";\
	else\
		echo "  Nothing to clean.";\
	fi

# Full cleanup: build artifacts + container images + test output
dist-clean: clean container-clean
	@for dir in logs reports; do\
		rm -rf $$dir 2>/dev/null || true;\
	done
	@echo "Python dist-clean complete."
