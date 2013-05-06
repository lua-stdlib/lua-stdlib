dnl Process this file with autoconf to produce a configure script

dnl Initialise autoconf and automake
AC_INIT([lua-stdlib], [35], [http://github.com/rrthomas/lua-stdlib/issues])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])

AS_BOX([Configuring AC_PACKAGE_TARNAME AC_PACKAGE_VERSION])
echo

AM_INIT_AUTOMAKE([-Wall foreign])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

dnl Check for programs
AX_PROG_LUA([5.1], [5.3])
AC_PATH_PROG([LUADOC], [luadoc], [:])
AC_PATH_PROG([SPECL], [specl], [:])
AC_PROG_EGREP
AC_PROG_SED

dnl Generate output files
SPECL_MIN=5
SS_CONFIG_TRAVIS([luadoc specl])
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
