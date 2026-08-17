include version.mk

# Toolchain configuration — FreeBSD clang++ (only compiler available)
CXX := clang++

# LTO flag: always -flto=thin on FreeBSD (no g++ special case)
LTO_FLAG = -flto=thin

# FreeBSD: clang++ uses libc++ by default (headers available)
CXXFLAGS = -std=c++20 -O3 -fPIC -Wall -Wextra -Wpedantic ${LTO_FLAG} -fvisibility=hidden -ffunction-sections -fdata-sections -I. -pthread

# Linker flags: FreeBSD uses ELF, same as Linux
LDFLAGS = -Wl,--gc-sections

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

.PHONY: all static shared clean dist-clean test-all

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

clean:
	${RM} ${BUILD_DIR} ${LIB_DIR} *.o *~ #*#

dist-clean: clean
.if exists(tests)
	${MAKE} -C tests dist-clean
.endif
	${RM} reports ../reports logs
