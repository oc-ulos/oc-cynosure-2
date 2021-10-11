-- logger stub --

--#include "src/platform/@[{os.getenv('KPLATFORM') == 'cc' and 'cc' or 'oc'}]/logger.lua"

do
  function k.panic(reason)
    k.log(k.L_EMERG, "============ kernel panic ============")
    k.log(k.L_EMERG, reason)
    for line in debug.traceback():gmatch("[^\n]+") do
      k.log(k.L_EMERG, (line:gsub("\t", "  ")))
    end
    k.log(k.L_EMERG, "======================================")
  end

  local klogo = [[
--#include "src/logo.txt" force
  ]]
  for line in klogo:gmatch("[^\n]+") do
    k.log(k.L_EMERG, line)
  end
end

