/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Model.metadataValue Extends %iKnow.Model.node [ Deprecated, System = 3 ]
{

Relationship list As %iKnow.Model.list(XMLPROJECTION = "NONE") [ Cardinality = one, Inverse = metadataValues ];

Property field As %String(MAXLEN = 150, XMLPROJECTION = "ATTRIBUTE");

Property value As %String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE");

Property disabled As %Boolean(XMLPROJECTION = "ATTRIBUTE");

Method %Validate(pDomainId As %Integer, pDomainDefinition As %iKnow.Model.domain) As %Status
{
	set tSC = $$$OK
	try {
		quit:..disabled
		
		if (##class(%iKnow.Queries.MetadataAPI).GetFieldId(pDomainId, ..field)<=0) {
			set tFound = 0
			if $isobject(pDomainDefinition.metadata) {
				for i = 1:1:pDomainDefinition.metadata.fields.Count() {
					set tFound = (..field=pDomainDefinition.metadata.fields.GetAt(i).name)
					quit:tFound
				}
			}
			if ('tFound) {
				set tSC = $$$ERROR($$$IKMDFieldDoesNotExistE, ..field)
				quit
			}
		}
		
		if ..value="" {
			set tSC = $$$ERROR($$$GeneralError, "no field value specified")
			quit
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
