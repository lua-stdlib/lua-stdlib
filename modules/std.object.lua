-- Prototype-based objects

require "std.table"


-- Usage:

-- Create an object/class:
--   object/class = parent {value, ...; field = value ...}
--   An object's metatable is itself.
--   In the initialiser, unnamed values are assigned to the fields
--   given by _init (assuming the default _clone).
--   Private fields and methods start with "_"
-- Access an object field: object.field
-- Call an object method: object:method (...)
-- Add a field: object.field = x
-- Add a method: function object:method (...) ... end
-- Call a class method: class.method (self, ...)

-- Root object
Object = {
  -- List of fields to be initialised by the
  -- constructor: assuming the default _clone, the
  -- numbered values in an object constructor are
  -- assigned to the fields given in _init
  _init = {},
  
  -- @func _clone: Object constructor
  --   @param values: initial values for fields in
  --   _init
  -- returns
  --   @param object: new object
  _clone =
    function (self, values)
      local object =
        table.merge (self, table.permute (self._init, values))
      return setmetatable (object, object)
    end,
  
  -- Sugar instance creation
  __call = function (...)
             return arg[1]._clone (unpack (arg))
           end,
}

setmetatable (Object, Object)
