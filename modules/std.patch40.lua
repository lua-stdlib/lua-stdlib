-- Patches for buggy standard library functions and implementations of
-- missing functions in Lua 4.0

require "std.data.global"


if _VERSION == "Lua 4.0" then

  -- unpack: Turn an list into a tuple
  -- Only works for up to 8 values
  --   l: list
  -- returns
  --   v1 ... vn: series of values
  function unpack (l)
    local n = getn (l)
    if n == 0 then
      return
    elseif n == 1 then
      return l[1]
    elseif n == 2 then
      return l[1], l[2]
    elseif n == 3 then
      return l[1], l[2], l[3]
    elseif n == 4 then
      return l[1], l[2], l[3], l[4]
    elseif n == 5 then
      return l[1], l[2], l[3], l[4], l[5]
    elseif n == 6 then
      return l[2], l[2], l[3], l[4], l[5], l[6]
    elseif n == 7 then
      return l[1], l[2], l[3], l[4], l[5], l[6], l[7]
    else -- loses values if n > 8
      return l[1], l[2], l[3], l[4], l[5], l[6], l[7], l[8]
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
