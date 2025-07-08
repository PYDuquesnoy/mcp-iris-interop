/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This is an automatically generated class, offering a functionally equivalent set of methods and queries as <class>%iKnow.Metrics.MetricAPI</class>, exposed as WebMethod methods.</p><p>See the classdocs for <class>%iKnow.Metrics.MetricAPI</class> for more information.</p>
Class %iKnow.Metrics.MetricWSAPI Extends %iKnow.Queries.AbstractWSAPI [ Deprecated, System = 4 ]
{

/// Returns the ID corresponding to the supplied metric name for this domain.
ClassMethod GetMetricId(pDomainId As %Integer, pMetricName As %Integer) As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Metrics.MetricAPI).GetMetricId(pDomainId, pMetricName, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// Returns all the metrics registered in this domain.
ClassMethod GetMetrics(pDomainId As %Integer) As %XML.DataSet [ WebMethod ]
{
	set data = ##class(%XML.DataSet).%New("%iKnow.Metrics.MetricQAPI:GetMetrics")
	set tSC = data.Execute(pDomainId)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// Returns all the target types registered for a given metric.
ClassMethod GetTargets(pDomainId As %Integer, pMetricId As %Integer) As %XML.DataSet [ WebMethod ]
{
	set data = ##class(%XML.DataSet).%New("%iKnow.Metrics.MetricQAPI:GetTargets")
	set tSC = data.Execute(pDomainId, pMetricId)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Returns the elements with the highest values for custom metric <var>pMetricId</var>,
/// optionally restricted to the target type <var>pTargetType</var>.</p>
/// <p><var>pContext</var> is ignored when the metric is type $$$IKMTRTYPEDOMAIN 
/// and should be a source ID for $$$IKMTRTYPESOURCE or a metadata value for $$$IKMTRTYPEGROUP.
/// In the latter case, <var>pContext</var> is optional and the top entries for all metadata
/// values will be returned if left blank.</p>
ClassMethod GetTop(pDomainId As %Integer, pMetricId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pContext As %String = "", pTargetType As %String = "") As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set pPage = $s($g(pPage)="":1, 1:pPage)
	set pPageSize = $s($g(pPageSize)="":10, 1:pPageSize)

	set data = ##class(%XML.DataSet).%New("%iKnow.Metrics.MetricQAPI:GetTop")
	set tSC = data.Execute(pDomainId, pMetricId, pPage, pPageSize, pContext, pTargetType)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Returns the value of a particular target element identified by <var>pTargetId</var> (for example,
/// when <var>pTargetType</var> = $$$IKMTRENTITY, <var>pTargetId</var> is a unique entity ID).</p>
/// <p><var>pContext</var> is only required when the metric is not of type $$$IKMTRTYPEDOMAIN 
/// and should be a source ID for $$$IKMTRTYPESOURCE or a metadata value for $$$IKMTRTYPEGROUP.</p>
ClassMethod GetValue(pDomainId As %Integer, pMetricId As %Integer, pTargetType As %String, pTargetId As %Integer, pContext As %String = "") As %Library.Numeric [ WebMethod ]
{
	quit ##class(%iKnow.Metrics.MetricAPI).GetValue(pDomainId, pMetricId, pTargetType, pTargetId, pContext)
}

/// <p>Sets the value of a particular target element identified by <var>pTargetId</var> (for example,
/// when <var>pTargetType</var> = $$$IKMTRENTITY, <var>pTargetId</var> is a unique entity ID) to
/// <var>pValue</var>.</p>
/// <p><var>pContext</var> is only required when the metric is not of type $$$IKMTRTYPEDOMAIN 
/// and should be a source ID for $$$IKMTRTYPESOURCE or a metadata value for $$$IKMTRTYPEGROUP.</p>
ClassMethod SetValue(pDomainId As %Integer, pMetricId As %Integer, pTargetType As %String, pTargetId As %Integer, pValue As %Integer, pContext As %String = "") As %Boolean [ WebMethod ]
{
	set sc = ##class(%iKnow.Metrics.MetricAPI).SetValue(pDomainId, pMetricId, pTargetType, pTargetId, pValue, pContext)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

Parameter NAMESPACE = "http://www.intersystems.com/iKnow/Metrics/MetricWSAPI";

Parameter SERVICENAME = "iKnow.Metrics.MetricWSAPI";

Parameter USECLASSNAMESPACES = 1;

}
