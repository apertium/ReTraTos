VERSION=0.8.0

SUBDIRS = ReTraTos

bin_SCRIPTS = ReTraTos_lex ReTraTos_rgl

# here we should probably do some path processing

ReTraTos_lex:	
	cp ReTraTos_lex.pl ReTraTos_lex

ReTraTos_rgl:
	cp ReTraTos.pl ReTraTos_rgl

pkgconfigdir = $(libdir)/pkgconfig

EXTRA_DIST = m4/perlmodules.m4 m4/definedir.m4 \
	ReTraTos_lex.pl \
	ReTraTos.pl
