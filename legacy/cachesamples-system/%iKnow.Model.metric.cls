/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>The <package>%iKnow.Metrics</package> infrastructure is deprecated in favour of the
/// more SQL-oriented approach offered through <class>%iKnow.Tables.Utils</class>, where you
/// can add computed fields at different levels and choose whether they need to be persisted or not.</p>
Class %iKnow.Model.metric Extends %iKnow.Model.node [ Deprecated, System = 3 ]
{

/// The &lt;metrics&gt; element this metric belongs to
Relationship group As %iKnow.Model.metrics(XMLPROJECTION = "none") [ Cardinality = one, Internal, Inverse = metrics ];

/// Name of the metric.
/// <p>WARNING: Changing the name of a &lt;metric&gt; element will create a new metric
/// definition and not change the name of an existing one.</p>
Property name As %String(MAXLEN = 250, XMLPROJECTION = "attribute");

/// Description of the metric
Property description As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

/// Context type to which the metric applies, either $$$IKMTRTYPEDOMAIN, $$$IKMTRTYPESOURCE or $$$IKMTRTYPEGROUP
Property type As %String(VALUELIST = ",domain,source,group", XMLPROJECTION = "attribute") [ InitialExpression = "domain" ];

/// Comma-separated list of the target elements this metric applies to. Any combination of
/// $$$IKMTRENTITY, $$$IKMTRCRC, $$$IKMTRCC, $$$IKMTRPATH, $$$IKMTRSENTENCE and $$$IKMTRSOURCE
Property targets As %String(MAXLEN = 250, XMLPROJECTION = "attribute");

/// The subclass of <class>%iKnow.Metrics.MetricBuilder</class> this metric will be build by.
Property builderClass As %String(MAXLEN = 250, XMLPROJECTION = "attribute");

/// Defines whether indices on this metric should be built and maintained automatically when 
/// metric values change as the result of a Build() or SetValue() invocation.
Property maintainIndex As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// If set to 1, this element is ignored when compiling, validating and building
Property disabled As %Boolean(XMLPROJECTION = "attribute");

/// If the context type (<property>type</property>) is $$$IKMTRTYPEGROUP ("group"), this specifies
/// the metadata field on which the grouping is based. 
Property groupField As %String(XMLPROJECTION = "attribute");

Method %Validate(pDomainId As %Integer, pDomainDefinition As %iKnow.Model.domain = "") As %Status
{
	set tSC = $$$OK
	try {
		quit:..disabled
		
		if (..name="") {
			set tSC = $$$ERROR($$$GeneralError, "Metric name is a required attribute")
			quit
		}
		
		if (..type="") {
			set tSC = $$$ERROR($$$GeneralError, "Metric '"_..name_"': context type is a required attribute")
			quit
		}
		
		if (..type=$$$IKMTRTYPESOURCE) && ..maintainIndex {
			set tSC = $$$ERROR($$$GeneralError, "No indices are maintained for a source-level metric ('"_..name_"')")
			quit
		}
		
		if (..type=$$$IKMTRTYPEGROUP) && (..groupField = "") {
			set tSC = $$$ERROR($$$GeneralError, "Metrics with context type 'group' need to have their groupField set")
			quit
		}
		
		if (..groupField'="") && (..type'=$$$IKMTRTYPEGROUP) {
			set tSC = $$$ERROR($$$GeneralError, "Only metrics of context type 'group' can register a groupField")
			quit
		}
		
		if (..groupField'="") && (pDomainId>0) {
			set tField = ##class(%iKnow.Objects.MetadataField).NameIndexOpen(pDomainId, ..groupField)
			if '$isobject(tField) || ((tField.StorageType '= $$$MDSTCOMPRESS) && (tField.StorageType '= $$$MDSTCOMPRESSBITMAP)) {
				set tSC = $$$ERROR($$$GeneralError, "groupField needs to refer to a field with compressed storage type ($$$MDSTCOMPRESS or $$$MDSTCOMPRESSBITMAP)")
				quit
			}
		}
		
		if (..builderClass '= "") && '$$IsDerivedFrom^%occLibrary(..builderClass,"%iKnow.Metrics.MetricBuilder") {
			set tSC = $$$ERROR($$$GeneralError, "Metric builder class '"_..builderClass_"' does not extend %iKnow.Metrics.MetricBuilder")
			quit
		}
		
		if (..targets = "") {
			set tSC = $$$ERROR($$$GeneralError, "Metric must define at least one target")
			quit
		} else {
			set tValidTargets = $lb($$$IKMTRENTITY, $$$IKMTRCRC, $$$IKMTRCC, $$$IKMTRPATH, $$$IKMTRSENTENCE, $$$IKMTRSOURCE)
			set ..targets = $$$LOWER($zstrip(..targets,"*W"))
			for i = 1:1:$length(..targets,",") {
				set tTarget = $piece(..targets,",",i)
				if '$lf(tValidTargets,tTarget) {
					set tSC = $$$ERROR($$$GeneralError, "Invalid metric target: '"_tTarget_"'")
					quit
				}
			}
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
