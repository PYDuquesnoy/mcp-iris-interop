/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines a function flag within a DeepSee query.<br/>
Class %DeepSee.Query.flag Extends node [ System = 3 ]
{

/// Return the type of this node.<br/>
Method %GetType() As %String
{
	Quit $$$dstFlag
}

/// Convert this node to its text representation.
Method %ToString(Output pSC As %Status) As %String
{
	Set pSC = $$$OK
	Quit ..value // not quoted
}

/// Execute and build the axes output for this node.
Method %ProcessAxes(pCube As %String, pKey As %String, ByRef pNodeNo As %Integer, Output pNewNodeNo As %Integer, pParent As %Integer, pVisible As %Boolean = 1) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tCubeIndex = $$$DeepSeeIndex(pCube)
		// tSet = $LB(type,visible,calc,parent,value,key,fact,agg)
		Set $$$DeepSeeAxisGLVN(tCubeIndex,pKey,"axes",$I(pNodeNo)) = $LB("flag",0,0,pParent,"flag",..value)
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

}
