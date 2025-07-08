/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Administration - License Key 
Class %CSP.UI.Portal.License.Key Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.License.Utils) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.License.Key.zen";

Parameter HELPADDRESS = "Home,Licensing,License Key";

Parameter EMSSERVICE = "License";

/// Displayed name of this page.
Parameter PAGENAME = "License Key";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

XData Style
{
<style type="text/css">
table.tpTable td {
	border-bottom: 1px solid #F1F0E7;
}
table.tpTable td.caption {
	border-bottom: 1px solid #F1F0E7;
	border-right: 1px solid #F1F0E7;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<label id="pendingMsg" label="The license key in MGR will not take effect until it is activated or the system is restarted." labelClass="rednote" hidden="true" containerStyle="padding-bottom:4px;"/>
<label id="restartMsg" labelClass="rednote" hidden="true" containerStyle="padding-bottom:4px;"/>
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<label id="downloadMsg" labelClass="normal" hidden="true" containerStyle="padding-bottom:4px;"/>
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<html id="idLicense" OnDrawContent="DrawLicense"/>
</pane>
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if ((action == "ok") && (popupName == "LicenseActivate")) {
			if (value != "") {
				zen('restartMsg').setHidden(true);
				zen('pendingMsg').setHidden(true);
				zen('downloadMsg').setHidden(true);
				this.showMsg(value,0);
			} else {
				zen('restartMsg').setHidden(false);
				zen('pendingMsg').setHidden(true);
				this.resetMsg();
			}
			zen('idLicense').refreshContents();
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

ClientMethod doActivate() [ Language = javascript ]
{
	var url = zenLink("%CSP.UI.Portal.Dialog.LicenseActivate.zen");
	zenLaunchPopupWindow(url,'LicenseActivate','status,scrollbars,resizable=yes,height=600');
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..%GetComponentById("Text1").value = $$$Text("Current license key information for this system:")
	
	If $$LicenseDownload^%SYS.LICENSE(.date, .licenseid) {
		Set ..%GetComponentById("downloadMsg").label = $$$FormatText($$$Text("LicenseID %1 activated from License Server keys at %2"),licenseid,$zdatetime(date,3))
		Set ..%GetComponentById("downloadMsg").hidden = 0
	}

	Set ..%GetComponentById("restartMsg").label = ..RestartMsg

	If ##class(%SYSTEM.License).IsPendingActivation() {
		Set tSC = ##class(%SYSTEM.License).IsValidKey($$$KEYFILENAME,.RequiresRestart,.RestartReason)
		If $$$ISERR(tSC) Quit $$$OK
		If (RequiresRestart) {
			Set ..%GetComponentById("restartMsg").hidden = 0
		} Else {
			Set ..%GetComponentById("pendingMsg").hidden = 0
		}
	}
	
	Quit $$$OK
}

///  Return the array of links to show in the locator bar.<br/>
///  pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Licensing","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$ZCVT(NAMESPACE,"O","URL"))))
	
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnPrint",$$$Text("Print"),$$$Text("Print the current license key information"),"zenPage.doPrint('');")
	Set pCommands(2) = $LB("btnActivate",$$$Text("Activate New Key"),$$$Text("Activate a new license key without system restart"),"zenPage.doActivate();")

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("License Key")
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (this.IsEMSReadOnly) {
		this.disableCommandButton('btnActivate');
	}
}

}
