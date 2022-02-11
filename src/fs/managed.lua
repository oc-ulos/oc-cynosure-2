--[[
    Managed filesystem driver
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

printk(k.L_INFO, "fs/managed")

do
  local _node = {}

  -- file attributes are stored as 'key:value' pairs
  -- these are:
  --  uid:number
  --  gid:number
  --  mode:number
  --  devmaj:number present if file is block/chardev
  --  devmin:number present if file is block/chardev
  --  created:number

  -- take the attribute file data and return a table
  local function load_attributes()
  end

  -- take a table of attributes and return file data
  local function dump_attributes()
  end

  -- get the attributes of a specific file
  function _node:get_attributes(file)
  end

  -- set the attributes of a specific file
  function _node:set_attributes(file)
  end

  function _node:exists()
  end

  function _node:stat()
  end

  function _node:chmod()
  end

  function _node:chown()
  end
  
  function _node:link()
  end

  function _node:unlink()
  end
  
  function _node:mkdir()
  end

  function _node:opendir()
  end

  function _node:readdir()
  end

  function _node:open()
  end

  function _node:read()
  end
  
  function _node:write()
  end
  
  function _node:seek()
  end

  -- this function does nothing
  function _node:flush() end

  function _node:close()
  end
end
