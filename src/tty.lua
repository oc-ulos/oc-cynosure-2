--[[
    Cynosure 2.0's improved VT100 emulator.  Compatible with Cynosure 1's.
    Copyright (C) 2021 Ocawesome101

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

k.log(k.L_INFO, "tty")

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
  local oscommand = {}
  local controllers = {}
  
  local function scroll(self, n)
    self.scr.scroll(n, self.scrolltop, self.scrollbot)
  end

  -- RIS - reset
  function nocsi:c()
    self.fg = colors[8]
    self.bg = colors[1]
    self.scr.setForeground(colors[8])
    self.scr.setBackground(colors[1])
    self.scr.fill(1, 1, self.w, self.h, " ")
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
    self.rbuf = self.rbuf .. "\27[?6c"
  end

  local save = {"fg", "bg", "echo", "line", "raw", "cx", "cy"}
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
        self.scr.setForeground(self.fg)
        self.scr.setBackground(self.bg)
      end
    end
  end

  -- ESC % not implemented, OC doesn't have a way to switch character sets
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
      self.scr.fill(1, self.cy, self.w, self.h - self.cy, " ")
    elseif n == 1 then
      self.scr.fill(1, self.cx, self.w, self.cy, " ")
    elseif n == 2 then
      self.scr.fill(1, 1, self.w, self.h, " ")
    end
  end

  -- EL - erase line
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

  -- IL - insert lines
  function commands:L(args)
    local n = args[1] or 1
    -- copy everything from cy and lower down n
    self.scr.scroll(n, self.cy)--, self.w, self.h - self.cy, 0, n)
  end

  -- DL - delete lines
  function commands:M(args)
    local n = args[1] or 1
    -- copy everything from cy and lower up n
    self.scr.scroll(-1, self.cy)--, self.w, self.h - self.cy, 0, -n)
  end

  -- DCH - delete characters
  function commands:P(args)
    local n = args[1] or 1
    self.scr.copy(self.cx + n, self.cy, self.w - self.cx, 1, -n, 0)
    self.scr.fill(self.w - n, self.cy, n, 1, " ")
  end

  -- ECH - erase characters
  function commands:X(args)
    local n = args[1] or 1
    self.scr.fill(self.cx, self.cy, n, 1, " ")
  end

  -- HPR - move cursor right
  function commands:a(args)
    local n = args[1] or 1
    self.cx = self.cx + n
  end

  -- DA - same as ESC Z
  function commands:c()
    self.rbuf = self.rbuf .. "\27[?6c"
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

  local function hl(set, args)
    for i=1, #args, 1 do
      local n = args[i]
      -- 1 - cursor keys send ESC O prefix rather than ESC [
      if n == 1 then
        self.altcursor = set
      -- 3 - display control characters
      elseif n == 3 then
        self.showctrl = set
      -- 9 - X10 mouse reporting
      elseif n == 9 then
        self.mousereport = set and 1 or 0
      -- 20 - automatically add CR after LF, VT or FF
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
    hl(true, args)
  end
  
  -- RM - reset mode
  function commands:l()
    hl(false, args)
  end

  -- SGR - set attributes
  function commands:m(args)
    args[1] = args[1] or 0
    for i=1, #args, 1 do
      local n = args[1]
      -- bold mode (1) not implemented
      -- half-bright (2) not implemented
      -- underscore (4) not implemented
      -- blink (5) not implemented
      -- reverse video
      if n == 7 or n == 27 then
        self.fg, self.bg = self.bg, self.fg
        self.scr.setForeground(self.fg)
        self.scr.setBackground(self.bg)
      -- 10, 11, 12, 21, 22, 25 not implemented
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

  -- DSR - status report
  function commands:n(args)
    local n = args[1] or 0
    if n == 5 then
      self.rbuf = self.rbuf .. "\27[0n"
    elseif n == 6 then
      self.rbuf = self.rbuf .. string.format("\27[%d;%dR", self.cy, self.cx)
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
  commands["`"] = function(args)
    local n = args[1] or 1
    self.cx = math.max(1, math.min(self.w, n))
  end

  -- cursor bounds checking
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

  -- write some text
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

  -- write a single line to the output
  -- most of the time a single line is probably under 500 characters,
  -- which OC's string.* wrapper considers to be "short" - so, doing
  -- things this way should in theory be faster (or at least no slower).
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
          elseif css == "#" then -- it is hilarious to me that this exists
            self.scr.fill(1, 1, self.w, self.h, "E")
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

  -- shifted[c] = shifted version of c
  local shifted = {
    ['1']   = "!",
    ['2']   = "@",
    ['3']   = "#",
    ['4']   = "$",
    ['5']   = "%",
    ['6']   = "^",
    ['7']   = "&",
    ['8']   = "*",
    ['9']   = "(",
    ['0']   = ")",
    ['-']   = "_",
    ['=']   = "+",
    ['[']   = "{",
    [']']   = "}",
    ['\\']  = "|",
    [';']   = ":",
    ["'"]   = '"',
    [',']   = "<",
    ['.']   = ">",
    ['/']   = "?",
    ['`']   = "~"
  }

  -- `screen' is a screen object as described in `docs/screen.txt'
  function k.opentty(screen)
    local w, h = screen.getResolution()
    screen.setPalette(colors)
    local new = {
      scr = screen.id,
      w = w, h = h, cx = 1, cy = 1,
      scrolltop = 1, scrollbot = h,
      rbuf = "", wbuf = "",
      fg = colors[1], bg = colors[8],
      -- attributes
      altcursor = false, showctrl = false,
      mousereport = 0, autocr = false,
      cursor = true,
    }

    -- handlers
    new.kdid = k.handle("key_down", function(_, screenid, code)
      if screenid ~= new.scr then return end

      local kname = k.keys[code]
      if kname == "leftShift" or kname == "rightShift" then
        new.shift = true
      elseif kname == "leftCtrl" or "rightCtrl" then
        new.ctrl = true
      end
    end)

    new.kuid = k.handle("key_down", function(_, screenid, code)
      if screenid ~= new.scr then return end

      local kname = k.keys[code]
      if kname == "leftShift" or kname == "rightShift" then
        new.shift = false
      elseif kname == "leftCtrl" or "rightCtrl" then
        new.ctrl = false
      end
    end)

    setmetatable(new, {__index = _tty})
    return new
  end
end
