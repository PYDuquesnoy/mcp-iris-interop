/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents an link item within a DeepSee folder.<br/>
/// A link is a wrapper around a URL; when the user selects it, the UserPortal
/// navigates to the URL.
Class %DeepSee.UserLibrary.Link Extends %DeepSee.UserLibrary.FolderItem [ System = 4 ]
{

Parameter XMLNAME = "link";

/// This is the extension returned by this type from the Finder.
Parameter ITEMTYPE = "link";

Parameter ICON = "deepsee/ds2_globe_44.png";

Parameter LARGEICON = "deepsee/ds2_globe_44.png";

/// URL for this link.
Property href As %String(MAXLEN = 1000, XMLPROJECTION = "attribute");

/// Array of URL parameters to apply to the link.
Property parameters As array Of %String(MAXLEN = 5000, XMLKEYNAME = "name", XMLNAME = "parameter", XMLPROJECTION = "ELEMENT");

/// Return the URL for this item.
Method %GetURL() As %String
{
	Set tURL = ..href
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
	Quit $$$Text("Link","%DeepSee")
}

Storage Default
{
<Data name="LinkDefaultData">
<Subscript>"Link"</Subscript>
<Value name="1">
<Value>href</Value>
</Value>
</Data>
<Data name="parameters">
<Attribute>parameters</Attribute>
<Structure>subnode</Structure>
<Subscript>"%DeepSee.UserLibrary.Link.parameters"</Subscript>
</Data>
<DefaultData>LinkDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
