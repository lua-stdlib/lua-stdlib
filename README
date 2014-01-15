Standard Lua libraries
======================

by the [stdlib project][github]

[github]: http://github.com/rrthomas/lua-stdlib/ "Github repository"

[![travis-ci status](https://secure.travis-ci.org/rrthomas/lua-stdlib.png?branch=master)](http://travis-ci.org/rrthomas/lua-stdlib/builds)


This is a collection of Lua libraries for Lua 5.1 and 5.2. The
libraries are copyright by their authors 2000-2013 (see the AUTHORS
file for details), and released under the MIT license (the same
license as Lua itself). There is no warranty.

Stdlib has no prerequisites beyond a standard Lua system.


Installation
------------

The simplest way to install stdlib is with [LuaRocks][]. To install the
latest release (recommended):

    luarocks install stdlib

To install current git master (for testing):

    luarocks install https://raw.github.com/rrthomas/lua-stdlib/release/stdlib-git-1.rockspec

To install without LuaRocks, check out the sources from the
[repository][github], and then run the following commands: the
dependencies are listed in the dependencies entry of the file
`stdlib-rockspec.lua`. You will also need autoconf and automake.

    cd lua-stdlib
    autoreconf --force --version --install
    ./configure --prefix=INSTALLATION-ROOT-DIRECTORY
    make all check install

See [INSTALL][] for instructions for `configure`.

[luarocks]: http://www.luarocks.org "LuaRocks Project"
[install]: https://raw.github.com/rrthomas/lua-stdlib/master/INSTALL

Use
---

As well as requiring individual libraries, you can load the standard
set with

    require "std"

Modules not in the standard set may be removed from future versions of
stdlib.


Documentation
-------------

The libraries are [documented in LDoc][github.io]. Pre-built HTML
files are included.

[github.io]: http://rrthomas.github.io/lua-stdlib


Bug reports and code contributions
----------------------------------

These libraries are written and maintained by their users. Please make
bug report and suggestions on GitHub (see URL at top of file). Pull
requests are especially appreciated.
