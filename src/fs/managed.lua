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
  local attr = "<I2I2I2LLLLI2"
  -- but, if the file is a hard link, then its attributes contain the
  -- string "LINK" followed by a path, ex. /.bin.attr could contain
  -- "LINK/usr/bin"
  -- or, if the file is a soft link, then the path is stored at the end
  -- of the inode data

  function node:_readpfile(file)
    local fd = self.fs.open(file:gsub("([^/+])$", ".%1.attr"), "r")
    if not fd then
      return nil
    end
    local data = self.fs.read(fd, math.huge)
    self.fs.close(fd)
    return data
  end
  
  function node:_writepfile(file, data)
    local fd = self.fs.open(file:gsub("([^/+])$", ".%1.attr"), "w")
    self.fs.write(fd, data)
    self.fs.close(fd)
  end

  function node:_attributes(file, new, raw)
    local data = self:_readpfile(file)
    local mode, uid, gid, ctime, atime, mtime, size, nlink
    if data then
      if data:sub(1,4) == "LINK" then
        file = data:sub(5)
        mode, uid, gid, ctime, atime, mtime, size, nlink =
          self:_attributes(file, nil, true)
      else
        mode, uid, gid, ctime, atime, mtime, size, nlink = attr:unpack(data)
      end
    end
    if new then
      mode, uid, gid, ctime, atime, mtime, size, nlink =
        new.mode or mode, new.uid or uid, new.gid or gid,
        new.ctime or ctime, new.atime or atime, new.mtime = mtime,
        new.size or size, new.nlink or nlink
      self:_writepfile(file, attr:pack(mode, uid, gid, ctime, atime, mtime,
        size, nlink) .. (new.path or ""))
    end
    if raw then
      return mode, uid, gid, ctime, atime, mtime, size, nlink
    else
      return {
        mode = mode,
        uid = uid,
        gid = gid,
        ctime = ctime,
        atime = atime,
        mtime = mtime,
        size = size,
        nlink = nlink,
        path = #data > 72 and data:sub(72)
      }
    end
  end

  function node:stat(file)
    local attr = self:_attributes(file)
    return {
      ino = -1,
      mode = attr.mode,
      nlink = attr.nlink,
      uid = attr.uid,
      gid = attr.gid,
      size = attr.size,
      blksize = k.,
      blocks = 
    }
  end

  function node:open(file, flags, mode)
    local fd = 
  end
end
