dnl Process this file with autoconf to produce a configure script

dnl Initialise autoconf and automake
AC_INIT(stdlib, 29, rrt@sc3d.org)
AC_CONFIG_AUX_DIR([build-aux])
AM_INIT_AUTOMAKE([foreign])
AM_SILENT_RULES([yes])

dnl Lua
AC_SUBST([LUA_MIN_VERSION], [5.1])
AX_PROG_LUA([$LUA_MIN_VERSION], [5.3])

dnl Generate output files
AC_CONFIG_MACRO_DIR(m4)
AC_CONFIG_FILES(Makefile $PACKAGE.rockspec luarocks-config.lua)
AC_OUTPUT
