#!/usr/bin/env tcsh

# generate_test_data.tcsh
# Purpose: Generate test data with a zig-zag space pattern for Tcsh.
# Usage: generate_test_data.tcsh [-l lines] [output_file]

usage() {
    echo "Usage: generate_test_data.tcsh [-l lines] [output_file]"
    echo "Options:"
    echo "  -l lines    Number of lines to generate. Defaults to 10."
    echo "  -h          Display usage information."
    exit 1
}

set lines = 10
set output_file = ""

set argv_count = $#argv
set i = 1
while ($i <= $argv_count)
    if ("$argv[$i]" == "-l") then
        set i = $i + 1
        set lines = "$argv[$i]"
    else if ("$argv[$i]" == "-h") then
        usage
    else
        set output_file = "$argv[$i]"
    endif
    set i = $i + 1
end

set template = "ABCEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>"
set len = `echo $template | wc -c`
set len = `expr $len - 1`

if ("$output_file" != "") then
    cat /dev/null > "$output_file"
    # Tcsh doesn't have easy redirection for the whole script, 
    # so we'll append to the file in the loop.
endif

set j = 1
while ($j <= $lines)
    # Format sequence number
    set seq = `printf "%04d" $j`
    
    if ($j > 1) then
        set period = `expr 2 \* \( $len - 2 \)`
        set rel_pos = `expr \( $j - 2 \) % $period`
        
        if ($rel_pos <= `expr $len - 2`) then
            set pos = `expr $rel_pos + 2`
        else
            set pos = `expr $period - $rel_pos + 2`
        endif
        
        # Extract prefix and suffix
        # Tcsh doesn't have easy substring. Use cut.
        set prefix = `echo $template | cut -c 1-`$pos-1`
        set suffix = `echo $template | cut -c `expr $pos + 1`-`
        
        set line = "${seq} ${prefix} ${suffix} ${seq}"
    else
        set line = "${seq} ${template} ${seq}"
    endif
    
    if ("$output_file" != "") then
        echo "$line" >> "$output_file"
    else
        echo "$line"
    endif
    
    set j = `expr $j + 1`
end
