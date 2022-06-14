#!/usr/bin/env lua
local release = "2.0.0-"..(os.getenv("OS") or "custom")
local function sh(c)
  local h=io.popen(c,"r")local d=h:read("a")h:close()return d:gsub("\n","")
end
print(os.getenv("RELEASE") and release or release.."-"
  ..sh("git rev-parse --short HEAD"))
