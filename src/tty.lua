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

  -- cursor bounds checking
  local function corral(self)
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
        self.gpu.set(self.cx, self.cy, chunk)
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
    while #line > 0 do
      local nesc = line:find("\27", nil, true)
      local e = (nesc and nesc - 1) or #str
      local chunk = line:sub(1, e)
      line = line:sub(#chunk + 1)
      textwrite(self, chunk)
      
      if nesc then
        local css, params, csc, len
          = line:match("^\27([%[%?])([%d;]*)([%a%[])()")
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
          if csc == "A" then
            args[1] = args[1] or 1
            self.cy = self.cy - args[1]
          end
        elseif css == "?" then
        end
      end
    end
  end

  local function togglecursor(self)
    local cc, cf, cb = self.gpu.get(self.cx, self.cy)
    self.gpu.setForeground(cb)
    self.gpu.setBackground(cf)
    self.gpu.set(self.cx, self.cy, cc)
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

  function k.opentty(gpu, screen)
  end
end
