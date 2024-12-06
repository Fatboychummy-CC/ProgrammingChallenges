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

local linked_grid = require "linked_grid"

---@class aoc.2024.6.1.guard_grid : linked_grid
---@field grid aoc.2024.6.1.guard_grid_object[][]

---@class aoc.2024.6.1.guard_grid_object : linked_grid_object
---@field value aoc.2024.6.1.MapPoint

---@class aoc.2024.6.1.MapPoint
---@field obstructed boolean True if the point is obstructed.
---@field counted boolean True if the point has been counted.
---@field guard_facing string? The direction the guard is facing, if the guard is currently here.


local right_turns = {
  up = "right",
  right = "down",
  down = "left",
  left = "up"
}

--- Tick the guard a single step.
---@param grid aoc.2024.6.1.guard_grid The grid.
---@param guard_point aoc.2024.6.1.guard_grid_object The guard's position.
---@return aoc.2024.6.1.guard_grid_object? new_pos The next position the guard will be at.
local function tick_guard(grid, guard_point)
  ---@type aoc.2024.6.1.guard_grid_object?
  local next_position

  repeat
    next_position = guard_point[guard_point.value.guard_facing]

    if not next_position then
      return nil -- Guard has left the map.
    end

    if next_position.value.obstructed then
      guard_point.value.guard_facing = right_turns[guard_point.value.guard_facing]
    end
  until next_position and not next_position.value.obstructed

  -- Copy over the direction the guard is facing.
  next_position.value.guard_facing = guard_point.value.guard_facing

  -- And clear it from the current position.
  guard_point.value.guard_facing = nil

  return next_position
end

--- Run the guard until he cannot run anymore.
---@param grid aoc.2024.6.1.guard_grid The grid.
---@param guard_point aoc.2024.6.1.guard_grid_object The guard's position.
---@return integer distinct_locations The number of distinct locations the guard visited.
local function run_guard(grid, guard_point)
  -- Repeatedly attempt to move the guard in the direction he wants to move,
  -- until successful.

  local distinct_locations = 0

  ---@type aoc.2024.6.1.guard_grid_object?
  local current_point = guard_point

  while current_point do
    if not current_point.value.counted then
      distinct_locations = distinct_locations + 1
      current_point.value.counted = true
    end

    current_point = tick_guard(grid, current_point)
  end

  return distinct_locations
end


--- Run the challenge.
---@param input MockReadHandle The input handle.
---@param output MockWriteHandle The output handle.
local function run(input, output)
  -- Guard is denoted by an `^` character in the input.
  -- Guard moves forward until he cannot anymore.
  -- Guard turns right, always, when against an obstruction (`#`).
  -- If the guard *leaves* the map, he done.
  -- Count the number of distinct locations he visits before leaving the map.

  local grid = linked_grid() --[[@as aoc.2024.6.1.guard_grid]]
  local guard_pos = { x = 1, y = 1 }

  -- Read in the grid.
  local y = 1
  for line in input:lines() do
    local x = 1
    for char in line:gmatch(".") do
      grid:Insert(y, x, {
        obstructed = char == "#",
        counted = false,
        guard_facing = char == "^" and "up" or nil -- Guard starts facing up
      })

      if char == "^" then
        guard_pos.x = x
        guard_pos.y = y
        print("Found the guard's starting position at (", x, ",", y, ")")
      end

      x = x + 1
    end
    y = y + 1
  end

  grid:Link()

  -- THE JOURNEY BEGINS
  output:write(
    run_guard(
      grid,
      grid:Get(guard_pos.y, guard_pos.x) --[[@as aoc.2024.6.1.guard_grid_object]]
    )
  )
end

return run