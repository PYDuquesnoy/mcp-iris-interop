/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKCompiler

Class %iKnow.Compiler.GotoFunction Extends %RegisteredObject [ Deprecated, System = 4 ]
{

Property StatesGlobal As %String [ MultiDimensional ];

Property NextState As %Integer [ InitialExpression = 1 ];

Property RegexEnabled As %Boolean [ InitialExpression = 0 ];

Property RegexDictionary As RegexDictionary;

Method AddTransition(curState As %Integer, char As %String) As %Integer
{
	Set nextState = $G(..StatesGlobal("GoTo", curState, char))
	If 'nextState {
		Set nextState = ..GetNextState()
		Do ..Set(curState, char, nextState)
	}
	Quit nextState
}

/// Produces a list of alternatives of the form (a|b|cd)
ClassMethod ParseAlternatives(ByRef input As %String) As %List
{
	Set len = $L(input)
	Set depth = 1 //the leading "("
	Set token = ""
	Set tokenList = ""
	Set escaped = 0
	For i=2:1:len {
		Set char = $E(input,i)
		
		//Process regexp characters
		If 'escaped {
			If char = "(" {
				Set depth = depth + 1
			}
			ElseIf char = ")" {
				Set depth = depth - 1
			}
			ElseIf (char = "|") && (depth = 1) {
				Set tokenList = tokenList _ $LB(token)
				Set token = ""
				Continue
			}
			ElseIf (char = "\") {
				Set escaped = 1
				Continue
			}
		}
		
		//Add character to current token
		Set escaped = 0
		If depth '= 0 {
			Set token = token _ char
		}
		Else {
			Set tokenList = tokenList _ $LB(token)
			Set token = ""
			Quit
		}
	}
	If depth '= 0 Throw ##class(%Exception.SystemException).%New("Mismatched Parentheses")
	Set input = $E(input, i+1,*)
	Quit tokenList
}

Method ConsumeInput(state As %Integer, input As %String, outputObj As %RegisteredObject, curToken As %String = "", escaping As %Boolean = 0)
{
ConsumeInputStart
	If $L(input) = 0 {
		// $$$AddOutputAtInline(outputObj,state,curToken)
		// #define AddOutputAtInline(%outputObj,%state,%curToken)
	Set IKCValue = outputObj.GetValue(curToken) 													
	Set IKCKey = $ORDER(outputObj.OutputFunc.StatesGlobal("Output",state,""), 1, IKCEValue)		
	While IKCKey '= "" {	
		W !,"double["_curToken_"]"																				
		If IKCValue = IKCEValue Quit
		W !,"a real double["_IKCEValue_"]"																
		Set IKCKey = $ORDER(outputObj.OutputFunc.StatesGlobal("Output",state,IKCKey), 1, IKCEValue)
	}																								
	If IKCValue '= $G(IKCEValue) {																
		Set IKCKey = $G(outputObj.OutputFunc.StatesGlobal("Output",state), 0)				
		Set outputObj.OutputFunc.StatesGlobal("Output", state, IKCKey) = IKCValue
		If outputObj.OutputFunc.MaxState < state Set outputObj.OutputFunc.MaxState = state
		Set outputObj.OutputFunc.StatesGlobal("Output", state) = IKCKey + 1
	}

		Quit
	}
	Set remainingInput = $E(input, 2, *)
	Set char = $E(input,1)
	If (char = "\") && ..RegexEnabled {
		Do ..ConsumeInput(state, remainingInput, outputObj, curToken, 1)
		Quit
	}
	If (char = "(") && ..RegexEnabled && 'escaping {
		Set rest = input
		Set alternatives = ..ParseAlternatives(.rest)
		Set len = $LL(alternatives)
		For i=1:1:len {
			Set case = $LI(alternatives, i)
			Do ..ConsumeInput(state, case _ rest, outputObj, curToken)
		}
		Quit
	}
	If (char = "{") && ..RegexEnabled && 'escaping {
		Set regexName = $PIECE(remainingInput, "}", 1)
		//A pseudo-char for the regex
		Set char = "{"_regexName_"}"
		Set remainingInput = $PIECE(input, "}",2,*)
	}
	// $$$AddTransitionInline(state,char,nextState)
	// #define AddTransitionInline(%state,%char,%nextState) 											
	Set nextState = $G(..StatesGlobal("GoTo", state, char)) 									
	If 'nextState {																				
		Set nextState = ..NextState																
		Set ..NextState = nextState + 1															
		Set ..StatesGlobal("GoTo", state, char) = nextState										
		Set IKCdepth = $G(..StatesGlobal("Depth", state)) + 1									
		Set ..StatesGlobal("Depth", nextState) = IKCdepth				
		Set ..StatesGlobal("DepthMap", IKCdepth - 1, state, char, nextState) = ""
	}
	
	Set state = nextState, input = remainingInput, curToken = curToken _ char
	Goto ConsumeInputStart
}

Method AddWord(word As %String, stateOutputFunction As StateOutputFunction)
{
		Do ..ConsumeInput(0, word, stateOutputFunction)
}

Method Set(state As %Integer, input As %String, nextState As %Integer)
{
		Set ..StatesGlobal("GoTo", state, input) =  nextState
		//Record depth
		Set depth = $G(..StatesGlobal("Depth", state)) + 1
		Set ..StatesGlobal("Depth", nextState) = depth
		//Depth map: We need states sorted by depth to build the failure function
		Set ..StatesGlobal("DepthMap", depth - 1, state, input, nextState) = ""
}

Method Get(state As %Integer, input As %String) As %Integer
{
		Set next = $G(..StatesGlobal("GoTo", state, input))
		If (next = "") && (state = 0) Quit 0 //0-state loops back
		Quit next
}

Method GetNextState()
{
	
		Set state = ..NextState
		Set ..NextState = state + 1
		Quit state
}

Method DepthOrder(ByRef depth As %String, ByRef state As %String, ByRef input As %String, ByRef nextState As %String)
{
	//Allow an empty depth to start
	If depth = "" Goto Depth
NextState 
	Set nextState = $ORDER(..StatesGlobal("DepthMap", depth, state, input, nextState))
	If nextState '= "" Quit
Input
	Set input = $ORDER(..StatesGlobal("DepthMap", depth, state, input))
	If input '= "" Goto NextState
State
	Set state = $ORDER(..StatesGlobal("DepthMap", depth, state))
	If state '= "" Goto Input
Depth
	Set depth = $ORDER(..StatesGlobal("DepthMap", depth))
	If depth '= "" Goto State
	//If we fell all the way through, everything is empty and we're done ordering
}

/// From a binary string "01101100" to a hex string "0xEB"
ClassMethod ToHex(bin As %String)
{
	Set high = $E(bin,1,4)
	Set low = $E(bin,5,8)
	Set highB = $SELECT(high="0000":0,high="0001":1,high="0010":2,high="0011":3,high="0100":4,high="0101":5,high="0110":6,high="0111":7,high="1000":8,high="1001":9,high="1010":"A",high="1011":"B",high="1100":"C",high="1101":"D",high="1110":"E",high="1111":"F")
	Set lowB = $SELECT(low="0000":0,low="0001":1,low="0010":2,low="0011":3,low="0100":4,low="0101":5,low="0110":6,low="0111":7,low="1000":8,low="1001":9,low="1010":"A",low="1011":"B",low="1100":"C",low="1101":"D",low="1110":"E",low="1111":"F")
	Quit "0x"_highB_lowB
}

Method ToC(dir As %String = "")
{
	Set maxState = ..NextState
	Kill AryZeroStateMap
	Kill AryOneStateMap
	Kill AryNextStateMap
	Kill ArySymbolMap
	Kill AryTransitionMap
	
	Kill AryRegexOneStateMap
	Kill AryRegexNextStateMap
	Kill AryRegexNameMap
	Kill AryRegexTransitionMap
	
	Set TotalTransitions = 0
	Set SymbolMapIndex = 0
	Set RegexMapIndex = 0
	Kill AryRegexId
	Kill AryIdRegex
	Set AryIdRegex = 0
	For i=0:1:maxState {
		//Build a char-code sorted map, as the CharToState
		//values must be sorted.
		Kill AryCharStateMap
		//Build a regex map
		Kill AryRegexStateMap
		Set charCount = 0
		Set regexCount = 0
		Set nextState = ""
		Set char = $ORDER(..StatesGlobal("GoTo", i, ""),1,nextState)
		While char '= "" {
			Set TotalTransitions = TotalTransitions + 1
			//Ordinary characters
			If $L(char) = 1 {
				Set charCount = charCount + 1
				Set AryCharStateMap($A(char)) = nextState
			}
			//Regular expression
			Else {
				Set regexCount = regexCount + 1
				//Note the transition
				Set AryRegexStateMap(char) = nextState
				//Add an entry to the regex id map if not present
				If $G(AryRegexId(char)) = "" {
					Set id = AryIdRegex
					Set AryRegexId(char) = id
					Set AryIdRegex(id) = char
					Set AryIdRegex = id + 1
				}
			}
			Set char = $ORDER(..StatesGlobal("GoTo", i, char),1,nextState)
		}
		If charCount = 0 {
			Set AryZeroStateMap(i) = 1
			Set AryOneStateMap(i) = 0
			Set AryNextStateMap(i) = 0
		}
		Else {
			Set AryZeroStateMap(i) = 0
			If (charCount) = 1 {
				Set AryOneStateMap(i) = $O(AryCharStateMap(""))
				Set AryNextStateMap(i) = AryCharStateMap(AryOneStateMap(i))
			}
			Else {
				Set AryOneStateMap(i) = "kNullSymbol"
				Set AryNextStateMap(i) = ..MakeNextState(SymbolMapIndex, charCount)
				Set char = $ORDER(AryCharStateMap(""))
				While char '= "" {
					Set state = AryCharStateMap(char)
					Set ArySymbolMap(SymbolMapIndex) = char
					Set AryTransitionMap(SymbolMapIndex) = state
					Set SymbolMapIndex = SymbolMapIndex + 1
					Set char = $ORDER(AryCharStateMap(char))
				}
			}
		}
		
		//Just like the characters for the regexes.
		If regexCount = 0 {
			Set AryRegexOneStateMap(i) = "kNullOffset"
			Set AryRegexNextStateMap(i) = 0
		}
		ElseIf regexCount = 1 {
			Set regex = $O(AryRegexStateMap(""))
			Set regexId = AryRegexId(regex)
			Set AryRegexOneStateMap(i) = regexId + 1 //So 0 is special
			Set AryRegexNextStateMap(i) = AryRegexStateMap(regex)
		}
		Else {
			Set AryRegexOneStateMap(i) = "kNullOffset"
			Set AryRegexNextStateMap(i) = ..MakeNextState(RegexMapIndex, regexCount)
			Set regex = $ORDER(AryRegexStateMap(""))
			While regex '= "" {
				Set state = AryRegexStateMap(regex)
				Set AryRegexNameMap(RegexMapIndex) = AryRegexId(regex)
				Set AryRegexTransitionMap(RegexMapIndex) = state
				Set RegexMapIndex = RegexMapIndex + 1
				Set regex = $ORDER(AryRegexStateMap(regex))
			}
			
		}
	}

	//Skip writing the Zero state map, no efficiency gain at this time
	Do ##class(Util).OutputToFile(dir _ "/OneStateMap.inl")
	Set buf = ""
	for i=0:1:maxState {
		Set buf = buf _ AryOneStateMap(i) _ ","
		If '(i#256) Write buf,! Set buf = ""
	}
	Write buf
	Write "Symbol()",! //At least one.
	Do ##class(Util).OutputToFile(dir _ "/NextStateMap.inl")
	Set buf = ""
	For i=0:1:maxState {
		//The behavior of large unsigned literals that wouldn't fit inside
		//signed integers is tricky, and some compilers warn about it, so we
		//mark them explicitly unsigned
		Set buf = buf _ AryNextStateMap(i)_"U"_","
		If '(i#256) Write buf,! Set buf = ""
	}
	Write buf
	Write "SmallState()",! //At least one
	Do ##class(Util).OutputToFile(dir _ "/SymbolMap.inl")
	Set buf = ""
	for i=0:1:SymbolMapIndex-1 {
		Set buf = buf _ ArySymbolMap(i)_","
		If '(i#256) Write buf,! Set buf = ""
	}
	Write buf
	Write "Symbol()",! //At least one
	Do ##class(Util).OutputToFile(dir _ "/StateMap.inl")
	Set buf = ""
	for i=0:1:SymbolMapIndex-1 {
		Set buf = buf _ AryTransitionMap(i)_","
		If '(i#256) Write buf,! Set buf = ""
	}
	Write buf
	Write "SmallState()",! //At least one
	
	//Regexes
	If ..RegexEnabled {
		Do ##class(Util).OutputToFile(dir _ "/RegexObjs.inl")
		For i=0:1:AryIdRegex - 1 {
			Set regex = AryIdRegex(i)
			Set regexName = $E(regex,2,*-1) //remove {}
			Set pattern = ..RegexDictionary.Lookup(regexName)
			If pattern = "" Throw ##class(%Exception.SystemException).%New("Unknown regex specified.")
			Write "static const Char Regex"_i_"Str[] = {"
			For j=1:1:$L(pattern) {
				W $A(pattern, j)_", "
			}
			Write "}; // """_ pattern _ """", !
		}
		Write !
		Do ##class(Util).OutputToFile(dir _ "/RegexMap.inl")
		For i=0:1:AryIdRegex - 1 {
			Set regex = AryIdRegex(i)
			Set regexName = $E(regex,2,*-1) //remove {}
			Set pattern = ..RegexDictionary.Lookup(regexName)
			Write "Regex(String(Regex"_i_"Str, "_$L(pattern)_")), "
			If '(i+1#4) Write !
		}
		Write "Regex()",! //Avoid 0-length array
		Do ##class(Util).OutputToFile(dir _ "/RegexOneStateMap.inl")
		If $G(AryIdRegex) > 0 {
			for i=0:1:maxState {
				Write AryRegexOneStateMap(i)_", "
				If '(i+1#4) Write !
			}	
		}
		Else {
			Write "0"
		}
		Write !
		Do ##class(Util).OutputToFile(dir _ "/RegexNextStateMap.inl")
		If $G(AryIdRegex) > 0 {
			for i=0:1:maxState {
				//The behavior of large unsigned literals that wouldn't fit inside
				//signed integers is tricky, and some compilers warn about it, so we
				//mark them explicitly unsigned
				Write AryRegexNextStateMap(i),"U, "
				If '(i+1#4) Write !
			}
		}
		Else {
			Write "0"
		}
		Write !
		Do ##class(Util).OutputToFile(dir _ "/RegexOffsetMap.inl")
		for i=0:1:RegexMapIndex-1 {
			Write AryRegexNameMap(i),", "
			If '(i+1#8) Write !
		}
		Write "0",! //avoid 0-sized array
		Do ##class(Util).OutputToFile(dir _ "/RegexStateMap.inl")
		for i=0:1:RegexMapIndex-1 {
			Write AryRegexTransitionMap(i),", "
			If '(i+1#8) Write !
		}
		Write "0",! //avoid 0-sized array		
	}
	Close $IO
	Write "Total transitions ("_dir_"): " _ TotalTransitions,!
	Write "Total states ("_dir_"): " _ ..NextState,!
}

/// "NextState" values are 32-bits, split between an offset into the State/SymbolMap tables
/// and a size.
ClassMethod MakeNextState(offset As %Integer, size As %Integer) As %Integer [ Private ]
{
	If offset > (2**20) Throw ##class(%Exception.SystemException).%New()
	If size > (2**12) Throw ##class(%Exception.SystemException).%New()
	Quit $ZBOOLEAN(offset, size * (2 ** 20), 7) //logical OR
}

}
