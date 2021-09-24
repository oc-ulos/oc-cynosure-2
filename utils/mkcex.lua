#!/usr/bin/env lua
-- generate a CEX file --

local args = table.pack(...)

local usage = [[
usage: mkcex [options] INFILE OUTFILE
Create a CEX file from a Lua script, following the
provided options.
  -link FILE    Repeat as many times as necessary to link to a file.
  -lua53        Requires Lua 5.3
  -bootable     Is bootable
  -executable   Is executable
  -library      Usable as a library
]]

local magic = 0x43796e6f

local pflags = {
  lua53 = 0x1,
  static = 0x2,
  bootable = 0x4,
  executable = 0x8,
  library = 0x10
}
local flags = 0

local link = {}
local infile, outfile
local ignext = false
for i, arg in ipairs(args) do
  if ignext then
    link[#link+1] = arg
  else
    if arg:sub(1,1) == "-" then
      if pflags[arg:sub(2)] then
        if arg == "-static" then
          io.stderr:write("mkcex: static linking is not possible\n")
          os.exit(1)
        end
        flags = flags | pflags[arg:sub(2)]
      elseif arg == "-link" then
        ignext = true
      elseif arg == "-help" then
        io.stderr:write(usage)
        os.exit(0)
      else
        io.stderr:write("mkcex: invalid option '", arg:sub(2), "'\n")
        os.exit(1)
      end
    else
      if infile then outfile = arg
      else infile = arg end
    end
  end
end

if not (infile and outfile) then
  io.stderr:write(usage)
  os.exit(1)
end

local header = string.pack("<I4I1I1", magic, flags, #link)
for i=1, #link, 1 do
  io.stderr:write("mkcex: linking to ", link[i], "\n")
  header = header .. string.pack("<I1", #link[i])
            .. string.pack("<c"..#link[i], link[i])
end

local data = assert(io.open(infile, "r")):read("a")
header = header .. string.pack("<I2", #data)

assert(io.open(outfile, "w")):write(header, data):close()
