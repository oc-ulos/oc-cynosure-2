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

    -- Uncomment for debugging purposes.
    --printk(k.L_DEBUG, "syscall %s => %s, %s", name, tostring(result[1]),
    --  tostring(result[2]))

    return table.unpack(result, 1, result.n)
  end

  -------------------------------
  -- File-related system calls --
  -------------------------------

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

  function k.syscalls.ioctl(fd, operation, ...)
    checkArg(1, fd, "number")
    checkArg(2, operation, "string")

    local current = k.current_process()
    if not current.fds[fd] then
      return nil, k.errno.EBADF
    end

    return k.ioctl(current.fds[fd], operation, ...)
  end

  function k.syscalls.read(fd, fmt)
    checkArg(1, fd, "number")
    checkArg(2, fmt, "string", "number")

    local current = k.current_process()
    if not current.fds[fd] then
      return nil, k.errno.EBADF
    end

    return k.read(current.fds[fd], fmt)
  end

  function k.syscalls.write(fd, data)
    checkArg(1, fd, "number")
    checkArg(2, data, "string")

    local current = k.current_process()
    if not current.fds[fd] then
      return nil, k.errno.EBADF
    end

    local ok, err = k.write(current.fds[fd], data)
    return not not ok, err
  end

  function k.syscalls.seek(fd, whence, offset)
    checkArg(1, fd, "number")
    checkArg(2, whence, "string")
    checkArg(3, offset, "number", "nil")

    local current = k.current_process()
    if not current.fds[fd] then
      return nil, k.errno.EBADF
    end

    return k.seek(current.fds[fd], whence, offset or 0)
  end

  function k.syscalls.flush(fd)
    checkArg(1, fd, "number")

    local current = k.current_process()
    if not current.fds[fd] then
      return nil, k.errno.EBADF
    end

    return k.flush(current.fds[fd])
  end

  function k.syscalls.opendir(url)
    checkArg(1, url, "string")

    local fd, err = k.opendir(url)
    if not fd then return nil, err end

    local current = k.current_process()
    local n = #current.fds + 1
    current.fds[n] = fd

    return n
  end

  function k.syscalls.readdir(fd)
    checkArg(1, fd, "number")

    local current = k.current_process()
    if not current.fds[fd] then
      return nil, k.errno.EBADF
    end

    return k.readdir(current.fds[fd])
  end

  function k.syscalls.close(fd)
    checkArg(1, fd, "number")

    local current = k.current_process()
    if not current.fds[fd] then
      return nil, k.errno.EBADF
    end

    k.close(current.fds[fd])

    if current.fds[fd].refs <= 0 then
      current.fds[fd] = nil
    end

    return true
  end

  k.syscalls.mkdir = k.mkdir

  k.syscalls.stat = k.stat

  k.syscalls.link = k.link
  k.syscalls.unlink = k.unlink
  k.syscalls.mount = k.mount
  k.syscalls.unmount = k.unmount

  ----------------------------------
  -- Process-related system calls --
  ----------------------------------

  function k.syscalls.fork(func)
    checkArg(1, func, "function")

    local proc = k.get_process(k.add_process())
    proc:add_thread(k.thread_from_function(func))

    return proc.pid
  end

  function k.syscalls.execve(path, args, env)
    checkArg(1, path, "string")
    checkArg(2, args, "table")
    checkArg(3, env, "table", "nil")

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
    current:add_thread(k.thread_from_function(function()
      return func(args, env)
    end))

    coroutine.yield()
  end

  function k.syscalls.wait(pid)
    checkArg(1, pid, "number")

    local sig, id, status
    repeat
      sig, id, status = coroutine.yield(0)
    until sig == "process_exit" and id == pid

    return status
  end

  function k.syscalls.exit(status)
    checkArg(1, status, "number")

    local current = k.current_process()
    current.status = status
    current.threads = {}
    current.thread_count = 0

    coroutine.yield()
  end

  function k.syscalls.getcwd()
    return k.current_process().cwd
  end

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

  function k.syscalls.getuid()
    return k.current_process().uid
  end

  function k.syscalls.geteuid()
    return k.current_process().euid
  end

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

  function k.syscalls.getgid()
    return k.current_process().gid
  end

  function k.syscalls.getegid()
    return k.current_process().egid
  end

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

  -- Handlers of signals whose value here is 'false' can't be
  -- overwritten, but those signals can still be sent by kill(2).
  local valid_signals = {
    SIGKILL = false,
    SIGINT  = true,
    SIGQUIT = true,
    SIGTSTP = true,
    SIGSTOP = false,
    SIGCONT = false,
    SIGTTIN = true,
    SIGTTOU = true
  }

  function k.syscalls.sigaction(name, handler)
    checkArg(1, name, "string")
    checkArg(2, handler, "function")

    if not valid_signals[name] then return nil, k.errno.EINVAL end

    local current = k.current_process()
    current.signal_handlers[name] = handler

    return true
  end

  -- Differs from the standard slightly: SIGEXIST, rather than 0,
  -- is used to check if a process exists - since signals don't
  -- have numeric IDs under Cynosure 2.
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

  --------------------------------
  -- Miscellaneous system calls --
  --------------------------------

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
end
