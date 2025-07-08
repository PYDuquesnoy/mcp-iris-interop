/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Model representation of a Dictionary Term consisting of a single Dictionary Format element.
/// See also <class>%iKnow.Matching.DictionaryAPI</class>
Class %iKnow.Model.dictionaryFormat Extends %iKnow.Model.node [ Deprecated, System = 3 ]
{

Parameter XMLNAME = "format";

Relationship item As %iKnow.Model.dictionaryItem(XMLPROJECTION = "none") [ Cardinality = one, Inverse = formats ];

/// The implementation class to use for matching this format. This should be a subclass of 
/// <class>%iKnow.Matching.Formats.Format</class>
Property formatClass As %String(MAXLEN = 250, XMLPROJECTION = "ATTRIBUTE");

/// Any parameters required by <property>formatClass</property>
Property formatParams As %String(MAXLEN = 1000, XMLPROJECTION = "ATTRIBUTE");

/// If set to 1, this element is ignored when compiling, validating and building the domain
Property disabled As %Boolean(XMLPROJECTION = "attribute");

Method %Validate(pDomainId As %Integer, pDomainDefinition As %iKnow.Model.domain) As %Status
{
	set tSC = $$$OK
	try {
		quit:..disabled
		
		if (..formatClass="") {
			set tSC = $$$ERROR($$$GeneralError, "Dictionary Format class is a required field")
			quit
		} elseif '##class(%Dictionary.CompiledClass).%ExistsId(..formatClass) {
			set tSC = $$$ERROR($$$IKDFClassDoesNotExist, ..formatClass)
			quit
		} elseif '$$IsDerivedFrom^%occLibrary(..formatClass,"%iKnow.Matching.Formats.Format") {
			set tSC = $$$ERROR($$$GeneralError, ..formatClass _ " does not extend %iKnow.Matching.Formats.Format")
			quit
		}
		
		// BDB687
		if '##class(%iKnow.DomainDefinition).%IsProperCode(..formatParams) {
			set tSC = $classmethod(..formatClass, "TestParams", $lfs(..formatParams))
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
