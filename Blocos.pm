package Blocos;

# 19/03/2007 (alterei a atribuicao do fim2f e fim2a em cria blocos que estava sem o -1)
# 30/01/2007 (alteracoes para o codigo fonte ficar mais parecido com o algoritmo da tese)
# 31/08/2006 (impressao de blocos alterada para apagar de $blocos os que nao foram filtrados)

use 5.006;
use strict;
use warnings;
use locale;

#*****************************************************************************************************
#                                                TIPOS DE  BLOCOS
#*****************************************************************************************************
sub processa_tipo_0 {
	my($fim,$array) = @_;

	while (($$fim <= $#$array) && ($$array[$$fim] !~ /_/) && ($$array[$$fim] == 0)) { $$fim++; }
}

sub processa_tipo_1 {
	my($fimf,$fonte,$fima,$alvo,$fim2f,$fim2a) = @_;
	my(@auxf,@auxa);
	
	while (($$fimf <= $#$fonte) && ($$fima <= $#$alvo)) {
		@auxf = split(/\_/,$$fonte[$$fimf]);
		if (($auxf[0] == $$fima+1) && ($auxf[$#auxf] == $auxf[0]+$#auxf)) { 
			@auxa = split(/\_/,$$alvo[$$fima]);
			if ($auxa[$#auxa] == $auxa[0]+$#auxa) {
				$$fimf = $auxa[$#auxa];
				$$fima = $auxf[$#auxf];
				$$fim2f = ($$fimf > $$fim2f) ? $$fimf : $$fim2f;
				$$fim2a = ($$fima > $$fim2a) ? $$fima : $$fim2a;
			}
			else { last; }
		}
		else { last; }
	}
}

sub incrementa_menores {
	my($ind,$array,$indc) = @_;
	my(@aux,$saida);
	
	$saida = 0;
	@aux = split(/\_/,$$array[$$ind]);
	if (($aux[0] != 0) && ($aux[$#aux] < $indc)) { 
		while (($$ind < $#$array) && ($aux[0] != 0) && ($aux[$#aux] < $indc)) {
			$$ind++;
			@aux = split(/\_/,$$array[$$ind]);
			$saida = 1;
		}
	}
	return $saida;
}

sub aplica_janela {
	my($ini,$fim,$janela,$limsup) = @_;
	
	$$ini = ($$ini-$janela > 0) ? $$ini-$janela : 0;
	$$fim = ($$fim+$janela < $limsup) ? $$fim+$janela : $limsup;
}

sub cria_bloco {
	my($indexe,$ini,$fim,$tipo,$blocos) = @_;
	my(@ind) = ();
	
	push(@ind,$ini,$fim-1);
	push(@{$$blocos{$tipo}},[$indexe,[@ind]]);
}

sub cria_blocos {
	my($janela,$tammin,$indexe,$fonte,$alvo,$blofonte,$bloalvo) = @_;
	my($inif,$inia,$fimf,$fima,@auxf,@auxa,$ini0,$fim0,$ini2f,$ini2a,$fim2f,$fim2a,$dois);
	
#	print "$indexe\n";
	$inif = $inia = $fimf = $fima = $ini2f = $ini2a = $fim2f = $fim2a = $dois = 0;
	while (($fimf <= $#$fonte) && ($fima <= $#$alvo)) { # percorre todos os alinhamentos (L1)
		@auxf = split(/\_/,$$fonte[$fimf]);
		@auxa = split(/\_/,$$alvo[$fima]);
		if (($auxf[0] == $fima+1) && ($auxf[$#auxf] == $auxf[0]+$#auxf) &&
			($auxa[0] == $fimf+1) && ($auxa[$#auxa] == $auxa[0]+$#auxa)) { # alinhamento em ordem: tipo1
			$inia = $fima;
			$inif = $fimf;
			processa_tipo_1(\$fimf,$fonte,\$fima,$alvo,\$fim2f,\$fim2a);
			if ($fimf - $inif >= $tammin) {
				cria_bloco($indexe,$inif,$fimf,1,$blofonte); # cria bloco fonte
				cria_bloco($indexe,$inia,$fima,1,$bloalvo); # cria bloco alvo			
			}
		}
		elsif (($$fonte[$fimf] !~ /_/) && ($$fonte[$fimf] == 0)) { # omissoes fonte: tipo0
			$inif = $fimf;
			processa_tipo_0(\$fimf,$fonte); # 30/01/07
#			while (($fimf <= $#$fonte) && ($$fonte[$fimf] !~ /_/) && ($$fonte[$fimf] == 0)) { $fimf++; }
			$ini0 = $inif;
			$fim0 = $fimf;
			aplica_janela(\$ini0,\$fim0,$janela,$#$fonte);
			if ($fim0 - $ini0 >= $tammin) { cria_bloco($indexe,$ini0,$fim0,0,$blofonte); } # cria bloco fonte
		}
		elsif (($$alvo[$fima] !~ /\_/) && ($$alvo[$fima] == 0)) { # omissoes alvo: tipo0
			$inia = $fima;
			processa_tipo_0(\$fima,$alvo); # 30/01/07
#			while (($fima <= $#$alvo) && ($$alvo[$fima] !~ /_/) && ($$alvo[$fima] == 0)) { $fima++; }
			$ini0 = $inia;
			$fim0 = $fima;
			aplica_janela(\$ini0,\$fim0,$janela,$#$alvo);
			if ($fim0 - $ini0 >= $tammin) { cria_bloco($indexe,$ini0,$fim0,0,$bloalvo); } # cria bloco alvo
		}
		else { # tipo 2: reordenamento
			if ($dois == 0) {
				$ini2f = $fimf; 
				$ini2a = $fima; 
				$dois = 1;
			}
			if ((incrementa_menores(\$fimf,$fonte,$fima) == 0) && (incrementa_menores(\$fima,$alvo,$fimf) == 0)) {
				if ($auxf[0] == $fima+2) { $fima++; }
				elsif ($auxa[0] == $fimf+2) { $fimf++; }
				else {	$fimf++; $fima++; }
				$fim2f = ($auxa[$#auxa]-1 > $fim2f) ? $auxa[$#auxa]-1 : $fim2f; 
				$fim2a = ($auxf[$#auxf]-1 > $fim2a) ? $auxf[$#auxf]-1 : $fim2a;
			}
			if ($dois && ($fimf >= $fim2f) && ($fima >= $fim2a)) {
				if ($fim2f - $ini2f >= $tammin) {
					cria_bloco($indexe,$ini2f,$fim2f,2,$blofonte); # cria bloco fonte
					cria_bloco($indexe,$ini2a,$fim2a,2,$bloalvo); # cria bloco alvo			
				}
				$dois = 0;
			}
		}
	} #fim de L1
	if ($fimf <= $#$fonte) { cria_bloco($indexe,$fimf,$#$fonte+1,0,$blofonte); } # tipo 0: omissao fonte
	if ($fima <= $#$alvo) { cria_bloco($indexe,$fima,$#$alvo+1,0,$bloalvo); } # tipo 0: omissao alvo
	if ($#{$$blofonte{'1'}} != $#{$$bloalvo{'1'}}) {
		print "ERRO: Quantidades diferentes de blocos fonte e alvo do tipo 1 no exemplo ",$indexe+1,"\n";
		exit 1;
	}
	if ($#{$$blofonte{'2'}} != $#{$$bloalvo{'2'}}) {
		print "ERRO: Quantidades diferentes de blocos fonte e alvo do tipo 2 no exemplo ",$indexe+1,"\n";
		exit 1;
	}
}

sub imprime_blocos {
	my($exemplos,$blocos,$icategs,$campo,$tipo,$arq) = @_;	
	my($indexe,$itens,$ini,$fim,$i,@aux);
	
	open(ARQ,">$arq") or die "Nao eh possivel abrir o arquivo $arq\n";
	$i = 0;
	while ($i <= $#$blocos) {
		$indexe = ${$$blocos[$i]}[0]; # 02/08/06
		($ini,$fim) = @{${$$blocos[$i]}[1]}; # 02/08/06
		$itens = join(" ",map(Auxiliares::mapeia_valor($exemplos,$indexe,$_,$campo,$icategs),($ini .. $fim)));
		if (($icategs ne "") && (Auxiliares::filtra_categorias_gramaticais($itens,$icategs,1) == 0)) { $itens = ''; }	
		if ($itens ne '') { print ARQ "$itens\n"; }
		else { delete($$blocos[$i]); } # 31/08/06
		$i++;		
	}
	close ARQ;
	@$blocos = grep(defined($_),@$blocos); # 31/08/06
}

1;
__END__
