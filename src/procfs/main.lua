--[[
    Cynosure's /proc filesystem.
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

--#include "src/ramfs.lua"

k.log(k.L_INFO, "procfs/main")

do
  local procfs = k.common.ramfs.new("procfs")
  k.state.procfs = procfs
  k.state.mount_sources.procfs = procfs

  function procfs.registerStaticFile(path, data)
    local ent = procfs:_create(path, k.common.fsmodes.f_regular)
    ent.writer = function() end
    ent.data = k.state.cmdline
  end

  local function mkdblwrap(func)
    return function(n)
      return function(...)
        return func(n, ...)
      end
    end
  end

  function procfs.registerDynamicFile(path, reader, writer)
    local ent = procfs:_create(path, k.common.fsmodes.f_regular)
    ent.reader = mkdblwrap(reader)
    ent.writer = mkdblwrap(writer)
  end
end
