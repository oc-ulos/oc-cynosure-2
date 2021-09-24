-- kernel command line parsing --

do
  k.cmdline = {}

  local _args = table.pack(...)
  k.state.cmdline = table.concat(_args, " ", 1, _args.n)
  for i, arg in ipairs(_args) do
    local key, val = arg, true
    if arg:find("=") then
      key, val = arg:match("^(.-)=(.+)$")
      if val == "true" then val = true
      elseif val == "false" then val = false
      else val = tonumber(val) or val end
    end
    local ksegs = {}
    for ent in key:gmatch("[^%.]+") do
      ksegs[#ksegs+1] = ent
    end
    local cur = k.cmdline
    for i=1, #ksegs-1, 1 do
      k.cmdline[ksegs[i]] = k.cmdline[ksegs[i]] or {}
      cur = k.cmdline[ksegs[i]]
    end
    cur[ksegs[#ksegs]] = val
  end
end
