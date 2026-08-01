# Include versioning variables
include version.mk

# Toolchain
CXX = clang++
LIBTOOL = libtool
LIPO = lipo
RM = rm -rf

# Compilation Flags
# Each architecture must be compiled separately
CXXFLAGS_BASE = -std=c++20 -fPIC -Wall -Wextra -Wpedantic -O3 -flto -fvisibility=hidden -ffunction-sections -fdata-sections -I.
CXXFLAGS_ARM64 = $(CXXFLAGS_BASE) -arch arm64
CXXFLAGS_X86_64 = $(CXXFLAGS_BASE) -arch x86_64

# Linker Flags
LDFLAGS_BASE = -dead_strip
LDFLAGS_DYLIB = -dynamiclib -install_name @rpath/libswtr_ringbuffer.dylib

# Versioned artifact name
LIB_NAME = libswtr_ringbuffer-$(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID)

# Directories
LIB_DIR = lib
OBJ_DIR = build/obj

# Source files
SRCS = $(wildcard *.cpp)
# We need object files for both architectures
OBJS_ARM64 = $(SRCS:%.cpp=$(OBJ_DIR)/%.arm64.o)
OBJS_X86_64 = $(SRCS:%.cpp=$(OBJ_DIR)/%.x86_64.o)

# Default target
all: $(LIB_DIR)/$(LIB_NAME).a $(LIB_DIR)/$(LIB_NAME).dylib symlinks

# Static Library (Fat binary using libtool)
$(LIB_DIR)/$(LIB_NAME).a: $(OBJS_ARM64) $(OBJS_X86_64)
	@mkdir -p $(LIB_DIR)
	$(LIBTOOL) -static -o $(LIB_DIR)/$(LIB_NAME).a $(OBJS_ARM64) $(OBJS_X86_64)

# Shared Library (Two-stage process)
$(LIB_DIR)/$(LIB_NAME).dylib: $(OBJ_DIR)/libswtr_ringbuffer.arm64.dylib $(OBJ_DIR)/libswtr_ringbuffer.x86_64.dylib
	@mkdir -p $(LIB_DIR)
	$(LIPO) -create $(OBJ_DIR)/libswtr_ringbuffer.arm64.dylib $(OBJ_DIR)/libswtr_ringbuffer.x86_64.dylib -output $(LIB_DIR)/$(LIB_NAME).dylib

# Intermediate Shared Libraries (Single architecture)
$(OBJ_DIR)/libswtr_ringbuffer.arm64.dylib: $(OBJS_ARM64)
	@mkdir -p $(OBJ_DIR)
	$(CXX) -arch arm64 $(LDFLAGS_BASE) $(LDFLAGS_DYLIB) -o $@ $(OBJS_ARM64)

$(OBJ_DIR)/libswtr_ringbuffer.x86_64.dylib: $(OBJS_X86_64)
	@mkdir -p $(OBJ_DIR)
	$(CXX) -arch x86_64 $(LDFLAGS_BASE) $(LDFLAGS_DYLIB) -o $@ $(OBJS_X86_64)

# Object files - ARM64
$(OBJ_DIR)/%.arm64.o: %.cpp
	@mkdir -p $(OBJ_DIR)
	$(CXX) $(CXXFLAGS_ARM64) -c $< -o $@

# Object files - X86_64
$(OBJ_DIR)/%.x86_64.o: %.cpp
	@mkdir -p $(OBJ_DIR)
	$(CXX) $(CXXFLAGS_X86_64) -c $< -o $@

# Symbolic links
symlinks:
	cd $(LIB_DIR) && ln -sf $(LIB_NAME).a libswtr_ringbuffer.a
	cd $(LIB_DIR) && ln -sf $(LIB_NAME).dylib libswtr_ringbuffer.dylib

# Clean target
clean:
	$(RM) $(OBJ_DIR) $(LIB_DIR)

.PHONY: all clean symlinks
