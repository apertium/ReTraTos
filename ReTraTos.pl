#!/usr/bin/perl

# 31/08/2006

######################################################################################################
# Programa indutor de regras de transferencia
# Entrada: 
# - dois arquivos (um fonte e outro alvo): com os exemplos no seguinte formato:
# <s snum=1156>Balões/Balão<n><m><pl>:1 analisam/analisar<vblex><pri><3><pl>:2 atmosfera/atmosfera<n><f><sg>:4 
# tropical/tropical<adj><mf><sg>:5 </s>
# <s snum=1156>Globos/Globo<n><m><pl>:1 analizan/analizar<vblex><pri><3><pl>:2 la/el<det><def><f><sg>:0 
# atmósfera/atmósfera<n><f><sg>:3 tropical/tropical<adj><mf><sg>:4 </s>
######################################################################################################

use warnings;
use strict;
use locale;

use Getopt::Long;
use Pod::Usage;
use IO::Handle;
# Modulos do ReTraTos
use Entrada;
use Auxiliares;
use Blocos;
use Identifica;
use Gera;
use Filtra;
use Ordena;

#*****************************************************************************************************
my(@exemplosfonte,@exemplosalvo); # array com exemplos fonte e alvo
my(%blocosfonte,%blocosalvo); # blocos de exemplos fonte e alvo
my(%regras); # regras de traducao
my(%padroesbil); # padroes bilingues
my($n) = 0; # numero de blocos a partir dos quais as regras sao geradas
#*****************************************************************************************************
my($arqfonte,$arqalvo,$help,$verbose,$remove);

my $tipo = 3;        # tipo de bloco de alinhamento para o qual as regras serao geradas (tipo=3, todos)
my $campo = 'pos';   # nivel de abstracao para o qual as regras serao geradas
my $icategs = '';    # categorias gramaticais para as quais se deseja induzir regras de traducao
my $ecategs = '';    # categorias gramaticais para as quais NAO se deseja induzir regras de traducao
my $poride = 0.0015; # porcentagem da frequencia para se considerar uma sequencia um padrao
my $filtra = 0;      # opcao 	exit 1;de filtrar as regras de traducao ambiguas (0=nao,1=sim)
my $porfil = 0.5;	 # porcentagem da frequencia da melhor opcao para que outra seja filtrada
my $ordena = 0;      # opcao de ordenar as regras de traducao (0=nao,1=sim)

	GetOptions( 'sourcefile|s=s' => \$arqfonte,
					'targetfile|t=s' => \$arqalvo,
					'type|ty=s' => \$tipo,
					'level|l=s' => \$campo,
					'include_pos|ig=s' => \$icategs,
					'exclude_pos|eg=s' => \$ecategs,
					'per_ident|pi=f' => \$poride,
					'filter|fi' => \$filtra,
					'per_filter|pf=f' => \$porfil,
					'sort|so' => \$ordena,
					'remove|r' => \$remove,
					'verbose|v' => \$verbose,
					'help|h|?' => \$help,) 
		  || pod2usage(2);

	pod2usage(2) if $help;
	pod2usage(2) unless $arqfonte && $arqalvo;

	print "\nHora inicial: ",Auxiliares::imprime_hora,"\n";	
	
	my($ngram,$janela,$dir,$arq);

	$ngram = 1;	
	$janela = 3; #19/12: numero de posicoes antes e depois da omissao no bloco de tipo 0
	my $tammin = 2; # 02/08: tamanho minimo de um padrao
	my $tammax = 5; # 02/08: tamanho maximo de um padrao
	$dir = Auxiliares::nome($0).'_'.Auxiliares::nome($arqfonte).'X'.Auxiliares::nome($arqalvo);
	$dir .= '_pi='.$poride.'_pf='.$porfil.'_'.$campo.'_'.$tipo;
	if ($icategs ne "") { $dir .= '_+'.$icategs; }
	if ($ecategs ne "") { $dir .= '_-'.$ecategs; }
	mkdir($dir);
	
	@exemplosfonte = @exemplosalvo = %blocosfonte = %blocosalvo = ();

	print "\nPRE-PROCESSAMENTO\n\n";
	
	Entrada::le_exemplos($arqfonte,\@exemplosfonte);
	Entrada::le_exemplos($arqalvo,\@exemplosalvo);

	print "\tCriando blocos de alinhamentos ... ";
	map(Blocos::cria_blocos($janela,$tammin,$_,\@{$exemplosfonte[$_]{'ali'}},\@{$exemplosalvo[$_]{'ali'}},\%blocosfonte,\%blocosalvo),0..$#exemplosfonte);
	print "OK\n";
	
	print "\n\nINDUCAO DAS REGRAS\n\n";
	
	%padroesbil = %regras = ();

	if ($tipo == 3) { print "\tInduzindo regras para campo $campo e todos os tipos ...\n"; }
	else { print "\tInduzindo regras para campo $campo e tipo $tipo ...\n"; }
	
	# PASSO 1 - inicio
	print "\nPasso 1 - Identificacao de padroes\n";
		
	if ($tipo == 3) {
		identifica_padroes(0);
		identifica_padroes(1);
		identifica_padroes(2);
	}
	else { identifica_padroes($tipo); }
	# PASSO 1 - fim

	# PASSO 2 - inicio
	print "\nPasso 2 - Geracao das regras\n";
	Gera::regras($campo,$tipo,\@exemplosfonte,\@exemplosalvo,\%padroesbil,\%regras);

	%padroesbil = (); # libera memória
	# PASSO 2 - fim
	
	# PASSO 3 - inicio	
	if ($filtra) {
		print "\nPasso 3 - Filtragem das regras\n";
		Filtra::regras(\%regras,\@exemplosfonte,$porfil);
	}
	# PASSO 3 - fim

	# PASSO 4 - inicio		
	if ($ordena) {
		print "\nPasso 4 - Ordenacao das regras\n";
 		Ordena::regras(\%regras);		
 	}
	# PASSO 4 - fim

	print "\n\nIMPRESSAO DAS REGRAS\n\n";
	$arq = $dir.'/regras_finais_'.$campo.'.txt';
	print "\t",imprime_regras($arq,\%regras,$n)," regras impressas em $arq\n\n";
	
	%regras = @exemplosfonte = @exemplosalvo = ();

	print "Hora final: ",Auxiliares::imprime_hora,"\n\n";	
	
	exit;

# -----------------------------------------------------------------------------------------------------

# Sub-rotina identifica_padroes
# Entrada: $t       (tipo de bloco de alinhamento para o qual se deseja induzir os padroes)
# Funcao: Induz os padroes mono e bilingues, do tipo $t, imprimindo-os em arquivos auxiliares
sub identifica_padroes {
	my($t) = @_;
	my(%padroesfonte,$qtd,$freq,$arqblo,$arqpadfon,$arqpadbil,$qtdblocos); #%padroesalvo

	# Pre-processamento: impressao dos blocos, calculo da frequencia minima - INICIO	
	$arqblo = $dir.'/blocos_fonte_'.$campo.'_+'.$icategs.'_'.$t.'.txt';

	Blocos::imprime_blocos(\@exemplosfonte,\@{$blocosfonte{$t}},$icategs,$campo,$t,$arqblo);
	$qtdblocos = $#{$blocosfonte{$t}}+1;
	$freq = int($poride*$qtdblocos);
	# Pre-processamento: impressao dos blocos - FIM

	$arqpadfon = $dir.'/padroes_fonte_'.$campo.'_+'.$icategs.'_-'.$ecategs.'_'.$t.'_'.$freq.'.txt';
	$arqpadbil = $dir.'/padroes_bilingues_'.$campo.'_+'.$icategs.'_-'.$ecategs.'_'.$t.'_'.$freq.'.txt';

	print "\tIdentificando padroes para campo $campo";
	if ($icategs ne '') { print " (+ $icategs)";  }
	if ($ecategs ne '') { print " (- $ecategs)"; }
	print " e tipo $t a partir de $qtdblocos blocos com frequencia minima $freq ...\n";

	%padroesfonte = ();

	if (open(ARQ,$arqpadbil)) { close ARQ; } # Se arquivo com padroes bilingues ja existe nao faz nada
	else { 
		# Passo 1: identificacao de padroes monolingues (fonte)
		if (open(ARQ,$arqpadfon)) { close ARQ; } # Se arquivo com padroes fonte ja existe nao faz nada
		else { 
			Identifica::padroes_monolingues($arqblo,$icategs,$ecategs,$freq,$tammin,$tammax,$arqpadfon); 
		}

		# Le padroes monolingues
		print "\t",Identifica::le_padroes_mono($arqpadfon,\@{$blocosfonte{$t}},\@exemplosfonte,$icategs,$campo,$ngram,\%padroesfonte);
		print " padroes monolingues identificados\n";

		# Passo 2: identificacao de padroes bilingues
		Identifica::padroes_bilingues($campo,$t,$icategs,$freq,\%padroesfonte,\@exemplosfonte,\@exemplosalvo,$arqpadbil); 
	
		%padroesfonte = (); # libera memoria
	}
	
	# Le os padroes bilingues
	print "\t",Identifica::le_padroes_bili($arqpadbil,\%padroesbil);
	print " padroes bilingues identificados\n";

	$n += $qtdblocos;
	# Passo 2: identificacao de padroes bilingues - FIM
}

#*****************************************************************************************************
#                                           SAIDA
#*****************************************************************************************************
# Sub-rotina imprime_regras
# Entrada: $arq    (arquivo no qual as regras serao impressas)
#          $regras (hash com as regras)
#          $n      (numero de exemplos usados para a inducao das regras)
# Saida: Quantidade de regras impressas no arquivo $arq
# Funcao: Imprime as regras em $regras no arquivo $arq
sub imprime_regras {
	my($arq,$regras,$n) = @_;
	my($idf,$ida,@fontes,@al,$peso,$freq,@rfonte,@ralvo,@rbili,$partefonte,$partealvo,$idres);
	my($i,$str,@todosal,@aux);
	
	# Ordena as regras por ordem crescente alfabetica antes da impressao
	@fontes = sort {lc($a) cmp lc($b)} keys %$regras;
	# Ordena as regras por ordem decrescente das frequencias antes da impressao
	#@fontes = sort {int($$regras{$b}[$#{$$regras{$b}}]) <=> int($$regras{$a}[$#{$$regras{$a}}])} keys %$regras;
	open(ARQ,">$arq") or die "Nao eh possivel abrir o arquivo $arq\n";
	print ARQ "$n\n\n";
	for($idf = 0;$idf <= $#fontes; $idf++) { # cada partefonte
		$partefonte = $fontes[$idf];
		$str = pop(@{$$regras{$partefonte}}); # frequencia da regra
		print ARQ "R",$idf+1,"/",pop(@{$$regras{$partefonte}}),"/",$str,"\n"; # id, peso, freq
		for($ida = 0;$ida <= $#{$$regras{$partefonte}};$ida++) { # para cada opcao alvo
			$partealvo = ${$$regras{$partefonte}[$ida]}[0];
			($peso,$freq) = split('/',${$$regras{$partefonte}[$ida]}[$#{$$regras{$partefonte}[$ida]}]);
			$str = "";
			@todosal = ();
			# Imprime alinhamento em ${$$regras{$partefonte}[$ida]}[1]
			@aux = split(/\&/,${$$regras{$partefonte}[$ida]}[1]);
			for ($i=0;$i <= $#aux;$i++) {
				$str .= ($i+1)."::";
				@al = split("_",$aux[$i]);
				map($_ = $_+1,@al);
				$str .= join("_",@al);
				$str .= ($i < $#aux) ? "," : "";
				push(@todosal,join("_",@al));
			}
			# Imprime tipo da regra, verificando o tipo de alinhamento
			if (Identifica::filtra_tipo0(\@todosal)) { $str = "T0\n$partefonte<=>$partealvo/(".$str; }
			elsif (Identifica::filtra_tipo1(\@todosal)) { $str = "T1\n$partefonte<=>$partealvo/(".$str; }
			elsif (Identifica::filtra_tipo2(\@todosal)) {$str = "T2\n$partefonte<=>$partealvo/(".$str; }				
			print ARQ $str,")/$peso/$freq\n";
			# NAO 21/03/2007 So imprime o conjunto de restricoes se a regra eh ambigua, ou seja, peso < 1
			#if ($peso < 1) {
				# para cada conjunto de restricoes em @{${$$regras{$partefonte}[$ida]}[2]}
				for($idres=0;$idres <= $#{${$$regras{$partefonte}[$ida]}[2]};$idres++) { 
					@rfonte = @{${${${$$regras{$partefonte}[$ida]}[2]}[$idres]}[0]};
					@ralvo = @{${${${$$regras{$partefonte}[$ida]}[2]}[$idres]}[1]};
					@rbili = @{${${${$$regras{$partefonte}[$ida]}[2]}[$idres]}[2]};
					($peso,$freq) = split('/',${${${$$regras{$partefonte}[$ida]}[2]}[$idres]}[$#{${${$$regras{$partefonte}[$ida]}[2]}[$idres]}]);				
					if (($#rfonte >= 0) || ($#ralvo >= 0) || ($#rbili >= 0)) {
						print ARQ "$peso/$freq\n";
						if ($#rfonte >= 0) { print ARQ "\t",join("\n\t",@rfonte),"\n"; }
						if ($#ralvo >= 0) { print ARQ "\t",join("\n\t",@ralvo),"\n"; }
						if ($#rbili >= 0) { print ARQ "\t",join("\n\t",@rbili),"\n"; }
					}
				}
			#}
			print ARQ "\n";
		}
	}
	close ARQ;
	return $idf;
}

__END__

# Para obter os valores de um campo ($campo) de um dado exemplo ($exemplo) deve-se acessar sua posicao no array de exemplos correspondente ($exemplos): $exemplos[$exemplo]{$campo} o que devolverá um array com os valores do campo

=head1 NAME

ReTraTos - Transfer rule inductor from aligned parallel texts

=head1 SYNOPSIS

ReTraTos [options...] 

 Options:
-sourcefile|s       file with examples in source language (required)
-targetfile|t       file with examples in target language (required)
-type|ty            alignment type: 0, 1, 2 or 3 (all) (default=3)	
-level|l            rules\' abstraction level(s) (default=pos)
-include_gra|ig     grammatical categories for which induce rules (default=all)
-exclude_gra|eg     grammatical categories for which do not induce rules (default=none)
-per_ident|pi       percentage for frequency threshold on pattern identification (default=0.0015)
-filter|fi          determines if filter will be applied (default=no)
-per_filter|pf      percentage for frequency threshold on rule filtering (default=0.0015)
-sort|so            determines if sort will be done (default=no)
-remove|r           remove auxiliary files
-verbose|v          verbose   
-help|h|?           this guide

 Usage Example:

ReTraTos -s pt.txt -t es.txt -f 0.0015 -ig pr,pr+det -eg cm -fi -so

Helena de Medeiros Caseli mai/2005-ago/2006

=cut

