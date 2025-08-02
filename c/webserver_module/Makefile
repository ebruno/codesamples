CFLAGS 	        =

SRCS 		= add_cookie.c \
		  delete_cookie.c \
		  delete_cookies.c \
		  extend_cookies.c \
		  find_cookie.c \
		  init_cookies.c \
		  locate_cookie.c \
		  main.c \
		  sort_cookies.c


OBJS            = $(SRCS:*.c=.obj)

TARGET		= showheader

.PHONY: clean dist-clean test01 test02

all: $(TARGET)

$(TARGET): $(OBJS)
	@$(CC) $(OBJS) -o $(TARGET)

%.o: %.c
	@$(CC) $(CFLAGS) -c $< -o $@

test01:
	@$(CURDIR)/$(TARGET) < test01.txt

test02:
	@$(CURDIR)/$(TARGET) < test02.txt


clean:
	@find . -maxdepth 1 -name "*~" -exec ${RM} {} \;
	@find . -maxdepth 1 -name "#*#" -exec ${RM} {} \;
	@$(RM) -f $(TARGET)

dist-clean: clean
