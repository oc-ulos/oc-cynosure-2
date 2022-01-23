-- load configuration

local conflib = require("scripts/requirable/config")
local log = require("scripts/requirable/logger")

print(log.indent .. "Loading " .. log.yellow .. ".config" .. log.white)
_G.bconf = conflib.load(".defconfig")
