Standard Lua libraries
======================

by the [stdlib project](http://github.com/rrthomas/lua-stdlib/)

[![travis-ci status](https://secure.travis-ci.org/rrthomas/lua-stdlib.png?branch=master)](http://travis-ci.org/rrthomas/lua-stdlib/builds)


This is a collection of Lua libraries for Lua 5.1 and 5.2. The
libraries are copyright by their authors 2000-2013 (see the AUTHORS
file for details), and released under the MIT license (the same
license as Lua itself). There is no warranty.

The standard subset of stdlib has no prerequisites beyond a standard
Lua system. The following modules have extra dependencies:

    fstable: Lua 5.2, lfs, luaposix


Installation
------------

The simplest way to install stdlib is with LuaRocks
(http://www.luarocks.org/ ):

    luarocks install stdlib

To install from a release tarball using luarocks (replacing ?? with
the release number you want to build):

    wget https://github.com/rrthomas/lua-stdlib/archive/release-v??.tar.gz
    tar zxf release-v??.tar.gz
    cd lua-stdlib-release-v??
    ./configure
    make rockspecs
    luarocks make stdlib-??-1.rockspec

If you need access to features not in a luarocks release yet:

    git clone git@github.com:rrthomas/lua-stdlib.git
    cd lua-stdlib
    ./configure
    make rockspecs
    luarocks make stdlib-git-1.rockspec

You can also install stdlib without luarocks, but you must first check
that you have all the dependencies installed, because configure assumes
they are already available. The latest dependencies are listed in the
dependencies entry of the file stdlib-rockspec.lua.  You will also need
a working recent autoconf and automake installation for autoreconf to
generate configure and Makeflie.in correctly:

    git clone git@github.com:rrthomas/lua-stdlib.git
    cd lua-stdlib
    autoreconf --force --version --install
    ./configure --prefix=INSTALLATION-ROOT-DIRECTORY
    make all check install

Note that the configured installation method installs directly to the
specified --prefix tree, even if you have luarocks installed too.

Use
---

As well as requiring individual libraries, you can load the standard
set with

    require "std"

Modules not in the standard set may be removed from future versions of
stdlib.


Documentation
-------------

The libraries are documented in LuaDoc. Pre-built HTML files are
included.


Bug reports and code contributions
----------------------------------

These libraries are maintained and extended by their users. Please
make bug report and suggestions on GitHub (see URL at top of file).
Pull requests are especially appreciated.
