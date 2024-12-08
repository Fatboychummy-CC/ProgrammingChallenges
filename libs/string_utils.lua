--- String utilities

---@class string_utils
local string_utils = {}


--- Split a string into a table of strings.
---@param str string The string to split.
---@param sep string The separator to split the string by.
---@return string[] parts The parts of the string.
function string_utils.split(str, sep)
  error("You haven't implemented this yet, you fool!")
end


--- `gmatch` a string into a table of strings.
---@param str string The string to split.
---@param pattern string The pattern to split the string by.
---@return string[] parts The parts of the string.
function string_utils.gmatch_t(str, pattern)
  local matches = {}

  for match in str:gmatch(pattern) do
    matches[#matches + 1] = match
  end

  return matches
end


return string_utils