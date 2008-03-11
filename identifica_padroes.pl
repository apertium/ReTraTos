#!/usr/bin/perl

# 02/08/2006 (apenas documentacao)

########################################################################################################
# Programa identificador de padroes
# Entrada: 
# - um arquivo com sequencias de itens separados por espaço
# - frequencia minima de uma sequencia para que esta seja considerada um padrao
# - tamanho minimo do padrao
# - tamanho maximo do padrao
# Saida:
# - imprime na tela os padroes identificados a partir das sequencias de itens no arquivo de entrada e 
# de acordo com os parametros de entrada. Por exemplo, o padrão "2 3" que ocorre nas linhas, 1 (uma vez),
# 2 (uma vez) e 3 (duas vezes) é impresso no formato:
# <pattern>
# <freq>4</freq>
# <what>2 3</what>
# <where>1 2 3 3</where>
# </pattern>
########################################################################################################

use warnings;
use strict;
use locale;

use Getopt::Long;
use Pod::Usage;
use IO::Handle;

my($arq,$minfreq,$tammin,$tammax,$help,$verbose);

$minfreq = 2;
$tammin = 2; # tamanho mínimo de um padrao
$tammax = 5; # tamanho máximo de um padrao

	GetOptions( 'arq|s=s' => \$arq,
							'freq|f=n'  => \$minfreq,
							'tammin|mi=n' => \$tammin,
							'tammax|ma=n' => \$tammax,		
							'verbose|v'  => \$verbose,
							'help|h|?'	 => \$help,) 
				  || pod2usage(2);

	pod2usage(2) if $help;
	pod2usage(2) unless $arq;

	my($padrao,@linhas,$ini,$fim,@tokens,@ids,$qtd,$suporte,$i,$l,@aux,@padroes,@naofreq);
		
	open(IN,$arq) or die "Nao eh possivel abrir o arquivo $arq\n";
	@linhas = <IN>;
	close IN;
	
	map(s/\n//,@linhas);
	map(s/\r//,@linhas);
	
	@padroes = @naofreq = ();
	for($l=0;$l <= $#linhas;$l++) { #L1
		@tokens = split(/ +/,$linhas[$l]);
		$ini = 0;
		while ($ini <= ($#tokens-$tammin+1)) { #L2
			$fim = $ini+$tammin-1;
			@aux = ($l .. $#linhas);
			# Busca padroes de tamanho de $tammin a $tammax começando na posiçao 0
			while (($fim <= $#tokens) && ($fim <= $ini+$tammax-1)) { #L3
				$padrao = join(" ",map($tokens[$_],$ini .. $fim));
				# Se o prefixo nao foi considerado nao frequente e o padrao ainda nao foi testado
				if ((pertence($padrao,\@padroes) == 0) && (pertence($padrao,\@naofreq) == 0)) { 
					# Cria conjunto de identificadores de sentenças nas quais $padrao ocorre
					@ids = (); $suporte = 0;			
					for($i = 0;$i <= $#aux;$i++) {
						if ($verbose) { print "Verificando $padrao em linha ",$aux[$i]+1; }
						$qtd = ocorrencias($padrao,$linhas[$aux[$i]]);
						if ($verbose) { print " ocorre $qtd vezes\n"; }
						while ($qtd > 0) { push(@ids,$aux[$i]); $suporte++; $qtd--; }					
					}
					if ($suporte >= $minfreq) { # Eh um padrao
						print "<pattern>\n<freq>",$#ids+1,"</freq>\n<what>$padrao</what>\n<where>",join(" ",map($_+1,@ids)),"</where>\n</pattern>\n";
						@aux = ();
						map(pertence($_,\@aux) == 0 ? push(@aux,$_) : (),@ids);
						push(@padroes,$padrao);
					}
					else { # se o prefixo nao eh um padrao qualquer coisa que começa com ele tb nao sera
						push(@naofreq,$padrao);
						last; 
					} 				
				}
				$fim++;
			}
			$ini++;
		}
	}

# Sub-rotina pertence
# Entrada: $elemento e $array
# Funcao: Verifica se $elemento esta presente em @$array
sub pertence {
	my($elemento,$array) = @_;
	
	if ($#$array < 0) { return 0; }
	$elemento = quotemeta($elemento);
	return grep(/^$elemento$/,@$array);	
}

# Sub-rotina ocorrencias
# Entrada: $sub e $str
# Funcao: Retorna o numero de vezes que $sub eh encontrada em $str
sub ocorrencias {
	my($sub,$str) = @_;
	my($ind,$qtd,$off);
	
	$qtd = $off = 0;
	while ($off < length($str)) {
		$ind = index($str,$sub,$off);
		if ($ind == -1) { last; }
		if ((($ind == 0) || (substr($str,$ind-1,1) eq " ")) && 
			(($ind+length($sub) >= length($str)) || (substr($str,$ind+length($sub),1) eq " "))) {
			$qtd++;
		}
		$off = $ind + length($sub) + 1;		
	}
	return $qtd;
}
__END__

=head1 NAME

identifica_padroes - Identifica os padroes em um arquivo com sequencias de itens

=head1 SYNOPSIS

identifica_padroes [options...] 

 Options:
-arq|a     arquivo de entrada (obrigatorio)
-freq|f    frequencia minima para que uma sequencia seja um padrao (df = 2)
-tammin|mi tamanho minimo permitido para um padrao (df = 2)
-tammax|ma tamanho maximo permitido para um padrao (df = 5)
-verbose|v imprime mensagens durante o processamento
-help|h|?  imprime esse guia 

 Examplo de uso:

identifica_padroes -a exemplos.txt 

Helena de Medeiros Caseli nov/2005

=cut
