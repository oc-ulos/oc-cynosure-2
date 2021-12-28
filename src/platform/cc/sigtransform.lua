--[[
    Signal transformations for ComputerCraft.
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

k.log(k.L_INFO, "platform/cc/sigtransform")

local converters = {}

function converters.key(sig)
  return {
    "key_down",
    "term",
    sig[2]
  }
end

function converters.key_up(sig)
  return {
    "key_up",
    "term",
    sig[2]
  }
end

function converters.mouse_click(sig)
  return {
    "mouse_down",
    "term",
    sig[2],
    sig[3],
    sig[4]
  }
end

function converters.mouse_drag(sig)
  return {
    "mouse_drag",
    "term",
    sig[2],
    sig[3],
    sig[4]
  }
end

function converters.mouse_up(sig)
  return {
    "mouse_up",
    "term",
    sig[2],
    sig[3],
    sig[4]
  }
end

function converters.monitor_touch(sig)
  os.queueEvent("monitor_drop", sig[2], sig[3], sig[4])
  return {
    "mouse_click",
    sig[2],
    0,
    sig[3],
    sig[4]
  }
end

-- not a real signal but it's here for consistency
function converters.monitor_drop(sig)
  return {
    "mouse_up",
    sig[2],
    0,
    sig[3],
    sig[4]
  }
end
