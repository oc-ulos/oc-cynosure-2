--[[
    Binary format registry through /proc/sys/fs/binfmt_misc/
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

k.log(k.L_INFO, "exec/binfmt")

do
  local procfs = k.state.procfs
  k.state.binfmt = {
    cex = {
      type = "CEX",
      magic = "onyC",
      offset = 0,
      interpreter = k.load_cex,
      flags = {P = true, C = true, O = true}
    }
  }
  
  procfs.registerDynamicFile("/binfmt", function()end, function(_, data)
    local name, mtype, offset, magic, mask, interpreter, flags = data:match(
        ":([^;]+):([^:]+):(%d-):([^:]+):(0x[%x]-):([^:]+):(.-)")
    if not name then return nil, k.errno.EINVAL end
    if mtype ~= "E" and mtype ~= "M" then return nil, k.errno.EINVAL end
    k.state.binfmt[name] = {
      type = mtype,
      extension = mtype == "E" and magic,
      magic = mtype == "M" and magic,
      offset = tonumber(offset) or 0,
      interpreter = interpreter,
      flags = {}
    }
    for c in flags:gmatch(".") do k.state.binfmt[name].flags[c] = true end
    if k.state.binfmt[name].flags.F then
      local err
      k.state.binfmt[name].interpreter, err = k.load_executable(interpreter)
      if not k.state.binfmt[name].interpreter then
        return nil, err
      end
    end
    if k.state.binfmt[name].flags.C then
      k.state.binfmt[name].flags.O = true
    end
    return true
  end)
end
