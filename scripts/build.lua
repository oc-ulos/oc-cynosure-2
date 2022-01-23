--== Overly fancy build system ==--

local depcheck = require("scripts/requirable/depcheck")
local log = require("scripts/requirable/logger")

print(log.green .. ">" .. log.yellow .. " LBuild 1.0 " .. log.green
  .. "<" .. log.white)

local dirent = depcheck("posix.dirent")

local dir = "scripts/" .. (arg[1] or "build") .. "/"

local files = dirent.dir(dir)
for i=#files, 1, -1 do
  if files[i]:sub(1,1) == "." then table.remove(files, i) end
end

table.sort(files)
for i=1, #files, 1 do
  print(string.format("(%d/%d) ", i, #files) .. log.blue .. files[i] ..
    log.white)
  dofile(dir .. files[i])
end
