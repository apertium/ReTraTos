package Entrada;

# 19/04/2006

use 5.006;
use strict;
use warnings;
use locale;

sub le_exemplos {    
	my($arq,$exe) = @_;
	my(%sent,$cont);
	
	print "\tLendo exemplos ... ";
	open(ARQ,$arq) or die "Nao eh possivel abrir o arquivo $arq\n";	
	$cont = 0;
	while (<ARQ>) {
			if (/^<s snum=(\d+)>(.+)<\/s>$/) { 
				%sent = le_sentenca($2,$1);
				push @$exe,{ %sent };
				$cont++;
			}
			else { die "ERRO (ReTraTos_IO:le_exemplos): Formato errado em $_\n"; }
	}  
	close ARQ;
	print " $cont exemplos lidos\n";
}

sub le_sentenca {
	my($sent,$id) = @_;	
	my(@tokens,@aux,$sup,$str,$alinhamento,$token,$atributos,$etiquetas,$t,$atr,$et,%hashsent);
	
	%hashsent = ();
	@tokens = split(/ /,$sent);
	while ($#tokens >= 0) {
# 1. Separa os tokens da sentenca em: forma superficial, item lexical, etiqueta de POS, atributos da etiqueta e alinhamento
		$_ = shift(@tokens);
		($str,$alinhamento) = /^(.+):(.+)$/;
		if (!defined($str)) { die "ERRO (ReTraTos_IO:le_sentenca): Formato errado em sentenca $id, token $_\n"; }
		if ($str =~ /^(.+)\/(.+)$/) {
			$sup = $1; $str = $2;
		}
		else { $sup = $str; }
		if ($sup ne '+') {
			$str =~ s/\>_/>+_/g;
			@aux = split(/\+/,$str);
		}
		else { @aux = ($str); }
		$token = $etiquetas = $atributos = "";
		while ($#aux >= 0) {
			$_ = shift(@aux);
			$t = $et = $atr = '';
			if (/^\*(.+)$/) { $t = $1; }			# palavra desconhecida
			elsif (/^([^<]+)$/) { $t = $1; }	# token nao etiquetado
			elsif (/^([^<]*)\<([^>]+)\>(\<.+\>)*(.*)\*([^<]*)$/) { ($t,$et,$atr) = ($1.$4.$5,$2,$3); }		
			elsif (/^([^<]*)\<([^>]+)\>(\<.+\>)*([^<]*)$/) { ($t,$et,$atr) = ($1.$4,$2,$3); }
			elsif (/^([^<]*)\<([^>]+)\>(\<.+\>)*(.*)\*(.+)$/) { 
				($t,$et,$atr) = ($1,$2,$3); 
				$t .= $4.$5;
			}
			elsif (/^(.+)<num>,<cm>(.+)<num>$/) { ($t,$et) = ("$1,$2","num"); }
			elsif (/^(.+)<num>\.<sent>(.+)<num>$/) { ($t,$et) = ("$1.$2","num"); }
			elsif (/^(.+)<num>(.)(\d+)<num>$/) { ($t,$et) = ("$1$2$3","num"); }
			elsif (/^(\d+)<num>h(\<.+\>)*(\d+)<num>$/) { ($t,$et) = ("$1h$3","time"); }
			elsif (/^(\d+)<num>o\<det\>\<def\>(\<.+\>+)$/) { ($t,$et,$atr) = ("$1o","numord",$2); }
			else {	
				print "AVISO (ReTraTos_IO:le_sentenca): String etiquetada errada em $str\n"; 
				1 while s/([^\<]+)<(.+?)>/$1/g;
				$t = $_;
			}
			$t = ($t ne '') ? $t : 'NC';
			$et = ($et ne '') ? $et : 'NC';
			$atr = (defined($atr) && ($atr ne '')) ? $atr : 'NC';
			$etiquetas .= ($etiquetas eq '') ? $et : '+'.$et;
			$atributos .= ($atributos eq '') ? $atr : '+'.$atr;
			$token .= ($token eq '') ? $t : '+'.$t;
		}
# 2. Armazena estas informacoes, para cada token, em um hash (%exemplo).
		push(@{$hashsent{'sup'}},$sup);
		push(@{$hashsent{'lex'}},$token);
		push(@{$hashsent{'pos'}},$etiquetas);
		push(@{$hashsent{'atr'}},$atributos);
		push(@{$hashsent{'ali'}},$alinhamento);
	}
	return %hashsent;
}

1;
__END__
