/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// See <CLASS>%Text.Text</CLASS>
/// <p>
/// The <CLASS>%Text.Portuguese</CLASS> class implements the Portuguese language-specific stemming algorithm
/// and initializes the language-specific list of noise words.</p>
/// 
Class %Text.Portuguese Extends %Text.Text [ System = 4 ]
{

Parameter DICTIONARY = 7;

Parameter SOURCELANGUAGE = "pt";

Parameter NOISEWORDS100 = "de a e em é ele você isso ele era para em seja com como his eles seja em um tenha isto de ou teve por quente palavra mas que alguns nós lata para fora outro eram tudo lá quando acima use seu como dito cada ela qual seu tempo se vontade maneira sobre muitos então eles escreva como assim estes ela longo faça coisa veja ele dois tem olhar mais dia poderia vá vindo número som não maioria povos meu sobre saiba água do que chamada primeiramente quem possa para baixo lado sido agora achado alguns novo trabalho parte tomada";

Parameter NOISEWORDS200 = "comece lugar feito vivo onde seguida parte traseira pouco somente redondo homem ano veio mostra cada bom mim elasticidade nosso sob nome muito através apenas formulário sentença grande pense palavra ajuda baixo linha difira volta causa muito meio antes movimento direita menino velho demasiado mesmos diga jogo três queira ar poço também jogo pequeno extremidade posto home lido mão porto grande período adicione nivele terra aqui obrigação grande elevado tais siga ato porque peça homens mudança foi luz amável fora de necessidade casa retrato tentativa nós outra vez animal ponto mãe mundo perto configuração self terra pai cabeça carrinho para possuir página se país encontrado resposta";

Parameter NOISEWORDS300 = "escola cresça estudo ainda aprenda planta tampa alimento sol quatro entre estado sustento olho nunca último deixado pensamento cidade árvore cruz fazenda duramente começo poder história serra distante mar tração esquerdo tarde funcionamento não quando imprensa fim noite real vida poucos norte aberto pareça junto em seguida branco crianças comece começado caminhada exemplo facilidade papel grupo sempre música aqueles ambos marca frequentemente letra até milha rio carro pés cuidado em segundo livro carregue fêz exame ciência coma quarto amigo começou idéia peixes montanha batente uma vez que base ouça cavalo corte certo relógio cor cara madeira principal bastantes planície menina usual novo apronte acima sempre vermelho lista embora sensação";

ClassMethod removeAllAccents(ByRef b As %String, ByRef k As %Integer)
{
	s b=$tr(b,"äâàáãôöóòõêéèëüúùûïîìíçÀÁÂÃÇÉÊÍÓÕÔÚÜ","aaaaaoooooeeeeuuuuiiiicAAAACEEIOOOUU")
}

/// Remove plural and feminine form of Portuguese words
ClassMethod removePTSuffix(ByRef b As %String, ByRef k As %Integer, ByRef j As %Integer)
{
	if (k>4) && ( (..ends(b, k, 3, "ses", .j)) ||
	              (..ends(b, k, 3, "res", .j)) ||
	              (..ends(b, k, 3, "zes", .j)) ||
	              (..ends(b, k, 3, "les", .j)) ) {
		d ..setto(.b,  "", j+1, .k)
	} elseif ( (k>3) && ..ends(b, k, 2, "ns", .j)) {
		d ..setto(.b, "m", j,   .k) 
	} elseif ( (k>4) && (..ends(b, k, 3, "éis", .j) ||
	                    (..ends(b, k, 3, "eis", .j)))) {
		d ..setto(.b, "el", j, .k)
	} elseif ( (k>4) && (..ends(b, k, 3, "ais", .j))) {
		d ..setto(.b, "al", j, .k)
	} elseif ( (k>4) && (..ends(b, k, 3, "óis", .j))) {
		d ..setto(.b, "ol", j, .k) 
	} elseif ( (k>3) && (..ends(b, k, 2,  "is", .j))) {
		d ..setto(.b, "il", j, .k) 
	} elseif ( (k>4) && (..ends(b, k, 3, "ões", .j))) {
		d ..setto(.b, "ão", j, .k) 
	} elseif ( (k>4) && (..ends(b, k, 3, "ães", .j))) { 
		d ..setto(.b, "ão", j, .k) 
	} elseif ( (k>6) && (..ends(b, k, 5, "mente", .j))) {
		d ..setto(.b, "", j, .k) 
	} elseif ( (k>3) && (..ends(b, k, 1, "s", .j))) {
		d ..setto(.b, "", j, .k) 
	}
	;
}

ClassMethod normFemininePortuguese(ByRef b As %String, ByRef k As %Integer, ByRef j As %Integer)
{
	q:((k<4)||($e(b,k)'="a"))
	if (k>7) {
		if ..ends(b, k, 4, "inha", .j) {
			d ..setto(.b, "inho", j, .k) 
		} elseif ..ends(b, k, 4, "iaca", .j) {
			d ..setto(.b, "iaco", j, .k) 
		} elseif ..ends(b, k, 4, "eira", .j) {
			d ..setto(.b, "eiro", j, .k) 
		}	
	}
	if (k>6) { 
		if ..ends(b, k, 3, "ona", .j) {
			d ..setto(.b, "ão", j, .k)
		} elseif ..ends(b, k, 3, "ora", .j) {
			d ..setto(.b, "or", j, .k) 
		} elseif ..ends(b, k, 3, "osa", .j) { 
			d ..setto(.b, "oso", j, .k) 
		} elseif ..ends(b, k, 3, "esa", .j) {
			d ..setto(.b, "ês", j, .k) 
		} elseif ..ends(b, k, 3, "ica", .j) {
			d ..setto(.b, "ico", j, .k) 
		} elseif ..ends(b, k, 3, "ida", .j) {
			d ..setto(.b, "ido", j, .k) 
		} elseif ..ends(b, k, 3, "ada", .j) { 
			d ..setto(.b, "ado", j, .k) 
		} elseif ..ends(b, k, 3, "iva", .j) { 
			d ..setto(.b, "ivo", j, .k) 
		} elseif ..ends(b, k, 3, "ama", .j) {
			d ..setto(.b, "amo", j, .k) 
		} elseif ..ends(b, k, 2, "na", .j)  { 
			d ..setto(.b, "no", j, .k) 
		}
	}
	;
}

/// Simple Portuguese stemmer.  See http://www.unine.ch/info/clef/portugueseStemmer.txt
ClassMethod stemWord(ByRef b As %String) As %String
{
	s k = $l(b)
	if k<=3 { do ..removeAllAccents(.b,.k) QUIT b }		; don't stem if the word has length <= 4
	s j=0
	do ..removePTSuffix(.b, .k, .j)
	do ..normFemininePortuguese(.b, .k, .j)
	s:((k>4) && ("eao"[$e(b,k))) k=k-1	; remove final vowel
	do ..removeAllAccents(.b, .k)
	s b=$e(b,1,k)
	QUIT b
}

}
