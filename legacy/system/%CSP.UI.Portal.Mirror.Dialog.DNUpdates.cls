/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Actions for Mirrored Databases: Mount, Activate, Catchup, Remove.
Class %CSP.UI.Portal.Mirror.Dialog.DNUpdates Extends (%CSP.Portal.standardDialog, %CSP.UI.Portal.Mirror.Utils) [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Mirror.Dialog.DNUpdates.zen";

/// Displayed name of this page.
Parameter PAGENAME = "Authorize Pending DN Updates";

/// Domain used for localization.
Parameter DOMAIN = "%Utility";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property MirrorName As %ZEN.Datatype.string(ZENURL = "MirrorName");

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
.link {
	font-size: 0.8em;
	color: #3B84BC;
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
<button id="btnAuthorize" controlClass="commandButton" caption="Authorize" onclick="zenPage.doAuthorize();"/>
<button id="btnCancel" controlClass="commandButton" caption="Cancel" title="Return to the Edit Mirror page" onclick="zenPage.dialogCancel();" />
<button id="btnFinish" controlClass="commandButton" caption="Close" title="Return to the Edit Mirror page" onclick="zenPage.dialogFinish();" hidden="true"/>
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<spacer height="10"/>
<group id="page1">
<label id="result" controlClass="redText" value="" containerStyle="padding-left:5px;" controlStyle="white-space:pre-line;"/>
<label id="msg1"/>
<tablePane
id="table"
cellSpacing="2"
queryClass="SYS.Mirror"
queryName="PendingDNUpdates"
dataSource="columns"
maxRows="1000"
multiSelect="false"
showZebra="true"
valueColumn="Name"
>
<parameter value="#(%page.MirrorName)#"/>
<column colName="Name" header="Name"/>
<column colName="MemberType" header="Member Type"/>
<column colName="GUID" header="GUID" hidden="true"/>
<column colName="SSLComputerName" header="DN"/>
</tablePane>
<spacer height="5px"/>
<label id="msg2"/>
</group>
</pane>
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	// this is only invoked from the "Close" button, after actions are done
	// so, just return true to close the dialog.
	return true;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return ""
}

ClientMethod doAuthorize() As %Boolean [ Language = javascript ]
{
	zen('result').setValue('');
	var text = "";
	text = $$$Text("Are you sure you want to update the DN of all pending member(s)?")+"\n";
	if (!confirm(text)) return;
	
	var proxy = new zenProxy();
	proxy.Members = zen('table').selectedRows;
	proxy.MirrorName = this.MirrorName;
	var result = this.AuthorizeDN(proxy);
	if (result.status != 1) {
		zen('result').setValue(result.resultText);
		return;
	}
	window.location.reload(true);
}

ClassMethod AuthorizeDN(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.status = $$$OK
	Set tProxy.resultText = ""
	Set Members = ","_pProxy.Members_","
	Set mirname = pProxy.MirrorName
	
	Try {
		Set rs=##class(%ResultSet).%New("SYS.Mirror:PendingDNUpdates")
		Do rs.Execute(mirname)
		while rs.Next() {
			Set name = rs.Data("Name")
			Set props("SSLComputerName") = rs.Data("SSLComputerName")
			Set rc=##class(Config.MapMirrors).Modify(mirname,name,.props)
			if '$$$ISOK(rc) {
				Set tProxy.status = rc
				Set tProxy.resultText = tProxy.resultText_$c(10)_..EscapeHTML(name)_"..."_..EscapeHTML($System.Status.GetErrorText(rc))
			} else {
				d ##class(SYS.Mirror).RemoveFromApprovalList(name,rs.Data("GUID"),mirname)
			}
		}
	} Catch exp {
		Set tSC = exp.AsStatus()
		Set tProxy.status = tSC
		Set tProxy.resultText = ..EscapeHTML($System.Status.GetErrorText(tSC))
	}
	Quit tProxy
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set ..%GetComponentById("msg1").label = $$$Text("Pending DN Updates List:")
	If '..AnyDNUpdates(..MirrorName) {
		Set ..%GetComponentById("result").value = $$$Text("There is no pending DN updates.")
		Set ..%GetComponentById("btnCancel").hidden = 1
		Set ..%GetComponentById("btnAuthorize").hidden = 1
		Set ..%GetComponentById("btnFinish").hidden = 0
		Quit $$$OK
	}
	Set ..%GetComponentById("msg2").label = $$$Text("The DN of above failover member(s) is changed. You need to authorize the DN updates so local system could connect to the primary member. Click Authorize button to authorize all pending DN updates.") 
	Set ..%GetComponentById("btnFinish").hidden = 1
	Set ..%GetComponentById("btnAuthorize").hidden = 0
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Set title = $$$Text("Authorize Pending DN Updates")
	Quit title
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	zen('btnCancel').focus();
}

}
