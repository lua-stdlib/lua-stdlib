--[[--
 Provide at least one year of support for deprecated APIs, or at
 least one release cycle if that is longer.

 When `_DEBUG.deprecate` is `true` we don`t even load this support, in
 which case `require`ing this module returns `false`.

 Otherwise, return a table of all functions deprecated in the given
 `RELEASE` and earlier, going back at least one year.  The table is
 keyed on the original module to enable merging deprecated APIs back
 into their previous namespaces - this is handled automatically by the
 documented modules according to the contents of `_DEBUG`.

 In some release after the date of this module, it will be removed and
 these APIs will not be available any longer.
]]


local RELEASE	= "upcoming"


local M		= false

if not require "std.debug_init"._DEBUG.deprecate then

  local getmetatable	= getmetatable
  local pairs		= pairs
  local type		= type

  local io_stderr	= io.stderr
  local io_type		= io.type

  local _, deprecated	= {
    -- Adding anything else here will probably cause a require loop.
    maturity		= require "std.maturity",
    std			= require "std.base",
    strict		= require "std.strict",
  }

  -- Merge in deprecated APIs from previous release if still available.
  _.ok, deprecated = pcall (require, "std.delete-after.2016-03-08")
  if not _.ok then deprecated = {} end


  local _pairs		= _.std.pairs
  local DEPRECATED	= _.maturity.DEPRECATED
  local DEPRECATIONMSG	= _.maturity.DEPRECATIONMSG
  local len		= _.std.operator.len
  local sortkeys	= _.std.base.sortkeys

  -- Only the above symbols are used below this line.
  local _, _ENV		= nil, _.strict {}

 
  --[[ ========== ]]--
  --[[ Death Row! ]]--
  --[[ ========== ]]--

  local function okeys (t)
    local r = {}
    for k in _pairs (t) do r[#r + 1] = k end
    return sortkeys (r)
  end


  local function _type (x)
    return (getmetatable (x) or {})._type or io_type (x) or type (x)
  end


  -- Ensure deprecated APIs observe _DEBUG warning standards.
  local function X (old, new, fn)
    return DEPRECATED (RELEASE, "'std." .. old .. "'", "use '" .. new .. "' instead", fn)
  end

  local function acyclic_merge (dest, src)
    for k, v in pairs (src) do
      if type (v) == "table" then
        dest[k] = dest[k] or {}
        if type (dest[k]) == "table" then acyclic_merge (dest[k], v) end
      else
        dest[k] = dest[k] or v
      end
    end
    return dest
  end

  M = acyclic_merge ({
    object = {
      type = function (x)
        local r = (getmetatable (x) or {})._type
	if r == nil then
	  io_stderr:write (DEPRECATIONMSG (RELEASE,
            "non-object argument to 'std.object.type'",
            [[check for 'type (x) == "table"' before calling 'std.object.type (x)' instead]],
	    2))
	 end
	 return r or io_type (x) or type (x)
      end,
    },

    table = {
      len = X ("table.len", "std.operator.len", len),
      okeys = DEPRECATED (RELEASE, "'std.table.okeys'", "compose 'std.table.keys' and 'std.table.sort' instead", okeys),
    },

    methods = {
      object = {
        prototype = DEPRECATED (RELEASE, "'std.object.prototype'", "use 'std.functional.any (std.object.type, io.type, type)' instead", _type),
        type = DEPRECATED (RELEASE, "'std.object.type'", "use 'std.functional.any (std.object.type, io.type, type)' instead", _type),
      },
    },
  },
  deprecated)

end

return M
