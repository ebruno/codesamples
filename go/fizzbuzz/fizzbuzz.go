// Write a program that prints the numbers from 1 to 100.
// But for multiples of three print “Fizz” instead of
// the number and for the multiples of five print “Buzz”.
// For numbers which are multiples of both three and five print “FizzBuzz”."
//

package main

import (
	"fmt"
	"os"
)

func fizzbuzz(start int, end int, step int, modulo_fizz int, modulo_buzz int) int {
	status := 0
	var result string = ""
	for value := start; value <= end; value += step {
		result = ""
		if (value % modulo_fizz) == 0 {
			result += "fizz"
		}
		if (value % modulo_buzz) == 0 {
			result += "buzz"
		}
		if len(result) == 0 {
			fmt.Printf("%d\n", value)
		} else {
			fmt.Printf("%s\n", result)
		}
	}
	return status
}

func main() {
	exit_status := 0
	start := 1
	end := 100
	step := 1
	modulo_fizz := 3
	module_buzz := 5
	exit_status = fizzbuzz(start, end, step, modulo_fizz, module_buzz)
	os.Exit(exit_status)
}
