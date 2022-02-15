--[[
    Signal handling
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

printk(k.L_INFO, "signals")

do
  local handlers = {}

  function k.add_signal_handler(name, callback)
    checkArg(1, name, "string")
    checkArg(2, callback, "function")
    local id
    repeat id = math.random(100000, 999999) until not handlers[id]
    handlers[id] = {signal = name, callback = callback}
    return id
  end

  function k.remove_signal_handler(id)
    checkArg(1, id, "number")
    local success = not not handlers[id]
    handlers[id] = nil
    return success
  end

  local pullsignal = computer.pullSignal

  function computer.pullSignal(timeout)
    local sig = table.pack(pullsignal(timeout))
    if sig.n == 0 then return end
    for id, handler in pairs(handlers) do
      if handler.signal == sig[1] then
        local success, err = pcall(handler.callback,
          table.unpack(sig, 1, sig.n))
        if not success and err then
          printk(k.L_WARNING,
            "error in event handler %d while handling signal %s: %s", id,
            sig[1], err)
        end
      end
    end
    return table.unpack(sig, 1, sig.n)
  end
end
