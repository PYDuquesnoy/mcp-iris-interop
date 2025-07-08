/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Model representation of a specific <class>%iKnow.UserDictionary</class>, which can be referred
/// from <class>%iKnow.Model.configuration</class> entries. 
Class %iKnow.Model.userDictionary Extends %iKnow.Model.node [ Deprecated, System = 3 ]
{

Relationship domain As %iKnow.Model.domain(XMLPROJECTION = "none") [ Cardinality = one, Inverse = userDictionaries ];

/// Name of this User Dictionary
Property name As %String(MAXLEN = 150, XMLPROJECTION = "ATTRIBUTE") [ Required ];

/// Optional description
Property description As %String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE");

Relationship entries As list Of %iKnow.Model.userDictionaryEntry(XMLELEMENTREF = 1, XMLNAME = "entry", XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = userDictionary ];

Method %Validate(pDomainId As %Integer, pDomainDefinition As %iKnow.Model.domain) As %Status
{
	set tSC = $$$OK
	try {
		
		if (..name="") {
			set tSC = $$$ERROR($$$GeneralError, "'name' is a required attribute for <userDictionary>")
			quit
		} else {
			set tUserDict = ##class(%iKnow.UserDictionary).NameIndexOpen(..name)
			if $isobject(tUserDict) {
				set tDefClass = ^IRIS.IK.Sys.Params(pDomainId,$$$IKPDEFINITIONCLASS)
				if '$d(^IRIS.IK.Sys.Definition(tDefClass,"userdict",tUserDict.Id)) {
					set tSC = $$$ERROR($$$IKUserDictWithNameExists, ..name)
					quit
				}
			}
		}
		
		// verify if the name is unique
		set tCount = 0
		for i = 1:1:..domain.userDictionaries.Count() {
			set tUD = ..domain.userDictionaries.GetAt(i)
			set:tUD.name=..name tCount = tCount+1
		}
		if (tCount > 1) {
			set tSC = $$$ERROR($$$GeneralError, "Duplicate <userDictionary> name: '"_..name_"'")
			quit
		}
		
		// verify elements
		for i = 1:1:..entries.Count() {
			set tSC = ..entries.GetAt(i).%Validate(pDomainId, pDomainDefinition)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
