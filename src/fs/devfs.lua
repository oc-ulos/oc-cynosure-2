--[[
  Device fs implementation
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

printk(k.L_INFO, "fs/devfs")

do
  local provider = {}
  -- A table of path -> node.  Doesn't scale super well for lots
  -- of subdirectories, but better than maintaining an N-deep table,
  -- particularly since it supports sub-pseudo-filesystems e.g.
  -- componentfs - and I don't see large devfs trees being common.
  local devices = {}

  k.devfs = {}

  function k.devfs.register_device(path, device)
    checkArg(1, path, "string")
    checkArg(2, device, "table")

    local segments = k.split_path(path)
    if #segments > 1 then
      error("cannot register device in subdirectory '"..path.."' of devfs", 2)
    end

    devices[path] = device

    if path:sub(1,1) ~= "/" then path = "/" .. path end
    printk(k.L_INFO, "devfs: registered device at %s", path)
  end

  k.devfs.register_device("/", {
    opendir = function()
      local devs = {}
      for k in pairs(devices) do if k ~= "/" then devs[#devs+1] = k end end
      return { devs = devs, i = 0 }
    end,
    readdir = function(_, fd)
      fd.i = fd.i + 1
      if fd.devs and fd.devs[fd.i] then
        return { inode = -1, name = fd.devs[fd.i] }
      else
        fd.devs = nil
      end
    end,
    stat = function()
      return { dev = -1, ino = -1, mode = 0x41A4, nlink = 1,
        uid = 0, gid = 0, rdev = -1, size = 0, blksize = 2048,
        atime = 0, ctime = 0, mtime = 0 }
    end
  })

  local function path_to_node(path)
    local segments = k.split_path(path)

    if path == "/" or path == "" then
      return devices[path]
    end

    if not devices[segments[1]] then
      return nil, k.errno.ENOENT
    else
      return devices[segments[1]], table.concat(segments, "/", 2, segments.n)
    end
  end

  k.devfs.lookup = path_to_node

  function provider:exists(path)
    checkArg(1, path, "string")
    return not not path_to_node(path)
  end

  -- The following code is primarily intended to reduce the
  -- amount of LOC, and probably memory usage.
  --
  -- The checks for open, opendir, and ioctl are edge cases
  -- as a result of the kernel's buffering implementation.
  local function autocall(calling, pathorfd, ...)
    checkArg(1, pathorfd, "string", "table")

    if type(pathorfd) == "string" then
      local device, path = path_to_node(pathorfd)
      if not device then return nil, k.errno.ENOENT end
      if not device[calling] then return nil, k.errno.ENOSYS end

      local result, err = device[calling](device, path, ...)

      if not result then return nil, err end

      if result and (calling == "open" or calling == "opendir") then
        return { node = device, fd = result,
          default_mode = result.default_mode }
      else
        return result, err
      end
    else
      if not (pathorfd.node and pathorfd.fd) then
        return nil, k.errno.EBADF
      end

      local device, fd = pathorfd.node, pathorfd.fd
      if not device[calling] then return nil, k.errno.ENOSYS end

      local result, err
      if calling == "ioctl" and not device.is_dev then
        result, err = device[calling](fd, ...)
      else
        result, err = device[calling](device, fd, ...)
      end

      return result, err
    end
  end

  provider.default_mode = "none"

  setmetatable(provider, {__index = function(_, k)
    if k ~= "ioctl" then
      return function(_, ...)
        return autocall(k, ...)
      end
    else
      return function(...)
        return autocall(k, ...)
      end
    end
  end})

  provider.address = "devfs"

  k.register_fstype("devfs", function(x)
    return x == "devfs" and provider
  end)
end

--#include "src/fs/devfs_chardev.lua"
-- TODO
-- #include "src/fs/devfs_blockdev.lua"
