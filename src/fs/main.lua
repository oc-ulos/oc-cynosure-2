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

do
  k.fstypes = {}

  function k.register_fstype()
  end

  local provider = {}

  -- TODO: Actually implement the functions and their arguments

  function provider.open()
  end

  function provider.close()
  end

  function provider.read()
  end

  function provider.write()
  end

  function provider.opendir()
  end

  function provider.readdir()
  end

  function provider.flush()
  end

  k.register_scheme("file", provider)
end

--@[{bconf.FS_MANAGED == 'y' and '#include "src/fs/managed.lua"' or ''}]
--@[{bconf.FS_SFS == 'y' and '#include "src/fs/simplefs.lua"' or ''}]
