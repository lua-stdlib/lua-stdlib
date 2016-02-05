Standard Lua libraries
======================

by the [stdlib project][github]

[![License](http://img.shields.io/:license-mit-blue.svg)](http://mit-license.org)
[![travis-ci status](https://secure.travis-ci.org/lua-stdlib/lua-stdlib.png?branch=master)](http://travis-ci.org/lua-stdlib/lua-stdlib/builds)
[![Stories in Ready](https://badge.waffle.io/lua-stdlib/lua-stdlib.png?label=ready&title=Ready)](https://waffle.io/lua-stdlib/lua-stdlib)


This is a collection of Lua libraries for Lua 5.1 (including LuaJIT), 5.2
and 5.3. The libraries are copyright by their authors 2000-2016 (see the
[AUTHORS][] file for details), and released under the [MIT license][mit]
(the same license as Lua itself). There is no warranty.

_stdlib_ has no run-time prerequisites beyond a standard Lua system,
though it will take advantage of [strict][] and [typecheck][] if they
are installed.

[authors]: http://github.com/lua-stdlib/lua-stdlib/blob/master/AUTHORS.md
[github]: http://github.com/lua-stdlib/lua-stdlib/ "Github repository"
[lua]: http://www.lua.org "The Lua Project"
[mit]: http://mit-license.org "MIT License"
[strict]: https://github.com/lua-stdlib/strict "strict variables"
[typecheck]: https://github.com/gvvaughan/typecheck "function type checks"


Installation
------------

The simplest and best way to install stdlib is with [LuaRocks][]. To
install the latest release (recommended):

```bash
    luarocks install stdlib
```

To install current git master (for testing, before submitting a bug
report for example):

```bash
    luarocks install http://raw.githubusercontent.com/lua-stdlib/lua-stdlib/master/stdlib-git-1.rockspec
```

The best way to install without [LuaRocks][] is to copy the `std`
folder and its contents into a directory on your package search path.

[luarocks]: http://www.luarocks.org "Lua package manager"


Documentation
-------------

The latest release of these libraries is [documented in LDoc][github.io].
Pre-built HTML files are included in the release.

[github.io]: http://lua-stdlib.github.io/lua-stdlib


Bug reports and code contributions
----------------------------------

These libraries are written and maintained by their users.

Please make bug reports and suggestions as [GitHub Issues][issues].
Pull requests are especially appreciated.

But first, please check that your issue has not already been reported by
someone else, and that it is not already fixed by [master][github] in
preparation for the next release (see Installation section above for how
to temporarily install master with [LuaRocks][]).

There is no strict coding style, but please bear in mind the following
points when proposing changes:

0. Follow existing code. There are a lot of useful patterns and avoided
   traps there.

1. 2-character indentation using SPACES in Lua sources.

[issues]: http://github.com/lua-stdlib/lua-stdlib/issues
