# DESCRIPTION

ReTraTos package is composed of two bilingual resources induction programs:
* ReTraTos.pl: induces rules from corpora
* ReTraTos_lex.pl: induces bilingual dictionaries from corpora

At the moment there is no engine (in this package) to perform translation based
on the induced resources.

# INPUT FORMAT

Two parallel texts are used as input for both inductors. In this text each sentence
has to be tagged with initial `<s>` and final `</s>` tags. The initial sentence
tag `<s>` has an attribute (snum) whose value is an identificator for this
sentence. Parallel sentences have the same identificator in source and target files.

Example:

Source sentence
```
<s snum=1>sourcetoken1 sourcetoken2 ... sourcetokenn</s>
```

Target sentence (translation of source sentence identified as 1)
```
<s snum=1>targettoken1 targettoken2 ... targettokenn</s>
```

Each token in each sentence has to be separated by a white space as show above.
Each token can have at most 5 pieces of information:

1. sur: the surface form of a word or a special character, that is,
   the token as it was found in the original sentences. For example:
   houses, living and .

2. bas: the lemma of a word or a special character, a number, etc.
   when it was tagged by the PoS tagger. For example: house, live and
   .

3. pos: PoS of lexical item according to the PoS tagger. The words
   unknown by the tagger (not tagged) and many special characters do
   not have this information. For example: n (noun), vblex (verb) or
   nothing.

4. atr: the value of each morphological attribute of a PoS tag. Each
   attribute value has to be between `<` and `>`. For example: <pl>
   (plural), <ger> (gerund).

5. ali: a sequence of one or more numbers (separated by `_`) refering
   to the positions of aligned items in the parallel sentences. For
   example: 14, 3, 7_8, 0.

This information is derived from preprocessing the parallel texts with at
least 2 tools: a PoS tagger (bas, pos and atr) and a lexical aligner (ali).

  The tokens are formated as shown below:

  1. `\*sup/sup:ali`
     Unknown words. For example: `*piquia/piquia:4`
  2. `sup:ali`
     Special characters not tagged by the PoS tagger. For example: `":27`
  3. `sup/C[\+C]*:ali`
     Other words and special characters tagged by the PoS tagger, in which
     `C = base<pos>A* e`
     `A = [attribute]+`
     For example: houses/house<n><pl>:14, living/live<vblex><ger>:3,
     cannot/can<vaux><pres>+not<adv>:7_8, ,/,<cm>:25

Example of input parallel sentences:

Portuguese
```
<s snum=1>Os/O<det><def><m><pl>:1 alunos/aluno<n><m><pl>:2 do/de<pr>+o<det><def><m><sg>:3_4 mais/mais<adv>:5 antigo/antigo<adj><m><sg>:5 colégio/colégio<n><m><sg>:6 de/de<pr>:7 São_Paulo/São_Paulo<np><loc>:8_9 </s>
```

English
```
<s snum=1>The/The<det><def><sp>:1 students/student<n><pl>:2 of/of<pr>:3 the/the<det><def><sp>:3 oldest/old<adj><sint><sup>:4_5 school/school<n><pl>:6 of/of<pr>:7 *São/São:8 *Paulo/Paulo:8 </s>
```


# OUTPUT FORMAT

* Bilingual dictionaries are in a XML format very similiar to that used by
  Apertium open-source machine translation platform (http://apertium.sourceforge.net/)

* Transfer rules are in a human readable format and a new module are being
  developed to put them in the Apertium's XML format

# REQUIREMENTS

* ReTraTos needs Perl installed in the system, along with the following Perl
  modules: Getopt::Long; Pod::Usage; IO::Handle

# QUICK START

1) Download the package for retratos-VERSION.tar.gz

2) Unpack retratos and do ('#' means 'do that with root privileges'):

```
$ cd retratos-VERSION
$ ./configure
$ make
# make install
```

3) Use the dictionary inductor (ReTraTos_lex.pl)

```
USAGE: perl ReTraTos_lex -s sourcefile -t targetfile -b headerfile -e footerfile [-a attfile] [-f freqmwu]
 -sourcefile|s sourcefile    file with examples in source language (required)
 -targetfile|t targetfile    file with examples in target language (required)
 -beginning|b  headerfile    file with the beginning of a bilingual dictionary (required)
 -ending|e     footerfile    file with the ending of a bilingual dictionary (required)
 -attrsfile|a  attfile       file with information about atributes (optional)
 -multifreq|f  freqmwu       frequency threshold to filter multiword units (default=1)
```

   Sample:

```
   $ perl ReTraTos_lex -s test/pt.txt -t test/en.txt -b test/dic_header.txt -e test/dic_footer.txt -f 50
```

4) Use the rule inductor (ReTraTos.pl)

```
USAGE: perl ReTraTos_rules -s sourcefile -t targetfile [-ty type] [-l level] [-ig inpos] [-eg outpos] [-pi percident] [-fi] [-pf percfilt] [-so] [-r] [-v]
 -sourcefile|s sourcefile  file with examples in source language (required)
 -targetfile|t targetfile  file with examples in target language (required)
 -type|ty      type        alignment type: 0, 1, 2 or 3 (all) (default=3)
 -level|l      level       abstraction level(s) of rules (default=pos)
 -include_gra|ig inpos     PoS for which induce rules (default=all)
 -exclude_gra|eg outpos    PoS for which do not induce rules (default=none)
 -per_ident|pi percident   % for frequency threshold on pattern ident. (df=0.0015)
 -filter|fi                determines if filter will be applied (default=no)
 -per_filter|pf percfilt   % for frequency threshold on rule filtering (df=0.0015)
 -sort|so                  determines if sorting will be done (default=no)
 -remove|r                 remove auxiliary files
 -verbose|v                verbose
```

Sample:

```
   $ perl ReTraTos_rules -s test/pt.txt -t test/en.txt -f 0.0007 -eg cm -fi -so
```

# SEE ALSO

* https://wiki.apertium.org/wiki/ReTraTos
* http://www.nilc.icmc.usp.br/nilc/projects/retratos.htm
