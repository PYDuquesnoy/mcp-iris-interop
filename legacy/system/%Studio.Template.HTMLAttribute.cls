/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Represents an HTML attribute associated with a specific HTML element.<BR>
/// See the <CLASS>%Studio.Template.HTMLElement</CLASS> class for more information.
Class %Studio.Template.HTMLAttribute Extends (%Persistent, %XML.Adaptor) [ Inheritance = right, Not ProcedureBlock, System = 3 ]
{

/// The tag this attribute is associated with.
Relationship Tag As HTMLElement [ Cardinality = parent, Inverse = Attrs ];

Parameter XMLNAME = "attr";

/// Name of this attribute.
Property Name As %String(MAXLEN = 256, XMLNAME = "name", XMLPROJECTION = "attribute");

/// Type of this attribute.
Property Type As %String(XMLNAME = "type", XMLPROJECTION = "attribute");

/// Category of this attribute.
Property Category As %String(XMLNAME = "cat", XMLPROJECTION = "attribute");

/// List of enumerated values (for enum types).
Property Enum As %String(MAXLEN = 300, XMLNAME = "enum", XMLPROJECTION = "attribute");

/// Description of this attribute.
Property Description As %String(MAXLEN = 255, XMLNAME = "desc", XMLPROJECTION = "attribute");

Storage Default
{
<Data name="HTMLAttributeDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Category</Value>
</Value>
<Value name="3">
<Value>Description</Value>
</Value>
<Value name="4">
<Value>Enum</Value>
</Value>
<Value name="5">
<Value>Name</Value>
</Value>
<Value name="6">
<Value>Type</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("Attrs")</DataLocation>
<DefaultData>HTMLAttributeDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>{%%PARENT}("Attrs")</IdLocation>
<IndexLocation>^%Studio.HTMLAttributeI</IndexLocation>
<StreamLocation>^%Studio.HTMLAttributeS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
