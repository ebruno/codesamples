include version.mk

# Toolchain configuration — FreeBSD clang++ (only compiler available)
CXX := clang++

# LTO flag: always -flto=thin on FreeBSD (no g++ special case)
UNAME_S := $(shell uname -s)
LTO_FLAG = -flto=thin

# FreeBSD: clang++ uses libc++ by default (headers available)
override CXXFLAGS = -std=c++20 -O3 -fPIC -Wall -Wextra -Wpedantic $(LTO_FLAG) -fvisibility=hidden -ffunction-sections -fdata-sections -I.

# Linker flags: FreeBSD uses ELF, same as Linux
LDFLAGS = -Wl,--gc-sections

RM = rm -rf

SRCS = $(wildcard *.cpp)
OBJS = $(SRCS:%.cpp=%.o)

LIB_DIR = lib
BUILD_DIR = build

VERSIONED_STATIC = $(LIB_DIR)/libswtr_ringbuffer-$(VERSION).a
VERSIONED_SHARED = $(LIB_DIR)/libswtr_ringbuffer-$(VERSION).so

# ============================================================================
# Parse-time compiler detection — FreeBSD only has clang++ (no g++)
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

# Combined multi-compiler target: FreeBSD only has clang++
ifeq ($(CLANG_REAL)$(GPP_REAL),)
  # No compilers found — dummy target
  all-all:
	@echo "WARNING: No C++ compilers found"
else ifeq ($(GPP_REAL),)
  # Only clang++ available (FreeBSD default)
  all-all: all-clang++
else ifeq ($(CLANG_REAL),)
  # Only g++ available (not expected on FreeBSD)
  all-all: all-g++
else ifeq ($(CLANG_REAL),$(GPP_REAL))
  # Both point to same binary — use clang++ (FreeBSD default)
  all-all: all-clang++
else
  # Both available and different — use clang++ (FreeBSD default)
  all-all: all-clang++
endif

.PHONY: all static shared clean dist-clean test-all

all: static shared

static: $(VERSIONED_STATIC)
	@cd $(LIB_DIR) && ln -sf libswtr_ringbuffer-$(VERSION).a libswtr_ringbuffer.a

$(VERSIONED_STATIC): $(OBJS)
	@mkdir -p $(LIB_DIR)
	ar rcs $(VERSIONED_STATIC) $(OBJS)

shared: $(VERSIONED_SHARED)
	@cd $(LIB_DIR) && ln -sf libswtr_ringbuffer-$(VERSION).so libswtr_ringbuffer.so

$(VERSIONED_SHARED): $(OBJS)
	@mkdir -p $(LIB_DIR)
	$(CXX) -shared $(LDFLAGS) -soname libswtr_ringbuffer.so -o $(VERSIONED_SHARED) $(OBJS)

%.o: %.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	@$(RM) $(BUILD_DIR) $(LIB_DIR) *.o *~ #*#
	@find . -name '*.o.tmp' -delete 2>/dev/null || true

dist-clean: clean
	@if [ -d tests ]; then $(MAKE) -C tests dist-clean; fi
	@$(RM) reports ../reports logs
