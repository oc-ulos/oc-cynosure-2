--[[
    Executable loading.
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

--#include "src/exec/cex.lua"
--#include "src/exec/binfmt.lua"

do
  function k.load_executable(file)
    local info, err = k.syscall.stat(file)
    if not info then
      return nil, err
    end
    if not k.common.has_permission(
        {mode = info.mode, uid = info.uid, gid = info.gid}, "x") then
      return nil, k.errno.EACCES
    end
    local fd, err = k.syscall.open(file, {rdonly = true})
    if not fd then
      return nil, err
    end
  end
end
