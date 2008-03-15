AC_PREREQ([2.56])

AC_INIT([retratos], [0.8.0], [helename@sourceforge.net])
AM_INIT_AUTOMAKE([retratos], [0.8.0], no-define)

AM_MAINTAINER_MODE

AC_CHECK_PROG(PERL, perl, perl, none)

AC_DEFINE_DIR(DATADIR, datadir)
       
perlpath=`$PERL -e 'foreach (@INC) { print "$_\n";}' | grep "^$DATADIR" | sort -r | head -1`
if test -z "$perlpath" ; then
	perlpath=`$PERL -e 'foreach (@INC) { print "$_\n";}' | grep "^$prefix" | sort -r | head -1`
fi

if test "$PERL" = "none" ; then
        AC_MSG_ERROR([Perl not found])
fi

if test -z "$perlpath" ; then
        perlpath="$DATADIR/perl5/"
	AC_MSG_NOTICE([Perl libraries will be installed in $perlpath, make sure to include it in your path])
else
        AC_MSG_NOTICE([Perl libraries will be installed in $perlpath])
fi

AC_DEFINE_DIR(PERLPATH, perlpath)

#use Getopt::Long;
#use Pod::Usage;
#use IO::Handle;

AC_PROG_PERL_MODULES(Getopt::Long Pod::Usage IO::Handle, , AC_MSG_WARN(Need some Perl modules))


AC_PATH_PROG(PKG_CONFIG, pkg-config, no)
if test x$ac_cv_path_PKG_CONFIG = x
then
  AC_MSG_ERROR([You don't have pkg-config installed.])
fi
if test x$ac_cv_path_PKG_CONFIG = xno
then
  AC_MSG_ERROR([You don't have pkg-config installed.])
fi

PKG_CHECK_MODULES(LTTOOLBOX, lttoolbox-3.0 >= 3.0.0, LTTOOLBOX="yes", AC_MSG_ERROR([*** unable to locate lttoolbox! Run: apt-get install liblttoolbox3-3.0-0-dev lttoolbox ***]))
PKG_CHECK_MODULES(APERTIUM, apertium-3.0 >= 3.0.0, APERTIUM="yes", AC_MSG_ERROR([*** unable to locate apertium! Run: apt-get install libapertium3-3.0-0-dev apertium ***]))

AC_OUTPUT([
Makefile
ReTraTos/Makefile
])
