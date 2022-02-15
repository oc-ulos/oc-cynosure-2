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
    for k in pairs(mounts) do
      if path:sub(1, #k) == k and #k > #mnt then
        mnt, rem = k, path:sub(#k+1)
      end
    end
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

    if type(node) == "string" then node = component.proxy(node) end
    if not node then return nil, k.errno.ENODEV end

    local proxy = recognize_filesystem(node)
    if not proxy then return nil, k.errno.EUNATCH end

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

  local provider = {}

  function provider.open(file, mode)
    checkArg(1, file, "string")
    checkArg(2, mode, "string")

    local node, remain = path_to_node(file)
    if mode ~= "w" and not node:exists(remain) then
      return nil, k.errno.ENOENT
    end

    local stat = node:stat(remain)

    if not k.process_has_permission(cur_proc(), stat, mode) then
      return nil, k.errno.EACCES
    end

    local fd, err = node:open(remain, mode)
    if not fd then return nil, err end
    local stream = k.fd_from_node(node, fd, mode)
    return { fd = stream, node = stream }
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

  function provider.read(fd, fmt)
    verify_fd(fd)
    checkArg(2, fmt, "string", "number")
    return fd.node:read(fd.fd, fmt)
  end

  function provider.write(fd, data)
    verify_fd(fd)
    checkArg(2, data, "string")
    return fd.node:write(fd.fd, data)
  end

  function provider.flush(fd)
    verify_fd(fd)
    return fd.node:flush(fd.fd)
  end

  function provider.opendir(path)
    checkArg(1, path, "string")

    local node, remain = path_to_node(path)
    if not node:exists(remain) then return nil, k.errno.ENOENT end

    local stat = node:stat(remain)
    if not k.process_has_permission(cur_proc(), stat, "r") then
      return nil, k.errno.EACCES
    end

    local fd, err = node:opendir(remain)
    if not fd then return nil, err end

    return { fd = fd, node = node, dir = true }
  end

  function provider.readdir(dirfd)
    verify_fd(dirfd, true)
    return dirfd.node:readdir(dirfd.fd)
  end

  function provider.close(fd)
    verify_fd(fd, true)
    return fd.node:close(fd.fd)
  end

  function provider.stat(path)
    checkArg(1, path, "string")
    local node, remain = path_to_node(path)
    return node:stat(remain)
  end

  function provider.mkdir(path)
    checkArg(1, path, "string")
    local node, remain = path_to_node(path)
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

  function provider.link(source, dest)
    checkArg(1, source, "string")
    checkArg(2, dest, "string")

    local node, sremain = path_to_node(source)
    local _node, dremain = path_to_node(dest)

    if _node ~= node then return nil, k.errno.EXDEV end
    if node:exists(dremain) then return nil, k.errno.EEXIST end

    local segments = k.split_path(dremain)
    local parent = "/" .. table.concat(segments, "/", 1, #segments - 1)
    local stat = node:stat(parent)

    if not k.process_has_permission(cur_proc(), stat, "w") then
      return nil, k.errno.EACCES
    end

    return node:link(sremain, dremain)
  end

  function provider.unlink(path)
    checkArg(1, path, "string")
    local node, remain = path_to_node(path)
    if not node:exists(remain) then return nil, k.errno.ENOENT end

    local segments = k.split_path(remain)
    local parent = "/" .. table.concat(segments, "/", 1, #segments - 1)
    local stat = node:stat(parent)

    if not k.process_has_permission(cur_proc(), stat, "w") then
      return nil, k.errno.EACCES
    end

    return node:unlink(remain)
  end

  function provider.chmod(path, mode)
    checkArg(1, path, "string")
    checkArg(2, mode, "number")
    local node, remain = path_to_node(path)
    if not node:exists(remain) then return nil, k.errno.ENOENT end

    local stat = node:stat(remain)
    if not k.process_has_permission(cur_proc(), stat, "w") then
      return nil, k.errno.EACCES
    end

    -- only preserve the lower 12 bits
    mode = bit32.band(mode, 0x1FF)
    return node:chmod(remain, mode)
  end

  function provider.chown(path, uid, gid)
    checkArg(1, path, "string")
    checkArg(2, uid, "number")
    checkArg(3, gid, "number")
    local node, remain = path_to_node(path)
    if not node:exists(remain) then return nil, k.errno.ENOENT end

    local stat = node:stat(remain)
    if not k.process_has_permission(cur_proc(), stat, "w") then
      return nil, k.errno.EACCES
    end

    return node:chown(remain, uid, gid)
  end

  k.register_scheme("file", provider)
end

--@[{bconf.FS_MANAGED == 'y' and '#include "src/fs/managed.lua"' or ''}]
--@[{bconf.FS_SFS == 'y' and '#include "src/fs/simplefs.lua"' or ''}]
--#include "src/fs/rootfs.lua"
