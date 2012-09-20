dnl Process this file with autoconf to produce a configure script

AC_INIT(stdlib, 27, rrt@sc3d.org)
AC_CONFIG_AUX_DIR([build-aux])

AM_INIT_AUTOMAKE([foreign no-dist-gzip dist-zip])

m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

dnl Lua 5.1 or 5.2
AX_PROG_LUA(501, 503)
AC_SUBST(LUA)

dnl md5sum
AX_WITH_PROG([MD5SUM], [md5sum], [false])

dnl Generate output files
AC_CONFIG_MACRO_DIR(m4)
AC_CONFIG_FILES(Makefile $PACKAGE.rockspec src/std.lua)
AC_OUTPUT
