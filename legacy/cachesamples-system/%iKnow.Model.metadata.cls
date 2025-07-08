/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Model representation of the set of metadata fields to be registered in the iKnow domain (as represented
/// by a <class>%iKnow.Model.domain</class> object).
Class %iKnow.Model.metadata Extends %iKnow.Model.node [ Deprecated, System = 3 ]
{

/// If set to 1, this element is ignored when compiling, validating and building the domain
Property disabled As %Boolean(XMLPROJECTION = "attribute");

/// Metadata fields registered
Relationship fields As %iKnow.Model.metadataField(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = metadata ];

Method %Validate(pDomainId As %Integer, pDomainDefinition As %iKnow.Model.domain) As %Status
{
	set tSC = $$$OK
	try {
		quit:..disabled
		
		// validate metadata fields
		kill tNames
		for i = 1:1:..fields.Count() {
			set tMD = ..fields.GetAt(i)
			set tSC = tMD.%Validate(pDomainId, pDomainDefinition)
			quit:$$$ISERR(tSC)
			if $i(tNames(tMD.name))>1 {
				set tSC = $$$ERROR($$$GeneralError, "Metadata field name not unique: '"_tMD.name_"'")
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
