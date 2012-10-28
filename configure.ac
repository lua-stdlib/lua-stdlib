dnl Process this file with autoconf to produce a configure script

dnl Initialise autoconf and automake
AC_INIT(stdlib, 28, rrt@sc3d.org)
AC_CONFIG_AUX_DIR([build-aux])
AM_INIT_AUTOMAKE([foreign no-dist-gzip dist-zip])
AM_SILENT_RULES([yes])

dnl Lua 5.1 or 5.2
AX_PROG_LUA(501, 503)
AC_SUBST(LUA)

dnl md5sum
AX_WITH_PROG([MD5SUM], [md5sum], [false])

dnl Generate output files
AC_CONFIG_MACRO_DIR(m4)
AC_CONFIG_FILES(Makefile $PACKAGE.rockspec src/std.lua)
AC_OUTPUT
