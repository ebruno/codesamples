include version.mk

# ============================================================================
# Compiler auto-detection: Arch Linux has both g++ and clang++ available
# ============================================================================

ALL_COMPILERS := g++ clang++

# Filter to only compilers that exist on the system
AVAILABLE_COMPILERS := $(foreach COMP,$(ALL_COMPILERS),\
  $(if $(shell which $(COMP) >/dev/null 2>&1 && echo found),$(COMP)))

# Default compiler (first available) — ?= respects CXX from environment
CXX ?= $(firstword $(AVAILABLE_COMPILERS))

# ============================================================================
# Per-compiler LTO flags: g++ uses -flto, clang++ uses -flto=thin
# ============================================================================

define COMPILER_LTO_FLAGS
ifeq ($(strip $(CXX)),g++)
  LTO_FLAG := -flto
else ifeq ($(strip $(CXX)),clang++)
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
ifeq ($(strip $(CXX)),g++)
  LDFLAGS = -Wl,--gc-sections
else ifeq ($(strip $(CXX)),clang++)
  LDFLAGS = -Wl,--gc-sections -flto=thin
endif

RM = rm -rf

SRCS = $(wildcard *.cpp)
OBJS = $(SRCS:%.cpp=%.o)

LIB_NAME = libswtr_ringbuffer
LIB_DIR = lib
BUILD_DIR = build

VERSIONED_STATIC = $(LIB_DIR)/libswtr_ringbuffer-$(VERSION).a
VERSIONED_SHARED = $(LIB_DIR)/libswtr_ringbuffer-$(VERSION).so

.PHONY: all static shared clean dist-clean verify test-all

all: $(LIB_DIR) $(BUILD_DIR) $(VERSIONED_STATIC) $(VERSIONED_SHARED)

static: $(VERSIONED_STATIC)
	@cd $(LIB_DIR) && ln -sf libswtr_ringbuffer-$(VERSION).a libswtr_ringbuffer.a

shared: $(VERSIONED_SHARED)
	@cd $(LIB_DIR) && ln -sf libswtr_ringbuffer-$(VERSION).so libswtr_ringbuffer.so

$(LIB_DIR):
	mkdir -p $(LIB_DIR)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

%.o: %.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(VERSIONED_STATIC): $(OBJS)
	ar rcs $@ $^
	@echo "Static library: $@"

$(VERSIONED_SHARED): $(OBJS)
	$(CXX) -shared $(LDFLAGS) -Wl,-soname,$(LIB_NAME).so -o $@ $^ -pthread
	@ln -sf libswtr_ringbuffer-$(VERSION).so $(LIB_DIR)/libswtr_ringbuffer.so
	@ln -sf libswtr_ringbuffer-$(VERSION).so $(LIB_DIR)/libswtr_ringbuffer.so.1
	@echo "Shared library: $@"

clean:
	$(RM) $(BUILD_DIR) $(LIB_DIR) *.o *~ #*#
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
