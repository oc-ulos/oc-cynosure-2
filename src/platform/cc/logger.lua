--[[
    Boot logger implementation for ComputerCraft
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

do
  local term = term
  k.logio = {y = 1}
  
  local time = os.epoch("utc")

  local w, h = term.getSize()
  function k.logio:write(msg)
    if k.logio.y > h then
      term.scroll(1)
    end
    term.setCursorPos(1, k.logio.y)
    term.write(msg)
    k.logio.y = k.logio.y + 1
  end
end
