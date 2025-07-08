/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// Base class for DeepSee dialog pages.
Class %DeepSee.UI.Dialog.standardDialog Extends %CSP.Portal.standardDialog [ System = 4 ]
{

Parameter JSINCLUDES = "zenCSLM.js,zenESVG.js,DeepSee.js";

Parameter DOMAIN = "%DeepSee";

/// All DeepSee pages require %DeepSee_Portal USE.
Parameter RESOURCE = "%DeepSee_Portal,%DeepSee_PortalEdit";

Parameter APPLYBUTTON = 1;

XData Style
{
<style type="text/css">
a.radioButtonCaption {
	font-size: 12px;
}
a.radioButtonCaptionDisabled {
	font-size: 12px;
}
.comboboxTable td {
	padding-left: 3px;
}
.labelValue {
	color: #404040;
}

select option {
	background-color: #FFFFFF;
}

select option:nth-of-type(odd) {
	background-color: #F8F8F8;
}

</style>
}

/// Contents of this page:
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" 
	title="#(%page.dialogTitle)#"
	dragAndDrop="true"
	>
<!-->WAL126 dragAndDrop, above<-->
<html id="header" OnDrawContent="%DrawTitle" />
<pane paneName="dialogBody" id="body" />
<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnApply" caption="Apply" controlClass="commandButton" hidden="#(%page.hideApplyButton)#" onclick="zenPage.dialogApply();" />
<spacer width="5" />
<button id="btnCancel" caption="Cancel" controlClass="commandButton" hidden="#(%page.hideCancelButton)#" onclick="zenPage.dialogCancel();" />
<spacer width="5" />
<button id="btnOK" caption=" OK " controlClass="commandButton" onclick="zenPage.dialogFinish();" />
<spacer width="10" />
</hgroup>
</hgroup>
</page>
}

/// Strip beginning and ending whitespaces from a given string.
ClientMethod stripWhitespaces(string As %String) As %String [ Language = javascript ]
{
	return string.replace(/^\s*|\s*$/g,'')
}

ClientMethod getOpener() [ Language = javascript ]
{
	var realSuper = this.superClass;
	var origMethod = this.getOpener;
	while (realSuper && (typeof realSuper.getOpener == 'function') && (realSuper.getOpener === origMethod)) {
		realSuper = realSuper.superClass;
	}
	if (realSuper && realSuper.getOpener) return this.invokeSuper('getOpener',arguments);
	return window.opener;
}

Method %OnDrawHTMLMeta() As %Status
{
	//Ensure that we force Internet Explorer to use its most recent rendering engine.
	If $$$ZENISIE &html<<meta http-equiv="X-UA-Compatible" content="IE=edge" />>
	Quit $$$OK
}

}
