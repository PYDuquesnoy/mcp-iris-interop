/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syMirror, %syINET)

/// Zen page for System Management Portal - Edit Node Address
Class %CSP.UI.Portal.Mirror.Dialog.NodeAddressEdit Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Mirror.Dialog.NodeAddressEdit.zen";

/// Displayed name of this page.
Parameter PAGENAME = "NodeAddressEdit";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property ErrorMsg As %String;

Property MirrorName As %ZEN.Datatype.string(ZENURL = "MirrorName");

Property NodeName As %ZEN.Datatype.string(ZENURL = "NodeName");

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" 
	title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />

<pane paneName="dialogBody" id="body" />

<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();"/>
<spacer width="5" />
<button id="btnFinish" controlClass="commandButton" caption="Save" onclick="zenPage.dialogFinish();"/>
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
<fieldSet label="Agent">
<hgroup labelPosition="left">
<text id="AgentAddress" label="Address" size="32"/>
<spacer width="5px"/>
<text id="AgentPort" label="Port" size="5"/>
</hgroup>
</fieldSet>
<spacer height="10px"/>
<fieldSet label="Mirror Private" labelPosition="left">
<text id="SSAddress" label="Address" size="32"/>
</fieldSet>
<spacer height="10px"/>
<fieldSet label="Superserver">
<vgroup>
<hgroup labelPosition="left">
<text id="ECPAddress" label="Address" size="32"/>
<spacer width="5px"/>
<text id="SSPort" label="Port" size="5"/>
<link id="linkPort" hidden="true" onclick="zenPage.EditPort();return false;" href="#" enclosingClass="smpLink"/>
</hgroup>
<label id="LocalPort" hidden="true" value="This is a local member, click 'Edit Port' to update system's Super Server Port."/>
</vgroup>
</fieldSet>
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
	zen("AgentAddress").focus();
}

ClientMethod doSave() [ Language = javascript ]
{
	var proxy = new zenProxy();
	
	proxy.MirrorName = zenPage.MirrorName;
	proxy.NodeName = zenPage.NodeName;
	
	proxy.AgentAddress = zen("AgentAddress").getValue();
	proxy.AgentPort = zen("AgentPort").getValue();
	proxy.SSAddress = zen("SSAddress").getValue();
	proxy.SSPort = zen("SSPort").getValue();
	proxy.ECPAddress = zen("ECPAddress").getValue();
	
	var ok = this.validateSave(proxy);
	if (!ok) return false;
	
	var result = this.SaveData(proxy);

	if (result.ok == 1) {
		return true;
	} else {
		this.showMsg(result.ErrorMessage);
		return false;
	}
}

ClientMethod validateSave(proxy) [ Language = javascript ]
{
	this.resetMsg('');
	zen("idRespond").setProperty("controlClass","redText");
	
	if (proxy.AgentAddress.length < 1) {
		this.showMsg($$$Text("Please enter an agent address."));
		zen("AgentAddress").focus();
		return false;
	}
	var result = this.ValidateAddress(proxy,1);
	if (result.ok == 0) {
		this.showMsg(result.ErrorMessage);
		zen("AgentAddress").focus();
		return false;
	} else if (result.ok == 2) {
		if (!confirm(result.Text + $$$Text("Are you sure you want to use this?"))) {
			zen("AgentAddress").focus();
			return false;
		}
	}
	if (proxy.AgentPort.length < 1) {
		this.showMsg($$$Text("Please enter an agent port."));
		zen("AgentPort").focus();
		return false;
	}
	if (proxy.SSAddress.length < 1) {
		this.showMsg($$$Text("Please enter a mirror private address."));
		zen("SSAddress").focus();
		return false;
	}
	result = this.ValidateAddress(proxy,2);
	if (result.ok == 0) {
		this.showMsg(result.ErrorMessage);
		zen("SSAddress").focus();
		return false;
	} else if (result.ok == 2) {
		if (!confirm(result.Text + $$$Text("Are you sure you want to use this?"))) {
			zen("SSAddress").focus();
			return false;
		}
	}
	if (proxy.SSPort.length < 1) {
		this.showMsg($$$Text("Please enter a Super Server port."));
		zen("SSPort").focus();
		return false;
	}
	if (proxy.ECPAddress.length < 1) {
		this.showMsg($$$Text("Please enter a Super Server address."));
		zen("ccccccc").focus();
		return false;
	}
	result = this.ValidateAddress(proxy,3);
	if (result.ok == 0) {
		this.showMsg(result.ErrorMessage);
		zen("ECPAddress").focus();
		return false;
	} else if (result.ok == 2) {
		if (!confirm(result.Text + $$$Text("Are you sure you want to use this?"))) {
			zen("ECPAddress").focus();
			return false;
		}
	}
	
	return true;
}

///  Save general association data to server.<br/>
///  Returns proxy.ok = 1 (save successful) or 0 (error occurred)<br/>
///  proxy.ErrorMessage (save failed and display this error message).
///  If proxy.ok is 1 and no messages returned then we return to SMP home.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 1

	Try {
		Set mm = ##class(Config.MapMirrors).Open(pProxy.MirrorName,pProxy.NodeName,,,.tSC)
		if '$IsObject(mm) {
			Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
		Set mm.AgentAddress = pProxy.AgentAddress
		Set mm.AgentPort = pProxy.AgentPort
		Set mm.MirrorAddress = pProxy.SSAddress
		Set mm.MirrorSSPort = pProxy.SSPort
		Set mm.ECPAddress = pProxy.ECPAddress
		Set tSC = mm.%Save()
		If $$$ISERR(tSC) Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Kill ^SYS("MIRRORSET",":LocalValidationFailure",pProxy.MirrorName)
	} Catch Error {
		Set Message = ..EscapeHTML($System.Status.GetErrorText(Error.AsStatus()))
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = Message
	}
	Quit tProxy
}

ClassMethod ValidateAddress(pProxy As %ZEN.proxyObject, AddrType As %Integer) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 1
	s Addr=$case(AddrType,1:pProxy.AgentAddress,2:pProxy.SSAddress,3:pProxy.ECPAddress,:"")
	s rc=##class(SYS.MirrorConfiguration).IsIPFormatValid(Addr, .IPType, 0)
	if $$$ISOK(rc) {
		if IPType="HOST" {
			set ipToUse=$s($zcvt(Addr,"U")=$zcvt($$$LOCALHOST,"U"):$$$HOST2IP("localhost"),1:$$$HOST2IP(Addr))
			if (ipToUse="") {
				s tProxy.ErrorMessage = $$$Text("Host ")_Addr_$$$Text(" does not resolve to IP address.")
				s tProxy.ok = 0
				Quit tProxy
			}
		} else {
			set ipToUse=Addr
		}
		if $System.INetInfo.CheckAddressExist(ipToUse) {
			Quit tProxy  ;all is good
		}
		s tProxy.ok = 2
		s tProxy.Text = $s(Addr'=ipToUse:$$$Text("Host '")_Addr_$$$Text("' translated to "),1:"")_$$$Text("IP address ")_ipToUse_$$$Text(" does not exist. ")
		Quit tProxy
	} else {
		s tProxy.ok = 0
		s tProxy.ErrorMessage = $$$Text("Address '")_Addr_$$$Text("' is not valid")
		Quit tProxy
	}
}

/// Set Locator bar and determine whether to show change password option.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

#if 0	
	If $SYSTEM.Mirror.GetInfo()[$$$Primary {
		Set tSC = $$$ERROR($$$OperationNotAllowedInPrimary)
		Set %page.ErrorMsg = ..EscapeHTML($System.Status.GetErrorText(tSC))
		Quit $$$OK
	}
#endif
	
	Set mm = ##class(Config.MirrorMember).Open(,,.tSC)
	if '$IsObject(mm) {
		Set %page.ErrorMsg = ..EscapeHTML($System.Status.GetErrorText(tSC))
		Quit $$$OK
	}
	// Disable SSPort if this is local member or it is data channle connected member.
	Set (PortDisable,LocalMember)=(mm.SystemName=%page.NodeName)
	If LocalMember Set ..%GetComponentById("LocalPort").hidden = 0
	If 'PortDisable,$SYSTEM.Mirror.IsPrimary() {
		Set clientcnt=$SYSTEM.Mirror.ClientQuery()
		For id=1:1:clientcnt {
			Set meminfo=$SYSTEM.Mirror.ClientQuery(id)
			If +meminfo,$P(meminfo,",",2)=%page.NodeName,$P(meminfo,",",3)="Active"||($P(meminfo,",",3)="Catchup") {
				Set PortDisable = 1
				Quit
			}
		}
	}
	Set mm = ##class(Config.MapMirrors).Open(%page.MirrorName,%page.NodeName,,,.tSC)
	if '$IsObject(mm) {
		Set %page.ErrorMsg = ..EscapeHTML($System.Status.GetErrorText(tSC))
		Quit $$$OK
	}
	Set ..%GetComponentById("AgentAddress").value = mm.AgentAddress
	Set ..%GetComponentById("AgentPort").value = mm.AgentPort
	Set ..%GetComponentById("SSAddress").value = mm.MirrorAddress
	Set ..%GetComponentById("SSPort").value = mm.MirrorSSPort
	Set ..%GetComponentById("ECPAddress").value = mm.ECPAddress
	Kill mm
	Set ..%GetComponentById("linkPort").caption = $$$TextHTML("Edit Port")
	If LocalMember Set ..%GetComponentById("linkPort").hidden = 0
	If PortDisable {
		Set ..%GetComponentById("SSPort").disabled = 1
		if 'LocalMember {
			Set ..%GetComponentById("LocalPort").hidden = 0
			Set ..%GetComponentById("LocalPort").value = $$$Text("This is a connected member, editing Super Server Port is not allowed.")
		}
	}
	
	If ..IsEMSReadOnly {
		Set ..%GetComponentById("AgentAddress").disabled = 1
		Set ..%GetComponentById("AgentPort").disabled = 1
		Set ..%GetComponentById("SSAddress").disabled = 1
		Set ..%GetComponentById("SSPort").disabled = 1
		Set ..%GetComponentById("ECPAddress").disabled = 1	
	}
	
	Quit 1
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		if (this.doSave()==false) return false;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
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

ClientMethod EditPort() [ Language = javascript ]
{
	var url = zenLink('%CSP.UI.Portal.MemoryStartup.zen')
	var parms = new Object()
	parms.EditPort = 1;
	this.launchPopupWindow(url,'MemoryStartup','resizable,width=1000,height=700',parms);
}

ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (parseInt(zen("SSPort").getValue()) !== parseInt(value)) {
		zen("SSPort").setValue(value);
	}
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Edit Network Address")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set tPageTitle = $$$FormatText($$$Text("Use the form below to change the network address for member %1 in mirror %2"),$zconvert(%page.NodeName,"O","HTML"),$zconvert(%page.MirrorName,"O","HTML"))_"<br/>"
	&html<<div class="Description">#(tPageTitle)#</div>
	<hr size="1"/>>
	Quit $$$OK
}

}
