--[[
    Main source file for the Cynosure kernel's scheduler.
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

k.log(k.L_INFO, "scheduler/main")
  
do
  --#include "src/scheduler/process.lua"

  --@syscall execf()
  --@arg file string
  --@arg args table
  --@arg env table
  --@shortdesc execute program
  --@startdocs
  -- This execve() mostly conforms to the POSIX-specified behavior.  It will
  -- replace the program currently being run by the calling process with the
  -- script or executable specified by @arg[file].
  --@enddocs
  function k.syscall.execve(file, args, env)
    checkArg(1, file, "string")
    checkArg(2, args, "table")
    checkArg(3, env, "table")
  end

  --@syscall getpid()
  --@shortdesc get process identifier
  function k.syscall.getpid()
    return k.state.cpid
  end

  --@syscall getpid()
  --@shortdesc get parent process's identifier
  function k.syscall.getppid()
    return k.state.processes[k.state.cpid].uid
  end

  --@syscall getuid()
  --@shortdesc get process's real uid
  function k.syscall.getuid()
    return k.state.processes[k.state.cpid].uid
  end

  --@syscall geteuid()
  --@shortdesc get process's effective uid
  function k.syscall.geteuid()
    return k.state.processes[k.state.cpid].euid
  end

  --@syscall getgid()
  --@shortdesc get process's real group identifier
  function k.syscall.getgid()
    return k.state.processes[k.state.cpid].gid
  end

  --@syscall getegid()
  --@shortdesc get process's effective group identifier
  function k.syscall.getegid()
    return k.state.processes[k.state.cpid].egid
  end

  -- Determine if we should yield.
  local lastYield = 0
  local function shouldYield(procs)
  end

  -- bland empty signal table for memory usage reasons
  -- not a huge deal, but has some slight benefit.
  local emptySignal = {n = 0}
  function k.schedloop()
    -- Here's how yielding works:
    -- If all the processes yielded because of pre-emption, and the
    -- last time we yielded was less than five seconds ago, and the
    -- last cycle took less than the time remaining before we will
    -- hit a too-long-without-yielding error, then the scheduler will
    -- simply resume all processes again.  This timing is taken into
    -- account while determining how strict to be with pre-emption
    -- yields also.
    --
    -- Tf any process has explicitly yielded, the scheduler will not
    -- resume that process until its yield duration is exceeded or it
    -- receives a signal.  Signals sitting in the process's queue
    -- count as receiving a signal, so if these are present then the
    -- scheduler will not yield*.
    --
    -- In any case, if the time since the last yield has reached the
    -- configured maximum limit, the scheduler will yield for the
    -- maxmum possible amount of time.
    while k.state.processes[1] do
      local to_run = {}

      -- filter out stopped/dead processes
      for k, v in pairs(k.state.processes) do
        if k ~= 0 and not (v.stopped or v.dead) then
          to_run[#to_run+1] = v
        end
      end

      -- sort by priority
      table.sort(to_run, function(a, b)
        return a.nice > b.nice
      end)

      local signal = emptySignal
      if shouldYield(to_run) then
        signal = table.pack(k.pullSignal())
      end

      -- run all the processes
      for i, proc in ipairs(to_run) do
        local ok, err = proc:resume(sig)
      end
    end
    k.shutdown()
  end
end
