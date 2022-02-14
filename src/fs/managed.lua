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
    local attributes = {}
    for line in data:gmatch("[^\n]+") do
      local key, val = line:match("^(.-):(.+)$")
      attributes[key] = tonumber(val)
    end
    return attributes
  end

  local serialize_order = {"uid", "gid", "mode", "devmaj", "devmin", "created"}
  -- take a table of attributes and return file data
  local function dump_attributes(attributes)
    local data = ""
    for _, key in ipairs(serialize_order) do
      if attributes[key] then
        data = data .. string.format("%s:%d\n", key, attributes[key])
      end
    end
    return data
  end

  -- sanitize a path to not contain a .attr
  local function sanitize(path)
    local segments = k.split_path(path)
    local final = segments[#segments]
    if final:sub(1,1) == "." and final:sub(-5) == ".attr" then
      return nil, k.errno.EACCES
    end
    return path
  end

  local function attr_path(path)
    local segments = k.split_path(path)
    return "/" .. table.concat(segments, "/", 1, #segments - 1) .. "." ..
      segments[#segments] .. ".attr"
  end

  -- get the attributes of a specific file
  function _node:get_attributes(file)
    checkArg(1, file, "string")
    local err
    file, err = sanitize(file)
    if not file then return nil, err end
    local fd, err = self.fs.open(attr_path(file), "r")
    if not fd then
      return {
        uid = 0,
        gid = 0,
        mode = bit32.bor(self.fs.isDirectory(file) and 0x4000 or 0x8000, 511),
        created = self.fs.lastModified(file)
      }
    end
    local data = self.fs.read(fd, 2048)
    self.fs.close(fd)
    return load_attributes(data)
  end

  -- set the attributes of a specific file
  function _node:set_attributes(file, attributes)
    checkArg(1, file, "string")
    checkArg(2, attributes, "table")
    local err
    file, err = sanitize(file)
    if not file then return nil, err end
    local fd, err = self.fs.open(attr_path(file), "w")
    if not fd then return nil, k.errno.EROFS end
    self.fs.write(fd, dump_attributes(attributes))
    self.fs.close(fd)
    return true
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
