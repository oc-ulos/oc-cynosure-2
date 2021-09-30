-- CEX loading --

do
  local magic = 0x43796e6f
  local flags = {
    lua53 = 0x1,
    static = 0x2,
    bootable = 0x4,
    executable = 0x8,
    library = 0x10
  }

  local function read_file(file)
    local handle, err = k.syscalls.open(file, {
      rdonly = true
    })
    
    if not handle then
      return nil, err
    end
    
    local data = k.syscalls.read(handle, math.huge)
    k.syscalls.close(handle)
    
    return data
  end

  local _flags = {
    lua53 = 0x1,
    static = 0x2,
    boot = 0x4,
    exec = 0x8,
    library = 0x10,
  }

  local function parse_cex(str)
    local header, str = k.util.pop(str, 4)
    if header ~= "onyC" then
      return nil, "invalid magic number"
    end

    local flags, str = k.util.pop(str, 1)
    flags = flags:byte()
    local osid, str = k.util.pop(str, 1)
    osid = osid:byte()

    if osid ~= 0 and isod ~= 255 then
      return nil, "bad OSID"
    end
  end

  local function load_cex(file)
    return parse_cex(read_file(file))
  end
end
