TOP      = .

OBJS     = main.o \
	   add_cookie.o \
	   init_cookies.o \
	   sort_cookies.o \
           extend_cookies.o \
           find_cookie.o \
           locate_cookie.o \
           delete_cookie.o \
           delete_cookies.o

SOURCE   = main.c \
	   sort_cookies.c \
           add_cookie.c \
           extend_cookies.c \
           find_cookie.c \
           init_cookies.c \
           locate_cookie.c \
           delete_cookie.c \
           delete_cookies.c

HEADER   = webmodule.h
BINNAME  = webmodule
CC	 = cc
DEBUG    = -g
FLAGS	 = $(DEBUG) -c -Wall -std=c99
LFLAGS	 = 

all: $(OBJS)
	@$(CC) $(DEBUG) $(OBJS) -o $(BINNAME) $(LFLAGS)

test01: all
	cat test01.txt | ./$(BINNAME)

test02: all
	cat test02.txt | ./$(BINNAME)

main.o: main.c
	$(CC) $(FLAGS) main.c 

sort_cookies.o: sort_cookies.c
	$(CC) $(FLAGS) sort_cookies.c 

init_cookies.o: init_cookies.c
	$(CC) $(FLAGS) init_cookies.c 

extend_cookies.o: extend_cookies.c
	$(CC) $(FLAGS) extend_cookies.c 

add_cookie.o: add_cookie.c
	$(CC) $(FLAGS) add_cookie.c 

find_cookie.o: find_cookie.c
	$(CC) $(FLAGS) find_cookie.c 

locate_cookie.o: locate_cookie.c
	$(CC) $(FLAGS) locate_cookie.c 

delete_cookies.o: delete_cookies.c
	$(CC) $(FLAGS) delete_cookies.c 

delete_cookie.o: delete_cookie.c
	$(CC) $(FLAGS) delete_cookie.c 

clean:
	@rm -f $(OBJS) $(BINNAME)
	@rm -r -f *.dSYM
	@rm -f *~;