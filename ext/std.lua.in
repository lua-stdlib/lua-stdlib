--- Lua standard library
-- <ul>
-- <li>TODO: Write a style guide (indenting/wrapping, capitalisation,
--   function and variable names); library functions should call
--   error, not die; OO vs non-OO (a thorny problem).</li>
-- <li>TODO: Add tests for each function immediately after the function;
--   this also helps to check module dependencies.</li>
-- <li>TODO: pre-compile.</li>
-- </ul>
local version = "General Lua libraries / @VERSION@"

for m, globally in pairs (require "std.modules") do
  if globally == true then
    -- Inject stdlib extensions directly into global package namespaces.
    for k, v in pairs (require ("std." .. m)) do
      _G[m][k] = v
    end
  else
    _G[m] = require ("std." .. m)
  end
end

-- Add io functions to the file handle metatable.
local file_metatable = getmetatable (io.stdin)
file_metatable.readlines  = io.readlines
file_metatable.writelines = io.writelines

-- Maintain old global interface access points.
for _, api in ipairs {
  "functional.bind",
  "functional.collect",
  "functional.compose",
  "functional.curry",
  "functional.eval",
  "functional.filter",
  "functional.fold",
  "functional.id",
  "functional.map",
  "functional.memoize",
  "functional.metamethod",
  "functional.op",

  "io.die",
  "io.warn",

  "string.assert",
  "string.pickle",
  "string.prettytostring",
  "string.render",
  "string.require_version",
  "string.tostring",

  "table.pack",
  "table.ripairs",
  "table.totable",

  "tree.ileaves",
  "tree.inodes",
  "tree.leaves",
  "tree.nodes",
} do
  local module, method = api:match "^(.*)%.(.-)$"
  _G[method] = _G[module][method]
end

local M = {
  version = version,
}

return M
