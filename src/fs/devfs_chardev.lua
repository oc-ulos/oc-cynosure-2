--[[
  Character device support
  Copyright (C) 2022 Ocawesome101

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

--#include "src/disciplines/main.lua"

printk(k.L_INFO, "fs/devfs_chardev")

do
  local chardev = {}

  function chardev.new(stream, discipline)
    checkArg(1, stream, "table")
    checkArg(2, discipline, "string")

    if not k.disciplines[discipline] then
      error("no line discipline '"..discipline.."'")
    end

    local new = setmetatable({stream = stream, discipline = discipline},
      {__index = chardev})

    return new
  end

  function chardev:open(path)
    if #path > 0 then return nil, k.errno.ENOTDIR end
    return { fd = k.disciplines[self.discipline].wrap(self.stream),
      default_mode = "none" }
  end

  function chardev:stat()
    return { dev = -1, ino = -1, mode = 0x21FF, nlink = 1,
      uid = 0, gid = 0, rdev = -1, size = 0, blksize = 2048,
      atime = 0, ctime = 0, mtime = 0 }
  end

  function chardev:read(fd, n)
    return fd.fd:read(n)
  end

  function chardev:write(fd, data)
    return fd.fd:write(data)
  end

  function chardev:seek()
    return nil, k.errno.ENOSYS
  end

  function chardev:flush(fd)
    if fd.fd.flush then fd.fd:flush() end
  end

  function chardev.ioctl(fd, ...)
    return fd.fd:ioctl(...)
  end

  function chardev:close(fd)
    return fd.fd:close()
  end

  k.chardev = chardev
end
