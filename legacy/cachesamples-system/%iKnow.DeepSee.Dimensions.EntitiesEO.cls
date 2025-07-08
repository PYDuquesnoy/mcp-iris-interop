/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.DeepSee.Dimensions.EntitiesEO Extends %iKnow.DeepSee.Dimensions.Entities [ Deprecated, System = 4 ]
{

ClassMethod %Create(pCube As %String, pFactNo As %Integer, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %DeepSee.ComputedDimension.Base
{
	Set tObj = ##super(pCube, pFactNo, pDimNo, pHierNo, pLevelNo)
	
	set tObj.%ikDomainId = $g($$$DeepSeeMetaGLVN("cubes",pCube,"fact","prop",tObj.%factName,"expr"))
	
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
			
	Quit tObj
}

/// Build the bitset that corresponds to the given computed dimension "spec".
Method %OnComputeBitset(pSpec As %String, pIndexKey As %String) As %Status
{
	set tSC = $$$OK
	try {
		set tSC = ..%ResolveKey(pSpec,.tSpec)
		quit:$$$ISERR(tSC)
		quit:tSpec=""
		
		// BDB354 - check if EntUniToOccBit is present
		$$$IKQBCHECKX(i%%ikDomainId,$$$IKBENTUNIBIT,tSC)
		
		//set tNeg = ($e(tSpec)="~")
		//set:tNeg tSpec = $e(tSpec,2,*)
		set tKeyLen=$l(tSpec,","),tIds=""
		for i=1:1:tKeyLen {
			set tEntSpec = $p(tSpec,",",i)
			set tEntUniId = +$p(tEntSpec,":",$l(tEntSpec,":"))
			continue:'tEntUniId
			set tIds = tIds_","_tEntUniId
		}
		
		kill ^||%IK.FactIds, ^||%IK.FactBits
		set tIds=$e(tIds,2,*), tKeyLen=$l(tIds,",")
		for i = 1:1:tKeyLen {
			if (i=1) || (..#COMBINATIONLOGIC = "OR") {
				$$$IKMERGEBITSOR("^IRIS.IK.EntUniToOccBit("_..%ikDomainId_","_$p(tIds,",",i)_")", "^||%IK.FactBits")
			} else {
				$$$IKMERGEBITSAND("^IRIS.IK.EntUniToOccBit("_..%ikDomainId_","_$p(tIds,",",i)_")", "^||%IK.FactBits")
			}
		}
		
		$$$IKSORTBEGIN(^||%IK.FactIds)
		set tOff = ""
		for {
			set tOff = $order(^||%IK.FactBits(tOff),1,tBits)
			quit:tOff=""
			
			set tPos=0
			for {
				set tPos = $bitfind(tBits,1,tPos+1)
				quit:'tPos
				$$$IKGETIDOFFPOS(tEntOccId,tOff,tPos)
				set ^||%IK.FactIds(+$o($$$DeepSeeIndexGLVN(..%baseCube,"%sourceId",tEntOccId,""))) = ""
			}
		}
		set x = $sortend(^||%IK.FactIds)
		
		set tPrevChunk=0, tFactId="", tBits=""
		for {
			set tFactId = $order(^||%IK.FactIds(tFactId))
			quit:tFactId=""
			
			$$$IKBITOFFPOS(tFactId,tChunk,tFPos)
			if (tChunk '= tPrevChunk) {
				set:tPrevChunk $$$DeepSeeIndexGLVN(..%baseCube,..%factNumber,pIndexKey,tPrevChunk) = $bitlogic(tBits)
				set tPrevChunk=tChunk, tBits=""
			}
			set $bit(tBits,tFPos) = 1
		}
		set:tPrevChunk $$$DeepSeeIndexGLVN(..%baseCube,..%factNumber,pIndexKey,tPrevChunk) = $bitlogic(tBits)
		
		kill ^||%IK.FactIds, ^||%IK.FactBits
		
	} catch(ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method GetEntitySortType() [ Internal, Private ]
{
	quit $$$SORTBYFREQUENCY
}

/// Return number of members.
ClassMethod %Count(pCube As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %Integer
{
	Set tCube = $$$UPPER(pCube)
	Set tCount = 0
	// count number of pre-defined members
	Set p = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",pDimNo,pHierNo,pLevelNo,"mbr",""))
	While (p'="") {
		Set tCount = tCount + 1
		Set p = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",pDimNo,pHierNo,pLevelNo,"mbr",p))
	}
	
	// if none predefined, query domain
	if 'tCount {
		do ##class(%DeepSee.Utils).%GetDimensionFact(pCube, pDimNo, pHierNo, pLevelNo, .tFactName)
		if (tFactName'="") {
			set tDomainId = $g($$$DeepSeeMetaGLVN("cubes", tCube, "fact", "prop", tFactName, "expr"))
			set:tDomainId tCount = ##class(%iKnow.Queries.EntityAPI).GetCountByDomain(tDomainId)
		}
	}

	Quit tCount
}

}
