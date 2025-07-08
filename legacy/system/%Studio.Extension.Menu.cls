/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Table user top level menu names for use with user defined Studio customisation
Class %Studio.Extension.Menu Extends (%Persistent, %XML.Adaptor) [ Inheritance = right, System = 3 ]
{

Index NameIdx On Name [ IdKey ];

Property MenuItem As list Of MenuItem(XMLPROJECTION = "ELEMENT");

Relationship MenuBase As MenuBase [ Cardinality = parent, Inverse = Menu ];

/// Resource name of this top level menu item
Property Name As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE");

/// If the type is 0 then this is a regular top level menu. If the type is 1 then this is a context
/// submenu to be added to all the context menus.
Property Type As %Integer(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "0" ];

Storage Default
{
<Data name="MenuDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Type</Value>
</Value>
<Value name="3">
<Value>Test</Value>
</Value>
</Data>
<Data name="MenuItem">
<Attribute>MenuItem</Attribute>
<Structure>subnode</Structure>
<Subscript>"MenuItem"</Subscript>
</Data>
<DataLocation>{%%PARENT}("Menus")</DataLocation>
<DefaultData>MenuDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%Studio.Extension.MenuBaseC("Menu")</IdLocation>
<IndexLocation>^%Studio.Extension.MenuI</IndexLocation>
<StreamLocation>^%Studio.Extension.MenuS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
