--[[
    URL infrastructure
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

printk(k.L_INFO, "urls/main")

do
  k.schemes = {}

  function k.register_scheme(name, registrar)
    checkArg(1, name, "string")
    checkArg(2, registrar, "table")
    if k.schemes[name] then
      panic("attempted to double-register scheme " .. name)
    end
    schemes[name] = registrar
  end
end

--@[{bconf.SCHEME_MISC == 'y' and '#include "src/urls/scheme_misc.lua"' or ''}]
--@[{bconf.SCHEME_EXEC == 'y' and '#include "src/urls/scheme_exec.lua"' or ''}]
--@[{bconf.SCHEME_HTTP == 'y' and '#include "src/urls/scheme_http.lua"' or ''}]
--@[{bconf.SCHEME_TCP == 'y' and '#include "src/urls/scheme_tcp.lua"' or ''}]
--@[{bconf.SCHEME_COMPONENT == 'y' and '#include "src/urls/scheme_component.lua"' or ''}]
