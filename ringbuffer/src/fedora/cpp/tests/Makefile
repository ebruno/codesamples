# Test Build Makefile

# Toolchain
CXX = g++
CXXFLAGS = -std=c++20 -I../ -Wall -Wextra -Wpedantic -O3

# Directories
BIN_DIR = bin
SRC_DIR = src

# Test Binaries
TESTS_STATIC = test001_staticlib
TESTS_DYNAMIC = test001_dynamiclib

# Object files
OBJS = $(addprefix $(BIN_DIR)/, $(TESTS_STATIC:.cpp=.o))

# Default target
all: $(BIN_DIR)/$(firstword $(TESTS_STATIC)) $(BIN_DIR)/$(firstword $(TESTS_DYNAMIC))

# Link test binaries (Static linking requirement)
# Note: We link directly to the .a file to ensure static linking
$(BIN_DIR)/test001_staticlib: $(SRC_DIR)/test001.cpp
	@mkdir -p $(BIN_DIR)
	$(CXX) $(CXXFLAGS) $(SRC_DIR)/test001.cpp -o $(BIN_DIR)/test001_staticlib ../lib/libswtr_ringbuffer.a

# Link test binaries (Dynamic linking requirement)
$(BIN_DIR)/test001_dynamiclib: $(SRC_DIR)/test001.cpp
	@mkdir -p $(BIN_DIR)
	$(CXX) $(CXXFLAGS) $(SRC_DIR)/test001.cpp -o $(BIN_DIR)/test001_dynamiclib -L../lib -Wl,-rpath,$(abspath ../lib) -lswtr_ringbuffer

# Clean target
clean:
	rm -rf $(BIN_DIR)/*

.PHONY: all clean
