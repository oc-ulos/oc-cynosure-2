-- early boot logger --

do
  local gpu, screen = component.list("gpu", true)(),
    component.list("screen", true)()

  k.logio = {y = 1}

  local time = computer.uptime()

  if gpu and screen then
    gpu = component.proxy(gpu)
    gpu.bind(screen)
    local w, h = gpu.maxResolution()
    gpu.setResolution(w, h)
    gpu.fill(1,1,w,h," ")
    function k.logio:write(msg)
      if k.logio.y > h then
        gpu.copy(1, 1, w, h, 0, -1)
        gpu.fill(1, h, w, 1, " ")
      end
      gpu.set(1, k.logio.y, (msg:gsub("\n","")))
      k.logio.y = k.logio.y + 1
    end
  else
    function k.logio.write() end
  end

  k.cmdline.loglevel = tonumber(k.cmdline.loglevel) or 8
  
  function k.log(l, ...)
    local args = table.pack(...)
    if type(l) == "string" then table.insert(args, 1, l) l = 1 end
    local msg = ""
    for i=1, args.n, 1 do
      msg = msg .. (i > 1 and i < args.n and " " or "") .. tostring(args[i])
    end
    if l <= k.cmdline.loglevel then
      k.logio:write(msg, "\n")
    end
    return true
  end

end
