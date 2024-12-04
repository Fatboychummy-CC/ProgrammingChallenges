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

----- @alias direction "up" | "down" | "left" | "right" | "up_left" | "up_right" | "down_left" | "down_right"

--- Check if the X-"MAS" is present at the current position in the grid.
---@param grid_obj linked_grid_object The grid object to check.
---@return boolean x_mas_found Whether the "MAS" cross is present at the current position.
local function check_x_mas(grid_obj)
  local mas_count = 0

  -- check up-left to down-right
  if grid_obj.up_left and grid_obj.down_right then
    if grid_obj.up_left.value == "M" and grid_obj.down_right.value == "S" 
    or grid_obj.up_left.value == "S" and grid_obj.down_right.value == "M" then
      mas_count = mas_count + 1
    end
  end

  -- check down-left to up-right
  if grid_obj.down_left and grid_obj.up_right then
    if grid_obj.down_left.value == "M" and grid_obj.up_right.value == "S" 
    or grid_obj.down_left.value == "S" and grid_obj.up_right.value == "M" then
      mas_count = mas_count + 1
    end
  end

  return mas_count == 2
end

--- Run the challenge.
---@param input MockReadHandle The input handle.
---@param output MockWriteHandle The output handle.
local function run(input, output)
  -- Input is a "word search", we are looking for all instances of "XMAS" in the grid.
  -- We can go in all 8 directions to find the word.

  -- Part 2: Instead of looking for "XMAS", we are looking for "MAS", but so that it makes an "X" shape, i.e:
  -- M S
  --  A
  -- M S

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

  -- Stage 3: Check for "X-MAS" in all directions.
  local xmas_count = 0

  for y = grid.nh, grid.h do
    for x = grid.nw, grid.w do
      local grid_obj = grid:Get(y, x)

      if grid_obj and grid_obj.value == "A" then
        if check_x_mas(grid_obj) then
          xmas_count = xmas_count + 1
        end
      end
    end
  end

  output:write(xmas_count)
end

return run