-- logger constants --

local function e(n)
  return string.format("\27[%dm", n)
end

local log = {
  -- colors
  red     = e(91),
  green   = e(92),
  yellow  = e(93),
  blue    = e(94),
  magenta = e(95),
  cyan    = e(96),
  white   = e(39)
}

-- prefixes
log.info = log.green .. "> " .. log.white
log.warn = log.yellow .. "> " .. log.white
log.fail = log.red .. "> " .. log.white

return log
