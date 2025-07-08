/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Model representation of a Dictionary to be used for matching. 
/// See also <class>%iKnow.Matching.DictionaryAPI</class>
Class %iKnow.Model.dictionary Extends %iKnow.Model.node [ Deprecated, System = 3 ]
{

/// Link to the &lt;matching&gt; element this dictionary belongs to.
Relationship matching As %iKnow.Model.matching(XMLPROJECTION = "none") [ Cardinality = one, Inverse = dictionaries ];

/// The Dictionary Items registered in this Dictionary
Relationship items As %iKnow.Model.dictionaryItem(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = dictionary ];

/// A name for this Dictionary. A dictionary name should be unique within the domain.
Property name As %String(MAXLEN = 150, XMLPROJECTION = "ATTRIBUTE");

/// An optional description for this Dictionary.
Property description As %String(MAXLEN = 1000, XMLPROJECTION = "ATTRIBUTE");

/// The default language items and terms in this Dictionary are expressed in.
Property language As %String(MAXLEN = 10, XMLPROJECTION = "ATTRIBUTE");

/// The Matching profile to be used for matching terms in this dictionary.
/// See also <class>%iKnow.Model.matchingProfile</class>. Leave blank to use the default.
Property profile As %String(MAXLEN = 150, XMLPROJECTION = "ATTRIBUTE");

/// If set to 1, this element is ignored when compiling, validating and building the domain
Property disabled As %Boolean(XMLPROJECTION = "attribute");

Method %Validate(pDomainId As %Integer, pDomainDefinition As %iKnow.Model.domain) As %Status
{
	set tSC = $$$OK
	try {
		quit:..disabled
		
		if (..name="") {
			set tSC = $$$ERROR($$$GeneralError, "Dictionary name is a required field")
			quit
		}
		
		if (..language'="") && '$lf($$$IKLANGUAGES, $$$LOWER(..language)) {
			set tSC = $$$ERROR($$$IKLanguageDoesNotExist, ..language)
			quit
		}
		
		if (..profile'="") {
			if ($e(..profile,1,2)="0:") {
				if '$isobject(##class(%iKnow.Matching.MatchingProfile).GetProfileByName(0,..profile)) {
					set tSC = $$$ERROR($$$GeneralError, "Cross-domain matching profile '"_..profile_"' not found")
					quit
				}
			} else {
				set tFound = 0
				for i = 1:1:..matching.profiles.Count() {
					set tFound = (..profile = ..matching.profiles.GetAt(i).name)
					quit:tFound
				}
				if 'tFound {
					set tSC = $$$ERROR($$$GeneralError, "Matching profile '"_..profile_"' is not defined in this domain")
					quit
				}
			}
		}
		
		// validate items
		for i = 1:1:..items.Count() {
			set tSC = ..items.GetAt(i).%Validate(pDomainId, pDomainDefinition)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
