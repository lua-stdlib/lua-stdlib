dnl configure.ac
dnl
dnl Copyright (c) 2012-2014 Free Software Foundation, Inc.
dnl Written by Gary V. Vaughan, 2012
dnl
dnl This program is free software; you can redistribute it and/or modify
dnl it under the terms of the GNU General Public License as published
dnl by the Free Software Foundation; either version 3, or (at your
dnl option) any later version.
dnl
dnl This program is distributed in the hope that it will be useful, but
dnl WITHOUT ANY WARRANTY; without even the implied warranty of
dnl MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
dnl General Public License for more details.
dnl
dnl You should have received a copy of the GNU General Public License
dnl along with this program.  If not, see <http://www.gnu.org/licenses/>.


dnl Initialise autoconf and automake
AC_INIT([stdlib], [37], [http://github.com/rrthomas/lua-stdlib/issues])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])

AS_BOX([Configuring AC_PACKAGE_TARNAME AC_PACKAGE_VERSION])
echo

AM_INIT_AUTOMAKE([-Wall])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

dnl Check for programs
AX_PROG_LUA([5.1], [5.3])
AC_PATH_PROG([LDOC], [ldoc], [:])
AC_PATH_PROG([SPECL], [specl], [:])
AC_PROG_EGREP
AC_PROG_SED

dnl Generate output files
SS_CONFIG_TRAVIS([ldoc specl])
AC_CONFIG_FILES([Makefile build-aux/config.ld specs/spec_helper.lua])
AC_OUTPUT
