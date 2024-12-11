--- Challenge library for working with filehandles that have extra functionality.

local expect = require "cc.expect".expect

---@class ExtraFilehandles
local extra_file_handles = {}

--- Opens a file for reading, using a MockReadHandle
---@param path string|FS_Root The path to the file to open.
---@param is_data boolean? If true, will treat `path` like it is pure data from a file.
---@return MockReadHandle? handle The read handle for the file.
---@return string? error The error message, if any.
function extra_file_handles.openRead(path, is_data)
  if type(path) == "table" then
    path = tostring(path)
    ---@cast path string  
  end


  --- A mocked read-handle that has a few extra utility functions.
  ---@class MockReadHandle
  ---@field path string The path to the file.
  ---@field data string The data in the file.
  ---@field len integer The length of the data in the file.
  ---@field cursor integer The current cursor position.
  ---@field closed boolean Whether the handle is closed.
  local MockReadHandle = {}

  local function attempt_closed()
    if MockReadHandle.closed then
      error("Attempted to use a closed file handle.", 3)
    end
  end

  --- Read `bytes` bytes from the handle (Default 1)
  ---@param bytes integer? The number of bytes to read.
  ---@return string? data The data read from the handle.
  function MockReadHandle:read(bytes)
    expect(1, bytes, "number", "nil")
    attempt_closed()

    bytes = bytes or 1
    if bytes < 0 then
      error("Cannot read a negative number of bytes.", 2)
    end

    if self.cursor > self.len then
      return nil
    end

    -- Read in the data then push the cursor forward.
    local data = MockReadHandle.data:sub(MockReadHandle.cursor, MockReadHandle.cursor + bytes - 1)
    MockReadHandle.cursor = MockReadHandle.cursor + bytes

    return data
  end

  --- Read a single line from the handle.
  ---@param separator string? The separator to split the line by. Defaults to newline ('\n'), pattern enabled.
  ---@return string? data The line read from the handle.
  function MockReadHandle:readLine(separator)
    expect(1, separator, "string", "nil")
    attempt_closed()

    separator = separator or '\n'

    if self.cursor > self.len then
      return nil
    end

    local start = self.cursor
    local stop, stop_2 = self.data:find(separator, start)

    if not stop then
      self.cursor = self.len + 1
      return self.data:sub(start)
    end

    self.cursor = stop_2 + 1
    return self.data:sub(start, stop - 1)
  end

  --- Read the entire contents of the handle.
  ---@return string? data The data read from the handle.
  function MockReadHandle:readAll()
    attempt_closed()

    if self.cursor > self.len then
      return nil
    end

    local data = self.data:sub(self.cursor)
    self.cursor = self.len + 1
    return data
  end

  --- Reads a double number from the file.
  --- WARNING: This method will skip over data until it is able to read a number.
  --- 
  --- The algorithm essentially just continues extending the current value until
  --- `tonumber` returns `nil`, then returns the last valid number.
  --- Because of this, it will read values like `100.` as `100`, but the `.` 
  --- *will* be consumed, as `100.` is a valid number to Lua.
  --- 
  ---@param base integer? The base to read the value in. Defaults to 10.
  ---@return number? number The number read from the file.
  function MockReadHandle:readNumber(base)
    expect(1, base, "number", "nil")
    attempt_closed()

    base = base or 10

    -- Stage 1: From the cursor, find a value that is considered a valid number.
    local start = self.cursor
    local stop = start
    local found = false
    while start <= self.len do
      if tonumber(self.data:sub(start, start), base) then
        found = true
        break
      end

      start = start + 1
    end

    if not found then
      return nil
    end

    -- Stage 2: From the found value, extend it until it is no longer a valid number.
    stop = start
    while stop <= self.len do
      if not tonumber(self.data:sub(start, stop), base) then
        break
      end

      stop = stop + 1
    end

    -- Stage 3: Set the cursor to the end of the number and return the number.
    self.cursor = stop
    return tonumber(self.data:sub(start, stop - 1), base)
  end

  --- Reads the entire file, but returns a table split by the given separator.
  ---@param separator string? The separator to split the file by. Defaults to newline ('\n'), pattern enabled.
  ---@return table<string> data The data read from the file.
  function MockReadHandle:readLines(separator)
    expect(1, separator, "string", "nil")
    attempt_closed()

    separator = separator or '\n'

    local lines = {}
    while true do
      local line = self:readLine(separator)
      if not line then
        break
      end

      table.insert(lines, line)
    end

    return lines
  end

  --- Reads the entire file, but returns an iterator for the file (split by the given separator).
  ---@param separator string? The separator to split the file by. Defaults to newline ('\n'), pattern enabled.
  ---@return fun():string? iterator The iterator for the file.
  function MockReadHandle:lines(separator)
    expect(1, separator, "string", "nil")
    attempt_closed()

    separator = separator or '\n'

    return function()
      return self:readLine(separator)
    end
  end

  --- Use a lua pattern match on the file, from the current cursor position.
  ---@param pattern string The pattern to match.
  ---@return string? ... The matches from the pattern.
  function MockReadHandle:match(pattern)
    expect(1, pattern, "string")
    attempt_closed()

    -- results[1]: Start
    -- results[2]: End
    -- results[3+]: Captures
    local results = {self.data:find(pattern, self.cursor)}

    if not results then
      return nil
    end

    self.cursor = results[2] + 1

    ---@diagnostic disable-next-line: return-type-mismatch The return type is technically correct, but the linter doesn't understand it
    return table.unpack(results, 3)
  end

  --- Use a lua pattern match on the file. This will match across the entire file,
  --- regardless of the current cursor position.
  ---@param pattern string The pattern to match.
  ---@return string? ... The matches from the pattern.
  function MockReadHandle:matchAll(pattern)
    expect(1, pattern, "string")
    attempt_closed()

    local results = {}
    while true do
      local out = {self:match(pattern)}

      if not out then
        break
      end

      table.insert(results, table.unpack(out))
    end

    return table.unpack(results)
  end

  --- Closes the read handle. The handle cannot be used after this.
  function MockReadHandle:close()
    attempt_closed()

    self.closed = true
  end

  --- Checks if the handle is closed.
  ---@return boolean closed Whether the handle is closed.
  function MockReadHandle:isClosed()
    return self.closed
  end

  --- Returns the current cursor position in the file.
  ---@return integer cursor The current cursor position.
  function MockReadHandle:getCursor()
    attempt_closed()

    return self.cursor
  end

  --- Sets the read cursor position in the file.
  ---@param whence "set"|"cur"|"end" The position to set the cursor relative to (cur: current, end: end of file--backwards, set: absolute).
  function MockReadHandle:seek(whence, offset)
    expect(1, whence, "string")
    expect(2, offset, "number", "nil")
    attempt_closed()

    if whence ~= "set" and whence ~= "cur" and whence ~= "end" then
      error(("Bad argument #1: Expected 'cur', 'end', or 'set', got '%s'"):format(whence), 2)
    end

    if whence == "set" then
      if offset < 0 then
        error("Cannot seek to a negative position.", 2)
      end

      self.cursor = offset
    elseif whence == "cur" then
      if self.cursor + offset < 0 then
        error("Cannot seek to a negative position.", 2)
      end
      if self.cursor + offset > self.len then
        error("Cannot seek to a position after the end of the file.", 2)
      end

      self.cursor = self.cursor + offset
    elseif whence == "end" then
      if offset < 0 then
        error("Cannot seek to a position after the end of the file.", 2)
      end

      if self.len - offset < 0 then
        error("Cannot seek to a negative position.", 2)
      end

      self.cursor = self.len - offset
    end
  end

  --- Returns the length of the file.
  ---@return integer len The length of the file.
  function MockReadHandle:length()
    attempt_closed()

    return self.len
  end


  if is_data then
    MockReadHandle.data = path
    MockReadHandle.len = #path
    MockReadHandle.cursor = 1
    MockReadHandle.closed = false
    MockReadHandle.path = "data"
    return MockReadHandle
  end

  local _handle, err = fs.open(path, "rb")
  if not _handle then
    return nil, err
  end

  -- Inject the data

  MockReadHandle.data = _handle.readAll() --[[@as string]]
  MockReadHandle.len = #MockReadHandle.data
  MockReadHandle.cursor = 1
  MockReadHandle.closed = false
  MockReadHandle.path = path

  _handle.close()

  return MockReadHandle
end

--- Opens one or more files for simultaneous writing, using a MockWriteHandle
---@param paths (string|FS_Root)[] The paths to the files to open.
---@return MockWriteHandle? handle The write handle for all files at once.
---@return string? error The error message, if any.
function extra_file_handles.openWrite(paths)
  expect(1, paths, "table")

  local cleaned_paths = {} ---@type string[]
  for i, path in ipairs(paths) do
    if type(path) == "table" then
      path = tostring(path)
    end

    table.insert(cleaned_paths, path)
  end

  --- A mocked write-handle that has a few extra utility functions, and can
  --- write to multiple files at once.
  ---@class MockWriteHandle
  ---@field paths string[] The paths to the files.
  ---@field handles table<string, BinaryWriteHandle> The raw handles to the files.
  ---@field closed boolean Whether the handle is closed.
  ---@field buffer string Everything that has been written to the file, concatenated.
  local MockWriteHandle = {}

  local function attempt_closed()
    if MockWriteHandle.closed then
      error("Attempted to use a closed file handle.", 3)
    end
  end

  --- Write data to the handle.
  ---@param data any The data to write to the handle. This will be `tostring`ed.
  function MockWriteHandle:write(data)
    attempt_closed()

    data = tostring(data)

    for _, handle in pairs(self.handles) do
      handle.write(tostring(data))
    end

    self.buffer = self.buffer .. data
  end

  --- Write an integer to the handle. This uses the float format string, but
  --- with `.0f` in order to write a large integer (as lua does not like to
  --- output large integers with `%d`)
  ---@param data integer The integer to write to the handle.
  function MockWriteHandle:writeInt(data)
    expect(1, data, "number")
    attempt_closed()

    self:write(("%.0f"):format(data))
  end

  --- Write a formatted string to the handle.
  ---@param format string The format string.
  ---@param ... any The arguments to the format string.
  function MockWriteHandle:writef(format, ...)
    expect(1, format, "string")
    attempt_closed()

    local data = format:format(...)

    for _, handle in pairs(self.handles) do
      handle.write(data)
    end

    self.buffer = self.buffer .. data
  end

  --- Write a line to the handle.
  ---@param data any The data to write to the handle. This will be `tostring`ed.
  function MockWriteHandle:print(data)
    attempt_closed()

    self:write(data)
    self:write('\n')
  end

  --- Write a formatted line to the handle.
  ---@param format string The format string.
  ---@param ... any The arguments to the format string.
  function MockWriteHandle:printf(format, ...)
    expect(1, format, "string")
    attempt_closed()

    self:print(format:format(...))
  end

  --- Write a newline to the handle.
  --- This is equivalent to `write("\n")`.
  function MockWriteHandle:newLine()
    attempt_closed()

    self:write('\n')
  end

  --- Write data to a file, literally (not passed through `tostring`).
  --- This method may error, depending on the type of data passed.
  ---@param data string|number The data to write to the handle.
  function MockWriteHandle:writeRaw(data)
    attempt_closed()

    for _, handle in pairs(self.handles) do
      handle.write(data)
    end

    self.buffer = self.buffer .. data
  end

  --- Closes the write handle. The handle cannot be used after this.
  function MockWriteHandle:close()
    attempt_closed()

    for _, handle in pairs(self.handles) do
      handle.close()
    end

    self.closed = true
  end

  --- Checks if the handle is closed.
  ---@return boolean closed Whether the handle is closed.
  function MockWriteHandle:isClosed()
    return self.closed
  end

  MockWriteHandle.paths = cleaned_paths
  MockWriteHandle.handles = {}
  MockWriteHandle.closed = false
  MockWriteHandle.buffer = ""

  for _, path in ipairs(cleaned_paths) do
    local _handle, err = fs.open(path, "wb") --[[@as BinaryWriteHandle,string?]]

    if not _handle then
      return nil, err ---@diagnostic disable-line: return-type-mismatch I really hate that @as can't handle vararg returns.
    end

    MockWriteHandle.handles[path] = _handle
  end

  return MockWriteHandle
end

--- Opens a URL for reading, using a MockReadHandle
---@param url string The URL to open.
---@return MockReadHandle? handle The read handle for the URL.
---@return string? error The error message, if any.
function extra_file_handles.openURL(url)
  expect(1, url, "string")

  local response, err = http.get(url)
  if not response then
    return nil, err
  end

  local data = response.readAll()
  response.close()

  if not data then
    return nil, "No data in response object."
  end

  return extra_file_handles.openRead(data, true)
end

return extra_file_handles