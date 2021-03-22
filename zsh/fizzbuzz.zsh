#!/bin/zsh
# Write a program that prints the numbers from 1 to 100.
# But for multiples of three print “Fizz” instead of
# the number and for the multiples of five print “Buzz”.
# For numbers which are multiples of both three and five print “FizzBuzz”."
# fizzbuzz.sh [start value] [end_value]

declare -i exit_status=0;
ZSH_VERSINFO=("${(@s/./)ZSH_VERSION}")
echo "ZSH_VERSINFO=${#ZSH_VERSINFO[@]};"
echo "ZSH_VERSINFO_A=${ZSH_VERSINFO[1]};"
if [ ${ZSH_VERSINFO[1]} -ge 5 ]; then
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
		   result="${result}Buzz";
	       fi;
	       if [ -z "${result}" ]; then
		    result=${idx};
	       fi;
	       echo "${result}";
	   ((idx++));
	   done;
       else
	   echo "Start ${idx} is greater than max ${max_value}.";
	   exit_status=1;
       fi;
else
    echo "ZSH 5.n or higher is required.";
    exit_status=1;
fi;
exit ${exit_status};
