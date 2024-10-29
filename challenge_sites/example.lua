--- This is an example library containing everything that is needed for a 
--- programming challenge "runner" system.

--- This object represents your challenge site. It should contain all the
--- information needed to interact with the site, such as the URL and
--- authentication methods.
--- 
--- You will want to create a class that extends this ChallengeSite class,
--- containing the necessary methods to interact with the site.

local credential_store = require "credential_store"

---@class ChallengeSite
---@field name string The name of the challenge site. This is used as a semi-ID for the site, and cannot contain spaces, and must be all-lowercase.
---@field website string The website homepage of the challenge site.
---@field description string A brief description of the challenge site.
---@field folder_depth integer The required depth of the challenge site folders. This is used to determine how many arguments are needed for various commands, and should equal however many "unique" folders are needed to reach the challenges.
---@field credential_store_type string The type of credential store to use for this site. This should be one of the `authentication_utils.ENTRY_TYPES` values.

---@class ExampleChallengeSite : ChallengeSite
---@field cookies string The cookies needed to authenticate with the site.
local site = {
  name = "example",
  website = "https://example.com",
  description = "An example challenge site.",
  folder_depth = 2,
  credential_store_type = credential_store.ENTRY_TYPES.USER_PASS
}

local errors = require "errors"

--- The authentication method. This should set `site.cookies` to the cookies
--- needed to authenticate with the site.
---@return boolean success Whether the authentication was successful.
---@return string? error The error message if the authentication failed.
function site.authenticate()
  -- This method will ask the user for their username and password.
  -- It will also ask if the user would like to save it for future use.
  -- If it is saved, it will pull from that instead of asking again.
  local user, pass = credential_store.get_basic_credentials(site.website)

  local response, err = http.get(site.website .. "/auth", {
    ["Authorization"] = require("base64").encode(user .. ":" .. pass) -- or however your site does its authentication
  })

  if response then
    -- Inject whatever is needed to authenticate into the site object
    site.cookies = response.getResponseHeaders()["Set-Cookie"]
  end

  return response ~= nil and response.getResponseCode() == 200, err
end

--- This object is passed to `site.get_challenge`, and is expected to be filled
--- with the challenge data.
---@class EmptyChallenge
---@field site ChallengeSite The site this challenge is from.

--- This represents the items that need to be filled out in the `EmptyChallenge`
--- object to create a challenge.
---@class Challenge : EmptyChallenge
---@field name string The name of the challenge.
---@field description string The description of the challenge. This will be stored as a `.md` file alongside the challenge.
---@field test_inputs string[] The inputs to test the challenge with, if applicable. These will be stored in `challenge_root/tests/inputs/n.txt`, where `n` is the index of the input.
---@field test_outputs string[] The expected outputs of the test inputs, if applicable. These will be stored in `challenge_root/tests/outputs/n.txt`, where `n` is the index of the output.
---@field input string The actual input for the challenge. This will be stored in `challenge_root/input.txt`.

--- The method to retrieve a challenge from the site. This is only called if
--- local data does not already exist for the challenge, or if the user uses
--- `update`.
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

  -- It is recommended to use the `errors` library for your errors.
  error(errors.InternalError("This is the example site."))
end

--- Submit a challenge to the site.
---@param challenge Challenge The challenge to submit.
---@param challenge_answer string The answer to submit.
---@param ... string Additional arguments passed to the challenge library (past `challenge site_name submit`).
---@return boolean success Whether the submission was successful.
---@return string? error The error message if the submission failed.
---@return string? details Detailed information about the error, if applicable.
---@return string? hint A hint to help the user fix the error, if applicable.
function site.submit(challenge, challenge_answer, ...)
  -- submit the challenge to the site
  -- local response = http.post(bla, challenge_code) -- pseudo code

  -- return the result
  return false, "Failed to submit challenge", "The server returned a 500 error.", "Try again later."
  -- return false, "Incorrect", "The output was incorrect.", "Your value is above the expected value."
  -- or whatever the response was
end

--- This is the final step in the challenge runner. It is called after the
--- challenge has been submitted, and is meant to display any final information
--- to the user.
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

--- Display the help message for this site (i.e: what parameters are needed for `get`).
--- This is called when the user runs `challenge site_name help`.
---@param previous string The substring of the command from 1 to the start of "help".
function site.help(previous)
  print(previous, "get <challenge_id> <challenge_sub_id>")
  print(previous, "update <challenge_id> <challenge_sub_id>")
  print(previous, "submit <challenge_id> <challenge_sub_id>")
end

--- The completion function for this site, used for tab completion in the interactive shell.
--- This function is not required.
---@param text string The text to complete.
---@return string[] completions The possible completions.
function site.completion(text)
  return {}
end

return site