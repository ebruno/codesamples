#!/bin/bash
# Write a program that prints the numbers from 1 to 100.
# But for multiples of three print “Fizz” instead of
# the number and for the multiples of five print “Buzz”.
# For numbers which are multiples of both three and five print “FizzBuzz”."
# fizzbuzz.sh [start value] [end_value]

declare -i status=0;
if [ ${BASH_VERSINFO[0]} -ge 3 ]; then
       idx=1;
       max_value=100;
       modulo_fizz=3;
       modulo_buzz=5;
       if [ $# -ge 1 ]; then
	   idx=${1};
       fi;
       if [ $# -eq 2 ]; then
	   max_value=${2};
       fi;
       if [ ${idx} -lt ${max_value} ]; then
	   while [ ${idx} -le ${max_value} ]
	   do
	       result=""
	       if [ $((idx % ${modulo_fizz})) -eq 0 ]; then
		   result="Fizz";
	       fi;
	       if [ $((idx % ${modulo_buzz})) -eq 0 ]; then
		   result="${result}"Buzz"";
	       fi;
	       if [ -z "${result}" ]; then
		    result=${idx};
	       fi;
	       echo "${result}";
	   ((idx++));
	   done;
       else
	   echo "Start ${idx} is greater than max ${max_value}.";
	   status=1;
       fi;
else
    echo "BASH 3.n or higher is required.";
    status=1;
fi;
exit ${status};
