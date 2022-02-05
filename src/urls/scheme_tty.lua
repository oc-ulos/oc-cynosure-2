--[[
    tty: scheme
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

printk(k.L_INFO, "urls/scheme_tty")

do
  local provider = {}

  local ttys = {}

  function provider.opendir(d)
    if d ~= "/" then
      return nil, k.errno.ENOENT
    end
    return {n = 0}
  end

  function provider.readdir(fd)
    if type(fd) ~= "table" or not fd.n then
      return nil, k.errno.EBADF
    end
    fd.n = fd.n + 1
    if ttys[fd.n] then
      return {
        inode = -1,
        name = tostring(fd.n)
      }
    end
  end

  function provider.close()
  end

  function provider.open(tty)
    checkArg(1, tty, "string")
    return ttys[tty], k.errno.ENOENT
  end

  function provider.read(tty, n)
    checkArg(1, tty, "table")
    checkArg(2, n, "number")
    if not tty.read then
      return nil, k.errno.EBADF
    end
    return tty:read(n)
  end

  function provider.write(tty, data)
    checkArg(1, tty, "table")
    checkArg(2, data, "string")
    if not tty.write then
      return nil, k.errno.EBADF
    end
    return tty:write(data)
  end

  function provider.flush(tty)
    checkArg(1, tty, "table")
    if not tty.flush then
      return nil, k.errno.EBADF
    end
    return tty:flush()
  end

  k.register_scheme("tty", provider)

  -- dynamically register ttys
  local screens = {}
  for gpu in component.list("gpu", true) do
    for screen in component.list("screen", true) do
      if not screens[screen] then
        screens[screen] = true
        printk(k.L_DEBUG, "registering TTY on %s,%s", gpu:sub(1,6),
          screen:sub(1,6))
        ttys[#ttys+1] = k.open_tty(gpu, screen)
      end
    end
  end
end
