/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

Class EnsLib.EDI.SEF.Util.Scanner Extends EnsLib.EDI.SEF.Util.TokenClassifier [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the source to be scanner
Property Source As %RawString;

/// This holds the source length
Property SourceLen As %Integer;

/// This holds the current index into the source
Property Index As %Integer;

/// This holds the beggining of a lexeme
Property LexemeBegin As %Integer;

/// This holds the current token
Property CurrentToken As %Integer;

/// This holds the current character
Property CurrentChar As %String;

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	Quit ..Initialize($Get(initvalue))
}

Method Initialize(initvalue) As %Status
{
	#; Initialize the token table
	Do ..InitTab()
	
	#; Establish the source
	Set ..Source=$Get(initvalue),..SourceLen=$Length(..Source)

	Set (..Index,..LexemeBegin)=0
	
	#; Make the first token current
	Do ..NextToken()
	
	Quit $$$OK
}

/// This marks the beggining of a lexeme
Method BeginLexeme()
{
	Set ..LexemeBegin=..Index
}

/// This marks the end of a lexeme and returns it
Method EndLexeme() As %String
{
	Set tLexeme="",tLexemeLen=(..Index-..LexemeBegin)-1
	If tLexemeLen '< 0
	{
		Set tLexeme=$Extract(..Source,..LexemeBegin,..LexemeBegin+tLexemeLen)
	} 
	Quit tLexeme
}

/// This advances the scanner by one token
Method NextToken() As %Integer
{
	If ..Index'>..SourceLen
	{
		Set ..Index=..Index+1
		If ..Index>..SourceLen
		{
			Set ..CurrentChar="",..CurrentToken=$$$tokEOFL
		}
		else 
		{
			Set ..CurrentChar=$Extract(..Source,..Index)
			Set ..CurrentToken=..Classify(..CurrentChar)
		}
	} else {
		Set ..CurrentChar="",..CurrentToken=$$$tokEOFL
	}
	Quit ..CurrentToken
}

/// This peeks at the next token without making it current
Method PeekNextToken() As %Integer
{
	Quit ..PeekAheadToken(1)
}

/// This peeks at the one after next token without making it current
Method PeekNextNextToken() As %Integer
{
	Quit ..PeekAheadToken(2)
}

/// This peeks at the char without making it current
Method PeekNextChar() As %String
{
	Quit ..PeekAheadChar(1)
}

/// This peeks at the one after next char without making it current
Method PeekNextNextChar() As %String
{
	Quit ..PeekAheadChar(2)
}

/// This skips spaces and tabs returning the next token found
Method SkipWhitespace() As %Integer
{
	While ((..CurrentToken=$$$tokSPACE) || (..CurrentToken=$$$tokTAB))
	{
		Do ..NextToken()
		If ..CurrentToken=$$$tokEOS
		{
			Quit
		}
	}
	Quit ..CurrentToken
}

/// This looks ahead without changing the current token
Method PeekAheadToken(Chars As %Integer) As %Integer [ Private ]
{
	Set tOffset=..Index+Chars
	If tOffset>..SourceLen
	{
		Quit $$$tokEOFL
	} 
	else
	{
		Quit ..Classify($Extract(..Source,tOffset))
	}
}

/// This looks ahead without changing the current token
Method PeekAheadChar(Chars As %Integer) As %Integer [ Private ]
{
	Set tOffset=..Index+Chars
	If tOffset>..SourceLen
	{
		Quit ""
	} 
	else
	{
		Quit $Extract(..Source,tOffset)
	}
}

/// Return a string which displays the current context
Method DisplayContext() As %String
{
	Set tStr=" at Offset "_..Index_":"_$Char(10,13)_..Source_$Char(10,13)
	For i=1:1:..Index-1 Set tStr=tStr_". "
	Set tStr=tStr_"^"
	Quit tStr
}

}
