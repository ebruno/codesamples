include version.mk

# Toolchain configuration based on CXX variable
# macOS Make 3.81 bug: "CXX := clang++" overrides command-line CXX=g++.
# Workaround: use ?= first, then force c++ → clang++. Command-line CXX=g++ still works.
CXX ?= clang++
ifeq ($(CXX),c++)
  CXX := clang++
endif

# LTO flag determined at parse time: g++ on macOS uses -flto, all others use -flto=thin
UNAME_S := $(shell uname -s)
CXX_BASE := $(patsubst g++-%,g++,$(patsubst clang++-%,clang++,$(CXX)))
LTO_FLAG := $(shell if [ "$(CXX_BASE)" = "g++" ] && [ "$(UNAME_S)" = "Darwin" ]; then echo "-flto"; else echo "-flto=thin"; fi)
# macOS: clang++ uses libc++ by default (headers available). Homebrew g++ defaults to libstdc++,
# but Apple deprecated libstdc++ headers on macOS 10.14+. g++ may fail to compile on modern macOS
# if libstdc++ headers are missing — this is acceptable and documented in session_hints.md.
# Universal binary support: g++ on Apple Silicon does not support -arch x86_64, so skip it.
UNAME_M := $(shell uname -m)
ifeq ($(CXX_BASE),g++)
  ifeq ($(UNAME_M),arm64)
    SUPPORTS_X86_64 = no
  else
    SUPPORTS_X86_64 = yes
  endif
else
  SUPPORTS_X86_64 = yes
endif

# Object file lists — conditionally include x86_64 objects
OBJS_ARM64 = $(SRCS:%.cpp=%.arm64.o)
ifeq ($(SUPPORTS_X86_64),yes)
  OBJS_X86_64 = $(SRCS:%.cpp=%.x86_64.o)
  OBJS_ALL = $(OBJS_ARM64) $(OBJS_X86_64)
else
  OBJS_X86_64 =
  OBJS_ALL = $(OBJS_ARM64)
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

VERSIONED_STATIC = $(LIB_DIR)/libswtr_ringbuffer-$(VERSION).a
VERSIONED_SHARED = $(LIB_DIR)/libswtr_ringbuffer-$(VERSION).dylib

.PHONY: test  all static shared clean dist-clean test-all man-page

# Always clean first for repeatability in verify_build
all: clean static shared

static: $(VERSIONED_STATIC)
	@cd $(LIB_DIR) && ln -sf libswtr_ringbuffer-$(VERSION).a libswtr_ringbuffer.a

$(VERSIONED_STATIC): $(OBJS_ALL)
	@mkdir -p $(LIB_DIR)
	libtool -static -o $(VERSIONED_STATIC) $(OBJS_ALL)

shared: $(VERSIONED_SHARED)
	@cd $(LIB_DIR) && ln -sf libswtr_ringbuffer-$(VERSION).dylib libswtr_ringbuffer.dylib

ifeq ($(SUPPORTS_X86_64),yes)
$(VERSIONED_SHARED): $(OBJS_ARM64) $(OBJS_X86_64)
	@mkdir -p $(BUILD_DIR)
	$(CXX) -arch arm64 -dynamiclib -install_name @rpath/libswtr_ringbuffer.dylib $(LDFLAGS) -o $(BUILD_DIR)/libswtr_ringbuffer_arm64.dylib $(OBJS_ARM64)
	$(CXX) -arch x86_64 -dynamiclib -install_name @rpath/libswtr_ringbuffer.dylib $(LDFLAGS) -o $(BUILD_DIR)/libswtr_ringbuffer_x86_64.dylib $(OBJS_X86_64)
	@if lipo -create $(BUILD_DIR)/libswtr_ringbuffer_arm64.dylib $(BUILD_DIR)/libswtr_ringbuffer_x86_64.dylib -output $(VERSIONED_SHARED) 2>/dev/null; then \
		echo "Universal binary created (arm64 + x86_64)"; \
	else \
		echo "WARNING: Compiler does not support universal binaries — using arm64 only"; \
		cp $(BUILD_DIR)/libswtr_ringbuffer_arm64.dylib $(VERSIONED_SHARED); \
	fi
	@if lipo -info $(VERSIONED_SHARED) 2>/dev/null | grep -q "Architectures in the fat file"; then \
		echo "[INFO] Universal binary: arm64 + x86_64" > $(BUILD_DIR)/binary_arch.txt; \
	else \
		echo "[INFO] Universal binary: arm64-only (compiler does not support -arch x86_64 on Apple Silicon)" > $(BUILD_DIR)/binary_arch.txt; \
	fi
else
$(VERSIONED_SHARED): $(OBJS_ARM64)
	@mkdir -p $(BUILD_DIR)
	$(CXX) -arch arm64 -dynamiclib -install_name @rpath/libswtr_ringbuffer.dylib $(LDFLAGS) -o $(VERSIONED_SHARED) $(OBJS_ARM64)
	@echo "[INFO] Universal binary: arm64-only (compiler does not support -arch x86_64 on Apple Silicon)" > $(BUILD_DIR)/binary_arch.txt
endif

%.arm64.o: %.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -arch arm64 -c $< -o $@

ifeq ($(SUPPORTS_X86_64),yes)
%.x86_64.o: %.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -arch x86_64 -c $< -o $@
endif

test: all
	@if [ -d tests ]; then $(MAKE) -C tests verify; else echo "No tests directory"; fi

clean:
	@$(RM) $(BUILD_DIR) $(LIB_DIR) *.o *~ #*#
	@find . -name '*.o.tmp' -delete 2>/dev/null || true
	@$(MAKE) -C ../../../prompts/common/cpp clean-man

dist-clean: clean
	@if [ -d tests ]; then $(MAKE) -C tests dist-clean; fi
	@$(RM) reports ../reports logs
	@$(MAKE) -C ../../../prompts/common/cpp clean-man
