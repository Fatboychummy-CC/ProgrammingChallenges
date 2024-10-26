--- Programming Challenge Aide Script
--- 
--- This script is designed to help with programming challenges across multiple
--- websites. It allows you to quickly download and run challenges and tests
--- from the ComputerCraft shell. It also centralizes the library import
--- process, providing a central location that all ran challenges can `require`
--- from.
--- 
--- Currently supported websites are:
--- - None lol
--- 
--- Planned support for:
--- - Advent of Code
--- - Kattis
--- - LeetCode

package.path = package.path .. ";libs/?.lua;libs/?/init.lua"
local file_helper = require "file_helper"
local completion = require "cc.completion"
local errors = require "errors"

local CHALLENGES_ROOT = "challenges"
local SITES_ROOT = "challenge_sites"
local CREDENTIAL_STORE_ROOT = ".credential_store"

---@type table<string, ChallengeSite>
local sites = {}

--- Register a challenge site, doing a few checks to ensure it's valid.
---@param _path string The path to the challenge site file.
local function register_site(_path)
  local path = _path
  if fs.isDir(path) then
    path = fs.combine(path, "init.lua")
  end

  local handle, err = fs.open(path, "r")
  if not handle then
    error(errors.InternalError(
      ("Failed to open challenge site file '%s': %s"):format(path, err)
    ))
  end

  local content = handle.readAll()
  handle.close()

  if not content then
    error(errors.InternalError(
      ("Failed to read challenge site file '%s'"):format(path),
      "File is empty, or some other issue occurred while reading."
    ))
  end

  local site_func, load_err = load(content, "=" .. path, "t", _ENV)
  if not site_func then
    error(errors.InternalError(
      ("Failed to load challenge site file '%s': %s"):format(path, load_err),
      "Compile error occurred while loading the file."
    ))
  end

  local success, _site = pcall(site_func)
  if not success then
    error(errors.InternalError(
      ("Failed to load challenge site file '%s': %s"):format(path, _site),
      "Runtime error occurred while loading the file."
    ))
  end

  if type(_site) ~= "table" then
    error(errors.InternalError(
      ("Invalid challenge site file '%s': Expected table, got %s"):format(path, type(_site)),
      "The file must return a table."
    ))
  end

  -- Ensure the main fields are present.
  local function check_invalid_site(t, field_name, expected_type)
    if type(t[field_name]) ~= expected_type then
      error(errors.InternalError(
        ("Invalid challenge site file '%s': Expected field '%s' to be of type %s, got %s"):format(path, field_name, expected_type, type(t[field_name])),
        "The file is returning a table with a required field that is missing or of the wrong type."
      ))
    end
  end

  check_invalid_site(_site, "name", "string")
  check_invalid_site(_site, "website", "string")
  check_invalid_site(_site, "description", "string")
  check_invalid_site(_site, "folder_depth", "number")

  sites[_site.name] = _site
end

--- Load all challenge sites from the `challenge_sites` directory.
local function register_challenge_sites()

  local challenge_sites = file_helper:instanced(SITES_ROOT)

  for _, path in ipairs(challenge_sites:list()) do
    register_site(fs.combine(challenge_sites.working_directory, path))
  end
end

--- Display the help message.
---@param site string? The site to display help for.
---@param no_name boolean? Whether to display the name of the program.
local function display_help(site, no_name)
  local program_name = fs.getName(shell.getRunningProgram())

  if site then
    local site_obj = sites[site]
    if not site_obj then
      error(errors.UserError(
        ("Unknown challenge site '%s'"):format(site),
        "Provide a valid challenge site name."
      ))
    end

    print(site_obj.description)
    site_obj.help(no_name and "" or program_name)
    return
  end

  local function p(str)
    print(str:format(program_name))
  end

  p("Usage: %s <site|command> <subcommand> [args...]")
  p("  %s list")
  p("    Lists all available challenge sites.")
  p("  %s help")
  p("    Displays this help message.")
  p("  %s help <site>")
  p("    Displays a help message for a specific challenge site.")
  p("  %s <site> get [args...]")
  p("    Retrieves a challenge from a challenge site.")
  p("  %s <site> update [args...]")
  p("    Updates a challenge from a challenge site.")
  p("  %s <site> submit [args...]")
  p("    Submits a challenge to a challenge site.")
  p("  %s interactive <site>")
  p("    Enters an interactive shell for a challenge site.")
  p("    This just makes it so you don't have to type the site name every time.")
end

--- List all available challenge sites.
local function list_sites()
  for name, site in pairs(sites) do
    print(("%s - %s"):format(name, site.website))
  end
end

--- Concatenate directories together, expecting a specific amount of directories.
---@param n integer The number of directories to expect.
---@param ... string The directories to concatenate.
---@return string concatted The concatenated directories.
local function concat_dirs(n, ...)
  local dirs = table.pack(...)
  if dirs.n < n then
    -- This is a user error, so we will use level 0.
    error(errors.UserError(
      ("Expected %d more argument(s)."):format(n - dirs.n),
      ("Expected %d argument(s), got %d."):format(n, dirs.n)
    ), 0)
  elseif dirs.n > n then
    -- This is a user error, so we will use level 0.
    error(errors.UserError(
      ("Expected %d less argument(s)."):format(dirs.n - n),
      ("Expected %d argument(s), got %d."):format(n, dirs.n)
    ), 0)
  end

  return fs.combine(table.unpack(dirs, 1, dirs.n))
end

--- Get the directory for a challenge from a challenge site and user arguments.
---@param site ChallengeSite The challenge site to get the challenge from.
---@param ... string The arguments passed to the challenge site.
---@return file_helper directory The directory instance for the challenge.
local function get_challenge_dir(site, ...)
  -- First, we need to get the path to the challenge.
  local dirs = concat_dirs(site.folder_depth, ...)

  -- This folder will be the root of the challenge.
  local cache_path = fs.combine(CHALLENGES_ROOT, site.name, dirs)

  return file_helper:instanced(cache_path)
end

--- Get a challenge from a challenge site.
---@param internal boolean If true, this command was invoked by another command (i.e: was internally called), and will not try to update the challenge if it doesn't exist.
---@param update boolean If true, this command was invoked with the `update` command, and we will fetch the challenge no matter what. We can still fetch the challenge if this is false, but only if the challenge doesn't exist.
---@param site ChallengeSite The challenge site to get the challenge from.
---@param ... string The arguments passed to the challenge site.
local function get(internal, update, site, ...)
  local site_dir = get_challenge_dir(site, ...)
  if not update and site_dir:exists() then
    -- The challenge already exists, so lets just check for the cache file.
    ---@type Challenge
    local challenge = {
      site = site,
      name = site_dir:get_all("name.txt", "Unknown"),
      description = site_dir:get_all("description.md", "No description available."),
      test_inputs = {},
      test_outputs = {},
      input = ""
    }

    -- Read each test input from the files.
    for i = 1, math.huge do
      local file = "tests/inputs/" .. i .. ".txt"
      if not site_dir:exists(file) then
        break
      end

      table.insert(challenge.test_inputs, site_dir:get_all(file))
    end

    -- Read each test output from the files.
    for i = 1, math.huge do
      local file = "tests/outputs/" .. i .. ".txt"
      if not site_dir:exists(file) then
        break
      end

      table.insert(challenge.test_outputs, site_dir:get_all(file))
    end

    -- Read the challenge input from the file.
    local ok = site_dir:exists("input.txt")
    if ok then
      challenge.input = site_dir:get_all("input.txt")

      return challenge
    end

    -- The challenge input file is missing, so we need to fetch the challenge.
    -- If we are directly calling `get`, we can do this fine. Otherwise, throw
    -- an error, as the user may not want to re-fetch the challenge.
    if internal then
      error(errors.InternalError(
        "Challenge input file is missing.",
        "Try updating the challenge."
      ))
    end
  end

  -- The challenge doesn't exist, so we need to fetch it.
  if internal then
    return
  end

  ---@type EmptyChallenge
  local empty_challenge = {
    site = site
  }
  site.get_challenge(empty_challenge, ...)

  -- Now we need to create the directories and files.
  site_dir:make_dir()
  site_dir:make_dir("tests")
  site_dir:make_dir("tests/inputs")
  site_dir:make_dir("tests/outputs")

  -- For each test input, we will write it to the file.
  for i, input in ipairs(empty_challenge.test_inputs) do
    site_dir:write("tests/inputs/" .. i .. ".txt", input)
  end

  -- For each test output, we will write it to the file.
  for i, output in ipairs(empty_challenge.test_outputs) do
    site_dir:write("tests/outputs/" .. i .. ".txt", output)
  end

  -- Write the challenge data to the files.
  site_dir:write("name.txt", empty_challenge.name)
  site_dir:write("description.md", empty_challenge.description)
  site_dir:write("input.txt", empty_challenge.input)
end

--- Run a challenge from a challenge site.
local function run(site, ...)
  local site_dir = get_challenge_dir(site, ...)
end

--- Submit a challenge to a challenge site.
local function submit(site, ...)
  local site_dir = get_challenge_dir(site, ...)
end

--- Credential Store : Remove an entry
---@param site string The site to remove the credentials for.
local function remove_credentials(site)
  
end

--- Credential Store : Handle a command.
---@param site string The site to alter the credentials for.
---@param ... string The arguments passed to the command.
local function cred_store(site, ...)
  local args = table.pack(...)
  local sub_command = table.remove(args, 1)
  if not sub_command then
    error(errors.UserError(
      "No subcommand provided.",
      "Provide a subcommand."
    ))
  end
  sub_command = sub_command:lower()

  if site == "cred-store" then -- Global cred-store commands
    local credential_store = file_helper:instanced(CREDENTIAL_STORE_ROOT)
    if sub_command == "disable" then
      term.setTextColor(colors.orange)
      print("Warning: Disabling the credential store will remove all stored credentials.")
      term.setTextColor(colors.red)
      write("Are you sure you want to disable the credential store? (y/n): ")
      term.setTextColor(colors.white)
      local _, key
      repeat
        _, key = os.pullEvent("key")
      until key == keys.y or key == keys.n
      os.pullEvent("char") -- consume the char event this is also generated.
      print(key == keys.y and "Yes" or "No")

      for _, file in ipairs(credential_store:list()) do
        credential_store:delete(file)
      end
      credential_store:empty(".disabled")

      print("All credentials removed, credential store disabled.")
    elseif sub_command == "enable" then
      credential_store:delete(".disabled")
      print("Credential store enabled.")
    else
      error(errors.UserError(
        ("Unknown subcommand '%s'"):format(sub_command),
        "Provide a valid subcommand."
      ))
    end
    return
  end

  if sub_command == "remove" then
    remove_credentials(site)
  else
    error(errors.UserError(
      ("Unknown subcommand '%s'"):format(sub_command),
      "Provide a valid subcommand."
    ))
  end
end

--- Process a command.
---@type fun(args: table)
---@param args table The arguments passed to the script.
local function process_command(args) end -- Forward declaration

--- Enter an interactive shell for a challenge site.
local function interactive(site)
  local site_obj = sites[site]
  if not site_obj then
    error(errors.UserError(
      ("Unknown challenge site '%s'"):format(site),
      "Provide a valid challenge site name."
    ))
  end

  local command_history = {}

  while true do
    term.setTextColor(colors.lightBlue)
    write("challenges : " .. site_obj.name)
    term.setTextColor(colors.white)
    term.write(" > ")
    local line = read(
      nil,
      command_history,
      function(text)
        if #text == 0 then
          return {}
        end

        local allowed_commands = {
          "get",
          "run",
          "update",
          "submit",
          "help",
          "cred-store",
          "exit"
        }

        -- Check if the first word in the text is one of the commands.
        local first_word = text:match("%S+")
        local second_word = text:match("%S+%s+(%S+)")

        -- If there is no command yet, return the list of allowed commands.
        if not first_word then
          return completion.choice(text, allowed_commands) --[[@as string[] ]]
        end

        -- Special case for cred-store:
        if first_word == "cred-store" then
          return completion.choice(text, {
            "cred-store remove"
          }) --[[@as string[] ]]
        end

        -- If there is a second word, we delegate to the site's completion function.
        if second_word then
          if site_obj.completion then
            return site_obj.completion(text)
          else
            return {}
          end
        end

        -- Otherwise, we return the list of allowed commands (we have a partial command).
        return completion.choice(text, allowed_commands) --[[@as string[] ]]
      end
    ) --[[@as string]]
    table.insert(command_history, line)

    -- Exit if the user types "exit".
    if line == "exit" then
      break
    end

    -- Split the line into words
    local parts = {}
    for part in line:gmatch("%S+") do
      table.insert(parts, {part, false})
    end

    -- Check for quotes. We only need this in the interactive shell, as the main
    -- shell takes care of this for us otherwise.
    ---@type string?
    local quote
    for i, part in ipairs(parts) do
      local str = part[1]
      local char_1 = str:sub(1, 1)
      local len = #str
      local char_n = str:sub(len, len)

      if not quote and (char_1 == "'" or char_1 == '"') then
        -- Handle the first character being a quote
        quote = char_1
        part[1] = str:sub(2, len - 1)
        part[2] = true

        -- If the last character is also the quote, then we're done.
        if char_n == quote then
          quote = nil
          part[1] = str:sub(2, len - 2)
        end
      elseif quote and char_n == quote then
        -- Handle the last character being the quote we're looking for.
        quote = nil
        part[1] = parts[1] .. str:sub(1, len - 1)

        -- Now we search backwards for the start of the quote.
        for j = i, 1, -1 do
          local r_part = table.remove(parts, j)
          local l_part = parts[j - 1]
          l_part[1] = l_part[1] .. " " .. r_part[1]

          if l_part[2] then
            l_part[2] = false
            break
          end
        end
      end
    end
    -- well that got complicated, maybe I'll come back and simplify it later.

    if quote then
      error(errors.UserError("Unmatched quote in command."))
    end

    -- Now we can process the command.
    local command = {site}
    for _, part in ipairs(parts) do
      table.insert(command, part[1])
    end

    local ok, err = pcall(process_command, command)

    if not ok then
      if type(err) == "table" then
        -- It's an error object, print it.
        printError(err)

        -- If it's a user error, continue the loop.
        if err.type ~= "UserError" then
          break
        end
      else
        -- Something else happened, elevate the error.
        error(err, 0)
      end
    end
  end
end

--- Process a command.
---@type fun(args: table)
---@param args table The arguments passed to the script.
process_command = function(args)
  if #args == 0 then
    display_help()
    return
  end

  local command = table.remove(args, 1):lower()

  if command == "test" then
    local ok, user, pass = require "authentication_utils".get_user_pass("test")
    term.setTextColor(colors.orange)
    print("username:", user)
    print("password:", pass)
    term.setTextColor(colors.white)
  elseif command == "list" then
    list_sites()
  elseif command == "help" then
    display_help(table.unpack(args))
  elseif command == "cred-store" then
    cred_store(command, table.unpack(args))
  elseif command == "interactive" then
    interactive(table.unpack(args))
  else
    local site = sites[command]
    if not site then
      error(errors.UserError(
        ("Unknown challenge site '%s'"):format(command),
        "Provide a valid challenge site name."
      ))
    end

    local sub_command = table.remove(args, 1)
    if sub_command == "get" then
      get(false, false, site, table.unpack(args))
    elseif sub_command == "run" then
      run(site, table.unpack(args))
    elseif sub_command == "update" then
      get(false, true, site, table.unpack(args))
    elseif sub_command == "submit" then
      submit(site, table.unpack(args))
    elseif sub_command == "help" then
      display_help(command, true)
    else
      printError(errors.UserError(
        ("Unknown command '%s'"):format(sub_command),
        "Provide a valid command."
      ))
    end
  end
end

register_challenge_sites()

--- Main entry point for the script.
process_command { ... }