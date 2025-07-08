/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Compiler.LexrepIdeographicStateOutputFunction Extends %iKnow.Compiler.LexrepStateOutputFunc [ Deprecated ]
{

Method IsKatakanaWord(word As %String) As %Boolean
{
	For cnt=1:1:$Length(word) {
		If '..IsKatakana($Extract(word,cnt)) { Return 0 }
	}
	Return 1
}

Method IsKatakana(token As %Char) As %Boolean
{
 Quit:(($Ascii(token)'<$ZHEX("30A0")) & ($Ascii(token)'>$ZHEX("30FF"))) 1
 Quit 0
}

Method IsJapanese(token As %Char) As %Boolean
{
	Quit:(($Ascii(token)'<$ZHEX("3040")) & ($Ascii(token)'>$ZHEX("309F"))) 1 // Hiragana
	Quit:(($Ascii(token)'<$ZHEX("309F")) & ($Ascii(token)'>$ZHEX("30FF"))) 1 
	Quit:(($Ascii(token)'<$ZHEX("4E00")) & ($Ascii(token)'>$ZHEX("9FCF"))) 1 
	Quit:(($Ascii(token)'<$ZHEX("3000")) & ($Ascii(token)'>$ZHEX("303F"))) 1 // CJK Symbols and Punctuation (u3000-u303F)
	Quit:(($Ascii(token)'<$ZHEX("FF00")) & ($Ascii(token)'>$ZHEX("FFEF"))) 1 // Half width & Full width forms
	Quit 0
}

Method IsNumeric(token As %Char) As %Boolean
{
	Quit:(($Ascii(token)'<$ZHEX("0030")) & ($Ascii(token)'>$ZHEX("0039"))) 1 // '0' to '9'
	Quit 0
}

Method IsNumericWord(word As %String) As %Boolean
{
	For cnt=1:1:$Length(word) {
		Return:'..IsNumeric($E(word,cnt)) 0 // not numerical
	}
	Return 1
}

Method CountWithNumeric(word As %String) As %Integer
{
	Set bInNumeric=0
	Set cntNumeric=0
	Set cntNonNumeric=0
	For cnt=1:1:$Length(word) {
		If ..IsNumeric($extract(word,cnt)) { 
		  If bInNumeric=0 Set cntNumeric = cntNumeric + 1
		  Set bInNumeric=1
		} Else {
		    Set bInNumeric=0
		    Set cntNonNumeric = cntNonNumeric + 1
		}
	}
	Return (cntNumeric+cntNonNumeric)
}

Method GetValue(value As %String) As %String
{
  	Set wordCount = ..CountWithNumeric(value)		
  	If (wordCount > ..MaxWordCount) Set ..MaxWordCount = wordCount
  	Set NoFailureFunction = (wordCount=1)
  	Set:$E(value,*)="}" wordCount=1 // regular expression
	Quit $LB(wordCount, ..Labels, value, ..LabelString, ..MetaString, NoFailureFunction)
}

}
