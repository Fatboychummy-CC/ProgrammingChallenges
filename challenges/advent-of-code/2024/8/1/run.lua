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

local lg = require "linked_grid" -- We don't actually need the links, but the grid is useful.
local table_utils = require "table_utils" -- table_utils.combinations - size 2

---@class aoc.2024.8.1.character_position
---@field y integer The Y position of the character.
---@field x integer The X position of the character.

--- Run the challenge.
---@param input MockReadHandle The input handle.
---@param output MockWriteHandle The output handle.
local function run(input, output)
  -- Input is a grid of characters. Any character that is not a `.` is a
  -- "transmitter". Transmitters make "antinodes" when two transmitters are on
  -- the same frequency (character same). Antinodes are placed, quoting AoC:
  --
  -- > In particular, an antinode occurs at any point that is perfectly in line
  -- > with two antennas of the same frequency - but only when one of the
  -- > antennas is twice as far away as the other. This means that for any pair
  -- > of antennas with the same frequency, there are two antinodes, one on
  -- > either side of them.
  -- 
  -- Part 1: Determine number of unique antinodes.

  local grid = lg()
  local antinode_grid = lg()
  local char_positions = {} ---@type table<string, aoc.2024.8.1.character_position[]>

  -- Read the grid.
  -- We will cache all unique characters and their positions.
  local y = 0
  for line in input:lines() do
    local x = 0
    y = y + 1
    for char in line:gmatch(".") do
      x = x + 1
      grid:Insert(y, x, char)
      antinode_grid:Insert(y, x, false) -- Initialize all antinode grid nodes to false.

      if char ~= "." then
        if not char_positions[char] then
          char_positions[char] = {}
        end

        table.insert(char_positions[char], { y = y, x = x })
      end
    end
  end

  -- Convert all character positions into a pair of transmitters.
  local char_combinations = {}
  for _, positions in pairs(char_positions) do
    if #positions > 1 then
      for _, pair in ipairs(table_utils.combinations(positions, 2)) do
        table.insert(char_combinations, pair)
      end
    end
  end

  -- For each pair, calculate the two antinodes.
  for _, pair in ipairs(char_combinations) do
    local p1, p2 = pair[1], pair[2]

    -- Determine which point is the bottom-most point.
    if p1.y > p2.y then
      p1, p2 = p2, p1
    end -- Now p1 is lower on the y value (or equal), this will help us
        -- determine the antinode positions.

    -- Calculate the distance between the two points.
    local dy = math.abs(p2.y - p1.y)
    local dx = math.abs(p2.x - p1.x)

    -- Calculate the antinodes.
    local antinode1, antinode2
    if p1.x > p2.x then -- p1 is down-left of p2
      -- print("Down-left")
      antinode1 = { y = p1.y - dy, x = p1.x + dx }
      antinode2 = { y = p2.y + dy, x = p2.x - dx }
    else -- p1 is down-right of p2
      -- print("Down-right")
      antinode1 = { y = p1.y - dy, x = p1.x - dx }
      antinode2 = { y = p2.y + dy, x = p2.x + dx }
    end

    -- Mark the antinodes on the antinode grid.
    antinode_grid:Insert(antinode1.y, antinode1.x, true)
    antinode_grid:Insert(antinode2.y, antinode2.x, true)
  end

  -- Final step: count the number of antinodes.
  local antinode_count = 0
  for y = 1, grid.h do
    local ylist = antinode_grid.grid[y]

    if ylist then
      for x = 1, grid.w do
        local node = ylist[x]
        if node and node.value then
          antinode_count = antinode_count + 1
          if grid.grid[y] and grid.grid[y][x] and grid.grid[y][x].value ~= "." then
            term.setTextColor(colors.red)
          end
          write("#")
          term.setTextColor(colors.white)
        elseif grid.grid[y] and grid.grid[y][x] then
          write(grid.grid[y][x].value)
        else
          write(".")
        end
      end
    else
      for _ = 1, grid.w do
        write(".")
      end
    end

    print()
  end

  output:write(antinode_count)
end

return run