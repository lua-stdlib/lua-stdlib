--[[--
 String buffer prototype.

 Buffers are mutable by default, but being based on objects, they can
 also be used in a functional style:

    local StrBuf = require "std.strbuf".prototype
    local a = StrBuf {"a"}
    local b = a:concat "b"    -- mutate *a*
    print (a, b)              --> ab   ab
    local c = a {} .. "c"     -- copy and append
    print (a, c)              --> ab   abc

 In addition to the functionality described here, StrBuf objects also
 have all the methods and metamethods of the @{std.object.prototype}
 (except where overridden here),

 Prototype Chain
 ---------------

      table
       `-> Container
            `-> Object
                 `-> StrBuf

 @prototype std.strbuf
]]


local tostring		= tostring
local type		= type

local table_concat	= table.concat


local _ = {
  debug			= require "std.debug",
  object		= require "std.object",
  setenvtable		= require "std.strict".setenvtable,
  std			= require "std.base",
}

local Module		= _.std.object.Module
local Object		= _.object.prototype

local argscheck		= _.debug.argscheck
local ielems		= _.std.ielems
local insert		= _.std.table.insert
local merge		= _.std.base.merge


local deprecated	= require "std.delete-after.2016-01-31"

local _, _ENV		= nil, _.setenvtable {}



--[[ =============== ]]--
--[[ Implementation. ]]--
--[[ =============== ]]--


local function __concat (self, x)
  return insert (self, x)
end


local function __tostring (self)
  local strs = {}
  for e in ielems (self) do strs[#strs + 1] = tostring (e) end
  return table_concat (strs)
end


--[[ ================= ]]--
--[[ Public Interface. ]]--
--[[ ================= ]]--


local function X (decl, fn)
  return argscheck ("std.strbuf." .. decl, fn)
end

local methods = {
  --- Methods
  -- @section methods

  --- Add a object to a buffer.
  -- Elements are stringified lazily, so if you add a table and then
  -- change its contents, the contents of the buffer will be affected
  -- too.
  -- @function prototype:concat
  -- @param x object to add to buffer
  -- @treturn prototype modified buffer
  -- @usage
  -- c = StrBuf {} :concat "append this" :concat (StrBuf {" and", " this"})
  concat = X ("concat (StrBuf, any)", __concat),
}

if deprecated then
  methods = merge (methods, deprecated.strbuf)
end



--[[ ================== ]]--
--[[ Type Declarations. ]]--
--[[ ================== ]]--


--- StrBuf prototype object.
-- @object prototype
-- @string[opt="StrBuf"] _type object name
-- @see std.object.prototype
-- @usage
-- local StrBuf = require "std.strbuf".prototype
-- local a = StrBuf {1, 2, 3}
-- local b = StrBuf {a, "five", "six"}
-- a = a .. 4
-- b = b:concat "seven"
-- print (a, b) --> 1234   1234fivesixseven
-- os.exit (0)

local M = {
  prototype = Object {
    _type = "std.strbuf.StrBuf",

    --- Metamethods
    -- @section metamethods

    __index = methods,

    --- Support concatenation to StrBuf objects.
    -- @function prototype:__concat
    -- @param x a string, or object that can be coerced to a string
    -- @treturn prototype modified *buf*
    -- @see concat
    -- @usage
    -- buf = buf .. x
    __concat = __concat,

    --- Support fast conversion to Lua string.
    -- @function prototype:__tostring
    -- @treturn string concatenation of buffer contents
    -- @see tostring
    -- @usage
    -- str = tostring (buf)
    __tostring = __tostring,
  },
}

if deprecated then
  M = merge (M, deprecated.strbuf)
end


return Module (M)
