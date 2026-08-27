.PHONY: clean dist-clean

# Host OS detection
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  OS_NAME := macos
  OS_VERSION := $(shell sw_vers -productVersion)
else ifeq ($(UNAME_S),Linux)
  OS_ID := $(shell grep '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2)
  ifeq ($(OS_ID),debian)
    ifneq ($(shell test -f /etc/rpi-issue 2>/dev/null && echo yes),)
      OS_ID := raspios
    endif
  endif
  OS_NAME := $(OS_ID)
  OS_VERSION := $(shell grep '^VERSION_ID=' /etc/os-release 2>/dev/null | cut -d= -f2)
  ifeq ($(OS_VERSION),)
    OS_VERSION := $(shell grep '^BUILD_ID=' /etc/os-release 2>/dev/null | cut -d= -f2)
  endif
else ifeq ($(UNAME_S),FreeBSD)
  OS_ID := $(shell grep '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2)
  ifneq ($(OS_ID),)
    OS_NAME := $(OS_ID)
  else
    OS_NAME := freebsd
  endif
  OS_VERSION := $(shell grep '^VERSION_ID=' /etc/os-release 2>/dev/null | cut -d= -f2)
  ifeq ($(OS_VERSION),)
    OS_VERSION := $(shell grep '^BUILD_ID=' /etc/os-release 2>/dev/null | cut -d= -f2)
  endif
  ifeq ($(OS_VERSION),)
    OS_VERSION := $(shell uname -r)
  endif
else
  OS_NAME := $(UNAME_S)
  OS_VERSION := unknown
endif

# Container runtime detection — prefer the right tool per OS
ifeq ($(OS_NAME),macos)
  CONTAINER_CMD := $(shell command -v container 2>/dev/null || echo "")
else ifeq ($(OS_NAME),freebsd)
  CONTAINER_CMD :=
else ifeq ($(UNAME_S),Linux)
  # Linux distro — prefer podman
  CONTAINER_CMD := $(shell command -v podman 2>/dev/null || echo "")
else
  # Unknown OS — no container support
  CONTAINER_CMD :=
endif

# Discover all OS directories that have a Makefile (skip freebsd* — BSD make, not GNU make)
OS_DIRS := $(filter-out src/freebsd%/cpp/Makefile,$(wildcard src/*/cpp/Makefile))
# Strip the trailing /Makefile to get src/<os>/cpp paths
OS_CPP_DIRS := $(patsubst %/Makefile,%,$(OS_DIRS))

# Common language directories (platform-insensitive)
JAVA_DIR  := src/common/java
PYTHON_DIR := src/common/python

# Container images managed by this project
CONTAINER_IMAGES := ringbuffer_debian_build ringbuffer_debian_test \
                   ringbuffer_fedora_build ringbuffer_fedora_test \
                   ringbuffer_raspios_build ringbuffer_raspios_test \
                   ringbuffer_ubuntu_build ringbuffer_ubuntu_test \
                   vascoguita/raspios

clean:
	@date +%s > .ringbuffer_start
	@find . -maxdepth 1 -name "*~" -exec ${RM} {} \;
	@find . -maxdepth 1 -name "#*#" -exec ${RM} {} \;	
	@find prompts -type f \( -name "*~" -o -name "#*#" \) -delete
	@for dir in $(OS_CPP_DIRS); do \
		echo "Cleaning $$dir ..."; \
		$(MAKE) -C $$dir clean; \
	done
	@if [ -f $(JAVA_DIR)/Makefile ]; then \
		echo "Cleaning $(JAVA_DIR) ..."; \
		$(MAKE) -C $(JAVA_DIR) clean; \
	fi
	@if [ -f $(PYTHON_DIR)/Makefile ]; then \
		echo "Cleaning $(PYTHON_DIR) ..."; \
		$(MAKE) -C $(PYTHON_DIR) clean; \
	fi
	@echo "Cleaning tmp/ (preserving .required_directory)..."
	@if [ -d tmp ]; then find tmp -mindepth 1 -maxdepth 1 ! -name '.required_directory' -exec rm -rf {} + 2>/dev/null; fi
	@./utils/bin/clean_stale_locks.sh 2>/dev/null || true
	echo "Cleaning all reports (*.md and *.xml)..."; \
	find reports -type f \( -name "*.md" -o -name "*.xml" \) -delete 2>/dev/null || true

dist-clean: clean
	@START=$$(cat .ringbuffer_start 2>/dev/null || date +%s); \
	rm -f .ringbuffer_start; \
	for dir in $(OS_CPP_DIRS); do \
		echo "Dist-cleaning $$dir ..."; \
		$(MAKE) -C $$dir dist-clean; \
	done; \
	if [ -f $(JAVA_DIR)/Makefile ]; then \
		echo "Dist-cleaning $(JAVA_DIR) ..."; \
		$(MAKE) -C $(JAVA_DIR) dist-clean; \
	fi; \
	if [ -f $(PYTHON_DIR)/Makefile ]; then \
		echo "Dist-cleaning $(PYTHON_DIR) ..."; \
		$(MAKE) -C $(PYTHON_DIR) dist-clean; \
	fi; \
	echo "Cleaning session files..."; \
	rm -rf .ringbuffer_sessions/; \
	echo "Removing container images..."; \
	if [ -n "$(CONTAINER_CMD)" ]; then \
		$(foreach img,$(CONTAINER_IMAGES),$(CONTAINER_CMD) image rm -f $(img) 2>/dev/null || true; ); \
		echo "  Container images removed."; \
	else \
		echo "  No container runtime found — skipping image cleanup."; \
	fi; \
	END=$$(date +%s); \
	ELAPSED=$$((END - START)); \
	HH=$$(printf "%02d" $$((ELAPSED / 3600))); \
	MM=$$(printf "%02d" $$((ELAPSED % 3600 / 60))); \
	SS=$$(printf "%02d" $$((ELAPSED % 60))); \
	echo "Dist-clean completed in $${HH}:$${MM}:$${SS}"
