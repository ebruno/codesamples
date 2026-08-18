.PHONY: clean dist-clean container container-clean

# Detect container runtime based on host OS
CONTAINER_CMD := $(shell if command -v container >/dev/null 2>&1; then echo "container"; elif command -v podman >/dev/null 2>&1; then echo "podman"; else echo ""; fi)

# Container image names
PYTHON_BUILD_IMAGES  := ringbuffer_python_debian ringbuffer_python_fedora ringbuffer_python_ubuntu ringbuffer_python_raspios
PYTHON_TEST_IMAGES   := ringbuffer_python_debian_test ringbuffer_python_fedora_test ringbuffer_python_ubuntu_test ringbuffer_python_raspios_test

# OS → uppercase mapping (no shell calls needed)
OS_DEBIAN_UC    := DEBIAN
OS_UBUNTU_UC    := UBUNTU
OS_FEDORA_UC    := FEDORA
OS_RASPIOS_UC   := RASPIOS

# Lowercase OS → uppercase mapping for variable lookup
OS_debian_UC    := DEBIAN
OS_ubuntu_UC    := UBUNTU
OS_fedora_UC    := FEDORA
OS_raspios_UC   := RASPIOS

container: container-build-debian container-test-debian \
           container-build-fedora container-test-fedora \
           container-build-ubuntu container-test-ubuntu \
           container-build-raspios container-test-raspios

container-build-%:
	@if [ -z "$(CONTAINER_CMD)" ]; then \
		echo "ERROR: No container runtime found."; exit 1; \
	fi
	@if [ ! -f containers/$*/build/Dockerfile ]; then \
		echo "No build Dockerfile for $*"; exit 1; \
	fi
	@if ! $(CONTAINER_CMD) image ls --quiet | grep -q "ringbuffer_python_$*"; then \
		echo "Building ringbuffer_python_$* ..."; \
		timeout 600 $(CONTAINER_CMD) build \
			-t ringbuffer_python_$* \
			-f containers/$*/build/Dockerfile .; \
	else \
		echo "ringbuffer_python_$* already exists. Skipping."; \
	fi

container-test-%: container-build-%
	@if [ -z "$(CONTAINER_CMD)" ]; then \
		echo "ERROR: No container runtime found."; exit 1; \
	fi
	@if [ ! -f containers/$*/test/Dockerfile ]; then \
		echo "No test Dockerfile for $*"; exit 1; \
	fi
	@if ! $(CONTAINER_CMD) image ls --quiet | grep -q "ringbuffer_python_$*_test"; then \
		echo "Building ringbuffer_python_$*_test ..."; \
		timeout 600 $(CONTAINER_CMD) build \
			-t ringbuffer_python_$*_test \
			-f containers/$*/test/Dockerfile .; \
	else \
		echo "ringbuffer_python_$*_test already exists. Skipping."; \
	fi

container-clean:
	@for img in $(PYTHON_BUILD_IMAGES) $(PYTHON_TEST_IMAGES); do \
		echo "Removing $$img"; \
		$(CONTAINER_CMD) image rm -f $$img 2>/dev/null || true; \
	done

.PHONY: test syntax-check

# Syntax check — catches broken Python files before they're committed
syntax-check:
	@echo "Syntax checking Python files..."
	python3 -m py_compile swtr_ringbuffer_pure.py || { echo "FAIL: swtr_ringbuffer_pure.py has syntax errors"; exit 1; }
	python3 -m py_compile test_ringbuffer.py || { echo "FAIL: test_ringbuffer.py has syntax errors"; exit 1; }
	python3 -m py_compile test_ringbuffer_pure.py || { echo "FAIL: test_ringbuffer_pure.py has syntax errors"; exit 1; }
	@echo "Syntax check passed."

# Run all tests for both harnesses — validates CLI, execution, and output correctness
test: syntax-check
	@echo ""
	@echo "=== Running Concurrent harness (test_ringbuffer.py) ==="
	@PASS=0; FAIL=0; \
	for t in 1 2 3 4 5 6 7; do \
		RESULT=$$(echo 'Hello, World! This is a test input for the ringbuffer pipeline.' | python3 test_ringbuffer.py $$t 2>&1); \
		EXIT=$$?; \
		echo "  T00$$t: $$RESULT"; \
		if [ $$EXIT -ne 0 ]; then FAIL=$$((FAIL+1)); else PASS=$$((PASS+1)); fi; \
	done; \
	echo "Concurrent: $$PASS passed, $$FAIL failed"; \
	if [ $$FAIL -ne 0 ]; then echo "CONCURRENT HARNES FAILED"; exit 1; fi
	@echo ""
	@echo "=== Running Pure Python harness (test_ringbuffer_pure.py) ==="
	@PASS=0; FAIL=0; \
	for t in 1 2 3 4 5 6 7; do \
		RESULT=$$(echo 'Hello, World! This is a test input for the ringbuffer pipeline.' | python3 test_ringbuffer_pure.py $$t 2>&1); \
		EXIT=$$?; \
		echo "  T00$$t: $$RESULT"; \
		if [ $$EXIT -ne 0 ]; then FAIL=$$((FAIL+1)); else PASS=$$((PASS+1)); fi; \
	done; \
	echo "Pure Python: $$PASS passed, $$FAIL failed"; \
	if [ $$FAIL -ne 0 ]; then echo "PURE PYTHON HARNES FAILED"; exit 1; fi
	@echo ""
	@echo "=== All tests passed ==="

# Clean build artifacts (Python bytecode, egg-info, build dirs)
clean:
	@echo "Cleaning Python build artifacts..."
	@if [ -d __pycache__ ]; then \
		rm -rf __pycache__; \
		echo "  Removed __pycache__/"; \
	else \
		echo "  Nothing to clean."; \
	fi
	@find . -name "*.pyc" -delete 2>/dev/null || true
	@if [ -d .egg-info ]; then \
		rm -rf .egg-info; \
		echo "  Removed .egg-info/"; \
	else \
		echo "  Nothing to clean."; \
	fi
	@if [ -d build ]; then \
		rm -rf build; \
		echo "  Removed build/"; \
	else \
		echo "  Nothing to clean."; \
	fi

# Full cleanup: build artifacts + container images + test output
dist-clean: clean container-clean
	@for dir in logs reports; do \
		rm -rf $$dir 2>/dev/null || true; \
	done
	@echo "Python dist-clean complete."
