# validate-tools.mk — thin Makefile for probe-os only
# Does NOT have all/clean/test targets — build still uses src/common/<lang>/

.PHONY: probe-os

OS_NAME = raspios
PROJECT_ROOT_DIR := $(abspath $(CURDIR)/../../..)
PROBE_COMPILER ?= $(PYTHON)$(JAVA)

probe-os:
	@echo "Probing compiler availability for ${OS_NAME}/python..."
	@${PROJECT_ROOT_DIR}/utils/bin/probe_targets.sh ${OS_NAME} python $(PROBE_COMPILER)
