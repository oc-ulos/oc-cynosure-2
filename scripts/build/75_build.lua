-- actually assemble the kernel

local log = require("scripts/requirable/logger")

print(log.indent .. "Assembling kernel")

local preproc = assert(loadfile("scripts/preproc.lua"))

os.execute("rm -r ./pkg")
os.execute("mkdir -p ./pkg/boot")

preproc("src/main.lua", "pkg/boot/cynosure.lua", "-strip-comments")
