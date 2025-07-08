/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Model representation of a Dictionary Term.
/// See also <class>%iKnow.Matching.DictionaryAPI</class>
Class %iKnow.Model.dictionaryTerm Extends %iKnow.Model.node [ Deprecated, System = 3 ]
{

Parameter XMLNAME = "term";

/// The item this term belongs to.
Relationship item As %iKnow.Model.dictionaryItem(XMLPROJECTION = "none") [ Cardinality = one, Inverse = terms ];

/// The string representation of this Dictionary Term. This string will will be indexed by the
/// iKnow engine as to be able to properly compare it against indexed source text, using the same
/// normalized entity structure.
Property string As %String(MAXLEN = 150, XMLPROJECTION = "ATTRIBUTE");

/// The language to use for indexing this Dictionary Term.
Property language As %String(MAXLEN = 10, XMLPROJECTION = "ATTRIBUTE");

/// If set to 1, this element is ignored when compiling, validating and building the domain
Property disabled As %Boolean(XMLPROJECTION = "attribute");

Method %Validate(pDomainId As %Integer, pDomainDefinition As %iKnow.Model.domain) As %Status
{
	set tSC = $$$OK
	try {
		quit:..disabled
		
		if (..string="") {
			set tSC = $$$ERROR($$$GeneralError, "Dictionary Term string is a required field")
			quit
		}
		
		if (..language'="") && '$lf($$$IKLANGUAGES, $$$LOWER(..language)) {
			set tSC = $$$ERROR($$$IKLanguageDoesNotExist, ..language)
			quit
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
