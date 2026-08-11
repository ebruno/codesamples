include version.mk

# Toolchain
CXX ?= g++
CXXFLAGS = -std=c++20 -fPIC -Wall -Wextra -Wpedantic -O3 \
           -flto -fvisibility=hidden -ffunction-sections -fdata-sections -I.
LDFLAGS = -Wl,--gc-sections

# Versioning
LIB_NAME = libswtr_ringbuffer
VERSIONED_NAME = $(LIB_NAME)-$(MAJOR).$(MINOR).$(SUBVERSION)-$(BUILD_ID)

# Artifacts
LIB_DIR = lib
BUILD_DIR = build
STATIC_LIB = $(LIB_DIR)/$(VERSIONED_NAME).a
SHARED_LIB = $(LIB_DIR)/$(VERSIONED_NAME).so

# Sources
SRCS = Lifecycle.cpp \
       Threading.cpp \
       ReadOps.cpp \
       TransformOps.cpp \
       WriteOps.cpp \
       ErrorOps.cpp \
       LoggingOps_1.cpp \
       LoggingOps_2.cpp \
       LoggingOps_3.cpp \
       LoggingOps_4.cpp \
       LoggingOps_5.cpp \
       LoggingOps_6.cpp \
       Accessors_Status.cpp \
       Accessors_ChecksumAlg.cpp \
       Accessors_ChecksumVal.cpp \
       Accessors_Size_Max.cpp \
       Accessors_Size_Data.cpp \
       Accessors_Size_Transformed.cpp

OBJS = $(patsubst %.cpp, $(BUILD_DIR)/%.o, $(SRCS))

# Utilities
RM = rm -rf
JOBS ?= 1

# Container Configuration
CONTAINER_IMAGE = ringbuffer_debian_build
DOCKERFILE = containers/Dockerfile

# Detect Container Runtime
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    CONTAINER_CMD = container
else
    CONTAINER_CMD = podman
endif

.PHONY: all static shared clean dist-clean container container-clean verify lint format

all: $(STATIC_LIB) $(SHARED_LIB)

# Static Library
$(STATIC_LIB): $(OBJS)
	@mkdir -p $(LIB_DIR)
	ar rcs $@ $^
	@cd $(LIB_DIR) && ln -sf $(VERSIONED_NAME).a $(LIB_NAME).a

# Standalone static target (builds only the static library)
static: $(STATIC_LIB)

# Standalone shared target (builds only the shared library)
shared: $(SHARED_LIB)

# Shared Library
$(SHARED_LIB): $(OBJS)
	@mkdir -p $(LIB_DIR)
	$(CXX) $(LDFLAGS) -shared -Wl,-soname,$(LIB_NAME).so -o $@ $^
	@cd $(LIB_DIR) && ln -sf $(VERSIONED_NAME).so $(LIB_NAME).so

# Object Files
$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Parallel build support: Use $(MAKE) -j$(JOBS) for concurrent compilation
# Default JOBS=1 (serial), override with: make -j4 or JOBS=4

clean:
	$(RM) $(BUILD_DIR) $(LIB_DIR) *.o "*.o" "*~" "#*#"

dist-clean: clean container-clean
	$(RM) ../reports logs
	$(MAKE) -C tests dist-clean

# Container Management
container:
	@mkdir -p logs
	@echo "Checking build container..."
	@if [ "$(UNAME_S)" = "Darwin" ]; then \
		if ! $(CONTAINER_CMD) info >/dev/null 2>&1; then \
			echo "Container service not running. Starting..."; \
			$(CONTAINER_CMD) system start; \
			sleep 2; \
			if ! $(CONTAINER_CMD) info >/dev/null 2>&1; then \
				echo "ERROR: Failed to start container service."; \
				exit 1; \
			fi; \
		fi; \
	fi
	@if ! $(CONTAINER_CMD) image ls | grep -q $(CONTAINER_IMAGE); then \
		echo "Image $(CONTAINER_IMAGE) not found. Building..."; \
		timeout 600 $(CONTAINER_CMD) build -t $(CONTAINER_IMAGE) -f $(DOCKERFILE) .; \
	else \
		echo "Image $(CONTAINER_IMAGE) already exists. Skipping build."; \
	fi
	@echo "Container environment ready."

container-clean:
	@echo "Removing build container image..."
	@$(CONTAINER_CMD) image rm -f $(CONTAINER_IMAGE) || true
	@echo "Container environment cleaned."

# Container Health Check
container-info:
	@echo "Container runtime: $(CONTAINER_CMD)"
	@if [ "$(UNAME_S)" = "Darwin" ]; then \
		if $(CONTAINER_CMD) info >/dev/null 2>&1; then \
			echo "Container service: RUNNING"; \
		else \
			echo "Container service: NOT RUNNING (run 'container system start')"; \
		fi; \
	else \
		if $(CONTAINER_CMD) info >/dev/null 2>&1; then \
			echo "Container service: RUNNING"; \
		else \
			echo "Container service: NOT RUNNING"; \
		fi; \
	fi
	@echo "Available images:"
	@$(CONTAINER_CMD) image ls | grep ringbuffer || echo "  (none)"

# Build Only (no container, no tests)
build-only:
	@echo "Building library only..."
	$(MAKE) clean
	$(MAKE) all
	@echo "Build complete. Artifacts in lib/"

# Verification targets (per common build.md Build Process step 7)
verify:
	@echo "=== Binary Verification ==="
	@echo "--- Static Library ---"
	@file $(STATIC_LIB) | grep -q "current ar archive" && echo "Static library: OK ($(shell file $(STATIC_LIB) | cut -d: -f2-))" || (echo "Static library: FAIL"; exit 1)
	@echo "--- Shared Library ---"
	@file $(SHARED_LIB) | grep -q "shared object" && echo "Shared library: OK ($(shell file $(SHARED_LIB) | cut -d: -f2-))" || (echo "Shared library: FAIL"; exit 1)
	@readelf -d $(SHARED_LIB) | grep -q "SONAME.*$(LIB_NAME).so" && echo "SONAME: OK ($(shell readelf -d $(SHARED_LIB) | grep SONAME))" || (echo "SONAME: FAIL"; exit 1)
	@size -m $(SHARED_LIB) | tail -1 | awk '{print "Binary size: " $$3 " bytes"}'
	@echo "=== Verification Complete ==="

# Optional lint and format targets (requires clang-tidy / clang-format)
lint:
	@echo "Running clang-tidy..."
	@for f in *.cpp; do \
		clang-tidy $$f -- $(CXXFLAGS) -I. 2>/dev/null || true; \
	done
	@echo "Lint complete."

format:
	@echo "Running clang-format..."
	@for f in *.cpp *.hpp; do \
		clang-format -i $$f 2>/dev/null || true; \
	done
	@echo "Format complete."
