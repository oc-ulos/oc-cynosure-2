--[[
    Permissions-related utilities.
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

k.log(k.L_INFO, "permissions")

do
  local modes = k.common.fsmodes
  local checks = {
    r = {modes.owner_r, modes.group_r, modes.other_r},
    w = {modes.owner_w, modes.group_w, modes.other_w},
    x = {modes.owner_x, modes.group_x, modes.other_x}
  }

  function k.common.has_permission(info, perm)
    local uid = k.syscall.geteuid()
    local gid = k.syscall.getegid()
    local level = (info.uid == uid and 1) or (info.gid == gid and 2) or 3
    return info.mode & checks[perm][level] ~= 0
  end
end
