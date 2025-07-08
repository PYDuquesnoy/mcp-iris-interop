/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occUtility, %DeepSee)

IncludeGenerator (%occUtility, %DeepSee)

/// Server-side implementation and utilities for Worksheet formulae.
Class %DeepSee.WorksheetEngine Extends %RegisteredObject [ Abstract, System = 4 ]
{

Parameter DOMAIN = "%DeepSee";

/// Given a worksheet name, open it and load the data needed to drive a dyna grid control.
/// If <var>pComputed</var> is true return the computed values for each cell,
/// otherwise return the original values, which could include formula.
ClassMethod %LoadDataSet(pWorksheetName As %String, pGrid As %ZEN.Component.dynaGrid, pDataSet As %ZEN.Auxiliary.dataSet, pComputed As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC =  $$$OK
	Try {
		Do pDataSet.%Clear()
		Set tName = $P(pWorksheetName,".",1,$L(pWorksheetName,".")-1)
		If (tName="") {
			Do pDataSet.%SetLabel("1",1,1)
			Do pDataSet.%SetLabel("A",1,2)
			Quit
		}

		// get data from worksheet
		#dim tWorksheet As %DeepSee.UserLibrary.Worksheet
		Set tWorksheet = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tName_".worksheet")
		If $IsObject(tWorksheet) {
			// grid-wide settings
			Set pGrid.format = tWorksheet.format
			Set pGrid.style = tWorksheet.style
			Set pGrid.showColumnLabels = tWorksheet.showColumnLabels
			Set pGrid.showRowLabels = tWorksheet.showRowLabels
			Set pGrid.borders = tWorksheet.borders
			Set pGrid.showZebra = tWorksheet.showZebra
			Set pGrid.columnHeaderStyle = tWorksheet.columnHeaderStyle
			Set pGrid.rowHeaderStyle = tWorksheet.rowHeaderStyle

			// loop and get headers
			Do pGrid.rows.Clear()
			Set tRowCount = tWorksheet.rowHeaders.Count()
			For r = 1:1:tRowCount {
				#dim tRow As %DeepSee.UserLibrary.WorksheetAxis
				Set tRow = tWorksheet.rowHeaders.GetAt(r)
				#; row labels  (dimension 1)
				Do pDataSet.%SetLabel(tRow.name,r,1)

				Set tRowInfo = ##class(%ZEN.Auxiliary.gridRow).%New()
				Set:tRow.style'="" tRowInfo.style = tRow.style
				Set:tRow.format'="" tRowInfo.format = tRow.format
				Set:tRow.priority'="" tRowInfo.priority = tRow.priority
				Set:tRow.value'="" tRowInfo.value = tRow.value
				Set:tRow.height'="" tRowInfo.height = tRow.height
				Set:tRow.readOnly'="" tRowInfo.readOnly = tRow.readOnly

				Do pGrid.rows.Insert(tRowInfo)
				Do:$IsObject($G(%page)) %page.%AddComponent(tRowInfo)
			}

			Do pGrid.columns.Clear()
			Set tColCount = tWorksheet.columnHeaders.Count()
			For c = 1:1:tColCount {
				#dim tCol As %DeepSee.UserLibrary.WorksheetAxis
				Set tCol = tWorksheet.columnHeaders.GetAt(c)
				#; columns labels  (dimension 2)
				Do pDataSet.%SetLabel(tCol.name,c,2)
				Set tColInfo = ##class(%ZEN.Auxiliary.gridColumn).%New()
				Set:tCol.style'="" tColInfo.style = tCol.style
				Set:tCol.format'="" tColInfo.format = tCol.format
				Set:tCol.priority'="" tColInfo.priority = tCol.priority
				Set:tCol.value'="" tColInfo.value = tCol.value
				Set:tCol.width'="" tColInfo.width = tCol.width
				Set:tCol.readOnly'="" tColInfo.readOnly = tCol.readOnly

				Set:tCol.type'="" tColInfo.type = tCol.type
				Set:tCol.valueList'="" tColInfo.valueList = tCol.valueList
				Set:tCol.lookupSpec'="" tColInfo.lookupSpec = tCol.lookupSpec
				Set:tCol.logicalValue'="" tColInfo.logicalValue = tCol.logicalValue

				Do pGrid.columns.Insert(tColInfo)
				Do:$IsObject($G(%page)) %page.%AddComponent(tColInfo)
			}

			// cell overrides
			Do pGrid.cells.Clear()
			Set tCellCount = tWorksheet.cells.Count()
			For n = 1:1:tCellCount {
				#dim tCell As %DeepSee.UserLibrary.WorksheetCell
				Set tCell = tWorksheet.cells.GetAt(n)
				Set tCellInfo = ##class(%ZEN.Auxiliary.gridCell).%New()
				Set:tCell.page'="" tCellInfo.page = tCell.page
				Set:tCell.row'="" tCellInfo.row = tCell.row
				Set:tCell.column'="" tCellInfo.column = tCell.column

				Set:tCell.style'="" tCellInfo.style = tCell.style
				Set:tCell.format'="" tCellInfo.format = tCell.format
				Set:tCell.readOnly'="" tCellInfo.readOnly = tCell.readOnly

				Do pGrid.cells.Insert(tCellInfo)
				Do:$IsObject($G(%page)) %page.%AddComponent(tCellInfo)
			}

			#; find size of dataSet
			Set rows = pDataSet.%GetDimSize(1)
			Set cols = pDataSet.%GetDimSize(2)

			#; recalc
			If (pComputed) {
				Set tSC = tWorksheet.%Calculate()
				If $$$ISERR(tSC) Quit
			}

			#; fill in initial data
			For r=1:1:rows {
				For c=1:1:cols {
					Set tVal = $S(pComputed:$G(tWorksheet.%values(r,c)),1:$G(tWorksheet.%cells(r,c)))
					Do pDataSet.%SetValue(tVal,r,c)
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// DIAGNOSTIC!!!
ClassMethod TestTokens(pExpr As %String) [ Internal ]
{
	Set tMsg = ..%Tokenize(pExpr,.tokens)
	If (tMsg'="") {
		Write tMsg,!
		Quit
	}

	Write !,"-------------------------",!

	Set t = $O(tokens(""))
	While (t '= "") {
		Write t,?5,$G(tokens(t,"type")),?15,"'",$G(tokens(t,"token")),"'"," (",$G(tokens(t,"pos")),")",!
		Set t = $O(tokens(t))
	}
}

/// Split the formula <var>expr</var> into a token list:<br/>
/// tokens(n,"token") = token<br/>
/// tokens(n,"pos") = position in expr<br/>
/// tokens(n,"type") = string | number | ident | func |op |unary | ( | ) | , | end
/// Returns "" if the formula is correct else an error message.
/// Note that idents are also returned as escaped: [a]
ClassMethod %Tokenize(expr As %String, ByRef pTokens As %String) As %String [ Internal ]
{
	// clear out token list
	Kill pTokens

	// append an endmarker to simplify 
	// end of expr processing
	Set expr = expr _ $C(0)
	
	Set tIdentStart	= "["
	Set tIdentEnd	= "]"
	Set pTokens = 0			// number of tokens in list
	Set err = ""			// error msg ("" for ok)
	Set state = 0			// current state of state machine
	Set token = ""			// current token
	Set n = 0				// current character pos in input
	Set ch = ""				// current character from input
	Set startpos = 1		// startpos of current token
	Set firsttok = 1		// keep track of first tok (or first in parens) to detect unary ops

	While ((err = "") && (n < $L(expr))) {
		Set n = n + 1
		Set ch = $E(expr,n)

		// process next character using state machine
		#;WRITE:$G(%debug) state,": '",ch,"'",!
		If (state = 0) {
			// start
			If (ch = $C(0)) {
				// end
			}
			ElseIf (ch = """") {
				// start of string literal
				Set token = ""
				Set state = 1
				Set startpos = n
				Set firsttok = 0
			}
			ElseIf (ch=tIdentStart) {
				// start of quoted ident
				Set state = 8
				Set token = ch
				Set startpos = n
				Set firsttok = 0
			}
			ElseIf (ch = +ch) {
				// start of integer literal
				Set token = ch
				Set state = 2
				Set startpos = n
				Set firsttok = 0
			}
			ElseIf (ch = ".") {
				// numeric literal
				Set state = 3
				Set token = "0."
			}
			ElseIf (firsttok && ..IsUnaryOperatorChar(ch)) {
				// unary operator
				Set state = 7
				Set token = ch
				Set startpos = n
				Set firsttok = 0
			}
			ElseIf (..IsOperatorChar(ch)) {
				// start of op
				Set state = 6
				Set token = ch
				Set startpos = n
				Set firsttok = 0
			}
			ElseIf (..IsSpecialChar(ch)) {
				// special token: add to list
				Set pTokens = $$AddToken(pTokens,ch,ch,n)
				Set firsttok = 0
				Set:(ch'=")") firsttok = 1
			}
			ElseIf (..IsIdentChar(ch)) {
				// start of ident
				Set state = 4
				Set token = tIdentStart _ ch
				Set startpos = n
				Set firsttok = 0
			}
			ElseIf (..IsWhiteSpace(ch)) {
				// ignore
			}
			Else {
				// error
				Set err = $$$FormatText($$$Text("ERROR(T01): unexpected character (%1) %2"),n,ch)
			}
		}
		ElseIf (state = 1) {
			// string literal
			If (ch = $C(0)) {
				// end
				Set err = $$$FormatText($$$Text("ERROR(T11): no closing quotes for string (%1) %2"),n,token)
			}
			ElseIf (ch = """") {
				// look ahead for ""
				Set peek = $E(expr,n+1)
				If (peek = """") {
					// "" (first ")
					Set token = token _ ch
					Set state = 5
				}
				Else {
					// end of string
					Set pTokens = $$AddToken(pTokens,token,"string",startpos)
					Set token = ""
					Set state = 0
				}
			}
			Else {
				Set token = token _ ch
			}
		}
		ElseIf (state = 2) {
			// integer literal
			If (ch = $C(0)) {
				// end
				// add number to list
				Set pTokens = $$AddToken(pTokens,token,"number",startpos)
			}
			ElseIf (ch = +ch) {
				// add to integer literal
				Set token = token _ ch
			}
			ElseIf (ch = ".") {
				// numeric literal
				Set state = 3
				Set token = token _ ch
			}
			ElseIf (..IsOperatorChar(ch)) {
				// add number to list
				Set pTokens = $$AddToken(pTokens,token,"number",startpos)

				// start of op
				Set state = 6
				Set token = ch
				Set startpos = n
			}
			ElseIf (..IsSpecialChar(ch)) {
				// add number to list
				Set pTokens = $$AddToken(pTokens,token,"number",startpos)

				// special token: add to list
				Set pTokens = $$AddToken(pTokens,ch,ch,n)

				Set token = ""
				Set state = 0
				Set firsttok = 0
				Set:(ch'=")") firsttok = 1
			}
			ElseIf (..IsWhiteSpace(ch)) {
				// add number to list
				Set pTokens = $$AddToken(pTokens,token,"number",startpos)

				Set state = 0
				Set token = ""
			}
			Else {
				// error
				Set token = token _ ch
				Set err = $$$FormatText($$$Text("ERROR(T21): invalid number at position (%1) %2"),n,token)
			}
		}
		ElseIf (state = 3) {
			// numeric literal
			If (ch = $C(0)) {
				// end
				// add number to list
				Set:$E(token,$L(token))="." token = token_"0"
				Set pTokens = $$AddToken(pTokens,token,"number",startpos)
			}
			ElseIf (ch = +ch) {
				// add to numeric literal
				Set token = token _ ch
			}
			ElseIf (ch = ".") {
				// error
				Set token = token _ ch
				Set err = $$$FormatText($$$Text("ERROR(T31): invalid number at position (%1) %2"),n,token)
			}
			ElseIf (..IsOperatorChar(ch)) {
				// add number to list
				Set:$E(token,$L(token))="." token = token_"0"
				Set pTokens = $$AddToken(pTokens,token,"number",startpos)

				// start of op
				Set state = 6
				Set token = ch
				Set startpos = n
			}
			ElseIf (..IsSpecialChar(ch)) {
				// add number to list
				Set:$E(token,$L(token))="." token = token_"0"
				Set pTokens = $$AddToken(pTokens,token,"number",startpos)

				// special token: add to list
				Set pTokens = $$AddToken(pTokens,ch,ch,n)

				Set token = ""
				Set state = 0
				Set firsttok = 0
				Set:(ch'=")") firsttok = 1
			}
			Else {
				Set:$E(token,$L(token))="." token = token_"0"
				Set pTokens = $$AddToken(pTokens,token,"number",startpos)

				Set token = ""
				Set state = 0
			}
		}
		ElseIf (state = 4) {
			// ident
			If (ch = $C(0)) {
				// end
				// add ident to list (!!! don't test multipart ident)
				If ((token'[".")&&'..IsValidIdent(token)) {
					Set err = $$$FormatText($$$Text("ERROR(T40): invalid identifier at position (%1) %2"),n,token)
				}
				Else {
					Set pTokens = $$AddToken(pTokens,token_tIdentEnd,"ident",startpos)
				}
			}
			ElseIf ((ch = ".")) {
				// compound ident
				Set peek = $E(expr,n+1)
				If (peek=tIdentStart) {
					Set token = token _ tIdentEnd _ ch
					Set state = 8
				}
				ElseIf (..IsIdentChar(peek)) {
					Set token = token_ tIdentEnd _ ch _ tIdentStart
					Set state = 4
				}
				Else {
					Set err = $$$FormatText($$$Text("ERROR(T49): invalid identifier '%2' at position (%1)"),n,token)
				}
			}
			ElseIf (..IsOperatorChar(ch)) {
				// add ident to list
				If ('..IsValidIdent(token)) {
					Set err = $$$FormatText($$$Text("ERROR(T41): invalid identifier at position (%1) %2"),n,token)
				}
				Else {
					Set pTokens = $$AddToken(pTokens,token_tIdentEnd,"ident",startpos)

					// start of op
					Set state = 6
					Set token = ch
					Set startpos = n
				}
			}
			ElseIf (..IsSpecialChar(ch)) {
				// add ident to list
				If ('..IsValidIdent(token)) {
					Set err = $$$FormatText($$$Text("ERROR(T42): invalid identifier at position (%1) %2"),n,token)
				}
				Else {
					Set pTokens = $$AddToken(pTokens,token_tIdentEnd,"ident",startpos)

					// special token: add to list
					Set pTokens = $$AddToken(pTokens,ch,ch,n)

					Set token = ""
					Set state = 0
					Set firsttok = 0
					Set:(ch'=")") firsttok = 1
				}
			}
			ElseIf (..IsWhiteSpace(ch)) {
				// whitespace: end of ident 

				// add ident to list
				If ('..IsValidIdent(token)) {
					Set err = $$$FormatText($$$Text("ERROR(T43): invalid identifier at position (%1) %2"),n,token)
				}
				Else {
					Set pTokens = $$AddToken(pTokens,token_tIdentEnd,"ident",startpos)
					Set token = ""
					Set state = 0
				}
			}
			ElseIf ((ch = """")) {
				// error: quote in ident
				Set token = token _ ch
				Set err = $$$FormatText($$$Text("ERROR(T45): misplaced quotation mark (%1) %2"),n,token)
			}
			ElseIf ('..IsIdentChar(ch)) {
				// error: invalid char
				Set token = token _ ch
				Set err = $$$FormatText($$$Text("ERROR(T46): invalid character in identifier (%1) %2"),n,token)
			}
			Else {
				Set token = token _ ch
			}
		}
		ElseIf (state = 5) {
			// "" in a string
			If (ch = """") {
				// this is the 2nd " that we expect
				Set token = token _ ch
				Set state = 1
			}
			Else {
				// should not happen- we have looked ahead for "
				Set err = $$$FormatText($$$Text("ERROR(T51): unexpected character '%2' at position (%1)"),n,ch)
			}
		}
		ElseIf (state = 6) {
			// op (binary)
			If (ch = $C(0)) {
				// end
				Set err = $$$FormatText($$$Text("ERROR(T64): unexpected end of expression at position (%1)"),n)
			}
			ElseIf (..IsOperatorChar(ch)) {
				// test for unary operator after binary...
				If ((..IsBinaryOperator(token)) && (..IsUnaryOperatorChar(ch))) {
					// add first op to list
					Set pTokens = $$AddToken(pTokens,token,"op",startpos)

					// process 2nd op as new unary op
					Set token = ch
					Set state = 7
					Set startpos = n
				}
				Else {
					Set token = token _ ch
				}
			}
			ElseIf (..IsSpecialChar(ch)) {
				If (('..IsBinaryOperator(token)) && ('..IsUnaryOperator(token))) {
					Set err = $$$FormatText($$$Text("ERROR(T61): invalid operator '%2' at position (%1)"),n,token)
				}
				Else {
					// add op to list
					Set pTokens = $$AddToken(pTokens,token,"op",startpos)

					// special token: add to list
					Set pTokens = $$AddToken(pTokens,ch,ch,n)

					Set token = ""
					Set state = 0
					Set firsttok = 0
					Set:(ch'=")") firsttok = 1
				}
			}
			Else {
				// end of op
				If (('..IsBinaryOperator(token)) && ('..IsUnaryOperator(token))) {
					Set err = $$$FormatText($$$Text("ERROR(T62): invalid operator '%2' at position (%1)"),n,token)
				}
				Else {
					// add op to list
					Set pTokens = $$AddToken(pTokens,token,"op",startpos)

					If (..IsWhiteSpace(ch)) {
						// whitespace
						Set token = ""
						Set state = 0
						Set firsttok = 1
					}
					ElseIf (ch = """") {
						// start of string
						Set token = ""
						Set state = 1
						Set startpos = n
					}
					ElseIf (ch = +ch) {
						// start of number
						Set token = ch
						Set state = 2
						Set startpos = n
					}
					ElseIf (ch = ".") {
						// numeric literal
						Set state = 3
						Set token = "0."
					}
					ElseIf (ch=tIdentStart) {
						// start of quoted ident
						Set state = 8
						Set token = ch
						Set startpos = n
					}
					ElseIf (..IsIdentChar(ch)) {
						// start of ident
						Set token = tIdentStart _ ch
						Set state = 4
						Set startpos = n
					}
					Else {
						// error
						Set err = $$$FormatText($$$Text("ERROR(T63): invalid character '%2' at position (%1)"),n,ch)
					}
				}
			}
		}
		ElseIf (state = 7) {
			// unary operator
			// Note: there cannot be multi-char unary operators
			If (..IsSpecialChar(ch)) {
				If ('..IsUnaryOperator(token)) {
					Set err = $$$FormatText($$$Text("ERROR(T72): invalid operator '%2' at position (%1)"),n,token)
				}
				Else {
					// add op to list
					Set pTokens = $$AddToken(pTokens,token,"unary",startpos)

					// special token: add to list
					Set pTokens = $$AddToken(pTokens,ch,ch,n)

					Set token = ""
					Set state = 0
					Set firsttok = 0
					Set:(ch'=")") firsttok = 1
				}
			}
			Else {
				// end of op
				If (ch = $C(0)) {
					// end
					Set err = $$$FormatText($$$Text("ERROR(T71): unexpected end of expression at position (%1)"),n)
				}
				ElseIf ('..IsUnaryOperator(token)) {
					Set err = $$$FormatText($$$Text("ERROR(T73): invalid unary operator '%2' at position (%1)"),n,token)
				}
				Else {
					// add op to list
					Set pTokens = $$AddToken(pTokens,token,"unary",startpos)

					If (..IsWhiteSpace(ch)) {
						// whitespace
						Set token = ""
						Set state = 0
					}
					ElseIf (ch = """") {
						// start of string
						Set token = ""
						Set state = 1
						Set startpos = n
					}
					ElseIf (ch = +ch) {
						// start of number
						Set token = ch
						Set state = 2
						Set startpos = n
					}
					ElseIf (ch = ".") {
						// numeric literal
						Set state = 3
						Set token = "0."
					}
					ElseIf (ch=tIdentStart) {
						// start of quoted ident
						Set state = 8
						Set token = ch
						Set startpos = n
					}
					ElseIf (..IsIdentChar(ch)) {
						// start of ident
						Set token = tIdentStart_ch
						Set state = 4
						Set identType = "ident"
						Set startpos = n
					}
					ElseIf (..IsUnaryOperatorChar(ch)) {
						// unary operator
						Set state = 7
						Set token = ch
						Set startpos = n
						Set firsttok = 0
					}
					Else {
						// error
						Set err = $$$FormatText($$$Text("ERROR(T74): invalid character '%2' at position (%1)"),n,ch)
					}
				}
			}
		}
		ElseIf (state = 8) {
			// delimited ident
			If (ch = $C(0)) {
				// end
				Set err = $$$FormatText($$$Text("ERROR(T80): unexpected end of identifier at position (%1) %2"),n,token)
			}
			ElseIf (ch = tIdentEnd) {
				// do not validate
				// keep [] around ident
				// test for compound ident [a].[b]
				Set peek = $E(expr,n+1)
				If (peek=".") {
					// compound ident: [a].[b]
					Set token = token _ ch
					Set state = 9
				}
				Else {
					// add ident to list
					Set token = token _ ch
					Set pTokens = $$AddToken(pTokens,token,"ident",startpos)
					Set token = ""
					Set state = 0
				}
			}
			Else {
				Set token = token _ ch
			}
		}
		ElseIf (state = 9) {
			// . in compound ident
			Set peek = $E(expr,n+1)
			If ((ch=".") &&(peek=tIdentStart)) {
				Set token = token _ ch
				Set state = 8
			}
			ElseIf ((ch=".")&&(..IsIdentChar(peek))) {
				Set token = token _ ch _ tIdentStart
				Set state = 4
			}
			Else {
				Set err = $$$FormatText($$$Text("ERROR(T74): invalid identifier '%2' at position (%1)"),n,token)
			}
		} // end of states
	} // end of next character loop
	
	// add end token
	If (err = "") {
		Set pTokens = $$AddToken(pTokens,"","end",n)
	}

	If (err = "") {
		// loop over tokens and find any functions: ident + "(" 
		// also build list of properties and functions used
		Set last = ""
		Set t = $O(pTokens(""))
		While (t '= "") {

			If ($G(pTokens(t,"type")) = "(" ) {
				If ((last '= "") && ($G(pTokens(last,"type")) = "ident")) {
					// replace two tokens with one
					Kill pTokens(t)
					Set pTokens(last,"type") = "func"
				}
			}

			Set last = t
			Set t = $O(pTokens(t))
		}
	}
	
	Quit err

AddToken(no,tok,tp,ps)
	// insert new token into token list
	Set no=no+1, pTokens(no,"token")=tok,pTokens(no,"type")=tp, pTokens(no,"pos")=ps
	Quit no
}

/// Returns true if <var>op1</var> has precedence over <var>op2</var>.
ClassMethod TestPrecedence(op1 As %String, op2 As %String) As %Boolean [ Internal ]
{
	Set prec("||") = 1
	Set prec("&&") = 2
	Set prec("&") = 3
	Set prec("+") = 4
	Set prec("-") = 4
	Set prec("*") = 5
	Set prec("/") = 5
	
	// if value not in table, it has high precedence
	Set p1 = $G(prec(op1),9)
	Set p2 = $G(prec(op2),9)
	
	Quit p1 >= p2
}

/// Test if token is a valid (unquoted) identifier.
ClassMethod IsValidIdent(token As %String) As %Boolean [ Internal ]
{
	Set tRet = 1
	For p=1:1:$L(token,".") {
		Set x = $P(token,".",p)
		// remove []
		Set:$E(x,1)="[" x = $E(x,2,*)
		Set:$E(x,*)="]" x = $E(x,1,*-1)

		// $ can be at start of piece
		Set:$E(x,1)="$" x = $E(x,2,*)
		If '$zname(x) {
			Set tRet = 0
			Quit
		}
	}
	Quit tRet
}

/// Test if token is a unary operator
ClassMethod IsUnaryOperator(token As %String) As %Boolean [ CodeMode = expression, Internal ]
{
",+,-,!," [ (","_token_",")
}

/// Test if token is a binary operator
ClassMethod IsBinaryOperator(token As %String) As %Boolean [ CodeMode = expression, Internal ]
{
",+,-,*,/,!=,=,>=,<=,>,<,&,&&,||,[,_," [ (","_token_",")
}

/// Test if char is a part of an unary operator name
ClassMethod IsUnaryOperatorChar(char As %String) As %Boolean [ CodeMode = expression, Internal ]
{
",+,-,!," [ (","_char_",")
}

/// Test if char is a part of an operator name
ClassMethod IsOperatorChar(char As %String) As %Boolean [ CodeMode = expression, Internal ]
{
",+,-,*,/,<,>,=,&,|,!,_," [ (","_char_",")
}

/// Test if char is a special character "(" ")" or ","
ClassMethod IsSpecialChar(char As %String) As %Boolean [ CodeMode = expression, Internal ]
{
((char = ",") || (char = "(") || (char = ")"))
}

/// Test if char can be part of an identifier
ClassMethod IsIdentChar(char As %String) As %Boolean [ CodeMode = expression, Internal ]
{
$S(char="%":1,char="$":1,1:$zname("a" _ char))
}

/// Test if char is a whitespace character
ClassMethod IsWhiteSpace(char As %String) As %Boolean [ CodeMode = expression, Internal ]
{
(char = " ")
}

/// Evaluate the given expression.<br/>
ClassMethod %Evaluate(pExpr As %String, pContextObj As %RegisteredObject = "", Output pErrorMsg As %String, Output pSC As %Status) As %String [ Internal ]
{
	Set tValue = ""
	Set pErrorMsg = ""
	Set pSC = $$$OK

	Try {
		Set tMsg = ..%Parse(pExpr, .pTree)
		If (tMsg '= "") {
			Set pErrorMsg = tMsg
			Quit
		}

		// n.b., don't use execute because the error handling is impossible
		Set tValue = ..%EvalExpression(.tErr,pContextObj,.pTree)

		/*

		Set x = ..%GenExpression(.tErr,"%engine",.pTree)
		If (tErr '= "") {
			Set pErrorMsg = tErr
			Quit
		}
		If (x = "") {
			Quit
		}

		// set up execute environment		
		New %val,%engine
		Set %engine = pContextObj
		X "Set %val=" _ x

		If ($IsObject(%val)) {
			Set tValue = "object"
			Quit
		}
		Set tValue = %val
		*/
	}
	Catch(ex) {
		Set pSC = ex.AsStatus()
		Set pErrorMsg = $P($ZE,">",1) _ ">"
		Set pErrorMsg = $TR(pErrorMsg,"<>","[]")
		Set tValue = ""
	}
	Quit tValue
}

/// DIAGNOSTIC!!!
ClassMethod Test(expr As %String, ByRef tree) [ Internal ]
{
	Kill tree
	Set msg = ..%Parse(expr, .tree, .props,.funcs)
	If (msg '= "") {
		Write msg,!
		Quit
	}

	Write !,"-------------------------------",!
	Do ..%PrintParseNode(.tree,0)

	Write !,"-------------------------------",!
	Set expr = ..%GenExpression(.tErr,"%engine",.tree)
	
	Write !,"expr = ",expr
	If (tErr '= "") {
		Write "GenExpression Error: ",tErr,!
	}

	// X "Write !,""Result=""," _ expr
	
	If ($D(props)) {
		Write !,"-------------------------------"
		Write !,"Properties"
		Set k = $O(props(""))
		While (k '= "") {
			Write !,?5,k
			Set k = $O(props(k))
		}
	}

	If ($D(funcs)) {
		Write !,"-------------------------------"
		Write !,"Functions"
		Set k = $O(funcs(""))
		While (k '= "") {
			Write !,?5,k
			Set k = $O(funcs(k))
		}
	}
}

ClassMethod %PrintParseNode(ByRef tree, node As %Integer, level As %Integer = 0) [ Internal ]
{
	If ($G(tree(node,"type")) = "string") {
		Set q = """"
	} Else {
		Set q = ""
	}
	Set ind=(level*3)
	Write ?ind,node,?(ind+3),$G(tree(node,"type")),":",?(ind+12),q,$G(tree(node,"token")),q,!
	
	Set ch="" For { Set ch=$O(tree(node,"ch",ch))  Quit:""=ch
		Do ..%PrintParseNode(.tree,ch,level+1)
	}
}

/// Parse the expr into a parse tree <var>tree</var><br>
/// Returns "" if ok or else an error message.<br>
/// <var>pPropList</var> returns an array of properties referenced
/// by the expression.
/// <var>pFuncList</var> returns an array of functions referenced
/// by the expression.
ClassMethod %Parse(pExpr As %String, Output tree As %String, Output pPropList As %String, Output pFuncList As %String) As %String [ Internal ]
{
	Kill tree
	Kill pPropList
	Kill pFuncList

	// first tokenize
	Set err = ..%Tokenize(pExpr,.tokens)
	If (err '= "") {
		Quit err
	}
	
	// first pass at syntax check: check for back-to-back idents, etc.
	Set lasttype = ""
	Set tokno = $O(tokens(""))
	While ((err = "") && (tokno '= "")) {
		Set type = tokens(tokno,"type")
		
		If ((type = "ident") && (lasttype = "ident")) {
			// 2 idents in a row: error
			Set err = $$$FormatText($$$Text("Missing operator in expression at position: %1"),$G(tokens(tokno,"pos")))
		}
		
		// update list of funcs and props
		If (type = "ident") {
			Set pPropList(tokens(tokno,"token")) = ""
		}
		ElseIf (type = "func") {
			Set pFuncList(tokens(tokno,"token")) = ""
		}
		Set lasttype = type
		Set tokno = $O(tokens(tokno))
	}
	
	If (err '= "") {
		Quit err
	}
	
	// walk over each item in token list
	// add them to the parse tree and reduce
	
	Set tree = 0					// node ptr
	Set tree(tree,"type") = "top"
	Set level = 0					// stack level
	Set parent(0) = tree			// parent of current level
	Set unary(0) = 0				// flag for unary operators (stacked)
	
	Set tokno = $O(tokens(""))
	While ((err = "") && (tokno '= "")) {
		
		// add token to tree
		If (tokens(tokno,"type") = "func") {
			
			Set tree = tree + 1
			Merge tree(tree) = tokens(tokno)
			Set tree(parent(level),"ch",tree) = ""

			// make func node the parent until we find ")"
			Set level = level + 1
			Set parent(level) = tree
			Set unary(level) = 0
		}
		ElseIf (tokens(tokno,"type") = "(") {
			
			// push paren on the stack
			Set tree = tree + 1
			Merge tree(tree) = tokens(tokno)
			Set tree(parent(level),"ch",tree) = ""

			Set level = level + 1
			Set parent(level) = tree
			Set unary(level) = 0
		}
		ElseIf (tokens(tokno,"type") = ")") {
			If (level = 0) {
				Set err = $$$Text("ERROR (P8) Extra ')' in formula.")
			}
			Else {
				While (unary(level) = 1) {
					// pop unary op
					Set level = level - 1
				}

				Set level = level - 1
			}
		}
		ElseIf (tokens(tokno,"type") = "end") {
			// dummy end node
			While ((level > 0) && (unary(level) = 1)) {
				// single arg for unary operator; pop stack
				Set level = level - 1
			}
		}
		ElseIf (tokens(tokno,"type") = "unary") {
			// put unary op in tree; make next item a child of it
			Set tree = tree + 1
			Merge tree(tree) = tokens(tokno)
			Set tree(parent(level),"ch",tree) = ""

			// make unary node the parent for next token(s)
			Set level = level + 1
			Set parent(level) = tree
			Set unary(level) = 1
		}
		Else {
			Set tree = tree + 1
			Merge tree(tree) = tokens(tokno)
			Set tree(parent(level),"ch",tree) = ""
			
			While ((unary(level) = 1)) {
				// single arg for unary operator; pop stack
				Set level = level - 1
			}
		}
		
		//Write "===================================",!
		//Write tokno,?10,"(",tokens(tokno,"token"),") ",tokens(tokno,"type"),!
		//Do ..PrintParseNode(.tree,0)

		// apply reducing rules
		// for convenience, get last 3 types from parent
		Set node(1)="",node(2)="",node(3)=""
		Set tok(1)="",tok(2)="",tok(3)=""
		
		Set node(3) = $O(tree(parent(level),"ch",""),-1)
		Set:(node(3)'="") node(2) = $O(tree(parent(level),"ch",node(3)),-1)
		Set:(node(2)'="") node(1) = $O(tree(parent(level),"ch",node(2)),-1)
		
		//Write !,?5,tokno," ",r,!
		For i=1:1:3 {
			Set tok(i) = $S(node(i)="":"",1:$G(tree(node(i),"token")))
			Set type(i) = $S(node(i)="":"",1:$G(tree(node(i),"type")))
			//Write ?10,">> ",tok(i)," ",node(i)," ",type(i),!
		}

		// arg op arg ==>   
		If (((type(1) '= "") && (type(1) '= "op")) &&
			 (type(2) = "op") && 
			 ((type(3) '= "") && (type(3) '= "op"))) {

			//Write "AOA(",r,")",!

			// replace (arg op arg) with (op (arg arg))
			Set tree(node(2),"ch",node(1)) = ""
			Set tree(node(2),"ch",node(3)) = ""
			Kill tree(parent(level),"ch",node(1))
			Kill tree(parent(level),"ch",node(3))
		}
		// op op arg ==>   
		ElseIf (((type(1) = "op")) &&
			 (type(2) = "op") && 
			 ((type(3) '= "") && (type(3) '= "op"))) {

			//Write "OOA(",r,")  ",tok(1),":",node(1),",",tok(2),":",node(2)

			If ('..TestPrecedence(tok(1),tok(2))) {
				// rebuild tree to match precedence
				
				// find last child of op1
				Set child = $O(tree(node(1),"ch",""),-1)
				
				// make op1 a child of op2
				Set tree(node(1),"ch",node(2)) = ""
				Kill tree(parent(level),"ch",node(2))
				
				// make child a child of op2
				Set tree(node(2),"ch",child) = ""
				Kill tree(node(1),"ch",child)

				// make arg a child of op2
				Set tree(node(2),"ch",node(3)) = ""
				Kill tree(parent(level),"ch",node(3))
			}
			Else {
				// replace (arg op arg) with (op (arg arg))
				Set tree(node(2),"ch",node(1)) = ""
				Set tree(node(2),"ch",node(3)) = ""
				Kill tree(parent(level),"ch",node(1))
				Kill tree(parent(level),"ch",node(3))
			}
		}
	
		//Write !,"-----------------------------",!
		//Do ..PrintParseNode(.tree,0)

		// next token
		Set tokno = $O(tokens(tokno))
	}
	
	If (err '= "") {
		Quit err
	}

	If (level > 0) {
		Quit $$$Text("ERROR (P9) missing ')' in formula")
	}
	
	// walk tree and remove "," and "end" nodes
	Set n = $O(tree(""))
	While (n '= "") {
		If ((tree(n,"type") = ",") || (tree(n,"type") = "end")) {
			// remove node
			Kill tree(n)

			// remove parent reference (the lazy way)
			Set k = $O(tree(""))
			While (k '= "") {
				Kill tree(k,"ch",n)
				Set k = $O(tree(k))
			}
		}
		
		Set n = $O(tree(n))
	}

	Quit ""
}

/// Generate an executable COS expression for part of the parse tree<br/>
/// <var>context</var> is the name of the object variable containing runtime context.<br/>
/// Returns "" for error (assumes that parse tree has already been checked)
/// NOT USED
ClassMethod %GenExpression(ByRef pErr As %String, pContext As %String, ByRef tree As %String, node As %String = "") As %String
{
	Set:node="" node = $O(tree(""))
	Set:'$D(pErr) pErr=""
	
	Set tType = $G(tree(node,"type"))
	Set tToken = $G(tree(node,"token"))
	
	If (tType = "top") {
		// call this for child of top
		If ($O(tree(node,"ch","")) = "") {
			// empty tree
			Quit """"""
		}
		Else {
			Quit ..%GenExpression(.pErr,pContext,.tree,$O(tree(node,"ch","")))
		}
	}
	ElseIf (tType = "ident") {
		Set expr = $S(pContext="":"",1:pContext_".") _ "%Lookup("_$$$quote(tToken)_")"
	}
	ElseIf (tType = "qident") {
		Set expr = $S(pContext="":"",1:pContext_".") _ "GetValueAt(""" _ tToken _ """)"
	}
	ElseIf (tType = "number") {
		Set expr = tToken
	}
	ElseIf (tType = "string") {
		Set expr = """" _ tToken _ """"
	}
	ElseIf (tType = "op") {
		// binary operator: get args
		Set ch1 = $O(tree(node,"ch",""))
		Set ch2 = $O(tree(node,"ch",ch1))
		
		If ((ch1 = "") || (ch2 = "")) {
			Set pErr = $G(pErr) _ $$$FormatText($$$Text("Missing args for binary operator: %1; "),tToken)
			Set expr = ""
		}
		Else {
			// translate ops to COS
			Set tok = tToken
			If (tok = "!=") {
				Set op = "'="
			}
			ElseIf (tok = "&") {	 // !!!
				Set op = "_"
			}
			Else {
				Set op = tok
			}
			Set expr = "(" _ ..%GenExpression(.pErr,pContext,.tree,ch1) _
						op _ ..%GenExpression(.pErr,pContext,.tree,ch2) _ ")"
		}
	}
	ElseIf (tType = "unary") {
		// unary operator: get arg
		Set ch1 = $O(tree(node,"ch",""))
		
		If (ch1 = "") {
			Set pErr = $G(pErr) _ $$$Text("Missing arg for unary operator; ")
			Set expr = ""
		}
		Else {
			// translate op to COS
			Set tok = tToken
			If (tok = "!") {
				Set tok = "'"
			}
			Set expr = "(" _ tok _ ..%GenExpression(.pErr,pContext,.tree,ch1) _ ")"
		}
	}
	ElseIf (tType = "(") {
		// parens: get arg
		Set ch1 = $O(tree(node,"ch",""))
		
		Set expr = "(" _ ..%GenExpression(.pErr,pContext,.tree,ch1) _ ")"
	}
	ElseIf (tType = "func") {
		// lookup function from list
		// !!!! If $d(tFunctionSet)=0 Do ##class(Ens.Rule.Utils).GetAllFunctions(.tFunctionSet)
		Set val = $g(tFunctionSet($ZCVT(tToken,"U")))
		If ""'=val {
			Set cls = $LG(val,1)
			Set method = $LG(val,2)

			Set expr = "##class(" _ cls _ ")." _ method _ "("

			// build list of args
			Set n = 1
			Set ch="" For { Set ch=$O(tree(node,"ch",ch))  Quit:""=ch
				Set expr = expr _ $S(n>1:",",1:"") _ ..%GenExpression(.pErr,pContext,.tree,ch)
				Set n = n + 1
			}
			Set expr = expr _ ")"
		} Else {
			Set pErr = $G(pErr) _ $$$FormatText($$$Text("Unknown Function: %1; "),tToken)
			Set expr = ""
		}
	}
	Else {
		Set pErr = $G(pErr) _ $$$FormatText($$$Text("Unknown Node: %1; "),tType)
		Set expr = ""
	}
	Quit expr
}

/// Evaluates part of the parse tree.<br/>
/// <var>pContext</var> is the object variable containing runtime context.<br/>
/// Returns "" for error (assumes that parse tree has already been checked)
ClassMethod %EvalExpression(ByRef pErr As %String, pContext As %String, ByRef tree As %String, node As %String = "") As %String
{
	Set tValue = ""
	Set tSC = $$$OK
	Try {
		Set:node="" node = $O(tree(""))
		Set:'$D(pErr) pErr=""

		Set tType = $G(tree(node,"type"))
		Set tToken = $G(tree(node,"token"))
	
		If (tType = "top") {
			// call this for child of top
			If ($O(tree(node,"ch","")) = "") {
				// empty tree
				Set tValue = ""
			}
			Else {
				Set tValue = ..%EvalExpression(.pErr,pContext,.tree,$O(tree(node,"ch","")))
			}
			Quit
		}
		ElseIf (tType = "ident") {
			// invoke Lookup method
			Set tValue = $method(pContext,"%Lookup",tToken)
		}
		ElseIf (tType = "number") {
			Set tValue = tToken
		}
		ElseIf (tType = "string") {
			Set tValue = tToken
		}
		ElseIf (tType = "op") {
			// binary operator: get args
			Set ch1 = $O(tree(node,"ch",""))
			Set ch2 = $O(tree(node,"ch",ch1))
		
			If ((ch1 = "") || (ch2 = "")) {
				Set pErr = $G(pErr) _ $$$FormatText($$$Text("Missing args for binary operator: %1; "),tToken)
				Set expr = ""
			}
			Else {
				Set tVal1 = ..%EvalExpression(.pErr,pContext,.tree,ch1)
				Set tVal2 = ..%EvalExpression(.pErr,pContext,.tree,ch2)
				Set tOp = tToken

				// for expression involving "" value, convert to 0
				If ((tVal1="")&&$IsValidNum(tVal2)) {
					Set tVal1 = 0
				}
				ElseIf ((tVal2="")&&$IsValidNum(tVal1)) {
					Set tVal2 = 0
				}
				ElseIf ((tVal1="")||(tVal2="")) {
					Set tValue = ""
				}
				ElseIf ($E(tVal1)="@") {
					// propagate errors
					Set tValue = tVal1
				}
				ElseIf ($E(tVal2)="@") {
					// propagate errors
					Set tValue = tVal2
				}
				ElseIf ($IsValidNum(tVal1)&&$IsValidNum(tVal2)) {
					Set tValue = $Case(tOp,
							"+":tVal1+tVal2,
							"*":tVal1*tVal2,
							"/":$S(tVal2'=0:tVal1/tVal2,1:"@DIVIDE"),
							"-":tVal1-tVal2,
							">":tVal1>tVal2,
							"<":tVal1<tVal2,
							">=":tVal1>=tVal2,
							"<=":tVal1<=tVal2,
							"=":tVal1=tVal2,
							"AND":tVal1&&tVal2,
							"OR":tVal1||tVal2,
							:"N/A")
				}
				Else { // strings
					Set tValue = $Case(tOp,
							"+":tVal1_tVal2,
							">":tVal1]]tVal2,
							"<":tVal1']]tVal2,
							">=":(tVal1]]tVal2)||(tVal1=tVal2),
							"<=":(tVal1']]tVal2)||(tVal1=tVal2),
							"=":tVal1=tVal2,
							:"N/A")
				}
			}
		}
		ElseIf (tType = "unary") {
			// unary operator: get arg
			Set ch1 = $O(tree(node,"ch",""))
		
			If (ch1 = "") {
				Set pErr = $G(pErr) _ $$$Text("Missing arg for unary operator; ")
				Set expr = ""
			}
			Else {
				Set tVal1 = ..%EvalExpression(.pErr,pContext,.tree,ch1)
				If ($E(tVal1)="@") {
					// propagate errors
					Set tValue = tVal1
				}
				ElseIf (tVal1="") {
					Set tValue = ""
				}
				ElseIf ($IsValidNum(tVal1)) {
					Set tValue = $Case(tToken,
							"+":+tVal1,
							"-":-tVal2,
							"!":'tVal1,
							:"N/A")
				}
				Else {
					Set tValue = tVal1
				}
			}
		}
		ElseIf (tType = "(") {
			// parens: get arg
			Set ch1 = $O(tree(node,"ch",""))
			Set tValue = ..%EvalExpression(.pErr,pContext,.tree,ch1)
		}
		ElseIf (tType = "func") {
			
			// !!!
			Set x = 1/0
			
			// lookup function from list
			// !!!! If $d(tFunctionSet)=0 Do ##class(Ens.Rule.Utils).GetAllFunctions(.tFunctionSet)
			Set val = $g(tFunctionSet($ZCVT(tToken,"U")))
			If ""'=val {
				Set cls = $LG(val,1)
				Set method = $LG(val,2)

				Set expr = "##class(" _ cls _ ")." _ method _ "("

				// build list of args
				Set n = 1
				Set ch="" For { Set ch=$O(tree(node,"ch",ch))  Quit:""=ch
					Set expr = expr _ $S(n>1:",",1:"") _ ..%GenExpression(.pErr,pContext,.tree,ch)
					Set n = n + 1
				}
				Set expr = expr _ ")"
			} Else {
				Set pErr = $G(pErr) _ $$$FormatText($$$Text("Unknown Function: %1; "),tToken)
				Set expr = ""
			}
		}
		Else {
			Set pErr = $G(pErr) _ $$$FormatText($$$Text("Unknown Node: %1; "),tType)
			Set expr = ""
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Set tValue = "@ERR"
	}
	
	Quit tValue
}

/// Diagnostic method. Create a test worksheet and save it.
ClassMethod %CreateTestWorksheet(pName As %String, Output pWorksheet) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tExists = ##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(pName_".worksheet")
		If (tExists) {
			Do ##class(%DeepSee.UserLibrary.Utils).%DeleteFolderItem(pName_".worksheet")
		}
		Set pWorksheet = ##class(%DeepSee.UserLibrary.Worksheet).%New()
		Set pWorksheet.name = pName

		Set tColCount = 5
		Set tRowCount = 10

		// columns
		For c=1:1:tColCount {
			Set tCol = ##class(%DeepSee.UserLibrary.WorksheetAxis).%New()
			Set tCol.name = "Col "_c
			Do pWorksheet.columnHeaders.Insert(tCol)
		}

		// rows
		For r=1:1:tRowCount {
			Set tRow = ##class(%DeepSee.UserLibrary.WorksheetAxis).%New()
			Set tRow.name = "Row "_r
			Do pWorksheet.rowHeaders.Insert(tRow)
		}

		// cells
		/*
		Set tCell = ##class(%DeepSee.UserLibrary.WorksheetCell).%New()
		Set tCell.page = 1
		Set tCell.row = 2
		Set tCell.column = 2
		Set tCell.style = "font-size:48px;"
		Do pWorksheet.cells.Insert(tCell)
		*/

		// data
		For r=1:1:tRowCount {
			For c=1:1:tColCount {
				Set pWorksheet.%cells(r,c) = r*111
			}
		}

		Do pWorksheet.%Save()
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Given a worksheet name (with no extension), open it and load the data needed to drive a json provider.
/// If <var>pComputed</var> is true return the computed values for each cell,
/// otherwise return the original values, which could include formula.
ClassMethod %LoadWorksheet(pWorksheetName As %String, pComputed As %Boolean = 0, Output pObject As %DeepSee.UserLibrary.Worksheet) As %Status [ Internal ]
{
	Set tSC =  $$$OK
	Try {
		Set pObject = ""
		
		#dim tWorksheet As %DeepSee.UserLibrary.Worksheet
		#dim tItem As %DeepSee.UserLibrary.WorksheetAxis
		#dim tAxis As %DeepSee.UserLibrary.WorksheetAxis

		If (pWorksheetName="") {
			// new worksheet
			Set tWorksheet = ##class(%DeepSee.UserLibrary.Worksheet).%New()
			Set tAxis = ##class(%DeepSee.UserLibrary.WorksheetAxis).%New()
			Set tAxis.name = "1"
			Do tWorksheet.rowHeaders.Insert(tAxis)

			Set tAxis = ##class(%DeepSee.UserLibrary.WorksheetAxis).%New()
			Set tAxis.name = "1"
			Do tWorksheet.columnHeaders.Insert(tAxis)
		}
		Else {
			Set tWorksheet = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pWorksheetName_".worksheet",.tSC)
			If $$$ISERR(tSC) Quit
		}

		If '$IsObject(tWorksheet) {
			Quit
		}

		// recalc
		If (pComputed) {
			Set tSC = tWorksheet.%Calculate()
			If $$$ISERR(tSC) Quit
		}

		// convert to proxy object for transport
		Set pObject = ##class(%ZEN.proxyObject).%New()
		Set pObject.folderName = tWorksheet.folderName
		Set pObject.name = tWorksheet.name
		Set pObject.title = tWorksheet.title
		Set pObject.description = tWorksheet.description
		Set pObject.keywords = tWorksheet.keywords
		Set pObject.owner = tWorksheet.owner
		Set pObject.shared = tWorksheet.shared
		Set pObject.public = tWorksheet.public
		Set pObject.locked = tWorksheet.locked
		Set pObject.resource = tWorksheet.resource
		Set pObject.timeCreated = tWorksheet.timeCreated
		Set pObject.timeModified = tWorksheet.timeModified
		Set pObject.createdBy = tWorksheet.createdBy
		Set pObject.category = tWorksheet.category
		Set pObject.bookCover = tWorksheet.bookCover
		Set pObject.format = tWorksheet.format
		Set pObject.style = tWorksheet.style
		Set pObject.columnHeaderStyle = tWorksheet.columnHeaderStyle
		Set pObject.rowHeaderStyle = tWorksheet.rowHeaderStyle
		Set pObject.borders = tWorksheet.borders
		Set pObject.showZebra = tWorksheet.showZebra
		Set pObject.showRowLabels = tWorksheet.showRowLabels
		Set pObject.showColumnLabels = tWorksheet.showColumnLabels
		Set pObject.columnWidth = tWorksheet.columnWidth

		// row headers
		Set tRowCount = tWorksheet.rowHeaders.Count()
		Set pObject.rowHeaders = ##class(%Library.ListOfObjects).%New()
		For n=1:1:tRowCount {
			Set tItem = tWorksheet.rowHeaders.GetAt(n)
			Set tAxis = ##class(%ZEN.proxyObject).%New()
			Set tAxis.name = tItem.name
			Set tAxis.format = tItem.format
			Set tAxis.style = tItem.style
			Set tAxis.value = tItem.value

			Set tAxis.logicalValue = tItem.logicalValue
			Set tAxis.lookupSpec = tItem.lookupSpec
			Set tAxis.priority = tItem.priority
			Set tAxis.readOnly = tItem.readOnly
			Do pObject.rowHeaders.Insert(tAxis)
		}

		// column headers
		Set tColCount = tWorksheet.columnHeaders.Count()
		Set pObject.columnHeaders = ##class(%Library.ListOfObjects).%New()
		For n=1:1:tColCount {
			Set tItem = tWorksheet.columnHeaders.GetAt(n)
			Set tAxis = ##class(%ZEN.proxyObject).%New()
			Set tAxis.name = tItem.name
			Set tAxis.format = tItem.format
			Set tAxis.style = tItem.style
			Set tAxis.value = tItem.value

			Set tAxis.logicalValue = tItem.logicalValue
			Set tAxis.lookupSpec = tItem.lookupSpec
			Set tAxis.priority = tItem.priority
			Set tAxis.readOnly = tItem.readOnly
			Do pObject.columnHeaders.Insert(tAxis)
		}

		// cell overrides
		Set pObject.cells = ##class(%Library.ListOfObjects).%New()
		Set tCellCount = tWorksheet.cells.Count()
		For n = 1:1:tCellCount {
			#dim tCell As %DeepSee.UserLibrary.WorksheetCell
			#dim tJCell As %DeepSee.UserLibrary.WorksheetCell
			Set tCell = tWorksheet.cells.GetAt(n)

			Set tJCell = ##class(%ZEN.proxyObject).%New()
			Set tJCell.format = tCell.format
			Set tJCell.page = tCell.page
			Set tJCell.row = tCell.row
			Set tJCell.column = tCell.column
			Set tJCell.readOnly = tCell.readOnly
			Set tJCell.style = tCell.style
			Do pObject.cells.Insert(tJCell)
		}

		// cell data
		Set pObject.values = ##class(%Library.ListOfObjects).%New()
		If (pComputed) {
			For r=1:1:tRowCount {
				Set tList = ##class(%Library.ListOfDataTypes).%New()
				Do pObject.values.Insert(tList)
				For c=1:1:tColCount {
					Set tVal = $G(tWorksheet.%values(r,c))
					Do tList.Insert(tVal)
				}
			}
		}
		Else {
			Set pObject.values = ##class(%Library.ListOfObjects).%New()
			For r=1:1:tRowCount {
				Set tList = ##class(%Library.ListOfDataTypes).%New()
				Do pObject.values.Insert(tList)
				Set c = $O(tWorksheet.%cells(r,""))
				For c=1:1:tColCount {
					Set tVal = $G(tWorksheet.%cells(r,c))
					Do tList.Insert(tVal)
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Given a worksheet name and a proxy object, save it as a folder item.
ClassMethod %SaveWorksheet(pWorksheetName As %String, pObject As %ZEN.proxyObject) As %Status [ Internal ]
{
	Set tSC =  $$$OK
	Try {
		// test for overwrite
		If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(pWorksheetName)) {
			// we *could* send this to trash, but let's delete it for now
			Set tSC = ##class(%DeepSee.UserLibrary.Utils).%DeleteFolderItem(pWorksheetName)
			If $$$ISERR(tSC) Quit
		}

		// create and save the worksheet
		Set tWorksheet = ##class(%DeepSee.UserLibrary.Worksheet).%New()
		Set tWorksheet.fullName = pWorksheetName
		Set tWorksheet.title = pObject.title
		Set tWorksheet.description = pObject.description
		Set tWorksheet.keywords = pObject.keywords
		Set tWorksheet.owner = pObject.owner
		Set tWorksheet.shared = pObject.shared
		Set tWorksheet.public = pObject.public
		Set tWorksheet.locked = pObject.locked
		Set tWorksheet.resource = pObject.resource
		Set tWorksheet.timeCreated = pObject.timeCreated
		Set tWorksheet.timeModified = pObject.timeModified
		Set tWorksheet.createdBy = pObject.createdBy
		Set tWorksheet.category = pObject.category
		Set tWorksheet.bookCover = pObject.bookCover
		Set tWorksheet.format = pObject.format
		Set tWorksheet.style = pObject.style
		Set tWorksheet.columnHeaderStyle = pObject.columnHeaderStyle
		Set tWorksheet.rowHeaderStyle = pObject.rowHeaderStyle
		Set tWorksheet.borders = pObject.borders
		Set tWorksheet.showZebra = pObject.showZebra
		Set tWorksheet.showRowLabels = pObject.showRowLabels
		Set tWorksheet.showColumnLabels = pObject.showColumnLabels
		Set tWorksheet.columnWidth = pObject.columnWidth

		Set tRowCount = 1
		If $IsObject(pObject.rowHeaders) {
			Set tRowCount = pObject.rowHeaders.Count()
			For n=1:1:tRowCount {
				Set tItem = pObject.rowHeaders.GetAt(n)
				Set tAxis = ##class(%DeepSee.UserLibrary.WorksheetAxis).%New()
				Set tAxis.name = tItem.name
				Set tAxis.format = tItem.format
				Set tAxis.style = tItem.style
				Set tAxis.value = tItem.value
				Set tAxis.logicalValue = tItem.logicalValue
				Set tAxis.lookupSpec = tItem.lookupSpec
				Set tAxis.priority = tItem.priority
				Set tAxis.readOnly = tItem.readOnly
				Do tWorksheet.rowHeaders.Insert(tAxis)
			}
		}

		Set tColCount = 1
		If $IsObject(pObject.columnHeaders) {
			Set tColCount = pObject.columnHeaders.Count()
			For n=1:1:tColCount {
				Set tItem = pObject.columnHeaders.GetAt(n)
				Set tAxis = ##class(%DeepSee.UserLibrary.WorksheetAxis).%New()
				Set tAxis.name = tItem.name
				Set tAxis.format = tItem.format
				Set tAxis.style = tItem.style
				Set tAxis.value = tItem.value
				Set tAxis.logicalValue = tItem.logicalValue
				Set tAxis.lookupSpec = tItem.lookupSpec
				Set tAxis.priority = tItem.priority
				Set tAxis.readOnly = tItem.readOnly
				Do tWorksheet.columnHeaders.Insert(tAxis)
			}
		}

		// cell overrides
		If $IsObject(pObject.cells) {
			Set tCellCount = pObject.cells.Count()
			For n=1:1:tCellCount {
				Set tItem = pObject.cells.GetAt(n)
				Set tCell = ##class(%DeepSee.UserLibrary.WorksheetCell).%New()
				Set tCell.page = tItem.page
				Set tCell.row = tItem.row
				Set tCell.column = tItem.column
				Set tCell.format = tItem.format
				Set tCell.style = tItem.style
				Set tCell.readOnly = tItem.readOnly
				Do tWorksheet.cells.Insert(tCell)
			}
		}

		// data
		If $IsObject(pObject.values) {
			For r=1:1:tRowCount {
				Set tRowList = pObject.values.GetAt(r)
				If $IsObject(tRowList) {
					For c=1:1:tColCount {
						Set tWorksheet.%cells(r,c) = tRowList.GetAt(c)
					}
				}
			}
		}

		Set tSC = tWorksheet.%Save()
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
