#!/usr/bin/env lua

-- fizzbuzz.lua [start value] [end_value]

local start_val = tonumber(arg[1]) or 1
local end_val = tonumber(arg[2]) or 100
local modulo_fizz = 3
local modulo_buzz = 5

if start_val < end_val then
    for idx = start_val, end_val do
        local result = ""
        if idx % modulo_fizz == 0 then
            result = result .. "Fizz"
        end
        if idx % modulo_buzz == 0 then
            result = result .. "Buzz"
        end
        if result == "" then
            result = tostring(idx)
        end
        print(result)
    end
    os.exit(0)
else
    print("Start " .. start_val .. " is greater than or equal to max " .. end_val .. ".")
    os.exit(1)
end
