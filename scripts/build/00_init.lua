-- load configuration

local conflib = require("scripts/requirable/config")
local log = require("scripts/requirable/logger")

local handle = io.open(".config", "r")
if handle then handle:close() else
  print(log.red .. "==> " .. log.white .. "Build configuration not found.")
  print(log.red .. "==> " .. log.white .. "Copy " .. log.yellow ..
    ".defconfig" .. log.white .. " to " .. log.yellow .. ".config" ..
    log.white .. " and edit it.")
  os.exit(1)
end

print(log.indent .. "Loading " .. log.yellow .. ".config" .. log.white)
_G.bconf = conflib.load(".config")

function _G.depend(thing, need, ...)
  local names = table.pack(...)
  for i=1, #names, 1 do
    if bconf[names[i]] == 'y' and bconf[need] ~= 'y' then
      io.stderr:write("===> ", thing, " depends on ", need, "=y <===\n")
      os.exit(1)
    end
  end
end

function _G.includeif(name, file)
  return bconf[name] == 'y' and ("#include \""..file.."\"") or ""
end
