/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syMirror, %syINET)

/// This page maybe called to allow user to join the system as a new member when certain failure occurred.
Class %CSP.UI.Portal.Mirror.Dialog.JoinNewMember Extends (%CSP.UI.Portal.Dialog.WizardTemplate, %ZEN.Portal.Utils, %CSP.UI.Portal.Mirror.Utils) [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Mirror.Dialog.JoinNewMember.zen";

/// Displayed name of this page.
Parameter PAGENAME = "JoinNewMember";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property MirrorName As %ZEN.Datatype.string(ZENURL = "MirrorName");

Property MemberType As %ZEN.Datatype.string(ZENURL = "MemberType");

Property MemberCount As %ZEN.Datatype.string(ZENURL = "MemberCount");

Property FailoverCount As %ZEN.Datatype.string(ZENURL = "FailoverCount");

Property PrimaryId As %ZEN.Datatype.string(ZENURL = "PrimaryId");

Property InitialMessage As %String;

XData Style
{
<style type="text/css">
/* @doc="error note style used in idRespond" */
.errorNote {
	color: #da4848;
	border: 1px gray solid;
	border-radius: 5px;
	font-size: 1.0em;
	font-weight: bold;
	padding: 6px;
}
/* @doc="regular note style used in idRespond" */
.note {
	color: #4D3926;
	border: 1px solid #4D3926;
	border-radius: 5px;
	font-size: 1.0em;
	font-weight: bold;
	padding: 6px;
}
.radioButtonCaption,.radioButtonCaptionDisabled {
	font-size: 12px;
}
.zenHint {
	padding-left: 25px;	
}
.ml25 {
	margin-left: 25px;	
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
<button id="command_btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();"/>
<spacer width="5" />
<button id="command_btnFinish" controlClass="commandButton" caption="Finish" onclick="zenPage.dialogFinish();"/>
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<jsonProvider id="jsonSystemInfo" OnGetTargetObject="GetSystemInfo">
<parameter paramName="parmMirrorName" value="#(%page.MirrorName)#"/>
<parameter paramName="parmPrimaryId" value="#(%page.PrimaryId)#"/>
 </jsonProvider>
<spacer height="10"/>
<label id="idRespond" enclosingClass="note" containerStyle="padding-top:10px;padding-left:4px;" hidden="true"/>
<textarea id="testjsonText" cols="80" rows="10" hidden="true"/>
<group id="fld" enclosingClass="EditForm" enclosingStyle="margin-left:3px;padding:3px;">
<radioSet id="JoinType" label="Join Mirror As" displayList="Failover,Async" valueList="0,2" value="" onchange="zenPage.changeType();"/>

<group id="content" hidden="true">

<group id="groupSSL" hidden="true">
<label label="The primary member has UseSSL set, so you need to setup Mirror SSL configuration before you could join the mirror set."/>
 <button id="btnSSL1" caption="Setup Mirror SSL Configuration Now" onclick="zenPage.doSSL('btnSSL1');"/></group>
</group>

<group id="groupAsyncMemberType" hidden="true">
<radioButton id="radAsyncMemberType_0" name="radAsyncMemberTypeFlag" label="Select Async member type" caption="Disaster Recovery" captionClass="radioButtonCaption" 
hint="" optionValue="0" onclick="zenPage.doChangeAsyncMemberType(0);"/>

<radioButton id="radAsyncMemberType_1" name="radAsyncMemberTypeFlag" label="" caption="Read-Only Reporting" captionClass="radioButtonCaption"
hint="" optionValue="1" onclick="zenPage.doChangeAsyncMemberType(1);"/>

<radioButton id="radAsyncMemberType_2" name="radAsyncMemberTypeFlag" label="" caption="Read-Write Reporting" captionClass="radioButtonCaption"
hint="" optionValue="2" onclick="zenPage.doChangeAsyncMemberType(2);"/>

<!-- groupAsyncSSL is not currently used.
<group id="groupAsyncSSL" hidden="true">
<label label="Use SSL/TLS is not required in primary member. Please choose the following SSL/TLS communication for this async member."/>
<radioSet id="EncryptCommunication" label="Select Encrypt communication" displayList="None,Outgoing only,Incoming only,All" valueList="0,1,2,3" value="" onchange="zenPage.doChangeEncryptCommunication();" />
</group>
-->
</group> <!-- end of groupAsyncMemberType -->

<!-- groupSSLEncrypt is not currently used -->
<group id="groupSSLEncrypt" hidden="true">
<label label="SSL/TLS configuration is not setup yet."/>
<button id="btnSSL2" caption="Setup Mirror SSL Configuration Now" onclick="zenPage.doSSL('btnSSL2');"/>
</group>

<group id="groupLocalMirrorInfo" hidden="true" enclosingClass="ml25">
<text id="Ourname" name="Ourname" label="Our mirror member name" size="60" onblur="zenPage.validateBeforeSave();"/>
<text id="MirrorAddress" name="MirrorAddress" label="Mirror private address of local member" size="60" onblur="zenPage.validateBeforeSave();"/>
<text id="SuperServer" name="SuperServer" label="Super Server address" size="60" onblur="zenPage.validateBeforeSave();"/>
<text id="AgentAddress" name="AgentAddress" label="Agent address" size="60" onblur="zenPage.validateBeforeSave();"/>
</group>

<group id="groupVIP" hidden="true" enclosingClass="ml25">
<select id="VirtualAddressInterface" label="Select network interface for mirror virtual network address" valueList="" displayList=""/>
<text id="idxnum" name="idxnum" label="Logical index number" hidden="true" onchange="return zenPage.validateLogicalIndex();"/>
</group>

</group>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	var json = zen('jsonSystemInfo').getContentObject();
	this._SystemInfo = json;
	// if InitialMessage exists, it means we should not show anything and Join cannot continue.
	if (this.InitialMessage) {
		this.showMsg(this.InitialMessage,1);
		return;
	}
	if (this.MemberType || this.FailoverCount == 2) {
		zen('JoinType').setValue(2);
		zen('JoinType').setHidden(true);
		this._SystemInfo.JoinType = 2;
		this.handleType();
	} else {
		zen('JoinType').setHidden(false);
	}
	if (!json.ISCAgentRunning) {
		// selection DR requires the ISCAgent running.
		zen('radAsyncMemberType_0').setProperty('hint',$$$FormatText($$$Text("(DR is not allowed to join due to %1)"),json.ISCAgentError));
		zen('radAsyncMemberType_0').setDisabled(true);
	}
	/// for yan's testing only:
	///zen('testjsonText').setValue(JSON.stringify(this._SystemInfo,null,4))
	if (json.DefaultSystemName) {
		zen('Ourname').setValue(json.DefaultSystemName);			
	}
	if (json.DefaultAddress) {
		zen('MirrorAddress').setValue(json.DefaultAddress);
		zen('SuperServer').setValue(json.SuperServer);
		zen('AgentAddress').setValue(json.AgentAddress);
	}
	if (json.VIPValueList) {
		zen('VirtualAddressInterface').setProperty('valueList', json.VIPValueList);
		zen('VirtualAddressInterface').setProperty('displayList', json.VIPDisplayList);
	}
}

/// user selected/changed Join Mirror type as Failover(joinType=1) or Async(joinType=2)
ClientMethod changeType() [ Language = javascript ]
{
	this.resetMsg();
	var joinType = parseInt(zen('JoinType').getValue());
	this._SystemInfo.JoinType = joinType;
	//unselect Async type
	zen('radAsyncMemberType_0').setValue('');
	this.handleType();
}

/// user changed the join type: Failover or Async.
/// if Failover,
ClientMethod handleType() [ Language = javascript ]
{
	var json = this._SystemInfo;
	var joinType = parseInt(json.JoinType);
	/// for Failover join, if VIPAddressMessage exists, show it and disable Finish.
	if (joinType === 0 && json.VIPAddressMessage) {
		this.showMsg(json.VIPAddressMessage,1);
		//zen('groupLocalMirrorInfo').setHidden(true);
		this.hideContent(true);
		return;
	}
	this.hideContent(false);
	zen('content').setHidden(false);
	if (json.UseSSL) {
		if (!json.SSLConfigured) {
			zen('groupSSL').setHidden(false);
			zen('groupAsyncMemberType').setHidden(true);
		}
		if (json.UseSSLMessage) {
			this.showMsg(json.UseSSLMessage,0);	
		}
	}
	var showVIP = false;
	if (joinType === 0) {
		zen('groupAsyncMemberType').setHidden(true);
		zen('groupLocalMirrorInfo').setHidden(false);
		var hideVIP = true;
		if (json.VirtualAddress && json.VIPValueList) {
			hideVIP = false;	
		}
		zen('groupVIP').setHidden(hideVIP);
		
	} else {
		//This is adding mirror set for async member. Ask for async member type and
		//encrypt communication type when UseSSL is cleared.
		zen('groupVIP').setHidden(true);
		zen('groupAsyncMemberType').setHidden(false);
		var AsynMembertType = zen('radAsyncMemberType_0').getValue();
		if (AsynMembertType == '') {
			zen('groupLocalMirrorInfo').setHidden(true);
			/* 	SSL, encrypt communication type not implemented yet
				zen('groupSSL').setHidden(false);
				if (!json.IsAsync) {
					zen('groupSSL').setHidden(true);
					zen('groupAsyncSSL').setHidden(true);
					zen('groupSSLEncrypt').setHidden(true);		
				}
			*/
		}
	}
}

ClientMethod hideContent(flag) [ Language = javascript ]
{
	zen('content').setHidden(flag);
	zen('groupAsyncMemberType').setHidden(flag);
	if (flag) {
		this.hideCommandButton("btnFinish");
		zen('groupLocalMirrorInfo').setHidden(flag);
		zen('groupVIP').setHidden(flag);
	} else {
		this.showCommandButton("btnFinish");
		zen('groupLocalMirrorInfo').setHidden(flag);
	}
}

/// User has selected an AsyncMemberType
ClientMethod doChangeAsyncMemberType(AsyncMemberType) [ Language = javascript ]
{
	var json = this._SystemInfo;
	//if (AsyncMemberType > 0) {
		//For reporting member, we want to set it as RO Reporting so we won't ask Agent later.
	//	AsyncMemberType = 1;
	//}
	this._SystemInfo.AsyncMemberType = AsyncMemberType;
	var hideAgent = (AsyncMemberType === 0) ? false : true;
	zen('AgentAddress').setHidden(hideAgent);
	//zen('groupSSLEncrypt').setHidden(true);	
	zen('groupLocalMirrorInfo').setHidden(false);
	// Promp user to choose SSL/TLS communication for this async member
	if (json.VirtualAddress && (!json.IsAsync && AsyncMemberType===0)) {
		var hideVIP = true;
		if (json.VirtualAddress && json.VIPValueList) {
			hideVIP = false;	
		}
		zen('groupVIP').setHidden(hideVIP);
		if (json.VIPAddressMessage) {
			this.showMsg(json.VIPAddressMessage,1);
		} else {
			//$$getVirtualAddressInterface
			// showVirtualAddress group
			// if (json.hpsun) then prompt for idxnum
			zen('idxnum').setHidden(!json.hpsun);
		}
	} else {
		zen('groupVIP').setHidden(true);
	}
	/// show VIPAddressMessage only if AsyncMemberType is 0
	if (json.VIPAddressMessage) {
		if (AsyncMemberType === 0) {
			msg = $$$Text("This instance is not on the same subnet as the failover member(s), which is recommended for DR async members. Please confirm the virtual IP address and subnet mask. ");
			if (json.UseSSLMessage) {
				msg += "  " + json.UseSSLMessage;
			}
			this.showMsg(msg,0);
		} else {
			if (json.UseSSLMessage) {
				this.showMsg(json.UseSSLMessage,0);
			} else {
				this.resetMsg();
			}		
		}
	}
}

/// User has made a selection of EncryptCommunication type
ClientMethod doChangeEncryptCommunication() [ Language = javascript ]
{
	var json = this._SystemInfo;	
	var EncryptCommunication = parseInt(zen('EncryptCommunication').getValue());
	this._SystemInfo.EncryptCommunication = EncryptCommunication;
	
	if (EncryptCommunication > 0 && !json.SSLConfigured) {
		// prompt user to setup SSL if it has not been setup
		zen('groupSSLEncrypt').setHidden(false);
		zen('groupLocalMirrorInfo').setHidden(true);
	} else {
		zen('groupSSLEncrypt').setHidden(true);
		//this.getLocalMirrorInfo();
		zen('groupLocalMirrorInfo').setHidden(false);
	}
}

/// delete?
ClientMethod getLocalMirrorInfo() [ Language = javascript ]
{
	var json = this._SystemInfo;	
	zen('groupLocalMirrorInfo').setHidden(false);
	if (json.AsyncMemberType === 0) {
		zen('AgentAddress').setValue(json.AgentAddress);
	}
}

ClientMethod validateOurname() [ Language = javascript ]
{
	var ourname = zenTrim(zen('Ourname').getValue());
	zen('Ourname').setValue(ourname);
	if (!ourname) {
		var msg = $$$Text("Mirror member name cannot be null. ");
		this._hasError.push(msg);
		return;
	}
	var names = this._SystemInfo.ExistingNames.split(",");
	var upourname = ourname.toUpperCase();
	var msg = '';
	if (names.length) {
		for (var n=0; n<names.length; n++) {
			if (names[n] == upourname) {
				msg = $$$Text("Member name is already in use by another mirror member. ");
				break;
			}	
		}	
	}
	if (msg == '') {
		msg = this.ValidateMemberName(upourname);
	}
	if (msg) {
		this._hasError.push(msg);
	}
}

ClientMethod validateIPFormat() [ Language = javascript ]
{
	var defaultAddr = zenTrim(zen('MirrorAddress').getValue());
	zen('MirrorAddress').setValue(defaultAddr);
	if (!defaultAddr) {
		var msg = $$$Text("Mirror private address cannot be null.");
		this._hasError.push(msg);
		return;	
	}
	var msg = this.IsIPFormatValid(defaultAddr,'default');
	if (msg) {
		this._hasError.push(msg);
		return;	
	}
}

ClientMethod validateSuperServer() [ Language = javascript ]
{
	var superServer = zenTrim(zen('SuperServer').getValue());
	zen('SuperServer').setValue(superServer);
	if (!superServer) {
		var msg = $$$Text("Super Server address cannot be null.");
		this._hasError.push(msg);
		return;	
	}
	var msg = this.IsIPFormatValid(superServer,'super');
	if (msg) {
		this._hasError.push(msg);
		return;	
	}
}

ClientMethod validateAgent() [ Language = javascript ]
{
	var agent = zenTrim(zen('AgentAddress').getValue());
	zen('AgentAddress').setValue(agent);
	if (!agent) {
		var msg = $$$Text("Agent address cannot be null.");
		this._hasError.push(msg);
		return;	
	}
	var msg = this.IsIPFormatValid(agent,'agent');
	if (msg) {
		this._hasError.push(msg);
		return;	
	}
}

ClientMethod validateInstanceName() [ Language = javascript ]
{
	var instance = zenTrim(zen('InstanceName').getValue());
	zen('InstanceName').setValue(instance);
	if (!instance) {
		this.showMsg($$$Text("Instance Name cannot be null."),1);
		return;	
	}
	var json = this._SystemInfo;
	//mirname, ipaddr, port, InstanceName
	var result = this.RetrieveMirrorConfig(this.MirrorName,json.ipaddr,json.port,instance);
	if (result) {
		this.showMsg(result,1);
		return;	
	}
}

ClientMethod validateLogicalIndex() [ Language = javascript ]
{
	var idxnum = zenTrim(zen('idxnum').getValue());
	zen('idxnum').setValue(idxnum);
	if (!idxnum) {
		var msg = $$$Text("Logical index cannot be null.");
		if (msg) {
			this._hasError.push(msg);
			return;	
		}
	}
	var json = this._SystemInfo;
	var iVirt = zen('VirtualAddressInterface').getValue() + ":" + idxnum;
	var result = this.ValidateVI(idxnum, json.OS, json.hpsun, iVirt);
	if (result) {
		this._hasError.push(result);
		return;
	} else {
		this._SystemInfo.iVirt = iVirt;
	}
	return
}

ClientMethod doSSL(btnId) [ Language = javascript ]
{
	//option1 is for groupSSL; option2 is for groupSSLEncrypt
	this._SystemInfo.sslOption = btnId;
	zenLaunchPopupWindow(zenPage.SSLLink,'SSL','resizable,width=1000,height=700');
}

/// Overriding for DN redraw
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if ((popupName == "SSL") && (action == "ok")) {
			this.SSLDefined = 1;
			var btnId = this._SystemInfo.sslOption;
			zen(btnId).setProperty("caption", $$$Text("Edit SSL/TLS"));
		}
	} catch (ex) {
		alert("Error: " + ex);
	}
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
/// 
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var abort = 1;
		var json = this._SystemInfo;
		var errorMsg = "";
		var memberType = json.JoinType;
		if (typeof memberType === 'undefined') {
			errorMsg = $$$Text("Please select the join type. ");			
		}
		memberType = parseInt(memberType);
		/// for Failover join, if VIPAddressMessage exists, show it and quit.
		if (memberType === 0 && json.VIPAddressMessage && !json.VIPValueList) {
			errorMsg += json.VIPAddressMessage;
		}
		var asyncMemberType = '';
		if (memberType === 2) {
			asyncMemberType = json.AsyncMemberType;
			if (typeof asyncMemberType === 'undefined') {
				errorMsg += $$$Text("Please select the Async member type");
			}
		}
		if (errorMsg) {
			this.showMsg(errorMsg,1);
			return false;
		}
		this.validateBeforeSave();
		if (this._hasError && this._hasError.length > 0) {
			alert($$$Text("Please fix the invalid values and try again!"));
			return false;
		}
		// if all of the above is validated, then check if we need to verify SSL
		// if there is an error, user can elect to continue or cancel. It is possible to still Join an mirror depending
		// on the type of error. It is user's responsibility to decide.
		var msg = '';
		if (this._SystemInfo.UseSSL) {
			error = zenPage.InitialSSLverification(this.MirrorName,this._SystemInfo.BaseDirectory,this._SystemInfo.ipaddr,this._SystemInfo.port);
			if (error != '') {
				var msg = $$$Text("SSL verification found following problems: ") + "\n";
				if (error.charAt(0) == '0') {
					msg += error.slice(1) + '\n\n' + $$$Text("There is real certificate error, you need to fix it before you can join the mirror.");
					alert(msg);
					return false;
				}
				msg += error.slice(1) + '\n\n';
			}
		}
		msg += (memberType === 0) ? $$$Text("Are you sure you want to join Mirror Set '%1' as a failover member?") : $$$Text("Are you sure you want to join Mirror Set '%1' as an async member?");
		var ok = confirm(msg.replace("%1",this.MirrorName));
		if (!ok) {
			return false;	
		}
		var systemName = zen('Ourname').getValue();
		var MirrorInfo = new zenProxy();
		MirrorInfo.UseSSL = json.UseSSL;
		MirrorInfo.EncryptCommunication = 0  //json.EncryptCommunication;
		MirrorInfo.AgentAddress = json.AgentAddress;
		MirrorInfo.ECPAddress = json.SuperServer;
		MirrorInfo.MirrorAddress = (zen('MirrorAddress').getValue()) ? zen('MirrorAddress').getValue() : json.MirrorAddress;
		MirrorInfo.idxnum = (zen('idxnum').getValue()) ? zen('idxnum').getValue() : json.idxnum;
		MirrorInfo.VirtualAddress = json.VirtualAddress;
		MirrorInfo.VirtualAddressInterface = (this._SystemInfo.iVirt) ? this._SystemInfo.iVirt : this._SystemInfo.VirtualAddressInterface;
		//pMirrorName, pSystemName, pMemberType, pAsyncMemberType, pMirrorInfo	
		var result = this.SaveData(this.MirrorName, systemName, memberType, asyncMemberType, MirrorInfo);
		abort = 0;
		// if save returned an error, display it and then still trigger the refresh of the loading page because things could be changed during save.
		if (result.ok != 1) {
			alert(result.ErrorMessage);
		}
		return true;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return !abort;
}

/// Check all mirroring fields and display all error messages.
ClientMethod validateBeforeSave() [ Language = javascript ]
{
	this._hasError = [];
	this.resetMsg();
	try {
		this.validateOurname();
		this.validateIPFormat();
		this.validateSuperServer();
		if (this._SystemInfo.AsyncMemberType === 0) {
			this.validateAgent();
		}
		var iVirt = zen('VirtualAddressInterface').getValue();
		// if VIP group is shown and no VIP selected, then log error
		if (!zen('groupVIP').getProperty('hidden')) {
			if (iVirt === '') {
				var msg = $$$Text("Select network interface for mirror virtual network address.");
				this._hasError.push(msg);
			} else {
				if (this._SystemInfo.hpsun) {
					/// make sure the Vitural address and index for hpsun is checked properly
					this.validateLogicalIndex();
				} else {
					this._SystemInfo.iVirt = iVirt;	
				}
			}
		}
		if (this._hasError.length>0) {
			var msg = "";
			for (i=0; i<this._hasError.length; i++) {
				msg += " " + this._hasError[i];
			}
			this.showMsg(msg,1);
			return;
		} else {
		}
		return;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return;
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

ClassMethod SaveData(pMirrorName, pSystemName, pMemberType, pAsyncMemberType, pMirrorInfo As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Try {
		Set tProxy = ##class(%ZEN.proxyObject).%New()
		Set tProxy.ok = 1
		Set tProxy.ErrorMessage = ""
		//Set MirrorInfo("UseSSL") = pMirrorInfo.UseSSL
		//Set MirrorInfo("VirtualAddress") = pMirrorInfo.VirtualAddress
		Set MirrorInfo("EncryptCommunication") = pMirrorInfo.EncryptCommunication
		Set MirrorInfo("VirtualAddressInterface") = pMirrorInfo.VirtualAddressInterface
		Set MirrorInfo("AgentAddress") = pMirrorInfo.AgentAddress
		Set MirrorInfo("ECPAddress") = pMirrorInfo.ECPAddress
		Set MirrorInfo("MirrorAddress") = pMirrorInfo.MirrorAddress
		//Set MirrorInfo("idxnum") = pMirrorInfo.idxnum
		Set tSC = ##class(SYS.MirrorConfiguration).ResetAndAdd(pMirrorName, pSystemName, pMemberType, pAsyncMemberType, .MirrorInfo)
		If $$$ISERR(tSC) {
			Set tProxy.ErrorMessage = $System.Status.GetErrorText(tSC)
			Set tProxy.ok = 0
		}
		Quit
	} Catch Error {
		Set Message = ..EscapeHTML($System.Status.GetErrorText(Error.AsStatus()))
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = Message
	}
	Quit tProxy
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$FormatText($$$Text("Join Mirror '%1' as New Member"), $zconvert(%page.MirrorName,"O","HTML"))
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Set tSC = ..GetSSLLink(.linkSSL, .labelSSL)
	If $$$ISERR(tSC) {
		Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
	}
	Set %page.SSLLink = linkSSL

	Quit tSC
}

/// Method to get validation info
Method GetSystemInfo(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
#define DEFSSPORT 1972

	Set tSC = $$$OK
	Set pObject = ##class(%ZEN.proxyObject).%New()
	Try {
		Set tMirrorName = pParms("parmMirrorName")
		Set tPrimaryId = pParms("parmPrimaryId")
		If ((tMirrorName = "") || (tPrimaryId = "")) {
			Set ..InitialMessage = $S(tMirrorName="":$$$TextHTML("Mirror Name is null!"),1:$$$TextHTML("Primary Id is null!"))
			Quit
		}
		Set info = $G(^SYS("MIRRORSET",tMirrorName,"Member",tPrimaryId))
		Set pObject.InstanceName = $LG(info,1)  ; the mirror member name, it's not instance name in the remote member
		Set pObject.BaseDirectory = $LG(info,6) ; base directory for current primary (base directory of the instance, it can replace instance name as we assume if a value passed to InstanceLookup failed we assume it is already a base directory path)
		Set pObject.agentaddr = $LG(info,5)
		Set pObject.ipaddr = $P(pObject.agentaddr,"|")
		Set pObject.port = $P(pObject.agentaddr,"|",2)
		Set tObj = ##class(Config.Mirrors).Open(tMirrorName,,,.status)
		If $$$ISERR(status) {
			Set ..InitialMessage = $$$FormatText($$$Text("Failed to open the mirror configuration for '%1'. Error: %2"), tMirrorName, $SYSTEM.Status.GetErrorText(status))
			Quit
		}
		Set pObject.UseSSL = tObj.UseSSL
		Set sslc = ##class(Security.SSLConfigs).%OpenId("%MirrorClient",,.status)
		Set ssls = ##class(Security.SSLConfigs).%OpenId("%MirrorServer",,.status)
		Set pObject.SSLConfigured = (($isobject(sslc))||($isobject(ssls)))
		Set rc=##class(SYS.Mirror).CheckISCAgent()
		Set pObject.ISCAgentRunning = $$$ISOK(rc)
		If '$$$ISOK(rc) Set pObject.ISCAgentError = $SYSTEM.Status.GetErrorText(rc)
		If tObj.UseSSL {
			Set pObject.UseSSLMessage = $$$TextHTML("After adding this instance to the mirror, you must authorize it as a mirror member on the primary failover member, using the Edit Mirror page or ^MIRROR > Mirror Configuration > Authorize/reject pending new members.")
		}
		Set pObject.IsAsync = ##class(Config.MirrorMember).isAsyncMember()
		Set pObject.DefaultSystemName = $$$GetDefaultSystemName
		Set pObject.DefaultAddress = $System.INetInfo.LocalHostName()
		Set pObject.MirrorAddress = pObject.DefaultAddress
		Set pObject.SuperServer = pObject.DefaultAddress
		Set pObject.AgentAddress = ##class(SYS.Agent).GetApplicationInterface()
		If ((pObject.AgentAddress = "") || (pObject.AgentAddress = "*")) {
			Set pObject.AgentAddress = pObject.SuperServer
		}
		Set pObject.VirtualAddress = tObj.VirtualAddress
		If tObj.VirtualAddress '= "" {
			Set mirrorVIP = tObj.VirtualAddress
			Set tList = ##class(%SYSTEM.INetInfo).GetListOfConfiguredInterfaces(0,mirrorVIP)
	 		If tList = "" {
		 		Set pObject.VIPAddressMessage = $$$Text("You cannot add this instance as a failover member because it is not on the same subnet as the existing failover member. Please confirm the virtual IP address and subnet mask.")
		 		Set pObject.VIPAddressMessageAsyncDR = $$$Text("This instance is not on the same subnet as the failover member(s), which is recommended for DR async members. Please confirm the virtual IP address and subnet mask.")
	 		} Else {
		 		Set pObject.VIPValueList = ""
		 		Set pObject.VIPDisplayList = ""
	 			Set tItem = 1
		 		While $lg(tList,tItem) '= "" {
	 				Set text = $lg($lg(tList,tItem),1)
	 				Set pObject.VIPDisplayList = pObject.VIPDisplayList _ $S(tItem>1:",",1:"") _ text
	 				Set tItem = tItem + 1		
 				}
 				Set pObject.VIPValueList = pObject.VIPDisplayList	 		
	 		}
		}
		Set os = ##class(SYS.MirrorConfiguration).GetOS()
		Set hpsun = ((",HP-UX,")[(","_os_","))
		Set pObject.OS = os
		Set pObject.hpsun = hpsun
		Set pObject.DEFSSPORT = $$$DEFSSPORT
		Set pObject.DEFAGENTPORT = $$$DEFAGENTPORT
		// Get a list of existing names for checking ourname for uniqueness later
		Set rs = ##class(%ResultSet).%New("Config.MapMirrors:List")
		If $IsObject(rs) {
			Do rs.Execute(tMirrorName,"*","",0,0)
			While rs.Next() {
				Set pObject.ExistingNames = pObject.ExistingNames _ rs.GetData(1) _","
			}
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod ValidateMemberName(pName) As %String [ ZenMethod ]
{
	Set tReturn = ""
	Set tSC = ##class(Config.MirrorMember).ValidateMemberName(pName)
	If $$$ISERR(tSC) {
		Set tReturn = $System.Status.GetErrorText(tSC)_" "
	}
	Quit tReturn
}

ClassMethod ValidateVI(pIdxnum, pOS, pHpsun, pVirt) As %String [ ZenMethod ]
{
	Try {
		Set tReturn = ""
		If pIdxnum'?.N {
			Set tReturn = $$$TextHTML("Logical index number must be a integer value. ")
			Quit
		}
		If pOS]"" { ;This is some form of UNIX/Linux 
			Set ifaceExists = $System.INetInfo.CheckInterfaceExist(pVirt,1) ;Ask for exact match for the interface - don't strip out the virtual part...
	
			If ($e(pVirt,1,2)="lo") {  ;On UNIX platforms, interfaces that start with lo are *typically* loopback interfaces. We don't want these...
				Set tReturn = $$$TextHTML("This interface appears to be a loopback interface. Please enter an appropriate non-loopback interface.")
				Quit
			}
	 		If pHpsun { ;For HP-UX and SunOS platforms, we require virtual (logical) interfaces, so we have to check to see if the base (physical) one exists...
		 		Set tMsg = $$$Text("Please enter an appropriate logical interface that does not already exist (it will be created when assigining the Virtual IP.")
		 		If ifaceExists {
		 			Set tReturn = $$$FormatText($$$Text("This platform requires a virtual (logical) interface. The interface you entered (%1) already exists. "), pVirt)
		 			Set tReturn = tReturn _ tMsg	
					Quit
		 		}
		 		If $p(pVirt,":",2)="" {
					Set tReturn = tMsg
					Quit
		 		}
			 	If '$System.INetInfo.CheckInterfaceExist($p(pVirt,":")) {
					Set tReturn = $$$FormatText($$$Text("Physical interface (%1) does not exist."),$p(pVirt,":"))
					Set tReturn = tReturn _ $$$TextHTML("The base physical interface must exist for a virtual interface to be added on.")
					Quit
			 	}
			} Else { ;Non HP-UX, non SunOS platforms, so the entered interface must already exist for it to be selected
				If 'ifaceExists {
			 		Set tReturn = $$$FormatText($$$Text("This platform requires a physical interface, and it must already exists. The interface you entered (%1) does not exist."),pVirt)
					Quit
				}
		 	}
		} Else {
		 	If '$System.INetInfo.CheckInterfaceExist(pVirt) {
		 		Set tReturn = $$$FormatText($$$Text("Interface (%1) does not exist."),pVirt)
				Quit
			}
		}		
	} Catch ex {
		Set tReturn = ex.AsStatus()
	}
	Quit tReturn
}

/// pAddressType = "default" or "super" or "agent"
ClassMethod IsIPFormatValid(pAddress, pAddressType) As %String [ ZenMethod ]
{
	Set tReturn = ""
	Set type = ""
	If ##class(SYS.MirrorConfiguration).IsIPFormatValid(pAddress,.type) {
		If type = "HOST" {
			//Set ipToUse = $$convHostToIP^MIRROR(pAddress)
			If $zcvt(pAddress,"U") = $zcvt($$$LOCALHOST,"U") {
				Set pAddress = "localhost"  ;force to localhost to get loopback address if the machine name is passed in
			} 
			Set ipToUse = $$$HOST2IP(pAddress)
			If (ipToUse = "") {
				Set tReturn = $$$FormatText($$$Text("Error: Host '%1' does not resolve to IP address. "),pAddress)	
				Quit tReturn
			}
		} Else {
			Set ipToUse = pAddress
		}
		If ('$System.INetInfo.CheckAddressExist(ipToUse)) {
			Set ipType = $Case(pAddressType,"default":"Mirror Private","super":"SuperServer",:"Agent")
			Set tReturn = $$$FormatText($$$Text("IP address '%1' does not exist. Cannot use it as the %2 address. "), ipToUse, ipType)
		}
	} Else {
		Set tReturn = $$$Text("Invalid IP address")
	}
	Quit tReturn
}

ClassMethod RetrieveMirrorConfig(pMirname, pIpaddr, pPort, pInstanceName) As %String [ ZenMethod ]
{
	Set tReturn = ""
	Set tObj = ##class(SYS.MirrorConfiguration).RetrieveMirrorConfig(pMirname, pIpaddr, pPort, pInstanceName, .status)
	Quit tReturn
}

}
