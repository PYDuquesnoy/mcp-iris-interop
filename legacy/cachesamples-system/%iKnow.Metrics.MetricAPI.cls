/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>The <package>%iKnow.Metrics</package> infrastructure is deprecated in favour of the
/// more SQL-oriented approach offered through <class>%iKnow.Tables.Utils</class>, where you
/// can add computed fields at different levels and choose whether they need to be persisted or not.</p>
/// <p>This class offers a number of API methods to interact with any custom metrics registered
/// in a particular domain. Use <class>%iKnow.Metrics.MetricDefinition</class> to configure
/// any custom metric properties, eventually referring a <class>%iKnow.Metrics.MetricsBuilder</class>
/// implementation for applicable calculations and then consult the results through the different
/// methods in this interface.</p>
Class %iKnow.Metrics.MetricAPI Extends %iKnow.Queries.AbstractAPI [ Deprecated, System = 4 ]
{

Parameter SetValueEXP [ Internal ] = 1;

/// <p>Sets the value of a particular target element identified by <var>pTargetId</var> (for example,
/// when <var>pTargetType</var> = $$$IKMTRENTITY, <var>pTargetId</var> is a unique entity ID) to
/// <var>pValue</var>.</p>
/// <p><var>pContext</var> is only required when the metric is not of type $$$IKMTRTYPEDOMAIN 
/// and should be a source ID for $$$IKMTRTYPESOURCE or a metadata value for $$$IKMTRTYPEGROUP.</p>
ClassMethod SetValue(pDomainId As %Integer, pMetricId As %Integer, pTargetType As %String, pTargetId As %Integer, pValue As %Integer, pContext As %String = "") As %Status
{
	set tSC = $$$OK
	try {
		$$$IKCHECKPRIVWRITEX(tSC)
		$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
		$$$IKCHECKIDEXISTSX(^IRIS.IK.Mtr.MetricId,pDomainId,pMetricId,tMetric,$$$IKMetricIDDoesNotExist,tSC)
		
		// Check if pContext is present when required
		set tType = $li(tMetric,2)
		if tType = $$$IKMTRTYPESOURCE {
			$$$CHECKSRCIDEXISTSX(pDomainId,pContext,tSC)
		} elseif (tType = $$$IKMTRTYPEGROUP) {
			set tUniValueId = ##class(%iKnow.Queries.MetadataAPI).GetUniValueId(pDomainId,pContext,.tSC)
			quit:$$$ISERR(tSC)
			set pContext=tUniValueId
		} else {
			set pContext=""
		}
		
		set gIdCheck = "^IRIS.IK." _ $case(pTargetType, $$$IKMTRENTITY:"EntUni", $$$IKMTRCRC:"CrcUni",
									$$$IKMTRCC:"CcUni", $$$IKMTRPATH:"Path", $$$IKMTRSENTENCE:"Sent",
									$$$IKMTRSOURCE:"Src") _ "Id"
		if '$d(@gIdCheck@(pDomainId, pTargetId)) {
			set tSC = $$$ERROR($$$IKMetricTargetDoesNotExist, pTargetType, pTargetId)
			quit
		}
		
		if '$d(^IRIS.IK.Mtr.MetricTarget(pDomainId, pMetricId, pTargetType), tOffset) {
			set tSC = $$$ERROR($$$IKMetricTargetNotSupported, pMetricId, pTargetType)
			quit
		}
		
		set tMaintainIndex = +$lg(tMetric,6)
		
		set gValues = ..GetGlobalName(pDomainId, tType, pTargetType, pContext)
		set:tMaintainIndex tPrevValue = $lg($g(@gValues@(pTargetId)), tOffset)
		set $li(@gValues@(pTargetId), tOffset) = pValue
		
		// update the index
		if tMaintainIndex {
			set tTargetType = $$$IKMTRTARGETID(pTargetType)
			if (tType=$$$IKMTRTYPEDOMAIN) {
				kill:tPrevValue'="" ^IRIS.IK.Mtr.Sorted(pDomainId, pMetricId, -tPrevValue, tTargetType, pTargetId)
				set:pValue'="" ^IRIS.IK.Mtr.Sorted(pDomainId, pMetricId, -pValue, tTargetType, pTargetId) = ""
			} else {
				kill:tPrevValue'="" ^IRIS.IK.Mtr.Sorted(pDomainId, pMetricId, pContext, -tPrevValue, tTargetType, pTargetId)
				set:pValue'="" ^IRIS.IK.Mtr.Sorted(pDomainId, pMetricId, pContext, -pValue, tTargetType, pTargetId) = ""
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns the global storing the data for the given target type.
/// Note: <var>pContext</var> should be in %Integer format (SrcId or MetaUniValueId).
ClassMethod GetGlobalName(pDomainId As %Integer, pType As %String, pTargetType As %String, pContext As %Integer = "") As %String [ Internal ]
{
	if (pType=$$$IKMTRTYPEGROUP) {
		quit "^IRIS.IK.Mtr." _ $case(pTargetType, $$$IKMTRENTITY:"EntGrp", $$$IKMTRCRC:"CrcGrp",
									$$$IKMTRCC:"CcGrp", $$$IKMTRPATH:"PathGrp", 
									$$$IKMTRSENTENCE:"SentGrp", $$$IKMTRSOURCE:"SrcGrp") 
									_ "Values(" _ pDomainId _ $s(pContext="":"", 1:"," _ pContext) _ ")"
	} elseif (pType=$$$IKMTRTYPESOURCE) {
		quit "^IRIS.IK.Mtr." _ $case(pTargetType, $$$IKMTRENTITY:"EntSrc", $$$IKMTRCRC:"CrcSrc",
									$$$IKMTRCC:"CcSrc", $$$IKMTRPATH:"PathSrc", 
									$$$IKMTRSENTENCE:"SentSrc", $$$IKMTRSOURCE:"Src") 
									_ "Values(" _ pDomainId _ $s(pContext="":"", 1:"," _ pContext) _ ")"
	} else {
		quit "^IRIS.IK.Mtr." _ $case(pTargetType, $$$IKMTRENTITY:"EntUni", $$$IKMTRCRC:"CrcUni",
									$$$IKMTRCC:"CcUni", $$$IKMTRPATH:"Path", 
									$$$IKMTRSENTENCE:"Sent", $$$IKMTRSOURCE:"Src") 
									_ "Values(" _ pDomainId _ ")"
	}
}

/// <p>Returns the value of a particular target element identified by <var>pTargetId</var> (for example,
/// when <var>pTargetType</var> = $$$IKMTRENTITY, <var>pTargetId</var> is a unique entity ID).</p>
/// <p><var>pContext</var> is only required when the metric is not of type $$$IKMTRTYPEDOMAIN 
/// and should be a source ID for $$$IKMTRTYPESOURCE or a metadata value for $$$IKMTRTYPEGROUP.</p>
ClassMethod GetValue(pDomainId As %Integer, pMetricId As %Integer, pTargetType As %String, pTargetId As %Integer, pContext As %String = "") As %Numeric
{
	$$$IKCHECKPRIVREADR(pSC,"")
	
	set tType = $lg($g(^IRIS.IK.Mtr.MetricId(pDomainId,pMetricId)),2)
	quit:tType="" ""
	if '$d(^IRIS.IK.Mtr.MetricTarget(pDomainId, pMetricId, pTargetType), tOffset) {
		quit ""
	}
	set:tType=$$$IKMTRTYPEGROUP pContext = ##class(%iKnow.Queries.MetadataAPI).GetUniValueId(pDomainId, pContext)
	quit $lg($g(@..GetGlobalName(pDomainId, tType, pTargetType, pContext)@(pTargetId)),tOffset)
}

Parameter GetTopRT = "targetId:%Integer,targetValue:%String,score:%Numeric,targetType:%String";

/// <p>Returns the elements with the highest values for custom metric <var>pMetricId</var>,
/// optionally restricted to the target type <var>pTargetType</var>.</p>
/// <p><var>pContext</var> is ignored when the metric is type $$$IKMTRTYPEDOMAIN 
/// and should be a source ID for $$$IKMTRTYPESOURCE or a metadata value for $$$IKMTRTYPEGROUP.
/// In the latter case, <var>pContext</var> is optional and the top entries for all metadata
/// values will be returned if left blank.</p>
ClassMethod GetTop(ByRef pResult, pDomainId As %Integer, pMetricId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pContext As %String = "", pTargetType As %String = "") As %Status
{
	$$$IKQBEGINTRY(pResult,"",tSC)
	$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
	$$$IKCHECKIDEXISTSX(^IRIS.IK.Mtr.MetricId,pDomainId,pMetricId,tMetric,$$$IKMetricIDDoesNotExist,tSC)
	$$$IKSETPAGINGVARS(pPage,pPageSize,tUsePaging,tFirst,tLast,tCount)
	
	set tType = $li(tMetric,2)
	
	set:(tType=$$$IKMTRTYPEGROUP)&&(pContext'="") pContext = ##class(%iKnow.Queries.MetadataAPI).GetUniValueId(pDomainId, pContext, .tSC)
	quit:$$$ISERR(tSC)
	
	if $d(^IRIS.IK.Mtr.Sorted(pDomainId, pMetricId)) {
		
		set tScore=""
		for {
			set tScore = $order(^IRIS.IK.Mtr.Sorted(pDomainId, pMetricId, tScore))
			quit:tScore=""
			
			if (pTargetType'="") {
				set tTargetType = $$$IKMTRTARGETID(pTargetType)
				
				set tId = ""
				for {
					set tId = $order(^IRIS.IK.Mtr.Sorted(pDomainId, pMetricId, tScore, tTargetType, tId), 1, tContext)
					quit:tId=""
					continue:(pContext'="")&&(tContext'=pContext)
					
					set tCount = $i(tCount)
					$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
					$$$IKQADDRESULT(pResult,tCount,$lb(tId,..GetElementValue(pDomainId,pTargetType,tId),-tScore,tTargetType))
				}
				
			} else {
				set tTargetType = ""
				for {
					set tTargetType = $order(^IRIS.IK.Mtr.Sorted(pDomainId, pMetricId, tScore, tTargetType))
					quit:tTargetType=""
					
					set tId = ""
					for {
						set tId = $order(^IRIS.IK.Mtr.Sorted(pDomainId, pMetricId, tScore, tTargetType, tId), 1, tContext)
						quit:tId=""
						continue:(pContext'="")&&(pContext'=tContext)
						
						set tCount = $i(tCount)
						$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
						set tTargetTypeStr = $$$IKMTRTARGETSTR(tTargetType)
						$$$IKQADDRESULT(pResult,tCount,$lb(+tId,..GetElementValue(pDomainId,tTargetTypeStr,tId),-tScore,tTargetTypeStr))
					}
					$$$IKCHECKPAGING(tUsePaging,0,tLast,tCount)
				}
			}
			$$$IKCHECKPAGING(tUsePaging,0,tLast,tCount)
		}
			
	} elseif (tType = $$$IKMTRTYPEDOMAIN) {
		
		set tSC = $$$ERROR($$$GeneralError, "Index needs to be built for domain-level metrics to get sorted results")
		quit
		
	} elseif (pContext="") {
		
		if (tType = $$$IKMTRSOURCE) {
			set tSC = $$$ERROR($$$GeneralError, "pContext needs to be specified for source-level metrics")
		} else {
			set tSC = $$$ERROR($$$GeneralError, "pContext needs to be specified for group-level metrics if no index is maintained")
		}
		quit
		
	} else {
		
		// metric type = $$$IKMTRTYPESOURCE or $$$IKMTRTYPEGROUP
		
		// first build a context-specific ranking at ^||%IK.MtrTop
		set tTargetType = ""
		for {
			set tTargetType = $order(^IRIS.IK.Mtr.MetricTarget(pDomainId, pMetricId, tTargetType), 1, tOffset)
			quit:tTargetType=""
			
			continue:pTargetType&&(tTargetType'=pTargetType)
			
			set gMetric = ..GetGlobalName(pDomainId, tType, tTargetType, pContext)
			set tId = ""
			for {
				set tId = $order(@gMetric@(tId),1,tValues)
				quit:tId=""
				
				set tScore = $lg(tValues,tOffset)
				continue:tScore=""
				
				set ^||%IK.MtrTop(-tScore, tTargetType, tId)=""
			}
		}
		
		set tScore=""
		for {
			set tScore = $order(^||%IK.MtrTop(tScore))
			quit:tScore=""
			
			set tTargetType = ""
			for {
				set tTargetType = $order(^||%IK.MtrTop(tScore, tTargetType))
				quit:tTargetType=""
				
				set tId = ""
				for {
					set tId = $order(^||%IK.MtrTop(tScore, tTargetType, tId))
					quit:tId=""
					
					set tCount = $i(tCount)
					$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
					$$$IKQADDRESULT(pResult,tCount,$lb(+tId,..GetElementValue(pDomainId,tTargetType,tId),-tScore,+tTargetType))
				}
				$$$IKCHECKPAGING(tUsePaging,0,tLast,tCount)
			}
			$$$IKCHECKPAGING(tUsePaging,0,tLast,tCount)
		}
	}
	
	$$$IKQENDCATCH(pResult,"^||%IK.MtrTop",tSC)
}

/// Returns a displayable value for the element identified by <var>pId</var> of type <var>pTargetType</var>
ClassMethod GetElementValue(pDomainId As %Integer, pTargetType As %Integer, pId As %Integer) As %String [ Internal ]
{
	if (pTargetType=$$$IKMTRENTITY) {
		quit ##class(%iKnow.Queries.EntityAPI).GetValueInternal(pDomainId,pId)
	} elseif (pTargetType=$$$IKMTRCRC) {
		quit $lts(##class(%iKnow.Queries.CrcAPI).GetValueInternal(pDomainId,pId))
	} elseif (pTargetType=$$$IKMTRCC) {
		quit $lts(##class(%iKnow.Queries.CcAPI).GetValueInternal(pDomainId,pId))
	} elseif (pTargetType=$$$IKMTRPATH) {
		quit $lts(##class(%iKnow.Queries.PathAPI).GetValue(pDomainId,pId))
	} elseif (pTargetType=$$$IKMTRSENTENCE) {
		quit ##class(%iKnow.Queries.SentenceAPI).GetValue(pDomainId,pId)
	} elseif (pTargetType=$$$IKMTRSOURCE) {
		quit ##class(%iKnow.Queries.SourceAPI).GetExternalId(pDomainId,pId)
	}
}

Parameter GetMetricsRT = "metricId:%Integer,name:%String,description:%String,type:%String,definitionClass:%String,builderClass:%String,groupField:%String";

/// Returns all the metrics registered in this domain.
ClassMethod GetMetrics(ByRef pResult, pDomainId As %Integer) As %Status
{
	$$$IKQBEGINTRY(pResult,"",tSC)
	$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
	
	set tMetricId = ""
	for {
		set tMetricId = $order(^IRIS.IK.Mtr.MetricId(pDomainId, tMetricId))
		quit:tMetricId=""
		
		set tMetric = ##class(%iKnow.Metrics.Metric).PKINDEXOpen(pDomainId, tMetricId)
		
		$$$IKQADDRESULT(pResult,$i(tCount),$lb(+tMetricId, tMetric.Name, tMetric.Description, tMetric.Type, tMetric.DefinitionClass, tMetric.BuilderClass, tMetric.GroupField))
	}
	
	$$$IKQENDCATCH(pResult,"",tSC)
}

Parameter GetTargetsRT = "targetType:%String";

/// Returns all the target types registered for a given metric.
ClassMethod GetTargets(ByRef pResult, pDomainId As %Integer, pMetricId As %Integer) As %Status
{
	$$$IKQBEGINTRY(pResult,"",tSC)
	$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
	$$$IKCHECKIDEXISTSX(^IRIS.IK.Mtr.MetricId,pDomainId,pMetricId,tMetric,$$$IKMetricIDDoesNotExist,tSC)
	
	set tTarget = ""
	for {
		set tTarget = $order(^IRIS.IK.Mtr.MetricTarget(pDomainId, pMetricId, tTarget))
		quit:tTarget=""
		
		$$$IKQADDRESULT(pResult,$i(tCount),$lb(tTarget))
	}
	
	$$$IKQENDCATCH(pResult,"",tSC)
}

/// Drops all metric values and definitions for this domain.
ClassMethod DropAllMetrics(pDomainId As %Integer) As %Status [ Internal ]
{
	$$$IKCHECKPRIVWRITE
	$$$CHECKDOMAINEXISTS(pDomainId)
	$$$IKCHECKDOMMGR(pDomainId)
	
	set tSC = ..ClearAllValues(pDomainId)
	quit:$$$ISERR(tSC) tSC
	
	kill ^IRIS.IK.Mtr.MetricId(pDomainId)
	kill ^IRIS.IK.Mtr.Metric(pDomainId)
	kill ^IRIS.IK.Mtr.MetricTarget(pDomainId)
	
	quit tSC
}

/// Drops all metric values for this domain.
ClassMethod ClearAllValues(pDomainId As %Integer) As %Status [ Internal ]
{
	$$$IKCHECKPRIVWRITE
	$$$CHECKDOMAINEXISTS(pDomainId)
	
	kill ^IRIS.IK.Mtr.Sorted(pDomainId)
	
	kill ^IRIS.IK.Mtr.EntUniValues(pDomainId)
	kill ^IRIS.IK.Mtr.EntSrcValues(pDomainId)
	kill ^IRIS.IK.Mtr.EntGrpValues(pDomainId)
	kill ^IRIS.IK.Mtr.CrcUniValues(pDomainId)
	kill ^IRIS.IK.Mtr.CrcSrcValues(pDomainId)
	kill ^IRIS.IK.Mtr.CrcGrpValues(pDomainId)
	kill ^IRIS.IK.Mtr.CcUniValues(pDomainId)
	kill ^IRIS.IK.Mtr.CcSrcValues(pDomainId)
	kill ^IRIS.IK.Mtr.CcGrpValues(pDomainId)
	kill ^IRIS.IK.Mtr.PathValues(pDomainId)
	kill ^IRIS.IK.Mtr.PathSrcValues(pDomainId)
	kill ^IRIS.IK.Mtr.PathGrpValues(pDomainId)
	kill ^IRIS.IK.Mtr.SentValues(pDomainId)
	kill ^IRIS.IK.Mtr.SentSrcValues(pDomainId)
	kill ^IRIS.IK.Mtr.SentGrpValues(pDomainId)
	kill ^IRIS.IK.Mtr.SrcValues(pDomainId)
	kill ^IRIS.IK.Mtr.SrcGrpValues(pDomainId)
	
	quit $$$OK
}

/// Drops all metric values for metric <var>pMetricId</var> in domain <var>pDomainId</var>. 
/// This can optionally be limited to one or more target types using <var>pTargets</var>. If
/// <var>pTargets</var> is "" (default), values for all targets registered for this metric
/// will be dropped.
ClassMethod ClearValues(pDomainId As %Integer, pMetricId As %Integer, pTargets As %List = "") As %Status
{
	set tSC = $$$OK
	try {
		$$$IKCHECKPRIVWRITEX(tSC)
		$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
		$$$IKCHECKIDEXISTSX(^IRIS.IK.Mtr.MetricId,pDomainId,pMetricId,tMetric,$$$IKMetricIDDoesNotExist,tSC)
		
		$$$IKENSURELISTSTR(pTargets)
		set tType = $li(tMetric,2)
		
		// delete all values
		kill ^||%IK.KillSorted
		set tTarget = ""
		for {
			set tTarget = $order(^IRIS.IK.Mtr.MetricTarget(pDomainId, pMetricId, tTarget), 1, tOffset)
			quit:tTarget=""
			
			continue:(pTargets'="")&&'$lf(pTargets,tTarget)
			
			set tTargetTypeId = $$$IKMTRTARGETID(tTarget)
			set gValues = ##class(%iKnow.Metrics.MetricAPI).GetGlobalName(pDomainId, tType, tTarget)
			
			if tType'=$$$IKMTRTYPEDOMAIN {
				set tContext = ""
				for {
					set tContext = $order(@gValues@(tContext))
					quit:tContext=""
					
					set tTargetId=""
					for {
						set tTargetId = $order(@gValues@(tContext,tTargetId),1,tValues)
						quit:tTargetId=""
						
						set $li(@gValues@(tContext,tTargetId),tOffset) = ""
						set:pTargets'="" ^||%IK.KillSorted(-$lg(tValues,tOffset),tTargetTypeId) = ""
					}
				}
			} else {
				set tTargetId=""
				for {
					set tTargetId = $order(@gValues@(tTargetId),1,tValues)
					quit:tTargetId=""
					
					set $li(@gValues@(tTargetId),tOffset) = ""
					set:pTargets'="" ^||%IK.KillSorted(-$lg(tValues,tOffset),tTargetTypeId) = ""
				}
			}
		}
		
		if (pTargets="") {
			kill ^IRIS.IK.Mtr.Sorted(pDomainId, pMetricId)
		} else {
			set tValue = ""
			for {
				set tValue = $order(^||%IK.KillSorted(tValue))
				quit:tValue=""
				
				set tTarget = ""
				for {
					set tTarget = $order(^||%IK.KillSorted(tValue, tTarget))
					quit:tTarget=""
					
					kill ^IRIS.IK.Mtr.Sorted(pDomainId, pMetricId, tValue, tTarget)
				}
			}
			kill ^||%IK.KillSorted
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns the ID corresponding to the supplied metric name for this domain.
ClassMethod GetMetricId(pDomainId As %Integer, pMetricName As %Integer, Output pSC As %Status) As %Integer
{
	$$$CHECKDOMAINEXISTSR(pDomainId,pSC,"")
	$$$IKCHECKPRIVREADR(pSC,"")
	
	set pSC = $$$OK, tMetricId = ""
	try {
		
		set tMetric = ##class(%iKnow.Metrics.Metric).NameIndexOpen(pDomainId, pMetricName)
		set:$isobject(tMetric) tMetricId = tMetric.MetricId
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tMetricId
}

}
