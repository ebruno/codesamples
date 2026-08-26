include version.mk

# OS name for registry lookup
OS_NAME = fedora

# Project root (workspace top-level directory)
PROJECT_ROOT_DIR := $(abspath $(CURDIR)/../../../..)

# Toolchain configuration based on CXX variable
CXX ?= clang++
ifeq ($(CXX),c++)
  CXX := clang++
endif

# Normalize compiler name: strip version suffix (g++-13 → g++, clang++-17 → clang++)
CXX_BASE := $(patsubst g++-%,g++,$(patsubst clang++-%,clang++,$(CXX)))

# LTO flag: g++ uses -flto (produces native objects). clang++ on Linux produces LLVM IR
# bitcode with -flto or -flto=thin that the linker cannot link directly. Disable LTO for clang++ on Linux.
UNAME_S := $(shell uname -s)
ifeq ($(CXX_BASE),clang++)
  ifeq ($(UNAME_S),Darwin)
    LTO_FLAG = -flto=thin
  else
    LTO_FLAG =
  endif
else
  LTO_FLAG = -flto
endif
override CXXFLAGS = -std=c++20 -O3 -fPIC -Wall -Wextra -Wpedantic $(LTO_FLAG) -fvisibility=hidden -ffunction-sections -fdata-sections -I.

# Linker flags: OS-dependent + compiler-specific for thin LTO
ifeq ($(shell uname -s),Darwin)
  LDFLAGS = -dead_strip
else
  ifeq ($(strip $(CXX_BASE)),clang++)
    LDFLAGS = -Wl,--gc-sections -fuse-ld=lld
  else
    LDFLAGS = -Wl,--gc-sections
  endif
endif

RM = rm -rf

SRCS = $(wildcard *.cpp)

LIB_DIR = lib
BUILD_DIR = build

LIB_NAME = libswtr_ringbuffer
VERSIONED_STATIC = $(LIB_DIR)/$(LIB_NAME)-$(VERSION).a
VERSIONED_SHARED = $(LIB_DIR)/$(LIB_NAME)-$(VERSION).so

.PHONY: test  all static shared clean dist-clean container container-clean start_container stop_container remove_container test-all probe-os

# Container Mount Directory — resolves to workspace root from any nested Makefile
CONTAINER_MOUNT_DIR := $(abspath $(CURDIR)/../../..)

# Container Configuration
CONTAINER_IMAGE = ringbuffer_fedora_build
TARGET_OS ?= fedora
TEST_CONTAINER_IMAGE := ringbuffer_$(TARGET_OS)_test
DOCKERFILE = ../containers/build/Dockerfile

# Detect Container Runtime and Host OS (allow override from host via -e CONTAINER_CMD)
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

# When host is not Fedora (e.g. macOS), auto-build inside container
ifeq ($(INSIDE_CONTAINER),yes)
    # Already in a container - build natively
    all: clean static shared
else ifeq ($(UNAME_S),Darwin)
    all: container
	@$(CONTAINER_CMD) run --rm -v $(CONTAINER_MOUNT_DIR):/app/ringbuffer -w /app/ringbuffer/fedora/cpp $(CONTAINER_IMAGE) make all
else ifneq ($(HOST_DISTRO),fedora)
    all: container
	@$(CONTAINER_CMD) run --rm -v $(CONTAINER_MOUNT_DIR):/app/ringbuffer -w /app/ringbuffer/fedora/cpp $(CONTAINER_IMAGE) make all
else
    all: clean static shared
    test: all
endif

static: $(VERSIONED_STATIC)
	@cd $(LIB_DIR) && ln -sf libswtr_ringbuffer-$(VERSION).a libswtr_ringbuffer.a

shared: $(VERSIONED_SHARED)
	@cd $(LIB_DIR) && ln -sf libswtr_ringbuffer-$(VERSION).so libswtr_ringbuffer.so

$(VERSIONED_STATIC): $(SRCS:%.cpp=$(BUILD_DIR)/%.o)
	@mkdir -p $(LIB_DIR)
	ar rcs $(VERSIONED_STATIC) $^

$(VERSIONED_SHARED): $(SRCS:%.cpp=$(BUILD_DIR)/%.o)
	@mkdir -p $(BUILD_DIR)
	$(CXX) -shared $(LDFLAGS) -Wl,-soname,$(LIB_NAME).so -o $(VERSIONED_SHARED) $^

$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@
test: all
	@if [ -d tests ]; then $(MAKE) -C tests verify; else echo "No tests directory"; fi

clean:
	@$(RM) $(BUILD_DIR) $(LIB_DIR) *.o *~ #*#
	@find . -name '*.o.tmp' -delete 2>/dev/null || true

dist-clean: clean container-clean
	@if [ -d tests ]; then $(MAKE) -C tests dist-clean; fi
	@$(RM) reports ../reports logs

# Container Management
container:
	@if [ -z "$(CONTAINER_CMD)" ]; then \
		echo "ERROR: No container runtime found."; exit 1; \
	fi
	@if ! $(CONTAINER_CMD) image ls --quiet | grep -q "$(CONTAINER_IMAGE)"; then \
		echo "Image $(CONTAINER_IMAGE) not found. Building..."; \
		timeout 600 $(CONTAINER_CMD) build -t $(CONTAINER_IMAGE) -f $(DOCKERFILE) .; \
	else \
		echo "Image $(CONTAINER_IMAGE) already exists. Skipping build."; \
	fi
	@echo "Container environment ready."

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

container-clean:
	@if [ -z "$(CONTAINER_CMD)" ]; then \
		echo "ERROR: No container runtime found."; exit 1; \
	fi
	@echo "Removing $(CONTAINER_IMAGE)..."
	$(CONTAINER_CMD) image rm -f $(CONTAINER_IMAGE) 2>/dev/null || true

# Probe OS/compiler availability (manual use only — not called by other rules)
probe-os:
	@echo "Probing compiler availability for ${OS_NAME}/cpp..."
	@${PROJECT_ROOT_DIR}/utils/bin/probe_targets.sh ${OS_NAME} cpp
