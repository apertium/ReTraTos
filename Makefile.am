VERSION=0.8.0

bin_SCRIPTS = ReTraTos_lex ReTraTos

# here we should probably do some path processing

ReTraTos_lex:	
	cp ReTraTos_lex.pl ReTraTos_lex

ReTraTos:
	cp ReTraTos.pl ReTraTos

pkgconfigdir = $(libdir)/pkgconfig

retratos_perldir = @PERLPATH@/ReTraTos
retratos_perl_DATA = Auxiliares.pm Blocos.pm Entrada.pm Filtra.pm \
	Gera.pm Identifica.pm Lexico.pm Ordena.pm

EXTRA_DIST = README ReTraTos_lex.pl ReTraTos.pl $(retratos_perl_DATA)
