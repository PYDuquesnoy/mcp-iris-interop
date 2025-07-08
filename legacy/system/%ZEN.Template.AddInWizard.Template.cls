/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Template for Misc Add-In Wizards (originally these wizards were written under /csp/studio/templates in CSP).
Class %ZEN.Template.AddInWizard.Template Extends %ZEN.Template.ObjectGatewayWizard.Template [ Deprecated, System = 4 ]
{

/// Domain used for localization.
Parameter DOMAIN = "%TemplateMessages";

/// After user clicks the Finish button, the caption of button Finish becomes Exit,and isExit becomes 1.
/// If btnFinish is clicked when isExit = 1 then we exit out of the wizard.
Property isExit As %Boolean [ InitialExpression = 0 ];

XData Style
{
<style type="text/css">
body {
	overflow: hidden;
}
#btnR1 input,#btnR2 input,#btnL1 input,#btnL2 input,#btnU1 input,#btnD1 input {
	width: 1.7em;
}
div.Description	{
	font-size: 0.9em; 
	padding: 5px;
}

/* style for title instruction of Next button */
span.guibutton { 
	color: green;
	font-weight: bold;
}
/* custom style for this set of wizards */
.helpText {
	color:gray;
	font-size:0.8em;	
}
/* style for idRespond message */
.note {
	color: #da4848;
	font-size: 1.0em;
	font-weight: bold;
	padding: 6px;
	border: 1px gray solid;
}
/* style for text labels or captions */
.normal {
	font-size: 0.8em;
	text-decoration: none;
	vertical-align: middle;
}
.caption {
	color: black;
	font-size: 1.0em;
	font-weight: normal;
}
a.radioSetCaption {
	font-size: 0.8em;
	vertical-align: middle;
}
a.radioButtonCaption {
	font-size: 0.8em;
}

/* Progress message style */
.progress { 
	color: green; 
	font-weight: bold;
}

</style>
}

/// Display message on top of page.
ClientMethod showMsg(msg) [ Language = javascript ]
{
	zen("idRespond").setValue(msg);
 	zen("idRespond").setHidden(false);
}

/// Clear message on top of page.
ClientMethod resetMsg() [ Language = javascript ]
{
	zen("idRespond").setValue('');
 	zen("idRespond").setHidden(true);
}

}
