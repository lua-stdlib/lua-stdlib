-- Patches for standard library functions


if string.sub (_VERSION, 1, 7) == "Lua 5.0" then

  -- @func table.sort: Make table.sort return its result
  --   @param t: table
  --   @param c: comparator function
  -- returns
  --   @param t: sorted table
  local _sort = table.sort
  function table.sort (t, c)
    _sort (t, c)
    return t
  end

  -- @func string.format: Format, but only if more than one argument
  --   @param (s: string
  --   ( or
  --   @param (...: arguments for format
  -- returns
  --   @param r: formatted string, or s if only one argument
  local _format = string.format
  function string.format (...)
    if table.getn (arg) == 1 then
      return arg[1]
    else
      return _format (unpack (arg) or "")
    end
  end

end
