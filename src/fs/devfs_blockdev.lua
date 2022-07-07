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
          local romdata = eeprom.get()
          local romsize = eeprom.getSize()
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
                size = romsize,
                blksize = romsize, -- Idk the difference between this and size
                atime = 0,
                ctime = 0,
                mtime = 0
              }
            end,
            open = function(_, _, mode)
              local pos = 0
              if mode == "w" then
                romdata = ""
              end
              return {pos = pos, mode = mode}
            end,
            read = function(_, fd, len)
              -- printk(k.L_DEBUG, tostring(fd.pos))
              if fd.pos < romsize then
                local data = romdata:sub(fd.pos+1, math.min(romsize, fd.pos+len))
                fd.pos = fd.pos + len
                return data
              else
                return nil
              end
            end,
            write = function(_, fd, data)
              if fd.mode == "w" then
                romdata = (romdata .. data):sub(1, romsize)
                eeprom.set(romdata)
              end
            end,
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
      end
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
