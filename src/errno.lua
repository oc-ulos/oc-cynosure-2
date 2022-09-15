--[[
    Template kernel source file
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

printk(k.L_INFO, "errno")

do
  k.errno = {
    EPERM = 1,
    ENOENT = 2,
    ESRCH = 3,
    ENOEXEC = 8,
    EBADF = 9,
    ECHILD = 10,
    EACCES = 13,
    ENOTBLK = 15,
    EBUSY = 16,
    EEXIST = 17,
    EXDEV = 18,
    ENODEV = 19,
    ENOTDIR = 20,
    EISDIR = 21,
    EINVAL = 22,
    ENOTTY = 25,
    ENOSYS = 38,
    EUNATCH = 49,
    ELIBEXEC = 83,
    ENOPROTOOPT = 92,
    ENOTSUP = 95,
  }

  function k.fix_error(err, name)
    -- this gsub fixes up line numbers because preemption makes them
    -- seemingly incorrect
    return err
      @[{bconf.PREEMPT_MODE ~= 'none' and ':gsub(name:gsub("[%.%%%[%]%*%$%^%.%?%+%-]", "%%%1")..":(%d+):", function(d)return name..":"..(tonumber(d)-1)..":"end)' or ''}]
  end

  local old_pcall, old_xpcall = _G.pcall, _G.xpcall
  function _G.pcall(...)
    local result = table.pack(old_pcall(...))

    if not result[1] then
      if type(result[2]) == "string" then
        local name = result[2]:match("^[^:]+") or ""
        result[2] = k.fix_error(result[2], name)
      end
    end

    return table.unpack(result, 1, result.n)
  end

  function _G.xpcall(...)
    local result = table.pack(old_xpcall(...))

    if not result[1] then
      if type(result[2]) == "string" then
        local name = result[2]:match("^[^:]+") or ""
        result[2] = k.fix_error(result[2], name)
      end
    end

    return table.unpack(result, 1, result.n)
  end
end
