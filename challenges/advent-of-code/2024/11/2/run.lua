--- This file contains the default challenge runner, copied to every challenge.
--- 
--- Your code should be put in the `run` function below. You can also add
--- additional functions and variables as needed, however, the main bulk MUST
--- be inside the `run` function.
--- 
--- Do note that everything within the `libs` folder is available to you via
--- `require` calls.
--- 
--- The run function takes two arguments: `input` and `output`. The `input`
--- argument is a mocked file-handle object that you can read from. The `output`
--- argument is a mocked file-handle object that you can write to. You should
--- read from the `input` file and write to the `output` file to solve the
--- challenge.
--- 
--- These mock handles are slightly different than both that of the `io` and `fs`
--- libraries, but they should be fairly simple to adapt to.
--- 
--- The output will be put in both the challenge folder's `output.txt` file, and
--- the root folder's `challenge_output.txt` file.
--- 
--- You can `print` or `write` as much as you want for debugging, but only the
--- information stored in the `output` file will be saved.

-- Part 2 is an optimization problem: We can just keep track of how many of
-- each value we have in a dictionary-style table.
--
-- I probably should have done this for the first part.

--- Run a single iteration of the challenge
---@param values table<integer, integer> The "tree" of numbers.
---@return table<integer, integer> new_values The new values.
local function iterate(values)
  local new_values = {} ---@type table<integer, integer>

  for value, count in pairs(values) do
    if value == 0 then
      new_values[1] = (new_values[1] or 0) + count
    elseif #tostring(value) % 2 == 0 then
      local str = tostring(value)
      local half = #str / 2
      local first_half = tonumber(str:sub(1, half)) --[[@as integer]]
      local second_half = tonumber(str:sub(half + 1)) --[[@as integer]]

      -- Add the new children.
      new_values[first_half] = (new_values[first_half] or 0) + count
      new_values[second_half] = (new_values[second_half] or 0) + count
    else
      new_values[value * 2024] = (new_values[value * 2024] or 0) + count
    end
  end

  return new_values
end



--- Run the challenge.
---@param input MockReadHandle The input handle.
---@param output MockWriteHandle The output handle.
local function run(input, output)
  -- Input is a list of numbers. We keep them as a list, and work with them as
  -- follows:
  -- 1. If the number is `0`, it becomes `1`.
  -- 2. If the number has an even number of digits, it is replaced by two numbers:
  --    the first half of the digits, and the second half of the digits.
  -- 3. If no other rules apply, multiply the number by `2024`.
  -- Part 1: Determine the number of numbers after 25 iterations.
  --
  -- Part 2: Determine the number of numbers after 75 iterations.

  -- Read in the numbers.
  local values = {} ---@type table<integer, integer>
  for n in input:readAll():gmatch("%d+") do
    values[tonumber(n)] = (values[tonumber(n)] or 0) + 1
  end

  -- Iterate over the tree 75 times.
  for i = 1, 75 do
    print("Iteration", i)
    values = iterate(values)
  end


  -- Count the number of "leaves".
  local n_leaves = 0
  for _, count in pairs(values) do
    n_leaves = n_leaves + count
  end

  -- Write the number of leaves.
  output:writeInt(n_leaves)
end

return run