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
      O_RDONLY = true
    })
  end

  local function parse_cex(string)
  end

  local function load_cex(file)
    return parse_cex(read_file(file))
  end
end
