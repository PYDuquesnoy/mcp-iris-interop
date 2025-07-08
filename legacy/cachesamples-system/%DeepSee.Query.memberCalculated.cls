/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specialized version of the member class used for calculated members.<br/>
/// A calculated member is defined using the WITH clause of a query or
/// in the calculatedMember section of a cube definition.<br/>
/// This provider is used in the cases where there is a calculated member for a dimension
/// that is not defined as an actual dimension. Its only function is to indicate the
/// presence of a calculated member.
Class %DeepSee.Query.memberCalculated Extends member [ System = 3 ]
{

/// Find the member with the given key.
/// In this case, the key and value are the same.
Method %FindMemberByKey(pKey As %String, pDim As %Integer, pHier As %Integer, Output pFlag As %Boolean, Output pMemberValue As %String, pRecurse As %Boolean = 1) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pFlag = 1
		Set pMemberValue = pKey
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if <var>pName</var> is a valid member name.
Method %FindMemberByName(pName As %String, pDim As %Integer, pHier As %Integer, Output pFlag As %Boolean, pLevel As %Integer = "", Output pMemberKey As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// If we get here, we already know this is not a member!
		Set pFlag = 0
		Set pMemberKey = ""
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Set the state of this member using the current meta data node.
Method %ApplyState(pType As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..%type = pType
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if this member supports the given function.
Method %SupportsFunction(pFunction As %String, Output pMessage As %String) As %Boolean
{
	Set pMessage = "Functions are not allowed on calculated members"
	Quit 0
}

}
