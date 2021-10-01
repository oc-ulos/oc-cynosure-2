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
    local node, longest = nil, 0
    for _path, _node in pairs(mounts) do
      if path:sub(1, #_path) == _path and #_path > longest then
        longest = #_path
        node = _node
      end
    end
    if not node then
      return nil, k.errno.ENOENT
    end
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

  function k.syscall.mkdir()
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
    fds[n] = {fd = fd, node = node}
    return n
  end

  function k.syscall.read(fd, count)
    checkArg(1, fd, "number")
    checkArg(2, count, "number")
    if not fds[fd] then
      return nil, k.errno.EBADF
    end
    local read = ""
  end

  function k.syscall.write()
  end

  function k.syscall.seek()
  end

  function k.syscall.close()
  end

  function k.syscall.mount(source, target, fstype, mountflags, fsopts)
    checkArg(1, source, "string")
    checkArg(2, target, "string")
    checkArg(3, fstype, "string")
    checkArg(4, mountflags, "table", "nil")
    checkArg(5, fsopts, "table", "nil")
  end

  function k.syscall.mount(target)
    checkArg(1, target, "string")
  end
end
