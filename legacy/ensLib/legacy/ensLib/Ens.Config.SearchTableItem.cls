/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// SearchTable Item specifier object, for parsing XData SearchTable definition
Class Ens.Config.SearchTableItem Extends (%RegisteredObject, Ens.Config.SearchTablePropAttrs, %XML.Adaptor) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 2 ]
{

Parameter XMLNAME = "Item";

Parameter XMLIGNORENULL = 1;

/// The DocType for which this expression applies. ":" or "" means all Doc objects, :nnn means objects with doc.Name nnn,
/// and ccc:sss means doc objects with doc.DocType = category ccc : structure sss.
Property DocType As %String(XMLPROJECTION = "ATTRIBUTE");

/// The name of the virtual property under which the value gotten with this expression will be stored.
Property PropName As %String(XMLPROJECTION = "ATTRIBUTE");

/// Indicates whether this expression should be ignored if it is a doc.Name expression or a default ("") expression,
///  and doc.DocType matches a different expression, and both expressions have the same PropertyName.
/// If true, no value for this expression will be stored for that doc.
/// If false, both expression values will be stored for the Property.
/// This allows subclasses or DocType expressions to optionally override generic, catch-all expressions
Property Supersedable As %Boolean(XMLPROJECTION = "ATTRIBUTE");

/// The expression to execute in order to retrieve the value for the virtual property
Property ValueGetExpression As %String(MAXLEN = "", XMLPROJECTION = "CONTENT");

/// Normalize view of PropType values gotten from XML definition; supply defaults
Method PropTypeGet() As %String
{
	#; Keep in sync with superclass VALUELIST definition
	Quit $Case($ZCVT(i%PropType,"L")
				,"integer":"Integer"
				,"numeric":"Numeric"
				,"boolean":"Boolean"
				,"datetime:hl7":"DateTime:HL7"
				,"datetime:odbc":"DateTime:ODBC"
				,"datetime":"DateTime:ODBC"
				,"string:casesensitive":"String:CaseSensitive"
				,:"String:CaseInsensitive")
}

/// Strip leading and trailing whitespace
Method DocTypeGet() As %String [ CodeMode = expression ]
{
$ZStrip(i%DocType,"<>W")
}

/// Strip leading and trailing whitespace
Method PropNameGet() As %String [ CodeMode = expression ]
{
$ZStrip(i%PropName,"<>W")
}

}
