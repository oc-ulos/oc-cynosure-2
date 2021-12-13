--[[
    Device management as an abstraction over components.
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

k.log(k.L_INFO, "devices")

-- base API
do
  k.state.devsearchers = {}
  function k.lookup_device(node)
    for k, v in pairs(k.state.devsearchers) do
      if v.matches(node) then
        return v.setup(node)
      end
    end
    return nil, k.errno.ENXIO
  end
end

--#include "src/platform/@[{os.getenv('KPLATFORM') or 'oc'}]/devices.lua"