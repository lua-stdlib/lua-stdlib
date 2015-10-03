Standard Lua libraries
======================

by the [stdlib project][github]

[![License](http://img.shields.io/:license-mit-blue.svg)](http://mit-license.org)
[![travis-ci status](https://secure.travis-ci.org/lua-stdlib/lua-stdlib.png?branch=master)](http://travis-ci.org/lua-stdlib/lua-stdlib/builds)
[![Stories in Ready](https://badge.waffle.io/lua-stdlib/lua-stdlib.png?label=ready&title=Ready)](https://waffle.io/lua-stdlib/lua-stdlib)


This is a collection of Lua libraries for LuaJIT, Lua 5.1, 5.2 and 5.3.
The libraries are copyright by their authors 2000-2015 (see the
[AUTHORS][] file for details), and released under the [MIT license][mit]
(the same license as Lua itself). There is no warranty.

Stdlib has no run-time prerequisites beyond a standard Lua system.

[authors]: http://github.com/lua-stdlib/lua-stdlib/blob/master/AUTHORS
[github]: http://github.com/lua-stdlib/lua-stdlib/ "Github repository"
[lua]: http://www.lua.org "The Lua Project"
[mit]: http://mit-license.org "MIT License"


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

The best way to install without [LuaRocks][] is to download a github
[release tarball][releases] and follow the instructions in the included
[INSTALL][] file.  Even if you are repackaging or redistributing
[stdlib][github], this is by far the most straight forward place to
begin.

Note that you'll be responsible for providing dependencies if you choose
not to let [LuaRocks][] handle them for you, though you can find a list
of minimal dependencies in the [rockspec.conf][] file.

It is also possible to perform a complete bootstrap of the
[master][github] development branch, although this branch is unstable,
and sometimes breaks subtly, or does not build at all, or provides
experimental new APIs that end up being removed prior to the next
official release. Unfortunately, we don't have time to provide support
for taking this most difficult and dangerous option. It is presumed
that you already know enough to be aware of what you are getting yourself
into - however, there are full logs of complete bootstrap builds in
[Travis][] after every commit, that you can examine if you get stuck.
Also, the bootstrap script tries very hard to tell you why it is unhappy
and, sometimes, even how to fix things before trying again.

[install]: http://raw.githubusercontent.com/lua-stdlib/lua-stdlib/release/INSTALL
[luarocks]: http://www.luarocks.org "Lua package manager"
[releases]: http://github.com/lua-stdlib/lua-stdlib/releases
[rockspec.conf]: http://github.com/lua-stdlib/lua-stdlib/blob/release/rockspec.conf
[travis]: http://travis-ci.org/lua-stdlib/lua-stdlib/builds


Use
---

As well as requiring individual libraries, you can load the standard
set with

```lua
    local std = require "std"
```

Modules not in the standard set may be removed from future versions of
stdlib.


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
