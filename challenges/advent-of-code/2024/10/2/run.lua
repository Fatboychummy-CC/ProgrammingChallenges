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

local lg = require "linked_grid"

------ @class aoc.2024.10.1.Grid : linked_grid
------ @field grid aoc.2024.10.1.GridObject[][]

------ @class aoc.2024.10.1.GridObject : linked_grid_object
------ @field value aoc.2024.10.1.TrailPoint
------ @field cardinal_connections aoc.2024.10.1.GridObject[]

------ @class aoc.2024.10.1.TrailPoint
------ @field height integer The height of the point.
------ @field counted boolean True if the point is a 9 that has been counted already.

--- Check how many 9's can be reached from a given grid position.
--- Depth-first search.
---@param grid_obj aoc.2024.10.1.GridObject The position to check from.
---@return integer n_reachable The number of 9's that can be reached.
local function check_reachable(grid_obj)
  local n_reachable = 0

  local current_height = grid_obj.value.height

  -- Check the four sides.
  for _, side in ipairs(grid_obj.cardinal_connections) do
    local next_point = side.value
    local next_height = next_point.height

    if current_height == 8 and next_height == 9 then
      --if not next_point.counted then
        --next_point.counted = true
        n_reachable = n_reachable + 1
      --end
    elseif current_height == next_height - 1 then
      n_reachable = n_reachable + check_reachable(side)
    end
  end

  return n_reachable
end

--- Reset all `counted` values in the grid.
---@param grid aoc.2024.10.1.Grid The grid to reset.
local function reset_counted(grid)
  for _, _, grid_obj in grid:Iterate() do
    grid_obj.value.counted = false
  end
end


--- Run the challenge.
---@param input MockReadHandle The input handle.
---@param output MockWriteHandle The output handle.
local function run(input, output)
  -- Input is a grid of numbers, from 0-9. Each number represents a height.
  -- 0 is an entrance, and the goal is to count how many 9's we can reach, given
  -- that we can only ever increment by 1.
  --
  -- Part 1: Sum up each 9 we can reach from every 0.
  --
  -- Part 2: A trail's "rating" is now how many *distinct ways* you can take to
  --         get to a 9. Find the sum of all ratings.

  local grid = lg() --[[@as aoc.2024.10.1.Grid]]

  -- Read in the grid.
  local y = 0
  for line in input:lines() do
    local x = 0
    y = y + 1
    for char in line:gmatch(".") do
      x = x + 1
      grid:Insert(y, x, {
        height = tonumber(char),
        counted = false
      })
      --write(char)
    end
    --print()
  end

  -- Connect the grid.
  grid:Link()

  -- Find all 0's and check how many 9's they can reach.
  local sum = 0

  for _, _, grid_obj in grid:Iterate() do
    if grid_obj.value.height == 0 then
      reset_counted(grid)
      sum = sum + check_reachable(grid_obj)
    end
  end

  output:write(sum)
end

return run