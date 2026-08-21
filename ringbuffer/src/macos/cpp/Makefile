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
LTO_FLAG := $(shell if [ "$(CXX)" = "g++" ] && [ "$(UNAME_S)" = "Darwin" ]; then echo "-flto"; else echo "-flto=thin"; fi)
# macOS: clang++ uses libc++ by default (headers available). Homebrew g++ defaults to libstdc++,
# but Apple deprecated libstdc++ headers on macOS 10.14+. g++ may fail to compile on modern macOS
# if libstdc++ headers are missing — this is acceptable and documented in session_hints.md.
override CXXFLAGS = -std=c++20 -O3 -fPIC -Wall -Wextra -Wpedantic $(LTO_FLAG) -fvisibility=hidden -ffunction-sections -fdata-sections -I.

# Linker flags are OS-dependent, not compiler-dependent:
ifeq ($(shell uname -s),Darwin)
  LDFLAGS = -dead_strip
else
  LDFLAGS = -Wl,--gc-sections
endif

RM = rm -rf

SRCS = $(wildcard *.cpp)
OBJS_ARM64 = $(SRCS:%.cpp=%.arm64.o)
OBJS_X86_64 = $(SRCS:%.cpp=%.x86_64.o)

LIB_DIR = lib
BUILD_DIR = build

VERSIONED_STATIC = $(LIB_DIR)/libswtr_ringbuffer-$(VERSION).a
VERSIONED_SHARED = $(LIB_DIR)/libswtr_ringbuffer-$(VERSION).dylib

.PHONY: test  all static shared clean dist-clean test-all

# Always clean first for repeatability in verify_build
all: clean static shared

static: $(VERSIONED_STATIC)
	@cd $(LIB_DIR) && ln -sf libswtr_ringbuffer-$(VERSION).a libswtr_ringbuffer.a

$(VERSIONED_STATIC): $(OBJS_ARM64) $(OBJS_X86_64)
	@mkdir -p $(LIB_DIR)
	libtool -static -o $(VERSIONED_STATIC) $(OBJS_ARM64) $(OBJS_X86_64)

shared: $(VERSIONED_SHARED)
	@cd $(LIB_DIR) && ln -sf libswtr_ringbuffer-$(VERSION).dylib libswtr_ringbuffer.dylib

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

%.arm64.o: %.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -arch arm64 -c $< -o $@

%.x86_64.o: %.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -arch x86_64 -c $< -o $@
test: all
	@if [ -d tests ]; then $(MAKE) -C tests verify; else echo "No tests directory"; fi

clean:
	@$(RM) $(BUILD_DIR) $(LIB_DIR) *.o *~ #*#
	@find . -name '*.o.tmp' -delete 2>/dev/null || true

dist-clean: clean
	@if [ -d tests ]; then $(MAKE) -C tests dist-clean; fi
	@$(RM) reports ../reports logs
