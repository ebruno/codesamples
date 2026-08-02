#!/bin/tcsh

# Default values
set lines = 10
set output_file = ""

# Usage function
usage() {
    echo "Usage: generate_test_data.tcsh [-l lines] [output_file]"
    echo "  -l lines: Number of lines to generate. Defaults to 10."
    echo "  -h: Display usage information."
    exit 1
}

# Parse options
while ("!" $status && $# > 0 && "$1" =~ ^- ) {
    if ("$1" == "-h") then
        usage
    else if ("$1" == "-l") then
        set lines = $2
        set 1 = ""
        set 2 = ""
    else
        usage
    endif
    shift
}

# The remaining argument is the output file
if ($# > 0) then
    set output_file = $1
endif

set payload = "ABCEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>"
set payload_len = 46
set cycle = 92

foreach i (1)
    set seq_num = 0000
    set p = -1
    if ($i > 1) then
        @ m = ( ($i - 2) % $cycle )
        if ($m < 46) then
            @ p = $m + 1
        else
            @ p = $cycle - 1 - $m
        endif
    endif

    if ($p >= 0 && $p < $payload_len) then
        # Tcsh doesn't have easy string slicing.
        # Use a helper or sed.
        set line = "`echo \"$seq_num $payload $seq_num\" | sed \"s/^\([0-9]\{4\} \).\([^$]*\)/\1 \\2/\"`"
        # The above sed is hard to make dynamic.
        # Let's use a loop to build it or just call a shell one-liner.
        set line = `echo "$seq_num $payload $seq_num" | perl -ne 's/(\d{4} )(.{0,46}) (\d{4})/  . substr($2,0,) . " " . substr($2,+1) . " " . $3 /e' `
        # Since we can't guarantee perl, let's use a simple loop in a subshell.
        set line = `sh -c "p=$p; payload='$payload'; seq='$seq_num'; res=''; j=0; while [ $j -lt $payload_len ]; do char=$(echo $payload | cut -c $(expr $j + 1)); if [ $j -eq $p ]; then res=\"$res \"; else res=\"$res$char\"; fi; j=$(expr $j + 1); done; echo \"$seq $res $seq\"" `
    else
        set line = "$seq_num $payload $seq_num"
    endif
    echo "$line"
end | {
    if ("$output_file" != "") then
        cat > "$output_file"
    else
        cat
    endif
}
