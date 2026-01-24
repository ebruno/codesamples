//
// Unit tests.
package main

import (
	"fmt"
	"strings"
	"testing"
)

type test_data struct {
	num1 []int
	num2 []int
	expected_result string
}
func TestBasic(t *testing.T) {
	var num1 = []int{1,2,3,4,5,6}
	var num2 = []int{1,2,3,4,5,6}
	var expected_result = "777777"
	num1_string := strings.Trim(strings.Replace(fmt.Sprint(num1), " ", "", -1), "[]")
	num2_string := strings.Trim(strings.Replace(fmt.Sprint(num2), " ", "", -1), "[]")
	reverse(num2)
	result := Add(num1,num2)
	if result != expected_result {
		t.Errorf("Add(%s,%s) expected \"%s\" result: \"%s\"",num1_string,num2_string,expected_result,result)
	}
}

func TestVariablelength(t *testing.T) {
	var tests []test_data
	tests = append(tests,test_data{num1: []int{1,2,3,4,5,6},
		num2: []int{1,2,3,4,5,6},expected_result: "777777"})
	tests = append(tests,test_data{num1: []int{},
		num2: []int{},expected_result: ""})
	tests = append(tests,test_data{num1: []int{4},
		num2: []int{2},expected_result: "6"})
	tests = append(tests,test_data{num1: []int{7},
		num2: []int{7},expected_result: "14"})
	tests = append(tests,test_data{num1: []int{8,8,8},
		num2: []int{8,8,8},expected_result: "1776"})
	tests = append(tests,test_data{num1: []int{2,1,1,6,8}, num2: []int{},expected_result: "21168"})
	tests = append(tests,test_data{num1: []int{},
		num2: []int{2,1,1,6,8},expected_result: "86112"})
	tests = append(tests,test_data{num1: []int{5,2,1,7,1,1,3,6,1,1,1,5},
		num2: []int{5,0,8,2,8},expected_result: "521711443920"})
	tests = append(tests,test_data{num1: []int{4,6,4,0,5,7,7,2,7,6,5,0,1,2,1,4,1,5,8,8,0,5,2,3,6,4,8},
		num2: []int{5,2,1,7,3,4,2,7,8,4,8,8},
		expected_result: "464057727650122300752960773"})
//	tests = append(tests,test_data{num1: []int{}, num2: []int{},expected_result: ""})
//	tests = append(tests,test_data{num1: []int{}, num2: []int{},expected_result: ""})
//	tests = append(tests,test_data{num1: []int{}, num2: []int{},expected_result: ""})
	for _, test := range tests {
		num1_string := strings.Trim(strings.Replace(fmt.Sprint(test.num1), " ", "", -1), "[]")
		num2_string := strings.Trim(strings.Replace(fmt.Sprint(test.num2), " ", "", -1), "[]")
		testname := fmt.Sprintf("\"%s+%s\"",num1_string,num2_string)
		t.Run(testname,func (t *testing.T) {
			reverse(test.num2)
			result := Add(test.num1,test.num2)
			if result != test.expected_result {
				t.Errorf("Add(%s,%s) expected \"%s\" result: \"%s\"",num1_string,
					num2_string,test.expected_result,result)
			}
		})
	}
}
