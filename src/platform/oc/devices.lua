--[[
    OpenCompters device registry.
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

k.log(k.L_INFO, "platform/oc/devices")

do
  -- device: filesystem
  k.state.devsearchers.filesystem = {
    matches = function(n)
      -- returns true if 'n' is a filesystem proxy
      if type(n) == "table" and n.type == "filesystem" then return true end
      if type(n) ~= "string" then return nil end
      -- returns 'true' if 'n' is a filesystem address
      if component.type(n) == "filesystem" then return true end
    end,
    setup = function(n)
      if type(n) == "table" then
        return n
      else
        return component.proxy(n)
      end
    end
  }

  -- device: drive
  k.state.devsearchers.drive = {
    matches = function(n)
      -- returns true if 'n' is a drive proxy
      if type(n) == "table" and n.type == "drive" then return true end
      if type(n) ~= "string" then return nil end
      -- returns 'true' if 'n' is a drive address
      if component.type(n) == "drive" then return true end
    end,
    setup = function(n)
      if type(n) == "table" then return n end
      return component.proxy(n)
    end
  }

  -- device: keyboard
  -- mapping of keyboards to screens
  local kbds = {}
  local kblcache = {}

  k.state.devsearchers.keyboard = {
    matches = function(n)
      -- returns true if 'n' is a keyboard proxy
      if type(n) == "table" and n.type == "keyboard" then return true end
      if type(n) ~= "string" then return nil end
      -- returns 'true' if 'n' is a keyboard address
      if component.type(n) == "keyboard" then return true end
    end,
    -- the keyboard proxy provides no useful functionality whatsoever
    setup = function(n)
    end
  }

  k.handle("component_added", function(_, addr, ctype)
    if ctype == "screen" then
      local kbs = component.invoke(addr, "getKeyboards")
      kblcache[addr] = kbs
      for _, kb in ipairs(kbs) do
        kbds[kb] = addr
      end
    elseif ctype == "keyboard" then
      for saddr in component.list("screen") do
        local kbs = component.invoke(addr, "getKeyboards")
        kblcache[addr] = kbs
        for _, kb in ipairs(kbs) do
          if addr == kb then
            kbds[addr] = saddr
            break
          end
        end
      end
    end
  end)

  k.handle("component_removed", function(_, addr, ctype)
    if ctype == "screen" then
      local kbs = kblcache[addr]
      for _, kb in ipairs(kbs) do
        kbds[kb] = nil
      end
    elseif ctype == "keyboard" then
      for saddr in component.list("screen") do
        local kbs = kblcache[addr]
        for _, kb in ipairs(kbs) do
          if addr == kb then
            kbds[addr] = nil
            break
          end
        end
      end
    end
  end)
end
