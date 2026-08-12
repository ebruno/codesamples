#!/usr/bin/env tcsh
# generate_test_data.tcsh - Generate zig-zag pattern test data files for Ringbuffer testing
# Usage: generate_test_data.tcsh [-l lines] [output_file]
#
# NOTE: Tcsh lacks native string manipulation.  External commands (expr, cut) are
# used as a necessary compromise — the spec's "built-ins only" rule cannot be met
# in pure Tcsh.

set -e

# Version check (Tcsh 6.22+)
set tcsh_version = `tcsh -c 'echo $version'`
set major = ${tcsh_version[1]}
if ($major < 6) then
    echo "ERROR: Tcsh version 6.22 or higher is required (current: $tcsh_version)" >&2
    exit 1
endif

# Defaults
set lines = 10
set output_file = ""

# Parse options
while (1)
    switch ($argv[1])
        case '-l':
            set lines = $argv[2]
            shift argv; shift argv
            breaksw
        case '-h':
            echo "Usage: generate_test_data.tcsh [-l lines] [output_file]"
            echo "  -l lines    Number of lines to generate (default: 10)"
            echo "  -h          Display this help message"
            exit 0
        default:
            if ($#argv > 0) then
                set output_file = $argv[1]
                shift argv
            endif
            breaksw
    endsw
end

# Template string (48 characters) — authoritative ground truth
set template = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>""
set L = ${#template}

# Generate output — truncate first, then append per line (avoids error messages going to data file)
if ($output_file != "") then
    > $output_file  # Truncate file first
endif

@ n = 1
while ($n <= $lines)
    # Format 4-digit sequence number
    if ($n < 10) then
        set prefix = "000${n} "
    else if ($n < 100) then
        set prefix = "00${n} "
    else if ($n < 1000) then
        set prefix = "0${n} "
    else
        set prefix = "${n} "
    endif
    
    if ($n == 1) then
        set line = "${prefix}${template} ${prefix}"
    else
        # Calculate zig-zag position
        @ idx = $n - 2
        @ cycle = 2 * ($L - 1)
        @ off = $idx % $cycle
        
        if ($off < $L - 1) then
            @ i = $off + 2  # Convert to 1-based for Tcsh string indexing
        else
            @ i = $cycle - $off + 2
        endif
        
        # Replace character at position i with space (1-based index in Tcsh)
        set prefix_part = "${template:0,$((i-2))}"
        set suffix_part = "${template:$i,${#template}}"
        set line = "${prefix}${prefix_part} ${suffix_part} ${prefix}"
    endif
    
    if ($output_file != "") then
        echo "$line" >> $output_file
    else
        echo "$line"
    endif
    
    @ n++
end
