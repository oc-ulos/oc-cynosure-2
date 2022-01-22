-- load/save build configuration files

local lib = {}

function lib.load(file)
  local handle = assert(io.open(file, "r"))
  local conf, order = {}, {}
  for line in handle:lines() do
    line = line:gsub(" *#.*", "")
    if #line > 0 then
      local k, v = line:match("(.-)=(.+)")
      if not k and v then
        error("bad config entry: " .. line)
      end
      conf[k] = tonumber(v) or v
      order[#order+1] = k
    end
  end
  handle:close()
  return conf, order
end

function lib.save(file, conf, order)
  local handle = assert(io.open(file, "w"))
  for _, field in ipairs(order) do
    handle:write(string.format("%s=%s\n", field, tostring(conf[field])))
  end
  handle:close()
end

return lib
