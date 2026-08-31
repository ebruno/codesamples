.PHONY: all clean dist-clean container container-clean test

# Target OS for cross-platform builds (set by verify_build: TARGET_OS=fedora, etc.)
TARGET_OS ?=

# Detect container runtime based on host OS
CONTAINER_CMD := $(shell if command -v container >/dev/null 2>&1; then echo "container"; elif command -v podman >/dev/null 2>&1; then echo "podman"; else echo ""; fi)

# Global JDK version (default 25, overridable from command line)
JDKVER ?= 25

# Per-OS JDK version overrides (inherit global default unless overridden)
JDKVER_DEBIAN    ?= $(JDKVER)
JDKVER_UBUNTU    ?= $(JDKVER)
JDKVER_FEDORA    ?= $(JDKVER)
JDKVER_RASPIOS   ?= 17

# Container image names (unified OS-level, shared across all languages)
OS_BUILD_IMAGES  := ringbuffer_debian_build ringbuffer_fedora_build ringbuffer_ubuntu_build ringbuffer_raspios_build
OS_TEST_IMAGES   := ringbuffer_debian_test ringbuffer_fedora_test ringbuffer_ubuntu_test ringbuffer_raspios_test

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

# Lowercase OS → directory name mapping (for Dockerfile paths)
OS_debian_DIR   := debian
OS_ubuntu_DIR   := ubuntu
OS_fedora_DIR   := fedora
OS_raspios_DIR  := raspios

container: container-build-debian container-test-debian \
           container-build-fedora container-test-fedora \
           container-build-ubuntu container-test-ubuntu \
           container-build-raspios container-test-raspios

container-build-%:
	@if [ -z "$(CONTAINER_CMD)" ]; then \
		echo "ERROR: No container runtime found."; exit 1; \
	fi
	@if [ ! -f ../../$(OS_$*_DIR)/containers/build/Dockerfile ]; then \
		echo "No build Dockerfile for $*"; exit 1; \
	fi
	@if ! $(CONTAINER_CMD) image ls --quiet | grep -q "ringbuffer_$*_build"; then \
		echo "Building ringbuffer_$*_build ..."; \
		timeout 600 $(CONTAINER_CMD) build \
			--build-arg JDKVER=$(JDKVER_$(OS_$*_UC)) \
			-t ringbuffer_$*_build \
			-f ../../$(OS_$*_DIR)/containers/build/Dockerfile .; \
	else \
		echo "ringbuffer_$*_build already exists. Skipping."; \
	fi

container-test-%: container-build-%
	@if [ -z "$(CONTAINER_CMD)" ]; then \
		echo "ERROR: No container runtime found."; exit 1; \
	fi
	@if [ ! -f ../../$(OS_$*_DIR)/containers/test/Dockerfile ]; then \
		echo "No test Dockerfile for $*"; exit 1; \
	fi
	@if ! $(CONTAINER_CMD) image ls --quiet | grep -q "ringbuffer_$*_test"; then \
		echo "Building ringbuffer_$*_test ..."; \
		timeout 600 $(CONTAINER_CMD) build \
			-t ringbuffer_$*_test \
			-f ../../$(OS_$*_DIR)/containers/test/Dockerfile .; \
	else \
		echo "ringbuffer_$*_test already exists. Skipping."; \
	fi

container-clean:
	@for img in $(OS_BUILD_IMAGES) $(OS_TEST_IMAGES); do \
		echo "Removing $$img"; \
		$(CONTAINER_CMD) image rm -f $$img 2>/dev/null || true; \
	done

# Start a persistent container for test execution (image stays)
start_container:
	@if [ -z "$(CONTAINER_CMD)" ]; then\
		echo "ERROR: No container runtime found."; exit 1;\
	fi
	@if $(CONTAINER_CMD) list --all 2>/dev/null | grep -q "ringbuffer_$(TARGET_OS)_test_running"; then\
		echo "Container ringbuffer_$(TARGET_OS)_test already running."; \
	else\
		echo "Starting persistent container: ringbuffer_$(TARGET_OS)_test";\
		$(CONTAINER_CMD) run --detach --name "ringbuffer_$(TARGET_OS)_test_running" \
			-v $(abspath ../../..):/app/ringbuffer \
			-w /app/ringbuffer \
			ringbuffer_$(TARGET_OS)_test tail -f /dev/null;\
	fi

# Stop the persistent container (image stays, container remains on disk)
stop_container:
	@if [ -z "$(CONTAINER_CMD)" ]; then\
		echo "ERROR: No container runtime found."; exit 1;\
	fi
	@if $(CONTAINER_CMD) list --all 2>/dev/null | grep -q "ringbuffer_$(TARGET_OS)_test_running"; then\
		echo "Stopping container: ringbuffer_$(TARGET_OS)_test";\
		$(CONTAINER_CMD) stop "ringbuffer_$(TARGET_OS)_test_running" 2>/dev/null || true;\
	else\
		echo "No running container found for ringbuffer_$(TARGET_OS)_test.";\
	fi

# Remove the persistent container (image stays)
remove_container:
	@if [ -z "$(CONTAINER_CMD)" ]; then\
		echo "ERROR: No container runtime found."; exit 1;\
	fi
	@if $(CONTAINER_CMD) list --all 2>/dev/null | grep -q "ringbuffer_$(TARGET_OS)_test_running"; then\
		echo "Removing container: ringbuffer_$(TARGET_OS)_test";\
		$(CONTAINER_CMD) rm "ringbuffer_$(TARGET_OS)_test_running" 2>/dev/null || true;\
	else\
		echo "No container found for ringbuffer_$(TARGET_OS)_test.";\
	fi

# Clean build artifacts (Maven target directory)
clean:
	@echo "Cleaning Java build artifacts..."
	@if [ -d target ]; then \
		rm -rf target; \
		echo "  Removed target/"; \
	else \
		echo "  Nothing to clean."; \
	fi

# Build: compile and package (no tests).
# Auto-container: if on macOS or non-matching host, run inside target OS container.
# Container images use ringbuffer_<os>_build (unified naming).
all: clean
	@echo "Building Java ringbuffer..."
	@./version.sh 2>&1
	@mvn package -DskipTests -q 2>&1 || { echo "ERROR: mvn package failed"; exit 1; }
	@mkdir -p lib
	@for jar in target/ringbuffer-*.jar; do \
		case "$$jar" in *-sources*) continue ;; esac; \
		ln -sf "../$$jar" lib/ringbuffer.jar; \
		break; \
	done
	@echo "Java build complete."

all-container:
	@echo "Building Java ringbuffer in container..."
	@./version.sh 2>&1
	@mvn package -DskipTests -q 2>&1 || { echo "ERROR: mvn package failed"; exit 1; }
	@mkdir -p lib
	@for jar in target/ringbuffer-*.jar; do \
		case "$$jar" in *-sources*) continue ;; esac; \
		ln -sf "../$$jar" lib/ringbuffer.jar; \
		break; \
	done
	@echo "Java build complete."

# Cross-OS container build entry point (called by run_build scripts)
ifeq ($(UNAME_S),Darwin)
container-build: container-build-$(TARGET_OS)
	@$(CONTAINER_CMD) run --rm --network default \
		-v $(abspath ../../..):/app/ringbuffer \
		-w /app/ringbuffer \
		ringbuffer_$(TARGET_OS)_build sh -c "cd src/common/java && make all-container"
else
    HOST_DISTRO := $(shell cat /etc/os-release 2>/dev/null | grep '^ID=' | cut -d= -f2)
    ifneq ($(HOST_DISTRO),$(TARGET_OS))
container-build: container-build-$(TARGET_OS)
	@$(CONTAINER_CMD) run --rm --network default \
		-v $(abspath ../../..):/app/ringbuffer \
		-w /app/ringbuffer \
		ringbuffer_$(TARGET_OS)_build sh -c "cd src/common/java && make all-container"
    else
container-build:
	@echo "Native build (host matches target) — use 'make all' directly"
	@$(MAKE) all
    endif
endif

# Run full build + tests via Maven
test: clean
	@echo "Running Java test suite..."
	mvn clean test -q 2>&1 || { echo "ERROR: mvn test failed"; exit 1; }
	@echo "Java tests passed."

# Full cleanup: build artifacts + container images
# Note: reports are managed at top-level reports/java/per_os/
# Per-platform runs clean only their own report files before regenerating
dist-clean: clean container-clean
	@rm -rf logs 2>/dev/null || true
	@echo "Java dist-clean complete."
