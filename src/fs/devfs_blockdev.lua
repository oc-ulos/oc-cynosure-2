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

    k.blacklist_signal("component_added")
    k.blacklist_signal("component_removed")

    k.add_signal_handler("component_added", function(_, address, type)
        printk(k.L_DEBUG, ("component_added: %s %s"):format(address, type))
        -- TODO Compare with registered handlers and register chardev.
    end)

    k.add_signal_handler("component_removed", function(_, address, type)
        printk(k.L_DEBUG, ("component_removed: %s %s"):format(address, type))
        -- TODO Compare with registered handlers and unregister chardev.
    end)
end
