include ../version.mk

CXX := clang++
CXXFLAGS = -std=c++20 -O3 -I.. -I../src/macos/cpp
LDFLAGS = -Wl,-rpath,$(abspath ../lib)

RM = rm -f

UTILS_PROMPT_DIR = ../../../../prompts/common/cpp/utils/bin
UTILS_BIN_DIR = utils/bin

BIN_DIR = bin
LIB_DIR = ../lib
LOG_DIR = logs
REPORT_DIR = reports

all: test001_staticlib test001_dynamiclib

test001_staticlib: src/test001.cpp
	@mkdir -p $(BIN_DIR)
	$(CXX) $(CXXFLAGS) src/test001.cpp $(LIB_DIR)/libswtr_ringbuffer.a -o $(BIN_DIR)/test001_staticlib

test001_dynamiclib: src/test001.cpp
	@mkdir -p $(BIN_DIR)
	$(CXX) $(CXXFLAGS) src/test001.cpp -L$(LIB_DIR) -lswtr_ringbuffer -o $(BIN_DIR)/test001_dynamiclib

deploy_utils:
	mkdir -p $(UTILS_BIN_DIR)
	cp $(UTILS_PROMPT_DIR)/* $(UTILS_BIN_DIR)/

container:
	@echo "Container not used for macOS native build"

verify: deploy_utils all
	@mkdir -p $(LOG_DIR) $(REPORT_DIR)
	@# Audit Trail: capture compiler and linker versions
	@echo "Compiler:" > $(REPORT_DIR)/compiler_version.txt
	@clang++ -v >> $(REPORT_DIR)/compiler_version.txt 2>&1 || true
	@echo "Linker:" >> $(REPORT_DIR)/compiler_version.txt
	@ld -v >> $(REPORT_DIR)/compiler_version.txt 2>&1 || true
	@echo "Running Test Matrix..."
	@# T001: Identity transform, normal operation (expect exit 0)
	@$(BIN_DIR)/test001_staticlib -o $(LOG_DIR)/t001_out.txt -l $(LOG_DIR)/t001.log data/inputs/test001.txt; echo $$? > $(LOG_DIR)/t001.exit
	@diff -q $(LOG_DIR)/t001_out.txt data/expected/t001_out.txt > /dev/null 2>&1 && echo "T001: PASS (output match)" || echo "T001: FAIL (output mismatch)"
	@# T002: Stress test (1 slot, 1 byte buffer) (expect exit 0)
	@$(BIN_DIR)/test001_staticlib -s 1 -b 1 -o $(LOG_DIR)/t002_out.txt -l $(LOG_DIR)/t002.log data/inputs/test001.txt; echo $$? > $(LOG_DIR)/t002.exit
	@diff -q $(LOG_DIR)/t002_out.txt data/expected/t002_out.txt > /dev/null 2>&1 && echo "T002: PASS (output match)" || echo "T002: FAIL (output mismatch)"
	@# T003: Uppercase transform (expect exit 0)
	@$(BIN_DIR)/test001_staticlib -b 10 -t 1 -o $(LOG_DIR)/t003_out.txt -l $(LOG_DIR)/t003.log data/inputs/test001.txt; echo $$? > $(LOG_DIR)/t003.exit
	@diff -q $(LOG_DIR)/t003_out.txt data/expected/t003_out.txt > /dev/null 2>&1 && echo "T003: PASS (output match)" || echo "T003: FAIL (output mismatch)"
	@# T004: Small input, fast EOF (expect exit 0)
	@$(BIN_DIR)/test001_staticlib -o $(LOG_DIR)/t004_out.txt -l $(LOG_DIR)/t004.log data/inputs/test001.txt; echo $$? > $(LOG_DIR)/t004.exit
	@diff -q $(LOG_DIR)/t004_out.txt data/expected/t004_out.txt > /dev/null 2>&1 && echo "T004: PASS (output match)" || echo "T004: FAIL (output mismatch)"
	@# T005: Fatal error mode (expect exit 1)
	@$(BIN_DIR)/test001_staticlib -e 1 -o $(LOG_DIR)/t005_out.txt -l $(LOG_DIR)/t005.log data/inputs/test001.txt; echo $$? > $(LOG_DIR)/t005.exit
	@# T006: Non-fatal error mode (expect exit 0)
	@$(BIN_DIR)/test001_staticlib -e 2 -o $(LOG_DIR)/t006_out.txt -l $(LOG_DIR)/t006.log data/inputs/test001.txt; echo $$? > $(LOG_DIR)/t006.exit
	@diff -q $(LOG_DIR)/t006_out.txt data/expected/t006_out.txt > /dev/null 2>&1 && echo "T006: PASS (output match)" || echo "T006: FAIL (output mismatch)"
	@# T007: XOR transform (expect exit 0)
	@$(BIN_DIR)/test001_staticlib -t 2 -o $(LOG_DIR)/t007_out.txt -l $(LOG_DIR)/t007.log data/inputs/test001.txt; echo $$? > $(LOG_DIR)/t007.exit
	@diff -q $(LOG_DIR)/t007_out.txt data/expected/t007_out.txt > /dev/null 2>&1 && echo "T007: PASS (output match)" || echo "T007: FAIL (output mismatch)"
	@# Generate Reports (Markdown + JUnit XML)
	@./utils/bin/generate_junit_report.zsh
	@echo "Verification complete."

clean:
	@$(RM) -r $(BIN_DIR)/* $(LOG_DIR)/*
	@$(RM) *.o $(BIN_DIR)/*.o *~ #*#

dist-clean: clean
	@$(RM) -r $(LOG_DIR) $(REPORT_DIR)
