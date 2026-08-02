# Test Build Makefile

# Toolchain
CXX = g++
CXXFLAGS = -std=c++20 -I../ -Wall -Wextra -Wpedantic -O3
LDFLAGS = -L../lib -lswtr_ringbuffer

# Directories
BIN_DIR = bin
SRC_DIR = src

# Test Binaries
TESTS = test001_staticlib

# Object files
OBJS = $(addprefix $(BIN_DIR)/, $(TESTS:.cpp=.o))

# Default target
all: $(BIN_DIR)/$(firstword $(TESTS))

# Link test binaries (Static linking requirement)
# Note: We link directly to the .a file to ensure static linking
$(BIN_DIR)/test001_staticlib: $(SRC_DIR)/test001_staticlib.cpp
	@mkdir -p $(BIN_DIR)
	$(CXX) $(CXXFLAGS) $(SRC_DIR)/test001_staticlib.cpp -o $(BIN_DIR)/test001_staticlib ../lib/libswtr_ringbuffer.a

# Clean target
clean:
	rm -rf $(BIN_DIR)/*

.PHONY: all clean
