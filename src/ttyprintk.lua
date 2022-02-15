--[[
    TTY-based printk
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

printk(k.L_INFO, "ttyprintk")

do
  local console, err = k.open("tty:1", "r")
  if not console then
    panic("cannot open console: " .. err)
  end
  console.fd.bufmode = "none"
  k.write(console, "\27[39;49m\27[2J")
  function k.log_to_screen(message)
    k.write(console, message.."\n")
  end
end
