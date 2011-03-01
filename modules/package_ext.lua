-- Package

module ("package", package.seeall)


-- Reflect package.config (undocumented in 5.1; see luaconf.h for C
-- equivalents)
dirsep, pathsep, path_mark, execdir, igmark =
  string.match (package.config, "^([^\n]+)\n([^\n]+)\n([^\n]+)\n([^\n]+)\n([^\n]+)")
