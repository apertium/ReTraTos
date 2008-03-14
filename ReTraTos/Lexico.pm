package Lexico;

use 5.006;
use strict;
use warnings;
use locale;
use ReTraTos::Auxiliares;

#**************************************************************************************************
#                                   PROCESSAMENTO NOS DOIS SENTIDOS
#**************************************************************************************************
sub gera_lexico_bilingue {
	my($freq,$exef,$exea,$atrs,$lexbil) = @_;
	my(%lexfonte,%lexalvo);
	
	gera_lexico($exef,$exea,'source-target',\%lexfonte);
	gera_lexico($exea,$exef,'target-source',\%lexalvo);
	processa_bilingue($freq,\%lexfonte,\%lexalvo,$lexbil);
	%lexfonte = %lexalvo = ();
	generaliza_bilingue($lexbil);
	if ($#$atrs > 0) { trata_gd_nd($lexbil,$atrs); }
	limpa_atributos($lexbil);	
}

#**************************************************************************************************
#                                   PROCESSAMENTO EM UM SENTIDO
#**************************************************************************************************
sub gera_lexico {
	my($exef,$exea,$sent,$lex) = @_;
	my($idexe,$posf,$basef,$basea,$categf,$catega,$atrf,$atra,@alvos,@fontes,$i,@itensfonte);

	Auxiliares::mensagem("\tGenerating $sent dictionary ... ");	
	for($idexe=0;$idexe <= $#$exef;$idexe++) {
		$posf = 0;
		@itensfonte = @{$$exef[$idexe]{'lex'}};
		while ($posf <= $#itensfonte) {
			if (($itensfonte[$posf] =~ /[a-zA-Z0-9]+/) && # nao insere entradas para numeros nem caracteres
				(${$$exef[$idexe]{'ali'}}[$posf] ne "0")) { # omissao nao eh opcao de traducao
				@alvos = split(/\_/,${$$exef[$idexe]{'ali'}}[$posf]);
				map($_--,@alvos);
				@alvos = sort {int($a) <=> int($b)} @alvos;
				@fontes = ();
				for($i=0;$i <= $#alvos;$i++) {
					map(Auxiliares::insere_array($_-1,\@fontes),split(/\_/,${$$exea[$idexe]{'ali'}}[$alvos[$i]]));
				}
				@fontes = sort {int($a) <=> int($b)} @fontes;
				$basef = join('+',map(lc(${$$exef[$idexe]{'lex'}}[$_]),@fontes));
				$basef =~ s/\+_/+/g;
				$categf = join('+',map(${$$exef[$idexe]{'pos'}}[$_],@fontes));
				$atrf = join('+',map(${$$exef[$idexe]{'atr'}}[$_],@fontes));				
				$basea = join('+',map(lc(${$$exea[$idexe]{'lex'}}[$_]),@alvos));
				$catega = join('+',map(${$$exea[$idexe]{'pos'}}[$_],@alvos));
				$atra = join('+',map(${$$exea[$idexe]{'atr'}}[$_],@alvos));
				# incrementa frequencia se a entrada ja existe no hash ou a inicializa com 1, em caso contrario
				if (exists($$lex{$basef.'/'.$categf}{$atrf}{$basea.'/'.$catega})) { 
					${$$lex{$basef.'/'.$categf}{$atrf}{$basea.'/'.$catega}}[0]++; 
				}
				else { ${$$lex{$basef.'/'.$categf}{$atrf}{$basea.'/'.$catega}}[0] = 1; }
				# preenche array de opcoes de atributos
				if (exists(${$$lex{$basef.'/'.$categf}{$atrf}{$basea.'/'.$catega}[1]}{$atra})) {
					${$$lex{$basef.'/'.$categf}{$atrf}{$basea.'/'.$catega}[1]}{$atra}++;
				}
				else { ${$$lex{$basef.'/'.$categf}{$atrf}{$basea.'/'.$catega}[1]}{$atra} = 1; }
				map($itensfonte[$_] = "-",@fontes);			
			}
			$posf++;
		}
	}
	Auxiliares::mensagem("OK\n");
}

#**************************************************************************************************
#                                   PROCESSAMENTO NOS DOIS SENTIDOS
#**************************************************************************************************
sub resolve_ambiguidades {
	my($fonte,$freq,$lex) = @_;
	my(@atributosf,@atributosa,@alvos,$atrf,$atra,%aux,$alvo);
	
	%aux = ();
	@atributosf = keys %{$$lex{$fonte}}; # opcoes de atributos fonte
	while ($#atributosf >= 0) {
		$atrf = shift(@atributosf);
		@alvos = sort{int($$lex{$fonte}{$atrf}{$b}[0]) <=> int($$lex{$fonte}{$atrf}{$a}[0])} keys %{$$lex{$fonte}{$atrf}};
		$alvo = $alvos[0]; # melhor opcao alvo para atributos fonte em $atrf
		# so insere multipalavras com uma frequencia consideravel para tentar minimizar os efeitos de alinhamentos errados
		if (($fonte =~ /\+/) && ($$lex{$fonte}{$atrf}{$alvo}[0] < $freq)) {	next; }
		else {
			@atributosa = sort{int($$lex{$fonte}{$atrf}{$alvo}[1]{$b}) <=> int($$lex{$fonte}{$atrf}{$alvo}[1]{$a})} keys %{$$lex{$fonte}{$atrf}{$alvo}[1]};
			$atra = $atributosa[0]; # melhor combinacao de atributos alvo para a opcao $alvo
			$aux{$atrf} = $alvo.'/'.$atra.'/'.$$lex{$fonte}{$atrf}{$alvo}[1]{$atra};			
		}
	}
	return %aux;
}

sub processa_bilingue {
	my($freq,$lexf,$lexa,$lexbil) = @_;
	my(@chaves,$fonte,$alvo,$basef,$basea,$catega,$categf,@fontes,@atributosf,@atributosa,$atrf,$atra,%aux,@teste,$str,$novafreq);

	Auxiliares::mensagem("\tProcessing bilingual dictionary ... ");

	# insere entradas que valem para os dois sentidos ou apenas para LR
	@chaves = sort{$a cmp $b} keys %$lexf;
	while ($#chaves >= 0) {
		$fonte = shift(@chaves);
		if ($fonte !~ /[a-zA-Z]+\/.+/) { next; }
		%aux = resolve_ambiguidades($fonte,$freq,$lexf);
		@atributosf = keys %aux;
		while ($#atributosf >= 0) {
			$atrf = shift(@atributosf);
			$basea = $catega = $atra = "";
			if ($aux{$atrf} =~ /^(.*)\/(.*)\/(.*)\/(.*)$/) {
				$basea = $1; $catega = $2; $atra = $3; $novafreq = $4;
			}
			$alvo = $basea.'/'.$catega;
			@fontes = sort{int($$lexa{$alvo}{$atra}{$b}[0]) <=> int($$lexa{$alvo}{$atra}{$a}[0])} keys %{$$lexa{$alvo}{$atra}};
			@fontes = grep($$lexa{$alvo}{$atra}{$_}[0] == $$lexa{$alvo}{$atra}{$fontes[0]}[0],@fontes);
			if (Auxiliares::pertence($fonte,\@fontes)) { # a traducao vale nos dois sentidos
				insere_entrada_bilingue($fonte,"",$atrf,$alvo,$atra,$novafreq,$lexbil);
			}
			else { # eh preciso inserir inlexacao de que esta traducao so vale para o sentido LR
				insere_entrada_bilingue($fonte,"LR",$atrf,$alvo,$atra,$novafreq,$lexbil);
			}
		}
	}
	# insere entradas que valem apenas para RL
	@chaves = sort{$a cmp $b} keys %$lexa;
	while ($#chaves >= 0) {
		$alvo = shift(@chaves);
		if ($alvo !~ /[a-zA-Z]+\/.+/) { next; }
		%aux = resolve_ambiguidades($alvo,$lexa);
		@atributosa = keys %aux;
		while ($#atributosa >= 0) {
			$atra = shift(@atributosa);
			$basef = $categf = $atrf = "";
			if ($aux{$atra} =~ /^(.*)\/(.*)\/(.*)\/(.*)$/) {
				$basef = $1; $categf = $2; $atrf = $3; $novafreq = $4;
			}
			$fonte = $basef.'/'.$categf;	
			$str = quotemeta($atrf.'/'.$alvo.'/'.$atra);			
			@teste = grep(/^$str$/,map(@{$$lexbil{$fonte}{$_}},keys %{$$lexbil{$fonte}}));
			# Acho que nao precisa if ($#teste < 0) { @teste = grep(/^$str$/,@{$$lexbil{$fonte."/LR"}}); }
			if ($#teste < 0) { # se esta combinacao de valores ainda nao foi inserida no lexico bilingue
				# eh preciso inserir inlexacao de que esta traducao so vale para o sentido RL
				insere_entrada_bilingue($fonte,"RL",$atrf,$alvo,$atra,$novafreq,$lexbil);				
			}
		}
	}
	Auxiliares::mensagem("OK\n");
}

sub insere_entrada_bilingue {
	my($pfonte,$sent,$atrf,$palvo,$atra,$freq,$lex) = @_;
	
	push(@{$$lex{$pfonte}{$sent}},$atrf.'/'.$palvo.'/'.$atra.'/'.$freq);
}

#**************************************************************************************************
#                                          GENERALIZACAO
#**************************************************************************************************
sub generaliza {
	my($atr1,$atr2,$val) = @_;
	my(@aux1,@aux2,$comum,$gen,$depois,$i,$val1,$val2,@valores);

	$gen = $depois = $$val = "";
	$atr1 =~ s/<//g;
	$atr2 =~ s/<//g;
	@aux1 = split(/>/,$atr1);
	@aux2 = split(/>/,$atr2);
	if ($#aux1 != $#aux2) { return ""; }
	@valores = ();
	$i = 0;
	while (($i <= $#aux1) && ($aux1[$i] eq $aux2[$i])) { $gen .= "<".$aux1[$i++].">"; }
	$depois = join("",map("<".$aux1[$_].">",$i+1 .. $#aux1));
	if ($depois eq join("",map("<".$aux2[$_].">",$i+1 .. $#aux2))) {
		push(@valores,$aux1[$i],$aux2[$i]);
		$$val = join("|",sort {$a cmp $b} @valores);
		$gen .= "<".$$val.">".$depois;
		return $gen;
	}
	return "";
}

sub generaliza_atrs {
	my($atr1,$atr2,$val) = @_;
	my(@aux1,@aux2,$gen,$v,$g);

	@aux1 = split(/\+/,$atr1);
	@aux2 = split(/\+/,$atr2);
	if ($#aux1 != $#aux2) { return ""; }
	$gen = $$val = "";
	while (($#aux1 >= 0) && ($#aux2 >= 0)) {
		if ($aux1[0] eq $aux2[0]) { $gen .= $aux1[0].'+'; }
		else {	
			$g = generaliza($aux1[0],$aux2[0],\$v);
			if ($$val eq "") { $$val = $v; }
			if (($g ne "") && ($$val eq $v)) { $gen .= $g.'+'; }
			else { return ""; }
		}
		shift(@aux1);
		shift(@aux2);
	}
	$gen =~ s/^(.+)\+$/$1/;
	return $gen;
}

sub generaliza_opcoes {
	my($opcoes) = @_;
	my($atrf1,$atrf2,$atra1,$atra2,$basea1,$basea2,$catega1,$catega2,$freq1,$freq2,@aux,$i,$j,$genf,$gena,$valf,$vala,$opcao);

	$j = 0;
	while ($j < $#$opcoes) {
		$atrf1 = $basea1 = $catega1 = $atra1 = $freq1 = "";
		if ($$opcoes[$j] =~ /^(.*)\/(.*)\/(.*)\/(.*)\/(.*)$/) {
			$atrf1 = $1; $basea1 = $2; $catega1 = $3; $atra1 = $4; $freq1 = $5;
		}
		$i = $j+1;
		while ($i <= $#$opcoes) {
			$atrf2 = $basea2 = $catega2 = $atra2 = $freq2 = "";
			if ($$opcoes[$i] =~ /^(.*)\/(.*)\/(.*)\/(.*)\/(.*)$/) {
				$atrf2 = $1; $basea2 = $2; $catega2 = $3; $atra2 = $4; $freq2 = $5;
			}
			if (($basea1 eq $basea2) && ($catega1 eq $catega2)) {
				$valf = $vala = "";
				$genf = ($atrf1 ne $atrf2) ? generaliza_atrs($atrf1,$atrf2,\$valf) : $atrf1;
				if ($genf ne "") {
					$gena = ($atra1 ne $atra2) ? generaliza_atrs($atra1,$atra2,\$vala) : $atra1;
					if (($gena ne "") && (($valf eq "") || ($valf eq $vala) || ($atra1 eq $atra2))) {
						delete($$opcoes[$j]);
						delete($$opcoes[$i]);
						$opcao = $genf.'/'.$basea1.'/'.$catega1.'/'.$gena.'/'.($freq1+$freq2);
						push(@$opcoes,$opcao);
						@$opcoes = grep(defined($_),@$opcoes);
						$i = $#$opcoes;
						$j--;
					}
				}
			}
			$i++;
		}		
		$j++;
	}
}

sub generaliza_bilingue {
	my($lex) = @_;
	my(@fontes,@sents,$fonte,$atrf,$atra,$freq,$basea,$catega,$s);

	Auxiliares::mensagem("\tGeneralizing bilingual dictionary ... ");	
	@fontes = keys %$lex;
	while ($#fontes >= 0) {
		$fonte = shift(@fontes);
		@sents = keys %{$$lex{$fonte}};
		for($s=0;$s <= $#sents;$s++) {
			if ($#{$$lex{$fonte}{$sents[$s]}} > 0) { generaliza_opcoes(\@{$$lex{$fonte}{$sents[$s]}}); }
			if (($#sents == 0) && ($#{$$lex{$fonte}{$sents[$s]}} == 0)) {
				$atrf = $basea = $catega = $atra = $freq = "";
				if (${$$lex{$fonte}{$sents[$s]}}[0] =~ /^(.*)\/(.*)\/(.*)\/(.*)\/(.*)$/) {
					$atrf = $1; $basea = $2; $catega = $3; $atra = $4; $freq = $5;
				}
				if ($atrf eq $atra) {
					${$$lex{$fonte}{$sents[$s]}}[0] = "NC/".$basea.'/'.$catega."/NC/$freq";
				}
			}
		}
	}
	Auxiliares::mensagem("OK\n");
}

#**************************************************************************************************
#                                               LIMPEZA
#**************************************************************************************************
sub limpa {
	my($atrf,$atra,$continua) = @_;
	my(@auxf,@auxa,$i,$saida);
	
	$$continua = $saida = 0;
	if ($$atrf eq $$atra) { 
		$$atrf = $$atra = "NC"; 
		$saida = 1;
		$continua = 1;
	}
	else {
		if (($$atrf ne "NC") && ($$atra ne "NC")) {
			@auxf = split(/>/,$$atrf);
			@auxa = split(/>/,$$atra);
			if ($auxf[$#auxf] eq $auxa[$#auxa]) { $saida = 1; }
			while (($#auxf >= 0) && ($#auxa >= 0) && ($auxf[$#auxf] eq $auxa[$#auxa])) { 
				pop(@auxf);
				pop(@auxa);
			}
			# so ira continuar a limpeza para outros elementos se os atributos deste sao todos iguais
			if (($#auxf < 0) && ($#auxa < 0)) { $$continua = 1; } 
			$$atrf = join("",map($_.">",@auxf));
			$$atra = join("",map($_.">",@auxa));			
		}
	}
	return $saida; # retorna a indicacao se foi limpado (1) ou nao (0)
}

sub limpa_atrs {
	my($atrsf,$atrsa) = @_;
	my(@auxf,@auxa,$continua,$i,$saida);

	$saida = 0;
	@auxf = split(/\+/,$$atrsf);
	@auxa = split(/\+/,$$atrsa);
	if ($#auxf == $#auxa) {
		$continua = 1;
		$i = 0;
		while ((($#auxf-$i) >= 0) && (($#auxa-$i) >= 0) && $continua) {
			$saida = $saida || limpa(\$auxf[$#auxf-$i],\$auxa[$#auxa-$i],\$continua);
			$i++;
		}
		@auxf = grep($_ ne "",@auxf);
		@auxa = grep($_ ne "",@auxa);
		$$atrsf = join("+",@auxf);
		$$atrsa = join("+",@auxa);
	}
	return $saida;
}

sub limpa_atributos {
	my($lexbil) = @_;
	my($fonte,@sents,@chaves,$basef,$basea,$categf,$catega,$atrf,$atra,$freq,$sent,@alvos,%atributos,@fontes,$i);
	
	Auxiliares::mensagem("\tCleaning equal attributes ... ");
	@chaves = sort {$a cmp $b} keys %$lexbil;
	while ($#chaves >= 0) {
		$fonte = shift(@chaves);
		$basef = $categf = "";
		if ($fonte =~ /^(.*)\/(.*)$/) {
			$basef = $1; $categf = $2;
		}
		@sents = keys %{$$lexbil{$fonte}};
		if ($#sents == 0) { # so limpa se ha apenas um sentido de traducao
			$sent = shift(@sents);
			%atributos = ();
			for ($i = 0;$i <= $#{$$lexbil{$fonte}{$sent}};$i++) { # para cada uma das opcoes de atributos
				$atrf = $basea = $catega = $atra = $freq = "";
				if (${$$lexbil{$fonte}{$sent}}[$i] =~ /^(.*)\/(.*)\/(.*)\/(.*)\/(.*)$/) {
					$atrf = $1; $basea = $2; $catega = $3; $atra = $4; $freq = $5;
				}
				if (($atrf ne "NC") && ($atra ne "NC")) { 
					if (limpa_atrs(\$atrf,\$atra)) {
						if (exists($atributos{$atrf}{$basea.'/'.$catega.'/'.$atra})) {
							$atributos{$atrf}{$basea.'/'.$catega.'/'.$atra} += $freq;
						}
						else { $atributos{$atrf}{$basea.'/'.$catega.'/'.$atra} = $freq; }
					}
				}
			}
			@fontes = keys %atributos;
			if ($#fontes == 0) { 
				@alvos = keys %{$atributos{$fontes[0]}};
				if ($#alvos == 0) {
					@{$$lexbil{$fonte}{$sent}} = ($fontes[0].'/'.$alvos[0].'/'.$atributos{$fontes[0]}{$alvos[0]});
				}
			}
		}
	}
	Auxiliares::mensagem("OK\n");
}

#**************************************************************************************************
#                                     TRATAMENTO DE GD E ND
#**************************************************************************************************
sub a_determinar {
	my($sent,$opcoes,$atrs) = @_;
	my(@saida,$atrf,$basea,$catega,$atra,$freq,$enu,$gen,$det);

	@saida = ();
	while ($#$opcoes >= 0) {
		$atrf = $basea = $catega = $atra = $freq = "";
		if ($$opcoes[0] =~ /^(.*)\/(.*)\/(.*)\/(.*)\/(.*)$/) {
			$atrf = $1; $basea = $2; $catega = $3; $atra = $4; $freq = $5;
		}
		shift(@$opcoes);
		$gen = $$atrs[$#$atrs-1];
		$det = $$atrs[$#$atrs];
		$enu = quotemeta(join("|",map($$atrs[$_],0..$#$atrs-2)));
		if (($atra =~ /<$gen>/) && ($atrf =~ /<$enu>/) && (($sent eq "RL") || ($sent eq ""))) {
			push(@saida,"LR!".$atrf.'/'.$basea.'/'.$catega.'/'.$atra.'/'.$freq);
			$atrf =~ s/$enu/$det/;
			push(@saida,"RL!".$atrf.'/'.$basea.'/'.$catega.'/'.$atra.'/'.$freq);
		}
		elsif (($atrf =~ /<$gen>/) && ($atra =~ /<$enu>/) && (($sent eq "LR") || ($sent eq ""))) {
			push(@saida,"RL!".$atrf.'/'.$basea.'/'.$catega.'/'.$atra.'/'.$freq);
			$atra =~ s/$enu/$det/;
			push(@saida,"LR!".$atrf.'/'.$basea.'/'.$catega.'/'.$atra.'/'.$freq);
		}
	}
	@$opcoes = @saida;
}

sub trata_gd_nd {
	my($lex,$atrs) = @_;
	my(@fontes,$fonte,@aux,@sents,$i,$s,$sent,$info,$gen,$enu);

	Auxiliares::mensagem("\tDealing with gender and number to be defined ... ");
	@fontes = keys %$lex;
	while ($#fontes >= 0) {
		$fonte = shift(@fontes);
		@sents = keys %{$$lex{$fonte}};
		for($s=0;$s <= $#sents;$s++) {
			for($i=0;$i <= $#$atrs;$i++) {
				$gen = $$atrs[$i][$#{$$atrs[$i]}-1];
				$enu = quotemeta(join("|",map($$atrs[$i][$_],0..$#{$$atrs[$i]}-2)));		
				@aux = grep(/<$gen>/,@{$$lex{$fonte}{$sents[$s]}});
				@aux = grep(/<$enu>/,@aux);
				# Se houver entrada com valor generalizado e geral entao deve-se tratar o genero/numero a determinar
				if (($#aux >= 0) && (($sents[$s] ne "") || ($#sents == 0))) {
					a_determinar($sents[$s],\@aux,$$atrs[$i]);
					if ($#aux >= 0) {
						while ($#aux >= 0) {
							($sent,$info) = split(/!/,shift(@aux));
							push(@{$$lex{$fonte}{$sent}},$info);
						}
						if ($sents[$s] eq "") {	delete($$lex{$fonte}{$sents[$s]}); }
						if ($i < $#$atrs) {
							@sents = keys %{$$lex{$fonte}};
							$s = 0;
						}
					}
				}			
			}
		}
	}
	Auxiliares::mensagem("OK\n");
}

#**************************************************************************************************
#                                     IMPRESSAO NO FORMATO DO APERTIUM
#**************************************************************************************************
sub formata_atrs {
	my($atrs) = @_;
	
	if ($atrs eq "NC") { return ""; }
	$atrs =~ s/<([^>]+)>/<s n="$1"\/>/g; #/
	return $atrs;
}

sub formata_info {
	my($b,$c,$a) = @_;
	my($str);
	
	$str = $b;
	$str .= ($c ne "NC") ? "<s n=".'"'.$c.'"'."/>" : "";
	$str .= defined($a) ? formata_atrs($a) : "";
	return $str;
}

sub multipalavra_tipo2 {
	my($bases,$categs,$atrs) = @_;
	my($i,$saida);
	
	$saida = "";
	$i = 0;
	# Substitui + por <j/> entre cada base<categ><atrs> da concatenacao	
	while ($i < $#$bases) { $saida .= formata_info($$bases[$i],$$categs[$i],$$atrs[$i])."<j/>"; $i++;}
	if ($i == $#$bases) { $saida .= formata_info($$bases[$i],$$categs[$i],$$atrs[$i]); }
	return $saida;
}

sub multipalavra_tipo3 {
	my($bases,$categs) = @_;
	my($i,$saida,$categ);
	
	$saida = "";
	$i = 0;
	# Substitui + por <b/> copiando apenas as bases (sem categ) ate encontrar o verbo
	while (($i <= $#$bases) && ($$categs[$i] !~ /^v.+/)) { $saida .= $$bases[$i++]."<b/>"; }
	$saida .= $$bases[$i]."<g><b/>"; # Copia a base do verbo seguida de <g><b/>
	$categ = $$categs[$i++]; # Guarda apenas a categoria do verbo
	# Copia todas as outras bases separadas por <b/>
	while ($i <= $#$bases) { $saida .= $$bases[$i++]."<b/>"; }
	# Fecha com </g>	
	$saida .= "</g>"."<s n=".'"'.$categ.'"'."/>";
	return $saida;
}

sub trata_multipalavra {
	my($base,$categ,$atr,$tipo) = @_;
	my(@bases,@categs,@atrs,$saida);
	
	@bases = split(/\+/,$base);
	@categs = split(/\+/,$categ);
	@atrs = split(/\+/,$atr);
	$saida = "";
	if ($categs[0] =~ /^v.+/) { # se a multipalavra comeca com verbo (vbser, vbhaver, vblex ou vbmod, etiquetador Felipe)
		# a multipalavra eh do tipo 2, pois trata-se de pronome enclitico a um verbo
		if ($categs[1] eq "prn") { 
			$saida = multipalavra_tipo2(\@bases,\@categs,\@atrs); 
			$$tipo = 2;
		} 
		else { # multipalavra do tipo 3, com flexao intercalada		
			$saida = multipalavra_tipo3(\@bases,\@categs); 
			$$tipo = 3;
		} 
	} 
	else { # eh do tipo 2, multipalavra composta
		$saida = multipalavra_tipo2(\@bases,\@categs,\@atrs); 
		$$tipo = 2;
	} 
	return $saida;
}

sub imprime_lexico_bilingue {
	my($arq,$cab,$rod,$lexbil) = @_;
	my($fonte,@sents,@chaves,$basef,$basea,$categf,$catega,$atrf,$atra,$sent,$freq,$strf,$stra,$tipo);
	
	Auxiliares::mensagem("\tPrinting bilingual dictionary ... ");	
	
	open(ARQ,">$arq") or Auxiliares::erro_abertura_arquivo($arq); 

	# Imprime cabecalho (o mesmo do arquivo do lexico bilingue pt-es de Apertium versao 0.9 (05/05/2006))
	open(CAB,"$cab") or Auxiliares::erro_abertura_arquivo($cab); 
	print ARQ <CAB>;
	close CAB;

	@chaves = sort {$a cmp $b} keys %$lexbil;
	while ($#chaves >= 0) {
		$fonte = shift(@chaves);
		$basef = $categf = "";
		if ($fonte =~ /^(.*)\/(.*)$/) {
			$basef = $1; $categf = $2;
		}
		@sents = keys %{$$lexbil{$fonte}};
		while ($#sents >= 0) { # imprime cada um dos sentidos
			$sent = shift(@sents);
			while ($#{$$lexbil{$fonte}{$sent}} >= 0) { # imprime cada uma das opcoes de atributos
				$atrf = $basea = $catega = $atra = $freq = "";
				if (${$$lexbil{$fonte}{$sent}}[0] =~ /^(.*)\/(.*)\/(.*)\/(.*)\/(.*)$/) {
					$atrf = $1; $basea = $2; $catega = $3; $atra = $4; $freq = $5;
				}
				shift(@{$$lexbil{$fonte}{$sent}});
				if (($basef =~ /[a-zA-Z]/) && ($basea =~ /[a-zA-Z]/)) {
					$strf = $stra = "";
					$tipo = 0;
					if ($basef =~ /\+/) { $strf = trata_multipalavra($basef,$categf,$atrf,\$tipo); }
					if ($basea =~ /\+/) { $stra = trata_multipalavra($basea,$catega,$atra,\$tipo); }
					if ($strf eq "") { 
						if (($tipo == 3) && ($categf =~ /^v.+/)) { $strf = formata_info($basef,$categf,"NC"); }
						else { $strf = formata_info($basef,$categf,$atrf); }
					}
					if ($stra eq "") {
						if (($tipo == 3) && ($catega =~ /^v.+/)) { $stra = formata_info($basea,$catega,"NC"); }
						else { $stra = formata_info($basea,$catega,$atra); }
					}
					$strf =~ s/\_/<b\/>/g;
					$stra =~ s/\_/<b\/>/g;
					print ARQ "\n\t<e";
					if ($sent ne "") { print ARQ ' r="',$sent,'"'; }
					print ARQ ">\n";
					if ($strf eq $stra) { print ARQ "\t\t<i>$strf</i>\n"; }
					else { print ARQ "\t\t<p>\n\t\t\t<l>$strf</l>\n\t\t\t<r>$stra</r>\n\t\t</p>\n"; }
					print ARQ "\t</e>";
				}
			}
		}
	}
	open(ROD,"$rod") or Auxiliares::erro_abertura_arquivo($rod);
	print ARQ <ROD>;
	close ROD;
	close ARQ;
	Auxiliares::mensagem("OK\n");
}

1;
__END__
