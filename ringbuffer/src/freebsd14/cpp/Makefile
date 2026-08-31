.include "version.mk"

# Man page generation (BSD make)
PANDOC_CMD = pandoc
MAN_SRC = ${PROJECT_ROOT_DIR}/prompts/common/cpp/swtr_ringbuffer.md
MAN_OUT = swtr_ringbuffer.1

# OS name for registry lookup
OS_NAME = freebsd14

# Project root (workspace top-level directory)
PROJECT_ROOT_DIR := ${.CURDIR}/../../..

# Toolchain configuration — FreeBSD clang++ (only compiler available)
CXX = clang++

# LTO flag: always -flto=thin on FreeBSD (no g++ special case)
LTO_FLAG = -flto=thin

# FreeBSD: clang++ uses libc++ by default (headers available)
CXXFLAGS = -std=c++20 -O3 -fPIC -Wall -Wextra -Wpedantic ${LTO_FLAG} \
           -fvisibility=hidden -ffunction-sections -fdata-sections -I. -pthread

# Linker flags: FreeBSD uses ELF, same as Linux
# Absolute RPATH so ctypes can load the shared library at test time
LDFLAGS = -Wl,--gc-sections -Wl,-rpath,${.CURDIR}/lib

RM = rm -rf

# Source files — list explicitly (BSD make has no $(wildcard))
SRCS = Lifecycle.cpp ReadOps.cpp WriteOps.cpp TransformOps.cpp Threading.cpp ErrorOps.cpp \
       Accessors_ChecksumAlg.cpp Accessors_ChecksumVal.cpp Accessors_Size_Data.cpp \
       Accessors_Size_Max.cpp Accessors_Size_Transformed.cpp Accessors_Status.cpp \
       LoggingOps_1.cpp LoggingOps_2.cpp LoggingOps_3.cpp LoggingOps_4.cpp \
       LoggingOps_5.cpp LoggingOps_6.cpp

OBJS = ${SRCS:.cpp=.o}

LIB_DIR = lib
BUILD_DIR = build

VERSIONED_STATIC = ${LIB_DIR}/libswtr_ringbuffer-${VERSION}.a
VERSIONED_SHARED = ${LIB_DIR}/libswtr_ringbuffer-${VERSION}.so

.SUFFIXES: .cpp
.PHONY: test  all static shared clean dist-clean test-all man-page

all: static shared

static: ${VERSIONED_STATIC}
	cd ${LIB_DIR} && ln -sf libswtr_ringbuffer-${VERSION}.a libswtr_ringbuffer.a

${VERSIONED_STATIC}: ${OBJS}
	@mkdir -p ${LIB_DIR}
	ar rcs ${VERSIONED_STATIC} ${OBJS}

shared: ${VERSIONED_SHARED}
	cd ${LIB_DIR} && ln -sf libswtr_ringbuffer-${VERSION}.so libswtr_ringbuffer.so

${VERSIONED_SHARED}: ${OBJS}
	@mkdir -p ${LIB_DIR}
	${CXX} -shared ${LDFLAGS} -Wl,-soname,libswtr_ringbuffer.so -o ${VERSIONED_SHARED} ${OBJS}

%.o: %.cpp
	@mkdir -p ${BUILD_DIR}
	${CXX} ${CXXFLAGS} -c $< -o $@
test: all
	@if [ -d tests ]; then $(MAKE) -C tests verify; else echo "No tests directory"; fi

clean:
	${RM} ${BUILD_DIR} ${LIB_DIR} *.o *~ #*#
	@find . -name '*.o.tmp' | xargs rm -f 2>/dev/null || true
	@rm -f ${MAN_OUT}

dist-clean: clean
.if exists(tests)
	${MAKE} -C tests dist-clean
.endif
	${RM} reports ../reports logs ${MAN_OUT}

man-page: ${MAN_OUT}
	@if command -v ${PANDOC_CMD} >/dev/null 2>&1; then \
		echo "Generating man page: ${MAN_OUT}"; \
		${PANDOC_CMD} ${MAN_SRC} -t man -o ${MAN_OUT}; \
	else \
		echo "WARNING: pandoc not found — skipping man page generation"; \
	fi

${MAN_OUT}: ${MAN_SRC}
	@true

# Probe OS/compiler availability (manual use only — not called by other rules)
PROBE_COMPILER ?= $(CXX)

probe-os:
	@echo "Probing compiler availability for ${OS_NAME}/cpp..."
	@${PROJECT_ROOT_DIR}/utils/bin/probe_targets.sh ${OS_NAME} cpp $(PROBE_COMPILER)
