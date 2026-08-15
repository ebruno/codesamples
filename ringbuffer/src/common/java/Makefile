.PHONY: container container-clean

# Detect container runtime based on host OS
CONTAINER_CMD := $(shell if command -v container >/dev/null 2>&1; then echo "container"; elif command -v podman >/dev/null 2>&1; then echo "podman"; else echo ""; fi)

# Container image names
JAVA_BUILD_IMAGES  := ringbuffer_java_debian ringbuffer_java_fedora ringbuffer_java_ubuntu ringbuffer_java_raspios
JAVA_TEST_IMAGES   := ringbuffer_java_debian_test ringbuffer_java_fedora_test ringbuffer_java_ubuntu_test ringbuffer_java_raspios_test

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
	@if ! $(CONTAINER_CMD) image ls --quiet | grep -q "ringbuffer_java_$$*"; then \
		echo "Building ringbuffer_java_$$* ..."; \
		timeout 600 $(CONTAINER_CMD) build -t ringbuffer_java_$$* -f containers/$*/build/Dockerfile .; \
	else \
		echo "ringbuffer_java_$$* already exists. Skipping."; \
	fi

container-test-%: container-build-%
	@if [ -z "$(CONTAINER_CMD)" ]; then \
		echo "ERROR: No container runtime found."; exit 1; \
	fi
	@if [ ! -f containers/$*/test/Dockerfile ]; then \
		echo "No test Dockerfile for $*"; exit 1; \
	fi
	@if ! $(CONTAINER_CMD) image ls --quiet | grep -q "ringbuffer_java_$$*_test"; then \
		echo "Building ringbuffer_java_$$*_test ..."; \
		timeout 600 $(CONTAINER_CMD) build -t ringbuffer_java_$$*_test -f containers/$*/test/Dockerfile .; \
	else \
		echo "ringbuffer_java_$$*_test already exists. Skipping."; \
	fi

container-clean:
	@for img in $(JAVA_BUILD_IMAGES) $(JAVA_TEST_IMAGES); do \
		echo "Removing $$img"; \
		$(CONTAINER_CMD) image rm -f $$img 2>/dev/null || true; \
	done
