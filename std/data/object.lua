-- Prototype-based objects

require "std/data/table.lua"


-- Usage:

-- Create an object/class:
--   object/newClass = class {value,...; field = value...}
--   The constructor function is _clone; the list of fields to be
--   intialised by the constructor is _init. Assuming the default
--   _clone, the values before the ; are assigned to the fields given
--   in _init.
-- Access an object field: object.field
-- Call an object method: object:method (...)
-- (Private fields and methods should start with "_")
-- Add a field: object.field = x
-- Add a method: function object:method (...) ... end
-- Call a class method: class.method (self, ...)

-- Root object
Object = {_init = {}}
settag (Object, newtag ())
copytagmethods (tag (Object), _TableTag)

-- Object constructor
--   values: initial values for fields in _init
-- returns
--   o: new object
function Object:_clone (values)
  return self + permute (self._init, values)
end

-- Sugar instance creation
settagmethod (tag (Object), "function",
              function (...)
                return call (arg[1]._clone, arg)
              end)
