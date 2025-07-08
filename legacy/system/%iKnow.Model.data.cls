/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Model representation of all the source data to be loaded into the iKnow domain (as represented
/// by a <class>%iKnow.Model.domain</class> object).
Class %iKnow.Model.data Extends %iKnow.Model.node [ Deprecated, System = 3 ]
{

/// If set to 1, this element is ignored when compiling, validating and building the domain
Property disabled As %Boolean(XMLPROJECTION = "attribute");

/// The locations to load data from, as represented by a <class>%iKnow.Model.list</class> instance.
Relationship lists As %iKnow.Model.list(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = data ];

/// Whether or not to drop all existing source data from the domain at the start of the %Build()
/// method. Defaults to 1.
Property dropBeforeBuild As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

Method %Validate(pDomainId As %Integer, pDomainDefinition As %iKnow.Model.domain) As %Status
{
	set tSC = $$$OK
	try {
		quit:..disabled
		
		// validate lists and their descendants
		kill tNames
		for i = 1:1:..lists.Count() {
			set tList = ..lists.GetAt(i)
			set tSC = tList.%Validate(pDomainId, pDomainDefinition)
			quit:$$$ISERR(tSC)
			if (tList.listname'="") && ($i(tNames(tList.listname))>1) {
				set tSC = $$$ERROR($$$GeneralError, "Data Location name not unique: '"_tList.listname_"'")
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
