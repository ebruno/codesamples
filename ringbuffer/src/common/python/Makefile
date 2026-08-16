.PHONY: container container-clean

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
