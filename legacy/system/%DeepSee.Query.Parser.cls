/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occUtility, %DeepSee)

/// Contains the DeepSee MDX query parser and related APIs.<br/>
/// This class contains no publicly accessible code.
Class %DeepSee.Query.Parser Extends %RegisteredObject [ System = 3 ]
{

/// Debug flag.
Property Trace As %Boolean [ InitialExpression = 0 ];

/// Query text.
Property Text As %String;

/// Current position within query text.
Property Position As %Integer;

/// Most recently parsed token (used for error reporting).
Property LastToken As %String;

/// Indicates the current tokens are within the %SEARCH context
Property InSearch As %Boolean [ InitialExpression = 0 ];

/// Current bookmark position within query text.
Property Bookmark As %Integer;

/// Context stack.
Property %Stack As %Integer [ MultiDimensional ];

/// The query object this parser is constructing.
Property Query As %DeepSee.Query.query;

/// Cubename within the current query.
Property CubeName As %DeepSee.Datatype.entityName;

/// Simple MDX parser.
/// Convert the MDX query in <var>pText</var> into a set of
/// DeepSee query objects (applied to <var>pQuery</var>).<br/>
/// If <var>pQuery</var> is not supplied, a new query object is created and returned.
ClassMethod %ParseMDX(pText As %String, pQuery As %DeepSee.Query.query = "", pTrace As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {		// DTB554 - Wrap in a Try block
		If ($ZSTRIP(pText,"<>W") = "") {
			Set tSC = $$$ERROR($$$GeneralError,"No query provided.")
			Quit
		}

		Set tParser = ..%New(pText)
		Set tParser.Trace = pTrace
		If ('$IsObject(pQuery)) {
			Set pQuery = ##class(%DeepSee.Query.query).%New()
		}
		
		// DTB720 - Add preliminary text validation
		Set tSC = tParser.%ValidateText(.pQuery)
		If $$$ISERR(tSC) Quit
		
		Set tSC = tParser.%ParseStatement(.pQuery)
		If $$$ISERR(tSC) Quit
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Simple MDX expression parser.
/// Convert the MDX expression in <var>pExpression</var> into a set of
/// DeepSee query objects (applied to <var>pGroup</var>).<br/>
/// <var>pQuery</var> is the outer query context which is calling this.
/// <var>pCube</var> is an optional cube to query, otherwise the one in the query context is used.
ClassMethod %ParseMDXExpression(pText As %String, pQuery As %DeepSee.Query.query, pGroup As %DeepSee.Query.group, Output pNode As %DeepSee.Query.node, pCube As %String = "") As %Status [ Internal ]
{
	Set tParser = ..%New(pText)
	Set tParser.Trace = 0
	Set tParser.Query = pQuery
	Set tOrigCubeName = pQuery.cube
	If (pCube'="") {	
		Set tParser.CubeName = pCube
		Set pQuery.cube = pCube
	}
	Else {
		Set tParser.CubeName = pQuery.cube
	}

	Set tSC = tParser.%ParseMEMBER(pGroup, .pNode, "", 3)
	If (pCube'="") {	
		Set pQuery.cube = tOrigCubeName
	}
	Quit tSC
}

/// Take the text in <var>pText</var> and convert it to a list of tokens using MDX grammar:
/// pTokens(n) = $LB(type,value)
ClassMethod %Tokenize(pText As %String, Output pTokens As %List) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tParser = ..%New(pText)
		While ('tParser.%AtEnd()) {
			Set tToken = tParser.%NextToken(.tType,.tSC)
			If $$$ISERR(tSC) Quit
			Set pTokens($I(n)) = $LB(tType,tToken)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if we are the end of the statement.
Method %AtEnd() As %Boolean [ CodeMode = expression, Internal ]
{
..Position > $L(..Text)
}

/// Bookmark the current parsing position.<br/>
/// This allows us to push a token back onto the incoming stream.
Method %SetBookmark() [ Internal ]
{
	Set ..Bookmark = ..Position
}

/// Revert to last set bookmark.
Method %GotoBookmark() [ Internal ]
{
	Set ..Position = ..Bookmark
}

/// Push the current parsing state and use
/// <var>pText</var> as a token source.
Method %PushContext(pText As %String) [ Internal ]
{
	Set:'$D(..%Stack) ..%Stack = 1
	Set ..%Stack(..%Stack,"Position") = ..Position
	Set ..%Stack(..%Stack,"Text") = ..Text
	Set ..%Stack(..%Stack,"Bookmark") = ..Bookmark
	Set ..%Stack(..%Stack,"LastToken") = ..LastToken
	Set ..%Stack = ..%Stack + 1
	Set ..Position = 1
	Set ..Text = pText
	Set ..Bookmark = 1
}

/// Pop the current parsing state restore the prior state.
Method %PopContext() [ Internal ]
{
	Set ..%Stack = ..%Stack - 1
	Set ..Position = ..%Stack(..%Stack,"Position")
	Set ..Text = ..%Stack(..%Stack,"Text")
	Set ..Bookmark = ..%Stack(..%Stack,"Bookmark")
	Set ..LastToken = ..%Stack(..%Stack,"LastToken")
}

/// Test if char is a special character
ClassMethod %IsSpecialChar(char As %String) As %Boolean [ CodeMode = expression, Internal ]
{
",,,{,},.,(,),',:,'," [ (","_char_",")
}

/// Test if token is a special token
ClassMethod %IsArrowToken(token As %String) As %Boolean [ CodeMode = expression, Internal ]
{
",->," [ (","_token_",")
}

/// Test if char is a part of an operator name
ClassMethod %IsOperatorChar(char As %String) As %Boolean [ CodeMode = expression, Internal ]
{
",+,-,*,/,<,>,=,&,|,!," [ (","_char_",")
}

/// Test if token is an operator name.
ClassMethod %IsOperatorToken(token As %String) As %Boolean [ CodeMode = expression, Internal ]
{
",+,-,*,/,<,>,=,>=,<=,<>,AND,OR,XOR,NOP," [ (","_token_",")
}

/// Test if token is a unary operator name.
ClassMethod %IsUnaryOperatorToken(token As %String) As %Boolean [ CodeMode = expression, Internal ]
{
",+,-," [ (","_token_",")
}

/// Test whether <var>pIdent</var> is a quoted identifier.
ClassMethod %IsQuotedIdent(pIdent As %String) As %Boolean [ CodeMode = expression, Internal ]
{
(($E(pIdent)="[")&&($E(pIdent,*)="]"))
}

/// Return the string portion of a quoted identifier.
ClassMethod %UnquoteIdent(pIdent As %String) As %String [ CodeMode = expression, Internal ]
{
$S(..%IsQuotedIdent(pIdent):$E(pIdent,2,*-1),1:pIdent)
}

/// Return a quoted version of the given identifier.
/// Ignore special "&" character as well as @namedParms
/// Do not add quotes if pIdent is already bounded by a [] pair
ClassMethod %QuoteIdent(pIdent As %String) As %String [ CodeMode = expression, Internal ]
{
$S($E(pIdent)="@":pIdent,..%IsQuotedIdent(pIdent):pIdent,pIdent="&":pIdent,1:"["_pIdent_"]")
}

/// Return a quoted version of the given identifier. Do not check to see if the identifier is already quoted
/// Ignore special "&" character as well as @namedParms
ClassMethod %QuoteTrustedIdent(pIdent As %String) As %String [ CodeMode = expression, Internal ]
{
$S($E(pIdent)="@":pIdent,pIdent="&":pIdent,1:"["_pIdent_"]")
}

/// Return a spec with escaped identifiers, translating each "]" into a
/// "]]" to escape the closing quote. The argument <var>pIdentifierList</var>
/// may be a list of any length. The method will terminate construction upon
/// encountering the first null entry in the list.<br>
/// The <var>pIncludeKey</var> flag can be used to add a "&[]"-enclosed key as
/// the final pice of the spec generated from the <var>pIdentifierList</var>. By default the method
/// will asume no key is included in the list.
ClassMethod %BuildEscapedSpec(pIdentifierList As %List, Output pStatus As %Status, pIncludeKey As %Boolean = 0) As %String
{
	// Method added by DTB247
	Set pStatus = $$$OK
	Set tReturnSpec = ""
	Try {
		Set tIdListLength = $LL(pIdentifierList)
		Set tIsKey = 0
		For ii=1:1:tIdListLength {
			Set:((ii=tIdListLength) && (pIncludeKey)) tIsKey = 1
			
			Set tIdentifier = $LG(pIdentifierList,ii)
			If (tIdentifier="") {
				Quit
			}
			Else {
				Set tReturnSpec = tReturnSpec _ $S($L(tReturnSpec):".",1:"") _ $S(tIsKey:"&[",1:"[") _ $$$dsEscapeIdent(tIdentifier) _"]"
			}
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tReturnSpec = ""
	}
	Quit tReturnSpec
}

/// Return next token within the query text and its type.
/// Type can be NUM[ber], LIT[eral], STR[ing], QSTR, OP[erator], SPEC[ial], END.
/// If there are comments, they are removed.
Method %NextToken(Output pType As %String, Output tSC As %Status) As %String [ Internal ]
{
	Set tToken = ""
	Set tSC = $$$OK
	Set pType = "END"
	Set tDone = 0
	Set tState = 0
	Set tInComment = 0	// 1=/**/  2= //,--
	Set tBracketCount = 0
	If ($$$UPPER(..LastToken)="[%SEARCH]")||($$$UPPER(..LastToken)="%SEARCH") {
		// DTB087 - tokens will be processed with special consideration for %SEARCH syntax
		Set ..InSearch=1
	}

	While ('tDone) {
		Set ..Position = ..Position + 1
		Set ch = $E(..Text,..Position)
		If (ch = "") Quit

		// first check for comments
		If (tInComment = 1) {
			If (ch = "*") {
				Set tTest = ch _ $E(..Text,..Position+1)
				If (tTest="*/") {
					Set ..Position = ..Position + 1
					Set tInComment = 0
				}
			}
			Continue
		}
		ElseIf (tInComment = 2) {
			If (ch=$C(10)) {
				Set tInComment = 0
			}
			Continue
		}
		Else {
			// JMD1392 do not allow comment inside of [...]
			If (pType'="QSTR") {
				If ((ch = "/")||(ch="-")) {
					Set tTest = ch _ $E(..Text,..Position+1)
					If (tTest="/*") {
						Set tInComment = 1
					}
					ElseIf ((tTest="//")||(tTest="--")) {
						Set tInComment = 2
					}
				}
			}
			If (tInComment) {
				Continue
			}
		}

		If (ch = $C(10)) { Set ch=" " }
		If (tState = 0) {
			If ($IsValidNum(ch)) {
				Set pType = "NUM"
				Set tToken = ch
				Set tState = 1
			}
			ElseIf ($ZSTRIP(ch,"<>W")="") {
			}
			ElseIf (ch="@") {
				// test for named parameter
				// peek ahead for @@ escape
				Set tPeek = $E(..Text,..Position+1)
				If (tPeek = "@") {
					Set pType = "STR"
					Set tState = 3
					Set tToken = ""
				}
				Else {
					Set pType = "STR"
					Set tToken = "@"
					Set tState = 5
				}
			}
			ElseIf (ch="'") {
				// peek ahead for '' escape
				Set tPeek = $E(..Text,..Position+1)
				If (tPeek = "'") {
					Set ..Position = ..Position + 1
					Set pType = "LIT"
					Set tToken = "'"
					Set tDone = 1
				}
				Else {
					Set pType = "SPEC"
					Set tToken = ch
					Set tDone = 1
				}
			}
			ElseIf (ch="[") {
				Set pType = "QSTR"
				Set tToken = ch
				Set tState = 2
				Set tBracketCount = 1
			}
			ElseIf (ch="""") { // string literal
				Set pType = "LIT"
				Set tToken = ""
				Set tState = 4
			}
			ElseIf (..%IsSpecialChar(ch)) {
				Set pType = "SPEC"
				Set tToken = ch
				Set tDone = 1
			}
			ElseIf (..%IsOperatorChar(ch)) {
				Set pType = "OP"
				Set tToken = ch
				Set tDone = 1

				// peek ahead for 2-character op
				Set tPeek = $E(..Text,..Position+1)
				If (..%IsOperatorToken(tToken_tPeek)) {
					Set ..Position = ..Position + 1
					Set tToken = tToken _ tPeek
				}
			}
			Else {
				Set pType = "STR"
				Set tState = 3
				Set tToken = ch
			}
		}
		ElseIf (tState = 1) { // NUM
			// E- !!!
			If ($IsValidNum(ch) || (ch="E") || (ch="e")) {
				Set tToken = tToken _ ch
				If ('$IsValidNum(tToken)) {
					Set tSC = ..%Error("Invalid number",tToken)
					Quit
				}
			}
			ElseIf (ch = ".") {
				// look ahead to see if this is a floating point number
				Set tPeek = $E(..Text,..Position+1)
				If ($IsValidNum(tPeek)) {
					Set tToken = tToken _ ch
				}
				Else {
					// treat token as integer
					Set ..Position = ..Position - 1 // go back
					Set tDone = 1
				}
			}
			ElseIf (ch="%") {
				// special handling for nn%
				Set tToken = tToken / 100
				// normalize!
				If ((tToken<1)&&(tToken>0)) {
					Set tToken = "0"_tToken
				}
				Set tDone = 1
			}
			ElseIf (($ZSTRIP(ch,"<>W")="")||..%IsOperatorChar(ch)||..%IsSpecialChar(ch)) {
				Set ..Position = ..Position - 1 // go back
				Set tDone = 1
			}
			Else {
				Set tToken = tToken _ ch
				If ('$IsValidNum(tToken)) {
					Set tSC = ..%Error("Invalid number",tToken)
					Quit
				}
			}
		}
		ElseIf (tState = 2) { // QSTR (look for matching ])
			If (ch="[") {
				// This is enclosed in [] and therefore is considered escaped, unless it follows a [%SEARCH]
				// Track the bracket nesting in the %SEARCH case to determine when the search term is closed
				If ..InSearch  {
					Set tBracketCount = tBracketCount + 1
				}
				Set tToken = tToken _ ch
			}
			ElseIf (ch="]") {
				Set tPeek = $E(..Text,..Position+1)

				If ((tPeek = "]")) { // JSL4415 replace JMD's code in this if quoted ]
					// rely on JMD1392 to "quote" internal "]" brackets.
					// Note well that ]] becomes ] JSL4415
					// DTB087 - an escaped ] has no effect on the bracket count
					Set ..Position = ..Position + 1
					Set tToken = tToken _ "]"
				}
				Else {
					Set tBracketCount = tBracketCount - 1
					Set tToken = tToken _ ch
					// JMD982: if we take the test for tBracketCount then we will handle [
					// within an ident correctly, *but* search expressions will be broken.
					If (tBracketCount=0) {
						Set ..InSearch=0	// DTB087 - release search mode once all nested brackets are closed
						Set tDone = 1
					}
				}
			}
			ElseIf (ch="{") {
				Set tToken = tToken _ ch
				Set tState = "2a"
			}
			ElseIf (ch="'") { // JSL4447
				Set tToken = tToken _ ch
				If ..InSearch {
					// DTB087 - this is a string literal in a search term, use JSL4447
					Set tState = "2b"
				}
			}
			Else {
				Set tToken = tToken _ ch
			}
		}
		ElseIf (tState = "2a") { // QSTR {
			If (ch="}") {
				Set tToken = tToken _ ch
				Set tState = 2
			}
			Else {
				Set tToken = tToken _ ch
			}
		}
		ElseIf (tState = "2b") { // [' JSL4447
			If (ch = "'") {
				Set tToken = tToken _ ch
				Set tPeek = $E(..Text, ..Position+1)
				If (tPeek = "'") {
					Set p = p + 1
					Set tToken = tToken _ tPeek
				}
				Else {
					Set tState = 2
				}
			}
			Else {
				Set tToken = tToken _ ch
			}
		}
		ElseIf (tState = 3) { // STR
			If (($ZSTRIP(ch,"<>W")="")||..%IsOperatorChar(ch)||..%IsSpecialChar(ch)) {
				// +PFS012 - Check for special token
				// peek ahead for 2-character op
				Set tPeek = $E(..Text,..Position+1)
				If (..%IsArrowToken(ch_tPeek)) {
					Set ..Position = ..Position + 1
					Set tToken = tToken _ ch _ tPeek
				} Else {				
					Set ..Position = ..Position - 1 // go back

					If ($E(tToken)="@") {
						// escape @, convert to QSTR
						Set pType = "QSTR"
						Set tToken = "["_tToken_"]"
					}
					ElseIf (..%IsOperatorToken($$$UPPER(tToken))) {
						// op name (e.g., "AND").
						Set pType = "OP"
						Set tToken = $$$UPPER(tToken)
					}
					Set tDone = 1
				}
				// -PFS012
			}
			Else {
				Set tToken = tToken _ ch
			}
		}
		ElseIf (tState = 4) { // String LIT
			If (ch = """") {
				Set tPeek = $E(..Text,..Position+1)
				If (tPeek = """") {
					// quoted ""
					Set ..Position = ..Position + 1
					Set tToken = tToken _ """"
				}
				Else {
					Set tDone = 1
				}
			}
			Else {
				Set tToken = tToken _ ch
			}
		}
		ElseIf (tState = 5) { // Named parm
			If ((ch=" ")||..%IsSpecialChar(ch)||..%IsOperatorChar(ch)) {
				Set ..Position = ..Position - 1 // go back
				// validate named parm
				Set tSC = ..%ValidateNamedParm(tToken)
				If $$$ISERR(tSC) Quit
				Set tDone = 1
			}
			Else {
				Set tToken = tToken _ ch
			}
		}
	}
	If $$$ISERR(tSC) Quit tSC

	If ('tDone) {
		If (tState = 1) {
			If ('$IsValidNum(tToken)) {
				Set tSC = ..%Error("Invalid number",tToken)
			}
		}
		ElseIf (tState = 5) {
			// named parm at end, validate
			Set tSC = ..%ValidateNamedParm(tToken)
			If $$$ISERR(tSC) Quit tSC
		}
		ElseIf ((tState'=3)) {
			If ($ZSTRIP(tToken,"<>W")'="") { 
				Set tSC = ..%Error("Unexpected end of statement",tToken)
			}
		}
	}

	If ((tToken = "")&&(pType="LIT")) {
		// convert literal "" to $C(0) to simplify later processing
		// later we will convert it back
		Set tToken = $C(0)
	}
	Set ..LastToken = tToken
	Quit tToken
}

/// Syntactically validate the given named parameter.
Method %ValidateNamedParm(pParmName As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	If ((pParmName="")||('$ZName($E(pParmName,2,*)))) {
		Set tSC = $$$ERROR($$$GeneralError,"Invalid named parameter: "_pParmName)
	}
	Quit tSC
}

/// Print a trace message if trace is enabled.
Method %Trace(pText As %String, pIndent As %Integer = 0) As %Boolean [ CodeMode = expression, Internal ]
{
$S(..Trace:..%TraceMsg(pText, pIndent),1:0)
}

/// Print out trace message (do not call directly).
Method %TraceMsg(pText As %String, pIndent As %Integer = 0) As %Boolean [ Internal ]
{
	Write ">> ",?pIndent,pText,!
	Quit 1
}

/// Construct a parser error message.
Method %Error(pMsg As %String, pToken As %String = "") As %Status [ Internal ]
{
	Set:pToken'="" ..LastToken = pToken
	Quit $$$ERROR($$$GeneralError,pMsg _ ": " _ "('" _ ..LastToken _ "' @pos " _ ..Position _ ")")
}

/// Parse an MDX statement.<br/>
/// Apply the results to <var>pQuery</var>.
Method %ParseStatement(pQuery As %DeepSee.Query.query) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set ..Query = pQuery
		Set ..CubeName = ""

		// Test first token in query
		// to find out what type of query OR to give a good error message
		Do ..%SetBookmark()
		Set tFirstToken = $$$UPPER(..%NextToken(.tType,.tSC))
		If $$$ISERR(tSC) Quit
	
		// look for leading %SHOWPLAN directive
		If (tFirstToken = "%SHOWPLAN") {
			Set pQuery.showPlan = 1
			Do ..%SetBookmark()
			Set tFirstToken = $$$UPPER(..%NextToken(.tType,.tSC))
			If $$$ISERR(tSC) Quit
		}

		If (tFirstToken = "CREATE") {
			Set pQuery.queryType = "CREATE"

			// test for SESSION
			Do ..%SetBookmark()
			Set tToken = $$$UPPER(..%NextToken(.tType,.tSC))
			If $$$ISERR(tSC) Quit
			If (tToken '= "SESSION") {
				Set tIsSession = 0
				Do ..%GotoBookmark()
			}
			Else {
				Set tIsSession = 1
				// n.b. SESSION is ignored!
			}

			// test for MEMBER or SET
			Set tTarget = ""
			Do ..%SetBookmark()
			Set tToken = $$$UPPER(..%NextToken(.tType,.tSC))
			If $$$ISERR(tSC) Quit
			If (tToken = "SET") {
				Set tTarget = "set"
			}
			ElseIf (tToken = "MEMBER") {
				Set tTarget = "member"
			}
			Else {
				Set tSC = ..%Error("CREATE can only be used for SETs or MEMBERs")
				Quit
			}

			// Get Cube name
			Do ..%SetBookmark()
			Set tToken = $$$UPPER(..%NextToken(.tType,.tSC))
			If $$$ISERR(tSC) Quit
			Set tCubeName = $$$UPPER(..%UnquoteIdent(tToken))
			Set ..CubeName = tCubeName
			Set ..Query.cube = tCubeName
			Set ..Query.%target = tTarget

			// Test cube name
			If ('##class(%DeepSee.Utils).%CubeExists(tCubeName,.x)) {
				Set tSC  = $$$ERROR($$$GeneralError,"Cannot find Subject Area: '"_tCubeName_"'")
				Quit
			}

			// test for .
			Do ..%SetBookmark()
			Set tToken = ..%NextToken(.tType,.tSC)
			If $$$ISERR(tSC) Quit
			If (tToken '= ".") {
				Set tSC = ..%Error("CREATE statement must specify a cube name")
				Quit
			}

			// now process definition (same as WITH clause)
			Set tSC = ..%ParseWITH(tTarget)
			If $$$ISERR(tSC) Quit
			
			// make sure there is no more text in the query
			Set tToken = ..%NextToken(.tType,.tSC)
			If (tToken '= "") {
				Set tSC = ..%Error("Unexpected text after CREATE statement: " _ tToken)
				Quit
			}
			Quit
		}
		ElseIf (tFirstToken = "DROP") {
			Set pQuery.queryType = "DROP"
			Set tTarget = ""

			// test for MEMBER or SET
			Do ..%SetBookmark()
			Set tToken = $$$UPPER(..%NextToken(.tType,.tSC))
			If $$$ISERR(tSC) Quit
			If (tToken = "SET") {
				Set tTarget = "set"
			}
			ElseIf (tToken = "MEMBER") {
				Set tTarget = "member"
			}
			Else {
				Set tSC = ..%Error("DROP can only be used for SETs or MEMBERs")
				Quit
			}

			// Get Cube name
			Do ..%SetBookmark()
			Set tToken = $$$UPPER(..%NextToken(.tType,.tSC))
			If $$$ISERR(tSC) Quit
			Set tCubeName = $$$UPPER(..%UnquoteIdent(tToken))
			Set ..CubeName = tCubeName
			Set ..Query.cube = tCubeName
			Set ..Query.%target = tTarget

			// Test cube name
			If ('##class(%DeepSee.Utils).%CubeExists(tCubeName,.x)) {
				Set tSC  = $$$ERROR($$$GeneralError,"Cannot find Subject Area: '"_tCubeName_"'")
				Quit
			}

			// test for .
			Do ..%SetBookmark()
			Set tToken = ..%NextToken(.tType,.tSC)
			If $$$ISERR(tSC) Quit
			If (tToken '= ".") {
				Set tSC = ..%Error("DROP statement must specify a cube name")
				Quit
			}

			// now get name
			Set tName = ""
			While ('..%AtEnd() && $$$ISOK(tSC)) {
				Do ..%SetBookmark()
				Set tToken = ..%NextToken(.tType,.tSC)
				If $$$ISERR(tSC) Quit
				If (tToken '= ".") {
					Set tToken = $$$UPPER(..%UnquoteIdent(tToken))
				}
				Set tName = tName _ tToken
			}
			Set ..Query.%targetKey = tName
			Quit
		}
		ElseIf ((tFirstToken = "DRILLTHROUGH")||(tFirstToken = "DRILLFACTS")) {
			Set pQuery.queryType = "DRILLTHROUGH"
			Set pQuery.%listingSource = $Case(tFirstToken,"DRILLFACTS":"facts",:"source")

			// test for MAXROWS
			Do ..%SetBookmark()
			Set tToken = $$$UPPER(..%NextToken(.tType,.tSC))
			If $$$ISERR(tSC) Quit
			If (tToken '= "MAXROWS") {
				Do ..%GotoBookmark()
			}
			Else {
				Set tMaxRows = ..%NextToken(.tType,.tSC)
				If $$$ISERR(tSC) Quit
				If ((tType'="NUM")||(+tMaxRows<=0)||(+tMaxRows'=(tMaxRows\1))) {
					Set tSC = ..%Error("The MAXROWS argument must be a positive integer: " _ tMaxRows)
					Quit
				}
				Set pQuery.%MaxListingRows = +tMaxRows
			}
		}
		ElseIf (tFirstToken = "%BITSET") {
			Set pQuery.queryType = "%BITSET"
		}
		ElseIf ((tFirstToken = "SELECT")||(tFirstToken = "WITH")) {
			Do ..%GotoBookmark()
		}
		Else {
			Set tSC = ..%Error("Unknown term at start of query: " _ tFirstToken)
			Quit
		}

		// look ahead and find the cube name
		// as we may need this to process the axes
		Do ..%SetBookmark()
		Set tCubeName = ""

		Set tState = 0
		Set tToken = ..%NextToken(.tType,.tSC)
		While ('..%AtEnd()) {
			Set tToken = ..%NextToken(.tType,.tSC)
			If $$$ISERR(tSC) Quit
			If (tState = 0) {
				If (tType = "END") {
					Quit
				}
				ElseIf ($$$UPPER(tToken) = "FROM") {
					Set tState = 1
				}
			}
			Else {
				Set tCubeName = $$$UPPER(..%UnquoteIdent(tToken))
				
				// +DTB130
				Set tVersion = ##class(%DeepSee.CubeVersion.Utils).%GetActiveCubeVersion(tCubeName)
				If (tVersion'="") {
					Do ..%Trace("Cube Version:" _ tVersion,5)
					Set tCubeName = ##class(%DeepSee.CubeVersion.Utils).%GetVersionedCubeName(tCubeName)
				} 
				// -DTB130
				Quit
			}
		}

		If (tCubeName = "") {
			Set tSC = ..%Error("Query has no FROM section or does not specify a cubename")
			Quit
		}
		If ('##class(%DeepSee.Utils).%CubeExists(tCubeName,.x)) {
			Set tSC  = $$$ERROR($$$GeneralError,"Cannot find Subject Area: '"_tCubeName_"'")
			Quit
		}
		Set ..CubeName = tCubeName
		Set ..Query.cube = tCubeName
		Do ..%GotoBookmark()

		Set tSC = ..%ParseWITH()
		If $$$ISERR(tSC) Quit
		
		// + WAL058 -- Second pass at calculated members to resolve dependencies
		Set tCmbrKey = ""
		For i=1:1:pQuery.calculatedMembers.Count() {
			set tCmbr = pQuery.calculatedMembers.GetNext(.tCmbrKey)
			do tCmbr.children.Clear()
			Set tSC = ##class(%DeepSee.Query.Parser).%ParseMDXExpression(tCmbr.definition,pQuery,tCmbr,.tNode)
			if $$$ISERR(tSC) Quit
			set tCmbr.isResolved=1
		}
		If $$$ISERR(tSC) Quit
		// - WAL058

		Set tSC = ..%ParseSELECT()
		If $$$ISERR(tSC) Quit

		If ..%AtEnd() {
			Set tSC = ..%Error("Query has no FROM section")
			Quit
		}

		Set tSC = ..%ParseFROM()
		If $$$ISERR(tSC) Quit
		If ..%AtEnd() Quit

		Set tSC = ..%ParseWHERE()
		If $$$ISERR(tSC) Quit
		If ..%AtEnd() Quit

		// ISC extension: there may be one or more %FILTER clauses
		// we will fold these into the slicer later
		Do ..%SetBookmark()
		Set tToken = ..%NextToken(.tType,.tSC)
		Do ..%GotoBookmark()
		While ($$$UPPER(tToken) = "%FILTER") {
			Set tSC = ..%ParseFILTER()
			If $$$ISERR(tSC) Quit
			If ..%AtEnd() Quit
			Do ..%SetBookmark()
			Set tToken = ..%NextToken(.tType,.tSC)
			Do ..%GotoBookmark()
		}
		If $$$ISERR(tSC) Quit

		If (pQuery.queryType = "DRILLTHROUGH") {
			Set tSC = ..%ParseRETURN()
			If $$$ISERR(tSC) Quit
		}
		If ..%AtEnd() Quit

		// there should be no more tokens
		Set tToken = ..%NextToken(.tType,.tSC)
		If (tToken '= "") {
			Set tSC = ..%Error("Unexpected term in query")
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Parse an MDX WITH statement.
/// If <var>pMode</var> is "with", then this is a WITH clause of a query;
/// If <var>pMode</var> is "set" or "member", then this is a CREATE statement;
Method %ParseWITH(pMode As %String = "with") As %Status
{
	Set tSC = $$$OK
	Do ..%Trace("ParseWITH")
	Try {
		// make sure cube is visible
		New %cube
		Set %cube = $$$UPPER(..CubeName)

		// list of valid parameter keywords
		Set tKeyWordNames("TYPE") = ""
		Set tKeyWordNames("CAPTION") = ""
		Set tKeyWordNames("VALUE") = ""
		Set tKeyWordNames("PRIVATE") = ""

		Set tState = $Case(pMode,"set":1,"member":5,:0)
		Set tEmpty = 1
		Set tHasQuotes = 0 // Expression wrapped with ''
		Set tMemberDef = ""
		Set tDirective = ""
		Set (tSetName,tMbrName,tDimName) = ""
		If (pMode = "with") {
			Do ..%SetBookmark()
			Set tToken = ..%NextToken(.tType,.tSC)
			If ($$$UPPER(tToken) '= "WITH") {
				Do ..%GotoBookmark()
				Quit
			}
		}

		While ('..%AtEnd() && $$$ISOK(tSC)) {
			Do ..%SetBookmark()
			Set tToken = ..%NextToken(.tType,.tSC)
			If $$$ISERR(tSC) Quit

			If (tState = 0) {
				Set tHasQuotes = 0
				If (pMode '= "with") {
					If (tToken '= "") {
						Do ..%GotoBookmark()
					}
					// create statement is complete
					Quit
				}

				If ($$$UPPER(tToken) = "SET") {
					Set tState = 1
					Set tEmpty = 0
					Set tSetName = ""
				}
				ElseIf ($$$UPPER(tToken) = "MEMBER") {
					Set tState = 5
					Set tEmpty = 0
					Set tMbrName = ""
					Set tDimName = ""
				}
				ElseIf ($$$UPPER(tToken) = "%PARM") {
					Set tState = 15
					Set tEmpty = 0
					Set tParmName = ""
					Kill tKeyWords
				}
				ElseIf ($$$UPPER(tToken) = "SELECT") {
					If (tEmpty) {
						Set tSC = ..%Error("Query has empty WITH section")
					}
					Else {
						Do ..%GotoBookmark()
					}
					Quit
				}
				Else {
					Set tSC = ..%Error("Expected MEMBER,SET,or %PARM in WITH section")
				}
			}
			ElseIf (tState = 1) { // SET
				If ((tType = "STR")||(tType = "QSTR")) {
					Set tSetName = $$$UPPER(tToken)
					If (tType = "QSTR") {
						Set tSetName = ..%UnquoteIdent(tSetName)
					}
					If ($D(tSetNames(tSetName))) {
						Set tSC = ..%Error("Named set defined more than once")
					}
					Set tSetNames(tSetName) = ""
					Set tState = 2
				}
				Else {
					Set tSC = ..%Error("Expected name for Named Set")
					Quit
				}
			}
			ElseIf (tState = 2) { // SET Name
				If ($$$UPPER(tToken) = "AS") {
					Set tState = 3
				}
				Else {
					Set tSC = ..%Error("Expected AS for Named Set")
				}
			}
			ElseIf (tState = 3) { // SET Name AS
				If ((tToken = "'")&&(tType="SPEC")) {
					Set tHasQuotes = 1
				}
				Else {
					Do ..%GotoBookmark()
					Set tHasQuotes = 0
				}

				Set tNamedSet = ##class(%DeepSee.Query.namedSet).%New()
				Set tNamedSet.name = tSetName
				Set tSC = ..%ParseMEMBER(tNamedSet, .tNode, $S(tHasQuotes:"'",1:""),3)
				If $$$ISERR(tSC) Quit
				Set tState = 4
				If '$IsObject(tNode) {
					Set tSC = ..%Error("Empty or invalid named set definition")
				}
				Else {
					// remember original definition
					Set tNamedSet.definition = tNode.%ToString()
					Do ..Query.namedSets.SetAt(tNamedSet,tSetName)
					Set tSetName = ""
				}
			}
			ElseIf (tState = 4) { // SET Name As '...'
				If (tHasQuotes) {
					If ((tToken = "'")&&(tType="SPEC")) {
						Set tState = 0
					}
					Else {
						Set tSC = ..%Error("Expected ' after SET in WITH section (4)")
					}
				}
				Else {
					If (tToken = "") {
						Set tState = 0
					}
				}
			}
			ElseIf (tState = 5) { // MEMBER
				// first we should get a dimension name
				If ((tType = "STR")||(tType = "QSTR")) {
					Set tDimName = $$$UPPER(tToken)
					If (tType = "QSTR") {
						Set tDimName = ..%UnquoteIdent(tDimName)
					}
					Set tState = 6
				}
				Else {
					Set tSC = ..%Error("Expected dimension name for Calculated Member")
				}
			}
			ElseIf (tState = 6) { // MEMBER: DIM
				If (tToken = ".") {
					Set tState = 7
				}
				Else {
					Set tSC = ..%Error("Expected . after DIMENSION name in WITH section")
				}
			}
			ElseIf (tState = 7) { // MEMBER: DIM.
				If ((tType = "STR")||(tType = "QSTR")) {
					Set tMbrName = $$$UPPER(tToken)
					Set tOrigMbrName = tToken
					If (tType = "QSTR") {
						Set tMbrName = ..%UnquoteIdent(tMbrName)
					}
					If ($D(tMbrNames(tDimName,tMbrName))) {
						Set tSC = ..%Error("Calculated member defined more than once")
					}
					Set tMbrNames(tDimName,tMbrName) = ""
					Set tState = 8
				}
				Else {
					Set tSC = ..%Error("Expected name for Calculated Member")
				}
			}
			ElseIf (tState = 8) { // MEMBER: DIM.MBR
				If ($$$UPPER(tToken) = "AS") {
					Set tState = 9
				}
				Else {
					Set tSC = ..%Error("Expected AS for Calculated Member")
				}
			}
			ElseIf (tState = 9) { // MEMBER DIM.MBR AS
				If (tToken = "'") {
					Set tHasQuotes = 1
				}
				Else {
					Do ..%GotoBookmark()
					Set tHasQuotes = 0
				}

				Set tCalcMbr = ##class(%DeepSee.Query.calculatedMember).%New()
				Set tCalcMbr.parentDimension = tDimName
				Set tCalcMbr.memberName = tMbrName
				Set tCalcMbr.originalName = tOrigMbrName
				Set tSC = ..%ParseMEMBER(tCalcMbr, .tNode, $S(tHasQuotes:"'",1:""),3)
				If $$$ISERR(tSC) Quit
				Set tState = 10
				If '$IsObject(tNode) {
					Set tSC = ..%Error("Empty or invalid calculated member definition")
				}
				Else {
					// remember original definition
					Set tCalcMbr.definition = tNode.%ToString()

					// mark member as unresolved: we will parse it again when we encounter it
					// this makes it possible for calc members to refer to one another regardless of the order
					// in which they are defined
					Set tCalcMbr.isResolved = 0
					Do tCalcMbr.children.Clear()

					Do ..Query.calculatedMembers.SetAt(tCalcMbr,tDimName_"."_tMbrName)
					Set tDimName = ""
					Set tMbrName = ""
				}
			}
			ElseIf (tState = 10) { // MEMBER DIM.MBR AS '...
				If (tToken = "'") {
					Set tState = 11
				}
				Else {
					Set tSC = ..%Error("Expected ' after MEMBER in WITH section")
				}
			}
			ElseIf (tState = 11) { // MEMBER DIM.MBR AS '...'
				If (tToken = ",") {
					Set tState = 12
				}
				Else {
					Do ..%GotoBookmark()
					Set tState = 0
				}
			}
			ElseIf (tState = 12) { // MEMBER DIM.MBR AS '...',
				If (($$$UPPER(tToken) = "SOLVE_ORDER")||($$$UPPER(tToken) = "FORMAT_STRING")) {
					Set tDirective = $$$UPPER(tToken)
					Set tState = 13
				}
				Else {
					Set tSC = ..%Error("Expected SOLVE_ORDER or FORMAT_STRING after MEMBER in WITH section")
				}
			}
			ElseIf (tState = 13) { // MEMBER DIM.MBR AS '...', SOLVE_ORDER|FORMAT_STRING
				If (tToken = "=") {
					Set tState = 14
				}
				Else {
					Set tSC = ..%Error("Expected '=' after directive in WITH section")
				}
			}
			ElseIf (tState = 14) { // MEMBER DIM.MBR AS '...', <directive> = 
				If (tDirective = "SOLVE_ORDER") {
					If (tType = "NUM") {
						If ((tToken<0)||(tToken'=(tToken\1))) {
							Set tSC = ..%Error("SOLVE_ORDER value must be a positive integer")
						}
						Else {
							Set tCalcMbr.solveOrder = tToken	
							Set tState = 11
						}
					}
					Else {
						Set tSC = ..%Error("Expected Integer after SOLVE_ORDER in WITH section")
					}
				}
				ElseIf (tDirective = "FORMAT_STRING") {
					If (tToken = "'") {
						Set tFormat = ""
						Set tState = 30
					}
					Else {
						Set tSC = ..%Error("Expected Single-quoted string after FORMAT_STRING in WITH section")
					}
				}
			}
			ElseIf (tState = 30) { // FORMAT_STRING
				If (tToken = "'") {
					Set tCalcMbr.formatString = tFormat
					Set tState = 11
				}
				Else {
					Set tFormat = tFormat _ tToken
				}
			}
			ElseIf (tState = 15) { // %PARM
				// first we should get a parameter name
				If ((tType = "STR")||(tType = "QSTR")) {
					Set tParmName = $$$UPPER(tToken)
					If (tType = "QSTR") {
						Set tParmName = ..%UnquoteIdent(tParmName)
					}
					Set tState = 16
				}
				Else {
					Set tSC = ..%Error("Expected name for query parameter")
				}
			}
			ElseIf (tState = 16) { // %PARM x
				If ($$$UPPER(tToken) = "AS") {
					Set tState = 17
				}
				Else {
					Set tSC = ..%Error("Expected AS for query parameter")
				}
			}
			ElseIf (tState = 17) { // %PARM x AS
				If (tToken = "'") {
					Set tState = 18
				}
				Else {
					Set tSC = ..%Error("Expected ' after %PARM in WITH section")
				}
			}
			ElseIf (tState = 18) { // %PARM x AS '
				// look for keyword:value;
				If (tToken = "'") {
					// add parameter to query
					If ($D(..Query.%NamedParameters(tParmName))) {
						// ??? perhaps this is ok?
						Set tSC = ..%Error("%PARM defined more than once in WITH section",tParmName)
					}
					ElseIf ('$ZName(tParmName)) {
						Set tSC = ..%Error("Invalid %PARM name in WITH section",tParmName)
					}
					Else {
						Set ..Query.%NamedParameters(tParmName) = ""
						Merge ..Query.%NamedParameters(tParmName) = tKeyWords
						Set tState = 22
					}
				}
				ElseIf ((tType="STR")||(tType="QSTR")) {
					Set tState = 19
					Set tKeyWord = $$$UPPER(tToken)
					Set tValue = ""
					Set tLastVToken = ""
					If (tType = "QSTR") {
						Set tKeyWord = ..%UnquoteIdent(tKeyWord)
					}
				}
				Else {
					Set tSC = ..%Error("Expected %PARM keyword in WITH section")
				}
			}
			ElseIf (tState = 19) { // %PARM x AS 'keyword
				If (tToken = ":") {
					Set tState = 20
				}
				Else {
					Set tSC = ..%Error("Expected ':' after %PARM keyword in WITH section")
				}
			}
			ElseIf (tState = 20) { // %PARM x AS 'keyword:
				If ((tToken = "'")||(tToken = ",")) {
					// validate keyword
					If '$D(tKeyWordNames(tKeyWord)) {
						Set tSC = ..%Error("Unrecognized %PARM keyword in WITH section",tKeyWord)
					}
					ElseIf $D(tKeyWords(tKeyWord)) {
						Set tSC = ..%Error("%PARM keyword defined more than once in WITH section",tKeyWord)
					}
					Else {
						Set tKeyWords(tKeyWord) = tValue
						If (tToken = "'") {
							Do ..%GotoBookmark()
						}
						Set tState = 18
					}
				}
				ElseIf ((tType="STR")||(tType="QSTR")) {
					If (tLastVToken'="") {
						Set tSC = ..%Error("Invalid value for %PARM in WITH section",tValue)
					}
					Else {
						Set tValue = tValue_tToken
	 					Set tLastVToken = tValue
					}
				}
				ElseIf ((tType="LIT")||(tType="NUM")) {
					If (tLastVToken'="") {
						Set tSC = ..%Error("Invalid value for %PARM in WITH section",tValue)
					}
					Else {
						Set tValue = tValue_tToken
	 					Set tLastVToken = tValue
					}
				}
				ElseIf (tToken = "{") { // COS expression
					Set tValue = tToken
					Set tState = 23
				}
				Else {
					// accumulate
					Set tValue = tValue_tToken
 					Set tLastVToken = ""
				}
			}
			ElseIf (tState = 22) { // %PARM x AS '...'
				If (tToken = ",") {
					Set tState = 0
				}
				Else {
					Do ..%GotoBookmark()
					Set tState = 0
				}
			}
			ElseIf (tState = 23) { // %PARM x AS 'kw:{
				If (tToken = "}") {
					Set tValue = tValue _ "}"
					Set tState = 21
				}
				Else {
					Set tValue = tValue _ tToken
				}
			}
		}
		
		// DTB630 - Immediately record the explicit WITH clause. This should occur before the shared calculated members are resolved.
		Set ..Query.%originalWITHContents = ..Query.%WITHToString()
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Parse an MDX SELECT statement.
Method %ParseSELECT() As %Status [ Internal ]
{
	Set tSC = $$$OK
	Do ..%Trace("ParseSELECT")
	Try {
		Set tToken = ..%NextToken(.tType,.tSC)
		If ($$$UPPER(tToken) '= "SELECT") {
			Set tSC = ..%Error("Query has no SELECT section")
			Quit
		}

		// process axes
		While(1) {
			Set tSC = ..%ParseAXIS(.tAxisNum, .tAxis)
			If $$$ISERR(tSC) Quit

			Do ..%Trace("Found Axis "_tAxisNum_":"_tAxis,5)

			If $D(tAxes(tAxisNum)) {
				Set tSC = ..%Error("More than one Axis with the same Axis number")
				Quit
			}
			Set tAxes(tAxisNum) = tAxis

			Do ..%SetBookmark()
			Set tToken = ..%NextToken(.tType,.tSC)
			If ($$$UPPER(tToken) = "FROM") {
				Do ..%GotoBookmark()
				Quit
			}
			ElseIf (tToken '= ",") {
				Set tSC = ..%Error("Expected 'FROM' or ',' at end of Axis specification")
				Quit
			}
		}
		If $$$ISERR(tSC) Quit

		// Add axes to query
		If ($D(tAxes)) {
			Set tAxisCount = 1+$O(tAxes(""),-1)
			Do ..%Trace("Axis Count: "_tAxisCount,5)
			For a = 0:1:(tAxisCount-1) {
				Set tAxis = $G(tAxes(a))
				If ('$IsObject(tAxis)) {
					// inject dummy axis
					Set tAxis = ##class(%DeepSee.Query.axis).%New()
					Do ..%Trace("Create Dummy Axis "_a_":"_tAxis,10)
				}
				Do ..Query.axes.Insert(tAxis)
				Do ..%Trace("Insert Axis "_a_":"_tAxis,5)
			}
		}	
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Parse an MDX Axis Specification statement.<br/>
/// <var>pMode</var> specifies context:
/// 0 = axis, 1 = slicer, 2 = %filter, (3 = named set).
Method %ParseAXIS(Output pAxisNum As %String, Output pAxis As %DeepSee.Query.axis, pMode As %Integer = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Do ..%Trace("ParseAXIS (")
	Try {
		Set pAxisNum = -1
		Set tState = 0
		Set tHasEmpty = 0
		Set pAxis = ##class(%DeepSee.Query.axis).%New()
		While ('..%AtEnd()) {
			Do ..%SetBookmark()
			Set tToken = ..%NextToken(.tType,.tSC)
			If $$$ISERR(tSC) Quit
			If (tToken ="") {
				Quit
			}
			If ((pMode=0) && ($$$UPPER(tToken) = "FROM")) {
				Do ..%GotoBookmark()
				Quit
			}
			ElseIf ((pMode'=0) && (..Query.queryType="DRILLTHROUGH") && (($$$UPPER(tToken) = "RETURN")||($$$UPPER(tToken) = "%LISTING"))) {
				Do ..%GotoBookmark()
				Quit
			}

			If (tState = 0) {
				If ((pMode=0) && ($$$UPPER(tToken) = "ON")) {
					Set tState = 1
				}
				ElseIf ((pMode=0) && ($$$UPPER(tToken) = "NON")) {
					If (tHasEmpty) {
						Set tSC = ..%Error("Unexpected NON keyword in statement")
						Quit
					}
					Set tState = 5
				}
				ElseIf ((pMode=0) && ($$$UPPER(tToken) = "EMPTY")) {
					If (tHasEmpty) {
						Set tSC = ..%Error("Duplicate EMPTY keyword in statement")
						Quit
					}
					Set tHasEmpty = 1
					Set pAxis.nonEmpty = 0
				}
				Else {
					Do ..%GotoBookmark()
					Set tSC = ..%ParseMEMBER(pAxis, .tNode, $S(pMode'=0:$S(..Query.queryType="DRILLTHROUGH":"RETURN",1:""),1:"ON"),$S(pMode=2:1,1:pMode))  // treat filter as WHERE
					If $$$ISERR(tSC) Quit
					Set tState = 6
				}
			}
			ElseIf (tState = 1) { // ON
				If ($$$UPPER(tToken) = "AXIS") {
					Set tState = 2
				}
				ElseIf ($IsValidNum(tToken)) {
					If ((tToken '= (tToken\1)) || (tToken<0)) {
						Set tSC = ..%Error("Axis number must a non-negative integer")
					}
					ElseIf (tToken>6) {
						Set tSC = ..%Error("Axis number must be less than 6")
					}
					Else {
						Set pAxisNum = +tToken
					}
					Quit
				}
				Else {
					// convert name to number
					Set n = $Case($$$UPPER(tToken),"COLUMNS":0,"ROWS":1,"PAGES":2,"CHAPTERS":3,"SECTIONS":4,:-1)
					If (n < 0) {
						Set tSC = ..%Error("Invalid axis name keyword")
					}
					Else {
						Set pAxisNum = n
					}
					Quit
				}
			}
			ElseIf (tState = 2) { // AXIS
				If ($$$UPPER(tToken) = "(") {
					Set tState = 3
				}
				Else {
					Set tSC = ..%Error("Invalid Axis Statement")
				}
			}
			ElseIf (tState = 3) { // AXIS(
				If ($IsValidNum(tToken)) {
					If ((tToken '= (tToken\1)) || (tToken<0)) {
						Set tSC = ..%Error("Axis number must a non-negative integer")
						Quit
					}
					Else {
						Set pAxisNum = +tToken
						Set tState = 4
					}
				}
				Else {
					Set tSC = ..%Error("Expected axis number")
				}
			}
			ElseIf (tState = 4) { // AXIS(#
				If (tToken '= ")") {
					Set tSC = ..%Error("Expected closing ) after axis number")
				}
				Quit
			}
			ElseIf (tState = 5) { // NON
				If ($$$UPPER(tToken) = "EMPTY") {
					Set tHasEmpty = 1
					Set pAxis.nonEmpty = 1
					Set tState = 0
				}
				Else {
					Set tSC = ..%Error("Invalid token after NON")
					Quit
				}
			}
			ElseIf (tState = 6) { // ...MEMBER
				If ((pMode=0) && ($$$UPPER(tToken) = "ON")) {
					Set tState = 1
				}
				ElseIf (pMode=0) {
					Set tSC = ..%Error("Expected ON in Axis")
					Quit
				}
				Else {
					Do ..%GotoBookmark()
					Quit
				}
			}
		}
		If $$$ISERR(tSC) Quit

		If (pAxis.children.Count() = 0) {
			If (pMode = 1) {
				Set tSC = ..%Error("Empty or invalid WHERE clause")
			}
			ElseIf (pMode = 2) {
				Set tSC = ..%Error("Empty or invalid %FILTER clause")
			}
			Quit
		}
		
		// DTB847 - Do not resolve memberSpecs in this fetch of the string
		New %dsQueryPrepare
		Set %dsQueryPrepare = 1
		Set pAxis.%originalSpec = pAxis.%ToString()		// DTB818 - Store original text of this axis for later reference
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Do ..%Trace("ParseAXIS )")
	Quit tSC
}

/// Parse a member expression within an MDX axis.<br/>
/// This can be a simple member specifier: "[Measures].[Sales]"<br/>
/// A range: "[Time].[2005]:[Time].[2008]"<br/>
/// or an expression: "[Measures].[Sales]>100*[Measures].[X]"<br/>
/// The member expression can contain a function: "FILTER(A.B,C.D)"<br/>
/// or a set: "{A.A,B.B}"<br/>
/// or a range: "{A.A:A.B}"<br/>
/// or a tuple: "(A.A,B.B)"<br/>
/// or some combination of these.<br/>
/// On return, <var>pNode</var> is the newly created query object
/// along with whatever children it needs..<br/>
/// <var>pCloseToken</var> is the token expected to end the tuple
/// (such as ")" for a function).<br/>
/// <var>pMode</var> specifies context:
/// 0 = axis, 1 = slicer, 2 = %filter, 3 = named set.<br/>
/// n.b., mode 2 is not used!
/// If <var>pFlags</var> is present, it contains the set of valid function flags
/// (we are parsing a function call in this case)...
Method %ParseMEMBER(pParent As %DeepSee.Query.group, Output pNode As %DeepSee.Query.node, pCloseToken As %String, pMode As %Integer, ByRef pFlags As %String, pLevel As %Integer = 1) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Do ..%Trace("ParseMEMBER ( "_pMode)
	Try {
		// read tokens until the end of the member definition
		// and stack them up.
		// then pop them and build a tree of query objects
		// if we run into () or F(), then process recursively
		// if we run into A.B.func, then create func(A.B)
		Set pNode = ""
		Set tCurrTuple = ""
		Set tExpression = ""
		Set tSpec = ""		// member spec currently being processed
		Set tIsMember = 0 // current spec *could* be a member: A.B
		Set tSpecList = ""	 // array of items within current member spec
		Set tSpecCount = 0
		Set tRangeSpecList = ""	 // array of items within first part of range (if any)
		Set tRangeSpecCount = 0

		Set tState = 0
		Set tParenCount = 0
		Set tNextSlot = 0 // list of "tokens"
		Kill tTokenList,tNodeList // lists of tokens,objects
		Set tLastToken = ""
		Set tLocalToken = ""
		Set tPossibleUnary = 1	// used to detect unary v. binary: "-A" v. "(A+A)-A"

		While ($$$ISOK(tSC)) {
			Do ..%SetBookmark()

			Set tToken = ..%NextToken(.tType,.tSC)
			If $$$ISERR(tSC) Quit

			// JMD1140: make sure we catch %LISTING as a close token
			If ((pCloseToken="RETURN")&&(tToken="%LISTING")) {
				Set tToken = "RETURN"
			}

			// $$$DSWRITELN($J(pLevel,pLevel)_" MEMBER>>> "_tState_":{"_tToken_"} "_tType_" "_tParenCount)

			If (tState = 0) {
				If ((($$$UPPER(tToken) = pCloseToken)&&(tType'="LIT"))||((tToken=",")&&(tType'="LIT"))||((pMode'=2)&&($$$UPPER(tToken)="%FILTER"))||(tToken="")) {
					If ((tToken=")")&&(tParenCount>0)) {
						Set tParenCount = tParenCount - 1
						Do Append(tToken,tType,1)
					}
					Else {
						Do ..%GotoBookmark() // unread
						Quit
					}
				}
				ElseIf (tToken = "(") {
					// could be tuple (A,B) 
					// or an expression(A+B), peek ahead to figure it out
					Set tIsTuple = $S(pMode=2:0,1:1) // mode 2 is always an expression (not used!)
					Set tTokNo = 0
					Set tTestParenCount = 1
					Do ..%SetBookmark()
					While (pMode'=2) { // while(1)
						Set tNextToken = ..%NextToken(.tNextType,.tSC)
						If $$$ISERR(tSC) Quit
						Set tTokNo = tTokNo + 1
						If (tNextToken = "") {
							Quit
						}
						ElseIf (tNextToken = "(") {
							Set tTestParenCount = tTestParenCount + 1
						}
						If (tNextToken = ")") {
							Set tTestParenCount = tTestParenCount - 1
							If (tTestParenCount = 0) {
								If (tTokNo = 1) {
									Set tSC = ..%Error("Empty () in expression")
								}
								Quit
							}
						}
						ElseIf ((tNextToken = ",")&&(tTestParenCount=1)) {
							Set tIsTuple = 1
							Quit
						}
						ElseIf (tNextType = "OP")  {
							Set tIsTuple = 0
						}
						ElseIf ((tTokNo=1)&&(tNextType = "NUM"))  {
							Set tIsTuple = 0
						}
					}
					If $$$ISERR(tSC) Quit
					Do ..%GotoBookmark() // unread
					If ('tIsTuple) {
						// push (
						Set tParenCount = tParenCount + 1
						Do Append(tToken,tType,2)
						Set tPossibleUnary = 1
					}
					Else {
						// start of tuple specification
						Set tSet = ##class(%DeepSee.Query.tuple).%New()
						Do Append(tSet,"OBJ",3)
						While (1) {
							Set tSC = ..%ParseMEMBER(tSet,.tNode,")",pMode,,pLevel+1)
							If $$$ISERR(tSC) Quit
							// test next token
							Set tNextToken = ..%NextToken(.tNextType,.tSC)
							If $$$ISERR(tSC) Quit
							If (tNextToken = ")") {
								Quit
							}
							ElseIf (tNextToken '= ",") {
								Set tSC = ..%Error("Missing ')' in query (1)")
								Quit
							}
						}
						If $$$ISERR(tSC) Quit
						Set tState = 3
					}
				}
				ElseIf (tToken = ")") {
					Set tParenCount = tParenCount - 1
					Do Append(tToken,tType,4)
				}
				ElseIf (tToken = "{") {
					If (pMode=2) {
						Set tSC = ..%Error("'{' not allowed within %FILTER")
						Quit
					}
					// start of set
					Set tSet = ##class(%DeepSee.Query.set).%New()
					Do Append(tSet,"OBJ",5)
					While (1) {
						Set tSC = ..%ParseMEMBER(tSet,.tNode,"}",pMode,,pLevel+1)
						If $$$ISERR(tSC) Quit

						If '$IsObject(tNode) {
							Set tSC = ..%Error("Empty '{}' set in query")
							Quit
						}
						// test next token
						Set tNextToken = ..%NextToken(.tNextType,.tSC)
						If $$$ISERR(tSC) Quit
						If (tNextToken = "}") {
							Quit
						}
						ElseIf (tNextToken '= ",") {
							Set tSC = ..%Error("Missing '}' in query (1)")
							Quit
						}
					}
					If $$$ISERR(tSC) Quit
				}
				ElseIf (tToken = "}") {
					Set tSC = ..%Error("Unexpected '}' in query (1)")
					Quit
				}
				ElseIf ((tType = "QSTR")||(tType = "STR")) {
					// start assembling member spec
					Set tState = 1
					Set tSpec = tToken
					Set tRangeSpec = ""
					Kill tSpecList
					Kill tRangeSpecList
					Set tSpecCount = 0
					Set tRangeSpecCount = 0
					Set tSpecList($I(tSpecCount)) = tToken
					Set tIsMember = 0 // true when we *know* this is a member
					Set tIsRelation = 0

					// test for relationship
					If (##class(%DeepSee.Utils).%IsRelationship(..CubeName,..%UnquoteIdent(tToken))) {
						If ##class(%DeepSee.Query.setFunction).%GetFunctionInfo(tToken)||
							##class(%DeepSee.Query.scalarFunction).%IsScalarFunction(tToken) {
							// DTB286 - There is a name collision between a relationship and a function. 
							// Look at the next token to decide which of the two this ambiguous token is. 
							// Functions will always be followed by a "(", while relationships never will.
							Set tFunctionTestToken = ..%NextToken()
							
							// Rewind to the current Bookmark and reset the Position after looking ahead.
							Do ..%GotoBookmark()
							Set tToken = ..%NextToken()
							
							If (tFunctionTestToken '= "(") {
								Set tIsRelation = 1
								Set tIsMember = 1
								
								// + WAL202 -- Note that this query includes members from related cubes.
								//             Is currently referenced by the pivot table component
								Set ..Query.%hasRelationship = 1
								// - WAL202
							}
						}
						Else {
							// DTB286 - This is unambiguously a relationship.
							Set tIsRelation = 1
							Set tIsMember = 1
							
							// + WAL202 -- Note that this query includes members from related cubes.
							//             Is currently referenced by the pivot table component
							Set ..Query.%hasRelationship = 1
							// - WAL202
						}
					}
				}
				ElseIf ((tType = "NUM")||(tType = "LIT")) {
					// constant, add to list
					Do Append(tToken,tType,6)
					Set tState = 3
				}
				ElseIf (tType = "OP") {
					If (tPossibleUnary&&..%IsUnaryOperatorToken(tToken)) {
						Do Append(tToken,"UNARY",7)
					}
					ElseIf $D(tTokenList) {
						Do Append(tToken,"OP",8)
						Set tPossibleUnary = 1
					}
					Else {
						Set tSC = ..%Error("Unexpected operator at start of tuple declaration",tToken)
						Quit
					}
				}
				Else {
					Set tSC = ..%Error("Expected member name at start of tuple declaration")
					Quit
				}
			}
			ElseIf (tState = 1) { // add on to tuple
				If (tToken = ".") {
					Set tSpec = tSpec_tToken
					Set tIsMember = 1
					Set tState = 2
				}
				ElseIf (tToken=":") {
					If (tRangeSpecCount > 0) {
						Set tSC = ..%Error("More than one ':' within a range",tSpec)
						Quit
					}
					// move spec into range spec, then start assembling again
					Kill tRangeSpecList
					Merge tRangeSpecList = tSpecList
					Set tRangeSpecCount = tSpecCount
					Set tRangeSpec = tSpec
					Set tSpec = ""
					Kill tSpecList
					Set tSpecCount = 0
					Set tState = 2
				}
				ElseIf (tToken = "(") {
					// either: "F(" or "a.F(" (isMember is true for 2nd case)
					// if "F(" then test if this is a known function
					If (tIsMember) {
						Set tState = 4
						Set tLocalParenCount = 1
						Set tLocalToken = tToken
					}
					Else {
						Set tFunc = $$$UPPER(tSpec)		// Normalize the token
						Set tFunctionLabel = tSpec		// Keep original casing for the label

						// first test for scalar function
						Set tIsScalarFunc = ##class(%DeepSee.Query.scalarFunction).%IsScalarFunction(tFunc)
						If ((+tIsScalarFunc)>= 0) {
							// add expression to graph
							Set tSet = ##class(%DeepSee.Query.expression).%New()
							Set tSet.operator = tFunc
							Set tSet.label = tFunctionLabel
							Set tSet.isScalarFunction = 1
							Set tSet.scalarArgCount = tIsScalarFunc
							Do Append(tSet,"OBJ",9)
							Set tArgDesc = ""
						}
						Else {
							If ($$$UPPER(tFunc)="COUNT") {
								If (##class(%DeepSee.Utils).%IsCubeCompound(..CubeName)) {
									// JMD869-defer count until result is consolidated
									Set tFunc="%POSTCOUNT"
								}
								Else {
									// JMD836-use optimized function
									// JMD1280-setFunction will change this for relationships
									Set tFunc="%DISTINCT"
								}
							}
							Set tIsFunc = ##class(%DeepSee.Query.setFunction).%GetFunctionInfo(tFunc,.tImplemented,.tArgCount,.tReturn,.tArgs,.tArgDesc)
							If ('tIsFunc) {
								Set tSC = ..%Error("Unknown function in query: "_tFunc)
								Quit
							}
							If ('tImplemented) {
								Set tSC = ..%Error("Function is not currently supported: "_tFunc)
								Quit
							}
							Set tSet = ##class(%DeepSee.Query.setFunction).%New()
							Set tSet.function = tFunc
							Do Append(tSet,"OBJ",10)
						}

						Set tArgCount = 0
						While (1) {
							Set tArgCount = tArgCount + 1

							// See if this argument uses a FLAG
							Kill tFuncFlags
							Set tFlag = $P($LG(tArgDesc,tArgCount),":",2)
							If (tFlag '= "") {
								For p = 1:1:$L(tFlag,",") {
									Set tFuncFlags($P(tFlag,",",p)) = ""
								}
							}
							Set tSC = ..%ParseMEMBER(tSet,.tNode,")",pMode,.tFuncFlags,pLevel+1)
							If $$$ISERR(tSC) Quit

							// JMD792: plug in "" for missing arguments
							// JMD: ignore for functions with no arguments
							If ('$IsObject(tNode)&&(tArgDesc'="")) {
								Set tNode = ##class(%DeepSee.Query.constant).%New()
								Set tNode.value = ""
								Do tSet.children.Insert(tNode)
							}

							// test next token
							Set tNextToken = ..%NextToken(.tNextType,.tSC)
							If $$$ISERR(tSC) Quit
							If (tNextToken = ")") {
								// +DTB502 - Replace a single argument AGGREGATE function
								// (acting only on a set) with %OR
								If ($$$UPPER(tFunc)="AGGREGATE") &&
									(tArgCount=1) &&
									tSet.children.GetAt(1).%IsA("%DeepSee.Query.set") &&
									'tSet.children.GetAt(1).%IsA("%DeepSee.Query.tuple") {
									Set tSet.function = "%OR"
									Set tSet.label = tFunctionLabel
								}
								// -DTB502
								
								Quit
							}
							ElseIf (tNextToken '= ",") {
								Set tSC = ..%Error("Missing ')' in query (1)")
								Quit
							}
						}
						If $$$ISERR(tSC) Quit
						Set tSpec = ""
						Kill tSpecList
						Set tSpecCount = 0
						Set tState = 3
					}
				}
				ElseIf (tType = "OP") {
					// add tuple & operator to list
					If (tRangeSpecCount>0) {
						// make this an error (otherwise use same range pad logic as other case)
						Set tSC = ..%Error("Operator not allowed with range.")
						Quit
					}
					Else {
						Set tSC = $$ProcessSpec(.tSpecList,tSpecCount,.tRangeSpecList,tRangeSpecCount)
						If $$$ISERR(tSC) Quit
					}
					Do Append(tToken,tType,11)
					Set tPossibleUnary = 1
					Set tSpec = ""
					Kill tRangeSpecList
					Set tRangeSpecCount = 0
					Kill tSpecList
					Set tSpecCount = 0
					Set tState = 0
				}
				ElseIf (($$$UPPER(tToken) = pCloseToken)||(tToken=",")||((pMode'=2)&&($$$UPPER(tToken)="%FILTER"))||(tToken="")) {
					If ((tToken=")")&&(tParenCount>0)) {
						If $D(tSpecList) {
							// if there is a spec process before the closing )
							Set tSC = $$ProcessSpec(.tSpecList,tSpecCount,.tRangeSpecList,tRangeSpecCount)
							If $$$ISERR(tSC) Quit
							Set tSpec = ""
							Kill tRangeSpecList
							Set tRangeSpecCount = 0
							Kill tSpecList
							Set tSpecCount = 0
							Set tState = 0
						}
						Set tParenCount = tParenCount - 1
						Do Append(tToken,tType,12)
					}
					Else {
						Do ..%GotoBookmark() // unread
						Set tSC = $$ProcessSpec(.tSpecList,tSpecCount,.tRangeSpecList,tRangeSpecCount)
						If $$$ISERR(tSC) Quit
						Quit
					}
				}
				ElseIf (tToken = "}") {
					Set tSC = ..%Error("Unexpected '}' in query (1)")
					Quit
				}
				ElseIf (tToken = ")") {
					// end of expression within ()
					Set tParenCount = tParenCount - 1

					// do not allow range within expression
					If (tRangeSpecCount>0) {
						Set tSC = ..%Error("Range not allowed within expression: ",tSpec)
						Quit
					}
					Set tSC = $$ProcessSpec(.tSpecList,tSpecCount,.tRangeSpecList,tRangeSpecCount)
					If $$$ISERR(tSC) Quit

					Do Append(tToken,tType,13)
					Set tSpec = ""
					Kill tRangeSpecList
					Set tRangeSpecCount = 0
					Kill tSpecList
					Set tSpecCount = 0
					Set tState = 0
				}
				Else {
					Set tSC = ..%Error("Expected '"_pCloseToken_"' or ',' at end of tuple declaration (1): ",tToken)
					Quit
				}
			}
			ElseIf (tState = 2) { // add on to tuple after . or :
				If ((tType = "QSTR")||(tType = "STR")||(tType = "NUM")||(tType = "LIT")) {
					Set tState = 1
					Set tSpec = tSpec_tToken
					Set tSpecList($I(tSpecCount)) = tToken
				}
				ElseIf (tToken = "&") {
					Set tSpec = tSpec_tToken
					Set tSpecList($I(tSpecCount)) = tToken
				}
				Else {
					Set tSC = ..%Error("Expected member name within tuple declaration (7)",tSpec)
					Quit
				}
			}
			ElseIf (tState = 3) {
				// got a literal, function or named set, 
				// looking for an operator, member function, or end
				If (tType = "OP") {
					Do Append(tToken,tType,14)
					Set tPossibleUnary = 1
					Set tState = 0
				}
				ElseIf (($$$UPPER(tToken) = pCloseToken)||(tToken=",")||((pMode'=2)&&($$$UPPER(tToken)="%FILTER"))||(tToken="")) {
					If ((tToken=")")&&(tParenCount>0)) {
						Set tParenCount = tParenCount - 1
						Do Append(tToken,tType,15)
					}
					Else {
						// done
						Do ..%GotoBookmark() // unread
						Quit
					}
				}
				ElseIf (tToken = ")") {
					Set tParenCount = tParenCount - 1
					Do Append(tToken,tType,16)
				}
				Else {
					Set tSC = ..%Error("Expected operator within tuple",tToken)
					Do ..%GotoBookmark()
					Quit
				}
			}
			ElseIf (tState = 4) {
				// "spec("  -- look for closing ")"
				If (tToken = ")") {
					Set tLocalToken = tLocalToken_tToken
					Set tLocalParenCount = tLocalParenCount - 1
					If (tLocalParenCount = 0) {
						Set tSpec = tSpec_tLocalToken
						Set tSpecList($I(tSpecCount)) = tLocalToken
						Set tLocalToken = ""
						Set tState = 1
					}
				}
				ElseIf (tToken = "(") {
					Set tLocalToken = tLocalToken_tToken
					Set tLocalParenCount = tLocalParenCount + 1
				}
				ElseIf (tToken = "") {
					Set tSC = ..%Error("Missing ')' in query")
					Quit
				}
				Else {
					If (tType = "LIT") { // preserve quotes
						Set tLocalToken = tLocalToken_""""_tToken_""""
					}
					Else {
						Set tLocalToken = tLocalToken_tToken
					}
				}
			}
			Set tLastToken = tToken
		} // While()
		If $$$ISERR(tSC) Quit

		// check parens
		If (tParenCount < 0) {
			Set tSC = ..%Error("Extra ')' in query")
			Quit
		}
		ElseIf (tParenCount > 0) {
			Set tSC = ..%Error("Missing ')' in query")
			Quit
		}
		Else {
			// test for dangling operator: 100+
			If ($LG($G(tTokenList(tNextSlot)),2) = "OP") {
				Set tSC = ..%Error("Extra '"_$LG(tTokenList(tNextSlot),1)_"' in query")
			}
		}

		If $$$ISERR(tSC) Quit

		// walk over each item in token list
		// add them to the parse tree and reduce
		Do Append("","END",17) // mark end of list

		Set tTree = 0					// node ptr
		Set tTree(tTree) = $LB("","TOP")
		Set tLevel = 0					// stack level
		Set tParent(0) = tTree			// parent of current level
		Set tUnary(0) = 0				// flag for unary operators (stacked)

		Set tTokenNo = $O(tTokenList(""))
		While (($$$ISOK(tSC)) && (tTokenNo '= "")) {
			Set tToken = $LG(tTokenList(tTokenNo),1)
			Set tType = $LG(tTokenList(tTokenNo),2)

			// add token to tree
			If (tToken = "(") {
				// push paren on the stack
				Set tTree = tTree + 1
				Set tTree(tTree) = tTokenList(tTokenNo)
				Set tTree(tParent(tLevel),"ch",tTree) = ""

				Set tLevel = tLevel + 1
				Set tParent(tLevel) = tTree
				Set tUnary(tLevel) = 0
			}
			ElseIf (tToken = ")") {
				If (tLevel = 0) {
					Set tSC = ..%Error("Extra ')' in expression")
				}
				Else {
					While (tUnary(tLevel) = 1) {
						// pop unary op
						Set tLevel = tLevel - 1
					}
					Set tLevel = tLevel - 1
				}
			}
			ElseIf (tType = "END") {
				// dummy end node
				While ((tLevel > 0) && (tUnary(tLevel) = 1)) {
					// single arg for unary operator; pop stack
					Set tLevel = tLevel - 1
				}
			}
			ElseIf (tType = "UNARY") {
				// put unary op in tTree; make next item a child of it
				Set tTree = tTree + 1
				Set tTree(tTree) = tTokenList(tTokenNo)
				Set tTree(tParent(tLevel),"ch",tTree) = ""

				// make unary node the parent for next token(s)
				Set tLevel = tLevel + 1
				Set tParent(tLevel) = tTree
				Set tUnary(tLevel) = 1
			}
			Else {
				Set tTree = tTree + 1
				Set tTree(tTree) = tTokenList(tTokenNo)
				Set tTree(tParent(tLevel),"ch",tTree) = ""

				While ((tUnary(tLevel) = 1)) {
					// single arg for unary operator; pop stack
					Set tLevel = tLevel - 1
				}
			}
			If $$$ISERR(tSC) Quit

			// apply reducing rules
			// for convenience, get last 3 types from parent
			Set node(1)="",node(2)="",node(3)=""
			Set tok(1)="",tok(2)="",tok(3)=""

			Set node(3) = $O(tTree(tParent(tLevel),"ch",""),-1)
			Set:(node(3)'="") node(2) = $O(tTree(tParent(tLevel),"ch",node(3)),-1)
			Set:(node(2)'="") node(1) = $O(tTree(tParent(tLevel),"ch",node(2)),-1)

			For i=1:1:3 {
				Set tok(i) = $S(node(i)="":"",1:$LG($G(tTree(node(i))),1))
				Set type(i) = $S(node(i)="":"",1:$LG($G(tTree(node(i))),2))
			}

			// arg op arg ==>
			If (((type(1) '= "") && (type(1) '= "OP")) &&
				 (type(2) = "OP") && 
				 ((type(3) '= "") && (type(3) '= "OP"))) {
				// replace (arg op arg) with (op (arg arg))
				Set tTree(node(2),"ch",node(1)) = ""
				Set tTree(node(2),"ch",node(3)) = ""
				Kill tTree(tParent(tLevel),"ch",node(1))
				Kill tTree(tParent(tLevel),"ch",node(3))
			}
			// op op arg ==>
			ElseIf (((type(1) = "OP")) &&
				 (type(2) = "OP") && 
				 ((type(3) '= "") && (type(3) '= "OP"))) {

				If ('..%TestPrecedence(tok(1),tok(2))) {
					// rebuild tTree to match precedence

					// find last child of op1
					Set tChild = $O(tTree(node(1),"ch",""),-1)

					// make op1 a child of op2
					Set tTree(node(1),"ch",node(2)) = ""
					Kill tTree(tParent(tLevel),"ch",node(2))

					// make child a child of op2
					Set tTree(node(2),"ch",tChild) = ""
					Kill tTree(node(1),"ch",tChild)

					// make arg a child of op2
					Set tTree(node(2),"ch",node(3)) = ""
					Kill tTree(tParent(tLevel),"ch",node(3))
				}
				Else {
					// replace (arg op arg) with (op (arg arg))
					Set tTree(node(2),"ch",node(1)) = ""
					Set tTree(node(2),"ch",node(3)) = ""
					Kill tTree(tParent(tLevel),"ch",node(1))
					Kill tTree(tParent(tLevel),"ch",node(3))
				}
			}
			// next token
			Set tTokenNo = $O(tTokenList(tTokenNo))
		}

		// there may be parens in the tree that are not needed; remove them
		Set tNode = $O(tTree(""))
		Set tSC = ..%RemoveParens(tNode,.tTree)
		If $$$ISERR(tSC) Quit

		// now convert tree into query objects
		Set tNode = $O(tTree(""))
		Set tSC = ..%ProcessMemberNode(tNode,.tTree,.tNodeList,.pNode)
		If $$$ISERR(tSC) Quit

		If $IsObject(pParent) {
			// JMD1442 check for tuple(tuple); simplify
			If (pParent.%IsA("%DeepSee.Query.tuple")&&pNode.%IsA("%DeepSee.Query.tuple")) {
				// fold tuple items into parent
				For tc=1:1:pNode.children.Count() {
					Do pParent.children.Insert(pNode.children.GetAt(tc))
				}
				Do ..%Trace("Fold "_pNode_" into "_pParent,5)
			}
			Else {
				// note: tuple(expr) is same as expr; we check for this in the tuple class
				Do pParent.children.Insert(pNode)
				Do ..%Trace("Insert "_pNode_" into "_pParent,5)
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Do ..%Trace("ParseMEMBER )")
	Quit tSC

	// add token to list of tokens (tCase is for debugging)
Append(tToken,tType,tCase)
	Set tPossibleUnary = 0
	If (tType="OBJ") {// push object onto stack
		Set tNodeList($I(tNodeList)) = tToken
		Set tToken = tNodeList
	}
	Set tTokenList($I(tNextSlot)) = $LB(tToken,tType)
	Quit

	// called when we encounter a complete member spec: "a.b", "a.b:c", etc.
	Set (tList1,tList1Count,tList2,tList2Count) = ""
ProcessSpec(tList1,tList1Count,tList2,tList2Count)
	Set tSC = $$$OK

	If ((tList1Count=1)&&(tList2Count=0)&&($E(tList1(1),1)="@")) {
		// this is a naked named parameter
		// pass it along so that it can be resolved later.
		Set tObj = ##class(%DeepSee.Query.constant).%New()
		Set tObj.value = tList1(1)
		Do Append(tObj,"OBJ",18)
		Quit tSC
	}

	If (tList2Count > 0) {
		// range
		// pad second part of range (if needed)
		If (tList1Count < tList2Count) {
			If (tList1(1)'=tList2(1)) {
				Set d = tList2Count - tList1Count
				For r = tList2Count:-1:1 {
					Set tList1(r) = $G(tList1(r-d),tList2(r))
				}
				Set tList1Count = tList2Count
			}
		}

		If (tIsRelation) {
			// special case for relationships
			Set tSC = $$ProcessRangePart(.tList2, tList2Count,.tNewItem2,.tNewType2)
			If $$$ISERR(tSC) Quit tSC

			Set tSC = $$ProcessRangePart(.tList1, tList1Count,.tNewItem,.tNewType)
			If $$$ISERR(tSC) Quit tSC
			
			Set tNewItem = tNewItem2_":"_tNewItem
			Do Append(tNewItem,tNewType,19)
		}
		Else {
			// create range
			Set tRangeNode = ##class(%DeepSee.Query.range).%New()
			Do Append(tRangeNode,"OBJ",20)

			Set tSC = $$ProcessRangePart(.tList2, tList2Count,.tNewItem,.tNewType)
			If $$$ISERR(tSC) Quit tSC

			If (tNewType = "OBJ") {
				Set tRangeNode.startMember = tNewItem
			}
			Else {
				Set tObj = ##class(%DeepSee.Query.memberSpec).%New()
				Set tObj.spec = tNewItem
				Set tRangeNode.startMember = tObj
			}

			Set tSC = $$ProcessRangePart(.tList1, tList1Count,.tNewItem,.tNewType)
			If $$$ISERR(tSC) Quit tSC

			If (tNewType = "OBJ") {
				Set tRangeNode.endMember = tNewItem
			}
			Else {
				Set tObj = ##class(%DeepSee.Query.memberSpec).%New()
				Set tObj.spec = tNewItem
				Set tRangeNode.endMember = tObj
			}
		}
	}
	Else {
		// single item
		Set tSC = $$ProcessRangePart(.tList1, tList1Count,.tNewItem,.tNewType)
		If $$$ISERR(tSC) Quit tSC
		Do Append(tNewItem,tNewType,21)
	}

	Quit tSC

	// Process part of a member spec: "A.B"
	// Return the new item and its type via tNewItem and tNewType
	// tMemberSpec is an array of tokens within the member
	// tMemberCount is the number of tokens
	Set (tMemberSpec, tMemberCount)=""
ProcessRangePart(tMemberSpec, tMemberCount,tNewItem,tNewType)
	Set tSC = $$$OK
	Set tIsFunc = 0
	Set tSetFunc = ""
	Set tNewItem = ""
	Set tNewType = ""
	Set tParmList = ""

	// check for currentMember as it gets special treatment
	// tQualifier is all the text *following* CurrentMember:
	// we hold onto this and process it later.
	Set tQualifier = ""
	For m = 1:1:tMemberCount {
		Set tFunc = tMemberSpec(m)
		If ($$$UPPER(tFunc) = "CURRENTMEMBER") {
			Set offset = 1
			For n = m+offset:1:tMemberCount {
				Set s = tMemberSpec(n)
				Set tQualifier = tQualifier _ $S(tQualifier="":"",$E(s)="(":"",1:".")_s
			}
			Set tMemberCount = m+offset-1
			Quit
		}
	}

	// walk list backwards, pull off functions if any
	Set tHolderCount = 0
	Kill tHolders
	Kill tHolderPartners
	Set m = tMemberCount
	While (m > 0) {
		Set tFunc = tMemberSpec(m)
		If ($E(tFunc)="(") { // argument list
			Set m = m - 1
			Set tParmList = tFunc
		}
		ElseIf ('..%IsQuotedIdent(tFunc) && ##class(%DeepSee.Query.memberFunction).%GetFunctionInfo(tFunc,.tImplemented,.tArgCount,.tReturn,.tArgs,.tArgDesc)) {
			// n.b, if we are processing a relationship
			// ignore functions as they are passed on the related cube
			// special case for currentMember: process at this point
			If (tIsRelation && ($$$UPPER(tFunc) '= "CURRENTMEMBER")) {
				Quit
			}
			Set m = m - 1
			Set tIsFunc = 1
			If ('tImplemented) {
				Set tSC = ..%Error("Function is not currently supported: "_tFunc)
				Quit
			}

			If (tSetFunc="") {
				// first function
				Set tSetFunc = ##class(%DeepSee.Query.memberFunction).%New()
				Set tSetFunc.function = tFunc
				Set tNewItem = tSetFunc
				Set tNewType = "OBJ"
			}
			Else {
				// tack onto previous function
				Set tSet = ##class(%DeepSee.Query.memberFunction).%New()
				Set tSet.function = tFunc
				Do tSetFunc.children.Insert(tSet)
				Set tSetFunc = tSet
			}

			// n.b., we assume only one CurrentMember per member spec
			If ($$$UPPER(tFunc) = "CURRENTMEMBER") {
				Set tSetFunc.%cmbrQualifier = tQualifier
				If (tIsRelation) {
					If (m<2) {
						Set tSC = ..%Error("CurrentMember on relationship must specify a dimension")
						Quit
					}
				}
			}

			// process parameter list, if any
			If (tParmList = "") {
				Set tParmCount = ""
			}
			ElseIf(tParmList = "()") {
				Set tParmCount = 0
			}
			Else {
				// Make parm list the current token source
				Do ..%PushContext(tParmList)

				// add arguments to place holder node
				Set tHolderCount = tHolderCount + 1
				Set tHolders(tHolderCount) = ##class(%DeepSee.Query.memberFunction).%New()
				Set tHolderPartners(tHolderCount) = tSetFunc

				Set tParmCount = 0
				While (1) {
					Set tParmCount = tParmCount + 1

					// See if this argument uses a FLAG
					// add one to count to account for member as first argument!
					Kill tFuncFlags
					Set tFlag = $P($LG(tArgDesc,tArgCount+1),":",2)
					If (tFlag '= "") {
						For p = 1:1:$L(tFlag,",") {
							Set tFuncFlags($P(tFlag,",",p)) = ""
						}
					}

					Set tSC = ..%ParseMEMBER(tHolders(tHolderCount),.tNode,")",pMode,.tFuncFlags,pLevel+1)
					If $$$ISERR(tSC) Quit
					// test next token
					Set tNextToken = ..%NextToken(.tNextType,.tSC)
					If $$$ISERR(tSC) Quit
					If (tNextToken = ")") {
						Quit
					}
					ElseIf (tNextToken '= ",") {
						Set tSC = ..%Error("Missing ')' in query (1)")
						Quit
					}
				}
				If $$$ISERR(tSC) Quit
				Do ..%PopContext()
			}

			If ((+tArgCount)>tParmCount) {
				Set tSC = ..%Error("Function missing arguments: "_tFunc)
				Quit
			}
			Set tParmList = ""
		}
		Else {
			// if not a function we are done
			Quit
		}
	} // while
	If $$$ISERR(tSC) Quit tSC

	If (tIsFunc) {
		// process the remaining items
		Set tHandled = 0
		If ((m=0)&&(tMemberSpec(1)'="")&&$D(pFlags($$$UPPER(tMemberSpec(1))))) {
			// flag
			Set tObj = ##class(%DeepSee.Query.flag).%New()
			Set tObj.value = $$$UPPER(tMemberSpec(1))
			Do Append(tObj,"OBJ",22)
		}
		ElseIf (m = 1) {
			// test for named set
			Set tTest = ..%UnquoteIdent($G(tMemberSpec(1)))
			If (..Query.%LookupNamedSet(tTest,.tNamedSet,.tSC)) {
				Set tHandled = 1
				Do tSetFunc.children.Insert(tNamedSet)
			}
			If $$$ISERR(tSC) Quit tSC

			// special case: look for CalcDim.Function
			// *Some* functions are allowed, namely: Members and its ilk
			If ('tHandled) {
				Kill tMemberSpecList
				Set tMemberSpecList($I(tMemberSpecList)) = ..%UnquoteIdent($G(tMemberSpec(1)))
				Set tMemberSpecList($I(tMemberSpecList)) = ..%UnquoteIdent($G(tMemberSpec(2)))
				If (..Query.%LookupCalculatedMember(.tMemberSpecList,tMemberSpecList,.tCalcSet,.tSC,.tIsCFunc)) {
					If (tIsCFunc) {
						Set tHandled = 1
						// replace the set function with the new set
						Set tSetFunc = tCalcSet
						Set tNewItem = tSetFunc
						Set tNewType = "OBJ"
					}
				}
			}
		}
		ElseIf (m >= 2) {
			// we could have a.calc (m=2) or a.&calc (m=3)
			// test for calculated member
			// if so, replace the current item with the calculated member contents
			Set tCalcDimName = ""
			If (m>=2) {
				Set tCalcDimName = ..%UnquoteIdent($G(tMemberSpec(1)))
			}

			If (tCalcDimName'="") {
				// JMD1366 pass all parts along, including function
				Kill tCalcMbrSpec
				For mx = 1:1:tMemberCount {
					Set tCalcMbrSpec($I(tCalcMbrSpec)) = ..%UnquoteIdent($G(tMemberSpec(mx)))
				}
				If (..Query.%LookupCalculatedMember(.tCalcMbrSpec,tCalcMbrSpec,.tCalcSet,.tSC,.tIsCFunc)) {
					If (tIsCFunc) {
						Set tHandled = 1
						// replace the set function with the new set
						Set tSetFunc = tCalcSet
						Set tNewItem = tSetFunc
						Set tNewType = "OBJ"
					}
					ElseIf (tMemberCount>2) {
						// There should be nothing after the calc member
						Set tSC = ..%Error("Function not allowed after calculated member (" _ $G(tMemberSpec(3)) _ ")")
						Quit tSC
					}
					Else {
						Set tHandled = 1
						Do tSetFunc.children.Insert(tCalcSet)
					}
				}
				If $$$ISERR(tSC) Quit tSC
			}
		}

		If ('tHandled) {
			Set tSpec = ""
			Set tInSearch=0
			For n=1:1:m {
				If ( $$$UPPER(..%UnquoteIdent(tMemberSpec(n)))="%SEARCH" ) {
					Set tInSearch = 1
				}
				
				// DTB087 - Convert back to the executable syntax. 
				If tInSearch {
					// Search term. Do not alter the syntax
					Set tSpec = tSpec _ $S((tSpec="")||($E(tSpec,*)="&"):"",1:".") _ tMemberSpec(n)
				}
				Else {
					// Standard identifier, Quote even if the escaped identifier looks like it is quoted
					Set tSpec = tSpec _ $S((tSpec="")||($E(tSpec,*)="&"):"",1:".") _ ..%QuoteTrustedIdent($$$dsEscapeIdent(..%UnquoteIdent(tMemberSpec(n))))
				}
			}
			Set tObj = ##class(%DeepSee.Query.memberSpec).%New()
			Set tObj.spec = tSpec
			Do tSetFunc.children.Insert(tObj)
		}

		// now pick up additional arguments from holder(s)
		For h=1:1:tHolderCount {
			If $IsObject(tHolders(h)) {
				For n = 1:1:tHolders(h).children.Count() {
					Do tHolderPartners(h).children.Insert(tHolders(h).children.GetAt(n))
				}
			}
		}
	}
	Else { // ('tIsFunc)
  		// test for function flag argument
		If ((tMemberCount=1)&&(tMemberSpec(1)'="")&&$D(pFlags($$$UPPER(tMemberSpec(1))))) {
			Set tObj = ##class(%DeepSee.Query.flag).%New()
			Set tObj.value = $$$UPPER(tMemberSpec(1))
			Do Append(tObj,"OBJ",23)
		}
		Else {
			Set tHandled = 0
			If (tMemberCount = 1) {
				// test for named set
				Set tTest = ..%UnquoteIdent($G(tMemberSpec(1)))
				If (..Query.%LookupNamedSet(tTest,.tNamedSet,.tSC)) {
					Set tHandled = 1
					Do Append(tNamedSet,"OBJ",24)
				}
				If $$$ISERR(tSC) Quit tSC
			}
			ElseIf (tMemberCount >= 2) {
				// test for calculated member
				// this could be dim.level...calcmbr
				// JMD1329: pass *all* names on to Lookup
				Kill tCalcMbrSpec	
				Set tCalcDimName = ""
				Set tUseKey = 0
				If (tMemberCount >= 2) {
					For q=1:1:tMemberCount {
						Set c = ..%UnquoteIdent($G(tMemberSpec(q)))
						If (c="&") {
							Set tUseKey = 1
						}
						Else {
							Set tCalcMbrSpec($I(tCalcMbrSpec)) = c
						}
					}
				}
				If (($G(tCalcMbrSpec)'="")&&($G(tCalcMbrSpec(tCalcMbrSpec))'="")) {
					If (..Query.%LookupCalculatedMember(.tCalcMbrSpec,tCalcMbrSpec,.tCalcSet,.tSC,,tUseKey)) {
						Set tNewItem = tCalcSet
						Set tNewType = "OBJ"
						Set tHandled = 1
					}
					If $$$ISERR(tSC) Quit tSC
				}
			}
			If ('tHandled) {
				Set tSpec = ""
				Set tInSearch = 0
				For n=1:1:tMemberCount {
					If ( $$$UPPER(..%UnquoteIdent(tMemberSpec(n)))="%SEARCH" ) {
						Set tInSearch = 1
					}
					
					// DTB087 - Convert back to the executable syntax. 
					If tInSearch {
						// Search term. Do not alter the syntax
						Set tSpec = tSpec _ $S((tSpec="")||($E(tSpec,*)="&"):"",1:".") _ tMemberSpec(n)
					}
					Else {
						// Standard identifier, Quote even if the escaped identifier looks like it is quoted
						Set tSpec = tSpec _ $S((tSpec="")||($E(tSpec,*)="&"):"",1:".") _ ..%QuoteTrustedIdent($$$dsEscapeIdent(..%UnquoteIdent(tMemberSpec(n))))
					}
				}
				Set tNewItem = tSpec
				Set tNewType = "MEMBER"
			}
		}
	}
	Quit tSC

	// test if there are functions at the end of a member spec
	// returns status code
	// If a function is found, return it via tIsFunc
	// Return the newly created set via tNewSet
	// tMemberSpec is an array of tokens within the member
	// tMemberCount is the number of tokens
	Set (tMemberSpec, tMemberCount)=""
ProcessMemberFunction(tMemberSpec, tMemberCount,tIsFunc,tNewSet)
	// test for function at end of spec
	Set tSC = $$$OK
	Set tIsFunc = 0
	Set tSetFunc = ""
	Set tNewSet = ""
	Set m = tMemberCount
	While (m > 0) {
		Set tFunc = tMemberSpec(m)
		If ('..%IsQuotedIdent(tFunc) && ##class(%DeepSee.Query.memberFunction).%GetFunctionInfo(tFunc,.tImplemented,.tArgCount,.tReturn,.tArgs,.tArgDesc)) {
			Set m = m - 1
			Set tIsFunc = 1
			If ('tImplemented) {
				Set tSC = ..%Error("Function is not currently supported: "_tFunc)
				Quit
			}
			If ((+tArgCount)>0) {
				Set tSC = ..%Error("Function missing arguments: "_tFunc)
				Quit
			}
			If (tSetFunc="") {
				// first function
				Set tSetFunc = ##class(%DeepSee.Query.memberFunction).%New()
				Set tSetFunc.function = tFunc
				Do Append(tSetFunc,"OBJ",25)
				Set tNewSet = tSetFunc
			}
			Else {
				Set tSet = ##class(%DeepSee.Query.memberFunction).%New()
				Set tSet.function = tFunc
				Do tSetFunc.children.Insert(tSet)
				Set tSetFunc = tSet
			}
		}
		Else {
			Quit
		}
	}
	If $$$ISERR(tSC) Quit tSC

	If (tIsFunc) {
		// process the remaining items
		Set tSpec = ""
		For n=1:1:m {
			Set tSpec = tSpec _ $S((tSpec="")||($E(tSpec,*)="&"):"",1:".") _ ..%QuoteIdent(tMemberSpec(n))
		}
		Set tObj = ##class(%DeepSee.Query.memberSpec).%New()
		Set tObj.spec = tSpec
		Do tSetFunc.children.Insert(tObj)
	}
	Quit tSC
}

/// Remove unneeded parens from tree.
/// <var>pEmpty</var> is set true (1) if the node has only parens and can be removed.
Method %RemoveParens(pNodeNo As %Integer, ByRef pTree, pEmpty As %Boolean) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tToken = $LG(pTree(pNodeNo),1)
		Set tType = $LG(pTree(pNodeNo),2)
		Set pEmpty = 0

		// recurse for children of node
		Set tChild = $O(pTree(pNodeNo,"ch",""))
		While (tChild'="") {
			Set tSC = ..%RemoveParens(tChild,.pTree,.tEmpty)
			If (tEmpty) {
				Kill pTree(pNodeNo,"ch",tChild)
				Kill pTree(tChild)
			}
			Set tChild = $O(pTree(pNodeNo,"ch",tChild))
		}
		
		// is this an empty node?
		If ((tToken="(")&&'$D(pTree(pNodeNo,"ch"))) {
			Set pEmpty = 1
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Used by parseMEMBER to convert expression trees into query objects.<br/>
/// <var>pNodeNo</var> is the top node number in the tree.<br/>
/// <var>pTree</var> is the expression tree.<br/>
/// <var>pObjList</var> an array of objects referenced by the tree.<br/>
/// <var>pObj</var> is the newly created object.<br/>
Method %ProcessMemberNode(pNodeNo As %Integer, ByRef pTree, ByRef pObjList, Output pObj As %DeepSee.Query.node) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pObj = ""
		Set tToken = $LG(pTree(pNodeNo),1)
		Set tType = $LG(pTree(pNodeNo),2)

		If (tType = "TOP") {
			// recurse for child of top
			Set tChild = $O(pTree(pNodeNo,"ch",""))
			If (tChild = "") {
				Quit
			}
			Else {
				Set tSC = ..%ProcessMemberNode(tChild,.pTree,.pObjList,.pObj)
			}
		}
		ElseIf (tType = "OBJ") {
			Set pObj = pObjList(tToken)
		}
		ElseIf ((tType = "NUM")||(tType = "LIT")) {
			Set pObj = ##class(%DeepSee.Query.constant).%New()
			Set pObj.value = $S(tToken=$C(0):"",1:tToken) // unescape $C(0)
			// JMD1373
			If (tType = "LIT") {
				Set pObj.type = "string"
			}
		}
		ElseIf (tType = "MEMBER") {
			Set pObj = ##class(%DeepSee.Query.memberSpec).%New()
			Set pObj.spec = tToken
		}
		ElseIf (tType = "RANGE") {
			// place range into container set
			Set pObj = ##class(%DeepSee.Query.set).%New()
			Set tTuple = ##class(%DeepSee.Query.memberSpec).%New()
			Set tTuple.spec = tToken
			Do pObj.children.Insert(tTuple)
		}
		ElseIf (tType = "OP") {
			// binary operator: get args
			Set ch1 = $O(pTree(pNodeNo,"ch",""))
			Set ch2 = $O(pTree(pNodeNo,"ch",ch1))

			If ((ch1 = "") || (ch2 = "")) {
				Set tSC  = ..%Error("Missing arguments for binary operator",tToken)
				Quit
			}
			Else {
				Set tSC = ..%ProcessMemberNode(ch1,.pTree,.pObjList,.tObj1)
				If $$$ISERR(tSC) Quit
				Set tSC = ..%ProcessMemberNode(ch2,.pTree,.pObjList,.tObj2)
				If $$$ISERR(tSC) Quit

				If (tObj1.%IsA("%DeepSee.Query.constant") && tObj2.%IsA("%DeepSee.Query.constant")
					&& ($E(tObj1.value)'="@")&& ($E(tObj2.value)'="@")) {
					// reduce constant expression
					// make sure constant is not a named parameter
					If ($IsValidNum(tObj1.value)&&$IsValidNum(tObj2.value)) {
						Set tValue = $Case(tToken,
							"+":tObj1.value+tObj2.value,
							"*":tObj1.value*tObj2.value,
							"/":$S(tObj2.value'=0:tObj1.value/tObj2.value,1:"DIVIDE"),
							"-":tObj1.value-tObj2.value,
							">":tObj1.value>tObj2.value,
							"<":tObj1.value<tObj2.value,
							">=":tObj1.value>=tObj2.value,
							"<=":tObj1.value<=tObj2.value,
							"=":tObj1.value=tObj2.value,
							"<>":tObj1.value'=tObj2.value,
							:"N/A")
					}
					Else {
						// string
						Set tValue = $Case(tToken,
							"+":tObj1.value_tObj2.value,
							">":tObj1.value]]tObj2.value,
							"<":tObj1.value']]tObj2.value,
							">=":(tObj1.value]]tObj2.value)||(tObj1.value=tObj2.value),
							"<=":(tObj1.value']]tObj2.value)||(tObj1.value=tObj2.value),
							"=":tObj1.value=tObj2.value,
							"<>":tObj1.value'=tObj2.value,
							:"N/A")
					}


					Set pObj = ##class(%DeepSee.Query.constant).%New()
					Set pObj.value = tValue
				}
				Else {
					Set pObj = ##class(%DeepSee.Query.expression).%New()
					Set pObj.operator = tToken
					Do pObj.children.Insert(tObj1)
					Do pObj.children.Insert(tObj2)
				}
			}
		}
		ElseIf ((tType = "UNARY")||(tToken = "(")) {
			// unary operator: get arg
			// treat parens as unary operator
			Set ch1 = $O(pTree(pNodeNo,"ch",""))
			If (ch1 = "") {
				If (tToken = "(") {
					// should not happen!
					Set tSC  = ..%Error("Error parsing parentheses",tToken)
				}
				Else {
					Set tSC  = ..%Error("Missing arguments for unary operator",tToken)
				}
				Quit
			}
			Else {
				Set tSC = ..%ProcessMemberNode(ch1,.pTree,.pObjList,.tObj1)
				If $$$ISERR(tSC) Quit
				If (tObj1.%IsA("%DeepSee.Query.constant")&&($E(tObj1.value)'="@")) {
					// reduce to constant
					Set tValue = $Case(tToken,
							"+":tObj1.value,
							"(":tObj1.value,
							"-":-tObj1.value,
							:"N/A")

					// normalize numbers
					If $IsValidNum(tValue) {
						If ((tValue<1)&&(tValue>0)) {
							Set tValue = "0"_(+tValue)
						}
						ElseIf ((tValue>-1)&&(tValue<0)) {
							Set tValue = "-0"_-(+tValue)
						} 
					}
					Set pObj = ##class(%DeepSee.Query.constant).%New()
					Set pObj.value = tValue
				}
				ElseIf (tToken="-") {
					Set tObj2 = ##class(%DeepSee.Query.constant).%New()
					Set tObj2.value = -1
	
					Set pObj = ##class(%DeepSee.Query.expression).%New()
					Set pObj.operator = "*"
					Do pObj.children.Insert(tObj1)
					Do pObj.children.Insert(tObj2)
				}
				Else {
					// unary +
					Set pObj = tObj1
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Parse an MDX FROM statement.
Method %ParseFROM() As %Status [ Internal ]
{
	Set tSC = $$$OK
	Do ..%Trace("ParseFROM")
	Try {
		Set tToken = ..%NextToken(.tType,.tSC)
		If ($$$UPPER(tToken) '= "FROM") {
			Set tSC = ..%Error("Query has no FROM section")
			Quit
		}

		Set tCubeName = ""
		Set tCanAppend = 1
		While ('..%AtEnd()) {
			Do ..%SetBookmark()
			Set tToken = ..%NextToken(.tType,.tSC)
			If $$$ISERR(tSC) Quit

			If (tType = "END") {
				Quit
			}
			ElseIf (($$$UPPER(tToken) = "WHERE")||($$$UPPER(tToken) = "%FILTER")) {
				If (tCubeName = "") {
					Set tSC = $$$ERROR($$$GeneralError,"No cube name in FROM clause")
				}
				Do ..%GotoBookmark()
				Quit
			}
			ElseIf (($$$UPPER(tToken) = "RETURN")||($$$UPPER(tToken) = "%LISTING")) {
				If (tCubeName = "") {
					Set tSC = $$$ERROR($$$GeneralError,"No cube name in FROM clause")
				}
				Do ..%GotoBookmark()
				Quit
			}
			ElseIf (tCanAppend) {
				If (tToken = ".") {
					Set tSC = $$$ERROR($$$GeneralError,"Unexpected . in FROM clause")
					Quit
				}
				Else {
					Set tTest = ..%UnquoteIdent(tToken)
					Set tCubeName = tCubeName_tTest
					Set tCanAppend = 0
				}
			}
			Else {
				If (tToken = ".") {
					Set tTest = ..%UnquoteIdent(tToken)
					Set tCubeName = tCubeName_tTest
					Set tCanAppend = 1
				}
				Else {
					Set tSC = $$$ERROR($$$GeneralError,"Unexpected string in FROM clause '"_tToken_"'")
					Quit
				}
			}
		}
		If $$$ISERR(tSC) Quit
		
		// +DTB130
		Set tVersion = ##class(%DeepSee.CubeVersion.Utils).%GetActiveCubeVersion(tCubeName)
		If (tVersion'="") {
			Do ..%Trace("Cube Version:" _ tVersion,5)
			Set tCubeName = ##class(%DeepSee.CubeVersion.Utils).%GetVersionedCubeName(tCubeName)
		} 
		// -DTB130

		Set ..Query.cube = tCubeName
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Parse an MDX WHERE statement.
Method %ParseWHERE() As %Status [ Internal ]
{
	Set tSC = $$$OK
	Do ..%Trace("ParseWHERE")
	Try {
		Do ..%SetBookmark()
		Set tToken = ..%NextToken(.tType,.tSC)
		If ($$$UPPER(tToken) = "RETURN") {
			Do ..%GotoBookmark()
			If (..Query.queryType '= "DRILLTHROUGH") {
				Set tSC = $$$ERROR($$$GeneralError,"RETURN clause invalid in non DRILLHROUGH query")
			}
			Quit
		}
		ElseIf ($$$UPPER(tToken) = "%LISTING") {
			Do ..%GotoBookmark()
			If (..Query.queryType '= "DRILLTHROUGH") {
				Set tSC = $$$ERROR($$$GeneralError,"%LISTING clause invalid in non DRILLHROUGH query")
			}
			Quit
		}
		ElseIf ($$$UPPER(tToken) = "%FILTER") {
			Do ..%GotoBookmark()
			Quit
		}
		ElseIf ($$$UPPER(tToken) '= "WHERE") {
			Set tSC = ..%Error("Invalid WHERE section")
			Quit
		}

		Set tSC = ..%ParseAXIS(.tAxisNum, .tAxis, 1)
		If $$$ISERR(tSC) Quit
		// DP-424293 - If this is specifically parsing a WHERE clause, place this in the filters array also
		Set tAxis.context = "filter"
		Set ..Query.slicer = tAxis
		Do:'..Query.%HasMeasure(tAxis) ..Query.filters.Insert(tAxis.%ConstructClone())	
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Parse an MDX %FILTER statement.
/// %FILTER is an ISC extension.
Method %ParseFILTER() As %Status [ Internal ]
{
	Set tSC = $$$OK
	Do ..%Trace("ParseFILTER")
	Try {
		Do ..%SetBookmark()
		Set tToken = ..%NextToken(.tType,.tSC)
		If ($$$UPPER(tToken) = "RETURN") {
			Do ..%GotoBookmark()
			If (..Query.queryType '= "DRILLTHROUGH") {
				Set tSC = $$$ERROR($$$GeneralError,"RETURN clause invalid in non DRILLHROUGH query")
			}
			Quit
		}
		ElseIf ($$$UPPER(tToken) '= "%FILTER") {
			Set tSC = ..%Error("Invalid %FILTER section")
			Quit
		}

		Set tSC = ..%ParseAXIS(.tAxisNum, .tAxis, 1)
		If $$$ISERR(tSC) Quit

		Set tAxis.context = "filter"		// DP-424293
		Do ..Query.filters.Insert(tAxis)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Parse an MDX RETURN statement (used by DRILLTHROUGH statements).
/// A RETURN statement is basically the SELECT list used against
/// the source table to return rows.<br/>
/// Also tests for %LISTING statement: "DRILLTHROUGH ... %LISTING LISTINGNAME"
Method %ParseRETURN() As %Status [ Internal ]
{
	Set tSC = $$$OK
	Do ..%Trace("ParseRETURN")
	Try {
		Set tToken = ..%NextToken(.tType,.tSC)
		If (tToken = "") {
			Quit
		}
		ElseIf (($$$UPPER(tToken)'="RETURN")&&($$$UPPER(tToken)'="%LISTING")) {
			Set tSC = ..%Error("Expecting RETURN but found",tToken)
			Quit
		}

		If ($$$UPPER(tToken)="%LISTING") {
			// JMD1140: %LISTING statement; get name of listing and process it
			Set tListingName = ""
			While (1) {
				Do ..%SetBookmark()
				Set tToken = ..%NextToken(.tType,.tSC)
				If $$$ISERR(tSC) Quit

				If (tType = "END") {
					If (tListingName = "") {
						Set tSC = ..%Error("%LISTING clause is empty")
					}
					Quit
				}
				Else {
					If (tListingName '= "") {
						Set tSC = ..%Error("Unexpected term after %LISTING",tToken)
						Quit
					}
					Else {
						Set tListingName = ..%UnquoteIdent(tToken)
					}
				}
			}
			
			If ($$$ISOK(tSC)&&(tListingName'="")) {
				// test if the listing exists and we have permission to use it
				Set tListingExists = 0
				If ($D($$$DeepSeeMetaGLVN("cubes",..CubeName,"listing",tListingName))) {
					Set tResource = $G($$$DeepSeeMetaGLVN("cubes",..CubeName,"listing",tListingName,"resource"))
					If ((tResource="")||($System.Security.Check(tResource,"USE"))) {
						Set tListingExists = 1
						Set ..Query.%listing = tListingName
						Set ..Query.%returnList = ""
						Set ..Query.%orderList = ""
					}
				}
				ElseIf ($D($$$DeepSeeListingGroupGLVN("cubes",..CubeName,"listing",tListingName))) {
					// DTB255 - Also look for the listing in the Listing Groups index if not found in the cube meta data
					Set tResource = $G($$$DeepSeeListingGroupGLVN("cubes",..CubeName,"listing",tListingName,"resource"))
					If ((tResource="")||($System.Security.Check(tResource,"USE"))) {
						Set tListingExists = 1
						Set ..Query.%listing = tListingName
						Set ..Query.%returnList = ""
						Set ..Query.%orderList = ""
					}
				}
				
				If ('tListingExists) {
					Set tSC = ..%Error("Listing does not exist",tListingName)
					Quit
				}
			}
		}
		Else {
			// get list of return columns
			// a,B,c. This is NOT the same as MS version
			// basically this is the SELECT list for the DRILLTHROUGH query
			// we will read everything until the end and use it as the select list
			// we also a %ORDER BY directive that lets you specify an order by
			// that is passed on to the drillthrough query

			Set tState = 0
			Set tSpec = ""
			Set tReturnList = ""
			Set tOrderList = ""
			Set tReturnTokens = ""
			Set tOrderTokens = ""
			Do ..%SetBookmark()		// DTB827 - Bookmark at the beginning of the RETURN list
			While (1) {
				set tLastToken = ..LastToken		// DTB690
				
				Set tToken = ..%NextToken(.tType,.tSC)
				If $$$ISERR(tSC) Quit

				Set tSpace = $S(..%IsOperatorToken(tLastToken)||..%IsOperatorToken(tToken):"",1:" ")		// DTB690 - Do not add spaces to operators and operands

				If (tState = 0) {
					If ((tType = "END")||($$$UPPER(tToken)="%ORDER")) {
						If (tReturnTokens = "") {
							Set tSC = ..%Error("RETURN clause is empty")
						}
						
						// + DTB827 - Take the original text to be processed later by the SQL parser
						If ($$$UPPER(tToken)="%ORDER") {
							Set tReturnList = $ZSTRIP($E(..Text,..Bookmark+1,..Position-$L("%ORDER")),"<>W")
							Set tState = 1
						}
						Else {
							Set tReturnList = $ZSTRIP($E(..Text,..Bookmark+1,*),"<>W")
							Quit
						}
						// - DTB827
					}
					
					Set tReturnTokens = tReturnTokens _ tToken		// DTB827 - Make sure there is something to pass along in the RETURN statement
				}
				ElseIf (tState = 1) { // %ORDER
					If ($$$UPPER(tToken)="BY") {
						Do ..%SetBookmark()		// DTB827 - Bookmark at the beginning of the %ORDER BY list
						Set tState = 2
					}
					Else {
						Set tSC = ..%Error("Invalid %ORDER BY clause")
						Quit
					}
				}
				ElseIf (tState = 2) { // %ORDER BY
					If (tType = "END") {
						// + DTB827 - Take the original text to be processed later by the SQL parser
						If (tOrderTokens = "") {
							Set tSC = ..%Error("%ORDER BY clause is empty")
						}
						Set tOrderList = $ZSTRIP($E(..Text,..Bookmark+1,..Position),"<>W")
						// - DTB827
						Quit
					}
					
					Set tOrderTokens = tOrderTokens _ tToken		// DTB827 - Make sure there is something to pass along in the %ORDER BY 
				}
			}
			If $$$ISERR(tSC) Quit

			Set ..Query.%listing = ""
			Set ..Query.%returnList = tReturnList
			Set ..Query.%orderList = tOrderList
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Take a string containing a member specification,
/// "[Member1].[Member2]", and return an array of the member
/// names indexed by ordinal position as well as an array of whether
/// a term was quoted or not.<br/>
/// <var>pMemberKey</var> is array indicating if a member key (&[]) is specified for an item.<br/>
/// This is used later in query processing.
ClassMethod %ParseMemberSpec(pText As %String, Output pInfo, Output pQuoted, Output pMemberKey) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Kill pInfo
	Set p = 1
	Set ch = $E(pText,p)
	Set tState = 0
	Set tItem = 0
	Set tToken = ""
	Set tBracketCount = 0
	Kill pInfo,pQuoted,pMemberKey		// DTB793 - Initialize output variables
	
	// State:
	// 0  - new token
	// 1  - [ 
	// 1a - [{
	// 1b - ['
	// 2  - []
	// 3  - : or . handling with state reset
	While (ch '= "") {
		Set tInSearch = $$$UPPER($G(pInfo(tItem)))="%SEARCH"		// DTB087 
		If (tState = 0) {
			If (ch = "[") {
				Set tState = 1
				Set tBracketCount = 1
				Set tToken = ""
			}
			ElseIf (ch = "&") {
				Set pMemberKey(tItem+1) = 1
			}
			ElseIf (ch = ":") {
				Set tSC = $$$ERROR($$$GeneralError,"Invalid Member Expression: ':' not expected.")
			}
			Else {
				Set tState = 3
				Set tToken = ch
			}
		}
		ElseIf (tState = 1) { // [
			If (ch = "[") {
				// DTB087 - This is enclosed in [] and therefore is considered escaped, unless it follows a [%SEARCH]
				// Track the bracket nesting in the %SEARCH case to determine when the search term is closed
				If tInSearch {
					Set tBracketCount = tBracketCount + 1
				}
				Set tToken = tToken _ "["
			}
			ElseIf (ch = "]") {
				Set tPeek = $E(pText,p+1)
				
				If (tPeek = "]") { 
					// DTB087 - This is an escaped ] and has no effect on the bracket count
					Set tToken = tToken _ "]" 
					Set p = p + 1
				}
				Else {
					Set tBracketCount = tBracketCount - 1
					If (tBracketCount = 0) {
						Set tState = 2
						If (tToken'="") {
							Set pInfo($I(tItem)) = tToken
							Set pQuoted(tItem) = 1
						}
						Else {
							Set tSC = $$$ERROR($$$GeneralError,"Invalid Member Expression: empty name (2)")
						}
						Set tToken = ""
					}
					Else {
						Set tToken = tToken _ "]"
					}
				}
			}
			ElseIf(ch="{") {
				Set tToken = tToken _ ch
				Set tState = "1a"
			}		
			ElseIf (ch="'") { // JSL4447
				Set tToken = tToken _ ch
				If tInSearch  {
					// DTB087 - use the string literal processing for a %Search term
					Set tState = "1b"
				}
			}

			Else {
				Set tToken = tToken _ ch
			}		
		}
		ElseIf (tState = "1a") { // [{
			If (ch="}") {
				Set tToken = tToken _ ch
				Set tState = 1
			}		
			Else {
				Set tToken = tToken _ ch
			}		
		}
		ElseIf (tState = "1b") { // [' JSL4447
			If (ch = "'") {
				Set tToken = tToken _ ch
				Set tPeek = $E(pText, p + 1)
				If (tPeek = "'") {
					Set p = p + 1
					Set tToken = tToken _ tPeek
				}
				Else {
					Set tState = 1
				}
			}
			Else {
				Set tToken = tToken _ ch
			}
		}
		
		ElseIf (tState = 2) { // []
			If (ch = ".") {
				Set tState = 0
			}
			ElseIf (ch = ":") {
				Set pInfo($I(tItem)) = ":"
				Set pQuoted(tItem) = 0
				Set tState = 0
			}
			ElseIf (ch '= " ") {
				Set tSC = $$$ERROR($$$GeneralError,"Invalid Member Expression: characters outside of []")
			}
		}
		ElseIf (tState = 3) { // ch
			If ((ch = ".")||(ch = ":")) {
				Set tState = 0
				Set tToken = $ZSTRIP(tToken,"<>W")
				If (tToken'="") {
					Set pInfo($I(tItem)) = tToken
					Set pQuoted(tItem) = 0
				}
				Else {
					Set tSC = $$$ERROR($$$GeneralError,"Invalid Member Expression: empty name (3)")
				}

				If (ch = ":") {
					Set pInfo($I(tItem)) = ":"
					Set pQuoted(tItem) = 0
				}
				Set tToken = ""
			}
			Else {
				Set tToken = tToken _ ch
			}		
		}

		#; next
		Set p = p + 1
		Set ch = $E(pText,p)
	}

	If (tState = 1) {
		If (tToken'="") {
			Set pInfo($I(tItem)) = tToken
			Set pQuoted(tItem) = 1
		}
		Else {
			Set tSC = $$$ERROR($$$GeneralError,"Invalid Member Expression: empty name (2)")
		}
	}
	ElseIf (tState = 3) {
		Set tToken = $ZSTRIP(tToken,"<>W")
		If (tToken'="") {
			Set pInfo($I(tItem)) = tToken
			Set pQuoted(tItem) = 0
		}
		Else {
			Set tSC = $$$ERROR($$$GeneralError,"Invalid Member Expression: empty name (4)")
		}
	}

	If ($G(pInfo(tItem)) = ":") {
		Set tSC = $$$ERROR($$$GeneralError,"Invalid Member Expression: ':' not expected.")
	}

	Quit tSC
}

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
/// <p>It is passed the arguments provided in the %New call.
/// When customizing this method, override the arguments with whatever variables and types you expect to receive from %New().
/// For example, if you're going to call %New, passing 2 arguments, %OnNew's signature could be:
/// <p>Method %OnNew(dob as %Date = "", name as %Name = "") as %Status
Method %OnNew(text As %RawString) As %Status [ Internal, Private, ServerOnly = 1 ]
{
	Set ..Text = text
	Set ..Position = 0
	Quit $$$OK
}

/// Returns true if <var>op1</var> has precedence over <var>op2</var>.
ClassMethod %TestPrecedence(op1 As %String, op2 As %String) As %Boolean [ Internal ]
{
	Set prec("OR") = 1
	Set prec("AND") = 2
	Set prec(">") = 3
	Set prec("<") = 3
	Set prec(">=") = 3
	Set prec("<=") = 3
	Set prec("=") = 4
	Set prec("<>") = 4
	Set prec("+") = 5
	Set prec("-") = 5
	Set prec("*") = 6
	Set prec("/") = 6

	// if value not in table, it has high precedence
	Set p1 = $G(prec(op1),9)
	Set p2 = $G(prec(op2),9)
	
	Quit p1 >= p2
}

/// Perform initial checks on the MDX text itself to see if there are obvious errors that can be reported
/// without further processing.
Method %ValidateText(pQuery As %DeepSee.Query.query = {$$$NULLOREF}, pText = "") As %Status
{
	// Method Added by DTB720
	Set tSC = $$$OK
	
	Try {
		If (pText'="") {
			Set tText = pText
		}
		ElseIf (..Text'="") {
			Set tText = ..Text
		}
		Else {
			Quit
		}

		// Tokenize the query text to check content rules
		Set tSC = ..%Tokenize(tText,.tTokenList)
		If $$$ISERR(tSC) Quit

		Set tHasSqlRestrict = 0

		Set tTokenNo = $O(tTokenList(""),1,tTokenData)
		While (tTokenNo'="") {
			Set tToken = $LG(tTokenData,2)
			If ($$$UPPER(tToken)="%SQLRESTRICT") {
				If tHasSqlRestrict {
					Set tSC = $$$ERROR($$$GeneralError,"Query must contain only one %SQLRESTRICT statement")
					$$$ThrowStatus(tSC)
				}
				Else {
					Set tHasSqlRestrict = 1
				}
			}
			
			Set tTokenNo = $O(tTokenList(tTokenNo),1,tTokenData)
		}
		
		If $IsObject(pQuery) {
			// DTB720 - If the query object is supplied, set what we have learned about flags. 
			Set pQuery.%hasSqlRestrict = tHasSqlRestrict
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

}
