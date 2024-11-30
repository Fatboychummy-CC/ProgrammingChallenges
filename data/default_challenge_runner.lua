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
  -- Write your main challenge code here
  -- For example, if your challenge was to add two numbers, you would write:
  local a = input:readNumber()
  local b = input:readNumber()

  print(a, "+", b, "=", a + b) -- Printed data is NOT saved

  -- Anything passed to `write` will be first `tostring`ed
  -- This ensures that certain numbers won't be output as 1.0000000000001 and
  -- such.
  output:write(a + b)

  -- You can also use `writef` to format strings

  -- There is no need to close either file handle, this is handled internally.
  -- However, the `:close()` method does exist in case you have a bad case of
  -- old-habits-die-hard.
  output:close()
end

return run