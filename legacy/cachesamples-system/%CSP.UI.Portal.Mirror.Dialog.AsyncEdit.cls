/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syMirror

/// Zen page for System Management Portal - Edit Async Configuration
Class %CSP.UI.Portal.Mirror.Dialog.AsyncEdit Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Mirror.Dialog.AsyncEdit.zen";

/// Displayed name of this page.
Parameter PAGENAME = "EditAsync";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property ErrorMsg As %String;

Property MirrorName As %ZEN.Datatype.string(ZENURL = "MirrorName");

Property MemberName As %ZEN.Datatype.string(ZENURL = "MemberName");

Property lblText1 As %String;

Property lblText2 As %String;

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" 
	title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />

<pane paneName="dialogBody" id="body" />

<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnCancel" controlClass="commandButton" caption="Close" onclick="zenPage.dialogCancel();"/>
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<spacer height="10"/>
<html OnDrawContent="DrawPageTitle" seed=""/>
<label id="idRespond" enclosingClass="note" containerStyle="padding-top:10px;padding-left:4px;" hidden="true"/>
<group id="fld" enclosingClass="EditForm" enclosingStyle="margin-left:3px;padding:3px;">
<spacer height="10px"/>
<label id="Text2" value="#(%page.lblText1)#" containerStyle="padding-bottom:4px;"/>
<tablePane id="table" cellSpacing="2"
queryClass="Config.MapMirrors"
queryName="List"
enclosingStyle="width:80%;min-width:800px;"
dataSource="columns"
fixedHeaders="false"
maxRows="100"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
valueColumn="Name"
useSnapshot="false"
>
<column colName="Name" header="Name" id="MemberName" link="#" onclick="zenPage.doEdit('#(%query.Name)#');return false;"/>
<column colName="MemberType" header="Member Type" OnDrawCell="DrawMemberType"/>
<column colName="InstanceDirectory" header="Instance Directory"/>
<column colName="AgentAddress" header="Agent Address"/>
<column colName="AgentPort" header="Agent Port"/>
<column colName="MirrorAddress" header="Mirror Private Address"/>
<column colName="MirrorSSPort" header="Superserver Port"/>
<column colName="ECPAddress" header="Superserver Address"/>
<column colName="EncryptCommunication" hidden="true"/>
<parameter value="#(%page.MirrorName)#"/>
<parameter value="*"/>
<parameter value=""/>
<parameter value="0"/>
<parameter value="0"/>
 </tablePane>
<label id="Text3" value="#(%page.lblText2)#" containerStyle="padding-bottom:4px;"/>
</group>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (this.ErrorMsg !== "") {
		var msg = this.ErrorMsg;
		this.showMsg(msg);
		zen("btnFinish").setDisabled(true);
		zen("btnFinish").setProperty("controlClass","commandButtonDisabled");
		zen("fld").setHidden(true);
		return;
	}
}

ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if ((popupName == "NodeEdit") && (action == "ok")) {
			zen("table").executeQuery();
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

ClientMethod doEdit(nodeName) [ Language = javascript ]
{
	var url = zenLink('%CSP.UI.Portal.Mirror.Dialog.NodeAddressEdit.zen?MirrorName='+encodeURIComponent(zenPage.MirrorName)+'&NodeName='+encodeURIComponent(nodeName));
	zenLaunchPopupWindow(url,'NodeEdit','resizable,width=600,height=500');
}

ClassMethod DrawMemberType(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Write $CASE(%query(pName),$$$FailoverMemberType:"Failover",$$$AsyncMemberType:"Async",:"Unknown")
	Quit $$$OK
}

/// Set Locator bar and determine whether to show change password option.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	If $SYSTEM.Mirror.GetInfo()[$$$Primary {
		Set tSC = $$$ERROR($$$OperationNotAllowedInPrimary)
		Set %page.ErrorMsg = ..EscapeHTML($System.Status.GetErrorText(tSC))
		Quit $$$OK
	}
	#;SML1880+
	Set ..lblText1 = $$$Text("This member is ")_%page.MemberName
	If $SYSTEM.Mirror.IsPrimary() {
		Set ..lblText2 = $$$Text("This member is the primary. Changes will be sent to other members.")
	} elseif $SYSTEM.Mirror.ConnectedToPrimary(%page.MirrorName) {
		Set ..%GetComponentById("MemberName").link = ""
		Set ..%GetComponentById("MemberName").onclick = ""
		If $SYSTEM.Mirror.IsBackup() {
			Set ..lblText2 = $$$Text("This member is the backup. Changes must be made on the primary.")
		} else {
			Set ..lblText2 = $$$Text("This member is connected. Changes must be made on the primary.")
		}
	} elseif +$G(^SYS("MIRRORSET")) {
		Set ..lblText2 = $$$Text("This member is not connected. If the network addresses of the primary have changed, ensure that the addresses for all members are correctly configured on the primary, then update the primary's current addresses here. Once connected, this member will automatically update all addresses to match the primary's configuration.")
	} else {
		Set ..lblText2 = $$$Text("This member is neither primary nor backup. If the network addresses of the other failover member have changed, and it is running as primary, ensure that the addresses for all members are correctly configured on the primary, then update the primary's current addresses here. Otherwise, update the addresses of all members here as required. On connecting, the backup and async members automatically update all addresses to match the primary's configuration.")
	}
	#;SML1880-
	
	
	Set mirror = ##class(Config.Mirrors).Open(%page.MirrorName,,,.tSc)
	If '$IsObject(mirror) {
		Set %page.ErrorMsg = ..EscapeHTML($System.Status.GetErrorText(tSC))
		Quit $$$OK
	}
	Kill mirror
	
	Set mm = ##class(Config.MapMirrors).Open(%page.MirrorName,%page.MemberName,,,.tSC)
	if '$IsObject(mm) {
		Set %page.ErrorMsg = ..EscapeHTML($System.Status.GetErrorText(tSC))
		Quit $$$OK
	}
	Kill mm
	
	Quit 1
}

/// This callback, if defined, is called when the user presses the Cancel button.
/// If this returns false, then the dialog is not cancelled.
ClientMethod ondialogCancel() [ Language = javascript ]
{
	return true;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return true;
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Edit Mirror")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set tPageTitle = $$$FormatText($$$TextHTML("Change the settings for mirror %1"),%page.MirrorName)_"<br/>"
	&html<<div class="Description">#(tPageTitle)#</div>
	<hr size="1"/>>
	Quit $$$OK
}

}
