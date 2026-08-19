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
	$(CXX) -shared $(LDFLAGS) -Wl,-soname,$(LIB_NAME).so -o $(VERSIONED_SHARED) $^

$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	@$(RM) $(BUILD_DIR) $(LIB_DIR) *.o *~ #*#
	@find . -name '*.o.tmp' -delete 2>/dev/null || true

dist-clean: clean
	@if [ -d tests ]; then $(MAKE) -C tests dist-clean; fi
	@$(RM) reports ../reports logs
