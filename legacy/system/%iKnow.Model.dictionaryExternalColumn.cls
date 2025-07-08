/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Model representation for columns in an external dictionary content source. Each column
/// represents an attribute of the dictionary, item or terms, as specified by the
/// <property>role</property> property.
Class %iKnow.Model.dictionaryExternalColumn Extends %iKnow.Model.node [ Deprecated, System = 3 ]
{

Parameter XMLNAME = "column";

/// Link to the &lt;matching&gt; element this dictionary belongs to.
Relationship external As %iKnow.Model.dictionaryExternal(XMLPROJECTION = "none") [ Cardinality = one, Inverse = columns ];

/// The position of the column in the file or query result set to be loaded
Property position As %Integer(XMLPROJECTION = "ATTRIBUTE");

/// If referring to a column in a CSV file, this boolean defines whether or not to strip 
/// quotes surrounding the actual value of that column.
Property stripQuotes As %Boolean(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

/// As an alternative to a <property>position</property> within the file or query result set,
/// <property>fixedValue</property> allows hardcoding a particular value.
Property fixedValue As %String(XMLPROJECTION = "ATTRIBUTE");

/// The type of content this &lt;column&gt; contains, to be used for creating dictionary content.
/// Each possible value can only be listed once, with the exception of "term", which can occur
/// any number of times (&gt;0) to simplify adding multiple columns as dictionary terms.
/// The "term", "dictionary name" and "item URI" roles must be supplied for this &lt;external&gt;
/// element to be valid.
Property role As %String(VALUELIST = ",dictionary name,dictionary description,item name,item URI,term,language", XMLPROJECTION = "ATTRIBUTE");

Method %Validate(pDomainId As %Integer, pDomainDefinition As %iKnow.Model.domain) As %Status
{
	set tSC = $$$OK
	try {
		
		if ..position && (..fixedValue'="") {
			set tSC = $$$ERROR($$$GeneralError, "A <column> element should either refer to a position within the file or query result, or specify a fixed value, but not both")
			quit
		}
		if '..position && (..fixedValue="") {
			set tSC = $$$ERROR($$$GeneralError, "A <column> element should either refer to a position within the file or query result, or specify a fixed value")
			quit
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
