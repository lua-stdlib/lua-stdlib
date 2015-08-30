--[[--
 Object prototype.

 This module provides a specialization of the @{std.container.prototype}
 with the addition of object methods.  In addition to the functionality
 described here, object prototypes also have all the methods and
 metamethods of the @{std.container.prototype}.

 Note that object methods are stored in the `__index` field of their
 metatable, and so cannot also use the `__index` metamethod to lookup
 references with square brackets.  Use a @{std.container.prototype} based
 object if you want to do that.

 Prototype Chain
 ---------------

       table
        `-> Container
             `-> Object

 @prototype std.object
]]


local _ENV, _DEBUG = _G, require "std.debug_init"._DEBUG

if _DEBUG.strict then
  _ENV = require "std.strict" (setmetatable ({}, {__index = _G}))
  if rawget (_G, "setfenv") then setfenv (1, _ENV) end
end


local container = require "std.container"
local debug     = require "std.debug"
local std       = require "std.base"

local Container = container.prototype


local function X (decl, fn)
  return debug.argscheck ("std.object." .. decl, fn)
end


--- Object prototype.
-- @object prototype
-- @string[opt="Object"] _type object name
-- @tfield[opt] table|function _init object initialisation
-- @usage
-- local Object = require "std.object".prototype
-- local Process = Object {
--   _type = "Process",
--   _init = { "status", "out", "err" },
-- }
-- local process = Process {
--   procs[pid].status, procs[pid].out, procs[pid].err, -- auto assigned
--   command = pipeline[pid],                           -- manual assignment
-- }
local prototype = Container {
  _type  = "std.object.Object",

  --- Metamethods
  -- @section metamethods

  --- Return an in-order iterator over public object fields.
  -- @function prototype:__pairs
  -- @treturn function iterator function
  -- @treturn Object *self*
  -- @usage
  -- for k, v in std.pairs (anobject) do process (k, v) end

  __index = {
    --- Methods
    -- @section methods

    --- Return a clone of this object and its metatable.
    --
    -- This function is useful if you need to override the normal use of
    -- the `__call` metamethod for object cloning, without losing the
    -- ability to clone an object.
    -- @function prototype:clone
    -- @param ... arguments to prototype's *\_init*, often a single table
    -- @treturn prototype a clone of this object, with shared or merged
    --   metatable as appropriate
    -- @see std.container.__call
    -- @usage
    -- local Node = Object { _type = "Node" }
    -- -- A trivial FSA to recognize powers of 10, either "0" or a "1"
    -- -- followed by zero or more "0"s can transition to state 'finish'
    -- local states; states = {
    --   start  = Node { ["1"] = states[1], ["0"] = states.finish },
    --   [1]    = Node { ["0"] = states[1], [""] = states.finish },
    --   finish = Node {},
    -- }
    clone = std.getmetamethod (Container, "__call"),

    --- Type of this object.
    -- @function prototype:type
    -- @treturn string type of this object.
    -- @see std.type
    -- @usage
    -- assert (Object:type () == getmetatable (Object)._type)
    type = X ("type (?any)", std.type),


    --- Object Functions
    -- @section objfunctions

    --- Return *new* with references to the fields of *src* merged in.
    --
    -- You can change the value of this function in an object, and that
    -- new function will be called during cloning instead of the
    -- standard @{std.container.mapfields} implementation.
    -- @function prototype.mapfields
    -- @tparam table new partially instantiated clone container
    -- @tparam table src @{clone} argument table that triggered cloning
    -- @tparam[opt={}] table map key renaming specification in the form
    --   `{old_key=new_key, ...}`
    -- @treturn table merged public fields from *new* and *src*, with a
    --   metatable of private fields (if any), both renamed according to
    --   *map*
    -- @see std.container.mapfields
    mapfields = X ("mapfields (table, table|object, ?table)", std.object.mapfields),

    -- Backwards compatibility:
    prototype = debug.DEPRECATED ("41.3", "'std.object.prototype'", std.type),
  },
}


return std.object.Module {
  prototype = prototype,

  type = debug.DEPRECATED ("41.3", "'std.object.type'", std.type),
}
