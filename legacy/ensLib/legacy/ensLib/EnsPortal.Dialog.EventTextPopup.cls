/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This very simple dialog allows us to pop up text details from an event log entry.
Class EnsPortal.Dialog.EventTextPopup Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs USE permissions on the %Ens_EventLog resource to view this page.
Parameter RESOURCE = "%Ens_EventLog:USE";

/// JavaScript library
Parameter JSINCLUDES = "zenCSLM.js";

/// Displayed name of this page.
Parameter PAGENAME = "Event Text";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// If true, then this dialog displays a Cancel button.
Parameter CANCELBUTTON As BOOLEAN = 0;

/// If true, then this dialog displays an OK button.
Parameter OKBUTTON As BOOLEAN = 0;

Property eventType As %ZEN.Datatype.string(ZENURL = "TYPE");

Property eventId As %ZEN.Datatype.string(ZENURL = "ID");

XData Style
{
<style type="text/css">
body {
	background: #FFFFCC;
	margin: 0px;
	font-family: verdana;
}

div.title {
	width: 95%;
	font-size: 0.8em;
	font-weight: bold;
	padding-top: 10px;
	padding-left: 10px;
	padding-right: 10px;
}

div.text	{
	font-size: 0.8em; 
	padding-left: 10px;
	padding-right: 10px;
}

div.text:first-letter {
	font-size: 1.0em;
}

</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<spacer height="10" />
<html id="helpText">
</html>
</pane>
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return "";
}

/// Get the (localized) title string for the dialog.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Event Text")
}

/// Get the (localized) subtitle string for the dialog.
Method %OnGetSubtitle() As %String
{
	If (%page.eventType [ "Alert") {
		Set title = $$$Text("Alert")
	} 
	ElseIf (%page.eventType [ "Assert") {
		Set title = $$$Text("Assert")
	} 
	ElseIf (%page.eventType [ "Error") {
		Set title = $$$Text("Error")
	} 
	ElseIf (%page.eventType [ "Info") {
		Set title = $$$Text("Info")
	} 
	ElseIf (%page.eventType [ "Trace") {
		Set title = $$$Text("Trace")
	}
	ElseIf (%page.eventType [ "Warning") {
		Set title = $$$Text("Warning")
	} 
	Else {
		Set title = $$$Text("Unknown")
	}
	
	Quit title_" "_$zconvert(..eventId,"O","HTML")
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	var help = zen("helpText");
	var text = '';
	var opener = this.getOpener();
	if (opener && opener.zenPage && opener.zenPage._eventText) text = zenEscapeHTML(opener.zenPage._eventText);
	text = text.toString().replace(/\n/g,'<br/>');
	help.content = '<div class="text">' + text + '</div>';
	help.refreshContents();
}

}
