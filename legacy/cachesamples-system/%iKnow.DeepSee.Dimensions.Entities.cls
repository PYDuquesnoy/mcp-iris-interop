/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.DeepSee.Dimensions.Entities Extends %iKnow.DeepSee.Dimensions.Base [ Deprecated, System = 4 ]
{

Property %ikSkipList As %Integer;

Property %ikUseStemming As %Boolean;

ClassMethod %Create(pCube As %String, pFactNo As %Integer, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %DeepSee.ComputedDimension.Base
{
	set tObj = ##super(pCube, pFactNo, pDimNo, pHierNo, pLevelNo)
	
	// BDB320 - load SkipList ID, if any
	set tSkipList = $$$GETIKPDSSKIPLIST(tObj.%ikDomainId)
	if (tSkipList'="") {
		// BDB387 - use cross-domain Skiplist
		set tBLDomainId = $s($$$IKVERSIONATLEAST(tObj.%ikDomainId,$$$IKVERSIONXDOMAIN):0, 1:tObj.%ikDomainId)
		set tBLID = ##class(%iKnow.Utils.MaintenanceAPI).GetSkipListId(tBLDomainId, tSkipList)
		
		// BDB754 - fall-back to in-domain ones for iKnow-managed domains
		if (tBLID <= 0) && (tObj.%ikDomainType="iKnow") {
			set tObj.%ikSkipList = ##class(%iKnow.Utils.MaintenanceAPI).GetSkipListId(tObj.%ikDomainId, tSkipList)
		} else {
			set tObj.%ikSkipList = tBLID * $s(tBLDomainId:1, 1:-1)
		}
	}
	
	set tObj.%ikUseStemming = +$$$GETPARAMNODEF(tObj.%ikDomainId,$$$IKPSTEMMING)
	
	quit tObj
}

Method %FindComputedMemberByKeyInternal(pKey As %String, Output pFlag As %Boolean, Output pMemberName As %String, Output pMemberId As %String, pComputeBitset As %Boolean = 1) As %Status [ Internal, Private ]
{
	set tSC = $$$OK
	try {
		set pFlag = 0, pMemberId = "", pMemberName = ""
	
		set tColons = $l(pKey,":")
		if (tColons>1) {
			set pMemberId = $piece(pKey,":",tColons), pMemberName = $piece(pKey,":",1,tColons-1)
		} else {
			set pMemberName = $g(^IRIS.IK.EntUniId(..%ikDomainId, +pKey))
			quit:pMemberName=""
			set pMemberId = pKey
		}
		quit:pMemberName=""
		
		if (pComputeBitset) {
			set tSC = ..%ComputeBitset(pKey, .tIndexKey)
			quit:$$$ISERR(tSC)
		}
		
		set pFlag = 1
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %FindComputedMemberByName(pName As %String, Output pFlag As %Boolean, Output pMemberKey As %String, Output pMemberId As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pFlag = 0, pMemberId = "", pMemberKey = ""
		
		set pMemberId = ##class(%iKnow.Queries.EntityAPI).GetIdInternal(..%ikDomainId, pName)
		quit:'+pMemberId
		
		// BDB522 - ensure we're using the base form ID
		set:..%ikUseStemming pMemberId = ##class(%iKnow.Queries.EntityAPI).GetBaseFormId(..%ikDomainId, pMemberId)
		
		set pFlag = 1
		set pMemberKey = pMemberId
		
		set tSC = ..%ComputeBitset(pMemberKey, .tIndexKey)
		quit:$$$ISERR(tSC)
		
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Build the bitset that corresponds to the given computed dimension "spec".
Method %OnComputeBitset(pSpec As %String, pIndexKey As %String) As %Status
{
	set tSC = $$$OK
	try {
		quit:'..%ikDomainId  // simply quit to avoid noisy errors
		set tSC = ..%ResolveKey(pSpec,.tSpec)
		quit:$$$ISERR(tSC)
		quit:tSpec=""
		
		// BDB354 - check if EntUniToSrc is present
		$$$IKQBCHECKX(..%ikDomainId,$$$IKBENTUNISRC,tSC)
		
		//set tNeg = ($e(tSpec)="~")
		//set:tNeg tSpec = $e(tSpec,2,*)
		set tKeyLen=$l(tSpec,","),tIds=""
		for i=1:1:tKeyLen {
			set tEntSpec = $p(tSpec,",",i)
			set tEntUniId = +$p(tEntSpec,":",$l(tEntSpec,":"))
			continue:'tEntUniId
			set tIds = tIds_$lb(tEntUniId)
		}
		
		set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityIdList(..%ikDomainId, tIds, .tEntIds,,, $s('..%ikUseStemming:0, (..#COMBINATIONLOGIC="AND"):3, 1:2))
		quit:$$$ISERR(tSC)
		
		set tIndexGlo = $name($$$DeepSeeIndexGLVN(..%baseCube,..%factNumber,pIndexKey))
		kill @tIndexGlo
		set tEntUniId = "", tIsFirstEntity=1
		for {
			set tEntUniId = $order(tEntIds(tEntUniId))
			quit:tEntUniId=""
			
			if (..#COMBINATIONLOGIC="OR") {
				$$$IKMERGEBITSOR("^IRIS.IK.EntUniToSrcBit("_..%ikDomainId_","_tEntUniId_")",tIndexGlo)
			} else {
				
				/// BDB522 - a two-level array means the sub-nodes should be ORed before ANDing them
				kill ^||%IK.EntBits
				if $d(tEntIds(tEntUniId))>1 {
					
					set tSubEntId = ""
					for {
						set tSubEntId = $order(tEntIds(tEntUniId,tSubEntId))
						quit:tSubEntId=""
						$$$IKMERGEBITSOR("^IRIS.IK.EntUniToSrcBit("_..%ikDomainId_","_tSubEntId_")","^||%IK.EntBits")
					}
					if tIsFirstEntity {
						merge @tIndexGlo = ^||%IK.EntBits
					} else {
						$$$IKMERGEBITSAND("^||%IK.EntBits",tIndexGlo)
					}
					
				} else {
					if tIsFirstEntity {
						merge @tIndexGlo = ^IRIS.IK.EntUniToSrcBit(..%ikDomainId,tEntUniId)
					} else {
						$$$IKMERGEBITSAND("^IRIS.IK.EntUniToSrcBit("_..%ikDomainId_","_tEntUniId_")",tIndexGlo)
					}
				}
				set tIsFirstEntity=0
			}
		}
		
		if (..%ikDomainType = "iKnow") {
			set tSC = ##class(%iKnow.DeepSee.CubeUtils).TranslateIKnowBitstring(..%baseCube, ..%ikMeasure, tIndexGlo)
			quit:$$$ISERR(tSC)
		}
		
	} catch(ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
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
		quit:'..%ikDomainId  // simply quit to avoid noisy errors
		
		// for searching through the predefined entities, we'll simply use $find,
		// which is slightly less selective than the EntityAPI.GetSimilar() implementation
		set pSearchKey = $$$IKNORMALIZED(pSearchKey,..%ikDomainId)
		
		// if there's already data supplied, try to fill in key and id
		if ($o(pMembers(""))) {
			kill tMemberList
			set i=""
			for {
				set i = $order(pMembers(i),1,tMember)
				quit:i=""
				
				// we expect an entity ID as spec
				set tEntUniId = +$lg(tMember,3)
				
				// verify if it exists
				set:tEntUniId tEntValue = ##class(%iKnow.Queries.EntityAPI).GetValueInternal(..%ikDomainId, tEntUniId,, $case(..%ikUseStemming, 1:2, 2:1, :0))
				if tEntUniId && (tEntValue '= "") {
					
					// verify if it satisfies the search condition
					continue:(pSearchKey'="")&&'$find(tEntValue,pSearchKey)
					
					set tMemberList($i(tMemberList)) = $lb(tEntUniId, tEntValue, tEntUniId)
					continue
				}
				
				// otherwise try to find it by value
				set tEntUniId = +##class(%iKnow.Queries.EntityAPI).GetIdInternal(..%ikDomainId, $lg(tMember,2))
				if tEntUniId {
					set:..%ikUseStemming tEntUniId = ##class(%iKnow.Queries.EntityAPI).GetBaseFormId(..%ikDomainId, tEntUniId)
					set tEntValue = ##class(%iKnow.Queries.EntityAPI).GetValueInternal(..%ikDomainId, tEntUniId,, $case(..%ikUseStemming, 1:2, 2:1, :0))
					
					// verify if it satisfies the search condition
					continue:(pSearchKey'="")&&'$find(tEntValue,pSearchKey)
					
					set tMemberList($i(tMemberList)) = $lb(tEntUniId, tEntValue, tEntUniId)
					continue
				}
				
				// if we weren't able to resolve it, return a warning (except when searching)
				if (pSearchKey="") {
					if ($lg(tMember,2)'="") {
						set tMemberList($i(tMemberList)) = $lb("","Unknown member: """_$lg(tMember,2)_"""","")
					} elseif ($lg(tMember,3)'="") {
						set tMemberList($i(tMemberList)) = $lb("","Unknown member key: """_$lg(tMember,3)_"""","")
					} else {
						set tMemberList($i(tMemberList)) = $lb("","Unknown member ID: "_$lg(tMember,1),"")
					}
				}
			}
			kill pMembers
			merge pMembers = tMemberList
			quit
		}
		
		// BDB371 - add query context filter
		set tContextFilter = ..%GetQueryContextFilter(.tSC)
		quit:$$$ISERR(tSC)
		
		if (pSearchKey="") {
			set tSC = ##class(%iKnow.Queries.EntityAPI).GetTop(.tResult, ..%ikDomainId, 1, ..#MAXRESULTS, tContextFilter,, ..GetEntitySortType(),,, ..%ikSkipList)
		} else {
			set tSC = ##class(%iKnow.Queries.EntityAPI).GetSimilar(.tResult, ..%ikDomainId, pSearchKey, 1, ..#MAXRESULTS, tContextFilter,,, ..%ikSkipList)
		}
		quit:$$$ISERR(tSC)
		
		set ti = "", tCount=0
		for {
			set ti = $order(tResult(ti),1,tData)
			quit:ti=""
			
			set pMembers($i(tCount)) = $li(tData,1,2) _ $li(tData,1,1)
		}
	} catch(ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method GetEntitySortType() [ Internal, Private ]
{
	quit $$$GETPARAM(..%ikDomainId,$$$IKPSORTFIELD,$$$SORTBYSPREAD)
}

/// Return number of members.
ClassMethod %Count(pCube As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %Integer
{
	set tSC = $$$OK, tCount = 0
	try {
		set tCube = $$$UPPER(pCube)
		
		// count number of pre-defined members
		set tSC = ..%GetPredefinedMembers(.tMembers, pCube, pDimNo, pHierNo, pLevelNo)
		quit:$$$ISERR(tSC)
		set i = ""
		for {
			set i = $order(tMembers(i))
			quit:i=""
			set tCount = tCount + 1
		}
		quit:tCount
		
		// if none predefined, query domain
		do ##class(%DeepSee.Utils).%GetDimensionFact(pCube, pDimNo, pHierNo, pLevelNo, .tFactName)
		if (tFactName'="") {
			set tIKMeasure = $g($$$DeepSeeMetaGLVN("cubes", tCube, "fact", "prop", tFactName, "iKnowMsr"))
			if (tIKMeasure'="") {
				set tDomainId = ##class(%iKnow.DeepSee.CubeUtils).GetDomainId(pCube, tIKMeasure)
				set:tDomainId tCount = ##class(%iKnow.Queries.EntityAPI).GetCountByDomain(tDomainId)
			}
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tCount
}

}
