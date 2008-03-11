retratos_perldir = @PERLPATH@/ReTraTos
retratos_perl_DATA = Auxiliares.pm Blocos.pm Entrada.pm Filtra.pm \
        Gera.pm Identifica.pm Lexico.pm Ordena.pm Prefix.pm

Prefix.pm: Prefix.pm.in Makefile
	sed \
        -e 's|@retratosdir[@]|$(retratos_perldir)|g' \
        -e 's|@datadir[@]|$(datadir)|g' \
        -e 's|@prefix[@]|$(prefix)|g' \
        Prefix.pm.in > $@

EXTRA_DIST = Auxiliares.pm Blocos.pm Entrada.pm Filtra.pm \
        Gera.pm Identifica.pm Lexico.pm Ordena.pm Prefix.pm.in

CLEANFILES = Prefix.pm
