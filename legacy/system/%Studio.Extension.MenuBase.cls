/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Table of user defined menus for use with Studio customisation
Class %Studio.Extension.MenuBase Extends (%Persistent, %XML.Adaptor) [ Inheritance = right, System = 3 ]
{

Index NameIdx On Name [ IdKey ];

Relationship Menu As Menu(XMLPROJECTION = "ELEMENT") [ Cardinality = children, Inverse = MenuBase ];

/// Classname of the source control class associated with these menus
Property Name As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE");

Storage Default
{
<Data name="MenuBaseDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^oddStudioMenu</DataLocation>
<ExtentSize>100000</ExtentSize>
<IdLocation>^oddStudioMenu</IdLocation>
<IndexLocation>^oddStudioMenuI</IndexLocation>
<StreamLocation>^oddStudioMenuS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
