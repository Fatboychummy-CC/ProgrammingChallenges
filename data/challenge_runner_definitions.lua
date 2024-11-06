---@meta

--- A mock read handle with a few extra helpful functions.
---@class MockReadHandle
local MockReadHandle = {}

--- Read `bytes` bytes from the handle (Default 1)
---@param bytes integer? The number of bytes to read.
---@return string? data The data read from the handle.
function MockReadHandle:read(bytes) end

--- Read a single line from the handle.
---@return string? data The line read from the handle.
function MockReadHandle:readLine() end

--- Read the entire contents of the handle.
---@return string? data The data read from the handle.
function MockReadHandle:readAll() end

--- Reads a number from the file.
--- WARNING: This method will skip over data until it is able to read a number.
---@return number? number The number read from the file.
function MockReadHandle:readNumber() end

--- Reads an integer from the file.
--- WARNING: This method will skip over data until it is able to read a number.
---@return integer? number The integer read from the file.
function MockReadHandle:readInteger() end

--- Reads a boolean from the file.
--- A boolean can either be a 1/0, or a string "true" or "false" (with any
--- capitalization).
--- WARNING: This method will skip over data until it is able to read a boolean.
---@return boolean? boolean The boolean read from the file.
function MockReadHandle:readBoolean() end

--- Reads the entire file, but returns a table split by the given separator.
---@param separator string? The separator to split the file by. Defaults to newline ('\n').
---@return table<string> data The data read from the file.
function MockReadHandle:readLines(separator) end

--- Use a lua pattern match on the file, from the current cursor position.
---@param pattern string The pattern to match.
---@return string? ... The matches from the pattern.
---@return integer? start The start position of the match.
---@return integer? stop The end position of the match.
function MockReadHandle:match(pattern) end

--- Use a lua pattern match on the file. This will match across the entire file,
--- regardless of the current cursor position.
---@param pattern string The pattern to match.
---@return string? ... The matches from the pattern.
---@return integer? start The start position of the match.
---@return integer? stop The end position of the match.
function MockReadHandle:matchAll(pattern) end

--- Closes the read handle. The handle cannot be used after this.
function MockReadHandle:close() end

--- Checks if the handle is closed.
---@return boolean closed Whether the handle is closed.
function MockReadHandle:isClosed() end

--- Returns the current cursor position in the file.
---@return integer cursor The current cursor position.
function MockReadHandle:getCursor() end

---@class MockWriteHandle
local MockWriteHandle = {}

--- Write data to the handle.
---@param data any The data to write to the handle. This will be `tostring`ed.
function MockWriteHandle:write(data) end

--- Write a formatted string to the handle.
---@param format string The format string.
---@param ... any The arguments to the format string.
function MockWriteHandle:writef(format, ...) end

--- Write a line to the handle.
---@param data any The data to write to the handle. This will be `tostring`ed.
function MockWriteHandle:print(data) end

--- Write a formatted line to the handle.
---@param format string The format string.
---@param ... any The arguments to the format string.
function MockWriteHandle:printf(format, ...) end

--- Write a newline to the handle.
--- This is equivalent to `write("\n")`.
function MockWriteHandle:newLine() end

--- Write data to a file, literally (not passed through `tostring`).
--- This method may error, depending on the type of data passed.
---@param data any The data to write to the handle.
function MockWriteHandle:writeRaw(data) end

--- Closes the write handle. The handle cannot be used after this.
function MockWriteHandle:close() end

--- Checks if the handle is closed.
---@return boolean closed Whether the handle is closed.
function MockWriteHandle:isClosed() end

--- Returns the current cursor position in the file.
---@return integer cursor The current cursor position.
function MockWriteHandle:getCursor() end