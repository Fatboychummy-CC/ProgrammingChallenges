--- Advent of Code Challenge Site

local credential_store = require "credential_store"
local completion = require "cc.completion"
local filesystem = require "filesystem":programPath()
local errors = require "errors"
local LOG = require "logging".create_context("AoC")

---@class AdventOfCode : ChallengeSite
---@field session string? The session token for the site.
local site = {
  name = "advent-of-code",
  website = "https://adventofcode.com/",
  description = "Advent of Code is an Advent calendar of small programming puzzles for a variety of skill sets and skill levels that can be solved in any programming language you like.",
  folder_depth = 3,
  credential_store_type = credential_store.ENTRY_TYPES.USER_PASS
}

local URL_FORMATTER = site.website .. "%d/day/%d"
local INPUT_URL_FORMATTER = URL_FORMATTER .. "/input"
local SUBMIT_URL_FORMATTER = URL_FORMATTER .. "/answer"

local FILE_FORMATTER = "challenges/" .. site.name .. "/%d/%d/%d"

--- The authentication method. This should set a value in the class that can
--- be used in get_challenge (or others) to authenticate with the site.
---@return boolean success Whether the authentication was successful.
---@return string? error The error message if the authentication failed.
function site.authenticate()
  if site.session then
    LOG.info("Already authenticated.")
    return true
  end

  LOG.debug("Not authenticated. Prompting user for session token.")
  if not credential_store.entries.exists(site.name, "token") then
    print()
    term.setTextColor(colors.orange)
    write("Authenticate to get your puzzle input.")
    term.setTextColor(colors.white)
    print(" Provide your session token from the Advent of Code website. Use 'inspect element' -> 'Network' tab -> refresh page -> find 'session' cookie.")
    print()
    print("Copy only the value after 'session=' and paste it here.")
    print()

    if credential_store.is_credential_store_enabled() then
      term.setTextColor(colors.yellow)
      print("The token is encrypted and stored on disk. To disable credential storage, run:")
      term.setTextColor(colors.lightBlue)
      print("    challenge cred-store disable")
      term.setTextColor(colors.white)
      print()
    end
  end

  local ok, session = credential_store.get_token(site.name)

  if not ok then
    return false, "Authentication failure."
  end
  ---@cast session string

  -- Because we know people will listen to the instructions right?
  if session:match("^session=") then
    session = session:sub(8)
  end

  site.session = session
  return true
end

--- Retrieve a challenge from Advent of Code.
---@param empty_challenge EmptyChallenge|Challenge The EmptyChallenge object to be filled out.
---@param challenge_year string The year of the challenge.
---@param challenge_day string The day of the challenge.
---@param challenge_part string The part of the challenge.
---@return boolean success Whether the challenge collection was successful.
---@return string? warnings Any warnings that occurred during the collection.
function site.get_challenge(empty_challenge, challenge_year, challenge_day, challenge_part)
  if not site.session then
    errors.ChallengeError("Not authenticated.")
  end

  local cy_n = tonumber(challenge_year)
  local cd_n = tonumber(challenge_day)
  local cp_n = tonumber(challenge_part)

  if not cy_n or not cd_n or not cp_n then
    errors.UserError("Invalid challenge year, day, or part.", nil, 0)
    return false -- errors.UserError throws an error, but the linter doesn't realize it.
  end

  cy_n, cd_n, cp_n = math.floor(cy_n), math.floor(cd_n), math.floor(cp_n)

  if cy_n < 2015 or cy_n > os.date("*t").year then
    error("Invalid challenge year.", 0)
  end

  if cd_n < 1 or cd_n > 25 then
    error("Invalid challenge day.", 0)
  end

  if cp_n < 1 or cp_n > 2 then
    error("Invalid challenge part.", 0)
  end

  local challenge_url = URL_FORMATTER:format(cy_n, cd_n)
  local input_url = INPUT_URL_FORMATTER:format(cy_n, cd_n)

  -- If this is day two, check if the input for the first challenge is already
  -- stored on disk, since the challenges use the same input.
  local got_input = false
  if cp_n == 2 then
    local first_challenge = FILE_FORMATTER:format(cy_n, cd_n, 1)
    if filesystem:exists(first_challenge) then
      empty_challenge.input = filesystem:at(first_challenge):file("input.txt"):readAll()
      if empty_challenge.input then
        got_input = true
      end
    end
  end

  if not got_input then
    -- HTTP request.
    print(input_url)
    local response, err = http.get(input_url, {["Cookie"] = "session=" .. site.session})
    if not response then
      errors.NetworkError("Failed to get input for challenge.", err)
      return false -- errors.NetworkError throws an error, but the linter doesn't realize it.
    end

    empty_challenge.input = response.readAll() --[[@as string]]
    response.close()
  end

  -- Request the challenge page.
  local response, err = http.get(challenge_url, {["Cookie"] = "session=" .. site.session})
  if not response then
    errors.NetworkError("Failed to get challenge page.", err)
    return false -- errors.NetworkError throws an error, but the linter doesn't realize it.
  end

  local challenge_page = response.readAll() --[[@as string]]
  response.close()

  -- Parse the challenge page for the name.
  local name = challenge_page:match("<h2>%-%-%- (.-) %-%-%-</h2>")

  -- fill out the empty_challenge object
  -- In your real `get_challenge`, you would want to substitute this with the actual challenge data.
  empty_challenge.name = name or "Parse Failure"
  empty_challenge.description = "No description can be provided."
  empty_challenge.test_inputs = {}
  empty_challenge.test_outputs = {}

  return true, "Challenge description and test inputs/outputs are unable to be collected currently (NYI)."
end

--- Submit a challenge to Advent of Code.
---@param challenge Challenge The challenge to submit.
---@param challenge_answer string The code to submit.
---@param challenge_year string The year of the challenge.
---@param challenge_day string The day of the challenge.
---@param challenge_part string The part of the challenge.
---@return boolean success Whether the submission was successful. Not "no error" successful, but "challenge passed" successful.
---@return string? error The error message if the submission failed.
function site.submit(challenge, challenge_answer, challenge_year, challenge_day, challenge_part)
  if not site.session then
    errors.ChallengeError("Not authenticated.")
  end

  local cy_n = tonumber(challenge_year)
  local cd_n = tonumber(challenge_day)
  local cp_n = tonumber(challenge_part)

  if not cy_n or not cd_n or not cp_n then
    errors.UserError("Invalid challenge year, day, or part.", nil, 0)
    return false -- errors.UserError throws an error, but the linter doesn't realize it.
  end

  cy_n, cd_n, cp_n = math.floor(cy_n), math.floor(cd_n), math.floor(cp_n)

  if cy_n < 2015 or cy_n > os.date("*t").year then
    error("Invalid challenge year.", 0)
  end

  if cd_n < 1 or cd_n > 25 then
    error("Invalid challenge day.", 0)
  end

  if cp_n < 1 or cp_n > 2 then
    error("Invalid challenge part.", 0)
  end

  local submit_url = SUBMIT_URL_FORMATTER:format(cy_n, cd_n)

  local post_body = "level=" .. cp_n .. "&answer=" .. textutils.urlEncode(challenge_answer)
  local headers = {
    ["Cookie"] = "session=" .. site.session,
    ["Content-Type"] = "application/x-www-form-urlencoded"
  }

  LOG.infof("Submitting challenge %d/%d, part %d...", cy_n, cd_n, cp_n)
  LOG.debugf("Submit URL: %s", submit_url)
  LOG.debugf("Post body: %s", post_body)
  local keys = {}
  for k in pairs(headers) do
    table.insert(keys, k)
  end
  LOG.debugf(
    "Header keys: %s",
    table.concat(keys, ", ")
  )
  local response, err = http.post(
    submit_url,
    "level=" .. challenge_part .. "&answer=" .. textutils.urlEncode(challenge_answer),
    {
      ["Cookie"] = "session=" .. site.session,
      ["Content-Type"] = "application/x-www-form-urlencoded"
    }
  )

  if not response then
    errors.NetworkError("Failed to submit challenge.", err)
    return false -- errors.NetworkError throws an error, but the linter doesn't realize it.
  end

  local response_text = response.readAll() --[[@as string]]

  -- Check if the submission was successful.
  local message = response_text:match("<article><p>(.-) If you're stuck.*</p></article>")
  if not message then
    message = response_text:match("<article><p>(.-)Curiously,</p></article>") -- "Curiously, it's the right answer for someone else"
  end
  local correct = response_text:match("That's the right answer!")

  if correct then
    return true, message
  end

  local too_recent = response_text:match("<article><p>You gave an answer too recently;.*You have (.-) left to wait.</p></article>")

  if too_recent then
    return false, "Submission too recent. Wait " .. too_recent .. " to submit again."
  end

  errors.InternalError("Failed to parse submission response.", response_text:match("<article>.-</article>"))
  return false -- errors.InternalError throws an error, but the linter doesn't realize it.
end

--- Display the results of a submission.
---@param success boolean Whether the challenge was successful.
---@param error string The error message if the challenge failed.
---@param details string Detailed information about the error, if applicable.
---@param hint string A hint to help the user fix the error, if applicable.
function site.display_result(success, error, details, hint)
  if success then
    print("Challenge submitted successfully!")
  else
    print("Challenge submission failed!")
    print("Error:", error)
    print("Details:", details)
    print("Hint:", hint)
  end
end

--- Display the help message.
---@param previous string The substring of the command from 1 to the start of "help".
function site.help(previous)
  print(previous, "get <year> <day> <part>")
  print(previous, "run <year> <day> <part>")
  print(previous, "update <year> <day> <part>")
  print(previous, "submit <year> <day> <part>")
  print(previous, "test <year> <day> <part>")
end

--- The completion function for this site, used for tab completion in the interactive shell.
---@param text string The text to complete.
---@return string[]? completions The possible completions.
function site.completion(text)
  local current_date = os.date("!*t")
  local year = current_date.year --[[@as integer]]
  local day = current_date.day --[[@as integer]]
  local hour = current_date.hour --[[@as integer]]

  local iter = text:gmatch( "%S+")
  local command = iter()
  local _year = iter()
  local space_after_year = text:match("%S+%s+%S+%s+")
  local _day = iter()
  local space_after_day = text:match("%S+%s+%S+%s+%S+%s+")
  local _part = iter()

  -- Only up to the current year is allowed.
  local years = {}
  for i = year, 2015, -1 do
    table.insert(years, tostring(i))
  end

  -- Only up to the current date is shown (if current year)
  -- Allow the next day as well, if within an hour of midnight.
  -- Note: EST (UTC-5) is AoC's time zone.
  local days = {}
  if _year and tonumber(_year) == year then
    local _allowed_day = day
    -- If it's within an hour of midnight, allow the next day.
    if (hour - 5) % 24 < 1 then
      _allowed_day = _allowed_day + 1
    end

    -- If it's still november, only allow the first day.
    if current_date.month == 11 then
      _allowed_day = 1
    end

    for i = math.min(25, _allowed_day), 1, -1 do
      table.insert(days, tostring(i))
    end
  else
    -- Otherwise allow any day.
    for i = 25, 1, -1 do
      table.insert(days, tostring(i))
    end
  end

  if command == "get" or command == "run" or command == "update" or command == "submit" or command == "test" then
    if not space_after_year then
      return completion.choice(_year or "", years)
    end

    if not space_after_day then
      return completion.choice(_day or "", days)
    end

    return completion.choice(_part or "", {"1", "2"})
  end
end

return site