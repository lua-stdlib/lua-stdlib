--[[--
 Lua Standard Libraries.

 This module contains a selection of improved Lua core functions, among
 others.

 Also, after requiring this module, simply referencing symbols in the
 submodule hierarchy will load the necessary modules on demand.

 By default there are no changes to any global symbols, or monkey
 patching of core module tables and metatables.  However, sometimes it's
 still convenient to do that: For example, when using stdlib from the
 REPL, or in a prototype where you want to throw caution to the wind and
 compatibility with other modules be damned. In that case, you can give
 `stdlib` permission to scribble all over your namespaces by using the
 various `monkey_patch` calls in the library.

 @todo Write a style guide (indenting/wrapping, capitalisation,
   function and variable names); library functions should call
   error, not die; OO vs non-OO (a thorny problem).
 @todo pre-compile.
 @module std
]]


local base = require "std.base"

local M, monkeys


local function monkey_patch (namespace)
  base.copy (namespace or _G, monkeys)
  return M
end


local function barrel (namespace)
  namespace = namespace or _G

  -- Older releases installed the following into _G by default.
  for _, name in pairs {
    "functional.bind", "functional.collect", "functional.compose",
    "functional.curry", "functional.filter", "functional.id",
    "functional.map",

    "io.die", "io.warn",

    "string.pickle", "string.prettytostring", "string.render",

    "table.pack",

    "tree.ileaves", "tree.inodes", "tree.leaves", "tree.nodes",
  } do
    local module, method = name:match "^(.*)%.(.-)$"
    namespace[method] = M[module][method]
  end

  -- Support old api names, for backwards compatibility.
  namespace.fold = M.functional.fold
  namespace.metamethod = M.getmetamethod
  namespace.op = M.operator
  namespace.require_version = M.require

  require "std.io".monkey_patch (namespace)
  require "std.math".monkey_patch (namespace)
  require "std.string".monkey_patch (namespace)
  require "std.table".monkey_patch (namespace)

  return monkey_patch (namespace)
end



--- Module table.
--
-- In addition to the functions documented on this page, and a `version`
-- field, references to other submodule functions will be loaded on
-- demand.
-- @table std
-- @field version release version string

local function X (decl, fn)
  return require "std.debug".argscheck ("std." .. decl, fn)
end

M = {
  --- Enhance core `assert` to also allow formatted arguments.
  -- @function assert
  -- @param expect expression, expected to be *truthy*
  -- @string[opt=""] f format string
  -- @param[opt] ... arguments to format
  -- @return value of *expect*, if *truthy*
  -- @usage
  -- std.assert (expected ~= nil, "100% unexpected!")
  -- std.assert (expected ~= nil, "%s unexpected!", expected)
  assert = X ("assert (?any, ?string, [any...])", base.assert),

  --- A [barrel of monkey_patches](http://dictionary.reference.com/browse/barrel+of+monkeys).
  --
  -- Apply **all** `monkey_patch` functions.  Additionally, for backwards
  -- compatibility only, write a selection of sub-module functions into
  -- the given namespace.
  -- @function barrel
  -- @tparam[opt=_G] table namespace where to install global functions
  -- @treturn table module table
  -- @usage local std = require "std".barrel ()
  barrel = X ("barrel (?table)", barrel),

  --- An iterator over all elements of a sequence.
  -- If *t* has a `__pairs` metamethod, use that to iterate.
  -- @function elems
  -- @tparam table t a table
  -- @treturn function iterator function
  -- @treturn table *t*, the table being iterated over
  -- @return *key*, the previous iteration key
  -- @see ielems
  -- @see pairs
  -- @usage
  -- for value in std.elems {a = 1, b = 2, c = 5} do process (value) end
  elems = X ("elems (table)", base.elems),

  --- Evaluate a string as Lua code.
  -- @function eval
  -- @string s string of Lua code
  -- @return result of evaluating `s`
  -- @usage std.eval "math.min (2, 10)"
  eval = X ("eval (string)", base.eval),

  --- An iterator over the integer keyed elements of a sequence.
  -- If *t* has a `__len` metamethod, iterate up to the index it returns.
  -- @function ielems
  -- @tparam table t a table
  -- @treturn function iterator function
  -- @treturn table *t*, the table being iterated over
  -- @treturn int *index*, the previous iteration index
  -- @see elems
  -- @see ipairs
  -- @usage
  -- for v in std.ielems {"a", "b", "c"} do process (v) end
  ielems = X ("ielems (table)", base.ielems),

  --- An iterator over elements of a sequence, until the first `nil` value.
  --
  -- Like Lua 5.1 and 5.3, but unlike Lua 5.2 (which looks for and uses the
  -- `__ipairs` metamethod), this iterator returns successive key-value
  -- pairs with integer keys starting at 1, up to the first `nil` valued
  -- pair.
  -- @function ipairs
  -- @tparam table t a table
  -- @treturn function iterator function
  -- @treturn table *t*, the table being iterated over
  -- @treturn int *index*, the previous iteration index
  -- @see ielems
  -- @see npairs
  -- @see pairs
  -- @usage
  -- -- length of sequence
  -- args = {"first", "second", nil, "last"}
  -- --> 1=first
  -- --> 2=second
  -- for i, v in std.ipairs (args) do
  --   print (string.format ("%d=%s", i, v))
  -- end
  ipairs = X ("ipairs (table)", base.ipairs),

  --- Return a new table with element order reversed.
  -- Apart from the order of the elments returned, this function follows
  -- the same rules as @{ipairs} for determining first and last elements.
  -- @function ireverse
  -- @tparam table t a table
  -- @treturn table a new table with integer keyed elements in reverse
  --   order with respect to *t*
  -- @see ielems
  -- @see ipairs
  -- @usage
  -- local rielems = std.functional.compose (std.ireverse, std.ielems)
  -- for e in rielems (l) do process (e) end
  ireverse = X ("ireverse (table)", base.ireverse),

  --- Return named metamethod, if any, otherwise `nil`.
  -- @function getmetamethod
  -- @param x item to act on
  -- @string n name of metamethod to lookup
  -- @treturn function|nil metamethod function, or `nil` if no metamethod
  -- @usage lookup = std.getmetamethod (require "std.object", "__index")
  getmetamethod = X ("getmetamethod (?any, string)", base.getmetamethod),

  --- Overwrite core methods and metamethods with `std` enhanced versions.
  --
  -- Write all functions from this module, except `std.barrel` and
  -- `std.monkey_patch`, into the given namespace.
  -- @function monkey_patch
  -- @tparam[opt=_G] table namespace where to install global functions
  -- @treturn table the module table
  -- @usage local std = require "std".monkey_patch ()
  monkey_patch = X ("monkey_patch (?table)", monkey_patch),

  --- Ordered iterator for integer keyed values.
  -- Like ipairs, but does not stop until the largest integer key.
  -- @function npairs
  -- @tparam table t a table
  -- @treturn function iterator function
  -- @treturn table t
  -- @see ipairs
  -- @see rnpairs
  -- @usage
  -- for i,v in npairs {"one", nil, "three"} do ... end
  npairs = X ("npairs (table)", base.npairs),

  --- Enhance core `pairs` to respect `__pairs` even in Lua 5.1.
  -- @function pairs
  -- @tparam table t a table
  -- @treturn function iterator function
  -- @treturn table *t*, the table being iterated over
  -- @return *key*, the previous iteration key
  -- @see elems
  -- @see ipairs
  -- @usage
  -- for k, v in pairs {"a", b = "c", foo = 42} do process (k, v) end
  pairs = X ("pairs (table)", base.pairs),

  --- Enhance core `require` to assert version number compatibility.
  -- By default match against the last substring of (dot-delimited)
  -- digits in the module version string.
  -- @function require
  -- @string module module to require
  -- @string[opt] min lowest acceptable version
  -- @string[opt] too_big lowest version that is too big
  -- @string[opt] pattern to match version in `module.version` or
  --  `module._VERSION` (default: `"([%.%d]+)%D*$"`)
  -- @usage
  -- -- posix.version == "posix library for Lua 5.2 / 32"
  -- posix = require ("posix", "29")
  require = X ("require (string, ?string, ?string, ?string)", base.require),

  --- An iterator like ipairs, but in reverse.
  -- Apart from the order of the elments returned, this function follows
  -- the same rules as @{ipairs} for determining first and last elements.
  -- @function ripairs
  -- @tparam table t any table
  -- @treturn function iterator function
  -- @treturn table *t*
  -- @treturn number `#t + 1`
  -- @see ipairs
  -- @see rnpairs
  -- @usage for i, v = ripairs (t) do ... end
  ripairs = X ("ripairs (table)", base.ripairs),

  --- An iterator like npairs, but in reverse.
  -- Apart from the order of the elments returned, this function follows
  -- the same rules as @{npairs} for determining first and last elements.
  -- @function rnpairs
  -- @tparam table t a table
  -- @treturn function iterator function
  -- @treturn table t
  -- @see npairs
  -- @see ripairs
  -- @usage
  -- for i,v in rnpairs {"one", nil, "three"} do ... end
  rnpairs = X ("rnpairs (table)", base.rnpairs),

  --- Enhance core `tostring` to render table contents as a string.
  -- @function tostring
  -- @param x object to convert to string
  -- @treturn string compact string rendering of *x*
  -- @usage
  -- -- {1=baz,foo=bar}
  -- print (std.tostring {foo="bar","baz"})
  tostring = X ("tostring (?any)", base.tostring),

  version = "General Lua libraries / 41.1.1",
}


monkeys = base.copy ({}, M)

-- Don't monkey_patch these apis into _G!
for _, api in ipairs {"barrel", "monkey_patch", "version"} do
  monkeys[api] = nil
end


--- Metamethods
-- @section Metamethods

return setmetatable (M, {
  --- Lazy loading of stdlib modules.
  -- Don't load everything on initial startup, wait until first attempt
  -- to access a submodule, and then load it on demand.
  -- @function __index
  -- @string name submodule name
  -- @treturn table|nil the submodule that was loaded to satisfy the missing
  --   `name`, otherwise `nil` if nothing was found
  -- @usage
  -- local std = require "std"
  -- local prototype = std.object.prototype
  __index = function (self, name)
              local ok, t = pcall (require, "std." .. name)
              if ok then
		rawset (self, name, t)
		return t
	      end
	    end,
})
