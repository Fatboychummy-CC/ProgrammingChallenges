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

--- Run the challenge.
---@param input MockReadHandle The input handle.
---@param output MockWriteHandle The output handle.
local function run(input, output)
  -- Read every first number into A, and every second number into B
  local A, B = {}, {}

  for line in input:lines() do
    local a, b = line:match("(%d+)%s+(%d+)")
    table.insert(A, tonumber(a))
    table.insert(B, tonumber(b))
  end

  -- Sort the tables so they are both lowest to highest
  table.sort(A)
  table.sort(B)

  -- Calculate the difference between each value, and sum it.
  local sum = 0
  for i = 1, #A do
    sum = sum + math.abs(A[i] - B[i])
  end

  -- Write the sum to the output
  output:write(sum)
end

return run