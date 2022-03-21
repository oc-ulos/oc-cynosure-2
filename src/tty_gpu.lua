  -- GPU control escape code
  --
  -- Controls:
  --  - 1;x;y;w;h;cU = gpu.fill(x,y,w,h,string.char(c))
  --  - 2;x;y;w;h;dx;dyU = gpu.copy(x,y,w,h,dx,dy)
  --  - 3;idx;valU = gpu.setPaletteColor(idx, val)

  function commands:U(args)
    if #args == 0 then return end
    if args[1] == 1 then
      if #args < 6 then return end
      args[6] = unicode.char(args[6])
      self.gpu.fill(table.unpack(args, 2))
    elseif args[1] == 2 then
      if #args < 7 then return end
      self.gpu.copy(table.unpack(args, 2))
    elseif args[1] == 3 then
      if #args < 3 then return end
      self.gpu.setPaletteColor(table.unpack(args, 2))
    end
  end
