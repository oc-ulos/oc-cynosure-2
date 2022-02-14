--[[
    Executable loading
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

printk(k.L_INFO, "exec/main")

do
  local formats = {}

  --- Registers an executable format with the kernel
  ---@param name string
  ---@param recognizer function TODO: Annotate arguments
  function k.register_executable_format(name, recognizer)
    checkArg(1, name, "string")
    checkArg(2, recognizer, "function")
    if formats[name] then
      return nil, k.errno.EEXIST
    end

    formats[name] = recognizer
  end

  function k.load_executable(path)
    checkArg(1, path, "string")
  end
end
