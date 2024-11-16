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
local credential_store = require "credential_store"
local filesystem = require "filesystem":programPath()
local completion = require "cc.completion"
local errors = require "errors"
-- local mock_filehandles = require "mock_filehandles"

local CHALLENGES_ROOT = "challenges"
local SITES_ROOT = "challenge_sites"


---@type table<string, ChallengeSite>
local sites = {}

--- Register a challenge site, doing a few checks to ensure it's valid.
---@param file FS_File The file representing the challenge site.
local function register_site(file)
  if file:isDirectory() then
    file = file:file("init.lua")
  end

  local handle, err = file:open("r")
  if not handle then
    error(errors.InternalError(
      ("Failed to open challenge site file '%s': %s"):format(tostring(file), err)
    ))
  end

  local content = handle.readAll()
  handle.close()

  if not content then
    error(errors.InternalError(
      ("Failed to read challenge site file '%s'"):format(tostring(file)),
      "File is empty, or some other issue occurred while reading."
    ))
  end

  local site_func, load_err = load(content, "=" .. tostring(file), "t", _ENV)
  if not site_func then
    error(errors.InternalError(
      ("Failed to load challenge site file '%s': %s"):format(tostring(file), load_err),
      "Compile error occurred while loading the file."
    ))
  end

  local success, _site = pcall(site_func)
  if not success then
    error(errors.InternalError(
      ("Failed to load challenge site file '%s': %s"):format(tostring(file), _site),
      "Runtime error occurred while loading the file."
    ))
  end

  if type(_site) ~= "table" then
    error(errors.InternalError(
      ("Invalid challenge site file '%s': Expected table, got %s"):format(tostring(file), type(_site)),
      "The file must return a table."
    ))
  end

  -- Ensure the main fields are present.
  local function check_invalid_site(t, field_name, expected_type)
    if type(t[field_name]) ~= expected_type then
      error(errors.InternalError(
        ("Invalid challenge site file '%s': Expected field '%s' to be of type %s, got %s"):format(tostring(file), field_name, expected_type, type(t[field_name])),
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
  local challenge_sites = filesystem:at(SITES_ROOT)

  for _, file in ipairs(challenge_sites:list()) do
    register_site(file)
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
  local function pb(str)
    term.setTextColor(colors.lightBlue)
    p(str)
  end
  local function py(str)
    term.setTextColor(colors.yellow)
    p(str)
  end
  local function pg(str)
    term.setTextColor(colors.lightGray)
    p(str)
  end

  pb("Usage: %s <site|command> <subcommand> [args...]")
  py("  %s list")
  pg("    Lists all available challenge sites.")
  py("  %s help")
  pg("    Displays this help message.")
  py("  %s cred-store enable")
  pg("    Enables the credential store.")
  py("  %s cred-store disable")
  pg("    Disables the credential store.")
  py("  %s <site> cred-store remove")
  pg("    Removes the credentials for a specific challenge site.")
  py("  %s <site> help")
  pg("    Displays a help message for a specific challenge site.")
  py("  %s <site> get [args...]")
  pg("    Retrieves a challenge from a challenge site.")
  py("  %s <site> update [args...]")
  pg("    Updates a challenge from a challenge site.")
  py("  %s <site> submit [args...]")
  pg("    Submits a challenge to a challenge site.")
  py("  %s <site> interactive")
  pg("    Enters an interactive shell for a challenge site.")
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
---@return FS_Root directory The directory instance for the challenge.
local function get_challenge_dir(site, ...)
  -- First, we need to get the path to the challenge.
  local dirs = concat_dirs(site.folder_depth, ...)

  -- This folder will be the root of the challenge.
  local cache_path = fs.combine(CHALLENGES_ROOT, site.name, dirs)

  return filesystem:at(cache_path)
end

--- Get a challenge from a challenge site.
---@param internal boolean If true, this command was invoked by another command (i.e: was internally called), and will not try to update the challenge if it doesn't exist.
---@param update boolean If true, this command was invoked with the `update` command, and we will fetch the challenge no matter what. We can still fetch the challenge if this is false, but only if the challenge doesn't exist.
---@param site ChallengeSite The challenge site to get the challenge from.
---@param ... string The arguments passed to the challenge site.
local function get(internal, update, site, ...)
  local site_dir = get_challenge_dir(site, ...)
  local data_dir = filesystem:at("data")

  if not update and site_dir:exists() then
    -- The challenge already exists, so lets just check for the cache file.
    ---@type Challenge
    local challenge = {
      site = site,
      name = site_dir:file("namt.txt"):readAll() or "Unknown",
      description = site_dir:file("description.md"):readAll() or "No description available.",
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

      table.insert(challenge.test_inputs, site_dir:file(file):readAll())
    end

    -- Read each test output from the files.
    for i = 1, math.huge do
      local file = "tests/outputs/" .. i .. ".txt"
      if not site_dir:exists(file) then
        break
      end

      table.insert(challenge.test_outputs, site_dir:file(file):readAll())
    end

    -- Read the challenge input from the file.
    local ok = site_dir:exists("input.txt")
    if ok then
      challenge.input = site_dir:file("input.txt"):readAll()

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
  site_dir:mkdir()
  site_dir:mkdir("tests")
  site_dir:mkdir("tests/inputs")
  site_dir:mkdir("tests/outputs")

  -- For each test input, we will write it to the file.
  for i, input in ipairs(empty_challenge.test_inputs) do
    site_dir:file("tests/inputs/" .. i .. ".txt"):write(input)
  end

  -- For each test output, we will write it to the file.
  for i, output in ipairs(empty_challenge.test_outputs) do
    site_dir:file("tests/outputs/" .. i .. ".txt"):write(output)
  end

  -- Write the challenge data to the files.
  site_dir:file("name.txt"):write(empty_challenge.name)
  site_dir:file("description.md"):write(empty_challenge.description)
  site_dir:file("input.txt"):write(empty_challenge.input)

  -- Write the default run.lua file
  site_dir:file("run.lua"):copyTo(site_dir:file("default_challenge_runner.lua"))
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
  -- Get the site info
  local site_obj = sites[site]

  if not site_obj then
    error(errors.UserError(
      ("Unknown challenge site '%s'"):format(site),
      "Provide a valid challenge site name."
    ))
  end

  credential_store.entries.remove(site, site_obj.credential_store_type)
end

local function process_site_command(site, command, ...)
  local commands = {
    help = function()
      display_help(site)
    end,
    get = function(...)
      get(false, false, sites[site], ...)
    end,
    update = function(...)
      get(false, true, sites[site], ...)
    end,
    submit = function(...)
      submit(sites[site], ...)
    end,
    ["cred-store"] = function(subcommand, ...)
      if subcommand and subcommand:lower() == "remove" then
        remove_credentials(site)
        return
      end
    end
  }
  commands[""] = commands.help
  commands["?"] = commands.help
  commands["-h"] = commands.help
  commands["--help"] = commands.help

  if not sites[site] then
    error(errors.UserError(
      ("Unknown challenge site '%s'"):format(site),
      "Provide a valid challenge site name."
    ))
  end

  command = (command or ""):lower()
  if commands[command] then
    commands[command](...)
    return
  end

  error(errors.UserError(
    ("Unknown command '%s' for challenge site '%s'"):format(command, site),
    "Provide a valid command for the challenge site."
  ))
end

local function interactive(site)
  local site_obj = sites[site]
  local command_history = {}
  local function add_history(cmd)
    if command_history[#command_history] ~= cmd then
      table.insert(command_history, cmd)
    end
  end

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

    add_history(line)

    -- Exit if the user types "exit".
    if line == "exit" then
      break
    end

    --#region Process the command into parts

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

    --#endregion Process the command into parts

    -- Now we can process the command.
    local command = {site}
    for _, part in ipairs(parts) do
      table.insert(command, part[1])
    end

    local ok, err = pcall(process_site_command, table.unpack(command))

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

--- Process a command from the user.
---@param args string[] The command arguments.
local function process_top_level_command(args)
  local commands = {
    list = list_sites,
    help = display_help,
    test = function(site_type)
      if site_type == "up" then
        local ok, user, pass = credential_store.get_user_pass("advent-of-code")
        print("Success:", ok)
        if ok then
          print("User:", user)
          print("Pass:", pass)
        end
      elseif site_type == "token" then
        local ok, token = credential_store.get_token("advent-of-code")
        print("Success:", ok)
        if ok then
          print("Token:", token)
        end
      end
    end,
    ["cred-store"] = function(subcommand)
      if subcommand == "enable" then
        credential_store.enable_credential_store()
      elseif subcommand == "disable" then
        credential_store.disable_credential_store()
      elseif subcommand == "list" then
        credential_store.list_credentials()
      end
    end
  }
  for name in pairs(sites) do
    commands[name] = function(subcommand, ...)
      if subcommand and subcommand:lower() == "interactive" then
        interactive(name)
      else
        process_site_command(name, subcommand, ...)
      end
    end
  end

  local a1 = (args[1] or ""):lower()

  if commands[a1] then
    commands[a1](table.unpack(args, 2, args.n))
    return
  else
    display_help()
  end
end


register_challenge_sites()

-- Register Autocomplete funcs, now that we have access to the challenge sites.
do
  local l1_choices = {"list", "help", "cred-store"}
  for name in pairs(sites) do
    table.insert(l1_choices, name .. " ")
  end

  local l2_cred_choices = {"enable", "disable", "list"}
  local l2_choices = {"help", "get", "update", "submit", "interactive", "cred-store"}
  local l3_choices = {"remove"}

  shell.setCompletionFunction(shell.getRunningProgram(), function (shell, index, text, previous)
    ---@cast previous string[]

    if index == 1 then
      return completion.choice(text, l1_choices)
    end

    if index == 2 then
      if previous[2] == "cred-store" then
        return completion.choice(text, l2_cred_choices)
      end

      if not sites[previous[2]] then
        return
      end

      return completion.choice(text, l2_choices, true)
    end

    if index == 3 then
      if previous[3] ~= "cred-store" then
        return
      end

      return completion.choice(text, l3_choices)
    end
  end)
end


--- Main entry point for the script.
_G.errors_enable_traceback = true
local ok, err = xpcall(process_top_level_command, debug.traceback, table.pack(...))

if not ok then
  error(err, 0)
end