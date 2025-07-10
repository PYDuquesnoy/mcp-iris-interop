/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Page for configuring the link to the Message Bank for the current namespace.
/// The data required to build the link are stored in ^Ens.MsgBank("Link"). If no data is present in that node,
/// the code will attempt to retrieve the data from the nodes used by the Message Bank client code, and copy those
/// values into the "Link" data location.
Class EnsPortal.FindMsgBank Extends EnsPortal.Template.standardPage [ System = 4 ]
{

Parameter PAGENAME = "Configure Message Bank Link";

/// User needs READ permissions on the %Ens_MsgBankConfig resource to view this page.
Parameter RESOURCE = "%Ens_MsgBankConfig:READ";

/// User needs WRITE permissions on the %Ens_MsgBankConfig resource to make changes on this page.
Parameter EDITRESOURCE = "%Ens_MsgBankConfig:WRITE";

/// Full URL of the Message Bank Status Monitor. If this is the empty string, the bank is not correctly configured.
Property bankLocation As %ZEN.Datatype.uri [ InitialExpression = {..GetBankLink()} ];

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<spacer height="10" />
<titleBox id="id_Title" title="Connect to the Enterprise Message Bank &amp; Enterprise Monitor portal" 
		subtitle="Supply the values needed to connect to the Message Bank web server" />
<spacer height="10" />
<vgroup id="idshowform" groupStyle="background:#F7ECD7;">
<form id="theForm" width="100%" layout="vertical" cellStyle="padding: 2px; padding-left: 10px; padding-right: 5px;" >
<text id="serverIP" name="serverIP" required="true" label="Web Server IP Address" size="40" title="IP address or host name of your Message Bank web server" />
<text id="serverPort" name="serverPort" required="true" label="Web Server Port Number" size="40" title="The port number used by your Message Bank web server" onvalidate="return zenPage.validatePort();" />
<text id="instancePrefix" name="instancePrefix" label="Instance Prefix" size="40" title="The instance prefix to use for a web server that services multiple instances"/>
<text id="bankNamespace" name="bankNamespace" required="true" label="Message Bank Production Namespace" size="40" title="The namespace your Message Bank production is running in"/>
<checkbox id="useSSL" name="useSSL" label="Use SSL To Connect To The Message Bank Web Server" title="Should SSL be used when connecting to the Message Bank?" />
<spacer height="5"/>
<hgroup>
<button caption="Go" id="btnGo" disabled="true" onclick="zenPage.goToBank();" controlClass="commandButtonDisabled" title="Go to the Message Bank portal" />
<spacer width="30" />
<button caption="Save" id="btnSave" onclick="zenPage.saveValues();" controlClass="commandButton" title="Save connection settings" />
</hgroup>
</form>
</vgroup>
</pane>
}

/// Validate the contents of the form.
ClientMethod validate() [ Language = javascript ]
{
	var form = zen('theForm');
	if (form) {
		var valid = form.validate();
		if (!valid) return false;
	}
	return true;
}

/// Ensure that the port is a positive integer.
ClientMethod validatePort() [ Language = javascript ]
{
	var control = zen('serverPort');
	if (control) {
		var value = control.getValue();
		if ((value.toString() != parseInt(value,10).toString()) || (value.toString() == 'NaN') || (parseInt(value,10) <= 0)) {
			control.invalidMessage = $$$Text('must be a positive integer.');
			return false;
		}
	}
	return true;
}

ClientMethod updateGoButton() [ Language = javascript ]
{
	var goButton = zen('btnGo');
	if (goButton) {
		var disableButton = (this.bankLocation == '');
		goButton.setDisabled(disableButton);
		var buttonControl = goButton.findElement('control');
		if (buttonControl) buttonControl.className = 'commandButton' + (disableButton ? 'Disabled' : '');
	}
}

/// Redirect the client to the Message Bank.
ClientMethod goToBank() [ Language = javascript ]
{
	if (this.bankLocation == '') {
		alert($$$Text("Unable to determine Message Bank Location"));
		return;
	}
	window.document.location = this.bankLocation;
}

/// Actually save the values to the server.
ClientMethod saveValues() [ Language = javascript ]
{
	if (!this.checkEdit()) return false;
	var valid = this.validate();
	if (!valid) return false;

	var proxy = zen('theForm').getValuesAsObject();

	var ok = false;
	var errMsg = this.SaveLinkData(proxy);
	if (errMsg == '') {
		ok = true;
		alert($$$Text('Settings saved successfully'));
		this.updateGoButton();
	}
	else {
		alert($$$Text('Error saving settings') + ':\n' + errMsg);
	}
	return ok;
}

/// Save the values and update the value of <property>bankLocation</property>.
Method SaveLinkData(pData As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	If '$IsObject($get(pData)) Quit $$$Text("Invalid arguments supplied")
	Set tStatus = ..SetBankAddress(pData.serverIP,pData.serverPort,pData.instancePrefix,pData.bankNamespace,''pData.useSSL)
	Set ..bankLocation = ..GetBankLink()
	If $$$ISERR(tStatus) Quit $system.Status.GetErrorText(tStatus)
	Quit ""
}

/// Helper method to get the constituent parts of the link to the Message Bank.
ClassMethod getBankAddr(Output pWebServer As %String, Output pWebPort As %String, Output pInstancePrefix As %String, Output pBankNS As %String, Output pUseSSL As %Boolean) [ Internal, ServerOnly = 1 ]
{
	#; Check in "Link" node for UI-specific values
	If $data(^Ens.MsgBank("Link"),tLinkData)#10 {
		Set pWebServer = $lg(tLinkData,1)
		Set pWebPort = $lg(tLinkData,2)
		Set pInstancePrefix = $lg(tLinkData,3)
		Set pBankNS = $lg(tLinkData,4)
		Set pUseSSL = $lg(tLinkData,5)
		Quit
	}
	#; If the UI doesn't have any saved values, look in the runtime globals, and then use these for the UI
	Set pWebServer=$G(^Ens.MsgBank("WebSvr"))
	Set pWebPort=$P(pWebServer,"|",2)
	Set pInstancePrefix=$P(pWebServer,"|",3)
	Set pWebServer=$P(pWebServer,"|")
	Set tBank=$G(^Ens.MsgBank)
	Set pBankNS=$P(tBank,"|",3)
	Set pUseSSL=+$G(^Ens.MsgBank("UseSSL"),$Case(pWebPort, 22:1, 443: 1, :0))
	If pWebServer = "" {
		Set tIPAddr=$G(^Ens.MsgBank("IPAddr"))
		Set tIPAddr=$P(tIPAddr,"|")
		If tIPAddr '= "" {
			Set pWebServer = tIPAddr
		}
		Else {
			Set pWebServer = $P(tBank,"|")
		}
	}
	If (pWebServer '= "") && (pWebPort '= "") && (pBankNS '= "") {
		Do ..SetBankAddress(pWebServer,pWebPort,pInstancePrefix,pBankNS,pUseSSL)
	}
}

/// Physically set the values into the ^Ens.MsgBank("Link") node.
/// This method is the API for changing this.
ClassMethod SetBankAddress(pWebServer As %String, pWebPort As %String, pInstancePrefix As %String, pBankNS As %String, pUseSSL As %Boolean) As %Status
{
	Set ^Ens.MsgBank("Link") = $lb(pWebServer,pWebPort,pInstancePrefix,pBankNS,''pUseSSL)
	Quit $$$OK
}

/// Build the constituent parts of the link into a single URL.
ClassMethod MakeLink(pWebServer As %String, pPort As %String = 80, pInstancePrefix As %String = "", pBankNS As %String, pUseSSL As %Boolean = 0) As %String [ CodeMode = expression ]
{
"http"_$S(pUseSSL:"s",1:"")_"://"_$S(pWebServer[":":"["_pWebServer_"]",1:pWebServer)_":"_pPort_$S(pInstancePrefix '= "": "/"_pInstancePrefix, 1: "")_"/csp/"_$ZCVT(pBankNS,"L")_"/Ens.Enterprise.Portal.MonitorStatus.zen"
}

/// Return the current link
ClassMethod GetBankLink() As %String
{
	Do ..getBankAddr(.tWebServer,.tWebPort,.tInstancePrefix, .tBankNS,.tUseSSL)
	If (tWebServer '= "") && (tWebPort '= "") && (tBankNS '= "") {
		Quit ..MakeLink(tWebServer,tWebPort,tInstancePrefix,tBankNS,tUseSSL)
	}
	Quit ""
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Configure Message Bank Link","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Quit $$$OK
}

/// Populate the controls as needed.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Do ..getBankAddr(.tWebServer,.tWebPort,.tInstancePrefix,.tBankNS,.tUseSSL)
	Do ..%SetValueById("serverIP",$get(tWebServer))
	Do ..%SetValueById("serverPort",$get(tWebPort))
	Do ..%SetValueById("instancePrefix",$get(tInstancePrefix))
	Do ..%SetValueById("bankNamespace",$get(tBankNS))
	Do ..%SetValueById("useSSL",$get(tUseSSL,0))
	
	If '..canEdit {
		Set tSaveGo = ..%GetComponentById("btnGo")
		Set tSaveGo.disabled = 1
		Set tSave = ..%GetComponentById("btnSave")
		Set tSave.disabled = 1
	}
	Quit $$$OK
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod, "SaveLinkData": ..#EDITRESOURCE, :"")
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',[]);
	this.updateGoButton();
}

}
