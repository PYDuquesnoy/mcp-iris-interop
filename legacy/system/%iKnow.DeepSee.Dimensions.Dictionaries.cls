/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// for ..%ikDictLevel = "D" (dictionary)
/// 	KEY: [dictId]
/// 		NAME: [dictName]
/// 
/// for ..%ikDictLevel = "I" (dictionary item)
/// 	KEY: [dictItemId]
/// 		NAME: [dictItemName]
Class %iKnow.DeepSee.Dimensions.Dictionaries Extends %iKnow.DeepSee.Dimensions.Base [ Deprecated, System = 4 ]
{

Property %ikDictLevel As %String(VALUELIST = ",D,I");

Property %ikDictDomainId As %Integer;

Method %FindComputedMemberByKeyInternal(pKey As %String, Output pFlag As %Boolean, Output pMemberName As %String, Output pMemberId As %String, pComputeBitset As %Boolean = 1) As %Status [ Internal, Private ]
{
	set tSC = $$$OK
	try {
		set pFlag = 0, pMemberId = "", pMemberName = ""
	
		set tColons = $l(pKey,":")
		if (tColons>1) {
			set pMemberId = $piece(pKey,":",tColons), pMemberName = $piece(pKey,":",1,tColons-1)
		} elseif (..%ikDictLevel="D") {
			set tData = $g(^IRIS.IK.Mat.DictId(i%%ikDictDomainId, $zabs(pKey)))
			quit:tData=""
			set pMemberId = pKey, pMemberName = $li(tData,1)
			set:..%ikDomainType="DeepSee" pMemberName = ..GetTermListName(pMemberName)
		} elseif (..%ikDictLevel="I") {
			set tData = $g(^IRIS.IK.Mat.DictItemId(i%%ikDictDomainId, $zabs(pKey)))
			quit:tData=""
			set pMemberId = pKey, pMemberName = $li(tData,2) // uses NAME, not URI!
		}
		
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
	set tSC = $$$OK
	try {
		Set pFlag = 0, pMemberId = "", pMemberKey = ""
		
		set pMemberKey = ..GetId(pName)
		quit:'pMemberKey
		set pFlag = 1
		
		set tSC = ..%ComputeBitset(pMemberKey, .pMemberId)
		quit:$$$ISERR(tSC)
	} catch(ex) {
		Set tSC = ex.AsStatus()
	}
	quit tSC
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
		
		//set tNeg = ($e(tSpec)="~")
		//set:tNeg tSpec = $e(tSpec,2,*)
		set tKeyLen=$l(tSpec,","),tIds=""
		for i=1:1:tKeyLen {
			set tDSpec = $p(tSpec,",",i)
			set tDId = +$p(tDSpec,":",$l(tDSpec,":"))
			continue:'tDId
			set tIds = tIds_","_$s(i%%ikDictDomainId:tDId, 1:-tDId)
		}
		set tIds = $e(tIds,2,*), tKeyLen = $l(tIds,",")
		quit:tIds=""
		
		set tIndexGlo = $name($$$DeepSeeIndexGLVN(..%baseCube,..%factNumber, pIndexKey))
		kill @tIndexGlo
		
		if (..%ikDictLevel="D") {
			
			for i = 1:1:tKeyLen {
				if (i=1) || (..#COMBINATIONLOGIC = "OR") {
					$$$IKMERGEBITSOR("^IRIS.IK.Mat.DictToSrcBit("_..%ikDomainId_","_$p(tIds,",",i)_")",tIndexGlo)
				} else {
					$$$IKMERGEBITSAND("^IRIS.IK.Mat.DictToSrcBit("_..%ikDomainId_","_$p(tIds,",",i)_")",tIndexGlo)
				}
			}
		
			if (..%ikDomainType = "iKnow") {
				set tSC = ##class(%iKnow.DeepSee.CubeUtils).TranslateIKnowBitstring(..%baseCube, ..%ikMeasure, tIndexGlo)
				quit:$$$ISERR(tSC)
			}
			
		} elseif (..%ikDictLevel="I") {
			
			// BDB791 - leverage additional index
			set tMeasure = $$$UPPER(..%ikMeasure)
			if $d($$$DeepSeeIndexGLVN(..%baseCube, "%ikDI", $$$UPPER(tMeasure))) {
				
				merge @tIndexGlo = $$$DeepSeeIndexGLVN(..%baseCube, "%ikDI", tMeasure, $p(tIds,",",i))
				for i=2:1:tKeyLen {
					set tItemId = $p(tIds,",",i)
					set tOffset=""
					for {
						set tOffset = $order($$$DeepSeeIndexGLVN(..%baseCube, "%ikDI", tMeasure, tItemId, tOffset), 1, tBits)
						quit:tOffset=""
						set @tIndexGlo(tOffset) = $bitlogic(tBits | @tIndexGlo(tOffset))
					}
				}
				
			} else { // revert to slower pre-BDB791 mechanism
			
				for i=1:1:tKeyLen {
					kill ^||%IK.Srcs, ^||%IK.SrcItemBits
					$$$IKSORTBEGIN(^||%IK.Srcs)
					set tItemId = $p(tIds,",",i)
					kill aMatches
					merge aMatches = ^IRIS.IK.Mat.DictItemToMatch(..%ikDomainId, tItemId)
					set tMatchId = ""
					for {
						set tMatchId = $order(aMatches(tMatchId))
						quit:tMatchId=""
					
						set tMatch = $g(^IRIS.IK.Mat.MatchId(..%ikDomainId, tMatchId))
						continue:tMatch=""
						set ^||%IK.Srcs(##class(%iKnow.Matching.MatchingAPI).GetSourceIdForMatchTarget(..%ikDomainId, $li(tMatch,4), $li(tMatch,5))) = ""
					}
					kill aMatches
					set x = $sortend(^||%IK.Srcs)
					
					set tSrcId="", tPrevOff=0, tBits=""
					for {
						set tSrcId = $order(^||%IK.Srcs(tSrcId))
						quit:tSrcId=""
						
						$$$IKBITOFFPOS(tSrcId,tOff,tPos)
						if (tPrevOff '= tOff) {
							set:tPrevOff ^||%IK.SrcItemBits(tPrevOff) = $bitlogic(tBits)
							set tPrevOff = tOff, tBits = ""
						}
						set $bit(tBits, tPos) = 1
					}
					set:tPrevOff ^||%IK.SrcItemBits(tPrevOff) = $bitlogic(tBits)
					
					if (i=1) || (..#COMBINATIONLOGIC = "OR") {
						$$$IKMERGEBITSOR("^||%IK.SrcItemBits",tIndexGlo)
					} else {
						$$$IKMERGEBITSAND("^||%IK.SrcItemBits",tIndexGlo)
					}
				}
				kill ^||%IK.SrcItemBits, ^||%IK.Srcs
				
				if (..%ikDomainType = "iKnow") {
					set tSC = ##class(%iKnow.DeepSee.CubeUtils).TranslateIKnowBitstring(..%baseCube, ..%ikMeasure, tIndexGlo)
					quit:$$$ISERR(tSC)
				}
			}
		}
	} catch(ex) {
		Set tSC = ex.AsStatus()
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
		set tDomainId = ..%ikDomainId
		quit:'tDomainId  // simply quit to avoid noisy errors
		
		set pSearchKey = $$$IKNORMALIZED(pSearchKey,tDomainId)
		
		// if there's already data supplied, try to fill in key and id
		if ($o(pMembers(""))) {
			kill tMemberList
			set i=""
			for {
				set i = $order(pMembers(i),1,tMember)
				quit:i=""
				
				// we expect a dict/item ID as spec
				set tId = +$lg(tMember,3)
				
				// verify if it exists
				set:tId tName = ..GetName(tId)
				if tId && (tName '= "") {
					
					// verify if it satisfies the search condition
					continue:(pSearchKey'="")&&'$find($$$IKNORMALIZED(tName,tDomainId),pSearchKey)
					
					set tMemberList($i(tMemberList)) = $lb(tId, tName, tId)
					continue
				}
				
				// otherwise try to find it by name
				set tId = +..GetId($lg(tMember,2))
				if tId {
					set tName = ..GetName(tId)
					
					// verify if it satisfies the search condition
					continue:(pSearchKey'="")&&'$find($$$IKNORMALIZED(tName,tDomainId),pSearchKey)
					
					set tMemberList($i(tMemberList)) = $lb(tId, tName, tId)
					continue
				}
				
				// if we weren't able to resolve it, return a warning, except if in a search
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
		
		set tCount = 0, tDomainId = i%%ikDomainId, tDictDomainId = i%%ikDictDomainId
		
		// BDB467 - prepare to filter to selected dictionaries
		if (..%ikDomainType="DeepSee") {
			set tSC = ##class(%iKnow.DeepSee.CubeUtils).GetMeasureInfo(..%cube, ..%ikMeasure,,,,,, .tSelectedDictList)
			quit:$$$ISERR(tSC)
			set tSelectedDictList = $lfs(tSelectedDictList)
		}
		
		if (..%ikDictLevel="D") {
			
			set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaries(.tResult, tDictDomainId, 1, ..#MAXRESULTS)
			quit:$$$ISERR(tSC)
		
			set ti = ""
			for {
				set ti = $order(tResult(ti),1,tData)
				quit:ti=""
				
				set tDictId = $li(tData,1), tDictName = $li(tData,2)
				
				if (..%ikDomainType="DeepSee") {
					set tDictName = ..GetTermListName(tDictName)
					continue:'$listfind(tSelectedDictList,tDictName)
				}
				
				continue:(pSearchKey'="")&&'$find($$$IKNORMALIZED(tDictName,tDomainId),pSearchKey)
				set tXDictId = tDictId * $s(tDictDomainId:1, 1:-1)
				
				// BDB371 - verify there are sources satisfying the current filter criteria
				// matching anything within this dictionary
				set tFilter = ..%GetQueryContextFilter(.tSC)
				quit:$$$ISERR(tSC)
				if $isobject(tFilter) {
					set tOff = "", tHasMatch = 0
					for {
						set tOff = $order(^IRIS.IK.Mat.DictToSrcBit(tDomainId, tXDictId, tOff),1,tBits)
						quit:tOff=""
						set tFilterBits = tFilter.GetSourceFilter(tOff)
						set tBits = $bitlogic(tBits & tFilterBits)
						set tHasMatch = $$$IKHASBIT(tBits)
						quit:tHasMatch
					}
					continue:'tHasMatch
				}
				
				set pMembers($i(tCount)) = $lb(tDictId, tDictName, tDictId)
			}
			
		} elseif (..%ikDictLevel="I") {
			
			kill tDictList
			if (pRollupKey'="") {
				// if we have a rollup key, this is our dictionary ID
				set tDictList($i(tDictList)) = $lb(+pRollupKey)
			} else {
				// otherwise, try to retrieve items through the model-defined list of
				// dictionaries in the level above this one, if any
				set i = "", tDictLevel=..%levelNumber-1
				for {
					set i = $order($$$DeepSeeMetaGLVN("cubes", ..%baseCube, "mbr#", ..%dimNumber, ..%hierNumber, tDictLevel, "mbr", i), 1, tDictInfo)
					quit:i=""
				
					// first try to find by id
					set tId = +$lg(tDictInfo,2)
					if tId && $d(^IRIS.IK.Mat.DictId(tDictDomainId, tId),tDictData) {
						set tDictList($i(tDictList)) = $lb(tId)
						continue
					}
				
					// otherwise try by name
					set tId = +##class(%iKnow.Matching.DictionaryAPI).GetDictionaryId(tDictDomainId, ..GetDictionaryName($lg(tDictInfo,1)))
					if tId>0 {
						set tDictList($i(tDictList)) = $lb(tId)
						continue
					}
				}
				
				// BDB467 - if none found, prepare list based on the selected dictionaries
				// for this iKnow measure
				if '$d(tDictList) && (..%ikDomainType="DeepSee") {
					for i = 1:1:$ll(tSelectedDictList) {
						set tDictName = ..GetDictionaryName($li(tSelectedDictList,i))
						set tDictList($i(tDictList)) = $lb(##class(%iKnow.Matching.DictionaryAPI).GetDictionaryId(tDictDomainId, tDictName))
					}
				}
			}
			
			// if no predefined dicts were found at the dict level, look for all
			if '$d(tDictList) {
				set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaries(.tDictList, tDictDomainId)
				quit:$$$ISERR(tSC)
			}
			
			// now loop through the list and add items for each dictionary
			set i=""
			for {
				set i = $order(tDictList(i),1,tDictInfo)
				quit:i=""
				
				kill ^||%IKQ.DictItems
				set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryItems("^||%IKQ.DictItems", tDictDomainId, $li(tDictInfo,1), 0, 0)
				quit:$$$ISERR(tSC)
				
				set j = ""
				for {
					set j = $order(^||%IKQ.DictItems(j),1,tItemData)
					quit:j=""
					
					set tItemId = $li(tItemData,1), tItemName = $li(tItemData,2), tItemURI = $li(tItemData,3)
					continue:(pSearchKey'="")&&'$find($$$IKNORMALIZED(tItemName,tDomainId),pSearchKey) //&&'$find($$$IKNORMALIZE(tItemURI),pSearchKey)
					
					// BDB371 - verify there are sources satisfying the current filter criteria
					// matching anything within this dictionary
					set tFilter = ..%GetQueryContextFilter(.tSC)
					quit:$$$ISERR(tSC)
					if $isobject(tFilter) {
						// NOTE: for performance reasons, we only check whether there's any matches
						// for the current Item's dictionary, as checking the item level too would mean
						// a lot of extra global lookups for little added value.
						set tDictId = $lg(^IRIS.IK.Mat.DictItemId(tDictDomainId, tItemId),1)
						set:'tDictDomainId tDictId = -tDictId
						set tOff = "", tHasMatch = 0
						for {
							set tOff = $order(^IRIS.IK.Mat.DictToSrcBit(tDomainId, tDictId, tOff),1,tBits)
							quit:tOff=""
							set tFilterBits = tFilter.GetSourceFilter(tOff)
							set tBits = $bitlogic(tBits & tFilterBits)
							set tHasMatch = $$$IKHASBIT(tBits)
							quit:tHasMatch
						}
						continue:'tHasMatch
					}
					
					set pMembers($i(tCount)) = $lb(tItemId, tItemName, tItemId)
					quit:tCount>=..#MAXRESULTS
				}
				kill ^||%IKQ.DictItems
				quit:tCount>=..#MAXRESULTS
			}
		}
		
	} catch(ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method GetId(pName As %String) As %Integer [ Internal ]
{
	quit:'..%ikDomainId 0
	quit:pName="" 0
	
	// URIs and dict names are case-sensitive, but pMemberKey is lowercased. to avoid having to go through
	// all URIs in the index or all case variations in pMemberKey, go through the index for
	// each 3-character case variation of $e(pMemberKey,1,3) (this is crazy)
	
	if (..%ikDictLevel = "D") {
		set globName = "^IRIS.IK.Mat.Dict("_i%%ikDictDomainId_")"
		set:'i%%ikDictDomainId pName = ..GetDictionaryName(pName)
	} elseif (..%ikDictLevel = "I") {
		set globName = "^IRIS.IK.Mat.DictItemURI("_i%%ikDictDomainId_")"
		set:'i%%ikDictDomainId pName = ..GetDictionaryItemURI(pName)
	}
	
	set tId = +$g(@globName@(pName))
	quit:tId tId
	
	// BDB485 - since BDB397, dictionary names are case-insensitive
	if (i%%ikDictLevel = "D") && ('i%%ikDictDomainId || $$$IKVERSIONATLEAST(i%%ikDomainId,$$$IKVERSIONCASEINSENSITIVENAMES)) {
		set tId = +$g(@globName@($$$UPPER(pName)))
		quit:tId tId
	}
	
	set a=$e(pName,1), b=$e(pName,2), c=$e(pName,3)
	set a1=$$$UPPER(a), b1=$$$UPPER(b), c1=$$$UPPER(c)
	set a2=$$$LOWER(a), b2=$$$LOWER(b), c2=$$$LOWER(c)
	set len = $l(pName), isShort = (len<=3), upper = $$$UPPER(pName)
	for candidate = a1_b1_c1, a1_b1_c2, a1_b2_c1, a1_b2_c2, a2_b1_c1, a2_b1_c2, a2_b2_c1, a2_b2_c2 {
		if (isShort) {
			set tId = +$g(@globName@(candidate))
		} else {
			set tUri = candidate
			for {
				set tId = 0
				set tUri = $o(@globName@(tUri),1,tId)
				quit:tUri=""
				
				quit:($$$UPPER(tUri)=upper)
				
				if ($e(tUri,1,3)'=candidate) {
					set tId = 0
					quit
				}
			}
		}
		quit:tId
	}
	
	quit tId
}

Method GetName(pId As %Integer) As %String [ Internal, Private ]
{
	if ('i%%ikDictDomainId) { // deepsee-managed domain, cross-domain dictionaries
		if (..%ikDictLevel="D") {
			quit ..GetTermListName($lg($g(^IRIS.IK.Mat.DictId(0, pId)),1))
		} else {
			quit ..GetTermListURI($lg($g(^IRIS.IK.Mat.DictItemId(0, +pId)),2))
		}
	} elseif (pId<0) { // iKnow-managed domain, cross-domain dictionaries
		if (..%ikDictLevel="D") {
			quit $lg($g(^IRIS.IK.Mat.DictId(0, $zabs(pId))),1)
		} else {
			quit $lg($g(^IRIS.IK.Mat.DictItemId(0, $zabs(pId))),2)
		}
	} else { // non-cross-domain dictionaries
		if (..%ikDictLevel="D") {
			quit $lg($g(^IRIS.IK.Mat.DictId(..%ikDomainId, +pId)),1)
		} else {
			quit $lg($g(^IRIS.IK.Mat.DictItemId(..%ikDomainId, +pId)),2)
		}
	}
}

/// Create a instance of this dimension class.
ClassMethod %Create(pCube As %String, pFactNo As %Integer, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %DeepSee.ComputedDimension.Base
{
	set tObj = ##super(pCube, pFactNo, pDimNo, pHierNo, pLevelNo)
	set tObj.%ikDictLevel = ..%GetDictLevel(pCube, pDimNo, pHierNo, pLevelNo)
	set tObj.%ikDictDomainId = $s((tObj.%ikDomainType="DeepSee")&&$$$IKVERSIONATLEAST(tObj.%ikDomainId,$$$IKVERSIONXDOMAIN):0, 1:tObj.%ikDomainId)
	
	quit tObj
}

ClassMethod %GetDictLevel(pCube As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %String [ Private ]
{
	// derive dict level from previous level: if it has one, we're at the item level
	set tPrevLevel = $g($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCube),"mbr#",pDimNo,pHierNo,pLevelNo-1))
	quit $s($lg(tPrevLevel,1)="l":"I", 1:"D")
}

Parameter DICTIONARYNAMEPREFIX [ Internal ] = "DeepSee - ";

Parameter ITEMNAMEPREFIX [ Internal ] = ":DS:";

/// Returns the dictionary name used for a DeepSee Term List
/// Note: assumes version >= 3 (for cross-domain dictionary use)
ClassMethod GetDictionaryName(pTermListName As %String) As %String [ CodeMode = objectgenerator, Internal ]
{
	do %code.WriteLine("	quit "_$$$QUOTE(%parameter("DICTIONARYNAMEPREFIX"))_"_pTermListName")
}

ClassMethod GetTermListName(pDictionaryName As %String) As %String [ CodeMode = objectgenerator, Internal ]
{
	do %code.WriteLine("	quit $e(pDictionaryName,"_($length(%parameter("DICTIONARYNAMEPREFIX"))+1)_",*)")
}

ClassMethod GetDictionaryItemURI(pTermListURI As %String) As %String [ CodeMode = objectgenerator, Internal ]
{
	do %code.WriteLine("	quit "_$$$QUOTE(%parameter("ITEMNAMEPREFIX"))_"_pTermListURI")
}

ClassMethod GetTermListURI(pDictionaryItemURI As %String) As %String [ CodeMode = objectgenerator, Internal ]
{
	do %code.WriteLine("	quit $e(pDictionaryItemURI,"_($length(%parameter("ITEMNAMEPREFIX"))+1)_",*)")
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
				do ##class(%iKnow.DeepSee.CubeUtils).GetMeasureInfo(pCube, tIKMeasure,, .tDomainId,, .tDomainType,, .tDictionaries)
				if (..%GetDictLevel(pCube, pDimNo, pHierNo, pLevelNo)="D") {
					set tCount = $l(tDictionaries,",")
				} else {
					set tDomainId = $s((tDomainType="DeepSee")&&$$$IKVERSIONATLEAST(tDomainId,$$$IKVERSIONXDOMAIN):0, 1:tDomainId)
					set tDictIds = ""
					for i = 1:1:$l(tDictionaries,",") {
						set tDictName = ..GetDictionaryName($piece(tDictionaries,",",i))
						set tDictId = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryId(tDomainId, tDictName)
						continue:'tDictId
						set tDictIds = tDictIds _ $lb(tDictId)
					}
					set tCount = ##class(%iKnow.Matching.DictionaryAPI).GetItemCount(tDomainId, tDictIds, .tSC)
				}
			}
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tCount
}

}
