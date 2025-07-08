/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// See <CLASS>%Text.Text</CLASS>
/// <p>
/// The <CLASS>%Text.Japanese</CLASS> class implements (or calls) the Japanese language-specific stemming algorithm
/// and initializes the language-specific list of noise words.</p>
/// 
Class %Text.Japanese Extends %Text.Text [ System = 4 ]
{

Parameter DICTIONARY = 6;

Parameter SOURCELANGUAGE = "ja";

Parameter SEPARATEWORDS = 1;

Parameter FILTERNOISEWORDS = 0;

Parameter MINWORDLEN = 1;

Parameter NUMCHARS;

Parameter CASEINSENSITIVE = 0;

Parameter STEMMING = 0;

Parameter NGRAMLEN = 2;

ClassMethod SeparateWords(rawText As %String) As %String
{
	Set out = ""
	
	#; Some characters are converted to ";" and word which contains ';' will not add to index
	#;
	Set splitchars = $c(12289,12290,12300,12301,8220,8221)
	Set rawText=$TR(rawText,splitchars,$TR($Justify("",$L(splitchars))," ",";"))
	Set soundmarks = $c(65438,65439)
	
	For i = 1 : 1 : $length(rawText) 
	{	Set c = $extract(rawText,i,i)
		
		#; hankaku kana dakuten(voiced sound mark) or han-dakuten(semivoiced sound mark) 
		#; 
		Set:soundmarks[c c = $extract(rawText,i,$i(i))
		Set out = out_$select(c'=" ":" ",1:"")_c
	}
	Set $extract(out,1,2) = $extract(out,2,2)
	Quit out						; Override in subclasses, if necessary
}

ClassMethod stemWord(ByRef b As %String) As %String
{
	if b=$C(10) s b="" quit b		// Discard the line feed code
	
	quit b
}

ClassMethod ExcludeCommonTerms(nWords) As %Status
{
	//k ^%SYSDict(-..#DICTIONARY)
	//Full width Hiragana
	f ascii=12353:1:12435 s ^%SYSDict(..#DICTIONARY,$$$noiseword,$C(ascii))=""
	//Full width Katakana
	f ascii=12449:1:12531 s ^%SYSDict(..#DICTIONARY,$$$noiseword,$C(ascii))=""
	//Half width Katanaka
	f ascii=65393:1:65437 s ^%SYSDict(..#DICTIONARY,$$$noiseword,$C(ascii))=""

	//Half width English
	f ascii=65:1:90 s ^%SYSDict(..#DICTIONARY,$$$noiseword,$C(ascii))=""
	f ascii=97:1:122 s ^%SYSDict(..#DICTIONARY,$$$noiseword,$C(ascii))=""

	//Numbers
	f ascii=48:1:57 s ^%SYSDict(..#DICTIONARY,$$$noiseword,$C(ascii))=""

	//Full width English and so on..
	//
	QUIT $$$OK
}

}
