-- Globals

-- newGlobalType: Make a new global variable type
--   get: getglobal tag method
--   set: setglobal tag method
-- returns
--   tag: tag of new global type
function newGlobalType (get, set)
  local tag = newtag ()
  settagmethod (tag, "getglobal", get)
  settagmethod (tag, "setglobal", set)
  return tag
end

-- newGlobal: Make a special global variable
-- If a tag is supplied, that type is used; otherwise, a uniquely
-- tagged variable with the given methods is created
--   (tag: tag of the special type
--   ( or
--   (get: get tag method
--   (set: set tag method
-- returns
--   t: value of new global
function newGlobal (get, set)
  local t, tTag = {}, get
  if set ~= nil then
    tTag = newGlobalType (get, set)
  end
  return settag (t, tTag)
end

-- newConstant: Make a global constant
--   c: value of the constant
-- returns
--   t: value of new global
function newConstant (c)
  return newGlobal (function (n, v)
                      return %c
                    end,
                    function (n, o, v)
                      error ("constant value")
                    end)
end
