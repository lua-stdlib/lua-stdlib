--[[--
 Prototype-based objects.

 This module creates the root prototype object from which every other
 object is descended.  There are no classes as such, rather new objects
 are created by cloning an existing object, and then changing or adding
 to the clone. Further objects can then be made by cloning the changed
 object, and so on.

 Objects are cloned by simply calling an existing object, which then
 serves as a prototype from which the new object is copied.

 Note that Object methods are stored in the `__index` field of their
 metatable, and so cannot also use `__index` to lookup references with
 square brackets.  See @{std.container} objects if you want to do that.

 Prototype Chain
 ---------------

       table
        `-> Object

 @classmod std.object
]]


-- Surprise!!  The real root object is Container, which has less
-- functionality than Object, but that makes the heirarchy hard to
-- explain, so the documentation pretends this is the root object, and
-- Container is derived from it.  Confused? ;-)


local base      = require "std.base"
local container = require "std.container"

local Container = container {}
local getmetamethod, prototype = base.getmetamethod, base.prototype



--- Root object.
--
-- Changing the values of these fields in a new object will change the
-- corresponding behaviour.
-- @object Object
-- @string[opt="Object"] _type object name
-- @tfield[opt={}] table|function _init object initialisation
-- @tfield table _functions module functions omitted when cloned
-- @see __call
-- @usage
-- -- `_init` can be a list of keys; then the unnamed `init_1` through
-- -- `init_m` values from the argument table are assigned to the
-- -- corresponding keys in `new_object`.
-- local Process = Object {
--   _type = "Process",
--   _init = { "status", "out", "err" },
-- }
-- local process = Process {
--   procs[pid].status, procs[pid].out, procs[pid].err, -- auto assigned
--   command = pipeline[pid],                           -- manual assignment
-- }
-- @usage
-- -- Or it can be a function, in which the arguments passed to the
-- -- prototype during cloning are simply handed to the `_init` function.
-- local Bag = Object {
--   _type = "Bag",
--   _init = function (obj, ...)
--     for e in std.elems {...} do
--       obj[#obj + 1] = e
--     end
--     return obj
--   end,
-- }
-- local bag = Bag ("function", "arguments", "sent", "to", "_init")

return Container {
  _type  = "Object",

  -- No need for explicit module functions here, because calls to, e.g.
  -- `Object.prototype` will automatically fall back metamethods in
  -- `__index`.

  __index = {
    --- Clone an Object.
    --
    -- Objects are essentially tables of `field_n = value_n` pairs.
    --
    -- Normally `new_object` automatically shares a metatable with
    -- `proto_object`. However, field names beginning with "_" are *private*,
    -- and moved into the object metatable during cloning. So, adding new
    -- private fields to an object during cloning will result in a new
    -- metatable for `new_object` that also happens to contain a copy of all
    -- the entries from the `proto_object` metatable.
    --
    -- While clones of @{Object} inherit all properties of their prototype,
    -- it's idiomatic to always keep separate tables for the module table and
    -- the root object itself: That way you can't mistakenly engage the slower
    -- clone-from-module-table process unnecessarily.
    -- @static
    -- @function clone
    -- @tparam Object obj an object
    -- @param ... a list of arguments if *obj.\_init* is a function, or a
    --   single table if *obj.\_init* is a table.
    -- @treturn Object a clone of *obj*
    -- @see __call
    -- @usage
    -- local object = require "std.object"  -- module table
    -- local Object = object {}             -- root object
    -- local o = Object {
    --   field_1 = "value_1",
    --   method_1 = function (self) return self.field_1 end,
    -- }
    -- print (o.field_1)                    --> value_1
    -- o.field_2 = 2
    -- function o:method_2 (n) return self.field_2 + n end
    -- print (o:method_2 (2))               --> 4
    -- os.exit (0)
    clone = getmetamethod (container, "__call"),

    --- Type of an object, or primitive.
    --
    -- It's conventional to organise similar objects according to a
    -- string valued *\_type* field, which can then be queried using this
    -- function.
    --
    -- Additionally, this function returns the results of @{io.type} for
    -- file objects, or @{type} otherwise.
    --
    -- @static
    -- @function prototype
    -- @param x anything
    -- @treturn string type of *x*
    -- @usage
    -- local Stack = Object {
    --   _type = "Stack",
    --
    --   __tostring = function (self) ... end,
    --
    --   __index = {
    --     push = function (self) ... end,
    --     pop  = function (self) ... end,
    --   },
    -- }
    -- local stack = Stack {}
    -- assert (stack:prototype () == getmetatable (stack)._type)
    --
    -- local prototype = Object.prototype
    -- assert (prototype (stack) == getmetatable (stack)._type)
    --
    -- local h = io.open (os.tmpname (), "w")
    -- assert (prototype (h) == io.type (h))
    --
    -- assert (prototype {} == type {})
    prototype = prototype,


    --- Return *obj* with references to the fields of *src* merged in.
    --
    -- More importantly, split the fields in *src* between *obj* and its
    -- metatable. If any field names begin with "_", attach a metatable
    -- to *obj* by cloning the metatable from *src*, and then copy the
    -- "private" `_` prefixed fields there.
    --
    -- You might want to use this function to instantiate your derived
    -- object clones when the *src.\_init* is a function -- when
    -- *src.\_init* is a table, the default (inherited unless you overwrite
    -- it) clone method calls @{mapfields} automatically.  When you're
    -- using a function `_init` setting, @{clone} doesn't know what to
    -- copy into a new object from the `_init` function's arguments...
    -- so you're on your own.  Except that calling @{mapfields} inside
    -- `_init` is safer than manually splitting `src` into `obj` and
    -- its metatable, because you'll pick up any fixes and changes when
    -- you upgrade stdlib.
    -- @static
    -- @function mapfields
    -- @tparam table obj destination object
    -- @tparam table src fields to copy int clone
    -- @tparam[opt={}] table map key renames as `{old_key=new_key, ...}`
    -- @treturn table *obj* with non-private fields from *src* merged,
    --   and a metatable with private fields (if any) merged, both sets
    --   of keys renamed according to *map*
    -- @usage
    -- myobject.mapfields = function (obj, src, map)
    --   object.mapfields (obj, src, map)
    --   ...
    -- end
    mapfields = container.mapfields.call,


    -- Backwards compatibility:
    type = prototype,
  },


  --- Return a @{clone} of this object, and its metatable.
  --
  -- Private fields are stored in the metatable.
  -- @function __call
  -- @param ... arguments for prototype's *\_init*
  -- @treturn Object a clone of the this object.
  -- @see clone
  -- @usage
  -- local Object = require "std.object" {} -- not a typo!
  -- new = Object {"initialisation", "elements"}


  --- Return an in-order iterator over public object fields.
  -- @function __pairs
  -- @treturn function iterator function
  -- @treturn Object *self*
  -- @usage
  -- for k, v in std.pairs (anobject) do process (k, v) end


  --- Return a string representation of this object.
  --
  -- First the object type, and then between { and } a list of the
  -- array part of the object table (without numeric keys) followed
  -- by the remaining key-value pairs.
  --
  -- This function doesn't recurse explicity, but relies upon suitable
  -- `__tostring` metamethods in field values.
  -- @function __tostring
  -- @treturn string stringified object representation
  -- @see tostring
  -- @usage print (anobject)
}
