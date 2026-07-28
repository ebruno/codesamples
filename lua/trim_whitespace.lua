-- trim_whitespace.lua
-- Utility function to remove leading and trailing whitespace from a string.

local function trim(s)
    if not s then return nil end
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Example usage if run as a script
if arg then
    local input = table.concat(arg, " ")
    if input ~= "" then
        print("Original: '" .. input .. "'")
        print("Trimmed:  '" .. trim(input) .. "'")
    else
        print("Please provide a string to trim.")
    end
end

return trim
