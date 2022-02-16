--[[
  Component pseudo-filesystem
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

printk(k.L_INFO, "fs/component")

do
  -- Provides a vfs structured such that /component/filesystem/abc3f31e is
  -- a filesystem component.
  local provider = {}

  function provider:exists(path)
    checkArg(1, path, "string")

    local ctype, caddr = table.unpack(k.split_path(path))
    if caddr then
      return not not component.list(ctype, true)[caddr]
    elseif ctype then
      return not not component.list(ctype, true)()
    else
      return true
    end
  end

  function provider:stat(path)
    checkArg(1, path, "string")

    local ctype, caddr = table.unpack(k.split_path(path))
    if (not caddr) and component.list(ctype)() or not ctype then
      return {
        dev=-1, ino=-1, mode=0x41FF, nlink=1, uid=0, gid=0,
        rdev=-1, size=0, blksize=2048
      }
    end

    if component.list(ctype, true)[caddr] then
      return {
        dev=-1, ino=-1, mode=0x61FF, nlink=1, uid=0, gid=0,
        rdev=-1, size=0, blksize=2048
      }
    end

    return nil, k.errno.ENOENT
  end

  -- This VFS only provides a few methods. Most of its functionality is
  -- done through ioctl().
  function provider:open(path)
    checkArg(1, path, "string")
    local ctype, caddr = table.unpack(k.split_path(path))
    if not (ctype and caddr) then return nil, k.errno.ENOENT end
    local proxy = component.proxy(caddr)
    if (not proxy) or proxy.type ~= ctype then
      return nil, k.errno.ENOENT
    end
    return { proxy = proxy }
  end

  local ioctls = {}

  function ioctls.invoke(fd, call, ...)
    checkArg(3, call, "string")
    if not fd.proxy[call] then
      return nil, k.errno.EINVAL
    end
    return fd.proxy[call](...)
  end

  function ioctls.address(fd)
    return fd.proxy.address
  end

  function ioctls.slot(fd)
    return fd.proxy.slot
  end

  function ioctls.type(fd)
    return fd.proxy.type
  end

  function provider:ioctl(fd, method, ...)
    checkArg(1, fd, "table")
    checkArg(2, method, "string")

    if fd.iterator then return nil, k.errno.EBADF end

    if ioctls[method] then
      return ioctls[method](fd, ...)
    else
      return nil, k.errno.ENOTTY
    end
  end

  function provider:opendir(path)
    checkArg(1, path, "string")
    local segments = k.split_path(path)
    if #segments > 1 then return nil, k.errno.ENOENT end
    if #segments == 0 then
      local types, _types = {}, {}

      for _, ctype in component.list() do
        if type(ctype) == "string" then _types[ctype] = true end
      end
      for ctype in pairs(_types) do types[#types+1] = ctype end

      local i = 0
      return { iterator = function()
        i = i + 1
        return types[i]
      end }
    else
      return { iterator = component.list(segments[1], true) }
    end
  end

  function provider:readdir(dirfd)
    checkArg(1, dirfd, "table")
    if not dirfd.iterator then return nil, k.errno.EBADF end
    return { inode = -1, name = dirfd.iterator() }
  end

  function provider:close() end

  k.mkdir("/sys/component")
  k.mount(provider, "/sys/component")
end
