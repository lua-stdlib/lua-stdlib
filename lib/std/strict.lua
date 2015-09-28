--[[--
 Checks uses of undeclared variables.

 All variables (including functions!) must be "declared" through a regular
 assignment (even assigning `nil` will do) in a strict scope before being
 used anywhere or assigned to inside a function.

 Use the callable returned by this module to interpose a strictness check
 proxy table to the given environment.

 The implementation calls `setfenv` appropriately in Lua 5.1 interpreters
 to ensure the same semantics.

 @module std.strict
]]

local debug_getinfo	= debug.getinfo
local error		= error
local rawset		= rawset
local rawget		= rawget
local setfenv		= setfenv or function () end
local setmetatable	= setmetatable

local _DEBUG		= require "std.debug_init"._DEBUG

local _ENV = {}
setfenv (1, _ENV)


--- What kind of variable declaration is this?
-- @treturn string "C", "Lua" or "main"
local function what ()
  local d = debug_getinfo (3, "S")
  return d and d.what or "C"
end


local function restrict (env)
  -- The set of declared variables in this scope.
  local declared = {}

  --- Metamethods
  -- @section metamethods

  return setmetatable ({}, {
    --- Detect dereference of undeclared global.
    -- @function __index
    -- @string n name of the variable being dereferenced
    __index = function (_, n)
      local v = env[n]
      if v ~= nil then
        declared[n] = true
      elseif not declared[n] and what () ~= "C" then
        error ("variable '" .. n .. "' is not declared", 2)
      end
      return v
    end,

    --- Detect assignment to undeclared global.
    -- @function __newindex
    -- @string n name of the variable being declared
    -- @param v initial value of the variable
    __newindex = function (_, n, v)
      local x = env[n]
      if x == nil and not declared[n] then
        local w = what ()
        if w ~= "main" and w ~= "C" then
          error ("assignment to undeclared variable '" .. n .. "'", 2)
        end
      end
      declared[n] = true
      env[n] = v
    end,
  })
end


return setmetatable ({}, {
  --- Enforce strict variable declarations in *env* according to `_DEBUG`.
  -- @function strict:__call
  -- @tparam table env lexical environment table
  -- @treturn table *env* which must be assigned to `_ENV`
  -- @usage
  -- local _ENV = require "std.strict" (setmetatable ({}, {__index = _G}))
  __call = function (_, env)
    if _DEBUG.strict then
      env = restrict (env)
    end
    setfenv (2, env)
    return env
  end,
})
