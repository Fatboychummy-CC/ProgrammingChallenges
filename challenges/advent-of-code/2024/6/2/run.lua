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

---@class aoc.2024.6.2.guard_grid : linked_grid
---@field grid aoc.2024.6.2.guard_grid_object[][]

---@class aoc.2024.6.2.guard_grid_object : linked_grid_object
---@field value aoc.2024.6.2.MapPoint

---@class aoc.2024.6.2.MapPoint
---@field obstructed boolean True if the point is obstructed.
---@field counted boolean True if the point has been counted.
---@field guard_facing string? The direction the guard is facing, if the guard is currently here.
---@field y integer The Y position of the point.
---@field x integer The X position of the point.
---@field false_obstruction boolean True if the point is a false obstruction.


local right_turns = {
  up = "right",
  right = "down",
  down = "left",
  left = "up"
}

--- Tick the guard a single step.
---@param guard_point aoc.2024.6.2.guard_grid_object The guard's position.
---@return aoc.2024.6.2.guard_grid_object? new_pos The next position the guard will be at.
local function tick_guard(guard_point)
  ---@type aoc.2024.6.2.guard_grid_object?
  local next_position

  repeat
    next_position = guard_point[guard_point.value.guard_facing]

    if not next_position then
      -- Guard has left the map, remove the guard facing.
      guard_point.value.guard_facing = nil
      return nil
    end

    if next_position.value.obstructed or next_position.value.false_obstruction then
      guard_point.value.guard_facing = right_turns[guard_point.value.guard_facing]
    end
  until next_position and not next_position.value.obstructed and not next_position.value.false_obstruction

  -- Copy over the direction the guard is facing.
  next_position.value.guard_facing = guard_point.value.guard_facing

  -- And clear it from the current position.
  guard_point.value.guard_facing = nil

  return next_position
end

--- Run the guard until he cannot run anymore, setting up the grid to count the
--- distinct locations visited.
---@param guard_point aoc.2024.6.2.guard_grid_object The guard's position.
---@return aoc.2024.6.2.guard_grid_object[] distinct_locations The distinct locations the guard visited.
local function run_guard_setup(guard_point)
  -- Repeatedly attempt to move the guard in the direction he wants to move,
  -- until successful.

  local distinct_locations = {}

  ---@type aoc.2024.6.2.guard_grid_object?
  local current_point = guard_point

  local f = false

  while current_point do
    if not current_point.value.counted then
      if f then -- Skip the first location, as it's the guard's starting position.
        table.insert(distinct_locations, current_point)
      else
        f = true
      end
      current_point.value.counted = true
    end

    current_point = tick_guard(current_point)
  end

  return distinct_locations
end

--- Run the guard, checking for loops.
---@param guard_point aoc.2024.6.2.guard_grid_object The guard's position.
---@return boolean has_loop True if the guard has a loop.
local function run_guard_loop(guard_point)
  -- Repeatedly attempt to move the guard in the direction he wants to move,
  -- until successful.

  ---@type table<string, true>
  local move_map = {}

  ---@type aoc.2024.6.2.guard_grid_object?
  local current_point = guard_point

  while current_point do
    local pos = current_point.value.y .. "," .. current_point.value.x .. "," .. current_point.value.guard_facing
    if move_map[pos] then
      return true
    end

    move_map[pos] = true

    current_point = tick_guard(current_point)
  end

  return false -- If we made it here, the guard exited the map without looping.
end

--- Brute-force a good position for the false obstruction.
---@param valid_positions aoc.2024.6.2.guard_grid_object[] The valid positions to place the false obstruction.
---@param guard_point aoc.2024.6.2.guard_grid_object The guard's position.
---@return integer n_locations The number of locations that lead to a loop.
local function brute_force_false_obstruction(valid_positions, guard_point)
  local n_locations = 0

  local len = #valid_positions

  for i, pos in ipairs(valid_positions) do
    os.queueEvent("no_yield_error")
    os.pullEvent("no_yield_error")

    pos.value.false_obstruction = true

    -- Reset the guard's position before each run.
    guard_point.value.guard_facing = "up"

    if run_guard_loop(guard_point) then
      --print("Loop when obstruction at (", pos.value.y, ",", pos.value.x, ")", ": on iteration", i, "of", len)
      n_locations = n_locations + 1
    end

    pos.value.false_obstruction = false
  end

  return n_locations
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

  -- Part 2: Determine where we can place an obstruction such that the guard
  -- gets stuck in a loop.
  -- Output the number of locations that lead to such a loop.

  local grid = linked_grid() --[[@as aoc.2024.6.2.guard_grid]]
  local guard_pos = { x = 1, y = 1 }

  -- Read in the grid.
  local y = 1
  for line in input:lines() do
    local x = 1
    for char in line:gmatch(".") do
      grid:Insert(y, x, {
        obstructed = char == "#",
        counted = false,
        guard_facing = char == "^" and "up" or nil, -- Guard starts facing up
        false_obstruction = false,
        y = y,
        x = x
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
  -- Run the guard through the grid to determine which locations are visited by the guard.
  local valid_positions = run_guard_setup(grid:Get(guard_pos.y, guard_pos.x) --[[@as aoc.2024.6.2.guard_grid_object]])

  -- Now, we need to find a position where we can place a false obstruction that
  -- will cause the guard to loop.
  local n_locations = brute_force_false_obstruction(valid_positions, grid:Get(guard_pos.y, guard_pos.x) --[[@as aoc.2024.6.2.guard_grid_object]])

  output:write(n_locations)
end

return run