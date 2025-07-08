/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines a function within a DeepSee query.<br/>
/// The actual behavior of functions is implemented within the subclasses of this class.
Class %DeepSee.Query.function Extends group [ Abstract, System = 3 ]
{

/// Used to indicate which class of functions this class supports.
Parameter FUNCTIONCLASS As STRING;

/// Name of the function.
Property function As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// Label to display for the function (used internally).
Property label As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// Handle of subquery for this function (if needed).
Property subqueryKey As %Integer(XMLPROJECTION = "none");

/// Make sure function table global is deleted whenever the function class is compiled.
Method %KillFunctionTable() As %String [ CodeMode = objectgenerator, Internal, Private ]
{
	Kill $$$DeepSeeFunctionGLVN
	Do %code.WriteLine(" Kill $$$DeepSeeFunctionGLVN")
	Quit $$$OK
}

/// Return a version number for the metadata.
ClassMethod %GetFunctionVersionNo() As %Integer [ CodeMode = objectgenerator, Internal, Private ]
{
	Do %code.WriteLine(" Quit " _ $R(10000000))
	Quit $$$OK
}

/// Return type of this node.
Method %GetType() As %String
{
	Set tType = $$$dstSet
	If (..function '= "") {
		Set tExists =..%GetFunctionInfo(..function,.tIsImplemented, .tArgCount, .tReturns, .tArgs, .tArgDesc)
		If (tExists) {
			Set tType = tReturns
		}
	}
	Quit tType
}

/// Convert a ds Type to a printable string.
/// Used for error reporting.
ClassMethod %TypeFlagToString(pTypeFlag) As %String
{
	Quit $Case(pTypeFlag,
			$$$dstInteger:"integer",
			$$$dstValue:"value",
			$$$dstString:"string",
			$$$dstFlag:"flag",
			$$$dstLevel:"level",
			$$$dstHierarchy:"hierarchy",
			$$$dstDimension:"dimension",
			$$$dstMember:"member",
			$$$dstMeasure:"measure",
			$$$dstSet:"set",
			$$$dstExpression:"expression",
			:pTypeFlag)
}

/// Test if function metadata is in the DeepSeeFunctionGLVN global.
/// If not, put it there.
ClassMethod %BuildFunctionMetaData() As %Status
{
	Quit $$$OK
}

/// Return meta-data for the function <var>pFunction</var>.
/// Returns true if the function exists.<br/>
/// On return,
/// <var>pIsImplemented</var> if the function is implemented.<br/>
/// <var>pArgCount</var> returns the number of required arguments the function expects
/// or "" if this function does not take arguments.<br/>
/// <var>pReturns</var> is the return type.<br/>
/// <var>pArgTypes</var> is a list of argument types for the function.<br/>
/// <var>pArgDesc</var> is a list of argument descriptors for the function.<br/>
ClassMethod %GetFunctionInfo(pFunction As %String, Output pIsImplemented As %Boolean, Output pArgCount As %Integer, Output pReturns As %String, Output pArgTypes As %List, Output pArgDesc As %List) As %Boolean [ Final ]
{
	Set tFound = 0
	Set tSC = ..%BuildFunctionMetaData()
	Set pIsImplemented = 0
	Set pReturns = ""
	Set pArgTypes = ""
	Set pArgDesc = ""
	Set pArgCount = ""

	If ($$$ISOK(tSC)) {
		Set tClass = ..#FUNCTIONCLASS
		If ($D($$$DeepSeeFunctionGLVN(tClass,$$$UPPER(pFunction)))) {
			Set tInfo = $$$DeepSeeFunctionGLVN(tClass,$$$UPPER(pFunction))
			Set tFound = 1
			Set pIsImplemented = +$LG(tInfo,1)
			Set pReturns = $LG(tInfo,2)
			Set pArgTypes = $LG(tInfo,3)
			Set pArgDesc = $LG(tInfo,4)
			If (pArgDesc'="") {
				If (($LL(pArgDesc)>1)||($LG(pArgTypes,1)'="M")) {
					Set pArgCount = 0
					For n=1:1:$LL(pArgTypes) {
						Set t = $P($LG(pArgDesc,n),":",1)
						If ((t=1)||(t="S")||(t="X")) {
							Set pArgCount = pArgCount + 1
						}
					}
				}
			}
		}
	}
	Quit tFound
}

/// Return a string containing the signature for the given function
/// (used for error messages).
ClassMethod %GetFunctionSignature(pFunction As %String) As %String [ Final ]
{
	Set tSignature = ""
	Set tExists =..%GetFunctionInfo(pFunction,.tIsImplemented,.tArgCount,.tReturn,.tArgs,.tArgDesc)
	If (tExists) {
		Set tHasParen = 0
		Set tFirstArg = 1
		Set tSignature = pFunction
		If (tArgDesc '= "") {
			Set tSignature = ""
			For n = 1:1:$LL(tArgDesc) {
				Set tArgT = $LG(tArgs,n)
				Set tArgD = $LG(tArgDesc,n)
				Set tFlags = $P(tArgD,":",2)
				Set tArgD = $P(tArgD,":",1)
				If ((n = 1)&&(tArgD = "M")) {
					Set tSignature = "Member." _ pFunction
				}
				Else {
					If (tSignature = "") {
						Set tSignature = pFunction
					}
					If ('tHasParen) {
						Set tSignature = tSignature _ "("
						Set tHasParen = 1
					}
					Set tSignature = tSignature _ $S(tFirstArg:"",1:",") _ $Case(tArgD,0:"[",:"") _$$GetType(tArgT,tFlags)_ $Case(tArgD,0:"]",:"")
					Set tFirstArg = 0
				}
			}
			Set:tHasParen tSignature = tSignature _ ")"
		}

		Set tReturnType = $$GetType(tReturn,"")
		If (tReturnType '= "") {
			Set tSignature = tSignature _ " AS " _ tReturnType
		}
	}

	Quit tSignature

	Set (type,flags)=""
GetType(type,flags)
	If (type = $$$dstFlag) {
		Quit $TR(flags,",","|")
	}

	Quit $Case(type,
		$$$dstSet:"SET",
		$$$dstValue:"NUMBER",
		$$$dstInteger:"INTEGER",
		$$$dstString:"STRING",
		$$$dstExpression:"EXPRESSION",
		$$$dstMember:"MEMBER",
		$$$dstDimension:"MEMBER",
		$$$dstHierarchy:"MEMBER",
		$$$dstLevel:"LEVEL",
		:"")
}

}
