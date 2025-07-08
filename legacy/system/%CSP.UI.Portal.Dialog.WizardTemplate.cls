/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// Wizard style template for System Management Portal.<br>
/// Zen-based SMP wizard dialogs with multiple pages extend this class.
Class %CSP.UI.Portal.Dialog.WizardTemplate Extends %CSP.Portal.standardDialog [ Abstract, System = 4 ]
{

/// If $NAMESPACE is set, auto switch namespace
Parameter AUTONS = 1;

/// Title of the template to show in the template window.
Parameter TEMPLATETITLE As STRING;

/// DOCBOOK Topic Id that offers help for this template.
Parameter HELPID As STRING;

/// DocBook topic id used to show help for this template.
Property helpId As %ZEN.Datatype.string [ InitialExpression = {..#HELPID} ];

/// The standard template has three main divs: header,body, and footer.
/// Subclasses typically place their content within the body div (pane).
XData Style
{
<style type="text/css">
/* UserName etc. */
.stdTitleInfo {
	background: #ffffff;
	color: #000000;
	font-size: 12px;
	font-weight: normal;
	white-space: nowrap;
}
/* style for idRespond message */
.note {
	color: #da4848;
	font-size: 12px;
	font-weight: bold;
	padding: 6px;
	border: 1px #cbcbcb solid;
}
.phoneBox {
	font-size:12px;
	padding:20px;
	white-space: nowrap;
}
</style>
}

/// Contents of standard template page;
/// Subclasses can override this if they wish or
/// (more typically) implement the "body" pane with the desired content.
/// Contents of this page:
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" 
	title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />

<pane paneName="dialogBody" id="body" />

<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnBack" controlClass="commandButton" caption="Back" onclick="zenPage.previousPage();" hidden="true"/>
<spacer width="5" />
<button id="btnNext" controlClass="commandButton" caption="Next" onclick="zenPage.nextPage();" hidden="true"/>
<spacer width="15" />
<button id="btnFinish" controlClass="commandButton" caption="Finish" onclick="zenPage.dialogFinish();" />
<spacer width="5" />
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();" />
<spacer width="15" />
<button id="btnHelp" controlClass="commandButton" caption="Help" onclick="zenPage.showHelp();" />
<spacer width="10" />
</hgroup>
</hgroup>
</page>
}

/// Provide HTML for standard template html title box.
Method %DrawTitle(pSeed As %String) As %Status
{
	#; draw html title box
	Set tTitle = ..%OnGetTitle()
	Set tProp = ..%OnGetSubtitle()
	Set tUserName = $$$TextHTML("User","%Utility")
	Set tNamespace = $$$TextHTML("Namespace","%Utility")
	Set tSelNamespace = $G(%request.Data("NAMESPACE",1),$namespace)

	&html<<table border="0" cellpadding="0" cellspacing="0" width="100%">
		<tr>
		<td align="left">
		<div class="stdTitle">#(tTitle)#</div>
		<div class="stdSubTitle">#(tProp)#</div>
		</td>
		<td class="phoneBox">&nbsp;
		<table border="0" cellpadding="0" cellspacing="2">
		<tr><td class="zenLabel">#(tUserName)#</td><td class="stdTitleInfo" >#($zconvert($UserName,"O","HTML"))#</td></tr>
		<tr><td class="zenLabel">#(tNamespace)#</td><td class="stdTitleInfo" >#($zconvert(tSelNamespace,"O","HTML"))#</td></tr>
		</table>
		</td>
		</tr></table>
		<div class="stdTitleBorder"></div>>	
	
	Quit $$$OK
}

/// Return false from this method to disable this template (for example based on the server platform)
ClassMethod IsEnabled() As %Boolean
{
	Quit 1
}

/// Update the state of the template buttons.
/// Subclasses should call this method when they need to 
/// update the state of the footer buttons.
ClientMethod updateState() [ Language = javascript ]
{
	var btnBack = zen('btnBack');
	var btnNext = zen('btnNext');
	var btnFinish = zen('btnFinish');
	var btnHelp = zen('btnHelp');

	var multi = this.hasMultiplePages();

	if (btnBack) {
		btnBack.setProperty('hidden',!multi);
		btnBack.setProperty('disabled',!this.canGoBack());
		btnBack.setProperty('controlClass',	(this.canGoBack() ? 'commandButton' :'commandButtonDisabled'));
	}
	if (btnNext) {
		btnNext.setProperty('hidden',!multi);
		btnNext.setProperty('disabled',!this.canGoNext());
		btnNext.setProperty('controlClass',	(this.canGoNext() ? 'commandButton' :'commandButtonDisabled'));
	}
	if (btnFinish) {
		btnFinish.setProperty('disabled',!this.canFinish());
		btnFinish.setProperty('controlClass', (this.canFinish() ? 'commandButton' :'commandButtonDisabled'));
	}
	if (btnHelp) {
		btnHelp.setProperty('disabled',(''==this.helpId));
		btnHelp.setProperty('controlClass',	(this.helpId != '' ? 'commandButton' :'commandButtonDisabled'));
	}
}

/// This is called when the template is first displayed;
/// This provides a chance to set focus etc.
ClientMethod onstartHandler() [ Language = javascript ]
{
}

/// This is called when the template is finished;
ClientMethod onfinishHandler() [ Language = javascript ]
{
	return true;
}

/// Validation handler for form built-into template.
ClientMethod formValidationHandler() [ Language = javascript ]
{
	return true;
}

/// Return true if this template has more than one "page".
/// This will display Back and Next buttons.
/// This is implemented by subclasses.
ClientMethod hasMultiplePages() [ Language = javascript ]
{
	return false;
}

/// Return true if this template can Finish (i.e., enable
/// the Finish button).<br>
/// This is implemented by subclasses.
ClientMethod canFinish() [ Language = javascript ]
{
	return true;
}

/// Return true if this template can go to the next page (i.e., enable
/// the Next button).<br>
/// This is implemented by subclasses.
ClientMethod canGoNext() [ Language = javascript ]
{
	return false;
}

/// Return true if this template can go to the previous page (i.e., enable
/// the Back button).<br>
/// This is implemented by subclasses.
ClientMethod canGoBack() [ Language = javascript ]
{
	return false;
}

/// Go to the next page of the template (if there is one).<br>
/// This is implemented by subclasses.
ClientMethod nextPage() [ Language = javascript ]
{
}

/// Go to the previous page of the template (if there is one).<br>
/// This is implemented by subclasses.
ClientMethod previousPage() [ Language = javascript ]
{
}

/// Show the help message for this template.
/// This opens a browser and goes to the DocBook application
/// using the value given by helpId.
ClientMethod showHelp() [ Language = javascript ]
{
	this.showDocumentation(this.helpId);
}

/// Open a browser window to show documentation.
ClientMethod showDocumentation(topic) [ Language = javascript ]
{
	var url = '/csp/docbook/DocBook.UI.Page.cls?KEY=' + encodeURIComponent(topic);
	var win = window.open(url,'docbook','status,scrollbars,resizable,location=1,toolbar=1,menubar=1');
	win.focus();
}

/// This client event, if present, is fired when a keydown event occurs on the page.
ClientMethod onkeydownHandler(evt) [ Language = javascript ]
{
	// prevent backpage via keyboard in templates
	return evt.altKey ? false : true;
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	//this.updateState();
	this.onstartHandler();
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

}
