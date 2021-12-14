--[[
    Cynosure 2.0's improved VT100 emulator.
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

  function _tty:write(str)
    checkArg(1, str, "string")
    self.wbuf = self.wbuf .. str
    repeat
      local idx = self.wbuf:find("\n")
      if idx then
        local chunk = self.wbuf:sub(1, idx)
        self.wbuf = self.wbuf:sub(#chunk + 1)
        self:internalwrite(chunk)
      end
    until not idx
  end

  function k.opentty(gpu, screen)
  end
end
