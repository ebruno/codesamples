include version.mk

# Toolchain configuration based on CXX variable
CXX ?= clang++
ifeq ($(CXX),c++)
  CXX := clang++
endif

# LTO flag determined at parse time: g++ on macOS uses -flto, all others use -flto=thin
UNAME_S := $(shell uname -s)
LTO_FLAG := $(shell if [ "$(CXX)" = "g++" ] && [ "$(UNAME_S)" = "Darwin" ]; then echo "-flto"; else echo "-flto=thin"; fi)
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

VERSIONED_STATIC = $(LIB_DIR)/libswtr_ringbuffer-$(VERSION).a
VERSIONED_SHARED = $(LIB_DIR)/libswtr_ringbuffer-$(VERSION).so

# ============================================================================
# Parse-time compiler detection and per-compiler target definitions
# Each available compiler gets its own all-<compiler> target.
# ============================================================================

CLANG_REAL := $(shell which clang++ 2>/dev/null || echo "")
GPP_REAL   := $(shell which g++ 2>/dev/null || echo "")

# Per-compiler build targets (each does clean + build)
ifdef CLANG_REAL
.PHONY: all-clang++
all-clang++:
	@echo "=== Building with clang++ ==="
	@$(MAKE) clean
	@CXX=clang++ $(MAKE) all
endif

ifdef GPP_REAL
.PHONY: all-g++
all-g++:
	@echo "=== Building with g++ ==="
	@$(MAKE) clean
	@CXX=g++ $(MAKE) all
endif

# Combined multi-compiler target: order depends on platform
ifeq ($(CLANG_REAL)$(GPP_REAL),)
  # No compilers found — dummy target
  all-all:
	@echo "WARNING: No C++ compilers found"
else ifeq ($(GPP_REAL),)
  # Only clang++ available
  all-all: all-clang++
else ifeq ($(CLANG_REAL),)
  # Only g++ available
  all-all: all-g++
else ifeq ($(CLANG_REAL),$(GPP_REAL))
  # Both point to same binary — use one (clang++ on macOS, g++ on Linux)
  ifeq ($(UNAME_S),Darwin)
    all-all: all-clang++
  else
    all-all: all-g++
  endif
else
  # Both available and different — run in platform-appropriate order
  ifeq ($(UNAME_S),Darwin)
    all-all: all-clang++ all-g++
  else
    all-all: all-g++ all-clang++
  endif
endif

.PHONY: all static shared clean dist-clean test-all

all: static shared

static: $(VERSIONED_STATIC)
	@cd $(LIB_DIR) && ln -sf libswtr_ringbuffer-$(VERSION).a libswtr_ringbuffer.a

shared: $(VERSIONED_SHARED)
	@cd $(LIB_DIR) && ln -sf libswtr_ringbuffer-$(VERSION).so libswtr_ringbuffer.so

$(VERSIONED_STATIC): $(SRCS:%.cpp=$(BUILD_DIR)/%.o)
	@mkdir -p $(LIB_DIR)
	ar rcs $(VERSIONED_STATIC) $^

$(VERSIONED_SHARED): $(SRCS:%.cpp=$(BUILD_DIR)/%.o)
	@mkdir -p $(BUILD_DIR)
	$(CXX) -shared $(LDFLAGS) -o $(VERSIONED_SHARED) $^

$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	@$(RM) $(BUILD_DIR) $(LIB_DIR) *.o *~ #*#
	@find . -name '*.o.tmp' -delete 2>/dev/null || true

dist-clean: clean
	@if [ -d tests ]; then $(MAKE) -C tests dist-clean; fi
	@$(RM) reports ../reports logs
