--[[--
 Additional Lua language features.

 @module std.lua
]]

local base     = require "std.base"
local operator = require "std.operator"

local export, getmetamethod = base.export, base.getmetamethod

local M = { "std.lua" }



--[[ ================= ]]--
--[[ Helper Functions. ]]--
--[[ ================= ]]--


local function wrapiterator (factory, ...)
  -- Capture wrapped ctrl variable into an upvalue...
  local fn, istate, ctrl = factory (...)
  -- Wrap the returned iterator fn to maintain wrapped ctrl.
  return function (state, _)
           local v
	   ctrl, v = fn (state, ctrl)
	   if ctrl then return v end
	 end, istate, true -- wrapped initial state, and wrapper ctrl
end



--[[ ================= ]]--
--[[ Module Functions. ]]--
--[[ ================= ]]--


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
-- @function elems
-- @tparam sequence x a sequence
-- @treturn function iterator function
-- @treturn sequence *x*, the sequence being iterated over
-- @treturn int *key*, the previous iteration key
-- @usage
-- for v in elems {a = 1, b = 2, c = 5} do process (v) end
export (M, "elems (string|table)", function (x)
  return wrapiterator (getmetamethod (x, "__pairs") or pairs, x)
end)


--- An iterator over the integer keyed elements of a sequence.
-- @function ielems
-- @tparam sequence x a sequence
-- @treturn function iterator function
-- @treturn sequence *x*, the sequence being iterated over
-- @treturn int *index*, the previous iteration index
-- @usage
-- for v in ielems {"a", "b", "c"} do process (v) end
export (M, "ielems (List|list|string)", function (x)
  return wrapiterator (getmetamethod (x, "__ipairs") or ipairs, x)
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



return M
