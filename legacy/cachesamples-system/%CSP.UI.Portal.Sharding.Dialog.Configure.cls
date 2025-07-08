/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.Sharding.Dialog.Configure Extends (%CSP.Portal.standardDialog, %CSP.UI.Portal.Sharding.Utils)
{

Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Sharding.Dialog.Configure.zen";

/// Displayed name of this page.
Parameter PAGENAME = "Node-Level-Configure";

Parameter RESOURCE = "%Admin_Secure";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property PageMessage As %String;

XData Style
{
<style type="text/css">
.normal {
	padding-top:6px;
}
.pL20 {
	padding-left: 20px;
}
.pR20 {
	padding-right: 20px;
}
.optionTitle {
	font-size: 16px;
	font-weight: bold;	
}
.radGroupSub {
	padding-left: 22px;	
}
.zenLabel {
	font-weight: normal;
}
.lm20 {
	padding-left: 20px;	
}
</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">

<group enclosingStyle="margin:10px;">

<spacer height="10"/>
<label label="Select an action" labelClass="optionTitle" />
<spacer height="4"/>
<label id="idRespond" value=""/>

<radioButton id="rad1" name="radType" caption="Initialize a new sharded cluster on this instance" 
optionValue="Initialize" onclick="zenPage.changeOption(1);"/>

<radioButton id="rad2" name="radType" caption="Add this instance to an existing sharded cluster" 
optionValue="Add" onclick="zenPage.changeOption(2);"/>

<spacer height="10"/>
<fieldSet id="option1" label="Initialize a new sharded cluster on this instance" labelClass="pL20 optionTitle" enclosingClass="pL20 pR20" hidden="true">
 <group enclosingStyle="margin:10px;" labelPosition="left" label="(* indicates required field)" cellStyle="padding:6px;">
 <select id="selClusterNamespace" label="Cluster namespace *" 
title=""
showEmpty="false"
/>

<select id="selMasterNamespace" label="Master namespace *" 
title=""
showEmpty="false"
/>

<text id="txtHostName" label="Override hostname with IP address" size="30" autocomplete="false"/>

<checkbox id="chkMirror" caption="Enable mirroring" captionClass="zenLabel" onchange="zen('groupMirror').setHidden(!zenThis.value);"/>
<fieldSet id="groupMirror" hidden="true" containerStyle="font-size:0.8em;padding-left:4px;padding-right:4px;" labelPosition="left" cellStyle="padding:4px;">
<text id="txtArbiterIP" label="Arbiter" hint="host" size="20" autocomplete="false"/>
<text id="txtArbiterPort" hint="port" size="8" autocomplete="false"/>
</fieldSet>
 
</group>
</fieldSet>

<fieldSet id="option2" label="Add this instance to an existing sharded cluster" labelClass="pL20 optionTitle" enclosingClass="pL20 pR20" hidden="true">
 <group enclosingStyle="margin:10px;" labelPosition="left" label="(* indicates required field)" cellStyle="padding:6px;">
<text id="txtClusterURL" label="Cluster URL *" size="60" hint="Cluster node URL is of the form IRIS://hostname_or_IPaddress:IRIS_SuperServer_port"/>
<select id="selRole21" label="Role *" valueList="data,compute" value="" onchange="zenPage.changeRole(zenThis.value);" hint=""/>
<text id="txtHostName2" label="Override hostname with IP address" size="30" autocomplete="false"/>
<checkbox id="chkCheckMirror" caption="Mirrored cluster" captionClass="zenLabel" onchange="zen('groupMirror2').setHidden(!zenThis.value);"/>
<fieldSet id="groupMirror2" hidden="true" containerStyle="font-size:0.8em;padding-left:4px;padding-right:4px;" labelPosition="left" cellStyle="padding:4px;">
<select id="selRole22" label="Mirror role *" valueList="primary,backup,drasync" displayList="new primary,backup failover,DR async" value="" hint=""/>
<text id="txtArbiterIP2" label="Arbiter" hint="host" size="20" autocomplete="false"/>
<text id="txtArbiterPort2" hint="port" size="8" autocomplete="false"/>
</fieldSet>
</group>
</fieldSet>

</group>
</pane>
}

ClientMethod changeOption(newOption) [ Language = javascript ]
{
	this.resetMsg();
	var id = 'option' + parseInt(newOption);
	for (i=1;i<3;i++) {
		zen('option'+i).setHidden(i!=newOption);
	}
}

/// For option2, user changed the Role. If Role is "computed" then the checkMirror becomes disabled and the fields under it should disappear.
/// If Role is "data" then checkMirror becomes enabled. If user has previously checked it then now the fields with the previouly entered values are shown.
ClientMethod changeRole(newOption) [ Language = javascript ]
{
	if (newOption=='compute') {
		zen('chkCheckMirror').setDisabled(true);
		zen('groupMirror2').setHidden(true);
	} else {
		zen('chkCheckMirror').setDisabled(false);
		// if user previously checked the Mirror then show the group under it.
		if (zen('chkCheckMirror').getValue()) {
			zen('groupMirror2').setHidden(false);
		}
	}
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Set ShardInfo = 1
	Set tCnt = ##class(%CSP.Util.SMNavigatorPane).GetAllNamespaces(.Namespaces, .ShardInfo)
	Set valueList = ""
	Set displayList = ""
	Set (IRISCLUSTERExists,IRISDMExists) = 0
	For i=1:1:tCnt {
		set sName = Namespaces(i)
		If sName '= "%SYS" {
			Set sType = $lg($G(ShardInfo(i)),1)
			Set:sName="IRISCLUSTER" IRISCLUSTERExists = 1
			Set:sName="IRISDM" IRISDMExists = 1
			If ((sType'="DS") && (sType'="DM")) { // skip namespaces part of existing setup
				Set valueList = valueList _ "," _ Namespaces(i)
				Set displayList = displayList _ "," _ Namespaces(i) _ " " _ $lg($G(ShardInfo(i)),2)
			}
		}
	}
	Set ..%GetComponentById("selClusterNamespace").valueList = $S('IRISCLUSTERExists:"IRISCLUSTER",1:"")_valueList
	Set ..%GetComponentById("selClusterNamespace").displayList = $S('IRISCLUSTERExists:"IRISCLUSTER ("_$$$Text("new")_")",1:"")_displayList
	Set ..%GetComponentById("selMasterNamespace").valueList = $S('IRISCLUSTERExists:"IRISDM",1:"")_valueList
	Set ..%GetComponentById("selMasterNamespace").displayList = $S('IRISCLUSTERExists:"IRISDM ("_$$$Text("new")_")",1:"")_displayList
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Configure Node-Level Cluster")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

Method DrawAbortError(seed As %String) As %Status
{
	If seed '= "" {
		&html<<div class="ErrorBox"><pre>#(..EscapeHTML(seed))#</pre></div>>
	}
	Quit $$$OK
}

Method DrawResult(seed As %String) As %Status
{
	If seed '= "" {
		&html<<pre>#(..EscapeHTML(seed))#</pre>>
	}
	Quit $$$OK
}

/// If creating a new view, make sure that the view name is not empty.
ClientMethod validate(proxy) [ Language = javascript ]
{
	var pass = true;
	switch (proxy.nodeType) {
		case 'Add':
			if (!this.validateRequired(zen('txtClusterURL'),pass,"S")) pass = false;
			if (!this.validateRequired(zen('selRole21'),pass,"S")) pass = false;
			if (proxy.ClusterMirror) {
				if (!this.validateRequired(zen('selRole22'),pass,"S")) pass = false;
			}
			break;
	}
	return pass;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var ok = 1;
		this.resetMsg();
		var proxy = new zenProxy();
		proxy.nodeType = zen("rad1").getValue();
		switch (proxy.nodeType) {
			case 'Initialize':
				proxy.ClusterNamespace = zen("selClusterNamespace").getValue();
				proxy.MasterNamespace = zen("selMasterNamespace").getValue();
				proxy.HostIPAddress = zen("txtHostName").getValue();
				proxy.EnableMirroring = zen("chkMirror").getValue() ? 1 : 0;
				proxy.ArbiterIP = zen("txtArbiterIP").getValue();
				proxy.ArbiterPort = zen("txtArbiterPort").getValue();
				break;
			case 'Add':
				proxy.ClusterURL = zen('txtClusterURL').getValue();
				proxy.Role = zen("selRole21").getValue();
				proxy.HostName2 = zen("txtHostName2").getValue();
				proxy.ClusterMirror = zen("chkCheckMirror").getValue() ? 1 : 0;
				proxy.Role2 = zen("selRole22").getValue();
				proxy.ArbiterIP2 = zen("txtArbiterIP2").getValue();
				proxy.ArbiterPort2 = zen("txtArbiterPort2").getValue();
				break;
		}
		if (!this.validate(proxy)) {
			this.showMsg($$$Text("Please enter values for required fields."),1);
			if (this.FirstFailed && zen(this.FirstFailed)) {
				zen(this.FirstFailed).focus();
			}
			return false;
		}
		var proxy = this.SaveData(proxy);
		if (proxy.error != '') {
			this.showMsg(proxy.error,1);
			ok = 0;
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	if (ok == 1) {
		return true;
	}
	return false;
}

/// Start background job to cleanup a selected directory
ClassMethod SaveData(proxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		Set tProxy = ##class(%ZEN.proxyObject).%New()
		Set tProxy.error = ""
		Set tProxy.message = ""
		If (proxy.nodeType = "Initialize") {
			If proxy.EnableMirroring = 0 {
				Set tSC = $SYSTEM.Cluster.Initialize(proxy.ClusterNamespace,proxy.MasterNamespace,"",proxy.HostIPAddress)
			} Else {
				Set ArbiterPort = $S(proxy.ArbiterIP="":0,1:proxy.ArbiterPort)
				Set tSC = $SYSTEM.Cluster.InitializeMirrored(proxy.ClusterNamespace,proxy.MasterNamespace,"",proxy.HostIPAddress,proxy.ArbiterIP,ArbiterPort)
			}
		} ElseIf proxy.nodeType = "Add" {
			// if Role = data and is not cluster mirrored:
			If proxy.Role = "data" {
				If proxy.ClusterMirror = 0 {
					Set tSC = $SYSTEM.Cluster.AttachAsDataNode(proxy.ClusterURL,proxy.HostName2)
				} Else {
					Set ArbiterPort = $S(proxy.ArbiterIP2="":0,1:proxy.ArbiterPort2)
					Set tSC = $SYSTEM.Cluster.AttachAsMirroredNode(proxy.ClusterURL,proxy.Role2,proxy.HostName2,proxy.ArbiterIP2,ArbiterPort)
				}
			} ElseIf proxy.Role = "compute" {
				Set tSC = $SYSTEM.Cluster.AttachAsComputeNode(proxy.ClusterURL,proxy.HostName2)
			}		
		}		
		If $$$ISERR(tSC) {
			Set tProxy.error = ..EscapeHTML($System.Status.GetErrorText(tSC))
		}
	} While (0)
Done
	If $$$ISERR(tSC) {
		Set tProxy.error = ..EscapeHTML($System.Status.GetErrorText(tSC))
	}
	Quit tProxy
Trap
	Set $ZT=""
	Set tProxy.error =  ..EscapeHTML("Error occurred in SaveData: "_$ZE)
	Quit tProxy
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

}
