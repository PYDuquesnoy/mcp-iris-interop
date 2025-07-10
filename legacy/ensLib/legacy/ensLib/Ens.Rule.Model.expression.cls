/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// model class for an expression
Class Ens.Rule.Model.expression Extends (%RegisteredObject, %XML.Adaptor, %JSON.Adaptor) [ System = 3 ]
{

Property operator As %String(MAXLEN = "");

Property operands As list Of Ens.Rule.Model.expression;

Property value As %String(MAXLEN = "");

Property errorText As %String;

Property warningText As %String;

Property errorOffset As %String;

Property defaultValue As %String(MAXLEN = "");

/// if there is only one argument, then it is set to value property with operator being null and operands being empty
/// if there are more than one argument, then the first one is the operator and the remaining arguments are operands, in this case, value property is empty.
Method %OnNew(operator, operands...) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	if +$g(operands)=0 {
		set ..value=$g(operator)
	} else {
		set ..operator=$g(operator)
		for i=1:1:operands do ..operands.Insert($s($isObject(operands(i)):operands(i),1:..%New(operands(i))))
	}
	quit $$$OK
}

ClassMethod test(pExpression, variables, pLogicalOnly = 0, pAllowNullOperand = 0, pUseLegacyOperatorPrecedence = 0) As %Status
{
	set tSC=..parseExpression($g(pExpression),.tObject,pAllowNullOperand,pUseLegacyOperatorPrecedence)
	if $$$ISERR(tSC) do DisplayError^%apiOBJ(tSC) quit tSC
	if pLogicalOnly do tObject.makeLogical()
	write tObject.constructExpression("",pLogicalOnly)
	set tSC=tObject.constructCOS(.expression,.variables)
	if $$$ISERR(tSC) do DisplayError^%apiOBJ(tSC) quit tSC
	w !,expression
	quit $$$OK
}

/// This method is called by the Portal to parse an expression string
/// When encountering syntax error, it returns an value object with errorText and errorOffset
ClassMethod parse(pExpression As %String, pObject As Ens.Rule.Model.expression, pLogicalOnly As %Boolean) As %Status
{
	set tSC=$$$OK
	try {
		set tSC=..parseExpression(pExpression,.pObject,1)
		if $$$ISERR(tSC) {
			set pObject=..%New()
			set pObject.value=pExpression
			set pObject.errorText=$system.Status.GetErrorText(tSC)
			do DecomposeStatus^%apiOBJ(tSC,.errorlist)
			set pObject.errorOffset=$g(errorlist(1,"param",1),0)
			set tSC=$$$OK
			quit
		}
		if pObject=$$$NULLOREF set pObject=..%New()
		if $g(pLogicalOnly) do pObject.makeLogical()
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	}
	quit tSC
}

/// This method parses an expressions string and outputs the model object by reference
/// It returns a error status code if there are syntax errors
/// If pAllowNullOperand is true, the expression will allow "()" as place holder for empty operands
/// If pUseLegacyOperatorPrecedence is true, the parser will use legacy operator precedence
ClassMethod parseExpression(pExpression As %String, pObject As Ens.Rule.Model.expression, pAllowNullOperand = 0, pUseLegacyOperatorPrecedence = 0) As %Status
{
	set tSC=$$$OK
	try {
		set tSC=..tokenize(pExpression,.tToken) quit:$$$ISERR(tSC)
		set tSC=..parseToken(.tToken,1,.pObject,.tOffset,pAllowNullOperand,pUseLegacyOperatorPrecedence) quit:$$$ISERR(tSC)
		if tOffset'="EOL" set tSC=$$$ERROR($$$EnsErrInvalidToken,tOffset)
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	}
	quit tSC
}

/// parseToken accepts tokenList which is a linear list of all tokens
/// 1) It first converts tokenList to tokenTree by resolving nested structures.
/// 2) At each heiarchical level, tokenTree contains a flat structure of operands, binary operators, unary operators, functions and arguments
/// 3) We resolve functions into on single model object
/// 4) We resolve unary operators into model objects
/// 5) At each binary operator precedence level, from high to low, we combining tokens into binary or multiary model objects
ClassMethod parseToken(tokenList, tokenCount, pObject, pTokenOffset, pAllowNullOperand, pUseLegacyOperatorPrecedence) As %Status
{
#define TRYCATCH 1

	set tSC=$$$OK
#if $$$TRYCATCH
	try {
#endif
		do ..dumpData(.tokenList,"tokenList as input parameter")

		// we convert tokenList to tokenTree first
		set pTokenOffset=0,tokenTree=0
		set currentTokenIndex=1,currentTokenType="operand",currentTokenString="",currentTokenOffset=0
		for tokenCount=tokenCount:1:tokenList+1 {
			;
			if ..getToken(.tokenList,tokenCount,.tokenString,.pTokenOffset)=0 {
				if currentTokenString'="" do ..addTokenTree(.tokenTree,currentTokenIndex,currentTokenString,currentTokenOffset,currentTokenType)
				quit
			}
			;
			if (tokenString=",")||(tokenString=")") {
				if currentTokenString'="" do ..addTokenTree(.tokenTree,currentTokenIndex,currentTokenString,currentTokenOffset,currentTokenType)
				quit
			}
			;
			if currentTokenType="operand" {
				; we are working on an operand
				if currentTokenString="" {
					; we do not have a partially built operand
					if tokenString="(" {
						; start nested parsing, absorb everything until the matching closing paren
						set tokenCount=tokenCount+1
						set tSC=..parseToken(.tokenList,.tokenCount,.tObject,.tTokenOffset,pAllowNullOperand,pUseLegacyOperatorPrecedence) quit:$$$ISERR(tSC)
						if 'pAllowNullOperand,tObject=$$$NULLOREF set tSC=$$$ERROR($$$EnsErrInvalidToken,tTokenOffset) quit
						do ..addTokenTree(.tokenTree,currentTokenIndex,tObject,tTokenOffset,currentTokenType)
						if ..getToken(.tokenList,tokenCount,.tokenString,.pTokenOffset)=0 set tokenCount=tokenCount+1,tSC=$$$ERROR($$$EnsErrMissingCloseParen,"EOL") quit
						if tokenString'=")" set tSC=$$$ERROR($$$EnsErrMissingCloseParen,pTokenOffset) quit
						set currentTokenIndex=currentTokenIndex+1
						set currentTokenType="operator"
						set currentTokenString=""
						set currentTokenOffset=0
					} elseif (..isUnaryOperator(tokenString)) {
						; unary operator
						do ..addTokenTree(.tokenTree,currentTokenIndex,tokenString,pTokenOffset,"unary")
						set currentTokenIndex=currentTokenIndex+1
						set currentTokenString=""
						set currentTokenOffset=0
					} elseif ( (tokenString=".")||(tokenString'?1P) ) {
						; . is for numeric, .123, then anything non-puctuation is good
						set currentTokenString=tokenString
						set currentTokenOffset=pTokenOffset
					} elseif ( tokenString="@" ) {
						; this is to support variable syntax @xyz or Rule class method invocation
						set currentTokenString=tokenString
						set currentTokenOffset=pTokenOffset
					} else {
						set tSC=$$$ERROR($$$EnsErrInvalidName,pTokenOffset) quit
					}
				} else {
					; we already have a partially built operand
					if $e(currentTokenString,*)=".",$lf($lb("{","(","[","<"),tokenString) {
						; we are about to start a virtual property
						set vpBegin=tokenString,vpEnd=$case(tokenString, "{":"}", "(":")", "[":"]", "<":">"),vpLevel=1
						set currentTokenString=currentTokenString_tokenString
						for tokenCount=tokenCount+1:1:tokenList+1 {
							if ..getToken(.tokenList,tokenCount,.tokenString,.pTokenOffset)=0 {
								set tSC=$$$ERROR($$$EnsErrMissingCloseCurlyBrace,"EOL") quit
							}
							set currentTokenString=currentTokenString_tokenString
							if tokenString=vpBegin set vpLevel=vpLevel+1
							if tokenString=vpEnd   set vpLevel=vpLevel-1
							if vpLevel=0 {
								do ..addTokenTree(.tokenTree,currentTokenIndex,currentTokenString,currentTokenOffset,currentTokenType)
								set currentTokenIndex=currentTokenIndex+1
								set currentTokenType="operator"
								set currentTokenString=""
								set currentTokenOffset=0
								quit
							}
						}
					} elseif tokenString="(" {
						if ..isValidFunction(currentTokenString) || ..isValidCollectionsMethod(currentTokenString) {
							; start function here if the currentTokenString is a valid function name
							do ..addTokenTree(.tokenTree,currentTokenIndex,currentTokenString,pTokenOffset,"function")
							set currentTokenIndex=currentTokenIndex+1
							set currentTokenType="argument"
							set currentTokenString=""
							set currentTokenOffset=0
							for {
								set tokenCount=tokenCount+1
								set tSC=..parseToken(.tokenList,.tokenCount,.tObject,.tTokenOffset,pAllowNullOperand,pUseLegacyOperatorPrecedence) quit:$$$ISERR(tSC)
								if tObject=$$$NULLOREF set tObject=..%New()
								do ..addTokenTree(.tokenTree,currentTokenIndex,tObject,tTokenOffset,currentTokenType)
								if ..getToken(.tokenList,tokenCount,.tokenString,.pTokenOffset)=0 set tokenCount=tokenCount+1,tSC=$$$ERROR($$$EnsErrMissingCloseParen,"EOL") quit
								if (tokenString'=",")&&(tokenString'=")") set tSC=$$$ERROR($$$EnsErrMissingCloseParen,pTokenOffset) quit
								set currentTokenIndex=currentTokenIndex+1
								if tokenString=")" quit
							}
							set currentTokenType="operator"
							set currentTokenString=""
							set currentTokenOffset=0
						} else {
							set tSC=$$$ERROR($$$EnsErrInvalidToken,pTokenOffset) quit
						}
					} elseif ..canAppendToken(currentTokenString,tokenString) {
						; we can append the tokens
						set currentTokenString=currentTokenString_tokenString
					} elseif ( (currentTokenString="@")&&(tokenString?1.ANZFWCHARZ) ) {
						; this is to support variable syntax @xyz
						set currentTokenString=currentTokenString_tokenString
					} else {
						; terminate the token, rewind the tokenCount to re-start scanning of an operator
						do ..addTokenTree(.tokenTree,currentTokenIndex,currentTokenString,currentTokenOffset,currentTokenType)
						set currentTokenIndex=currentTokenIndex+1
						set currentTokenType="operator"
						set currentTokenString=""
						set currentTokenOffset=0
						; rewind the tokenCount, allow the next iteration to handle this token
						set tokenCount=tokenCount-1
					}
				}
			} else {
				; we are working on an operator
				if currentTokenString="" {
					; we do not have a partially built operator, just save it
					set currentTokenString=tokenString
					set currentTokenOffset=pTokenOffset
				} else {
					; we already have a partially built operator
					if ..isBinaryOperator(currentTokenString_tokenString) {
						set currentTokenString=currentTokenString_tokenString
					} elseif ( ..isBinaryOperator(currentTokenString) ) {
						do ..addTokenTree(.tokenTree,currentTokenIndex,currentTokenString,currentTokenOffset,currentTokenType)
						set currentTokenIndex=currentTokenIndex+1
						set currentTokenType="operand"
						set currentTokenString=""
						set currentTokenOffset=0
						; rewind the tokenCount, allow the next iteration to handle this token
						set tokenCount=tokenCount-1
					} else {
						set tSC=$$$ERROR($$$EnsErrInvalidBinaryOperator,currentTokenOffset) quit
					}
				}
			}
		}
		quit:$$$ISERR(tSC)
		do ..dumpData(.tokenTree,"tokenTree when first created")
		;
		if tokenTree=0 set pObject=$$$NULLOREF quit
		;
		; we now have a flat structure, but with mixed types of operand, operator, unnary, function and argument
		; binary operators are not checked, but unary operators have been checked
		;
		; first we check to see if all the binary operators are valid
		for count=1:1:tokenTree {
			if tokenTree(count,"type")="operator",..isBinaryOperator(tokenTree(count))=0 set tSC=$$$ERROR($$$EnsErrInvalidBinaryOperator,tokenTree(count,"offset")) quit
		}
		quit:$$$ISERR(tSC)
		;
		; we resolve all the functions with arguments first
		set reorderNeeded=0
		for count=1:1:tokenTree {
			if tokenTree(count,"type")'="function" continue
			set tObject=..%New()
			set tObject.operator=tokenTree(count)
			set tokenTree(count,"type")="operand"
			for i=count+1:1:tokenTree+1 {
				if i=(tokenTree+1) quit
				if tokenTree(i,"type")'="argument" quit
				do tObject.operands.Insert(tokenTree(i))
				kill tokenTree(i)
				set reorderNeeded=1
			}
			set tokenTree(count)=tObject
			set count=i-1
		}
		if ( reorderNeeded ) {
			set sub="" for count=1:1 {
				set sub=$o(tokenTree(sub)) quit:sub=""
				merge tokenTree(count)=tokenTree(sub) kill:count'=sub tokenTree(sub)
				set tokenTree=count
			}
		}
		do ..dumpData(.tokenTree,"tokenTree after functions and argument have been resolved")
		;
		; we resolve the unary operators, we go backwards so to associate the unary operators from right to left
		set reorderNeeded=0
		for count=tokenTree:-1:1 {
			if tokenTree(count,"type")'="unary" continue
			set tokenTree(count)=..%New(tokenTree(count),tokenTree(count+1))
			set tokenTree(count,"type")="operand"
			kill tokenTree(count+1)
			set reorderNeeded=1
		}
		; re-orer tokenTree to remove gaps
		if ( reorderNeeded ) {
			set sub="" for count=1:1 {
				set sub=$o(tokenTree(sub)) quit:sub=""
				merge tokenTree(count)=tokenTree(sub) kill:count'=sub tokenTree(sub)
				set tokenTree=count
			}
		}
		do ..dumpData(.tokenTree,"tokenTree after unary operators are resolved")
		;
		; tokenTree now has alternating operand, operator, operand, operator, ...
		; make sure we have all the arguments
		if tokenTree#2=0 set tSC=$$$ERROR($$$EnsErrMissingBinaryOperator,pTokenOffset) quit
		;
		; now group the binary operators, start with precedence=3, then 2
		for precedence=7:-1:1 {
			set reorderNeeded=0
			for count=2:2:tokenTree {
				set tokenOperator = tokenTree(count)
				set thisPrecedence = $s(pUseLegacyOperatorPrecedence:..operatorPrecedenceLegacy(.tokenOperator),1:..operatorPrecedence(.tokenOperator))
				if thisPrecedence'=precedence continue
				if ..isMultiaryOperator(.tokenOperator) {
					for last=count:2:tokenTree+1 quit:(last=(tokenTree+1))||(tokenTree(last)'=tokenOperator)
					set offset = tokenTree(count-1,"offset")
					set tLogical = ..%New()
					set tLogical.operator = tokenOperator
					for i=count-1:1:last-1 {
						if i#2=1 do tLogical.operands.Insert($s($isObject(tokenTree(i)):tokenTree(i),1:..%New(tokenTree(i))))
						kill tokenTree(i)
					}
					set tokenTree(last-1)=tLogical
					set tokenTree(last-1,"offset")=offset
					set count=last-2
				} else {
					set tokenTree(count+1) = ..%New(tokenOperator,tokenTree(count-1),tokenTree(count+1))
					set tokenTree(count+1,"offset")=tokenTree(count-1,"offset")
					kill tokenTree(count-1),tokenTree(count)
				}
				set reorderNeeded=1
			}
			; re-orer tokenTree to remove gaps between each precedence
			if ( reorderNeeded ) {
				set sub="" for count=1:1 {
					set sub=$o(tokenTree(sub)) quit:sub=""
					if count'=sub merge tokenTree(count)=tokenTree(sub) kill tokenTree(sub)
					set tokenTree=count
				}
			}
		}
		do ..dumpData(.tokenTree,"tokenTree after operators of different precedences are resolved")
		;
		; there should be only one node left in tokenTree, and that is our answer
		set token=tokenTree($o(tokenTree("")))
		set pObject=$s($isObject(token):token,1:..%New(token))
		;
#if $$$TRYCATCH
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	}
#endif
	quit tSC
}

ClassMethod addTokenTree(tokenTree, tokenIndex, tokenString, tokenOffset, tokenType)
{
	set tokenTree=tokenIndex
	set tokenTree(tokenTree)=tokenString
	set tokenTree(tokenTree,"offset")=tokenOffset
	set tokenTree(tokenTree,"type")=tokenType
	quit
}

ClassMethod isValidFunction(token) As %Boolean
{
	quit ("@"=$E(token)&&($zname($E(token,2,*))))||$zname(token)||("Rule."=$E(token,1,5)&&($zname($E(token,6,*))))||("Assist."=$E(token,1,7)&&($zname($E(token,8,*))))
}

ClassMethod isValidCollectionsMethod(token) As %Boolean
{
	Quit ''$lf($lb("Count","Find","GetAt","GetNext","GetPrevious","IsDefined","Next","Previous"),$Piece(token,".",*))
}

ClassMethod canAppendToken(currentToken, newToken) As %Boolean
{
	if currentToken?1.N,newToken="." quit 1
	if currentToken?.N1".",newToken?1.N quit 1
	if newToken="." {
		set isValid=1 for i=1:1:$l(currentToken,".") if ($p(currentToken,".",i)="")||($zname($p(currentToken,".",i))=0) set isValid=0 quit
		quit isValid
	}
	if $zname(newToken) {
		set isValid=1 for i=1:1:$l(currentToken,".")-1 if ($p(currentToken,".",i)="")||($zname($p(currentToken,".",i))=0) set isValid=0 quit
		if $p(currentToken,".",$l(currentToken,"."))'="" set isValid=0
		quit isValid
	}
	quit 0
}

ClassMethod isUnaryOperator(token) As %Boolean
{
	quit ''$lf($lb("+","-","!"),token)
}

ClassMethod isBinaryOperator(token) As %Boolean
{
	quit ''$lf($lb("+","-","*","/","!=","=",">=","<=",">","<","&","&&","||","[","_","CONTAINS","DOESNOTCONTAIN","IN","NOTIN","STARTSWITH","DOESNOTSTARTWITH","LIKE","NOTLIKE","MATCHES","DOESNOTMATCH","INFILE","NOTINFILE","INTERSECTSLIST","DOESNOTINTERSECTLIST"),$zcvt(token,"u"))
}

ClassMethod isMultiaryOperator(token) As %Boolean
{
	quit ''$lf($lb("+","*","&","&&","||","_"),token)
}

ClassMethod operatorPrecedence(pOperator) As %String
{
	if $lf($lb("*","/"),pOperator)               quit 7
	if $lf($lb("+","-","_","&"),pOperator)       quit 6
	if $lf($lb(">=","<=",">","<","["),pOperator) quit 5
	if $lf($lb("CONTAINS","DOESNOTCONTAIN","IN","NOTIN","STARTSWITH","DOESNOTSTARTWITH","LIKE","NOTLIKE","MATCHES","DOESNOTMATCH","INFILE","NOTINFILE","INTERSECTSLIST","DOESNOTINTERSECTLIST"),$zcvt(pOperator,"u")) quit 4
	if $lf($lb("!=","="),pOperator)              quit 3
	if pOperator="&&"                            quit 2
	if pOperator="||"                            quit 1
	quit 0
}

ClassMethod operatorPrecedenceLegacy(pOperator) As %String
{
	if pOperator="||"              quit 1
	if pOperator="&&"              quit 2
	if pOperator="&"               quit 3
	if $lf($lb("+","-"),pOperator) quit 4
	if $lf($lb("*","/"),pOperator) quit 5
	if $lf($lb("!=","=",">=","<=",">","<","[","_"),pOperator) quit 6
	if $lf($lb("CONTAINS","DOESNOTCONTAIN","IN","NOTIN","STARTSWITH","DOESNOTSTARTWITH","LIKE","NOTLIKE","MATCHES","DOESNOTMATCH","INFILE","NOTINFILE","INTERSECTSLIST","DOESNOTINTERSECTLIST"),$zcvt(pOperator,"u")) quit 7
	quit 0
}

ClassMethod tokenize(pExpression, tokenList) As %Status
{
	set tSC=$$$OK
	try {
		kill tokenList 
		set tokenList=0,length=$l(pExpression)
		for i=1:1:length {
			quit:$$$ISERR(tSC)
			set char=$e(pExpression,i)
			; skip spaces
			if char=" " continue
			if char="""" {
				; quote characters, token is to the matching closing quote
				for j=i+1:1:length+1 {
					if $e(pExpression,j)'="""" continue
					if $e(pExpression,j+1)="""" set j=j+1 continue
					if $e(pExpression,j+1)'="""" quit
				}
				if j=(length+1) set tSC=$$$ERROR($$$EnsErrMissingCloseQuote,"EOL") quit
				do ..addTokenList(.tokenList,$e(pExpression,i,j),i)
				set i=j
				continue
			} elseif char?1N {
				; character is numeric, move the token to the end of numeric
				for j=i+1:1:length+1 quit:$e(pExpression,j)'?1N
				do ..addTokenList(.tokenList,$e(pExpression,i,j-1),i)
				set i=j-1
			} elseif char?1(1AZFWCHARZ,1"%") {
				; character is alpha, move the token to the end of alpha-numeric
				for j=i+1:1:length+1 quit:$e(pExpression,j)'?1ANZFWCHARZ
				do ..addTokenList(.tokenList,$e(pExpression,i,j-1),i)
				set i=j-1
			} else {
				; any other character, just this character as a token
				do ..addTokenList(.tokenList,$e(pExpression,i),i)
			}
		}
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	}
	quit tSC
}

ClassMethod addTokenList(tokenList, tokenString, tokenOffset)
{
	set tokenList=$i(tokenList)
	set tokenList(tokenList)=tokenString
	set tokenList(tokenList,"offset")=tokenOffset
	quit
}

ClassMethod getToken(tokenList, tokenCount, tokenString, tokenOffset) As %Boolean
{
	if tokenCount>tokenList set tokenString="",tokenOffset="EOL" quit 0
	set tokenString=tokenList(tokenCount)
	set tokenOffset=tokenList(tokenCount,"offset")
	quit 1
}

Property type As %String(%JSONINCLUDE = "NONE", MAXLEN = "", XMLPROJECTION = "NONE");

Method typeGet() As %String
{
	if ..operator="" {
		quit "value"
	} elseif ..operator'?1.P {
		quit "function"
	} elseif ..operands.Count()=1 {
		quit "unary"
	} else {
		quit "binary"
	}
}

Method constructExpression(pParentOperator = "", pLogicalOnly = 1) As %String
{
	if ..type="value" {
		if (..value="")&&(pParentOperator?1.P) {
			set expression = "("_..value_")"
		} elseif (pLogicalOnly)&&(..isSimpleValue()=0)&&..isBinaryOperator(pParentOperator) {
			set expression = "("_..value_")"
		} elseif (..value=$c(0)) {
			set expression = ""
		} else {
			set expression = ..value
		}
	} elseif ..type="function" {
		if ..isBinaryOperator(..operator)&&(..operands.Count()=2) {
			set expression = ..operands.GetAt(1).constructExpression(..operator,pLogicalOnly) _ " " _ ..operator _ " " _ ..operands.GetAt(2).constructExpression(..operator,pLogicalOnly)
			if ..isUnaryOperator(pParentOperator)||..isBinaryOperator(pParentOperator) set expression="("_expression_")"
		} else {
			set expression=..operator_"("
			for i=1:1:..operands.Count() {
				if i>1 set expression = expression _ ","
				set expression = expression_..operands.GetAt(i).constructExpression(..operator,pLogicalOnly)
			}
			set expression = expression_")"
		}
	} elseif ..type="unary" {
		set expression = ..operator_..operands.GetAt(1).constructExpression(..operator,pLogicalOnly)
		if ..isUnaryOperator(pParentOperator)||..isBinaryOperator(pParentOperator) set expression="("_expression_")"
	} else {
		set expression=""
		for i=1:1:..operands.Count() {
			if i>1 set expression = expression _ ..operator
			set expression = expression_..operands.GetAt(i).constructExpression(..operator,pLogicalOnly)
		}
		if ..isUnaryOperator(pParentOperator)||..isBinaryOperator(pParentOperator) set expression="("_expression_")"
	}
	quit expression
}

Method isSimpleValue() As %Boolean
{
	if ..value="" quit 0
	if $$$ISERR(..parse(..value,.tObject)) quit 0
	quit (tObject.type="value")||((tObject.type="function")&&('..isBinaryOperator(tObject.operator)))
}

ClassMethod convertToCOS(pExpression, pExpressionCOS, variables, isAssignProp As %Boolean = 0) As %Status
{
	set tSC=$$$OK
	try {
		set pExpressionCOS=""
		set tSC=..parseExpression(pExpression,.tObject) quit:$$$ISERR(tSC)
		if $isObject(tObject) {
			if 'isAssignProp { set tSC=tObject.constructCOS(.pExpressionCOS,.variables) }
			else { set tSC=tObject.constructAssign(.pExpressionCOS,.variables) }
			quit:$$$ISERR(tSC)
		}
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	}
	if $$$ISERR(tSC) {
		set tSC=$$$ERROR($$$EnsErrParsingExpression,pExpression,$system.Status.GetErrorText(tSC))
	}
	quit tSC
}

/// variables(name) contains the list of declared variables
Method constructAssign(pExpression, variables) As %Status
{
	set tSC=$$$OK
	try {
		if ..type="value" {
			set pExpression=..value
			if $e(pExpression)?1(1A,1"%") {
				set pExpression="pContext."_pExpression
				for i=1:1:$l(pExpression) {
					if $e(pExpression,i)="." {
						if '$lf($lb("{","(","[","<"),$e(pExpression,i+1)) continue
						set vpBegin=$e(pExpression,i+1),vpEnd=$case($e(pExpression,i+1), "{":"}", "(":")", "[":"]", "<":">"),vpLevel=1
						for j=i+2:1:$l(pExpression) {
							if $e(pExpression,j)=vpBegin set vpLevel=vpLevel+1
							if $e(pExpression,j)=vpEnd   set vpLevel=vpLevel-1
							if vpLevel=0 {
								set:j'=$l(pExpression) tSC=$$$ERROR($$$EnsErrGeneral,"Invalid property for action assign: "_..value)
								quit
							}
						}
						set object=$case($e(pExpression,i+1), "{":$e(pExpression,1,i), :"##class(Ens.Rule.VirtualProperty).")
						set method="SetValueAt"
						set arguments=$case($e(pExpression,i+1), "{":"", :$e(pExpression,1,i-1)_",")_""""_$e(pExpression,i+2,j-1)_""""
						set parenLevel=0, k=1
						for {
							quit:$e(arguments,k)=""
							if $e(arguments,k)="(" {
								set parenLevel = parenLevel+1
								set:parenLevel=1 parenStart = k
							}
							if $e(arguments,k)=")" {
								set parenLevel = parenLevel -1
								if parenLevel = 0 {
									set tIndex = $e(arguments,parenStart+1, k-1)
									If (($f(tIndex,"""_")'=0) && ($f(tIndex,"_""",$f(tIndex,"""_"))'=0)) {
										set tSC=$$$ERROR($$$EnsErrGeneral,"Invalid index value "_tIndex_" in "_..value_". Index value should not contain ""_ and _""")
										quit
									}
									Else {
										if ((tIndex'="") && (tIndex '="*") && (tIndex '= "-")) {
											do ..convertToCOS(tIndex, .result, .variables)
											set $e(arguments,parenStart, k) = "(""_"_result_"_"")"
											set k = k+4+$l(result)
										}
									}
								}
							}
							set k = k+1
						}
						if parenLevel'=0 {
							set tSC=$$$ERROR($$$EnsErrMissingCloseParen,$l(..value)-1)
						}
						quit:$$$ISERR(tSC)
						set pExpression=object_method_"("_","_arguments_")"
					}
				}
			} elseif $e(pExpression)="@" {
				if $d(variables($e(pExpression,2,*))) {
					set pExpression = "tTempVars("""_$e(pExpression,2,*)_""")"
					set i=$l(pExpression)+1
				} else {
					set tSC=$$$ERROR($$$EnsErrTempVariableNotDeclared,$e(pExpression,2,*)) quit
				}
			}
			else {
				set tSC = $$$ERROR($$$EnsErrGeneral,"Invalid property for action assign: "_..value)
				quit
			}
		} 
		else {
			set tSC = $$$ERROR($$$EnsErrGeneral,"Invalid property for action assign: "_..value)
		}
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	}
	quit tSC
}

/// variables(name) contains the list of declared variables
Method constructCOS(pExpression, variables) As %Status
{
	set tSC=$$$OK
	try {
		if ..type="value" {
			set pExpression=..value
			if $e(pExpression)'="""" {
				if $e(pExpression)?1(1AZFWCHARZ,1"%") set pExpression="pContext."_pExpression
				for i=1:1:$l(pExpression) {
					if $e(pExpression,i)="." {
						if '$lf($lb("{","(","[","<"),$e(pExpression,i+1)) continue
						set vpBegin=$e(pExpression,i+1),vpEnd=$case($e(pExpression,i+1), "{":"}", "(":")", "[":"]", "<":">"),vpLevel=1
						for j=i+2:1:$l(pExpression) {
							if $e(pExpression,j)=vpBegin set vpLevel=vpLevel+1
							if $e(pExpression,j)=vpEnd   set vpLevel=vpLevel-1
							if vpLevel=0 quit
						}
						set object=$case($e(pExpression,i+1), "{":$e(pExpression,1,i), :"##class(Ens.Rule.VirtualProperty).")
						set method=$case($e(pExpression,i+1), "{":"GetValueAt", "(":"getParenSyntax", "[":"getSquareSyntax", "<":"getAngelSyntax")
						set arguments=$case($e(pExpression,i+1), "{":"", :$e(pExpression,1,i-1)_",")_""""_$e(pExpression,i+2,j-1)_""""
						set parenLevel=0, k=1
						for {
							quit:$e(arguments,k)=""
							if $e(arguments,k)="(" {
								set parenLevel = parenLevel+1
								set:parenLevel=1 parenStart = k
							}
							if $e(arguments,k)=")" {
								set parenLevel = parenLevel -1
								if parenLevel = 0 {
									set tIndex = $e(arguments,parenStart+1, k-1)
									If (($f(tIndex,"""_")'=0) && ($f(tIndex,"_""",$f(tIndex,"""_"))'=0)) {
										set tSC=$$$ERROR($$$EnsErrGeneral,"Invalid index value "_tIndex_" in "_..value_". Index value should not contain ""_ and _""")
										quit
									}
									Else {
										if ((tIndex'="") && (tIndex '="*") && (tIndex '= "-")) {
											do ..convertToCOS(tIndex, .result, .variables)
											set $e(arguments,parenStart, k) = "(""_"_result_"_"")"
											/* replacing abc(<tIndex>) with abc("_<result>_")
												Moving position of ) by 4 [length of "__"] and
												the difference in length between value of tIndex
												and value of result 
											*/
											set k = k+4+$l(result)-$l(tIndex)
										}
									}
								}
							}
							set k = k+1
						}
						if parenLevel'=0 {
							set tSC=$$$ERROR($$$EnsErrMissingCloseParen,$l(..value)-1)
						}
						quit:$$$ISERR(tSC)
						set pExpression=object_method_"("_arguments_")"_$e(pExpression,j+1)
						set i=j+1
					} elseif $e(pExpression,i)="@" {
						if $d(variables($e(pExpression,2,*))) {
							set pExpression = "tTempVars("""_$e(pExpression,2,*)_""")"
							set i=$l(pExpression)+1
						} else {
							set tSC=$$$ERROR($$$EnsErrTempVariableNotDeclared,$e(pExpression,2,*)) quit
						}
					}
				}
			}
			if pExpression'="" set pExpression="("_pExpression_")"
		} elseif ..type="function" {
			set tSC=##class(Ens.Rule.Utilities).ResolveFunction(..operator,.class,.method)
			#dim tIsCollection = 0
			#dim tIsAssistMethod = 0
			if $$$ISOK(tSC) {
				set pExpression="##class("_class_")."_method_"("
			} elseif "@"=$E(..operator) && ("%" '= $E(..operator,2)) {
				set pExpression=".."_$E(..operator,2,*)_"("
			} elseif ..isValidCollectionsMethod(..operator) {
				#; takes precedence over Rule. and Assist.
				Set tIsCollection = 1
				Set pExpression = ..operator
			} elseif "Rule."=$E(..operator,1,5) {
				#; Note reserved methods defined in isValidCollectionsMethod()
				set pExpression=".."_$E(..operator,6,*)_"("
			} elseif "Assist."=$E(..operator,1,7) {
				#; Note reserved methods defined in isValidCollectionsMethod()
				set tIsAssistMethod = 1
				set pExpression="$classmethod($parameter($this,""RuleAssistClass""),"""_$E(..operator,8,*)_""""
			} else {
				#; Exit with error
				Quit
			}
			for i=1:1:..operands.Count() {
				set tSC=..operands.GetAt(i).constructCOS(.tSubExpression,.variables) quit:$$$ISERR(tSC)
				if i>1 {
					set pExpression = pExpression _ ","
					if tIsCollection {
						#; need to rewrite (1),(2) as (1,2).
						if $e(pExpression,*-1)=")" set $e(pExpression,*-1)=""
						if $e(tSubExpression)="(" set $e(tSubExpression,1)=""
					}
				}
				/*	Add first comma unless the assist method call does
					not include a parameter -..operands.Count() is still 1
					Closing ) will be appended below
				*/
				if tIsAssistMethod && (i=1)&&((tSubExpression'="")||(..operands.Count()>1)) set pExpression = pExpression _ ","
				set pExpression = pExpression_tSubExpression
			}
			#; Error in for loop
			if $$$ISERR(tSC) Quit

			if tIsCollection {
				#; For methods without operands (e.g. Count() we need to put back ())
				if $e(pExpression,*)'=")" set pExpression = pExpression_"()"
				#; Although identified as a function this is a collection property of the context object.
				set pExpression = "pContext."_pExpression
			} else {
				set pExpression = pExpression_")"
			}
		} elseif ..type="unary" {
			set operator=$s(..operator="!":"'",1:..operator)
			set tSC=..operands.GetAt(1).constructCOS(.tSubExpression,.variables) quit:$$$ISERR(tSC)
			set pExpression = "("_operator_tSubExpression_")"
		} else {
			set pExpression=""
			set operator=$s(..operator="!=":"'=",..operator="&":"_",1:..operator)
			for i=1:1:..operands.Count() {
				if i>1 set pExpression = pExpression _ operator
				set tSC=..operands.GetAt(i).constructCOS(.tSubExpression,.variables) quit:$$$ISERR(tSC)
				set pExpression = pExpression_tSubExpression
			}
			if pExpression'="" set pExpression="("_pExpression_")"
		}
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	}
	quit tSC
}

Method makeLogical() As %Status
{
	if (..operator="&&")||(..operator="||") {
		for i=1:1:..operands.Count() do ..operands.GetAt(i).makeLogical()
	} else {
		if ..type'="value" {
			set ..value=..constructExpression()
			set ..operator=""
			do ..operands.Clear()
		}
	}
	quit $$$OK
}

ClassMethod dumpData(tokenData, description)
{
	if $g(^%modebug)'=1 quit
	write !,">>> ",$g(description),!
	;write "total token = ",$g(tokenData,"<undefined>"),!
	set indent=($stack-2)*4
	set sub="" for  {
		set sub=$o(tokenData(sub)) quit:sub=""
		write ?indent,sub,?(indent+5),tokenData(sub),?(indent+10)
		for node="" for  set node=$o(tokenData(sub,node)) quit:node=""  write "  ",node,":",tokenData(sub,node)
		write !
	}
}

/// This method returns 1 if the expression's intepretation is changed under the new operator precedence order
ClassMethod IsInterpretationChanged(pExpression, pInterpretationOld, pInterpretationNew) As %Boolean
{
	set tIsChanged = 0
	try {
		set tSC=..parseExpression(pExpression,.tObject1,1,1) quit:$$$ISERR(tSC)
		set tSC=..parseExpression(pExpression,.tObject2,1,0) quit:$$$ISERR(tSC)
		set pInterpretationOld = tObject1.constructExpression()
		set pInterpretationNew = tObject2.constructExpression()
		set tIsChanged = (pInterpretationOld'=pInterpretationNew)
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	}
	quit tIsChanged
}

}
