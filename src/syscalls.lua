--[[
    System call registry.
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

do
  k.syscall = {}

  local mutices = {}

  local _mut = {}
  function _mut:lock()
    repeat
      coroutine.yield()
    until not self.locked
    self.locked = k.state.sched_current
    return true
  end

  function _mut:unlock()
    self.locked = false
  end

  function k.syscall.lockmutex()
  end

  function k.syscall.unlockmutex()
  end
end
