# Include versioning variables
include version.mk

# Toolchain
CXX = g++
AR = ar
RM = rm -f

# Compilation Flags
# -fPIC: Position Independent Code for shared libraries
# -Wall -Wextra -Wpedantic: Strict warnings
# -O3: High-level optimization
# -flto: Link Time Optimization
# -fvisibility=hidden: Hide symbols by default
# -ffunction-sections -fdata-sections: Place each function/data in its own section for GC
CXXFLAGS = -std=c++20 -fPIC -Wall -Wextra -Wpedantic -O3 -flto -fvisibility=hidden -ffunction-sections -fdata-sections -I.

# Linker Flags
# -Wl,--gc-sections: Remove unreferenced sections (Dead Code Elimination)
# -shared: Create shared object
# -Wl,-soname: Set the SONAME of the library
# -flto: Ensure LTO is applied during linking
LDFLAGS = -flto -Wl,--gc-sections -shared -Wl,-soname,libswtr_ringbuffer.so

# Versioned artifact name
LIB_NAME = libswtr_ringbuffer-$(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID)

# Directories
LIB_DIR = lib
OBJ_DIR = build

# Source files
SRCS = $(wildcard *.cpp)
OBJS = $(SRCS:%.cpp=$(OBJ_DIR)/%.o)

# Default target
all: $(LIB_DIR)/$(LIB_NAME).a $(LIB_DIR)/$(LIB_NAME).so symlinks

# Static Library
$(LIB_DIR)/$(LIB_NAME).a: $(OBJS)
	@mkdir -p $(LIB_DIR)
	$(AR) rcs $(LIB_DIR)/$(LIB_NAME).a $(OBJS)

# Shared Library
$(LIB_DIR)/$(LIB_NAME).so: $(OBJS)
	@mkdir -p $(LIB_DIR)
	$(CXX) $(LDFLAGS) -o $(LIB_DIR)/$(LIB_NAME).so $(OBJS)

# Object files
$(OBJ_DIR)/%.o: %.cpp
	@mkdir -p $(OBJ_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Symbolic links
# Links are created using relative paths by changing directory first
symlinks:
	cd $(LIB_DIR) && ln -sf $(LIB_NAME).a libswtr_ringbuffer.a
	cd $(LIB_DIR) && ln -sf $(LIB_NAME).so libswtr_ringbuffer.so

# Clean target
# Removes build and lib directories and backup files using the RM macro
clean:
	$(RM) -r $(OBJ_DIR) $(LIB_DIR)
	$(RM) *~ #*#

.PHONY: all clean symlinks
