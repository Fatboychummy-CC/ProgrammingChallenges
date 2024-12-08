--- Utilities for tables.


---@class table_utils
local table_utils = {}

--- Sum the values of an array
---@param t table The table to sum.
---@return number sum The sum of the table values.
function table_utils.sum(t)
  local sum = 0
  for _, v in ipairs(t) do
    sum = sum + v
  end
  return sum
end


--- Get the keys of a table.
---@param t table The table to get the keys of.
---@return any[] keys The keys of the table.
function table_utils.keys(t)
  local keys = {}
  for k, _ in pairs(t) do
    table.insert(keys, k)
  end
  return keys
end

--- Invert a table (keys -> values, values -> keys).
---@param t table The table to invert.
---@return table inverted The inverted table.
function table_utils.invert(t)
  local inverted = {}
  for k, v in pairs(t) do
    inverted[v] = k
  end
  return inverted
end

--- Check if a (or many) value(s) is(are) in a table.
---@param t table The table to check.
---@param ... any The value(s) to check for.
---@return boolean is_in True if all values are in the table, false otherwise.
function table_utils.contains(t, ...)
  for _, v in ipairs({...}) do
    for _, tv in pairs(t) do
      if tv == v then
        return true
      end
    end
  end
  return false
end

return table_utils