# prompts/common/cpp/Makefile — Man page generation (GNU make)
# Include this from OS-specific Makefiles: include ../../prompts/common/cpp/Makefile

PANDOC_CMD := $(shell command -v pandoc 2>/dev/null)
MAN_SRC = $(CURDIR)/../../prompts/common/cpp/swtr_ringbuffer.md
MAN_OUT = swtr_ringbuffer.1

.PHONY: man-page clean-man

man-page: $(MAN_OUT)

$(MAN_OUT): $(MAN_SRC)
	@if [ -n "$(PANDOC_CMD)" ]; then \
		echo "Generating man page: $@"; \
		$(PANDOC_CMD) $(MAN_SRC) -t man -o $@; \
	else \
		echo "WARNING: pandoc not found — skipping man page generation"; \
	fi

clean-man:
	@rm -f $(MAN_OUT)
