--[[
    Cynosure's /sys file system.
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

--#include "src/ramfs.lua"
k.log(k.L_INFO, "sysfs/main")
do
  k.state.sysfs = k.common.ramfs.new("sysfs")
  k.state.mount_sources.sysfs = k.state.sysfs
  
  --[[
  
    Cynosure's sysfs is laid out like this:

    /sys/ - the root of the tree
      |- devices/ - platform-specific device nodes
      \- kernel/ - some kernel-specific things
            |- platform - the name of the platform this kernel was compiled for
            |- preempt_mode - the compiled-in preemption mode
            |- io_bufsize - the IO buffer size
            |- power - power control (write 2 to reboot, 1 to shutdown)
            |- keymap - the keymap the kernel is using
            \- name - the kernel name
  ]]
end
