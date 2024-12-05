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

---@class aoc.2024.5.1.RuleMap
---@field before_map table<integer, true> A map of numbers that must come before the key.
---@field after_map table<integer, true> A map of numbers that must come after the key.

---@class aoc.2024.5.1.Update
---@field list integer[] A list of numbers in the update.
---@field map table<integer, integer> A map of numbers in the update, to their position in the update.


--- Check if an update is valid based on the rules.
---@param update aoc.2024.5.1.Update The update to check.
---@param rule_maps table<integer, aoc.2024.5.1.RuleMap> The rules to check against.
---@return boolean valid True if the update is valid, false otherwise.
local function check_update(update, rule_maps)
  for i, n1 in ipairs(update.list) do
    if rule_maps[n1] then
      -- Check that numbers that should come after are actually after this entry.
      for j = 1, i - 1 do
        local n2 = update.list[j]
        if rule_maps[n1].after_map[n2] then
          return false
        end
      end

      -- Check that numbers that should come before are actually before this entry.
      for j = i + 1, #update.list do
        local n2 = update.list[j]
        if rule_maps[n1].before_map[n2] then
          return false
        end
      end
    end
  end

  -- If we made it here, we checked all rules of each value and they all passed.
  return true
end


--- Run the challenge.
---@param input MockReadHandle The input handle.
---@param output MockWriteHandle The output handle.
local function run(input, output)
  -- Input is a list of rules in the format of `n1|n2`, which means `n1 must come before n2` (if n1 or n2 are present).
  -- After that, is a list of "updates", which are numbers separated by commas.
  -- Goal is to check which "updates" are valid based on the rules.
  -- An empty line separates the rules from the updates.
  -- Sum up the middle page number of all valid updates.


  -- Read the rules and updates
  local rule_maps = {} ---@type table<integer, aoc.2024.5.1.RuleMap>
  local updates = {} ---@type aoc.2024.5.1.Update[]
  local reading_rules = true
  for line in input:lines() do
    if line == "" then
      reading_rules = false
    elseif reading_rules then
      local n1, n2 = line:match("(%d+)|(%d+)")
      n1, n2 = tonumber(n1) --[[@as integer]], tonumber(n2) --[[@as integer]]

      if rule_maps[n1] then
        rule_maps[n1].after_map[n2] = true
      else
        rule_maps[n1] = {before_map = {}, after_map = {[n2] = true}}
      end

      if rule_maps[n2] then
        rule_maps[n2].before_map[n1] = true
      else
        rule_maps[n2] = {before_map = {[n1] = true}, after_map = {}}
      end
    else
      local update = {list = {}, map = {}}
      local i = 0
      for n in line:gmatch("%d+") do
        i = i + 1
        update.list[i] = tonumber(n)
        update.map[tonumber(n)] = i
      end
      table.insert(updates, update)
    end
  end

  -- Check each update for rule breaks.
  local sum = 0
  for _, update in ipairs(updates) do
    if check_update(update, rule_maps) then
      -- Assumption: All updates have an odd number of pages.
      --print("Valid update:", table.concat(update.list, ", "))
      --print("Selected middle:", update.list[math.ceil(#update.list / 2)])
      sum = sum + update.list[math.ceil(#update.list / 2)]
    end
  end

  output:write(sum)
end

return run