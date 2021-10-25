--[[
    
    A loader for the Cynosure Executable Format.
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

do
  local magic = 0x43796e6f
  local flags = {
    lua53 = 0x1,
    static = 0x2,
    bootable = 0x4,
    executable = 0x8,
    library = 0x10
  }

  local function read_file(file)
    local handle, err = k.syscall.open(file, {
      rdonly = true
    })
    
    if not handle then
      return nil, err
    end
    
    local data = k.syscall.read(handle, math.huge)
    k.syscall.close(handle)
    
    return data
  end

  local _flags = {
    lua53 = 0x1,
    static = 0x2,
    boot = 0x4,
    exec = 0x8,
    library = 0x10,
  }

  local function parse_cex(str)
    local header, str = k.util.pop(str, 4)
    if header ~= "onyC" then
      return nil, "invalid magic number"
    end

    local flags, str = k.util.pop(str, 1)
    flags = flags:byte()
    local osid, str = k.util.pop(str, 1)
    osid = osid:byte()

    if osid ~= 0 and isod ~= 255 then
      return nil, "bad OSID"
    end
  end

  local function load_cex(file)
    return parse_cex(read_file(file))
  end
end
