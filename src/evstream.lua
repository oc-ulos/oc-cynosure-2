--[[
    Event streams.  May be used to filter events.
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

k.log(k.L_INFO, "evstream")

do
  local evstreams = {}
  local handlers = {}
  local _evs = {}

  function _evs.new(wants)
    checkArg(1, wants, "table")
    return setmetatable({wants = wants, queue = queue}, {__index = _evs})
  end

  function _evs:poll()
    if #queue > 0 then
      return table.remove(self.queue, 1)
    end
  end

  function _evs:wait()
    while #queue > 0 do
      coroutine.yield()
    end
    return table.remove(self.queue, 1)
  end

  --#include "src/platform/@[{os.getenv('KPLATFORM')or'oc'}]/sigtransform.lua"

  local ps = k.pullSignal
  function k.pullSignal(tout)
    checkArg(1, tout, "number", "nil")
    local sig = table.pack(ps(tout))
    if sig.n > 0 then
      sig = evs_process(sig)
      -- kernel-level handlers take priority
      for i, hand in ipairs(handlers) do
        if hand.sig == sig[1] then
          hand.call(table.unpack(sig))
        end
      end
      for i, evs in pairs(evstreams) do
        if evs.wants[sig[1]] and #evs.queue < 128 then
          table.insert(evs.queue, table.pack(table.unpack(sig)))
        end
      end
    end
    return sig.n > 0
  end

  k.openevstream = _evs.new

  function k.handle(evt, func)
    local n = #handlers+1
    handlers[n] = {sig = evt, call = func}
    return n
  end

  function k.drop(hid)
    handlers[hid] = nil
  end
end
