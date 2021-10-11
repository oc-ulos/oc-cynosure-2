-- main kernel source file --

_G.k = { state = {}, common = {} }
-- versioning --

do
  k._VERSION = {
    major = "2",
    minor = "0",
    patch = "0",
    build_host = "pangolin",
    build_user = "ocawesome101",
    build_name = "default"
  }
  _G._OSVERSION = string.format("Cynosure %s.%s.%s-%s",
    k._VERSION.major, k._VERSION.minor, k._VERSION.patch, k._VERSION.build_name)
end
-- kernel command line parsing --

do
  k.cmdline = {}

  local _args = table.pack(...)
  k.state.cmdline = table.concat(_args, " ", 1, _args.n)
  for i, arg in ipairs(_args) do
    local key, val = arg, true
    if arg:find("=") then
      key, val = arg:match("^(.-)=(.+)$")
      if val == "true" then val = true
      elseif val == "false" then val = false
      else val = tonumber(val) or val end
    end
    local ksegs = {}
    for ent in key:gmatch("[^%.]+") do
      ksegs[#ksegs+1] = ent
    end
    local cur = k.cmdline
    for i=1, #ksegs-1, 1 do
      k.cmdline[ksegs[i]] = k.cmdline[ksegs[i]] or {}
      cur = k.cmdline[ksegs[i]]
    end
    cur[ksegs[#ksegs]] = val
  end
end
-- logger stub --

-- early boot logger --

do
  local gpu, screen = component.list("gpu", true)(),
    component.list("screen", true)()

  k.logio = {y = 1}

  local time = computer.uptime()

  if gpu and screen then
    gpu = component.proxy(gpu)
    gpu.bind(screen)
    local w, h = gpu.maxResolution()
    gpu.setResolution(w, h)
    function k.logio:write(msg)
      if k.logio.y > h then
        gpu.copy(1, 1, w, h, 0, -1)
        gpu.fill(1, h, w, 1, " ")
      end
      gpu.set(1, k.logio.y, (msg:gsub("\n","")))
      k.logio.y = k.logio.y + 1
    end
  else
    function k.logio.write() end
  end

  k.cmdline.loglevel = tonumber(k.cmdline.loglevel) or 8
  
  function k.log(l, ...)
    local args = table.pack(...)
    if type(l) == "string" then table.insert(args, 1, l) l = 1 end
    local msg = ""
    for i=1, args.n, 1 do
      msg = msg .. (i > 1 and i < args.n and " " or "") .. tostring(args[i])
    end
    if l <= k.cmdline.loglevel then
      k.logio:write(msg, "\n")
    end
    return true
  end

  k.L_EMERG = 0
  k.L_ALERT = 1
  k.L_CRIT = 2
  k.L_ERR = 3
  k.L_WARNING = 4
  k.L_NOTICE = 5
  k.L_INFO = 6
  k.L_DEBUG = 7

  k.log(k.L_NOTICE, string.format("%s (%s@%s) on %s", _OSVERSION,
    k._VERSION.build_user, k._VERSION.build_host, _VERSION))

  if #k.state.cmdline > 0 then
    k.log(k.L_INFO, "Command line:", k.state.cmdline)
  end
end

do
  function k.panic(reason)
    k.log(k.L_EMERG, "============ kernel panic ============")
    k.log(k.L_EMERG, reason)
    for line in debug.traceback():gmatch("[^\n]+") do
      k.log(k.L_EMERG, (line:gsub("\t", "  ")))
    end
    k.log(k.L_EMERG, "======================================")
  end

  local klogo = [[
   ______                                     
  / ____/_  ______  ____  _______  __________ 
 / /   / / / / __ \/ __ \/ ___/ / / / ___/ _ \
/ /___/ /_/ / / / / /_/ (__  ) /_/ / /  /  __/
\____/\__, /_/ /_/\____/____/\__,_/_/   \___/
     /____/  Stable.  Reliable.  Featureful.

  ]]
  for line in klogo:gmatch("[^\n]+") do
    k.log(k.L_EMERG, line)
  end
end

-- wrap checkArg --

do
  function _G.checkArg(n, have, ...)
    have = type(have)

    local function check(want, ...)
      if not want then
        return false
      else
        return have == want or defs[want] == have or check(...)
      end
    end

    if type(n) == "number" then n = string.format("#%d", n)
    else n = "'"..tostring(n).."'" end
    if not check(...) then
      local name = debug.getinfo(3, 'n').name
      local msg
      if name then
         msg = string.format("bad argument %s to '%s' (%s expected, got %s)",
          n, name, table.concat(table.pack(...), " or "), have)
      else
        msg = string.format("bad argument %s (%s expected, got %s)", n,
          table.concat(table.pack(...), " or "), have)
      end
      error(msg, 2)
    end
  end
end
-- all posible values for errno --

do
  k.errno = {
    EPERM = "Operation not permitted",
    ENOENT = "No such file or directory",
    ESRCH = "No such process",
    EINTR = "Interrupted system call",
    EIO = "Input/output error",
    ENXIO = "No such device or address",
    EBIG = "Argument list too long",
    ENOEXEC = "Exec format error",
    EBADF = "Bad file descriptor",
    ECHILD = "No child processes",
    EAGAIN = "Resource temporarily unavailable",
    ENOMEM = "Cannot allocate memory",
    EACCES = "Permission denied",
    EFAULT = "Bad address",
    ENOTBLK = "Block device required",
    EBUSY = "Device or resource busy",
    EEXIST = "File exists",
    EXDEV = "Invalid cross-device link",
    ENODEV = "No such device",
    ENOTDIR = "Not a directory",
    EISDIR = "Is a directory",
    EINVAL = "Invalid argument",
    ENFILE = "Too many open files in system",
    EMFILE = "Too many open files",
    ENOTTY = "Inappropriate ioctl for device",
    ETXTBSY = "Text file busy",
    EFBIG = "File too large",
    ENOSPC = "No space left on device",
    ESPIPE = "Illegal seek",
    EROFS = "Read-only file system",
    EMLINK = "Too many links",
    EPIPE = "Broken pipe",
    EDOM = "Numerical argument out of domain",
    ERANGE = "Numerical result out of range",
    EDEADLK = "Resource deadlock avoided",
    ENAMETOOLONG = "File name too long",
    ENOLCK = "No locks available",
    ENOSYS = "Function not implemented",
    ENOTEMPTY = "Directory not empty",
    ELOOP = "Too many levels of symbolic links",
    EWOULDBLOCK = "Resource temporarily unavailable",
    ENOMSG = "No message of desired type",
    EIDRM = "Identifier removed",
    ECHRNG = "Channel number out of range",
    ELNSYNC = "Level not synchronized",
    ELHLT = "Level halted",
    ELRST = "Level reset",
    ELNRNG = "Link number out of range",
    EUNATCH = "Protocol driver not attached",
    ENOCSI = "No CSI structure available",
    ELHLT = "Level halted",
    EBADE = "Invalid exchange",
    EBADR = "Invalid request descriptor",
    EXFULL = "Exchange full",
    ENOANO = "No anode",
    EBADRQC = "Invalid request code",
    EBADSLT = "Invalid slot",
    EDEADLOCK = "Resource deadlock avoided",
    EBFONT = "Bad font file format",
    ENOSTR = "Device not a stream",
    ENODATA = "No data available",
    ETIME = "Timer expired",
    ENOSR = "Out of streams resources",
    ENONET = "Machine is not on the network",
    ENOPKG = "Package not installed",
    EREMOTE = "Object is remote",
    ENOLINK = "Link has been severed",
    EADV = "Advertise error",
    ESRMNT = "Srmount error",
    ECOMM = "Communication error on send",
    EPROTO = "Protocol error",
    EMULTIHOP = "Multihop attempted",
    EDOTDOT = "RFS specific error",
    EBADMSG = "Bad message",
    EOVERFLOW = "Value too large for defined data type",
    ENOTUNIQ = "Name not unique on network",
    EBADFD = "File descriptor in bad state",
    EREMCHG = "Remote address changed",
    ELIBACC = "Can not access a needed shared library",
    ELIBBAD = "Accessing a corrupted shared library",
    ELIBSCN = ".lib section in a.out corrupted",
    ELIBMAX = "Attempting to link in too many shared libraries",
    ELIBEXEC = "Cannot exec a shared library directly",
    EILSEQ = "Invalid or incomplete multibyte or wide character",
    ERESTART = "Interrupted system call should be restarted",
    ESTRPIPE = "Streams pipe error",
    EUSERS = "Too many users",
    ENOTSOCK = "Socket operation on non-socket",
    EDESTADDRREQ = "Destination address required",
    EMSGSIZE = "Message too long",
    EPROTOTYPE = "Protocol wrong type for socket",
    ENOPROTOOPT = "Protocol not available",
    EPROTONOSUPPORT = "Protocol not supported",
    ESOCKTNOSUPPORT = "Socket type not supported",
    EOPNOTSUPP = "Operation not supported",
    EPFNOSUPPORT = "Protocol family not supported",
    EAFNOSUPPORT = "Address family not supported by protocol",
    EADDRINUSE = "Address already in use",
    EADDRNOTAVAIL = "Cannot assign requested address",
    ENETDOWN = "Network is down",
    ENETUNREACH = "Network is unreachable",
    ENETRESET = "Network dropped connection on reset",
    ECONNABORTED = "Software caused connection abort",
    ECONNRESET = "Connection reset by peer",
    ENOBUFS = "No buffer space available",
    EISCONN = "Transport endpoint is already connected",
    ENOTCONN = "Transport endpoint is not connected",
    ESHUTDOWN = "Cannot send after transport endpoint shutdown",
    ETOOMANYREFS = "Too many references: cannot splice",
    ETIMEDOUT = "Connection timed out",
    ECONNREFUSED = "Connection refused",
    EHOSTDOWN = "Host is down",
    EHOSTUNREACH = "No route to host",
    EALREADY = "Operation already in progress",
    EINPROGRESS = "Operation now in progress",
    ESTALE = "Stale file handle",
    EUCLEAN = "Structure needs cleaning",
    ENOTNAM = "Not a XENIX named type file",
    ENAVAIL = "No XENIX semaphores available",
    EISNAM = "Is a named type file",
    EREMOTEIO = "Remote I/O error",
    EDQUOT = "Disk quota exceeded",
    ENOMEDIUM = "No medium found",
    EMEDIUMTYPE = "Wrong medium type",
    ECANCELED = "Operation canceled",
    ENOKEY = "Required key not available",
    EKEYEXPIRED = "Key has expired",
    EKEYREVOKED = "Key has been revoked",
    EKEYREJECTED = "Key was rejected by service",
    EOWNERDEAD = "Owner died",
    ENOTRECOVERABLE = "State not recoverable",
    ERFKILL = "Operation not possible due to RF-kill",
    EHWPOISON = "Memory page has hardware error",
    ENOTSUP = "Operation not supported",
  }
end
-- system call registry --

do
  k.syscall = {}

  local mutices = {}

  local _mut = {}
  function _mut:lock()
    repeat
      coroutine.yield()
    until not self.locked
    self.locked = k.state.sched_current
    return true
  end

  function _mut:unlock()
    self.locked = false
  end

  function k.syscall.lockmutex()
  end

  function k.syscall.unlockmutex()
  end
end
-- Cynosure kernel scheduler --

-- processes --

do
  local _proc = {}

  k.state.pid = 0
  k.state.processes = {}

  function _proc:resume(...)
    for i, thd in ipairs(self.threads) do
    end
  end

  function _proc:new(parent, func, cmdline)
    parent = parent or {}
    k.state.pid = k.state.pid + 1
    local new = setmetatable({
      -- Process ID.
      pid = k.state.pid + 1,
      -- Parent process's PID.
      ppid = parent.pid or 0,
      -- Open file handles.
      handles = {
        [0] = parent.handles[0],
        [1] = parent.handles[1],
        [2] = parent.handles[2]
      },
      -- Total CPU time consumed by the process.
      cputime = 0,
      -- Whether the process is stopped.
      stopped = false,
      -- Session the process belongs to.
      sid = parent.sid or 0,
      -- Process group the process belongs to.
      pgid = parent.pgid or 0,
      -- Real user ID (process owner).
      uid = parent.uid or 0,
      -- Real group ID
      gid = parent.gid or 0,
      -- Effective user ID (for shared resources
      -- (e.g. events) and file permissions)
      euid = parent.euid or 0,
      -- Effective group ID
      egid = parent.egid or 0,
      -- saved set-user-ID
      suid = parent.suid or 0,
      -- saved set-group-ID
      sgid = parent.sgid or 0,
      -- file mode creation mask
      umask = 255,
      -- current directory relative to root
      cwd = parent.cwd or "/",
      -- root directory
      root = parent.root or "/",
      threads = {
        [1] = {
          errno = 0,
          sigmask = 0,
          tid = 1,
          coroutine = coroutine.create(func)
        }
      },
    }, {__index = _proc, __call = _proc.resume})
    
    k.state.processes[k.state.pid] = new

    return new
  end


  function k.syscall.execf()
  end
end
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
    checkArg(1, path, "string")
    local node, rpath = find_node(path)
    if not node then
      return nil, rpath
    end
    return node:mkdir(rpath)
  end

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
-- base ramfs node --

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
      mode = ftmode |
             k.common.fsmodes.owner_r |
             k.common.fsmodes.owner_w |
             k.common.fsmodes.group_r |
             k.common.fsmodes.other_r,
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
    return self:_create(path, mode | k.common.fsmodes.f_directory)
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
-- sysfs --

do
  k.state.sysfs = k.common.ramfs.new("sysfs")
  k.state.mount_sources.sysfs = k.state.sysfs
end
-- procfs --

do
  k.state.procfs = k.common.ramfs.new("procfs")
  k.state.mount_sources.procfs = k.state.procfs
end
-- devfs --

do
  k.state.devfs = k.common.ramfs.new("devfs")
  k.state.mount_sources.devfs = k.state.devfs
end
-- CEX loading --

do
  local magic = 0x43796e6f
  local flags = {
    lua53 = 0x1,
    static = 0x2,
    bootable = 0x4,
    executable = 0x8,
    library = 0x10
  }

  local function read_file(file)
    local handle, err = k.syscalls.open(file, {
      rdonly = true
    })
    
    if not handle then
      return nil, err
    end
    
    local data = k.syscalls.read(handle, math.huge)
    k.syscalls.close(handle)
    
    return data
  end

  local _flags = {
    lua53 = 0x1,
    static = 0x2,
    boot = 0x4,
    exec = 0x8,
    library = 0x10,
  }

  local function parse_cex(str)
    local header, str = k.util.pop(str, 4)
    if header ~= "onyC" then
      return nil, "invalid magic number"
    end

    local flags, str = k.util.pop(str, 1)
    flags = flags:byte()
    local osid, str = k.util.pop(str, 1)
    osid = osid:byte()

    if osid ~= 0 and isod ~= 255 then
      return nil, "bad OSID"
    end
  end

  local function load_cex(file)
    return parse_cex(read_file(file))
  end
end
while true do computer.pullSignal() end
