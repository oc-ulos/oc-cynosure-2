--[[
    Versioning.
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
  k._VERSION = {
    major = "@[{os.getenv 'KV_MAJOR' or '2'}]",
    minor = "@[{os.getenv 'KV_MINOR' or '0'}]",
    patch = "@[{os.getenv 'KV_PATCH' or '0'}]",
    build_host = "$[{hostnamectl hostname}]",
    build_user = "@[{os.getenv 'USER' or 'none'}]",
    build_name = "@[{os.getenv 'KNAME' or 'default'}]"
  }
  _G._OSVERSION = string.format("Cynosure %s.%s.%s-%s",
    k._VERSION.major, k._VERSION.minor, k._VERSION.patch, k._VERSION.build_name)
end
