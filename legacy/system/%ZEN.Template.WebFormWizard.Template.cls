/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Template for Web Form Wizard.
Class %ZEN.Template.WebFormWizard.Template Extends %ZEN.Template.studioTemplate [ Deprecated, System = 4 ]
{

Parameter fkUnused = 0;

Parameter fkString = 1;

Parameter fkReadOnly = 2;

Parameter fkReference = 3;

Parameter fkRefCombo = 4;

Parameter fkList = 5;

Parameter fkArray = 6;

Parameter fkImage = 7;

Parameter fkMultiLine = 8;

Parameter fkRefSearch = 9;

Parameter fkRefLink = 10;

Parameter fkValCombo = 11;

Parameter fkBoolean = 12;

Property CSPCHD As %ZEN.Datatype.string [ InitialExpression = {%session.CSPSessionCookie} ];

XData Style
{
<style type="text/css">
.zenLabel {
	padding-left: 0px;
	font-size: 0.8em;
	vertical-align: middle;
}
</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" >
<html id="header" OnDrawContent="%DrawTitle" />
<form id="templateForm" groupStyle=""
onvalidate="return zenPage.formValidationHandler();">
<hidden id="templateFinal" name="$FINAL" value="0" />
<pane paneName="templateBody" id="body"/>
</form>
<hgroup id="footer" width="100%" cellAlign="even">
<button id="btnSettings" controlClass="commandButton" caption="Settings" onclick="zenPage.doSettings();" containerStyle="padding-left:14px;"/>
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnBack" controlClass="commandButton" caption="Back" onclick="zenPage.previousPage();" hidden="true"/>
<spacer width="5" />
<button id="btnNext" controlClass="commandButton" caption="Next" onclick="zenPage.nextPage();" hidden="true"/>
<spacer width="15" />
<button id="btnFinish" controlClass="commandButton" caption="Finish" onclick="zenPage.finishTemplate();"/>
<spacer width="5" />
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.cancelTemplate();"/>
<spacer width="15" />
<button id="btnHelp" controlClass="commandButton" caption="Help" onclick="zenPage.showHelp();"/>
<spacer width="10" />
</hgroup>
</hgroup>
</page>
}

/// Open Settings page.
ClientMethod doSettings() [ Language = javascript ]
{
	var url = "%ZEN.Template.WebFormWizard.Settings.cls?CSPSHARE=1&CSPCHD="+this.CSPCHD;
	zenLaunchPopupWindow(url,'WebFormWizardSettings','status,scrollbars,resizable,width=520,height=650');
}

}
