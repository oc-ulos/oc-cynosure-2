--[[
  TTY line discipline
  Copyright (C) 2022 Ocawesome101

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

printk(k.L_INFO, "disciplines/tty")

do
  local discipline = {}

  local eolpat = "\n[^\n]-$"

  function discipline.wrap(obj)
    checkArg(1, obj, "table")

    local new
    if obj.discipline then
      new = obj.discipline

    else
      new = setmetatable({
        obj = obj,
        mode = "line", rbuf = "", wbuf = "",
        erase = "\8", intr = "\3", kill = "\21",
        quit = "\28", start = "\19", stop = "\17",
        susp = "\26", eof = "\4", raw = false,
        stopped = false, echo = true
      }, {__index=discipline})
      obj.discipline = new
      new.eofpat = string.format("%%%s[^%%%s]-$", new.eof, new.eof)
    end

    local proc = k.current_process()
    if proc and not new.session and not proc.tty then
      proc.tty = new
      new.session = proc.sid
    end

    return new
  end

  local sub32_lookups = {
    [0]   = " ",
    [27]  = "[",
    [28]  = "\\",
    [29]  = "]",
    [30]  = "~",
    [31]  = "?"
  }

  local sub32_lookups_notraw = {
    [10] = "\n"
  }

  for i=1, 26, 1 do sub32_lookups[i] = string.char(64 + i) end

  local function send(obj, sig)
    local pids = k.get_pids()

    for i=1, #pids, 1 do
      local proc = k.get_process(pids[i])
      if proc.pgid == obj.pgroup then
        table.insert(proc.sigqueue, sig)
      end
    end
  end

  local function wchar(self, c)
    if (not self.raw) and c == "\r" then c = "\n" end
    self.rbuf = self.rbuf .. c
    if self.echo then
      local byte = string.byte(c)
      if (not self.raw) and sub32_lookups_notraw[byte] then
        self.obj:write(sub32_lookups_notraw[byte])
      elseif sub32_lookups[byte] then
        self.obj:write("^"..sub32_lookups[byte])
      elseif byte < 126 then
        self.obj:write(c)
      end
    end
  end

  -- process new input from the stream - this is keyboard input
  function discipline:processInput(inp)
    self:flush()
    for c in inp:gmatch(".") do
      if c == self.erase and not self.raw then
        if #self.rbuf > 0 then
          local last = self.rbuf:sub(-1)
          if self.echo then
            if last:byte() < 32 then
              self.obj:write("\27[2D  \27[2D")
            else
              self.obj:write("\27[D \27[D")
            end
          end
          if last ~= self.eol and last ~= self.eof then
            self.rbuf = self.rbuf:sub(1, -2)
          end
        end
      elseif c == self.eof then
        if self.rbuf:sub(-1) == self.eol then
          wchar(self, c)
        end

      elseif c == self.intr then
        send(self, "SIGINT")

      -- kill (erase current line) not implemented; this
      -- implementation does not provide line editing

      elseif c == self.quit then
        send(self, "SIGQUIT")
        self.obj:write("^\\")

      elseif c == self.start then
        self.stopped = false

      elseif c == self.stop then
        self.stopped = true

      elseif c == self.susp then
        send(self, "SIGSTOP")

      else
        wchar(self, c)
      end
    end
  end

  local function s(se,k,v)
    se[k] = v[k] or se[k]
  end

  function discipline:ioctl(method, args)
    if method == "stty" then
      checkArg(2, args, "table")

      s(self, "eol", args)
      s(self, "erase", args)
      s(self, "intr", args)
      s(self, "kill", args)
      s(self, "quit", args)
      s(self, "start", args)
      s(self, "stop", args)
      s(self, "susp", args)

      -- One of those rare cases where comparing against nil
      -- directly is the correct thing to do.
      if args.echo ~= nil then self.echo = not not args.echo end
      if args.raw ~= nil then self.raw = not not args.raw end

      self.eofpat = string.format("%%%s[^%%%s]-$", self.eof, self.eof)

      return true

    elseif method == "setpg" then
      local current = k.current_process()
      if self.pgroup and current.pgid ~= self.pgroup then
        current:signal("SIGTTOU")
        return true
      end

    elseif method == "getpg" then
      return self.pgroup or math.huge

    else
      return nil, k.errno.ENOSYS
    end
  end

  function discipline:read(n)
    checkArg(1, n, "number")

    self:flush()

    local current = k.current_process()
    if self.pgroup and current.pgid ~= self.pgroup then
      current:signal("SIGTTIN")
      return true
    end

    if self.last_eof then
      self.last_eof = false
      return nil
    end

    while #self.rbuf < n do
      coroutine.yield()
      if self.rbuf:find("%"..self.eof) then break end
    end
    if self.mode == "line" then
      while (self.rbuf:find(eolpat) or 0) < n do
        coroutine.yield()
        if self.rbuf:find("%"..self.eof) then break end
      end
    end

    local eof = self.rbuf:find("%"..self.eof)
    n = math.min(n, eof or math.huge)

    self.last_eof = not not eof

    local data = self.rbuf:sub(1, n)
    self.rbuf = self.rbuf:sub(#data + 1)
    return data
  end

  function discipline:write(text)
    checkArg(1, text, "string")

    while self.stopped and #self.wbuf >= @[{bconf.BUFFER_SIZE or 1024}] do
      coroutine.yield()
    end

    self.wbuf = self.wbuf .. text

    local last_eol = self.wbuf:find(eolpat)
    if last_eol then
      local data = self.wbuf:sub(1, last_eol)
      self.wbuf = self.wbuf:sub(#data + 1)
      self.obj:write(data)
    end

    return true
  end

  function discipline:flush()
    local data = self.wbuf
    self.wbuf = ""
    self.obj:write(data)
  end

  function discipline:close()
    local proc = k.current_process()
    if proc.tty == self then
      proc.tty = false
    end
    return true
  end

  k.disciplines.tty = discipline
end
