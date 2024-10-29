--- Advent of Code Challenge Site

local credential_store = require("credential_store")

---@class AdventOfCode : ChallengeSite
local site = {
  name = "advent-of-code",
  website = "https://adventofcode.com/",
  description = "Advent of Code is an Advent calendar of small programming puzzles for a variety of skill sets and skill levels that can be solved in any programming language you like.",
  folder_depth = 2,
  credential_store_type = credential_store.ENTRY_TYPES.USER_PASS
}

local URL_FORMATTER = site.website .. "%d/day/%d"
local INPUT_URL_FORMATTER = URL_FORMATTER .. "/input"
local SUBMIT_URL_FORMATTER = URL_FORMATTER .. "/answer"

--- The authentication method. This should set `site.cookies` to the cookies
--- needed to authenticate with the site.
---@return boolean success Whether the authentication was successful.
---@return string? error The error message if the authentication failed.
function site.authenticate()
  return false
end

--- Retrieve a challenge from Advent of Code.
---@param empty_challenge EmptyChallenge|Challenge The EmptyChallenge object to be filled out.
---@param ... string The arguments passed to the challenge library (past `challenge site_name get`).
function site.get_challenge(empty_challenge, ...)
  local challenge_id, challenge_sub_id = ...
  -- get the challenge data from the site
  -- local challenge_data = http.get(bla .. challenge_id .. "/" .. challenge_sub_id, {Cookie=site.cookies}).readAll().close() -- pseudo code

  -- fill out the empty_challenge object
  -- In your real `get_challenge`, you would want to substitute this with the actual challenge data.
  empty_challenge.name = "Example Challenge"
  empty_challenge.description = "This is an example challenge."
  empty_challenge.test_inputs = {"input1", "input2"}
  empty_challenge.test_outputs = {"output1", "output2"}
  empty_challenge.input = "input"
end

--- Submit a challenge to Advent of Code.
---@param challenge Challenge The challenge to submit.
---@param challenge_answer string The code to submit.
---@param ... string Additional arguments passed to the challenge library (past `challenge site_name submit`).
---@return boolean success Whether the submission was successful.
---@return string? error The error message if the submission failed.
---@return string? details Detailed information about the error, if applicable.
---@return string? hint A hint to help the user fix the error, if applicable.
function site.submit(challenge, challenge_answer, ...)
  return false, "Not implemented", "This part of the API is not implemented yet.", "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
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
end

--- The completion function for this site, used for tab completion in the interactive shell.
---@param text string The text to complete.
---@return string[] completions The possible completions.
function site.completion(text)
  return {}
end

return site