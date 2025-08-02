CFLAGS 	        =

SRCS 		= fizzbuzz.c

OBJS            = $(SRCS:*.c=.obj)

TARGET		= fizzbuzz

.PHONY: clean dist-clean

all: $(TARGET)

$(TARGET): $(OBJS)
	@$(CC) $(OBJS) -o $(TARGET)

%.o: %.c
	@$(CC) $(CFLAGS) -c $< -o $@

clean:
	@find . -maxdepth 1 -name "*~" -exec ${RM} {} \;
	@find . -maxdepth 1 -name "#*#" -exec ${RM} {} \;
	@$(RM) -f $(TARGET)

dist-clean: clean
