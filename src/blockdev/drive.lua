--[[
  Unmanaged drive block device support
  Copyright (C) 2022 Ocawesome101, Atirut-W

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

printk(k.L_INFO, "blockdev/drive")

do
  local drives = {}
  local byaddress = {}

  k.devfs.register_blockdev("drive", {
    init = function(addr)
      local index = 0

      while drives[index] do
        index = index + 1
      end

      local letter = string.char(string.byte("a") + index)
      local proxy = component.proxy(addr)
      drives[index] = true
      byaddress[addr] = index

      return ("hd%s"):format(letter), {
        stat = function()
          local size = proxy.getCapacity()
          return {
            dev = -1,
            ino = -1,
            mode = 0x6000 + k.perm_string_to_bitmap("rw-rw----"),
            nlink = 1,
            uid = 0,
            gid = 0,
            rdev = -1,
            size = size,
            blksize = 512,
            atime = 0,
            ctime = 0,
            mtime = 0
          }
        end,
      }
    end,

    destroy = function(addr)
      local letter = string.char(string.byte("a") + byaddress[addr])
      drives[byaddress[addr]] = nil
      byaddress[addr] = nil
      return ("hd%s"):format(letter)
    end,
  })
end
