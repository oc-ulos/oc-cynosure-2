--[[
    
    A loader for the CYnosure eXecutable (CYX) format.
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

k.log(k.L_INFO, "exec/cyx")

do
  local magic = 0x43796e6f
  local flags = {
    lua53 = 0x1,
    static = 0x2,
    bootable = 0x4,
    executable = 0x8,
    library = 0x10
  }

  local _flags = {
    lua53 = 0x1,
    static = 0x2,
    boot = 0x4,
    exec = 0x8,
    library = 0x10,
  }

  local accepted = {[0] = true, [5] = true}

  local function parse_cyx(fd)
    local header = k.syscall.read(fd, 4)
    if header ~= "onyC" then
      return nil, k.errno.ENOEXEC
    end

    local version = k.syscall.read(fd, 1):byte()
    local flags = k.syscall.read(fd, 1):byte()
    local osid = k.syscall.read(fd, 1):byte()

    if not accepted[osid] then
      return nil, k.errno.ENOEXEC
    end

    local _
    if flags & flags.static == 0 then
      local nlink = k.syscall.read(fd, 1):byte()
      if nlink == 0 then
        -- no interpreter!
        return nil, k.errno.ENOEXEC
      end
      local nlib = k.syscall.read(fd, 1):byte()
      local itpfile = k.syscall.read(fd, nlib)
      local func, err = k.load_executable(itpfile)
      if not func then
        k.syscall.close(fd)
        return nil, err
      end
      k.syscall.seek(fd, "set", 0)
      return function(...)
        -- This function will take over a process.
        -- We need to do the following:
        --   1) Allocate a new file descriptor for the interpreter (this
        --      process).
        local fds = k.state.processes[k.state.cpid].fds
        local n = #fds + 1
        --   2) Assign the kernel's old file descriptor (from process 0) to the
        --      newly allocated file descriptor belonging to this process.
        fds[n] = k.state.processes[0].fds[fd]
        --   3) Remove the kernel's old file descriptor.
        k.state.processes[0].fds[fd] = nil
        --   4) Pass this process's new file descriptor to the interpreter, for
        --      use in further parsing the executable file.  Also pass any
        --      command-line arguments.
        return func(fd, ...)
      end
    else
      local nlink = k.syscall.read(fd, 1):byte()
      if nlink > 0 then
        return nil, k.errno.ENOEXEC
      end
      local str = k.syscall.read(fd, math.huge)
      k.syscall.close(fd)
      return load(str)
    end
  end

  function k.load_cyx(fd)
    return parse_cyx(fd)
  end
end
