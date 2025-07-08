/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This element allows loading dictionary content from an external file or from a SQL query,
/// as an alternative to fully listing the dictionary content in &lt;dictionary&gt;,
/// &lt;item&gt; and &lt;term&gt; elements.
Class %iKnow.Model.dictionaryExternal Extends %iKnow.Model.node [ Deprecated, System = 3 ]
{

Parameter XMLNAME = "external";

/// Link to the &lt;matching&gt; element this dictionary belongs to.
Relationship matching As %iKnow.Model.matching(XMLPROJECTION = "none") [ Cardinality = one, Inverse = external ];

/// The query to source the dictionary content from
Property sql As %String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE");

/// The file containing the dictionary content
Property file As %String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE");

/// When referring to a file, this property defines the delimiter separating the different columns in the file
Property delimiter As %String(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = ";" ];

/// When referring to a file, this property defines how many header rows to skip at the top of the file
Property headerRows As %Integer(XMLPROJECTION = "ATTRIBUTE");

Relationship columns As %iKnow.Model.dictionaryExternalColumn(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = external ];

Method %Validate(pDomainId As %Integer, pDomainDefinition As %iKnow.Model.domain) As %Status
{
	set tSC = $$$OK
	try {
		
		if (..file="") && (..sql="") {
			set tSC = $$$ERROR($$$GeneralError, "In an <external> element, either the sql or file attribute should be non-null")
			quit
		}
		if (..file'="") && (..sql'="") {
			set tSC = $$$ERROR($$$GeneralError, "In an <external> element, either the sql or file attribute should be non-null, but not both")
			quit
		}
		
		for i = 1:1:..columns.Count() {
			set tColumn = ..columns.GetAt(i)
			set tSC = tColumn.%Validate(pDomainId, pDomainDefinition)
			quit:$$$ISERR(tSC)
			
			if ($i(tRoleCount(tColumn.role))>1) && (tColumn.role'="term") {
				set tSC = $$$ERROR($$$GeneralError, "Duplicate column spec for role '"_tColumn.role_"'")
				quit
			}
		}
		quit:$$$ISERR(tSC)
		for tRole = "dictionary name", "item URI", "term" {
			if '$d(tRoleCount(tRole)) {
				set tSC = $$$ERROR($$$GeneralError, "Missing column spec for role '"_tRole_"'")
				quit
			}
		}
		quit:$$$ISERR(tSC)
		
		// test SQL statement
		if (..sql'="") {
			set tStmt = ##class(%SQL.Statement).%New()
			set tSC = tStmt.%Prepare(..sql)
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
