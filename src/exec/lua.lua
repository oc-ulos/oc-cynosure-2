--[[
  Lua loader
  Copyright (C) 2022 Ocawesome101, Atirut

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

printk(k.L_INFO, "exec/lua")

do
  k.register_executable_format("lua", function(header)
    return header:sub(1, 6) == "--!lua"
  end, function(fd, env)
    local chunk = ""
    repeat
      local data = k.read(fd, math.huge)
      chunk = chunk .. (data or "")
    until not data

    chunk = k.load(chunk, "=lua", "t", env)
    if not chunk then return nil, k.errno.ENOEXEC else return chunk end
  end)
end
