-- base ramfs node --

do
  local _ramfs = {}

  function _ramfs:_resolve(path, parent)
    local segments = k.common.split_path(path)
    local current = self.tree
    for i=1, #segments - (parent and 1 or 0), 1 do
      if not current.children then
        return nil, k.errno.ENOTDIR
      elseif current.children[segments[i]] then
        current = current.children[segments[i]]
      else
        return nil, k.errno.EEXIST
      end
    end
    return current, parent and segments[#segments]
  end

  function _ramfs:stat(path)
    checkArg(1, path, "string")
    local fblk, err = self:_resolve(path)
    if not fblk then
      return nil, err
    end
    return {
      ino = -1,
      mode = fblk.mode,
      nlink = fblk.nlink,
      uid = fblk.uid,
      gid = fblk.gid,
      size = fblk.size,
      blksize = -1,
      blocks = math.ceil(fblk.size / 512),
      atime = fblk.atime,
      mtime = fblk.mtime,
      ctime = fblk.ctime
    }
  end

  function _ramfs:open(file, flags, mode)
    checkArg(1, file, "string")
    checkArg(2, flags, "table")
    checkArg(3, mode, "number", "nil")
    local node, err = self:_resolve(file)
    if not node then
      if flags.creat then
        checkArg(3, mode, "number")
        local parent, name = self:_resolve(file, true)
        if not parent then
          return nil, name
        end
        parent.children[name] = {
          mode = k.common.fsmodes.f_regular |
                 k.common.fsmodes.owner_r |
                 k.common.fsmodes.owner_w |
                 k.common.fsmodes.group_r |
                 k.common.fsmodes.other_r,
          uid = k.syscall.getuid() or 0,
          gid = k.syscall.getgid() or 0,
          ctime = os.time(),
          mtime = os.time(),
          atime = os.time(),
          data = "",
          size = 0,
          nlink = 1
        }
        node = parent.children[name]
      else
        return nil, err
      end
    end
  end

  function _ramfs.new()
    return setmetatable({
      tree = {children = {}},
    }, {__index = _ramfs})
  end
end
