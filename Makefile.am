VERSION=0.8.0

SUBDIRS = ReTraTos

bin_SCRIPTS = ReTraTos_lex ReTraTos_rules

# here we should probably do some path processing

ReTraTos_lex:	
	cp ReTraTos_lex.pl ReTraTos_lex

ReTraTos_rules:
	cp ReTraTos.pl ReTraTos_rules

pkgconfigdir = $(libdir)/pkgconfig

man_MANS=ReTraTos_rules.1 ReTraTos_lex.1

EXTRA_DIST = m4/perlmodules.m4 m4/definedir.m4 \
	ReTraTos_lex.pl \
	ReTraTos.pl $(man_MANS)
