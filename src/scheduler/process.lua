--[[

    Process management for the Cynosure scheduler.
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
  local _proc = {}

  -- the PID of the last created process
  k.state.pid = 0
  -- the PID of the currently executing process
  k.state.cpid = 0
  -- the ID of the current thread in the current process
  k.state.ctid = 0
  -- table of all the processes
  k.state.processes = {[0] = {fds = {}}}

  function _proc:resume(...)
    for i, thd in ipairs(self.threads) do
      local ok, err = coroutine.resume(thd)
    end
  end

  function _proc:new(parent, func)
    parent = parent or {}
    k.state.pid = k.state.pid + 1
    local new = setmetatable({
      -- process command line
      cmdline = {},
      -- Process ID.
      pid = k.state.pid,
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
      -- Whether the process is dead.
      dead = false,
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
      -- nice value
      nice = 0,
      -- all the threads
      threads = {
        [1] = {
          errno = 0,
          sigmask = {},
          tid = 1,
          coroutine = coroutine.create(func)
        }
      },
    }, {__index = _proc, __call = _proc.resume})
    
    k.state.processes[k.state.pid] = new

    return new
  end

  --@syscall fork()
  --@arg func function
  --@shortdesc create a child process
  --@startdocs
  -- This fork() takes a single function argument, this being some code to
  -- execute in both the new process and the parent process; this function
  -- is called with the result of the `fork()` system call as its argument.
  --
  -- This result is `0` if the function is the child process, an error string
  -- on failure, and a number if the function is the parent process.
  --
  -- The recommended use for this function is to `exec()` some more code, as
  -- its capabilities and syntax leave much to be desired.
  --@enddocs
  function k.syscall.fork(func)
    checkArg(1, func, "function")
    local nproc = _proc:new(k.state.processes[k.state.cpid], func)
    func(nproc.pid)
    return 0
  end

  --@syscall nice()
  --@arg num number
  --@shortdesc change process's nice value
  function k.syscall.nice(num)
    checkArg(1, num, "number")
    local cproc = k.state.processes[k.state.cpid]
    cproc.nice = math.min(19, math.max(-20, cproc.nice + num))
  end
end
