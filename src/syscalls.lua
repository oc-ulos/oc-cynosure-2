-- system call registry --

do
  k.syscall = {}

  local mutices = {}

  local _mut = {}
  function _mut:lock()
    repeat
      coroutine.yield()
    until not self.locked
    self.locked = k.state.sched_current
    return true
  end

  function _mut:unlock()
    self.locked = false
  end

  function k.syscall.lockmutex()
  end

  function k.syscall.unlockmutex()
  end
end
