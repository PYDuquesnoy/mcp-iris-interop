/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Defines a submit button for an AutoForm form.
Class %CSP.Util.FormButton Extends (%SerialObject, %XML.Adaptor) [ Inheritance = right, ServerOnly = 1, System = 4 ]
{

Parameter XMLNAME = "Button";

/// Name used for a form submit button: e.g., $AUTOFORM_SAVE
Property Name As %String(MAXLEN = 30, XMLNAME = "name", XMLPROJECTION = "attribute");

/// What type of action does this button do: submit (default), popup (show a popup).
Property Type As %String(VALUELIST = ",popup", XMLNAME = "type", XMLPROJECTION = "attribute");

/// URL associated with this button (currently used for popup);
Property HREF As %String(MAXLEN = 128, XMLNAME = "href", XMLPROJECTION = "attribute");

/// Caption used for a form submit button (value attribute for the button)
Property Caption As %String(MAXLEN = 50, XMLNAME = "caption", XMLPROJECTION = "attribute");

/// If present, then display this as a confirmation message for the button.
Property Confirm As %String(MAXLEN = 100, XMLNAME = "confirm", XMLPROJECTION = "attribute");

/// If defined, onclick behavior (JavaScript) for this button
Property OnClick As %String(MAXLEN = 255, XMLNAME = "onclick", XMLPROJECTION = "attribute");

/// Utility method to generate code for this object
Method GenerateCode() As %String
{
	Set code = ""
	Set code = code _ " Set tButton = ##class(%CSP.Util.FormButton).%New()" _ $$$EOL
	Set code = code _ " Set tButton.Name = " _ ##class(%CSP.Util.Pane).QuoteCOS(..Name) _ $$$EOL
	Set code = code _ " Set tButton.Caption = $$$Text(" _ ##class(%CSP.Util.Pane).QuoteCOS(..Caption) _ ")" _ $$$EOL
	Set code = code _ " Set tButton.Confirm = $$$Text(" _ ##class(%CSP.Util.Pane).QuoteCOS(..Confirm) _ ")" _ $$$EOL
	Set code = code _ " Set tButton.HREF = " _ ##class(%CSP.Util.Pane).QuoteCOS(..HREF) _ $$$EOL
	Set code = code _ " Set tButton.Type = """ _ ..Type_ """" _ $$$EOL
	Set code = code _ " Set tButton.OnClick = " _ ##class(%CSP.Util.Pane).QuoteCOS(..OnClick) _ $$$EOL
	
	Quit code
}

Storage Default
{
<Data name="FormButtonState">
<Subscript>"%CSP.Util.FormButton"</Subscript>
<Value name="1">
<Value>Caption</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>HREF</Value>
</Value>
<Value name="4">
<Value>Type</Value>
</Value>
<Value name="5">
<Value>Confirm</Value>
</Value>
<Value name="6">
<Value>OnClick</Value>
</Value>
</Data>
<State>FormButtonState</State>
<StreamLocation>^%CSP.Util.FormButtonS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
