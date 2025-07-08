/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.ReportUtil

Class %ZEN.Report.Display.COSChart.dsFormulaParser Extends %RegisteredObject [ Deprecated ]
{

Property parseTree As parseTreeNode;

Property engine As dsFormulaEngine;

Property funcSet As list Of function;

Property errorHTML As %String;

Property lookupTable As %String [ MultiDimensional ];

Property dsFormulaLastError As %String;

Method %OnNew() As %Status
{
	Set true=1
	Set false=0
	Set ..lookupTable("UnaryOp","+") = true
	Set ..lookupTable("UnaryOp","-") = true

	Set ..lookupTable("BinaryOp","+") = true
	Set ..lookupTable("BinaryOp","-") = true
	Set ..lookupTable("BinaryOp","*") = true
	Set ..lookupTable("BinaryOp","/") = true
	Set ..lookupTable("BinaryOp","=") = true
	Set ..lookupTable("BinaryOp",">=") = true
	Set ..lookupTable("BinaryOp","<=") = true
	Set ..lookupTable("BinaryOp",">") = true
	Set ..lookupTable("BinaryOp","<") = true
	Set ..lookupTable("BinaryOp","<>") = true

	Set ..lookupTable("UnaryOpChar","+") = true
	Set ..lookupTable("UnaryOpChar","-") = true

	Set ..lookupTable("BinaryOpChar","+") = true
	Set ..lookupTable("BinaryOpChar","-") = true
	Set ..lookupTable("BinaryOpChar","*") = true
	Set ..lookupTable("BinaryOpChar","/") = true
	Set ..lookupTable("BinaryOpChar","<") = true
	Set ..lookupTable("BinaryOpChar",">") = true
	Set ..lookupTable("BinaryOpChar","=") = true

	Set ..lookupTable("SpecialChar",",") = true
	Set ..lookupTable("SpecialChar","(") = true
	Set ..lookupTable("SpecialChar",")") = true

	Set ..lookupTable("WhiteChar"," ") = true
	Set ..lookupTable("WhiteChar","\t") = true
	Set ..lookupTable("WhiteChar","\n") = true

	// delimited identifier
	Set ..lookupTable("IdentStart") = "["
	Set ..lookupTable("IdentEnd") = "]"
	Quit $$$OK
}

/// Connect a function set to the parser.
Method setFunctionSet(funcSet)
{
	Set this=##this
	for i=1:1:funcSet.Size {
		do ..funcSet.Insert(funcSet.GetAt(i))
	}
}

/// Evaluate a DeepSee formula.
/// lookupFunc is a function used to lookup ident values.
Method eval(lookupFunc)
{
	Set this=##this
	quit this.evalNode(this.parseTree,lookupFunc)
}

/// Get the parse tree.
Method getTree()
{
	Set this=##this
	quit this.parseTree
}

/// Set the parse tree directly.
Method setTree(tree)
{
	Set this=##this
	Set this.parseTree = tree
}

/// Evaluate a node within a parse tree
Method evalNode(node, lookupFunc)
{
	// Note: called recursively
	
	Set this=##this
	if (""=node) quit ""
	Set ret = ""

	/*
	if (node.children="") {
		node.children = [];
	}
	*/

	if node.type = "op" {
	//case "op":
		Set arg1 = this.evalNode(node.children.GetAt(0+1),lookupFunc)
		Set arg2 = this.evalNode(node.children(1+1),lookupFunc)
		if ((arg1="") || (arg2="")) quit ""
		if ('$$$ISNAN($$$PARSEFLOAT(arg1))) {
			Set arg1 = $$$PARSEFLOAT(arg1)
		}
		if ('$$$ISNAN($$$PARSEFLOAT(arg2))) {
			Set arg2 = $$$PARSEFLOAT(arg2)
		}

		// coerce "" into 0 for numeric expressions
		if ((arg1="") && '$$$ISNAN($$$PARSEFLOAT(arg2))) {
			Set arg1 = 0
		}
		if ((arg2="") && '$$$ISNAN($$$PARSEFLOAT(arg1))) {
			Set arg2 = 0
		}

		if node.value="+" {
			//case "+":
			Set ret = arg1 + arg2
		}
		elseif node.value="-" {
			Set ret = arg1 - arg2
		}
		elseif node.value="/" {
			Set ret = $s((arg2'=0) : arg1 / arg2, 1 : "@divide")
		}
		elseif node.value="*" {
			Set ret = arg1 * arg2
		}
		elseif node.value="=" {
			Set ret = (arg1 = arg2)
		}
		elseif node.value=">" {
			Set ret = arg1 > arg2
		}
		elseif node.value = ">=" {
			Set ret = arg1 >= arg2
		}
		elseif node.value="<" {
			Set ret = arg1 < arg2
		}
		elseif node.value="<=" {
			Set ret = arg1 <= arg2
		}
		elseif node.value="<>" {
			Set ret = arg1 '= arg2
		}
	}
	elseif node.type="number" {
			Set ret = $$$PARSEFLOAT(node.value)
	}
	elseif node.type="string" {
			Set ret = node.value
	}
	elseif node.type="ident" {
			if (this.engine'="") {
				/*
				var refersTo = {};
				ret = this.engine.resolveIdent(node.value,refersTo);
				this.referRow = refersTo.row;
				this.referCol = refersTo.col;
				*/
			}
			elseif (lookupFunc.%Extends("%ZEN.Report.Display.COSChart.function")) {
				//Set ret = lookupFunc(node.value);
				Set ret = $zobjmethod(lookupFunc.instance, lookupFunc.methodname, node.value)
			}
	}
	elseif node.type="func" {
		// var args = new Array();
		for n = 0:1:node.children.Count()-1 {
			Set args(n) = this.evalNode(node.children.GetAt(n+1),lookupFunc)
			if (args(n)="") {
				// func arg not resolved
				quit ; quit when we test args(n) after for loop
			}
		}
		if '$D(args) || (args(n)="") quit ""
		if $$$TOLOWERCASE(node.value)="if" {
			Set ret = $s(args(0) : ..get(args(1)), 1 : ..get(args(2)))
		}
		elseif $$$TOLOWERCASE(node.value)="not" {
			Set ret = 'args(0)
		}
		elseif $$$TOLOWERCASE(node.value)="round" {
			Set val = $$$PARSEFLOAT(args(0))
			Set ret = $s($$$ISNAN(val) : args(0), 1 : $$$ROUND(val))
		}
		elseif $$$TOLOWERCASE(node.value)="concat" {
			Set ret = ""
			for n = 0:1:node.children.Count()-1 {
				if ((args(n)'="") && (args(n)'="")) {
					Set ret = ret + args(n)
				}
			}
		}
		elseif $$$TOLOWERCASE(node.value)="and" {
			Set ret = 1 // true
			for n = 0:1:node.children.Count()-1 {
				if ((args(n)="") || ('args(n))) {
					Set ret = 0 ; false
					quit
				}
			}
		}
		elseif $$$TOLOWERCASE(node.value)="and" {
			Set ret = 0 // false
			for n = 0:1:node.children.Count()-1 {
				if ((args(n)'="") && args(n)) {
					Set ret = 1 // true
					quit
				}
			}
		}
		elseif $$$TOLOWERCASE(node.value)= "rowno" {
			if (this.engine'="") {
				Set ret = $$$PARSEINT(this.engine.currRow) + 1
			}
		}
		elseif $$$TOLOWERCASE(node.value)="colno" {
			if (this.engine'="") {
				Set ret = $$$PARSEINT(this.engine.currCol) + 1
			}
		}
		elseif $$$TOLOWERCASE(node.value)="sum" {
			for n = 0:1:##class(scoreCard).length(.args)-1 {
				if (args(n)'="") {
					Set ret = $s(ret="":0, 1:$$$PARSEFLOAT(ret)) + $$$PARSEFLOAT(args(n))
				}
			}
		} else { // default, not a recognized function, look in function set

	
			// see if function is in funcSet
			Set func = $$$TOLOWERCASE(node.value)
			Set function=..findFunctionInFunctionSet(func)
			if ((func'="") && (function'="")) {
				// assemble args
				// do not evaluate idents at this point (unless they are nested)
				//var argList = ();
				for n = 0:1:node.children.Count()-1 {
					if ("ident" = node.children.GetAt(n+1).type) {
						Set argList($i(argList)-1) = node.children.GetAt(n+1).value					}
					else {
						Set argList($i(argList)-1) = args(n)
					}
				}
				Set ret = $zobjmethod(function.instance,function.methodname,.argList)
			}
			else {
				Set ret = "@function: " _ node.value
			}
		}
	}
	quit ret
}

/// Parse a DeepSee formula.
Method parse(expr)
{
	Set this=##this
	Set this.parseTree = ""
	Set this.errorHTML = ""
	Set ..dsFormulaLastError = ""
	Set tokens = this.tokenize(expr)

	//alert(tokens.join('\n'));
	//for (var n = 0; n < tokens.length; n++) {
	//	console.log(n + tokens[n].value);
	//}

	if ("" '= this.errorHTML) {
		quit 0
	}
	if (tokens'="") {
		Set this.parseTree = this.reduceTokens(tokens,expr)
		// !!! alert('tree\n' + this.toString());
#if 0 ; debug		
		if (this.parseTree'="") {
			do this.parseTree.dumpTree()
		}
#endif		
	}
	quit $s(this.parseTree'="" : 1, 1 : 0)
}

/// tokenize a DeepSee formula; return a list of tokens.
/// each token is of the form: {type:ident|func|,|(|)|unary|op|string|number , value:value}
/// In ObjectScript the tokenList is a list of parseTreeNodes.
Method tokenize(expr)
{
	// 10 states, 0 through 9
	Set this=##this
	Set tokenList = ##class(%ArrayOfObjects).%New()

	// parse the expression
	Set state = 0
	Set token = ""
	Set hasError = 0
	Set firstTok = 1

	Set this.errorHTML = ..isExpressionBalanced(expr)
	if ("" '= this.errorHTML) {
		quit tokenList
	}

	// process extra char at end
	for n = 0:1:$L(expr)-1 {
		Set ch = $e(expr,n+1)
		Set peek = $e(expr,n+2) // next character
		if (ch="(") {
			Set foobar=1
		}
		if (ch=1) {
			Set foobar=1
		}
		if (ch=")") {
			Set foobar=1
		}
		// alert(state+":"+ch);

		if state=0 {
			// start
			if (ch = """") {
				// start of string
				Set token = ""
				Set state = 1
				Set firstTok = 0
			}
			elseif ('$$$ISNAN(ch)) {
				// start of integer
				Set token = ch
				Set state = 2
				Set firstTok = 0
			}
			elseif (ch = ".") {
				// start of numeric
				Set token = "0."
				Set state = 3
				Set firstTok = 0
			}
			elseif (firstTok && ..isUnaryOperatorChar(ch)) {
				// unary op
				Set token = ch
				Set state = 7
				Set firstTok = 0
			}
			elseif (..isOperatorChar(ch)) {
				Set token = ch
				Set state = 6
				Set firstTok = 0
			}
			elseif (..isIdentChar(ch,1)) {
				// start of ident
				Set state = 4
				Set token = ..lookupTable("IdentStart") _ ch
				Set firstTok = 0
			}
			elseif (ch = ..lookupTable("IdentStart")) {
				// start of delimited ident
				Set state = 8
				Set token = ch
				Set firstTok = 0
			}
			elseif (..isWhiteSpace(ch)) {
				// ignore
			}
			elseif ("" = ch) {
				// ignore
			}
			elseif (..isSpecialChar(ch)) {
				do ..Insert(tokenList,##class(parseTreeNode).%New(ch, ch))
				Set firstTok = 0
				if ("("=ch || (","=ch)) {
					Set firstTok = 1
				}
			}
			else {
				// unexpected character
				Set hasError = 1
				Set msg = ..dsGetErrorHTML(1,"Unexpected character",expr,n)
			}
		}
		elseif state=1 {
			// string literal
			if (ch = """") {
				// look ahead for ""
				Set peek = $e(expr,n+2)
				if (peek = """") {
					// ""
					Set token = token _ ch
					Set state = 5
				}
				else {
					// end of string
					do ..Insert(tokenList,##class(parseTreeNode).%New("string", token))
					Set state = 0
				}
			}
			else {
				Set token = token _ ch
			}
		}
		elseif state=2 {
			// integer literal
			if ('$$$ISNAN($$$PARSEINT(ch))) {
				// add to integer literal
				Set token = token _ ch
			}
			elseif (ch = ".") {
				// numeric literal
				Set state = 3
				Set token = token _ ch
			}
			elseif (..isOperatorChar(ch)) {
				// start of op
				do ..Insert(tokenList,##class(parseTreeNode).%New("number", token))
				//tokenList[tokenList.length] = { type:"number", value:token }
				Set state = 6
				Set token = ch
			}
			elseif (..isSpecialChar(ch)) {
				do ..Insert(tokenList,##class(parseTreeNode).%New("number", token))
				//tokenList[tokenList.length] = { type:'number', value:token };
				do ..Insert(tokenList,##class(parseTreeNode).%New(ch, ch))
				//tokenList[tokenList.length] = { type:ch, value:ch}
				if ("("=ch || (","=ch)) {
					Set firstTok = 1
				}
				Set token = ""
				Set state = 0
			}
			elseif (..isWhiteSpace(ch) || ch="") {
				do ..Insert(tokenList,##class(parseTreeNode).%New("number", token))
				Set state = 0
				Set token = ""
			}
			else {
				// error: invalid number
				Set hasError = 1
				Set msg = ..dsGetErrorHTML(2,"Invalid number",expr,n-$L(token)-1,n)
				Set state = 0
			}
		}
		elseif state=3 {
			// numeric literal
			if ('$$$ISNAN($$$PARSEINT(ch))) {
				// add to numeric literal
				Set token = token _ ch
			}
			elseif (ch = ".") {
				// error
				Set hasError = 1
				Set msg = ..dsGetErrorHTML(3,"Unexpected character",expr,n)
			}
			elseif (..isOperatorChar(ch)) {
				// start of op
				do ..Insert(tokenList,##class(parseTreeNode).%New("number", token))
				//tokenList[tokenList.length] = { type:"number", value:token }
				Set state = 6
				Set token = ch
			}
			elseif (..isSpecialChar(ch)) {
				do ..Insert(tokenList,##class(parseTreeNode).%New(ch, ch))
				//tokenList[tokenList.length] = { type:ch, value:ch}
				if (("("=ch) || (","=ch)) {
					Set firstTok = 1
				}
				Set state = 0
			}
			elseif (..isWhiteSpace(ch) || (ch="")) {
				// tokenList[tokenList.length] = { type:"number", value:token }
				do ..Insert(tokenList,##class(parseTreeNode).%New("number", token))
				Set state = 0
				Set token = ""
			}
			else {
				// error: invalid number
				Set hasError = 1
				Set msg = ..dsGetErrorHTML(4,"Invalid number",expr,n-$L(token)-1,n)
				Set token = ""
				Set state = 0
			}
		}
		elseif state=4 {
			// ident
			if (..isOperatorChar(ch)) {
				// add ident to list
				if ('..isValidIdent(token)) {
					Set hasError = 1
					Set msg = ..dsGetErrorHTML(5,"Invalid identifier",expr,n-$L(token)-1,n)
				}
				// tokenList[tokenList.length] = { type:"ident", value:token+lookupTable.IdentEnd }
				do ..Insert(tokenList,##class(parseTreeNode).%New("ident", token_..lookupTable("IdentEnd")))

				// start of op
				Set token = ch
				Set state = 6
			}
			elseif ("."=ch) {
				if (peek = lookupTable.IdentStart) {
					Set token = token _ ..lookupTable("IdentEnd") _ ch
					Set state = 8
				}
				elseif (..isIdentChar(peek,0)) {
					Set token = token _ ..lookupTable("IdentEnd") _ ch _ ..lookupTable("IdentStart")
					Set state = 4
				}
				else {
					Set hasError = 1
					Set msg = ..dsGetErrorHTML(49,"Invalid identifier",expr,n-$L(token)-1,n)
				}
			}
			elseif (..isWhiteSpace(ch) || ""=ch) {
				// whitespace: end of ident
				if ('..isValidIdent(token)) {
					Set hasError = 1
					Set msg = ..dsGetErrorHTML(6,"Invalid identifier",expr,n-$L(token)-1,n)
				}
				//tokenList[tokenList.length] = { type:"ident", value:token+lookupTable.IdentEnd }
				do ..Insert(tokenList,##class(parseTreeNode).%New("ident", token_..lookupTable("IdentEnd")))
				Set token = ""
				Set state = 0
			}
			elseif (ch = """") {
				// error: quote in ident
				Set hasError = 1
				Set token = ""
				Set state = 0
				Set msg = ..dsGetErrorHTML(7,"Unexpected character",expr,n)
			}
			elseif (..isSpecialChar(ch)) {
				// add ident to list
				if ('..isValidIdent(token)) {
					Set hasError = 1
					Set msg = ..dsGetErrorHTML(8,"Invalid identifier",expr,n-$L(token)-1,n)
				}
				if (ch="(") {
					// function: remove [
					Set token = $e(token, 2,*)
					// tokenList[tokenList.length] = { type:"func", value:token }
					do ..Insert(tokenList,##class(parseTreeNode).%New("func", token))
					// test if this is a known function
					if ('this.isFunction(token)) {
						Set hasError = 1
						Set msg = ..dsGetErrorHTML(8,"Unknown function " + token,expr,n-$L(token)-1,n)
					}
				}
				else {
					//tokenList[tokenList.length] = { type:"ident", value:token+lookupTable.IdentEnd }
					//tokenList[tokenList.length] = { type:ch, value:ch}
					do ..Insert(tokenList,##class(parseTreeNode).%New("ident", token_..lookupTable("IdentEnd")))
					do ..Insert(tokenList,##class(parseTreeNode).%New(ch, ch))
				}
				if (("("=ch) || (","=ch)) {
					Set firstTok = 1
				}
				Set token = ""
				Set state = 0
			}
			elseif ('..isIdentChar(ch,0)) {
				// error: invalid char
				Set hasError = 1
				Set msg = ..dsGetErrorHTML(9,"Invalid identifier",expr,n-$L(token)-1,n)
				Set state = 0
				Set token = ""
			}
			else {
				Set token = token _ ch
			}
		}
		elseif (state=5) {
			// "" in a string
			if (ch = """") {
				// this is the 2nd, expected quote
				Set state = 1
			}
			else {
				Set hasError = 1
				Set msg = ..dsGetErrorHTML(10,"Unexpected character",expr,n)
			}
		}
		elseif state=6 {
			// binary op
			if (..isOperatorChar(ch)) {
				// test for unary operator after binary...
				if ((..isBinaryOperator(token)) && (..isUnaryOperatorChar(ch))) {
					// process 2nd op as new unary op
					// tokenList[tokenList.length] = { type:"op", value:token }
					do ..Insert(tokenList,##class(parseTreeNode).%New("op", token))
					Set token = ch
					Set state = 7
				}
				else {
					Set token = token _ ch
				}
			}
			elseif (..isSpecialChar(ch)) {
				if (('..isBinaryOperator(token)) && ('..isUnaryOperator(token))) {
					Set hasError = 1
					Set msg = ..dsGetErrorHTML(11,"Unexpected character",expr,n)
				}
				else {
					//tokenList[tokenList.length] = { type:"op", value:token }
					do ..Insert(tokenList,##class(parseTreeNode).%New("op", token))
					//tokenList[tokenList.length] = { type:ch, value:ch }
					do ..Insert(tokenList,##class(parseTreeNode).%New(ch, ch))
					if (("("=ch) || (","=ch)) {
						Set firstTok = 1
					}
					Set token = ""
					Set state = 0
				}
			}
			else {
				// end of op
				if (('..isBinaryOperator(token)) && ('..isUnaryOperator(token))) {
					Set hasError = 1
					Set msg = ..dsGetErrorHTML(12,"Unexpected character",expr,n)
				}
				else {
					if (..isWhiteSpace(ch) || ("" = ch)) {
						// whitespace
						//tokenList[tokenList.length] = { type:"op", value:token }
						do ..Insert(tokenList,##class(parseTreeNode).%New("op", token))
						Set token = ""
						Set state = 0
					}
					elseif (ch = """") {
						// start of string
						//tokenList[tokenList.length] = { type:"op", value:token }
						do ..Insert(tokenList,##class(parseTreeNode).%New("op", token))
						Set token = ""
						Set state = 1
					}
					elseif ('$$$ISNAN($$$PARSEINT(ch))) {
						// start of number
						//tokenList[tokenList.length] = { type:"op", value:token }
						do ..Insert(tokenList,##class(parseTreeNode).%New("op", token))
						Set token = ch
						Set state = 2
					}
					elseif (ch = ".") {
						// start of numeric
						//tokenList[tokenList.length] = { type:"op", value:token }
						do ..Insert(tokenList,##class(parseTreeNode).%New("op", token))
						Set token = "0."
						Set state = 3
					}
					elseif (ch = ..lookupTable("IdentStart")) {
						// start of del ident
						//tokenList[tokenList.length] = { type:"op", value:token }
						do ..Insert(tokenList,##class(parseTreeNode).%New("op", token))
						Set token = ch
						Set state = 8
					}
					elseif (..isIdentChar(ch,1)) {
						// start of ident
						//tokenList[tokenList.length] = { type:"op", value:token }
						do ..Insert(tokenList,##class(parseTreeNode).%New("op", token))
						Set token = ..lookupTable("IdentStart") _ ch
						Set state = 4
					}
					else {
						// error
						Set hasError = 1
						Set msg = ..dsGetErrorHTML(13,"Unexpected character",expr,n)
					}
				}
			}
		}
		elseif state=7 {
			// unary op
			if (..isSpecialChar(ch)) {
				if ('isUnaryOperator(token)) {
					Set hasError = 1
					Set msg = ..dsGetErrorHTML(14,"Unexpected character",expr,n)
				}
				else {
					//tokenList[tokenList.length] = { type:"unary", value:token }
					//tokenList[tokenList.length] = { type:ch, value:ch}
					do ..Insert(tokenList,##class(parseTreeNode).%New("unary", token))
					do ..Insert(tokenList,##class(parseTreeNode).%New("ch", ch))
					Set token = ""
					Set state = 0
				}
			}
			else {
				// end of op
				if ('..isUnaryOperator(token)) {
					Set hasError = 0
					Set msg = ..dsGetErrorHTML(15,"Unexpected character",expr,n)
				}
				else {
					if (..isWhiteSpace(ch)) {
						// whitespace
						//tokenList[tokenList.length] = { type:"unary", value:token }
						do ..Insert(tokenList,##class(parseTreeNode).%New("unary", token))
						Set token = ""
						Set state = 0
					}
					elseif (ch = """") {
						// start of string
						//tokenList[tokenList.length] = { type:"unary", value:token }
						do ..Insert(tokenList,##class(parseTreeNode).%New("unary", token))
						Set token = ""
						Set state = 1
					}
					elseif ('$$$ISNAN($$$PARSEINT(ch))) {
						// start of number
						//tokenList[tokenList.length] = { type:"unary", value:token }
						do ..Insert(tokenList,##class(parseTreeNode).%New("unary", token))
						Set token = ch
						Set state = 2
					}
					elseif (ch = ".") {
						// start of numeric
						//tokenList[tokenList.length] = { type:"unary", value:token }
						do ..Insert(tokenList,##class(parseTreeNode).%New("unary", token))
						Set token = "0."
						Set state = 3
					}
					elseif (ch = ..lookupTable("IdentStart")) {
						// start of del ident
						//tokenList[tokenList.length] = { type:"unary", value:token }
						do ..Insert(tokenList,##class(parseTreeNode).%New("unary", token))
						Set token = ch
						Set state = 8
					}
					elseif (..isIdentChar(ch,1)) {
						// start of ident
						//tokenList[tokenList.length] = { type:"unary", value:token }
						do ..Insert(tokenList,##class(parseTreeNode).%New("unary", token))
						Set token = ..lookupTable("IdentStart") + ch
						Set state = 4
					}
					elseif (..isUnaryOperatorChar(ch)) {
						// unary operator
						Set state = 7
						//tokenList[tokenList.length] = { type:"unary", value:token }
						do ..Insert(tokenList,##class(parseTreeNode).%New("unary", token))
						Set token = ch
					}
					else {
						// error
						Set hasError = 1
						Set msg = ..dsGetErrorHTML(16,"Unexpected character",expr,n)
					}
				}
			}
		}
		elseif state=8 {
			// delimited ident
			if (ch = ..lookupTable("IdentEnd")) {
				// do not validate
				// keep [] around ident
				// test for compound ident [a].[b]
				if (peek=".") {
					// compound ident: [a].[b]
					Set token = token _ ch
					Set state = 9
				}
				else {
					// add ident to list
					Set token = token _ ch
					//tokenList[tokenList.length] = { type:"ident", value:token }
					Set Status=..Insert(tokenList,##class(parseTreeNode).%New("ident", token))
					d DecomposeStatus^%apiOBJ(Status,.Err)	
					Set token = ""
					Set state = 0
				}
			}
			else {
				Set token = token _ ch
			}
		}
		elseif state=9 {
			// . in compound ident
			if ((ch = ".") && (peek = ..lookupTable("IdentStart"))) {
				Set token = token _ ch
				Set state = 8
			}
			elseif (ch = "." && ..isIdentChar(peek,0)) {
				Set token = token _ ch + ..lookupTable("IdentStart")
				Set state = 4
			}
			else {
				Set msg = ..dsGetErrorHTML(17,"Invalid identifier",expr,n-$L(token)-1,n)
			}
		}
	}


	// end of next character loop
	if (hasError) {
		Set this.errorHTML = msg
	}

	quit tokenList
}

/// Reduce the token list (tokens) into a parse tree (expr) and return the top node of it.
Method reduceTokens(tokens, expr)
{
	Set this=##this
	Set true=1
	Set false=0
	Set null=""
	
	Set topNode = null
	//try {
		// special case: item or +item
		if (tokens.Count()=0) {
			Set topNode = null
			quit topNode
		}
		elseif (tokens.Count()=1) {
			Set topNode = tokens.GetAt(0+1)
			quit topNode
		}
		elseif ((tokens.Count()=2) && (tokens.GetAt(0+1).type="unary") && (tokens.GetAt(0+1).value="+")) {
			Set topNode = tokens.GetAt(1+1)
			quit topNode
		}

		// check for dangling operators
		if (tokens.GetAt(tokens.Count()).type = "op") {
			Set this.errorHTML = ..dsGetErrorHTML(18,"Extra operator",expr,$L(expr)-1)
			Set topNode = null
			quit topNode
		}

		Set stack = ##class(stack).%New()
		Set n = 0
		while (n < (tokens.Count()-1)) {
			Set token = tokens.GetAt(n+1)
			do stack.push(token)

			if ((token.type = "func") && (token.children.Count() = 0)) {
				// skip to end of function
				Set topNode = token
				Set n = this.reduceFunction(tokens,n,expr)
			}

			// apply reduction rules
			Set count = 0
			Set canReduce = true
			while (canReduce && (count<10)) {
				Set count=count+1
				// get top 3 items from stack
				// see if we can reduce
				Set item1 = stack.peek(0)
				Set item2 = stack.peek(1)
				Set item3 = stack.peek(2)

				// alert('can reduce: ' + n + ":\n" + (item3?item3.type+":"+item3.value:'')+'\n'+(item2?item2.type+":"+item2.value:'')+'\n'+(item1?item1.type+":"+item1.value:'')+'\n');

				if ((item1'=null)&&(item2'=null)&&(item3'=null)&&(item1.type=")")) {

					if (item3.type="(") {
						// (x) remove parens
						if (item2.type="op") {
							// note presence of ()
							Set item2.inParens = true
						}
						do stack.pop()
						do stack.pop()
						do stack.pop()
						do stack.push(item2)
						Set topNode = item2
					}
				}
				elseif ((item1'=null)&&(item2'=null)&&(item2.type="unary")&&((item1.type="number") || (item1.type="ident") || (item1.type="func") || (item1.type="op"))) {
					// unary arg
					if (item2.value = "+") {
						// toss
						do stack.pop()
					}
					elseif (item2.value = "-") {
						// convert to * -1
						Set newItem = ##class(parseTreeNode).%New()
						Set newItem.type = "number"
						Set newItem.value = -1
						Set item2.type = "op"
						Set item2.value = "*"
						Set Status=item2.children.SetAt(item1,1+1)
						Set Status=item2.children.SetAt(newItem, 0+1)
						do stack.pop()
						do stack.pop()
						do stack.push(item2)
						Set topNode = item2
					}
					else {
						//alert("Unknown unary operator: " + item1.value);
						Set canReduce = false
					}
				}

				elseif ((item1'=null)&&(item2'=null)&&(item3'=null)&&(item2.type="op")
					&&(item1.type'="(")
					&&(item3.type'="(")) {
					// arg op arg

					Set swap = false
					if (item3.type="op" && '(true=item3.inParens)) {
						// check precedence
						Set swap = this.testPrecedence(item2.value,item3.value)
					}

					Set Status=item2.children.SetAt(item1,1+1)
					do stack.pop()
					do stack.pop()
					do stack.pop()

					if (swap) {
						Set Status=item2.children.SetAt(item3.children.GetAt(1+1),0+1)
						Set Status=item3.children.SetAt(item2, 1+1)
						do stack.push(item3)
						Set topNode = item3
					}
					else {
						Set Status=item2.children.SetAt(item3,0+1) 
						do stack.push(item2)
						Set topNode = item2
					}
				}
				else {
					Set canReduce = false
				}
			}
			Set n=n+1
		} // end-while

		// check for errors
	//}
	//catch {
		//alert('Error in reduceTokens:\n' + ex.message);
	//}

	quit topNode
}

/// Reduce a function within a token list.
/// Return index of next token.
Method reduceFunction(tokens, offset, expr)
{
	Set this=##this
	
	Set nextToken = -1

	//try {
		// find end of function
		Set token = tokens.GetAt(offset+1)
		Set paren = 1
		// list of tokens for one func argument
		#dim list As %ArrayOfObjects
		Set list = ##class(%ListOfObjects).%New()
		Set arg = 0
		Set nextToken=offset+1
		while nextToken < tokens.Count() {
			Set test = tokens.GetAt(nextToken+1)
			if (test.type = "func") {

				// skip to end of function
				Set nextToken = this.reduceFunction(tokens,nextToken,expr)
				do list.Insert(test)
			}
			elseif (test.type="(") {
				Set paren = paren + 1
			}
			elseif ((test.type=",")&&(paren=1)) {
				if (list.Count()>0) {
					Set node = this.reduceTokens(list,expr)
					/*
					if (null = token.children) {
						token.children = new Array();
					}
					*/
					Set Status=token.children.SetAt(node,arg+1) 
					Do list.Clear()
				}
				Set arg = arg+1
			}
			elseif (test.type=")") {
				Set paren = paren - 1
				if (0=paren) {
					if (list.Size>0) {
						Set node = this.reduceTokens(list,expr)
						/*
						if (null = token.children) {
							token.children = new Array();
						}
						*/
						Set Status=token.children.SetAt(node,arg+1) 
					}
					else {
						//token.children = new Array();
					}
					quit
				}
			}
			else {
				do list.Insert(test)
			}
			Set nextToken=nextToken+1
		}
	//}
	//catch {
		//alert("Error in reduceFunction:\n" + ex.message);
	//}
	quit nextToken
}

/// Make a pass over expression and make sure parens and quotes are balanced
Method isExpressionBalanced(expr)
{
	Set state = 0
	Set token = ""
	Set paren = 0

	for n = 0:1:$L(expr)-1 {
		Set ch = $e(expr,n+1)
		if state = 0 {
			if ch = "(" {
				Set paren = paren+1
			}
			elseif ch = ")" {
				Set paren = paren-1
			}
			elseif ch = ..lookupTable("IdentStart") {
				Set state = 2
			}
			elseif ch = """" {
				Set state = 1
				
			}
		}
		elseif state = 1 {
			if ch = """" {
				Set state = 0
			}
		}
		elseif state = 2 {
			if ch = ..lookupTable("IdentEnd") { 
				Set state = 0

			}
		}
	}
	

	// construct errorHTML
	Set msg = ""
	if (state = 1) {
		// unmatched quotes: find last quote
		Set idx = ..lastIndexOf(expr, """")
		if (idx>=0) {
			Set msg = ..dsGetErrorHTML(19,"Missing quote",expr,idx,$L(expr))
		}
	}
	elseif (state = 2) {
		// unmatched delimiters: find last delim
		Set idx = ..lastIndexOf(expr, ..lookupTable("IdentStart"))
		if (idx>=0) {
			Set msg = ..dsGetErrorHTML(19,"Missing delimiter",expr,idx,$L(expr))
		}
	}
	elseif (paren '= 0) {
		// unbalanced parens: find last (
		Set idx = ..lastIndexOf("(")
		if (idx>=0) {
			Set msg = ..dsGetErrorHTML(20,"Unmatched parens",expr,idx,$L(expr))
		}
		else {
			Set idx = expr.lastIndexOf(")")
			Set msg = ..dsGetErrorHTML(21,"Unmatched parens",expr,idx,idx+1)
		}
	}

	quit msg
}

/// Return error HTML.
Method dsGetErrorHTML(code, msg, expr, start, end)
{
	
	Set ..dsFormulaLastError = msg
	Set end = $s('$D(end) : start+1, 1: end)
	quit $e(expr,1,start+1)_"<span title="""_msg_" (code: "_code_")"_ """ style=""color:red;"">"_$e(expr,start+1,end+1)_"</span>" _ $e(expr,end+1,*)
}

Method isBinaryOperator(ch)
{
	//return lookupTable.BinaryOp[ch] ? true : false;
	quit $D(..lookupTable("BinaryOp","ch"))
}

Method isUnaryOperator(ch)
{
	//return lookupTable.UnaryOp[ch] ? true : false;
	quit $D(..lookupTable("UnaryOp",ch))
}

Method isOperatorChar(ch)
{
	//return lookupTable.BinaryOpChar[ch] ? true : false;
	quit $D(..lookupTable("BinaryOpChar",ch))
}

Method isUnaryOperatorChar(ch)
{
	//return lookupTable.UnaryOpChar[ch] ? true : false;
	quit $D(..lookupTable("UnaryOpChar",ch))
}

Method isWhiteSpace(ch)
{
	//return lookupTable.WhiteChar[ch] ? true : false;
	quit $D(..lookupTable("WhiteChar",ch))
}

Method isIdentChar(ch, start)
{
	// start indicates first char of expression
	// a=97,z=122, A=65,Z=90 0=48,9=57
	
	Set code = $a($e(ch))
	if (((code >= 97) && (code <= 122)) ||
		((code >= 65) && (code <= 90)) ||
		(ch = "%") ||
		(ch = "#") ||
		(ch = "^") ||
		(ch = "$") ||
		('start && (code >= 48) && (code <= 57)) ||
		(code >= 128)) {
		quit 1 // true
	}

	quit 0 // false
}

Method isSpecialChar(ch)
{
	//return lookupTable.SpecialChar[ch] ? true : false;
	quit $D(..lookupTable("SpecialChar",ch))
}

/// test if complete token is a valid identifier
ClassMethod isValidIdent(token)
{
	/*
	if (token.toString().charAt(0)=='.') return false;

	if (token=='%' || token=='^') return false;

	if (token.search(/\.\d|\.[$^#]|[@!~]/) != -1) return false;
	
	return true;
	*/
	if $e(token)="." quit 0

	if (token="%" || (token="^")) quit 0

	if ($match(token,"\.\d|\.[$^#]|[@!~]")) quit 0
	
	quit 1
}

/// test if token is a valid class name
ClassMethod isValidClassName(token)
{
	/*
	// this could be improved!
	if (token == '') return false;
	if (token.search(/[@!~\*-\+\s]/) != -1) return false;
	return true;
	*/
	// this could be improved!
	if (token = "") quit 0
	if ($match(token,"[@!~\*-\+\s]")) quit 0
	quit 1
}

/// test if token is a supported function name
Method isFunction(token)
{
	Set func = $$$TOLOWERCASE(token)
	Set builtIn = $case(func,"if":1,"and":1,"or":1,"concat":1,"not":1,"round":1,"rowno":1,"colno":1,"sum":1,:0)
	if builtIn {
		quit 1
	}

	Set function=..findFunctionInFunctionSet(func)
	if ((func '= "")&&(function'="")) {
		quit 1
	}
	quit 0
}

/// Test if op1 has precendence over op2
Method testPrecedence(op1, op2)
{
	quit (..getPrecedence(op1) > ..getPrecedence(op2))
}

/// Return the precedence value for the given operator.
Method getPrecedence(op)
{
	Set p=$case(op, "+":4,"-":4, "*":5,"/":5,:1)
	quit p
}

ClassMethod get(arg, defvalue)
{
	// return (null != value) ? value : (null != defValue) ? defValue : '';
	quit $s($D(value): value, 1:$s($D(defValue):defValue, 1:""))
}

Method findFunctionInFunctionSet(func)
{
	// search function set for function
	Set retFunc=""
	for i=1:1:..funcSet.Size {
		#dim thisFunc As function
		Set thisFunc=..funcSet.GetAt(i)
		if thisFunc.key = func {
			Set retFunc = thisFunc
			quit
		}
	}	
	quit retFunc
}

ClassMethod lastIndexOf(string, substring)
{
	do {
		Set saveIndex=$g(lastIndexOf,0)
		Set lastIndexOf=$find(string,substring)
	} while (lastIndexOf '= 0)
	quit saveIndex
}

ClassMethod Insert(array, obj)
{
	Set Status=array.SetAt(obj,array.Count()+1)
	quit Status
}

}
