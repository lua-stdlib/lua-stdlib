dnl Process this file with autoconf to produce a configure script

dnl Initialise autoconf and automake
AC_INIT(stdlib, 28, rrt@sc3d.org)
AC_CONFIG_AUX_DIR([build-aux])
AM_INIT_AUTOMAKE([foreign no-dist-gzip dist-zip])
AM_SILENT_RULES([yes])

dnl Lua
AC_SUBST([LUA_MIN_VERSION], [5.1])
AX_PROG_LUA([$LUA_MIN_VERSION], [5.3])

dnl md5sum
AX_WITH_PROG([MD5SUM], [md5sum], [false])

dnl Generate output files
AC_CONFIG_MACRO_DIR(m4)
AC_CONFIG_FILES(Makefile $PACKAGE.rockspec luarocks-config.lua src/std.lua)
AC_OUTPUT
