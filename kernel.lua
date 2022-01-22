
local k = {}
do
k.cmdline = {}
local _args = table.pack(...)
k.original_cmdline = table.concat(_args, " ", 1, _args.n)
for i, arg in ipairs(_args) do
local key, val = arg, true
if arg:find("=") then
key, val = arg:match("^(.-)=(.+)$")
if val == "true" then val = true
elseif val == "false" then val = false
else val = tonumber(val) or val end
end
local ksegs = {}
for ent in key:gmatch("[^%.]+") do
ksegs[#ksegs+1] = ent
end
local cur = k.cmdline
for i=1, #ksegs-1, 1 do
k.cmdline[ksegs[i]] = k.cmdline[ksegs[i]] or {}
cur = k.cmdline[ksegs[i]]
end
cur[ksegs[#ksegs]] = val
end
end
do
local gpu, screen
for addr in component.list("gpu") do
screen = component.invoke(addr, "getScreen")
if screen then
gpu = component.proxy(addr)
break
end
end
if not gpu then
gpu = component.list("gpu")()
screen = component.list("screen")()
end
if gpu then
if type(gpu) == "string" then gpu = component.proxy(gpu) end
gpu.bind(screen)
local w, h = gpu.getResolution()
local current_line = 0
function k.log_to_screen(message)
while #message > 0 do
local line = message:sub(1, w)
message = message:sub(#line + 1)
current_line = current_line + 1
if current_line > h then
gpu.copy(1, 1, w, h, 0, -1)
gpu.fill(1, h, w, 1, " ")
end
gpu.set(1, current_line, line)
end
end
else
k.log_to_screen = function() end
end
local log_buffer = {}
local function log_to_buffer(message)
log_buffer[#log_buffer + 1] = message
if #log_buffer > computer.totalMemory() / 1024 then
table.remove(log_buffer, 1)
end
end
k.L_EMERG   = 0
k.L_ALERT   = 1
k.L_CRIT    = 2
k.L_ERROR   = 3
k.L_WARNING = 4
k.L_NOTICE  = 5
k.L_INFO    = 6
k.L_DEBUG   = 7
k.cmdline.loglevel = tonumber(k.cmdline.loglevel) or 8
function k.printk(level, fmt, ...)
local message = string.format(fmt, ...)
if level <= k.cmdline.loglevel then
k.log_to_screen(message)
end
k.log_to_buffer(message)
end
end
