/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

Class %iKnow.DeepSee.Dimensions.Base Extends %DeepSee.ComputedDimension.Base [ Abstract, Deprecated, System = 4 ]
{

Parameter CACHECOMPUTEDBITSET = "CHECK";

Property %ikDomainId As %Integer [ InitialExpression = -1 ];

Property %ikMeasure As %String;

Property %ikDomainType As %String(VALUELIST = "DeepSee,iKnow");

Parameter MAXRESULTS [ Internal ] = 100;

Parameter COMBINATIONLOGIC [ Internal ] = "OR";

ClassMethod %Create(pCube As %String, pFactNo As %Integer, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %DeepSee.ComputedDimension.Base
{
	set tObj = ##super(pCube, pFactNo, pDimNo, pHierNo, pLevelNo)
	
	set tObj.%ikMeasure = tObj.%factName
	set tSC = ##class(%iKnow.DeepSee.CubeUtils).GetMeasureInfo(pCube, tObj.%ikMeasure, .tSourceType, .tDomainId, .tDomainName, .tDomainType)
	set tObj.%ikDomainId = +tDomainId, tObj.%ikDomainType = tDomainType
	
	quit tObj
}

/// Return the type of this class (used by UI components).
ClassMethod %GetDimType() As %String
{
	quit "iknow"
}

/// If this represents multiple keys, use a hash, otherwise use the simple ID
Method %ComputeIndexKey(pMemberKey As %String) As %String
{
	if ($f(pMemberKey,",")) {
		quit pMemberKey //$zcrc(pMemberKey,7)  TODO: why does this break with $zcrc?
	} else {
		set tIndexKey = $p(pMemberKey,":",$l(pMemberKey,":"))
		quit:tIndexKey="" 0
		quit tIndexKey
	}
}

Method %FindComputedMemberByKey(pKey As %String, Output pFlag As %Boolean, Output pMemberName As %String, Output pMemberId As %String) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		set tKeyCount = $l(pKey,","), tFlags = 0, pFlag = 0, pMemberName = "", pMemberId = ""
		for i=1:1:tKeyCount {
			set tSC = ..%FindComputedMemberByKeyInternal($p(pKey,",",i), .tFlag, .tName, .tId, 0)
			quit:$$$ISERR(tSC)
			set tFlags = tFlags + tFlag
			set pMemberName = pMemberName _ "," _ tName
			set pMemberId = pMemberId _ "," _ tId
		}
		quit:$$$ISERR(tSC)
		set pMemberName = $e(pMemberName,2,*)
		set pMemberId = $e(pMemberId,2,*)
		
		set tSC = ..%ComputeBitset(pKey, .tIndexKey)
		quit:$$$ISERR(tSC)
		
		set pFlag = (tFlags>0)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %FindComputedMemberByKeyInternal(pKey As %String, Output pFlag As %Boolean, Output pMemberName As %String, Output pMemberId As %String, pComputeBitset As %Boolean = 1) As %Status [ Abstract, Internal, Private ]
{
}

/// Method combining the functionality of <method>%MemberSearch</method> and
/// <method>%OnGetComputedMembersFiltered</method> to avoid having the same code twice.<br/>
/// Returns entries of the form:<br/>
/// 		pMembers(n) = $lb(id, name, key)<br/>
/// Expects any predefined dimension members to supplied with <var>pMemmbers</var> upfront!
Method %OnGetComputedMembersInternal(ByRef pMembers, pSearchKey As %String = "", pRollupKey As %String = "", ByRef pRange As %String = "") As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		
	} catch(ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Workaround until PL96734 is sorted<br/>
/// NOTE: forwards to <method>%OnGetComputedMembersInternal</method>
Method %OnGetComputedMembers(ByRef pMemberList) As %Status
{
	quit ..%OnGetComputedMembersInternal(.pMemberList)
}

/// Find the set of members for this computed dimension object.<br/>
/// pMemberList(n) = $LB(id,name,key)<br/>
/// The top node of <var>pMemberList</var> will contain the next value of n to use.<br/>
/// NOTE: forwards to <method>%OnGetComputedMembersInternal</method>
Method %OnGetComputedMembersFiltered(ByRef pMemberList, pRollupKey As %String = "", ByRef pRange As %String = "") As %Status
{
	quit ..%OnGetComputedMembersInternal(.pMemberList,, pRollupKey, .pRange)
}

/// Execute a search for members.<br/>
/// Return a list of the form:<br/>
/// pList(n) = $LB(value,key)<br/>
/// NOTE: forwards to <method>%OnGetComputedMembersInternal</method>
Method %MemberSearch(pSearchKey As %String, Output pList As %List) As %Status
{
	set tSC = $$$OK
	try {
		// starts empty
		kill pList
		
		// first populate pMembers with any predefined <member> elements
		set tSC = ..%GetPredefinedMembers(.pList, ..%baseCube, ..%dimNumber, ..%hierNumber, ..%levelNumber)
		quit:$$$ISERR(tSC)
		
		// now forward to %OnGetComputedMembersInternal
		set tSC = ..%OnGetComputedMembersInternal(.pList, pSearchKey)
		
		// finally transform the results in %MemberSearch style
		set i = ""
		for {
			set i = $order(pList(i), 1, tData)
			quit:i=""
			
			// temp workaround for PL 96607
			set pList(i) = $lb($li(tData,2), "&["_$li(tData,1)_"]")
			//set pList(i) = $lb($li(tData,2), $li(tData,1))
		}
		
	} catch(ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns the current query context (as per <method>%GetCurrentQuery</method>) in the form
/// of a <class>%iKnow.Filters.Filter</class> object.
Method %GetQueryContextFilter(Output pSC As %Status) As %iKnow.Filters.Filter [ Private ]
{
	set pSC = $$$OK, tContextFilter = ""
	try {
		set tQuery = ..%GetCurrentQuery()
		quit:(tQuery="")||'$isobject(tQuery.slicer)

		// avoid nested calls (should be very unlikely)
		quit:$d(^IRIS.Temp.IKDS.ContextFilter(tQuery.%QueryKey))
		 
		set ^IRIS.Temp.IKDS.ContextFilter(tQuery.%QueryKey) = 1
		set tContextFilter = ##class(%iKnow.DeepSee.MDXFilter).%New(..%ikDomainId, tQuery.slicer.%ToString(), ..%cube, ..%ikMeasure)
		if (tContextFilter="") { set pSC = %objlasterror }
		kill ^IRIS.Temp.IKDS.ContextFilter(tQuery.%QueryKey)
		quit:$$$ISERR(pSC)
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tContextFilter
}

}
