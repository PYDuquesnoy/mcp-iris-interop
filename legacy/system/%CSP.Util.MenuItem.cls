/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Defines an item within a Menu for a CSP Menu page.
Class %CSP.Util.MenuItem Extends (%SerialObject, %XML.Adaptor) [ Inheritance = right, ServerOnly = 1, System = 4 ]
{

/// Value to display for menu item
Property Caption As %String(MAXLEN = 100, XMLNAME = "caption", XMLPROJECTION = "attribute");

/// URL to go to when menu item is chosen
Property HREF As %String(MAXLEN = 100, XMLNAME = "link", XMLPROJECTION = "attribute");

/// Help to display for menu item
Property Help As %String(MAXLEN = 400, XMLNAME = "help", XMLPROJECTION = "attribute");

/// (Optional) Resource required in order to use this link
Property Resource As %String(MAXLEN = 100, XMLNAME = "resource", XMLPROJECTION = "attribute");

/// (Optional) A COS expression that must evaluate true in order to use this link
Property Condition As %String(MAXLEN = 255, XMLNAME = "condition", XMLPROJECTION = "attribute");

/// What type of action to perform:<br>
/// link: link to another page (default).<br>
/// popup: launch a popup window.<br>
Property Type As %String(VALUELIST = ",link,popup", XMLNAME = "type", XMLPROJECTION = "attribute");

/// Utility method to generate code for this object
Method GenerateCode() As %String
{
	Set code = ""
	Set code = code _ " Set tMenuItem = ##class(%CSP.Util.MenuItem).%New()" _ $$$EOL
	If (..HREF '= "") {
		Set code = code _ " Set tMenuItem.HREF = " _ ##class(%CSP.Util.Pane).QuoteCOS(..HREF) _ $$$EOL
	}
	If (..Caption '= "") {
		Set code = code _ " Set tMenuItem.Caption = $$$Text(" _ ##class(%CSP.Util.Pane).QuoteCOS(..Caption) _ ")" _$$$EOL
	}
	If (..Help '= "") {
		Set code = code _ " Set tMenuItem.Help = $$$Text(" _ ##class(%CSP.Util.Pane).QuoteCOS(..Help) _ ")" _ $$$EOL
	}
	If (..Resource '= "") {
		Set code = code _ " Set tMenuItem.Resource = " _ ##class(%CSP.Util.Pane).QuoteCOS(..Resource) _ $$$EOL
	}
	If (..Condition '= "") {
		Set code = code _ " Set tMenuItem.Condition = " _ ##class(%CSP.Util.Pane).QuoteCOS(..Condition) _ $$$EOL
	}
	If (..Type '= "") {
		Set code = code _ " Set tMenuItem.Type = " _ ##class(%CSP.Util.Pane).QuoteCOS(..Type) _ $$$EOL
	}
	Quit code
}

Storage Default
{
<Data name="MenuItemState">
<Value name="1">
<Value>Caption</Value>
</Value>
<Value name="2">
<Value>HREF</Value>
</Value>
<Value name="3">
<Value>Popup</Value>
</Value>
<Value name="4">
<Value>Role</Value>
</Value>
<Value name="5">
<Value>Help</Value>
</Value>
<Value name="6">
<Value>Resource</Value>
</Value>
<Value name="7">
<Value>Condition</Value>
</Value>
<Value name="8">
<Value>Type</Value>
</Value>
</Data>
<State>MenuItemState</State>
<StreamLocation>^%CSP.Util.MenuItemS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
