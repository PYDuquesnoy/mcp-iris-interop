/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

IncludeGenerator %IKPublic

/// <p>The <package>%iKnow.Metrics</package> infrastructure is deprecated in favour of the
/// more SQL-oriented approach offered through <class>%iKnow.Tables.Utils</class>, where you
/// can add computed fields at different levels and choose whether they need to be persisted or not.</p>
/// <p>Use a Metric Definition to declare any custom metrics you wish to use in an application 
/// by creating a subclass of this class and supplying a <xdata>Metrics</xdata> XData block 
/// detailing the properties of these custom metrics. To be able to use a metric in a particular
/// domain, use the <method>Register</method> method.</p>
/// <p>Unless custom metrics are only assigned on an individual basis (such as a "reader score" 
/// metric), a metric will refer to a Builder Class that is responsible for implementing the logic
/// to calculate the appropriate values for a custom metric. See also 
/// <class>%iKnow.Metrics.MetricBuilder</class> for more details.</p>
/// <p>Note: metric definitions can also transparently be included in a domain definition, with
/// no further need to call <method>Register</method>.
/// See also <class>%iKnow.DomainDefinition</class>.</p>
Class %iKnow.Metrics.MetricDefinition Extends %RegisteredObject [ Abstract, Deprecated, System = 4 ]
{

/// <p>This XData block should contain a single &lt;metrics&gt; element with &lt;metric&gt; 
/// elements nested within for each custom metric to be registered.</p>
XData Metrics [ XMLNamespace = "http://www.intersystems.com/iknow/metrics" ]
{
}

/// Registers all Metrics, their properties and targets, as defined in the <xdata>Metrics</xdata>
/// XData block, in the domain <var>pDomainId</var>. 
ClassMethod Register(pDomainId As %Integer, pVerbose As %Boolean = 1) As %Status [ Final ]
{
	set tSC = $$$OK
	try {
		$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
		$$$IKCHECKVERSIONATLEASTX(pDomainId,$$$IKVERSIONMETRICS,tSC)
		$$$IKCHECKDOMMGRX(pDomainId,tSC)
		write:pVerbose !,"Registering metrics and targets for class ",$classname()
		
		set tMetrics = ..GetMetricDefinitions()
		quit:$$$ISERR(tSC)
		
		set tSC = ..RegisterInternal(pDomainId, tMetrics, $classname(), pVerbose)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	write:pVerbose&&$$$ISERR(tSC) !,"An error occurred while trying to register ",$classname(),":",!,$system.Status.GetErrorText(tSC),!
	write:pVerbose !
	quit tSC
}

ClassMethod RegisterInternal(pDomainId As %Integer, pMetrics As %iKnow.Model.metrics, pDefinitionClass As %String, pVerbose As %Boolean = 1) As %Status [ Final, Internal ]
{
	set tSC = $$$OK
	try {
		for i = 1:1:pMetrics.metrics.Count() {
			set tMetric = pMetrics.metrics.GetAt(i)
			continue:tMetric.disabled
			
			set tIsNew = '##class(%iKnow.Metrics.Metric).NameIndexExists(pDomainId, tMetric.name)
			if 'tIsNew {
				set tMetricObj = ##class(%iKnow.Metrics.Metric).NameIndexOpen(pDomainId, tMetric.name)
				if (tMetricObj.DefinitionClass'=pDefinitionClass) {
					set tSC = $$$ERROR($$$GeneralError, "Metric '"_tMetric.name_"' is managed by another class: "_tMetricObj.DefinitionClass)
					quit
				}
				write:pVerbose !,"	Metric '",tMetric.name,"' is already registered with ID ",tMetricObj.MetricId
			} else {
				set tMetricObj = ##class(%iKnow.Metrics.Metric).%New(pDomainId, tMetric.name, tMetric.type, pDefinitionClass)
				if (tMetricObj="") { set tSC = %objlasterror  quit }
			}
			set tMetricObj.BuilderClass = tMetric.builderClass
			set tMetricObj.Description = tMetric.description
			set tMetricObj.MaintainIndex = tMetric.maintainIndex
			set tMetricObj.GroupField = tMetric.groupField
			set tSC = tMetricObj.%Save()
			quit:$$$ISERR(tSC)
			
			write:tIsNew&&pVerbose !,"	Successfully registered metric '",tMetric.name,"' (",tMetric.type,") with ID ",tMetricObj.MetricId
			
			
			// process the target types for this metric
			for j = 1:1:$length(tMetric.targets,",") {
				set tTarget = $$$LOWER($piece(tMetric.targets,",",j))
				set tSC = tMetricObj.AddTargetType(tTarget, .tOffset)
				quit:$$$ISERR(tSC)
				write:pVerbose !,"		added target type ",tTarget, " at offset ",tOffset
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Drops all metrics defined in the <xdata>Metrics</xdata> XData block from domain
/// <var>pDomainId</var>.
ClassMethod UnRegister(pDomainId As %Integer, pVerbose As %Boolean = 1) As %Status [ Final ]
{
	set tSC = $$$OK
	try {
		$$$IKCHECKDOMMGRX(pDomainId,tSC)
		write:pVerbose !,"Unregistering metrics and targets for class ",$classname()
		
		set tMetrics = ..GetMetricDefinitions()
		quit:$$$ISERR(tSC)
		
		set tSC = ..UnRegisterInternal(pDomainId, tMetrics, pVerbose)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	write:pVerbose&&$$$ISERR(tSC) !,"An error occurred while trying to unregister ",$classname(),":",!,$system.Status.GetErrorText(tSC)
	write:pVerbose !
	quit tSC
}

ClassMethod UnRegisterInternal(pDomainId As %Integer, pMetrics As %iKnow.Model.metrics, pVerbose As %Boolean = 1) As %Status [ Final, Internal ]
{
	set tSC = $$$OK
	try {
		for i = 1:1:pMetrics.metrics.Count() {
			set tMetric = pMetrics.metrics.GetAt(i)
			
			set tMetricObj = ##class(%iKnow.Metrics.Metric).NameIndexOpen(pDomainId, tMetric.name)
			continue:tMetricObj=""
			
			set tSC = ##class(%iKnow.Metrics.Metric).%Delete(tMetricObj.%Oid())
			quit:$$$ISERR(tSC)
			
			write:pVerbose !,"	Successfully dropped metric '",tMetric.name,"'"
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Returns the list of metrics defined in <xdata>Metrics</xdata> as a 
/// <class>%iKnow.Model.metrics</class> object.</p>
ClassMethod GetMetricDefinitions() As %iKnow.Model.metrics [ CodeMode = objectgenerator, Final, Internal ]
{
	set tSC = $$$OK
	try {
		// exit if we're not in the parent class
		if (%class.Abstract || (%class.Name = "%iKnow.Metrics.MetricDefinition")) {
			do %code.WriteLine(" quit """"")
			quit
		}
		
		do %code.WriteLine("	set tSC = $$$OK, mtrcs1 = """"")
		do %code.WriteLine("	try {")
		
		// first locate the Metrics XData block
		set tXDataIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||Metrics")
		if (tXDataIndex="") {
			set tSC = $$$ERROR($$$GeneralError, "No Metrics XData block in MetricDefinition class")
			quit
		}
		set tXDataStream = %compiledclass.XDatas.GetAt(tXDataIndex).Data
		do tXDataStream.Rewind()
		if (tXDataStream.Size <= 0) {
			set tSC = $$$ERROR($$$GeneralError, "Metrics XData block in MetricDefinition class is empty")
			quit
		}
		
		// correlate the XData stream with %iKnow.Model.Metrics.metric
		set tReader = ##class(%XML.Reader).%New()
		set tSC = tReader.OpenStream(tXDataStream)
		quit:$$$ISERR(tSC)
		
		// we expect only a single <metrics> element
		do tReader.Correlate("metrics","%iKnow.Model.metrics")
		do tReader.Next(.tMetrics,.tSC)
		quit:$$$ISERR(tSC)
		
		if '$isobject(tMetrics) {
			set tSC = $$$ERROR($$$GeneralError,"No <metrics> element found in MetricDefinition XData.")
			quit
		}
		
		set tSC = tMetrics.%Validate(-1)
		quit:$$$ISERR(tSC)
		
		do tMetrics.%GenerateCode(%code, 0)
		
		do %code.WriteLine("	} catch (ex) {")
		do %code.WriteLine("		set tSC = ex.AsStatus()")
		do %code.WriteLine("	}")
		do %code.WriteLine("	quit mtrcs1")
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
