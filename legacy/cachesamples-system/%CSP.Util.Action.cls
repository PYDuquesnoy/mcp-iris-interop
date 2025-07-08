/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Defines an action for a CSP Utility page.
Class %CSP.Util.Action Extends (%SerialObject, %XML.Adaptor) [ Inheritance = right, ServerOnly = 1, System = 4 ]
{

/// When used as a menu, this is the menu caption.<br>
/// This is a localizable value.
Property Caption As %String(MAXLEN = 100);

/// When appropriate, popup help for this action.<br>
/// This is a localizable value.
Property Popup As %String(MAXLEN = 100);

/// If present, then display this as a confirmation message for the action.
Property Confirm As %String(MAXLEN = 500);

/// Name of page to go to.
Property HREF As %String(MAXLEN = 128, XMLNAME = "href", XMLPROJECTION = "attribute");

/// What type of Action is this:<br>
/// link: link to another page (default).<br>
/// popup: launch a popup window.<br>
/// help: launch a documentation window. ID1 will be DocBook ID.<br>
Property Type As %String(VALUELIST = ",link,popup,help", XMLNAME = "type", XMLPROJECTION = "attribute");

/// If set, the name of the frame affected by the action
Property TargetFrame As %String(MAXLEN = 50, XMLNAME = "targetFrame", XMLPROJECTION = "attribute");

/// An array (subscripted by contiguous integer values) of ID values for this
/// action. These values are used to specify a specific instance of page to display. <br>
/// This value is either a literal or the name of column in the current query enclosed
/// within { } (e.g., {Name} ).
Property IDValues As %String [ MultiDimensional ];

/// A comma-separated list of all the IDValues in one list; this is used only by XML import/export.
Property IDExprList As %String(MAXLEN = 500, XMLNAME = "IDValues");

/// If true the values will be encrypted before they are added to the link
Property Encrypted As %Boolean(XMLNAME = "encrypted", XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// (Optional) A COS expression that must evaluate true in order to use this link
Property Condition As %String(MAXLEN = 255, XMLNAME = "condition", XMLPROJECTION = "attribute");

Method IDExprListGet() As %String
{
	Set val = ""
	Set count = +$O(..IDValues(""),-1)
	
	For i=1:1:count {
		Set val = val _ $S(i=1:"",1:",") _ $G(..IDValues(i))
	}

	Quit val
}

Method IDExprListSet(val As %String) As %Status
{
	Kill ..IDValues
	
	For i = 1:1:$L(val,",") {
		Set ..IDValues(i) = $P(val,",",i)
	}
	Quit $$$OK
}

/// Evaluate the current value of the IDValues
/// associated with this Action.
/// IDValues are either literals, 
/// or expressions referring to page properties: {$ID1}
Method GetIDValues(ByRef ids As %String)
{
	Set key = $O(..IDValues(""))
	While (key '= "") {
		Set val = ..IDValues(key)
		
		// test for expression involving $ID etc.
		If (($E(val,1,1) = "{") && ($E(val,2,2) = "$") && ($E(val,$L(val),$L(val)) = "}")) {
			Set val = $G(%request.Data($E(val,2,$L(val)-1),1))
		}

		Set ids(key) = val		
		Set key = $O(..IDValues(key))
	}
}

/// Utility method to generate code for this object
Method GenerateCode() As %String
{
	Set code = ""
	Set code = code _ " Set tAction = ##class(%CSP.Util.Action).%New()" _ $$$EOL
	If (..HREF '= "") {
		Set code = code _ " Set tAction.HREF = " _ ##class(%CSP.Util.Pane).QuoteCOS(..HREF) _ $$$EOL
	}
	If (..Caption '= "") {
		//Set code = code _ " Set tAction.Caption = " _ ##class(%CSP.Util.Pane).QuoteCOS(..Caption) _ $$$EOL
		Set code = code _ " Set tAction.Caption = $$$Text(" _ ##class(%CSP.Util.Pane).QuoteCOS(..Caption) _ ")"_$$$EOL
	}
	If (..Popup '= "") {
		Set code = code _ " Set tAction.Popup = $$$Text(" _ ##class(%CSP.Util.Pane).QuoteCOS(..Popup) _ ")"_$$$EOL
	}
	If (..Confirm '= "") {
		Set code = code _ " Set tAction.Confirm = $$$Text(" _ ##class(%CSP.Util.Pane).QuoteCOS(..Confirm )_ ")" _ $$$EOL
	}
	If (..Type '= "") {
		Set code = code _ " Set tAction.Type = """ _ ..Type _ """" _ $$$EOL
	}
	If (..TargetFrame '= "") {
		Set code = code _ " Set tAction.TargetFrame = " _ ##class(%CSP.Util.Pane).QuoteCOS(..TargetFrame) _ $$$EOL
	}
	If (..IDExprList '= "") {
		Set code = code _ " Set tAction.IDExprList = """ _ ..IDExprList _ """" _ $$$EOL
	}
	If (..Encrypted '= "") {
		Set code = code_ " Set tAction.Encrypted = " _ ..Encrypted _ $$$EOL
	}
	If (..Condition '= "") {
		Set code = code _ " Set tAction.Condition = " _ ##class(%CSP.Util.Pane).QuoteCOS(..Condition) _ $$$EOL
	}
	
	Quit code
}

Storage Default
{
<Data name="ActionState">
<Subscript>"%CSP.Util.Action"</Subscript>
<Value name="1">
<Value>Page</Value>
</Value>
<Value name="2">
<Value>Class</Value>
</Value>
<Value name="3">
<Value>IDColumn</Value>
</Value>
<Value name="4">
<Value>Caption</Value>
</Value>
<Value name="5">
<Value>Popup</Value>
</Value>
<Value name="6">
<Value>IDValue</Value>
</Value>
<Value name="7">
<Value>IDExprList</Value>
</Value>
<Value name="8">
<Value>Link</Value>
</Value>
<Value name="9">
<Value>HREF</Value>
</Value>
<Value name="10">
<Value>Column</Value>
</Value>
<Value name="11">
<Value>Type</Value>
</Value>
<Value name="12">
<Value>Confirm</Value>
</Value>
<Value name="13">
<Value>LocalTarget</Value>
</Value>
<Value name="14">
<Value>TargetFrame</Value>
</Value>
<Value name="15">
<Value>Condition</Value>
</Value>
<Value name="16">
<Value>Encrypted</Value>
</Value>
</Data>
<State>ActionState</State>
<StreamLocation>^%CSP.Util.ActionS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
