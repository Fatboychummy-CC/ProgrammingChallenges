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
  -- Find all `mul(x,y)` values. Must be exact!
  -- Multiply them together, then sum every value returned.
  -- 1-3 digits max, nothing in-between.

  -- Part 2: `do()` enables `mul`, `don't()` disables it!

  local sum = 0
  local enabled = true
  local data = input:readAll() --[[@as string]]
  for i = 1, #data do
    if data:find("^do%(%)", i) then
      enabled = true
    elseif data:find("^don't%(%)", i) then
      enabled = false
    elseif data:find("^mul%(%d+,%d+%)", i) then
      local mulA, mulB = data:match("^mul%((%d+),(%d+)%)", i)
      if enabled and #mulA <= 3 and #mulB <= 3 then
        sum = sum + mulA * mulB
      end
    end
  end


  --[[ -- Old code
  for mulA, mulB in input:readAll():gmatch("mul%((%d+),(%d+)%)") do
    if #mulA > 3 or #mulB > 3 then
      -- Do nothing
    else
      sum = sum + mulA * mulB
    end
  end
  ]]

  output:write(sum)
end

return run