CXXFLAGS 	= --std=c++20

SRCS 		= fizzbuzz.cpp

OBJS            = $(SRCS:*.c=.obj)

TARGET		= fizzbuzz

.PHONY: clean dist-clean

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) $(OBJS) -o $(TARGET)

%.o: %.c
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	@find . -maxdepth 1 -name "*~" -exec ${RM} {} \;
	@find . -maxdepth 1 -name "#*#" -exec ${RM} {} \;
	@$(RM) -f $(TARGET)

dist-clean: clean
