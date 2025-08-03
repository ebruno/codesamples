GO              = /opt/homebrew/bin/go

SRCS 		= numberadder.go

TARGET		= numberaddr

.PHONY: clean dist-clean

all: $(TARGET)

$(TARGET): $(SRCS)
	@$(GO) build

clean:
	@find . -maxdepth 1 -name "*~" -exec ${RM} {} \;
	@find . -maxdepth 1 -name "#*#" -exec ${RM} {} \;
	@$(RM) -f $(TARGET)

dist-clean: clean
