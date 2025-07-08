/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><class>%iKnow.Filters.Filter</class> implementation selecting sources based on whether they
/// contain a particular set of entities in a single context. This means they appear in the same CRC
/// (direct relationship) or path (any relationship) in the sources to be included. Optionally,
/// any entities similar to the supplied ones are also accepted.</p>
/// 
/// <p><b>Filter parameters</b>:
/// <ol>
/// 	<li><b>pDomainId</b> As <class>%Integer</class></li>
/// 	<li><b>pEntityList</b> As <class>%List</class> - entities to check for, appearing in a relationship with one another.</li>
/// 	<li><b>pDirectRelation</b> As <class>%Boolean</class> (default 0) - if true, the entities in <var>pEntityList</var> should appear in a direct relationship (within the same CRC) with one another. Otherwise, having the entities appear in the same path is enough for a source to be included.</li>
/// 	<li><b>pIncludeSimilar</b> As <class>%Boolean</class> (default 0) - if true, entities similar to the strings in <var>pEntityList</var> are also considered.</li>
/// </ol>
Class %iKnow.Filters.ContainsRelatedEntitiesFilter Extends %iKnow.Filters.Filter [ Deprecated, System = 4 ]
{

Property Entities As %List;

Property DirectRelation As %Boolean;

Property IncludeSimilar As %Boolean;

Method %OnNew(pDomainId As %Integer, pEntityList As %List, pDirectRelation As %Boolean = 0, pIncludeSimilar As %Boolean = 0) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
		set i%DomainId = pDomainId
		
		// BDB354 - check if required globals are present
		set tGlobs = $s(pDirectRelation:$lb($$$IKBCRCUNIMAP,$$$IKBCRCUNISRC), 1:$lb($$$IKBENTUNIBIT,$$$IKBPATH))
		set:pIncludeSimilar tGlobs = tGlobs _ $lb($$$IKBPARTS)
		$$$IKQBCHECKX(pDomainId,tGlobs,tSC)
		
		$$$IKENSURELISTSTR(pEntityList)
		set i%Entities = pEntityList
		set i%IncludeSimilar = pIncludeSimilar
		set i%DirectRelation = pDirectRelation
		
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
		// first build the list of similar entities per supplied one
		set tCount = $ll(i%Entities)
		
		kill ^||%IKQ.Groups
		for i = 1:1:tCount {
			set tString = $li(i%Entities,i)
			
			if (i%IncludeSimilar) {
				set tSC = ##class(%iKnow.Queries.EntityAPI).GetSimilarIds("^||%IKQ.Groups("_i_")", i%DomainId, tString)
				quit:$$$ISERR(tSC)
			} else {
				set tEntUniId = ##class(%iKnow.Queries.EntityAPI).GetId(i%DomainId, tString)
				quit:'tEntUniId // walk away if this is not an existing entity
				set ^||%IKQ.Groups(i,tEntUniId) = ""
			}
		}
		quit:$$$ISERR(tSC)
		
		if i%DirectRelation {
			
			kill ^||%IK.CrcBits
			set tCombinedGlo = $name(^||%IK.CrcBits(0))
			for i = 1:1:tCount {
				set tEntUniId = "", tGloTo = $name(^||%IK.CrcBits(i))
				for {
					set tEntUniId = $order(^||%IKQ.Groups(i,tEntUniId))
					quit:tEntUniId=""
					
					set tGloFrom = $name(^IRIS.IK.EntUniMToCrcUniBit(i%DomainId, tEntUniId))
					$$$IKMERGEBITSOR(tGloFrom,tGloTo)
					set tGloFrom = $name(^IRIS.IK.EntUniRToCrcUniBit(i%DomainId, tEntUniId))
					$$$IKMERGEBITSOR(tGloFrom,tGloTo)
					set tGloFrom = $name(^IRIS.IK.EntUniSToCrcUniBit(i%DomainId, tEntUniId))
					$$$IKMERGEBITSOR(tGloFrom,tGloTo)
				}
				if (i=1) {
					$$$IKMERGEBITSOR(tGloTo,tCombinedGlo)
				} else {
					$$$IKMERGEBITSAND(tGloTo,tCombinedGlo)
				}
			}
			
			// now translate CRCs into sources
			kill ^||%IK.SrcBits
			set tCrcOff = ""
			for {
				set tCrcOff = $order(^||%IK.CrcBits(0,tCrcOff),1,tCrcBits)
				quit:tCrcOff=""
				
				set tCrcPos = 0
				for {
					set tCrcPos = $bitfind(tCrcBits, 1, tCrcPos+1)
					quit:'tCrcPos
					
					$$$IKGETIDOFFPOS(tCrcId,tCrcOff,tCrcPos)
					
					set tGloFrom = $name(^IRIS.IK.CrcUniToSrcBit(i%DomainId, tCrcId))
					$$$IKMERGEBITSOR(tGloFrom,"^||%IK.SrcBits")
				}
			}
			
			set tOff = ""
			for {
				set tOff = $order(^||%IK.SrcBits(tOff),1,tBits)
				quit:tOff=""
				
				set tSC = ..SetSourceBits(tOff, tBits)
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
			
		} else {
			kill ^||%IK.PathBits
			set tCombinedGlo = $name(^||%IK.PathBits(0))
			for i = 1:1:tCount {
				set tEntUniId = "", tGloTo = $name(^||%IK.PathBits(i))
				for {
					set tEntUniId = $order(^||%IKQ.Groups(i,tEntUniId))
					quit:tEntUniId=""
					
					set tGloFrom = $name(^IRIS.IK.EntUniToPathBit(i%DomainId,tEntUniId))
					$$$IKMERGEBITSOR(tGloFrom,tGloTo)
				}
				if (i=1) {
					$$$IKMERGEBITSOR(tGloTo,tCombinedGlo)
				} else {
					$$$IKMERGEBITSAND(tGloTo,tCombinedGlo)
				}
			}
			
			// now translate paths to sources
			kill ^||%IK.Src
			set tPathOff = ""
			for {
				set tPathOff = $order(^||%IK.PathBits(0,tPathOff),1,tPathBits)
				quit:tPathOff=""
				
				set tPathPos = 0, tPrevLastPath=0
				for {
					set tPathPos = $bitfind(tPathBits,1,tPathPos+1)
					quit:'tPathPos
					
					$$$IKGETIDOFFPOS(tPathId,tPathOff,tPathPos)
					
					continue:tPrevLastPath&&(tPathId<tPrevLastPath) // still in the same src
					
					set tPathBase = $order(^IRIS.IK.PathToSrc(i%DomainId,tPathId),-1,tPathInfo)
					set ^||%IK.Src($li(tPathInfo,1))="", tPrevLastPath = tPathBase + $li(tPathInfo,2)
				}
			}
		
			set tSrcId = "", tPrevOff = 0, tBits=""
			for {
				set tSrcId = $order(^||%IK.Src(tSrcId))
				quit:tSrcId=""
				
				$$$IKBITOFFPOS(tSrcId,tOff,tPos)
				
				if (tPrevOff'=tOff) {
					set:tPrevOff tSC = ..SetSourceBits(tPrevOff, tBits)
					quit:$$$ISERR(tSC)
					set tBits = "", tPrevOff = tOff
				}
				set $bit(tBits,tPos) = 1
			}
			quit:$$$ISERR(tSC)
			set:tPrevOff tSC = ..SetSourceBits(tPrevOff,tBits)
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	kill ^||%IK.SrcBits, ^||%IK.PathBits, ^||%IK.CrcBits, ^||%IKQ.Groups
	quit tSC
}

ClassMethod RestoreFilterFromStringInternal(filterParams As %String) As %iKnow.Filters.Filter [ Private ]
{
	set tLength = $length(filterParams,"|")
	quit ..%New($piece(filterParams,"|",1), $lfs($piece(filterParams,"|",2,tLength-2)), $piece(filterParams,"|",tLength-1), $piece(filterParams,"|",tLength))
}

Method ToString() As %String
{
	quit $classname()_"|"_i%DomainId_"|"_$lts(i%Entities)_"|"_i%DirectRelation_"|"_i%IncludeSimilar
}

Method EntitiesSet(pEntities As %List) As %Status [ Internal, ServerOnly = 1 ]
{
	quit:$ls(pEntities,i%Entities) $$$OK
	set i%Entities = pEntities
	quit ..ChangeParams()
}

Method IncludeSimilarSet(pIncludeSimilar As %Boolean) As %Status [ Internal, ServerOnly = 1 ]
{
	quit:pIncludeSimilar=i%IncludeSimilar $$$OK
	set i%IncludeSimilar = pIncludeSimilar
	quit ..ChangeParams()
}

Method DirectRelationSet(pDirectRelation As %Boolean) As %Status [ Internal, ServerOnly = 1 ]
{
	quit:pDirectRelation=i%DirectRelation $$$OK
	set i%DirectRelation = pDirectRelation
	quit ..ChangeParams()
}

}
