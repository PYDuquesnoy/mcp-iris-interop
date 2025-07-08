/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Template for Gateway Wizards.
Class %ZEN.Template.ObjectGatewayWizard.Template Extends %ZEN.Template.studioTemplate [ Deprecated, System = 4 ]
{

Parameter TEMPLATETYPE = "*";

/// What type of template.
Parameter TEMPLATEMODE = "addin";

/// Domain used for localization.
Parameter DOMAIN = "%ZEN";

/// %session.CSPSessionCookie passed as CSPCHD for Browse dialog
Property CSPSessionCookie As %String [ InitialExpression = {%session.CSPSessionCookie} ];

Property lblExit As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Exit")} ];

Property lblFinish As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Finish")} ];

Property lblNotExist As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("File does not exist!")} ];

Property lblNoRespond As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Gateway did not respond!")} ];

/// After user clicks the Finish button, the caption of button Finish becomes Exit,and isExit becomes 1.
/// If btnFinish is clicked when isExit = 1 then we exit out of the wizard.
Property isExit As %Boolean [ InitialExpression = 0 ];

XData CSS3Style
{
<style type="text/css">
/* Customized TabGroup */
/* if tab bar is shown, this wraps the body of tabgroup */
.tabGroupBody {
	border-right: 1px solid #c4d8e2;
	border-left: 1px solid #c4d8e2;
	border-bottom: 1px solid #c4d8e2;
	height: 500px;
	background: #eeeeee;
}

/* container of tab bar buttons */
table.tabGroupBar {
	font-size: 1.0em;
}

/* individual tab bar button */
td.tabGroupButtonOn {
	background: #eeeeee;
	border-top: 1px solid #c4d8e2;
	border-bottom: none;
	border-right: 1px solid #c4d8e2;
	border-left: 1px solid #c4d8e2;
	font-weight: bold;
	padding-right: 5px;
	padding-left: 5px;
	cursor: pointer;
	border-top-left-radius:6px;
	border-top-right-radius:6px;
}

td.tabGroupButtonOff {
	background: none;
	border: 1px solid #c4d8e2;
	padding-right: 5px;
	padding-left: 5px;
	cursor: pointer;
	border-top-left-radius:6px;
	border-top-right-radius:6px;
}

td.tabGroupButtonDisabled {
	background: #AAAAAA;
	color: gray;
	border: 1px solid #c4d8e2;
	padding-right: 5px;
	padding-left: 5px;
	border-top-left-radius:6px;
	border-top-right-radius:6px;
}
td.tabGroupButtonOff:hover {
	background: #89aacb;
}

/* extra space on edges of tab bar */
.tabGroupExtra {
	background: white; /* !!! */
	border-bottom: 1px solid #c4d8e2;
}

/* Customized TablePane */
/* style for table pane */
#table {
	height: 20.0em;
	overflow: auto;
}
/* defines style sheet used by this application table pane */

/* table */
table.tpTable {
	background: white;
	border: 1px solid black;
	font-family: arial;
	width: 100%;
	font-size: 0.8em;
	margin-left: 20px; margin-right: 20px;
}

/* column header (th) */
table.tpTable th {
	border-right: 1px solid gray;
	border-bottom: 1px solid gray;
	background: #E1C07D;
	color: black;
	font-weight: bold;
	text-align: left;
	padding: 2px;
}

/* selected column header (th) */
table.tpTable th.tpHdrSelected {
	background: #00A0EE;
}

table.tpTable td {
	border-right: 1px solid gray;
	border-bottom: 1px solid gray;
	padding: 2px;
}

table.tpTable tr.tpSelected td {
	border-top: 1px solid black;
	border-bottom: 2px solid black;
	padding-top: 1px;
	padding-bottom: 1px;
}

/* this is a normal, unselected row */
table.tpTable tr {
	color: black;
	white-space: nowrap;
	font-size: 0.8em;
}

/* this is a selected row */
table.tpTable tr.tpSelected {
	background: #FFFF80;
	color: black;
}

/* style for odd-rows when using zebra styling */
.tpOdd {
}

/* style for even-rows when using zebra styling */
.tpEven {
	background: #eeeeee;
}
.redText {
	font-size: 0.8em;
	color: red;
}

</style>
}

XData Style
{
<style type="text/css">
/* Customized TabGroup */
/* if tab bar is shown, this wraps the body of tabgroup */
.tabGroupBody {
	border-right: 1px solid #c4d8e2;
	border-left: 1px solid #c4d8e2;
	border-bottom: 1px solid #c4d8e2;
	height: 500px;
	background: #eeeeee;
}

/* container of tab bar buttons */
table.tabGroupBar {
	font-size: 1.0em;
}

/* individual tab bar button */
td.tabGroupButtonOn {
	background: #eeeeee;
	border-top: 1px solid #c4d8e2;
	border-bottom: none;
	border-right: 1px solid #c4d8e2;
	border-left: 1px solid #c4d8e2;
	font-weight: bold;
	padding-right: 5px;
	padding-left: 5px;
	cursor: pointer;
	-moz-border-radius-topleft:6px;
	-moz-border-radius-topright:6px;
}

td.tabGroupButtonOff {
	background: none;
	border: 1px solid #c4d8e2;
	padding-right: 5px;
	padding-left: 5px;
	cursor: pointer;
	-moz-border-radius-topleft:6px;
	-moz-border-radius-topright:6px;
}

td.tabGroupButtonDisabled {
	background: #AAAAAA;
	color: gray;
	border: 1px solid #c4d8e2;
	padding-right: 5px;
	padding-left: 5px;
	-moz-border-radius-topleft:6px;
	-moz-border-radius-topright:6px;
}
td.tabGroupButtonOff:hover {
	background: #89aacb;
}

/* extra space on edges of tab bar */
.tabGroupExtra {
	background: white; /* !!! */
	border-bottom: 1px solid #c4d8e2;
}

/* Customized TablePane */
/* style for table pane */
#table {
	height: 20.0em;
	overflow: auto;
}
/// defines style sheet used by this application table pane

/* table */
table.tpTable {
	background: white;
	border: 1px solid black;
	font-family: arial;
	width: 100%;
	font-size: 0.8em;
	margin-left: 20px; margin-right: 20px;
}

/* column header (th) */
table.tpTable th {
	border-right: 1px solid gray;
	border-bottom: 1px solid gray;
	background: #E1C07D;
	color: black;
	font-weight: bold;
	text-align: left;
	padding: 2px;
}

/* selected column header (th) */
table.tpTable th.tpHdrSelected {
	background: #00A0EE;
}

table.tpTable td {
	border-right: 1px solid gray;
	border-bottom: 1px solid gray;
	padding: 2px;
}

table.tpTable tr.tpSelected td {
	border-top: 1px solid black;
	border-bottom: 2px solid black;
	padding-top: 1px;
	padding-bottom: 1px;
}

/* this is a normal, unselected row */
table.tpTable tr {
	color: black;
	white-space: nowrap;
	font-size: 0.8em;
}

/* this is a selected row */
table.tpTable tr.tpSelected {
	background: #FFFF80;
	color: black;
}

/* style for odd-rows when using zebra styling */
.tpOdd {
}

/* style for even-rows when using zebra styling */
.tpEven {
	background: #eeeeee;
}
.redText {
	font-size: 0.8em;
	color: red;
}

</style>
}

/// validate the control value. pass is either "true" or "false" indicating if there is already a field failed pass validation.
ClientMethod validateRequired(ctl, pass, type) As %Boolean [ Language = javascript ]
{
	var ok = true;
	var value = ctl.getValue();
	switch (type) {
		/// contains at least one numeric character
		case "N":
			if (!(value.match(/\d/))) {
				ok = false;
			}
			break;
		case "S":
		/// contains at least one character after striping all blanks
			if (this.CheckAllBlanks(value) == 1) {
				ok = false;
			}
			break;
	}
	if (ok == false) {
		ctl.setProperty("hintClass","redText");
		if (pass) {
			zenPage.getComponentById("firstFailed").setValue(ctl.getProperty("id"));
		}		
	} else {
		ctl.setProperty("hintClass","helpText");
	}
	return ok;
}

ClassMethod CheckAllBlanks(string) As %Boolean [ ZenMethod ]
{
	Quit $ZStrip(string,"<>W")=""
}

}
