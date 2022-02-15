--[[
    Sandboxing
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

printk(k.L_INFO, "user/sandbox")

do
  -- from https://lua-users.org/wiki/CopyTable
  local function deepcopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy

    if orig_type == 'table' then
      if copies[orig] then
        copy = copies[orig]
      else
        copy = {}
        copies[orig] = copy

        for orig_key, orig_value in next, orig, nil do
          copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
        end

        setmetatable(copy, deepcopy(getmetatable(orig), copies))
      end
    else -- number, string, boolean, etc
      copy = orig
    end

    return copy
  end

  local blacklist = {
    k = true, component = true, computer = true, printk = true, panic = true
  }

  function k.create_env(base)
    checkArg(1, base, "table", "nil")
    local new = deepcopy(base or _G)
    for key in pairs(blacklist) do
      new[key] = nil
    end
    if not base then new.syscall = k.perform_system_call end
    return new
  end
end
