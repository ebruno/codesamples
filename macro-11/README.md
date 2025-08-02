# Fizzbuzz on an PDP-11 Running RSX-11M Plus. #
Introduced in 1975, the 11/70 was top of the line in the famed PDP-11 range.
I worked on various PDP-11 machines in college in 1976-1978 and professionally from 1978-1993.


## Development Environment ##

[Obsolescence Guaranteed](https://obsolescence.wixsite.com/obsolescence/pidp-11)

## Building the program ##

To build the program on a RSX-11M Plus system use the following commands.

    mac fizzbuzz.obj,fizzbuzz.lst=fizzbuzz.mac
    tkb fizzbuzz.tsk=fizzbuzz.obj
	
	
## Sample run ##

	  >run fizzbuzz.tsk
	  1
	  2
	  FIZZ
	  4
	  BUZZ
	  FIZZ
	  7
	  8
	  FIZZ
	  BUZZ
	  11
	  FIZZ
	  13
	  14
	  FIZZBUZZ
	  16
	  17
	  FIZZ
	  19
	  BUZZ
	  FIZZ
	  22
	  23
	  FIZZ
	  BUZZ
	  26
	  FIZZ
	  28
	  29
	  FIZZBUZZ
	
