--[[
    Managed filesystem support.
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

do
  -- use this command line argument if your server has the
  -- filesystem IO blocksize configured differently
  k.state.cmdline["fs.managed.blocksize"] =
    k.state.cmdline["fs.managed.blocksize"] or
    @[{os.getenv("MANAGED_BLOCKSIZE") or 2048}]
  local node = {}
  local blocksize = k.state.cmdline["fs.managed.blocksize"]

  -- file attributes are stored in .filename.attr
  -- so for example the attributes of /bin/ls are stored at /bin/.ls.attr
  -- and the attributes of /bin are stored at /.bin.attr
  -- mode, uid, gid, ctime, atime, mtime, size, nlink
  local attr = "<I2I2I2LLLL"
  -- if the file is a soft link, then the path is stored at the end
  -- of the inode data
  -- hard links are unsupported

  function node:_readpfile(file)
    local fd = self.fs.open(file:gsub("([^/]+)/?$", ".%1.attr"), "r")
    if not fd then
      return nil
    end
    local data = self.fs.read(fd, math.huge)
    self.fs.close(fd)
    return data
  end
  
  function node:_writepfile(file, data)
    local fd = self.fs.open(file:gsub("([^/]+)/?$", ".%1.attr"), "w")
    self.fs.write(fd, data)
    self.fs.close(fd)
  end

  function node:_attributes(file, new, raw)
    local data = self:_readpfile(file)
    local mode, uid, gid, ctime, atime, mtime, size, nlink
    if data then
      mode, uid, gid, ctime, atime, mtime, size = attr:unpack(data)
    end
    if new then
      mode, uid, gid, ctime, atime, mtime, size =
        new.mode or mode, new.uid or uid, new.gid or gid,
        new.ctime or ctime, new.atime or atime, new.mtime or mtime,
        new.size or size
      self:_writepfile(file, attr:pack(mode, uid, gid, ctime, atime, mtime,
        size) .. (new.path or ""))
    end
    if raw then
      return mode, uid, gid, ctime, atime, mtime, size,
        #data > 72 and data:sub(73), file
    else
      return {
        mode = mode,
        uid = uid,
        gid = gid,
        ctime = ctime,
        atime = atime,
        mtime = mtime,
        size = size,
        file = file,
        path = #data > 72 and data:sub(73)
      }
    end
  end

  function node:stat(file)
    local attr = self:_attributes(file)
    return {
      ino = -1,
      mode = attr.mode,
      nlink = 1,
      uid = attr.uid,
      gid = attr.gid,
      size = attr.size,
      blksize = blocksize,
      blocks = math.ceil(attr.size / blocksize),
      atime = attr.atime,
      mtime = attr.mtime,
      ctime = attr.ctime
    }
  end

  local function parent(path)
    local s = k.common.split_path(path)
    return "/" .. table.concat(s, "/", 1, s.n - 1)
  end
  
  function node:_create(path, mode)
    local p = parent(path)
    if not (self.fs.exists(p) and self.fs.isDir(p)) then
      return nil, k.errno.ENOENT
    end
    if mode & 0xF000 == k.common.fsmodes.f_directory then
      self.fs.makeDirectory(path)
    else
      self.fs.close(self.fs.open(path, "w"))
    end
    local parent = self:_attributes(p)
    self:_attributes(path, {
      mode = mode,
      uid = k.syscall.getuid(),
      gid = (mode & k.common.fsmodes.setgid ~= 0) and parent.gid or
        k.syscall.getgid(),
      ctime = os.time(),
      mtime = os.time(),
      atime = os.time(),
      size = 0,
    })
    return true
  end

  function node:mkdir(path, mode)
    return self:_create(path, mode | k.common.fsmodes.f_directory)
  end

  function node:open(file, flags, mode)
    if not self.fs.exists(file) then
      if not flags.creat then
        return nil
      else
        local ok, err = self:_create(file, mode)
        if not ok and err then
          return nil, err
        end
      end
    end
    local attr = self:_attributes(file)
    if attr.mode & 0xF000 == k.common.fsmodes.f_directory then
      return nil, k.errno.EISDIR
    end
    local mode = ""
    if flags.rdonly then mode = "r" end
    if flags.wronly then mode = "w" end
    if flags.rdwr then mode = "rw" end
    local fd = self.fs.open(file, mode)
    if not fd then
      return nil, k.errno.ENOENT
    end
    local n = #self.fds+1
    self.fds[n] = fd
    return n
  end

  function node:read(fd, count)
    local data = ""
    repeat
      local chunk = self.fs.read(fds[fd], count)
      data = data .. chunk
      count = count - #chunk
    until count <= 0
    return data
  end

  function node:write(fd, data)
    return self.fs:write(self.fds[fd], data)
  end

  function node:seek(fd, whence, offset)
    return self.fs:seek(self.fds[fd], whence, offset)
  end

  function node:close(fd)
    if self.fds[fd] then
      self.fs:close(self.fds[fd])
    end
  end

  function node:unlink(path)
    self.fs.remove(path)
  end

  k.state.fs_types.managed = {
    create = function(fsnode)
      return setmetatable({fs = fsnode, }, {__index = node})
    end
  }
end
