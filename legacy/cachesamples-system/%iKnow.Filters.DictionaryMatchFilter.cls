/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><class>%iKnow.Filters.Filter</class> implementation selecting sources based on whether they
/// contain a minimum and/or maximum number or total score of dictionary matches.</p>
/// 
/// <p><b>NOTE:</b> by default, this filter only uses existing match results and will only ensure
///   all sources are fully matched when the ensureMatched parameter is enabled!</p>
/// 
/// <p><b>Filter parameters</b>:
/// <ol>
/// 	<li><b>domainId</b> As <class>%Integer</class></li>
/// 	<li><b>dictIds</b> As <class>%List</class> - target dictionaries (ORed together). Use negative IDs to refer to cross-domain dictionaries.</li>
/// 	<li><b>min</b> As <class>%Numeric</class> (default 1) - minimum count or total score (-1 = no minimum)</li>
/// 	<li><b>max</b> As <class>%Numeric</class> (default -1) - maximum count or total score (-1 = no maximum)</li>
/// 	<li><b>metric</b> As <class>%String</class> (["COUNT"|"SCORE"], default "COUNT") - whether to take the 
/// 								number of matches (default) or their aggregated score.</li>
/// 	<li><b>ensureMatched</b> As <class>%Integer</class> - controls whether or not 
/// 									all sources in the domain are matched through an explicit call to 
/// 									MatchingAPI.MatchSources() as follows:<ul>
/// 				<li>0 - no explicit matching, use current matching results (default)</li>
/// 				<li>1 - match before every invocation of the filter (warning: significant performance impact!)</li>
/// 				<li>2 - match once when the filter is instantiated</li></ul></li>
/// </ol>
Class %iKnow.Filters.DictionaryMatchFilter Extends %iKnow.Filters.Filter [ Deprecated, System = 4 ]
{

Property DictIds As %List;

Property Min As %Numeric;

Property Max As %Numeric;

Property Metric As %String;

Property EnsureMatched As %Integer;

Method %OnNew(domainId As %Integer, dictIds As %List, min As %Numeric = 1, max As %Numeric = -1, metric As %String = "COUNT", ensureMatched As %Integer = 0) As %Status [ Private, ServerOnly = 1 ]
{
	$$$CHECKDOMAINEXISTS(domainId)
	$$$IKENSURELISTNUM(dictIds)
	
	quit:(min=-1)&&(max=-1) $$$ERROR($$$InvalidArgument)
	quit:(min=0)&&(max=0) $$$ERROR($$$InvalidArgument)
	quit:(max'=-1)&&(min>max) $$$ERROR($$$InvalidArgument)
	
	set i%DomainId = domainId
	set i%DictIds = dictIds
	set i%Min = min
	set i%Max = max
	set i%Metric = metric
	set i%EnsureMatched = ensureMatched
	
	// BDB358 - refining ensureMatched policy
	if (ensureMatched=2) {
		set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSources(domainId,, dictIds)
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
	set domainId=i%DomainId, min=i%Min, max=i%Max, checkCounts=(i%Metric="COUNT")
	
	for offset = 1:1:maxOffset {
		
		// first merge the requested offset from DictToSrcBit
		kill dictIds
		set ptr = 0, bits = ""
		while $listnext(..DictIds,ptr,dictId) {
			set dictIds(dictId) = 1
			set bits = $bitlogic(bits | ^IRIS.IK.Mat.DictToSrcBit(domainId, dictId, offset))
		}
	
		// if max=0 or (max=-1)&&(min=1)&&(metric=COUNT) we know enough
		if (..Max=0) {
			do ..SetSourceBits(offset, $bitlogic(^IRIS.IK.SrcExistsBit(domainId,offset) & ~bits))
			continue
		} elseif (max=-1)&&(min=1)&&checkCounts {
			do ..SetSourceBits(offset, bits)
			continue
		}
	
		// otherwise we'll have to count the actual ones and update bits as we go through
		set pos = 0
		for {
			set pos = $bitfind(bits,1,pos+1)
			quit:pos=0
		
			$$$IKGETIDOFFPOS(srcId,offset,pos)
			set score = 0
			
			kill matches
			merge matches = ^IRIS.IK.Mat.SrcToMatch(domainId, srcId)
			
			set matchId = ""
			for {
				set matchId = $order(matches(matchId))
				quit:matchId=""
			
				set match = ^IRIS.IK.Mat.MatchId(domainId, matchId)
			
				// check if it's in the requested list of dictionaries
				continue:'$d(dictIds($li(match,1)))
			
				// update score
				set score = score + $s(checkCounts:1, 1:$li(match,6))
			
				// check if we can exit if the max is met
				quit:(max>0)&&(score>max)
			}
		
			// clear this pos if the source does not meet min/max criteria
			set:((max'=-1)&&(score>max))||(score<min) $bit(bits,pos) = 0
		}
		
		do ..SetSourceBits(offset, $bitlogic(bits))
	}
	quit $$$OK
}

Method ToString() As %String
{
	quit ..%ClassName(1)_"|"_..DomainId_"|"_$lts(..DictIds)_"|"_..Min_"|"_..Max_"|"_..Metric_"|"_..EnsureMatched
}

ClassMethod RestoreFilterFromStringInternal(filterParams As %String) As %iKnow.Filters.Filter [ Internal, Private ]
{
	quit ..%New($piece(filterParams, "|", 1), $lfs($piece(filterParams, "|", 2)), $piece(filterParams, "|", 3), $piece(filterParams, "|", 4), $piece(filterParams, "|", 5), $piece(filterParams, "|", 6))
}

Method DictIdsSet(dictIds As %List) As %Status [ Internal, ServerOnly = 1 ]
{
	quit:$ls(dictIds,i%DictIds) $$$OK
	set i%DictIds = dictIds
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
