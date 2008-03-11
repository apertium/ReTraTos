package Identifica;

# 31/08/2006 (mudanca nas rotinas padroes_monolingues, padroes_bilingues e le_padroes_bili)
# 29/08/2006 (alinhamentos sao salvos como string e nao mais como array)
# 02/08/2006 (otimizacoes no codigo: $janela em padroes_monolingues, imprime_blocos e le_padroes; remocao de mapeia_bloco)

use 5.006;
use strict;
use warnings;
use locale;
use Auxiliares;

#*****************************************************************************************************
#                                     IDENTIFICACAO DE PADROES MONOLINGUES
#*****************************************************************************************************
sub padroes_monolingues {
	my($entrada,$icategs,$ecategs,$freq,$min,$max,$saida) = @_;

	# Identifica padroes que ocorrem no minimo $freq vezes e tem tamanho entre $min e $max itens
	system("perl identifica_padroes.pl -a $entrada -f $freq -mi $min -ma $max > $saida");
	
	if (($icategs ne '') || ($ecategs ne '')) {
		$entrada = $saida.'_temp';
		system("mv $saida $entrada"); # So no linux
#		$entrada = 'ReTraTos_pt_lemas_lihla_1000Xes_lemas_lihla_1000_0.0015_pos_0_+pr_temp.txt';
		imprime_padroes_filtrados($entrada,$icategs,$ecategs,$saida);
		system("rm $entrada"); # So no linux
	}
}

#*****************************************************************************************************
#                                     IDENTIFICACAO DE PADROES BILINGUES
#*****************************************************************************************************
sub padroes_bilingues {	
	my($campo,$tipo,$icategs,$freq,$padfonte,$exefonte,$exealvo,$saida) = @_;
	my($partefonte,$exemplos,$indexe,$posicoesfonte,@posicoesalvo,$partealvo);
	my(@padroesalvo,%candidatos,@alinhamento,@ordenadas,$chave,@fontes,@aux,$alinhamentos);
	
	@fontes = sort {lc($a) cmp lc($b)} keys %$padfonte;
	open(ARQ,">$saida") or die "Nao eh possivel abrir o arquivo $saida\n";	
	while($#fontes >= 0) { # cada padrao fonte
		$partefonte = shift(@fontes);
		%candidatos = ();
		while ($#{$$padfonte{$partefonte}} >= 0) { # para cada ocorrencia desse padrao fonte
			($indexe,$posicoesfonte) = @{shift(@{$$padfonte{$partefonte}})};
			@posicoesalvo = map(${$$exefonte[$indexe]}{'ali'}[$_],@$posicoesfonte);
			# aplica um filtro relativo ao tipo de padrao sendo gerado
			if ((($tipo == 2) && filtra_tipo2(\@posicoesalvo)) || 
				 (($tipo == 1) && filtra_tipo1(\@posicoesalvo)) ||
			    (($tipo == 0) && filtra_tipo0(\@posicoesalvo))) {
				# poe as posicoes alvo em ordem crescente
				@ordenadas = sort {int($a) <=> int($b)} map($_-1,map(split(/\_/,$_),@posicoesalvo));
				Auxiliares::remove_repetidos(\@ordenadas);
				# Por enquanto nao se permite alinhamentos com GAP 
				if (($ordenadas[0] == -1) && ($tipo == 0)) { shift(@ordenadas); }
				if (($#ordenadas >= 0) && ($ordenadas[0] != -1) && 
						(Auxiliares::consecutivos(\@ordenadas) == 1)) {
					@alinhamento = map($_ =~ /\_/ ? join("_",map(Auxiliares::posicao($_-1,\@ordenadas,0),split(/\_/))) : Auxiliares::posicao($_-1,\@ordenadas,0),@posicoesalvo);
					$partealvo = join(" ",map(Auxiliares::mapeia_valor($exealvo,$indexe,$_,$campo,$icategs),@ordenadas));				
					# armazena em candidatos o indice desse exemplo e as posicoes do tokens fonte 
					# (que formam o padrao) e alvo (alinhados com os tokens fonte)
					$chave = $partealvo.'/'.join("&",@alinhamento);
					@aux = ($indexe,$posicoesfonte,[@ordenadas]);
					push(@{$candidatos{$chave}},[@aux]);
				}
			}
		}
		@padroesalvo = map($#{$candidatos{$_}} >= $freq ? [split('/',$_),$candidatos{$_}] : (),keys %candidatos);
		# $padroesalvo[n] = (parte_alvo,alinhamentos,@exemplos)
		while ($#padroesalvo >= 0) {		
			($partealvo,$alinhamentos,$exemplos) = @{shift(@padroesalvo)};
			print ARQ $partefonte,"=>",$partealvo,"\n",$alinhamentos,"\n";
			imprime_exemplos(\*ARQ,$exemplos,$exefonte,$exealvo);
			print ARQ "\n";
		}
	}
	close ARQ;
}

#*****************************************************************************************************
#                                       FILTRAGEM POR TIPOS
#*****************************************************************************************************
sub filtra_tipo2 {
	my($posicoes) = @_;
	my(@aux,@ord);
	
	@aux = map($_ =~ /\_/ ? Auxiliares::maior(split(/\_/,$_)) : $_,@$posicoes);
	@aux = grep($_ > 0,@aux);
	@ord = sort {int($a) <=> int($b)} @aux;
	if (join(",",@ord) ne join(",",@aux)) { return 1; } # se $posicoes nao sao crescentes: tipo 2
	return 0;
}

sub filtra_tipo1 {
	my($posicoes) = @_;
	my(@aux,@ord);
	
	@aux = map($_ =~ /\_/ ? Auxiliares::maior(split(/\_/,$_)) : $_,@$posicoes);
	@aux = grep($_ > 0,@aux);
	@ord = sort {int($a) <=> int($b)} @aux;
	if (join(",",@ord) eq join(",",@aux)) { return 1; } # se $posicoes esta em ordem crescente: tipo 1
	return 0;
}

sub filtra_tipo0 {
	my($posicoes) = @_;
	my(@aux);
	
	@aux = map($_ =~ /\_/ ? Auxiliares::menor(split(/\_/,$_)) : $_,@$posicoes);
	@aux = grep($_ == 0,@aux);
	return ($#aux >= 0);
}

#*****************************************************************************************************
#                                     			ENTRADA/SAIDA
#*****************************************************************************************************
sub imprime_padroes_filtrados {
	my($entrada,$icategs,$ecategs,$saida) = @_;
	my($n,$padrao,$aux);
	
	$n = 0;
	open(IN,$entrada) or die "Nao eh possivel abrir o arquivo $entrada\n";
	open(OUT,">$saida") or die "Nao eh possivel abrir o arquivo $saida\n";
	while (<IN>) {
		if (/<pattern>/) { $aux = "<pattern>\n"; }
		elsif (/<what>(.+)<\/what>/) { 
			$padrao = $1;
			if ((($icategs eq '') || Auxiliares::filtra_categorias_gramaticais($padrao,$icategs,1)) &&
					(($ecategs eq '') || Auxiliares::filtra_categorias_gramaticais($padrao,$ecategs,0))) { 
				print OUT $aux,"<what>$padrao<\/what>\n";
				$n++;
				$_ = <IN>;
				while ($_ !~ /<\/pattern>/) { 
					print OUT $_; 
					$_ = <IN>;
				}
				print OUT $_;
			}
		}
		else { $aux .= $_; }
	}	
	close IN;
	close OUT;
	return $n;
}

sub le_padroes_mono {
	my($arq,$blocos,$exemplos,$icategs,$campo,$ngram,$padroes) = @_;
	my($padrao,@saida,@ids,$exe,$ini,$fim,@pospad,@aux,$qtd,$offset,$id,@tokens);
	
	$qtd = 0;
	open(ARQ,$arq) or die "Nao eh possivel abrir o arquivo $arq\n";
	while (<ARQ>) {
		if (/<what>(.+)<\/what>/) { 
			$padrao = $1;
			@tokens = split(/ /,$padrao);
			@saida = ();
			$_ = <ARQ>;
			if (/<where>(.+)<\/where>/) { @ids = split(/ /,$1); }
			while ($#ids >= 0) {
				$id = shift(@ids);
				$exe = $$blocos[$id-1][0]; # 02/08
				($ini,$fim) = @{$$blocos[$id-1][1]}; # 02/08
				@aux = map(Auxiliares::mapeia_valor($exemplos,$exe,$_,$campo,$icategs),($ini .. $fim));
				while ($#aux >= 0) { # o padrao pode ocorrer mais de uma vez em um bloco
					@pospad = @tokens;
					Auxiliares::tokens_to_posicao(\@pospad,\@aux,$ngram);
					@pospad = grep($_ >= 0,@pospad);
					if ($#tokens == $#pospad) {
						splice(@aux,0,$pospad[0]+1);
						$offset = $pospad[0]+1;
						map($_ = $ini+$_,@pospad);
						push(@saida,[$exe,[@pospad]]);
						$ini += $offset;
						# verifica se ha outra ocorrencia desse padrao nessa linha
						if (($#ids >= 0) && ($ids[0] != $id)) { @aux = (); } 
						else { shift(@ids); }
					}
					else { @aux = (); }
				}									
			}
			$$padroes{$padrao} = [@saida];
			$qtd++;
		}
	}
	close ARQ;
	return $qtd;
}

sub le_padroes_bili { # 31/08
	my($arq,$padroes) = @_;
	my($qtd,$partefonte,$partealvo,$alinhamentos,@exemplos,$id,@posfonte,@posalvo);

	$qtd = 0;
	open(ARQ,$arq) or die "Nao eh possivel abrir o arquivo $arq\n";
	while (<ARQ>) {
		if (/(.+)=>(.+)/) { 
			$partefonte = $1;
			$partealvo = $2;
			$partealvo =~ s/\n//g;
			$alinhamentos = <ARQ>;
			$alinhamentos =~ s/\n//g;			
			@exemplos = ();
			$_ = <ARQ>;
			while (/^Exemplo (\d+): (.+)=>(.+)\n/) {
				$id = $1-1;
				@posfonte = split(/ /,$2);
				@posalvo = split(/ /,$3);
				map(s/\[(\d+)\].+/$1/,@posfonte);
				map(s/\[(\d+)\].+/$1/,@posalvo);
				map($_ = $_-1,@posfonte);
				map($_ = $_-1,@posalvo);
				push(@exemplos,[$id,[@posfonte],[@posalvo]]);
				$_ = <ARQ>;
			}
			push(@{$$padroes{$partefonte}},[$partealvo,$alinhamentos,[@exemplos]]);
			$qtd++;
		}
	}
	close ARQ;
	return $qtd;
}

sub info {
	my($elemento,$exemplo) = @_;
	my($str,@aux,@itens,@categs,@atrs,$i);
	
	if ($elemento == -1) { return 'NULL'; }
	@itens = split(/\+/,$$exemplo{'lex'}[$elemento]);
	@categs = split(/\+/,$$exemplo{'pos'}[$elemento]);
	@atrs = split(/\+/,$$exemplo{'atr'}[$elemento]);
	$str = '['.($elemento+1).']:';
	for($i=0;$i <= $#itens;$i++) {
		$str .= $itens[$i];	
		if ($categs[$i] ne 'NC') { 
			$str .= '<'.$categs[$i].'>';
			if ($atrs[$i] ne 'NC') { $str .= $atrs[$i]; }
		}
		$str .= '+';
	}
	chop $str;
	if (defined($$exemplo{'ali'})) { $str .= ':'.$$exemplo{'ali'}[$elemento]; }
	return $str;
}

sub imprime_exemplos {
	my($fh,$exemplos,$exef,$exea) = @_;
	my($idexe,@posicoes,@tokens,$ant,$pos,$dist);
	
	while ($#$exemplos >= 0) {
		($idexe,@posicoes) = @{shift(@$exemplos)};
		@tokens = map(info($_,\%{$$exef[$idexe]}),@{shift(@posicoes)});
		print $fh "Exemplo ",$idexe+1,": ",join(" ",@tokens),"=>";
		@posicoes = @{shift(@posicoes)};				
		$ant = -1;
		while ($#posicoes >= 0) {
			$pos = shift(@posicoes);
			if ($ant >= 0) { # Imprime gaps entre posicoes
				$dist = abs($pos-$ant)-1;
				if ($dist > 0) { print $fh "_($dist) "; }
			}
			print $fh info($pos,\%{$$exea[$idexe]})," ";
			$ant = $pos;
		}
		print $fh "\n";
	}			
}

1;
__END__
