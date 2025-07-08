/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// <p>This <class>%iKnow.Filters.Filter</class> filters sources according to an MDX
/// set expression. This should be a DeepSee-managed domain, created automatically through
/// the use of an iKnow measure in a DeepSee cube. The MDX will be run against this cube
/// and hence should be a valid MDX statement using dimensions and/or measures defined
/// for this cube.</p>
/// 
/// <p><b>Filter parameters</b>:
/// <ol>
/// 	<li><b>pDomainId</b> As <class>%Integer</class></li>
/// 	<li><b>pMDXWhereClause</b> As <class>%String</class> - The MDX set expression to filter 
/// 			cube facts through. This should be a valid expression for the MDX WHERE clause.</li>
/// 		<li><b>pCubeName</b> As <class>%String</class> - If this is an iKnow-managed domain, 
/// 				use this parameter to specify the DeepSee cube the MDX should be run against.
/// 				(this parameter is ignored for DeepSee-managed domains)</li>
/// 		<li><b>pMeasureName</b> As <class>%String</class> - If this is an iKnow-managed domain, 
/// 				use this parameter to specify the iKnow measure in <var>pCubeName</var> for
/// 				which the values are represented by this iKnow domain.
/// 				(this parameter is ignored for DeepSee-managed domains)</li>
/// </ol>
/// 
/// <p>Example:</p>
/// <blockquote><pre>USER>zn "samples"
/// 
/// SAMPLES>set domId = ##class(%iKnow.DeepSee.CubeUtils).GetDomainId("AviationEvents","Report")
/// 
/// SAMPLES>set filter = ##class(%iKnow.DeepSee.MDXFilter).%New(domId, "{[AircraftDim].[H1].[AircraftCategory].&[Balloon],[AircraftDim].[H1].[AircraftCategory].&[Glider]}")
/// 
/// SAMPLES>write ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(domId)
/// 1005
/// SAMPLES>write ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(domId,filter)
/// 27</pre></blockquote>
Class %iKnow.DeepSee.MDXFilter Extends %iKnow.Filters.Filter [ Deprecated, System = 4 ]
{

Property CubeName As %String [ ReadOnly ];

Property MeasureName As %String [ ReadOnly ];

Property MDXWhereClause As %String [ ReadOnly ];

Method %OnNew(pDomainId As %Integer, pMDXWhereClause As %String, pCubeName As %String = "", pMeasureName As %String = "") As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	$$$CHECKDOMAINEXISTS(pDomainId)
	
	set i%DomainId = pDomainId
	set i%MDXWhereClause = pMDXWhereClause
	
	if '$$$GETPARAMNODEF(pDomainId,$$$IKPDEEPSEEDOMAIN) {
		set tSC = ##class(%iKnow.DeepSee.CubeUtils).GetMeasureInfo(pCubeName, pMeasureName, .tSourceType, .tDomainId)
		quit:tDomainId'=pDomainId $$$ERROR($$$GeneralError, "Domain with id "_pDomainId_" is not referenced by measure "_pMeasureName_" in cube "_pCubeName)
		set i%CubeName = pCubeName
		set i%MeasureName = pMeasureName
	} else {
		set i%CubeName = $$$GETPARAMNODEF(pDomainId,$$$IKPDSCUBE)
		set i%MeasureName = $$$GETPARAMNODEF(pDomainId,$$$IKPDSMEASURE)
	}
	
	quit ..Initialize(0)
}

Method BuildSourceFilter(maxOffset As %Integer) As %Status [ Private ]
{
	try {
		set tMDX = "DRILLFACTS SELECT FROM ["_i%CubeName_"] WHERE "_i%MDXWhereClause
		
		set tRS = ##class(%DeepSee.ResultSet).%New()
		set tSC = tRS.%PrepareMDX(tMDX)
		quit:$$$ISERR(tRS)
		
		// DTB316 - If applicable, set the parentQueryKey to allow use of axes locked by the parent query. 
		// Do not assume the %query object exists when this is called.
		If ($G(%query)'="")&&$IsObject(%query)&&%query.%IsA("%DeepSee.Query.query") {
			Set tRS.%Query.parentQueryKey = $S(%query.parentQueryKey'="":%query.parentQueryKey,1:%query.%QueryKey)
		}
		
		set tSC = tRS.%Execute()
		quit:$$$ISERR(tRS)
		
		set tSC = tRS.%ExecuteListing(1)
		quit:$$$ISERR(tRS)
		
		set tCubeIndex=$$$UPPER(i%CubeName), tQueryKey = tRS.%GetQueryKey()
		
		if $$$GETPARAMNODEF(i%DomainId,$$$IKPDEEPSEEDOMAIN) {
			set tChunk = ""
			for {
				set tChunk = $order($$$DeepSeeListingBitGLVN(tCubeIndex, tQueryKey, tChunk), 1, tBits)
				quit:tChunk=""
			
				do ..SetSourceBits(tChunk, tBits)
			}
		} else {
			
			set tFactBits = $name($$$DeepSeeListingBitGLVN(tCubeIndex, tQueryKey))
			set tSC = ##class(%iKnow.DeepSee.CubeUtils).TranslateIKnowBitstring(tCubeIndex, i%MeasureName, tFactBits, "^||%IK.SrcBits", 0)
			quit:$$$ISERR(tSC)
			
			set tOffset = ""
			for {
				set tOffset = $order(^||%IK.SrcBits(tOffset), 1, tBits)
				quit:tOffset=""
			
				do ..SetSourceBits(tOffset, tBits)
			}
			kill ^||%IK.SrcBits
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method ToString() As %String
{
	quit ..%ClassName(1)_"|"_..DomainId_"|"_..MDXWhereClause_"|"_..CubeName_"|"_..MeasureName
}

ClassMethod RestoreFilterFromStringInternal(filterParams As %String) As %iKnow.Filters.Filter [ Private ]
{
	quit ..%New($p(filterParams,"|",1), $p(filterParams,"|",2,*-2), $p(filterParams,"|",*-1), $p(filterParams,"|",*))
}

}
