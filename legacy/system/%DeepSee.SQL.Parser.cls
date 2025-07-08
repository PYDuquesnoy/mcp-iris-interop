/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Include %qaqplex
Class %DeepSee.SQL.Parser Extends %RegisteredObject
{

Property %Input As %String [ MultiDimensional ];

/// The ordered list of complete tokens
Property %TokenList As %DynamicArray;

/// Current position in the string
Property %Position As %Integer [ InitialExpression = 0 ];

/// Current part of the input being processed
Property %InputPart As %Integer [ InitialExpression = 0 ];

/// Accumulator for the current token
Property %CurrentToken As %String;

/// Container for the last complete token. This is used for looking back when
/// there are multiple tokens in a succession.
Property %LastToken As %String;

/// Any state information can be packed into this object, which can be pushed or popped from a stack if needed.
Property state As %DynamicObject;

/// Stack for changing state
Property stack As %DynamicArray;

/// Optionally set the input as the object is created.
Method %OnNew(pInput As %String) As %Status
{
	Set tSC = $$$OK
	
	Try {
		If $$$ISERR(tSC) Quit
		
		Set tSC = ..%SetInput(.pInput)
		If $$$ISERR(tSC) Quit
		
		Do ..%InitializeState()
		Set ..stack = []		// DTB824 - Initialize stack to avoid access error
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Initialize the state object.
Method %InitializeState() As %Status
{
	Set ..state = {}		// New
	// Boolean on/off 
	Set ..state.inQuote = 0			// In quoted string that will behve as a single token
	Set ..state.quoteChar = ""		// Container for the current quote character
	
	// An open character increases the depth by one, a close reduces it
	Set ..state.parensDepth = 0
	//Set ..state.bracketDepth = 0
	Set ..state.braceDepth = 0
	
	// Function tokenizing state
	Set ..state.inArgList = 0
	Set ..state.functionArity = 0
	Set ..state.argItem = 0
	Set ..state.inFunctionID = 0		// Triggered by $$
	Set ..state.inMacro = 0				// Triggered by $$$
}

/// Set the current input to be analyzed.
Method %SetInput(pInput) As %Status
{
	Set tSC = $$$OK
	
	Try {
		Kill ..%Input
		
		If ($D(pInput)#10=1) {
			Set ..%Input($I(..%Input)) = pInput
		}
		ElseIf ($D(pInput)=10) {
			Set tPartNo = $O(pInput(""),1,tPart)
			While (tPartNo'="") {
				Set ..%Input($I(..%Input)) = tPart
				Set tPartNo = $O(pInput(tPartNo),1,tPart)
			}
		}
		Else {
			Set tSC = $$$ERROR($$$GeneralError,"Invalid input provided")
		}
		
		Do ..%InitializeState()
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Walk through the string per character and tokenize.
Method %Tokenize() As %Status
{
	Set tSC = $$$OK
	Do ..%InitializeState()
	Set ..%TokenList = []
	
	
	Try {
		Set tPartNo = $O(..%Input(""))
		While (tPartNo'="") {
			Set ..%InputPart = tPartNo
			
			Set ..%Position = 0
			Set ..%CurrentToken = ""
			Set tPartLength = $L(..%Input(tPartNo))
			
			While ..%Position < tPartLength {
				Set ..%Position = ..%Position+1
				
				Set tChar = $E(..%Input(tPartNo),..%Position)
				
				
				// Tokenize this part of the input string
				If (..state.inQuote) {
					If (tChar=..state.quoteChar) {
						// The quote character has been encountered.
						// Check if this is an escaped character within the quotation
						Set tPeek = $E(..%Input(tPartNo),..%Position+1)
						If (tChar=tPeek) {
							// Quote character is escaped, accumulate and continue
							Set ..%Position = ..%Position+1
							Set ..%CurrentToken = ..%CurrentToken _ tChar _ tPeek
						}
						Else {
							// Closing quote character
							Set ..state.inQuote = 0
							Do ..%PushCurrentToken()		// Accumulated string as token
							Set ..%CurrentToken = tChar
							Do ..%PushCurrentToken()		// Closing quote token
						}
					}
					ElseIf (tChar="$") {
						// The $ character can trigger special behavior while in a quote
						Set tDollarCount = ..%CheckDollar(..%Input(tPartNo))
						
						If (tDollarCount=3) {
							// DS Macro - Temporarily exit the quote until ] is reached
							Set tSC = ..%PushState()		// DTB824 - Respond to status
							If $$$ISERR(tSC) Quit
							Set ..state.inMacro = 1
							Set ..%CurrentToken = ..%CurrentToken _ "$$$"
							Set ..%Position = ..%Position+2
						}
						ElseIf (tDollarCount=2) {
							// COS Function reference
							Set ..%CurrentToken = ..%CurrentToken _ "$$"
							Set ..%Position = ..%Position+1
						}
						Else {
							// Accumulate as normal
							Set ..%CurrentToken = ..%CurrentToken _ tChar
						}
					}
					Else {
						// Push this onto the current token and accumulate it
						Set ..%CurrentToken = ..%CurrentToken _ tChar
					}
				}
				ElseIf ..state.braceDepth {
					If (tChar="}") {
						// Close the braces
						Do ..%PushCurrentToken()
						Set ..%CurrentToken = tChar
						Do ..%PushCurrentToken()
						Set ..state.braceDepth = ..state.braceDepth - 1
					}
					Else {
						// Push this onto the current token and accumulate it. An entire ODBC escape statement will be accumulated as one token
						Set ..%CurrentToken = ..%CurrentToken _ tChar
					}
				}
				Else {		// inQuote=0, braceDepth=0
					If ..%IsWhiteSpace(tChar) {
						// Push the current token to the token list and clear the accumulator
						Do ..%PushCurrentToken()
					}
					ElseIf(..%IsSeparatorChar(tChar)) {
						// Push whatever has been accumulated and log the separator
						Do ..%PushCurrentToken()
						Set ..%CurrentToken = tChar
						Do ..%PushCurrentToken()
					}
					ElseIf (tChar="""")||(tChar="'") {
						Set ..%CurrentToken = tChar
						Do ..%PushCurrentToken()
						Set ..state.inQuote = 1
						Set ..state.quoteChar = tChar
					}
					ElseIf (tChar="(") {
						// This is either a lone token or is the end of a function token
						If (..%CurrentToken'="") {
							If ..state.inFunctionID {
								// Function identifiers accumulate everything until the
								// ( character is encountered.
								// User-defined functions do not declare arity so these state 
								// variables are not used.
								Set ..state.inFunctionID = 0
								
							}
							ElseIf ..%IsUserFunction(..%CurrentToken) {
								Set ..state.inArgList = 1
								Set ..state.functionArity = -1		// Signal undefined arity	
							}
							ElseIf ..%IsFunction(..%CurrentToken,.tArity) {
								// Log the function state
								Set ..state.inArgList = 1
								Set ..state.functionArity = tArity
							}
							ElseIf ..%IsScalarFunction(..%CurrentToken,.tArity) {
								// Log the function state
								Set ..state.inArgList = 1
								Set ..state.functionArity = tArity
							}
							Else {
								$$$ThrowStatus($$$ERROR($$$GeneralError,$$$FormatText("The function '%1' is not a supported SQL function",..%CurrentToken)))
							}
						}
						
						Set ..%CurrentToken = ..%CurrentToken _ tChar
						Do ..%PushCurrentToken()
						Set ..state.parensDepth = ..state.parensDepth + 1
					}
					ElseIf (tChar=")") {
						If ..state.inArgList {
							// Close the argument list
							Set ..state.inArgList = 0
							Set ..state.functionArity = ""
						}

						Do ..%PushCurrentToken()
						Set ..%CurrentToken = tChar
						Do ..%PushCurrentToken()
						Set ..state.parensDepth = ..state.parensDepth - 1
					}
					ElseIf (tChar="[") {
						// DS macros use this to indicate the beginning of the argument list.
						If (..%CurrentToken'="") {
							If (..state.inMacro) {
								If (..%IsDSMacro(..%CurrentToken,.tArity)) {
									Set ..state.inArgList = 1
									Set ..state.functionArity = tArity
								}
								Else {
									$$$ThrowStatus($$$ERROR($$$GeneralError,$$$FormatText("'%1' is not a supported DS Macro",..%CurrentToken)))
								}
							}
						}

						// In this case treat this as the end of a token. 
						Set ..%CurrentToken = ..%CurrentToken _ tChar
						Do ..%PushCurrentToken()
					}
					ElseIf (tChar="]") {
						If (..state.inMacro) {
							Set tSC = ..%PopState()		// DTB824 - Respond to status
							If $$$ISERR(tSC) Quit
						}
						
						Do ..%PushCurrentToken()
						Set ..%CurrentToken = tChar
						Do ..%PushCurrentToken()
					}
					ElseIf (tChar="{") {
						// Open a 
						Do ..%PushCurrentToken()
						Set ..%CurrentToken = tChar
						Do ..%PushCurrentToken()
						Set ..state.braceDepth = ..state.braceDepth + 1
					}
					ElseIf (tChar="}") {
						Do ..%PushCurrentToken()
						Set ..%CurrentToken = tChar
						Do ..%PushCurrentToken()
						Set ..state.braceDepth = ..state.braceDepth - 1
					}
					ElseIf (tChar="$") {
						// The $ character can trigger special behavior 
						Set tDollarCount = ..%CheckDollar(..%Input(tPartNo))
						
						If (tDollarCount=3) {
							// DS Macro - Temporarily exit the quote until ] is reached
							Set tSC = ..%PushState()		// DTB824 - Respond to status
							If $$$ISERR(tSC) Quit
							Set ..state.inMacro = 1
							Set ..%CurrentToken = ..%CurrentToken _ "$$$"
							Set ..%Position = ..%Position+2
						}
						ElseIf (tDollarCount=2) {
							// COS Function reference
							Set ..%CurrentToken = ..%CurrentToken _ "$$"
							Set ..state.inFunctionID = 1
							Set ..%Position = ..%Position+1
						}
						Else {
							// Accumulate as normal
							Set ..%CurrentToken = ..%CurrentToken _ tChar
						}
					}
					ElseIf ..%IsOperatorChar(tChar,.tMaxOpLength) {
						If (tChar="_") {
							// The underscore can be used in a number of ways, one of which is as a character within a function name.
							// Rely on the context to push it as a standalone token if applicable, otherwise just accumulate it.
							Set ..%CurrentToken = ..%CurrentToken _ tChar 
						}
						Else {
							// First, push the current token and start a new one with this operator
							Do ..%PushCurrentToken()
							Set ..%CurrentToken = tChar
							
							// Determine if the operator is one or two characters and push that to the token list
							If (tMaxOpLength=1) {
								Do ..%PushCurrentToken()
							}
							ElseIf (tMaxOpLength=2) {
								// Peek ahead one position. If the character matches, move to that position and push the double
								Set tPeek = $E(..%Input(tPartNo),..%Position+1)
								If ..%IsOperatorToken(tChar_tPeek) {
									Set ..%Position = ..%Position+1
									Set ..%CurrentToken = ..%CurrentToken _ tPeek
									//Do ..%PushCurrentToken()
								}
								
								Do ..%PushCurrentToken()
							}
						}
					}
					ElseIf (..%Position=tPartLength) {
						// Final token of this part - push it onto the list
						Set ..%CurrentToken = ..%CurrentToken _ tChar
						Do ..%PushCurrentToken()
					}
					Else {
						// Default Action: Accumulate the current character
						Set ..%CurrentToken = ..%CurrentToken _ tChar
					}
				}
			}
			
			Set tPartNo = $O(..%Input(tPartNo))
		}
		
		If ..state.parensDepth > 0 {
			Set tSC = $$$ERROR($$$GeneralError,"Unclosed parenthesis")
			Quit
		}
		If ..state.parensDepth < 0 {
			Set tSC = $$$ERROR($$$GeneralError,"Extra closing parenthesis")
			Quit
		}


	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Investigate the current position for $ tokens. Returns the number of 
/// consecutive dollar sign characters beginning at the current position
Method %CheckDollar(pString As %String = "") As %Integer [ Private ]
{
	Set tReturn = 0
	
	Set tChar = $E(pString,..%Position)
	Set tPeek1 = $E(pString,..%Position+1)
	Set tPeek2 = $E(pString,..%Position+2)
	Set tTripleChar = tChar_tPeek1_tPeek2
	
	If (tChar_tPeek1_tPeek2="$$$") {
		Set tReturn = 3
	}
	ElseIf (tChar_tPeek1="$$") {
		Set tReturn = 2
	}
	ElseIf (tChar="$") {
		Set tReturn = 1
	}

	Quit tReturn
}

/// Test for white space character
Method %IsWhiteSpace(pChar As %String = "") As %Boolean [ Private ]
{
	Quit (pChar=" ") ||
		(pChar=$C(10)) ||
		(pChar=$C(13))
}

/// Test for a characer separating two different terms.
Method %IsSeparatorChar(pChar As %String = "", pPosition As %Integer = {..%Position}) As %Boolean [ Private ]
{
	Set tReturn=0
	If (pChar="") Quit tReturn
	
	If (pChar=",") {
		Set tReturn = 1
	}
	ElseIf (pChar=".") {
		// Check previous position to see if the "." is a decimal
		Set tPrevChar = $E(..%Input(..%InputPart),pPosition-1)
		Set tNextChar = $E(..%Input(..%InputPart),pPosition+1)
		
		If $IsValidNum(tNextChar) && (..%IsOperatorChar(tPrevChar) || $IsValidNum(tPrevChar) || ..%IsWhiteSpace(tPrevChar)) {
			// The following character is a digit and the preceding character does not invalidate it as a number
			Set tReturn = 0
		}
		Else {
			Set tReturn = 1
		}
	}
	
	Quit tReturn
}

/// Test for a single-character operator
Method %IsOperatorChar(pChar As %String = "", Output pOpLength) As %Boolean
{
	If (pChar="") Quit 0
	Set pOpLength = 0
	
	// 		+ | - | * | / | \ | # | _ | "||" | < | > | <> | <= | >= | =
	Set tOpChars("+") = 1
	Set tOpChars("-") = 2
	Set tOpChars("*") = 1
	Set tOpChars("/") = 1
	Set tOpChars("\") = 1
	Set tOpChars("#") = 1
	Set tOpChars("_") = 1
	Set tOpChars("|") = 2
	Set tOpChars("<") = 2
	Set tOpChars(">") = 2
	Set tOpChars("=") = 1
	
	If (pChar="-")||(pChar="+") {
		Set tPrevCharU = $$$UPPER($E(..%Input(..%InputPart),..%Position-1))
		Set tNextChar = $E(..%Input(..%InputPart),..%Position+1)
		
		If (tPrevCharU="E")&&$IsValidNum(tNextChar) {
			// This is part of an exponent. Do not treat it as an operator
			Set pOpLength = 0
			Quit 0
		}
	}
	
	Set pOpLength = +$G(tOpChars(pChar))
	
	Quit ''pOpLength
}

/// Test for an opertor token of arbitrary length
Method %IsOperatorToken(pToken As %String = "") As %Boolean
{
	If (pToken="") Quit 0
	
	// +,-,*,/,<,>,=,>=,<=,<>
	Set tOpTokens("+") = ""
	Set tOpTokens("-") = ""
	Set tOpTokens("*") = ""
	Set tOpTokens("/") = ""
	Set tOpTokens("\") = ""
	Set tOpTokens("=") = ""
	Set tOpTokens("->") = ""
	Set tOpTokens(">=") = ""
	Set tOpTokens("<=") = ""
	Set tOpTokens("<>") = ""
	Set tOpTokens("||") = ""
	
	Quit $D(tOpTokens(pToken))
}

/// Test for a supported function
Method %IsFunction(pToken As %String = "", Output pFunctionArity) As %Boolean [ Private ]
{
	Set tReturn = 0
	Set pFunctionArity = ""
	
	Try {
		If (pToken = "") Quit
		Set tTokenU = $$$UPPER(pToken)

		Set tFuncs("ABS") = 1 
		Set tFuncs("ACOS") = 1
		Set tFuncs("ASIN") = 1
		Set tFuncs("ATAN") = 1
	   	Set tFuncs("ASCII") = 1
		Set tFuncs("CEILING") = 1
		Set tFuncs("COS") = 1
		Set tFuncs("COT") = 1
		Set tFuncs("CHAR") = 1
		Set tFuncs("CONCAT") = 2
		Set tFuncs("CONVERT") = 2
		Set tFuncs("CURDATE") = 0
		Set tFuncs("CURTIME") = 0
		Set tFuncs("DATABASE") = 0
		Set tFuncs("DAYNAME") = 1
		Set tFuncs("DAYOFMONTH") = 1
		Set tFuncs("DAYOFWEEK") = 1
		Set tFuncs("DAYOFYEAR") = 1
		Set tFuncs("EXP") = 1
		Set tFuncs("FLOOR") = 1
		Set tFuncs("HOUR") = 1
		Set tFuncs("IFNULL") = 2 
		Set tFuncs("LCASE") = 1
		Set tFuncs("LEFT") = 2
		Set tFuncs("LENGTH") = 1
		Set tFuncs("LOG") = 1
		Set tFuncs("LOG10") = 1
		Set tFuncs("LTRIM") = 1
		Set tFuncs("MINUTE") = 1
		Set tFuncs("MOD") = 2
		Set tFuncs("MONTH") = 1
		Set tFuncs("MONTHNAME") = 1
		Set tFuncs("NOW") = 0
		Set tFuncs("PI") = 0
		Set tFuncs("POWER") = 2
		Set tFuncs("QUARTER") = 1
		Set tFuncs("REPEAT") = 2
		Set tFuncs("RIGHT") = 2
		Set tFuncs("ROUND") = 2
		Set tFuncs("RTRIM") = 1
		Set tFuncs("SECOND") = 1
		Set tFuncs("SIGN") = 1
		Set tFuncs("SIN") = 1
		Set tFuncs("SPACE") = 1
		Set tFuncs("SQRT") = 1
		Set tFuncs("SUBSTRING") = -1
		Set tFuncs("TAN") = 1
		Set tFuncs("TIMESTAMPADD") = 3
		Set tFuncs("TIMESTAMPDIFF") = 3
		Set tFuncs("TRUNCATE") = 2
		Set tFuncs("UCASE") = 1
		Set tFuncs("USER") = 0
		Set tFuncs("WEEK") = 1
		Set tFuncs("YEAR") = 1

		
		If $D(tFuncs(tTokenU),pFunctionArity) {
			Set tReturn = 1
		}
		ElseIf $E(tTokenU)="%" {
			// Accept all % functions. Arity is unlimited if not specifically declared above.
			Set tReturn = 1
			Set pFunctionArity = -1
		}
		Else {
			// Final check to see if this is an aggregate function
			Set tReturn = ..%IsAggFunction(tTokenU,.pFunctionArity)||
					..%IsCastType(tTokenU,.pFunctionArity)		// DTB - This can look like a function
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tReturn = 0
	}
	
	Quit tReturn
}

/// Test for a supported scalar function
Method %IsScalarFunction(pToken As %String = "", Output pFunctionArity) As %Boolean [ Private ]
{
	Set tReturn = 0
	Set pFunctionArity = ""
	
	Try {
		If (pToken = "") Quit
		Set tTokenU = $$$UPPER(pToken)

		Set tScalFuncs("ABS") = 1 
		Set tScalFuncs("ASCII") = 1
		Set tScalFuncs("CAST") = 1
		Set tScalFuncs("CEILING") = 1
		Set tScalFuncs("CHARINDEX") = 3
		Set tScalFuncs("CHAR_LENGTH") = 1
		Set tScalFuncs("CHARACTER_LENGTH") = 1 
		Set tScalFuncs("COALESCE") = -1
		Set tScalFuncs("CONVERT") = 3
		Set tScalFuncs("CURRENT_TIME") = 1 
		Set tScalFuncs("CURRENT_TIMESTAMP") = 1 
		Set tScalFuncs("DATALENGTH") = 1
		Set tScalFuncs("DATEADD") = -1
		Set tScalFuncs("DATEDIFF") = -1
		Set tScalFuncs("DATENAME") = -1
		Set tScalFuncs("DATEPART") = -1
	    Set tScalFuncs("DATE") = 1
		Set tScalFuncs("DAY") = 1
		Set tScalFuncs("DECODE") = -1
		Set tScalFuncs("FLOOR") = 1
		Set tScalFuncs("GETDATE") = 1
		Set tScalFuncs("GETUTCDATE") = 1
		Set tScalFuncs("GREATEST") = -1
		Set tScalFuncs("IFNULL") = 3
		Set tScalFuncs("INSTR") = 4
		Set tScalFuncs("ISNULL") = 2
		Set tScalFuncs("ISNUMERIC") = 1
		Set tScalFuncs("$JUSTIFY") = 3
		Set tScalFuncs("LAST_DAY") = 1
		Set tScalFuncs("LAST_IDENTITY") = 0
		Set tScalFuncs("LCASE") = 1
		Set tScalFuncs("LEAST") = -1
		Set tScalFuncs("LEFT") = 2
		Set tScalFuncs("LEN") = 1
		Set tScalFuncs("LENGTH") = 1
		Set tScalFuncs("$EXTRACT") = 3
		Set tScalFuncs("$FIND") = 3
		Set tScalFuncs("$LENGTH") = 2
		Set tScalFuncs("$LIST") = 3
		Set tScalFuncs("$LISTBUILD") = -1
		Set tScalFuncs("$LISTDATA") = 2
		Set tScalFuncs("$LISTFIND") = 3
		Set tScalFuncs("$LISTFROMSTRING") = 2
		Set tScalFuncs("$LISTGET") = 3
		Set tScalFuncs("$LISTLENGTH") = 1
		Set tScalFuncs("$LISTSAME") = 2
		Set tScalFuncs("$LISTTOSTRING") = 2
		Set tScalFuncs("$MVFMT") = 2
		Set tScalFuncs("$MVFMTS") = 2
		Set tScalFuncs("$MVICONV") = 2
		Set tScalFuncs("$MVICONVS") = 2
		Set tScalFuncs("$MVOCONV") = 2
		Set tScalFuncs("$MVOCONVS") = 2
		Set tScalFuncs("LOWER") = 1
		Set tScalFuncs("LPAD") = 3
		Set tScalFuncs("LTRIM") = 1
		Set tScalFuncs("MONTH") = 1
		Set tScalFuncs("NOW") = 0
		Set tScalFuncs("NULLIF") = 2
		Set tScalFuncs("NVL") = 2
		Set tScalFuncs("%OBJECT") = 1
		Set tScalFuncs("%OID") = 1
		Set tScalFuncs("$PIECE") = 4
		Set tScalFuncs("PATINDEX") = 2
		Set tScalFuncs("POSITION") = 0
		Set tScalFuncs("POWER") = 2
		Set tScalFuncs("REPEAT") = 2
		Set tScalFuncs("REPLACE") = 3
		Set tScalFuncs("REPLICATE") = 2
		Set tScalFuncs("REVERSE") = 1
		Set tScalFuncs("RIGHT") = 2
		Set tScalFuncs("ROUND") = 2
		Set tScalFuncs("RPAD") = 3
		Set tScalFuncs("RTRIM") = 1
		Set tScalFuncs("SEARCH_INDEX") = -1
		Set tScalFuncs("SIGN") = 1 
		Set tScalFuncs("%SIMILARITY") = 2
		Set tScalFuncs("SPACE") = 1
		Set tScalFuncs("STR") = 3
		Set tScalFuncs("STRING") = -1
		Set tScalFuncs("STUFF") = 4
		Set tScalFuncs("SUBSTR") = 3 
		Set tScalFuncs("SUBSTRING") = -1
		Set tScalFuncs("SYSDATE") = 0
		Set tScalFuncs("TOCHAR") = 2 
		Set tScalFuncs("TO_CHAR") = 2 
		Set tScalFuncs("TODATE") = 2 
		Set tScalFuncs("TO_DATE") = 2 
		Set tScalFuncs("TO_NUMBER") = 1
		Set tScalFuncs("TO_TIMESTAMP") = 2 
		Set tScalFuncs("$TRANSLATE") = 3
		Set tScalFuncs("TRIM") = -1
		Set tScalFuncs("$TSQL_ERROR") = 0
		Set tScalFuncs("$TSQL_GETUTCDATE") = 0
		Set tScalFuncs("$TSQL_FETCH_STATUS") = 0
		Set tScalFuncs("$TSQL_LOCK_TIMEOUT") = 0
		Set tScalFuncs("$TSQL_NESTLEVEL") = 0
		Set tScalFuncs("$TSQL_SERVERNAME") = 0
		Set tScalFuncs("$TSQL_SPID") = 0
		Set tScalFuncs("$TSQL_SQLSTATUS") = 0
		Set tScalFuncs("$TSQL_TRANCOUNT") = 0
		Set tScalFuncs("$TSQL_VERSION") = 0
		Set tScalFuncs("$TSQL_DB_NAME") = 0
		Set tScalFuncs("$TSQL_HOST_NAME") = 0
		Set tScalFuncs("UCASE") = 1
		Set tScalFuncs("UNIX_TIMESTAMP") = 1
		Set tScalFuncs("YEAR") = 1
		
		
		If $D(tScalFuncs(tTokenU),pFunctionArity) {
			Set tReturn = 1
		}
		ElseIf $E(tTokenU)="%" {
			// Accept all % functions. Arity is unlimited if not specifically declared above.
			Set tReturn = 1
			Set pFunctionArity = -1
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tReturn = 0
	}
	
	Quit tReturn
}

Method %IsAggFunction(pToken As %String = "", Output pFunctionArity) As %Boolean [ Private ]
{
	Set tReturn = 0
	Set pFunctionArity = ""
	
	Try {
		If (pToken = "") Quit
		Set tTokenU = $$$UPPER(pToken)
		
		Set tAggFuncs("AVG") = 1
		Set tAggFuncs("SUM") = 1
		Set tAggFuncs("MAX") = 1
		Set tAggFuncs("MIN") = 1
		Set tAggFuncs("COUNT") = 1
		Set tAggFuncs("LIST") = 1
		Set tAggFuncs("XMLAGG") = 1
		Set tAggFuncs("%DLIST") = 1
		Set tAggFuncs("STDDEV") = 1
		Set tAggFuncs("STDDEV_POP") = 1
		Set tAggFuncs("STDDEV_SAMP") = 1
		Set tAggFuncs("VARIANCE") = 1
		Set tAggFuncs("VAR_POP") = 1
		Set tAggFuncs("VAR_SAMP") = 1
		Set tAggFuncs("JSON_ARRAYAGG") = 1
		
		
		If $D(tAggFuncs(tTokenU),pFunctionArity) {
			Set tReturn = 1
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tReturn = 0
	}
	
	Quit tReturn
}

/// Type arguments in the CAST function can look like 
Method %IsCastType(pToken As %String = "", pFunctionArity) As %Boolean [ Private ]
{
	Set tReturn = 0
	Set pFunctionArity = ""
	
	Try {
		If (pToken = "") Quit
		Set tTokenU = $$$UPPER(pToken)
		
		Set tType("NUMERIC") = "" 
		Set tType("FLOAT") = ""
		Set tType("DOUBLE") = ""
		Set tType("REAL") = ""
		Set tType("DECIMAL") = ""
		Set tType("DEC") = ""
		Set tType("INTEGER") = ""
		Set tType("INT") = ""
		Set tType("BIGINT") = ""
		Set tType("SMALLINT") = ""
		Set tType("TINYINT") = ""
		Set tType("BIT") = ""
		Set tType("CHAR") = ""
		Set tType("CHARACTER") = ""
		Set tType("NCHAR") = ""
		Set tType("VARCHAR") = ""
		Set tType("NVARCHAR") = ""
		Set tType("CHAR VARYING") = ""
		Set tType("CHARACTER VARYING") = ""
		Set tType("DATE") = ""
		Set tType("TIME") = ""
		Set tType("TIMESTAMP") = ""
		Set tType("DATETIME") = ""
		Set tType("SMALLDATETIME") = ""
		Set tType("MONEY") = ""
		Set tType("SMALLMONEY") = ""
		Set tType("BINARY") = ""
		Set tType("BINARY VARYING") = ""
		Set tType("VARBINARY") = ""
		Set tType("GUID") = ""

		If $D(tType(tTokenU),pFunctionArity) {
			Set tReturn = 1
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tReturn = 0
	}
	
	Quit tReturn
}

/// Test for one of the DeepSee-specific macro functions
Method %IsDSMacro(pToken As %String = "", pFunctionArity) As %Boolean [ Private ]
{
	Set tReturn = 0
	Set pFunctionArity = ""
	
	Try {
		If (pToken = "") Quit
		Set tTokenU = $$$UPPER(pToken)
		
		Set tMacros("$$$TEXT") = 2
		Set tMacros("$$$IKSUMMARY") = 2
		Set tMacros("$$$IKLINK") = 1
		Set tMacros("$$$PMML") = 2
		
		Set tReturn = $D(tMacros(tTokenU),pFunctionArity)
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tReturn = 0
	}
	
	Quit tReturn
}

Method %IsUserFunction(pFunction, pLastToken = {..%LastToken}) As %Boolean
{
	Set tReturn = 0
	
	Try {
		If (pLastToken=".")||(pLastToken="_") {
			Set tReturn = 1
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tReturn = 0
	}
	
	Quit tReturn
}

Method %PushCurrentToken() As %Status [ Private ]
{
	Do:(..%CurrentToken'="") ..%TokenList.%Push(..%CurrentToken)
	Set ..%LastToken = ..%CurrentToken
	Set ..%CurrentToken = ""
}

/// Push the current parser state to the stack and initialize a new state object
Method %PushState() As %Status [ Private ]
{
	Set tSC = $$$OK
	Try {
		Do ..stack.%Push(..state)
		Do ..%InitializeState()
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Restore the last state from the top of the stack.
Method %PopState() As %Status [ Private ]
{
	Set tSC = $$$OK
	Try {
		Set ..state = ..stack.%Pop()
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Parse SELECT list for a DeepSee listing. The output <var>pParsedTree</var> is a %DynamicArray containing the individual select terms.
ClassMethod %ParseSelect(pSelectTokens As %DynamicArray, Output pParsedTree, Output pSpecialTokens) As %Status
{
	Set tSC = $$$OK
	Kill pParsedTree
	
	Try {
		// Identify $$$TEXT and actual ',' field separators.
		// Organization for the tokens
		Set tSelectTerms = []
		Set tCurrTermTokens = []
		
		// State variables
		Set tInMacro = 0
		
		Set tInParens = 0		// Commas in terms do not separate different terms
		Set tParensDepth = 0
		Set tInBraces = 0
		
		Set tInQuote = 0
		Set tQuoteChar = ""
		
		Set tLastToken = ""
		
		Set tLastTokenNo = pSelectTokens.%Size()-1
		For tPos=0:1:tLastTokenNo {
			Set tToken = pSelectTokens.%Get(tPos)
			Set tTokenU = $$$UPPER(tToken)
			
			Do tCurrTermTokens.%Push(tToken)
			
			If tInParens {
				If (tTokenU=")") {
					Set tParensDepth=tParensDepth-1
					If 'tParensDepth {
						Set tInParens = 0
					}
				}
				ElseIf ($E(tTokenU,$L(tTokenU))="(") {
					Set tParensDepth = tParensDepth+1
				}
			}
			ElseIf tInBraces {
				// Accept everything until the closing brace
				If (tTokenU="}") {
					Set tInBraces=0
				}
			}
			ElseIf tInQuote&&'tInMacro {
				If (tTokenU=tQuoteChar) {
					Set tInQuote = 0
					
					Set tSpecialTokens("pos",tSelectTerms.%Size(),tCurrTermTokens.%Size()-1) = tToken
					Set tSpecialTokens("tokens",tToken,tSelectTerms.%Size(),tCurrTermTokens.%Size()-1) = ""	
				}
				ElseIf (tTokenU="$$$TEXT[") {
					Set tSpecialTokens("pos",tSelectTerms.%Size(),tCurrTermTokens.%Size()-1) = tToken
					Set tSpecialTokens("tokens",tToken,tSelectTerms.%Size(),tCurrTermTokens.%Size()-1) = ""	
				
					Set tInMacro = 1
				}
			}
			ElseIf tInMacro {
				If (tTokenU="]") {
					Set tInMacro = 0
				}
			}
			Else {
				If (tTokenU=",") {
					Do tCurrTermTokens.%Pop()		// This Comma was pushed but is not part of the actual Select Term
					Do tSelectTerms.%Push(tCurrTermTokens)
					
					Set tCurrTermTokens = []
				}
				ElseIf (tTokenU="$$$TEXT[") {
					// Current Select Term has not been pushed, the Term Token has.
					Set tSpecialTokens("pos",tSelectTerms.%Size(),tCurrTermTokens.%Size()-1) = tToken
					Set tSpecialTokens("tokens",tToken,tSelectTerms.%Size(),tCurrTermTokens.%Size()-1) = ""	
					
					Set tInMacro = 1
				}
				ElseIf ($E(tTokenU,$L(tTokenU))="(") {
					Set tInParens = 1
					Set tParensDepth = tParensDepth+1
				}
				ElseIf (tTokenU="{") {
					Set tInBraces = 1
				}
				ElseIf (tTokenU="""")||(tTokenU="'") {
					Set tInQuote = 1
					Set tQuoteChar = tTokenU
					
					Set tSpecialTokens("pos",tSelectTerms.%Size(),tCurrTermTokens.%Size()-1) = tToken
					Set tSpecialTokens("tokens",tToken,tSelectTerms.%Size(),tCurrTermTokens.%Size()-1) = ""	
				}
				ElseIf (tTokenU="AS") {
					Set tSpecialTokens("pos",tSelectTerms.%Size(),tCurrTermTokens.%Size()-1) = tToken
					Set tSpecialTokens("tokens",tTokenU,tSelectTerms.%Size(),tCurrTermTokens.%Size()-1) = ""
				}
			}
			
			If (tPos=tLastTokenNo) {
				// Last token in the list
				Do tSelectTerms.%Push(tCurrTermTokens)
			}
			
			Set tLastToken = tToken
		}
		
		Set pParsedTree = tSelectTerms
		Merge pSpecialTokens = tSpecialTokens
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Returns the current %TokenList array
Method %GetTokenList() As %DynamicArray
{
	Quit ..%TokenList
}

/// Print the current inputas set by <method>%SetInput</method>. If <var>pVerbose</var> = 1, print the string
/// to the current device.
Method %PrintInput(pVerbose = 1) As %String
{
	Set tFullString = ""
	Set inputPart = $O(..%Input(""))
	While inputPart'="" {
		Set tFullString = tFullString _ " " _ ..%Input(inputPart)
		
		Set inputPart = $O(..%Input(inputPart))
	}
	
	Quit tFullString
}

Method %PrintTokenList(pVerbose = 1) As %String
{
	Set tJSON = ..%GetTokenList().%ToJSON()
	Write:pVerbose tJSON
	
	Quit tJSON
}

/// Reassemble the select Item in both the logical and display versions. The parameter <var>pLocalize</var> allows the caller to request translation
/// of the header string to the current locale. A default domain for this translation can be supplied via
/// <var>pDomain</var>. When defined, this default is used if there is no domain explicitly declared as the 
/// second argument of $$$TEXT.  
Method %ProcessSelectItem(pSelectItemTokens As %DynamicArray, pHeaderPos, pDomain As %String = "", Output pSelectItemPair, pLocalize As %Boolean = 0) As %Status
{
	// Method added by DTB814
	Set tSC = $$$OK
	
	Try {
		Set tHeaderPos = pHeaderPos
		
		// Reassemble the select item string in both the logical
		// and display versions of the string
		Set tTermString = ""
		Set tInQuote = 0
		Set tQuotChar = ""
		Set tLastToken = ""
		Set pos = 0
		
		// Start with the actual select term
		While (pos<pSelectItemTokens.%Size())&&((tHeaderPos=-1)||(pos<tHeaderPos)) {
			Set tToken = pSelectItemTokens.%Get(pos)
			Set tSkip = 0
			
			// DTB815 - Spaces are used to normalize the field item string. In some cases suppress the space for readability
			If (pos=0) ||
				tInQuote || 
				(tToken="->") ||
				(tLastToken="->") ||
				(tToken=".") ||
				(tLastToken=".") ||
				(tToken=")") ||
				(tToken=",") || 
				(($E(tLastToken,*)="(")&&..%IsFunction($E(tLastToken,1,*-1))) ||
				(($E(tLastToken,*)="(")&&..%IsScalarFunction($E(tLastToken,1,*-1))) ||
				($E(tLastToken,*)="(") {
				Set tSpace = ""
			}
			Else {
				Set tSpace = " "
			}
			
			If (tToken="""")||(tToken="'") {
				If tInQuote&&(tToken=tQuoteChar) {
					Set tInQuote=0
				}
				Else {
					Set tInQuote = 1
					Set tQuoteChar = tToken
				}
			}

			// Optionally signal the concatenation to skip this particular token
			Set tSkip = ((pos=(tHeaderPos-1))&&($$$UPPER(tToken)="AS"))

			// Add the current token
			If 'tSkip {
				Set tTermString = tTermString _ tSpace _ tToken
			}
			
			Set tLastToken = tToken
			Set pos=pos+1
		}
		
		// Now assemble the header if it exists.
		Set tInMacro = 0
		Set tHeaderString = ""
		Set tTextMacroTokens = []
		Set tHeaderIsQuoted = $S(tHeaderPos>0:(pSelectItemTokens.%Get(tHeaderPos)=""""),1:0)
		While (pos<pSelectItemTokens.%Size()) {
			Set tToken = pSelectItemTokens.%Get(pos)
			
			If (tToken="$$$TEXT[") {
				Set tInMacro=1
			}
			If tInMacro {
				Do tTextMacroTokens.%Push(tToken)
				If (tToken="]") {
					Set tInMacro=0
				}
			}
			
			// Add the current token. All necessary spaces should already be included 
			// in string literals
			Set tHeaderString = tHeaderString _ tToken
			
			Set tLastToken=tToken
			Set pos=pos+1
		}
		
		// Resolve $$$TEXT[]
		If tTextMacroTokens.%Size() {
			Set tHeaderDisplayString = ..%ProcessDsTEXT(tTextMacroTokens,pDomain,.tSC,pLocalize)		// DTB827 - Pass localization flag
			If $$$ISERR(tSC) Quit
			
			If tHeaderIsQuoted {
				Set tHeaderDisplayString = """" _ tHeaderDisplayString _ """"
			}
		}
		Else {
			Set tHeaderDisplayString = tHeaderString
		}

		Set tTermValueList = $LB(tTermString) _ $S(tHeaderString'="":$LB("AS",tHeaderString),1:"")
		Set tTermDisplayList = $LB(tTermString) _ $S(tHeaderDisplayString'="":$LB("AS",tHeaderDisplayString),1:"")
		Set pSelectItemPair = $LB(tTermValueList,tTermDisplayList)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Extract the display header from the $$$TEXT macro. The parameter <var>pLocalize</var> allows the caller to request translation
/// of the header string to the current locale. A default domain for this translation can be supplied via
/// <var>pDomain</var>. When defined, this default is used if there is no domain explicitly declared as the 
/// second argument of $$$TEXT.  
Method %ProcessDsTEXT(pTextMacroTokens As %DynamicArray, pDomain As %String = "", Output pStatus, pLocalize As %Boolean = 0) As %String
{
	// Method added by DTB814
	Set tReturn = ""
	
	Try {
		Set tHeader = pTextMacroTokens.%Get(2)
		
		Set tReturn = tHeader
		If pLocalize {
			// DTB827 - Resolve the header with the appropriate domain. The domain supplied in 
			// the original text takes precedence, pDomain is the default domain if none is
			// explicitly declared.
			Set tDomain = pTextMacroTokens.%Get(6)
			Set:(tDomain="") tDomain = pDomain
			
			If (tDomain'="") {
				Set tResolveString = tHeader_"/"_tDomain
				Set tReturn =  ##class(%DeepSee.UserPortal.Utils).%ResolveText("$$$"_tResolveString)
			}
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tReturn = ""
	}
	
	Quit tReturn
}

}
