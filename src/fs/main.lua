--[[
    Main file system code
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

printk(k.L_INFO, "fs/main")

---@alias fs_recognizer fun(component: table): table
--#include "src/fs/permissions.lua"

do
  ---@type fs_recognizer[]
  k.fstypes = {}

  -- fs mode constants
  k.FS_FIFO   = 0x1000 -- FIFO
  k.FS_CHRDEV = 0x2000 -- character device
  k.FS_DIR    = 0x4000 -- directory
  k.FS_BLKDEV = 0x6000 -- block device
  k.FS_REG    = 0x8000 -- regular file
  k.FS_SYMLNK = 0xA000 -- symbolic link
  k.FS_SOCKET = 0xC000 -- socket

  --- Registers a filesystem type
  ---@param name string
  ---@param recognizer fs_recognizer
  function k.register_fstype(name, recognizer)
    checkArg(1, name, "string")
    checkArg(2, recognizer, "function")
    if k.fstypes[name] then
      panic("attempted to double-register fstype " .. name)
    end
    k.fstypes[name] = recognizer
    return true
  end

  local function recognize_filesystem(component)
    for _, recognizer in pairs(k.fstypes) do
      local fs = recognizer(component)
      if fs then return fs end
    end
    return nil
  end

  local mounts = {}

  function k.split_path(path)
    checkArg(1, path, "string")
    local segments = {}
    for piece in path:gmatch("[^/\\]+") do
      if piece == ".." then
        segments[#segments] = nil
      elseif piece ~= "." then
        segments[#segments+1] = piece
      end
    end
    return segments
  end

  function k.clean_path(path)
    checkArg(1, path, "string")
    return "/" .. table.concat(k.split_path(path), "/")
  end

  function k.check_absolute(path)
    checkArg(1, path, "string")
    if path:sub(1, 1) == "/" then
      return "/" .. table.concat(k.split_path(path), "/")
    else
      local current = k.current_process()
      if current then
        return "/" .. table.concat(k.split_path(current.cwd .. "/" .. path),
          "/")
      else
        return "/" .. table.concat(k.split_path(path), "/")
      end
    end
  end

  local function path_to_node(path)
    path = k.check_absolute(path)

    local mnt, rem = "/", path
    for m in pairs(mounts) do
      if path:sub(1, #m) == m and #m > #mnt then
        mnt, rem = m, path:sub(#m+1)
      end
    end

    if #rem == 0 then rem = "/" end

    --printk(k.L_DEBUG, "path_to_node(%s) = %s, %s",
    --  path, tostring(mnt), tostring(rem))

    return mounts[mnt], rem or "/"
  end

  local default_proc = {euid = 0, gid = 0}
  local function cur_proc()
    return k.current_process and k.current_process() or default_proc
  end

  --- Mounts a drive or filesystem at the given path.
  ---@param node table|string The component proxy or address
  ---@param path string The path at which to mount it
  function k.mount(node, path)
    checkArg(1, node, "table", "string")
    checkArg(2, path, "string")

    if cur_proc().euid ~= 0 then return nil, k.errno.EACCES end

    local proxy = node
    if type(node) == "string" then
      node = component.proxy(node)
      proxy = recognize_filesystem(node)
      if not proxy then return nil, k.errno.EUNATCH end
    end
    if not node then return nil, k.errno.ENODEV end

    path = k.clean_path(path)
    mounts[path] = proxy

    if proxy.mount then proxy:mount(path) end

    return true
  end

  --- Unmounts something from the given path
  ---@param path string
  function k.unmount(path)
    checkArg(1, path, "string")

    if cur_proc().euid ~= 0 then return nil, k.errno.EACCES end

    path = k.clean_path(path)
    if not mounts[path] then
      return nil, k.errno.EINVAL
    end

    local node = mounts[path]
    if node.unmount then
      node:unmount(path)
    end

    mounts[path] = nil
    return true
  end

  function k.open(file, mode)
    checkArg(1, file, "string")
    checkArg(2, mode, "string")

    local node, remain = path_to_node(file)
    if not node.open then return nil, k.errno.ENOSYS end
    if mode ~= "w" and not node:exists(remain) then
      return nil, k.errno.ENOENT
    end

    if mode ~= "w" then
      local stat = node:stat(remain)

      if not k.process_has_permission(cur_proc(), stat, mode) then
        return nil, k.errno.EACCES
      end
    end

    local fd, err = node:open(remain, mode)
    if not fd then return nil, err end
    local stream = k.fd_from_node(node, fd, mode)
    if node.default_mode then stream:ioctl("setvbuf", node.default_mode) end
    return { fd = stream, node = stream, refs = 1 }
  end

  local function verify_fd(fd, dir)
    checkArg(1, fd, "table")
    if not (fd.fd and fd.node) then
      error("bad argument #1 (file descriptor expected)", 2)
    end
    -- Casts both sides to booleans to ensure correctness when comparing
    if (not not fd.dir) ~= (not not dir) then
      error("bad argument #1 (cannot supply dirfd where fd is required, or vice versa)", 2)
    end
  end

  function k.ioctl(fd, op, ...)
    verify_fd(fd)
    checkArg(2, op, "string")
    if not fd.node.ioctl then return nil, k.errno.ENOSYS end
    return fd.node.ioctl(fd.fd, op, ...)
  end

  function k.read(fd, fmt)
    verify_fd(fd)
    checkArg(2, fmt, "string", "number")
    if not fd.node.read then return nil, k.errno.ENOSYS end
    return fd.node.read(fd.fd, fmt)
  end

  function k.write(fd, data)
    verify_fd(fd)
    checkArg(2, data, "string")
    if not fd.node.write then return nil, k.errno.ENOSYS end
    return fd.node.write(fd.fd, data)
  end

  function k.seek(fd, whence, offset)
    verify_fd(fd)
    checkArg(2, whence, "string")
    checkArg(3, offset, "number")
    return fd.node.seek(fd.fd, whence, offset)
  end

  function k.flush(fd)
    if fd.dir then return end -- cannot flush dirfd
    verify_fd(fd)
    if not fd.node.flush then return nil, k.errno.ENOSYS end
    return fd.node.flush(fd.fd)
  end

  function k.opendir(path)
    checkArg(1, path, "string")

    path = k.check_absolute(path)

    local node, remain = path_to_node(path)
    if not node.opendir then return nil, k.errno.ENOSYS end
    if not node:exists(remain) then return nil, k.errno.ENOENT end

    local stat = node:stat(remain)
    if not k.process_has_permission(cur_proc(), stat, "r") then
      return nil, k.errno.EACCES
    end

    local fd, err = node:opendir(remain)
    if not fd then return nil, err end

    local _extra = {}
    local extra = {}

    local base = k.split_path(path)
    for m in pairs(mounts) do
      if m:sub(1, #path) == path then
        local segments = k.split_path(m)
        local nexts = segments[#base + 1]
        if nexts then
          if not _extra[nexts] then extra[#extra+1] = nexts end
          _extra[nexts] = true
        end
      end
    end

    return { fd = fd, node = node, dir = true, refs = 1,
      extra = extra, eindex = 1 }
  end

  function k.readdir(dirfd)
    verify_fd(dirfd, true)
    if not dirfd.node.readdir then return nil, k.errno.ENOSYS end
    if dirfd.extra[dirfd.eindex] then
      dirfd.eindex = dirfd.eindex + 1
      return { inode = -1, name = dirfd.extra[dirfd.eindex - 1] }
    end
    return dirfd.node:readdir(dirfd.fd)
  end

  function k.close(fd)
    verify_fd(fd, fd.dir) -- close closes either type of fd
    fd.refs = fd.refs - 1
    if fd.refs == 0 then
      if not fd.node.close then return nil, k.errno.ENOSYS end
      if fd.dir then return fd.node:close(fd.fd) end
      return fd.node.close(fd.fd)
    end
  end

  function k.stat(path)
    checkArg(1, path, "string")
    local node, remain = path_to_node(path)
    if not node.stat then return nil, k.errno.ENOSYS end
    return node:stat(remain)
  end

  function k.mkdir(path)
    checkArg(1, path, "string")
    local node, remain = path_to_node(path)
    if not node.mkdir then return nil, k.errno.ENOSYS end
    if node:exists(remain) then return nil, k.errno.EEXIST end

    local segments = k.split_path(remain)
    local parent = "/" .. table.concat(segments, "/", 1, #segments - 1)
    local stat = node:stat(parent)

    if not stat then return nil, k.errno.ENOENT end
    if not k.process_has_permission(cur_proc(), stat, "w") then
      return nil, k.errno.EACCES
    end

    return node:mkdir(remain)
  end

  function k.link(source, dest)
    checkArg(1, source, "string")
    checkArg(2, dest, "string")

    local node, sremain = path_to_node(source)
    local _node, dremain = path_to_node(dest)

    if _node ~= node then return nil, k.errno.EXDEV end
    if not node.link then return nil, k.errno.ENOSYS end
    if node:exists(dremain) then return nil, k.errno.EEXIST end

    local segments = k.split_path(dremain)
    local parent = "/" .. table.concat(segments, "/", 1, #segments - 1)
    local stat = node:stat(parent)

    if not k.process_has_permission(cur_proc(), stat, "w") then
      return nil, k.errno.EACCES
    end

    return node:link(sremain, dremain)
  end

  function k.unlink(path)
    checkArg(1, path, "string")
    local node, remain = path_to_node(path)
    if not node.unlink then return nil, k.errno.ENOSYS end
    if not node:exists(remain) then return nil, k.errno.ENOENT end

    local segments = k.split_path(remain)
    local parent = "/" .. table.concat(segments, "/", 1, #segments - 1)
    local stat = node:stat(parent)

    if not k.process_has_permission(cur_proc(), stat, "w") then
      return nil, k.errno.EACCES
    end

    return node:unlink(remain)
  end

  function k.chmod(path, mode)
    checkArg(1, path, "string")
    checkArg(2, mode, "number")
    local node, remain = path_to_node(path)
    if not node.chmod then return nil, k.errno.ENOSYS end
    if not node:exists(remain) then return nil, k.errno.ENOENT end

    local stat = node:stat(remain)
    if not k.process_has_permission(cur_proc(), stat, "w") then
      return nil, k.errno.EACCES
    end

    -- only preserve the lower 12 bits
    mode = bit32.band(mode, 0x1FF)
    return node:chmod(remain, mode)
  end

  function k.chown(path, uid, gid)
    checkArg(1, path, "string")
    checkArg(2, uid, "number")
    checkArg(3, gid, "number")
    local node, remain = path_to_node(path)
    if not node.chown then return nil, k.errno.ENOSYS end
    if not node:exists(remain) then return nil, k.errno.ENOENT end

    local stat = node:stat(remain)
    if not k.process_has_permission(cur_proc(), stat, "w") then
      return nil, k.errno.EACCES
    end

    return node:chown(remain, uid, gid)
  end
end

--@[{bconf.FS_MANAGED == 'y' and '#include "src/fs/managed.lua"' or ''}]
--@[{bconf.FS_SFS == 'y' and '#include "src/fs/simplefs.lua"' or ''}]
--#include "src/fs/tty.lua"
--@[{bconf.FS_COMPONENT == 'y' and '#include "src/fs/component.lua"' or ''}]
--#include "src/fs/rootfs.lua"
