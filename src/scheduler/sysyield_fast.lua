  local function sysyield()
    local proc = k.current_process()
    proc.last_yield = proc.last_yield or computer.uptime()
    local last_yield = proc.last_yield

    if computer.uptime() - last_yield >= 0.1 then
      if pcall(coroutine.yield, k.sysyield_string) then
        proc.last_yield = computer.uptime()
      end
    end
  end
