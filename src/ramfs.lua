--[[
    Template tmpfs object.
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

k.log(k.L_INFO, "src/ramfs")

do
  local _ramfs = {}

  function _ramfs:_resolve(path, parent)
    local segments = k.common.split_path(path)
    local current = self.tree
    
    for i=1, #segments - (parent and 1 or 0), 1 do
      if not current.children then
        return nil, k.errno.ENOTDIR
      elseif current.children[segments[i]] then
        current = current.children[segments[i]]
      else
        return nil, k.errno.ENOENT
      end
    end
    
    return current, parent and segments[#segments]
  end

  function _ramfs:stat(path)
    checkArg(1, path, "string")
    
    local fblk, err = self:_resolve(path)
    if not fblk then
      return nil, err
    end
    
    return {
      ino = -1,
      mode = fblk.mode,
      nlink = fblk.nlink,
      uid = fblk.uid,
      gid = fblk.gid,
      size = fblk.size or #fblk.data,
      blksize = -1,
      blocks = math.ceil(fblk.size / 512),
      atime = fblk.atime,
      mtime = fblk.mtime,
      ctime = fblk.ctime
    }
  end

  function _ramfs:_create(file, ftmode)
    checkArg(1, file, "string")
    checkArg(2, ftmode, "number")

    local parent, name = self:_resolve(file, true)
    if not parent then
      return nil, name
    end

    if parent.children[name] then
      return nil, k.errno.EEXIST
    end

    parent.children[name] = {
      mode = bit32.bor(ftmode,
             k.common.fsmodes.owner_r,
             k.common.fsmodes.owner_w,
             k.common.fsmodes.group_r,
             k.common.fsmodes.other_r),
      uid = k.syscall.getuid() or 0,
      gid = k.syscall.getgid() or 0,
      ctime = os.time(),
      mtime = os.time(),
      atime = os.time(),
      nlink = 1
    }

    if ftmode == k.common.fsmodes.f_directory then
      parent.children[name].children = {}
    else
      parent.children[name].data = ""
    end

    return parent.children[name]
  end

  local fds = {}
  function _ramfs:open(file, flags, mode)
    checkArg(1, file, "string")
    checkArg(2, flags, "table")
    checkArg(3, mode, "number", "nil")
    
    local node, err = self:_resolve(file)
    if not node then
      if flags.creat then
        checkArg(3, mode, "number")
    
        node, err = self:_create(file, k.common.fsmodes.f_regular)
        if not node then
          return nil, err
        end
      else
        return nil, err
      end
    end
    
    local n = #fds + 1
    fds[n] = {
      ptr = 0,
      node = node,
      flags = flags,
      read = (flags.rdwr or flags.rdonly) and node.reader and node.reader(n),
      write = (flags.rdwr or flags.wronly) and node.writer and node.writer(n),
    }
    
    return n
  end

  function _ramfs:read(fd, count)
    checkArg(1, fd, "number")
    checkArg(2, count, "number")
    
    local _fd = fds[fd]
    if not (_fd and (_fd.flags.rdwr or fd.flags.rdonly)) then
      return nil, k.errno.EBADF
    end
    
    if _fd.read then
      return _fd.read(fd, _fd.ptr, count)
    end
    
    if fd.ptr < #fd.data then
      local n = math.min(#fd.data, fd.ptr + count)
      local ret = fd.data:sub(fd.ptr, n)
      fd.ptr = n + 1
      return ret
    end

    return nil
  end

  function _ramfs:write(fd, data)
    checkArg(1, fd, "number")
    checkArg(2, data, "string")
    
    local _fd = fds[fd]
    if not (_fd and (_fd.flags.rdwr or fd.flags.wronly)) then
      return nil, k.errno.EBADF
    end
    
    if _fd.write then
      return _fd.write(fd, _fd.ptr, data)
    end
    
    if fd.ptr == #fd.data then
      fd.data = fd.data .. data
      fd.ptr = #fd.data
    else
      fd.data = fd.data:sub(0, fd.ptr) .. data .. fd.data:sub(fd.ptr+1)
    end
    
    return true
  end

  function _ramfs:seek(fd, whence, offset)
    checkArg(1, fd, "number")
    checkArg(2, whence, "string")
    checkArg(3, offset, "number")
    
    local _fd = fds[fd]
    if not _fd then
      return nil, k.errno.EBADF
    end
    
    if _fd.seek then
      return _fd.seek(fd, _fd.ptr, whence, offset)
    end
    
    whence = (whence == "set" and 0)
          or (whence == "cur" and _fd.ptr)
          or (whence == "end" and #_fd.data)
    
    if whence + offset > #_fd.data then
      return nil, k.errno.EOVERFLOW
    end
    
    _fd.ptr = whence + offset
    return _fd.ptr
  end

  function _ramfs:close(fd)
    checkArg(1, fd, "number")
    
    if not fds[fd] then
      return nil, k.errno.EBADF
    end
    
    if fds[fd].close then
      fds[fd].close(fd, fds[fd].ptr)
    end
    
    fds[fd] = nil
    return true
  end

  function _ramfs:mkdir(path, mode)
    checkArg(1, path, "string")
    checkArg(2, mode, "number")
    return self:_create(path, bit32.bor(mode, k.common.fsmodes.f_directory))
  end

  function _ramfs:link(old, new)
    checkArg(1, old, "string")
    checkArg(2, new, "string")
    
    local node, err = self:_resolve(old)
    if not node then
      return nil, err
    end
    
    local newnode, name = self:_resolve(new, true)
    if not newnode then
      return nil, err
    end
    
    if not newnode.children then
      return nil, k.errno.ENOTDIR
    end
    
    if newnode.children[name] then
      return nil, k.errno.EEXIST
    end
    
    newnode.children[name] = node
    node.nlink = node.nlink + 1
    return true
  end

  function _ramfs:unlink(path)
    checkArg(1, path, "string")
    
    local parent, name = self:_resolve(path, true)
    if not parent then
      return nil, name
    end
    
    if not parent.children then
      return nil, k.errno.ENOTDIR
    end
    
    if not parent.children[name] then
      return nil, k.errno.ENOENT
    end
    
    parent.children[name].nlink = parent.children[name].nlink - 1
    if parent.children[name].nlink == 0 then
      parent.children[name] = nil
    end
    
    return true
  end

  function _ramfs:list(path)
    checkArg(1, path, "string")
    local node, err = self:_resolve(path)
    if not node then
      return nil, err
    end

    local flist = {}
    for k, v in pairs(node.children) do
      flist[#flist+1] = k
    end

    return flist
  end

  function _ramfs.new(label)
    return setmetatable({
      tree = {children = {}},
      label = label or "ramfs",
    }, {__index = _ramfs})
  end

  k.common.ramfs = _ramfs
end
