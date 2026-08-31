# FizzBuzz on a PDP-11 Running RSX-11M Plus
Introduced in 1975, the 11/70 was top of the line in the famed PDP-11 range.
I worked on various PDP-11 machines in college in 1976-1978 and professionally from 1978-1993.


## Development Environment

[Obsolescence Guaranteed](https://obsolescence.wixsite.com/obsolescence/pidp-11)

## Building

To build the program on a RSX-11M Plus system use the following commands.

```
mac fizzbuzz.obj,fizzbuzz.lst=fizzbuzz.mac
tkb fizzbuzz.tsk=fizzbuzz.obj
```

## Sample Run

```
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
  ...
  26
  FIZZ
  28
  29
  FIZZBUZZ
```
    
