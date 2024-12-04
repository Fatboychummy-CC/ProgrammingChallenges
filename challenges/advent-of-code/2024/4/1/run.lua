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

local linked_grid = require("linked_grid")

---@alias direction "up" | "down" | "left" | "right" | "up_left" | "up_right" | "down_left" | "down_right"

--- Check if the word "XMAS" is present at the current position in the grid.
---@param grid_obj linked_grid_object The grid object to check.
---@param direction direction The direction to check.
---@param last_char string? The last character checked. Nil if this is the first character. This decides which character we're looking for at the current position.
---@return boolean xmas_found Whether the word "XMAS" is present at the current position.
local function check_xmas(grid_obj, direction, last_char)
  -- If the grid object doesn't exist, we're out of bounds (no xmas).
  if not grid_obj then
    return false
  end

  -- If the last character was "X", we're looking for "M".
  -- If the last character was "M", we're looking for "A".
  -- If the last character was "A", we're looking for "S". If it is an S, we're done.
  local ok = false
  if last_char == "X" then
    ok = grid_obj.value == "M"
  elseif last_char == "M" then
    ok = grid_obj.value == "A"
  elseif last_char == "A" then
    return grid_obj.value == "S"
  end

  -- If the character is incorrect, we stop.
  if not ok then
    return false
  end

  -- If the character is correct, we continue in the same direction.
  return check_xmas(
    grid_obj[direction],
    direction,
    grid_obj.value
  )
end

--- Run the challenge.
---@param input MockReadHandle The input handle.
---@param output MockWriteHandle The output handle.
local function run(input, output)
  -- Input is a "word search", we are looking for all instances of "XMAS" in the grid.
  -- We can go in all 8 directions to find the word.

  -- Stage 1: Read the grid from the input.
  local grid = linked_grid()
  local y = 0
  for line in input:lines() do
    y = y + 1
    local x = 0
    for char in line:gmatch(".") do
      x = x + 1
      --print(x, char)
      grid:Insert(y, x, char)
    end
  end

  -- Stage 2: Link the grid.
  grid:Link()

  -- Stage 3: Check for "XMAS" in all directions.
  local xmas_count = 0

  for y = grid.nh, grid.h do
    for x = grid.nw, grid.w do
      local grid_obj = grid:Get(y, x)

      if grid_obj and grid_obj.value == "X" then
        -- Check all 8 directions.
        for direction, linked_obj in pairs(grid_obj.named_connections) do
          if check_xmas(linked_obj, direction, "X") then
            xmas_count = xmas_count + 1
          end
        end
      end
    end
  end

  output:write(xmas_count)
end

return run