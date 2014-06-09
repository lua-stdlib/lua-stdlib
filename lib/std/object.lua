--[[--
 Prototype-based objects.

 This module creates the root prototype object from which every other
 object is descended.  There are no classes as such, rather new objects
 are created by cloning an existing object, and then changing or adding
 to the clone. Further objects can then be made by cloning the changed
 object, and so on.

 Objects are cloned by simply calling an existing object, which then
 serves as a prototype from which the new object is copied.

 All valid objects contain a field `_init`, which determines the syntax
 required to execute the cloning process:

   1. `_init` can be a list of keys; then the unnamed `init_1` through
      `init_m` values from the argument table are assigned to the
      corresponding keys in `new_object`;

         new_object = proto_object {
           init_1, ..., init_m;
           field_1 = value_1,
           ...
           field_n = value_n,
         }

   2. Or it can be a function, in which the arguments passed to the
      prototype during cloning are simply handed to the `_init` function:

        new_object = proto_object (arg, ...)

 Objects, then, are essentially tables of `field\_n = value\_n` pairs:

      > object = require "std.object"  -- module table
      > Object = object {}             -- root object
      > o = Object {
      >>  field_1 = "value_1",
      >>  method_1 = function (self) return self.field_1 end,
      >> }
      > = o.field_1
      value_1
      > o.field_2 = 2
      > function o:method_2 (n) return self.field_2 + n end
      > = o:method_2 (2)
      4

 Normally `new_object` automatically shares a metatable with
 `proto_object`. However, field names beginning with "_" are *private*,
 and moved into the object metatable during cloning. So, adding new
 private fields to an object during cloning will result in a new
 metatable for `new_object` that also contains a copy of all the entries
 in the `proto_object` metatable.

 While clones of @{std.object} inherit all properties of their prototype,
 it's idiomatic to always keep separate tables for the module table and
 the root object itself: That way you can't mistakenly engage the slower
 clone-from-module-table process accidentally if the underlying object
 later changes from being an `Object` to being a `Container`.

     local object = require "std.object"  -- module table
     local Object = object {}             -- root object

     local prototype = object.prototype

     local Derived = Object { _type = "Derived" }

 Note that Object methods are stored in the `__index` field of their
 metatable, and so cannot also use `__index` to lookup references with
 square brackets.  See @{std.container} objects if you want to do that.

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
-- @table std.object
-- @string[opt="Object"] _type type of Object, returned by @{prototype}
-- @tfield table|function _init a table of field names, or
--   initialisation function, used by @{clone}
-- @tfield nil|table _functions a table of module functions not copied
--   by @{std.object.__call}
return Container {
  _type  = "Object",

  -- No need for explicit module functions here, because calls to, e.g.
  -- `Object.prototype` will automatically fall back metamethods in
  -- `__index`.

  __index = {
    --- Clone an Object.
    -- @static
    -- @function clone
    -- @tparam std.object obj an object
    -- @param ... a list of arguments if `obj._init` is a function, or a
    --   single table if `obj._init` is a table.
    -- @treturn std.object a clone of *obj*
    -- @see __call
    -- @usage
    -- local object = require "std.object"
    -- new = object.clone (object, {"foo", "bar"})
    clone = getmetamethod (container, "__call"),


    --- Type of an object, or primitive.
    --
    -- It's conventional to organise similar objects according to a
    -- string valued `_type` field, which can then be queried using this
    -- function.
    --
    -- Additionally, this function returns the results of `io.type` for
    -- file objects, or `type` otherwise.
    --
    -- @static
    -- @function prototype
    -- @param x anything
    -- @treturn string type of *x*
    -- @see std.object:prototype
    -- @usage
    --   local Stack = Object {
    --     _type = "Stack",
    --
    --     __tostring = function (self) ... end,
    --
    --     __index = {
    --       push = function (self) ... end,
    --       pop  = function (self) ... end,
    --     },
    --   }
    --   local stack = Stack {}
    --   assert (stack:prototype () == getmetatable (stack)._type)
    --
    --   local prototype = Object.prototype
    --   assert (prototype (stack) == getmetatable (stack)._type)
    --
    --   local h = io.open (os.tmpname (), "w")
    --   assert (prototype (h) == io.type (h))
    --
    --   assert (prototype {} == type {})

    --- Type of this object.
    --
    -- Additionally, this function returns the results of `io.type` for
    -- file objects, or `type` otherwise.
    -- @function prototype
    -- @treturn string type of this object
    -- @see std.object.prototype
    -- @usage if anobject:prototype () ~= "table" then ... end
    prototype = prototype,


    --- Return `obj` with references to the fields of `src` merged in.
    --
    -- More importantly, split the fields in `src` between `obj` and its
    -- metatable. If any field names begin with `\_`, attach a metatable
    -- to `obj` if it doesn't have one yet, and copy the "private" `\_`
    -- prefixed fields there.
    --
    -- You might want to use this function to instantiate your derived
    -- objct clones when the prototype's `_init` is a function -- when
    -- `_init` is a table, the default (inherited unless you overwrite
    -- it) clone method calls `mapfields` automatically.  When you're
    -- using a function `_init` setting, `clone` doesn't know what to
    -- copy into a new object from the `_init` function's arguments...
    -- so you're on your own.  Except that calling `mapfields` inside
    -- `_init` is safer than manually splitting `src` into `obj` and
    -- its metatable, because you'll pick up fixes and changes when you
    -- upgrade stdlib.
    -- @static
    -- @function mapfields
    -- @tparam table obj destination object
    -- @tparam table src fields to copy int clone
    -- @tparam[opt={}] table map `{old_key=new_key, ...}`
    -- @treturn table `obj` with non-private fields from `src` merged,
    --   and a metatable with private fields (if any) merged, both sets
    --   of keys renamed according to `map`
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
  -- @param ... arguments for `\_init`
  -- @treturn std.object a clone of the this object.
  -- @see clone
  -- @usage
  -- local Object = require "std.object" {} -- not a typo!
  -- new = Object {"initialisation", "elements"}


  --- Return a string representation of this object.
  --
  -- First the object type, and then between { and } a list of the
  -- array part of the object table (without numeric keys) followed
  -- by the remaining key-value pairs.
  --
  -- This function doesn't recurse explicity, but relies upon suitable
  -- `__tostring` metamethods in field values.
  -- @function __tostring
  -- @treturn string stringified container representation
  -- @see tostring
  -- @usage print (anobject)


  --- Return a shallow copy of non-private object fields.
  --
  -- Used by @{clone} to get the base contents of the new object. Can
  -- be overridden in other objects for greater control of which fields
  -- are considered non-private.
  -- @function __totable
  -- @treturn table a shallow copy of non-private object fields
  -- @see std.table.totable
  -- @usage
  -- tostring = require "std.string".tostring
  -- print (totable (anobject))
}
