#!/usr/bin/env lua
-- ld: CEX linker --

local _MAGIC = 0x43796e6f
local _LINK_PATH = "./lib/?.lua"

local args = table.pack(...)

local function usage()
  io.stderr:write([[
usage: ld.cex [options] BASE OUTFILE
Create and link a CEX executable.
  -l,-link LIBRARY  Link to LIBRARY.
  -s,-static        Use static linking.
  -53,-lua53        Specify Lua 5.3 requirement.
  -b,-boot          Specify the executable as
                    bootable (requires -static).
  -e,-exec          Specify the executable as a
                    regular executable.
  -L,-library       Specify the executable as a
                    library.
  -p,-plat PLATFORM Specify platform-specific
                    binary.

CEXUtils copyright (c) 2021 Ocawesome101 under the
DSLv2.
]])
end

local infile, outfile
local to_link = {}
local flags = 0
local static = false
local skipnext = false
for i, arg in ipairs(args) do
  if skipnext then
    skipnext = false
    to_link[#to_link+1] = arg
  elseif arg:sub(1,1) == "-" then
    arg = arg:sub(2)
    if arg == "l" or arg == "link" then
      skipnext = true
    elseif arg == "help" then
      usage()
      os.exit(0)
    elseif arg == "53" or arg == "lua53" then
      flags = flags | 0x1
    elseif arg == "s" or arg == "static" then
      static = true
      flags = flags | 0x2
    elseif arg == "b" or arg == "boot" then
      flags = flags | 0x4
    elseif arg == "e" or arg == "exec" then
      flags = flags | 0x8
    elseif arg == "L" or arg == "library" then
      flags = flags | 0x10
    else
      io.stderr:write("ld.cex: unrecognized option '", arg, "'\nsee '-help'\n")
      os.exit(1)
    end
  else
    if not infile then
      infile = arg
    elseif not outfile then
      outfile = arg
    else
      usage()
      os.exit(1)
    end
  end
end

if not outfile then
  usage()
  os.exit(1)
end

if flags & 0x4 ~= 0 and not static then
  io.stderr:write("ld.cex: warning: -boot enables and requires static linking but it was not explicitly enabled - enabling it anyway\n")
  static = true
end

local header = string.pack("<I4I1I1I1", _MAGIC, flags, 255, #to_link)
local data = ""
for i, file in ipairs(to_link) do
  data = data .. string.pack("<I1c"..#file, #file, file)
  local path = _LINK_PATH:gsub("%?", file)
  local handle, err = io.open(path, "r")
  if not handle then
    io.stderr:write("ld.cex: " .. err .. "\n")
    os.exit(1)
  end
  if static then
    local _data = handle:read("a")
    local size = #_data
    data = data .. string.pack("<I2c"..size, size, _data)
  end
  handle:close()
end

local handle, err = io.open(infile, "r")
if not handle then
  io.stderr:write("ld.cex: " .. err .. "\n")
  os.exit(1)
end
data = data .. handle:read("a")
handle:close()

local handle, err = io.open(outfile, "w")
if not handle then
  io.stderr:write("ld.cex: " .. err .. "\n")
  os.exit(1)
end
handle:write(header, data)
handle:close()
