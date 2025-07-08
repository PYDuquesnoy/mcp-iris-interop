/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><class>%iKnow.Filters.Filter</class> implementation selecting sources based on whether they
/// contain a minimum and/or maximum number or total score of dictionary term matches.</p>
/// 
/// <p><b>NOTE:</b> by default, this filter only uses existing match results and will only ensure
///   all sources are fully matched when the ensureMatched parameter is enabled!</p>
/// 
/// <p><b>Filter parameters</b>:
/// <ol>
/// 	<li><b>pDomainId</b> As <class>%Integer</class></li>
/// 	<li><b>pDictTermIds</b> As <class>%List</class> - target dictionary terms (ORed together). Use negative IDs to refer to cross-domain dictionary terms.</li>
/// 	<li><b>pMin</b> As <class>%Numeric</class> (default 1) - minimum count or total score (-1 = no minimum)</li>
/// 	<li><b>pMax</b> As <class>%Numeric</class> (default -1) - maximum count or total score (-1 = no maximum)</li>
/// 	<li><b>pMetric</b> As <class>%String</class> (["COUNT"|"SCORE"], default "COUNT") - whether to take the 
/// 								number of matches (default) or their aggregated score.</li>
/// 	<li><b>ensureMatched</b> As <class>%Integer</class> - controls whether or not 
/// 									all sources in the domain are matched through an explicit call to 
/// 									MatchingAPI.MatchSources() as follows:<ul>
/// 				<li>0 - no explicit matching, use current matching results (default)</li>
/// 				<li>1 - match before every invocation of the filter (warning: significant performance impact!)</li>
/// 				<li>2 - match once when the filter is instantiated</li></ul></li>
/// </ol>
Class %iKnow.Filters.DictionaryTermMatchFilter Extends %iKnow.Filters.Filter [ Deprecated, System = 4 ]
{

Property DictTermIds As %List;

Property DictItemIds [ Internal, MultiDimensional, Private ];

Property Min As %Numeric;

Property Max As %Numeric;

Property Metric As %String;

Property EnsureMatched As %Boolean;

Property DictIds As %List [ Internal, Private ];

Method %OnNew(pDomainId As %Integer, pDictTermIds As %List, pMin As %Numeric = 1, pMax As %Numeric = -1, pMetric As %String = "COUNT", pEnsureMatched As %Integer = 0) As %Status [ Private, ServerOnly = 1 ]
{
	$$$CHECKDOMAINEXISTS(pDomainId)
	$$$IKENSURELISTNUM(pDictTermIds)
	
	quit:(pMin=-1)&&(pMax=-1) $$$ERROR($$$InvalidArgument)
	quit:(pMin=0)&&(pMax=0) $$$ERROR($$$InvalidArgument)
	quit:(pMax'=-1)&&(pMin>pMax) $$$ERROR($$$InvalidArgument)
	
	set i%DomainId = pDomainId
	
	set ptr=0, i%DictIds=""
	while $listnext(pDictTermIds,ptr,tDictTermId) {
		set tDictDomainId = $s(tDictTermId<0:0, 1:pDomainId)
		continue:'$d(^IRIS.IK.Mat.DictTermId(tDictDomainId,$zabs(tDictTermId)),tTerm)
		set i%DictTermIds = i%DictTermIds _ $lb(tDictTermId)
		set xDom = $s(tDictDomainId:1, 1:-1)
		set i%DictItemIds($li(tTerm,2)*xDom)=""
		set tDictId = $li(tTerm,1)*xDom
		set:'$lf(i%DictIds,tDictId) i%DictIds = i%DictIds _ $lb(tDictId)
	}
	
	set i%Min = pMin
	set i%Max = pMax
	set i%Metric = pMetric
	set i%EnsureMatched = pEnsureMatched
	
	// BDB358 - refining ensureMatched policy
	if (pEnsureMatched=2) {
		set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSources(pDomainId,, i%DictIds)
		quit:$$$ISERR(tSC) tSC
	}
	
	quit ..Initialize()
}

/// <p>In addition to default <class>%iKnow.Filters.Filter</class> checks, this class ensures match status
/// is up to date for the sources at the supplied offset.</p>
Method Validate(type As %Integer = {$$$IKFSOURCE}, Output isValid As %Boolean = 0) As %Status [ Private ]
{
	set tSC = ##super(type, .isValid)
	quit:$$$ISERR(tSC) tSC
	
	if (..EnsureMatched=1) {
		set tMatchId = $order(^IRIS.IK.Mat.MatchId(..DomainId,""),-1)
		set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSources(..DomainId,, ..DictIds)
		quit:$$$ISERR(tSC) tSC
		set:(tMatchId<$order(^IRIS.IK.Mat.MatchId(..DomainId,""),-1)) tSC = ..Invalidate()
	}
	
	quit tSC
}

Method BuildSourceFilter(maxOffset As %Integer) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		set tDomainId=i%DomainId, tMin=i%Min, tMax=i%Max
		
		kill ^||%IK.Matches
		set tDictItemId=""
		for {
			set tDictItemId = $order(i%DictItemIds(tDictItemId))
			quit:tDictItemId=""
			merge ^||%IK.Matches = ^IRIS.IK.Mat.DictItemToMatch(tDomainId,tDictItemId)
		}
		
		kill ^||%IK.Sources
		set tMatchId = ""
		for {
			set tMatchId = $order(^||%IK.Matches(tMatchId))
			quit:tMatchId=""
			
			set tMatch = $g(^IRIS.IK.Mat.MatchId(tDomainId, tMatchId))
			continue:tMatch=""
			continue:'$lf(i%DictTermIds,$li(tMatch,3))
			
			set tTargetType = $li(tMatch,4), tTargetId = $li(tMatch,5)
			set tSrcId = ##class(%iKnow.Matching.MatchingAPI).GetSourceIdForMatchTarget(tDomainId, tTargetType, tTargetId)
			set x = $i(^||%IK.Sources(tSrcId),$s(i%Metric="COUNT":1, 1:$li(tMatch,6)))
		}
		
		kill ^||%IK.SourcesBits
		set tSrcId="", tPrevOff=0
		for {
			set tSrcId = $order(^||%IK.Sources(tSrcId),1,tScore)
			quit:tSrcId=""
			
			continue:(tMax>0)&&(tScore>tMax)
			continue:(tMin>0)&&(tScore<tMin)
			
			$$$IKBITOFFPOS(tSrcId,tOff,tPos)
			
			if (tOff'=tPrevOff) {
				if (tPrevOff) {
					set:tMax=0 tBits = $bitlogic(^IRIS.IK.SrcExistsBit(tDomainId,tPrevOff) & ~tBits)
					set tSC = ..SetSourceBits(tPrevOff,tBits)
					quit:$$$ISERR(tSC)
				}
				set tPrevOff=tOff, tBits=""
			}
			set $bit(tBits,tPos)=1
		}
		quit:$$$ISERR(tSC)
		
		if (tPrevOff) {
			set:tMax=0 tBits = $bitlogic(^IRIS.IK.SrcExistsBit(tDomainId,tPrevOff) & ~tBits)
			set tSC = ..SetSourceBits(tPrevOff,tBits)
			quit:$$$ISERR(tSC)
		}
		
		kill ^||%IK.SourcesBits, ^||%IK.Sources, ^||%IK.Matches
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method ToString() As %String
{
	quit ..%ClassName(1)_"|"_..DomainId_"|"_$lts(..DictTermIds)_"|"_..Min_"|"_..Max_"|"_..Metric_"|"_..EnsureMatched
}

ClassMethod RestoreFilterFromStringInternal(filterParams As %String) As %iKnow.Filters.Filter [ Internal, Private ]
{
	quit ..%New($piece(filterParams, "|", 1), $lfs($piece(filterParams, "|", 2)), $piece(filterParams, "|", 3), $piece(filterParams, "|", 4), $piece(filterParams, "|", 5), $piece(filterParams, "|", 6))
}

Method DictTermIdsSet(pDictTermIds As %List) As %Status [ Internal, ServerOnly = 1 ]
{
	quit:$ls(pDictTermIds,i%DictTermIds) $$$OK
	set ptr=0, i%DictTermIds="", i%DictIds=""
	kill i%DictItemIds
	while $listnext(pDictTermIds,ptr,tDictTermId) {
		set tDictDomainId = $s(tDictTermId<0:0, 1:i%DomainId)
		continue:'$d(^IRIS.IK.Mat.DictTermId(tDictDomainId,$zabs(tDictTermId)),tTerm)
		set i%DictTermIds = i%DictTermIds _ $lb(tDictTermId)
		set xDom = $s(tDictDomainId:1, 1:-1)
		set i%DictItemIds($li(tTerm,2)*xDom)=""
		set tDictId = $li(tTerm,1)*xDom
		set:'$lf(i%DictIds,tDictId) i%DictIds = i%DictIds _ $lb(tDictId)
	}
	quit ..ChangeParams()
}

Method MinSet(min As %Numeric) As %Status [ Internal, ServerOnly = 1 ]
{
	quit:min=i%Min $$$OK
	set i%Min = min
	quit ..ChangeParams()
}

Method MaxSet(max As %Numeric) As %Status [ Internal, ServerOnly = 1 ]
{
	quit:max=i%Max $$$OK
	set i%Max = max
	quit ..ChangeParams()
}

Method MetricSet(metric As %String) As %Status [ Internal, ServerOnly = 1 ]
{
	quit:metric=i%Metric $$$OK
	set i%Metric = metric
	quit ..ChangeParams()
}

Method EnsureMatchedSet(ensureMatched As %Boolean) As %Status [ Internal, ServerOnly = 1 ]
{
	quit:ensureMatched=i%EnsureMatched $$$OK
	set i%EnsureMatched = ensureMatched
	quit ..ChangeParams()
}

/// <p>If <property>EnsureMatched</property>=2, filter invalidation (for example as the result of 
/// new sources being added to the domain) implies matching all sources.</p>
Method Invalidate(type As %Integer = {$$$IKFSOURCE}) As %Status
{
	set tSC = ##super(type)
	quit:$$$ISERR(tSC) tSC
	
	set:(..EnsureMatched=2) tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSources(..DomainId,, i%DictIds)
	quit tSC
}

}
