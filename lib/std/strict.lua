--[[--
 Checks uses of undeclared variables.

 All variables (including functions!) must be "declared" through a regular
 assignment (even assigning `nil` will do) in a strict scope before being
 used anywhere or assigned to inside a function.

 Use the callable returned by this module to interpose a strictness check
 proxy table to the argument table.  To apply to just the current module,
 for example:

     local strict = require "std.strict"
     local _ENV = strict (setmetatable ({}, {__index = _G}))
     if rawget (_G, "setfenv") then setfenv (1, _ENV) end

 Note that we have to be careful not to reference `setfenv` directly in
 the `if` statement, because on Lua >= 5.2, it doesn't exist and would
 trigger an undeclared variable error!

 @module std.strict
]]

local getinfo, error, rawset, rawget = debug.getinfo, error, rawset, rawget


--- What kind of variable declaration is this?
-- @treturn string "C", "Lua" or "main"
local function what ()
  local d = getinfo (3, "S")
  return d and d.what or "C"
end


return setmetatable ({}, {
  __call = function (self, env)
    -- The set of globally declared variables.
    local declared = {}

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
  end,
})
