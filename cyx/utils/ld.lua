#!/usr/bin/env lua
--[[
    CYX linker.
    Copyright (C) 2021 Ocawesome101

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
  ]]--

local _MAGIC = 0x43796e6f

local args = table.pack(...)

local function usage()
  io.stderr:write([[
usage: ld.cyx [options] BASE OUTFILE
Create and link a CYX executable.
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
  -i,-include DIR   Include DIR in the paths
                    searched for a binary.  Will
                    be searched for DIR/?.cyx in
                    the same manner as Lua's
                    package.path entries.

CYXUtils copyright (c) 2021 Ocawesome101 under the
GPLv3.
]])
end

local infile, outfile
local to_link = {}

local lib_search = {"./lib/?.cyx"}

local read_libdata
read_libdata = function(file)
  local handle, err = io.open(file, "r")
  if not handle then
    io.stderr:write("ld.cyx: " .. err .. "\n")
    os.exit(1)
  end
  assert(handle:read(4) == "onyC", "invalid CYX signature for " .. file)
  local flags = handle:read(1):byte()
  handle:read(1) -- we don't use OSID
  local nlinks = handle:read(1):byte()
  local needsl53 = flags & 0x1 ~= 0
  local static = flags & 0x2 ~= 0
  local boot = flags & 0x4 ~= 0
  local exec = flags & 0x8 ~= 0
  local lib = flags & 0x10 ~= 0
  if not lib then
    io.stderr:write("ld.cyx: " .. file .. " not marked as library\n")
    os.exit(1)
  end
  local data = ""
  if not static then
    while nlinks > 0 do
      local nlen = handle:read(1):byte()
      local name = handle:read(nlen)
      for i=1, #lib_search, 1 do
        local path = lib_search[i]:gsub("%?", name)
        local handle = io.open(path, "r")
        if handle then
          handle:close()
          io.stderr:write("ld.cyx: linking to library ", name, "\n")
          data = data .. read_libdata(path)
          break
        end
        if i == #lib_search then
          io.stderr:write("ld.cyx: could not find library " .. name .. "\n")
          os.exit(1)
        end
      end
    end
  end
  data = data .. handle:read("a")
  return data
end

local flags = 0
local static = false
local skipnext = false
for i, arg in ipairs(args) do
  if skipnext then
    skipnext = false
  elseif arg:sub(1,1) == "-" then
    arg = arg:sub(2)
    if arg == "l" or arg == "link" then
      to_link[#to_link+1] = args[i+1]
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
    elseif arg == "i" or arg == "include" then
      lib_search[#lib_search + 1] = args[i+1] .. "/?.cyx"
      skipnext = true
    else
      io.stderr:write("ld.cyx: unrecognized option '", arg, "'\nsee '-help'\n")
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
  io.stderr:write("ld.cyx: warning: -boot enables and requires static linking but it was not explicitly enabled - enabling it anyway\n")
  static = true
end

local header = string.pack("<I4I1I1I1", _MAGIC, flags, 255, (static and 0
  or #to_link))

local data = ""

for i, file in ipairs(to_link) do
  if not static then
    data = data .. string.pack("<I1c"..#file, #file, file)
  end
  local path
  for i=1, #lib_search, 1 do
    local _path = lib_search[i]:gsub("%?", file)
    local handle, err = io.open(_path, "r")
    if i == #lib_search and not handle then
      io.stderr:write("ld.cyx: could not find library " .. file .. "\n")
      os.exit(1)
    else
      handle:close()
      io.stderr:write("ld.cyx: linking to library ", file, "\n")
      path = _path
    end
  end
  if static then
    local _data = read_libdata(path)
    local size = #_data
    data = data .. "local " .. file .. " = assert(load([========[" .. _data ..
      "]========], \"=" .. file .. "\", \"t\", _G))()\n"
  end
end

local handle, err = io.open(infile, "r")
if not handle then
  io.stderr:write("ld.cyx: " .. err .. "\n")
  os.exit(1)
end
data = data .. handle:read("a")
handle:close()

local handle, err = io.open(outfile, "w")
if not handle then
  io.stderr:write("ld.cyx: " .. err .. "\n")
  os.exit(1)
end
handle:write(header, data)
handle:close()
