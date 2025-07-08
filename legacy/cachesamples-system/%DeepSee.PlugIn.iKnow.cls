/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p>Sample DeepSee plugin implementation exposing the numeric results for iKnow Queries in 
/// a domain associated with an iKnow measure in this cube, as returned for the individual
/// iKnow measure values for each fact. This PlugIn has only one result
/// property named <b>Result</b>.</p><p>The following arguments can be
/// passed through &lt;filter&gt; elements in the <xdata>KPI</xdata> XData block:</p>
/// <ul>
/// 		<li><b>%cube</b>: the Subject Area which' iKnow measure to look for. Uses the default cube for this query if not specified.</li>
/// 		<li><b>%measure</b>: the iKnow measure (in cube <var>%cube</var>) whose domain needs to be queried. Uses the first iKnow measure in <var>%cube</var> if not specified.</li>
/// 		<li><b>aggregate</b>: how to aggregate the query results for the individual facts. Any of total (default), sum, average, max or min.</li>
/// 		<li><b>iKnowQuery</b>: which iKnow query to invoke, specified as "<i>queryClass</i>:<i>queryName</i>". This should be a query returning a single number taking the domain ID and source ID (or a filter object) as its first two arguments. Defaults to "%iKnow.Queries.EntityAPI:GetCountByDomain"</li>
/// </ul>
/// <p>Sample usage:<blockquote><pre>%KPI("%DeepSee.iKnow","Result",1,"aggregate","total","%CONTEXT")</pre></blockquote>
/// Note: it is essential to pass in the "%CONTEXT" special parameter into the %KPI function for
/// it to return correct results.</p>
Class %DeepSee.PlugIn.iKnow Extends %DeepSee.KPIPlugIn [ Deprecated, System = 4 ]
{

Parameter BASECUBE = "*";

Parameter LISTINGSOURCE = "FactTable";

Parameter PLUGINTYPE = "Aggregate";

Parameter LISTINGFIELDS = "ID";

/// This XData definition defines the KPI.
XData KPI [ XMLNamespace = "http://www.intersystems.com/deepsee/kpi" ]
{
<kpi name="%DeepSee.iKnow" displayName="Generic iKnow plugin" caption="Generic iKnow plugin" >
<filter name="%cube" displayName="Subject Area"
description="The Subject Area which' iKnow measure to look for. Uses the default cube for this query if not specified." />
<filter name="%measure" displayName="iKnow measure"
description="The iKnow measure (in [%cube]) whose domain needs to be queried. Uses the first iKnow measure in [%cube] if not specified." />
<filter name="aggregate" displayName="Aggregation" valueList="total,sum,average,max,min" defaultValue="total" 
description="How to aggregate the query results for the individual facts. Any of total (default), sum, average, max or min." />
<filter name="iKnowQuery" displayName="iKnow query" valueList="%iKnow.Queries.EntityAPI:GetCountByDomain,%iKnow.Queries.EntityAPI:GetOccurrenceCountByDomain" displayList="Distinct entity count,Total entity count" defaultValue="EntityAPI:GetCountByDomain"
description="hich iKnow query to invoke, specified as 'queryClass:queryName'. This should be a query returning a single number taking the domain ID and source ID (or a filter object) as its first two arguments." />
<property name="Result" description="The aggregated results of the query this KPI is to invoke" />
</kpi>
}

Method GetCubeName() As %String [ Internal ]
{
	// DTB549 - Use the parser instead of the $Extract approach
	Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(..%filterValues.%cube,.tInfo)
	If $$$ISERR(tSC) Quit
	
	Set tCube = $$$UPPER($G(tInfo(1)))
	quit tCube
}

Method GetIKnowMeasureName(Output pSC As %Status) As %String [ Internal ]
{
	set tMeasure = ..%filterValues.%measure, pSC = $$$OK
	if (tMeasure '= "") {
		
		// verify this is indeed an iKnow Measure
		set tDomainId = ##class(%iKnow.DeepSee.CubeUtils).GetDomainId(..GetCubeName(), tMeasure, .pSC)
		
	} else {
		
		// if none specified, just use the first iKnow measure we come across
		set pSC = ##class(%iKnow.DeepSee.CubeUtils).GetIKnowMeasures(..GetCubeName(), .tMeasures)
		set tMeasure = $lg($g(tMeasures(1)),1)
		
	}
	quit tMeasure
}

/// Get the base query for this plug-in.
Method %OnGetMDX(ByRef pMDX As %String) As %Status
{
	set pMDX = "SELECT FROM ["_..GetCubeName()_"]"
	quit $$$OK
}

/// Compute the median of values within the result set.
Method %OnCompute(pSQLRS As %SQL.StatementResult, pFactCount As %Integer) As %Status
{
	set tSC = $$$OK
	try {
		set tAggregate = ..%filterValues.aggregate
		set:tAggregate="" tAggregate = "total"
		
		set tQuery = ..%filterValues.iKnowQuery
		set:tQuery="" tQuery = "%iKnow.Queries.EntityAPI:GetCountByDomain"
		set tQueryClass = $p(tQuery,":",1), tQueryName = $p(tQuery,":",2)
		
		set tMeasure = ..GetIKnowMeasureName(.tSC)
		quit:$$$ISERR(tSC)
		set tSC = ##class(%iKnow.DeepSee.CubeUtils).GetMeasureInfo(..GetCubeName(), tMeasure,, .tDomainId,, .tDomainType)
		quit:$$$ISERR(tSC)
		
		set tCubeIndex = $$$DeepSeeIndex(..GetCubeName())
		set tMeasureIndex = $$$UPPER(tMeasure)
		
		set tParams = 2
		set tParams(1) = tDomainId
		
		// TODO:
		//	- allow more parameter passing?
		
		set tCount = 0, tResult = "", n=0
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
			
			if tAggregate="total" {
				
				$$$IKBITOFFPOS(tSrcId,tOff,tPos)
				set $bit(^||%IKDS.SrcBits(tOff),tPos)=1
				
			    if (n#100 = 0) {
				    // let's say running through the result set is just half the work
			        do ..%SetPercentComplete(100*(n/pFactCount)/2)
			    }
    
			} else {
				set %objlasterror = $$$OK
				set tParams(2) = tSrcId
				set tResultRow = $classmethod(tQueryClass, tQueryName, tParams...)
				continue:$$$ISERR(%objlasterror) // just ignore error rows
				set tCount = tCount+1
				
				if (tAggregate="sum") || (tAggregate="average") {
					set tResult = tResult + tResultRow
				} elseif (tAggregate = "max") {
					set:(tResult="")||(tResultRow>tResult) tResult = tResultRow
				} elseif (tAggregate = "min") {
					set:(tResult="")||(tResultRow<tResult) tResult = tResultRow
				}
				
			    if (n#100 = 0) {
			        do ..%SetPercentComplete(100*(n/pFactCount))
			    }
			}
		}
		
		if (tAggregate = "total") {
			set tParams(2) = ##class(%iKnow.Filters.BitmapFilter).%New(tDomainId, "^||%IKDS.SrcBits")
			set tResult = $classmethod(tQueryClass, tQueryName, tParams...)
			kill ^||%IKDS.SrcBits
		} elseif (tAggregate = "average") && tCount {
			set tResult = tResult / tCount
		}
		
		set ..%seriesCount = 1
		set ..%seriesNames(1) = "Total"
		set ..%data(1, "Result") = tResult
		
	} catch ex {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
