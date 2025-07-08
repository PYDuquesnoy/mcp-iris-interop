/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><class>%iKnow.Filters.Filter</class> implementation selecting sources based on whether they
/// contain a particular entity or (optionally) any entities similar to the supplied string(s).</p>
/// 
/// <p><b>Filter parameters</b>:
/// <ol>
/// 	<li><b>pDomainId</b> As <class>%Integer</class></li>
/// 	<li><b>pEntityList</b> As <class>%List</class> - entity values to check for. At least one needs to occur in the source for it to be included in the filter. Values can also be provided as an array, in which case the top node is ignored.</li>
/// 	<li><b>pIncludeSimilar</b> As <class>%Boolean</class> (default 0) - if true, any sources containing an entity "similar" to the supplied ones is also withheld.</li>
/// 	<li><b>pExcludeList</b> As <class>%List</class> - if <var>pIncludeSimilar</var>=1, exclude any entity IDs in this list. Can also be provided as an array, in which case the top node is ignored.</li>
/// 		<li><b>pUseIDs</b> As <class>%Boolean</class> (default 0) - if 1, entity IDs are provided for pEntityList rather than entity values (cannot be combined with pIncludeSimilar=1).</li>
/// </ol>
Class %iKnow.Filters.ContainsEntityFilter Extends %iKnow.Filters.Filter [ Deprecated, System = 4 ]
{

Property Entities As %List [ MultiDimensional ];

Property IncludeSimilar As %Boolean;

Property ExcludeList As %List [ MultiDimensional ];

Property UseIDs As %Boolean;

Method %OnNew(pDomainId As %Integer, ByRef pEntityList As %List, pIncludeSimilar As %Boolean = 0, ByRef pExcludeList As %List = "", pUseIDs As %Boolean = 0) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
		set i%DomainId = pDomainId
		
		if (pIncludeSimilar && pUseIDs) {
			set tSC = $$$ERROR($$$GeneralError, "Cannot use IDs when also including similar entities")
			quit:$$$ISERR(tSC)
		}
		
		// BDB354 - check if EntUniToSrcBit exists
		set tGlobs = $lb($$$IKBENTUNISRC)
		set:pIncludeSimilar tGlobs = tGlobs _ $lb($$$IKBPARTS)
		$$$IKQBCHECKX(pDomainId,tGlobs,tSC)
		
		if $d(pEntityList)<10 {
			$$$IKENSURELISTSTR(pEntityList)
		}
		merge i%Entities = pEntityList
		set i%IncludeSimilar = pIncludeSimilar
		merge i%ExcludeList = pExcludeList
		set i%UseIDs = pUseIDs
	
		set tSC = ..Initialize()
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method BuildSourceFilter(maxOffset As %Integer) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		set tDomainId = i%DomainId, tIncludeSimilar = i%IncludeSimilar, tUseIDs = i%UseIDs
		kill ^||%IKF.CE.All
		merge tEntities = i%Entities
		if ($d(tEntities)<10) {
			for i = 1:1:$ll(tEntities) {
				set tString = $li(tEntities,i)
				
				if (tIncludeSimilar) {
					set tSC = ##class(%iKnow.Queries.EntityAPI).GetSimilarIds("^||%IKQ.One", tDomainId, tString)
					quit:$$$ISERR(tSC)
					
					merge ^||%IKF.CE.All = ^||%IKQ.One
				} elseif (tUseIDs) {
					set:+tString ^||%IKF.CE.All(+tString) = ""
				} else {
					set tEntUniId = ##class(%iKnow.Queries.EntityAPI).GetIdInternal(tDomainId, tString,,0)
					set:tEntUniId ^||%IKF.CE.All(tEntUniId) = ""
				}
			}
			quit:$$$ISERR(tSC)
		} else {
			set tString = ""
			for {
				set tString = $order(tEntities(tString))
				quit:tString=""
				
				if (tIncludeSimilar) {
					set tSC = ##class(%iKnow.Queries.EntityAPI).GetSimilarIds("^||%IKQ.One", tDomainId, tString)
					quit:$$$ISERR(tSC)
					
					merge ^||%IKF.CE.All = ^||%IKQ.One
				} elseif (tUseIDs) {
					set:+tString ^||%IKF.CE.All(+tString) = ""
				} else {
					set tEntUniId = ##class(%iKnow.Queries.EntityAPI).GetIdInternal(tDomainId, tString,,0)
					set:tEntUniId ^||%IKF.CE.All(tEntUniId) = ""
				}
			}
		}
		
		merge tExcludeList = i%ExcludeList
		if $d(tExcludeList)<10 {
			set ptr=0
			while $listnext(tExcludeList,ptr,tEntUniId) {
				kill ^||%IKF.CE.All(tEntUniId)
			}
		} else {
			set tEntUniId = ""
			for {
				set tEntUniId = $order(tExcludeList(tEntUniId))
				quit:tEntUniId=""
				kill ^||%IKF.CE.All(tEntUniId)
			}
		}	
		
		kill ^||%IKF.CE.Bits
		set tEntUniId = ""
		for {
			set tEntUniId = $order(^||%IKF.CE.All(tEntUniId))
			quit:tEntUniId=""
			
			set tGloFrom = $name(^IRIS.IK.EntUniToSrcBit(tDomainId,tEntUniId))
			$$$IKMERGEBITSOR(tGloFrom,"^||%IKF.CE.Bits")
		}
		
		set tOff = ""
		for {
			set tOff = $order(^||%IKF.CE.Bits(tOff),1,tBits)
			quit:tOff=""
			
			set tSC = ..SetSourceBits(tOff, tBits)
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	kill ^||%IKF.CE.Bits, ^||%IKF.CE.All, ^||%IKF.CE.One
	quit tSC
}

ClassMethod RestoreFilterFromStringInternal(filterParams As %String) As %iKnow.Filters.Filter [ Private ]
{
	quit ..%New($piece(filterParams,"|",1), $lfs($piece(filterParams,"|",2)), $piece(filterParams,"|",3), $lfs($piece(filterParams,"|",4)), $piece(filterParams,"|",5))
}

Method ToString() As %String
{
	merge tEnts = i%Entities
	if $d(tEnts)<10 {
		set tEntities = $lts(tEnts)
	} else {
		set tEntity = "", tEntities = ""
		for {
			set tEntity = $order(tEnts(tEntity))
			quit:tEntity=""
			set tEntities = tEntities _ $s(tEntities="":"", 1:",") _ tEntity
		}
	}
	merge tExcls = i%ExcludeList
	if $d(tExcls)<10 {
		set tExcludes = $lts(tExcls)
	} else {
		set tEntity = "", tExcludes = ""
		for {
			set tEntity = $order(tExcls(tEntity))
			quit:tEntity=""
			set tExcludes = tExcludes _ $s(tExcludes="":"", 1:",") _ tEntity
		}
	}
	quit $classname()_"|"_i%DomainId_"|"_tEntities_"|"_i%IncludeSimilar_"|"_tExcludes_"|"_i%UseIDs
}

Method EntitiesSet(ByRef pEntities As %List) As %Status [ Internal, ServerOnly = 1 ]
{
	merge tEntities = i%Entities
	if ($d(tEntities) > 1) || ($d(pEntities) > 1) {
		kill i%Entities
		merge i%Entities = pEntities
		quit ..ChangeParams()
	} else {
		quit:$ls(pEntities,i%Entities) $$$OK
		set i%Entities = pEntities
		quit ..ChangeParams()
	}
}

Method ExcludeListSet(ByRef pExcludeList As %List) As %Status [ Internal, ServerOnly = 1 ]
{
	merge tExclude = i%ExcludeList
	if ($d(tExclude)>1) || ($d(pExcludeList)>1) {
		kill i%ExcludeList
		merge i%ExcludeList = pExcludeList
		quit ..ChangeParams()
	} else {
		quit:$ls(pExcludeList,i%ExcludeList) $$$OK
		set i%ExcludeList = pExcludeList
		quit ..ChangeParams()
	}
}

Method IncludeSimilarSet(pIncludeSimilar As %Boolean) As %Status [ Internal, ServerOnly = 1 ]
{
	quit:pIncludeSimilar=i%IncludeSimilar $$$OK
	set i%IncludeSimilar = pIncludeSimilar
	quit ..ChangeParams()
}

Method UseIDsSet(pUseIDs As %Boolean) As %Status [ Internal, ServerOnly = 1 ]
{
	quit:pUseIDs=i%UseIDs $$$OK
	set i%UseIDs = pUseIDs
	quit ..ChangeParams()
}

}
