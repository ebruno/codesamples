.PHONY: container container-clean

# Detect container runtime based on host OS
CONTAINER_CMD := $(shell if command -v container >/dev/null 2>&1; then echo "container"; elif command -v podman >/dev/null 2>&1; then echo "podman"; else echo ""; fi)

# Container image names (Python only has test images currently)
PYTHON_TEST_IMAGES := ringbuffer_python_debian_test ringbuffer_python_fedora_test ringbuffer_python_ubuntu_test

container: container-test-debian container-test-fedora container-test-ubuntu

container-test-%:
	@if [ -z "$(CONTAINER_CMD)" ]; then \
		echo "ERROR: No container runtime found."; exit 1; \
	fi
	@if [ ! -f containers/$*/Dockerfile ]; then \
		echo "No Dockerfile for $*"; exit 1; \
	fi
	@if ! $(CONTAINER_CMD) image ls --quiet | grep -q "ringbuffer_python_$$*_test"; then \
		echo "Building ringbuffer_python_$$*_test ..."; \
		timeout 600 $(CONTAINER_CMD) build -t ringbuffer_python_$$*_test -f containers/$*/Dockerfile .; \
	else \
		echo "ringbuffer_python_$$*_test already exists. Skipping."; \
	fi

container-clean:
	@for img in $(PYTHON_TEST_IMAGES); do \
		echo "Removing $$img"; \
		$(CONTAINER_CMD) image rm -f $$img 2>/dev/null || true; \
	done
