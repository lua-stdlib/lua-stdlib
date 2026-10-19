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
   'std._debug',
   'std.functional',
   'std.normalize >= 2.0',
}

build = {
   type = 'command',
   build_command = '$(LUA) build-aux/luke'
      .. ' package="' .. package .. '"'
      .. ' version="' .. _MODREV .. '"'
      .. ' PREFIX="$(PREFIX)"'
      .. ' LUA="$(LUA)"'
      ,
   install_command = '$(LUA) build-aux/luke install --quiet'
      .. ' INST_LUADIR="$(LUADIR)"'
      ,
}

test_dependencies = {
   'ansicolors',
   'luacov',
   'specl >= 15',
}

test = {
   type = 'command',
   command = 'specl -vfreport --coverage spec/*_spec.yaml',
}

if _MODREV == 'dev' then
   source = {
      url = 'git+https://github.com/lua-stdlib/lua-stdlib.git',
   }
end
