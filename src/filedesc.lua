--[[
    File descriptor support code
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

printk(k.L_INFO, "filedesc")

do
  local function fread(self, n)
    return self.proxy.read(self.fd, n)
  end
  local function fwrite(self, d)
    return self.proxy.write(self.fd, d)
  end
  local function fseek(self, w, o)
    return self.proxy.seek(self.fd, w, o)
  end
  local function fclose(self)
    return self.proxy.close(self.fd)
  end
  -- create a file descriptor object from a managed filesystem's file
  -- descriptor
  function k.fd_from_managed(proxy, fd, mode)
    checkArg(1, proxy, "table")
    -- ocvm returns userdata rather than a number
    checkArg(2, fd, "number", "userdata")
    checkArg(3, mode, "string")
    local new = k.buffer_from_stream({
      read = fread, write = fwrite, seek = fseek, close = fclose,
      fd = fd, proxy = proxy
    }, mode)
    -- number of references to the file descriptor
    -- when this hits 0, it is closed
    new.refs = 1
    local close = new.close
    function new:close()
      self.refs = self.refs - 1
      if self.refs == 0 then
        close(self)
      end
    end
    return new
  end

  local function ebadf()
    return nil, k.errno.EBADF
  end

  -- create a file descriptor from a reader and/or writer function
  function k.fd_from_rwf(read, write, close)
    checkArg(1, read, "function", write and "nil")
    checkArg(2, write, "function", read and "nil")
    checkArg(3, close, "function", "nil")
    return {
      read = read or ebadf, write = write or ebadf,
      refs = 1, close = function(s)
        self.refs = self.refs - 1
        if close and self.refs == 0 then close() end
      end
    }
  end
end
