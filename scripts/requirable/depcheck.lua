-- dependency checking --

local log = require("scripts/requirable/logger")

return function(lib)
  io.write(log.info .. "Checking dependency " .. log.yellow .. lib ..
    log.white .. "... ")
  local ok, tab, err = pcall(require, lib)
  if not ok and err then
    io.write(log.red .. "Failed\n" .. log.white .. err)
    os.exit(1)
  end
  io.write(log.green .. "OK" .. log.white .. "\n")
  return tab
end
