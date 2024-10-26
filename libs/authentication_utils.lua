--- This library contains a bunch of utilities for authentication.

local file_helper = require "file_helper"
local chacha20 = require "ccryptolib.chacha20"
local sha256 = require "ccryptolib.sha256"
local random = require "ccryptolib.random"
local errors = require "errors"
random.initWithTiming()

local PBKDF2_ROUNDS = 10000
local PBKDF2_SALT_SIZE = 128
local CHACHA20_ROUNDS = 20
local CHACHA20_NONCE_SIZE = 12

local credential_store = file_helper:instanced(".credential_store")

---@class CredentialEntry
---@field site_name string The name of the site.
---@field username string The username for the site, encrypted.
---@field password string The password for the site, encrypted.
---@field nonce_uname string The nonce used to encrypt the username.
---@field nonce_pass string The nonce used to encrypt the password.
---@field salt_verification string The salt used for verification of the encryption key.
---@field salt_encryption string The salt used to generate the hash of the encryption key.
---@field hash string The hash of the encryption key.

---@class authentication_utils
local authentication_utils = {}

--- Check if the credential store is enabled or not.
---@return boolean enabled Whether the credential store is enabled.
function authentication_utils.is_credential_store_enabled()
  return not credential_store:exists(".disabled")
end

--- Display a percentage based on progress.
---@param y number The y position to display the progress at. Starts at x=1.
---@param stage number The current stage of the progress. Use this if you want to merge multiple actions into one percentage.
---@param stage_max number The maximum stage of the progress. Use this if you want to merge multiple actions into one percentage.
local function progress(y, stage, stage_max)
  if not y then error("bruh", 2) end
  y = y - 1

  stage = stage or 1
  stage_max = stage_max or 1

  local set = "|/-\\|"
  local idx = 1
  local multiplier = 1 / stage_max
  local start = (stage - 1) / stage_max

  return function(iter)
    term.setCursorPos(1, y)
    if iter ~= PBKDF2_ROUNDS then
      term.write(set:sub(idx, idx))
      term.write(("%3d%%"):format(math.floor(((iter / PBKDF2_ROUNDS) * multiplier + start) * 100 + 0.5)))
    else
      term.write(("\xb7%3d%%"):format(math.floor((multiplier + start) * 100 + 0.5)))
    end

    idx = idx + 1
    if idx > #set then idx = 1 end
  end
end

--- Read a verification passphrase for a site.
---@param site_name string The name of the site to get the passphrase for.
---@param pbkdf2_salt string The salt used for the PBKDF2 hash.
---@param pbkdf2_hash string The hash of the PBKDF2 hash.
---@param stage number The current stage of the progress, used if multiple actions are being merged into one percentage.
---@param stage_max number The maximum stage of the progress, used if multiple actions are being merged into one percentage.
local function read_expected_passphrase(site_name, pbkdf2_salt, pbkdf2_hash, stage, stage_max)
  local passphrase
  local f = 0

  repeat
    if f >= 3 then
      error(errors.AuthenticationError("Too many incorrect passphrase attempts."))
    elseif f ~= 0 then
      print(" Incorrect passphrase, please try again.")
    end
    f = f + 1

    print("Please enter the passphrase to unlock credentials for site", site_name)
    write("\xb7\xb7\xb7\xb7\xb7> ")
    passphrase = read("*") --[[@as string bro this literally cannot return nil]]
    local _, y = term.getCursorPos()
  until sha256.pbkdf2(passphrase, pbkdf2_salt, PBKDF2_ROUNDS, progress(y, stage, stage_max)) == pbkdf2_hash
  sleep()
  return passphrase
end

--- Get a basic username/password combo for a site. This will either use the encrypted cache or prompt the user for the credentials.
---@param site_name string The name of the site to get the credentials for.
---@return boolean ok Whether the operation was successful.
---@return string? username The username for the site.
---@return string? password The password for the site.
function authentication_utils.get_user_pass(site_name)
  -- First, check if we already have any cached data for this site.
  local exists = credential_store:exists(site_name)

  local store_enabled = authentication_utils.is_credential_store_enabled()

  -- It exists, prompt the user for the encryption password.
  if store_enabled and exists then
    local entry = credential_store:unserialize(site_name) --[[@as CredentialEntry]]

    if not entry then
      error(errors.InternalError(
        ("Failed to unserialize credential data for site %s"):format(site_name),
        "Is the file corrupted?"
      ))
    end

    if not entry.hash or not entry.salt_verification or not entry.salt_encryption or not entry.nonce_uname or not entry.nonce_pass or not entry.username or not entry.password then
      error(errors.InternalError(
        ("Missing credential data in credential store."):format(site_name),
        "Is the file corrupted?"
      ))
    end

    local passphrase = read_expected_passphrase(site_name, entry.salt_verification, entry.hash, 1, 2)

    print()
    --print("\n      Calculating encryption hash...")
    local _, y = term.getCursorPos()
    local encryption_hash = sha256.pbkdf2(passphrase, entry.salt_encryption, PBKDF2_ROUNDS, progress(y, 2, 2))

    print("\nDecrypting credentials...")
    local username = chacha20.crypt(encryption_hash, entry.nonce_uname, entry.username, CHACHA20_ROUNDS)
    local password = chacha20.crypt(encryption_hash, entry.nonce_pass, entry.password, CHACHA20_ROUNDS)

    return true, username, password
  end

  -- It doesn't exist, prompt the user for new credentials.
  print("Please enter the username for", site_name)
  write("> ")
  local username = read() --[[@as string]]

  print("Please enter the password for", site_name)
  write("> ")
  local password = read("*") --[[@as string]]

  -- All of this we can ignore if the store is disabled.
  if store_enabled then
    -- Password confirmation
    print("Confirm the password for", site_name)
    write("> ")
    local confirm_password = read("*") --[[@as string]]
    if password ~= confirm_password then
      printError(errors.UserError("Passwords do not match."))
      return false
    end

    -- Passphrase
    print("Please enter a passphrase to encrypt these credentials (32 characters max).")
    write("> ")
    local passphrase = read("*") --[[@as string]]
    if #passphrase > 32 then
      printError(errors.UserError("Passphrase is too long."))
      return false
    end

    -- Passphrase confirmation
    print("Please confirm the passphrase.")
    write("> ")
    local confirm_passphrase = read("*") --[[@as string]]
    if passphrase ~= confirm_passphrase then
      printError(errors.UserError("Passphrases do not match."))
      return false
    end

    -- Hash encryption key.
    print("      Hashing passphrase...")
    local salt_verification = random.random(PBKDF2_SALT_SIZE)
    local _, y = term.getCursorPos()
    local hash_verification = sha256.pbkdf2(passphrase, salt_verification, PBKDF2_ROUNDS, progress(y, 1, 2))
    local nonce_uname = random.random(CHACHA20_NONCE_SIZE)
    local nonce_pass = random.random(CHACHA20_NONCE_SIZE)

    -- Hash verification key.
    local salt_encryption = random.random(PBKDF2_SALT_SIZE)
    local encryption_hash = sha256.pbkdf2(passphrase, salt_encryption, PBKDF2_ROUNDS, progress(y, 2, 2))

    -- Actually encrypt the credentials.
    print("\nEncrypting credentials...")
    local encrypted_username = chacha20.crypt(encryption_hash, nonce_uname, username, CHACHA20_ROUNDS)
    local encrypted_password = chacha20.crypt(encryption_hash, nonce_pass, password, CHACHA20_ROUNDS)

    -- Build the entry
    ---@type CredentialEntry
    local entry = {
      site_name = site_name,
      username = encrypted_username,
      password = encrypted_password,
      nonce_uname = nonce_uname,
      nonce_pass = nonce_pass,
      salt_verification = salt_verification,
      salt_encryption = salt_encryption,
      hash = hash_verification
    }

    -- Save the credentials.
    print("Saving credentials...")
    credential_store:serialize(site_name, entry, true)
  end

  return true, username, password
end

return authentication_utils