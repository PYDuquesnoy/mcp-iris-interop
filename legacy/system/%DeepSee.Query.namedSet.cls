/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This represents a named set within an MDX query.
Class %DeepSee.Query.namedSet Extends set [ System = 3 ]
{

/// Name of this named set.
Property name As %DeepSee.Datatype.string(MAXLEN = 1000, XMLPROJECTION = "attribute");

/// Original definition of this named set.
/// Used when creating subqueries.
Property definition As %DeepSee.Datatype.string(MAXLEN = 1000, XMLPROJECTION = "none");

/// This specifies where this named set was defined.
Property origin As %DeepSee.Datatype.string(MAXLEN = 50, VALUELIST = ",query,cube,session", XMLPROJECTION = "none") [ InitialExpression = "query", Internal ];

/// Return the member provider object associated with this node.
Method %GetMemberProvider() As %DeepSee.Query.member
{
	Set tChild = ..children.GetAt(1)
	If ($IsObject(tChild)) {
		Quit tChild.%GetMemberProvider()
	}
	Quit ""
}

/// Convert this node to its text representation.
/// Note, this is assumed to be called from the context of an axis or slicer
/// so it returns the name of the named set itself and not its definition.
Method %ToString(Output pSC As %Status) As %String
{
	Set pSC = $$$OK
	Quit "["_..name_"]"
}

/// Execute and build the axes output for this set.
Method %ProcessAxes(pCube As %String, pKey As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer, pVisible As %Boolean = 1) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// add node to axis tree
		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("set",0,0,pParent)
		Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",pParent,"ch",pNodeNo) = ""
		Set tSetNode = pNodeNo
		Set pNewNodeNo = pNodeNo

		Set tChildCount = ..children.Count()
		For n=1:1:tChildCount {
			Set tChild = ..children.GetAt(n)
			Set tSC = tChild.%ProcessAxes(pCube,pKey,.pNodeNo,.tNewNodeNo,tSetNode,pVisible)
			If $$$ISERR(tSC) Quit
		}
		If $$$ISERR(tSC) Quit

		// DP-421810 - reduce this node
		Set tSC = ..%ReduceNode(tCubeIndex,pKey,tSetNode)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

}
