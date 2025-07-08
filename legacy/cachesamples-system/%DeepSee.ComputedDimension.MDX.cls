/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements a computed dimension that uses MDX expressions to resolve members.
Class %DeepSee.ComputedDimension.MDX Extends %DeepSee.ComputedDimension.Base [ System = 4 ]
{

Parameter BEHAVIOR = "MDX";

/// Type reported back to the UI. This determines what type of control to display
/// for filters based on this class.
Parameter DIMTYPE = "mdx";

/// Find the set of members for this computed dimension object satisfying
/// <var>pRollupKey</var> and <var>pRange</var> (if applicable for this implementation).<br/>
/// pMemberList($I(pMemberList)) = $LB(id (expression),name,key,[format])<br/>
Method %OnGetComputedMembersFiltered(ByRef pMemberList, pRollupKey As %String = "", ByRef pRange As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		// ID is MDX expression in this case
		// assume cube %OnGetComputedMembers will do this work
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Find the member with the given key value.
Method %FindComputedMemberByKey(pKey As %String, Output pFlag As %Boolean, Output pMemberName As %String, Output pMemberId As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pFlag = 0
		Set tSC = ..%GetComputedMembers(.tMemberList)
		If $$$ISERR(tSC) Quit

		Set k = $O(tMemberList(""))
		While (k'="") {
			Set tKEY = $LG(tMemberList(k),3)
			if $e(tKEY,1,2)="&[" { // JSL4450
				Set tKEY=$e(tKEY,3,*-1) // strip off &[ and ] the code placed around tKey
			}
			If ($$$UPPER(tKEY)=$$$UPPER(pKey)) {
				Set pMemberId = $LG(tMemberList(k),1)
				Set pMemberName = $LG(tMemberList(k),2)
				Set pFlag = 1
				Quit
			}
			Set k = $O(tMemberList(k))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if <var>pName</var> is a valid member name.
Method %FindComputedMemberByName(pName As %String, Output pFlag As %Boolean, Output pMemberKey As %String, Output pMemberId As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pFlag = 0
		Set tSC = ..%GetComputedMembers(.tMemberList)
		If $$$ISERR(tSC) Quit

		Set k = $O(tMemberList(""))
		While (k'="") {
			Set tName = $LG(tMemberList(k),2)
			If ($$$UPPER(tName)=$$$UPPER(pName)) {
				Set pMemberId = $LG(tMemberList(k),1)
				Set pMemberKey = $LG(tMemberList(k),3)
				Set pFlag = 1
				Quit
			}
			Set k = $O(tMemberList(k))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Execute a search for members.<br/>
/// Return a list of the form:<br/>
/// pList(n) = $LB(value,key)
Method %MemberSearch(pSearchKey As %String, Output pList As %List) As %Status
{
	Quit ..%MemberSearchByMembers(pSearchKey,.pList)
}

/// Resolve any special tokens or expression in a key value and return the result.
Method %ResolveKey(pSpec As %String, Output pRKey As %String) As %Status
{
	// add this method in JSL4450
	Set tSC = $$$OK
	Set pRKey = "&["_pSpec_"]"
	Quit tSC
}

}
