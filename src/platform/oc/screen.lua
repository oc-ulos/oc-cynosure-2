--[[
    Screen object for OpenComputers
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

k.log(k.L_INFO, "platform/oc/screen")

do
  k.log(k.L_INFO, "[screen] getting device info")
  k.screen = {}

  -- used for registering platform-agnostic signal handlers in the TTY driver
  k.screen.char = "key_down"
  k.screen.keydown = "key_down"
  k.screen.mouseup = "touch"
  k.screen.mousedown = "drop"
  -- arrow keys - needed for arrow keys to function in the TTY
  k.screen.up = 200
  k.screen.right = 203
  k.screen.left = 205
  k.screen.down = 208
  -- backspace
  k.screen.backspace = 8

  local dinfo = {}
  local gpus, screens = {}, {}
  function k.screen.refresh()
    dinfo = computer.getDeviceInfo()
  end

  function k.screen.keyhandler(vt, screen)
    local keyboards = screen.keyboards
    return function(_, addr, char, key)
      if not keyboards[addr] then return end
      
    end
  end

  function k.screen.charhandler() end

  function k.screen.next()
    local gpu, screen
    for addr in component.list("gpu") do
      if not gpus[addr] then
        gpu = addr
        break
      end
    end

    for addr in component.list("screen") do
      if not screens[addr] then
        screen = addr
        break
      end
    end

    gpu = component.proxy(gpu)
    gpu.bind(screen)
    local keyboards = component.invoke(screen, "getKeyboards")
    for k, v in pairs(keyboards) do keyboards[v] = k end
    gpu.keyboards = keyboards

    function gpu.scroll(n, top, bot)
      if n == 0 then return end
      local w, h = gpu.getResolution()
      gpu.copy(1, top, w, bot - top + 1, 0, -n)
      if n > 0 then
        gpu.fill(1, bot - n, w, n, " ")
      elseif n < 0 then
        gpu.fill(1, top, w, n, " ")
      end
    end
    
    function gpu.setPalette(colors)
      for i=1, math.min(16, #colors), 1 do
        gpu.setPaletteColor(i-1, colors[i])
      end
    end

    return gpu
  end
end
