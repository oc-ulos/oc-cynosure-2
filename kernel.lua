-- main kernel source file --

_G.k = { state = {} }
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
--#include "src/version.lua"
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
--#include "src/cmdline.lua"
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

  k.cmdline.loglevel = tonumber(k.cmdline.loglevel) or 0
  
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
--#include "src/platform/oc/logger.lua"
--#include "src/logger.lua"
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
--#include "src/checkArg.lua"
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
--#include "src/syscalls.lua"
-- Cynosure kernel scheduler --

-- processes --

do
  local _proc = {}

  k.state.pid = 0

  function _proc:resume(...)
  end

  function _proc:new(parent, func)
    parent = parent or {}
    k.state.pid = k.state.pid + 1
    return setmetatable({
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
      session = parent.session or 0,
      -- Process group the process belongs to.
      pgroup = parent.pgroup or 0,
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
  end

--#include "src/sched/process.lua"

  function k.syscall.execf()
  end
end
--#include "src/scheduler.lua"
-- a fairly smart filesystem mounting arrangement --

do
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
    local node, err = find_node(path)
    if node and flags.creat and flags.excl then
      return nil, k.errno.EEXIST
    end
    if not node then
      if flags.creat then
        checkArg(3, mode, "number")
        local parent, err = find_node(path:match("(.+)/..-$"))
        if not parent then
          return nil, err
        end
        local fd, err = parent:creat(clean_path(err .. "/"
          .. path:match(".+/(..-)$")), mode)
        if not fd then
          return nil, err
        end
        parent:close(fd)
      else
        return nil, err
      end
    end
  end

  function k.syscall.read()
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
--#include "src/vfs/main.lua"
--#include "src/ramfs.lua"
