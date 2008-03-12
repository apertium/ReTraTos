package Ordena;

use 5.006;
use strict;
use warnings;
use locale;

#*****************************************************************************************************
#                                        ORDENACAO DE REGRAS
#*****************************************************************************************************
sub regras {
	my($regras) = @_;
	my($totalreg);
	
	$totalreg = calcula_frequencias($regras);
	Auxiliares::mensagem("\n\t".atribui_pesos_ordena($regras,$totalreg)." rules sorted\n");
}

#*****************************************************************************************************
#                                 	CALCULO DE FREQUENCIAS
#*****************************************************************************************************
sub frequencia_restricao {
	my($restricao) = @_;

	return $#{$$restricao[3]}+1; # numero de exemplos
}

sub frequencia_opcao {
	my($opcao) = @_;
	my($i,$res,$total);
	
	$total = 0;
	for($i=0;$i <= $#{$$opcao[2]};$i++) { # para cada uma das restricoes em $opcao
		$res = frequencia_restricao(\@{${$$opcao[2]}[$i]});
		push(@{${$$opcao[2]}[$i]},$res);
		$total += $res;
	}
	return $total;
}

sub frequencia_opcoes {
	my($opcoes) = @_;
	my($i,$opcao,$total);
	
	$total = 0;
	for($i=0;$i <= $#$opcoes;$i++) { # para cada uma das opcoes
		$opcao = frequencia_opcao(\@{$$opcoes[$i]});
		push(@{$$opcoes[$i]},$opcao);
		$total += $opcao;
	}
	return $total;
}

sub calcula_frequencias {
	my($regras) = @_;
	my($freqreg,$i,@chaves,$total);
	
	@chaves = keys %$regras;
	$total = 0;
	# Atribuindo quantidade de exemplos
	for($i=0;$i <= $#chaves;$i++) { # para cada regra
		$freqreg = frequencia_opcoes(\@{$$regras{$chaves[$i]}});
		# Adiciona este valor como o ultimo elemento do array de opcoes alvo dessa regra
		push(@{$$regras{$chaves[$i]}},$freqreg);
		$total += $freqreg;
	}
	return $total;
}

#*****************************************************************************************************
#                          ATRIBUICAO DE PESOS/ORDENACAO
#*****************************************************************************************************
sub atribui_pesos_ordena {
	my($regras,$totalreg) = @_;
	my($freqreg,$freqopc,$i,$j,@chaves);

	@chaves = keys %$regras;
	# Atribuindo pesos: insere junto com a frequencia, o peso (probabilidade)
	for($i=0;$i <= $#chaves;$i++) { # para cada regra
		$freqreg = pop(@{$$regras{$chaves[$i]}});
		for($j=0;$j <= $#{$$regras{$chaves[$i]}};$j++) { # para cada opcao alvo
			$freqopc = ${${$$regras{$chaves[$i]}}[$j]}[$#{${$$regras{$chaves[$i]}}[$j]}];
			# ordena os conjuntos de restricoes
			if ($#{${${$$regras{$chaves[$i]}}[$j]}[2]} > 0) {
				@{${${$$regras{$chaves[$i]}}[$j]}[2]} = sort {int($$b[$#{$b}]) <=> int($$a[$#{$a}])} @{${${$$regras{$chaves[$i]}}[$j]}[2]};
			}
			# atribui pesos para cada conjunto de restricoes
			map($$_[$#{$_}] = sprintf("%1.4f",$$_[$#{$_}]/$freqopc).'/'.$$_[$#{$_}],@{${${$$regras{$chaves[$i]}}[$j]}[2]});
		} # for $j
		if ($#{$$regras{$chaves[$i]}} > 0) { # ordena as opcoes alvo
			@{$$regras{$chaves[$i]}} = sort {int($$b[$#{$b}]) <=> int($$a[$#{$a}])} @{$$regras{$chaves[$i]}};
		}
		# atribui pesos para cada opcao alvo
		map($$_[$#{$_}] = sprintf("%1.4f",$$_[$#{$_}]/$freqreg).'/'.$$_[$#{$_}],@{$$regras{$chaves[$i]}});
		# atribui pesos para cada regra
		#push(@{$$regras{$chaves[$i]}},sprintf("%1.4f",$freqreg/$totalreg).'/'.$freqreg);
		# aletado em 19/03/07
		push(@{$$regras{$chaves[$i]}},sprintf("%1.4f",$freqreg/$totalreg));
		push(@{$$regras{$chaves[$i]}},$freqreg);
	}		
	return $i; 
}

1;
__END__
