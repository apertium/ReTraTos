package Filtra;

# 21/03/2007 (filtro de escopo para itens lematizados; impressao de qtd de regras filtradas
# por cada estrategia de filtragem; filtro de valores lexicais retorna 1 ou 0)
# 19/03/2007 (atribuicao das restricoes para lidar com os casos nos quais elas sao vazias)

use 5.006;
use strict;
use warnings;
use locale;
use Auxiliares;

sub regras {
	my($regras,$exef,$por) = @_;
	my(@pfontes,$partefonte,$i,$minfreq,@escopo,$contres,$contval,$contesc,$contfreq,$contamb,$naofil);

	$contres = $contval = $contesc = $contfreq = $contamb = $naofil = 0;
	@pfontes = keys %$regras;
	print "\n\tFiltrando regras para ",$#pfontes+1," partes fonte com ";
	while ($#pfontes >= 0) { #L1
		$partefonte = shift(@pfontes);
		if ($#{$$regras{$partefonte}} > 0) { # regra ambigua
			$contamb += $#{$$regras{$partefonte}};
			# ordena as regras por ordem decrescente de frequencia, elimina aquelas com frequencia menor
			# do que a frequencia minima e retorna a frequencia minima
			$i = $#{$$regras{$partefonte}};
			$minfreq = ordena_filtra_partes_alvo(\@{$$regras{$partefonte}},$por); # filtro por freq
			$contfreq += $i-$#{$$regras{$partefonte}};
			if ($#{$$regras{$partefonte}} > 0) { # regra ambigua
				# 21/03/2007 Se ha item lexicalizado na parte fonte entao o escopo de busca
				# sera alteracoes nesse item na parte alvo, alteracoes em outros itens nao
				# sao consideradas como importantes para serem filtradas
				@escopo = ();
				if ($partefonte =~ /\:/) {	escopo_lexicalizado($partefonte,\@escopo); } # filtro por item lexicalizado
				for($i = 1;$i <= $#{$$regras{$partefonte}};$i++) { # para as outras opcoes
					# so vou filtrar por restricoes e valores lexicais se nao ha item lexicalizado
					# ou a diferenca na parte alvo esta no item lexicalizado
					if (($#escopo < 0) || (filtra_escopo($partefonte,$regras,$i,\@escopo))) { # 21/03/2007
						if (filtra_restricoes(\@{$$regras{$partefonte}},$i,$minfreq) == 0) {
							if (filtra_valores_lexicais($partefonte,$regras,$i,$exef,$minfreq)) { $contval++; }
							else { $naofil++; }
							delete($$regras{$partefonte}[$i]);					
						}
						else { $contres++; }
					}
					else { 
						delete($$regras{$partefonte}[$i]); 
						$contesc++;
					}
				} # for i			
				@{$$regras{$partefonte}} = grep(defined($$_[0]),@{$$regras{$partefonte}});
			} # if ambigua apos ordena_filtra
		} # if ambigua
	} # while pfontes
	print "$contamb regras ambiguas:";
	if ($contfreq > 0) { print "\n\t\t-$contfreq filtradas de acordo com a frequencia minima para filtro"; }
	if ($contesc > 0) { print "\n\t\t-$contesc filtradas de acordo com os itens lexicalizados"; }
	if ($contres > 0) {	print "\n\t\t-$contres filtradas de acordo com as restricoes"; }
	if ($contval > 0) {	print "\n\t\t-+$contval regras alteradas com os valores lexicais"; }
	if ($naofil > 0) {	print "\n\t\t-$naofil eliminadas sem filtro"; }
	@pfontes = keys %$regras;
	print "\n\t",$#pfontes+1," regras resultantes apos o filtro\n";
}

#*****************************************************************************************************
#                                        ORDENACAO DE PARTES ALVO
#*****************************************************************************************************
sub ordena_filtra_partes_alvo {
	my($array,$por) = @_;
	my($i,%aux,$t,$j,@saida,@ordem,$maiorfreq,$minfreq);

	# calcula frequencias
	for($i=0;$i <= $#$array;$i++) { # array de opcoes alvo
		$t = 0;
		for($j=0;$j <= $#{$$array[$i][2]};$j++) { # array de opcoes de restricoes
			$t += $#{${${$$array[$i][2]}[$j]}[3]}+1;
		}
		$aux{$i} = $t; # ha $t exemplos nos quais a parte fonte ocorre alinhada com a parte alvo em $i
	}
	@ordem = sort {int($aux{$b}) <=> int($aux{$a})} keys %aux;
	$maiorfreq = $aux{$ordem[0]};
	$minfreq = $por*$maiorfreq;
	$minfreq = ($minfreq < 1) ? 1 : int($minfreq);
	@saida = ();
	# ordena e filtra
	while($#ordem >= 0) {
		if ($aux{$ordem[0]} >= $minfreq) { # filtra
			push(@saida,$$array[$ordem[0]]); # o 1o. em @ordem deve ser o 1o. em saida
		}
		shift(@ordem);
	}
	@$array = @saida;
	return $minfreq;
}

#****************************************************************************************************
#                                        FILTRAGEM POR ESCOPO
#****************************************************************************************************
sub filtra_escopo { # 21/03/2007
	my($partefonte,$regras,$posicao,$escopo) = @_;
	my(@melhoralvo,@outraalvo,@melhorali,@outraali,@melhorescopo,@outraescopo);
	
	@melhoralvo = split(/ /,${$$regras{$partefonte}[0]}[0]);	
	@melhorali = split(/\&/,${$$regras{$partefonte}[0]}[1]);	
	@melhorescopo = map($melhorali[$_],@$escopo);
	@outraalvo = split(/ /,${$$regras{$partefonte}[$posicao]}[0]);
	@outraali = split(/\&/,${$$regras{$partefonte}[$posicao]}[1]);	
	@outraescopo = map($outraali[$_],@$escopo);	
	while ($#melhorescopo >= 0) {
		if (join("+",map($melhoralvo[$_],split(/\_/,$melhorescopo[0]))) ne 
			join("+",map($outraalvo[$_],split(/\_/,$outraescopo[0])))) { 
			return 1; 
		}
		shift(@melhorescopo);
		shift(@outraescopo);
	}
	return 0;	
}

sub escopo_lexicalizado { # 21/03/2007
	my($partefonte,$escopo) = @_;
	my(@auxfonte);
	
	@auxfonte = split(/ /,$partefonte);
	@$escopo = grep($auxfonte[$_] =~ /\:/,0..$#auxfonte);
}

#****************************************************************************************************
#                                        FILTRAGEM POR VALORES LEXICAIS
#****************************************************************************************************
sub valores_lexicais {
	my($res,$pos,$exe,$saida) = @_;
	my($i);

	@$saida = ();
	for($i = 0;$i <= $#$res;$i++) { # para cada opcao de restricao
		map(Auxiliares::insere_array(${$$exe[$$_[0]]{'lex'}}[${$$_[1]}[$pos]],$saida),@{${$$res[$i]}[3]});
	}
}

sub insere_info {
	my($arrayexe,$infoexe,$arrayuni,$uni) = @_;
	
#	print "Tentando inserir: $$infoexe[0] (",join(",",@{$$infoexe[1]}),") (",join(",",@{$$infoexe[2]}),") em (",join(" ",@$arrayexe),")\n";
	Auxiliares::insere_exemplo($infoexe,$arrayexe);
	Auxiliares::insere_array($uni,$arrayuni);
}
	
sub valores_unicos {
	my($res,$pos,$exe,$melhores,$opres,$unicos) = @_;
	my($i,$qtd,@exemplos,$chave);
	
	$qtd = 0;
	@$unicos = ();
	for($i=0;$i <= $#$res;$i++) { # para cada conjunto de restricoes
		# armazena os exemplos nos quais os valores unicos ocorrem no conjunto de restricoes $$res[$i]
		@exemplos = ();
#		print "Exemplos: (",map($$_[0].'|'.join(",",@{$$_[1]}).'|'.join(",",@{$$_[2]}),@{$$res[$i][3]}),")\n";		
#		print "Valores lexicais: ",join(",",map(${$$exe[$$_[0]]{'lex'}}[${$$_[1]}[$pos]],@{$$res[$i][3]})),"\n";
#		print "Valores melhores: ",join(",",@$melhores),"\n";
		map(Auxiliares::pertence(${$$exe[$$_[0]]{'lex'}}[${$$_[1]}[$pos]],$melhores) == 0 ? insere_info(\@exemplos,$_,$unicos,${$$exe[$$_[0]]{'lex'}}[${$$_[1]}[$pos]]) : (),@{${$$res[$i]}[3]});
		if ($#exemplos >= 0) {
			$chave = join('&',@{$$res[$i][0]}).'/'.join('&',@{$$res[$i][1]}).'/'.join('&',@{$$res[$i][2]});
#			map(Auxiliares::insere_exemplo(\@{$_},\@{$$opres{$chave}}),@exemplos);
			@{$$opres{$chave}} = @exemplos;
			$qtd += $#exemplos+1;			
#			print "Chave = $chave, Exemplos:",join(" ",map($$_[0].'|'.join(",",@{$$_[1]}).'|'.join(",",@{$$_[2]}),@{$$opres{$chave}})),"\n";
		}
	}
	return $qtd;
}

sub busca_posicao_diferente {
	my($partefonte,$regras,$opalvo,$pos) = @_;
	my(@pamelhor,@paopalvo,@almelhor,@alopalvo,$aux);

	@pamelhor = split(/ /,$$regras{$partefonte}[0][0]);         # parte alvo da melhor opcao alvo
	@paopalvo = split(/ /,$$regras{$partefonte}[$opalvo][0]);   # parte alvo da opcao alvo sob estudo
	@almelhor = split(/\&/,$$regras{$partefonte}[0][1]);        # alinhamento da melhor opcao alvo
	@alopalvo = split(/\&/,$$regras{$partefonte}[$opalvo][1]);  # alinhamento da opcao sob estudo
	# busca a posicao na qual ha diferenca entre a melhor opcao e $opalvo, com base no alinhamento
	$aux = Auxiliares::posicao_diferente(\@almelhor,\@alopalvo,$$pos+1);
#	print "Alinhamentos = (",join(",",@almelhor),") e (",join(",",@alopalvo),") = $aux\n";
	if ($aux < 0) {
		# busca a posicao na qual ha diferenca entre a melhor opcao e $opalvo, com base na parte alvo
		$aux = Auxiliares::posicao_diferente(\@pamelhor,\@paopalvo,$$pos+1);
#		print "Alvos = (",join(",",@pamelhor),") e (",join(",",@paopalvo),") = $aux\n";
	}
	$$pos = $aux;
}

sub filtra_valores_lexicais {
	my($partefonte,$regras,$posicao,$exef,$minfreq) = @_;
	my(@auxfonte,$pos,@melhoresvalores,%oprestricao,@restringe,$t,$qtd,$novo,@chaves,@aux,$chave,@opcao,$sucesso);
	
	$sucesso = 0;
#	print "\nValores lexicais: Tentando filtrar $partefonte\n";
	@auxfonte = split(/ /,$partefonte);
	%oprestricao = ();
	$qtd = 0;
	$pos = -1;
	do {
		# pos = posicao fonte alinhada com o elemento alvo diferente
		busca_posicao_diferente($partefonte,$regras,$posicao,\$pos);
		if (($pos >= 0) && ($pos <= $#auxfonte) && 
			($auxfonte[$pos] !~ /\:/)) { # pos so sera lexicalizada se ainda nao estiver
#			print "Buscando valores lexicais para posicao $pos = $auxfonte[$pos]\n";
			map(valores_lexicais(\@{$$regras{$partefonte}[$_][2]},$pos,$exef,\@melhoresvalores),0..$posicao-1);
			$t = valores_unicos(\@{$$regras{$partefonte}[$posicao][2]},$pos,$exef,\@melhoresvalores,\%oprestricao,\@restringe);
			if ($t > 0) {
				$auxfonte[$pos] .= '|'.join("|",@restringe); # restringe parte fonte
				$qtd += $t;
			}
		}
	} until ($pos < 0);
	if ($qtd >= $minfreq) { # so cria a regra se ela ocorrer em pelo menos $minfreq exemplos
		$novo = join(" ",@auxfonte);
#		print "Lexicais: parte fonte anterior = $partefonte e nova = $novo\n";
		${$$regras{$novo}[0]}[0] = ${$$regras{$partefonte}[$posicao]}[0];
		${$$regras{$novo}[0]}[1] = ${$$regras{$partefonte}[$posicao]}[1];
		@chaves = keys %oprestricao;
		while ($#chaves >= 0) {
			$chave = shift(@chaves);
			@aux = split(/\//,$chave);
			@opcao = ();
			# restricoes fonte
			if ($#aux >= 0) { push(@opcao,[split(/\&/,shift(@aux))]); }
			else { push (@opcao,[()]); }
			# restricoes alvo
			if ($#aux >= 0) { push(@opcao,[split(/\&/,shift(@aux))]); }
			else { push (@opcao,[()]); }
			# restricoes bilingues
			if ($#aux >= 0) { push(@opcao,[split(/\&/,shift(@aux))]); }
			else {  push (@opcao,[()]); }
			# informacoes dos exemplos
			push(@opcao,[@{$oprestricao{$chave}}]);
			push(@{${$$regras{$novo}[0]}[2]},[@opcao]);
#			print join(" ",map($$_[0].'|'.join(",",@{$$_[1]}).'|'.join(",",@{$$_[2]}),@{${${$$regras{$novo}[0]}[2]}[3]})),"\n";
		}
		$sucesso = 1;
	}
	return $sucesso;
}

#****************************************************************************************************
#                                        FILTRAGEM POR RESTRICOES
#****************************************************************************************************
sub bili_to_mono {
	my($res,$pos) = @_;
	my(@aux) = split(/\=/,$res);
	return $aux[$pos]."=".$aux[$#aux];
}

sub filtra_restricoes {
	my($opcoes,$pos,$minfreq) = @_;
	my($op,@todas,$r,@aux,@resunica,$qtd);
	
	@todas = ();
	for($op=0;$op < $pos;$op++) { # para todas as opcoes alvo que vem antes de $pos
		for($r=0;$r <= $#{$$opcoes[$op][2]};$r++) { # para todas as opcoes de restricoes
			map(Auxiliares::insere_array($_,\@todas),@{${${$$opcoes[$op][2]}[$r]}[0]}); # restricoes fonte
			# restricoes bilingues
			map(Auxiliares::insere_array(bili_to_mono($_,0),\@todas),@{${${$$opcoes[$op][2]}[$r]}[2]}); 
		}		
	}
	@resunica = ();
	$qtd = 0;
	for($r=0;$r <= $#{$$opcoes[$pos][2]};$r++) { # para todos conj de restricoes da opcao em $pos
		# verifica se existe alguma restricao fonte que nao aparece nas restricoes das anteriores
		@aux = grep(Auxiliares::pertence($_,\@todas) == 0,@{${${$$opcoes[$pos][2]}[$r]}[0]}); 
		if ($#aux >= 0) { 
			push(@resunica,$r); # $r tem alguma restricao fonte diferente
			$qtd += $#{${$$opcoes[$pos][2]}[$r][3]}+1;
		}
		else { # verifica se existe alguma restricao bilingue que nao aparece nas restricoes das anteriores
			@aux = grep(Auxiliares::pertence(bili_to_mono($_,0),\@todas) == 0,@{${${$$opcoes[$pos][2]}[$r]}[2]}); 
			# mantem o conj de restricao $r pois tem alguma restricao bilingue diferente
			if ($#aux >= 0) { 
				push(@resunica,$r); 
				$qtd += $#{${$$opcoes[$pos][2]}[$r][3]}+1;
			}			
		}
	}
	if (($#resunica >= 0) && ($qtd >= $minfreq)) {
		for($r=0;$r <= $#{$$opcoes[$pos][2]};$r++) {
			# apaga as outras opcoes de restricoes dessa parte alvo que nao sao unicas, apaga exemplos junto
			if (Auxiliares::pertence($r,\@resunica) == 0) { delete(${$$opcoes[$pos][2]}[$r]);	}
		}
		@{$$opcoes[$pos][2]} = grep(defined($_),@{$$opcoes[$pos][2]});
		return 1;
	}
	return 0;
}

1;
__END__
