/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Start External Language Server
Class %CSP.UI.Portal.ExternalLanguageServerStart Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Start External Language Server";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.ExternalLanguageServerStart.zen";

Parameter HELPADDRESS = "Home,Configuration,External Language Servers,Start External Language Server";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.ExternalLanguageServers.zen";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = {$$$AdminExternalLanguageServerEditResourceName};

/// ID for edit. Object Name for this page.
Property PID As %String(ZENURL = "PID");

XData Style
{
<style type="text/css">
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<timer id="timer" ontimeout="zenPage.timeout();" timeout="0"/>
<html id="htmlResult" label="Please wait...result will show below:" OnDrawContent="DrawResult" seed=""></html>
<html><hr/></html>
<button id="btnDone" caption="Done" onclick="zenPage.doCancel();" disabled="true"/>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set ..lblTitle = $$$FormatText($$$Text("Start External Language Server %1:"),..PID)

	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("Start External Language Server")
}

/// Used to draw title for this page. pHalpAddress is need to build the link for Help for this page.
ClassMethod DrawTitle1(pSeed As %String) As %Status
{
	Do %application.DrawTitle(%page.LocatorHeader_"^"_%page.HelpAddress)
	Quit $$$OK
}

ClientMethod timeout() [ Language = javascript ]
{
	var status = this.IsDone();
	if (status) {
		zenPage.getComponentById('btnDone').setDisabled(false);
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (this.PID == "") {
		alert($$$Text("Sorry! External Language Server name is null!"));
		return;	
	}	
	var html = zenPage.getComponentById('htmlResult');
	html.setProperty('seed',this.PID);
	var timer = zenPage.getComponentById('timer');
	timer.setProperty('timeout',1000);
	timer.startTimer();
}

/// Start action and server method will pump out result.
Method DrawResult(seed As %String) As %Status
{
	If seed = "" Quit 1
	Set ^IRIS.Temp.ExternalLanguageServer("Start") = seed
	Set tSC = ##class(%Net.Remote.Service).StartGateway(seed,1)
	If $$$ISERR(tSC) Write "<br>",$$$TextHTML("External Language Server failed to Start:")_"<br>"_$ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
	Set ^IRIS.Temp.ExternalLanguageServer("Start") = ""
	Quit 1
}

/// Return 1 if start is done.
ClassMethod IsDone() As %Boolean [ ZenMethod ]
{
	If $G(^IRIS.Temp.ExternalLanguageServer("Start")) = "" Quit 1
	Quit 0
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Configuration","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("External Language Servers","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?PID="_..EscapeURL(..PID)_$S(NAMESPACE="":"",1:"&$NAMESPACE="_..EscapeURL(NAMESPACE))))
	Quit $$$OK
}

}
