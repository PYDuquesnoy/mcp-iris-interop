/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents a Report shortcut within a DeepSee folder.<br/>
Class %DeepSee.UserLibrary.Report Extends %DeepSee.UserLibrary.FolderItem [ System = 4 ]
{

Parameter XMLNAME = "report";

/// This is the extension returned by this type from the Finder.
Parameter ITEMTYPE = "report";

Parameter ICON = "deepsee/ds2_page_44.png";

Parameter LARGEICON = "deepsee/ds2_page_44.png";

/// Report class name.
Property reportClass As %String(MAXLEN = 1000, XMLPROJECTION = "attribute");

/// Array of URL parameters to apply to the link.
Property parameters As array Of %String(MAXLEN = 5000, XMLKEYNAME = "name", XMLNAME = "parameter", XMLPROJECTION = "ELEMENT");

/// Return the URL for this item.
Method %GetURL() As %String
{
	Set tURL = ..reportClass
	Set:tURL'="" tURL = tURL_".zen"
	Set key = ..parameters.Next("")
	While (key'="") {
		Set value = ..parameters.GetAt(key)
		Set tURL = tURL _ $S(tURL["?":"&",1:"?") _ $ZCVT(key,"O","URL") _ "=" _ $ZCVT(value,"O","URL")
		Set key = ..parameters.Next(key)
	}
	Quit tURL
}

/// Return the localized type name for this item.
Method %GetTypeName() As %String
{
	Quit $$$Text("Report","%DeepSee")
}

Storage Default
{
<Data name="ReportDefaultData">
<Subscript>"Report"</Subscript>
<Value name="1">
<Value>reportClass</Value>
</Value>
</Data>
<Data name="parameters">
<Attribute>parameters</Attribute>
<Structure>subnode</Structure>
<Subscript>"%DeepSee.UserLibrary.Report.parameters"</Subscript>
</Data>
<DefaultData>ReportDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
