/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Defines a menu for a CSP Menu page.
Class %CSP.Util.Menu Extends (%SerialObject, %XML.Adaptor) [ Inheritance = right, ServerOnly = 1, System = 4 ]
{

Parameter XMLIGNORENULL = 1;

/// Title of this menu
Property Title As %String(MAXLEN = 100, XMLNAME = "title", XMLPROJECTION = "attribute");

/// Optional subtitle of this menu
Property Subtitle As %String(MAXLEN = 100, XMLNAME = "subtitle", XMLPROJECTION = "attribute");

/// Background color for the menu title
Property Background As %String(MAXLEN = 100, XMLNAME = "background", XMLPROJECTION = "attribute");

/// Defines the menu items for this menu
Property Items As list Of MenuItem(XMLNAME = "MenuItem", XMLPROJECTION = "ELEMENT");

/// Utility method to generate code for this object
Method GenerateCode() As %String
{
	Set code = ""
	Set code = code _ " Set tMenu = ##class(%CSP.Util.Menu).%New()" _ $$$EOL
	If (..Title '= "") {
		Set code = code _ " Set tMenu.Title = $$$Text(" _ ##class(%CSP.Util.Pane).QuoteCOS(..Title) _ ")" _ $$$EOL
	}
	If (..Subtitle '= "") {
		Set code = code _ " Set tMenu.Subtitle = $$$Text(" _ ##class(%CSP.Util.Pane).QuoteCOS(..Subtitle) _ ")" _ $$$EOL
	}
	If (..Background '= "") {
		Set code = code _ " Set tMenu.Background = " _ ##class(%CSP.Util.Pane).QuoteCOS(..Background) _ $$$EOL
	}

	For i = 1:1:..Items.Count() {
		Set tItem = ..Items.GetAt(i)
		Set code = code _ tItem.GenerateCode()
		Set code = code _ " Do tMenu.Items.Insert(tMenuItem)" _ $$$EOL
		Set code = code _ $$$EOL
	}

	Quit code
}

Storage Default
{
<Data name="MenuState">
<Value name="1">
<Value>Background</Value>
</Value>
<Value name="2">
<Value>Title</Value>
</Value>
<Value name="3">
<Value>Items</Value>
</Value>
<Value name="4">
<Value>Subtitle</Value>
</Value>
</Data>
<State>MenuState</State>
<StreamLocation>^%CSP.Util.MenuS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
