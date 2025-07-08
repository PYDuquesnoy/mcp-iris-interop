/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Sample DeepSee plugin implementation exposing the number and total count of matching
/// results for a domain associated with an iKnow measure in this cube. This PlugIn has two
/// properties available for use in queries: <b>MatchCount</b> and <b>MatchScore</b>. These
/// numbers will have been broken down to the appropriate Dictionary and Item levels if there
/// is a corresponding Dictionary and/or Item member in the current filter, row or column spec.</p>
/// <p>The following arguments can be passed through &lt;filter&gt; elements in the <xdata>KPI</xdata> XData block:</p>
/// <ul>
/// 		<li><b>%cube</b>: the Subject Area which' iKnow measure to look for. Uses the default cube for this query if not specified.</li>
/// 		<li><b>%measure</b>: the iKnow measure (in cube <var>%cube</var>) whose domain needs to be queried. Uses the first iKnow measure in <var>%cube</var> if not specified.</li>
/// 		<li><b>aggregate</b>: how to aggregate the match count or total score. Any of sum (default), average, max or min.</li>
/// </ul>
/// <p>Sample usage:<blockquote><pre>%KPI("%DeepSee.iKnowDictionary","MatchCount",1,"aggregate","sum","%CONTEXT")</pre></blockquote>
/// Note: it is essential to pass in the "%CONTEXT" special parameter into the %KPI function for
/// it to return correct results.</p>
Class %DeepSee.PlugIn.iKnowDictionary Extends %DeepSee.PlugIn.iKnow [ Deprecated, System = 4 ]
{

Parameter BASECUBE = "*";

Parameter LISTINGSOURCE = "FactTable";

Parameter PLUGINTYPE = "Aggregate";

Parameter LISTINGFIELDS = "ID";

/// This XData definition defines the KPI.
XData KPI [ XMLNamespace = "http://www.intersystems.com/deepsee/kpi" ]
{
<kpi name="%DeepSee.iKnowDictionary" displayName="Generic iKnow plugin" caption="Generic iKnow plugin" >
<filter name="%cube" displayName="Subject Area"
description="The Subject Area which' iKnow measure to look for. Uses the default cube for this query if not specified." />
<filter name="%measure" displayName="iKnow measure"
description="The iKnow measure (in [%cube]) whose domain needs to be queried. Uses the first iKnow measure in [%cube] if not specified." />
<filter name="aggregate" displayName="Aggregation" valueList="sum,average,max,min"
description="How to aggregate the match count or total score. Any of sum (default), average, max or min." />
<property name="MatchCount" description="The aggregated number of individual matches found in the corresponding facts." />
<property name="MatchScore" description="The aggregated match score of individual matches found in the corresponding facts." />
</kpi>
}

/// Compute the median of values within the result set.
Method %OnCompute(pSQLRS As %SQL.StatementResult, pFactCount As %Integer) As %Status
{
	set tSC = $$$OK
	try {
		set tCube = ..GetCubeName()
		set tCubeIndex = $$$DeepSeeIndex(tCube)
		set tAggregate = ..%filterValues.aggregate
		set:tAggregate="" tAggregate = "sum"
		
		set tMeasure = ..GetIKnowMeasureName(.tSC)
		set tMeasureIndex = $$$UPPER(tMeasure)
		quit:$$$ISERR(tSC)
		set tSC = ##class(%iKnow.DeepSee.CubeUtils).GetMeasureInfo(..GetCubeName(), tMeasure,, .tDomainId,, .tDomainType)
		quit:$$$ISERR(tSC)
		
		// check if any of the context variables points to a dictionary or item
		set i="", tIncompatibleFilters = 0
		for {
			set i = $order(%dsCellContext(i),1,tSpec)
			quit:i=""
			
			set:$e(tSpec)="(" tSpec = $e(tSpec,2,*-1)
			for j = 1:1:$l(tSpec,",") {
				set tSpecPiece = $p(tSpec,",",j)
				set tDimHierLevelSpec = $piece(tSpecPiece,".",1,$l(tSpecPiece,".")-1)
				set tSC2 = ##class(%DeepSee.Utils).%GetDimensionInfo(tCube, tDimHierLevelSpec, .tDimNo, .tHierNo, .tLevelNo, .tRelatedCube,, .tSpecInfo,, 0)
				continue:$$$ISERR(tSC2)
				
				// BDB441: don't look into related cubes
				continue:tRelatedCube'=""
				
				set tLevelInfo = $g($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeIndex),"mbr#",+tDimNo,+tHierNo,+tLevelNo))
				continue:$lg(tLevelInfo,6)'="%iKnow.DeepSee.Dimensions.Dictionaries"
				
				set tDimObject = ##class(%iKnow.DeepSee.Dimensions.Dictionaries).%Create(tCube,$lg(tLevelInfo,5),tDimNo,tHierNo,tLevelNo)
				
				set tMemberSpec = $piece(tSpec,".",$l(tSpec,"."))
				if $e(tMemberSpec,1)="&" {
					set tMemberSpec = $e(tMemberSpec,3,*-1)
					set tID = $p(tMemberSpec,":",$l(tMemberSpec,":"))
				} else {
					set tMemberSpec = $e(tMemberSpec,2,*-1)
					set tID = tDimObject.GetId(tMemberSpec)
				}
				
				if $d(tDictFilter(tDimObject.%ikDictLevel), tCurrentId) && (tCurrentId '= tID) {
					set tIncompatibleFilters = 1
				} else {
					set tDictFilter(tDimObject.%ikDictLevel) = tID
				}
			}
		}
		set tHasDictFilter = $d(tDictFilter("D")), tHasItemFilter = $d(tDictFilter("I"))
		
		set tMatchCount = "", tTotalScore = ""
		if ('tIncompatibleFilters) {
			
			set tCount = 0, n = 0
			kill ^||%IKDS.SrcBits
			
			while pSQLRS.%Next(.tSC) {
				quit:$$$ISERR(tSC)
				
				set n = n+1
				
				set tFactId = pSQLRS.%Get("ID")
				continue:'tFactId
				
				if (tDomainType = "iKnow") {
					set tSrcId = $g($$$DeepSeeIndexGLVN(tCubeIndex, "%ikSrcIdReverse", tMeasureIndex, tFactId))
					continue:'tSrcId
				} else {
					set tSrcId = tFactId
				}
				
				set tCount = tCount+1
				set tRowMatchCount = 0, tRowTotalScore = 0
		
				kill tMatches
				merge tMatches = ^IRIS.IK.Mat.SrcToMatch(tDomainId,tSrcId)
				set tMatchId = ""
				for {
					set tMatchId = $order(tMatches(tMatchId))
					quit:tMatchId=""
					
					set tMatchInfo = ^IRIS.IK.Mat.MatchId(tDomainId, tMatchId)
					
					continue:tHasDictFilter&&(tDictFilter("D")'=$zabs($li(tMatchInfo,1)))
					continue:tHasItemFilter&&(tDictFilter("I")'=$zabs($li(tMatchInfo,2)))
					
					set tRowMatchCount = tRowMatchCount+1
					set tRowTotalScore = tRowTotalScore+$li(tMatchInfo,6)
				}
				kill tMatches
				
				continue:'tRowMatchCount
				
				// aggregate
				if (tAggregate="sum") || (tAggregate="average") {
					set tMatchCount = tMatchCount + tRowMatchCount
					set tTotalScore = tTotalScore + tRowTotalScore
				} elseif (tAggregate = "max") {
					set:(tMatchCount="")||(tRowMatchCount>tMatchCount) tMatchCount = tRowMatchCount
					set:(tTotalScore="")||(tRowTotalScore>tTotalScore) tTotalScore = tRowTotalScore
				} elseif (tAggregate = "min") {
					set:(tMatchCount="")||(tRowMatchCount<tMatchCount) tMatchCount = tRowMatchCount
					set:(tTotalScore="")||(tRowTotalScore<tTotalScore) tTotalScore = tRowTotalScore
				}
			    if (n#100 = 0) {
			        do ..%SetPercentComplete(100*(n/pFactCount))
			    }
			}
			
			if (tAggregate = "average") && tCount {
				set tTotalScore = tTotalScore / tCount
				set tMatchCount = tMatchCount / tCount
			}
		}
		
		set ..%seriesCount = 1
		set ..%seriesNames(1) = "Total"
		set ..%data(1, "MatchCount") = tMatchCount
		set ..%data(1, "MatchScore") = tTotalScore
		
	} catch ex {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
