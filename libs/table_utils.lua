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

--- Permute a table.
--- This will return a table of all possible permutations of the input table.
---@param t table The table to permutate.
---@return any[] permutations The permutations of the table.
function table_utils.permutate(t)
  if #t == 0 then
    return {}
  end

  if #t == 1 then
    return {t}
  end

  local permutations = {}

  for i = 1, #t do
    local copy = {}
    for j = 1, #t do
      if j ~= i then
        table.insert(copy, t[j])
      end
    end

    local sub_permutations = table_utils.permutate(copy)

    for _, p in ipairs(sub_permutations) do
      table.insert(p, 1, t[i])
      table.insert(permutations, p)
    end
  end

  return permutations
end

--- Calculate all possible combinations of a table (including smaller subsets).
---@param t table The table to calculate combinations for.
---@param size integer? The size of the combinations to return. If nil, returns ALL combinations.
---@return any[] combinations The combinations of the table.
function table_utils.combinations(t, size)
  local function generate_combinations(t, size, start, current_combination, all_combinations)
    if size == 0 then
      table.insert(all_combinations, {table.unpack(current_combination)})
      return
    end

    for i = start, #t do
      table.insert(current_combination, t[i])
      generate_combinations(t, size - 1, i + 1, current_combination, all_combinations)
      table.remove(current_combination)
    end
  end

  local combinations = {}
  if size then
    generate_combinations(t, size, 1, {}, combinations)
  else
    for s = 1, #t do
      generate_combinations(t, s, 1, {}, combinations)
    end
  end

  return combinations
end

return table_utils