# Makefile for Ringbuffer Tests

# Compiler and flags
CXX = clang++
CXXFLAGS = -std=c++20 -Wall -Wextra -Wpedantic -O3 -I..
# Linking flags for different library types
LDFLAGS_STATIC = ../lib/libswtr_ringbuffer.a
LDFLAGS_DYNAMIC = -L../lib -lswtr_ringbuffer -Wl,-rpath,$(abspath ../lib)

# Target binaries
BIN_DIR = bin
TARGETS = $(BIN_DIR)/test001_staticlib $(BIN_DIR)/test001_dynlib

# Source files
SRCS = src/test001.cpp
OBJS = $(SRCS:.cpp=.o)

# Macros
RM = rm -f

.PHONY: all clean dist-clean

all: $(TARGETS)

$(BIN_DIR)/test001_staticlib: $(OBJS) | $(BIN_DIR)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS_STATIC)

$(BIN_DIR)/test001_dynlib: $(OBJS) | $(BIN_DIR)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS_DYNAMIC)

$(BIN_DIR):
	mkdir -p $@

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	$(RM) $(OBJS) $(TARGETS)
	$(RM) -r $(BIN_DIR)/* data/expected/*
	$(RM) -f *~ #*#

dist-clean: clean
