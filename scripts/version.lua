#!/usr/bin/env lua
local function sh(c)
  local h=io.popen(c,"r")local d=h:read("a")h:close()return d:gsub("\n","")
end
local release = sh("cat version").."-"..(os.getenv("OS") or "custom")
print(os.getenv("RELEASE") and release or release.."-"
  ..sh("git rev-parse --short HEAD"))
