/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This is an automatically generated class, offering a functionally equivalent set of methods and queries as <class>%iKnow.Metrics.MetricAPI</class>, exposed as SqlProc methods.</p><p>See the classdocs for <class>%iKnow.Metrics.MetricAPI</class> for more information.</p>
Class %iKnow.Metrics.MetricQAPI Extends %iKnow.Queries.AbstractQAPI [ Deprecated, System = 4 ]
{

/// Returns the ID corresponding to the supplied metric name for this domain.
ClassMethod GetMetricId(pDomainId As %Integer, pMetricName As %Integer, Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Metrics.MetricAPI).GetMetricId(pDomainId, pMetricName, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// Returns all the metrics registered in this domain.
Query GetMetrics(pDomainId As %Integer) As %Library.Query(ROWSPEC = "metricId:%Integer,name:%String(MAXLEN=32767),description:%String(MAXLEN=32767),type:%String(MAXLEN=32767),definitionClass:%String(MAXLEN=32767),builderClass:%String(MAXLEN=32767),groupField:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetMetricsExecute(ByRef qHandle As %Binary,  pDomainId As %Integer) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Metrics.MetricAPI).GetMetrics("^||%IKQ.Result("_r_")", pDomainId)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetMetricsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetMetricsExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetMetricsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetMetricsExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// Returns all the target types registered for a given metric.
Query GetTargets(pDomainId As %Integer, pMetricId As %Integer) As %Library.Query(ROWSPEC = "targetType:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetTargetsExecute(ByRef qHandle As %Binary,  pDomainId As %Integer, pMetricId As %Integer) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Metrics.MetricAPI).GetTargets("^||%IKQ.Result("_r_")", pDomainId, pMetricId)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetTargetsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetTargetsExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetTargetsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetTargetsExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// <p>Returns the elements with the highest values for custom metric <var>pMetricId</var>,
/// optionally restricted to the target type <var>pTargetType</var>.</p>
/// <p><var>pContext</var> is ignored when the metric is type $$$IKMTRTYPEDOMAIN 
/// and should be a source ID for $$$IKMTRTYPESOURCE or a metadata value for $$$IKMTRTYPEGROUP.
/// In the latter case, <var>pContext</var> is optional and the top entries for all metadata
/// values will be returned if left blank.</p>
Query GetTop(pDomainId As %Integer, pMetricId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pContext As %String(MAXLEN=32767) = "", pTargetType As %String(MAXLEN=32767) = "") As %Library.Query(ROWSPEC = "targetId:%Integer,targetValue:%String(MAXLEN=32767),score:%Numeric,targetType:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetTopExecute(ByRef qHandle As %Binary,  pDomainId As %Integer, pMetricId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pContext As %String(MAXLEN=32767) = "", pTargetType As %String(MAXLEN=32767) = "") As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Metrics.MetricAPI).GetTop("^||%IKQ.Result("_r_")", pDomainId, pMetricId, pPage, pPageSize, pContext, pTargetType)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetTopFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetTopExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetTopClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetTopExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// <p>Returns the value of a particular target element identified by <var>pTargetId</var> (for example,
/// when <var>pTargetType</var> = $$$IKMTRENTITY, <var>pTargetId</var> is a unique entity ID).</p>
/// <p><var>pContext</var> is only required when the metric is not of type $$$IKMTRTYPEDOMAIN 
/// and should be a source ID for $$$IKMTRTYPESOURCE or a metadata value for $$$IKMTRTYPEGROUP.</p>
ClassMethod GetValue(pDomainId As %Integer, pMetricId As %Integer, pTargetType As %String(MAXLEN=32767), pTargetId As %Integer, pContext As %String(MAXLEN=32767) = "") As %Library.Numeric [ SqlProc ]
{
	quit ##class(%iKnow.Metrics.MetricAPI).GetValue(pDomainId, pMetricId, pTargetType, pTargetId, pContext)
}

/// <p>Sets the value of a particular target element identified by <var>pTargetId</var> (for example,
/// when <var>pTargetType</var> = $$$IKMTRENTITY, <var>pTargetId</var> is a unique entity ID) to
/// <var>pValue</var>.</p>
/// <p><var>pContext</var> is only required when the metric is not of type $$$IKMTRTYPEDOMAIN 
/// and should be a source ID for $$$IKMTRTYPESOURCE or a metadata value for $$$IKMTRTYPEGROUP.</p>
ClassMethod SetValue(pDomainId As %Integer, pMetricId As %Integer, pTargetType As %String(MAXLEN=32767), pTargetId As %Integer, pValue As %Integer, pContext As %String(MAXLEN=32767) = "") As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Metrics.MetricAPI).SetValue(pDomainId, pMetricId, pTargetType, pTargetId, pValue, pContext)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

}
