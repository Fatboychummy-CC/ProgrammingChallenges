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
  -- "safe" : All values are either increasing or decreasing (but not both), difference must be 1-3.
  -- "unsafe" : Values are increasing and decreasing, or difference is above 3 or below 1
  -- Determine how many "reports" (lines) are safe.

  local safe = 0

  for line in input:lines() do
    local values = {}
    for value in line:gmatch("(%d+)") do
      table.insert(values, tonumber(value))
    end

    local safe_report = true
    local incrementing = values[2] > values[1]
    for i = 1, #values - 1 do
      local _incrementing = values[i + 1] > values[i]
      if incrementing ~= _incrementing or math.abs(values[i + 1] - values[i]) > 3 or values[i + 1] == values[i] then
        safe_report = false
        break
      end
    end

    if safe_report then
      safe = safe + 1
    end
  end

  output:write(safe)
end

return run