/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%IKInclude, %IKPublic)

/// <p>The InterSystems IRIS NLP iKnow technology is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail.</p>
/// Main class for retrieving dominant terms from sources.
Class %iKnow.Semantics.DominanceAPI Extends %iKnow.Queries.AbstractAPI [ Deprecated, System = 4 ]
{

Parameter GetTopRT = "entUniId:%Integer,entity:%String,score:%Numeric";

/// <p>Returns the top entities for this domain, sorted by their aggregated dominance values.
/// <p><var>pAggregation</var> defines how to aggregate the source-level values. Currently the only
/// supported value is "AVG", which just calculates a regular average as a fast approximation.
/// Future versions will offer more advanced aggregation modes (which may be slower to calculate). </p>
ClassMethod GetTop(ByRef pResult, pDomainId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %iKnow.Filters.Filter = "", pAggregation As %String = "AVG", pEntRole As %Integer = {$$$SDCONCEPT}, pSkipLists As %List = "") As %Status
{
	new %IKBuildFlags
	$$$IKQBEGINTRY(pResult,"^||%IK.Dom",tSC)
	$$$CHECKDOMAINEXISTSX(pDomainId,tSC)

	
	if (pAggregation'="AVG") { set tSC = $$$ERROR($$$InvalidArgument)  quit }
	if '$lf($lb($$$SDCONCEPT,$$$SDRELATION,$$$SDSTEMCONCEPT,$$$SDSTEMRELATION),pEntRole) { set tSC = $$$ERROR($$$InvalidArgument)  quit }
	
	set tUseStemming = (pEntRole=$$$SDSTEMCONCEPT) || (pEntRole=$$$SDSTEMRELATION)
	if tUseStemming && ($$$GETPARAM(pDomainId,$$$IKPSTEMMING,0)=0) {
		set tSC = $$$ERROR($$$IKStemmingNotEnabled)
		quit
	}
	
	$$$IKBUILDSKIPLIST(pDomainId,pSkipLists,0,tUseStemming)

	$$$IKBFLAGS(pDomainId,%IKBuildFlags)
	$$$IKSETPAGINGVARS(pPage,pPageSize,tUsePaging,tFirst,tLast,tCount)
	set tRecordCount = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(pDomainId, pFilter)
	
	// if we have the fully sorted global, stick with it
	if (pFilter="") && $$$IKBUILD($$$IKBDOMPROF) {
		set tValue = ""
		for {
			set tValue = $order(^IRIS.IK.SD.DomProf(pDomainId,pEntRole,tValue))
			quit:tValue=""
			set tEntUniId=""
			for {
				set tEntUniId = $order(^IRIS.IK.SD.DomProf(pDomainId,pEntRole,tValue,tEntUniId))
				quit:tEntUniId=""
				set tCount=tCount+1
				continue:$$$IKISSKIPLISTED(tEntUniId)
				$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
				$$$IKQADDRESULT(pResult,tCount,$lb(+tEntUniId, ##class(%iKnow.Queries.EntityAPI).GetValueInternal(pDomainId,tEntUniId,, tUseStemming), +$justify(-tValue/tRecordCount,0,4)))
			}
			quit:tUsePaging&&(tCount>tLast)
		}
		quit
	}
	
	if (pFilter="") && 'tUseStemming && $$$IKBUILD($$$IKBENTUNIDET) {
		$$$IKSORTBEGIN(^||%IK.Dom)
		set tEntUniId="", tLP = 6+pEntRole
		for {
			set tEntUniId = $order(^IRIS.IK.EntUniDetails(pDomainId,tEntUniId),1,d)
			quit:tEntUniId=""
			set:$ld(d,tLP,v)&&v ^||%IK.Dom(-v,tEntUniId)=""
		}
		set x = $sortend(^||%IK.Dom)
	} elseif (pFilter="") && tUseStemming && $$$IKBUILD($$$IKBSTEMUNIDET) {
		$$$IKSORTBEGIN(^||%IK.Dom)
		set tEntUniId="", tLP = 6+pEntRole
		for {
			set tEntUniId = $order(^IRIS.IK.StemUniDetails(pDomainId,tEntUniId),1,d)
			quit:tEntUniId=""
			set:$ld(d,tLP,v)&&v ^||%IK.Dom(-v,tEntUniId)=""
		}
		set x = $sortend(^||%IK.Dom)
	} else {
		if (pFilter="") {
			set pFilter = ##class(%iKnow.Filters.NoFilter).%New(pDomainId)
		} else {
			$$$IKQFILTEROBJECTX(pDomainId,pFilter,tSC)
		}
		set tJobN = +$job, tLP = 3+pEntRole
		kill ^IRIS.Temp.IK.Dom(tJobN)
		if pFilter.FilteredSourceCount<1000 {
			set tOffset = ""
			for {
				set tOffset = pFilter.GetNextSourceFilterOffset(tOffset, .tBits)
				quit:tOffset=""
				do ..GetTopJob(pDomainId,tOffset,tBits,tJobN,tLP,tUseStemming)
			}
		} else {
			#dim tWorkMgr As %SYSTEM.WorkMgr
			set tWorkMgr = $system.WorkMgr.Initialize("", .tSC)
			quit:$$$ISERR(tSC)
			
			set tOffset = ""
			for {
				set tOffset = pFilter.GetNextSourceFilterOffset(tOffset, .tBits)
				quit:tOffset=""
				
				set tSC = tWorkMgr.Queue("##class(%iKnow.Semantics.DominanceAPI).GetTopJob",pDomainId,tOffset,tBits,tJobN,tLP,tUseStemming)
				quit:$$$ISERR(tSC)
			}
			
			set tSC = tWorkMgr.Sync()
			quit:$$$ISERR(tSC)
		}
	
		$$$IKSORTBEGIN(^||%IK.Dom)
		set tEntUniId = ""
		for {
			set tEntUniId = $order(^IRIS.Temp.IK.Dom(tJobN,tEntUniId),1,tValue)
			quit:tEntUniId=""
			
			set ^||%IK.Dom(-tValue,tEntUniId)=""
		}
		set x = $sortend(^||%IK.Dom)
		kill:$g(tJobN) ^IRIS.Temp.IK.Dom(tJobN)
	}
	
	set tValue="", tCount=""
	for {
		set tValue = $order(^||%IK.Dom(tValue))
		quit:tValue=""
		set tEntUniId=""
		for {
			set tEntUniId = $order(^||%IK.Dom(tValue,tEntUniId))
			quit:tEntUniId=""
			continue:$$$IKISSKIPLISTED(tEntUniId)
			set tCount = tCount+1
			$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
			
			$$$IKQADDRESULT(pResult,tCount,$lb(+tEntUniId, ##class(%iKnow.Queries.EntityAPI).GetValueInternal(pDomainId, tEntUniId,, tUseStemming), -$justify(tValue/tRecordCount,0,4)))
			
			quit:tUsePaging&&(tCount>tLast)
		}
		quit:tUsePaging&&(tCount>tLast)
	}
	
	$$$IKQENDCATCH(pResult,"^||%IK.Dom,^IRIS.Temp.IK.Dom(+$g(tJobN))",tSC)
}

ClassMethod GetTopJob(pDomainId As %Integer, pOffset As %Integer, pBits As %RawString, pJobID As %Integer, pLP As %Integer, pUseStemming As %Boolean) As %Status [ Internal ]
{
	set tPos = 0
	for {
		set tPos = $bitfind(pBits,1,tPos+1)
		quit:'tPos
		$$$IKGETIDOFFPOS(tSrcId,pOffset,tPos)
		
		if pUseStemming {
			merge tData = ^IRIS.IK.StemSrcDetails(pDomainId,tSrcId)
		} else {
			merge tData = ^IRIS.IK.EntSrcDetails(pDomainId,tSrcId)
		}
		set tEntUniId = ""
		for {
			set tEntUniId = $order(tData(tEntUniId),1,d)
			quit:tEntUniId=""
			set:$ld(d,pLP,v)&&v x = $i(^IRIS.Temp.IK.Dom(pJobID,tEntUniId),v)
		}
		kill tData
	}
	quit $$$OK
}

///  <p>Returned column summary for <method>GetBySource</method>.</p>
Parameter GetBySourceRT = "id:%Integer,values:%List,type:%Integer,dominance:%Numeric";

/// 	<p>Returns all dominant elements for a specific source. The type of elements returned can be set by the <var>type</var> parameter.
/// 	Available types are <var>$$$SDCONCEPT</var>, <var>$$$SDRELATION</var>, <var>$$$SDENTITY</var>, <var>$$$SDCRC</var>, <var>$$$SDPATH</var> and <var>$$$SDAGGREGATE</var>.</p>
/// 	<p>The elements returned can be limited to those with a dominance value above average by setting the <var>cutoff</var> parameter to <var>$$$SDABOVEAVERAGE</var>.</p>
ClassMethod GetBySource(ByRef result, domainid As %Integer, srcid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, cutoff As %Integer = {$$$SDALL}) As %Status
{
	quit ..GetBySourceInternal(.result,domainid,srcid,page,pagesize,type,cutoff,0)
}

///  <p>Returned column summary for <method>GetProfileBySource</method>.</p>
Parameter GetProfileBySourceRT [ Deprecated ] = "id:%Integer,values:%List,type:%Integer,dominance:%Numeric";

/// 	<p>Returns the dominance profile for a specific source. The type of elements returned can be set by the <var>type</var> parameter.
/// 	Available types are <var>$$$SDCONCEPT</var>, <var>$$$SDRELATION</var>, <var>$$$SDENTITY</var>, <var>$$$SDCRC</var>, <var>$$$SDPATH</var> and <var>$$$SDAGGREGATE</var>.</p>
/// 	<p>The elements returned can be limited to those with a dominance value above average by setting the <var>cutoff</var> parameter to <var>$$$SDABOVEAVERAGE</var>.</p>
ClassMethod GetProfileBySource(ByRef result, domainid As %Integer, srcid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, cutoff As %Integer = {$$$SDALL}) As %Status [ Deprecated ]
{
	quit ..GetBySourceInternal(.result,domainid,srcid,page,pagesize,type,cutoff,1)
}

/// Returns the dominance profile of a particular source as an array:
/// pArray(type, -dom, id) = "" or pArray(-dom, -length, id) = ""
ClassMethod GetBySourceArray(Output pArray, pDomainId As %Integer, pSrcId As %Integer, pType As %Integer = {$$$SDCONCEPT}, pByType As %Boolean = 0, pUseProfile As %Boolean = 1) As %Status [ Internal ]
{
	$$$IKQBEGINTRY(pArray,"",tSC)
	
	set tVersionOldDom = $$$IKVERSIONBEFORE(pDomainId,$$$IKVERSIONDOMINANCE2)
	
	set vSrcId = $s(pSrcId<0:$zabs(pSrcId),1:0)
	if vSrcId {
		set tProfile = $case(pType, $$$SDAGGREGATE:$g(^IRIS.IKV.SD.Profile(pDomainId, vSrcId),$lb("",0)), 
									:$g(^IRIS.IKV.SD.Profile(pDomainId,vSrcId,pType),$lb("",0)))
	} else {
		set tProfile = $case(pType, $$$SDAGGREGATE:$g(^IRIS.IK.SD.Profile(pDomainId, pSrcId),$lb("",0)), 
									:$g(^IRIS.IK.SD.Profile(pDomainId,pSrcId,pType),$lb("",0)))
	}

	#define CheckProfile(%v) continue:pUseProfile&&((($lg(tProfile,1)'="")&&($lg(tProfile,1)>=-%v))||($lg(tProfile,2)&&($lg(tProfile,2)<=-%v)))
	
	
	if (pType=$$$SDAGGREGATE) || (pType=$$$SDCONCEPT) || (pType=$$$SDRELATION) {
		if (vSrcId) {
			merge tEntSrcDetails = ^IRIS.IKV.EntUniDetails(pDomainId,vSrcId)
		} else {	
			merge tEntSrcDetails = ^IRIS.IK.EntSrcDetails(pDomainId,pSrcId)
		}
		set tEntUniId = ""
		for {
			set tEntUniId = $order(tEntSrcDetails(tEntUniId),1,tDetails)
			quit:tEntUniId=""
			
			if (pType'=$$$SDRELATION) {
				set tDomVal = $lg(tDetails,3+''vSrcId)
				continue:'tDomVal
				$$$CheckProfile(tDomVal)
				if pByType {
					$$$IKQADDRESULTSUB2(pArray,$$$SDCONCEPT, -tDomVal, tEntUniId,"")
				} else {
					$$$IKQADDRESULTSUB2(pArray,-tDomVal, -$$$SDCONCEPT, tEntUniId, "")
				}
			}
			
			if (pType'=$$$SDCONCEPT) {
				set tDomVal = $lg(tDetails,4+''vSrcId)
				continue:'tDomVal
				$$$CheckProfile(tDomVal)
				if pByType {
					$$$IKQADDRESULTSUB2(pArray,$$$SDRELATION, -tDomVal, tEntUniId, "")
				} else {
					$$$IKQADDRESULTSUB2(pArray,-tDomVal, -$$$SDRELATION, tEntUniId, "")
				}
			}
		}
		kill tEntSrcDetails
	}
	
	if (pType=$$$SDSTEMCONCEPT) || (pType=$$$SDSTEMRELATION) {
		if (vSrcId) {
			merge tStemSrcDetails = ^IRIS.IKV.StemUniDetails(pDomainId,vSrcId)
		} else {	
			merge tStemSrcDetails = ^IRIS.IK.StemSrcDetails(pDomainId,pSrcId)
		}
		set tStemUniId = ""
		for {
			set tStemUniId = $order(tStemSrcDetails(tStemUniId),1,tDetails)
			quit:tStemUniId=""
			
			if (pType'=$$$SDSTEMRELATION) {
				set tDomVal = $lg(tDetails,3+''vSrcId)
				continue:'tDomVal
				$$$CheckProfile(tDomVal)
				if pByType {
					$$$IKQADDRESULTSUB2(pArray,$$$SDSTEMCONCEPT, -tDomVal, tStemUniId,"")
				} else {
					$$$IKQADDRESULTSUB2(pArray,-tDomVal, -$$$SDSTEMCONCEPT, tStemUniId, "")
				}
			}
			
			if (pType'=$$$SDSTEMCONCEPT) {
				set tDomVal = $lg(tDetails,4+''vSrcId)
				continue:'tDomVal
				$$$CheckProfile(tDomVal)
				if pByType {
					$$$IKQADDRESULTSUB2(pArray,$$$SDSTEMRELATION, -tDomVal, tStemUniId, "")
				} else {
					$$$IKQADDRESULTSUB2(pArray,-tDomVal, -$$$SDSTEMRELATION, tStemUniId, "")
				}
			}
		}
		kill tStemSrcDetails
	}
	
	if (pType=$$$SDAGGREGATE) || (pType=$$$SDCRC) {
		if (vSrcId) {
			merge tCrcSrcDetails = ^IRIS.IKV.CrcUniDetails(pDomainId,vSrcId)
		} else {	
			merge tCrcSrcDetails = ^IRIS.IK.CrcSrcDetails(pDomainId,pSrcId)
		}
		set tCrcUniId = ""
		for {
			set tCrcUniId = $order(tCrcSrcDetails(tCrcUniId), 1, tDetails)
			quit:tCrcUniId=""
			
			set tDomVal = $lg(tDetails,2+''vSrcId)
			set:tVersionOldDom tDomVal = tDomVal/2
			
			$$$CheckProfile(tDomVal)
			if (pByType) {
				$$$IKQADDRESULTSUB2(pArray,$$$SDCRC, -tDomVal, tCrcUniId, "")
			} else {
				$$$IKQADDRESULTSUB2(pArray,-tDomVal, -$$$SDCRC, tCrcUniId, "")
			}
		}
		kill tCrcSrcDetails
	}
	
	if (pType=$$$SDAGGREGATE) || (pType=$$$SDPATH) {
		set tSrcDetails = $s(vSrcId:^IRIS.IKV.SrcDetails(pDomainId, vSrcId), 1:^IRIS.IK.SrcDetails(pDomainId, pSrcId))
		set tPathBase = $lg(tSrcDetails,7), tPathMax = $lg(tSrcDetails,8)+tPathBase
		set gPathDetails = $$$IKVGLOBNAME(pDomainId,"PathDetails",vSrcId)
		set gPathToEntOcc = $$$IKVGLOBNAME(pDomainId,"PathToEntOcc",vSrcId)
		for tPathId = (tPathBase+1):1:tPathMax {
			set tPathDetails = @gPathDetails@(tPathId)
			set tDomVal = $lg(tPathDetails,1)
			set:tVersionOldDom tDomVal = tDomVal/$lg(tPathDetails,2,1)
			$$$CheckProfile(tDomVal)
			if pByType {
				$$$IKQADDRESULTSUB2(pArray,$$$SDPATH, -tDomVal, tPathId, "")
			} else {
				set tPathLength = $ll(@gPathToEntOcc@(tPathId))
				if tVersionOldDom {
					set tPathFlag = $lg(tPathDetails,3)
					set tPathLength = tPathLength+(tPathFlag\2)+(tPathFlag#2)
				}
				$$$IKQADDRESULTSUB2(pArray,-tDomVal, -tPathLength, tPathId, "")
			}
		}
	}
	
	$$$IKQENDCATCH(pArray,"",tSC)
}

ClassMethod GetBySourceInternal(ByRef result, domainid As %Integer, srcid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, cutoff As %Integer = {$$$SDALL}, pUseProfile As %Boolean = 0) As %Status [ Internal, Private ]
{
	$$$IKQBEGINTRY(result,"^||%IKQ.Prof",tSC)
	if (srcid<0) && 'domainid {} else { $$$CHECKDOMAINEXISTSX(domainid,tSC) }
	$$$CHECKASRCIDEXISTSX(domainid,srcid,srcDetails,vSrcId,tSC)
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	set tSC = ..GetBySourceArray("^||%IKQ.Prof", domainid, srcid, type, 0, pUseProfile)
	quit:$$$ISERR(tSC)
	
	if (cutoff=$$$SDABOVEAVERAGE) {
		set (tSum, tCount) = 0
		set tDomVal = ""
		for {
			set tDomVal = $order(^||%IKQ.Prof(tDomVal))
			quit:tDomVal=""
			
			set tLength=""
			for {
				set tLength = $order(^||%IKQ.Prof(tDomVal,tLength))
				quit:tLength=""
				
				set tUniId=""
				for {
					set tUniId = $order(^||%IKQ.Prof(tDomVal, tLength, tUniId))
					quit:tUniId=""
					
					set tCount = tCount+1
					set tSum = tSum+tDomVal // neg value
				}
			}
		}
		quit:'tCount
		set tAverage = tSum / tCount
	}
	
	set tDomVal = "", tCount=0
	for {
		set tDomVal = $order(^||%IKQ.Prof(tDomVal))
		quit:tDomVal=""
		quit:(cutoff=$$$SDABOVEAVERAGE)&&(tDomVal>tAverage)
		
		set tLength=""
		for {
			set tLength = $order(^||%IKQ.Prof(tDomVal,tLength))
			quit:tLength=""
			
			set tUniId=""
			for {
				set tUniId = $order(^||%IKQ.Prof(tDomVal, tLength, tUniId))
				quit:tUniId=""
				
				set tValue = $case(tLength, -$$$SDCONCEPT:$lb(##class(%iKnow.Queries.EntityAPI).GetValueInternal(domainid, tUniId, vSrcId)),
											-$$$SDRELATION:$lb(##class(%iKnow.Queries.EntityAPI).GetValueInternal(domainid, tUniId, vSrcId)),
											-$$$SDSTEMCONCEPT:$lb(##class(%iKnow.Queries.EntityAPI).GetValueInternal(domainid, tUniId, vSrcId, 1)),
											-$$$SDSTEMRELATION:$lb(##class(%iKnow.Queries.EntityAPI).GetValueInternal(domainid, tUniId, vSrcId, 1)),
											-$$$SDCRC:##class(%iKnow.Queries.CrcAPI).GetValueInternal(domainid, tUniId, vSrcId),
											:##class(%iKnow.Queries.PathAPI).GetValue(domainid, tUniId, vSrcId))
				
				set tCount=tCount+1
				$$$IKCHECKPAGING(usePaging,first,last,tCount)
				$$$IKQADDRESULT(result,tCount,$lb(+tUniId,tValue,$s(tLength>=-2:$zabs(tLength), 1:$$$SDPATH),-tDomVal))
			}
		}
	}
	$$$IKQENDCATCH(result,"^||%IKQ.Prof",tSC)
}

/// <p>Returns the number of dominant terms found in a specific source. The type of elements counted can be set by the <var>type</var> parameter.
/// 	Available types are <var>$$$SDCONCEPT</var>, <var>$$$SDRELATION</var>, <var>$$$SDENTITY</var>, <var>$$$SDCRC</var>, <var>$$$SDPATH</var> and <var>$$$SDAGGREGATE</var>.</p>
/// 	<p>The number of elements counted can be limited to those with a dominance value above average by setting the <var>cutoff</var> parameter to <var>$$$SDABOVEAVERAGE</var>.</p>
ClassMethod GetCountBySource(domainid As %Integer, srcid As %Integer, type As %Integer = {$$$SDCONCEPT}, cutoff As %Integer = {$$$SDALL}, ByRef sc As %Status) As %Integer
{
	quit ..GetCountBySourceInternal(domainid,srcid,type,cutoff,0,.sc)
}

/// <p>Returns the number of dominant terms in the profile of a specific source. The type of elements counted can be set by the <var>type</var> parameter.
/// 	Available types are <var>$$$SDCONCEPT</var>, <var>$$$SDRELATION</var>, <var>$$$SDENTITY</var>, <var>$$$SDCRC</var>, <var>$$$SDPATH</var> and <var>$$$SDAGGREGATE</var>.</p>
/// 	<p>The number of elements counted can be limited to those with a dominance value above average by setting the <var>cutoff</var> parameter to <var>$$$SDABOVEAVERAGE</var>.</p>
ClassMethod GetProfileCountBySource(domainid As %Integer, srcid As %Integer, type As %Integer = {$$$SDCONCEPT}, cutoff As %Integer = {$$$SDALL}, ByRef sc As %Status) As %Integer [ Deprecated ]
{
	quit ..GetCountBySourceInternal(domainid,srcid,type,cutoff,1,.sc)
}

ClassMethod GetCountBySourceInternal(domainid As %Integer, srcid As %Integer, type As %Integer = {$$$SDCONCEPT}, cutoff As %Integer = {$$$SDALL}, pUseProfile As %Boolean = 1, ByRef sc As %Status) As %Integer
{
	$$$IKQBEGINR("^||%IKQ.Prof",sc,0)
	if (srcid<0) && 'domainid {} else { $$$CHECKDOMAINEXISTSR(domainid,sc,0) }
	$$$CHECKASRCIDEXISTSX(domainid,srcid,srcDetails,vSrcId,sc)
	
	set sc = ..GetBySourceArray("^||%IKQ.Prof", domainid, srcid, type, 0, pUseProfile)
	quit:$$$ISERR(sc) 0
	
	if (cutoff=$$$SDABOVEAVERAGE) {
		set (tSum, tCount) = 0
		set tDomVal = ""
		for {
			set tDomVal = $order(^||%IKQ.Prof(tDomVal))
			quit:tDomVal=""
			
			set tLength=""
			for {
				set tLength = $order(^||%IKQ.Prof(tDomVal,tLength))
				quit:tLength=""
				
				set tUniId=""
				for {
					set tUniId = $order(^||%IKQ.Prof(tDomVal, tLength, tUniId))
					quit:tUniId=""
					
					set tCount = tCount+1
					set tSum = tSum+tDomVal // neg value
				}
			}
		}
		quit:'tCount 0
		set tAverage = tSum / tCount
	}
	
	set tDomVal = "", tCount=0
	for {
		set tDomVal = $order(^||%IKQ.Prof(tDomVal))
		quit:tDomVal=""
		quit:(cutoff=$$$SDABOVEAVERAGE)&&(tDomVal>tAverage)
		
		set tLength=""
		for {
			set tLength = $order(^||%IKQ.Prof(tDomVal,tLength))
			quit:tLength=""
			
			set tUniId=""
			for {
				set tUniId = $order(^||%IKQ.Prof(tDomVal, tLength, tUniId))
				quit:tUniId=""
				
				set tCount=tCount+1
			}
		}
	}
	$$$IKQEND("^||%IKQ.Prof",tCount)
}

///  <p>Returned column summary for <method>GetProfileByDomain</method>.</p>
Parameter GetProfileByDomainRT [ Deprecated ] = "id:%Integer,values:%List,type:%Integer,dominance:%Numeric";

/// 	<p>Returns the dominance profile for a complete domain. The type of elements returned can be set by the <var>type</var> parameter.
/// 	Available types are <var>$$$SDCONCEPT</var>, <var>$$$SDRELATION</var>, <var>$$$SDENTITY</var>, <var>$$$SDCRC</var> and <var>$$$SDAGGREGATE</var>.</p>
ClassMethod GetProfileByDomain(ByRef result, domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}) As %Status [ Deprecated ]
{
	$$$IKQBEGINTRY(result,"",tSC)
	$$$CHECKDOMAINEXISTSX(domainid,tSC)
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	if (type=$$$SDPATH) { set tSC = $$$ERROR($$$GeneralError,"Type not supported") quit }
	
	if (type=$$$SDAGGREGATE) {
		set t=""
		for {
			set t=$o(^IRIS.IK.SD.DomProf(domainid,t))
			q:t=""
			
			set order=""
			for {
				set order=$o(^IRIS.IK.SD.DomProf(domainid,t,order))
				q:order=""
			
				set id=""
				for {
					set id=$o(^IRIS.IK.SD.DomProf(domainid,t,order,id))
					q:id=""
				
					set count=count+1
					$$$IKCHECKPAGING(usePaging,first,last,count)
				
					set values=""
					if ((t=$$$SDCONCEPT) || (t=$$$SDRELATION)) {
						set values=$lb(^IRIS.IK.EntUniId(domainid,id))
						set semdom=(-order)/$lg(^IRIS.IK.EntUniDetails(domainid,id),4+t,1)
					} elseif ((t=$$$SDSTEMCONCEPT) || (t=$$$SDSTEMRELATION)) {
						set values=$lb(^IRIS.IK.StemUniId(domainid,id))
						set semdom=(-order)/$lg(^IRIS.IK.StemUniDetails(domainid,id),4+t,1)
					} elseif (t=$$$SDCRC) {
						set crcdata=^IRIS.IK.CrcUniId(domainid,id)
						set values=$lb($g(^IRIS.IK.EntUniId(domainid,$lg(crcdata))),^IRIS.IK.EntUniId(domainid,$lg(crcdata,2)),$g(^IRIS.IK.EntUniId(domainid,$lg(crcdata,3))))
						set semdom = -order
					} else {
					    set values=""
						set pathdata=^IRIS.IK.PathId(domainid,id)
						for p=1:1:$listlength(pathdata) {
							set values=values_$lb(^IRIS.IK.EntUniId(domainid,$lg(pathdata,p)))
						}
						set semdom=-order
					}
					
					$$$IKQADDRESULT(result,count,$lb(id,values,t,semdom))
				}
				$$$IKCHECKPAGING(usePaging,first,last,count)
			}
			$$$IKCHECKPAGING(usePaging,first,last,count)
		}
	} else {
		set order=""
		for {
			set order=$o(^IRIS.IK.SD.DomProf(domainid,type,order))
			q:order=""
			
			set id=""
			for {
				set id=$o(^IRIS.IK.SD.DomProf(domainid,type,order,id))
				q:id=""
				
				set count=count+1
				$$$IKCHECKPAGING(usePaging,first,last,count)
				
				set values=""
				if ((type=$$$SDCONCEPT) || (type=$$$SDRELATION)) {
					set values=$lb(^IRIS.IK.EntUniId(domainid,id))
					set semdom=(-order)/$lg(^IRIS.IK.EntUniDetails(domainid,id),4+type,1)
				} elseif ((type=$$$SDSTEMCONCEPT) || (type=$$$SDSTEMRELATION)) {
					set values=$lb(^IRIS.IK.StemUniId(domainid,id))
					set semdom=(-order)/$lg(^IRIS.IK.StemUniDetails(domainid,id),4+type,1)
				} elseif (type=$$$SDCRC) {
					set crcdata=^IRIS.IK.CrcUniId(domainid,id)
					set values=$lb($g(^IRIS.IK.EntUniId(domainid,$lg(crcdata))),^IRIS.IK.EntUniId(domainid,$lg(crcdata,2)),$g(^IRIS.IK.EntUniId(domainid,$lg(crcdata,3))))
					set semdom = -order
				} else {
				    set values=""
					set pathdata=^IRIS.IK.PathId(domainid,id)
					for p=1:1:$listlength(pathdata) {
						set values=values_$lb(^IRIS.IK.EntUniId(domainid,$lg(pathdata,p)))
					}
					set semdom = -order
				}
				
				$$$IKQADDRESULT(result,count,$lb(id,values,type,semdom))
			}
			$$$IKCHECKPAGING(usePaging,first,last,count)
		}
	}
	
	$$$IKQENDCATCH(result,"",tSC)
}

/// <p>Returns the number of dominant terms in the profile of a complete domain. The type of elements counted can be set by the <var>type</var> parameter.
/// 	Available types are <var>$$$SDCONCEPT</var>, <var>$$$SDRELATION</var>, <var>$$$SDENTITY</var>, <var>$$$SDCRC</var> and <var>$$$SDAGGREGATE</var>.</p>
ClassMethod GetProfileCountByDomain(domainid As %Integer, type As %Integer = {$$$SDCONCEPT}, ByRef sc As %Status) As %Integer [ Deprecated ]
{
	set count=0, sc=$$$OK
	$$$IKCHECKPRIVREADR(sc,0)
	$$$CHECKDOMAINEXISTSR(domainid,sc,0)
	
	if (type=$$$SDPATH) { set sc = $$$ERROR($$$GeneralError,"Type not supported") quit 0 }
	
	if (type=$$$SDAGGREGATE) {
		set t=""
		for {
			set t=$o(^IRIS.IK.SD.DomProf(domainid,t))
			q:t=""
			
			set order=""
			for {
				set order=$o(^IRIS.IK.SD.DomProf(domainid,t,order))
				q:order=""
			
				set id=""
				for {
					set id=$o(^IRIS.IK.SD.DomProf(domainid,t,order,id))
					q:id=""
				
					set count=count+1
				}
			}
		}
	} else {
		set order=""
		for {
			set order=$o(^IRIS.IK.SD.DomProf(domainid,type,order))
			q:order=""
			
			set id=""
			for {
				set id=$o(^IRIS.IK.SD.DomProf(domainid,type,order,id))
				q:id=""
				
				set count=count+1
			}
		}
	}
	
	quit count
}

/// <p>Returns the dominance value of an element within a specified source. The <var>id</var> parameter takes either an entityId, crcId or pathId and the
/// <var>type parameter</var> defines of what type the <var>id</var> parameter is. Thus valid types are <var>$$$SDCONCEPT</var>, <var>$$$SDRELATIONM</var>,
/// 	<var>$$$SDENTITY</var>, <var>$$$SDCRC</var> and	<var>$$$SDPATH</var>.</p>
ClassMethod GetSourceValue(domainid As %Integer, srcid As %Integer, id As %Integer, type As %Integer = {$$$SDCONCEPT}, ByRef sc As %Status) As %Numeric
{
	Set sc=$$$OK
	$$$IKCHECKPRIVREADR(sc,"")
	if (srcid<0) && 'domainid {} else { $$$CHECKDOMAINEXISTSR(domainid,sc,"") }
	$$$CHECKASRCIDEXISTS(domainid,srcid,srcDetails,vSrcId)
	if vSrcId {
		quit $case(type, $$$SDCONCEPT:$lg($g(^IRIS.IKV.EntUniDetails(domainid,vSrcId,id)),4),
						$$$SDRELATION:$lg($g(^IRIS.IKV.EntUniDetails(domainid,vSrcId,id)),5),
						$$$SDSTEMCONCEPT:$lg($g(^IRIS.IKV.StemUniDetails(domainid,vSrcId,id)),4),
						$$$SDSTEMRELATION:$lg($g(^IRIS.IKV.StemUniDetails(domainid,vSrcId,id)),5),
						$$$SDCRC:$lg($g(^IRIS.IKV.CrcUniDetails(domainid,vSrcId,id)),3),
						$$$SDPATH:$lg($g(^IRIS.IKV.PathDetails(domainid,vSrcId,id)),1)/$lg($g(^IRIS.IKV.PathDetails(domainid,vSrcId,id)),2,1))
	} else {
		quit $case(type, $$$SDCONCEPT:$lg($g(^IRIS.IK.EntSrcDetails(domainid,srcid,id)),3),
						$$$SDRELATION:$lg($g(^IRIS.IK.EntSrcDetails(domainid,srcid,id)),4),
						$$$SDSTEMCONCEPT:$lg($g(^IRIS.IK.StemSrcDetails(domainid,srcid,id)),3),
						$$$SDSTEMRELATION:$lg($g(^IRIS.IK.StemSrcDetails(domainid,srcid,id)),4),
						$$$SDCRC:$lg($g(^IRIS.IK.CrcSrcDetails(domainid,srcid,id)),2),
						$$$SDPATH:$lg($g(^IRIS.IK.PathDetails(domainid,id)),1)/$lg($g(^IRIS.IK.PathDetails(domainid,id)),2,1))
	}
	quit ""
}

/// <p>Returns the dominance value of an element within a specified domain. The <var>id</var> parameter takes either an entityId, crcId or pathId and the
/// <var>type parameter</var> defines of what type the <var>id</var> parameter is. Thus valid types are <var>$$$SDCONCEPT</var>, <var>$$$SDCRC</var> and
/// 	<var>$$$SDPATH</var>.</p>
ClassMethod GetDomainValue(domainid As %Integer, id As %Integer, type As %Integer = {$$$SDCONCEPT}, ByRef sc As %Status) As %Numeric
{
	Set sc=$$$OK, count=""
	$$$IKCHECKPRIVREADR(sc,count)
	$$$CHECKDOMAINEXISTSR(domainid,sc,count)
	if (type=$$$SDPATH) { set sc = $$$ERROR($$$GeneralError,"Type not supported") quit 0 }
	Set sc=$$$OK
	Quit:type=$$$SDCONCEPT $lg($g(^IRIS.IK.EntUniDetails(domainid,id)),6)
	Quit:type=$$$SDRELATION $lg($g(^IRIS.IK.EntUniDetails(domainid,id)),7)
	Quit:type=$$$SDSTEMCONCEPT $lg($g(^IRIS.IK.StemUniDetails(domainid,id)),6)
	Quit:type=$$$SDSTEMRELATION $lg($g(^IRIS.IK.StemUniDetails(domainid,id)),7)
	Quit:type=$$$SDCRC $lg($g(^IRIS.IK.CrcUniDetails(domainid,id)),3)/2
	;Quit:type=$$$SDPATH $lg(^IRIS.IK.PathDetails(domainid,id))
	Set sc=$$$ERROR($$$GeneralError,"Unsupported type")
	Quit 0
}

/// <p>Builds overlap information of the dominant terms in all profiles of the sources in a domain. This can be restricted by using a filter.</p>
/// <p>Overlap information is needed for the following methods:
/// 	<ul>
/// 	<li><method>GetOverlap</method></li>
/// 	<li><method>GetOverlapDetails</method></li>
/// 	<li><method>FindMostTypicalSources</method></li>
/// 	<li><method>FindBreakingSources</method></li>
/// 	<li><method>GetAggregateOverlaps</method></li>
/// 	<li><method>GetSourcesByCorrelation</method></li>
/// 	</ul></p>
ClassMethod BuildOverlap(domainid As %Integer, filter As %iKnow.Filters.Filter = "") As %Status [ Deprecated ]
{
	set sc = $$$OK
	try {
		$$$IKCHECKPRIVREADX(sc)
		
		// By default we now build overlaps under setid 1
		// Later on when we support multiple overlap sets, we extend this
		set setId=1
		
		// Kill all previous overlap data
		k ^IRIS.IK.SD.Overlap(domainid,setId), ^IRIS.IK.SD.SrcOverlap(domainid,setId), ^IRIS.IK.SD.OverlapVal(domainid,setId)
		if (filter'="") {
			k ^||%IK.FilteredSrcs
			$$$IKQFILTEROBJECTX(domainid,filter,sc)
			
			set offset=""
			for {
				set bits=""
				set offset=filter.GetNextFilterOffset($$$IKFSOURCE,offset,.bits)
				Quit:offset=""
				
				set pos=0
				for {
					set pos=$bitfind(bits,1,pos+1)
					Quit:pos=0
					
					$$$IKGETIDOFFPOS(srcid,offset,pos)
					set ^||%IK.FilteredSrcs(srcid)=""
				}
			}
			set srcGlob="^||%IK.FilteredSrcs"
		} else {
			set srcGlob="^IRIS.IK.SrcId("_domainid_")"
		}
		
		// Count occurrences in profile
		//k ^||%IK.ConOverlap, ^||%IK.RElOverlap, ^||%IK.CrcOverlap
		kill ^||%IKQ.Overlap
		set srcId=""
		for {
			set srcId=$o(@srcGlob@(srcId))
			q:srcId=""
			
			for type = $$$SDCONCEPT, $$$SDRELATION, $$$SDCRC {
				set sc = ..GetBySourceArray("^||%IKQ.Profile", domainid, srcId, type, 1, 1)
				quit:$$$ISERR(sc)
			
				set order=""
				for {
					set order=$o(^||%IKQ.Profile(type,order))
					q:order=""
				
					set id=""
					for {
						set id=$o(^||%IKQ.Profile(type,order,id))
						q:id=""
					
						set x=$i(^IRIS.IK.SD.OverlapVal(domainid,setId,type,id))
						set ^||%IKQ.Overlap(type,id,srcId) = ""
					}
				}
			}
			kill ^||%IKQ.Profile
		}
		
		// Calculate overlaps
		// ^IRIS.IK.SD.Overlap(domId,setId,type,-overlap,uniId,offset)=bitstring
		// ^IRIS.IK.SD.SrcOverlap(domId,setId,srcId,type,-overlap,uniId)=""
		// ^IRIS.IK.SD.OverlapVal(domId,setId,type,id)=overlap 
		for type = $$$SDCONCEPT, $$$SDRELATION, $$$SDCRC {
			set id = ""
			for {
				set id = $order(^||%IKQ.Overlap(type, id))
				quit:id=""
				set cnt = ^IRIS.IK.SD.OverlapVal(domainid,setId,type,id)
				
				set srcId=""
				for {
					set srcId = $order(^||%IKQ.Overlap(type, id, srcId))
					quit:srcId=""
					
					$$$IKBITOFFPOS(srcId,offset,pos)
					set $bit(^IRIS.IK.SD.Overlap(domainid,setId,type,-cnt,id,offset),pos)=1
					set ^IRIS.IK.SD.SrcOverlap(domainid,setId,srcId,type,-cnt,id)=""
				}
			}
		}
	} catch (ex) {
		set sc = ex.AsStatus()
	}
	kill ^||%IKQ.Overlap, ^||%IKQ.Profile
	quit sc
}

///  <p>Returned column summary for <method>GetOverlap</method>.</p>
Parameter GetOverlapRT [ Deprecated ] = "id:%Integer,values:%Integer,type:%Integer,overlap:%Integer";

/// <p>Returns the most overlapping elements in a domain. This can be restricted by type by setting the <var>type</var> parameter to any of those values:
/// 	<ul>
/// 	<li>$$$SDCONCEPT</li>
/// 	<li>$$$SDRELATION</li>
/// 	<li>$$$SDENTITY</li>
/// 	<li>$$$SDCRC</li>
/// 	</ul>.</p>
ClassMethod GetOverlap(ByRef result, domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, filter As %iKnow.Filters.Filter = "") As %Status [ Deprecated ]
{
	$$$IKQBEGINTRY(result,"^||%IK.Overlap",sc)
	// By default we now build overlaps under setid 1
	// Later on when we support multiple overlap sets, we extend this
	set setId=1
	$$$CHECKDOMAINEXISTSX(domainid,sc)
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	if ((type=$$$SDAGGREGATE) || (type=$$$SDPATH)) {
		set sc = $$$ERROR($$$GeneralError,"Unsupported type") quit
	}
	
	k ^||%IK.Overlap
	if (filter'="") {
		set glob="^||%IK.Overlap"
		
		$$$IKQFILTEROBJECTX(domainid,filter,sc)
		
		set overlap=""
		for {
			set overlap=$o(^IRIS.IK.SD.Overlap(domainid,setId,type,overlap))
			Quit:overlap=""
			
			set id=""
			for {
				set id=$o(^IRIS.IK.SD.Overlap(domainid,setId,type,overlap,id))
				Quit:id=""
				
				set bitCnt=0
				k bitArr
				
				set offset=""
				for {
					set offset=$o(^IRIS.IK.SD.Overlap(domainid,setId,type,overlap,id,offset),1,overlapBits)
					Quit:offset=""
					
					set filterBits = filter.GetSourceFilter(offset)
					set bits=$bitlogic(overlapBits&filterBits)
					set cnt=$bitcount(bits,1)
					if (cnt>0) {
						set bitArr(offset)=bits
						set bitCnt=bitCnt+cnt
					}
				}
				
				set offset=""
				for {
					set offset=$o(bitArr(offset),1,bits)
					Quit:offset=""
					
					set ^||%IK.Overlap(-bitCnt,id,offset)=bits
				}
			}
		}
	} else {
		set glob="^IRIS.IK.SD.Overlap("_domainid_","_setId_","_type_")"
	}
	
	set overlap=""
	for {
		set overlap=$o(@glob@(overlap))
		Quit:overlap=""
		
		set id=""
		for {
			set id=$o(@glob@(overlap,id))
			Quit:id=""
			
			set count=count+1
			$$$IKCHECKPAGING(usePaging,first,last,count)
			
			if (type<$$$SDCRC) {
				set values=$lb(^IRIS.IK.EntUniId(domainid,id))
			} elseif (type=$$$SDCRC) {
				set crcdata=^IRIS.IK.CrcUniId(domainid,id)
				set values=$lb($g(^IRIS.IK.EntUniId(domainid,$lg(crcdata))),^IRIS.IK.EntUniId(domainid,$lg(crcdata,2)),$g(^IRIS.IK.EntUniId(domainid,$lg(crcdata,3))))
			} else {
			    set values=""
				set pathdata=^IRIS.IK.PathId(domainid,id)
				for p=1:1:$listlength(pathdata) {
					set values=values_$lb(^IRIS.IK.EntUniId(domainid,$lg(pathdata,p)))
				}
			}
			
			$$$IKQADDRESULT(result,count,$lb(id,values,type,-overlap))
		}
		
		$$$IKCHECKPAGING(usePaging,first,last,count)
	}
	$$$IKQENDCATCH(result,"^||%IK.Overlap",sc)
}

///  <p>Returned column summary for <method>GetOverlapDetails</method>.</p>
Parameter GetOverlapDetailsRT [ Deprecated ] = "srcid:%Integer,dominance:%Numeric,sentences:%List";

/// <p>Returns the overlap details of an element in a domain. The type of the element must be specified through the <var>type</var> parameter to any of those values:
/// 	<ul>
/// 	<li>$$$SDCONCEPT</li>
/// 	<li>$$$SDRELATION</li>
/// 	<li>$$$SDENTITY</li>
/// 	<li>$$$SDCRC</li>
/// 	</ul>.</p>
ClassMethod GetOverlapDetails(ByRef result, domainid As %Integer, id As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, filter As %iKnow.Filters.Filter = "") As %Status [ Deprecated ]
{
	$$$IKQBEGINTRY(result,"^||%IK.Overlap",sc)
	// By default we now build overlaps under setid 1
	// Later on when we support multiple overlap sets, we extend this
	set setId=1
	$$$CHECKDOMAINEXISTSX(domainid,sc)
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	// ^IRIS.IK.SD.OverlapDetails(domId,type,uniId,-overlap,-semdom,srcId)=""
	
	if ((type=$$$SDAGGREGATE) || (type=$$$SDPATH)) {
		set sc = $$$ERROR($$$GeneralError,"Unsupported type") quit
	}

	;Set overlap=$s(type=$$$SDCRC:$lg(^IRIS.IK.CrcUniDetails(domainid,id),4),1:$lg(^IRIS.IK.EntUniDetails(domainid,id),8+type))
	set overlap=$g(^IRIS.IK.SD.OverlapVal(domainid,setId,type,id))
	quit:overlap=""
	
	if (filter'="") {
		set glob="^||%IK.Overlap"
		
		$$$IKQFILTEROBJECTX(domainid,filter,sc)
			
		set bitCnt=0
		k bitArr
			
		set offset=""
		for {
			set offset=$o(^IRIS.IK.SD.Overlap(domainid,setId,type,-overlap,id,offset),1,overlapBits)
			Quit:offset=""
			
			set filterBits = filter.GetSourceFilter(offset)
			set bits=$bitlogic(overlapBits&filterBits)
			set cnt=$bitcount(bits,1)
			if (cnt>0) {
				set bitArr(offset)=bits
				set bitCnt=bitCnt+cnt
			}
		}
		
		set offset=""
		for {
			set offset=$o(bitArr(offset),1,bits)
			Quit:offset=""
			
			set ^||%IK.Overlap(-bitCnt,id,offset)=bits
		}
		set overlap=bitCnt
	} else {
		set glob=$name(^IRIS.IK.SD.Overlap(domainid,setId,type))
	}
	
	set offset=""
	for {
		set offset=$o(@glob@(-overlap,id,offset),1,bitstring)
		Quit:offset=""
		
		set pos=0
		for {
			set pos=$bitfind(bitstring,1,pos+1)
			Quit:pos=0
			
			set count=count+1
			$$$IKCHECKPAGING(usePaging,first,last,count)
			
			$$$IKGETIDOFFPOS(srcid,offset,pos)
			
			// Get dominance value
			if (type=$$$SDCONCEPT) {
				set dominance=$lg(^IRIS.IK.EntSrcDetails(domainid,srcid,id),3)
			} elseif (type=$$$SDRELATION) {
				set dominance=$lg(^IRIS.IK.EntSrcDetails(domainid,srcid,id),4)
			} else {
				set dominance=$lg(^IRIS.IK.CrcSrcDetails(domainid,srcid,id),2)
			}
			
			set sentList=""
			// Build sentencelist
			set sentBase = $lg(^IRIS.IK.SrcDetails(domainid,srcid))
			set sentCount=$lg(^IRIS.IK.SrcDetails(domainid,srcid),2)
			set firstSent = sentBase+1
			set lastSent = sentBase+sentCount
			$$$IKBITOFFPOS(firstSent,firstOffset,firstPos)
			$$$IKBITOFFPOS(lastSent,lastOffset,lastPos)
				
			if ((type=$$$SDCONCEPT) || (type=$$$SDRELATION)) {
				set glob="^IRIS.IK.EntUniToSentBit("_domainid_","_id_")"
			} else {
				set glob="^IRIS.IK.CrcUniToSentBit("_domainid_","_id_")"
			}
			set sentOffset=firstOffset-1
			for {
				set sentOffset=$o(@glob@(sentOffset),1,sentBits)
				Quit:sentOffset=""
				Quit:sentOffset>lastOffset
				
				set sentPos=0
				if (sentOffset=firstOffset) {
					set sentPos=firstPos-1
				}
				for {
					set sentPos=$bitfind(sentBits,1,sentPos+1)
					Quit:sentPos=0
					
					if (sentOffset=lastOffset) {
						quit:sentPos>lastPos
					}
					
					$$$IKGETIDOFFPOS(sentId,sentOffset,sentPos)
					set sentList=sentList_$lb(sentId)
				}
			}
			$$$IKQADDRESULT(result,count,$lb(srcid,dominance,sentList))
		}
		
		$$$IKCHECKPAGING(usePaging,first,last,count)
	}
	$$$IKQENDCATCH(result,"^||%IK.Overlap",sc)
}

Parameter FindMostTypicalSourcesExp [ Deprecated, Internal ] = 1;

/// <p>Uses the overlap information generated by <method>BuildOverlap</method> to calculate typical sources in a domain.</p>
/// <p>You can call <method>GetTypicalSources</method> to get the list of most typical sources.</p>
ClassMethod FindMostTypicalSources(domainid As %Integer) As %Status [ Deprecated ]
{
	quit ..FindMostTypicalSourcesInternal(domainid)
}

ClassMethod FindMostTypicalSourcesInternal(domainid As %Integer, filter As %iKnow.Filters.Filter = "") As %Status [ Internal, Private ]
{
	// By default we now build overlaps under setid 1
	// Later on when we support multiple overlap sets, we extend this
	set setId=1
	$$$IKCHECKPRIVREAD
	$$$CHECKDOMAINEXISTS(domainid)

	Set domDet=$g(^IRIS.IK.DomainDetails(domainid))
	if (filter="") {
		k ^IRIS.IK.SD.TypicalSrcs(domainid,setId), ^IRIS.IK.SD.TypicalSrcsOrd(domainid,setId)
		set startGlob=$name(^IRIS.IK.SD.SrcOverlap(domainid,setId))
		set typGlob=$name(^IRIS.IK.SD.TypicalSrcs(domainid,setId))
		set typGlobOrd=$name(^IRIS.IK.SD.TypicalSrcsOrd(domainid,setId))
		set totDom($$$SDCONCEPT)=$lg(domDet,3,1)
		set totDom($$$SDRELATION)=$lg(domDet,4,1)
		set totDom($$$SDCRC)=$lg(domDet,5,1)
	}else {
		k ^||%IK.FilteredSources, ^||%IK.TypicalSrcs, ^||%IK.TypicalSrcsOrd
		set sc=$$$OK
		$$$IKQFILTEROBJECTX(domainid,filter,sc)
		quit:$$$ISERR(sc) sc
		set startGlob="^||%IK.FilteredSources"
		set typGlob="^||%IK.TypicalSrcs"
		set typGlobOrd="^||%IK.TypicalSrcsOrd"
		set offset=""
		for {
			set bits=""
			set offset=filter.GetNextFilterOffset($$$IKFSOURCE,offset,.bits)
			Quit:offset=""
			
			set pos=0
			for {
				set pos=$bitfind(bits,1,pos+1)
				Quit:pos=0
				
				$$$IKGETIDOFFPOS(srcid,offset,pos)
				set ^||%IK.FilteredSources(srcid)=""
				
				set entOccBase=$lg(^IRIS.IK.SrcDetails(domainid,srcid),3)
				set entOccCount=$lg(^IRIS.IK.SrcDetails(domainid,srcid),4)
				set crcOccBase=$lg(^IRIS.IK.SrcDetails(domainid,srcid),5)
				set crcOccCount=$lg(^IRIS.IK.SrcDetails(domainid,srcid),6)
				for e=1:1:entOccCount {
					set eOcc=entOccBase+e
					set eOccType=$lg(^IRIS.IK.EntOccId(domainid,eOcc),2)
					continue:eOccType=$$$ENTTYPENONREL // BDB577
					continue:eOccType=$$$ENTTYPEPATHREL // BDB695
					set eUni=$lg(^IRIS.IK.EntOccId(domainid,eOcc))
					if (eOccType=$$$CONCEPT) {
						set:'$data(totDom($$$SDCONCEPT,eUni)) x=$i(totDom($$$SDCONCEPT))
						set totDom($$$SDCONCEPT,eUni)=""
					}elseif (eOccType=$$$RELATION) {
						set:'$data(totDom($$$SDRELATION,eUni)) x=$i(totDom($$$SDRELATION))
						set totDom($$$SDRELATION,eUni)=""
					}
				}
				for c=1:1:crcOccCount {
					set cOcc=crcOccBase+c
					set cUni=$lg(^IRIS.IK.CrcOccId(domainid,cOcc))
					set:'$data(totDom($$$SDCRC,cUni)) x=$i(totDom($$$SDCRC))
					set totDom($$$SDCRC,cUni)=""
				}
			}
		}
	}
	
	set srcid=""
	for {
		set srcid=$o(@startGlob@(srcid))
		Quit:srcid=""
		
		// Total concepts, relations and crc's
		k elemArr
		set entOccBase=$lg(^IRIS.IK.SrcDetails(domainid,srcid),3)
		set entOccCount=$lg(^IRIS.IK.SrcDetails(domainid,srcid),4)
		set crcOccBase=$lg(^IRIS.IK.SrcDetails(domainid,srcid),5)
		set crcOccCount=$lg(^IRIS.IK.SrcDetails(domainid,srcid),6)
		for e=1:1:entOccCount {
			set eOcc=entOccBase+e
			set eOccType=$lg(^IRIS.IK.EntOccId(domainid,eOcc),2)
			continue:eOccType=$$$ENTTYPENONREL // BDB577
			continue:eOccType=$$$ENTTYPEPATHREL // BDB695
			set eUni=$lg(^IRIS.IK.EntOccId(domainid,eOcc))
			if (eOccType=$$$CONCEPT) {
				set:'$data(elemArr($$$SDCONCEPT,eUni)) x=$i(elemArr($$$SDCONCEPT))
				set elemArr($$$SDCONCEPT,eUni)=""
			} elseif (eOccType=$$$RELATION) {
				set:'$data(elemArr($$$SDRELATION,eUni)) x=$i(elemArr($$$SDRELATION))
				set elemArr($$$SDRELATION,eUni)=""
			}
		}
		for c=1:1:crcOccCount {
			set cOcc=crcOccBase+c
			set cUni=$lg(^IRIS.IK.CrcOccId(domainid,cOcc))
			set:'$data(elemArr($$$SDCRC,cUni)) x=$i(elemArr($$$SDCRC))
			set elemArr($$$SDCRC,cUni)=""
		}
	
		set type=""
		for {
			set type=$o(^IRIS.IK.SD.SrcOverlap(domainid,setId,srcid,type))
			Quit:type=""
			
			set overlap=""
			for {
				set overlap=$o(^IRIS.IK.SD.SrcOverlap(domainid,setId,srcid,type,overlap))
				Quit:overlap=""
				set id=""
				for {
					set id=$o(^IRIS.IK.SD.SrcOverlap(domainid,setId,srcid,type,overlap,id))
					Quit:id=""
					set dominance=$S(type=$$$SDCRC:$lg(^IRIS.IK.CrcSrcDetails(domainid,srcid,id),2),
								     1:$lg(^IRIS.IK.EntSrcDetails(domainid,srcid,id),type+3))
					set @typGlob@(type,srcid)=$g(@typGlob@(type,srcid))-(overlap*dominance)
				}
			}
			
			// Normalise
			set @typGlob@(type,srcid)=$g(@typGlob@(type,srcid))*(elemArr(type)/totDom(type))
		}	
	}
	
	$$$IKSORTBEGIN(@typGlobOrd)
	set type=""
	for {
		set type=$o(@typGlob@(type))
		Quit:type=""
		
		set srcid=""
		for {
			set srcid=$o(@typGlob@(type,srcid),1,value)
			Quit:srcid=""
			
			set @typGlobOrd@(type,-value,srcid)=""
		}
	}
	set x=$sortend(@typGlobOrd)

	quit $$$OK
}

///  <p>Returned column summary for <method>GetTypicalSources</method>.</p>
Parameter GetTypicalSourcesRT [ Deprecated ] = "srcid:%Integer,extid:%String,coverage:%Numeric";

/// <p>Returns the list of most typical sources in a domain. The <var>type</var> parameter defines on which type of element you want the
/// list of typical documents to be based. This can be:
/// 	<ul>
/// 	<li>$$$SDCONCEPT</li>
/// 	<li>$$$SDRELATION</li>
/// 	<li>$$$SDENTITY</li>
/// 	<li>$$$SDCRC</li>
/// 	</ul>.</p>
ClassMethod GetTypicalSources(ByRef result, domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, filter As %iKnow.Filters.Filter = "") As %Status [ Deprecated ]
{
	$$$IKQBEGINTRY(result,"^||%IK.TypicalSrcsOrd",sc)
	// By default we now build overlaps under setid 1
	// Later on when we support multiple overlap sets, we extend this
	set setId=1
	$$$CHECKDOMAINEXISTSX(domainid,sc)
	
	if ((type=$$$SDAGGREGATE) || (type=$$$SDPATH)) {
		set sc = $$$ERROR($$$GeneralError,"Unsupported type") quit
	}
	
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	if (filter'="") {
		$$$IKQFILTEROBJECTX(domainid,filter,sc)
		do ..FindMostTypicalSourcesInternal(domainid,filter)
		//set typGlob="^||%IK.TypicalSrcs("_type_")"
		set typGlobOrd="^||%IK.TypicalSrcsOrd("_type_")"
	} else {
		//set typGlob="^IRIS.IK.SD.TypicalSrcs("_domainid_","_type_")"
		set typGlobOrd="^IRIS.IK.SD.TypicalSrcsOrd("_domainid_","_setId_","_type_")"
	}
	
	set score=""
	for {
		set score=$o(@typGlobOrd@(score))
		Quit:score=""
		
		set srcid=""
		for {
			set srcid=$o(@typGlobOrd@(score,srcid))
			Quit:srcid=""
			
			set count=count+1
			$$$IKCHECKPAGING(usePaging,first,last,count)
			
			set listerId=$lg(^IRIS.IK.SrcId(domainid,srcid),1)
			set groupId=$lg(^IRIS.IK.SrcId(domainid,srcid),2)
			set localRef=$lg(^IRIS.IK.SrcId(domainid,srcid),3)
			$$$IKQADDRESULT(result,count,$lb(+srcid,##class(%iKnow.Source.Lister).BuildExtId(domainid,listerId,groupId,localRef),-score))
		}
		
		$$$IKCHECKPAGING(usePaging,first,last,count)
	}
	$$$IKQENDCATCH(result,"^||%IK.TypicalSrcsOrd",sc)
}

Parameter FindBreakingSourcesExp [ Deprecated, Internal ] = 1;

/// <p>Uses the overlap information generated by <method>BuildOverlap</method> to calculate breaking sources in a domain.</p>
/// <p>You can call <method>GetBreakingSources</method> to get the list of most breaking sources.</p>
ClassMethod FindBreakingSources(domainid As %Integer) As %Status [ Deprecated ]
{
	quit ..FindBreakingSourcesInternal(domainid)
}

ClassMethod FindBreakingSourcesInternal(domainid As %Integer, filter As %iKnow.Filters.Filter = "") As %Status [ Internal, Private ]
{
	set tSC = $$$OK
	try {
		// By default we now build overlaps under setid 1
		// Later on when we support multiple overlap sets, we extend this
		set setId=1
		
		$$$IKCHECKPRIVREADX(tSC)
		$$$CHECKDOMAINEXISTSX(domainid,tSC)
		
		if (filter="") {
			k ^IRIS.IK.SD.BreakingSrcs(domainid,setId), ^IRIS.IK.SD.BreakingSrcsOrd(domainid,setId)
			set startGlob="^IRIS.IK.SrcId("_domainid_")"
			set breakGlob="^IRIS.IK.SD.BreakingSrcs("_domainid_","_setId_")"
			set breakGlobOrd="^IRIS.IK.SD.BreakingSrcsOrd("_domainid_","_setId_")"
			Set domDet=$g(^IRIS.IK.DomainDetails(domainid))
			set totDom($$$SDCONCEPT)=$lg(domDet,3,1)
			set totDom($$$SDRELATION)=$lg(domDet,4,1)
			set totDom($$$SDCRC)=$lg(domDet,5,1)
		} else {
			k ^||%IK.FilteredSources, ^||%IK.BreakingSrcs, ^||%IK.BreakingSrcsOrd
			set sc=$$$OK
			$$$IKQFILTEROBJECTX(domainid,filter,tSC)
			quit:$$$ISERR(tSC)
			set startGlob="^||%IK.FilteredSources"
			set breakGlob="^||%IK.BreakingSrcs"
			set breakGlobOrd="^||%IK.BreakingSrcsOrd"
			set offset=""
			for {
				set bits=""
				set offset=filter.GetNextFilterOffset($$$IKFSOURCE,offset,.bits)
				Quit:offset=""
				
				set pos=0
				for {
					set pos=$bitfind(bits,1,pos+1)
					Quit:pos=0
					
					$$$IKGETIDOFFPOS(srcid,offset,pos)
					set ^||%IK.FilteredSources(srcid)=""
					
					set entOccBase=$lg(^IRIS.IK.SrcDetails(domainid,srcid),3)
					set entOccCount=$lg(^IRIS.IK.SrcDetails(domainid,srcid),4)
					set crcOccBase=$lg(^IRIS.IK.SrcDetails(domainid,srcid),5)
					set crcOccCount=$lg(^IRIS.IK.SrcDetails(domainid,srcid),6)
					for e=1:1:entOccCount {
						set eOcc=entOccBase+e
						set eOccType=$lg(^IRIS.IK.EntOccId(domainid,eOcc),2)
						continue:eOccType=$$$ENTTYPENONREL // BDB577
						continue:eOccType=$$$ENTTYPEPATHREL // BDB695
						set eUni=$lg(^IRIS.IK.EntOccId(domainid,eOcc))
						if (eOccType=$$$CONCEPT) {
						    set:'$data(totDom($$$SDCONCEPT,eUni)) x=$i(totDom($$$SDCONCEPT))
							set totDom($$$SDCONCEPT,eUni)=""
						} elseif (eOccType=$$$RELATION) {
							set:'$data(totDom($$$SDRELATION,eUni)) x=$i(totDom($$$SDRELATION))
							set totDom($$$SDRELATION,eUni)=""
						}
					}
					for c=1:1:crcOccCount {
						set cOcc=crcOccBase+c
						set cUni=$lg(^IRIS.IK.CrcOccId(domainid,cOcc))
						set:'$data(totDom($$$SDCRC,cUni)) x=$i(totDom($$$SDCRC))
						set totDom($$$SDCRC,cUni)=""
					}
				}
			}
		}
		
		k ^||%IK.OverlapCache
		
		set srcid=""
		for {
			set srcid=$o(@startGlob@(srcid))
			Quit:srcid=""
			
			//set weight($$$SDCONCEPT)=0, weight($$$SDRELATION)=0, weight($$$SDCRC)=0
			//set cnt($$$SDCONCEPT)=0, cnt($$$SDRELATION)=0, cnt($$$SDCRC)=0
			
			set tSC = ..GetBySourceArray("^||%IKQ.Profile", domainid, srcid, $$$SDAGGREGATE, 1, 1)
			quit:$$$ISERR(tSC)
			
			for type = $$$SDCONCEPT,$$$SDRELATION,$$$SDCRC {
				
				set weight=0, cnt=0
				
				set order=""
				for {
					set order=$o(^||%IKQ.Profile(type,order))
					q:order=""
					
					set id=""
					for {
						set id=$o(^||%IKQ.Profile(type,order,id))
						q:id=""
						
						set cnt=cnt+1
						set overlap=$g(^IRIS.IK.SD.OverlapVal(domainid,setId,type,id))
						continue:overlap=""
						
						if (filter'="") {
							// Recalculate overlap
							set realOverlap=$g(^||%IK.OverlapCache(type,id))
							if (realOverlap="") {
								set bitCnt=0
								k bitArr
								
								set offset=""
								for {
									set offset=$o(^IRIS.IK.SD.Overlap(domainid,setId,type,-overlap,id,offset),1,overlapBits)
									Quit:offset=""
				
									set filterBits = filter.GetSourceFilter(offset)
									set bits=$bitlogic(overlapBits&filterBits)
									set cnt=$bitcount(bits,1)
									if (cnt>0) {
										set bitArr(offset)=bits
										set bitCnt=bitCnt+cnt
									}
								}
								set ^||%IK.OverlapCache(type,id)=bitCnt
								set realOverlap=bitCnt
							}
							set overlap=realOverlap
						}
						
						set semdom=0
						if (type=$$$SDCONCEPT) {
							set semdom=$lg(^IRIS.IK.EntSrcDetails(domainid,srcid,id),3)
						} elseif (type=$$$SDRELATION) {
							set semdom=$lg(^IRIS.IK.EntSrcDetails(domainid,srcid,id),4)
						} elseif (type=$$$SDCRC) {
							set semdom=$lg(^IRIS.IK.CrcSrcDetails(domainid,srcid,id),2)
						}
						if (overlap>0) {
							set weight=weight+(semdom/overlap)
						} else {
							set weight=weight + semdom
						}
					}
				}
				
				set srcWeight=weight*(cnt/totDom(type))
				set @breakGlobOrd@(type,-srcWeight,srcid)=""
				set @breakGlob@(type,srcid)=srcWeight
			}
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	k ^||%IK.OverlapCache
	quit tSC
}

///  <p>Returned column summary for <method>GetBreakingSources</method>.</p>
Parameter GetBreakingSourcesRT [ Deprecated ] = "srcid:%Integer,extid:%String,uniqueness:%Numeric";

/// <p>Returns the list of most breaking sources in a domain. The <var>type</var> parameter defines on which type of element you want the
/// list of breaking documents to be based. This can be:
/// 	<ul>
/// 	<li>$$$SDCONCEPT</li>
/// 	<li>$$$SDRELATION</li>
/// 	<li>$$$SDENTITY</li>
/// 	<li>$$$SDCRC</li>
/// 	</ul>.</p>
ClassMethod GetBreakingSources(ByRef result, domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, filter As %iKnow.Filters.Filter = "") As %Status [ Deprecated ]
{
	$$$IKQBEGINTRY(result,"^||%IK.BreakingSrcsOrd",sc)
	// By default we now build overlaps under setid 1
	// Later on when we support multiple overlap sets, we extend this
	set setId=1
	$$$CHECKDOMAINEXISTSX(domainid,sc)
	
	if ((type=$$$SDAGGREGATE) || (type=$$$SDPATH)) {
		set sc = $$$ERROR($$$GeneralError,"Unsupported type") quit
	}
	
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	if (filter'="") {
		$$$IKQFILTEROBJECTX(domainid,filter,sc)
		do ..FindBreakingSourcesInternal(domainid,filter)
		//set breakGlob="^||%IK.BreakingSrcs("_type_")"
		set breakGlobOrd="^||%IK.BreakingSrcsOrd("_type_")"
	} else {
		//set breakGlob="^IRIS.IK.SD.BreakingSrcs("_domainid_","_type_")"
		set breakGlobOrd="^IRIS.IK.SD.BreakingSrcsOrd("_domainid_","_setId_","_type_")"
	}
	
	set score=""
	for {
		set score=$o(@breakGlobOrd@(score))
		Quit:score=""
		
		set srcid=""
		for {
			set srcid=$o(@breakGlobOrd@(score,srcid))
			Quit:srcid=""
			
			set count=count+1
			$$$IKCHECKPAGING(usePaging,first,last,count)
			
			set listerId=$lg(^IRIS.IK.SrcId(domainid,srcid),1)
			set groupId=$lg(^IRIS.IK.SrcId(domainid,srcid),2)
			set localRef=$lg(^IRIS.IK.SrcId(domainid,srcid),3)
			$$$IKQADDRESULT(result,count,$lb(srcid,##class(%iKnow.Source.Lister).BuildExtId(domainid,listerId,groupId,localRef),-score))
		}
		
		$$$IKCHECKPAGING(usePaging,first,last,count)
	}
	$$$IKQENDCATCH(result,"^||%IK.BreakingSrcsOrd",sc)
}

///  <p>Returned column summary for <method>GetAggregateOverlaps</method>.</p>
Parameter GetAggregateOverlapsRT [ Deprecated ] = "id:%Integer,overlapSet1:%Integer,pctSet1:%Numeric,overlapSet2:%Integer,pctSet2:%Numeric,aggPct:%Numeric";

/// <p>Calculates the overlapping overlap of two sets of documents. First the overlap within <var>set1</var> is calculated, then the overlap within
/// 	<var>set2</var>. Finally those are compared and the most overlapping elements within those 2 sets are returned.</p>
ClassMethod GetAggregateOverlaps(ByRef result, domainid As %Integer, type As %Integer, set1 As %iKnow.Filters.Filter, set2 As %iKnow.Filters.Filter, page As %Integer = 1, pagesize As %Integer = 10) As %Status [ Deprecated ]
{
	$$$IKQBEGINTRY(result,"^||%IK.Set1Overlap,^||%IK.Set2Overlap,^||%IK.AggOverlap",sc)
	$$$CHECKDOMAINEXISTSX(domainid,sc)
	
	if ((type=$$$SDAGGREGATE) || (type=$$$SDPATH)) {
		set sc = $$$ERROR($$$GeneralError,"Unsupported type") quit
	}
	
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	$$$IKQFILTEROBJECTX(domainid,set1,sc)
	$$$IKQFILTEROBJECTX(domainid,set2,sc)
	
	do ..CalcSetOverlap(domainid,type,set1,"^||%IK.Set1Overlap")
	do ..CalcSetOverlap(domainid,type,set2,"^||%IK.Set2Overlap")
	
	k ^||%IK.AggOverlap
	set tot1=$g(^||%IK.Set1Overlap), tot2=$g(^||%IK.Set2Overlap)
	set entId=""
	for {
		set entId=$o(^||%IK.Set1Overlap(entId),1,cnt1)
		q:entId=""
		
		set cnt2=$get(^||%IK.Set2Overlap(entId),0)
		
		if (cnt2>0) {
			set pct1 = cnt1/tot1
			set pct2 = cnt2/tot2
			set aggPct = (cnt1+cnt2)/(tot1+tot2)
			set ^||%IK.AggOverlap(-aggPct,entId)=$lb(entId,cnt1,pct1,cnt2,pct2,aggPct)
		}
	}
	k ^||%IK.Set1Overlap, ^||%IK.Set2Overlap
		
	set aggPct=""
	for {
		set aggPct = $o(^||%IK.AggOverlap(aggPct))
		q:aggPct=""
		
		set entId=""
		for {
			set entId=$o(^||%IK.AggOverlap(aggPct,entId),1,data)
			q:entId=""
			
			set count=count+1
			$$$IKCHECKPAGING(usePaging,first,last,count)
			$$$IKQADDRESULT(result,count,data)
		}
		
		$$$IKCHECKPAGING(usePaging,first,last,count)
	}
	$$$IKQENDCATCH(result,"^||%IK.Set1Overlap,^||%IK.Set2Overlap,^||%IK.AggOverlap",sc)
}

ClassMethod CalcSetOverlap(domainid As %Integer, type As %Integer, set As %iKnow.Filters.Filter = "", glob As %String) As %Status [ Internal, Private ]
{
	$$$IKCHECKPRIVREAD
	
	set setId=1
	k @glob
	
	set sc=$$$OK
	$$$IKQFILTEROBJECTX(domainid,set,sc)
	if (set="") { set set = ##class(%iKnow.Filters.NoFilter).%New(domainid) }
	quit:$$$ISERR(sc) sc
	
	set offset=""
	for {
		set bits=""
		set offset=set.GetNextFilterOffset($$$IKFSOURCE,offset,.bits)
		Quit:offset=""
		
		set pos=0
		for {
			set pos=$bitfind(bits,1,pos+1)
			Quit:pos=0
			
			$$$IKGETIDOFFPOS(srcid,offset,pos)
			
			// count sources
			set tot=$i(@glob)
			set overlap=""
			for {
				set overlap=$o(^IRIS.IK.SD.SrcOverlap(domainid,setId,srcid,type,overlap))
				q:overlap=""
				
				set id=""
				for {
					set id=$o(^IRIS.IK.SD.SrcOverlap(domainid,setId,srcid,type,overlap,id))
					q:id=""
					
					set cnt=$i(@glob@(id))
				}
			}
		}
	}
	
	quit $$$OK
}

///  <p>Returned column summary for <method>GetAggregateOverlaps</method>.</p>
Parameter GetSourcesByCorrelationRT [ Deprecated ] = "srcid:%Integer,extid:%String,correlation:%Numeric";

/// <p>Returns a set of documents wich correlate closely to the input set (<var>entids</var>) of entities based on the dominance values of those entities
/// within the documents.</p>
ClassMethod GetSourcesByCorrelation(ByRef result, domainid As %Integer, entids As %List = "", page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "") As %Status [ Deprecated ]
{
	$$$IKQBEGINTRY(result,"^||%IK.SrcBits,^||%IK.SrcCorr",tSC)
	$$$CHECKDOMAINEXISTSX(domainid,tSC)
	
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	// remove duplicates and inexistent values
	set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityIdList(domainid,entids,.entArray)
	quit:$$$ISERR(tSC)
	
	set profCnt=0
	set entId=""
	for {
		set entId=$order(entArray(entId))
		quit:entId=""
		
		set profCnt = profCnt+1
		
		// build up a bitstring of sources containing any of the listed entities
		$$$IKMERGEBITSOR("^IRIS.IK.EntUniToSrcBit("_domainid_","_entId_")","^||%IK.SrcBits")
	}
	
	// apply filter if present
	set tSC=$$$OK
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	quit:$$$ISERR(tSC)
	
	if $isobject(filter) {
		set tSC = filter.MergeBits("^||%IK.SrcBits")
		quit:$$$ISERR(tSC)
	}
	
	
	set srcOff=""
	for {
		set srcOff=$o(^||%IK.SrcBits(srcOff),1,srcBits)
		quit:srcOff=""
		
		set srcPos = 0
		for {
			set srcPos = $bitfind(srcBits,1,srcPos+1)
			quit:'srcPos
			
			$$$IKGETIDOFFPOS(srcId,srcOff,srcPos)
			
			set notSrcCnt=0
			set srcCnt=0
			;set totSrcDom=0
		
			set range=$g(^IRIS.IK.SD.Profile(domainid,srcId,$$$SDCONCEPT),$lb("",0))
			set from=-$li(range,2), to=-$li(range,1)
			
			set entId=""
			for {
				set entId = $order(entArray(entId))
				quit:entId=""
				
				set details = $get(^IRIS.IK.EntSrcDetails(domainid,srcId,entId))
				continue:details=""
				
				;b "S+"
				set entDom = $lg(details,3)
				if ((from>entDom) || (to&&(to<entDom))) {
					set notSrcCnt=notSrcCnt+1
				} else {
				;;continue:from>entDom
				;;continue:to&&(to<entDom)
				
					set srcCnt=srcCnt+1
					;set totSrcDom=totSrcDom+entDom
				}
			}
			continue:'srcCnt
			
			;set avgSrcDom=totSrcDom/srcCnt
			;continue:(avgSrcDom<avgProfDom)
			
			set extId = ##class(%iKnow.Queries.SourceAPI).GetExternalId(domainid, srcId)
			//$$$IKQADDRESULTSORT(^||%IK.SrcCorr,-avgSrcDom,$lb(srcId,extId,avgSrcDom))
			$$$IKQADDRESULTSORT(^||%IK.SrcCorr,-(srcCnt/profCnt + notSrcCnt),$lb(srcId,extId,(srcCnt/profCnt + notSrcCnt)))
		}
	}
	set tSC = ..CopyFromTempSortGlobal(.result,"^||%IK.SrcCorr",usePaging,first,last)
	$$$IKQENDCATCH(result,"^||%IK.SrcBits,^||%IK.SrcCorr",tSC)
}

}
