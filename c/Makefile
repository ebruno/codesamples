CFLAGS 	        = -std=c23

SRCS 		= fizzbuzz.c

OBJS            = $(SRCS:*.c=.obj)

TARGET		= fizzbuzz

.PHONY: clean dist-clean refactor run_prompt

all: $(TARGET)

$(TARGET): $(OBJS)
	@$(CC) $(OBJS) -o $(TARGET)

%.o: %.c
	@$(CC) $(CFLAGS) -c $< -o $@

clean:
	@find . -maxdepth 1 -name "*~" -exec ${RM} {} \;
	@find . -maxdepth 1 -name "#*#" -exec ${RM} {} \;
	@$(RM) -f $(TARGET) $(foreach src,$(SRCS),prompt_$(src).txt)

dist-clean: clean

refactor:
	@if [ "$$(uname -s)" = "Darwin" ]; then ./assemble_prompt.zsh $(SRCS); else ./assemble_prompt.sh $(SRCS); fi

run_prompt:
	python3 prompt_engine.py $(SRCS)
