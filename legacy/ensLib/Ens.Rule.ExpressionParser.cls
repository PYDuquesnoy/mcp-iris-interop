/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %occXSLT)

/// Expression Parser for RuleSets.
Class Ens.Rule.ExpressionParser Extends %RegisteredObject [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

/// Evaluate the given expression using the given context object<br>
ClassMethod Evaluate(pExpr As %String, pContextObj As %RegisteredObject = "", Output pErrorMsg As %String) As %String
{
	Set $ZT="Trap"
	Set tValue = ""
	Set pErrorMsg = ""
	
	Set uselog = $D(^Ens.ExpressionLog)
	If (uselog) {
		Set logid = $I(^Ens.ExpressionLog)
		Set ^Ens.ExpressionLog(logid,1) = pExpr
	}

	Do {
		Set tMsg = ..Parse(pExpr, .pTree)
		If (tMsg '= "") {
			Set pErrorMsg = tMsg
			Quit
		}

		Set x = ..GenExpression(.tErr,"%contextObj",.pTree)
		Set:uselog ^Ens.ExpressionLog(logid,2) = x

		If (tErr '= "") {
			Set pErrorMsg = tErr
			Quit
		}
		If (x = "") {
			Quit
		}
		
		// set up execute environment		
		New %val,%contextObj
		Set %contextObj = pContextObj
		X "Set %val=" _ x
		
		If ($IsObject(%val)) {
			Set tValue = "object"
			Quit
		}
		Set tValue = %val

	} While (0)

Done
	Set:uselog ^Ens.ExpressionLog(logid,3) = tValue
	Quit tValue

Trap
	Set $ZT=""
	Set tValue = ""
	Set pErrorMsg = $P($ZE,">",1) _ ">"
	Set pErrorMsg = $TR(pErrorMsg,"<>","[]") // !!!p
	Goto Done
}

/// Returns executable code (a single expression) for the given expression.
ClassMethod GenerateCode(pExpr As %String, Output pCode As %String, Output pErrorMsg As %String) As %Status
{
	Set $ZT="Trap"
	Set tSC = $$$OK
	Set pCode = ""
	Set pErrorMsg = ""

	Do {
		// parse
		Set tMsg = ..Parse(pExpr, .pTree)
		If (tMsg '= "") {
			Set pErrorMsg = tMsg
			Quit
		}

		Set pCode = ..GenExpression(.tErr,"pContext",.pTree)
		If (tErr '= "") {
			Set pCode = ""
			Set pErrorMsg = tErr
			Quit
		}

	} While (0)
Done
	Quit tSC

Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$ObjectScriptError,$ZE)
	Set pCode = ""
	Set pErrorMsg = $P($ZE,">",1) _ ">"
	Set pErrorMsg = $TR(pErrorMsg,"<>","[]")
	Goto Done
}

/// Validate the given expression.
/// If <var>pContextClass</var> is provided, make sure properties exist in it.
ClassMethod Validate(pExpr As %String, Output pMsg As %String, pContextClass As %String = "", pDocumentClass As %String = "") As %Boolean
{
	New %propList

	Set pMsg = ..Parse(pExpr, .tTree, .tProps, .tFuncs)  Quit:""'=pMsg 0
	
	If ((pContextClass '= "") && $D(tProps)) {
		Do ##class(Ens.Rule.Utils).GetPropertyTree(.%propList,pContextClass,pDocumentClass)
		Set k = "" For { Set k = $O(tProps(k))  Quit:""=k
			// check for dot syntax
			Set ref = ""
			For p=1:1:$L(k,".") {
				Set ref = ref _ $S(ref="":"",1:",") _ """" _ $P(k,".",p) _ """"
			}
			Set ref = "%propList("_ref_")"
			
			If ('$D(@ref)) {
				Set pMsg = pMsg _ $$$FormatText($$$Text("Property '%1' does not exist. "),k)
			}
		}
	}
	If $D(tFuncs) {
		// validate functions used by expression
		Set tSC = ##class(Ens.Rule.Utils).GetFunctionSet(.funcset)  Quit:$$$ISERR(tSC) 0
		Set k = "" For { Set k = $O(tFuncs(k))  Quit:k=""
			Set func = $ZCVT(k,"U")
			If '$D(funcset(func)) {
				Set pMsg = pMsg _ $$$FormatText($$$Text("Function '%1' does not exist or is not compiled."),k)
			}
		}
	}
	Quit (""=pMsg)
}

/// Returns the type of an expression (used by the value editor).
ClassMethod GetOpType(pExpr As %String, Output pToken As %String) As %String
{
	Set tType = ""
	Set pToken = pExpr

	Set pMsg = ..Parse(pExpr, .pTree)  Quit:""'=pMsg "string"  ; error
	
	// get type of token
	Set tType = $G(pTree(1,"type"))
	If (tType = "ident") {
		Set tType = "property"
	}
	ElseIf (tType = "string") {
		Set tType = "string"
		Set pToken = $Replace($E(pExpr,2,$L(pExpr)-1),"""""","""")
	}
	ElseIf (tType = "number") {
		Set tType = "number"
	}
	ElseIf (tType = "func") {
		Quit "function"
	}
	ElseIf (tType = "mxident") {
		Set tType = "vprop"
	}
	Else {
		Set tType = "expression"  ; not expected
	}
	Quit:(pTree > 1) "expression"  ; must be an expression
	Quit tType
}

ClassMethod Test(expr As %String, ByRef tree)
{
	Kill tree
	Set msg = ..Parse(expr, .tree, .props,.funcs)
	If (msg '= "") {
		Write msg,!
		Quit
	}

	Write !,"-------------------------------",!
	Do ..PrintParseNode(.tree,0)

	Write !,"-------------------------------",!
	Set expr = ..GenExpression(.tErr,"context",.tree)
	
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

ClassMethod TestTokenize(expr As %String, pQuotedIdent As %Boolean = 0)
{
	Set msg = ..Tokenize(expr, .tokens, pQuotedIdent)

	If (msg '= "") {
		Write msg,!
		Quit
	}
	
	Write !,"-------------------------",!

	Set t = $O(tokens(""))
	While (t '= "") {
		Write t,?5,$G(tokens(t,"type")),?15,"'",$G(tokens(t,"token")),"'"," (",$G(tokens(t,"pos")),")",!
		Set t = $O(tokens(t))
	}
}

ClassMethod PrintParseNode(ByRef tree, node As %Integer, level As %Integer = 0)
{
	If ($G(tree(node,"type")) = "string") {
		Set q = """"
	} Else {
		Set q = ""
	}
	Set ind=(level*3)
	Write ?ind,node,?(ind+3),$G(tree(node,"type")),":",?(ind+12),q,$G(tree(node,"token")),q,!
	
	Set ch="" For { Set ch=$O(tree(node,"ch",ch))  Quit:""=ch
		Do ..PrintParseNode(.tree,ch,level+1)
	}
}

/// Parse the expr into a parse tree <var>tree</var><br>
/// Returns "" if ok or else an error message.<br>
/// <var>pPropList</var> returns an array of properties referenced
/// by the expression.
/// <var>pFuncList</var> returns an array of functions referenced
/// by the expression.
ClassMethod Parse(expr As %String, Output tree As %String, Output pPropList As %String, Output pFuncList As %String) As %String
{
	Kill tree
	Kill pPropList
	Kill pFuncList

	// first tokenize
	Set err = ..Tokenize(expr,.tokens,1)
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
		ElseIf (type = "qident") {
			Set pPropList("{" _ tokens(tokno,"token") _ "}") = ""
		}
		ElseIf (type = "qident2") {
			Set pPropList("(" _ tokens(tokno,"token") _ ")") = ""
		}
		ElseIf (type = "qident3") {
			Set pPropList("[" _ tokens(tokno,"token") _ "]") = ""
		}
		ElseIf (type = "qident4") {
			Set pPropList("<" _ tokens(tokno,"token") _ ">") = ""
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

/// Split the formula <var>expr</var> into a token list:<BR>
/// tokens(n,"token") = token<BR>
/// tokens(n,"pos") = position in expr<BR>
/// tokens(n,"type") = string | number | ident | func |op |unary | ( | ) | , | end
/// Returns "" if the formula is correct else an error message.
/// If pQuotedIdent, then support {ident},[ident],<ident> as ident
ClassMethod Tokenize(expr As %String, ByRef tokens As %String, pQuotedIdent As %Boolean = 0) As %String
{
	// clear out token list
	Kill tokens

	// append an endmarker to simplify 
	// end of expr processing
	Set expr = expr _ $C(0)
	
	Set tokens = 0			// number of tokens in list
	Set err = ""			// error msg ("" for ok)
	Set state = 0			// current state of state machine
	Set token = ""			// current token
	Set n = 0				// current character pos in input
	Set ch = ""				// current character from input
	Set startpos = 1		// startpos of current token
	Set firsttok = 1		// keep track of first tok (or first in parens) to detect unary ops
	Set identType = ""		// "ident","qident","qident3","qident4","mxident","mxident2","mxident3","mxident4" : a,{a},[a],<a>,a.{b},a.(b),a.[b],a.<b>
	Set mxlevel = 0			// nesting level for mxident and qident tokens

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
			ElseIf (pQuotedIdent && $Case(ch, "{":1, :0)) {
				// start of literal ident
				Set state = 4
				Set identType = "qident"_$Case(ch,"{":"", "(":"2", "[":"3", :"4")
				Set token = ""
				Set startpos = n
				Set firsttok = 0
				Set mxlevel = 1
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
				Set tokens = $$AddToken(tokens,ch,ch,n)
				Set firsttok = 0
				Set:(ch'=")") firsttok = 1
			}
			ElseIf (..IsIdentChar(ch)) {
				// start of ident
				Set state = 4
				Set identType = "ident"
				Set token = ch
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
					Set tokens = $$AddToken(tokens,token,"string",startpos)
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
				Set tokens = $$AddToken(tokens,token,"number",startpos)
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
				Set tokens = $$AddToken(tokens,token,"number",startpos)

				// start of op
				Set state = 6
				Set token = ch
				Set startpos = n
			}
			ElseIf (..IsSpecialChar(ch)) {
				// add number to list
				Set tokens = $$AddToken(tokens,token,"number",startpos)

				// special token: add to list
				Set tokens = $$AddToken(tokens,ch,ch,n)

				Set token = ""
				Set state = 0
				Set firsttok = 0
				Set:(ch'=")") firsttok = 1
			}
			ElseIf (..IsWhiteSpace(ch)) {
				// add number to list
				Set tokens = $$AddToken(tokens,token,"number",startpos)

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
				Set tokens = $$AddToken(tokens,token,"number",startpos)
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
				Set tokens = $$AddToken(tokens,token,"number",startpos)

				// start of op
				Set state = 6
				Set token = ch
				Set startpos = n
			}
			ElseIf (..IsSpecialChar(ch)) {
				// add number to list
				Set:$E(token,$L(token))="." token = token_"0"
				Set tokens = $$AddToken(tokens,token,"number",startpos)

				// special token: add to list
				Set tokens = $$AddToken(tokens,ch,ch,n)

				Set token = ""
				Set state = 0
				Set firsttok = 0
				Set:(ch'=")") firsttok = 1
			}
			Else {
				Set:$E(token,$L(token))="." token = token_"0"
				Set tokens = $$AddToken(tokens,token,"number",startpos)

				Set token = ""
				Set state = 0
			}
		}
		ElseIf (state = 4) {
			// ident
			
			// get end character of token
			Set endch = $E(token,*)
			
			If $Case(identType,"qident":1, "qident2":1, "qident3":1, "qident4":1, "mxident":1, "mxident2":1, "mxident3":1, "mxident4":1, :0) {
				Set idnum=$P(identType,"ident",2)
				If ch = $C(0) || $Case(idnum, "":ch="}", "2":ch=")", "3":ch="]", "4":ch=">", :0) {
					If (ch = $C(0)) {
						Set err = "ERROR(T47): missing closing "_$Case(idnum, "2":")", "3":"]", "4":">", :"}") _" for identifier ("_n_") "_token
					} ElseIf mxlevel>1 {
						Set mxlevel=mxlevel-1
						Set token = token _ ch
					} Else {
						If (identType [ "mxident") {
							Set token = token _ ch  // close off ident
						}
						// add ident to list
						Set tokens = $$AddToken(tokens,token,identType,startpos)
	
						Set token = ""
						Set state = 0
						Set identType = ""
						Set mxlevel = 0
					}
				}
				Else {
					Set token = token _ ch
					If $Case(idnum, "":ch="{", "2":ch="(", "3":ch="[", "4":ch="<", :0) {
						Set mxlevel=mxlevel+1
					}
				}
			}
			ElseIf (ch = $C(0)) {
				// end
				// add ident to list
				If (endch = ".") {
					Set err = $$$FormatText($$$Text("ERROR(T41): unexpected . at position (%1) %2"),n,token)
				}
				Else {
					Set tokens = $$AddToken(tokens,token,identType,startpos)
				}
			}
			ElseIf (endch = ".") {
				If $Case(ch, "{":1, "(":1, "[":1, "<":1, :0) {
					// start of "mixed ident"
					Set identType = "mxident"_$Case(ch,"{":"", "(":"2", "[":"3", :"4")
					Set mxlevel = 1
				}
				ElseIf (ch = ".") {
					Set err = $$$FormatText($$$Text("ERROR(T42): unexpected . at position (%1) %2"),n,token)
				}
				Set token = token _ ch
			}
			ElseIf (..IsOperatorChar(ch)) {
				// add ident to list
				If (endch = ".") {
					Set err = $$$FormatText($$$Text("ERROR(T42): unexpected . at position (%1) %2"),n,token)
				}
				Else {
					Set tokens = $$AddToken(tokens,token,identType,startpos)

					// start of op
					Set state = 6
					Set token = ch
					Set startpos = n
				}
			}
			ElseIf (..IsSpecialChar(ch)) {
				// add ident to list
				If (endch = ".") {
					Set err = $$$FormatText($$$Text("ERROR(T43): unexpected . at position (%1) %2"),n,token)
				}
				Else {
					Set tokens = $$AddToken(tokens,token,identType,startpos)

					// special token: add to list
					Set tokens = $$AddToken(tokens,ch,ch,n)

					Set token = ""
					Set state = 0
					Set firsttok = 0
					Set:(ch'=")") firsttok = 1
				}
			}
			ElseIf (..IsWhiteSpace(ch)) {
				// whitespace: end of ident 

				// add ident to list
				If (endch = ".") {
					Set err = $$$FormatText($$$Text("ERROR(T44): unexpected . at position (%1) %2"),n,token)
				}
				Else {
					Set tokens = $$AddToken(tokens,token,identType,startpos)

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
					Set tokens = $$AddToken(tokens,token,"op",startpos)

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
					Set tokens = $$AddToken(tokens,token,"op",startpos)

					// special token: add to list
					Set tokens = $$AddToken(tokens,ch,ch,n)

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
					Set tokens = $$AddToken(tokens,token,"op",startpos)

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
					ElseIf (pQuotedIdent && $Case(ch, "{":1, "(":1, "[":1, "<":1, :0)) {
						// start of literal ident
						Set state = 4
						Set identType = "qident"_$Case(ch,"{":"", "(":"2", "[":"3", :"4")
						Set token = ""
						Set startpos = n
					}
					ElseIf (..IsIdentChar(ch)) {
						// start of ident
						Set token = ch
						Set state = 4
						Set identType = "ident"
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
					Set tokens = $$AddToken(tokens,token,"unary",startpos)

					// special token: add to list
					Set tokens = $$AddToken(tokens,ch,ch,n)

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
					Set tokens = $$AddToken(tokens,token,"unary",startpos)

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
					ElseIf (pQuotedIdent && $Case(ch, "{":1, :0)) {
						// start of literal ident
						Set state = 4
						Set identType = "qident"_$Case(ch,"{":"", "(":"2", "[":"3", :"4")
						Set token = ""
						Set startpos = n
						Set mxlevel = 1
					}
					ElseIf (..IsIdentChar(ch)) {
						// start of ident
						Set token = ch
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
		} // end of states
	} // end of next character loop
	
	// add end token
	If (err = "") {
		Set tokens = $$AddToken(tokens,"","end",n)
	}

	If (err = "") {
		// loop over tokens and find any functions: ident + "(" 
		// also build list of properties and functions used
		Set last = ""
		Set t = $O(tokens(""))
		While (t '= "") {

			If ($G(tokens(t,"type")) = "(" ) {
				If ((last '= "") && ($G(tokens(last,"type")) = "ident")) {
					// replace two tokens with one
					Kill tokens(t)
					Set tokens(last,"type") = "func"
				}
			}
	
			Set last = t
			Set t = $O(tokens(t))
		}
	}
	
	Quit err

AddToken(no,tok,tp,ps)
	// insert new token into token list
	#;WRITE:$G(%debug) ?5,no,": ",tp,?20,tok,!
	Set no=no+1, tokens(no,"token")=tok,tokens(no,"type")=tp, tokens(no,"pos")=ps
	Quit no
}

/// Returns true if <var>op1</var> has precedence over <var>op2</var>.
ClassMethod TestPrecedence(op1 As %String, op2 As %String) As %Boolean
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

/// Test if token is a unary operator
ClassMethod IsUnaryOperator(token As %String) As %Boolean [ CodeMode = expression ]
{
",+,-,!," [ (","_token_",")
}

/// Test if token is a binary operator
ClassMethod IsBinaryOperator(token As %String) As %Boolean [ CodeMode = expression ]
{
",+,-,*,/,!=,=,>=,<=,>,<,&,&&,||,[,_," [ (","_token_",")
}

/// Test if char is a part of an unary operator name
ClassMethod IsUnaryOperatorChar(char As %String) As %Boolean [ CodeMode = expression ]
{
",+,-,!," [ (","_char_",")
}

/// Test if char is a part of an operator name
ClassMethod IsOperatorChar(char As %String) As %Boolean [ CodeMode = expression ]
{
",+,-,*,/,<,>,=,&,|,!,[,_," [ (","_char_",")
}

/// Test if char is a special character "(" ")" or ","
ClassMethod IsSpecialChar(char As %String) As %Boolean [ CodeMode = expression ]
{
((char = ",") || (char = "(") || (char = ")"))
}

/// Test if char can be part of an identifier
ClassMethod IsIdentChar(char As %String) As %Boolean [ CodeMode = expression ]
{
$S(char=".":1,char="%":1,1:$zname("a" _ char))
}

/// Test if char is a whitespace character
ClassMethod IsWhiteSpace(char As %String) As %Boolean [ CodeMode = expression ]
{
(char = " ")
}

/// Generate list of functions used by the parse tree
ClassMethod GetListOfMethods(ByRef tree As %String, ByRef list As %String)
{
	Set node = $O(tree(""))
	While (node '= "") {
		If (tree(node,"type") = "func") {
			Set list(tree(node,"token")) = ""
		}
		Set node = $O(tree(node))
	}
}

/// Get a list of the arguments for element <var>el</var> in a parse tree
ClassMethod GetArguments(ByRef tree As %String, el As %Integer, ByRef args As %String)
{
	Set i = 0
	Set ch = $O(tree(el,"ch",""))
	While (ch '= "") {
		Set i = i + 1
		If (tree(ch,"type") = "func") {
			// get sub args
			Set args(i) = tree(ch,"token") _ "("
			
			Kill subargs
			Do ..GetArguments(.tree, ch, .subargs)
			Set j = $O(subargs(""))
			Set first = 1
			While (j '= "") {
				Set args(i) = args(i) _ $S(first:"",1:",") _ subargs(j)
				Set first = 0
				Set j = $O(subargs(j))
			}
			Set args(i) = args(i) _ ")"
		}
		ElseIf (tree(ch,"type") = "op") {
			// get sub arg1 and arg2
			Kill subargs
			Do ..GetArguments(.tree, ch, .subargs)

			Set args(i) = $G(subargs(1)) _ tree(ch,"token") _ $G(subargs(2))
		}
		ElseIf (tree(ch,"type") = "string") {
			// put back quotes
			Set args(i) = """" _ tree(ch,"token") _ """"
		}
		Else {
			Set args(i) = tree(ch,"token")
		}
		Set ch = $O(tree(el,"ch",ch))
	}

	// !!!unary,( etc.
}

/// Generate an executable ObjectScript expression for part of the parse tree<BR>
/// <var>context</var> is the name of the object variable containing runtime context.<br>
/// Returns "" for error (assumes that parse tree has already been checked)
ClassMethod GenExpression(ByRef pErr As %String, pContext As %String, ByRef tree As %String, node As %String = "") As %String
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
			Quit ..GenExpression(.pErr,pContext,.tree,$O(tree(node,"ch","")))
		}
	}
	ElseIf (tType = "ident") {
		Set expr = $S(pContext="":"",1:pContext_".") _ tToken
	}
	ElseIf (tType = "qident") {
		Set expr = $S(pContext="":"",1:pContext_".") _ "GetValueAt(""" _ tToken _ """)"
	}
	ElseIf (tType = "qident2") {
		Set expr = """<""_"_$S(pContext="":"",1:pContext_".") _ "GetValues(""" _ tToken _ """,,""><"")_"">"""
	}
	ElseIf (tType = "qident3") {
		Set expr = """<""_"_$S(pContext="":"",1:pContext_".") _ "FindSegmentValues(""" _ tToken _ """,,""><"")_"">"""
	}
	ElseIf (tType = "qident4") {
		Set expr = """<""_##class(Ens.Rule.ExpressionParser).GetXPathValues(" _ $S(pContext="":"""""",1:pContext) _ ",""" _ tToken _ """,""><"")_"">"""
	}
	ElseIf (tType = "mxident") {
		// process mixed ident
		Set t1 = $P(tToken,".{",1) // oref
		Set t2 = $P(tToken,".{",2) // quoted id
		Set t2 = $E(t2,1,*-1) // take off "}"
		Set expr = $S(pContext="":"",1:pContext_".") _ t1 _ ".GetValueAt(""" _ t2 _ """)"
	}
	ElseIf (tType = "mxident2") {
		Set t1 = $P(tToken,".(",1) // oref
		Set t2 = $P(tToken,".(",2) // quoted id
		Set t2 = $E(t2,1,*-1) // take off ")"
		Set expr = """<""_"_$S(pContext="":"",1:pContext_".") _ t1 _ ".GetValues(""" _ t2 _ """,,""><"")_"">"""
	}
	ElseIf (tType = "mxident3") {
		Set t1 = $P(tToken,".[",1) // oref
		Set t2 = $P(tToken,".[",2) // quoted id
		Set t2 = $E(t2,1,*-1) // take off "]"
		Set expr = """<""_"_$S(pContext="":"",1:pContext_".") _ t1 _ ".FindSegmentValues(""" _ t2 _ """,,""><"")_"">"""
	}
	ElseIf (tType = "mxident4") {
		Set t1 = $P(tToken,".<",1) // oref
		Set t2 = $P(tToken,".<",2) // quoted id
		Set t2 = $E(t2,1,*-1) // take off ">"
		Set expr = """<""_##class(Ens.Rule.ExpressionParser).GetXPathValues(" _ $S(pContext="":"",1:pContext_".") _ t1 _ ",""" _ t2 _ """,""><"")_"">"""
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
			// translate ops to ObjectScript
			Set tok = tToken
			If (tok = "!=") {
				Set op = "'="
			}
			ElseIf (tok = "&") {
				Set op = "_"
			}
			Else {
				Set op = tok
			}
			Set expr = "(" _ ..GenExpression(.pErr,pContext,.tree,ch1) _
						op _ ..GenExpression(.pErr,pContext,.tree,ch2) _ ")"
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
			// translate op to ObjectScript
			Set tok = tToken
			If (tok = "!") {
				Set tok = "'"
			}
			Set expr = "(" _ tok _ ..GenExpression(.pErr,pContext,.tree,ch1) _ ")"
		}
	}
	ElseIf (tType = "(") {
		// parens: get arg
		Set ch1 = $O(tree(node,"ch",""))
		
		Set expr = "(" _ ..GenExpression(.pErr,pContext,.tree,ch1) _ ")"
	}
	ElseIf (tType = "func") {
		// lookup function from list
		If $d(tFunctionSet)=0 Do ##class(Ens.Rule.Utils).GetAllFunctions(.tFunctionSet)
		Set val = $g(tFunctionSet($ZCVT(tToken,"U")))
		If ""'=val {
			Set cls = $LG(val,1)
			Set method = $LG(val,2)

			Set expr = "##class(" _ cls _ ")." _ method _ "("

			// build list of args
			Set n = 1
			Set ch="" For { Set ch=$O(tree(node,"ch",ch))  Quit:""=ch
				Set expr = expr _ $S(n>1:",",1:"") _ ..GenExpression(.pErr,pContext,.tree,ch)
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

/// Generate a statement that sets a given property to a given value
ClassMethod GenSetCode(Output pCode As %String, pProperty As %String, pValue As %String) As %Status
{
	Set tSC = $$$OK
	Set pCode = ""
	
	Do {
		If (pProperty'["{") {
			Set pCode = "Set " _ pProperty _ " = " _ pValue
		}
		Else {
			// find start of virtual property
			Set p1 = $P(pProperty,"{",1)
			Set p2 = $P(pProperty,"{",2,$L(pProperty,"{"))
			Set p2 = $E(p2,1,$L(p2)-1) // strip off }
			Set pCode = "Do " _ p1 _ "SetValueAt(" _ pValue _ ",""" _ p2 _""")"
		}
	} While(0)
	
	Quit tSC
}

ClassMethod GetXPathValues(pStream, pExpression, pValSepString As %String = "<>", Output pStatus As %Status) As %String
{
	
	Set tDocument=$G($$$EnsJobLocal("CurrentXPATHDoc")), pStatus=$$$OK
	If '$IsObject(tDocument) {
		If '$IsObject(pStream) {
			Set pStatus=##class(%XML.XPATH.Document).CreateFromStream(##class(%IO.StringStream).%New(pStream),.tDocument)
		} ElseIf pStream.%Extends("%Stream.Object") || pStream.%Extends("%IO.I.Stream") {
			Set pStatus=##class(%XML.XPATH.Document).CreateFromStream(pStream,.tDocument)
		} ElseIf pStream.%Extends("Ens.StringContainer") || pStream.%Extends("Ens.StringRequest") || pStream.%Extends("Ens.StringResponse") {
			Set pStatus=##class(%XML.XPATH.Document).CreateFromStream(##class(%IO.StringStream).%New(pStream.StringValue),.tDocument)
		} ElseIf pStream.%Extends("Ens.StreamContainer") {
			Set pStatus=##class(%XML.XPATH.Document).CreateFromStream(pStream.Stream,.tDocument)
		} Else {
			Set pStatus=##class(%XML.XPATH.Document).CreateFromStream(pStream,.tDocument)
		}
		Quit:$$$ISERR(pStatus) ""  If '$IsObject(tDocument) Set pStatus=$$$ERROR($$$EnsErrGeneral,"Failed to create %XML.XPATHDocument for "_pStream)  Quit ""
		Set $$$EnsJobLocal("CurrentXPATHDoc")=tDocument
		Set:pStream.%IsA("%Persistent") $$$EnsJobLocal("CurrentXPATHDoc","oid")=pStream.%Oid
	}
	// We have the document, evaluate the expression and obtain the reader
	If pExpression["|" { Set tContext=$P(pExpression,"|"), pExpression=$P(pExpression,"|",2,9999) }
	Else { Set tContext="/" }
	Set pStatus=tDocument.EvaluateExpression(tContext,pExpression,.tResults)
	
	Set tResultStr=""
	Set n=tResults.Count()
	For i=1:1:n {		
		Set tResult = tResults.GetAt(i)
		If $IsObject(tResult) Set tVal=$S(tResult.Type=$$$XPATHDOM:"--XPATHDOM--",1:tResult.Value)  Set:""'=tVal tResultStr=tResultStr_tVal_pValSepString
	}
	Quit $E(tResultStr,1,*-$L(pValSepString))
}

}
