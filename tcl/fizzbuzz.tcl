#!/usr/bin/env tclsh

set start 1
set end 10

if { $argc == 1 } {
    set start [lindex $argv 0]
} elseif { $argc == 2 } {
    set start [lindex $argv 0]
    set end [lindex $argv 1]
}
puts "\[INFO\] Using Start: ${start} end: ${end}"	
if { $start < $end }  {     
    for {set i $start} {$i <= $end} {incr i} {
	if {$i % 15 == 0} {
	    puts "FizzBuzz"
	} elseif {$i % 3 == 0} {
	    puts "Fizz"
	} elseif {$i % 5 == 0} {
	    puts "Buzz"
	} else {
	    puts $i
	}
    }
} else {
    puts "\[ERROR\] Start: ${start} is not less than end: ${end}"	
}
