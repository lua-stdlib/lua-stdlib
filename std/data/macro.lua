-- Macros

require "std/data/list.lua"
require "std/data/global.lua"
require "std/text/regex.lua"


-- newMacro: Make a global to get and set an lvalue
--   e: the expression to evaluate for the lvalue
-- returns
--   t: value of new global
function newMacro (e)
  return newGlobal (function (n, v)
                      return dostring ("return " .. %e)
                    end,
                    dostring ("return function (n, o, v) " .. e ..
                              " = v end"))
end

-- newReadOnlyMacro: Make a read-only global expression
--   e: the expression to evaluate for the lvalue
-- returns
--   t: value of new global
function newReadOnlyMacro (e)
  return newGlobal (function (n, v)
                      return dostring ("return " .. %e)
                    end,
                    function (n, o, v)
                      error ("read-only value")
                    end)
end

-- pathSubscript: subscript a table with a string containing dots
--   t: table
--   s: subscript of the form s1.s2. ... .sn
-- returns
--   v: t.s1.s2. ... .sn
function pathSubscript (t, s)
  return foldl (subscript, t, split ("%.", s))
end
