-- Patches for buggy standard library functions and implementations of
-- missing functions in Lua 4.0.x

require "std.data.global"


if strsub (_VERSION, 1, 7) == "Lua 4.0" then

  -- @func unpack: Turn a list into a tuple
  --   @param l: list
  -- returns
  --   @param v1, ..., @param vn: values
  function unpack (l, from, to)
    from = from or 1
    to = to or getn (l)
    if from < to then
      return l[from], unpack (l, from + 1, to)
    else
      return l[from]
    end
  end
  
  -- Make sort return its result
  local _sort = sort
  function sort (t, c)
    if c then
      %_sort (t, c)
    else
      %_sort (t)
    end
    return t
  end
  
  -- Make tinsert (t, p, v1 ... vn) insert v1 rather than vn, and when
  -- p > getn (t), set t.n = p
  local _tinsert = tinsert
  function tinsert (t, ...)
    local pos
    local n = getn (t)
    if arg.n == 1 then
      pos = getn (t) + 1
    else
      pos = arg[1]
    end
    if pos > n then
      t.n = pos - 1
    end
    if arg.n == 1 then
      %_tinsert (t, arg[1])
    elseif arg.n >= 2 then
      %_tinsert (t, arg[1], arg[2])
    else
      %_tinsert (t)
    end
  end

  -- Make setglobal (g, v1 ... vn) assign v1 to g rather than vn
  local _setglobal = setglobal
  function setglobal (g, v)
    %_setglobal (g, v)
  end
  
  -- Make strfind work so that if init == nil it defaults to 1, and if
  -- plain == nil then magic characters are interpreted
  local _strfind = strfind
  function strfind (s, p, init, plain)
    init = init or 1
    if plain then
      return %_strfind (s, p, init, plain)
    else
      return %_strfind (s, p, init)
    end
  end

  -- Make PI unassignable
  PI = newConstant (PI)

end
