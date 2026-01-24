// You are given two arbitrarily large numbers,
// stored one digit at a time in a slice.
// The first must be added to the second,
// and the second must be reversed before addition.
//
// The goal is to calculate the sum of those two sets of values.
//
// IMPORTANT NOTE:
// - The input can be any lengths (i.e: it can be 20+ digits long).
// - num1 and num2 can be different lengths.
//
// Sample Inputs:
// num1 = 123456
// num2 = 123456
//
// Sample Output:
// Result: 777777
//
// We would also like to see a demonstration of appropriate unit tests
// for this functionality.


package main

import (
	 "fmt"
	 "strings"
	"math/rand"
	"time"
	"os"
)


func reverse(num_in []int) []int {
	for idx := 0; idx < len(num_in)/2; idx++ {
		jdx := len(num_in) - idx - 1
		num_in[idx], num_in[jdx] = num_in[jdx], num_in[idx]
	}
	return num_in
}


func get_test_arrays(maxlength int, samelength bool) ([]int, []int) {
	len1 := rand.Intn(maxlength)
	len2 := len1
	rand.Seed(time.Now().UTC().UnixNano())
	if samelength == false {
		len2 = rand.Intn(maxlength)
	}
	array1 := make([]int,0,0)
	array2 := make([]int,0,0)
	for idx := 0; idx < len1; idx++ {
		array1 = append(array1,rand.Intn(9))
	}
	for idx := 0; idx < len2; idx++ {
		array2 = append(array2,rand.Intn(9))
	}
	return array1,array2
}

func Add(num1 []int, num2 []int) string {
	var carry_over int = 0
	len_num1 := len(num1)
	len_num2 := len(num2)
	results_as_string := ""
	results := make([]int,0,0)
	max_idx := len_num1

	if max_idx < len_num2 {
		max_idx = len_num2
	}
	num1_idx := len_num1 - 1
	num2_idx := len_num2 - 1
	for idx := 0 ; idx < max_idx; idx++ {
		new_value := carry_over
		if num1_idx >= 0 {
			new_value += num1[num1_idx]
			num1_idx--
		} else {
			new_value = carry_over
		}
		if num2_idx >= 0 {
			new_value += num2[num2_idx]
			num2_idx--
		}
		if new_value > 9 {
			carry_over = new_value/10
			new_value = new_value % 10
		} else {
			carry_over = 0
		}
		results = append([]int{new_value},results...)
	}
	if carry_over > 0 {
		results = append([]int{carry_over},results...)
	}

	results_as_string = strings.Trim(strings.Replace(fmt.Sprint(results), " ", "", -1), "[]")
	return string(results_as_string)
}

func validate_array(nums []int, min int, max int) bool {
	// element should be between min and max
	result := true
	for idx :=0; idx < len(nums); idx++ {
		if nums[idx] < min || nums[idx] > max {
			fmt.Printf("nums[%d]:%d is not valid min=%d max=%d\n",idx,nums[idx],min,max)
			result = false
		}
	}
	return result

}
func main() {
	num1 := []int{}
	num2 := []int{}
	min := 0
	max := 9
	max_digits := 30
	num_samples := 20
	ok_to_process := true
	exit_status := 1
	fmt.Printf("%-30s | %-30s | %-30s | %s\n", "Number 1" ,"Number 2","Reversed Number 2", "Result")
	fmt.Printf("%-30s-|-%-30s-|-%-30s-|-%s\n",
		"------------------------------" ,
		"------------------------------",
		"------------------------------",
		"------------------------------")
	for idx := 0; idx < num_samples; idx++ {
		num1,num2 = get_test_arrays(max_digits,false)
		// Save the original value for reporting later as a string.
		num2_as_string := strings.Trim(strings.Replace(fmt.Sprint(num2), " ", "", -1), "[]")
		reverse(num2)
		ok_to_process = validate_array(num1,min,max)
		ok_to_process = validate_array(num2,min,max)
		if ok_to_process {
			result := Add(num1, num2)
			num1_as_string := strings.Trim(strings.Replace(fmt.Sprint(num1), " ", "", -1), "[]")
			num2_r_as_string := strings.Trim(strings.Replace(fmt.Sprint(num2), " ", "", -1), "[]")
			fmt.Printf("%-30s | %-30s | %-30s | %s\n", num1_as_string,num2_as_string,num2_r_as_string,result)
			exit_status = 0
		}
	}
	os.Exit(exit_status)
}
