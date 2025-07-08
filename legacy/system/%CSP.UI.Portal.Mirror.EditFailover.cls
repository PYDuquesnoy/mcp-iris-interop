/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Edit Failover
Class %CSP.UI.Portal.Mirror.EditFailover Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.Mirror.Utils) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

/// Displayed name of this page.
Parameter PAGENAME = "Edit Mirror";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Mirror.EditFailover.zen";

Parameter HELPADDRESS = "Home,Configuration,Edit Mirror";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property IsPrimary As %Boolean [ InitialExpression = {$SYSTEM.Mirror.GetInfo()[$$$Primary} ];

Property MirrorName As %ZEN.Datatype.string;

Property OldVirtualAddress As %ZEN.Datatype.string;

Property OldCIDRMask As %ZEN.Datatype.string;

Property OldVirtualAddressInterface As %ZEN.Datatype.string;

Property lblText1 As %String;

Property lblText2 As %String;

Property lblDNUpdates As %String;

Property lblNewMembers As %String;

/// Number of DNUpdates members currently selected
Property NumDNUpdates As %Integer [ InitialExpression = 0 ];

/// Number of NewMembers members currently selected
Property NumNewMembers As %Integer [ InitialExpression = 0 ];

/// Check if user has manage privilege
Property CanManage As %ZEN.Datatype.boolean [ InitialExpression = {$System.Security.Check("%Admin_Manage","USE")} ];

Property JoinMirror As %Boolean [ InitialExpression = 1 ];

Property CurrentUseSSL As %Integer;

XData Style
{
<style type="text/css">
tr.infoRow td {
	padding:0 6px 3px 0;
}
/* override the image because this form is too tall */
.EditForm {
	background-image: url('');
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<jsonProvider id="jsonValidationInfo" OnGetTargetObject="GetValidationInfo">
 </jsonProvider>
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<label id="errmsg" hidden="true" enclosingClass="ErrorBox"/>
<form id="fld" hidden="true">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<hgroup>
<fieldSet id="mirrorInfo" labelPosition="left" label="Mirror Information" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;">
<label id="MirrorName" label="Mirror Name" controlClass="normal" value="#(%page.MirrorName)#"/>
<hgroup label="Use SSL/TLS">
<vgroup>
<hgroup>
<checkbox id="UseSSL" onchange="zenPage.toggleSSL(zenThis.getValue());zenPage.doModified();" title="Mirroring requires SSL when journal file encryption is enabled."/>
<link id="linkSSL" onclick="zenPage.openSSL();return false;" href="#" enclosingClass="smpLink"/>
</hgroup>
<button id="verifySSL" caption="Verify SSL" onclick="zenPage.verifySSL(); return false;" />
</vgroup>
</hgroup>
<label id="idWarnSSL" controlClass="rednote" hidden="true"/>
<checkbox id="UseArbiter" label="Use Arbiter" onchange="zenPage.toggle('idArbiter');zenPage.doModified();"/>
<vgroup id="idArbiter" hidden="true">
<hgroup labelPosition="left" cellVAlign="top">
<text id="ArbiterAddress" label="Address" size="12" hint="Required." onchange="zenPage.changeArbiter(zenThis.getValue())"/>
<spacer width="5px"/>
<text id="ArbiterPort" label="Port" size="6" hint="Required." onchange="zenPage.doModified();"/>
</hgroup>
</vgroup>
<checkbox id="UseVIP" label="Use Virtual IP" hint="" onchange="zenPage.toggle('idNetwork');zenPage.doModified();"/>
<vgroup id="idNetwork" hidden="true">
<hgroup labelPosition="left" cellVAlign="top">
<text id="VirtualAddress" label="IP Address" size="12" hint="Required." onchange="zenPage.doModified();"/>
<spacer width="5px"/>
<text id="CIDRMask" label="Mask (CIDR format)" size="4" hint="Required." onchange="zenPage.doModified();"/>
</hgroup>
<html id="networkInterfaceHTML" label="Network Interface" OnDrawContent="DrawNetworkInterface" seed="#(%page.OldVirtualAddressInterface)#" hint="Required."/>
<spacer height="3px"/>
<vgroup id="idVAI" hidden="true">
<text id="VirtualAddressInterface" size="55" onchange="zenPage.doModified();"/>
<spacer height="3px"/>
<label label="(add index number if needed)" labelClass="helpText"/>
</vgroup>
</vgroup>
<hgroup labelPosition="left" cellVAlign="top">
<text id="QOSTimeout" label="Quality of Service Timeout (msec)" size="10"  onchange="zenPage.doModified();"/>
</hgroup>
<hgroup labelPosition="left" label="Compression Mode For Failover Members">
<combobox id="FOCmpMode"  dropdownHeight="60px" onchange="zenPage.CompressMode(zenThis.getValue(),false);">
<option value="0" text="System Selected" />
<option value="1" text="Uncompressed" />
<option value="2" text="Compressed" />
</combobox>
<combobox id="FOCmpType" label="Compression Type" dropdownHeight="60px" onchange="zenPage.CompressType(zenThis.getValue(),false);" hidden="true">
<option value="0" text="ZLIB" />
<option value="1" text="ZSTD" />
<option value="2" text="LZ4" />
</combobox>
</hgroup>
<hgroup labelPosition="left" label="Compression Mode For Async Members">
<combobox id="ASYNCmpMode" dropdownHeight="60px" onchange="zenPage.CompressMode(zenThis.getValue(),true);">
<option value="0" text="System Selected" />
<option value="1" text="Uncompressed" />
<option value="2" text="Compressed" />
</combobox>
<combobox id="ASYNCmpType" label="Compression Type" dropdownHeight="60px" onchange="zenPage.CompressType(zenThis.getValue(),true);" hidden="true">
<option value="0" text="ZLIB" />
<option value="1" text="ZSTD" />
<option value="2" text="LZ4" />
</combobox>
</hgroup>
<combobox id="MultiDejournal" label="Allow Parallel Dejournaling" dropdownHeight="60px" onchange="zenPage.MultiDejournal(zenThis.getValue());">
<option value="0" text="Failover Members and DR" />
<option value="1" text="Failover Members Only" />
<option value="2" text="All Members" />
</combobox>
</fieldSet>
</hgroup>
<hgroup>
<fieldSet labelPosition="left" label="Mirror Member Information" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;">
<label id="Text2" value="#(%page.lblText1)#" containerStyle="padding-bottom:4px;"/>
<tablePane id="MemberTable" cellSpacing="2"
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
<column colName="Name" id="MemberName" header="Name" link="#" onclick="zenPage.doEdit('#(%query.Name)#');return false;"/>
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
<html>
<div id="failureMessage"></div>
</html>
</fieldSet>
</hgroup>
<hgroup>
<fieldSet id="DNUpdatesField" labelPosition="left" label="Pending DN Updates" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;">
<label id="TextDNUpdates" value="#(%page.lblDNUpdates)#" containerStyle="padding-bottom:4px;"/>
<tablePane id="DNUpdatesTable" cellSpacing="2"
queryClass="SYS.Mirror"
queryName="PendingDNUpdates"
enclosingStyle="width:80%;min-width:800px;"
dataSource="columns"
fixedHeaders="false"
maxRows="100"
multiSelect="true"
showZebra="true"
valueColumn="Name"
onmultiselect="zenPage.rowSelectDNUpdates(zenThis.selectedRows);"
>
<parameter value="#(%page.MirrorName)#"/>
<column colName="Name" header="Name"/>
<column colName="MemberType" header="Member Type"/>
<column colName="GUID" header="GUID" hidden="true"/>
<column colName="SSLComputerName" header="DN"/>
</tablePane>
<hgroup id="buttonHolderDNUpdatess" cellAlign="right">
<button id="btnAuthorizeDNUpdates" controlClass="commandButtonDisabled" caption="Authorize" onclick="zenPage.doAuthorizeDNUpdates();" disabled="true"/>
<button id="btnRejectDNUpdates" controlClass="commandButtonDisabled" caption="Reject" onclick="zenPage.doRejectDNUpdates();" disabled="true" hidden="true"/>
</hgroup>
</fieldSet>
</hgroup>
<hgroup>
<fieldSet id="NewMembersField" labelPosition="left" label="Pending New Members" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;">
<label id="TextNewMembers" value="#(%page.lblNewMembers)#" containerStyle="padding-bottom:4px;"/>
<tablePane id="NewMembersTable" cellSpacing="2"
queryClass="SYS.Mirror"
queryName="PendingNewMembers"
enclosingStyle="width:80%;min-width:800px;"
dataSource="columns"
fixedHeaders="false"
maxRows="100"
multiSelect="true"
showZebra="true"
valueColumn="Name"
onmultiselect="zenPage.rowSelectNewMembers(zenThis.selectedRows);"
>
<parameter value="#(%page.MirrorName)#"/>
<column colName="Name" header="Name"/>
<column colName="MemberType" header="Member Type" OnDrawCell="DrawMemberType"/>
<column colName="GUID" header="GUID" hidden="true"/>
<column colName="SSLComputerName" header="DN"/>
</tablePane>
<hgroup id="buttonHolderNewMembers" cellAlign="right">
<button id="btnAuthorizeNewMembers" controlClass="commandButtonDisabled" caption="Authorize" onclick="zenPage.doAuthorizeNewMembers();" disabled="true"/>
<button id="btnRejectNewMembers" controlClass="commandButtonDisabled" caption="Reject" onclick="zenPage.doRejectNewMembers();" disabled="true"/>
</hgroup>
</fieldSet>
</hgroup>
</group>
</form>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	// get validation info and save a local copy for later use
	var json = zen('jsonValidationInfo').getContentObject();
	this._validationInfo = json;
	var msg = '';
	if (json.error) {
		msg = json.error;
		// foundemental error occurred getting validation data, page cannot continue, so display error then go back home.
		alert(json.error);
		window.location.href = this.homePage;
		return;
	}
	if (json.failedCount > 0) {
		// validation failed. Now disable fields when needed.
		zen("mirrorInfo").setHidden(true);
		json.CanManage = this.CanManage;
		var proxy = this.getFailureMessages(json);
		if (proxy.msg) {
			zen('Text3').setValue('');
			var msg = proxy.msg;
			if (proxy.list) {
				msg += proxy.list;
			}	
			var failureMessage = document.getElementById("failureMessage");
			failureMessage.innerHTML = msg;
		}
	}
	else {		
		zenPage.toggleSSL(zen("UseSSL").getValue());
		if (this.DisableSave) {
			this.disableCommandButton("btnSave");
			this.disableCommandButton("btnRemoveOthers");
		}
		if (this.DisableRemove) {
			this.disableCommandButton("btnRemove");
		}
		if (this.IsEMSReadOnly) {
			this.disableCommandButton("btnSave");
			this.disableCommandButton("btnRemove");
			this.disableCommandButton("btnRemoveOthers");
		}
		if (this.JoinMirror==false) {
			this.showMsg($$$Text("The JoinMirror flag has been cleared. Restart InterSystems IRIS to continue removing this mirror member."),false);
		}
	}
	/// show content now after all loading is done so user won't see flashing of content
	zen('fld').setHidden(false);
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action == "ok") {
			if (popupName == "SSL") {
				this.SSLDefined = 1;
				zen("linkSSL").setProperty("caption", $$$Text("Edit SSL/TLS"));
			}
			if (popupName == "Remove") {
				if (value == "cleared") {
					this.showMsg($$$Text("The JoinMirror flag has been cleared. Restart InterSystems IRIS to continue removing this mirror member."),false);
				} else if (value == "restart") {
					this.showMsg($$$Text("Restart InterSystems IRIS to finish removing this mirror member."),false);
				} else {
					this.doCancel();
				}
			}
			if (popupName == "RemoveOther") {
				window.location.reload(true);
			}
			if (popupName == "NodeEdit") {
				zen("MemberTable").executeQuery();
			}
			if (popupName == "RemoveLocalConfig") {
				window.location.href = this.homePage;
			}
			if (popupName == "JoinNewMember" || (popupName == 'NodeAddressEdit')) {
				window.location.reload(true);
			}
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

ClientMethod doRemove() [ Language = javascript ]
{
	var url;
	if (this.IsPrimary == 1) {
		url = zenLink('%CSP.UI.Portal.Mirror.Dialog.FailoverRemoveConfig.zen');
	} else {
		url = zenLink('%CSP.UI.Portal.Mirror.Dialog.AsyncRemoveConfig.zen');
	}
	zenLaunchPopupWindow(url,'Remove','resizable,width=1000,height=700');
}

ClientMethod doRemoveOther() [ Language = javascript ]
{
	var url = zenLink('%CSP.UI.Portal.Mirror.Dialog.FailoverRemoveOthers.zen?PID='+encodeURIComponent(this.MirrorName));
	zenLaunchPopupWindow(url,'RemoveOther','resizable,width=800,height=600');
}

ClientMethod verifySSL() [ Language = javascript ]
{
	var proxy = zenPage.SSLverification(zenPage.MirrorName);
	if (proxy.ok == 1) {
		alert(proxy.message);
	} else {
		alert(proxy.error);
	}
}

ClientMethod validate(proxy) [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var pass = true;
	var errorShown = false;
	var nonZenFail = "";
	try {
		if (proxy.UseArbiter) {
			if (!this.validateRequired(zen('ArbiterAddress'),pass,"S")) pass = false;
			if (!this.validateRequired(zen('ArbiterPort'),pass,"N")) pass = false;
		}
		if (proxy.UseVIP) {
			if (!this.validateRequired(zen('VirtualAddress'),pass,"S")) pass = false;
			if (!this.validateRequired(zen('CIDRMask'),pass,"N")) pass = false;
			if (zenTrim(proxy.VirtualAddressInterface) == '') {
				if (pass) nonZenFail = "VIPNetworkInterface";
				zen('networkInterfaceHTML').setProperty("hintClass","redText");
				document.getElementById("VIPNetworkInterface").className = "zenInvalid";
				pass = false;
			} else {
				zen('networkInterfaceHTML').setProperty("hintClass","helpText");
				document.getElementById("VIPNetworkInterface").className = "";
			}
		}
		if (pass) {
			// if user selects UseSSL and SSL is not defined, then do not go on.
			if (proxy.UseSSL && !this.SSLDefined) {
				this.showMsg($$$Text("Please click the 'Set up SSL/TLS' link to set up SSL/TLS for this system."),1);
				errorShown = true;
				pass = false;
			}
		}
		if (!pass && !errorShown) {
			if (nonZenFail != "") {
				// a non-zen field failed first
				this.showMsg(this.ValidationErrorMsg,1);
				document.getElementById(nonZenFail).focus();
			} else {
				this.afterValidate();
			}
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
	zenSynchronousMode = oldSynchronousMode;

	return pass;
}

ClientMethod doSave() [ Language = javascript ]
{
	this.resetMsg();
	var proxy = new zenProxy();
	
	proxy.MirrorName = zenPage.MirrorName;
	proxy.UseSSL = zen("UseSSL").getValue();
	proxy.UseArbiter = zen("UseArbiter").getValue();
	if (proxy.UseArbiter) {
		proxy.ArbiterAddress = zenTrim(zen("ArbiterAddress").getValue());
		proxy.ArbiterPort = zenTrim(zen("ArbiterPort").getValue());
		proxy.ArbiterNode = proxy.ArbiterAddress+'|'+proxy.ArbiterPort;
	} else {
		proxy.ArbiterNode = "";
	}
	proxy.UseVIP = zen("UseVIP").getValue();
	if (proxy.UseVIP) {
		proxy.VirtualAddress = zen("VirtualAddress").getValue();
		proxy.CIDRMask = zen("CIDRMask").getValue();
		proxy.VirtualAddressInterface = zen("VirtualAddressInterface").getValue();
		if (proxy.VirtualAddressInterface == "") {
			proxy.VirtualAddressInterface = zenPage.OldVirtualAddressInterface;
		}
		if (proxy.CIDRMask != "") {
			proxy.FullVirtualAddress = proxy.VirtualAddress + "/"+ proxy.CIDRMask;
		} else {
			proxy.FullVirtualAddress = proxy.VirtualAddress;
		}
	} else {
		// If user selected No then make sure to reset VirtualAddress and VirtualAddressInterface to null.
		proxy.VirtualAddress = "";
		proxy.CIDRMask = "";
		proxy.VirtualAddressInterface = "";
		proxy.FullVirtualAddress = "";
	}
	
	proxy.QOSTimeout = zen("QOSTimeout").getValue();
	
	proxy.CompressionForFailoverMembers = zen("FOCmpMode").getValue();
	proxy.CompressionForAsyncMembers = zen("ASYNCmpMode").getValue();
	proxy.CompressionTypeForFailoverMembers = zen("FOCmpType").getValue();
	proxy.CompressionTypeForAsyncMembers = zen("ASYNCmpType").getValue();
	proxy.AllowParallelDejournaling = zen("MultiDejournal").getValue();

	proxy.OldVirtualAddress = zenPage.OldVirtualAddress;
	proxy.OldVirtualAddressInterface = zenPage.OldVirtualAddressInterface;
	proxy.OldCIDRMask = zenPage.OldCIDRMask;
	
	var ok = this.validate(proxy);
	if (!ok) return;

	var result = this.SaveData(proxy);
	zenPage.afterSave(result);
}

///  Save general association data to server.<br/>
///  Returns proxy.ok = 1 (save successful) or 0 (error occurred)<br/>
///  proxy.ErrorMessage (save failed and display this error message).
///  If proxy.ok is 1 and no messages returned then we return to SMP home.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set ConfigSaved = 0
		
		Set VIPChanged = 0
		If (pProxy.VirtualAddress '= pProxy.OldVirtualAddress) {
			Set VIPChanged = 1
		} ElseIf (pProxy.CIDRMask '= pProxy.OldCIDRMask) {
			Set VIPChanged = 2
		} ElseIf (pProxy.OldVirtualAddressInterface '= pProxy.VirtualAddressInterface) {
			Set VIPChanged = 3
		}
		
		If VIPChanged {
			Set isPrimary = $SYSTEM.Mirror.IsPrimary()
			If pProxy.UseVIP = 1 {
				#; If we're here, we're changing from non-VIP to VIP
				
				#; Make sure the Virtual Interface is specified if we have a VIP.
				If (pProxy.VirtualAddress '= "") && (pProxy.VirtualAddressInterface = "") {
					Set tSC = $$$ERROR($$$VirtualInterfaceIsNull)
					throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)	
				}
				
				#; If HP-UX, make sure we have an index number.
				If (pProxy.VirtualAddressInterface '= "") && pProxy.ShowVAI {
					If ($L(pProxy.VirtualAddressInterface,":") '= 2) || 
						($P(pProxy.VirtualAddressInterface,":",2)'?.N) {
						Set tSC = $$$ERROR($$$BadVAI,pProxy.VirtualAddressInterface)
						throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
					}
				}
				
				#; Validate the VIP with subnet mask.
				#;SML1809 ; validate when CIDRMask is changed.
				If (pProxy.VirtualAddress '= "") && (pProxy.OldVirtualAddressInterface '= pProxy.VirtualAddressInterface || (pProxy.OldCIDRMask '= pProxy.CIDRMask)) {
					Set Type = $S((VIPChanged = 1) && isPrimary:1,1:0)
					Set tSC = ##class(SYS.MirrorConfiguration).ValidateVirtualAddress(pProxy.FullVirtualAddress,Type,pProxy.VirtualAddressInterface)
					If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
				}
			} Else {
				#; If we're here, we're changing from VIP to non-VIP
				If (pProxy.OldVirtualAddressInterface '= "") {
					Set tSC = ..SaveMirrorConfig(pProxy)
					If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
					
					Set ConfigSaved = 1
					
					#; Make sure the VIP is removed before removing the Interface.
					If isPrimary && (pProxy.OldVirtualAddress '= "") && (pProxy.VirtualAddress = "") {
						For i=1:1:10 {
							Quit:'$System.INetInfo.CheckAddressExist(pProxy.OldVirtualAddress)
							Hang .5
						}
					}
				}
			}
			
			#; Save Config.MapMirrors's VirtualAddressInterface if it's modified
			If (pProxy.OldVirtualAddressInterface '= pProxy.VirtualAddressInterface) {
				Set tSC = ##class(Config.MirrorMember).Get(.Properties)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
				Set Properties("VirtualAddressInterface") = pProxy.VirtualAddressInterface
				Set tSC = ##class(Config.MirrorMember).Modify(.Properties)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
				Kill Properties
			}
		}
		
		If (ConfigSaved = 0) {
			Set tSC = ..SaveMirrorConfig(pProxy)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
		
		Set tProxy.ok = 1
		
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

/// Save Config.Mirrors
ClassMethod SaveMirrorConfig(pProxy As %ZEN.proxyObject) As %Status
{
	Set tSC = ##class(Config.Mirrors).Get(pProxy.MirrorName,.Properties)
	If $$$ISERR(tSC) Quit tSC
	
	Set Modified = 0
	
	If ($G(Properties("QOSTimeout")) '= pProxy.QOSTimeout) {
		Set Properties("QOSTimeout") = pProxy.QOSTimeout
		Set Modified = 1
	}
	If ($G(Properties("UseSSL")) '= pProxy.UseSSL) {
		Set Properties("UseSSL") = pProxy.UseSSL
		Set Modified = 1
	}
	If ($G(Properties("VirtualAddress")) '= pProxy.FullVirtualAddress) {
		Set Properties("VirtualAddress") = pProxy.FullVirtualAddress
		Set Modified = 1
	}
	
	If ($G(Properties("ArbiterNode")) '= pProxy.ArbiterNode) {
		Set Properties("ArbiterNode") = pProxy.ArbiterNode
		Set Modified = 1
	}
	
	If ($G(Properties("CompressionForFailoverMembers")) '= pProxy.CompressionForFailoverMembers) {
		Set Properties("CompressionForFailoverMembers") = pProxy.CompressionForFailoverMembers
		Set Modified = 1
	}
	
	If ($G(Properties("CompressionForAsyncMembers")) '= pProxy.CompressionForAsyncMembers) {
		Set Properties("CompressionForAsyncMembers") = pProxy.CompressionForAsyncMembers
		Set Modified = 1
	}
	
	If ($G(Properties("CompressionTypeForFailoverMembers")) '= pProxy.CompressionTypeForFailoverMembers) {
		Set Properties("CompressionTypeForFailoverMembers") = pProxy.CompressionTypeForFailoverMembers
		Set Modified = 1
	}
	
	If ($G(Properties("CompressionTypeForAsyncMembers")) '= pProxy.CompressionTypeForAsyncMembers) {
		Set Properties("CompressionTypeForAsyncMembers") = pProxy.CompressionTypeForAsyncMembers
		Set Modified = 1
	}
	
	If ($G(Properties("AllowParallelDejournaling")) '= pProxy.AllowParallelDejournaling) {
		Set Properties("AllowParallelDejournaling") = pProxy.AllowParallelDejournaling
		Set Modified = 1
	}
	
	If (Modified = 1) {
		Set tSC = ##class(Config.Mirrors).Modify(pProxy.MirrorName,.Properties)
		If $$$ISERR(tSC) Quit tSC
	}
	
	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("Edit Mirror")
}

/// Set Locator bar and determine whether to show change password option.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..lblTitle = $$$Text("Use the form below to edit the existing Mirror")_":"
	
	Set %page.MirrorName = ##class(Config.Mirrors).GetMirrorName()
    If %page.MirrorName="" {
	    Set tSC = $$$ERROR($$$MirrorSetNameNotDefined)
	    Do ..DisplayError(tSC)
		Quit $$$OK
    } Else {
	 	Set ..lblTitle = $$$FormatText($$$Text("Use the form below to edit the existing Mirror '%1'"),%page.MirrorName)_":"   
    }

	Set tSC = ..GetSSLLink(.linkSSL, .labelSSL)
	If $$$ISERR(tSC) {
		Do ..DisplayError(tSC)
		Quit $$$OK
	}
	Set ..%GetComponentById("linkSSL").caption = labelSSL
	Set %page.SSLLink = linkSSL
	
	Set tSC = ##class(SYS.Mirror).CheckISCAgent()
	If $$$ISERR(tSC) {
		Do ..DisplayError(tSC)
		Quit $$$OK
	}
	
	Kill Properties
	Set tSC = ##class(Config.Mirrors).Get(%page.MirrorName,.Properties)
	If $$$ISERR(tSC) {
		Do ..DisplayError(tSC)
		Quit $$$OK
	}
	Set ..%GetComponentById("QOSTimeout").value = $G(Properties("QOSTimeout"))
	#;SMLXXX
	Set (..CurrentUseSSL,..%GetComponentById("UseSSL").value) = $G(Properties("UseSSL"))
	Set (..%GetComponentById("VirtualAddress").value,%page.OldVirtualAddress) = $P($G(Properties("VirtualAddress")),"/",1)
	Set (..%GetComponentById("CIDRMask").value,%page.OldCIDRMask) = $P($G(Properties("VirtualAddress")),"/",2)
	If $G(Properties("ArbiterNode"))'="" {
		Set ..%GetComponentById("UseArbiter").value = 1
		Set ..%GetComponentById("idArbiter").hidden = 0
		Set ..%GetComponentById("ArbiterAddress").value = $P(Properties("ArbiterNode"),"|",1)
		Set ..%GetComponentById("ArbiterPort").value = $P(Properties("ArbiterNode"),"|",2)
	} Else {
		Set ..%GetComponentById("ArbiterPort").value = $$$GetDefaultAgentPort
	}
	// SML2049+
	Set (..CurrentFOCmpMode,..%GetComponentById("FOCmpMode").value) = +$G(Properties("CompressionForFailoverMembers"))
	Set (..CurrentASYNCmpMode,..%GetComponentById("ASYNCmpMode").value) = +$G(Properties("CompressionForAsyncMembers"))
	// SML2049-
	// SML2635+
	Set (..CurrentFOCmpType,..%GetComponentById("FOCmpType").value) = +$G(Properties("CompressionTypeForFailoverMembers"))
	Set (..CurrentASYNCmpType,..%GetComponentById("ASYNCmpType").value) = +$G(Properties("CompressionTypeForAsyncMembers"))
	if ..CurrentFOCmpMode=$$$MIRCMPCompressed s ..%GetComponentById("FOCmpType").hidden = 0
	if ..CurrentASYNCmpMode=$$$MIRCMPCompressed s ..%GetComponentById("ASYNCmpType").hidden = 0
	// SML2635-
	// SML2393
	Set (..CurrentMultiDejournal,..%GetComponentById("MultiDejournal").value) = +$G(Properties("AllowParallelDejournaling"))
		
	// SML1756 ; check both runtime and startup journal encryption status.
	// SML1887 ; Non-primary should not be allowed to change UseSSL.
	If (##class(%SYS.Journal.System).IsJournalEncryptionEnabled(3) && ($G(Properties("UseSSL"),0) = 1))||'$SYSTEM.Mirror.IsPrimary() {
		Set ..%GetComponentById("UseSSL").disabled = 1
	}
	
	Kill Properties
	Set tSC = ##class(Config.MirrorMember).Get(.Properties)
	If $$$ISERR(tSC) {
		Do ..DisplayError(tSC)
		Quit $$$OK
	}
	Set ..JoinMirror = $s($System.Mirror.IsPrimary():+$G(Properties("JoinMirror")),1:1)
	Set (VirtualAddressInterface,%page.OldVirtualAddressInterface) = ""
	Set Name = $G(Properties("SystemName"))
	Set (VirtualAddressInterface,%page.OldVirtualAddressInterface) = $G(Properties("VirtualAddressInterface"))
	Set ..%GetComponentById("VirtualAddressInterface").value = VirtualAddressInterface
	#;SML1880+
	Set ..lblText1 = $$$FormatText($$$Text("This member is %1"), Name)
	If $SYSTEM.Mirror.IsPrimary() {
		Set ..lblText2 = $$$Text("This member is the primary. Changes will be sent to other members.")
	} ElseIf $SYSTEM.Mirror.ConnectedToPrimary(%page.MirrorName) {
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
	
	Set mirrorStatus = $SYSTEM.Mirror.GetInfo()
	If mirrorStatus["NOTINIT" {
		If Properties("SystemName") = "" {
			Set ..%GetComponentById("errmsg").value = $$$Text("This instance is not initialized as a mirror member.")
			Set ..DisableRemove = 1
		} Else {
			Set ..%GetComponentById("errmsg").value = $$$Text("This instance is configured but no longer initialized as a mirror member; click Remove Mirror Configuration again to completely remove the mirror configuration.")
		}
		Set ..%GetComponentById("errmsg").hidden = 0
		Set ..%GetComponentById("fld").hidden = 1
		Set ..DisableSave = 1
		Quit $$$OK
	} ElseIf mirrorStatus'[",PRIMARY," {
		Set (..%GetComponentById("UseArbiter").disabled,..%GetComponentById("ArbiterAddress").disabled,..%GetComponentById("ArbiterPort").disabled) = 1
		// SML2049
		Set (..%GetComponentById("FOCmpMode").disabled,..%GetComponentById("ASYNCmpMode").disabled) = 1
		// SML2692
		Set (..%GetComponentById("FOCmpType").disabled,..%GetComponentById("ASYNCmpType").disabled) = 1
		// SML2393
		Set ..%GetComponentById("MultiDejournal").disabled = 1
	}
	
	Kill Properties
	Set tSC = ##class(Config.MapMirrors).Get(%page.MirrorName,Name,.Properties)
	If $$$ISERR(tSC) {
		Do ..DisplayError(tSC)
		Quit $$$OK
	}

	#; Set UseVIP to 1 if the existing VirtualAddress is set. OW set to 0.
	If %page.OldVirtualAddress = "" {
		Set ..%GetComponentById("VirtualAddressInterface").value = ""
		Set UseVIP = 0
	} Else {
		Set UseVIP = 1
		Set ..%GetComponentById("idNetwork").hidden = 0
	}
	Set ..%GetComponentById("UseVIP").value = UseVIP
	#;SML1887+ ; Non-primary should not be allowed to change QOS timeout.
	if '$SYSTEM.Mirror.IsPrimary() Set ..%GetComponentById("QOSTimeout").disabled = 1
	#; Allow non-connected failover member to edit VIP. But don't allow backup member to edit VIP.
	#;SML2743
	if $SYSTEM.Mirror.IsBackup()||'$SYSTEM.INetInfo.CheckArpingInstalled() {
		Set ..%GetComponentById("UseVIP").disabled = 1
		Set ..%GetComponentById("VirtualAddress").disabled = 1
		Set ..%GetComponentById("CIDRMask").disabled = 1
		#;SML2743+
		if '$SYSTEM.INetInfo.CheckArpingInstalled() {
			Set %page.OldVirtualAddressInterface = ""
			Set ..%GetComponentById("UseVIP").hint = $$$Text("'arping' command is missing")
			Set ..%GetComponentById("UseVIP").hintClass = "redText"
			Set ..%GetComponentById("VirtualAddressInterface").value = ""
			Set ..%GetComponentById("idNetwork").hidden = 1
		}
		#;SML2743-
	}
	#;SML1887-
	If '##class(SYS.MirrorConfiguration).EnableMirrorMenu(8) || '..AnyDNUpdates(..MirrorName) {
		Set ..%GetComponentById("DNUpdatesField").hidden = 1
	} else {
		If '$SYSTEM.Mirror.IsPrimary() {
			Set ..lblDNUpdates = $$$Text("The SSL certificate of following failover member is changed. You need to authorize the DN update so local system could connect to the primary member.") 
			Set ..%GetComponentById("DNUpdatesTable").multiSelect = 0
			Set ..%GetComponentById("DNUpdatesTable").onmultiselect = ""
			Set ..%GetComponentById("btnAuthorizeDNUpdates").disabled = 0
			Set ..%GetComponentById("btnAuthorizeDNUpdates").controlClass = "commandButton"
		} else {
			// This is a primary member, we allow user to authorize or reject the selected member.
			Set ..lblDNUpdates = $$$Text("The SSL certificate of following member(s) is changed. Select the member(s) you wish to authorize or reject to connect to this system.") 
			Set ..%GetComponentById("btnRejectDNUpdates").hidden = 0
		}
	}
	If '##class(SYS.MirrorConfiguration).EnableMirrorMenu(3) || '..AnyPendingNewMembers(..MirrorName) {
		Set ..%GetComponentById("NewMembersField").hidden = 1
	} else {
		#;SMLXXX+
		if ..CurrentUseSSL {
			Set ..lblNewMembers = $$$Text("Select the member(s) you wish to authorize or reject:") 
		} else {
			Set ..%GetComponentById("btnAuthorizeNewMembers").caption = $$$Text("Add")
			Set ..lblNewMembers = $$$Text("Select the member(s) you wish to add or reject:") 
		}
		#;SMLXXX-
	}

	Set ..%GetComponentById("idWarnSSL").value = $$$Text("Use of SSL/TLS is highly recommended!")
	
	If ..IsEMSReadOnly {
		Set idlist="UseSSL,linkSSL,UseArbiter,ArbiterAddress,ArbiterPort,UseVIP,VirtualAddress,CIDRMask,VirtualAddressInterface,QOSTimeout,FOCmpMode,ASYNCmpMode"
		For id=1:1:$l(idlist,",") {
			Set ..%GetComponentById($p(idlist,",",id)).disabled = 1
		}
	}

	Quit 1
}

///  Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	If ..IsEditForm = 0 Quit $$$OK
	Set failedCnt = ##class(SYS.MirrorConfiguration).LookupLocalValidationFailures(.failure,0)
	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnSave",$$$Text("Save"),$$$Text("Save changes"),"zenPage.doSave();")
	Set pCommands(2) = $LB("btnCancel",$$$Text("Cancel"),$$$Text("Return without saving new changes"),"zenPage.doCancel();")
	If failedCnt = 0 {
		Set pCommands(3) = $LB("btnRemove",$$$Text("Remove Mirror Configuration"),$$$Text("Remove all mirror configuration information from this instance."),"zenPage.doRemove();")
		Set pCommands(4) = $LB("btnRemoveOthers",$$$Text("Remove Other Mirror Member"),$$$Text("Remove another instance from this mirror."),"zenPage.doRemoveOther();")
	}
	Quit $$$OK
}

ClassMethod DrawMemberType(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Write $CASE(%query(pName),$$$FailoverMemberType:"Failover",$$$AsyncMemberType:"Async",:"Unknown")
	Quit $$$OK
}

ClientMethod doEdit(nodeName) [ Language = javascript ]
{
	// check if editing this node is allowed or not
	var editAllowed = false;
	if (this._validationInfo) {
		var json = this._validationInfo;
		if (json.failedCount > 0) {
			if (json.failures) {
				for (var i=0; i<json.failures.length; i++) {
					var data = json.failures[i];
					if (data.failureCode == "TIMEOUT" && data.sysname == nodeName) {
						editAllowed = true;
						break;
					}
				}
			}
		} else {
			editAllowed = true;
		}
	} else {
		editAllowed = true;
	}
	if (editAllowed) {
		var url = zenLink('%CSP.UI.Portal.Mirror.Dialog.NodeAddressEdit.zen?MirrorName='+encodeURIComponent(zenPage.MirrorName)+'&NodeName='+encodeURIComponent(nodeName));
		zenLaunchPopupWindow(url,'NodeEdit','resizable,width=600,height=500');
	} else {
		var msg = $$$FormatText($$$Text("Editing of '%1' under the current Mirror condition is not allowed."),nodeName);
		alert(msg);	
	}
}

ClassMethod AnyPendingNewMembers(MirrorName As %String) As %Integer [ ZenMethod ]
{
	s rs=##class(%ResultSet).%New("SYS.Mirror:PendingNewMembers")
	d rs.Execute(MirrorName)
	Quit rs.Next()
}

/// enable the Authorize and Reject buttons if there are members selected. disable otherwise.
ClientMethod rowSelectDNUpdates(selectedRows) [ Language = javascript ]
{
	var dbArray = selectedRows.split(',');
	var buttonA = zen('btnAuthorizeDNUpdates');
	var buttonR = zen('btnRejectDNUpdates');
	this.NumDNUpdates = 0;
	for (var i = 0; i < dbArray.length; i++) {
		if (dbArray[i] != '') {
			this.NumDNUpdates++;
		}
	}
	if (this.NumDNUpdates > 0) {
		buttonA.setProperty('disabled',0);
		buttonA.setProperty('controlClass','commandButton');
		buttonR.setProperty('disabled',0);
		buttonR.setProperty('controlClass','commandButton');
	} else {
		buttonA.setProperty('disabled',1);
		buttonA.setProperty('controlClass','commandButtonDisabled');
		buttonR.setProperty('disabled',1);
		buttonR.setProperty('controlClass','commandButtonDisabled');
	}
}

ClientMethod doAuthorizeDNUpdates() As %Boolean [ Language = javascript ]
{
	var text = "";
	if (this.IsPrimary == 1 && this.NumDNUpdates < 1) {
		text = $$$Text('Please select at least one member');
		alert(text);
		return;
	}
	
	if (this.IsPrimary == 1) {
		text = $$$Text("Are you sure you want to update the DN of selected member(s)?")+"\n";
	} else {
		text = $$$Text("Are you sure you want to update the DN of the other failover member?")+"\n";
	}
	if (!confirm(text)) return;
	
	var proxy = new zenProxy();
	proxy.Members = zen('DNUpdatesTable').selectedRows;
	proxy.MirrorName = this.MirrorName;
	var result = this.AuthorizeDNUpdates(proxy);
	if (result.status != 1) {
		alert(result.resultText);
	}
	window.location.reload(true);
}

ClientMethod doRejectDNUpdates() As %Boolean [ Language = javascript ]
{
	var text = "";
	if (this.NumDNUpdates < 1) {
		text = $$$Text('Please select at least one member');
		alert(text);
		return;
	}
	
	text = $$$Text("Are you sure you want to reject updating the DN of selected member(s)?")+"\n";
	if (!confirm(text)) return;
	
	var proxy = new zenProxy();
	proxy.Members = zen('DNUpdatesTable').selectedRows;
	proxy.MirrorName = this.MirrorName;
	var result = this.RejectDNUpdates(proxy);
	if (result.status != 1) {
		alert(result.resultText);
	}
	window.location.reload(true);
}

ClassMethod AuthorizeDNUpdates(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
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
			If '$SYSTEM.Mirror.IsPrimary() || (Members[(","_name_",")) {
				Set props("SSLComputerName") = rs.Data("SSLComputerName")
				Set rc=##class(Config.MapMirrors).Modify(mirname,name,.props)
				if '$$$ISOK(rc) {
					Set tProxy.status = rc
					Set tProxy.resultText = tProxy.resultText_"<br/>"_..EscapeHTML(name)_"..."_..EscapeHTML($System.Status.GetErrorText(rc))
				} else {
					d ##class(SYS.Mirror).RemoveFromApprovalList(name,rs.Data("GUID"),mirname)
				}
			}
		}
	} Catch exp {
		Set tSC = exp.AsStatus()
		Set tProxy.status = tSC
		Set tProxy.resultText = ..EscapeHTML($System.Status.GetErrorText(tSC))
	}
	Quit tProxy
}

ClassMethod RejectDNUpdates(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
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
			Set name = rs.Data("Name"),GUID=rs.Data("GUID")
			If (Members[(","_name_",")) {
				s idx=$o(^SYS("MIRRORSET",mirname,"Member",""),1,info)
				while idx'="" {
					if $LG(info)=name quit
					s idx=$o(^SYS("MIRRORSET",mirname,"Member",idx),1,info)
				}
				if idx'="" s rc=$$RejectApproval^MIRRORCTL(mirname,idx,$LB(name,GUID))
				#; Always remove this pending request after rejection.
				d ##class(SYS.Mirror).RemoveFromApprovalList(name,GUID,mirname)
			}
		}
	} Catch exp {
		Set tSC = exp.AsStatus()
		Set tProxy.status = tSC
		Set tProxy.resultText = ..EscapeHTML($System.Status.GetErrorText(tSC))
	}
	Quit tProxy
}

/// enable the Authorize and Reject buttons if there are members selected. disable otherwise.
ClientMethod rowSelectNewMembers(selectedRows) [ Language = javascript ]
{
	var dbArray = selectedRows.split(',');
	var buttonA = zen('btnAuthorizeNewMembers');
	var buttonR = zen('btnRejectNewMembers');
	this.NumNewMembers = 0;
	for (var i = 0; i < dbArray.length; i++) {
		if (dbArray[i] != '') {
			this.NumNewMembers++;
		}
	}
	if (this.NumNewMembers > 0) {
		buttonA.setProperty('disabled',0);
		buttonA.setProperty('controlClass','commandButton');
		buttonR.setProperty('disabled',0);
		buttonR.setProperty('controlClass','commandButton');
	} else {
		buttonA.setProperty('disabled',1);
		buttonA.setProperty('controlClass','commandButtonDisabled');
		buttonR.setProperty('disabled',1);
		buttonR.setProperty('controlClass','commandButtonDisabled');
	}
}

ClientMethod doAuthorizeNewMembers() As %Boolean [ Language = javascript ]
{
	var text = "";
	if (this.NumNewMembers < 1) {
		text = $$$Text('Please select at least one member');
		alert(text);
		return;
	}
	
	if (this.CurrentUseSSL == 1) {
		text = $$$Text("Are you sure you want to authorize the selected member(s)?")+"\n";
	} else {
		text = $$$Text("Are you sure you want to add the selected member(s)?")+"\n";
	}
	if (!confirm(text)) return;
	
	var proxy = new zenProxy();
	proxy.Members = zen('NewMembersTable').selectedRows;
	proxy.MirrorName = this.MirrorName;
	var result = this.AuthorizeNewMembers(proxy);
	if (result.status != 1) {
		alert(result.resultText);
	}
	window.location.reload(true);
}

ClientMethod doRejectNewMembers() As %Boolean [ Language = javascript ]
{
	var text = "";
	if (this.NumNewMembers < 1) {
		text = $$$Text('Please select at least one member');
		alert(text);
		return;
	}
	
	text = $$$Text("Are you sure you want to reject the selected member(s)?")+"\n";
	if (!confirm(text)) return;
	
	var proxy = new zenProxy();
	proxy.Members = zen('NewMembersTable').selectedRows;
	proxy.MirrorName = this.MirrorName;
	var result = this.RejectNewMembers(proxy);
	if (result.status != 1) {
		alert(result.resultText);
	}
	window.location.reload(true);
}

ClassMethod AuthorizeNewMembers(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.status = $$$OK
	Set tProxy.resultText = ""
	Set Members = ","_pProxy.Members_","
	Set mirname = pProxy.MirrorName
	
	Try {
		Set rs=##class(%ResultSet).%New("SYS.Mirror:PendingNewMembers")
		Do rs.Execute(mirname)
		while rs.Next() {
			Set name = rs.Data("Name")
			If Members[(","_name_",") {
				#;SML2382+
				Set props("GUID") = rs.Data("GUID")
				Set props("ECPAddress") = rs.Data("ECPAddress")
				Set props("MemberType") = rs.Data("MemberType")
				Set props("MirrorAddress") = rs.Data("MirrorAddress")
				if props("MemberType")'=$$$FailoverMemberType {
					s ipaddr=##class(%SYSTEM.INetInfo).HostNameToAddr(props("ECPAddress"))
					if '##class(%SYSTEM.INetInfo).CheckAddressExist(ipaddr) {
						#; Check if both ECP and Mirror addresses are not accessible.
						Set SameECPMirror=(props("ECPAddress")=props("MirrorAddress"))
						if 'SameECPMirror {
							s mipaddr=##class(%SYSTEM.INetInfo).HostNameToAddr(props("MirrorAddress"))
							s SameECPMirror=(mipaddr=ipaddr)
						}
						if SameECPMirror||('##class(%SYSTEM.INetInfo).CheckAddressExist(mipaddr)) {
							Set tProxy.status = 0
							Set errtext="The Superserver address "_props("ECPAddress")_$s('SameECPMirror:" and Mirror Private address "_props("MirrorAddress")_" are",1:" is")_" unreachable, so this member is rejected and removed from the pending list."
							Set tProxy.resultText = tProxy.resultText_"<br>"_..EscapeHTML(name)_"..."_..EscapeHTML(errtext)
						    d ##class(SYS.Mirror).RemoveFromApprovalList(name,props("GUID"),mirname)
						    continue
						}
				    }
				}
				#;SML2382-
				Set props("SSLComputerName") = rs.Data("SSLComputerName")
				Set props("ConnectsTo") = rs.Data("ConnectsTo")
				Set props("AgentAddress") = rs.Data("AgentAddress")
				Set props("AgentPort") = rs.Data("AgentPort")
				Set props("InstanceDirectory") = rs.Data("InstanceDirectory")
				Set props("MirrorSSPort") = rs.Data("MirrorSSPort")
				Set props("EncryptCommunication") = rs.Data("EncryptCommunication")
				#;SML2911 ; Add AsyncMemberType property
				Set props("AsyncMemberType") = rs.Data("AsyncMemberType")
				Set rc=##class(Config.MapMirrors).Create(mirname,name,.props)
				if '$$$ISOK(rc) {
					Set tProxy.status = rc
					Set tProxy.resultText = tProxy.resultText_"<br/>"_..EscapeHTML(name)_"..."_..EscapeHTML($System.Status.GetErrorText(rc))
				} else {
					d ##class(SYS.Mirror).RemoveFromApprovalList(name,rs.Data("GUID"),mirname)
					#;SML2305 ; Notify other members if the new member is not failover member.
					if rs.Data("MemberType")'=$$$FailoverMemberType d NotifyAsyncMembers^MIRRORMGR(mirname,name,1)
				}
			}
		}
	} Catch exp {
		Set tSC = exp.AsStatus()
		Set tProxy.status = tSC
		Set tProxy.resultText = ..EscapeHTML($System.Status.GetErrorText(tSC))
	}
	Quit tProxy
}

ClassMethod RejectNewMembers(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.status = $$$OK
	Set tProxy.resultText = ""
	Set Members = ","_pProxy.Members_","
	Set mirname = pProxy.MirrorName
	
	Try {
		Set rs=##class(%ResultSet).%New("SYS.Mirror:PendingNewMembers")
		Do rs.Execute(mirname)
		while rs.Next() {
			Set name = rs.Data("Name"), GUID=rs.Data("GUID")
			If Members[(","_name_",") {
				if rs.Data("MemberType")=$$$FailoverMemberType {
					s basedir=rs.Data("InstanceDirectory")
					s addrlist=rs.Data("AgentAddress")_"|"_rs.Data("AgentPort")
					if rs.Data("MirrorAddress")'=rs.Data("AgentAddress") {
						s addrlist=addrlist_","_rs.Data("MirrorAddress")_"|"_rs.Data("AgentPort")
					}
					if (rs.Data("ECPAddress")'=rs.Data("AgentAddress")) && (rs.Data("ECPAddress")'=rs.Data("MirrorAddress")) {
						s addrlist=addrlist_","_rs.Data("ECPAddress")_"|"_rs.Data("AgentPort")
					}
				} else {
					s addrlist=rs.Data("ECPAddress")_"|"_rs.Data("MirrorSSPort")
					s basedir=""
				}
				s targguid=rs.Data("GUID")
				s rc=$$RejectApprovalByAddr^MIRRORCTL(mirname,addrlist,targguid,basedir,$LB(name,GUID))
				#; Always remove this pending request after rejection.
				d ##class(SYS.Mirror).RemoveFromApprovalList(name,GUID,mirname)
			}
		}
	} Catch exp {
		Set tSC = exp.AsStatus()
		Set tProxy.status = tSC
		Set tProxy.resultText = ..EscapeHTML($System.Status.GetErrorText(tSC))
	}
	Quit tProxy
}

/// Return server info per validation checks for failure. 
Method GetValidationInfo(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Set pObject = ##class(%ZEN.proxyObject).%New()
	Try {
		Set pObject = $$$NULLOREF
		Set tSC = ##class(%CSP.UI.Portal.Mirror.Utils).ValidateMirror(.pObject)
		If $$$ISERR(tSC) {
			Quit	
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
