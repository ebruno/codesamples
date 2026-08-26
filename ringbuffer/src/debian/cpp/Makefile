include version.mk

# OS name for registry lookup
OS_NAME = debian

# Project root (workspace top-level directory)
PROJECT_ROOT_DIR := $(abspath $(CURDIR)/../../../..)

# Toolchain
CXX ?= g++
# Normalize compiler name: strip version suffix (g++-13 → g++, clang++-17 → clang++)
CXX_BASE := $(patsubst g++-%,g++,$(patsubst clang++-%,clang++,$(CXX)))

# LTO flag: g++ uses -flto (produces native objects). clang++ on Linux produces LLVM IR
# bitcode with -flto or -flto=thin that the linker cannot link directly. Disable LTO for clang++ on Linux.
UNAME_S := $(shell uname -s)
ifeq ($(CXX_BASE),clang++)
  LTO_FLAG =
else
  LTO_FLAG = -flto
endif
override CXXFLAGS = -std=c++20 -fPIC -Wall -Wextra -Wpedantic -O3 $(LTO_FLAG) \
           -fvisibility=hidden -ffunction-sections -fdata-sections -I.
# Linker flags: compiler-specific for thin LTO
ifeq ($(strip $(CXX_BASE)),clang++)
  LDFLAGS = -Wl,--gc-sections -fuse-ld=lld
else
  LDFLAGS = -Wl,--gc-sections
endif

# Versioning
LIB_NAME = libswtr_ringbuffer
VERSIONED_NAME = $(LIB_NAME)-$(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID)

# Artifacts
LIB_DIR = lib
BUILD_DIR = build
STATIC_LIB = $(LIB_DIR)/$(VERSIONED_NAME).a
SHARED_LIB = $(LIB_DIR)/$(VERSIONED_NAME).so

# Sources
SRCS = Lifecycle.cpp \
       Threading.cpp \
       ReadOps.cpp \
       TransformOps.cpp \
       WriteOps.cpp \
       ErrorOps.cpp \
       LoggingOps_1.cpp \
       LoggingOps_2.cpp \
       LoggingOps_3.cpp \
       LoggingOps_4.cpp \
       LoggingOps_5.cpp \
       LoggingOps_6.cpp \
       Accessors_Status.cpp \
       Accessors_ChecksumAlg.cpp \
       Accessors_ChecksumVal.cpp \
       Accessors_Size_Max.cpp \
       Accessors_Size_Data.cpp \
       Accessors_Size_Transformed.cpp

OBJS = $(patsubst %.cpp, $(BUILD_DIR)/%.o, $(SRCS))

# Utilities
RM = rm -rf
JOBS ?= 1

# Container Mount Directory — resolves to workspace root from any nested Makefile
CONTAINER_MOUNT_DIR := $(abspath $(CURDIR)/../../..)

# Container Configuration
CONTAINER_IMAGE = ringbuffer_debian_build
DOCKERFILE = ../containers/build/Dockerfile

# Detect Container Runtime and Host OS (allow override from host via -e CONTAINER_CMD)
UNAME_S := $(shell uname -s)
HOST_DISTRO := $(shell cat /etc/os-release 2>/dev/null | grep '^ID=' | cut -d= -f2)
ifeq ($(CONTAINER_CMD),)
    ifeq ($(UNAME_S),Darwin)
        CONTAINER_CMD = container
    else
        CONTAINER_CMD = podman
    endif
endif

# Detect if already inside a container (prevent nested containers)
# Check multiple indicators: IN_CONTAINER env var, /.dockerenv, /run/.containerenv, or cgroup
INSIDE_CONTAINER := $(shell if [ "$$IN_CONTAINER" = "1" ] || test -f /.dockerenv || test -f /run/.containerenv; then echo yes; elif grep -q 'docker\|kubepods\|containerd' /proc/1/cgroup 2>/dev/null; then echo yes; else echo no; fi)

# When host is not Debian (e.g. macOS), auto-build inside container
# This conditional logic ensures cross-OS builds use containers automatically
ifeq ($(INSIDE_CONTAINER),yes)
    # Already in a container - build natively
    all: clean $(STATIC_LIB) $(SHARED_LIB)
else ifeq ($(UNAME_S),Darwin)
    # macOS host - use container for cross-OS build
    all: container
	@$(CONTAINER_CMD) run --rm -v $(CONTAINER_MOUNT_DIR):/app/ringbuffer -w /app/ringbuffer/debian/cpp $(CONTAINER_IMAGE) make all
else ifneq ($(HOST_DISTRO),debian)
    # Non-Debian Linux host - use container for cross-OS build
    all: container
	@$(CONTAINER_CMD) run --rm -v $(CONTAINER_MOUNT_DIR):/app/ringbuffer -w /app/ringbuffer/debian/cpp $(CONTAINER_IMAGE) make all
else
    # Debian host - build natively
    all: clean $(STATIC_LIB) $(SHARED_LIB)
endif

.PHONY: test  all static shared clean dist-clean container container-clean lint format test-all probe-os

# Static Library Target
static: $(STATIC_LIB)
	@echo "Static library built: $(STATIC_LIB)"

# Shared Library Target
shared: $(SHARED_LIB)
	@echo "Shared library built: $(SHARED_LIB)"

# Static Library
$(STATIC_LIB): $(OBJS)
	@mkdir -p $(LIB_DIR)
	ar rcs $@ $^
	@cd $(LIB_DIR) && ln -sf $(VERSIONED_NAME).a $(LIB_NAME).a

# Shared Library
$(SHARED_LIB): $(OBJS)
	@mkdir -p $(LIB_DIR)
	$(CXX) $(LDFLAGS) -shared -Wl,-soname,$(LIB_NAME).so -o $@ $^
	@cd $(LIB_DIR) && ln -sf $(VERSIONED_NAME).so $(LIB_NAME).so

# Object Files
$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@
# Auto-container for test when host is not debian
ifeq ($(UNAME_S),Darwin)
    test: container
	@$(CONTAINER_CMD) run --rm -v $(CONTAINER_MOUNT_DIR):/app/ringbuffer -w /app/ringbuffer/debian/cpp $(CONTAINER_IMAGE) make test
else ifneq ($(HOST_DISTRO),debian)
    test: container
	@$(CONTAINER_CMD) run --rm -v $(CONTAINER_MOUNT_DIR):/app/ringbuffer -w /app/ringbuffer/debian/cpp $(CONTAINER_IMAGE) make test
else
    test: all
endif

clean:
	@$(RM) $(BUILD_DIR) $(LIB_DIR) *.o "*.o" "*~" "#*#"
	@find . -name '*.o.tmp' -delete 2>/dev/null || true

dist-clean: clean container-clean
	@if [ -d tests ]; then $(MAKE) -C tests dist-clean; fi
	@$(RM) reports ../reports logs



# Container Management
container:
	@mkdir -p logs
	@echo "Checking build container..."
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
		echo "Image $(CONTAINER_IMAGE) already exists. Skipping build."; \
	fi
	@echo "Container environment ready."

container-clean:
	@echo "Removing build container image..."
	@$(CONTAINER_CMD) image rm -f $(CONTAINER_IMAGE) 2>/dev/null || true
	@echo "Container environment cleaned."

# Container Health Check
container-info:
	@echo "Container runtime: $(CONTAINER_CMD)"
	@if $(CONTAINER_CMD) info >/dev/null 2>&1; then \
		echo "Container service: RUNNING"; \
	else \
		echo "Container service: NOT RUNNING"; \
	fi
	@echo "Available images:"
	@$(CONTAINER_CMD) image ls --quiet | grep ringbuffer || echo "  (none)"

# Build Only (no container, no tests)
build-only:
	@echo "Building library only..."
	$(MAKE) clean
	$(MAKE) all
	@echo "Build complete. Artifacts in lib/"

# Optional lint and format targets (requires clang-tidy / clang-format)
lint:
	@echo "Running clang-tidy..."
	@for f in *.cpp; do \
		clang-tidy $$f -- $(CXXFLAGS) -I. 2>/dev/null || true; \
	done
	@echo "Lint complete."

format:
	@echo "Running clang-format..."
	@for f in *.cpp *.hpp; do \
		clang-format -i $$f 2>/dev/null || true; \
	done
	@echo "Format complete."

# ── Container Lifecycle Rules (persistent container for test execution) ──

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
			-v $(CONTAINER_MOUNT_DIR):/app/ringbuffer \
			-w /app/ringbuffer/src/$(TARGET_OS)/cpp \
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

# Probe OS/compiler availability (manual use only — not called by other rules)
probe-os:
	@echo "Probing compiler availability for ${OS_NAME}/cpp..."
	@${PROJECT_ROOT_DIR}/utils/bin/probe_targets.sh ${OS_NAME} cpp
