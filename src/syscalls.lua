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

    return table.unpack(result, 1, result.n)
  end

  function k.syscalls.open(url, mode)
    checkArg(1, url, "string")
    checkArg(2, mode, "string")

    local fd, err = k.open(url, mode)
    if not fd then
      return nil, err
    end

    local current = k.current_process()
    local n = #current.fds + 1
    current.fds[n] = fd

    return n
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

    return k.write(current.fds[fd], data)
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

    return k.close(current.fds[fd])
  end

  k.syscalls.stat = k.stat

  k.syscalls.link = k.link
  k.syscalls.unlink = k.unlink
  k.syscalls.mount = k.mount
  k.syscalls.unmount = k.unmount

  function k.syscalls.fork()
  end

  function k.syscalls.execve()
  end

  function k.syscalls.setuid()
  end

  function k.syscalls.seteuid()
  end

  function k.syscalls.getuid()
  end

  function k.syscalls.geteuid()
  end

  function k.syscalls.setgid()
  end

  function k.syscalls.setegid()
  end

  function k.syscalls.getgid()
  end

  function k.syscalls.getegid()
  end
end
