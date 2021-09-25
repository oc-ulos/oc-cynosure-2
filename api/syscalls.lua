--[[

    Generic Cynosure kernel system call interface.

    Cynosure 2.0 standard library headers
    copyright (c) 2021 Ocawesome101 under the
    DSLv2.

    ]]--

local syscall = setmetatable({}, {
  __index = function(t, k)
    return function(..) return t(k, ...) end
  end,
  __call = function(t, sysc, ...)
    return coroutine.yield("syscall", sysc, ...)
  end
})
