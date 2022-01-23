
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
gpu.fill(1, 1, w, h, " ")
local current_line = 0
function k.log_to_screen(lines)
for message in lines:gmatch("[^\n]+") do
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
function printk(level, fmt, ...)
local message = string.format("[%08.02f] ", computer.uptime()) ..
string.format(fmt, ...)
if level <= k.cmdline.loglevel then
k.log_to_screen(message)
end
log_to_buffer(message)
end
local pullSignal = computer.pullSignal
function panic(reason)
printk(k.L_EMERG, reason)
while true do pullSignal() end
end
end
printk(k.L_INFO, "checkArg")
do
function _G.checkArg(n, have, ...)
have = type(have)
local function check(want, ...)
if not want then
return false
else
return have == want or check(...)
end
end
if type(n) == "number" then n = string.format("#%d", n)
else n = "'"..tostring(n).."'" end
if not check(...) then
local name = debug.getinfo(3, 'n').name
local msg
if name then
msg = string.format("bad argument %s to '%s' (%s expected, got %s)",
n, name, table.concat(table.pack(...), " or "), have)
else
msg = string.format("bad argument %s (%s expected, got %s)", n,
table.concat(table.pack(...), " or "), have)
end
error(msg, 2)
end
end
end
printk(k.L_INFO, "errno")
do
k.errno = {
EPERM = 1,
ENOENT = 2,
ESRCH = 3,
EINTR = 4,
EIO = 5,
ENXIO = 6,
E2BIG = 7,
ENOEXEC = 8,
EBADF = 9,
ECHILD = 10,
EAGAIN = 11,
ENOMEM = 12,
EACCES = 13,
EFAULT = 14,
ENOTBLK = 15,
EBUSY = 16,
EEXIST = 17,
EXDEV = 18,
ENODEV = 19,
ENOTDIR = 20,
EISDIR = 21,
EINVAL = 22,
ENFILE = 23,
EMFILE = 24,
ENOTTY = 25,
ETXTBSY = 26,
EFBIG = 27,
ENOSPC = 28,
ESPIPE = 29,
EROFS = 30,
EMLINK = 31,
EPIPE = 32,
EDOM = 33,
ERANGE = 34,
EDEADLK = 35,
ENAMETOOLONG = 36,
ENOLCK = 37,
ENOSYS = 38,
ENOTEMPTY = 39,
ELOOP = 40,
EWOULDBLOCK = 11,
ENOMSG = 42,
EIDRM = 43,
ECHRNG = 44,
EL2NSYNC = 45,
EL3HLT = 46,
EL3RST = 47,
ELNRNG = 48,
EUNATCH = 49,
ENOCSI = 50,
EL2HLT = 51,
EBADE = 52,
EBADR = 53,
EXFULL = 54,
ENOANO = 55,
EBADRQC = 56,
EBADSLT = 57,
EDEADLOCK = 35,
EBFONT = 59,
ENOSTR = 60,
ENODATA = 61,
ETIME = 62,
ENOSR = 63,
ENONET = 64,
ENOPKG = 65,
EREMOTE = 66,
ENOLINK = 67,
EADV = 68,
ESRMNT = 69,
ECOMM = 70,
EPROTO = 71,
EMULTIHOP = 72,
EDOTDOT = 73,
EBADMSG = 74,
EOVERFLOW = 75,
ENOTUNIQ = 76,
EBADFD = 77,
EREMCHG = 78,
ELIBACC = 79,
ELIBBAD = 80,
ELIBSCN = 81,
ELIBMAX = 82,
ELIBEXEC = 83,
EILSEQ = 84,
ERESTART = 85,
ESTRPIPE = 86,
EUSERS = 87,
ENOTSOCK = 88,
EDESTADDRREQ = 89,
EMSGSIZE = 90,
EPROTOTYPE = 91,
ENOPROTOOPT = 92,
EPROTONOSUPPORT = 93,
ESOCKTNOSUPPORT = 94,
EOPNOTSUPP = 95,
EPFNOSUPPORT = 96,
EAFNOSUPPORT = 97,
EADDRINUSE = 98,
EADDRNOTAVAIL = 99,
ENETDOWN = 100,
ENETUNREACH = 101,
ENETRESET = 102,
ECONNABORTED = 103,
ECONNRESET = 104,
ENOBUFS = 105,
EISCONN = 106,
ENOTCONN = 107,
ESHUTDOWN = 108,
ETOOMANYREFS = 109,
ETIMEDOUT = 110,
ECONNREFUSED = 111,
EHOSTDOWN = 112,
EHOSTUNREACH = 113,
EALREADY = 114,
EINPROGRESS = 115,
ESTALE = 116,
EUCLEAN = 117,
ENOTNAM = 118,
ENAVAIL = 119,
EISNAM = 120,
EREMOTEIO = 121,
EDQUOT = 122,
ENOMEDIUM = 123,
EMEDIUMTYPE = 124,
ECANCELED = 125,
ENOKEY = 126,
EKEYEXPIRED = 127,
EKEYREVOKED = 128,
EKEYREJECTED = 129,
EOWNERDEAD = 130,
ENOTRECOVERABLE = 131,
ERFKILL = 132,
EHWPOISON = 133,
ENOTSUP = 95,
}
end
printk(k.L_INFO, "tty")
do
local _tty = {}
local colors = {
0x000000,
0xaa0000,
0x00aa00,
0xaaaa00,
0x0000aa,
0xaa00aa,
0x00aaaa,
0xaaaaaa,
0x555555,
0xff5555,
0x55ff55,
0xffff55,
0x5555ff,
0xff55ff,
0x55ffff,
0xffffff
}
local nocsi = {}
local commands = {}
local oscommand = {}
local controllers = {}

  local function scroll(self, n)
self.scr.scroll(n, self.scrolltop, self.scrollbot)
end
function nocsi:c()
self.fg = colors[8]
self.bg = colors[1]
self.scr.setForeground(colors[8])
self.scr.setBackground(colors[1])
self.scr.fill(1, 1, self.w, self.h, " ")
end
function nocsi:D()
self.cy = self.cy + 1
end
function nocsi:E()
self.cx, self.cy = 1, self.cy + 1
end
function nocsi:M()
self.cy = self.cy - 1
end
function nocsi:Z()
self.rbuf = self.rbuf .. "\27[?6c"
end
local save = {"fg", "bg", "echo", "line", "raw", "cx", "cy"}
nocsi["7"] = function(self)
self.saved = {}
for i=1, #save, 1 do
self.saved[save[i]] = self[save[i]]
end
end
nocsi["8"] = function(self)
if self.saved then
for i=1, #save, 1 do
self[save[i]] = self.saved[save[i]]
self.scr.setForeground(self.fg)
self.scr.setBackground(self.bg)
end
end
end

  function commands:A(args)
local n = args[1] or 1
self.cy = self.cy - n
end
function commands:B(args)
local n = args[1] or 1
self.cy = self.cy + n
end

  function commands:C(args)
local n = args[1] or 1
self.cx = self.cx + n
end
function commands:D(args)
local n = args[1] or 1
self.cx = self.cx - n
end
function commands:E(args)
local n = args[1] or 1
self.cx, self.cy = 1, self.cy + n
end
function commands:F(args)
local n = args[1] or 1
self.cx, self.cy = 1, self.cy - n
end
function commands:G(args)
local n = args[1] or 1
self.cx = math.max(1, math.min(self.w, n))
end
function commands:H(args)
local row, col = args[1] or 1, args[2] or 1
self.cx = math.max(1, math.min(self.w, col))
self.cy = math.max(1, math.min(self.h, row))
end
function commands:J(args)
local n = args[1] or 0
if n == 0 then
self.scr.fill(1, self.cy, self.w, self.h - self.cy, " ")
elseif n == 1 then
self.scr.fill(1, self.cx, self.w, self.cy, " ")
elseif n == 2 then
self.scr.fill(1, 1, self.w, self.h, " ")
end
end
function commands:K(args)
local n = args[1] or 0
if n == 0 then
self.scr.fill(self.cx, self.cy, self.w - self.cx, 1, " ")
elseif n == 1 then
self.scr.fill(1, self.cy, self.cx, 1, " ")
elseif n == 2 then
self.scr.fill(1, self.cy, self.w, 1, " ")
end
end
function commands:L(args)
local n = args[1] or 1
self.scr.scroll(n, self.cy)  end
function commands:M(args)
local n = args[1] or 1
self.scr.scroll(-1, self.cy)  end
function commands:P(args)
local n = args[1] or 1
self.scr.copy(self.cx + n, self.cy, self.w - self.cx, 1, -n, 0)
self.scr.fill(self.w - n, self.cy, n, 1, " ")
end
function commands:X(args)
local n = args[1] or 1
self.scr.fill(self.cx, self.cy, n, 1, " ")
end
function commands:a(args)
local n = args[1] or 1
self.cx = self.cx + n
end
function commands:c()
self.rbuf = self.rbuf .. "\27[?6c"
end
function commands:d(args)
local n = args[1] or 1
self.cy = math.max(1, math.min(self.h, n))
end
function commands:e(args)
local n = args[1] or 1
self.cy = self.cy + n
end
commands.f = commands.H
local function hl(set, args)
for i=1, #args, 1 do
local n = args[i]
if n == 1 then
self.altcursor = set
elseif n == 3 then
self.showctrl = set
elseif n == 9 then
self.mousereport = set and 1 or 0
elseif n == 20 then
self.autocr = set
elseif n == 25 then
self.cursor = set
elseif n == 1000 then
self.mousereport = set and 2 or 0
end
end
end

  function commands:h(args)
hl(true, args)
end

  function commands:l()
hl(false, args)
end
function commands:m(args)
args[1] = args[1] or 0
for i=1, #args, 1 do
local n = args[1]
if n == 7 or n == 27 then
self.fg, self.bg = self.bg, self.fg
self.scr.setForeground(self.fg)
self.scr.setBackground(self.bg)
elseif n > 29 and n < 38 then
self.fg = colors[n - 29]
self.scr.setForeground(self.fg)
elseif n > 89 and n < 98 then
self.fg = colors[n - 81]
self.scr.setForeground(self.fg)
elseif n > 39 and n < 48 then
self.bg = colors[n - 39]
self.scr.setForeground(self.bg)
elseif n > 99 and n < 108 then
self.bg = colors[n - 91]
self.scr.setForeground(self.bg)
elseif n == 39 then
self.fg = colors[8]
self.scr.setForeground(self.fg)
elseif n == 49 then
self.bg = colors[1]
self.scr.setForeground(self.bg)
end
end
end
function commands:n(args)
local n = args[1] or 0
if n == 5 then
self.rbuf = self.rbuf .. "\27[0n"
elseif n == 6 then
self.rbuf = self.rbuf .. string.format("\27[%d;%dR", self.cy, self.cx)
end
end
function commands:r(args)
local top, bot = args[1] or 1, args[2] or self.h
self.scrolltop = math.max(1, math.min(top, self.h))
self.scrollbot = math.min(self.h, math.max(1, bot))
end
function commands:s()
self.saved = self.saved or {}
self.saved.cx = self.cx
self.saved.cy = self.cy
end
function commands:u()
self.saved = self.saved or {}
self.cx = self.saved.cx
self.cy = self.saved.cy
end
commands["`"] = function(args)
local n = args[1] or 1
self.cx = math.max(1, math.min(self.w, n))
end
local function corral(self)
while self.cx < 1 do
self.cx = self.cx + self.w
self.cy = self.cy - 1
end
while self.cx > self.w do
self.cx = self.cx - self.w
self.cy = self.cy + 1
end
while self.cy < self.scrolltop do
scroll(self, -1)
self.cy = self.cy + 1
end
while self.cy > self.scrollbot do
scroll(self, 1)
self.cy = self.cy + 1
end
end
local function textwrite(self, text)
while #text > 0 do
local nl = text:find("\n") or #text
local line = text:sub(1, nl)
text = text:sub(#line + 1)
local nnl = line:sub(-1) == "\n"
while #line > 0 do
local chunk = line:sub(1, self.w - self.cx + 1)
line = line:sub(#chunk + 1)
self.scr.set(self.cx, self.cy, chunk)
self.cx = self.cx + #chunk
corral(self)
end
if nnl then
self.cx = 1
self.cy = self.cy + 1
end
corral(self)
end
end
local function internalwrite(self, line)
line = line:gsub("\x9b", "\27[")
while #line > 0 do
local nesc = line:find("\27", nil, true)
local e = (nesc and nesc - 1) or #str
local chunk = line:sub(1, e)
line = line:sub(#chunk + 1)
textwrite(self, chunk)

      if nesc then
local css, params, csc, len
= line:match("^\27(.)([%d;]*)([%a%d`])()")

        if css and params and csc and len then
line = line:sub(len)

          local args = {}
local num = ""
local plen = #params
for c, pos in params:gmatch(".()") do
if c == ";" then
args[#args+1] = tonumber(num) or 0
num = ""
else
num = num .. c
if pos == plen then
args[#args+1] = tonumber(num) or 0
end
end
end

          if css == "[" then
local func = commands[csc]
if func then func(self, args) end
elseif css == "]" or css == "?" then
local func = controllers[csc]
if func then func(self, args) end
elseif css == "#" then            self.scr.fill(1, 1, self.w, self.h, "E")
else
local func = nocsi[css]
if func then func(self, args) end
end
end
end
end
end
local function togglecursor(self)
if not self.cursor then return end
local cc, cf, cb = self.scr.get(self.cx, self.cy)
self.scr.setForeground(cb)
self.scr.setBackground(cf)
self.scr.set(self.cx, self.cy, cc)
end
function _tty:write(str)
checkArg(1, str, "string")
self.wbuf = self.wbuf .. str
local dc = (not not self.wbuf:find("\n", nil, true)) or #self.wbuf > 512
if dc then togglecursor(self) end

    repeat
local idx = self.wbuf:find("\n")
if not idx then if #self.wbuf > 512 then idx = #self.wbuf end end
if idx then
local chunk = self.wbuf:sub(1, idx)
self.wbuf = self.wbuf:sub(#chunk + 1)
internalwrite(self, chunk)
end
until not idx

    if dc then togglecursor(self) end
end
function _tty:flush()
local dc = #self.wbuf > 0
if dc then togglecursor(self) end
internalwrite(self, chunk)
if dc then togglecursor(self) end
end
local scancode_lookups = {
[200] = "A",
[208] = "B",
[205] = "C",
[203] = "D"
}
function k.open_tty(gpu, screen)
checkArg(1, gpu, "string", "table")
checkArg(2, screen, "string", "nil")
if type(gpu) == "string" then gpu = component.proxy(gpu) end
screen = screen or gpu.getScreen()
local w, h = gpu.getResolution()

    local new = {
gpu = gpu,
w = w, h = h, cx = 1, cy = 1,
scrolltop = 1, scrollbot = h,
rbuf = "", wbuf = "",
fg = colors[1], bg = colors[8],
altcursor = false, showctrl = false,
mousereport = 0, autocr = false,
cursor = true,
}
local keyboards = {}
for _, kbaddr in pairs(component.invoke(screen, "getKeyboards")) do
keyboards[kbaddr] = true
end
new.khid = k.sig_add_handler("key_down", function(_, kbd, char, code)
if not keyboards[kbd] then return end
local to_screen, to_buffer
if scancode_lookups[code] then

      end
end)
setmetatable(new, {__index = _tty})
return new
end
end
printk(k.L_INFO, "buffer")
do
local buffer = {}
local bufsize = tonumber(k.cmdline["io.bufsize"])
or 512
function buffer:readline()
if self.bufmode == "none" then
if self.stream.readline then
return self.stream:readline()
else
local dat = ""

        repeat
local n = self.stream:read(1)
dat = dat .. (n or "")
until n == "\n" or not n

        return dat
end

    else

      while not self.rbuf:match("\n") do
local chunk = self.stream:read(bufsize)
if not chunk then break end
self.rbuf = self.rbuf .. chunk
end
local n = self.rbuf:find("\n") or #self.rbuf

      local dat = self.rbuf:sub(1, n)
self.rbuf = self.rbuf:sub(n + 1)

      return dat
end
end
function buffer:readnum()
local dat = ""
if self.bufmode == "none" then
error(
"bad argument to 'read' (format 'n' not supported in unbuffered mode)",
0)
end

    local breakonwhitespace = false
while true do
local ch = self:readn(1)
if not ch then
break
end
if ch:match("[%s]") then
if breakonwhitespace then
self.rbuf = ch .. self.rbuf
break
end
else
breakonwhitespace = true

        if not tonumber(dat .. ch .. "0") then
self.rbuf = ch .. self.rbuf
break
end
dat = dat .. ch
end
end
return tonumber(dat)
end
function buffer:readn(n)
while #self.rbuf < n do
local chunk = self.stream:read(n)
if not chunk then break end

      self.rbuf = self.rbuf .. chunk
n = n - #chunk
end
local data = self.rbuf:sub(1, n)
self.rbuf = self.rbuf:sub(n + 1)
return data
end
function buffer:readfmt(fmt)
if type(fmt) == "number" then
return self:readn(fmt)
else
fmt = fmt:gsub("%*", "")
if fmt == "a" then        return self:readn(math.huge)
elseif fmt == "l" then        local line = self:readline()
return line:gsub("\n$", "")
elseif fmt == "L" then        return self:readline()
elseif fmt == "n" then        return self:readnum()
else        error("bad argument to 'read' (format '"..fmt.."' not supported)", 0)
end
end
end
local function chvarargs(...)
local args = table.pack(...)
for i=1, args.n, 1 do
checkArg(i, args[i], "string", "number")
end
return args
end
function buffer:read(...)
local args = chvarargs(...)
local ret = {}
for i=1, args.n, 1 do
ret[#ret+1] = self:readfmt(args[i])
end
return table.unpack(ret, 1, args.n)
end
function buffer:write(...)
local args = chvarargs(...)
for i=1, args.n, 1 do
self.wbuf = self.wbuf .. tostring(args[i])
end
local dat
if self.bufmode == "full" then
if #self.wbuf <= bufsize then
return self
end

      dat = self.wbuf
self.wbuf = ""

    elseif self.bufmode == "line" then
local lastnl = #self.wbuf - (self.wbuf:reverse():find("\n") or 0)

      dat = self.wbuf:sub(1, lastnl)
self.wbuf = self.wbuf:sub(lastnl + 1)

    else
dat = self.wbuf
self.wbuf = ""
end
self.stream:write(dat)
return self
end
function buffer:seek(whence, offset)
checkArg(1, whence, "string", "nil")
checkArg(2, offset, "number", "nil")
self:flush()
if self.stream.seek then
return self.stream:seek(whence or "cur", offset)
end
return nil, k.errno.EBADF
end
function buffer:flush()
if #self.wbuf > 0 then
self.stream:write(self.wbuf)
self.wbuf = ""
end
return true
end
function buffer:close()
self.closed = true
if self.stream.close then
self.stream:close()
end
end
function k.buffer_from_stream(stream, mode)
checkArg(1, stream, "table")
checkArg(2, mode, "string")
return setmetatable({
stream = stream,
call = ":",
mode = k.common.charize(mode),
rbuf = "",
wbuf = "",
bufmode = "full"
}, {__index = buffer})
end
end
printk(k.L_INFO, "scheduler/process")
do
local process = {}
local default = {n = 0}
function process:resume(sig, ...)
if self.stopped then return end
local resumed = false
if sig and #self.queue < 256 then
self.queue[#self.queue + 1] = sig
end
local signal = default
if #self.queue > 0 then
signal = table.remove(self.queue, 1)
end
for i, thread in pairs(self.threads) do
local result = thread:resume(table.unpack(signal, 1, signal.n))
resumed = resumed or not not result
if result == 1 then
self.threads[i] = nil
table.insert(self.queue, {"thread_died", i})
end
end
return resumed
end
function process:add_thread(thread)
self.threads[self.pid + self.thread_count] = thread
self.thread_count = self.thread_count + 1
end
function process:deadline()
local deadline = math.huge
for i, thread in pairs(self.threads) do
if thread.deadline < deadline then
deadline = thread.deadline
end
if thread.status == "S" or thread.status == "y" then
return -1
end
if thread.status == "w" and #self.queue > 0 then
return -1
end
end
return deadline
end
local process_mt = { __index = process }
local default = {handles = {}, _G = {}, pid = 0}
function k.create_process(pid, parent)
parent = parent or default
return setmetatable({
queue = {},
stopped = false,
threads = {},

      pid = pid,
ppid = parent.pid,

      pgid = parent.pgid or 0,
sid = parent.sid or 0,
uid = parent.uid or 0,
gid = parent.gid or 0,
euid = parent.euid or 0,
egid = parent.egid or 0,
suid = parent.uid or 0,
sgid = parent.gid or 0,
tty = false,
}, process_mt)
end
end
printk(k.L_INFO, "scheduler/loop")
do
local processes = {}
local pid = 0
local current = 0
local default = {n=0}
function k.scheduler_loop()
local last_yield = 0
while processes[1] do
local deadline = 0
for cpid, process in pairs(processes) do
local proc_deadline = process:deadline()
if proc_deadline < deadline then
deadline = proc_deadline
if deadline < 0 then break end
end
end
local signal = default
if deadline == -1 then
if computer.uptime() - last_yield > 4 then
last_yield = computer.uptime()
signal = table.pack(computer.pullSignal(0))
end
else
last_yield = computer.uptime()
signal = table.pack(computer.pullSignal(deadline - computer.uptime()))
end
for cpid, process in pairs(processes) do
process:resume(table.unpack(signal, 1, signal.n))
if not next(process.threads) then
computer.pushSignal("process_exit", cpid)
processes[cpid] = nil
end
end
end
end
function k.add_process(proc)
pid = pid + 1
processes[pid] = k.create_process(pid, processes[current])
end
end
k.scheduler_loop()
panic("init exited")
