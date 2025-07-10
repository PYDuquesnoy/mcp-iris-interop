/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

Class EnsLib.EDI.SEF.Scanner Extends EnsLib.EDI.SEF.Util.Scanner [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// <piece> := any string of characters except token
Method Piece(tToken As %Integer) As %String
{
	Do ..BeginLexeme()
	While ..CurrentToken'=tToken
	{
		If ..NextToken()=$$$tokEOFL Quit
	}
	Quit ..EndLexeme()
}

/// <count> :- <integer> | '>' '1' ;
Method Count() As %String
{
    If ..CurrentToken=$$$tokGREAT&&(..PeekNextChar()="1") {
	    #; Skip '>1'
	    Do ..NextToken(),..NextToken()
	    Set tVal=">1"
    } elseif ..CurrentToken=$$$tokDIGIT {
	    Set tVal=..Integer()
    } else {
	    Set tVal=""
    }
    Quit tVal
}

/// <element_name> :- <integer>
Method ElementID() As %String
{
	Do ..BeginLexeme()
	If ..CurrentToken=$$$tokLETTER||(..CurrentToken=$$$tokDIGIT)
	{
		While (1) {
			Set tTok=..NextToken()
			If ((tTok'=$$$tokLETTER)&&(tTok'=$$$tokDIGIT))
			{
				Quit
			}
		}
	}
	Quit ..EndLexeme()
}

/// <composite_name> :- <identifier>
Method CompositeName() As %String
{
	Quit ..Identifier()
}

/// <segment_name> :- <identifier>
Method SegmentName() As %String
{
	Quit ..Identifier()
}

/// <group_name> :- { Digit | Letter } [ Digit | Letter | Slash ]* 
Method GroupName() As %String
{
	Do ..BeginLexeme()
	If (..CurrentToken=$$$tokLETTER||(..CurrentToken=$$$tokDIGIT)) {
		Do ..NextToken()
		While (..CurrentToken=$$$tokLETTER||(..CurrentToken=$$$tokDIGIT)||(..CurrentToken=$$$tokSLASH))
		{
			Do ..NextToken()
		}
	}
	Quit ..EndLexeme()
}

/// <code_name> :- { Digit | Letter | [ Digit | Letter | Hyphen ]*
Method CodeName() As %String
{
	Do ..BeginLexeme()
	If ..CurrentToken=$$$tokLETTER||(..CurrentToken=$$$tokDIGIT)
	{
		Do ..NextToken()
		While (..CurrentToken=$$$tokLETTER||(..CurrentToken=$$$tokDIGIT)||(..CurrentToken=$$$tokMINUS)||(..CurrentToken=$$$tokUSCORE))
		{
			Do ..NextToken()
		}
	}
	Quit ..EndLexeme()
}

/// <identifier> :- <letter> | <identifier> {<letter> | <digit> };
Method Identifier() As %String
{
	Do ..BeginLexeme()
	If ..CurrentToken=$$$tokLETTER
	{
		While (1) {
			Set tTok=..NextToken()
			If ((tTok'=$$$tokLETTER)&&(tTok'=$$$tokDIGIT))
			{
				Quit
			}
		}
	}
	Quit ..EndLexeme()
}

/// <integer> :- <digit> | <integer> <digit>;
Method Integer() As %Integer
{
    Do ..BeginLexeme()
    while (..CurrentToken=$$$tokDIGIT)
    {
        Do ..NextToken()
    }
    Quit ..EndLexeme()
}

}
