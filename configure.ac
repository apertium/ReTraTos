AC_PREREQ([2.56])

AC_INIT([retratos], [0.8.0], [helename@sourceforge.net])
AM_INIT_AUTOMAKE([retratos], [0.8.0], no-define)

AM_MAINTAINER_MODE

AC_PATH_PROG(PERL, perl, no)
if test x$ac_cv_path_PERL = x
then
  AC_MSG_ERROR([You don't have perl installed.])
fi
if test x$ac_cv_path_PERL = xno
then
  AC_MSG_ERROR([You don't have perl installed.])
fi

#use Getopt::Long;
#use Pod::Usage;
#use IO::Handle;

AC_CHECK_PERL_MODULES(Getopt::Long Pod::Usage IO::Handle, ,
                          AC_MSG_WARN(Need some Perl modules)

AC_PATH_PROG(PKG_CONFIG, pkg-config, no)
if test x$ac_cv_path_PKG_CONFIG = x
then
  AC_MSG_ERROR([You don't have pkg-config installed.])
fi
if test x$ac_cv_path_PKG_CONFIG = xno
then
  AC_MSG_ERROR([You don't have pkg-config installed.])
fi

PKG_CHECK_MODULES(APERTIUM, apertium-3.0 >= 3.0.0, APERTIUM="yes", AC_MSG_ERROR([*** unable to locate apertium! Run: apt-get install libapertium3-3.0-0-dev apertium ***]))

AC_OUTPUT([
Makefile
])

