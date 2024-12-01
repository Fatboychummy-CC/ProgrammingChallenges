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
local efh = require "extra_filehandles"
local filesystem = require "filesystem":programPath()
local completion = require "cc.completion"
local errors = require "errors"
local pretty_print = require "cc.pretty".pretty_print
local logging = require "logging"
-- local mock_filehandles = require "mock_filehandles"

local CHALLENGES_ROOT = "challenges"
local SITES_ROOT = "challenge_sites"

local LOG = logging.create_context("challenge")
logging.set_level(logging.LOG_LEVEL.DEBUG)


---@type table<string, ChallengeSite>
local sites = {}

--- Register a challenge site, doing a few checks to ensure it's valid.
---@param file FS_File The file representing the challenge site.
local function register_site(file)
  LOG.debugf("-> Registering challenge site '%s'", tostring(file))

  if file:isDirectory() then
    file = file:file("init.lua")
  end

  local handle, err = file:open("r")
  if not handle then
    errors.InternalError(
      ("Failed to open challenge site file '%s': %s"):format(tostring(file), err)
    ) return -- otherwise the linter thinks this continues.
  end

  local content = handle.readAll()
  handle.close()

  if not content then
    errors.InternalError(
      ("Failed to read challenge site file '%s'"):format(tostring(file)),
      "File is empty, or some other issue occurred while reading."
    ) return -- otherwise the linter thinks this continues.
  end

  local site_func, load_err = load(content, "=" .. tostring(file), "t", _ENV)
  if not site_func then
    errors.InternalError(
      ("Failed to load challenge site file '%s': %s"):format(tostring(file), load_err),
      "Compile error occurred while loading the file."
    ) return -- otherwise the linter thinks this continues.
  end

  local success, _site = pcall(site_func)
  if not success then
    errors.InternalError(
      ("Failed to load challenge site file '%s': %s"):format(tostring(file), _site),
      "Runtime error occurred while loading the file."
    ) return -- otherwise the linter thinks this continues.
  end

  if type(_site) ~= "table" then
    errors.InternalError(
      ("Invalid challenge site file '%s': Expected table, got %s"):format(tostring(file), type(_site)),
      "The file must return a table."
    ) return -- otherwise the linter thinks this continues.
  end

  -- Ensure the main fields are present.
  local function check_invalid_site(t, field_name, expected_type)
    if type(t[field_name]) ~= expected_type then
      errors.InternalError(
        ("Invalid challenge site file '%s': Expected field '%s' to be of type %s, got %s"):format(tostring(file), field_name, expected_type, type(t[field_name])),
        "The file is returning a table with a required field that is missing or of the wrong type."
      ) return -- otherwise the linter thinks this continues.
    end
  end

  check_invalid_site(_site, "name", "string")
  check_invalid_site(_site, "website", "string")
  check_invalid_site(_site, "description", "string")
  check_invalid_site(_site, "folder_depth", "number")
  check_invalid_site(_site, "credential_store_type", "string")

  LOG.debugf("--> Registered challenge site '%s'", _site.name)

  sites[_site.name] = _site
end

--- Load all challenge sites from the `challenge_sites` directory.
local function register_challenge_sites()
  local challenge_sites = filesystem:at(SITES_ROOT)
  LOG.debug("Registering challenge sites")

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
      errors.UserError(
        ("Unknown challenge site '%s'"):format(site),
        "Provide a valid challenge site name."
      ) return
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
    errors.UserError(
      ("Expected %d more argument(s)."):format(n - dirs.n),
      ("Expected %d argument(s), got %d."):format(n, dirs.n),
      0
    ) return "" -- otherwise the linter thinks this continues.
  elseif dirs.n > n then
    -- This is a user error, so we will use level 0.
    errors.UserError(
      ("Expected %d less argument(s)."):format(dirs.n - n),
      ("Expected %d argument(s), got %d."):format(n, dirs.n),
      0
    ) return ""
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
---@return Challenge challenge The challenge data.
local function get(internal, update, site, ...)
  local site_dir = get_challenge_dir(site, ...)
  local data_dir = filesystem:at("data")

  LOG.debugf("Getting challenge from site '%s' at '%s'", site.name, tostring(site_dir))

  if not update and site_dir:exists() then
    LOG.debugf("-> Challenge directory already exists... Building on that.")

    -- The challenge already exists, so lets just check for the cached files.
    ---@type Challenge
    local challenge = {
      site = site,
      name = site_dir:file("name.txt"):readAll() or "Unknown",
      description = site_dir:file("description.md"):readAll() or "No description available.",
      test_inputs = {},
      test_outputs = {},
      input = "",
      directory = site_dir
    }
    LOG.debug("--> Collected name and description")

    -- Read each test input from the files.
    for i = 1, math.huge do
      local file = "tests/inputs/" .. i .. ".txt"
      if not site_dir:exists(file) then
        break
      end

      table.insert(challenge.test_inputs, site_dir:file(file):readAll())
      LOG.debugf("--> Collected test input %d", i)
    end

    -- Read each test output from the files.
    for i = 1, math.huge do
      local file = "tests/outputs/" .. i .. ".txt"
      if not site_dir:exists(file) then
        break
      end

      table.insert(challenge.test_outputs, site_dir:file(file):readAll())
      LOG.debugf("--> Collected test output %d", i)
    end

    -- Read the challenge input from the file.
    local ok = site_dir:exists("input.txt")
    if ok then
      challenge.input = site_dir:file("input.txt"):readAll()
      LOG.debug("--> Collected challenge input, done.")

      return challenge
    end

    -- The challenge input file is missing, so we need to fetch the challenge.
    -- If we are directly calling `get`, we can do this fine. Otherwise, throw
    -- an error, as the user may not want to re-fetch the challenge.
    if internal then
      errors.InternalError(
        "Challenge input file is missing.",
        "Try updating the challenge."
      ) return ---@diagnostic disable-line: missing-return-value
    end
  end

  -- The challenge doesn't exist, so we need to fetch it.
  if internal then
    errors.UserError(
      "Challenge does not exist.",
      "You must first get the challenge before you can run it."
    ) return ---@diagnostic disable-line: missing-return-value
  end

  LOG.debug("-> Challenge directory does not exist, fetching challenge.")
  if site.authenticate then
    LOG.debug("--> Requires authentication, authenticating...")
    local ok, err = site.authenticate()
    if not ok then
      errors.UserError(
        "Failed to authenticate with the challenge site.",
        err
      ) return ---@diagnostic disable-line: missing-return-value
    end
  end

  ---@type EmptyChallenge
  local challenge_data = {
    site = site
  }
  LOG.debugf("--> Delegating to site '%s' to get the challenge data.", site.name)
  if not site.get_challenge(challenge_data, ...) then
    errors.InternalError(
      "Failed to get the challenge from the challenge site.",
      "The challenge site failed to provide the challenge data."
    ) return ---@diagnostic disable-line: missing-return-value
  end
  ---@cast challenge_data Challenge

  -- Now we need to create the directories and files.
  LOG.debug("--> Creating directories and files for the challenge.")
  site_dir:mkdir()
  site_dir:mkdir("tests")
  site_dir:mkdir("tests/inputs")
  site_dir:mkdir("tests/outputs")

  -- For each test input, we will write it to the file.
  for i, input in ipairs(challenge_data.test_inputs) do
    site_dir:file("tests/inputs/" .. i .. ".txt"):write(input)
  end

  -- For each test output, we will write it to the file.
  for i, output in ipairs(challenge_data.test_outputs) do
    site_dir:file("tests/outputs/" .. i .. ".txt"):write(output)
  end

  -- Write the challenge data to the files.
  site_dir:file("name.txt"):write(challenge_data.name)
  site_dir:file("description.md"):write(challenge_data.description)
  site_dir:file("input.txt"):write(challenge_data.input)

  -- Write the default run.lua file
  data_dir:file("default_challenge_runner.lua"):copyTo(site_dir:file("run.lua"))

  LOG.debug("--> Challenge data written to files.")

  return challenge_data
end

--- Compile the challenge runner for a challenge site.
---@param site ChallengeSite The challenge site to compile the challenge runner for.
---@return fun(...):fun(input: MockReadHandle, output: MockWriteHandle) compiled The compiled challenge runner.
local function compile_challenge(site, ...)
  local site_dir = get_challenge_dir(site, ...)

  local _ = function(input,output)end

  if not site_dir:exists() then
    errors.UserError(
      "Challenge does not exist.",
      "You must first get the challenge before you can run it."
    ) return _
  end

  local run_file = site_dir:file("run.lua")
  if not run_file:exists() then
    errors.UserError(
      "Challenge runner does not exist.",
      "You must first get the challenge before you can run it."
    ) return _
  end

  LOG.debugf("Compiling challenge runner at '%s'", tostring(run_file))
  local func, err = load(run_file:readAll(), "=" .. run_file.path, "t", _ENV)
  if not func then
    errors.UserError(
      "Compilation failed: " .. tostring(err),
      "The challenge runner failed to compile. Check the file for errors, then try again."
    ) return _
  end

  return func
end



--- Display the result of a challenge.
---@param output_file MockWriteHandle The output file to display the result from.
local function display_result(output_file)
  -- Mock the logger a bit...
  term.blit(
    "[RESULT] ",
    "0dddddd00",
    "fffffffff"
  )
  term.setTextColor(colors.lightBlue)
  print(output_file.buffer)
  term.setTextColor(colors.white)
end



---@class ResultComparison
---@field expected_output string The expected output.
---@field actual_output string The actual output.

--- Display test results.
---@param test_results ResultComparison[] The test results to display.
local function display_test_results(test_results)
  local passed = 0
  local failed = 0

  for i, result in ipairs(test_results) do
    local passed_str = result.expected_output == result.actual_output and "PASSED" or "FAILED"
    local color = result.expected_output == result.actual_output and colors.green or colors.red

    term.setTextColor(color)
    print(("[%d] %s"):format(i, passed_str))
    term.setTextColor(colors.white)

    if result.expected_output ~= result.actual_output then
      term.setTextColor(colors.lightBlue)
      write("Expected: ")
      term.setTextColor(colors.white)
      print(result.expected_output)

      term.setTextColor(colors.lightBlue)
      write("Actual  : ")
      term.setTextColor(colors.white)
      print(result.actual_output)

      failed = failed + 1
    else
      passed = passed + 1
    end
  end

  term.setTextColor(colors.lightBlue)
  write("Results: ")
  term.setTextColor(colors.white)
  print(("%d passed, %d failed."):format(passed, failed))
end



--- Run the main challenge from a challenge site.
---@param site ChallengeSite The challenge site to run the challenge from.
---@param run_func fun(input: MockReadHandle, output: MockWriteHandle) The compiled challenge runner.
local function run_main(site, run_func, ...)
  local site_dir = get_challenge_dir(site, ...)

  LOG.debug("-> Loading challenge files")
  -- Load the input file, and the output files.
  local input_file, err = efh.openRead(site_dir:file("input.txt"))
  if not input_file then
    errors.InternalError(
      "Failed to open input file:" .. tostring(err),
      "The input file could not be opened. Check the file exists, then try again."
    ) return
  end

  local output_file, err = efh.openWrite {
    site_dir:file("output.txt"),
    filesystem:at("challenge_output.txt")
  }
  if not output_file then
    errors.InternalError(
      "Failed to open output file(s):" .. tostring(err),
      "The output file(s) could not be opened. Does your computer have enough space?"
    ) return
  end

  LOG.info("Running challenge")

  local start_time = os.epoch("utc")
  local ok, err = pcall(run_func, input_file, output_file)
  local time = os.epoch("utc") - start_time

  if not ok then
    errors.UserError(
      "Runtime error: " .. tostring(err),
      "The challenge runner failed to execute. Check the file for errors, then try again."
    ) return
  end

  if not input_file:isClosed() then
    input_file:close()
  end
  if not output_file:isClosed() then
    output_file:close()
  end
  LOG.debug("Input and output handles closed.")

  LOG.info("Challenge completed in", time, "ms")

  display_result(output_file)
end



--- Run the tests for a challenge from a challenge site.
---@param site ChallengeSite The challenge site to run the tests from.
---@param run_func fun(input: MockReadHandle, output: MockWriteHandle) The compiled challenge runner.
---@param ... string The arguments passed to the challenge site.
local function run_tests(site, run_func, ...)
  local site_dir = get_challenge_dir(site, ...)

  LOG.debug("-> Loading challenge files")
  -- Load all the test files from `inputs` and `outputs`.
  local test_inputs = site_dir:at("tests/inputs"):list()
  local test_outputs = site_dir:at("tests/outputs"):list()

  if #test_inputs == 0 then
    errors.UserError(
      "No test inputs found.",
      "You must first get the challenge before you can run the tests."
    ) return
  end

  if #test_outputs == 0 then
    errors.UserError(
      "No test outputs found.",
      "You must first get the challenge before you can run the tests."
    ) return
  end

  if #test_inputs ~= #test_outputs then
    errors.UserError(
      "Mismatched test inputs and outputs.",
      "The number of test inputs and outputs do not match. Ensure they are the same, then try again."
    ) return
  end

  -- Ensure each test input has a matching output. (inputs/n.txt -> inputs/n.txt)
  for _, input_file in ipairs(test_inputs) do
    local name = fs.getName(tostring(input_file))
    local found = false

    for _, output_file in ipairs(test_outputs) do
      if fs.getName(tostring(output_file)) == name then
        found = true
        break
      end
    end

    if not found then
      errors.UserError(
        ("No matching output file found for test input '%s'"):format(name),
        "Ensure each test input has a matching output, then try again."
      ) return
    end
  end

  -- Finally, actually run the tests.
  local results = {}

  for i, input_file in ipairs(test_inputs) do
    local output_file = test_outputs[i]

    LOG.debugf("-> Running test %d", i)
    local input_handle, err = efh.openRead(input_file)
    local expected_output = output_file:readAll()
    local output_handle = efh.openWrite {
      site_dir:file("output.txt"),
      filesystem:at("challenge_output.txt")
    }

    if not input_handle then
      errors.InternalError(
        ("Failed to open test input file %d: %s"):format(i, tostring(err)),
        "The test input file could not be opened. Check the file exists, then try again."
      ) return
    end
    if not expected_output then
      errors.InternalError(
        ("Failed to read test output file %d"):format(i),
        "The test output file could not be read. Check the file exists, then try again."
      ) return
    end
    if not output_handle then
      errors.InternalError(
        ("Failed to open test output file %d: %s"):format(i, tostring(err)),
        "The test output file could not be opened. Check the file exists, then try again."
      ) return
    end

    local ok, err = pcall(run_func, input_handle, output_handle)

    if not input_handle:isClosed() then
      input_handle:close()
    end

    if not output_handle:isClosed() then
      output_handle:close()
    end

    if not ok then
      errors.UserError(
        ("Runtime error in test %d: %s"):format(i, tostring(err)),
        "The challenge runner failed to execute. Check the file for errors, then try again."
      ) return
    end

    table.insert(results, {
      expected_output = expected_output,
      actual_output = output_handle.buffer
    })
  end

  display_test_results(results)
end



--- Run a challenge from a challenge site.
---@param site ChallengeSite The challenge site to run the challenge from.
---@param test boolean If true, run the tests instead of the main challenge. This loads and runs all the test inputs and outputs.
---@param ... string The arguments passed to the challenge site.
local function run(site, test, ...)
  ---@FIXME I hate how this function looks, maybe we could abstract some things out, but right now it looks like a mess.


  local site_dir = get_challenge_dir(site, ...)
  LOG.debugf("Running challenge from site '%s' at '%s'", site.name, tostring(site_dir))

  local func = compile_challenge(site, ...)

  LOG.debug("-> Init challenge runner")
  local success, result = pcall(func, ...)
  if not success then
    errors.UserError(
      "Setup error: " .. tostring(result),
      "The challenge runner failed to execute. Check the file for errors, then try again."
    ) return
  end


  if type(result) == "function" then
    if test then
      run_tests(site, result, ...)
    else
      run_main(site, result, ...)
    end
  end
end

--- Submit a challenge to a challenge site.
---@param site ChallengeSite The challenge site to submit the challenge to.
---@param ... string The arguments passed to the challenge site.
local function submit(site, ...)
  local site_dir = get_challenge_dir(site, ...)
  LOG.debugf("Submitting challenge from site '%s' at '%s'", site.name, tostring(site_dir))

  -- First, we need to get the challenge data...
  local challenge = get(true, false, site, ...)
  if not challenge then
    return
  end

  if not site_dir:exists("output.txt") then
    errors.UserError(
      "No output file found.",
      "You must first run the challenge before you can submit it."
    ) return
  end

  -- Now we can submit the challenge.
  if site.authenticate then
    LOG.debug("-> Requires authentication, authenticating...")
    local ok, err = site.authenticate()
    if not ok then
      errors.UserError(
        "Failed to authenticate with the challenge site.",
        err
      ) return
    end
  end

  LOG.debug("-> Delegating to site to submit the challenge.")
  local ok, err = site.submit(challenge, site_dir:file("output.txt"):readAll(), ...)

  if not ok then
    errors.ChallengeError(
      "Submission failed.",
      err
    ) return
  end

  LOG.info("Challenge complete!")
  if err then
    LOG.info("Message:", err)
  end
end

--- Credential Store : Remove an entry
---@param site string The site to remove the credentials for.
local function remove_credentials(site)
  -- Get the site info
  local site_obj = sites[site]
  LOG.debugf("Removing credentials for site '%s'", site)

  if not site_obj then
    errors.UserError(
      ("Unknown challenge site '%s'"):format(site),
      "Provide a valid challenge site name."
    )
  end

  credential_store.entries.remove(site, site_obj.credential_store_type)
  LOG.info("Credentials removed.")
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
    run = function(...)
      run(sites[site], false, ...)
    end,
    test = function(...)
      run(sites[site], true, ...)
    end,
    submit = function(...)
      submit(sites[site], ...)
    end,
    ["cred-store"] = function(subcommand, ...)
      if subcommand and subcommand:lower() == "remove" then
        remove_credentials(site)
        return
      end

      errors.UserError(
        ("Unknown subcommand '%s' for 'cred-store'"):format(subcommand),
        "Provide a valid subcommand for the 'cred-store' command."
      )
    end
  }
  commands[""] = commands.help
  commands["?"] = commands.help
  commands["-h"] = commands.help
  commands["--help"] = commands.help

  if not sites[site] then
    errors.UserError(
      ("Unknown challenge site '%s'"):format(site),
      "Provide a valid challenge site name."
    )
  end

  command = (command or ""):lower()
  if commands[command] then
    commands[command](...)
    return
  end

  errors.UserError(
    ("Unknown command '%s' for challenge site '%s'"):format(command, site),
    "Provide a valid command for the challenge site."
  )
end

local function interactive(site)
  local site_obj = sites[site]
  local command_history = {}
  local function add_history(cmd)
    if command_history[#command_history] ~= cmd then
      table.insert(command_history, cmd)
    end
  end

  LOG.debugf("Launching interactive shell for site '%s'", site_obj.name)

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
          "test",
          "update",
          "submit",
          "help",
          "cred-store",
          "exit"
        }

        -- Check if the first word in the text is one of the commands.
        local first_word = text:match("%S+")
        local space_after_first = text:match("%S+%s")
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
        -- Or, if there is a space after the first word.
        if second_word or space_after_first then
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
      errors.UserError("Unmatched quote in command.")
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
        if err.type ~= "UserError" and err.type ~= "ChallengeError" then
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
        --[[
        local ok, token = credential_store.get_token("advent-of-code")
        print("Success:", ok)
        if ok then
          print("Token:", token)
        end]]

        sites["advent-of-code"].authenticate()
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
  local l2_choices = {"help", "get", "run", "test", "update", "submit", "interactive", "cred-store"}
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