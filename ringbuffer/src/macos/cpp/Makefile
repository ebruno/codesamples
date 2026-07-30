# Makefile for swtr Ringbuffer (macOS, C++)
# Based on requirements in ringbuffer/prompts/macos/cpp/build.md

# Include versioning
include version.mk

# Toolchain Configuration
CXX      := clang++
RM       := rm -f
ARCH     := -arch arm64 -arch x86_64
CXXFLAGS := $(ARCH) -std=c++20 -O3 -Wall -Wextra -Wpedantic -ffunction-sections -fdata-sections -fPIC
LDFLAGS  := -Wl,-dead_strip

# Output Directory
LIB_DIR  := lib

# Targets
VERSION_STR := $(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID)
STATIC_LIB  := $(LIB_DIR)/libswtr_ringbuffer-$(VERSION_STR).a
SHARED_LIB  := $(LIB_DIR)/libswtr_ringbuffer-$(VERSION_STR).dylib

# Alias Targets
STATIC_ALIAS := $(LIB_DIR)/libswtr_ringbuffer.a
SHARED_ALIAS := $(LIB_DIR)/libswtr_ringbuffer.dylib

# Source and Object files
SRCS     := $(wildcard *.cpp)
OBJS     := $(SRCS:.cpp=.o)

# Header dependencies
DEPS     := status.hpp ringbuffer.hpp swtr_ringbuffer_impl.hpp

.PHONY: all clean dist-clean

all: $(LIB_DIR) $(STATIC_LIB) $(SHARED_LIB) $(STATIC_ALIAS) $(SHARED_ALIAS)

$(LIB_DIR):
	@mkdir -p $(LIB_DIR)

$(STATIC_LIB): $(OBJS)
	@echo "Linking Universal Static Library: $@"
	libtool -static -o $@ $(OBJS)

$(SHARED_LIB): $(OBJS)
	@echo "Linking Universal Shared Library: $@"
	$(CXX) $(LDFLAGS) -dynamiclib -o $@ $(OBJS)

$(STATIC_ALIAS): $(STATIC_LIB)
	@echo "Creating static alias..."
	cd $(LIB_DIR) && ln -sf $(notdir $(STATIC_LIB)) $(notdir $(STATIC_ALIAS))

$(SHARED_ALIAS): $(SHARED_LIB)
	@echo "Creating shared alias..."
	cd $(LIB_DIR) && ln -sf $(notdir $(SHARED_LIB)) $(notdir $(SHARED_ALIAS))

%.o: %.cpp $(DEPS)
	@echo "Compiling $< for universal binary..."
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	@echo "Cleaning build artifacts and lib directory..."
	$(RM) -r $(LIB_DIR)
	$(RM) $(OBJS)

dist-clean: clean
	@echo "Performing dist-clean..."
