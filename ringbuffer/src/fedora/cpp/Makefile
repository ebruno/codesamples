include version.mk

# Toolchain configuration based on CXX variable
CXX ?= clang++
ifeq ($(CXX),c++)
  CXX := clang++
endif

# LTO flag: g++ uses -flto (produces native objects). clang++ on Linux produces LLVM IR
# bitcode with -flto or -flto=thin that the linker cannot link directly. Disable LTO for clang++ on Linux.
UNAME_S := $(shell uname -s)
ifeq ($(CXX),clang++)
  ifeq ($(UNAME_S),Darwin)
    LTO_FLAG = -flto=thin
  else
    LTO_FLAG =
  endif
else
  LTO_FLAG = -flto
endif
override CXXFLAGS = -std=c++20 -O3 -fPIC -Wall -Wextra -Wpedantic $(LTO_FLAG) -fvisibility=hidden -ffunction-sections -fdata-sections -I.

# Linker flags are OS-dependent, not compiler-dependent:
ifeq ($(shell uname -s),Darwin)
  LDFLAGS = -dead_strip
else
  LDFLAGS = -Wl,--gc-sections
endif

RM = rm -rf

SRCS = $(wildcard *.cpp)

LIB_DIR = lib
BUILD_DIR = build

LIB_NAME = libswtr_ringbuffer
VERSIONED_STATIC = $(LIB_DIR)/$(LIB_NAME)-$(VERSION).a
VERSIONED_SHARED = $(LIB_DIR)/$(LIB_NAME)-$(VERSION).so

.PHONY: test  all static shared clean dist-clean container container-clean test-all

# Container Configuration
CONTAINER_IMAGE = ringbuffer_fedora_build
DOCKERFILE = ../containers/build/Dockerfile

# Detect Container Runtime and Host OS
HOST_DISTRO := $(shell cat /etc/os-release 2>/dev/null | grep '^ID=' | cut -d= -f2)
ifeq ($(UNAME_S),Darwin)
    CONTAINER_CMD = container
else
    CONTAINER_CMD = podman
endif

# Detect if already inside a container (prevent nested containers)
INSIDE_CONTAINER := $(shell test -f /.dockerenv && echo yes || echo no)

# When host is not Fedora (e.g. macOS), auto-build inside container
ifeq ($(INSIDE_CONTAINER),yes)
    # Already in a container - build natively
    all: clean static shared
else ifeq ($(UNAME_S),Darwin)
    all: container
	@$(CONTAINER_CMD) run --rm -v $$(pwd)/../..:/app/ringbuffer -w /app/ringbuffer/fedora/cpp $(CONTAINER_IMAGE) make all
else ifneq ($(HOST_DISTRO),fedora)
    all: container
	@$(CONTAINER_CMD) run --rm -v $$(pwd)/../..:/app/ringbuffer -w /app/ringbuffer/fedora/cpp $(CONTAINER_IMAGE) make all
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

container-clean:
	@if [ -z "$(CONTAINER_CMD)" ]; then \
		echo "ERROR: No container runtime found."; exit 1; \
	fi
	@echo "Removing $(CONTAINER_IMAGE)..."
	$(CONTAINER_CMD) image rm -f $(CONTAINER_IMAGE) 2>/dev/null || true
