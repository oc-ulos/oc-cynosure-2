-- processes --

do
  local _proc = {}

  k.state.pid = 0
  k.state.processes = {}

  function _proc:resume(...)
  end

  function _proc:new(parent, func)
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

