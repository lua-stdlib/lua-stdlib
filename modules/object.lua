-- Prototype-based objects

module ("object", package.seeall)

require "table_ext"


-- Usage:

-- Create an object/class:
--   object/class = parent {value, ...; field = value ...}
--   An object's metatable is itself.
--   In the initialiser, unnamed values are assigned to the fields
--   given by _init (assuming the default _clone).
--   Private fields and methods start with "_"

-- Access an object field: object.field
-- Call an object method: object:method (...)
-- Call a class method: class.method (self, ...)

-- Add a field: object.field = x
-- Add a method: function object:method (...) ... end


-- Root object
_G.Object = {
  -- List of fields to be initialised by the
  -- constructor: assuming the default _clone, the
  -- numbered values in an object constructor are
  -- assigned to the fields given in _init
  _init = {},
}
setmetatable (Object, Object)
  
-- @func Object:_clone: Object constructor
--   @param values: initial values for fields in
--   _init
-- @returns
--   @param object: new object
function Object:_clone (values)
  local object = table.merge (self, table.permute (self._init, values))
  return setmetatable (object, object)
end
  
-- @func Object:__call: Sugar instance creation
function Object.__call (...)
  -- First (...) gets first element of list
  return (...)._clone (...)
end
