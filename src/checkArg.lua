-- wrap checkArg --

do
  function _G.checkArg(n, have, ...)
    have = type(have)

    local function check(want, ...)
      if not want then
        return false
      else
        return have == want or defs[want] == have or check(...)
      end
    end

    if type(n) == "number" then n = string.format("#%d", n)
    else n = "'"..tostring(n).."'" end
    if not check(...) then
      local name = debug.getinfo(3, 'n').name
      local msg
      if name then
         msg = string.format("bad argument %s to '%s' (%s expected, got %s)",
          n, name, table.concat(table.pack(...), " or "), have)
      else
        msg = string.format("bad argument %s (%s expected, got %s)", n,
          table.concat(table.pack(...), " or "), have)
      end
      error(msg, 2)
    end
  end
end
