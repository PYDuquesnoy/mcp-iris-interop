/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Process Terminate dialog for Management Portal.
Class %CSP.UI.Portal.Dialog.ProcessTerminate Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.Dialog.ProcessTerminate.zen";

Parameter RESOURCE = "%Admin_Operate:USE";

/// Displayed name of this page.
Parameter PAGENAME = "TerminateProcess";

Parameter AUTONS As BOOLEAN = 0;

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property PID As %String(ZENURL = "PID");

Property DISPLAYID As %String(ZENURL = "DISPLAYID");

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* style for title instructions */
div.Description	{
	font-size: 0.9em; 
	padding: 5px;
}
</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" 
	title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />

<pane paneName="dialogBody" id="body" />

<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();" />
<spacer width="5" />
<button id="btnFinish" controlClass="commandButton" caption="Terminate" onclick="zenPage.doTerminate();"/>
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<label id="result" controlClass="redText" value="" containerStyle="padding-left:10px;"/>
<label id="idRespond" enclosingClass="note" containerStyle="padding-top:10px;padding-left:4px;" hidden="true"/>

<html OnDrawContent="DrawPageTitle" seed=""/>
<checkbox id="chkResjob" value="1" caption="Terminate this process and send &lt;RESJOB&gt; error." 
captionClass="zenLabel" hint="(log the status of the process when it terminates)"/>
</pane>
}

/// Use clicked the Terminate button. Process it. If successful, close this dialog and the Process Details page, and then refresh the Process list page.
ClientMethod doTerminate() [ Language = javascript ]
{
	var chkResjob = zen("chkResjob").getValue();
	var ok = this.StartTerminate(this.PID, this.DISPLAYID, (chkResjob?1:0));
	if (ok != 1) {
		// terminate failed. Display error message and close this dialog. 
		alert(ok);
		this.firePopupAction('close',"",1);
	} else {
		this.firePopupAction('ok',"",1);
	}
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return ""
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Terminate Process")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set tPageTitle = $$$Text("Process ID: ")_..EscapeHTML(%page.DISPLAYID)
	&html<<div class="Description">#(tPageTitle)#</div>>
	&html<<hr size="1"/>>
	Quit 1
}

/// Process Termination. If failed, return error message. Otherwise, return 1.
ClassMethod StartTerminate(PID, DISPLAYID, chkResjob) As %String [ ZenMethod ]
{
	Set tPOBJ = ##class(%CSP.UI.Portal.ProcessDetails).GetPIDOBJ(PID)
	If '$IsObject(tPOBJ) Quit tPOBJ
	If tPOBJ.CanBeTerminated = 0 {
		Quit $$$FormatText($$$Text("Process, %1, can not be terminated"),$zconvert(DISPLAYID,"O","JS"))
	} Else {
		Set tSC = tPOBJ.Terminate(chkResjob)
		If tSC '> 0 {
			Quit $System.Status.GetErrorText(tSC)
		}
		h 2
	}
	Quit 1
}

/// This is called when the template is first displayed;
/// This provides a chance to set focus etc.
ClientMethod onstartHandler() [ Language = javascript ]
{
	zen('btnCancel').focus();
}

}
