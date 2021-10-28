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
--#include "src/errno.lua"
--#include "src/syscalls.lua"
--#include "src/scheduler.lua"
--#include "src/vfs/main.lua"
--#include "src/ramfs.lua"
--#include "src/sysfs/main.lua"
--#include "src/procfs/main.lua"
--#include "src/devfs/main.lua"
--#include "src/exec/binfmt.lua"
while true do computer.pullSignal() end
