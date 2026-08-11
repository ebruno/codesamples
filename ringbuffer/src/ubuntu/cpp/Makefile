include version.mk

# Toolchain
CXX ?= g++
CXXFLAGS = -std=c++20 -fPIC -Wall -Wextra -Wpedantic -O3 -flto \
           -fvisibility=hidden -ffunction-sections -fdata-sections -I.
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
CONTAINER_IMAGE = ringbuffer_ubuntu_build
DOCKERFILE = containers/Dockerfile

# Detect Container Runtime and Host OS
UNAME_S := $(shell uname -s)
HOST_DISTRO := $(shell cat /etc/os-release 2>/dev/null | grep '^ID=' | cut -d= -f2)
ifeq ($(UNAME_S),Darwin)
    CONTAINER_CMD = container
else
    CONTAINER_CMD = podman
endif

# When host is not Ubuntu (e.g. macOS), auto-build inside container
# This conditional logic ensures cross-OS builds use containers automatically
ifeq ($(UNAME_S),Darwin)
    all: container
	@$(CONTAINER_CMD) run --rm -v $$(pwd)/../..:/app/ringbuffer -w /app/ringbuffer/src/ubuntu/cpp $(CONTAINER_IMAGE) make all
else ifneq ($(HOST_DISTRO),ubuntu)
    all: container
	@$(CONTAINER_CMD) run --rm -v $$(pwd)/../..:/app/ringbuffer -w /app/ringbuffer/src/ubuntu/cpp $(CONTAINER_IMAGE) make all
else
    all: $(STATIC_LIB) $(SHARED_LIB)
endif

.PHONY: all static shared clean dist-clean container container-clean verify lint format

# Static Library Target
static: $(STATIC_LIB)
	@echo "Static library built: $(STATIC_LIB)"

# Shared Library Target
shared: $(SHARED_LIB)
	@echo "Shared library built: $(SHARED_LIB)"

# Static Library
$(STATIC_LIB): $(OBJS)
	@mkdir -p $(LIB_DIR)
	ar rcs $@ $^
	@cd $(LIB_DIR) && ln -sf $(VERSIONED_NAME).a $(LIB_NAME).a

# Shared Library
$(SHARED_LIB): $(OBJS)
	@mkdir -p $(LIB_DIR)
	$(CXX) $(LDFLAGS) -shared -Wl,-soname,$(LIB_NAME).so -o $@ $^
	@cd $(LIB_DIR) && ln -sf $(VERSIONED_NAME).so $(LIB_NAME).so

# Object Files
$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	$(RM) $(BUILD_DIR) $(LIB_DIR) *.o "*.o" "*~" "#*#"

dist-clean: clean container-clean
	$(RM) ../reports logs
	$(MAKE) -C tests dist-clean

# Verification
verify:
	$(MAKE) -C tests verify

# Container Management
container:
	@mkdir -p logs
	@echo "Checking build container..."
	@if [ "$(UNAME_S)" = "Darwin" ]; then \
		if ! $(CONTAINER_CMD) system status 2>/dev/null | grep -q "status.*running"; then \
			echo "Starting container service..."; \
			$(CONTAINER_CMD) system start; \
			sleep 3; \
			if ! $(CONTAINER_CMD) system status 2>/dev/null | grep -q "status.*running"; then \
				echo "ERROR: Failed to start container service."; \
				exit 1; \
			fi; \
		fi; \
	fi
	@if ! $(CONTAINER_CMD) image ls --quiet | grep -q $(CONTAINER_IMAGE); then \
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
		if $(CONTAINER_CMD) system status 2>/dev/null | grep -q "status.*running"; then \
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
	@$(CONTAINER_CMD) image ls --quiet | grep ringbuffer || echo "  (none)"

# Build Only (no container, no tests)
build-only:
	@echo "Building library only..."
	$(MAKE) clean
	$(MAKE) all
	@echo "Build complete. Artifacts in lib/"

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
