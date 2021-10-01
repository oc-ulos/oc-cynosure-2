-- main kernel source file --

_G.k = { state = {}, common = {} }
--#include "src/version.lua"
--#include "src/cmdline.lua"
--#include "src/logger.lua"
--#include "src/checkArg.lua"
--#include "src/syscalls.lua"
--#include "src/scheduler.lua"
--#include "src/vfs/main.lua"
--#include "src/ramfs.lua"
--#include "src/sysfs/main.lua"
--#include "src/procfs/main.lua"
--#include "src/devfs/main.lua"
--#include "src/exec/cex.lua"
while true do computer.pullSignal() end
