/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>The InterSystems IRIS NLP iKnow technology is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail.</p>
/// <p>This is the main Query class to retrieve Paths as identified by the engine.
/// Paths are sequences of concepts and relations that form a meaningful sub-section of a sentence.</p>
Class %iKnow.Queries.PathAPI Extends %iKnow.Queries.AbstractAPI [ Deprecated, System = 4 ]
{

/// <p>Returns the sequence of entity values corresponding to the specified path as a
/// <class>%List</class>.</p>
/// <p>When specifying a Virtual Source ID, it will treat the pathId as a virtual one, 
/// in the context of that vSrcId.</p>
/// <p>If stemming is enabled for this domain through the $$$IKPSTEMMING domain parameter, you can
/// use <var>pUseStems</var>=1 to get the stems rather than the entities for this path.</p>
ClassMethod GetValue(domainid As %Integer, pathid As %Integer, vSrcId As %Integer = 0, Output pSC As %Status, pUseStems As %Boolean = 0) As %List
{
	set pSC = $$$OK, pathEnts=""
	try {
		$$$IKCHECKPRIVREADX(pSC)
		if vSrcId && (domainid=0) {} else { $$$CHECKDOMAINEXISTSX(domainid,pSC) }
		
		if pUseStems { $$$CHECKSTEMMINGX(domainid,pSC) }
		
		set path = ..GetEntIds(domainid, pathid, vSrcId, pUseStems)
		quit:path=""
		
		set ptr = 0, i = 0
		while $listnext(path, ptr, id) {
			continue:'id
			set $list(pathEnts, $i(i)) = ##class(%iKnow.Queries.EntityAPI).GetValueInternal(domainid, id, vSrcId, pUseStems)
		}
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit pathEnts
}

/// Internal method. See <method>GetPathId</method>
ClassMethod GetEntIds(pDomainId As %Integer, pPathId As %Integer, vSrcId As %Integer = 0, pUseStems As %Boolean = 0) As %List [ Internal ]
{
	set tUsePathId = $$$IKVERSIONBEFORE(pDomainId,$$$IKVERSIONOPTIONALGLOBALS) && 'pUseStems
	if 'tUsePathId {
		$$$IKBFLAGS(pDomainId,tFlags)
		set tFlag = $a(tFlags,$$$IKBPATH)
		if (tFlag = $$$IKBFALWAYS) || ((tFlag'=$$$IKBFNEVER) && $$$IKBUPTODATE(pDomainId)) { 
			set tUsePathId = 1 
		}
	}
	if tUsePathId {
		quit $s(vSrcId:$get(^IRIS.IKV.PathId(pDomainId, $zabs(vSrcId), pPathId)), 1:$get(^IRIS.IK.PathId(pDomainId, pPathId)))
	} else {
		set path = $s(vSrcId:$get(^IRIS.IKV.PathToEntOcc(pDomainId, $zabs(vSrcId), pPathId)), 1:$get(^IRIS.IK.PathToEntOcc(pDomainId, pPathId)))
		quit:path="" ""
		set l = $ll(path)
		for i = 1:1:l {
			set $li(path,i) = $lg($s(vSrcId:^IRIS.IK.EntOccId(pDomainId,$zabs(vSrcId),$li(path,i)), 1:^IRIS.IK.EntOccId(pDomainId,$li(path,i))), $s(pUseStems:10,1:1))
		}
		quit path
	}
}

Parameter GetPathIdEXP [ Internal ] = 1;

/// Left in for backwards compatibility. Use <method>GetId</method> instead.
ClassMethod GetPathId(domainid As %Integer, entityList As %List, vSrcId As %Integer = 0) As %Integer [ Internal ]
{
	quit ..GetId(domainid,entityList,vSrcId)
}

/// <p>This method will try to find a path corresponding to the supplied list of entities in the
/// specified order. If no path is found, "" is returned.</p>
/// <p>When specifying a Virtual Source ID, it will treat the path as a virtual one, 
/// in the context of that vSrcId.</p>
ClassMethod GetId(domainid As %Integer, entityList As %List, vSrcId As %Integer = 0, Output sc As %Status = {$$$OK}) As %Integer
{
	$$$IKQBEGINR("^||%IK.GetPathIdBits",sc,-1)
	if vSrcId && (domainid=0) {} else { $$$CHECKDOMAINEXISTSR(domainid,sc,-1) }
	
	if 'vSrcId {
		$$$IKQBCHECKR(domainid,$$$IKBENTUNIBIT,sc,-1)
	}
	
	set entIdList = $lb(), vSrcId = $zabs(vSrcId)
	
	// as there is no direct way to get to the applicable path, we'll have to
	// find it based on the set of paths containing all the supplied path elements
	// first
	set first = 1, ptr = 0, i = 0
	while $listnext(entityList, ptr, entity) {
		
		set entId = ##class(%iKnow.Queries.EntityAPI).GetIdInternal(domainid, .entity, vSrcId, 0)
		set $list(entIdList, $i(i)) = entId
		
		if ((entId = 0) || (entId = "")) {
			continue
		}
		
		if ('vSrcId) {
			set pathOffset = ""
			for {
				set pathOffset = $order(^IRIS.IK.EntUniToPathBit(domainid, entId, pathOffset), 1, pathBits)
				quit:pathOffset=""
				
				if (first) {
					set ^||%IK.GetPathIdBits(pathOffset) = pathBits, first = 0
				} else {
					set ^||%IK.GetPathIdBits(pathOffset) = $bitlogic(pathBits & ^||%IK.GetPathIdBits(pathOffset))
				}
			}
		}
	}
	
	if (vSrcId) {
		
		// for virtual cases, we'll just loop through all paths for that vSrcId
		set pathId = ""
		for {
			set pathId = $order(^IRIS.IKV.PathId(domainid, vSrcId, pathId),1,path)
			quit:pathId=""
			quit:$listsame(path,entIdList)
		}
		quit pathId
		
	} else {
		set thePathId = ""
		set pathOffset = ""
		for {
			set pathOffset = $order(^||%IK.GetPathIdBits(pathOffset), 1, pathBits)
			quit:pathOffset=""
			quit:thePathId'=""
		
			set pathPos = 0
			for {
				set pathPos = $bitfind(pathBits, 1, pathPos + 1)
				quit:pathPos=0
			
				$$$IKGETIDOFFPOS(pathId,pathOffset,pathPos)
				set path = ..GetEntIds(domainid, pathId)
			
				// now check if this path, containing all entities in the supplied pathlist,
				// matches the pathlist in order
				if ($listlength(path) = $listlength(entIdList)) {
					set match = 1
					for i = 1:1:$listlength(path) {
						if ($list(path, i) '= $list(entIdList, i)) {
							set match = 0
							quit
						}
					}
					if (match = 1) {
						set thePathId = pathId
						quit
					}
				}
			}
		}
		$$$IKQEND("^||%IK.GetPathIdBits",thePathId)
	}
}

/// Returns the sentence ID in which the supplied path ID occurs
ClassMethod GetSentenceId(domainId As %Integer, pathId As %Integer, Output sc As %Status = {$$$OK}, vSrcId As %Integer = 0) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	if vSrcId && (domainId=0) {} else { $$$CHECKDOMAINEXISTSR(domainId,sc,-1) }
	if ('vSrcId) {
	    set pathBase = $order(^IRIS.IK.PathToSent(domainId, pathId),-1, pathDetails)
	} else {
	    set pathBase = $order(^IRIS.IKV.PathToSent(domainId, $zabs(vSrcId), pathId),-1, pathDetails)
	}
    quit:pathBase="" -1 // inexistent path
    quit:(pathBase+$lg(pathDetails,2))<pathId -1 // inexistent path (gap)
    quit +$lg(pathDetails,1)
}

/// Returns the source ID in which the supplied path ID occurs
ClassMethod GetSourceId(domainId As %Integer, pathId As %Integer, Output sc As %Status = {$$$OK}) As %Integer
{
	$$$IKCHECKPRIVREADR(sc,-1)
	$$$CHECKDOMAINEXISTSR(domainId,sc,-1)
	$$$IKQBCHECKR(domainId,$$$IKBPATH,sc,-1)
    set pathBase = $order(^IRIS.IK.PathToSrc(domainId, pathId),-1, pathDetails)
    quit:pathBase="" -1 // inexistent path
    quit:(pathBase+$lg(pathDetails,2))<pathId -1 // inexistent path (gap)
    quit +$lg(pathDetails,1)
}

Parameter GetEntitiesRT = "position:%Integer,entOccId:%Integer,entUniId:%Integer,entityValue:%String,literal:%String,role:%Integer,stemUniId:%Integer,stemValue:%String";

/// <p>Returns a detailed overview of the entities <var>pathId</var> consists of, including their
/// unique and occurrence IDs, positions, roles and literal value.</p>
/// <p>The last two columns will only contain data if stemming is enabled for this domain through
///  the $$$IKPSTEMMING domain parameter.</p>
ClassMethod GetEntities(ByRef result, domainId As %Integer, pathId As %Integer, vSrcId As %Integer = 0) As %Status
{
	$$$IKQBEGINTRY(result,"",tSC)
	if vSrcId && (domainId'=0) { $$$CHECKDOMAINEXISTSX(domainId,tSC) }
	set tUseStemming = ($$$GETPARAM(domainId,$$$IKPSTEMMING,0)'=0)
	
	set pathToEntOccGlo = $$$IKVGLOBNAME(domainId,"PathToEntOcc",vSrcId)
	set entOccGlo = $$$IKVGLOBNAME(domainId,"EntOccId",vSrcId)
	set sentIdGlo = $$$IKVGLOBNAME(domainId, "SentId", vSrcId)
	set litUniIdGlo = $$$IKVGLOBNAME(domainId, "LitUniId", vSrcId)
	
	set entOccs = $g(@pathToEntOccGlo@(pathId))
	set entOccCount = $ll(entOccs)
	for position = 1:1:entOccCount {
		
		set entOccId = $li(entOccs,position)
		set entOcc = @entOccGlo@(entOccId)
		set entUniId = $li(entOcc,1)
		set role = $li(entOcc,2)
		set entValue = ##class(%iKnow.Queries.EntityAPI).GetValueInternal(domainId,entUniId,vSrcId)
        set id = $li(@sentIdGlo@($li(entOcc, 3)), $li(entOcc, 4))
        set literal = $s(id>0:entValue, 1:$zstrip(@litUniIdGlo@(-id),"<W"))
        set data = $lb(position,entOccId,entUniId,entValue,literal,role,,)
        
        if (tUseStemming) {
			if (role '= $$$ENTTYPEPATHREL) { // PathRelevants are not stemmed
				set stemUniId = $lg(entOcc,10)
				set $li(data,7,8) = $lb(stemUniId, ##class(%iKnow.Queries.EntityAPI).GetValueInternal(domainId, stemUniId, vSrcId, 1))
			}
        }
		
		$$$IKQADDRESULT(result,position,data)
	}
	
	$$$IKQENDCATCH(result,"",tSC)
}

Parameter GetByEntitiesRT = "pathId:%Integer,entIds:%List";

/// <p>This method will return all Paths containing any (if <i>setop</i> = $$$UNION) or all 
/// (if <i>setop</i> = $$$INTERSECT) of the entities in the supplied <i>entitylist</i>.</p>
/// <p>The scope of this query can be limited through supplying a <class>%iKnow.Filters.Filter</class> object for the <i>filter</i>
/// parameter to restrict the result to those Paths occurring in any source satisfying the filter
/// criteria.</p>
/// <p>Results are sorted by decreasing path ID.</p>
/// <p>If stemming is enabled for this domain through $$$IKPSTEMMING, paths containing any actual
/// form of the entities in <var>entitylist</var> will be returned. Use <var>pActualFormOnly</var>=1
/// to retrieve only those paths containing the actual forms in <var>entitylist</var>. This
/// argument is ignored if stemming is not enabled.</p>
ClassMethod GetByEntities(ByRef result, domainid As %Integer, entitylist As %List, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "", setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %Status
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainid)
	quit:entitylist="" $$$OK

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTSTR(entitylist)
	
	// unravel the entitylist into a clean %List
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly
	set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityList(domainid, entitylist, .entIdList,,, $s('tIncludeActuals:0, setop=$$$UNION:1, 1:2))
	quit:$$$ISERR(tSC) tSC
	
	// forward to ..GetPathsInternal
	quit ..GetByEntitiesInternal(.result, domainid, .entIdList, page, pagesize, filter, setop)
}

Parameter GetByEntityIdsRT = "pathId:%Integer,entIds:%List";

/// <p>Retrieves paths based on entity IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByEntityIds(ByRef result, domainid As %Integer, entityidlist As %List, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "", setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %Status
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainid)
	quit:entityidlist="" $$$OK

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTNUM(entityidlist)
	
	// clean up the entityidlist into a clean %List
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly
	set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityIdList(domainid, entityidlist, .cleanIdList,,, $s('tIncludeActuals:0, setop=$$$UNION:1, 1:2))
	quit:$$$ISERR(tSC) tSC
	
	// forward to ..GetPathsInternal
	quit ..GetByEntitiesInternal(.result, domainid, .cleanIdList, page, pagesize, filter, setop)
}

ClassMethod GetByEntitiesInternal(ByRef result, domainid As %Integer, ByRef entitylist, page As %Integer, pagesize As %Integer, filter As %iKnow.Filters.Filter, setop As %Integer) As %Status [ Internal, Private ]
{
	$$$IKQBEGINTRY(result,"",tSC)
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	quit:'entitylist
	
	$$$IKQBCHECKX(domainid,$$$IKBENTUNIBIT,tSC)
	
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	// filtering options:
	// 	- using pathFilter: [FilteredSourceCount]*[PathOffsetCount]  bitstring reads
	// 	- using isFiltered: MIN([1/FilterSelectivity]*[page*pagesize], [PathCount]*[EntitySelectivity]) bitstring reads
	if $isobject(filter) {
		if (filter.IsValid($$$IKFPATH)) {
			set usePathFilter = 1
		} else {
			set costUsingPathFilter = filter.FilteredSourceCount * ..GetMaxOffset(domainid,$$$IKFPATH)
			set costUsingIsFiltered1 = $s(filter.Selectivity:(page * pagesize / filter.Selectivity), 1:0)
			set costUsingIsFiltered2 = ..GetMaxId(domainid,$$$IKFPATH) * ..GetEntitySelectivity(domainid,.entitylist,.tSC)
			quit:$$$ISERR(tSC)
			set costUsingIsFiltered = $s('costUsingIsFiltered1:costUsingIsFiltered2, (costUsingIsFiltered1<costUsingIsFiltered2):costUsingIsFiltered1, 1:costUsingIsFiltered1)
			set usePathFilter = (costUsingPathFilter < costUsingIsFiltered)
		}
	}
	
	// define last path offset
	if $isobject(filter) {
		set lastSrcId = filter.GetFirstFilteredSource(-1)
		set srcDetails = $g(^IRIS.IK.SrcDetails(domainid,lastSrcId))
		set lastPathId = $lg(srcDetails,7)+$lg(srcDetails,8)
	} else {
		set lastPathId = $order(^IRIS.IK.PathDetails(domainid,""),-1)
	}
	$$$IKBITOFFPOS(lastPathId,lastPathOffset,lastPathPos)
	
	for tPathOffset = lastPathOffset:-1:1 {
		set mergedbits = ""
		
		// first loop through the entities
		set entId = "", tIsFirstEntity = 1
		for {
			set entId = $order(entitylist(entId))
			quit:entId=""
			
			// based on the setop, we either AND or OR the bitstrings from ^IRIS.IK.EntUniToPathBit
			if (setop = $$$UNION) {
				
				set mergedbits = $bitlogic(mergedbits | ^IRIS.IK.EntUniToPathBit(domainid, entId, tPathOffset))
				
			} elseif (setop = $$$INTERSECT) {
				
				if $d(entitylist(entId))>1 { 
				
					// BDB522: multi-level indicates the sub-level needs to be ORed before ANDing
					set tSubEntId = "", tTheseBits = ""
					for {
						set tSubEntId = $order(entitylist(entId,tSubEntId))
						quit:tSubEntId=""
						set tTheseBits = $bitlogic(tTheseBits | ^IRIS.IK.EntUniToPathBit(domainid, tSubEntId, tPathOffset))
					}
					
				} else {
					set tTheseBits = $get(^IRIS.IK.EntUniToPathBit(domainid, entId, tPathOffset))
				}
				
				if (tIsFirstEntity) {
					set mergedbits = tTheseBits
				} else {
					set mergedbits = $bitlogic(mergedbits & tTheseBits)
				}
				set tIsFirstEntity = 0
			}
				
		}
		
		// combine with the applicable filter, if any
		if ($isobject(filter) && usePathFilter) {
			set filterBits = filter.GetPathFilter(tPathOffset)
			set mergedbits = $bitlogic(mergedbits & filterBits)
		}
		
		// now add the entries satisfying the resulting bitstring
		set pathPos = 1
		for {
			
			// find the next bit, backwards
			set pathPos = $bitfind(mergedbits, 1, pathPos-1, -1)
			quit:pathPos=0
			
			// calculcate pathId
			$$$IKGETIDOFFPOS(pathId,tPathOffset,pathPos)
			
			// check if filtered
			if ($isobject(filter) && 'usePathFilter) {
				continue:'filter.IsFiltered(pathId,$$$IKFPATH)
			}
			
			// check if we're in the paging window
			set count = count + 1
			$$$IKCHECKPAGING(usePaging,first,last,count)
			
			// build path record to be added to ^||%IK.GetPathsInternal
			set pathDetails = ..GetEntIds(domainid, pathId)
			$$$IKQADDRESULT(result,count,$lb(pathId, pathDetails))
			
			// we should end here as well, as we're walking backwards through mergedbits
			quit:pathPos=1
		}
		
		// also quit this loop if we're done
		$$$IKCHECKPAGING(usePaging,0,last,count)
	}
	
	$$$IKQENDCATCH(result,"",tSC)
}

Parameter GetBySourceRT = "pathId:%Integer,entIds:%List";

/// <p>Retrieves the paths appearing in any of the sources supplied through <i>sourceidlist</i>.</p>
/// <p>To get the paths of a virtual source, only a single virtual source can be supplied using
/// its negative ID value (otherwise, -1 is returned).</p>
ClassMethod GetBySource(ByRef result, domainid As %Integer, sourceidlist As %List, page As %Integer = 1, pagesize As %Integer = 10) As %Status
{
	$$$IKQBEGINTRY(result,"",tSC)
	if (domainid'=0) { $$$CHECKDOMAINEXISTSX(domainid,tSC) }
	quit:sourceidlist=""
	
	// accepting single source IDs (non-list) as well
	$$$IKENSURELISTNUM(sourceidlist)
	
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	// check if looking for a virtual source
	if ($li(sourceidlist,1)<0) && ($ll(sourceidlist)=1) {
		set vSrcId = -$li(sourceidlist,1)
		$$$CHECKVSRCIDEXISTSX(domainid,vSrcId,tSC)
		
		set pathId = ""
		for {
			set pathId = $order(^IRIS.IKV.PathId(domainid, vSrcId, pathId), 1, details)
			quit:pathId=""
			
			set count=$i(count)
			$$$IKCHECKPAGING(usePaging,first,last,count)
			
			$$$IKQADDRESULT(result,count,$lb(+pathId, details))
		}
		quit
	}
	
	set ptr=0, srcId=0
	while $listnext(sourceidlist, ptr, srcId) {
		continue:srcId=""
		quit:srcId<0
		
		set srcDetails = $g(^IRIS.IK.SrcDetails(domainid, srcId))
		continue:srcDetails=""
		
		set base = +$lg(srcDetails,7)
		set pathCount = +$lg(srcDetails,8)
		for pathId = base+1:1:base+pathCount {
			
			// check if we're in the paging window
			set count = count + 1
			$$$IKCHECKPAGING(usePaging,first,last,count)
			
			// add to result list
			$$$IKQADDRESULT(result,count,$lb(+pathId, ..GetEntIds(domainid,pathId)))
		}
	}
	
	// if we ran into a negative srcId, return error
	if (srcId<0) { set tSC = $$$ERROR($$$IKOnlyOneVSrcSupported)  quit }
	
	$$$IKQENDCATCH(result,"",tSC)
}

/// <p>Returns the number of paths in a domain, optionally restricted to those appearing in a source
/// satisfying the <class>%iKnow.Filters.Filter</class> object supplied through <i>filter</i>.</p>
ClassMethod GetCountByDomain(domainid As %Integer, filter As %iKnow.Filters.Filter = "", Output sc As %Status = {$$$OK}) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	$$$IKQFILTEROBJECTR(domainid,filter,sc,-1)
	set total = 0
	
	if ($isobject(filter)) {
		
		set pathOffset = ""
		for {
			set pathOffset = filter.GetNextPathFilterOffset(pathOffset, .pathBits)
			quit:pathOffset=""
			
			set total = total + $bitcount(pathBits, 1)
		}
		
	} else {
		
		set srcId = ""
		for {
			set srcId = $order(^IRIS.IK.SrcDetails(domainid, srcId),1,details)
			quit:srcId=""
			
			set total = total + $li(details,8)
		}
	}
	
	quit total
}

/// <p>Returns the total number of paths in the sources specified through <i>sourceidlist</i>.
/// Use negative source IDs to refer to virtual sources.</p>
ClassMethod GetCountBySource(domainid As %Integer, sourceidlist As %List, Output sc As %Status = {$$$OK}) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	if (domainid'=0) { $$$CHECKDOMAINEXISTSR(domainid,sc,-1) }
	quit:sourceidlist="" 0
	
	// accepting single source IDs (non-list) as well
	$$$IKENSURELISTNUM(sourceidlist)
	
	set total = 0, ptr = 0
	while $listnext(sourceidlist, ptr, srcId) {
		continue:'+srcId
		$$$CHECKASRCIDEXISTSX(domainid,srcId,srcDetails,vSrcId,sc)
		set total = total + $lg(srcDetails,8)
	}
	quit:$$$ISERR(sc) -1
	
	quit total
}

/// <p>Retrieves the number of paths containing the specified entities.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByEntities(domainid As %Integer, entitylist As %List, filter As %iKnow.Filters.Filter = "", setop As %Integer = {$$$UNION}, Output sc As %Status = {$$$OK}, pActualFormOnly As %Boolean = 0) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	quit:entitylist="" 0

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTSTR(entitylist)
	
	// unravel the entitylist into a clean %List
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly
	set sc = ##class(%iKnow.Queries.EntityAPI).TranslateEntityList(domainid, entitylist, .entIdList,,, $s('tIncludeActuals:0, setop=$$$UNION:1, 1:2))
	quit:$$$ISERR(sc) -1
	
	// forward to ..GetTotPathsInternal
	quit ..GetCountByEntitiesInternal(domainid, .entIdList, filter, setop, .sc)
}

/// <p>Retrieves the number of paths containing the specified entity IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByEntityIds(domainid As %Integer, entityidlist As %List, filter As %iKnow.Filters.Filter = "", setop As %Integer = {$$$UNION}, Output sc As %Status = {$$$OK}, pActualFormOnly As %Boolean = 0) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	quit:entityidlist="" 0

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTNUM(entityidlist)
	
	// clean up the entityidlist into a clean %List
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly
	set sc = ##class(%iKnow.Queries.EntityAPI).TranslateEntityIdList(domainid, entityidlist, .cleanIdList,,, $s('tIncludeActuals:0, setop=$$$UNION:1, 1:2))
	quit:$$$ISERR(sc) -1
	
	// forward to ..GetTotPathsInternal
	quit ..GetCountByEntitiesInternal(domainid, .cleanIdList, filter, setop, .sc)
}

ClassMethod GetCountByEntitiesInternal(domainid As %Integer, ByRef entitylist, filter As %iKnow.Filters.Filter, setop As %Integer, Output sc As %Status = {$$$OK}) As %Integer [ Internal, Private ]
{
	set sc = $$$OK
	$$$IKQFILTEROBJECTR(domainid,filter,sc,-1)
	quit:'entitylist 0
	
	$$$IKQBCHECKR(domainid,$$$IKBENTUNIBIT,sc,-1)
	
	set total = 0
	
	// filtering options:
	// 	- using pathFilter: [FilteredSourceCount]*[PathOffsetCount]  bitstring reads
	// 	- using isFiltered: [PathCount]*[EntitySelectivity] bitstring reads
	if $isobject(filter) {
		if (filter.IsValid($$$IKFPATH)) {
			set usePathFilter = 1
		} else {
			set costUsingPathFilter = filter.FilteredSourceCount * ..GetMaxOffset(domainid,$$$IKFPATH)
			set costUsingIsFiltered = ..GetMaxId(domainid,$$$IKFPATH) * ..GetEntitySelectivity(domainid,.entitylist,.sc)
			quit:$$$ISERR(sc)
			set usePathFilter = (costUsingPathFilter < costUsingIsFiltered)
		}
	}
	
	// define last path offset
	if $isobject(filter) {
		set lastSrcId = filter.GetFirstFilteredSource(-1)
		set srcDetails = $g(^IRIS.IK.SrcDetails(domainid,lastSrcId))
		set lastPathId = $lg(srcDetails,7)+$lg(srcDetails,8)
	} else {
		set lastPathId = $order(^IRIS.IK.PathDetails(domainid,""),-1)
	}
	$$$IKBITOFFPOS(lastPathId,lastPathOffset,lastPathPos)
	
	for tPathOffset = 1:1:lastPathOffset {
		set mergedbits = ""
		
		// first loop through the entities
		set entId = "", tIsFirstEntity = 1
		for {
			set entId = $order(entitylist(entId))
			quit:entId=""
			
			// based on the setop, we either AND or OR the bitstrings from ^IRIS.IK.EntUniToPathBit
			if (setop = $$$UNION) {
				
				set mergedbits = $bitlogic(mergedbits | ^IRIS.IK.EntUniToPathBit(domainid, entId, tPathOffset))
				
			} elseif (setop = $$$INTERSECT) {
				
				if $d(entitylist(entId))>1 { 
				
					// BDB522: multi-level indicates the sub-level needs to be ORed before ANDing
					set tSubEntId = "", tTheseBits = ""
					for {
						set tSubEntId = $order(entitylist(entId,tSubEntId))
						quit:tSubEntId=""
						set tTheseBits = $bitlogic(tTheseBits | ^IRIS.IK.EntUniToPathBit(domainid, tSubEntId, tPathOffset))
					}
					
				} else {
					set tTheseBits = $get(^IRIS.IK.EntUniToPathBit(domainid, entId, tPathOffset))
				}
				
				// for $$$INTERSECT, the first bitstring should be taken as is (no ANDing)
				if (tIsFirstEntity) {
					set mergedbits = tTheseBits
				} else {
					set mergedbits = $bitlogic(mergedbits & tTheseBits)
				}
				set tIsFirstEntity = 0
			}
				
		}
		
		// combine with the applicable filter, if any
		if ($isobject(filter)) {
			
			if (usePathFilter) {
				
				// if we can use the path filter, just merge bits
				set filterBits = filter.GetPathFilter(tPathOffset)
				set mergedbits = $bitlogic(mergedbits & filterBits)
				
			} else {
				
				// otherwise, verify each filtered pathId individually against the filter
				set pos = 0
				for {
					set pos = $bitfind(mergedbits, 1, pos+1)
					quit:pos=0
					
					$$$IKGETIDOFFPOS(pathId,tPathOffset,pos)
					set $bit(mergedbits, pos) = filter.IsFiltered(pathId,$$$IKFPATH)
				}
				
			}
		}
		
		// now count the entries satisfying the criteria
		set total = total + $bitcount(mergedbits, 1)
	}
	
	quit total
}

/// clean a list of PathIds from duplicates and inexistent ids
ClassMethod TranslatePathIdList(domainid As %Integer, pathIdList As %List, Output ids, vSrcId As %Integer = 0, Output unMatchedCount As %Integer) As %Status [ Internal ]
{
	kill ids
	
	set unMatchedCount = 0
	set pathIdGlo = $$$IKVGLOBNAME(domainid,"PathToEntOcc",vSrcId)
	
	set ptr = 0
	while $listnext(pathIdList, ptr, pathId) {
		continue:pathId=""
		if $data(@pathIdGlo@(pathId)) { set ids(pathId) = "" } else { set unMatchedCount = unMatchedCount + 1 }
	}
	quit $$$OK
}

Parameter GetAttributesRT = "attTypeId:%Integer,attType:%String,start:%Integer,span:%Integer,properties:%String";

/// <p>Returns all attributes for a given path. Any named attribute properties are also
/// included through sub-nodes (not available through SQL or SOAP): 
/// <blockquote>pResult(<i>rowNumber</i>, <i>propertyName</i>) = <i>propertyValue</i></blockquote></p>
/// <p>Please note this query only returns path-level attributes and not those attributes applying
/// to individual entities or words within entities. To retrieve these, use <method>GetOccurrenceAttributes</method>
/// in <class>%iKnow.Queries.EntityAPI</class>.</p>
ClassMethod GetAttributes(ByRef pResult, pDomainId As %Integer, pPathId As %Integer, vSrcId As %Integer = 0) As %Status
{
	$$$IKQBEGINTRY(pResult,"",tSC)
	if vSrcId && (pDomainId=0) {} else { $$$CHECKDOMAINEXISTSX(pDomainId,tSC) }
	$$$IKCHECKVERSIONATLEASTX(pDomainId,$$$IKVERSIONATTRIBUTES,tSC)
	if (vSrcId) { $$$CHECKVSRCIDEXISTSX(pDomainId,vSrcId,tSC) }
	
	set gAttPath = $$$IKVGLOBNAME(pDomainId,"Att.Path",vSrcId)
	
	set tAttTypeId = ""
	for {
		set tAttTypeId = $order(@gAttPath@(pPathId, tAttTypeId))
		quit:tAttTypeId=""
		
		set tStartPos=""
		for {
			set tStartPos = $order(@gAttPath@(pPathId, tAttTypeId, tStartPos), -1, tAtt)
			quit:tStartPos=""
			
			set tAttName = $$$IKATTTYPENAME(tAttTypeId)
			set tSpan = +$lg(tAtt,1), tProps = $li(tAtt,2,*)
			$$$IKQADDRESULT(pResult,$i(tCount),$lb(+tAttTypeId,tAttName,+tStartPos,tSpan,$lts(tProps,,1)))
			
			set tSC = ##class(%iKnow.Queries.EntityAPI).BuildAttributePropArray(tAttTypeId,tProps,.tPropArray)
			quit:$$$ISERR(tSC)
			$$$IKQMERGERESULT(pResult,tCount,tPropArray)
		}
		quit:$$$ISERR(tSC)
	}
	
	$$$IKQENDCATCH(pResult,"",tSC)
}

}
