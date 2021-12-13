--[[
    Early boot logger for OpenComputers.
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
  local gpu, screen = component.list("gpu", true)(),
    component.list("screen", true)()

  k.logio = {y = 1}

  local time = computer.uptime()

  if gpu and screen then
    gpu = component.proxy(gpu)
    gpu.bind(screen)
    local w, h = gpu.maxResolution()
    gpu.setResolution(w, h)
    gpu.fill(1,1,w,h," ")
    function k.logio:write(msg)
      if  k.logio.y > h then
        gpu.copy(1, k.logio.sy, w, h, 0, -1)
        gpu.fill(1, h, w, 1, " ")
        k.logio.y = k.logio.y - 1
      end
      gpu.set(1, k.logio.y, (msg:gsub("\n","")))
      k.logio.y = k.logio.y + 1
    end
  else
    function k.logio.write() end
  end
end
