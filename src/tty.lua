--[[
    Cynosure 2.0's improved VT100 emulator.  Compatible with Cynosure 1's.
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

printk(k.L_INFO, "tty")

do
  local _tty = {}

  local colors = {
    -- normal colors
    0x000000,
    0xaa0000,
    0x00aa00,
    0xaaaa00,
    0x0000aa,
    0xaa00aa,
    0x00aaaa,
    0xaaaaaa,
    -- bright colors
    0x555555,
    0xff5555,
    0x55ff55,
    0xffff55,
    0x5555ff,
    0xff55ff,
    0x55ffff,
    0xffffff
  }

  -- i've implemented most of what console_codes(4) specifies
  local nocsi = {}
  local commands = {}
  local controllers = {}

  local function scroll(self, n)
    local top, bot = self.scrolltop, self.scrollbot
    local height = bot - top + 1
    self.gpu.copy(1, top, self.w, height, 0, -n)
    if n < 0 then n = self.h + n end
    self.gpu.fill(1, bot - n + 1, self.w, n, " ")
  end

  -- RIS - reset
  function nocsi:c()
    self.fg = 7
    self.bg = 0
    self.gpu.setForeground(7, true)
    self.gpu.setBackground(0, true)
    self.gpu.fill(1, 1, self.w, self.h, " ")
    self.cx, self.cy = 1, 1
  end

  -- IND - linefeed
  function nocsi:D()
    self.cy = self.cy + 1
  end

  -- NEL - newline
  function nocsi:E()
    self.cx, self.cy = 1, self.cy + 1
  end

  -- HTS not implemented
  -- RI - reverse linefeed
  function nocsi:M()
    self.cy = self.cy - 1
  end

  -- DECID: returns ESC [ ? 6 c, for VT102
  function nocsi:Z()
    if self.discipline then
      self.discipline:processInput("\27[?6c")
    end
  end

  local save = {"fg", "bg", "echo", "cx", "cy"}
  -- DECSC - save state
  nocsi["7"] = function(self)
    self.saved = {}
    for i=1, #save, 1 do
      self.saved[save[i]] = self[save[i]]
    end
  end

  -- DECRC - restore state from DECSC
  nocsi["8"] = function(self)
    if self.saved then
      for i=1, #save, 1 do
        self[save[i]] = self.saved[save[i]]
      end
      self.gpu.setForeground(self.fg, true)
      self.gpu.setBackground(self.bg, true)
    end
  end

  -- ESC % not implemented; OC doesn't have a way to switch character sets
  -- ESC # 8 implemented in write logic below
  -- ESC ( and ESC ) not implemented for the same reason as ESC %
  -- ESC > and ESC = not implemented

  -- CSI @ is not implemented

  -- CUU - cursor up
  function commands:A(args)
    local n = args[1] or 1
    self.cy = self.cy - n
  end

  -- CUD - cursor left
  function commands:B(args)
    local n = args[1] or 1
    self.cy = self.cy + n
  end

  -- CUF - cursor "forward" (right)
  function commands:C(args)
    local n = args[1] or 1
    self.cx = self.cx + n
  end

  -- CUB - cursor "backward" (left)
  function commands:D(args)
    local n = args[1] or 1
    self.cx = self.cx - n
  end

  -- CNL - cursor down # rows, to column 1
  function commands:E(args)
    local n = args[1] or 1
    self.cx, self.cy = 1, self.cy + n
  end

  -- CPL - cursor up # rows, to column 1
  function commands:F(args)
    local n = args[1] or 1
    self.cx, self.cy = 1, self.cy - n
  end

  -- CHA - cursor to indicated column
  function commands:G(args)
    local n = args[1] or 1
    self.cx = math.max(1, math.min(self.w, n))
  end

  -- CUP - set cursor position to row;column
  function commands:H(args)
    local row, col = args[1] or 1, args[2] or 1
    self.cx = math.max(1, math.min(self.w, col))
    self.cy = math.max(1, math.min(self.h, row))
  end

  -- ED - erase display
  function commands:J(args)
    local n = args[1] or 0
    if n == 0 then
      self.gpu.fill(1, self.cy, self.w, self.h - self.cy, " ")
    elseif n == 1 then
      self.gpu.fill(1, self.cx, self.w, self.cy, " ")
    elseif n == 2 then
      self.gpu.fill(1, 1, self.w, self.h, " ")
    end
  end

  -- EL - erase line
  function commands:K(args)
    local n = args[1] or 0
    if n == 0 then
      self.gpu.fill(self.cx, self.cy, self.w - self.cx, 1, " ")
    elseif n == 1 then
      self.gpu.fill(1, self.cy, self.cx, 1, " ")
    elseif n == 2 then
      self.gpu.fill(1, self.cy, self.w, 1, " ")
    end
  end

  -- IL - insert lines
  function commands:L(args)
    local n = args[1] or 1
    -- copy everything from cy and lower down n
    self.gpu.copy(1, self.cy, self.w, self.h - self.cy, 0, n)
    self.gpu.fill(1, self.cy, self.w, n, " ")
  end

  -- DL - delete lines
  function commands:M(args)
    local n = args[1] or 1
    -- copy everything from cy and lower up n
    self.gpu.copy(1, self.cy, self.w, self.h - self.cy, 0, -n)
    self.gpu.fill(1, self.h-n, self.w, n, " ")
  end

  -- DCH - delete characters
  function commands:P(args)
    local n = args[1] or 1
    self.gpu.copy(self.cx + n, self.cy, self.w - self.cx, 1, -n, 0)
    self.gpu.fill(self.w - n, self.cy, n, 1, " ")
  end

  -- ECH - erase characters
  function commands:X(args)
    local n = args[1] or 1
    self.gpu.fill(self.cx, self.cy, n, 1, " ")
  end

  -- HPR - move cursor right
  function commands:a(args)
    local n = args[1] or 1
    self.cx = self.cx + n
  end

  -- DA - same as ESC Z
  function commands:c()
    if self.discipline then
      self.discipline:processInput("\27[?6c")
    end
  end

  -- VPA - move cursor to indicated row in current column
  function commands:d(args)
    local n = args[1] or 1
    self.cy = math.max(1, math.min(self.h, n))
  end

  -- VPR - move cursor down
  function commands:e(args)
    local n = args[1] or 1
    self.cy = self.cy + n
  end

  -- HVP - see commands.H
  commands.f = commands.H

  -- CSI g not implemented

  local function hl(self, set, args)
    for i=1, #args, 1 do
      local n = args[i]
      -- 1 - cursor keys send ESC O prefix rather than ESC [
      if n == 1 then
        self.altcursor = set
      -- 9 - X10 mouse reporting
      elseif n == 9 then
        self.mousereport = set and 1 or 0
      -- 20 - automatically add carriage return after line feed, vertical tab,
      --      or form feed
      elseif n == 20 then
        self.autocr = set
      -- 25 - make cursor visible
      elseif n == 25 then
        self.cursor = set
      -- 1000 - X11 mouse reporting
      elseif n == 1000 then
        self.mousereport = set and 2 or 0
      end
    end
  end

  -- SM - set mode
  function commands:h(args)
    hl(self, true, args)
  end

  -- RM - reset mode
  function commands:l(args)
    hl(self, false, args)
  end

  -- SGR - set attributes
  function commands:m(args)
    args[1] = args[1] or 0
    for i=1, #args, 1 do
      local n = args[i]
      if n == 0 then
        self.fg = 7
        self.bg = 0
        self.gpu.setForeground(self.fg, true)
        self.gpu.setBackground(self.bg, true)
        self.echo = true
      -- bold mode (1) not implemented
      -- half-bright (2) not implemented
      -- underscore (4) not implemented
      -- blink (5) not implemented
      -- reverse video
      elseif (n == 7 and not self.reversed) or (n == 27 and self.reversed) then
        self.reversed = true
        self.fg, self.bg = self.bg, self.fg
        self.gpu.setForeground(self.fg, true)
        self.gpu.setBackground(self.bg, true)
      elseif n == 8 or n == 28 then
        self.echo = n == 28
      -- 10, 11, 12, 21, 22, 25 not implemented
      elseif n > 29 and n < 38 then
        self.fg = n - 30
        self.gpu.setForeground(self.fg, true)
      elseif n > 89 and n < 98 then
        self.fg = n - 82
        self.gpu.setForeground(self.fg, true)
      elseif n > 39 and n < 48 then
        self.bg = n - 40
        self.gpu.setBackground(self.bg, true)
      elseif n > 99 and n < 108 then
        self.bg = n - 92
        self.gpu.setBackground(self.bg, true)
      elseif n == 39 then
        self.fg = 7
        self.gpu.setForeground(self.fg, true)
      elseif n == 49 then
        self.bg = 0
        self.gpu.setBackground(self.bg, true)
      end
    end
  end

  -- DSR - status report
  function commands:n(args)
    local n = args[1] or 0
    if self.discipline then
      if n == 5 then
        self.discipline:processInput("\27[0n")
      elseif n == 6 then
        self.discipline:processInput(string.format("\27[%d;%dR",
          self.cy, self.cx))
      end
    end
  end

  -- CSI q not implemented; no keyboard LEDs

  -- DECSTBM - set scrolling region
  function commands:r(args)
    local top, bot = args[1] or 1, args[2] or self.h
    self.scrolltop = math.max(1, math.min(top, self.h))
    self.scrollbot = math.min(self.h, math.max(1, bot))
  end

  -- save cursor location
  function commands:s()
    self.saved = self.saved or {}
    self.saved.cx = self.cx
    self.saved.cy = self.cy
  end

  -- restore cursor location
  function commands:u()
    self.saved = self.saved or {}
    self.cx = self.saved.cx
    self.cy = self.saved.cy
  end

  -- who thought having ` as a command was a good idea?
  commands["`"] = function(self, args)
    local n = args[1] or 1
    self.cx = math.max(1, math.min(self.w, n))
  end

--@[{bconf.TTY_ENABLE_GPU == 'y' and '#include "src/tty_gpu.lua"' or ''}]

  -- cursor bounds checking
  local function corral(self)
    while self.cx < 1 do
      self.cx = self.cx + self.w
      self.cy = self.cy - 1
    end

    while self.cx > self.w + 1 do
      self.cx = self.cx - self.w
      self.cy = self.cy + 1
    end

    while self.cy < self.scrolltop do
      scroll(self, -1)
      self.cy = self.cy + 1
    end

    while self.cy > self.scrollbot do
      scroll(self, 1)
      self.cy = self.cy - 1
    end
  end

  -- write some text
  local function textwrite(self, line)
    corral(self)
    if not self.echo then line = (" "):rep(#line) end
    while #line > 0 do
      local chunk = line:sub(1, self.w - self.cx + 1)
      line = line:sub(#chunk + 1)
      self.gpu.set(self.cx, self.cy, chunk)
      self.cx = self.cx + #chunk
      corral(self)
    end
  end

  local function togglecursor(self)
    if not self.cursor then return end
    corral(self)
    local cc, cf, cb, pf, pb = self.gpu.get(self.cx, self.cy)
    self.gpu.setForeground(pb or cb, not not pb)
    self.gpu.setBackground(pf or cf, not not pf)
    self.gpu.set(self.cx, self.cy, cc)
  end

  -- write some text to the output
  function _tty:write(line)
    if #line == 0 then return end

    if self.cursor then togglecursor(self) end

    line = line:gsub("\x9b", "\27[")
    if self.autocr then
      line = line:gsub("[\n\v\f]", "%1\r")
    end

    -- i can't believe i haven't just done this in the past
    line = line:gsub("[\n\v\f]", "\27[B")
      :gsub("\r", "\27[G")
      -- TODO: perhaps custom escape for tab?
      :gsub("\t", "  ")

    while #line > 0 do
      local nesc = line:find("\27", nil, true)
      local e = (nesc and nesc - 1) or #line
      local chunk = line:sub(1, e)
      line = line:sub(#chunk + 1)
      if #chunk > 0 then textwrite(self, chunk) end

      if nesc then
        local css, params, csc, len
          = line:match("^\27(.)([%d;]*)([%a%d`])()")

        if css and params and csc and len then
          line = line:sub(len)

          local args = {}
          local num = ""
          local plen = #params
          for pos, c in params:gmatch("()(.)") do
            if c == ";" then
              args[#args+1] = tonumber(num) or 0
              num = ""
            elseif tonumber(c) then
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
          elseif css == "#" then -- it is hilarious to me that this exists
            self.gpu.fill(1, 1, self.w, self.h, "E")
          else
            local func = nocsi[css]
            if func then func(self, args) end
          end
        end
      end
    end

    if self.cursor then togglecursor(self) end
  end

  function _tty:flush()
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
      fg = 7, bg = 0,
      -- attributes
      altcursor = false, mousereport = 0,
      autocr = true, cursor = true,
      echo = true,
    }

    for i=1, #colors, 1 do
      gpu.setPaletteColor(i-1, colors[i])
    end

    gpu.setForeground(new.fg, true)
    gpu.setBackground(new.bg, true)
    gpu.fill(1, 1, w, h, " ")

    local keyboards = {}
    for _, kbaddr in pairs(component.invoke(screen, "getKeyboards")) do
      keyboards[kbaddr] = true
    end

    -- handlers
    new.khid = k.add_signal_handler("key_down", function(_, kbd, char, code)
      if not keyboards[kbd] then return end
      if not new.discipline then return end

      local to_buffer
      if scancode_lookups[code] then
        local c = scancode_lookups[code]
        local interim = new.altcursor and "O" or "["
        to_buffer = "\27" .. interim .. c
      elseif char > 0 then
        to_buffer = string.char(char)
      end

      if to_buffer then
        new.discipline:processInput(to_buffer)
      end
    end)

    new.thid = k.add_signal_handler("touch", function(_, addr, x, y, button)
      if addr ~= screen then return end
      if not new.discipline then return end

      if new.mousereport > 0 then
        new.discipline:processInput(string.format("\27[M%s%s%s",
          string.char(button),
          string.char(x + 32),
          string.char(y + 32)))
      end
    end)

    new.dhid = k.add_signal_handler("drop", function(_, addr, x, y, button)
      if addr ~= screen then return end
      if not new.discipline then return end

      if new.mousereport == 2 then
        new.discipline:processInput(string.format("\27[M\3%s%s",
          string.char(x + 32),
          string.char(y + 32)))
      end
    end)

    setmetatable(new, {__index = _tty})
    return new
  end

  k.init_ttys()
end
