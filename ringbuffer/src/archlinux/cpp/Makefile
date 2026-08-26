include version.mk

# OS name for registry lookup
OS_NAME = archlinux

# Project root (workspace top-level directory)
PROJECT_ROOT_DIR := $(abspath $(CURDIR)/../../../..)

# ============================================================================
# Compiler auto-detection: Arch Linux has both g++ and clang++ available
# ============================================================================

ALL_COMPILERS := g++ clang++

# Filter to only compilers that exist on the system
AVAILABLE_COMPILERS := $(foreach COMP,$(ALL_COMPILERS),\
  $(if $(shell which $(COMP) >/dev/null 2>&1 && echo found),$(COMP)))

# Default compiler (first available) — ?= respects CXX from environment
CXX ?= $(firstword $(AVAILABLE_COMPILERS))

# Normalize compiler name: strip version suffix (g++-13 → g++, clang++-17 → clang++)
CXX_BASE := $(patsubst g++-%,g++,$(patsubst clang++-%,clang++,$(CXX)))

# Archiver: use llvm-ar for clang++ (thin LTO objects), ar for g++
ifeq ($(strip $(CXX_BASE)),clang++)
  AR = llvm-ar
else
  AR = ar
endif

# ============================================================================
# Per-compiler LTO flags: g++ uses -flto, clang++ uses -flto=thin
# ============================================================================

define COMPILER_LTO_FLAGS
ifeq ($(strip $(CXX_BASE)),g++)
  LTO_FLAG := -flto
else ifeq ($(strip $(CXX_BASE)),clang++)
  LTO_FLAG := -flto=thin
endif
endef

# ============================================================================
# Build configuration (uses default CXX)
# ============================================================================

$(eval $(COMPILER_LTO_FLAGS))

override CXXFLAGS = -std=c++20 -O3 -fPIC -Wall -Wextra -Wpedantic $(LTO_FLAG) \
           -fvisibility=hidden -ffunction-sections -fdata-sections -I.

# Linker flags: ELF format (Linux)
ifeq ($(strip $(CXX_BASE)),g++)
  LDFLAGS = -Wl,--gc-sections
else ifeq ($(strip $(CXX_BASE)),clang++)
  LDFLAGS = -Wl,--gc-sections -flto=thin -fuse-ld=lld
endif

RM = rm -rf

SRCS = $(wildcard *.cpp)

LIB_NAME = libswtr_ringbuffer
LIB_DIR = lib
BUILD_DIR = build

VERSIONED_STATIC = $(LIB_DIR)/libswtr_ringbuffer-$(VERSION).a
VERSIONED_SHARED = $(LIB_DIR)/libswtr_ringbuffer-$(VERSION).so

# ============================================================================
# Container Mount Directory — resolves to workspace root from any nested Makefile
# ============================================================================
CONTAINER_MOUNT_DIR := $(abspath $(CURDIR)/../../..)

# ============================================================================
# Container Configuration (cross-platform builds)
# ============================================================================

CONTAINER_IMAGE = ringbuffer_archlinux_build
DOCKERFILE = ../containers/build/Dockerfile

# Detect Container Runtime and Host OS
UNAME_S := $(shell uname -s)
HOST_DISTRO := $(shell cat /etc/os-release 2>/dev/null | grep '^ID=' | cut -d= -f2)
ifeq ($(UNAME_S),Darwin)
    CONTAINER_CMD = container
else
    CONTAINER_CMD = podman
endif

# Detect if already inside a container (prevent nested containers)
# Check multiple indicators: IN_CONTAINER env var, /.dockerenv, /run/.containerenv, or cgroup
INSIDE_CONTAINER := $(shell if [ "$$IN_CONTAINER" = "1" ] || test -f /.dockerenv || test -f /run/.containerenv; then echo yes; elif grep -q 'docker\|kubepods\|containerd' /proc/1/cgroup 2>/dev/null; then echo yes; else echo no; fi)

# When host is not Arch Linux (e.g. macOS), auto-build inside container
ifeq ($(INSIDE_CONTAINER),yes)
    # Already in a container - build natively
    all: clean static shared
else ifeq ($(UNAME_S),Darwin)
    # macOS host - use container for cross-OS build
    all: container
	@$(CONTAINER_CMD) run --rm -v $(CONTAINER_MOUNT_DIR):/app/ringbuffer -w /app/ringbuffer/src/archlinux/cpp $(CONTAINER_IMAGE) make all
else ifneq ($(HOST_DISTRO),arch)
    # Non-Arch Linux host - use container for cross-OS build
    all: container
	@$(CONTAINER_CMD) run --rm -v $(CONTAINER_MOUNT_DIR):/app/ringbuffer -w /app/ringbuffer/src/archlinux/cpp $(CONTAINER_IMAGE) make all
else
    # Arch Linux host - build natively
    all: clean static shared
endif

.PHONY: test  all static shared clean dist-clean verify test-all container container-clean probe-os

# Always clean first for repeatability in verify_build
static: $(LIB_DIR) $(VERSIONED_STATIC)
	@cd $(LIB_DIR) && ln -sf libswtr_ringbuffer-$(VERSION).a libswtr_ringbuffer.a

shared: $(LIB_DIR) $(VERSIONED_SHARED)
	@cd $(LIB_DIR) && ln -sf libswtr_ringbuffer-$(VERSION).so libswtr_ringbuffer.so

$(LIB_DIR):
	mkdir -p $(LIB_DIR)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(VERSIONED_STATIC): $(SRCS:%.cpp=$(BUILD_DIR)/%.o)
	@mkdir -p $(LIB_DIR)
	$(AR) rcs $@ $^

$(VERSIONED_SHARED): $(SRCS:%.cpp=$(BUILD_DIR)/%.o)
	@mkdir -p $(LIB_DIR)
	$(CXX) -shared $(LDFLAGS) -Wl,-soname,$(LIB_NAME).so -o $@ $^ -pthread
	@ln -sf libswtr_ringbuffer-$(VERSION).so $(LIB_DIR)/libswtr_ringbuffer.so
	@ln -sf libswtr_ringbuffer-$(VERSION).so $(LIB_DIR)/libswtr_ringbuffer.so.1
	@echo "Shared library: $@"

test: all
	@if [ -d tests ]; then $(MAKE) -C tests verify; else echo "No tests directory"; fi

clean:
	@$(RM) $(BUILD_DIR) $(LIB_DIR) *.o *~ #*#
	@find . -name '*.o.tmp' -delete 2>/dev/null || true

dist-clean: clean container-clean
	@if [ -d tests ]; then $(MAKE) -C tests dist-clean; fi
	@$(RM) reports ../reports logs

verify: all
	@echo "=== Static Library ==="
	@file $(VERSIONED_STATIC)
	@ar t $(VERSIONED_STATIC) | head -5
	@echo ""
	@echo "=== Shared Library ==="
	@file $(VERSIONED_SHARED)
	@readelf -d $(VERSIONED_SHARED) | grep SONAME || echo "No SONAME"
	@nm -C $(VERSIONED_SHARED) | grep SwtrRingBuffer | head -5

# ============================================================================
# Container Management
# ============================================================================

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

container-clean:
	@if [ -z "$(CONTAINER_CMD)" ]; then \
		echo "ERROR: No container runtime found."; exit 1; \
	fi
	@echo "Removing $(CONTAINER_IMAGE)..."
	$(CONTAINER_CMD) image rm -f $(CONTAINER_IMAGE) 2>/dev/null || true

# ============================================================================
# Per-compiler build targets: libswtr_ringbuffer_<compiler>
# ============================================================================

define PER_COMPILER_BUILD_TARGETS
$(LIB_DIR)/libswtr_ringbuffer-$(VERSION)_$(1).a: $(SRCS)
	@mkdir -p $(LIB_DIR)
	$(1) -std=c++20 -O3 -fPIC -Wall -Wextra -Wpedantic $$(ifeq ($(1),clang++),-flto=thin,-flto) -I. -c $$^
	ar rcs $$@ $$(SRCS:%.cpp=%.o_$(1))

$(LIB_DIR)/libswtr_ringbuffer-$(VERSION)_$(1).so: $(SRCS)
	@mkdir -p $(LIB_DIR)
	$(1) -std=c++20 -O3 -fPIC -Wall -Wextra -Wpedantic $$(ifeq ($(1),clang++),-flto=thin,-flto) -I. -c $$^
	$(1) -shared $$(ifeq ($(1),clang++),-flto=thin,) -o $$@ $$(SRCS:%.cpp=%.o_$(1)) -pthread
	@ln -sf libswtr_ringbuffer-$(VERSION)_$(1).so $(LIB_DIR)/libswtr_ringbuffer_$(1).so
	@ln -sf libswtr_ringbuffer-$(VERSION)_$(1).so $(LIB_DIR)/libswtr_ringbuffer_$(1).so.1
	@echo "Shared library ($(1)): $$@"

clean_$(1):
	$(RM) $$(SRCS:%.cpp=%.o_$(1)) $(LIB_DIR)/libswtr_ringbuffer-$(VERSION)_$(1).*
endef

$(foreach COMP,$(AVAILABLE_COMPILERS),$(eval $(call PER_COMPILER_BUILD_TARGETS,$(COMP))))

# ============================================================================
# Multi-compiler build: test-all
# Builds and verifies with each available compiler.
# ============================================================================

test-all:
	@$(foreach COMP,$(AVAILABLE_COMPILERS),\
		echo "=== Building with $(COMP) ==="; \
		CXX=$(COMP) make clean; \
		CXX=$(COMP) make all; \
		echo "=== Verify $(COMP) ==="; \
		CXX=$(COMP) make verify; \
		echo ""; \
	)
	@echo "=== Multi-compiler build complete ==="

# Probe OS/compiler availability (manual use only — not called by other rules)
PROBE_COMPILER ?= $(CXX)

probe-os:
	@echo "Probing compiler availability for ${OS_NAME}/cpp..."
	@${PROJECT_ROOT_DIR}/utils/bin/probe_targets.sh ${OS_NAME} cpp $(PROBE_COMPILER)
