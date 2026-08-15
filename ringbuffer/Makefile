.PHONY: clean dist-clean sync-claude dist-clean-containers

# Discover all OS directories that have a Makefile
OS_DIRS := $(wildcard src/*/cpp/Makefile)
# Strip the trailing /Makefile to get src/<os>/cpp paths
OS_CPP_DIRS := $(patsubst %/Makefile,%,$(OS_DIRS))

# Detect container runtime based on host OS
CONTAINER_CMD := $(shell if command -v container >/dev/null 2>&1; then echo "container"; elif command -v podman >/dev/null 2>&1; then echo "podman"; else echo ""; fi)

clean:
	@find . -maxdepth 1 -name "*~" -exec ${RM} {} \;
	@find . -maxdepth 1 -name "#*#" -exec ${RM} {} \;	
	@find prompts -type f \( -name "*~" -o -name "#*#" \) -delete
	@for dir in $(OS_CPP_DIRS); do \
		echo "Cleaning $$dir ..."; \
		$(MAKE) -C $$dir clean; \
	done

dist-clean: clean
	@for dir in $(OS_CPP_DIRS); do \
		echo "Dist-cleaning $$dir ..."; \
		$(MAKE) -C $$dir dist-clean; \
	done

dist-clean-containers:
	@if [ -z "$(CONTAINER_CMD)" ]; then \
		echo "ERROR: No container runtime found (container or podman required)."; exit 1; \
	fi
	@echo "Removing C/C++ build containers..."
	@for os in debian fedora ubuntu; do \
		echo "  Removing ringbuffer_$${os}_build and ringbuffer_$${os}_test"; \
		$(CONTAINER_CMD) image rm -f "ringbuffer_$${os}_build" 2>/dev/null || true; \
		$(CONTAINER_CMD) image rm -f "ringbuffer_$${os}_test" 2>/dev/null || true; \
	done
	@echo "Removing Java containers..."
	@for os in debian fedora ubuntu raspios; do \
		echo "  Removing ringbuffer_java_$${os} and ringbuffer_java_$${os}_test"; \
		$(CONTAINER_CMD) image rm -f "ringbuffer_java_$${os}" 2>/dev/null || true; \
		$(CONTAINER_CMD) image rm -f "ringbuffer_java_$${os}_test" 2>/dev/null || true; \
	done
	@echo "Removing Python containers..."
	@for os in debian fedora ubuntu; do \
		echo "  Removing ringbuffer_python_$${os}_test"; \
		$(CONTAINER_CMD) image rm -f "ringbuffer_python_$${os}_test" 2>/dev/null || true; \
	done

# Sync .bionic → CLAUDE.md (keep LM Studio Bionic and Claude Code in sync)
sync-claude:
	@cp .bionic CLAUDE.md
