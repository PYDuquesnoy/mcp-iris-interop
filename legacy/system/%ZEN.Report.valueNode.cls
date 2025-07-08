/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for nodes that contain a value (such as element or attribute).
Class %ZEN.Report.valueNode Extends reportNode [ Abstract, Deprecated, System = 3 ]
{

/// Name used for the XML representation of this node.<br>
/// If a value is not supplied, "item" is used.<br>
/// This must contain a valid identifier value.
Property name As %ZEN.Datatype.name [ InitialExpression = "item", Required ];

/// Make sure name is a valid identifier.
ClassMethod nameIsValid(%val) As %Status
{
	//Quit $S($ZName($TR(%val,"_-","")):$$$OK,1:$$$ERROR($$$ParameterNameInvalid,%val))
	Quit $s(..IsQNAME(%val):$$$OK, 1:$$$ERROR($$$ParameterNameInvalid,%val))
}

/// Name of field (column) in the base query for this report that will
/// supply the value for this item.
/// If this starts with "!" then this is expression that evaluates to field name
Property field As %ZEN.Datatype.string;

/// Name of fields (columns) in the base query for this report that will
/// supply the values for this item.
Property fields As %ZEN.Datatype.string;

/// Only accumulate if accumif is true
Property accumIf As %ZEN.Datatype.string;

/// Make sure field name is a valid identifier.
ClassMethod fieldIsValid(%val) As %Status
{
	Quit 1 ; allow delimited identifiers
	// allow arbitrary expressions (expression starts with !")
	//if $e(%val)="!" Quit 1
	//else  Quit $S($ZName($TR(%val,"_","")):$$$OK,1:$$$ERROR($$$PropertyNameInvalid,%val))
}

/// Optional ObjectScript expression that can either be applied
/// to the value of this item (supplied as <var>%val</var>), or to provide an
/// arbitrary value for this item.<br>
/// For example:<br>
/// expression="%val*2"<br>
/// expression="..ReportProp"<br>
Property expression As %ZEN.Datatype.expression;

ClassMethod IsQNAME(pName) As %Boolean [ Internal ]
{
	#; [6]  QName       ::=  (Prefix ':')? LocalPart 
	#; [7]  Prefix      ::=  NCName 
	#; [8]  LocalPart   ::=  NCName 
	Quit ##class(%Compiler.XML.Generator.Adaptor).isXMLName(pName)
}

/// Validate if string is an NCName
/// 
ClassMethod IsNCNAME(pName) As %Boolean [ Internal ]
{
	Quit ##class(%Compiler.XML.Generator.Adaptor).isNCName(pName)
}

}
