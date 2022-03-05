--[[
  procfs
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

printk(k.L_INFO, "fs/proc")

do
  local provider = {}

  local function path_to_attr(path)
    return path:match("^/?([^/]*)/?([^/]*)$")
  end

  local files = {}

  function provider:exists(path)
    checkArg(1, path, "string")

    local pid, attr = path_to_attr(path)
    if #pid == 0 then return true end

    if files[pid] and #attr == 0 then return true end
    if files[pid] and #attr > 0 then return false end

    pid = tonumber(pid)
    if not pid then return false end

    local proc = k.get_process(pid)
    if not proc then return false end

    return #attr == 0 or not not proc[attr]
  end

  function provider:stat(path)
    checkArg(1, path, "string")
    if not self:exists(path) then return nil, k.errno.ENOENT end
  end

  return provider
end
