# BSD Make-compatible Makefile for FreeBSD 14 Java build
# Uses BSD make syntax (no $(shell), no ifeq/else)
# Source code lives in src/common/java — this is the BSD make override

.PHONY: all clean dist-clean test

# JDK version (FreeBSD 14 default)
JDKVER ?= 25

# Common Java source directory (same as src/common/java)
COMMON_SRC_DIR := ../../common/java

# Clean build artifacts (Maven target directory)
clean:
	@echo "Cleaning Java build artifacts..."
	cd ${COMMON_SRC_DIR} && \
	if [ -d target ]; then \
		rm -rf target; \
		echo "  Removed target/"; \
	else \
		echo "  Nothing to clean."; \
	fi

# Native build — FreeBSD 14 has no containers, run Maven directly from common source
all: clean
	@echo "Building Java (FreeBSD 14 native)..."
	cd ${COMMON_SRC_DIR} && mvn -q clean package || { echo "ERROR: Maven build failed"; exit 1; }
	@echo "Java build complete."

# Run full build + tests via Maven
test: clean
	@echo "Running Java test suite..."
	cd ${COMMON_SRC_DIR} && mvn -q clean test || { echo "ERROR: mvn test failed"; exit 1; }
	@echo "Java tests passed."

# Full cleanup: build artifacts only (no containers on FreeBSD)
dist-clean: clean
	@rm -rf logs 2>/dev/null || true
	@echo "Java dist-clean complete."
