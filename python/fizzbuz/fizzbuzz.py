#!/usr/bin/env python3
# Write a program that prints the numbers from 1 to 100.
# But for multiples of three print “Fizz” instead of
# the number and for the multiples of five print “Buzz”.
# For numbers which are multiples of both three and five print “FizzBuzz”."
import sys


def fizzbuzz(start=1,end=100,increment=1,modulo_fizz=3, modulo_buzz=5):
    status=0;
    if start <= end:
        for item in range(start,end+1,increment):
            result=""
            if (item % modulo_fizz) == 0:
                result += "Fizz"
            if (item % modulo_buzz) == 0:
                result += "Buzz"
            if len(result) == 0:
                result=item
            print(result)
    else:
        status=1
    return status

def main():
    status = fizzbuzz()
    return status

if __name__ == "__main__":
    sys.exit(main())
