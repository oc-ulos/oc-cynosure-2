  local last_yield = computer.uptime()
  local function sysyield()
    if computer.uptime() - last_yield >= 0.1 then
      last_yield = computer.uptime()
      coroutine.yield(sys)
    end
  end
