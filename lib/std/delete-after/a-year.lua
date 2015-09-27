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

  local pairs		= pairs
  local type		= type

  local _, deprecated	= {
    -- Adding anything else here will probably cause a require loop.
    maturity		= require "std.maturity",
    setenvtable		= require "std.strict".setenvtable,
    std			= require "std.base",
  }

  -- Merge in deprecated APIs from previous release if still available.
  _.ok, deprecated = pcall (require, "std.delete-after.2016-03-08")
  if not _.ok then deprecated = {} end


  local _pairs		= _.std.pairs
  local _type		= _.std.type
  local DEPRECATED	= _.maturity.DEPRECATED
  local len		= _.std.operator.len
  local sortkeys	= _.std.base.sortkeys

  -- Only the above symbols are used below this line.
  local _, _ENV		= nil, _.setenvtable {}

 
  --[[ ========== ]]--
  --[[ Death Row! ]]--
  --[[ ========== ]]--

  local function okeys (t)
    local r = {}
    for k in _pairs (t) do r[#r + 1] = k end
    return sortkeys (r)
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
      prototype = X ("object.prototype", "std.type", _type),
      type = X ("object.type", "std.type", _type),
    },

    table = {
      len = X ("table.len", "std.operator.len", len),
      okeys = DEPRECATED (RELEASE, "'std.table.okeys'", "compose 'std.table.keys' and 'std.table.sort' instead", okeys),
    },
  },
  deprecated)

end

return M
