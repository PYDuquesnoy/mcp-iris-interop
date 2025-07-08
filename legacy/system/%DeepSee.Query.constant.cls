/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines a constant within a DeepSee query.<br/>
Class %DeepSee.Query.constant Extends node [ System = 3 ]
{

/// Axis label used for this constant.
Property label As %DeepSee.Datatype.string(XMLPROJECTION = "attribute") [ InitialExpression = "Constant" ];

/// Format string to apply to this member.
Property formatString As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Internal flag used for subquery functions--true means that the subquery has run and this value is the result
/// of the query.
Property finalValue As %Boolean(XMLPROJECTION = "none") [ InitialExpression = 0 ];

/// If the value is a finalValue, this is used to remember the original value of the constant.
Property origValue As %String(XMLPROJECTION = "none");

/// If known, this is the type of the constant: "string" or "number".<br/>
/// This is used to keep track of string numerics: "123" v 123.
Property type As %String(XMLPROJECTION = "none");

/// If our value is a named parameter, resolve it.<br/>
/// We do this as soon as we are first asked for our value and then
/// we hold onto the resolved value.
Method %ResolveValue() As %Status
{
	Set tParmName = $E(..value,2,*)
	Set tSC = %query.%ResolveNamedParm(tParmName, .tText)
	Set ..value = tText
	Quit tSC
}

/// Return the type of this node.<br/>
Method %GetType() As %String
{
	Do:($E(..value)="@") ..%ResolveValue()

	// JMD1373
	If (..type="string") {
		Quit $$$dstString
	}

	// return type of value
	Quit $S(..value=(..value\1):$$$dstInteger,$IsValidNum(..value):$$$dstValue,1:$$$dstString)
}

/// Convert this node to its text representation.
Method %ToString(Output pSC As %Status) As %String
{
	Set pSC = $$$OK
	If (..finalValue) {
		// If we are creating a subquery we want to emit the original value, if present
		If +$G(%dsUseOrigValue) {
			Quit $$$quote(..origValue)
		}
	}

	If ($E(..value)="@")&&'$D(%dsQueryPrepare) {
		Set pSC = ..%ResolveValue()
	}
	Set tText = $$$quote(..value)

	// JMD1373
	If ((..type="string")&&$IsValidNum(tText)) {
		Set tText = """"_tText_""""
	}
	Quit tText
}

/// Execute and build the axes output for this constant.
Method %ProcessAxes(pCube As %String, pKey As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer, pVisible As %Boolean = 1) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Do:($E(..value)="@") ..%ResolveValue()

		// tSet = $LB(type,visible,calc,parent,value,key,fact,agg)
		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("lit",pVisible,1,pParent,..label,..value)

		Set:..formatString'="" $List($$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pNodeNo),12) = ..formatString

		Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
		Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",%axis,"all",pNodeNo) = ""
		Set pNewNodeNo = pNodeNo
		Set leaf = $I(%leafCount)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Process the filter output for this constant.
Method %ProcessFilter(ByRef pFilterTree As %List, pCube As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pFilterTree($I(pNodeNo)) = $LB("lit",..value)
		Set pFilterTree(pParent,"ch",pNodeNo) = ""
		Set pNewNodeNo = pNodeNo
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

}
