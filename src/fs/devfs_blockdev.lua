--[[
  Block device support
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

printk(k.L_INFO, "fs/devfs_blockdev")

do
  local handler = {}

  function k.devfs.register_blockdev(devtype, callbacks)
    handler[devtype] = callbacks
  end

  local function comp_added(_, addr, t)
    printk(k.L_DEBUG, ("component_added: %s %s"):format(addr, t))
    if handler[t] then
      local name, device = handler[t].init(addr)
      if name then
        k.devfs.register_device(name, device)
      end
    end
  end

  local function comp_removed(_, addr, t)
    printk(k.L_DEBUG, ("component_removed: %s %s"):format(addr, t))
    if handler[t] then
      local name = handler[t].destroy(addr)
      if name then
        k.devfs.unregister_device(name)
      end
    end
  end

  do
    local present = false

    k.devfs.register_blockdev("eeprom", {
      init = function(addr)
        if not present then
          present = true
          local eeprom = component.proxy(addr)
          return "eeprom", {
            stat = function()
              return {
                dev = -1,
                ino = -1,
                mode = 0x6000 + k.perm_string_to_bitmap("rw-rw----"),
                nlink = 1,
                uid = 0,
                gid = 0,
                rdev = -1,
                size = eeprom.getSize(),
                blksize = eeprom.getSize(), -- Idk the difference between this and size
                atime = 0,
                ctime = 0,
                mtime = 0
              }
            end
          }
        end
      end,
      destroy = function(addr)
        if present then
          present = false
          return "eeprom"
        end
      end,
    })
  end

  k.blacklist_signal("component_added")
  k.blacklist_signal("component_removed")

  k.add_signal_handler("component_added", comp_added)

  k.add_signal_handler("component_removed", comp_removed)

  for addr, ctype in component.list() do
    comp_added(nil, addr, ctype)
  end
end
