/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.DateTimeEditor Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs WRITE permissions on one of the following resources to view this page:
/// %Ens_Rules, %Ens_Code, %Ens_RoutingRules or %Ens_BusinessRules
Parameter RESOURCE = "%Ens_Rules:WRITE,%Ens_Code:WRITE,%Ens_RoutingRules:WRITE,%Ens_BusinessRules:WRITE";

/// Comma-separated list of additional JS include files for the page.
Parameter JSINCLUDES As STRING = "zenCSLM.js";

Parameter APPLYBUTTON = 0;

/// the expression string to be parsed
Property VALUE As %String(MAXLEN = "", ZENURL = "VALUE");

XData Style
{
<style type="text/css">
body {
	background:white;
}
</style>
}

/// This XML block defines the contents of this page.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" align="center">
<vgroup align="center">
<spacer height="40"/>
<calendar id="calendarControl" showTime="true"/>
</vgroup>
</pane>
}

ClientMethod ondialogStart() [ Language = javascript ]
{
	zen("calendarControl").setValue(this.VALUE)
	zen("calendarControl").focus();
	return;
}

Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Date and Time Selector")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return zen("calendarControl").getValue().replace(/ /,"T");
}

}
