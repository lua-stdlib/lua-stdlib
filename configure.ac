dnl Process this file with autoconf to produce a configure script

dnl Initialise autoconf and automake
AC_INIT([stdlib], [35], [http://github.com/rrthomas/lua-stdlib/issues])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])

AS_BOX([Configuring AC_PACKAGE_TARNAME AC_PACKAGE_VERSION])
echo

AM_INIT_AUTOMAKE([-Wall foreign])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

dnl Check for programs
AX_PROG_LUA([5.1], [5.3])
AC_PATH_PROG([SPECL], [specl], [false])
AC_PATH_PROG([LUADOC], [luadoc], [:])
AC_PROG_EGREP
AC_PROG_SED

dnl Generate output files
SPECL_MIN=5
SS_CONFIG_TRAVIS([luadoc])
# ensure we only run luadoc with lua5.1 - it isn't 5.2 compatible yet.
lua51_only='[s|^exec "[^"]*"|exec lua5.1|]'
EXTRA_ROCKS="$EXTRA_ROCKS perl -i -pe '$lua51_only' \`which luadoc\`"

AC_CONFIG_FILES([Makefile])
AC_OUTPUT
