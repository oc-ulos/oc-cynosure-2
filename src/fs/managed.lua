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

  -- take a table of attributes and return file data
  local function dump_attributes(attributes)
    local data = ""

    for key, val in ipairs(attributes) do
      data = data .. string.format("%s:%d\n", key, val)
    end

    return data
  end

  -- Check if a path points to an attribute file
  local function is_attribute(path)
    local segments = k.split_path(path)
    local final = segments[#segments]
    if final:sub(1,1) == "." and final:sub(-5) == ".attr" then
      return true
    end
    return false
  end

  local function attr_path(path)
    local segments = k.split_path(path)
    return "/" .. table.concat(segments, "/", 1, #segments - 1) .. "." ..
      segments[#segments] .. ".attr"
  end

  -- get the attributes of a specific file
  function _node:get_attributes(file)
    checkArg(1, file, "string")

    if is_attribute(file) then return nil, k.errno.EACCES end

    local fd = self.fs.open(attr_path(file), "r")
    if not fd then
      -- default to root/root, rwxrwxrwx permissions
      return {
        uid = 0,
        gid = 0,
        mode = self.fs.isDirectory(file) and 0x41FF or 0x81FF,
        created = self.fs.lastModified(file)
      }
    end

    local data = self.fs.read(fd, 2048)
    self.fs.close(fd)

    local attributes = load_attributes(data)
    attributes.uid = attributes.uid or 0
    attributes.gid = attributes.gid or 0
    -- default to root/root, rwxrwxrwx permissions
    attributes.mode = attributes.mode or (self.fs.isDirectory(file)
      and 0x41FF or 0x81FF)
    attributes.created = attributes.created or self.fs.lastModified(file)

    return attributes
  end

  -- set the attributes of a specific file
  function _node:set_attributes(file, attributes)
    checkArg(1, file, "string")
    checkArg(2, attributes, "table")

    if is_attribute(file) then return nil, k.errno.EACCES end

    local fd = self.fs.open(attr_path(file), "w")
    if not fd then return nil, k.errno.EROFS end

    self.fs.write(fd, dump_attributes(attributes))
    self.fs.close(fd)
    return true
  end

  -- Takes a file path and returns only whether that path exists.  Similar to
  -- stat(), but faster since there's no attribute checking.
  function _node:exists(path)
    checkArg(1, path, "string")
    -- this is a couple lines of code compressed into one.
    return not not ((not is_attribute(path)) and self.fs.exists(path))
  end

  -- Returns attributes about the given file.
  function _node:stat(path)
    checkArg(1, path, "string")
    if is_attribute(path) then return nil, k.errno.EACCES end
    if not self:exists(path) then return nil, k.errno.ENOENT end

    local attributes = self:get_attributes(path)
    -- TODO: populate the 'dev' and 'rdev' fields?
    local stat = {
      dev = -1,
      ino = -1,
      mode = attributes.mode,
      nlink = 1,
      uid = attributes.uid,
      gid = attributes.gid,
      rdev = -1,
      size = self.fs.size(path),
      blksize = 2048,
    }

    stat.blocks = math.ceil(stat.size / 512)
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

  local fs_mt = { __index = _node }

  -- register the filesystem type with the kernel
  k.register_fstype("managed", function(comp)
    if type(comp) == "table" and comp.type == "filesystem" then
      return setmetatable({fs = comp}, fs_mt)
    elseif type(comp) == "string" and component.type(comp) == "filesystem" then
      return setmetatable({fs = component.proxy(comp)}, fs_mt)
    end
  end)
end
