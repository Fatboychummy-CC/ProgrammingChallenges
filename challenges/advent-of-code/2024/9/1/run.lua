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

---@alias aoc.2024.9.1.DiskMap (integer|false)[]

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
  -- Sum up the "checksum" (sum of all file IDs * the block they appear in)

  -- Read in the disk map.

  ---@type aoc.2024.9.1.DiskMap
  local disk_map = {}
  local i = 0
  local file_index = 0
  local file = true
  for char in input:readAll():gmatch(".") do
    local length = tonumber(char) --[[@as integer]]

    if file then
      for _ = 1, length do
        disk_map[i] = file_index
        i = i + 1
      end

      file_index = file_index + 1
    else
      for _ = 1, length do
        disk_map[i] = false
        i = i + 1
      end
    end

    file = not file
  end

  -- Debug write the disk map
  --write_disk_map(disk_map)

  -- Collapse the disk map and sum up the checksum.
  local sum = 0
  local right_cursor = #disk_map + 1
  local left_cursor = 0

  while left_cursor <= right_cursor do
    if disk_map[left_cursor] then
      sum = sum + disk_map[left_cursor] * left_cursor
      --write(tostring(disk_map[left_cursor]))
    else
      -- Find the next file from the right.
      while not disk_map[right_cursor] do
        right_cursor = right_cursor - 1
      end

      if left_cursor > right_cursor then
        -- Right cursor has overrun the left cursor.
        break
      end
      -- This file would be moved to the left, but we can just sum it immediately.
      sum = sum + disk_map[right_cursor] * left_cursor
      --write(tostring(disk_map[right_cursor]))
      right_cursor = right_cursor - 1
    end

    left_cursor = left_cursor + 1
  end
  --print()

  output:write(sum)
end

return run