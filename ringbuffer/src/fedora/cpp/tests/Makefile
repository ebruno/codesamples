CXX = g++
CXXFLAGS = -std=c++20 -I../ -Wall -Wextra -Wpedantic -O3
BIN_DIR = bin
SRC_DIR = src
LIB_DIR = ../lib
LOG_DIR = logs

# Test Configuration
TEST_BIN = $(BIN_DIR)/test001_staticlib
INPUT_FILE = data/inputs/test001.txt
EXPECTED_DIR = data/expected

# Target binaries
TARGETS = $(BIN_DIR)/test001_staticlib $(BIN_DIR)/test001_dynamiclib

# Source files
SRCS = $(SRC_DIR)/test001.cpp
OBJS = $(SRCS:.cpp=.o)

RM = rm -f

# Container Configuration
CONTAINER_IMAGE = ringbuffer_debian_test
DOCKERFILE = containers/debian/Dockerfile
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    CONTAINER_CMD = container
else
    CONTAINER_CMD = podman
endif

all: $(TARGETS)

$(BIN_DIR)/test001_staticlib: $(OBJS) | $(BIN_DIR)
	$(CXX) $(CXXFLAGS) $(SRC_DIR)/test001.cpp -o $@ $(LIB_DIR)/libswtr_ringbuffer.a

$(BIN_DIR)/test001_dynamiclib: $(OBJS) | $(BIN_DIR)
	$(CXX) $(CXXFLAGS) $(SRC_DIR)/test001.cpp -o $@ -L$(LIB_DIR) -Wl,-rpath,$(shell pwd)/$(LIB_DIR) -lswtr_ringbuffer

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

# --- Verification Targets ---

# Main verification entry point
verify: artifact_verify test001 test002 test003 test004 test005 test006 test007
	@echo "All verification tests completed successfully."

# Static artifact verification
artifact_verify: all
	@echo "--- Artifact Verification ---"
	@file -L $(LIB_DIR)/libswtr_ringbuffer.so
	@readelf -d $(LIB_DIR)/libswtr_ringbuffer.so | grep SONAME
	@ls -lh $(LIB_DIR)/libswtr_ringbuffer.so

# Individual Functional Tests
# Each test depends on 'all' to ensure binaries are up to date.

test001: all
	@mkdir -p $(LOG_DIR)
	@echo "Running T001: Exact Match..."
	@$(TEST_BIN) -o $(EXPECTED_DIR)/t001.out $(INPUT_FILE) 2> $(LOG_DIR)/t001.log

test002: all
	@mkdir -p $(LOG_DIR)
	@echo "Running T002: Stress Test..."
	@$(TEST_BIN) -o $(EXPECTED_DIR)/t002.out -s 1 -b 1 $(INPUT_FILE) 2> $(LOG_DIR)/t002.log

test003: all
	@mkdir -p $(LOG_DIR)
	@echo "Running T003: Uppercase Transform..."
	@$(TEST_BIN) -o $(EXPECTED_DIR)/t003.out -b 10 -t 1 $(INPUT_FILE) 2> $(LOG_DIR)/t003.log

test004: all
	@mkdir -p $(LOG_DIR)
	@echo "Running T004: Fast EOF..."
	@$(TEST_BIN) -o $(EXPECTED_DIR)/t004.out $(INPUT_FILE) 2> $(LOG_DIR)/t004.log

test005: all
	@mkdir -p $(LOG_DIR)
	@echo "Running T005: Fatal Error (Expected failure)..."
	-@$(TEST_BIN) -o $(EXPECTED_DIR)/t005.out -e 1 $(INPUT_FILE) 2> $(LOG_DIR)/t005.log

test006: all
	@mkdir -p $(LOG_DIR)
	@echo "Running T006: Non-Fatal Error..."
	@$(TEST_BIN) -o $(EXPECTED_DIR)/t006.out -e 2 $(INPUT_FILE) 2> $(LOG_DIR)/t006.log

test007: all
	@mkdir -p $(LOG_DIR)
	@echo "Running T007: Bit-Inverted Output..."
	@$(TEST_BIN) -o $(EXPECTED_DIR)/t007.out -t 2 $(INPUT_FILE) 2> $(LOG_DIR)/t007.log

clean:
	$(RM) -r $(BIN_DIR)/*
	$(RM) -r data/expected/*
	$(RM) -r $(LOG_DIR)/*
	$(RM) *.o *~ #*#

dist-clean: clean
	$(RM) -r $(LOG_DIR)

# Container Management
container:
	@echo "Checking test container..."
	@if ! $(CONTAINER_CMD) image ls | grep -q $(CONTAINER_IMAGE); then \
		echo "Image $(CONTAINER_IMAGE) not found. Building..."; \
		$(CONTAINER_CMD) build -t $(CONTAINER_IMAGE) -f $(DOCKERFILE) .; \
	else \
		echo "Image $(CONTAINER_IMAGE) already exists. Checking for Dockerfile updates..."; \
		$(CONTAINER_CMD) build -t $(CONTAINER_IMAGE) -f $(DOCKERFILE) . ; \
	fi
	@echo "Test container environment ready."

.PHONY: all clean dist-clean verify artifact_verify test001 test002 test003 test004 test005 test006 test007 container
