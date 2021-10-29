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

  local _flags = {
    lua53 = 0x1,
    static = 0x2,
    boot = 0x4,
    exec = 0x8,
    library = 0x10,
  }

  local function parse_cex(fd)
    local header = k.syscall.read(fd, 4)
    if header ~= "onyC" then
      return nil, k.errno.ENOEXEC
    end

    local flags = k.common.pop(fd, 1)
    flags = flags:byte()
    local osid = k.common.pop(fd, 1)
    osid = osid:byte()

    if osid ~= 0 and isod ~= 255 then
      return nil, k.errno.ENOEXEC
    end

    local _
    if flags & flags.static == 0 then
      local nlink
      nlink = k.syscall.read(fd, 1)
      nlink = nlink:byte()
      if nlink == 0 then
        -- no interpreter!
        return nil, k.errno.ENOEXEC
      end
      local nlib = k.syscall.read(fd, 1):byte()
      local itpfile = k.syscall.read(fd, nlib)
      local func = k.load_executable(itpfile)
      k.syscall.seek(fd, "set", 0)
      return function(...)
        return func(fd, ...)
      end
    else
      k.syscall.read(fd, 3)
      local str = k.syscall.read(fd, math.huge)
      k.syscall.close(fd)
      return load(str)
    end
  end

  function k.load_cex(file, flags)
    local fd, err = k.syscall.open(file, {
      rdonly = true
    })
    if not fd then
      return nil, err
    end

    return parse_cex(fd)
  end
end
