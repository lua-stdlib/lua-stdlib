--[[--
 Additional Lua language features.

 @module std.lua
]]

local base     = require "std.base"
local list     = require "std.list"
local operator = require "std.operator"

local List     = list {}
local export, getmetamethod, wrapiterator =
      base.export, base.getmetamethod, base.wrapiterator
local ielems, ireverse, ripairs, split =
      base.ielems, base.ireverse, base.ripairs, base.split

local M = { "std.lua" }



--[[ ================= ]]--
--[[ Helper Functions. ]]--
--[[ ================= ]]--


--- Return a List object by splitting version string on periods.
-- @string version a period delimited version string
-- @treturn List a list of version components
local function version_to_list (version)
  return List (split (version, "%."))
end


--- Extract a list of period delimited integer version components.
-- @tparam table module returned from a `require` call
-- @string pattern to capture version number from a string
--   (default: `"%D*([%.%d]+)"`)
-- @treturn List a list of version components
local function module_version (module, pattern)
  local version = module.version or module._VERSION
  return version_to_list (version:match (pattern or "%D*([%.%d]+)"))
end



--[[ ================= ]]--
--[[ Module Functions. ]]--
--[[ ================= ]]--


--- Extend to allow formatted arguments.
-- @function assert
-- @param expect expression, expected to be *truthy*
-- @string[opt=""] f format string
-- @param[opt] ... arguments to format
-- @return value of *expect*, if *truthy*
-- @usage
-- assert (expected ~= nil, "100% unexpected!")
-- assert (expected ~= nil, "%s unexpected!", expected)
export (M, "assert (any?, string?, any?*)", function (expect, f, arg1, ...)
  local msg = (arg1 ~= nil) and string.format (f, arg1, ...) or f or ""
  return expect or error (msg, 2)
end)


--- A rudimentary case statement.
-- Match `with` against keys in `branches` table, and return the result
-- of running the function in the table value for the matching key, or
-- the first non-key value function if no key matches.
-- @function case
-- @param with expression to match
-- @tparam table branches map possible matches to functions
-- @return the return value from function with a matching key, or nil.
-- @usage
-- return case (type (object), {
--   table  = function ()  return something end,
--   string = function ()  return something else end,
--            function (s) error ("unhandled type: "..s) end,
-- })
export (M, "case (any?, #table)", function (with, branches)
  local f = branches[with] or branches[1]
  if f then return f (with) end
end)


--- Evaluate a string.
-- @function eval
-- @string s string of Lua code
-- @return result of evaluating `s`
-- @usage eval "math.pow (2, 10)"
export (M, "eval (string)", function (s)
  return loadstring ("return " .. s)()
end)


--- An iterator over all elements of a sequence.
-- If there is a `__pairs` metamethod, use that to iterate.
-- @function elems
-- @tparam table t a table
-- @treturn function iterator function
-- @treturn table *t*, the table being iterated over
-- @return *key*, the previous iteration key
-- @see ielems
-- @see pairs
-- @usage
-- for v in elems {a = 1, b = 2, c = 5} do process (v) end
export (M, "elems (table)", function (t)
  return wrapiterator (getmetamethod (t, "__pairs") or pairs, t)
end)


--- An iterator over the integer keyed elements of a sequence.
-- If there is an `__ipairs` metamethod, use that to iterate.
-- @function ielems
-- @tparam table t a table
-- @treturn function iterator function
-- @treturn list *l*, the list being iterated over
-- @treturn int *index*, the previous iteration index
-- @see elems
-- @see ipairs
-- @usage
-- for v in ielems {"a", "b", "c"} do process (v) end
export (M, "ielems (table)", ielems)


--- An implementation of core ipairs that respects __ipairs even in Lua 5.1.
-- @function ipairs
-- @tparam table t a table
-- @treturn function iterator function
-- @treturn list *l*, the list being iterated over
-- @treturn int *index*, the previous iteration index
-- @see ielems
-- @see pairs
-- @usage
-- for i, v in ipairs {"a", "b", "c"} do process (v) end
local ipairs = export (M, "ipairs (table)", function (l)
  return ((getmetatable (l) or {}).__ipairs or ipairs) (l)
end)


--- A new reversed list.
-- @function ireverse
-- @tparam table t a table
-- @treturn list a new list
-- @see ielems
-- @see ipairs
-- @usage
-- rielems = std.functional.compose (ireverse, ielems)
-- for e in rielems (l) do process (e) end
export (M, "ireverse (table)", function (l)
  return ireverse (l)
end)


--- Memoize a function, by wrapping it in a functable.
--
-- To ensure that memoize always returns the same results for the same
-- arguments, it passes arguments to `normalize` (std.string.tostring
-- by default). You can specify a more sophisticated function if memoize
-- should handle complicated argument equivalencies.
-- @function memoize
-- @func fn function with no side effects
-- @func normalize[opt] function to normalize arguments
-- @treturn functable memoized function
-- @usage
-- local fast = memoize (function (...) --[[ slow code ]] end)
local memoize = export (M, "memoize (func, func?)", function (fn, normalize)
  if normalize == nil then
    -- Call require here, to avoid pulling in all of 'std.string'
    -- even when memoize is never called.
    local stringify = require "std.string".tostring
    normalize = function (...) return stringify {...} end
  end

  return setmetatable ({}, {
    __call = function (self, ...)
               local k = normalize (...)
               local t = self[k]
               if t == nil then
                 t = {fn (...)}
                 self[k] = t
               end
               return unpack (t)
             end
  })
end)


--- Signature of memoize `normalize` functions.
-- @function memoize_normalize
-- @param ... arguments
-- @treturn string normalized arguments


--- Compile a lambda string into a Lua function.
--
-- A valid lambda string takes one of the following forms:
--
--   1. `operator`: where *op* is a key in @{std.operator}, equivalent to that operation
--   1. `"=expression"`: equivalent to `function (...) return (expression) end`
--   1. `"|args|expression"`: equivalent to `function (args) return (expression) end`
--
-- The second form (starting with `=`) automatically assigns the first
-- nine arguments to parameters `_1` through `_9` for use within the
-- expression body.
-- @function lambda
-- @string s a lambda string
-- @treturn table compiled lambda string, can be called like a function
-- @usage
-- -- The following are all equivalent:
-- lambda "<"
-- lambda "= _1 < _2"
-- lambda "|a,b| a<b"
local function lambda (l)
  local s

  -- Support operator table lookup.
  if operator[l] then
    return operator[l]
  end

  -- Support "|args|expression" format.
  local args, body = string.match (l, "^|([^|]*)|%s*(.+)$")
  if args and body then
    s = "return function (" .. args .. ") return " .. body .. " end"
  end

  -- Support "=expression" format.
  if not s then
    body = l:match "^=%s*(.+)$"
    if body then
      s = [[
        return function (...)
          local _1,_2,_3,_4,_5,_6,_7,_8,_9 = unpack {...}
	  return ]] .. body .. [[
        end
      ]]
    end
  end

  local ok, fn
  if s then
    ok, fn = pcall (loadstring (s))
  end

  -- Diagnose invalid input.
  if not ok then
    return nil, "invalid lambda string '" .. l .. "'"
  end

  return fn
end

export (M, "lambda (string)", memoize (lambda, function (s) return s end))


--- Inject `std.lua` functions into global table, overwriting core functions.
--
-- This function does not inject itself into the global table, however!
-- @function monkey_patch
-- @tparam[opt=_G] table namespace to install `std.lua` functions into
-- @treturn table the module table
-- @usage local lua = require "std.lua".monkey_patch ()
export (M, "monkey_patch (table?)", function (namespace)
  namespace = namespace or _G

  for fname in ielems {
    "assert", "case", "eval", "elems", "ielems", "ipairs", "ireverse",
    "lambda", "memoize", "pairs", "require"
  } do
    namespace[fname] = M[fname]
  end

  return M
end)


--- An implementation of core pairs that respects __pairs even in Lua 5.1.
-- @function pairs
-- @tparam table t a table
-- @treturn function iterator function
-- @treturn table *t*, the table being iterated over
-- @return *key*, the previous iteration key
-- @see elems
-- @see ipairs
-- @usage
-- for k, v in pairs {"a", b = "c", foo = 42} do process (k, v) end
export (M, "pairs (table)", function (t)
  return (getmetamethod (t, "__pairs") or pairs) (t)
end)


--- Require a module with a particular version.
-- @function require
-- @string module module to require
-- @string[opt] min lowest acceptable version
-- @string[opt] too_big lowest version that is too big
-- @string[opt] pattern to match version in `module.version` or
--  `module._VERSION` (default: `"%D*([%.%d]+)"`)
-- @usage std = require ("std", "41")
export (M, "require (string, string?, string?, string?)",
function (module, min, too_big, pattern)
  local m = require (module)
  if min then
    assert (module_version (m, pattern) >= version_to_list (min))
  end
  if too_big then
    assert (module_version (m, pattern) < version_to_list (too_big))
  end
  return m
end)


--- An iterator like ipairs, but in reverse.
-- @function ripairs
-- @tparam table t any table
-- @treturn function iterator function
-- @treturn table *t*
-- @treturn number `#t + 1`
-- @usage for i, v = ripairs (t) do ... end
export (M, "ripairs (table)", ripairs)


return M
