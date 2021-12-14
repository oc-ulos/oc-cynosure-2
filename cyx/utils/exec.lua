#!/usr/bin/env lua
--[[
    CYX loader script.
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

local _MAGIC = "onyC"

local args = table.pack(...)

local file = args[1]

if not file then
  io.stderr:write([[
usage: exec.cyx FILE ...
Executes the provided CYX file, passing it the
given arguments.

CYXUtils copyright (c) 2021 Ocawesome101 under the
GPLv3.
]])
  os.exit(1)
end

local function read_file(f)
  local handle, err = io.open(f, "r")
  if not handle then
    io.stderr:write("exec.cyx: ", err, "\n")
    os.exit(1)
  end
  local data = handle:read("a")
  handle:close()
  return data
end

local load_cyx
load_cyx = function(file, e)
  local data = read_file(file)
  if #data < 8 then
    io.stderr:write("exec.cyx: ", file, ": file is too small\n")
    os.exit(1)
  end
  
  if data:sub(1,4) ~= _MAGIC then
    io.stderr:write("exec.cyx: ", file, ": file has invalid magic number\n")
    os.exit(1)
  end

  local version = data:sub(5,5):byte()
  
  local flags = data:sub(6,6):byte()
  
  if flags & 0x1 ~= 0 and _VERSION < "Lua 5.3" then
    io.stderr:write("exec.cyx: executable requires Lua 5.3 or newer\n")
    os.exit(1)
  end
  
  local static = flags & 0x2 ~= 0
  local exec = flags & 0x8 ~= 0
  local lib = flags & 0x10 ~= 0

  io.stderr:write("exec.cyx: ", file, ": flags:",
    "\n  static:     ", static and "\27[32myes" or "\27[31mno",
    "\27[39m\n  executable: ", exec and "\27[32myes" or "\27[31mno",
    "\27[39m\n  library:    ", lib and "\27[32myes" or "\27[31mno", "\27[39m\n")

  if e and not exec then
    io.stderr:write("exec.cyx: ", file, ": not marked as executable\n")
    os.exit(1)
  elseif not (e or lib) then
    io.stderr:write("exec.cyx: ", file, ": not marked as a library\n")
    os.exit(1)
  end

  local osid = data:sub(7,7):byte()
  local nlinks = data:sub(8,8):byte()
  data = data:sub(9)
  if nlinks == 0 then
    return data
  else
    local libd = ""
    local offset = 0
    for i=1, nlinks, 1 do
      local nlen = data:sub(offset + i, offset + i):byte()
      local name = data:sub(offset + i + 1, offset + i + nlen)
      offset = offset + nlen
      local _data = load_cyx("./lib/"..name..".cyx")
      libd = libd .. "local " .. name .. " = assert(load([======["
        .._data .. "]======], '=" .. name .. "', 't', _G))()\n"
    end
    return libd .. data:sub(offset+3)
  end
end

local dat = load_cyx(file, true)
assert(load(dat, "="..file, "t", _G))()
