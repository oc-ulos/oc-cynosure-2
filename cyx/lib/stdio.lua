-- standard I/O --

local lib = {}

function lib.printf(fmt, ...)
  return io.write(string.format(fmt, ...))
end

return lib
