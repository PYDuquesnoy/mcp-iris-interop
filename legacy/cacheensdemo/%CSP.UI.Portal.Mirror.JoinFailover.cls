/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Join Failover
Class %CSP.UI.Portal.Mirror.JoinFailover Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.Mirror.Utils) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

/// Displayed name of this page.
Parameter PAGENAME = "Join Mirror as Failover";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Mirror.JoinFailover.zen";

Parameter HELPADDRESS = "Home,Configuration,Join Mirror as Failover";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property UseSSL As %ZEN.Datatype.boolean;

Property VirtualAddress As %ZEN.Datatype.string;

Property OtherMemberName As %ZEN.Datatype.string;

Property OtherMemberECP As %ZEN.Datatype.string;

Property OtherMemberPort As %ZEN.Datatype.integer;

Property OtherMemberPrivateAddress As %ZEN.Datatype.string;

Property OtherMemberAgentAddress As %ZEN.Datatype.string;

XData Style
{
<style type="text/css">
tr.infoRow td {
	padding:0 6px 3px 0;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<label id="errmsg" hidden="true" enclosingClass="ErrorBox"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<group id="Page1">
<fieldSet label="Mirror Information" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;">
<group labelPosition="left">
<text id="MirrorName" label="Mirror Name" size="20" maxlength="15" hint="Required." onchange="zenPage.cleanInput(zenThis);zenPage.doModified();"/>
</group>
<fieldSet labelPosition="left" label="Other Mirror Failover Member's Info" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;">
<text id="AgentAddress" label="Agent Address on Other System" size="32" hint="Required." onchange="zenPage.doModified();"/>
<text id="AgentPort" label="Agent Port" size="5" hint="Required." onchange="zenPage.doModified();"/>
<text id="InstanceName" label="InterSystems IRIS Instance Name" size="32" hint="Required." onchange="zenPage.doModified();"/>
</fieldSet>
</fieldSet>
<spacer height="5px"/>
<label label="Provide required information then click [Next] to retrieve data" containerStyle="padding-left:4px;"/>
</group>
<group id="Page2" hidden="true">
<fieldSet label="Mirror Failover Member Information" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;">
<html id="MemberInfoTable" OnDrawContent="DrawMemberInfoTable"/>
</fieldSet>
<link caption="Advanced Settings" onclick="zenPage.toggle('AdvancedContainer');return false;" href="#" enclosingClass="smpLink"/>
<fieldSet id="AdvancedContainer" hidden="true" labelPosition="left" label="Mirror Settings" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;">
<label id="QOSTimeout" label="Quality of Service Timeout (msec)" controlClass="normal"/>
</fieldSet>
</group>
</group>
</form>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.hideCommandButton("btnSave");
	this.hideCommandButton("btnClear");
	if (zen("MirrorName")) {
		zen("MirrorName").focus();
	}
	if (this.DisableSave) {
		this.disableCommandButton("btnSave");
	}
}

/// Overriding the template function because the elements are not zen on this page
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if ((popupName == "SSL") && (action == "ok")) {
			this.SSLDefined = 1;
			document.getElementById("idWarnSSL").style.display = "none";
			document.getElementById("idNotifySSL").style.display = "block";
			document.getElementById("linkSSL").innerHTML = $$$Text("Edit SSL/TLS");
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

ClientMethod goToNextPage() [ Language = javascript ]
{
	// refreshContents of the read-only checkbox so the display is correct
	zen("MemberInfoTable").refreshContents(true);
	zen("Page1").setHidden(true);
	zen("Page2").setHidden(false);
	this.hideCommandButton("btnConnect");
	this.showCommandButton("btnSave");
	this.showCommandButton("btnClear");
}

ClientMethod doClear() [ Language = javascript ]
{
	this.setModified(false);
	var url = '%25CSP.UI.Portal.Mirror.JoinFailover.zen';
	zenPage.gotoPage(url);
}

ClientMethod doConnect() [ Language = javascript ]
{
	this.resetMsg();

	var ok = this.validateConnect();
	if (!ok) {
		this.afterValidate();
		return;
	}

	var proxy = new zenProxy();
	
	proxy.MirrorName = zen("MirrorName").getValue();
	proxy.AgentAddress = zen("AgentAddress").getValue();
	proxy.AgentPort = zen("AgentPort").getValue();
	proxy.InstanceName = zen("InstanceName").getValue();

	var result = this.Connect(proxy);

	if (result.ok == 1) {
		this.goToNextPage();
	} else {
		this.showMsg(result.ErrorMessage,1);
	}
}

ClientMethod doSave() [ Language = javascript ]
{
	this.resetMsg();
	var proxy = new zenProxy();
	
	proxy.MirrorName = zen("MirrorName").getValue();
	proxy.AgentAddress = zen("AgentAddress").getValue();
	proxy.AgentPort = zen("AgentPort").getValue();
	proxy.InstanceName = zen("InstanceName").getValue();
	
	proxy.ThisMemberName = document.getElementById("ThisMemberName").value;
	proxy.ThisMemberECP = document.getElementById("ThisMemberECP").value;
	proxy.ThisMemberPort = document.getElementById("ThisMemberPort").value;
	proxy.ThisMemberMirrorAddress = document.getElementById("ThisMemberPrivateAddress").value;
	proxy.ThisMemberAgentAddress = document.getElementById("ThisMemberAgentAddress").value;
	proxy.VirtualAddressInterface = document.getElementById("VirtualAddressInterface").value;
	
	proxy.OtherMemberName = zenPage.OtherMemberName;
	proxy.VirtualAddress = zenPage.VirtualAddress;
	proxy.UseSSL = zenPage.UseSSL;
	proxy.SSLDefined = zenPage.SSLDefined;
	
	var ok = this.validateSave(proxy);
	if (!ok) return;

	var result = this.SaveData(proxy);
	if (result && (result.ok == 1) && proxy.UseSSL) {
		alert($$$Text("Don't forget to add this node to the configuration on the primary member."));
	}
	this.afterSave(result);
}

ClientMethod validateConnect() As %Boolean [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var pass = true;
	try {
		if (!this.validateRequired(zen('MirrorName'),pass,"S")) pass = false;
		if (!this.validateRequired(zen('AgentAddress'),pass,"S")) pass = false;
		if (!this.validateRequired(zen('AgentPort'),pass,"N")) pass = false;
		if (!this.validateRequired(zen('InstanceName'),pass,"S")) pass = false;
	} catch (ex) {
		alert("Error: " + ex);	
	}
	zenSynchronousMode = oldSynchronousMode;
	
	return pass;
}

ClientMethod validateSave(proxy) [ Language = javascript ]
{
	var pass = true;
	var msg = "";
	
	if (zenTrim(proxy.ThisMemberName) == '') {
		if (pass) this.FirstFailed = "ThisMemberName";
		document.getElementById("ThisMemberName").className = "zenInvalid";
		pass = false;
	} else {
		document.getElementById("ThisMemberName").className = "";
		
		if (proxy.ThisMemberName == proxy.OtherMemberName) {
			if (pass) this.FirstFailed = "ThisMemberName";
			document.getElementById("ThisMemberName").className = "zenInvalid";
			msg = $$$Text("Cannot have same name for both members.");
			pass = false;
		}
	}
	
	if (zenTrim(proxy.ThisMemberECP) == '') {
		if (pass) this.FirstFailed = "ThisMemberECP";
		document.getElementById("ThisMemberECP").className = "zenInvalid";
		pass = false;
	} else {
		document.getElementById("ThisMemberECP").className = "";
	}
	
	if (zenTrim(proxy.ThisMemberPort) == '') {
		if (pass) this.FirstFailed = "ThisMemberPort";
		document.getElementById("ThisMemberPort").className = "zenInvalid";
		pass = false;
	} else {
		document.getElementById("ThisMemberPort").className = "";
	}
	
	if (proxy.VirtualAddress != "") {
		if (zenTrim(proxy.VirtualAddressInterface) == '') {
			if (pass) this.FirstFailed = "VIPNetworkInterface";
			document.getElementById("VIPNetworkInterface").className = "zenInvalid";
			pass = false;
		} else {
			document.getElementById("VIPNetworkInterface").className = "";
		}
	}
	
	if (zenTrim(proxy.ThisMemberMirrorAddress) == '') {
		if (pass) this.FirstFailed = "ThisMemberPrivateAddress";
		document.getElementById("ThisMemberPrivateAddress").className = "zenInvalid";
		pass = false;
	} else {
		document.getElementById("ThisMemberPrivateAddress").className = "";
	}
	
	if (zenTrim(proxy.ThisMemberAgentAddress) == '') {
		if (pass) this.FirstFailed = "ThisMemberAgentAddress";
		document.getElementById("ThisMemberAgentAddress").className = "zenInvalid";
		pass = false;
	} else {
		document.getElementById("ThisMemberAgentAddress").className = "";
	}
	
	if (pass && proxy.UseSSL) {
		if (!proxy.SSLDefined) {
			msg = $$$Text("Please click the 'Set up SSL/TLS' link to set up SSL/TLS for this system.");
			pass = false;
		} else {
			var sc = zenPage.InitialSSLverification(proxy.MirrorName,proxy.InstanceName,proxy.AgentAddress,proxy.AgentPort);
			if (!sc || !sc.length) {
				pass = true;
			} else {
				var msgx = $$$Text("SSL verification found following problems:") + "\n\n" + sc.slice(1) + "\n\n";
				if (sc.charAt(0) == '0') {
					alert(msgx + $$$Text("There is real certificate error, you need to fix it before you can join the mirror."));
					pass = false;
				} else {
					pass = confirm(msgx + $$$Text("Continue to join mirror?"))
				}
				msg = $$$Text("Joining mirror is aborted.")
			}
		}
	}
	
	if (!pass) {
		if (msg == "") {
			msg = this.ValidationErrorMsg;
		}
		this.showMsg(msg,1);
		if (this.FirstFailed) {
			var field = this.FirstFailed;
			document.getElementById(field).focus();
		}
	}
	
	return pass;
}

///  Save general association data to server.<br/>
///  Returns proxy.ok = 1 (save successful) or 0 (error occurred)<br/>
///  proxy.ErrorMessage (save failed and display this error message).
///  If proxy.ok is 1 and no messages returned then we return to SMP home.
Method Connect(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 1

	Try {
		Set MirrorConfig = ##class(SYS.MirrorConfiguration).RetrieveMirrorConfig(pProxy.MirrorName,pProxy.AgentAddress,pProxy.AgentPort,pProxy.InstanceName,.tSC,,,.EMSManaged)
		If '$IsObject(MirrorConfig) {
			Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
		If EMSManaged {
			Set tSC = $$$ERROR($$$GeneralError,$$$TextHTML("Selected mirror is managed by Enterprise Manager, use Enterprise Manager to add this system as a mirror member."))
			Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
		Set %page.UseSSL = MirrorConfig.UseSSL
		Set ..%GetComponentById("QOSTimeout").value = MirrorConfig.QOSTimeout
		Set %page.VirtualAddress = MirrorConfig.VirtualAddress

		Set MapMirrorsConfig = ##class(SYS.MirrorConfiguration).RetrieveMirrorMemberConfig(pProxy.MirrorName,pProxy.AgentAddress,pProxy.AgentPort,pProxy.InstanceName,.tSC)
		If '$IsObject(MapMirrorsConfig) {
			Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
		Set %page.OtherMemberName = MapMirrorsConfig.Name
		Set %page.OtherMemberECP = MapMirrorsConfig.ECPAddress
		Set %page.OtherMemberPort = MapMirrorsConfig.AgentPort
		Set %page.OtherMemberPrivateAddress = MapMirrorsConfig.MirrorAddress
		#;SML2315
		Set %page.OtherMemberAgentAddress = MapMirrorsConfig.AgentAddress
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

Method DrawMemberInfoTable(pSeed As %String) As %Status
{
	Set ThisText = $$$TextHTML("This System")
	Set OtherText = $$$TextHTML("Other System")
	Set NameText = $$$TextHTML("Mirror Member Name")
	Set SuperserverText = $$$TextHTML("Superserver Address")
	Set AgentPortText = $$$TextHTML("Agent Port")
	Set SSLText = $$$TextHTML("SSL/TLS Requirement")
	Set PrivateAddressText = $$$TextHTML("Mirror Private Address")
	#;SML2315
	Set AgentAddressText = $$$TextHTML("Agent Address")
	#;SML2527+ ; Setup old value of addresses and member name.
	Set %page.OldMemberName=$$$GetDefaultSystemName
	Set (%page.OldPrivateAddr,%page.OldECPAddr)=$System.INetInfo.LocalHostName()
	Set %page.OldAgentAddr=$s(##class(SYS.Agent).GetApplicationInterface()=""||(##class(SYS.Agent).GetApplicationInterface()="*"):$System.INetInfo.LocalHostName(),1:##class(SYS.Agent).GetApplicationInterface())
	#;SML2527-
	
	If (%page.UseSSL = 0) {
		Set SSLContents = $$$TextHTML("The mirror does not require SSL/TLS.")
	} Else {
		Set SSLContents = ""
		Set notifyDisplay = $Select(%page.SSLDefined:"block",1:"none")
		Set warnDisplay = $Select('%page.SSLDefined:"block",1:"none")

		Set SSLContents = SSLContents_"<div id=""idNotifySSL"" class=""normal"" style=""display:"_notifyDisplay_""">"
		Set SSLContents = SSLContents_$$$TextHTML("The mirror requires SSL/TLS.")
		Set SSLContents = SSLContents_"</div>"

		Set SSLContents = SSLContents_"<div id=""idWarnSSL"" class=""rednote"" style=""display:"_warnDisplay_""">"
		Set SSLContents = SSLContents_$$$TextHTML("The mirror requires SSL/TLS. To join the mirror you must first set up SSL/TLS for this system.")
		Set SSLContents = SSLContents_"</div>"

		Set tSC = ..GetSSLLink(.linkSSL, .labelSSL)
		If $$$ISERR(tSC) {
			Do ..DisplayError(tSC)
			Quit $$$OK
		}
		Set %page.SSLLink = linkSSL
		Set SSLContents = SSLContents_"<span class=""smpLink""><a id=""linkSSL"" href=""#"" onclick=""zenPage.openSSL();"" class=""link"" style=""font-size:1em;"">"
		Set SSLContents = SSLContents_labelSSL_"</a></span>"
	}

	&html<<table width="100%" cellspacing="3px">
			<tr>
				<td>&nbsp;</td>
				<td class="normal" style="text-decoration:underline;">#(ThisText)#</td>
				<td class="normal" style="text-decoration:underline;">#(OtherText)#</td>
			</tr>
			<tr class="infoRow">
				<td class="zenLabel" nowrap valign="middle">&nbsp;#(NameText)#</td>
				<td class="normal" nowrap>
					<input id="ThisMemberName" class="normal" type="text" size="32" value='#($$$GetDefaultSystemName)#' onchange="zenPage.modifiedMemberName(this.value,1,false);">
				</td>
				<td class="normal" nowrap valign="middle">
					#(%page.OtherMemberName)#
				</td>
			</tr>
			<tr class="infoRow">
				<td class="zenLabel" nowrap valign="middle">&nbsp;#(SuperserverText)#</td>
				<td class="normal" nowrap valign="middle">
					<input id="ThisMemberECP" class="normal" type="text" size="20" value='#($System.INetInfo.LocalHostName())#' onkeyup="zenPage.updateAddress(this.value,false);" onchange="zenPage.modifiedECPAddress(this.value,1,false);">
				</td>
				<td class="normal" nowrap valign="middle">
					#(%page.OtherMemberECP)#
				</td>
			</tr>
			<tr class="infoRow">
				<td class="zenLabel" nowrap valign="middle">&nbsp;#(AgentPortText)#</td>
				<td class="normal" nowrap>
					<input id="ThisMemberPort" class="normal" type="text" size="5" value='#($$$GetDefaultAgentPort)#' onchange="zenPage.doModified();">
				</td>
				<td class="normal" nowrap valign="middle">
					#(%page.OtherMemberPort)#
				</td>
			</tr>>
	If (%page.VirtualAddress'="") {
		Set VirtualAddressText = $$$TextHTML("Network Interface for Virtual IP")
		Set IndexText = $$$TextHTML("(add index number if needed)")
		if '$SYSTEM.INetInfo.CheckArpingInstalled() {
			&html<
				<tr>
					<td class="zenLabel" nowrap valign="top">&nbsp;#(VirtualAddressText)#</td>
					<td class="rednote" nowrap valign="middle">
						#($$$TextHTML("'arping' command is missing, can't select VIP interface."))#
					</td>
				</tr>
			>
			&html<<input type="hidden" id="VirtualAddressInterface" value="">>
			&html<<input type="hidden" id="VIPNetworkInterface" value="">>
		} else {
		&html<
			<tr>
				<td class="zenLabel" nowrap valign="top">&nbsp;#(VirtualAddressText)#</td>
				<td class="normal" nowrap valign="middle">
			>
		Do ..DrawNetworkInterface(1)
		&html<
				<br/><div id="idVAI" style="display:#($Select(%page.ShowVAI:"block",1:"none"))#">
				<input type="text" name="VirtualAddressInterface" id="VirtualAddressInterface" size="40" onchange="zenPage.doModified();">
				<br/>#(IndexText)#</div>
				</td>
				<td class="centercaption" nowrap valign="top">&nbsp;-&nbsp;</td>
			</tr>
			>
		}
	} Else {
		&html<<input type="hidden" id="VirtualAddressInterface" value="">>
	}		
			
			&html<<tr class="infoRow">
				<td class="zenLabel" nowrap valign="top">&nbsp;#(SSLText)#</td>
				<td class="normal" colspan="2" nowrap valign="top">
					#(SSLContents)#
				</td>
			</tr>
			<tr class="infoRow">
				<td class="zenLabel" nowrap valign="middle">&nbsp;#(PrivateAddressText)#</td>
				<td class="normal" nowrap>
					<input id="ThisMemberPrivateAddress" class="normal" type="text" size="20" value='#($System.INetInfo.LocalHostName())#' onchange="zenPage.modifiedAddress(this.value,1,false);">
				</td>
				<td class="normal" nowrap valign="middle">
					#(%page.OtherMemberPrivateAddress)#
				</td>
			</tr>
			<tr class="infoRow">
				<td class="zenLabel" nowrap valign="middle">&nbsp;#(AgentAddressText)#</td>
				<td class="normal" nowrap>
					<input id="ThisMemberAgentAddress" class="normal" type="text" size="20" value='#($s(##class(SYS.Agent).GetApplicationInterface()=""||(##class(SYS.Agent).GetApplicationInterface()="*"):$System.INetInfo.LocalHostName(),1:##class(SYS.Agent).GetApplicationInterface()))#' onchange="zenPage.modifiedAgentAddress(this.value,1,false);">
				</td>
				<td class="normal" nowrap valign="middle">
					#(%page.OtherMemberAgentAddress)#
				</td>
			</tr>
		</table>>
	
	Quit $$$OK
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
#if 0
		Set MirrorConfig = ##class(SYS.MirrorConfiguration).RetrieveMirrorConfig(pProxy.MirrorName,pProxy.AgentAddress,pProxy.AgentPort,pProxy.InstanceName,.tSC)
		If '$IsObject(MirrorConfig) {
			Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
	
		Set MapMirrorConfig = ##class(Config.MapMirrors).%New()
		Set MapMirrorConfig.ID = pProxy.MirrorName
		Set MapMirrorConfig.Name = pProxy.ThisMemberName

		Set AgentAddress = ##class(SYS.Agent).GetApplicationInterface()
		Set MapMirrorConfig.AgentAddress = $Select(AgentAddress=""||(AgentAddress="*"):pProxy.ThisMemberECP,1:AgentAddress)
		Set MapMirrorConfig.ECPAddress = pProxy.ThisMemberECP
		Set MapMirrorConfig.AgentPort = pProxy.ThisMemberPort
		Set MapMirrorConfig.MirrorAddress = $Select(pProxy.ThisMemberMirrorAddress="":pProxy.ThisMemberECP,1:pProxy.ThisMemberMirrorAddress)
		
		Set MemberConfig = ##class(Config.MirrorMember).%New()
		Set MemberConfig.VirtualAddressInterface = pProxy.VirtualAddressInterface
		
		Set OtherMirrorMember = ##class(SYS.MirrorConfiguration).RetrieveMirrorMemberConfig(pProxy.MirrorName,pProxy.AgentAddress,pProxy.AgentPort,pProxy.InstanceName,.tSC)
		If '$IsObject(OtherMirrorMember) {
			Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
		
		Set tSC = ##class(SYS.MirrorConfiguration).JoinExistingMirror(MirrorConfig,MapMirrorConfig,MemberConfig,OtherMirrorMember)
#else
		Set LocalInfo("VirtualAddressInterface") = pProxy.VirtualAddressInterface
		Set LocalInfo("AgentPort") = pProxy.ThisMemberPort
		Set LocalInfo("ECPAddress") = pProxy.ThisMemberECP
		Set LocalInfo("MirrorAddress") = $Select(pProxy.ThisMemberMirrorAddress="":pProxy.ThisMemberECP,1:pProxy.ThisMemberMirrorAddress)
		#;SML2315 ; Pass Agent address.
		Set LocalInfo("AgentAddress") = $Select(pProxy.ThisMemberAgentAddress="":pProxy.ThisMemberECP,1:pProxy.ThisMemberAgentAddress)
		Set tSC = ##class(SYS.Mirror).JoinMirrorAsFailoverMember(pProxy.MirrorName,pProxy.ThisMemberName,pProxy.InstanceName,pProxy.AgentAddress,pProxy.AgentPort,.LocalInfo)
#endif
		If $$$ISERR(tSC) Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

///  Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	If ..IsEditForm = 0 Quit $$$OK
	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnConnect",$$$Text("Next"),$$$Text("Connect to the specified instance and retrieve data"),"zenPage.doConnect();")
	Set pCommands(2) = $LB("btnSave",$$$Text("Save"),$$$Text("Save and join the mirror"),"zenPage.doSave();")
	Set pCommands(3) = $LB("btnClear",$$$Text("Clear"),$$$Text("Clear the form and start over"),"zenPage.doClear();")
	Set pCommands(4) = $LB("btnCancel",$$$Text("Cancel"),$$$Text("Return without saving new changes"),"zenPage.doCancel();")

	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("Join Mirror as Failover")
}

/// Set Locator bar and determine whether to show change password option.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..lblTitle = $$$TextHTML("Use the form below to join an existing Mirror as the failover member")_":"
	
	Set tSC = ##class(SYS.Mirror).CheckISCAgent()
	If $$$ISERR(tSC) {
		Do ..DisplayError(tSC)
		Quit $$$OK
	}
	
	Set ..%GetComponentById("AgentPort").value = $$$DEFAGENTPORT

	Quit 1
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
