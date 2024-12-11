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

local _tree = require "n_tree"

--- Run a single iteration of the challenge
---@param tree nTree The tree of numbers.
local function iterate(tree)
  -- Iterate over the tree, applying the rules.
  local nodes = tree:get_leaves()

  for _, node in ipairs(nodes.nodes) do
    local value = node.value

    if value == 0 then
      node.value = 1
    elseif #tostring(value) % 2 == 0 then
      local str = tostring(value)
      local half = #str / 2
      local first_half = tonumber(str:sub(1, half))
      local second_half = tonumber(str:sub(half + 1))

      -- Add the new children.
      node.new_child(first_half)
      node.new_child(second_half)
    else
      node.value = value * 2024
    end
  end
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

  -- Read in the numbers.
  local tree = _tree.new() -- The tree of numbers. Initial children are the input.
  for n in input:readAll():gmatch("%d+") do
    tree.new_child(tonumber(n))
  end

  -- Iterate over the tree 25 times.
  for i = 1, 25 do
    print("Iteration", i)
    iterate(tree)
  end

  -- Count the number of leaves.
  local leaves = tree:get_leaves()
  local n_leaves = #leaves.nodes

  -- Write the number of leaves.
  output:write(n_leaves)
end

return run