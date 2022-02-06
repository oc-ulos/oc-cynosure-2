--[[
    Main file system code
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

printk(k.L_INFO, "fs/main")

---@alias fs_recognizer fun(component: table): table

do
  ---@type fs_recognizer[]
  k.fstypes = {}

  --- Registers a filesystem type
  ---@param name string
  ---@param recognizer fs_recognizer
  function k.register_fstype(name, recognizer)
    checkArg(1, name, "string")
    checkArg(2, recognizer, "function")
    if k.fstypes[name] then
      panic("attempted to double-register fstype " .. name)
    end
    k.fstypes[name] = recognizer
    return true
  end

  local provider = {}

  -- TODO: Actually implement functionality

  local fds = {}
  local mounts = {}

  function provider.open(file, mode)
    checkArg(1, file, "string")
    checkArg(2, mode, "string")
  end

  function provider.read(fd, fmt)
    checkArg(1, fd, "table")
    checkArg(2, fmt, "string", "number")
  end

  function provider.write(fd, data)
    checkArg(1, fd, "table")
    checkArg(2, data, "string")
  end

  function provider.flush(fd)
    checkArg(1, fd, "table")
  end

  function provider.opendir()
  end

  function provider.readdir()
  end

  function provider.close()
  end

  k.register_scheme("file", provider)
end

--@[{bconf.FS_MANAGED == 'y' and '#include "src/fs/managed.lua"' or ''}]
--@[{bconf.FS_SFS == 'y' and '#include "src/fs/simplefs.lua"' or ''}]
