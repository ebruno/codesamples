# Top-level Makefile for codesamples directory

# Shell script extension based on host OS (golden rule: zsh on macOS, sh elsewhere)
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  SHELL_EXT := zsh
else
  SHELL_EXT := sh
endif

GITHUB_PAGES_DIR = ./docs
GITLAB_PAGES_DIR  = ./pages
SUBDIRS = ringbuffer

.PHONY: publish-to-github-pages publish-to-gitlab-pages clean dist-clean

publish-to-github-pages:
	@echo "=== Publishing to GitHub Pages ==="
	@if [ ! -d $(GITHUB_PAGES_DIR) ]; then mkdir -p $(GITHUB_PAGES_DIR); fi
	@for subdir in $(SUBDIRS); do \
		echo "=== Publishing $$subdir to GitHub Pages ==="; \
		if [ -d "$$subdir" ]; then $(MAKE) -C "$$subdir" publish-to-github-pages; else echo "WARNING: $$subdir not found"; fi; \
	done
	@echo "=== Generating GitHub Pages index ==="
	./utils/bin/generate_docs_index.$(SHELL_EXT) github

publish-to-gitlab-pages:
	@echo "=== Publishing to GitLab Pages ==="
	@if [ ! -d $(GITLAB_PAGES_DIR) ]; then mkdir -p $(GITLAB_PAGES_DIR); fi
	@for subdir in $(SUBDIRS); do \
		echo "=== Publishing $$subdir to GitLab Pages ==="; \
		if [ -d "$$subdir" ]; then $(MAKE) -C "$$subdir" publish-to-gitlab-pages; else echo "WARNING: $$subdir not found"; fi; \
	done
	@echo "=== Generating GitLab Pages index ==="
	./utils/bin/generate_docs_index.$(SHELL_EXT) gitlab

clean:
	@echo "=== Cleaning publish directories ==="
	@if [ -d $(GITHUB_PAGES_DIR) ]; then for dir in $(SUBDIRS); do rm -rf "$(GITHUB_PAGES_DIR)/$$dir"; done; fi
	@if [ -d $(GITLAB_PAGES_DIR) ]; then for dir in $(SUBDIRS); do rm -rf "$(GITLAB_PAGES_DIR)/$$dir"; done; fi

dist-clean: clean
	@echo "=== Dist-cleaning publish directories ==="
	@if [ -d $(GITHUB_PAGES_DIR) ]; then find $(GITHUB_PAGES_DIR) -mindepth 1 ! -name '.required_directory' -exec rm -rf {} + 2>/dev/null || true; fi
	@if [ -d $(GITLAB_PAGES_DIR) ]; then find $(GITLAB_PAGES_DIR) -mindepth 1 ! -name '.required_directory' -exec rm -rf {} + 2>/dev/null || true; fi
