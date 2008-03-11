package Auxiliares;

# 21/03/2007 (nova rotina pertence, agora com hash e lc no mapeia_valores para itens
# lematizados)
# 31/01/2007 (insercao de subrotinas para tratamento de erros)
# 31/08/2006

use 5.006;
use strict;
use warnings;
no warnings qw(redefine);
use locale;

#***********************************  ERROS   ************************************
sub verifica_arquivo {
	my($arq) = @_;

	open(ARQ,$arq) or mensagem("ERRO: Impossivel abrir o arquivo $arq\n");
	close ARQ;
}

#***********************************  GERAIS  ************************************
sub mensagem {
	my($msg) = @_;

	print STDERR $msg;
}

sub mensagem_erro {
	my($msg) = @_;

	print STDERR $msg;
	exit 1; 
}

sub imprime_hora {
	my($s,$m,$h,$resto) = localtime(time);
	
	return "$h:$m:$s";
}

sub maior {
	my(@array) = @_;
	my(@aux);
	@aux = sort{int($b) <=> int($a)} @array;
	return $aux[0];
}

sub menor {
	my(@array) = @_;
	my(@aux);
	@aux = sort{int($a) <=> int($b)} @array;
	return $aux[0];
}

sub nome {
	my($arq) = @_;
  
	my(@aux,$c);
	$arq =~ s/\\/\//g;
	@aux = split(/\//,$arq);
	$arq = pop(@aux);
	if ($arq =~ /\./) { do { $c = chop($arq); }  until ($c eq '.'); }
	return $arq;
}

sub char {
	my($c) = @_;	
	if ($c =~ /^[\\\/\"\!\¡\(\)\{\}\[\]\?\¿\:\;\º\°\ª\@\$\%\&\=\+\-\~\>\*\«\»\'\`\·\#\|\,\.]$/) { return 1; }
	return 0;
}

sub tokens_to_posicao {
	my($parte,$todo,$ngram) = @_;
	my(@posicoes,$pos,$j,$i);

	@posicoes = ();
	$j = $i = 0;
	while (($j <= $#$parte) && ($i <= $#$todo)) {
		$pos = posicao($$parte[$j],$todo,$i);
		if ($pos == -1) { push(@posicoes,-1); }
		else {
			if (($ngram) && ($#posicoes >= 0) && (abs($posicoes[$#posicoes] - $pos) > 1)) { 
				$j = -1;
				$i = ($posicoes[0] != -1) ? $posicoes[0]+1 : $pos+1;
				@posicoes = ();
			}
			else {
				$i = $pos+1;
				push(@posicoes,$pos);
			}
		}
		$j++;
	}
	@$parte = @posicoes;
}

#***********************************  ARRAYS  ************************************
sub pertence {
	my($elemento,$array) = @_;
	my(%aux) = ();
	map($aux{$_}=0,@$array);
	return defined($aux{$elemento});
}

sub posicao {
	my($elemento,$array,$offset) = @_;	
	my($i) = $offset;
	
	while (($i <= $#$array) && ($elemento ne $$array[$i])) { $i++; }
	if ($i > $#$array) { return -1;}
	return $i;
}

sub posicao_diferente {
	my($array1,$array2,$offset) = @_;
	
	while (($offset <= $#$array1) && ($offset <= $#$array2)) {
		if ($$array1[$offset] ne $$array2[$offset]) { return $offset; }
		$offset++;
	}
	return -1;
}

sub array_igual {
	my($array1,$array2) = @_;
	
	return join(" ",@$array1) eq join(" ",@$array2);
}

sub insere_array {
	my($elemento,$array) = @_;
	
	if (pertence($elemento,$array) == 0) { push(@$array,$elemento); }	
}

sub insere_exemplo {
	my($infoexe,$array) = @_;
	my(@aux) = map($$_[0].'|'.join(",",@{$$_[1]}).'|'.join(",",@{$$_[2]}),@$array);
	
	if (Auxiliares::pertence($$infoexe[0].'|'.join(",",@{$$infoexe[1]}).'|'.join(",",@{$$infoexe[2]}),\@aux) == 0) { push(@$array,$infoexe); }
}

sub remove_array {
	my($elemento,$array) = @_;
	
	@$array = grep(defined($_),@$array);
	my($pos) = posicao($elemento,$array,0);
	if ($pos != -1) { delete($$array[$pos]); }	
	@$array = grep(defined($_),@$array);
}

sub remove_repetidos {
	my($array) = @_;
	my(@saida) = ();
	
	map((pertence($_,\@saida) == 0) ? push(@saida,$_) : (),@$array);
	@$array = @saida;
}

sub consecutivos {
	my($array) = @_;
	my($i);
	
	for($i=1;$i <= $#$array;$i++) {
		if ($$array[$i] > $$array[$i-1]+1) { return 0; }
	}
	return 1;
}

sub converte_stratr_arrays {
	my($atr) = @_;
	my(@aux,@arrayatr);
	
	@aux = split(/\//,$atr);
	map(s/NC/<NC>/g,@aux);
	map(s/<//g,@aux);
	map(s/>$//g,@aux);
	@arrayatr = ();
	map(push(@arrayatr,[split(/>/,$_)]),@aux);
	return @arrayatr;
}

#***************************************** MAPEAMENTO ***********************************
sub mapeia_valor {
	my($exemplos,$indexe,$pos,$campo,$icategs) = @_;
	my(@aux,@campos,$str);
	
	@campos = split(/\,/,$campo);
	if ($pos < 0) {
		die "(ERRO: Auxiliares::mapeia_valor) Tenta imprimir algo que nao deveria\n"; 
		return "_"; 
	}
	@aux = split(/\,/,$icategs);
	# imprime tb o valor lexical das categorias presentes em $icategs e mapeia todos os campos
	$str = join(":",map(${$$exemplos[$indexe]}{$_}[$pos],@campos));
	if ((pertence('lex',\@campos) == 0) && (pertence(${$$exemplos[$indexe]}{'pos'}[$pos],\@aux))) { 
		$str = lc(${$$exemplos[$indexe]}{'lex'}[$pos]).":".$str; # 21/03/2007 lc nos itens lematizados
	}
	return $str; 
}

#****************************************** FILTRO **************************************
sub filtra_categorias_gramaticais {
  my($itens,$categs,$acao) = @_;
  my(@aux,@aitens,@acategs);
	
	@aitens = split(/ /,$itens);
	map(s/^[^\:]+\:([^\:]+).*$/$1/,@aitens);
	@acategs = split(/\,/,$categs);
	@aux = grep(pertence($_,\@aitens),@acategs);
	# se o bloco contem pelo menos uma das categorias em $categs e a acao eh inclusao OU
	# se o bloco nao contem nenhuma das categorias em $categs e a acao eh exclusao
	# retorna 1
	if ((($#aux >= 0) && $acao) || (($#aux < 0) && ($acao == 0))) { return 1; } 
	return 0;
}

1;
__END__
