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

do
  --#include "src/sched/process.lua"

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
end
