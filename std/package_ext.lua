-- Additions to the package module.

local M = {}

--- Make named constants for <code>package.config</code> (undocumented
-- in 5.1; see luaconf.h for C equivalents).
-- @class table
-- @name package
-- @field dirsep directory separator
-- @field pathsep path separator
-- @field path_mark string that marks substitution points in a path template
-- @field execdir (Windows only) replaced by the executable's directory in a path
-- @field igmark Mark to ignore all before it when building <code>luaopen_</code> function name.
M.dirsep, M.pathsep, M.path_mark, M.execdir, M.igmark =
  string.match (package.config, "^([^\n]+)\n([^\n]+)\n([^\n]+)\n([^\n]+)\n([^\n]+)")

for k, v in pairs (package) do
  M[k] = M[k] or v
end

return M
