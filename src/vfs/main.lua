-- a fairly smart filesystem mounting arrangement --

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

    group_r = 0x20
    group_w = 0x10,
    group_x = 0x8,

    other_r = 0x4,
    other_w = 0x2,
    other_x = 0x1
  }

  local mounts = {}

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

  k.common.split_path = split_path
  k.common.clean_path = clean_path

  local function find_node(path)
    path = clean_path(path)
    local node, longest, __path = nil, 0, nil
    for _path, _node in pairs(mounts) do
      if path:sub(1, #_path) == _path and #_path > longest then
        longest = #_path
        node = _node
        __path = path:sub(#_path + 1)
      end
    end
    if not node then
      return nil, k.errno.ENOENT
    end
    return node, __path
  end

  local fds = {}

  function k.syscall.creat(path, mode)
    checkArg(1, path, "string")
    checkArg(2, mode, "number")
    return k.syscall.open(path, {
      creat = true,
      wronly = true,
      trunc = true
    }, mode)
  end

  function k.syscall.mkdir(path)
  end

  function k.syscall.link()
  end

  function k.syscall.open(path, flags, mode)
    checkArg(1, path, "string")
    checkArg(2, flags, "table")
    local fds = k.state.processes[k.syscall.getpid()].fds
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

  function k.syscall.read(fd, count)
    checkArg(1, fd, "number")
    checkArg(2, count, "number")
    local fds = k.state.processes[k.syscall.getpid()].fds
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

  function k.syscall.write(fd, data)
    checkArg(1, fd, "number")
    checkArg(2, data, "string")
    local fds = k.state.processes[k.syscall.getpid()].fds
    if not fds[fd] then
      return nil, k.errno.EBADF
    end
    return fds[fd].node:write(fds[fd].fd, data)
  end

  function k.syscall.seek(fd, whence, offset)
    checkArg(1, fd, "number")
    checkArg(2, whence, "string")
    checkArg(3, offset, "number")
    local fds = k.state.processes[k.syscall.getpid()].fds
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
    local fds = k.state.processes[k.syscall.getpid()].fds
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
    local fds = k.state.processes[k.syscall.getpid()].fds
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
    local fds = k.state.processes[k.syscall.getpid()].fds
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

  function k.syscall.mount(source, target, fstype, mountflags, fsopts)
    checkArg(1, source, "string")
    checkArg(2, target, "string")
    checkArg(3, fstype, "string")
    checkArg(4, mountflags, "table", "nil")
    checkArg(5, fsopts, "table", "nil")
    local node, rest = find_node(target)
  end

  function k.syscall.umount(target)
    checkArg(1, target, "string")
  end
end
