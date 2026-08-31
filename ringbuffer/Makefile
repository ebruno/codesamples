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

# Shell script extension based on host OS (golden rule: zsh on macOS, sh elsewhere)
ifeq ($(OS_NAME),macos)
  SHELL_EXT := zsh
else
  SHELL_EXT := sh
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

# Documentation output directories for hosting platforms
GITHUB_PAGES_DIR = ../docs
GITLAB_PAGES_DIR  = ../pages

# Documentation directories (Doxygen output)
DOCS_BASE_DIR       := docs/ringbuffer
CPP_DOCS_BASE_DIR   := $(DOCS_BASE_DIR)/cpp/html
JAVA_DOCS_BASE_DIR  := $(DOCS_BASE_DIR)/java/html
PYTHON_BREATHE_DIR  := $(DOCS_BASE_DIR)/python/breathe-html
PYTHON_SPHINX_DIR   := $(DOCS_BASE_DIR)/python/sphinx-html

# Documentation tools
DOXYGEN_CMD = doxygen
PYTHON3_CMD = python3



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
		$(foreach img,$(CONTAINER_IMAGES),$(CONTAINER_CMD) image rm -f $(img) 2>/dev/null || true; ) \
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

.PHONY: clean-docs create-doc docs-cpp docs-java docs-breathe docs-sphinx docs-with-index publish-to-github-pages publish-to-gitlab-pages

clean-docs:
	@echo "Cleaning Doxygen documentation artifacts..."
	@if [ -d $(DOCS_BASE_DIR) ]; then \
		find $(DOCS_BASE_DIR) -mindepth 1 ! -name '.required_directory' -exec rm -rf {} + 2>/dev/null || true; \
	fi
	@echo "Documentation artifacts cleaned."

# Generate C++ Doxygen documentation (with Types section fixup)
docs-cpp:
	@echo "=== Generating C++ Doxygen documentation ==="
	@if ! command -v $(DOXYGEN_CMD) > /dev/null 2>&1; then \
		echo "ERROR: $(DOXYGEN_CMD) not found. Please install Doxygen." >&2; \
		exit 1; \
	fi
	mkdir -p $(CPP_DOCS_BASE_DIR)
	cd prompts/common/cpp && $(DOXYGEN_CMD) Doxyfile
	$(PYTHON3_CMD) utils/bin/generate_docs.py src/common/cpp/status.hpp

# Generate Java Doxygen documentation
docs-java:
	@echo "=== Generating Java Doxygen documentation ==="
	@if ! command -v $(DOXYGEN_CMD) > /dev/null 2>&1; then \
		echo "ERROR: $(DOXYGEN_CMD) not found. Please install Doxygen." >&2; \
		exit 1; \
	fi
	mkdir -p $(JAVA_DOCS_BASE_DIR)
	cd src/common/java && $(DOXYGEN_CMD) Doxyfile

# Generate Python documentation using Doxygen + Breathe
docs-breathe:
	@echo "=== Setting up documentation venv ==="
	@if [ ! -d venv_doc ]; then python3 -m venv venv_doc; fi
	venv_doc/bin/pip install -q -r requirements-doc.txt
	@echo "=== Creating Python docs output directory ==="
	mkdir -p $(DOCS_BASE_DIR)/python/doxygen
	@echo "=== Running Doxygen on Python source ==="
	cd src/common/python && doxygen Doxyfile
	@echo "=== Generating Sphinx+Breathe documentation ==="
	venv_doc/bin/$(PYTHON3_CMD) -m sphinx -b html src/common/python/sphinx $(PYTHON_BREATHE_DIR)
	@echo "=== Cleaning up venv ==="
	rm -rf venv_doc
	@echo "Breathe docs generated at $(PYTHON_BREATHE_DIR)"

# Generate Python documentation using Sphinx-only (autodoc + napoleon, no Doxygen)
docs-sphinx:
	@echo "=== Setting up documentation venv ==="
	@if [ ! -d venv_doc ]; then python3 -m venv venv_doc; fi
	venv_doc/bin/pip install -q -r requirements-doc.txt
	@echo "=== Generating Sphinx documentation ==="
	venv_doc/bin/$(PYTHON3_CMD) -m sphinx -b html src/common/python/sphinx-solo $(PYTHON_SPHINX_DIR)
	@echo "=== Cleaning up venv ==="
	rm -rf venv_doc
	@echo "Sphinx docs generated at $(PYTHON_SPHINX_DIR)"

# Unified create-doc — generates C++, Java, and Python documentation
create-doc: clean-docs docs-cpp docs-java docs-breathe docs-sphinx
	@echo "=== All documentation generated ==="

# Generate all documentation AND create top-level index page with links to available language docs
docs-with-index: create-doc
	@echo "=== Generating docs index page ==="
	@./utils/bin/generate_docs_index.$(SHELL_EXT)

# Publish documentation to GitHub Pages
publish-to-github-pages: docs-with-index
	@echo "=== Publishing to GitHub Pages ==="
	@if [ ! -d $(GITHUB_PAGES_DIR) ]; then \
		echo "Creating $(GITHUB_PAGES_DIR)..."; \
		mkdir -p $(GITHUB_PAGES_DIR); \
	fi
	@if [ -d $(GITHUB_PAGES_DIR)/ringbuffer ]; then \
		echo "Removing existing ringbuffer directory from $(GITHUB_PAGES_DIR)..."; \
		rm -rf $(GITHUB_PAGES_DIR)/ringbuffer; \
	fi
	@if [ ! -d $(DOCS_BASE_DIR) ]; then \
		echo "ERROR: $(DOCS_BASE_DIR) directory not found. Run 'make create-doc' first." >&2; \
		exit 1; \
	fi
	echo "Moving $(DOCS_BASE_DIR) to $(GITHUB_PAGES_DIR)/ringbuffer..."
	mv $(DOCS_BASE_DIR) $(GITHUB_PAGES_DIR)/ringbuffer
	@echo "Published to GitHub Pages at $(GITHUB_PAGES_DIR)/ringbuffer"

# Publish documentation to GitLab Pages
publish-to-gitlab-pages: docs-with-index
	@echo "=== Publishing to GitLab Pages ==="
	@if [ ! -d $(GITLAB_PAGES_DIR) ]; then \
		echo "Creating $(GITLAB_PAGES_DIR)..."; \
		mkdir -p $(GITLAB_PAGES_DIR); \
	fi
	@if [ -d $(GITLAB_PAGES_DIR)/ringbuffer ]; then \
		echo "Removing existing ringbuffer directory from $(GITLAB_PAGES_DIR)..."; \
		rm -rf $(GITLAB_PAGES_DIR)/ringbuffer; \
	fi
	@if [ ! -d $(DOCS_BASE_DIR) ]; then \
		echo "ERROR: $(DOCS_BASE_DIR) directory not found. Run 'make create-doc' first." >&2; \
		exit 1; \
	fi
	echo "Moving $(DOCS_BASE_DIR) to $(GITLAB_PAGES_DIR)/ringbuffer..."
	mv $(DOCS_BASE_DIR) $(GITLAB_PAGES_DIR)/ringbuffer
	@echo "Published to GitLab Pages at $(GITLAB_PAGES_DIR)/ringbuffer"
