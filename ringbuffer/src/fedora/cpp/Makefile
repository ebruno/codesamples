# Include versioning variables
include version.mk

# Toolchain
CXX = g++
AR = ar
RM = rm -rf

# Compilation Flags
CXXFLAGS = -std=c++20 -fPIC -Wall -Wextra -Wpedantic -O3 -flto -fvisibility=hidden -ffunction-sections -fdata-sections -I.
LDFLAGS = -Wl,--gc-sections -shared -Wl,-soname,libswtr_ringbuffer.so

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
symlinks:
	cd $(LIB_DIR) && ln -sf $(LIB_NAME).a libswtr_ringbuffer.a
	cd $(LIB_DIR) && ln -sf $(LIB_NAME).so libswtr_ringbuffer.so

# Clean target
clean:
	$(RM) $(OBJ_DIR) $(LIB_DIR)

.PHONY: all clean symlinks
