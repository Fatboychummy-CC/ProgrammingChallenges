--- This file contains specific error definitions for the challenge runner.

local errors = {}

local TRACEBACK_FORMATTER = "%s : %s\n\n%s"
local ERROR_FORMATTER = "%s : %s"

if _G.debug_challenges then
  TRACEBACK_FORMATTER = "%s : %s\n%s\n\n%s"
  ERROR_FORMATTER = "%s : %s\n%s"
end

local error_mt = {
  __tostring = function(self)
    if _G.debug_challenges then
      if self.traceback then
        return TRACEBACK_FORMATTER:format(self.type, self.message, self.details or "No additional information.", self.traceback)
      end

      return ERROR_FORMATTER:format(self.type, self.message, self.details or "No additional information.")
    end

    if self.traceback then
      return TRACEBACK_FORMATTER:format(self.type, self.message, self.traceback)
    end

    return ERROR_FORMATTER:format(self.type, self.message)
  end
}

---@class CustomError
---@field message string The error message.
---@field details string? Detailed information about the error, if applicable.
---@field traceback string? The traceback of the error, if applicable.
---@field type ErrorType The type of error.

---@alias ErrorType
---| '"UserError"' # An error caused by the user.
---| '"InternalError"' # An error caused by the challenge runner itself.
---| '"ChallengeError"' # An error caused by the challenge itself.
---| '"NetworkError"' # An error caused by a network issue.
---| '"AuthenticationError"' # An error caused by authentication issues.

---@class UserError : CustomError
---@field type '"UserError"'

---@param message string The error message.
---@param details string? Detailed information about the error, if applicable.
---@return UserError user_error The user error object.
function errors.UserError(message, details)
  return setmetatable({
    message = message,
    details = details,
    type = "UserError"
  }, error_mt)
end

---@class InternalError : CustomError
---@field type '"InternalError"'

---@param message string The error message.
---@param details string? Detailed information about the error, if applicable.
---@param traceback string? The traceback of the error, if applicable.
---@return InternalError internal_error The internal error object.
function errors.InternalError(message, details, traceback)
  return setmetatable({
    message = message,
    details = details,
    traceback = traceback,
    type = "InternalError"
  }, error_mt)
end

---@class ChallengeError : CustomError
---@field type '"ChallengeError"'

---@param message string The error message.
---@param details string? Detailed information about the error, if applicable.
---@param traceback string? The traceback of the error, if applicable.
---@return ChallengeError challenge_error The challenge error object.
function errors.ChallengeError(message, details, traceback)
  return setmetatable({
    message = message,
    details = details,
    traceback = traceback,
    type = "ChallengeError"
  }, error_mt)
end

---@class NetworkError : CustomError
---@field type '"NetworkError"'

---@param message string The error message.
---@param details string? Detailed information about the error, if applicable.
---@return NetworkError network_error The network error object.
function errors.NetworkError(message, details)
  return setmetatable({
    message = message,
    details = details,
    type = "NetworkError"
  }, error_mt)
end

---@class AuthenticationError : CustomError
---@field type '"AuthenticationError"'

---@param message string The error message.
function errors.AuthenticationError(message)
  return setmetatable({
    message = message,
    type = "AuthenticationError"
  }, error_mt)
end

return errors