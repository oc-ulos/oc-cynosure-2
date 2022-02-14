--[[
    Utilities for working with permissions
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

printk(k.L_INFO, "fs/permissions")

do
  local order = {
    0x001,
    0x002,
    0x004,
    0x008,
    0x010,
    0x020,
    0x040,
    0x080,
    0x100,
  }

  --- Takes a permissions string and returns its bitmap representation.
  --- e.g. rwxr-xr-x
  ---@param permstr string Permissions string in the format output by ls
  function k.perm_string_to_bitmap(permstr)
    checkArg(1, permstr, "string")

    if not permstr:match("[r%-][w%-][x%-][r%-][w%-][x%-][r%-][w%-][x%-]") then
      return nil, k.errno.EINVAL
    end

    local bitmap = 0

    for i=#order, 1, -1 do
      local index = #order - i + 1
      if permstr:sub(index, index) ~= "-" then
        bitmap = bit32.bor(bitmap, order[i])
      end
    end

    return bitmap
  end
end
