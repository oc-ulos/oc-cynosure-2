--[[
  procfs
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

printk(k.L_INFO, "fs/proc")

do
  local provider = {}

  local function path_to_attr(path)
    local pid, attr = path:match("^/?([^/]*)/?([^/]*)$")
    if pid == "self" then pid = tostring(k.current_process().pid) end
    return pid, attr
  end

  local files = {self = true}

  function provider:exists(path)
    checkArg(1, path, "string")

    local pid, attr = path_to_attr(path)
    if #pid == 0 then return true end

    if files[pid] and #attr == 0 then return true end
    if files[pid] and #attr > 0 then return false end

    pid = tonumber(pid)
    if not pid then return false end

    local proc = k.get_process(pid)
    if not proc then return false end

    local attr = proc[attr]
    -- TODO: support more than two levels so it supports e.g. `proc.fds`
    if type(attr) == "table" then return false end

    return #attr == 0 or not not attr
  end

  function provider:stat(path)
    checkArg(1, path, "string")
    if not self:exists(path) then return nil, k.errno.ENOENT end

    local pid, attr = path_to_attr(path)

    if #pid == 0 or files[pid] then
      return {
        dev = -1, ino = -1, mode = 0x41FF, nlink = 1, uid = 0, gid = 0,
        rdev = -1, size = 0, blksize = 2048
      }
    end

    pid = tonumber(pid)
    local proc = k.get_process(pid)

    return {
      dev = -1, ino = -1, mode = #attr == 0 and 0x61FF or 0x41FF, nlink = 1,
      uid = proc.uid, gid = proc.gid, rdev = -1, size = 0, blksize = 2048
    }
  end

  local function to_fd(dat)
    dat = tostring(dat)
    local idx = 0
    return k.fd_from_rwf(function(n)
      local nidx = math.min(#dat, idx + n)
      local chunk = dat:sub(idx, nidx)
      idx = nidx
      return (#chunk > 0 or n == 0) and chunk
    end)
  end

  function provider:open(path)
    checkArg(1, path, "string")
    if not self:exists(path) then return nil, k.errno.ENOENT end

    local pid, attr = path_to_attr(path)

    if files[pid] then
      return { file = files[pid] }
    elseif #attr > 0 then
      return { file = to_fd(k.get_process(tonumber(pid))[attr]) }
    else
      return nil, k.errno.EISDIR
    end
  end

  function provider:opendir(path)
    checkArg(1, path, "string")
    if not self:exists(path) then return nil, k.errno.ENOENT end

    local pid, attr = path_to_attr(path)

    if files[pid] then
      return nil, k.errno.ENOTDIR
    elseif #attr > 0 then
      return nil, k.errno.ENOTDIR
    elseif #pid > 0 then
      local flist = {}

      local proc = k.get_process(tonumber(pid))

      for k, v in pairs(proc) do
        if type(v) ~= "table" then
          flist[#flist+1] = k
        end
      end

      return { i = 0, files = flist }
    else
      local flist = {}

      for k in pairs(files) do
        flist[#flist+1] = k
      end

      for _, ppid in pairs(k.get_pids()) do
        flist[#flist+1] = tostring(ppid)
      end

      return { i = 0, files = flist }
    end
  end

  function provider:readdir(dirfd)
    checkArg(1, dirfd, "table")

    if dirfd.closed then return nil, k.errno.EBADF end
    if not (dirfd.i and dirfd.files) then return nil, k.errno.EBADF end

    dirfd.i = dirfd.i + 1

    if dirfd.files[dirfd.i] then
      return { inode = -1, name = dirfd.files[dirfd.i] }
    end
  end

  function provider:read(fd)
    checkArg(1, fd, "table")

    if fd.closed then return nil, k.errno.EBADF end
    if not fd.file then return nil, k.errno.EBADF end

    return fd.file:read()
  end

  function provider:close(fd)
    checkArg(1, fd, "table")
    fd.closed = true
  end

  return provider
end
