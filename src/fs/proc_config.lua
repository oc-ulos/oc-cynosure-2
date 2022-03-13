  files.config = { data = [==[@[{ (function() local bc = "" for k, v in pairs(bconf) do bc = bc .. k .. "=" .. v .. "\n" end return bc end)() }]]==] }
