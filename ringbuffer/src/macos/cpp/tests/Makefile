# Makefile for Ringbuffer Tests

# Compiler and flags
CXX = clang++
CXXFLAGS = -std=c++20 -Wall -Wextra -Wpedantic -O3 -I..
LDFLAGS = ../lib/libswtr_ringbuffer.a

# Target binaries
BIN_DIR = bin
TARGETS = $(BIN_DIR)/test001_staticlib

# Source files
SRCS = src/test001.cpp
OBJS = $(SRCS:.cpp=.o)

# Macros
RM = rm -f

.PHONY: all clean dist-clean

all: $(TARGETS)

$(BIN_DIR)/test001_staticlib: $(OBJS) | $(BIN_DIR)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

$(BIN_DIR):
	mkdir -p $@

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	$(RM) $(OBJS) $(TARGETS)

dist-clean: clean
	# Additional cleanup if necessary
