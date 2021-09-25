#!/usr/bin/env lua

_G.env = setmetatable({}, {__index = function(t, k) return os.getenv(k) end})

local proc, handle

local included = {}
local dirs
dirs = {
  {"%-%-#define ([^ ]+).-([^ ]+)", function(a, b)
    dirs[#dirs + 1] = {"[^a-zA-Z0-9_]"..a.."[^a-zA-Z0-9_]", b}
  end},
  {"%-%-#undef ([^ }+)", function(a)
    local done = false
    for i=1, #dirs, 1 do
      if dirs[i][1]:sub(13, -13) == a then
        table.remove(dirs, i)
        done = true
        break
      end
    end
    if not done then
      error(a .. ": not defined")
    end
  end},
  {"$%[%{(.+)%}%]", function(ex)
    return assert(io.popen(ex, "r"):read("a")):gsub("\n$","")
  end},
  {"@%[%{(.+)%}%]", function(ex)
    return assert(load("return " .. ex, "=eval", "t", _G))()
  end},
  {"%-%-#include \"(.+)\" ?(.-)$", function(f, e)
    if (e == "force") or not included[f] then
      included[f] = true
      return proc(f)
    end
  end},
}

proc = function(f)
  io.write("\27[36m *\27[39m processing " .. f .. "\n")
  for line in io.lines(f) do
    for k, v in ipairs(dirs) do
      line = line:gsub(v[1], v[2])
    end
    handle:write(line .. "\n")
  end
end

local args = {...}

if #args < 2 then
  io.stderr:write([[
usage: proc IN OUT
Preprocesses files in a manner similar to LuaComp.

Much more primitive than LuaComp.
]])
  os.exit(1)
end

handle = assert(io.open(args[2], "w"))

proc(args[1])

handle:close()

io.write("\27[95m * \27[39mSuccess!\n")

os.exit(0)
