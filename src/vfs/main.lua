--[[
    Cynosure's virtual file system tree implementation.
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
  k.common.fsmodes = {
    f_socket = 0xC000,
    f_symlink = 0xA000,
    f_regular = 0x8000,
    f_blkdev = 0x6000,
    f_directory = 0x2000,
    f_fifo = 0x1000,

    setuid = 0x800,
    setgid = 0x400,
    sticky = 0x200,

    owner_r = 0x100,
    owner_w = 0x80,
    owner_x = 0x40,

    group_r = 0x20,
    group_w = 0x10,
    group_x = 0x8,

    other_r = 0x4,
    other_w = 0x2,
    other_x = 0x1
  }

  local mounts = {}
  k.state.mounts = mounts

  local function split_path(path)
    local segments = {}
    for part in path:gmatch("[^/]+") do
      if part == ".." then
        segments[#segments] = nil
      elseif part ~= "." then
        segments[#segments + 1] = part
      end
    end
    return segments
  end

  local function clean_path(path)
    if path:sub(1,1) ~= "/" then
      path = k.syscall.getcwd() .. "/" .. path
    end
    return "/" .. table.concat(split_path(path), "/")
  end

  local function fsgetpid()
    if not k.state.from_proc then
      return 0
    else
      return k.state.cpid
    end
  end

  k.common.split_path = split_path
  k.common.clean_path = clean_path

  local find_node
  find_node = function(path)
    path = clean_path(path)
    local rpath = ""
    local node, longest, __path = nil, 0, nil
    for _path, _node in pairs(mounts) do
      if path:sub(1, #_path) == _path and #_path > longest then
        longest = #_path
        if type(_node) == "string" then
          node, rpath = find_node(_node)
        else
          node = _node
        end
        __path = path:sub(#_path + 1)
      end
    end
    if not node then
      return nil, k.errno.ENOENT
    end
    return node, clean_path(rpath .. "/" .. __path)
  end

  --@syscall creat
  --@arg path string
  --@arg mode number
  --@shortdesc create a file
  --@startdocs
  -- Creates a regular file at the specified @arg[path].
  --@enddocs
  function k.syscall.creat(path, mode)
    checkArg(1, path, "string")
    checkArg(2, mode, "number")
    return k.syscall.open(path, {
      creat = true,
      wronly = true,
      trunc = true
    }, mode)
  end

  --@syscall mkdir
  --@arg path string
  --@shortdesc create a directory.
  function k.syscall.mkdir(path)
    checkArg(1, path, "string")
    local node, rpath = find_node(path)
    if not node then
      return nil, rpath
    end
    return node:mkdir(rpath)
  end

  --@syscall link
  --@arg path string
  --@arg new string
  --@shortdesc create a link
  function k.syscall.link(path, new)
    checkArg(1, path, "string")
    checkArg(2, new, "string")
    local node, rpath = find_node(path)
    if not node then
      return nil, rpath
    end
    local _node, _rpath = find_node(new)
    if not _node then
      return nil, _rpath
    end
    if node ~= _node then
      return nil, k.errno.EXDEV
    end
    return node:link(rpath, _rpath)
  end

  --@syscall open
  --@arg path string
  --@arg flags table
  --@optarg mode number
  --@return fd number
  --@shortdesc open or create a file
  function k.syscall.open(path, flags, mode)
    checkArg(1, path, "string")
    checkArg(2, flags, "table")
    local fds = k.state.processes[fsgetpid()].fds
    local node, rpath = find_node(path)
    if node and flags.creat and flags.excl then
      return nil, k.errno.EEXIST
    end
    if not node then
      if flags.creat then
        checkArg(3, mode, "number")
        local parent, _rpath = find_node(path:match("(.+)/..-$"))
        if not parent then
          return nil, _rpath
        end
        local fd, err = parent:creat(clean_path(_rpath .. "/"
          .. path:match(".+/(..-)$")), mode)
        if not fd then
          return nil, err
        end
        local n = #fds + 1
        fds[n] = {fd = fd, node = parent}
        return n
      else
        return nil, rpath
      end
    end
    local fd, err = node:open(rpath, flags, mode)
    if not fd then
      return nil, err
    end
    local n = #fds + 1
    fds[n] = {fd = fd, node = node, references = {}}
    return n
  end

  --@syscall read
  --@arg fd number
  --@arg count number
  --@return data string
  --@shortdesc read from a file descriptor
  function k.syscall.read(fd, count)
    checkArg(1, fd, "number")
    checkArg(2, count, "number")
    local fds = k.state.processes[fsgetpid()].fds
    if not fds[fd] then
      return nil, k.errno.EBADF
    end
    local read = ""
    for chunk in function() return
        (count > 0 and fds[fd].node:read(fds[fd].fd, count)) end do
      count = count - #chunk
      read = read .. chunk
    end
    return read
  end

  --@syscall write
  --@arg 
  function k.syscall.write(fd, data)
    checkArg(1, fd, "number")
    checkArg(2, data, "string")
    local fds = k.state.processes[fsgetpid()].fds
    if not fds[fd] then
      return nil, k.errno.EBADF
    end
    return fds[fd].node:write(fds[fd].fd, data)
  end

  function k.syscall.seek(fd, whence, offset)
    checkArg(1, fd, "number")
    checkArg(2, whence, "string")
    checkArg(3, offset, "number")
    local fds = k.state.processes[fsgetpid()].fds
    if not fds[fd] then
      return nil, k.errno.EBADF
    end
    if whence == "set" or whence == "cur" or whence == "end" then
      return nil, k.errno.EINVAL
    end
    return fds[fd].node:seek(fds[fd].fd, whence, offset)
  end

  function k.syscall.dup(fd)
    checkArg(1, fd, "number")
    local fds = k.state.processes[fsgetpid()].fds
    if not fds[fd] then
      return nil, k.errno.EBADF
    end
    fds[fd].references = fds[fd].references + 1
    local n = #fds + 1
    fds[n] = fds[fd]
    return n
  end

  function k.syscall.dup2(fd, nfd)
    checkArg(1, fd, "number")
    checkArg(2, nfd, "number")
    local fds = k.state.processes[fsgetpid()].fds
    if not fds[fd] then
      return nil, k.errno.EBADF
    end
    if nfd == fd then
      return nfd
    end
    if fds[nfd] then
      k.syscall.close(nfd)
    end
    fds[nfd] = fds[fd]
    return true
  end

  function k.syscall.close(fd)
    checkArg(1, fd, "number")
    local fds = k.state.processes[fsgetpid()].fds
    if not fds[fd] then
      return nil, k.errno.EBADF
    end
    fds[fd].references = fds[fd].references - 1
    if fds[fd].references == 0 then
      fds[fd].node:close(fds[fd].fd)
    end
    fds[fd] = nil
    return true
  end

  function k.syscall.listdir(path)
    checkArg(1, path, "string")
    local node, rpath = find_node(path)
    if not node then
      return nil, rpath
    end
    return node:list(rpath)
  end

  k.state.mount_sources = {}
  function k.syscall.mount(source, target, fstype, mountflags, fsopts)
    checkArg(1, source, "string")
    checkArg(2, target, "string")
    checkArg(3, fstype, "string")
    checkArg(4, mountflags, "table", "nil")
    checkArg(5, fsopts, "table", "nil")
    if k.syscall.getuid() ~= 0 then
      return nil, k.errno.EACCES
    end

    mountflags = mountflags or {}
    if source:find("/") then source = clean_path(source) end
    target = clean_path(target)
    
    if mountflags.move then
      if mounts[source] and source ~= "/" then
        mounts[target] = mounts[source]
        mounts[source] = nil
        return true
      else
        return nil, k.errno.EINVAL
      end
    
    else
      
      if k.state.mount_sources[source] then
        local _source, err = k.state.source_handlers[source]()
        
        if not _source then
          return nil, err
        end
        
        source = _source
      end

      if mounts[target] then
        if mountflags.remount then
          mounts[target] = source
        else
          return nil, k.errno.EBUSY
        end
      end
      
      local node, rest = find_node(target)
      if not node then
        return nil, k.errno.ENOENT
      end

      mounts[target] = source

      return true
    end
  end

  function k.syscall.umount(target)
    checkArg(1, target, "string")
    if k.syscall.getuid() ~= 0 then
      return nil, k.errno.EACCES
    end
    target = clean_path(target)
    if mounts[target] then
      for pid, process in pairs(k.state.processes) do
        if clean_path(process.root
            .. "/" .. process.cwd):sub(1, #target) == target then
          return nil, k.errno.EBUSY
        end
      end
      mounts[target] = nil
      return true
    end
    return nil, k.errno.EINVAL
  end
end

--#include "src/fs/main.lua"
