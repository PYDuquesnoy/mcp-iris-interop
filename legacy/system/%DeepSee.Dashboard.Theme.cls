/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A *theme* is a collection of style overrides for DeepSee components (such as charts) stored
/// as a folder item.<br/>
/// This lets you save the style for chart as part of a "theme" and then re-apply this them to other
/// charts.<br/>
Class %DeepSee.Dashboard.Theme Extends %DeepSee.UserLibrary.FolderItem [ System = 4 ]
{

/// Default value of public property for the class.
Parameter PUBLIC As BOOLEAN = 0;

Parameter XMLNAME = "theme";

Parameter ITEMTYPE = "theme";

Parameter ICON = "deepsee/ds2_palette_44.png";

Parameter LARGEICON = "deepsee/ds2_palette_44.png";

/// Array of override values (such as chart state) indexed by type (such as "barChart).
/// Each entry contains a set of override properties serialized as xml.
Property overrides As array Of %String(MAXLEN = 30000, XMLKEYNAME = "name", XMLNAME = "override", XMLPROJECTION = "ELEMENT");

/// Return the URL for this item.
Method %GetURL() As %String
{
	Set tURL = ""
	Quit tURL
}

/// Return the localized type name for this item.
Method %GetTypeName() As %String
{
	Quit $$$Text("DeepSee Theme","%DeepSee")
}

/// Return a list of all other folder items (including cubes or kpis) that this item depends upon.
Method %GetDependencies(pList As %String) As %Status
{
	Quit ##super(.pList)
}

Storage Default
{
<Data name="overrides">
<Attribute>overrides</Attribute>
<Structure>subnode</Structure>
<Subscript>"%DeepSee.Dashboard.Theme.overrides"</Subscript>
</Data>
<Type>%Storage.Persistent</Type>
}

}
