/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIX12

Class EnsLib.EDI.X12.Scanner Extends EnsLib.EDI.SEF.Util.Scanner [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the base character set
Parameter AllowedPunct As String = "!""&'()*+,-./:;?= %~@[]_{}\|<>^`#$";

ClassMethod IsValidSeparator(pChar As %String) [ CodeMode = expression ]
{
..#AllowedPunct[pChar||($A(pChar)<32)
}

ClassMethod IsValidChar(pChar As %String) [ CodeMode = expression ]
{
..#AllowedPunct_$Char(9,10,13)[pChar||(pChar?1AN)
}

/// Binary consists on 1..n bytes. The length is provided in a preceding element of the segment
Method Binary(pMinLen As %Integer, pMaxLen As %Integer, Output pData As %String, ByRef pErrors As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set pData=""
		Do ..BeginLexeme()
		For tI=1:1:pMaxLen {
			Do ..NextToken()
			If ..CurrentToken=$$$tokEOFL {
				Set tSC=$$$ERROR($$$EnsEDIX12UnexpectedEOD)
				#; Update Error Array	
				$$$AddCode($$$CodeAK4723DataElementTooShort,$$$CodeAK4723,pErrors)
				Quit
			}
		}
		Set tData=..EndLexeme()
		If $$$ISERR(tSC) Quit
		If pMinLen,$Length(tData)<pMinLen {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"minlength","Binary Data")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723DataElementTooShort,$$$CodeAK4723,pErrors)
			Quit
		} 
		Set pData=tData
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This corresponds to the 'DT' data element type, in practive only 6 (YYMMDD) and 
/// 8 (YYYMMDD) min/maxlength values are allowed 
/// 
/// <date> ::= <year> <month> <day> | <hundred_year> <year> <month> <day>
/// <hundred_year> ::= <digit> <digit>
/// <year> ::= <digit> <digit>
/// <month> ::= "01" | "02" | ... | "12"
/// <day> ::= "01" | "02" | ... | "31"
/// 
Method Date(pMinLen As %Integer, pMaxLen As %Integer, Output pDate As %Integer, ByRef pErrors As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set pDate=""
		Do ..BeginLexeme()
		While (..CurrentToken=$$$tokDIGIT) {
			Do ..NextToken()
		}
		Set tDate=..EndLexeme()
		If pMinLen,$Length(tDate)<pMinLen {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"minlength","Date")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723DataElementTooShort,$$$CodeAK4723,pErrors)
			Quit
		} 
		If pMaxLen,$Length(tDate)>pMaxLen {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"maxlength","Date")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723DataElementTooLong,$$$CodeAK4723,pErrors)
			Quit
		}
		#; Make sure that the date is really valid
		If $ZDH(tDate,8,,,,,,,"")="" {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"IllegalValue","Date")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723InvalidDate,$$$CodeAK4723,pErrors)
			Quit
		}
		#; Check there is no more data
		If ..CurrentToken'=$$$tokEOFL {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"ExtraneousCharacter","Date")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723InvalidCharacterInDataElement,$$$CodeAK4723,pErrors)
			Quit
		}
		Set pDate=tDate
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This corresponds to the 'R' data element type. Neither the leading minus sign or period 
/// contribute to the length of the value
/// 
/// <decimal_number> ::= ['-'] <unsigned_decimal_number> [<base_10_exponential>]
/// <base_10_exponential> ::= 'E' <exponent>
/// <exponent> ::= [-] <unsigned_integer>
/// <unsigned_decimal_number> ::= <unsigned_integer> | '.' <unsigned_integer> | <unsigned_integer> '.' {<digit>}
/// 
Method Decimal(pMinLen As %Integer, pMaxLen As %Integer, Output pDec As %Float, ByRef pErrors As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Do ..BeginLexeme()
		Set pNum="",tLen=0
		If ..CurrentToken=$$$tokMINUS||(..CurrentToken=$$$tokDIGIT) {
			If ..CurrentToken=$$$tokDIGIT Set tLen=tLen+1
			while (..NextToken()=$$$tokDIGIT) {
				Set tLen=tLen+1
			}
			If ..CurrentToken=$$$tokDOT {
				#; Skip '.'
				Do ..NextToken()
				If ..CurrentToken'=$$$tokDIGIT {
					Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"trailing decimal point","Decimal")
					#; Update Error Array
					$$$AddCode($$$CodeAK4723InvalidCharacterInDataElement,$$$CodeAK4723,pErrors)
					Quit
				}
				while ..CurrentToken=$$$tokDIGIT {
					Set tLen=tLen+1
					Do ..NextToken()
				}
			}
			#; Handle exponent
			If ..CurrentToken=$$$tokLETTER&(..CurrentChar="E") {
				Do ..NextToken()
				#; Handle minus
				If ..CurrentToken=$$$tokMINUS&&(..PeekNextToken()=$$$tokDIGIT) {
					Do ..NextToken()
					While ..CurrentToken=$$$tokDIGIT {
						Set tLen=tLen+1
						Do ..NextToken()
					}
				} elseif ..CurrentToken=$$$tokDIGIT {
					While ..CurrentToken=$$$tokDIGIT {
						Set tLen=tLen+1
						Do ..NextToken()
					}
				} else {
					Set tSC=$$$ERROR($$$EnsEDIX12InvalidExponent)
				}
				If ..CurrentToken=$$$tokDOT {
					#; Skip '.'
					Do ..NextToken()
					If ..CurrentToken'=$$$tokDIGIT {
						Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"trailing decimal point","Decimal")
						#; Update Error Array
						$$$AddCode($$$CodeAK4723InvalidCharacterInDataElement,$$$CodeAK4723,pErrors)
						Quit
					}
					while ..CurrentToken=$$$tokDIGIT {
						Set tLen=tLen+1
						Do ..NextToken()
					}
				}
			}
		}
		Set tDec=..EndLexeme()
		If pMinLen,tLen<pMinLen {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"minlength","Decimal")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723DataElementTooShort,$$$CodeAK4723,pErrors)
			Quit
		} 
		If pMaxLen,tLen>pMaxLen {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"maxlength","Decimal")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723DataElementTooLong,$$$CodeAK4723,pErrors)
			Quit
		}
		#; Check there is no more data
		If ..CurrentToken'=$$$tokEOFL {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"ExtraneousCharacter","Decimal")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723InvalidCharacterInDataElement,$$$CodeAK4723,pErrors)
			Quit
		}
		Set pDec=tDec
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This corresponds to the 'ID' data element type. The ID must be drawn from a list of
/// specfied codes for the element (where they can be determined). The standard does not
/// define the legal character set for identifiers but examiniation of extant transactions
/// shows only letters,digits and spaces allowed.
/// 
/// <id> ::= <letter_or_digit> {<letter_or_digit>} {<space>}
/// <letter_or_digit> ::= <uppercase_letter> | <digit>
/// 
Method Identifier(pMinLen As %Integer, pMaxLen As %Integer, Output pID As %String, ByRef pErrors As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set pID=""
		Do ..BeginLexeme()
		If ..CurrentToken=$$$tokLETTER||(..CurrentToken=$$$tokDIGIT) {
			Do ..NextToken()
			While ..CurrentToken=$$$tokLETTER||(..CurrentToken=$$$tokDIGIT||(..CurrentToken=$$$tokSPACE)) {
				Do ..NextToken()
			}
		}
		Set tID= ..EndLexeme()
		If pMinLen,$Length(tID)<pMinLen {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"minlength","Identifier")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723DataElementTooShort,$$$CodeAK4723,pErrors)
			Quit
		} 
		If pMaxLen,$Length(tID)>pMaxLen {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"maxlength","Identifier")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723DataElementTooLong,$$$CodeAK4723,pErrors)
			Quit
		}
		#; Check there is no more data
		If ..CurrentToken'=$$$tokEOFL {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"ExtraneousCharacter","Identifier")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723InvalidCharacterInDataElement,$$$CodeAK4723,pErrors)
			Quit
		}
		Set pID=tID
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This corresponds to the 'Nn' data element type. The leading minus sign does not
/// contribute to the length of the value. The 'n' is the level which indicates the
/// number of decimal positions to the right of the implied decimal pooint
/// 
/// <numeric> ::= [-] <unsigned_integer>
/// <unsigned_integer> ::= <digit> {<digit>}
/// 
Method Numeric(pMinLen As %Integer, pMaxLen As %Integer, pLevel As %Integer, Output pNum As %Integer, ByRef pErrors As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Do ..BeginLexeme()
		Set pNum="",tLen=0
		If ..CurrentToken=$$$tokMINUS||(..CurrentToken=$$$tokDIGIT) {
			#; Minus sign does not count in the length calculation
			If ..CurrentToken=$$$tokDIGIT Set tLen=tLen+1
			while (..NextToken()=$$$tokDIGIT) {
				Set tLen=tLen+1
			}
		}
		Set tNum=..EndLexeme()
		If tLen=0 Set tSC=$$$ERROR($$$EnsEDIX12InvalidNumericValue,tNum) Quit
		#; Apply the level
		Set tNum=tNum*(10**(-pLevel))
		If pMinLen,tLen<pMinLen {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"minlength","Numeric")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723DataElementTooShort,$$$CodeAK4723,pErrors)
			Quit
		}
		If pMaxLen,tLen>pMaxLen {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"maxlength","Numeric")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723DataElementTooLong,$$$CodeAK4723,pErrors)
			Quit
		}	
		#; Check there is no more data
		If ..CurrentToken'=$$$tokEOFL {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"ExtraneousCharacter","Numeric")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723InvalidCharacterInDataElement,$$$CodeAK4723,pErrors)
			Quit
		}
		Set pNum=tNum
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This skips to the specified terminator and over it
Method Skip(pTerminator As %String) As %Status
{
	Set tSC=$$$OK
	do {
		While (..CurrentToken'=pTerminator) {
			If ..CurrentToken=$$$tokEOFL {
				Set tSC=$$$ERROR($$$EnsEDIX12UnexpectedEOD)
				Quit
			}
			Do ..NextToken()
		}
		If $$$ISERR(tSC) Quit
		#; Must have found token, skip over it
		Do ..NextToken()
	} while (0)
	Quit tSC
}

/// This skips spaces and tabs returning the next token found
Method SkipWhitespace(pInUseDelims As %String) As %Integer
{
	While ((..CurrentToken=$$$tokSPACE) || (..CurrentToken=$$$tokTAB) || (..CurrentToken=$$$tokNEWLN) || (..CurrentToken=$$$tokRETURN)) {
		If pInUseDelims[..CurrentChar Quit
		Do ..NextToken()
		If ..CurrentToken=$$$tokEOFL {
			Quit
		}
	}
	Quit ..CurrentToken
}

/// This corresponds to the AN data element type
/// 
/// <string> ::= {<non_space_char> | <space>} <non_space_char> {<non_space_char> | <space>}
/// <non_space_char> ::= <uppercase_letter> | <digit> | <special_char> | <lowercase_letter> | <other_special_char> | <national_char> | <select_language_character>
Method String(pMinLen As %Integer, pMaxLen As %Integer, pDelims As %String, Output pStr As %String, ByRef pErrors As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set pStr=""
		Do ..BeginLexeme()
		While ..IsValidChar(..CurrentChar) {
			If pDelims[..CurrentChar {
				Quit
			}
			Set tTok=..NextToken()
			If tTok=$$$tokEOFL Quit
		}
		Set tStr= ..EndLexeme()
		If pMinLen,$Length(tStr)<pMinLen {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"minlength","String")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723DataElementTooShort,$$$CodeAK4723,pErrors)
			Quit
		} 
		If pMaxLen,$Length(tStr)>pMaxLen {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"maxlength","String")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723DataElementTooLong,$$$CodeAK4723,pErrors)
			Quit
		}
		#; Check there is no more data
		If ..CurrentToken'=$$$tokEOFL {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"ExtraneousCharacter","String")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723InvalidCharacterInDataElement,$$$CodeAK4723,pErrors)
			Quit
		}
		Set pStr=tStr
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This corresponds to the 'TM' data element type, in practive ony 4 (HHMM) and 6 (HHMMSS) min/max
/// length values are allowed
/// 
/// <time> ::= <hour> <minute> [<seconds>]
/// <hour> ::= "00" | "01" | "02" | ... | "23"
/// <minute> ::= "00" | "01" | "02" | ... | "59"
/// <seconds> ::= <integer_seconds> [<decimal_seconds>]
/// <integer_seconds> ::= "00" | ... | "59"
/// <decimal_seconds> ::= <digit> {<digit>}
/// 
Method Time(pMinLen As %Integer, pMaxLen As %Integer, Output pTime As %Integer, ByRef pErrors As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set pTime=""
		Do ..BeginLexeme()
		While (..CurrentToken=$$$tokDIGIT) {
			Do ..NextToken()
		}
		Set tTime=..EndLexeme()
		If pMinLen,$Length(tTime)<pMinLen {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"minlength","Time")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723DataElementTooShort,$$$CodeAK4723,pErrors)
			Quit
		} 
		If pMaxLen,$Length(tTime)>pMaxLen {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"maxlength","Time")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723DataElementTooLong,$$$CodeAK4723,pErrors)
			Quit
		}
		#; Make sure that the time is really valid
		If $Extract(tTime,1,2)>23 {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"Illegal Value","Time (hours)")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723InvalidTime,$$$CodeAK4723,pErrors)
			Quit
		}
		If $Extract(tTime,3,4)>60 {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"Illegal Value","Time (mins)")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723InvalidTime,$$$CodeAK4723,pErrors)
			Quit
		}
		If $Extract(tTime,5,6)>60 {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"Illegal Value","Time (secs)")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723InvalidTime,$$$CodeAK4723,pErrors)
			Quit
		}
		#; Check there is no more data
		If ..CurrentToken'=$$$tokEOFL {
			Set tSC=$$$ERROR($$$EnsEDIX12ConstraintViolation,"ExtraneousCharacter","Time")
			#; Update Error Array
			$$$AddCode($$$CodeAK4723InvalidCharacterInDataElement,$$$CodeAK4723,pErrors)
			Quit
		}
		Set pTime=tTime
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Override initialize to remove CR/LF
Method Initialize(initvalue) As %Status
{
	#; Initialize the token table
	Do ..InitTab()
	#; Establish the source
	Set ..Source=$Translate($Get(initvalue),$Char(10,12)),..SourceLen=$Length(..Source)
	Set (..Index,..LexemeBegin)=0
	#; Make the first token current
	Do ..NextToken()
	Quit $$$OK
}

/// Return a string which displays the current context
Method DisplayContext() As %String
{
	Set tStr="At Offset: "_..Index_$Char(10,13)_..Source_$Char(10,13)
	For i=1:1:..Index-1 Set tStr=tStr_"-"
	Set tStr=tStr_"^"
	Quit tStr
}

}
