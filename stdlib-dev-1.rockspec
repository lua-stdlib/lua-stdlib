local _MODREV, _SPECREV = 'dev', '-1'

package = 'stdlib'
version = _MODREV .. _SPECREV

rockspec_format = '3.0'

description = {
   summary = 'General Lua Libraries',
   detailed = [[
      stdlib is a library of modules for common programming tasks,
      including list and table operations, and pretty-printing.
   ]],
   homepage = 'https://lua-stdlib.github.io/lua-stdlib',
   issues_url = 'https://github.com/lua-stdlib/lua-stdlib/issues',
   license = 'MIT/X11',
}

source = {
   url = 'https://github.com/lua-stdlib/lua-stdlib/archive/v' .. _MODREV .. '.zip',
   dir = 'lua-stdlib-' .. _MODREV,
}

dependencies = {
   'lua >= 5.1, < 5.6',
   'optparse >= 2',
   'std._debug >= 1',
   'std.functional >= 2',
   'std.normalize >= 4',
   'std.prototype >= 2',
}

build_dependencies = {
   'luarocks-build-luke >= 0.3.1',
}

build = {
   type = 'luke',

   modules = {
      {['std']              = 'lib/std/init.lua'},
      {['std._base']        = 'lib/std/_base.lua'},
      {['std._container']   = 'lib/std/_container.lua'},
      {['std._deprecation'] = 'lib/std/_deprecation.lua'},
      {['std.container']    = 'lib/std/container.lua'},
      {['std.debug']        = 'lib/std/debug.lua'},
      {['std.debug_init']   = 'lib/std/debug_init.lua'},
      {['std.functional']   = 'lib/std/functional.lua'},
      {['std.io']           = 'lib/std/io.lua'},
      {['std.list']         = 'lib/std/list.lua'},
      {['std.math']         = 'lib/std/math.lua'},
      {['std.object']       = 'lib/std/object.lua'},
      {['std.operator']     = 'lib/std/operator.lua'},
      {['std.optparse']     = 'lib/std/optparse.lua'},
      {['std.package']      = 'lib/std/package.lua'},
      {['std.set']          = 'lib/std/set.lua'},
      {['std.strbuf']       = 'lib/std/strbuf.lua'},
      {['std.string']       = 'lib/std/string.lua'},
      {['std.table']        = 'lib/std/table.lua'},
      {['std.tree']         = 'lib/std/tree.lua'},
      {['std.version']      = 'lib/std/version.lua.in'},
   },
}

test_dependencies = {
   'ansicolors',
   'luacov',
   'specl >= 17',
}

test = {
   type = 'command',
   command = 'specl -vfreport --coverage spec/*_spec.yaml',
}

if _MODREV == 'dev' then
   -- luarocks.org's ldoc fails on Lua 5.5; gvvaughan's works.
   build_dependencies[#build_dependencies + 1] = 'gvvaughan/ldoc'

   -- Stamp a development build with who made it, and from which commit.
   build.version = '$USER/$gitref'

   source = {
      url = 'git+https://github.com/lua-stdlib/lua-stdlib.git',
   }
end
