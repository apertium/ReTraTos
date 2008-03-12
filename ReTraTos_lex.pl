#!/usr/bin/perl

######################################################################################################
# Programa indutor de lexico bilingue
# Entrada: 
# - dois arquivos (um fonte e outro alvo): com os exemplos no seguinte formato:
#    <s snum=1156>Balões/Balão<n><m><pl>:1 analisam/analisar<vblex><pri><3><pl>:2 atmosfera/atmosfera<n><f><sg>:4 
#    tropical/tropical<adj><mf><sg>:5 </s>
#    <s snum=1156>Globos/Globo<n><m><pl>:1 analizan/analizar<vblex><pri><3><pl>:2 la/el<det><def><f><sg>:0 
#    atmósfera/atmósfera<n><f><sg>:3 tropical/tropical<adj><mf><sg>:4 </s>
# - um arquivo com o cabecalho do lexico bilingue (o que vem antes das entradas) de acordo com o formato do Apertium
# - um arquivo com o rodape do lexico bilingue (o que vem depois das entradas) de acordo com o formato do Apertium
# - um arquivo com os possiveis valores para os atributos de genero e numero (genero em uma linha, numero
# em outra, separados por espaco e sendo o ultimo valor o mais geral
######################################################################################################

use warnings;
use strict;
no warnings qw(redefine);
use locale;

use lib "$ENV{PWD}/ReTraTos/";

use Getopt::Long;
use Pod::Usage;
use IO::Handle;
# Modulos do ReTraTos
use ReTraTos::Entrada;
use ReTraTos::Lexico;
use ReTraTos::Auxiliares;

#*****************************************************************************************************
my(@exemplosfonte,@exemplosalvo); # array com exemplos fonte e alvo
my(%lexicobilingue); # lexico bilingue
my(@atrs); # array de arrays com valores de atributos
#*****************************************************************************************************
my($arqfonte,$arqalvo,$arqcab,$arqrod,$arqatrs,$freq,$help);

$freq = 1;

	GetOptions( 'sourcefile|s=s' => \$arqfonte,
				'targetfile|t=s' => \$arqalvo,
				'beginning|b=s' => \$arqcab,
				'ending|e=s' => \$arqrod,
				'attrsfile|a=s'   => \$arqatrs,
				'multifreq|f=n'  => \$freq,
				'help|?'	 => \$help,) 
		  || pod2usage(2);

	pod2usage(2) if $help;
	pod2usage(2) unless $arqfonte && $arqalvo && $arqcab && $arqrod;

	Auxiliares::verifica_arquivo($arqfonte);
	Auxiliares::verifica_arquivo($arqalvo);
	Auxiliares::verifica_arquivo($arqcab);
	Auxiliares::verifica_arquivo($arqrod);

	# Le arquivo de atributos se o mesmo foi passado como parametro
	if (defined($arqatrs)) {
		open(ARQ,$arqatrs) or Auxiliares::erro_abertura_arquivo($arqatrs);
		while ($_ = <ARQ>) {
			$_ =~ s/\n//;
			push(@atrs,[split(/ /)]);
		}
		close ARQ;
	}

	my($arq) = Auxiliares::nome($0).'_'.Auxiliares::nome($arqfonte).'X'.Auxiliares::nome($arqalvo).'_'.$freq.'.dix';
	
	@exemplosfonte = @exemplosalvo = %lexicobilingue = @atrs = ();
	
	Auxiliares::mensagem("\nPREPROCESSING\n\n");
	
	# Le exemplos de entrada
	Entrada::le_exemplos($arqfonte,\@exemplosfonte);
	Entrada::le_exemplos($arqalvo,\@exemplosalvo);

	
	# Gera lexico bilingue
	Auxiliares::mensagem("\nGENERATING DICTIONARY\n\n");	
	Lexico::gera_lexico_bilingue($freq,\@exemplosfonte,\@exemplosalvo,\@atrs,\%lexicobilingue);	
	
	# Imprime lexico bilingue
	Auxiliares::mensagem("\nPRINTING DICTIONARY\n\n");
	Lexico::imprime_lexico_bilingue($arq,$arqcab,$arqrod,\%lexicobilingue);	
	Auxiliares::mensagem("\n\n");	

__END__

=head1 NAME

ReTraTos_lex - Bilingual dictionary inductor from aligned parallel texts

=head1 SYNOPSIS

 ReTraTos_lex [options...] 

 Options:
-sourcefile|s  file with examples in source language (required)
-targetfile|t  file with examples in target language (required)
-beginning|b   file with the beginning of a bilingual dictionary (required)
-ending|e      file with the ending of a bilingual dictionary (required)
-attrsfile|a   file with information about attributes (optional)
-multifreq|f   frequency threshold to filter multiword units (default=1)
-help|?        this guide

 Usage Example:

 perl ReTraTos_lex.pl -s pt.txt -t en.txt -b cab.txt -e rod.txt -f 50

 Helena de Medeiros Caseli jan/2006

=cut
