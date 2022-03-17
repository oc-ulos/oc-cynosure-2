  files.events = {
    data = function() end,
    ioctl = function(method, sig, a, ...)
      if method == "register" then
        local proc = k.current_process()
        local id = k.add_signal_handler(sig, a)
        proc.handlers[id] = true
        return id
      elseif method == "deregister" then
        local proc = k.current_process()
        if not proc.handlers[sig] then
          return nil, k.errno.EINVAL
        end
        proc.handlers[sig] = nil
        k.remove_signal_handler(sig)
        return true
      elseif method == "push" then
        return k.pushSignal(sig, a, ...)
      end
    end
  }
