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
  local function load_attributes(data)
  end

  -- take a table of attributes and return file data
  local function dump_attributes(attributes)
  end

  -- get the attributes of a specific file
  function _node:get_attributes(file)
  end

  -- set the attributes of a specific file
  function _node:set_attributes(file, attributes)
  end

  function _node:exists(path)
  end

  function _node:stat(path)
  end

  function _node:chmod(path, mode)
  end

  function _node:chown(path, uid, gid)
  end
  
  function _node:link(source, dest)
  end

  function _node:unlink(path)
  end
  
  function _node:mkdir(path)
  end

  function _node:opendir(path)
  end

  function _node:readdir(dirfd)
  end

  function _node:open(path, mode)
  end

  function _node:read(fd, fmt)
  end
  
  function _node:write(fd, data)
  end
  
  function _node:seek(fd, whence, offset)
  end

  -- this function does nothing
  function _node:flush() end

  function _node:close(fd)
  end
end
