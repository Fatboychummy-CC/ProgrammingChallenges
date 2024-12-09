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

------ @alias aoc.2024.9.1.DiskMap (integer|false)[]
---@class aoc.2024.9.1.FilePos
---@field length integer The length of the file.
---@field start integer The starting position of the file. 

--- Print out a disk map.
---@param map aoc.2024.9.1.DiskMap The disk map to print.
local function write_disk_map(map)
  for i = 0, #map do
    if map[i] then
      write(tostring(map[i]))
    else
      write(".")
    end
  end

  print()
end

--- Run the challenge.
---@param input MockReadHandle The input handle.
---@param output MockWriteHandle The output handle.
local function run(input, output)
  -- Input: A "disk map" of numbers. Each digit alternates between length of a
  -- file, and length of free space. `12345` -> 1 file, 2 free, 3 file, 4 free,
  -- 5 file.
  -- Each file has ID based on how they appear in the input, starting from `0`.
  --
  -- Part 1: "collapse" the disk map (from back to front) so no holes appear.
  --         Sum up the "checksum" (sum of all file IDs * the block they appear
  --         in)
  --
  -- Part 2: We now only move files if the entire file fits somewhere.
  --         Only attempt to move each file ONCE.

  -- Read in the disk map.

  ---@type aoc.2024.9.1.DiskMap
  local disk_map = {}
  local i = 0
  local file_index = 0
  local file_index_pos = {} ---@type aoc.2024.9.1.FilePos[]
  local gaps = {} ---@type aoc.2024.9.1.FilePos[]
  local file = true
  for char in input:readAll():gmatch(".") do
    local length = tonumber(char) --[[@as integer]]

    if file then
      file_index_pos[file_index] = {
        length = length,
        start = i
      }

      for _ = 1, length do
        disk_map[i] = file_index
        i = i + 1
      end

      file_index = file_index + 1
    else
      table.insert(gaps, {
        length = length,
        start = i
      })

      for _ = 1, length do
        disk_map[i] = false
        i = i + 1
      end
    end

    file = not file
  end

  -- Debug write the disk map
  --write_disk_map(disk_map)

  -- Collapse the disk map.
  local _, y = term.getCursorPos()
  local len = #file_index_pos
  for right_cursor = len, 0, -1 do
    local file_pos = file_index_pos[right_cursor]

    -- Check if the file can fit in any of the gaps.
    for j, gap in ipairs(gaps) do
      if file_pos.start < gap.start then
        -- The file is to the left of the gap.
        break
      end

      if gap.length >= file_pos.length then
        -- Move the file to the gap.
        for offset = 0, file_pos.length - 1 do
          disk_map[gap.start + offset] = disk_map[file_pos.start + offset]
          disk_map[file_pos.start + offset] = false
        end

        -- Update the gap.
        gap.length = gap.length - file_pos.length
        gap.start = gap.start + file_pos.length

        -- Move the file_pos to gap.
        table.insert(gaps, {
          length = file_pos.length,
          start = file_pos.start
        })

        if gap.length <= 0 then
          -- Remove the gap.
          table.remove(gaps, j)
        end

        break
      end
    end

    os.queueEvent("doot")
    os.pullEvent("doot")
    term.setCursorPos(1, y)
    term.clearLine()
    term.write("Progress: " .. math.floor((1 - (right_cursor / len)) * 100) .. "%")
  end
  print()

  --write_disk_map(disk_map)

  -- Sum up the checksum.
  local sum = 0

  for pos = 0, #disk_map do
    if disk_map[pos] then
      sum = sum + disk_map[pos] * pos
    end
  end

  output:write(sum)
end

return run