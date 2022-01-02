--[[
    Main source file for the Cynosure kernel.
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

_G.k = { state = {}, common = {} }
--#include "src/version.lua"
--#include "src/cmdline.lua"
--#include "src/logger.lua"
--#include "src/checkArg.lua"
--@[{os.getenv('KPLATFORM') == 'oc' and '#include "src/bit32.lua"' or ''}]
--#include "src/errno.lua"
--#include "src/signals.lua"
--#include "src/syscalls.lua"
--#include "src/scheduler/main.lua"
--#include "src/evstream.lua"
--#include "src/devices.lua"
--#include "src/vfs/main.lua"
--#include "src/permissions.lua"
--@[{os.getenv('KUSE_SOFTWARE_TMPFS') == 'y' and '#include "src/tmpfs/soft.lua"' or 'src/tmpfs/hard.lua'}]
--@[{os.getenv('KINCLUDE_SYSFS') == 'y' and '#include "src/sysfs/main.lua"' or ''}]
--@[{os.getenv('KINCLUDE_PROCFS') == 'y' and '#include "src/procfs/main.lua"' or ''}]
--@[{os.getenv('KINCLUDE_DEVFS') == 'y' and '#include "src/devfs/main.lua"' or ''}]
--#include "src/exec/main.lua"
--#include "src/keymap.lua"
--#include "src/tty.lua"
k.log(k.L_INFO, "entering idle loop")
while true do k.pullSignal() end
