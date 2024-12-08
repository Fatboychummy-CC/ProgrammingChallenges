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

local _tree = require "tree"
local table_utils = require "table_utils"
local string_utils = require "string_utils"

--- Check if the given number can be determined.
---@param n integer The number to check.
---@param numbers integer[] The numbers to check against.
---@return boolean can_determine True if the number can be determined, false otherwise.
local function can_determine(n, numbers)
  --print("Can determine", n, ":", table.unpack(numbers))
  local tree = _tree.new(numbers[1])
  -- Addition will be to the left
  -- Multiplication will be to the right

  ---@param obj Tree
  local function insert(obj, v)
    obj.new_left(obj.value + v)
    obj.new_right(obj.value * v)
  end

  for i = 2, #numbers do
    local layer = tree.get_layer(i - 2)

    for _, node in ipairs(layer.nodes) do
      insert(node, numbers[i])
    end
  end

  --[[for i = 0, tree.count_layers() do
    for _, value in ipairs(tree.get_layer(i):as_values()) do
      print((' '):rep(i), value)
    end
  end]]

  --print("Leaves:", table.unpack(tree.get_leaves():as_values()))

  local result = table_utils.contains(tree.get_leaves():as_values(), n)
  --print(" ", result)
  return result
end

--- Run the challenge.
---@param input MockReadHandle The input handle.
---@param output MockWriteHandle The output handle.
local function run(input, output)
  -- Input is a number followed by a colon followed by some more numbers.
  -- We need to check if the left number can be determined by adding or
  -- multiplying any combination of the right numbers (but they can only be used
  -- once).
  -- 
  -- The result is the sum of the left numbers which can be determined.

  local sum = 0

  for line in input:lines() do
    local Ns = string_utils.gmatch_t(line, "%d+")
    for i, v in ipairs(Ns) do
      Ns[i] = tonumber(v) ---@diagnostic disable-line
    end
    local n = table.remove(Ns, 1)

    if can_determine(n, Ns) then
      sum = sum + n
    end
  end

  output:write(sum)
end

return run