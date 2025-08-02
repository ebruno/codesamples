GO              = /opt/homebrew/bin/go

SRCS 		= fizzbuzz.go

TARGET		= fizzbuzz

.PHONY: clean dist-clean

all: $(TARGET)

$(TARGET): $(SRCS)
	@$(GO) build $(SRCS)

clean:
	@find . -maxdepth 1 -name "*~" -exec ${RM} {} \;
	@find . -maxdepth 1 -name "#*#" -exec ${RM} {} \;
	@$(RM) -f $(TARGET)

dist-clean: clean
