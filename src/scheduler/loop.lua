--[[
    Simple scheduler main loop
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

printk(k.L_INFO, "scheduler/loop")

do
  local processes = {}
  local pid = 0
  local current = 0

  k.pgroups = {[0] = { sid = 0 }}

  function collectgarbage()
    local missed = {}
    for i=1, 10, 1 do
      local sig = table.pack(computer.pullSignal(0))
      if sig.n > 0 then missed[#missed+1] = sig end
    end
    for i=1, #missed, 1 do
      computer.pushSignal(table.unpack(missed[i], 1, missed[i].n))
    end
  end

  --[[
    Scheduler main loop:
      * Go through all processes and find their deadlines.
      * If one of the deadlines is -1 (the process needs to
        be resumed immediately for maximum responsiveness),
        then we resume it if we can.  If it has been more
        than 4 seconds since the last yield, we pullSignal(0)
        first.  This is for maximum responsiveness during
        pre-emption and system calls.
      * For yielding, we pull a signal and resume processes
        with it.
  --]]
  local default = {n=0}
  function k.scheduler_loop()
    local last_yield = 0

    while processes[1] do
      local deadline = math.huge
      for _, process in pairs(processes) do
        local proc_deadline = process:deadline()
        if proc_deadline < deadline then
          deadline = proc_deadline
          if deadline < 0 then break end
        end
      end

      local signal = default
      if deadline == -1 then
        if computer.uptime() - last_yield > 4 then
          last_yield = computer.uptime()
          signal = table.pack(k.pullSignal(0))
        end
      else
        last_yield = computer.uptime()
        signal = table.pack(k.pullSignal(deadline - computer.uptime()))
      end

      for cpid, process in pairs(processes) do
        current = cpid
        if computer.uptime() >= process:deadline() or #signal > 0 then
          process:resume(table.unpack(signal, 1, signal.n))
          if not next(process.threads) then
          k.pushSignal("process_exit", cpid, process.status or 0)
            for _, fd in pairs(process.fds) do
              k.close(fd)
            end
            processes[cpid] = nil
          end
        end
      end

      -- if <8k memory free, collect some garbage
      if computer.freeMemory() < @[{bconf.MEM_THRESHOLD or 1024}] then
        printk(k.L_DEBUG, "low free memory - collecting garbage")
        collectgarbage()
      end
    end
  end

  function k.add_process()
    pid = pid + 1
    processes[pid] = k.create_process(pid, processes[current])
    return pid
  end

  function k.current_process()
    return processes[current]
  end

  function k.get_process(rpid)
    checkArg(1, rpid, "number")
    return processes[rpid]
  end

  function k.get_pids()
    local procs = {}
    for ppid in pairs(processes) do
      procs[#procs + 1] = ppid
    end
    return procs
  end
end
