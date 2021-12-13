--[[
    An implementation of mutexes.
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

k.log(k.L_INFO, "safety/mutex")

do
  local mutexes = {}

  --@syscall newmutex
  --@return mtxid number
  --@shortdesc create a new mutex
  function k.syscall.newmutex()
    local mtxid = math.random(0, 999999)
    while mutexes[mtxid] do
      mtxid = math.random(0, 999999)
    end
    mutexes[mtxid] = true
    return mtxid
  end

  --@syscall lockmutex
  --@arg mtxid number
  --@shortdesc lock a mutex
  function k.syscall.lockmutex(mtxid)
    checkArg(1, mtxid, "number")
    if not mutexes[mtxid] then
      return nil, k.errno.EIDRM
    end
    if type(mutexes[mtxid]) == "number" and
        mutexes[mtxid] ~= k.syscall.getpid() then
      return nil, k.errno.EWOULDBLOCK
    end
    mutexes[mtxid] = k.syscall.getpid()
    return true
  end

  --@syscall unlockmutex
  --@arg mtxid number
  --@shortdesc unlock a mutex
  function k.syscall.unlockmutex(mtxid)
    checkArg(1, mtxid, "number")
    if not mutexes[mtxid] then
      return nil, k.errno.EIDRM
    end
    if type(mutexes[mtxid]) == "boolean" then
      return true
    end
    if mutexes[mtxid] ~= k.syscall.getpid() then
      return nil, k.errno.EPERM
    end
    mutexes[mtxid] = true
  end

  --@syscall removemutex
  --@arg mtxid number
  --@shortdesc
  function k.syscall.removemutex(mtxid)
    checkArg(1, mtxid, "number")
    if not mutexes[mtxid] then
      return nil, k.errno.EIDRM
    end
    if mutexes[mtxid] ~= true then
      return nil, k.errno.EBUSY
    end
    mutexes[mtxid] = nil
  end
end
