--[[
    Main source file for the Cynosure kernel boot logger.
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

--#include "src/platform/@[{os.getenv('KPLATFORM') == 'cc' and 'cc' or 'oc'}]/logger.lua"

do
  function k.panic(reason)
    k.log(k.L_EMERG, "============ kernel panic ============")
    k.log(k.L_EMERG, reason)
    for line in debug.traceback():gmatch("[^\n]+") do
      k.log(k.L_EMERG, (line:gsub("\t", "  ")))
    end
    k.log(k.L_EMERG, "======================================")
  end

  k.L_EMERG = 0
  k.L_ALERT = 1
  k.L_CRIT = 2
  k.L_ERR = 3
  k.L_WARNING = 4
  k.L_NOTICE = 5
  k.L_INFO = 6
  k.L_DEBUG = 7

  local klogo = [[
--#include "src/logo.txt" force
  ]]
  for line in klogo:gmatch("[^\n]+") do
    k.log(k.L_EMERG, line)
  end
  
  k.log(k.L_NOTICE, string.format("%s (%s@%s) on %s", _OSVERSION,
    k._VERSION.build_user, k._VERSION.build_host, _VERSION))

  if #k.state.cmdline > 0 then
    k.log(k.L_INFO, "Command line:", k.state.cmdline)
  end
end

