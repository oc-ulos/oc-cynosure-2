  local function sysyield()
    pcall(coroutine.yield, k.sysyield_string)
  end
