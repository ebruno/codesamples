include version.mk

CXX = clang++
CXXFLAGS = -std=c++20 -O3 -fPIC -Wall -Wextra -Wpedantic -flto -fvisibility=hidden -ffunction-sections -fdata-sections -I.
LDFLAGS = -dead_strip
RM = rm -rf

SRCS = $(wildcard *.cpp)
OBJS_ARM64 = $(SRCS:%.cpp=%.arm64.o)
OBJS_X86_64 = $(SRCS:%.cpp=%.x86_64.o)

LIB_DIR = lib
BUILD_DIR = build

VERSIONED_STATIC = $(LIB_DIR)/libswtr_ringbuffer-$(VERSION).a
VERSIONED_SHARED = $(LIB_DIR)/libswtr_ringbuffer-$(VERSION).dylib

all: static shared

static: $(VERSIONED_STATIC)
	@cd $(LIB_DIR) && ln -sf libswtr_ringbuffer-$(VERSION).a libswtr_ringbuffer.a

$(VERSIONED_STATIC): $(OBJS_ARM64) $(OBJS_X86_64)
	@mkdir -p $(LIB_DIR)
	libtool -static -o $(VERSIONED_STATIC) $(OBJS_ARM64) $(OBJS_X86_64)

shared: $(VERSIONED_SHARED)
	@cd $(LIB_DIR) && ln -sf libswtr_ringbuffer-$(VERSION).dylib libswtr_ringbuffer.dylib

$(VERSIONED_SHARED): $(OBJS_ARM64) $(OBJS_X86_64)
	@mkdir -p $(BUILD_DIR)
	$(CXX) -arch arm64 -dynamiclib -install_name @rpath/libswtr_ringbuffer.dylib $(LDFLAGS) -o $(BUILD_DIR)/libswtr_ringbuffer_arm64.dylib $(OBJS_ARM64)
	$(CXX) -arch x86_64 -dynamiclib -install_name @rpath/libswtr_ringbuffer.dylib $(LDFLAGS) -o $(BUILD_DIR)/libswtr_ringbuffer_x86_64.dylib $(OBJS_X86_64)
	lipo -create $(BUILD_DIR)/libswtr_ringbuffer_arm64.dylib $(BUILD_DIR)/libswtr_ringbuffer_x86_64.dylib -output $(VERSIONED_SHARED)

%.arm64.o: %.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -arch arm64 -c $< -o $@

%.x86_64.o: %.cpp
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -arch x86_64 -c $< -o $@

clean:
	$(RM) $(BUILD_DIR) $(LIB_DIR) \"*~\" \"#*#\"

dist-clean: clean
	$(RM) ../reports logs
verify:
	$(MAKE) -C tests verify
