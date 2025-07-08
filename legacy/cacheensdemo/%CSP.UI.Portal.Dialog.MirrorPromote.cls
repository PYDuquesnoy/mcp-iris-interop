/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Promote a DR to failover member with VIP and partner selection.
Class %CSP.UI.Portal.Dialog.MirrorPromote Extends %CSP.Portal.standardDialog [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.Dialog.MirrorPromote.zen";

/// Displayed name of this page.
Parameter PAGENAME = "Actions for promotion to failover member";

/// Domain used for localization.
Parameter DOMAIN = "%Utility";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage:USE";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property DownList As %ZEN.Datatype.string(ZENURL = "DownList");

Property VIPAct As %ZEN.Datatype.integer(ZENURL = "VIPAct");

Property InterfaceSeed As %ZEN.Datatype.string(ZENURL = "InterfaceSeed");

Property ShowVAI As %ZEN.Datatype.boolean [ InitialExpression = {$ZCVT($ZV,"U")["HP-UX"} ];

Property LocalDownList As %String;

Property PromoteErrorText As %String;

Property PartnerMember As %ZEN.Datatype.string;

Property LastJrnFileName As %ZEN.Datatype.string;

Property LastJrnRecTime As %ZEN.Datatype.string;

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
<button id="btnPromote" controlClass="commandButton" caption="Promote" title="Promote this DR member to failover member" onclick="zenPage.doPromote(0);"/>
<button id="btnPromote2" controlClass="commandButton" caption="Promote" title="Promote this DR member to failover member" onclick="zenPage.doPromote(1);" hidden="true"/>
<button id="btnCancel" controlClass="commandButton" caption="Cancel" title="Return to the Mirror Monitor" onclick="zenPage.dialogCancel();" />
<button id="btnFinish" controlClass="commandButton" caption="Close" title="Return to the Mirror Monitor" onclick="zenPage.dialogFinish();" hidden="true"/>
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<spacer height="10"/>
<group id="NIGroup" hidden="true">
<label id="NImsg1"/>
<html id="networkInterfaceHTML" label="Please Select Network Interface" OnDrawContent="DrawNetworkInterface" seed="#(%page.InterfaceSeed)#" hint="Required."/>
<spacer height="3px"/>
<vgroup id="idVAI" hidden="true">
<text id="VirtualAddressInterface" size="55"/>
<spacer height="3px"/>
<label label="(add index number if needed)" labelClass="helpText"/>
</vgroup>
<spacer height="10px"/>
</group>
<group id="PartnerGroup" hidden="true">
<label id="Partnermsg10"/>
<label id="Partnermsg11"/>
<label id="Partnermsg12"/>
<label id="Partnermsg13"/>
<label id="Partnermsg14"/>
<label id="Partnermsg15"/>
<label id="Partnermsg16"/>
<html id="partnerHTML" label="Please Select a failover partner member" OnDrawContent="DrawMirrorPartner"/>
<label id="Partnermsg2" enclosingStyle="color: #DA4848;"/>
<label id="Partnermsg3"/>
</group>
<label id="Resultmsg1" hidden="true"/>
<label id="Resultmsg2" enclosingStyle="color: #DA4848;" hidden="true"/>
<label id="Resultmsg3" hidden="true"/>
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

/// user selected a VIP from drop-down. put it into the textbox and show when ShowVAI is true.
ClientMethod selectVIP(value) [ Language = javascript ]
{
	zen("VirtualAddressInterface").setValue(value);
	if ((value != "")&&(zenPage.ShowVAI == 1)) {
		zen("idVAI").setHidden(false);
		zen("VirtualAddressInterface").setProperty("disabled", 0);
		zen("VirtualAddressInterface").focus();
	} else {
		zen("idVAI").setHidden(true);
	}
}

/// user selected a failover partner member from drop-down.
ClientMethod selectPartner(value) [ Language = javascript ]
{
	this.PartnerMember = value;
	// Null '' indicates no option is chosen.
	// One space ' ' indicates no partner.
	// Two spaces '  ' indicates no partner with no failover.
	// Any other value indicates a selected partner.
	if (value == '') {
		// No partner selected. Clear the messages.
		zen("Partnermsg2").setHidden(true);
		zen("Partnermsg3").setHidden(true);
	} else {
		var text = "";
		zen("Partnermsg2").setHidden(false);
		if ((value != ' ')&&(value != '  ')) {
			// A failover partner is selected.
			text = $$$Text("Warning: If the partner member '%1' was not the last member to be primary, it may not have all of the journal data which has been generated in the mirror. The consequence of this is that some operations may be lost and the other mirror members may need to be rebuilt from a backup.");
			text = text.replace('%1',value);
		} else {
			// No failover partner.
			text = $$$Text("Warning: If this member becomes primary without all of the journal data which has been generated in the mirror, the consequence is that some operations may be lost and the other mirror members may need to be rebuilt from a backup. This member has journal data up to '%1' in file '%2'.");
			if (this.LastJrnRecTime != '') {
				text = text.replace('%1',this.LastJrnRecTime);
			} else {
				text = text.replace('%1',$$$Text("Unknown time"));
			}
			if (this.LastJrnFileName != '') {
				text = text.replace('%2',this.LastJrnFileName);
			} else {
				text = text.replace('%2',$$$Text("Unknown file - failed to read mirror journal log"));
			}
		}
		zen("Partnermsg2").setValue(text);
		zen("Partnermsg3").setHidden(false);
		zen("Partnermsg3").setValue($$$Text("Click 'Promote' button promote to failover member. Click 'Cancel' button to return to Mirror Monitor page."));
	}
}

/// Promote to failover after VIP interface is selected.
ClientMethod doPromote(stage) [ Language = javascript ]
{
	var interface = zen("VirtualAddressInterface").getValue();
	var standalone = 0;
	var nofailover = 0;
	var partner = this.PartnerMember;
	if (stage == 0) {
		if (interface == '') {
			alert($$$Text("You must select a network interface before promoting the DR member"));
			return;
		}
	} else {
		if (partner == '') {
			alert($$$Text("You must select a failover partner or 'No Partner Failover Member'."));
			return;
		} else if (partner == ' ' || (partner == '  ')) {
			if (partner == '  ') {
				// Two spaces partner is for 'no failover'
				nofailover = 1;
			}
			// 'No Partner Failover Member' selected, make it a null.
			partner = '';
			standalone = 1;
		}
		//interface = '';
	}
	var rc = zenPage.PromoteToFailover(interface,partner,standalone,nofailover);
	if (rc == 1) {
		zen("NIGroup").setHidden(true);
		zen("PartnerGroup").setHidden(true);
		zen('Resultmsg1').setValue($$$Text("Promoting to failover member succeeded."));
		zen('Resultmsg1').setHidden(false);
		if (zenPage.LocalDownList != '') {
			var text = $$$Text("IMPORTANT: Agent of '%1' could not be contacted.\nBefore you restart it you must manually edit the .cpf configuration file, and in the [MirrorMember] section set ValidatedMember=0. Failure to do so could result in having two primary members running simultaneously.");
			text = text.replace('%1',zenPage.LocalDownList);
			zen('Resultmsg2').setValue(text);
			zen('Resultmsg2').setHidden(false);
		}
		zen('Resultmsg3').setValue($$$Text("Click 'Close' button to return to Mirror Monitor page."));
		zen('Resultmsg3').setHidden(false);
		zen('btnPromote').setHidden(true);
		zen('btnPromote2').setHidden(true);
		zen('btnCancel').setHidden(true);
		zen('btnFinish').setHidden(false);
		return;
	}
	if (rc == 2 || (stage != 0)) {
		zen("NIGroup").setHidden(true);
		zen("PartnerGroup").setHidden(true);
		alert($$$Text("Promotion failed with error: ") + zenPage.PromoteErrorText + $$$Text("Click 'Cancel' button to return to Mirror Monitor page."));
		zen('Resultmsg1').setValue($$$Text("Promoting to failover member failed."));
		zen('Resultmsg1').setHidden(false);
		zen('Resultmsg2').setValue(zenPage.PromoteErrorText);
		zen('Resultmsg2').setHidden(false);
		zen('Resultmsg3').setValue($$$Text("Click 'Cancel' button to return to Mirror Monitor page."));
		zen('Resultmsg3').setHidden(false);
		zen('btnPromote').setHidden(true);
		zen('btnCancel').setHidden(false);
		zen('btnFinish').setHidden(true);
		return;
	}
	// Some failover member is down , need to select partners.
	zen('NIGroup').setHidden(true);
	zen('btnPromote').setHidden(true);
	zen('btnPromote2').setHidden(false);
	zenPage.DownListMsg(zenPage.LocalDownList);
	zen('PartnerGroup').setHidden(false);
}

/// This method is called by Mirror pages to build drop-down list for Interfaces
Method DrawNetworkInterface(pSeed As %String) As %Status
{
	Set selectOption = $p(pSeed,"^")
	Set ..%GetComponentById("VirtualAddressInterface").value = selectOption
	Set VIP=$p(pSeed,"^",2)
	Set selectText = $$$Text("--- Select one for Virtual IP ---")
	&html<<select id="VIPNetworkInterface" label="Network Interface:" onchange="zenPage.selectVIP(this.value);" />>
	&html<<option value="">#(selectText)#</option>>
	Set tList = ##class(%SYSTEM.INetInfo).GetListOfConfiguredInterfaces(1,VIP)
 	Set tItem = 1
 	While $listget(tList,tItem) '= "" {
 		Set value = $listget(tList,tItem)
 		Set select = $select(selectOption = value:"selected",1:"")
 		&html<<option value="#(value)#" #(select)#>#($zconvert(value,"O","HTML"))#</option>>
 		Set tItem = tItem + 1
 	}
	&html<</select>>
	Quit $$$OK
}

/// This method is called by Mirror pages to build drop-down list for mirror partner
Method DrawMirrorPartner(pSeed) As %Status
{
	Set mirname=##class(Config.Mirrors).GetMirrorName("")
	Set selectText = $$$Text("--- Select one or none failover partner member ---")
	&html<<select id="PartnerSelect" label="Failover Partner Member:" onchange="zenPage.selectPartner(this.value);" />>
	&html<<option value="">#(selectText)#</option>>
	Set rs=##class(%ResultSet).%New("Config.MapMirrors:List")
	d rs.Execute(mirname)
 	While rs.Next() {
	 	if rs.Data("MemberType") '= 0 continue
 		Set value = rs.Data("Name")
 		&html<<option value="#(value)#">#($zconvert(value,"O","HTML"))#</option>>
 	}
 	&html<<option value=" ">#($$$TextHTML("No Partner Failover Member"))#</option>>
 	&html<<option value="  ">#($$$TextHTML("No Partner Failover Member with 'no failover'"))#</option>>
	&html<</select>>
	Quit $$$OK
}

Method DownListMsg(DownList As %String) As %Status [ ZenMethod ]
{
	Set ..%GetComponentById("Partnermsg10").value = $$$Text("Could not contact the agent(s) on failover member(s): ")_DownList
	Set ..%GetComponentById("Partnermsg11").value = $$$Text("If these failover member(s) are available, click 'Cancel' and restore connectivity. Otherwise, you may select a failover partner for this member.")
	Set ..%GetComponentById("Partnermsg12").value = $$$Text("This member may not have the mirror's most recent journal data. If you select a partner failover member, on successful contact with it, this member will obtain any newer journal data that the partner has, and attempt to become primary.")
	Set ..%GetComponentById("Partnermsg13").value = $$$Text("Choose the failover member that was last primary since that member has the most recent journal data. If the partner member remains inaccessible and you wish to make this member primary without obtaining additional journal data, you may later use the ^MIRROR option 'Force this node to become primary'.")
	Set ..%GetComponentById("Partnermsg14").value = $$$Text("If you select 'No Partner Failover Member', the member will apply all the journal data it has and scan once for additional journal data from other members before becoming primary.")
	Set ..%GetComponentById("Partnermsg15").value = $$$Text("If you select 'No Partner Failover Member with 'no failover'', this member will prepare to become primary, but will not become primary until you clear 'no failover'. This preparation includes applying all the journal data it has, and periodically scanning for additional journal data from any other members it can contact. This allows you to perform any additional verification you wish before allowing the member to become primary.")
	Set ..%GetComponentById("Partnermsg16").value = $$$Text("Existing failover member(s) not selected as partner will be demoted to DR async.")
	// Obtain latest journal record timestamp and file on this member for warning message.
	Set ..LastJrnRecTime = ""
	Set ..LastJrnFileName = ""
	Set mirname = ##class(Config.Mirrors).GetMirrorName()
	Set rc = $SYSTEM.Mirror.GetLastJournalFilename(mirname)
	If (+rc > 0) {
		Set ..LastJrnFileName = $P(rc,",",2)
		Set rc = ##class(SYS.Mirror).GetJournalBlockTime(mirname,+rc,0)
		If rc {
			Set ..LastJrnRecTime = $zdt($zdth(rc,-2))
		}
	}
	Quit $$$OK
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
	
	if ..InterfaceSeed="" {
		Set ..%GetComponentById("NIGroup").hidden = 1
		Set ..%GetComponentById("btnPromote").hidden = 1
		Set ..%GetComponentById("PartnerGroup").hidden = 0
		Set ..%GetComponentById("btnPromote2").hidden = 0
		Do ..DownListMsg(..DownList)
	} else {
		Set ..%GetComponentById("NIGroup").hidden = 0
		Set ..%GetComponentById("PartnerGroup").hidden = 1
		Set msgText = ..%GetComponentById("NImsg1")
		if ..VIPAct = 2 {
			Set msgText.label = $$$FormatText($$$Text("The configured virtual IP address is '%1'. You must configure a network interface for this IP."),$p(..InterfaceSeed,"^",2))
		} elseif ..VIPAct = 3 {
			Set msgText.label = $$$FormatText($$$Text("Currently configured network interface is '%1'. It could not acquire virtual IP '%2'. So you must change it."),$p(..InterfaceSeed,"^"),$p(..InterfaceSeed,"^"))
		} else {
			Set msgText.label = $$$FormatText($$$Text("Currently configured network interface is '%1' for virtual IP '%2'. You can keep this network interface or select a different network interface."),$p(..InterfaceSeed,"^"),$p(..InterfaceSeed,"^",2))
		}
	}
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Promote a DR member to failover member")
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

Method PromoteToFailover(virtualinterface, partner, standalone, NoFailover) As %Integer [ ZenMethod ]
{
	s DownList="",..LocalDownList=""
	s rc=##class(SYS.MirrorConfiguration).PromoteToFailoverMember("",.DownList,partner,+standalone,virtualinterface,+NoFailover)
	s ..LocalDownList = DownList
	if $$$ISOK(rc) Quit 1
	S ..PromoteErrorText=$SYSTEM.Status.GetErrorText(rc)
	Quit $s(DownList="":2,1:3)
}

}
