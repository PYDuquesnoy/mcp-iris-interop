/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25iKnow.Model.metrics">NLP Domains</a>.</p>
/// <p>The <package>%iKnow.Metrics</package> infrastructure is deprecated in favour of the
/// more SQL-oriented approach offered through <class>%iKnow.Tables.Utils</class>, where you
/// can add computed fields at different levels and choose whether they need to be persisted or not.</p>
Class %iKnow.Model.metrics Extends %iKnow.Model.node [ Deprecated, System = 3 ]
{

/// If set to 1, this element is ignored when compiling, validating and building the domain.
/// This property is ignored in Metric Definitions (outside of a Domain Definition).
Property disabled As %Boolean(XMLPROJECTION = "attribute");

Relationship metrics As %iKnow.Model.metric(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = group ];

/// Whether or not metrics are to be built as part of the Domain Definition's %Build() method.
/// This property is ignored in Metric Definitions (outside of a Domain Definition).
Property autoExecute As %Boolean(XMLPROJECTION = "ATTRIBUTE");

Method %Validate(pDomainId As %Integer, pDomainDefinition As %iKnow.Model.domain = "") As %Status
{
	set tSC = $$$OK
	try {
		quit:..disabled
		
		// check individual metric definitions
		for i = 1:1:..metrics.Count() {
			set tSC = ..metrics.GetAt(i).%Validate(pDomainId, pDomainDefinition)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
