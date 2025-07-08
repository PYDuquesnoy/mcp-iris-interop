/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for  Management Portal dialogs.
Class %CSP.Portal.standardDialog Extends %ZEN.Dialog.standardDialog [ Abstract, System = 4 ]
{

Parameter DOMAIN = "%Utility";

Parameter APPLYBUTTON = 1;

Parameter EMSSERVICE As STRING;

Parameter USESESSIONLANG As BOOLEAN = 1;

/// Allow pages to have iframes by not setting x-frame-options: same origin. 
/// Set default for Management Portal as iframes are not allowed.
Parameter IFRAMEALLOWED As BOOLEAN = 0;

/// 1 if we are on an EMS manager and viewing group data or on a managed instance, 0 otherwise.
/// Property IsEMSReadOnly As %Boolean [ InitialExpression = {##class(%SYS.EMS).IsReadOnly($classname())} ];
Property IsEMSReadOnly As %Boolean [ InitialExpression = 0 ];

/// Set to 1 in %OnAfterCreatePage if a URI parameter is invalid. Used to disable command buttons in onloadHandler().
Property InvalidParam As %Boolean [ InitialExpression = 0 ];

/// Keeps track of the first form field that failed during validation.
Property FirstFailed As %String;

Property ValidationErrorMsg As %String [ InitialExpression = {$$$Text("There was a problem with the form. See the highlighted fields below.")} ];

XData Style
{
<style type="text/css">

body {
	background: #ffffff;
	font-family: Futura,Arial,sans-serif;
}
/* Default style for labels. */
.zenLabel {
	color: #000000;
	font-size: 12px;
	font-weight: 600;
	text-align: left;
}

.zenRequired {
	color: #333695;
	font-size: 12px;
	font-weight: bold;
}

.zenLabelDisabled {
	color: #979797;
	font-size: 12px;
	font-weight: normal;
}

.zenHint {
	color: #717171;
}

#header {
	position: relative;
}

/* assume there is a decsription block with this id */
#desc {
	line-height: 1.2;
	color: #333695;
	padding-top: 1.0em;
	padding-bottom: 1.0em;
}
.stdTitle {
	color:#000000;
	background: #ffffff;
	border-bottom: none;
	font-family: Futura,Arial,sans-serif; 
	font-size: 16px;
	font-weight: 700;
	letter-spacing: 0.75px;
	margin: 20px 20px 10px 20px;
	text-transform: uppercase;
	white-space: nowrap;
}
.stdSubTitle {
	color:#000000;
	font-family: Futura,Arial,sans-serif;
	font-style: italic;
	font-size: 12px;
	font-weight: normal;
	letter-spacing: 0.75px;
	margin: 4px 20px;	
	white-space: nowrap;
}
.stdTitleBorder {
	border: 1px solid #CBCBCB;
	border-radius: 4px;	
}
.formTitle {
	color:#000000;
	font-size:18px;
	font-weight: bold;
	letter-spacing: 0.75px;
}

/* UserName etc. */
.stdTitleInfo {
	color: #000000;
	width: 100%;
	padding: 0px;
	font-family: Futura,Arial,sans-serif; 
	text-align: left;
	white-space: nowrap;
}

.stdTitleInfo td {
	color: #000000;
	padding-left: 5px;
	padding-right: 10px;
	font-size: 12px;
	font-weight: bold;
	text-align: left;
	white-space: nowrap;
}

.stdTitleInfo th {
	color: #333695;
	padding: 0px;
	font-size: 8pt;
	font-weight: normal;
	text-align: right;
	white-space: nowrap;
}
.fieldSet {
	border-radius: 5px;	
}
/* buttons in footer */
#btnApply input,
#btnOK input,
#btnCancel input {
	width: 6.0em;
	cursor: pointer;
}
/* command button styles */
#btnOK input,
#btnApply input,
#btnCancel input,
.commandButton,.commandButtonDisabled {
	background: #FFFFFF;
	color: #333695;
	text-decoration: none;
	padding: 3px;
	padding-left: 10px;
	padding-right: 10px;
	border-radius: 4px;
 	border: 2px solid #333695;
}

.commandButtonRemove {
	background: rgb(141,53,53);
	color: #E0E0E0;
	text-decoration: none;
	padding: 3px;
	padding-left: 10px;
	padding-right: 10px;
	border-radius: 4px;
 	border: 2px solid #CBCBCB;
    cursor: pointer;
}

.commandButtonDisabled {
	border: 2px solid #c5c5c5;
	color: #979797;
	cursor: default;
}
#btnOK input:hover,
#btnApply input:hover,
#btnCancel input:hover,
.commandButton:hover {
	border: 2px solid #00A09A;
	background: #ffffff;
	color: #00A09A;
	transition: color 0.03 ease;
}
.commandButtonRemove:hover {
	border: 4px solid white;
}
/* override Zen's modalGroup CSS */
.modalGroup {
	border: 1px solid #cbcbcb;
	background: #ffffff;
	padding: 5px;
}
.modalGroup.modalGroupDialog {
	padding: 2px;
	background: #ffffff;
}
.stdTitleBorder {
	margin: 0px;
	padding: 0px;
	box-shadow:0 2px 8px 4 rgba(0,0,0,0.12);
	box-sizing: border-box;
}
/* listBox */
.listBox {
	font-size: 12px;
	color: #000000;
	background: white;
}

/* @doc="Item within listBox." */
.listBoxItem {
	white-space: nowrap;
	width: 100%;
	color: #000000;
	cursor: pointer;
	padding: 1px;
}
/* @doc="Mouse hover over item within combobox dropdown." */
.comboboxItem a:hover {
	color: #000000;
	background: #f7f7f7;
	border: 1px solid #cbcbcb;
}
/* @doc="Selected item within listBox." */
.listBoxItemSelected {
	white-space: nowrap;
	width: 100%;
	color: #000000;
	background: #bfe4e3;
	font-weight: bold;
	cursor: pointer;
	padding: 1px;
}

/* @doc="Selected item with focus within listBox." */
.listBoxItemFocus {
	white-space: nowrap;
	width: 100%;
	font-weight: bold;
	color: #000000;
	background: #bfe4e3;
	background-image: none;
	border: 1px solid #cbcbcb;
	cursor: pointer;
	padding: 1px;
}
.listBoxItem:hover, .listBoxItemSelected:hover, .listBoxItemFocus:hover {
	color: #000000;
	background: none;
}
</style>
}

/// Return tmsg. 1 means success. Otherwise error message in HTML.
ClassMethod EvalResult(pSC) As %String
{
	Quit ##class(%CSP.UI.Portal.Template).EvalResult(pSC)
}

/// Clear message from idRespond html (usually placed above the editing portion of the page, but could be anywhere).
ClientMethod resetMsg() [ Language = javascript ]
{
	zen("idRespond").setValue('');
 	zen("idRespond").setHidden(true);
}

/// Display message in idRespond html (usually placed above the editing portion of the page, but could be anywhere).
/// isErr: if 1 is passed in then the color will be changed to red; 
///        If 0 is passed in then the color is changed to #4D3926;
///        If nothing is passed in, then the color is unchanged. This allows developers to set their own style/class and still be able to use showMsg.
ClientMethod showMsg(msg, isErr) [ Language = javascript ]
{
	try {
	 	if (typeof(isErr) != "undefined") {
		 	var noteClass = (isErr == 1) ? "errorNote" : "note";
		 	zen("idRespond").setProperty("enclosingClass",noteClass);
	 	}
		zen("idRespond").setValue(msg);
	 	zen("idRespond").setHidden(false);
	}
  	catch(ex) {
		alert("showMsg ERROR: " + ex);
	}
}

/// Validate the control value. pass is either "true" or "false" indicating if there is already a field that failed validation. 
/// Type is "N" for numeric or "S" for string. If numeric, if checkRange is true, we additionally validate that the number is 
/// between minVal and maxVal, inclusive.
ClientMethod validateRequired(ctl, pass, type, checkRange, minVal, maxVal) As %Boolean [ Language = javascript ]
{
	var ok = true;
	var value = ctl.getValue();
	switch (type) {
		/// contains at least one numeric character
		case "N":
			if (!(value.match(/\d/))) {
				ok = false;
			} else if (checkRange == true) {
				if (isNaN(value)) {
					// fail if not numeric
					ok = false;
				} else if ((value < minVal) || (value > maxVal)) {
					// fail if not in range
					ok = false;
				}
			}
			break;
		case "S":
		/// contains at least one character after striping all blanks
			if (zenTrim(value) == '') {
				ok = false;
			}
			break;
	}
	if (ok == false) {
		ctl.setProperty("hintClass","redText");
		ctl.setProperty("controlClass","zenInvalid");
		if (pass) {
			this.FirstFailed = ctl.getProperty("id");
		}
	} else {
		ctl.setProperty("hintClass","helpText");
		ctl.setProperty("controlClass","");
	}
	return ok;
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (this.IsEMSReadOnly || this.InvalidParam) {
		var btnArray = ['btnOK','btnApply','btnFinish'];
		for (var i=0;i<btnArray.length;i++) {
			var btn = zen(btnArray[i]);
			if (btn) {
				zen(btnArray[i]).setProperty('controlClass','commandButtonDisabled');
				zen(btnArray[i]).setProperty('onclick','return false;');
			}
		}
	}
}

/// Be sure to do ##super() when overriding.
Method %OnAfterCreatePage() As %Status
{

	;If ##class(%SYS.EMS).IsEMSManagerSMP() {
	;	Set %zenPageError = $$$ERROR($$$EMSNoSMP)
	;}
	
	Quit $$$OK
}

/// Provide HTML for html title box.<br>
/// Default implementation displays the standard Zen title bar.
Method %DrawTitle(pSeed As %String) As %Status
{
	#; draw html title box
	Set tTitle = ..%OnGetTitle()
	Set tProp = ..%OnGetSubtitle()
	&html<<table border="0" cellpadding="0" cellspacing="0" width="100%">
		<tr>
		<td align="left" width="90%">
		<div class="stdTitle" >#(tTitle)#</div>
		<div class="stdSubTitle" >#(tProp)#</div></td>
		<td>&nbsp;</td></tr></table>
		<div class="stdTitleBorder"></div>>
	Quit $$$OK
}

}
