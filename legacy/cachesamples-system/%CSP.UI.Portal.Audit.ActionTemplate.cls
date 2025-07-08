/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.Audit.ActionTemplate Extends %CSP.UI.Portal.Template [ Abstract, System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property Action As %String;

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<html id="idHTMLResult" OnDrawContent="DrawResult" hidden="true"/>
<form id="fld">
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<group labelPosition="left">
<hgroup label="What would you like to do?" cellStyle="padding:4px;">
<radioSet id="DaysOption"
valueList="1,2" value="2"
 layout="vertical" onchange="zenPage.resetMsg();"/>
 <text id="ActionDays" size="3" maxlength="4" valign="bottom" value="10"/>
</hgroup>
<pane paneName="formPane" width="100%"/>
</group>
<html><hr size="1"/></html>
<hgroup cellAlign="right">
<hgroup cellStyle="padding:2px;">
 <button id="btnOK" caption=" OK " controlClass="commandButton" onclick="zenPage.doFinish();"/>
 <button id="btnCancel" caption="Cancel" controlClass="commandButton" onclick="zenPage.doCancel();"/>
 </hgroup>
 </hgroup>
 </group>
 </form>
</pane>
}

ClientMethod doFinish() [ Language = javascript ]
{
	this.resetMsg();
	
	var DaysOption = zen('DaysOption').getValue();
	if (!this.validate(DaysOption)) {
		this.afterValidate();
		return;
	}
	
	var proxy = new zenProxy();
	proxy.Action = this.Action;
	proxy.DaysOption = DaysOption;
	proxy.ActionDays = zenTrim(zen('ActionDays').getValue());
	
	if (this.Action == 'Export') {
		proxy.FileName = zenTrim(zen('FileName').getValue());
		if (this.FileExists(proxy.FileName)) {
			var msg = $$$Text('File already exists. Overwrite the existing file?');
			if (!confirm(msg)) return;
		}
	} else if (this.Action == 'Copy') {
		proxy.Namespace = zen('Namespace').getValue();
		proxy.AuditFlag = zen('AuditFlag').getValue();
	}
	
	var job = this.StartAction(proxy);
	
	if (this.Action == 'Export') {
		this.saveToCookie(proxy.FileName);
	}
	
	var html = zenPage.getComponentById('idHTMLResult');
	html.setHidden(false);
	html.seed = this.Action+'||'+job;
	html.refreshContents();
	zen('fld').setHidden(true);
	zen('Text1').setHidden(true);
}

ClientMethod validate(DaysOption) [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var pass = true;
	var ctl = zen('ActionDays');
	if (DaysOption == 2) {
		if (!this.validateRequired(ctl,pass,"N",true,0,9999)) pass = false;
	} else {
		ctl.setProperty("hintClass","helpText");
		ctl.setProperty("controlClass","");
	}
	if (this.Action == 'Export') {
		if (!this.validateRequired(zen('FileName'),pass,"S")) pass = false;
	} else if (this.Action == 'Copy') {
		if (!this.validateRequired(zen('Namespace'),pass,"S")) pass = false;
	}
	zenSynchronousMode = oldSynchronousMode;
	return pass;
}

ClassMethod StartAction(pProxy As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set return = ""
	Try {
		Set ID1 = ""
		If pProxy.DaysOption = 1 {
			Set ID2 = ""
		} Else {
			Set ID2 = $ZDT(+$H-pProxy.ActionDays,3)_" 00:00:00"
		}
		Set tParms("BeginDateTime") = ID1
		Set tParms("EndDateTime") = ID2
		
		If (pProxy.Action = "Export") {
			Set tParms("FileName") = pProxy.FileName
			Set tParms("AuditFlag") = 0  // no deletion
			Set taskName = "AuditExport"
		} ElseIf (pProxy.Action = "Purge") {
			Set taskName = "AuditPurge"
		} ElseIf (pProxy.Action = "Copy") {
			Set tParms("AuditCopyNamespace") = pProxy.Namespace
			Set tParms("AuditFlag") = pProxy.AuditFlag
			Set taskName = "AuditCopy"
		}
		
		Set tSC = ##class(%CSP.UI.System.BackgroundTask).RunTask(taskName,$namespace,.tParms,,.tJob)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set return = +$G(tJob)
	} Catch Error {
		Set return = ..EvalResult(Error.AsStatus())
	}
	Quit return
}

/// Actually write out result.
/// When the page is first opened, seed is null.
ClassMethod DrawResult(seed As %String) As %Status
{
	If seed = "" Quit $$$OK
	Try {
		&html<<pre class="brownnote">>
		Set action = $PIECE(seed,"||",1)
		Set job = $PIECE(seed,"||",2)
		If (action = "Export") {
			Write !,$$$TextHTML("Export audit log.")
		} ElseIf (action = "Purge") {
			Write !,$$$TextHTML("Purge audit log.")
		} ElseIf (action = "Copy") {
			Write !,$$$TextHTML("Copy audit log.")
		}
		Write !,$$$FormatText($$$Text("Background job, %1, started."),$zconvert(job,"O","HTML"))
		Set tLink = ..Link("/csp/sys/%25CSP.UI.Portal.BackgroundTaskList.zen")
		Set msg = $$$TextHTML("Click here to view the background tasks page.")
		&html<<br><a href="#(tLink)#" target="newWin">#(msg)#</a>>
		&html<</pre>>
	} Catch Error {
	}
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Quit $$$OK
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Security Management")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($classname(),"O","URL")_".zen"))
	Quit $$$OK
}

}
