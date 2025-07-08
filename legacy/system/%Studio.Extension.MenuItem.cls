/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Table of user defined menu items for Studio user interface extention
Class %Studio.Extension.MenuItem Extends (%SerialObject, %XML.Adaptor) [ Inheritance = right, System = 3 ]
{

/// Resource name of this menu item
Property Name As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE");

/// True if this menu item is enabled, false to disable this menu item
Property Enabled As %Boolean(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "1" ];

/// If this menu item is selected does the current document/project need to be saved?
/// This is a bit string with '000' meaning nothing should be saved and a '1' in the
/// following position meaning:
/// <ul><li>1 - Current document must be saved</li>
/// <li>2 - Project must be saved</li>
/// <li>3 - Force 'Save All'</li></ul>
Property Save As %String(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "000" ];

/// If true then this is a menu separator rather than a menu item.
/// All other properties will be ignored for a separator
Property Separator As %Boolean(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0 ];

Storage Default
{
<Data name="MenuItemDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Enabled</Value>
</Value>
<Value name="3">
<Value>Name</Value>
</Value>
</Data>
<Data name="MenuItemState">
<Value name="1">
<Value>Enabled</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Save</Value>
</Value>
<Value name="4">
<Value>Separator</Value>
</Value>
</Data>
<DataLocation>^%Studio.Extension.MenuItemD</DataLocation>
<DefaultData>MenuItemDefaultData</DefaultData>
<IdLocation>^%Studio.Extension.MenuItemD</IdLocation>
<IndexLocation>^%Studio.Extension.MenuItemI</IndexLocation>
<State>MenuItemState</State>
<StreamLocation>^%Studio.Extension.MenuItemS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
