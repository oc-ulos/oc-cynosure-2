--[[
    Provides core system calls
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
--- System calls
-- This page contains all the system calls available under Cynosure 2.
-- @module syscalls
-- @alias k.syscalls

printk(k.L_INFO, "syscalls")

do
  k.syscalls = {}

  function k.perform_system_call(name, ...)
    checkArg(1, name, "string")

    if not k.syscalls[name] then
      return nil, k.errno.ENOSYS
    end

    local result = table.pack(pcall(k.syscalls[name], ...))
    if result[1] then
      table.remove(result, 1)
      result.n = result.n - 1
    end

    --[[ Uncomment for debugging purposes.
    local args = {}
    for _, arg in ipairs(table.pack(...)) do
      if type(arg) == "string" then
        args[#args+1] = string.format("%q",
          arg:gsub("\n", "\\n"):gsub("\t", "\\t"))
      else
        args[#args+1] = tostring(arg)
      end
    end
    local current = k.current_process()
    printk(k.L_DEBUG, "%s[%d]: syscall %s(%s) => %s, %s", current.cmdline[0],
      current.pid, name, table.concat(args, ", "),
      (type(result[1]) == "string" and string.format("%q", result[1]) or tostring(result[1])):gsub("\n", "n"),
      (type(result[2]) == "string" and string.format("%q", result[2]) or tostring(result[2])):gsub("\n", "n"))--]]

    return table.unpack(result, 1, result.n)
  end

  ------
  -- This page contains all the system calls available under Cynosure 2.
  -- All system calls return `nil` and an errno value on failure.
  -- System calls are made using `coroutine.yield` like this: `coroutine.yield("syscall", "isatty", 2)`.

  --- Open a file with the given mode.
  -- Returns a file descriptor.
  -- @function open
  -- @tparam string file The file to open
  -- @tparam string mode The mode, similar to those given to `io`
  -- @treturn number The file descriptor
  function k.syscalls.open(file, mode)
    checkArg(1, file, "string")
    checkArg(2, mode, "string")

    local fd, err = k.open(file, mode)
    if not fd then
      return nil, err
    end

    local current = k.current_process()
    local n = #current.fds + 1
    current.fds[n] = fd

    return n
  end

  if k.request then
    --- Request a given network path.
    -- Uses any protocol supported by the kernel.  Returns a file descriptor.
    -- Paths must be bang paths, i.e. `https!example!com!404.html` or `mtel!upm!packages!list`
    -- @function request
    -- @tparam string path The bang path to request
    -- @treturn number The file descriptor
    function k.syscalls.request(path)
      checkArg(1, path, "string")

      local fd, err = k.request(path)
      if not fd then
        return nil, err
      end

      local current = k.current_process()
      local n = #current.fds + 1
      current.fds[n] = fd

      return n
    end
  end

  --- Perform some operation on a file descriptor.
  -- Not all file descriptors support all ioctls.
  -- @function ioctl
  -- @tparam number fd The file descriptor
  -- @tparam string operation The operation to perform
  -- @tparam any ... Any remaining arguments
  function k.syscalls.ioctl(fd, operation, ...)
    checkArg(1, fd, "number")
    checkArg(2, operation, "string")

    local current = k.current_process()
    if current.fds[fd] and current.fds[fd].refs <= 0 then
      current.fds[fd] = nil
    end

    if not current.fds[fd] then
      return nil, k.errno.EBADF
    end

    return k.ioctl(current.fds[fd], operation, ...)
  end

  --- Read some data from a file descriptor.
  -- Returns the data that was read.  Any format valid for `io` is valid when passed to this function.
  -- @function read
  -- @tparam number fd The file descriptor
  -- @tparam string|number fmt The format to use when reading
  -- @treturn string The data that was read
  function k.syscalls.read(fd, fmt)
    checkArg(1, fd, "number")
    checkArg(2, fmt, "string", "number")

    local current = k.current_process()
    if current.fds[fd] and current.fds[fd].refs <= 0 and not current.fds[fd].pipe then
      current.fds[fd] = nil
    end

    if not current.fds[fd] then
      return nil, k.errno.EBADF
    end

    return k.read(current.fds[fd], fmt)
  end

  --- Write some data to a file descriptor.
  -- @function write
  -- @tparam number fd The file descriptor
  -- @tparam string data The data to write
  -- @treturn boolean Whether the operation succeeded
  function k.syscalls.write(fd, data)
    checkArg(1, fd, "number")
    checkArg(2, data, "string")

    local current = k.current_process()
    if current.fds[fd] and current.fds[fd].refs <= 0 then
      current.fds[fd] = nil
    end

    if not current.fds[fd] then
      return nil, k.errno.EBADF
    end

    local ok, err = k.write(current.fds[fd], data)
    return not not ok, err
  end

  --- Seek to some position in a given file relative to the start position.
  -- Returns the new position.  Not all file descriptors support this.
  -- @function seek
  -- @tparam number fd The file descriptor
  -- @tparam string whence Where to start
  -- @tparam offset number|nil The offset to seek
  -- @treturn number The new position
  function k.syscalls.seek(fd, whence, offset)
    checkArg(1, fd, "number")
    checkArg(2, whence, "string")
    checkArg(3, offset, "number", "nil")

    local current = k.current_process()
    if current.fds[fd] and current.fds[fd].refs <= 0 then
      current.fds[fd] = nil
    end

    if not current.fds[fd] then
      return nil, k.errno.EBADF
    end

    return k.seek(current.fds[fd], whence, offset or 0)
  end

  --- Flush read and write buffers.
  -- Only does something on some file descriptors, and then only if the file descriptor is buffered.
  -- @function flush
  -- @tparam number fd The file descriptor
  function k.syscalls.flush(fd)
    checkArg(1, fd, "number")

    local current = k.current_process()
    if current.fds[fd] and current.fds[fd].refs <= 0 then
      current.fds[fd] = nil
    end

    if not current.fds[fd] then
      return nil, k.errno.EBADF
    end

    return k.flush(current.fds[fd])
  end

  --- Open a directory.
  -- Opens the given directory for reading and returns a directory descriptor.
  -- @function opendir
  -- @tparam string file The directory to open
  -- @treturn number The resulting directory descriptor
  function k.syscalls.opendir(file)
    checkArg(1, file, "string")

    local fd, err = k.opendir(file)
    if not fd then return nil, err end

    local current = k.current_process()
    local n = #current.fds + 1
    current.fds[n] = fd

    return n
  end

  --- Read from a directory.
  -- @function readdir
  -- @tparam number fd The directory descriptor
  -- @treturn table @{dirent}
  function k.syscalls.readdir(fd)
    checkArg(1, fd, "number")

    local current = k.current_process()
    if current.fds[fd] and current.fds[fd].refs <= 0 then
      current.fds[fd] = nil
    end

    if not current.fds[fd] then
      return nil, k.errno.EBADF
    end

    return k.readdir(current.fds[fd])
  end

  ------
  -- Returned by @{readdir}.
  -- @tfield number inode The inode on which the file is stored
  -- @tfield string name The name of the file
  -- @table dirent

  --- Close a file or directory descriptor.
  -- @function close
  -- @tparam number fd The file descriptor
  function k.syscalls.close(fd)
    checkArg(1, fd, "number")

    local current = k.current_process()
    if not current.fds[fd] then
      return nil, k.errno.EBADF
    end

    k.close(current.fds[fd])

    if current.fds[fd] and current.fds[fd].refs <= 0 then
      current.fds[fd] = nil
    end

    return true
  end

  --- Check if a file descriptor refers to a TTY.
  -- @function isatty
  -- @tparam number fd The file descriptor
  -- @treturn boolean Whether the file descriptor is a TTY
  function k.syscalls.isatty(fd)
    checkArg(1, fd, "number")

    local current = k.current_process()
    if current.fds[fd] and current.fds[fd].refs <= 0 then
      current.fds[fd] = nil
    end

    if not current.fds[fd] then
      return nil, k.errno.EBADF
    end

    local fdt = current.fds[fd]
    return not not (
      fdt.fd.stream and
      fdt.fd.stream.proxy and
      fdt.fd.stream.proxy.eofpat
    )
  end

  --- Duplicate a file descriptor.
  -- Returns the new file descriptor.
  -- @function dup
  -- @tparam number fd The descriptor to duplicate
  -- @treturn number The new file descriptor
  function k.syscalls.dup(fd)
    checkArg(1, fd, "number")

    local current = k.current_process()
    if current.fds[fd] and current.fds[fd].refs <= 0 then
      current.fds[fd] = nil
    end

    if not current.fds[fd] then
      return nil, k.errno.EBADF
    end

    local nfd = #current.fds + 1
    current.fds[nfd] = current.fds[fd]
    current.fds[fd].refs = current.fds[fd].refs + 1

    return nfd
  end

  --- Duplicate a file descriptor to the given new one.
  -- Returns the new file descriptor.  If the provided new file descriptor exists and is open, it will be silently closed.
  -- @function dup2
  -- @tparam number fd The file descriptor to duplicate
  -- @tparam number nfd The new file descriptor
  -- @treturn number The new file descriptor
  function k.syscalls.dup2(fd, nfd)
    checkArg(1, fd, "number")
    checkArg(2, nfd, "number")

    local current = k.current_process()
    if current.fds[fd] and current.fds[fd].refs <= 0 then
      current.fds[fd] = nil
    end

    if not current.fds[fd] then
      return nil, k.errno.EBADF
    end

    if fd == nfd then return nfd end

    if current.fds[nfd] then
      k.syscalls.close(nfd)
    end

    current.fds[nfd] = current.fds[fd]
    current.fds[fd].refs = current.fds[fd].refs + 1

    return nfd
  end

  --- Create a directory.
  -- @function mkdir
  -- @tparam string path The directory to create
  -- @tparam number mode The permissions to set on it
  k.syscalls.mkdir = k.mkdir

  --- Returns some information about a file.
  -- @function stat
  -- @tparam string path The file to query
  -- @treturn @{statx} The information
  k.syscalls.stat = k.stat

  ------
  -- The information returned by @{stat}.
  -- @tfield number ino The inode on which the file is located
  -- @tfield number mode The POSIX file mode (type and permissions)
  -- @tfield number nlink How many times the file's inode is referenced (hard linked)
  -- @tfield number uid The user ID of the file's owner
  -- @tfield number gid The group ID of the file's owner
  -- @tfield number size The file size in bytes
  -- @tfield number blksize The block size used for file I/O
  -- @tfield number atime File access time
  -- @tfield number ctime File creation time
  -- @tfield number mtime File modification time
  -- @table statx

  --- Create a hard link.
  -- Not supported by any filesystems at this time.
  -- @function link
  -- @tparam string source The source file
  -- @tparam string dest The location of the new link
  k.syscalls.link = k.link

  --- Remove a link.
  -- Removes the file when its link count reaches 0.
  -- @function unlink
  -- @tparam string path The file to unlink
  k.syscalls.unlink = k.unlink

  --- Change file permissions.
  -- Takes a standard POSIX file mode and applies the permissions to the given file.
  -- @function chmod
  -- @tparam string path The file to modify
  -- @tparam number mode The mode to set
  k.syscalls.chmod = k.chmod

  --- Change a file's owner.
  -- Changes the `uid` and `gid` fields for the given file.
  -- @function chown
  -- @tparam string path The file to modify
  -- @tparam number uid The new owning UID
  -- @tparam number gid The new owning GID
  k.syscalls.chown = k.chown

  --- Mount a filesystem.
  -- The given directory must exist or the operation will fail.
  -- @function mount
  -- @tparam table|string node The filesystem node
  -- @tparam string path The path at which to mount it
  k.syscalls.mount = k.mount

  -- Unmount a filesystem.
  -- @function unmount
  -- @tparam string path The path to unmount
  k.syscalls.unmount = k.unmount


  -- Process-related system calls --

  --- Create a new process.
  -- This function creates a new process from the given function.  Its behavior is nonstandard due to Lua limitations.
  -- @function fork
  -- @tparam function func The function to use
  -- @treturn number The PID of the new process
  function k.syscalls.fork(func)
    checkArg(1, func, "function")

    local proc = k.get_process(k.add_process())
    proc:add_thread(k.thread_from_function(func))

    return proc.pid
  end

  --- Replace the current process.
  -- Takes the path to an executable file and loads it as a replacement for the current process.
  -- @function execve
  -- @tparam string path The executable to load
  -- @tparam table args Any arguments to pass
  -- @tparam[opt] table env Environment variables, if any
  function k.syscalls.execve(path, args, env)
    checkArg(1, path, "string")
    checkArg(2, args, "table")
    checkArg(3, env, "table", "nil")

    args[0] = args[0] or path

    local current = k.current_process()

    local func, err = k.load_executable(path, current.env)
    if not func then return nil, err end

    local stat = k.stat(path)
    if bit32.band(stat.mode, k.FS_SETUID) ~= 0 then
      current.uid = stat.uid
      current.euid = stat.uid
      current.suid = stat.uid
    end
    if bit32.band(stat.mode, k.FS_SETGID) ~= 0 then
      current.gid = stat.gid
      current.egid = stat.egid
      current.sgid = stat.egid
    end

    current.threads = {}
    current.thread_count = 0
    current.environ = env or current.environ
    current.cmdline = args
    current:add_thread(k.thread_from_function(function()
      return func(args)
    end))

    for f, v in pairs(current.fds) do
      if f > 2 and v.cloexec then
        k.close(v)
        v.refs = v.refs - 1
        current.fds[k] = nil
      end
    end

    coroutine.yield()

    return true
  end

  --- Wait for a process.
  -- If a process has exited, it will not be removed until @{wait} is called on it.
  -- @function wait
  -- @tparam number pid The process ID for which to wait
  function k.syscalls.wait(pid)
    checkArg(1, pid, "number")

    if not k.get_process(pid) then
      return nil, k.errno.ESRCH
    end

    while not k.get_process(pid).is_dead do
      coroutine.yield(0)
    end

    local process = k.get_process(pid)
    local reason, status = process.reason, process.status or 0

    if k.cmdline.log_process_deaths then
      printk(k.L_DEBUG, "process died: %d, %s, %d", pid, reason, status or 0)
    end

    k.remove_process(pid)

    return reason, status
  end

  --- Terminate the current process.
  -- Takes an exit status, which is returned to the parent from a call to @{wait}.
  -- @function exit
  -- @tparam number status The exit status to use
  function k.syscalls.exit(status)
    checkArg(1, status, "number")

    local current = k.current_process()
    current.status = status
    current.threads = {}
    current.thread_count = 0

    coroutine.yield()
  end

  --- Get the current working directory.
  -- @function getcwd
  -- @treturn string The current process's working directory
  function k.syscalls.getcwd()
    return k.current_process().cwd
  end

  --- Set the current process's working directory.
  -- Does nothing if the given path does not exist.  The given path may be relative.
  -- @function chdir
  -- @tparam string path The new working directory
  function k.syscalls.chdir(path)
    checkArg(1, path, "string")
    path = k.check_absolute(path)

    local stat, err = k.stat(path)
    if not stat then
      return nil, err
    end

    if bit32.band(stat.mode, 0xF000) ~= k.FS_DIR then
      return nil, k.errno.ENOTDIR
    end

    local current = k.current_process()
    current.cwd = path

    return true
  end

  --- Modify the current process's identity.
  -- @see setuid(2)
  -- @function setuid
  -- @tparam number uid The new user ID
  function k.syscalls.setuid(uid)
    checkArg(1, uid, "number")
    local current = k.current_process()
    if current.euid == 0 then
      current.suid = uid
      current.euid = uid
      current.uid = uid
      return true
    elseif uid==current.uid or uid==current.euid or uid==current.suid then
      current.euid = uid
      return true
    else
      return nil, k.errno.EPERM
    end
  end

  --- Modify the current process's identity.
  -- @see seteuid(2)
  -- @function seteuid
  -- @tparam number uid The new user ID
  function k.syscalls.seteuid(uid)
    checkArg(1, uid, "number")
    local current = k.current_process()
    if current.euid == 0 then
      current.euid = uid
      current.suid = 0
    elseif uid==current.uid or uid==current.euid or uid==current.suid then
      current.euid = uid
    else
      return nil, k.errno.EPERM
    end
  end

  --- Get the current process's user ID.
  -- @function getuid
  -- @treturn number The user ID
  function k.syscalls.getuid()
    return k.current_process().uid
  end

  --- Get the current process's effective user ID.
  -- @function geteuid
  -- @treturn number The effective user ID
  function k.syscalls.geteuid()
    return k.current_process().euid
  end

  --- Modify the current process's identity.
  -- @see setgid(2)
  -- @function setgid
  -- @tparam number uid The new group ID
  function k.syscalls.setgid(gid)
    checkArg(1, gid, "number")
    local current = k.current_process()
    if current.egid == 0 then
      current.sgid = gid
      current.egid = gid
      current.gid = gid
    elseif gid==current.gid or gid==current.egid or gid==current.sgid then
      current.egid = gid
    else
      return nil, k.errno.EPERM
    end
  end

  --- Modify the current process's identity.
  -- @see setegid(2)
  -- @function setegid
  -- @tparam number uid The new group ID
  function k.syscalls.setegid(gid)
    checkArg(1, gid, "number")
    local current = k.current_process()
    if current.egid == 0 then
      current.sgid = gid
      current.egid = gid
    elseif gid==current.gid or gid==current.egid or gid==current.sgid then
      current.egid = gid
    else
      return nil, k.errno.EPERM
    end
  end

  --- Get the current process's group ID.
  -- @function getgid
  -- @treturn number The group ID
  function k.syscalls.getgid()
    return k.current_process().gid
  end

  --- Get the current process's effective group ID.
  -- @function getegid
  -- @treturn number The effective group ID
  function k.syscalls.getegid()
    return k.current_process().egid
  end

  --- Get the ID of the current process.
  -- @function getpid
  -- @treturn number The process's ID
  function k.syscalls.getpid()
    return k.current_process().pid
  end

  --- Get the parent PID of the current process.
  -- @function getpid
  -- @treturn number The parent PID
  function k.syscalls.getppid()
    return k.current_process().ppid
  end

  --- Set the session ID of the current process.
  -- Does not work if the current process is the leader of its process group.
  -- @function setsid
  -- @treturn number The new session ID
  function k.syscalls.setsid()
    local current = k.current_process()
    if current.pgid == current.pid then
      return nil, k.errno.EPERM
    end

    current.pgid = current.pid
    current.sid = current.pid
    if current.tty then
      current.tty.session = current.sid
      current.tty.pgroup = current.pgid
    end

    k.sessions[current.sid] = { leader = current.pid,
      pids = { [current.pid] = true } }

    return current.sid
  end

  --- Get the session ID of a process.
  -- @function getsid
  -- @tparam[opt] number pid The process to query
  -- @treturn number The session ID of the process
  function k.syscalls.getsid(pid)
    checkArg(1, pid, "number", "nil")

    if pid == 0 or not pid then
      return k.current_process().sid
    end

    local proc = k.get_process(pid)
    if not proc then
      return nil, k.errno.ESRCH
    end

    return proc.sid
  end

  --- Set a process's process group.
  -- @function setpgrp
  -- @tparam number pid The process to modify
  -- @tparam number pg The process group ID
  function k.syscalls.setpgrp(pid, pg)
    checkArg(1, pid, "number")
    checkArg(2, pg, "number")

    local current = k.current_process()
    if pid == 0 then pid = current.pid end
    if pg  == 0 then pg  = pid; k.pgroups[pg].sid = proc.sid end
    local proc = k.get_process(pid)

    if proc.pid ~= current.pid and proc.ppid ~= current.pid then
      return nil, k.errno.EPERM
    end

    if k.pgroups[pg].sid ~= proc.sid then
      return nil, k.errno.EPERM
    end

    k.pgroups[proc.pgid].pids[proc.pid] = nil
    proc.pgid = pg
    k.pgroups[proc.pgid] = k.pgroups[proc.pgid] or { sid = proc.sid,
      pids = {} }
    k.pgroups[proc.pgid].pids[proc.pid] = true

    return true
  end

  --- Get the process group of a process.
  -- @function getpgrp
  -- @tparam[opt] number pid The process ID to query
  -- @treturn number The process group ID of that process
  function k.syscalls.getpgrp(pid)
    checkArg(1, pid, "number", "nil")

    if pid == 0 or not pid then
      return k.current_process().pgid
    end

    local proc = k.get_process(pid)
    if not proc then
      return nil, k.errno.ESRCH
    end

    return proc.pgid
  end

  k.syscalls.setpgid = k.syscalls.setpgrp
  k.syscalls.getpgid = k.syscalls.getpgrp

  -- Handlers of signals whose value here is 'false' can't be
  -- overwritten, but those signals can still be sent by kill(2).
  local valid_signals = {
    SIGHUP  = true,
    SIGINT  = true,
    SIGQUIT = true,
    SIGKILL = false,
    SIGPIPE = true,
    SIGTERM = true,
    SIGCONT = false,
    SIGTSTP = true,
    SIGSTOP = false,
    SIGTTIN = true,
    SIGTTOU = true
  }

  --- Set a handler for some POSIX signal.
  -- Signals are represented by their constant names rather than by numbers.
  -- @function sigaction
  -- @tparam string name The signal name
  -- @tparam handler function The handler function to set
  function k.syscalls.sigaction(name, handler)
    checkArg(1, name, "string")
    checkArg(2, handler, "function")

    if not valid_signals[name] then return nil, k.errno.EINVAL end

    local current = k.current_process()
    current.signal_handlers[name] = handler

    return true
  end

  --- Signal a process.
  -- Differs from the standard slightly: SIGEXIST, rather than 0, is used to check if a process exists - since signals don't have numeric IDs under Cynosure 2.
  -- @function kill
  -- @tparam number pid The process to kill
  -- @tparam string name The signal to send
  function k.syscalls.kill(pid, name)
    checkArg(1, pid, "number")
    checkArg(2, name, "string")

    local proc = k.get_process(pid)
    local current = k.current_process()

    if valid_signals[name] == nil and name ~= "SIGEXIST" then
      return nil, k.errno.EINVAL
    end

    if not proc then return nil, k.errno.ESRCH end

    if current.uid == 0 or current.euid == 0 or current.uid == proc.uid or
       current.euid == proc.uid or current.uid == proc.suid or
       current.euid == proc.suid then
      if name == "SIGEXIST" and proc then return true end
      table.insert(proc.sigqueue, name)

      return true
    else
      return nil, k.errno.EPERM
    end
  end


  -- Networking system calls --

  --- Get the system hostname.
  -- @function gethostname
  -- @treturn string The hostname
  function k.syscalls.gethostname()
    return k.gethostname and k.gethostname() or
      "@[{bconf.DEFAULT_HOSTNAME or 'localhost'}]"
  end

  --- Set the system hostname.
  -- @function sethostname
  -- @tparam string name The new hostname
  function k.syscalls.sethostname(name)
    checkArg(1, name, "string")
    return k.sethostname and k.sethostname(name)
  end


  -- Miscellaneous system calls --

  --- Get the process environment.
  -- Returns the current process's environment table.
  -- @function environ
  -- @treturn table The environment
  function k.syscalls.environ()
    return k.current_process().environ
  end

  --- Set the umask.
  -- Only uses the permissions bits.  Returns the previous umask.
  -- @function umask
  -- @tparam number num The new umask
  -- @treturn number The old umask
  function k.syscalls.umask(num)
    checkArg(1, num, "number")
    local cur = k.current_process()
    local old = cur.umask
    if tonumber(num) then
      cur.umask = bit32.band(math.floor(num), 511)
    end
    return old
  end

  --- Create a pipe.
  -- Returns a pair of file descriptors.
  -- @function pipe
  -- @treturn number The read end
  -- @treturn number The write end
  function k.syscalls.pipe()
    local buf = ""
    local closed = false

    local instream = k.fd_from_rwf(function(_, _, n)
      printk(k.L_DEBUG, "READ(%d)", n)
      printk(k.L_DEBUG, "BL(%d)", #buf)
      while #buf < n and not closed do coroutine.yield(0) end
      local data = buf:sub(1, math.min(n, #buf))
      buf = buf:sub(#data + 1)

      if #data == 0 and closed then
        k.syscalls.kill(0, "SIGPIPE")
        return nil, k.errno.EBADF
      end

      return data
    end, nil, function() closed = true end)

    local outstream = k.fd_from_rwf(nil, function(_, _, data)
      if closed then
        k.syscalls.kill(0, "SIGPIPE")
        return nil, k.errno.EBADF
      end

      buf = buf .. data
      printk(k.L_DEBUG, "BL(%d)", #buf)
      return true
    end, function() closed = true end)

    local into, outof = k.fd_from_node(instream, instream, "r"),
      k.fd_from_node(outstream, outstream, "w")

    into:ioctl("setvbuf", "none")
    outof:ioctl("setvbuf", "none")

    local current = k.current_process()

    local infd = #current.fds + 1
    current.fds[infd] = { fd = into, node = into, refs = 1, pipe = true }

    local outfd = #current.fds + 1
    current.fds[outfd] = { fd = outof, node = outof, refs = 1, pipe = true }

    return infd, outfd
  end

  --- Restart the system.
  -- Does not function unless the effective user ID is 0 (root).
  -- The given action must be one of: `halt`, `poweroff`, `reboot`
  -- @function reboot
  -- @tparam string cmd The action to perform
  function k.syscalls.reboot(cmd)
    checkArg(1, cmd, "string")

    if k.current_process().euid ~= 0 then
      return nil, k.errno.EPERM
    end

    if cmd == "halt" then
      k.shutdown()
      printk(k.L_INFO, "System halted.")
      while true do
        computer.pullSignal()
      end
    elseif cmd == "poweroff" then
      printk(k.L_INFO, "Power down.")
      k.shutdown()
      computer.shutdown()
    elseif cmd == "restart" then
      printk(k.L_INFO, "Restarting system.")
      k.shutdown()
      computer.shutdown(true)
    end

    return nil, k.errno.EINVAL
  end

  --- Return some system information.
  -- @function uname
  -- @treturn @{unameinfo} The system information
  function k.syscalls.uname()
    return {
      sysname = "Cynosure",
      nodename = k.syscalls.gethostname() or "localhost",
      release = "$[{lua scripts/version.lua}]",
      version = "@[{os.date('%Y-%m-%d')}]",
      machine = "oc-".._VERSION:match("Lua (.+)")
    }
  end

  ------
  -- Table containing system information.
  -- @tfield string sysname The system name
  -- @tfield string nodename The nodename (hostname)
  -- @tfield string release The kernel release
  -- @tfield string version The day this kernel was built
  -- @tfield string machine The machine the kernel is running on
  -- @table unameinfo

  --- Return the system uptime.
  -- @function uptime
  -- @treturn number The uptime
  function k.syscalls.uptime()
    return computer.uptime()
  end
end
