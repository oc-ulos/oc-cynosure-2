-- actually assemble the kernel

local log = require("scripts/requirable/logger")

print(log.indent .. "Assembling kernel")

local preproc = assert(loadfile("scripts/preproc.lua"))

preproc("src/main.lua", "kernel.lua", "-strip-comments")
