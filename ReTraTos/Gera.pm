package Gera;

# 19/03/2007 (atribuicao das restricoes para lidar com os casos nos quais elas sao vazias)
# 29/08/2006 (alinhamentos sao salvos como string e nao mais como array)
# 07/08/2006 (separacao dos passos da geracao das regras em criacao e generalizacao e
# remocao das restricoes monolingues que estao nas bilingues em cria_restricoes)

use 5.006;
use strict;
use warnings;
use locale;
use Auxiliares;

#*******************************************************************************************
#                                     GERACAO DE REGRAS DE TRADUCAO
#*******************************************************************************************
sub regras {
	my($campo,$tipo,$exef,$exea,$padbil,$regras) = @_;
	my($i,$j,$fonte,$alvo,@fontes,$qtd,@opcoes,%res,@aux,$rfonte,$ralvo,$rbili,@opcao);
	
	$qtd = 0;
	@fontes = keys %$padbil;
	while ($#fontes >= 0) { # cada parte fonte
		$fonte = shift(@fontes);
		for ($j=0;$j <= $#{$$padbil{$fonte}};$j++) { # cada opcao alvo
			$alvo = ${$$padbil{$fonte}[$j]}[0];
			# Cria restricoes de concordancia em cada um dos lados e ambos os lados
			cria_restricoes(\@{${$$padbil{$fonte}[$j]}[2]},$exef,$exea,'X','Y',\%res);
			# Generaliza restricoes
			generaliza_restricoes(\%res);
			@aux = keys %res;
			@opcoes = ();
			while ($#aux >= 0) {
				($rfonte,$ralvo,$rbili) = split('/',$aux[0]);
				@opcao = ();
				# restricoes fonte
				if ($rfonte ne "") { push(@opcao,[split(/\&/,$rfonte)]); }
				else { push(@opcao,[()]); }
				# restricoes alvo
				if ($ralvo ne "") { push(@opcao,[split(/\&/,$ralvo)]); }
				else { push(@opcao,[()]); }
				# restricoes bilingues
				if ($rbili ne "") { push(@opcao,[split(/\&/,$rbili)]); }
				else { push(@opcao,[()]); }
				# informacoes de exemplos
				push(@opcao,$res{$aux[0]});
				push(@opcoes,[@opcao]);
				delete $res{shift(@aux)};
			}
			if ($#opcoes < 0) { 
				push(@opcoes,[[()],[()],[()],[@{${$$padbil{$fonte}[$j]}[2]}]]); 
			}	
			push(@{$$regras{$fonte}},[$alvo,${$$padbil{$fonte}[$j]}[1],[@opcoes]]);
			$qtd++;
		}
	}
	print "\n\t$qtd regras geradas\n";
}

sub ocorre_restricao { # criado em 07/08/2006
	my($res,$todas) = @_;
	my(@aux);
	
	@aux = split(/\=/,$res); # A = val ou A(,B) = C(,D) = val
	if (Auxiliares::pertence($aux[0],$todas)) { return 1; }
	return 0;
}

sub cria_restricoes {
	my($infoexe,$exef,$exea,$charf,$chara,$opres) = @_;
	my($idexe,@aux,$atrf,$atra,@resf,@resa,@resbili);
	
	%$opres = ();
	for($idexe=0;$idexe <= $#$infoexe;$idexe++) { # para cada exemplo
		$atrf = join("/",map($$exef[$$infoexe[$idexe][0]]{'atr'}[$_],@{$$infoexe[$idexe][1]}));
		@resf = restringe_monolingue($atrf,$charf);
		$atra = join("/",map($$exea[$$infoexe[$idexe][0]]{'atr'}[$_],@{$$infoexe[$idexe][2]}));
		@resa = restringe_monolingue($atra,$chara);
		@resbili = restringe_bilingue($atrf,$atra,$charf,$chara);
		# remove restricoes monolingues que aparecem nas restricoes bilingues (07/08/2006)
		@aux = ();
		map(push(@aux,split(/\=/,$_)),@resbili);
		map(s/([^\,]+)\,.+/$1/,@aux);
		@resf = grep(length($_) > 0,map(ocorre_restricao($_,\@aux) ? "" : $_,@resf));
		@resa = grep(length($_) > 0,map(ocorre_restricao($_,\@aux) ? "" : $_,@resa));
		# so estou guardando o id do exemplo, nada de posicoes fonte e alvo
		push(@{$$opres{join('&',@resf).'/'.join('&',@resa).'/'.join('&',@resbili)}},$$infoexe[$idexe]); 
	}
}
			
#*******************************************************************************************
#                                  RESTRICOES MONOLINGUES
#*******************************************************************************************
sub restringe_monolingue {
	my($atr,$char) = @_;
	my(@aux,@arrayatr,$a,$i,$j,@res);
	
	@res = ();
	$atr =~ s/[\+&]//g;
	@arrayatr = Auxiliares::converte_stratr_arrays($atr);
	for($i=0;$i <= $#arrayatr;$i++) {
		for($j=0;$j <= $#{$arrayatr[$i]};$j++) {
			$a = $arrayatr[$i][$j];
			if ($a ne "NC") {
				@aux = map(Auxiliares::pertence($a,\@{$arrayatr[$_]}) ? $char.($_+1)."_".(Auxiliares::posicao($a,\@{$arrayatr[$_]},0)+1) : (),$i+1 .. $#arrayatr);
				if ($#aux >= 0) {
					# cria restricao de concordancia/valor
					push(@res,$char.($i+1)."_".($j+1)."=".join(",",@aux)."=".$a); 
					map(Auxiliares::pertence($a,\@{$arrayatr[$_]}) ? map(s/^$a$/NC/,@{$arrayatr[$_]}) : (),$i .. $#arrayatr);
				}
				else { push(@res,$char.($i+1)."_".($j+1)."=".$a); } # cria restricao de valor
			}
		}
	}
	return @res;
}

#*******************************************************************************************
#                                  RESTRICOES BILINGUES
#*******************************************************************************************
sub restringe_bilingue {
	my($atrf,$atra,$charf,$chara) = @_;
	my(@auxf,@auxa,@arrayatrf,@arrayatra,$a,$i,$j,@res);
	
	@res = ();
	$atrf =~ s/[\+&]//g;
	@arrayatrf = Auxiliares::converte_stratr_arrays($atrf);
	$atra =~ s/[\+&]//g;
	@arrayatra = Auxiliares::converte_stratr_arrays($atra);
	for($i=0;$i <= $#arrayatrf;$i++) {
		for($j=0;$j <= $#{$arrayatrf[$i]};$j++) {
			$a = $arrayatrf[$i][$j];
			if ($a ne "NC") {
				@auxa = map(Auxiliares::pertence($a,\@{$arrayatra[$_]}) ? $chara.($_+1)."_".(Auxiliares::posicao($a,\@{$arrayatra[$_]},0)+1) : (),0 .. $#arrayatra);
				if ($#auxa >= 0) {
					@auxf = map(Auxiliares::pertence($a,\@{$arrayatrf[$_]}) ? $charf.($_+1)."_".(Auxiliares::posicao($a,\@{$arrayatrf[$_]},0)+1) : (),$i .. $#arrayatrf);
					push(@res,join(",",@auxf)."=".join(",",@auxa)."=".$a);
					map(Auxiliares::pertence($a,\@{$arrayatrf[$_]}) ? map(s/^$a$/NC/,@{$arrayatrf[$_]}) : (),$i .. $#arrayatrf);
				}
			}
		}
	}
	return @res;	
}

#*******************************************************************************************
#                                          GENERALIZACAO
#*******************************************************************************************
sub trata_valores {
	my($val1,$val2) = @_;
	my(@aux,@valores);
	
	@valores = split(/\|/,$val1);
	@aux = split(/\|/,$val2);
	while ($#aux >= 0) { Auxiliares::insere_array(shift(@aux),\@valores); }
	return @valores;
}

sub generaliza {
	my($res1,$res2,$val) = @_;
	my(@aux1,@aux2,$comum,$gen,$depois,$i,$val1,$val2,@valores,@auxval1,@auxval2);
	
	@aux1 = split(/&/,$res1);
	@aux2 = split(/&/,$res2);
	if ($#aux1 != $#aux2) { return "-"; }
	$gen = $depois = "";
	for($i=0;$i <= $#aux1;$i++) {
		# copia as restricoes iguais
		if ($aux1[$i] eq $aux2[$i]) { $gen .= $aux1[$i]."&"; }
		else { #ate que encontre uma diferente
			if ($aux1[$i] =~ /(.+)=(.+)/) { 
				$comum = $1;
				$val1 = $2;
			}
			# so generaliza se as variaveis forem as mesmas e as restricoes divergirem apenas em seus valores
			if ($aux2[$i] =~ /$comum=(.+)/) { $val2 = $1; }
			else { return "-"; }
			# determina qual restricao generalizar		
			$depois = join("&",map($aux1[$_],$i+1 .. $#aux1));
			# alem disso, as restricoes que vem depois da que sera generalizada (i) devem ser iguais
			if ($depois eq join("&",map($aux2[$_],$i+1 .. $#aux2))) { 
				if (($val1 =~ /\|/) || ($val2 =~ /\|/)) { @valores = trata_valores($val1,$val2); }
				else { @valores = ($val1,$val2); }
				$$val = join("|",sort {$a cmp $b} @valores);
				$gen .= $comum."=".$$val;
				if ($depois ne "") { $gen .= "&".$depois; }
				return $gen;
			}
			else { return "-"; }
		}
	} # for
	return "-";
}

sub generaliza_restricoes {
	my($opres) = @_;
	my(@chaves,$chave1,$chave2,$fonte1,$fonte2,$alvo1,$alvo2,$bili1,$bili2,$genf,$gena,$genbili,$i);
	my($valf,$vala,$valbili);
	
	@chaves = keys %$opres;
	while ($#chaves >= 0) {
		$chave1 = shift(@chaves);
		($fonte1,$alvo1,$bili1) = split('/',$chave1);
		$i = 0;
		while ($i <= $#chaves) {
			$chave2 = $chaves[$i];
			($fonte2,$alvo2,$bili2) = split('/',$chave2);
			$valf = $vala = $valbili = "";
			$genf = ($fonte1 eq $fonte2) ? $fonte1 : generaliza($fonte1,$fonte2,\$valf); 
			if ($genf ne "-") { # as duas partes fonte sao iguais ou foram generalizadas
				$gena = ($alvo1 eq $alvo2) ? $alvo1 : generaliza($alvo1,$alvo2,\$vala);
				if (($gena ne "-") && (($valf eq "") || 
            ($vala eq $valf))) { # as duas partes alvo sao =s ou foram generalizadas como as fonte
					$genbili = ($bili1 eq $bili2) ? $bili1 : generaliza($bili1,$bili2,\$valbili);
					if (($genbili ne "-") && (($vala eq "") || 
             ($valbili eq $vala))) { # as duas partes bilingues sao =s ou foram gen como as fonte/alvo
						push(@{$$opres{$genf.'/'.$gena.'/'.$genbili}},@{$$opres{$chave1}});
						delete($$opres{$chave1});
						push(@{$$opres{$genf.'/'.$gena.'/'.$genbili}},@{$$opres{$chave2}});
						delete($$opres{$chave2});
						Auxiliares::remove_array($chave2,\@chaves);
						push(@chaves,$genf.'/'.$gena.'/'.$genbili);
						$i = $#chaves;
					}
				}
			}
			$i++;
		}
	}	
}

1;
__END__
