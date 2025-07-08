/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Edit Service Popup Dialog for Management Portal
Class %CSP.UI.Portal.Dialog.Service Extends (%CSP.UI.Portal.Dialog.WizardTemplate, %CSP.UI.Component.SelectBoxUtils) [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Dialog.Service.zen";

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS = 0;

/// Displayed name of this page.
Parameter PAGENAME = "ServiceEdit";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Parameter EMSSERVICE = "Security";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

/// When editing a service this is passed in as the service name.
Property PID As %ZEN.Datatype.string(ZENURL = "PID");

Property AuthList As %ZEN.Datatype.list(DELIMITER = ";");

Property EnableClientSystem As %Boolean [ InitialExpression = 0 ];

Property FromPage As %ZEN.Datatype.string(ZENURL = "from");

Property OldUnauthenticated As %Boolean;

Property ServiceOK As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

Property ECPLink As %String [ InitialExpression = {..Link("/csp/sys/mgr/%25CSP.UI.Portal.ECP.zen")} ];

Property MonitorLink As %String [ InitialExpression = {..Link("/csp/sys/mgr/%25CSP.UI.Portal.Monitoring.zen")} ];

Property ShadowLink As %String [ InitialExpression = {..Link("/csp/sys/mgr/%25CSP.UI.Portal.Shadows.zen")} ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* style for title instructions */
div.Description	{
	font-size: 0.9em; 
	padding: 5px;
}
.link {
	font-size: 0.8em;
	color: #3B84BC;
}
table.DetailTable {
    border: 1px solid #888888;
    font-size: 0.8em;
    margin-left: 5%;
    width: 90%;
    border-collapse: collapse;
}
table.DetailTable thead th {
	border-bottom: 1px solid #888888;
    background-color: #FFFFFF;
    color: #3B84BC;
    font-weight: bold;
    text-align: left;
    padding: 3px;
    margin: 0px;
}
table.DetailTable td {
	padding: 3px;
	margin: 0px;
}
table.DetailTable tr.rowOdd td {
	background-color: #F1F0E7;
}
table.DetailTable tr.rowEven td {
	background-color: #FFFFFF;
}
table.DetailTable tbody td {
	border-bottom: 1px solid #888888;
}
table.RoleTable {
    border: 0px;
    background-color: #FFFAE7;
}
.cache-tagline {
    background-color: #9C9A8C;
    color: #FFFFFF;
    font-size: 1.1em;
    font-weight: bold;
    text-align: center;
    vertical-align: middle;
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
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();" />
<spacer width="5" />
<button id="btnFinish" controlClass="commandButton" caption="Save" onclick="zenPage.dialogFinish();;"/>
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
<group id="editGroup" labelPosition="left" cellStyle="padding-bottom:5px;">
<label id="Name" label="Service Name" enclosingClass="normal" containerStyle="vertical-align:middle;"/>
<label id="DescriptionLabel" label="Description" enclosingClass="normal" containerStyle="vertical-align:middle;"/>
<text id="Description" label="Description" size="60" maxlength="128" hidden="true"/>
<checkbox id="Enabled" label="Service Enabled" captionClass="normal"/>
<checkbox id="HttpOnlyCookies" label="HttpOnly flag with Session/Login Cookies" captionClass="normal" hidden="true"/>
</group>
<html id="AuthLine" hidden="true"><hr size="1"/></html>
<group id="AuthGroup" label="Allowed Authentication Methods" hidden="true">
<checkbox id="AutheUnauthenticated" captionClass="normal" hidden="true"/>
<checkbox id="AutheOS" captionClass="normal" hidden="true"/>
<checkbox id="AutheOSDelegated" captionClass="normal" hidden="true"/>
<checkbox id="AutheOSLDAP" captionClass="normal" hidden="true"/>
<checkbox id="AutheCache" captionClass="normal" hidden="true"/>
<checkbox id="AutheKB" captionClass="normal" hidden="true"/>
<checkbox id="AutheK5API" captionClass="normal" hidden="true"/>
<checkbox id="AutheK5Prompt" captionClass="normal" hidden="true"/>
<checkbox id="AutheK5CCache" captionClass="normal" hidden="true"/>
<checkbox id="AutheKBIntegrity" captionClass="normal" hidden="true"/>
<checkbox id="AutheKBEncryption" captionClass="normal" hidden="true"/>
<checkbox id="AutheK5KeyTab" captionClass="normal" hidden="true"/>
<checkbox id="AutheDelegated" captionClass="normal" hidden="true"/>
<checkbox id="AutheLDAP" captionClass="normal" hidden="true"/>
<checkbox id="AutheTwoFactorPW" captionClass="normal" hidden="true"/>
<checkbox id="AutheTwoFactorSMS" captionClass="normal" hidden="true"/>
<checkbox id="AutheMutualTLS" captionClass="normal" hidden="true"/>
</group>

<html id="CSPLink" OnDrawContent="DrawCSPLink" hidden="true"/>
<link id="ECPLink" caption="Configure ECP Settings" href="#(%page.ECPLink)#" target="_new" hidden="true"/>
<link id="MonitorLink" caption="Configure Monitor Settings" href="#(%page.MonitorLink)#" target="_new" hidden="true"/>
<link id="ShadowLink" caption="Configure Shadow Server Settings" href="#(%page.ShadowLink)#" target="_new" hidden="true"/>

<html id="ConnectionsLine" hidden="true"><hr size="1"/></html>
<pane id="IncomingConnectionPane" label="Allowed Incoming Connections" hidden="true" paneName="incomingConnectionPane"/>
</pane>
}

/// This XML block defines the contents of this pane.
XData incomingConnectionPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<spacer height="10"/>
<group id="IncomingConnections">
<hidden id="ClientSystems" value=""/>
<html id="ConnectionTable" OnDrawContent="DrawConnectionTable" seed=""/>
<hidden id="Index"/>
</group>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onstartHandler() [ Language = javascript ]
{
	if (!this.ServiceOK) {
		var msg = $$$Text("Invalid Service name.");
		this.showMsg(msg);
		zen("btnFinish").setDisabled(true);
		zen("btnFinish").setProperty("controlClass","commandButtonDisabled");
		zen("editGroup").setHidden(true);
		return;
	}
	if (zen('Description').getProperty('hidden')) {
		zen('Enabled').focus();
	} else {
		zen('Description').focus();
	}
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		if (this.validate()==false) return false;
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
	var serviceName = encodeURIComponent(zen("Name").getValue());
	return serviceName;
}

ClientMethod validate() [ Language = javascript ]
{
	if (this.PID != "%Service_WebGateway") return true;
	if (zen("AutheUnauthenticated").hidden == false) {
		var newA = zen("AutheUnauthenticated").getValue();
		var oldA = this.OldUnauthenticated;
		if (oldA == true && newA == false) {
			var txt1 = $$$Text("Removing unauthenticated access for the Web Gateway can potentially lock users out of the Management Portal and other Web applications.");
			var txt2 = $$$Text("Are you sure you want to proceed?");
			if (confirm(txt1 + '\n' + txt2) == false) {
				return false;
			}
		}
	}
	return true;
}

ClientMethod doSave() [ Language = javascript ]
{
	this.resetMsg();
	
	var proxy = new zenProxy();
	
	proxy.PID = this.PID;
	proxy.Description = zen('Description').getValue();
	proxy.Enabled = zen('Enabled').getValue();
	proxy.HttpOnlyCookies = zen('HttpOnlyCookies').getValue();
	proxy.EnableClientSystem = this.EnableClientSystem;
	if (this.EnableClientSystem) {
		proxy.ClientSystems = zen('ClientSystems').getValue();
	}
	
	for (var i=0;i<this.AuthList.length;i++) {
		var name = this.AuthList[i].substring(0,this.AuthList[i].indexOf('^'));
		proxy[name] = zen(name).getValue();
	}
	
	var result = this.SaveData(proxy);
	if (result.ok != 1) {
		this.showMsg(result.ErrorMessage,true);
		return false;
	}
	return true;
}

/// refresh the allowed incoming connections table and return whether there are now two or more clients listed
ClientMethod refreshConnectionTable() [ Language = javascript ]
{
	var table = zen('ConnectionTable');
	var seed = table.getProperty('seed');
	var seedArr = seed.split('||');
	var newCliSys = zen('ClientSystems').getValue();
	var newSeed = seedArr[0]+'||'+newCliSys;
	table.setProperty('seed',newSeed);
	table.refreshContents();
}

ClientMethod showRoles(index, ip) [ Language = javascript ]
{
	zenPage.clearList('selList',1);
	var roleid = "roleid_" + index;
	var roles = document.getElementById(roleid).innerHTML;
	if (roles != "") {
		var avaList = document.getElementById("avaList");
		var avalen = avaList.length;
		// make all avaList unselected
		for (var j=0; j<avalen; j++) {
			avaList[j].selected = false;
		}
		// move selected roles from avaList to selList
		var rolist = roles.split(",");
 		var rollen = rolist.length;
		for (var i=0; i<rollen; i++) {			
			for (var j=0; j<avalen; j++) {
				if (avaList[j].value == rolist[i]) {
					avaList[j].selected = true;
					break;	
				}
			}
		}
		zenPage.doSelectBoxMove("selectOne",1);
	}
	document.getElementById("Index").value = index;
	document.getElementById("RoleIP").innerHTML = ip;
	document.getElementById("editroles").style.display="block";
}

ClientMethod hideRoles() [ Language = javascript ]
{
	document.getElementById("editroles").style.display="none";
}

ClientMethod saveRoles() [ Language = javascript ]
{
	var index = document.getElementById("Index").value;
	var ip = document.getElementById("RoleIP").innerHTML;
	var roles = zenPage.getSelList(',',false,1);
	var addRoles = ip + ((ip.indexOf(":") == -1 || ip.indexOf(":") == ip.lastIndexOf(":")) ? ":" : "|") + roles; //ip + "|" + roles; 
	
	var realIndex = index - 1;
	var cliArr = zen('ClientSystems').getValue().split(';');
	cliArr[realIndex] = addRoles;
	var newList = cliArr.join(';');
	zen('ClientSystems').setValue(newList);
	zenPage.refreshConnectionTable();
}

ClientMethod deleteIndex(DeleteIndex, ip, ncli) [ Language = javascript ]
{
	var index = DeleteIndex - 1;
	var cliArr = zen('ClientSystems').getValue().split(';');
	cliArr.splice(index,1);
	var newList = cliArr.join(';');
	zen('ClientSystems').setValue(newList);

	zenPage.refreshConnectionTable();
}

ClientMethod deleteAll() [ Language = javascript ]
{
	zen('ClientSystems').setValue('');
	zenPage.refreshConnectionTable();
}

ClientMethod doAddIP() [ Language = javascript ]
{
	var newIP = prompt($$$Text("Please enter a new IP Address for Allowed Incoming Connection:"),"");
	if (newIP) {
		var st = zenPage.ValidateIP(newIP);
		if (st == 1) {
			var cliSys = zen('ClientSystems').getValue();
			if (cliSys == "") {
				zen('ClientSystems').setValue(newIP);
			} else {
				zen('ClientSystems').setValue(cliSys+';'+newIP);
			}
			zenPage.refreshConnectionTable();
		} else {
			alert(st);
		}
	}
}

Method DrawConnectionTable(pSeed As %String) As %Status
{
	Set doroles = $PIECE(pSeed,"||",1)
	Set CliSys = $PIECE(pSeed,"||",2)
 	Set ncli = $SELECT(CliSys="":0,1:$LENGTH(CliSys,";"))

	&html<<table class="DetailTable">
			<thead><tr><th nowrap>#($$$Text("Index"))#</th>
				<th nowrap>#($$$Text("IP Address"))#</th>
				<th nowrap style="text-align:center;">#($$$Text("Roles"))#</th>
				<th>&nbsp;</th>
			</tr></thead>>
	For i = 1:1:ncli {
		Set ClientSystems(i) = $PIECE(CliSys,";",i)
		Set dl = $S($L(ClientSystems(i),":")>2||(ClientSystems(i)["|"):"|",1:":")
		Set cli = $P(ClientSystems(i),dl,1)
		Set roles = $P(ClientSystems(i),dl,2)
		Set rowClass = $SELECT(i#2:"rowOdd",1:"rowEven")
		&html<<tbody><tr class="#(rowClass)#">>
		&html<<td>#(i)#</td><td>#(cli)#</td>>
		&html<<td nowrap style="text-align:center;">>
		If doroles {
			Set roleid = "roleid_"_i
			&html<<a href="#" onclick="zenPage.showRoles('#(i)#','#(cli)#')" class="link">#($$$Text("Edit"))#</a>&nbsp;<div id="#(roleid)#">#(..EscapeHTML(roles))#</div>>
		} Else {
			&html<->
		}
		&html<</td>>
		&html<<td style="text-align:center;"><a href="#" onclick="zenPage.deleteIndex('#(i)#','#(cli)#','#(ncli)#')" class="link">#($$$Text("Delete"))#</a></td>>
		&html<</tr>>
		Set addRowClass = $SELECT(ncli#2:"rowEven",1:"rowOdd")
	}
	If ncli = 0 {
		&html<<tr class="rowOdd"><td colspan="4" style="text-align:center;">#($$$Text("None defined"))#.</td></tr></tbody>>
		Set addRowClass = "rowEven"
	}
	Set rowClass = $SELECT(ncli#2:"rowEven",1:"rowOdd")
	&html<<tfoot><tr class="#(addRowClass)#"><td colspan="4" style="text-align:center;">
	<input type="button" name="Add" value='#($$$Text("Add New"))#' onclick="zenPage.doAddIP();">>
	If (ncli > 1) {
		&html<<input type="button" id="DeleteAll" value='#($$$Text("Delete All"))#' onclick="zenPage.deleteAll()" style="float:right;"/>>
	}
	&html<</td></tr></tfoot>> 
	&html<</table>>
	
	
	
	If doroles {
		&html<<div id="editroles" style="margin-top:5px;display:none;">
			<div style="background-color:#fcc835;"><div class="cache-tagline">#($$$Text("Select Roles for"))# <div id="RoleIP"></div></div></div>>
				// Start to draw the Available list box
				Set tSC = ..DrawAvailableList(,1)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			
				// Populate the Available list box
				Set tRS = ##class(%ResultSet).%New("Security.Roles:List")
				Do tRS.Execute()
				While tRS.Next() {
					Set name = tRS.GetData(1)
					&html<<option value="#(name)#">#(..EscapeHTML(name))#</option>>
				}
				Kill tRS

				// Draw the arrows and Select list box
				Set tSC = ..DrawSelectList(,1)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
				&html<<input type="button" name="Save" id="Save" textid="" value='#($$$TextHTML("Save Roles"))#' onclick="zenPage.saveRoles();">
			<input type="button" name="Hide" id="Hide" textid="" value='#($$$TextHTML("Close Roles"))#' onclick="zenPage.hideRoles();">>
			&html<</div>>
	}
	Quit $$$OK
}

ClassMethod ValidateIP(IP As %String) As %String [ ZenMethod ]
{
	Try {
		Set status = ##class(Security.Services).ValidateClientSystemsIP(IP)
		Set tmsg = $case(+status,
						0:$$$OK,
						1:$$$FormatText($$$Text("Invalid IP or IP range '%1'"),IP),
						2:$$$FormatText($$$Text("Invalid host name '%1'"),IP),
						3:$$$Text("Error occurred:")_" "_$p(status,",",2),
						4:$$$OK,
						:$$$Text("Unknown error:")_" "_status)
	} Catch tException {
		Set tmsg = $System.Status.GetErrorText(tException.AsStatus())
	}
	Quit tmsg
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Edit Service")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
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
	
	Set tSC = ##class(Security.Services).Get(..PID,.Properties)
	If $$$ISERR(tSC) {
		Set ..ServiceOK = 0
		Quit $$$OK
	}
	
	Set Properties("Name") = ..PID
	Set Properties("DescriptionLabel") = Properties("Description")
	
	Set tProperty = ""
	Set tProperty = $O(Properties(tProperty)) 
	While tProperty '= ""  {
		Set Component = ..%GetComponentById(tProperty)
		If $ISO(Component) {
			Set Component.value = Properties(tProperty)
		}
		Set tProperty = $O(Properties(tProperty)) 
	}
	
	Set tSC = ##class(Security.System).Get($$$SystemSecurityName,.SysProperties)
	If $E(..PID,1,1)'="%" {
		// Description can be edited for non-system Services
		Set ..%GetComponentById("DescriptionLabel").hidden = 1
	 	Set ..%GetComponentById("Description").hidden = 0
 	} ElseIf ..PID = $$$ServiceCSP {
		Set ..%GetComponentById("HttpOnlyCookies").hidden = 0
		Set ..%GetComponentById("CSPLink").hidden = 0
	} ElseIf ..PID = $$$ServiceECP {
		If (..FromPage'="ECP") && $SYSTEM.Security.Check($$$AdminManageResourceName,"USE") {
			Set ..%GetComponentById("ECPLink").hidden = 0
		}
	} ElseIf ..PID = $$$ServiceMonitor {
		If (..FromPage'="Monitor") && $SYSTEM.Security.Check($$$AdminManageResourceName,"USE") {
			Set ..%GetComponentById("MonitorLink").hidden = 0
		}
	} ElseIf ..PID = $$$ServiceShadow {
		If $SYSTEM.Security.Check($$$AdminManageResourceName,"USE") {
			Set ..%GetComponentById("ShadowLink").hidden = 0
		}
	}
	
	// Draw "Allowed Authentication Methods"
	If $zb(+Properties("Capabilities"),$$$EnablePrivilegeBasedSecurity,1) {
		Set ..%GetComponentById("AuthLine").hidden = 0
		Set ..%GetComponentById("AuthGroup").hidden = 0
	
		Set ..AuthList = 
			"AutheUnauthenticated^"_$$$AutheUnauthenticated_"^"_$$$AutheUnauthenticatedStr_";"_
			"AutheOS^"_$$$AutheOS_"^"_$$$AutheOSStr_";"_
			"AutheOSDelegated^"_$$$AutheOSDelegated_"^"_$$$AutheOSDelegatedStr_";"_
			"AutheOSLDAP^"_$$$AutheOSLDAP_"^"_$$$AutheOSLDAPStr_";"_
			"AutheCache^"_$$$AutheCache_"^"_$$$AutheCacheStr_";"_
			"AutheKB^"_$$$AutheKB_"^"_$$$AutheKBStr_";"_
			"AutheK5API^"_$$$AutheK5API_"^"_$$$AutheK5APIStr_";"_
			"AutheK5Prompt^"_$$$AutheK5Prompt_"^"_$$$AutheK5PromptStr_";"_
			"AutheK5CCache^"_$$$AutheK5CCache_"^"_$$$AutheK5CCacheStr_";"_
			"AutheKBIntegrity^"_$$$AutheKBIntegrity_"^"_$$$AutheKBIntegrityStr_";"_
			"AutheKBEncryption^"_$$$AutheKBEncryption_"^"_$$$AutheKBEncryptionStr_";"_
			"AutheK5KeyTab^"_$$$AutheK5KeyTab_"^"_$$$AutheK5KeyTabStr_";"_
			"AutheDelegated^"_$$$AutheDelegated_"^"_$$$AutheDelegatedStr_";"_
			"AutheLDAP^"_$$$AutheLDAP_"^"_$$$AutheLDAPStr_";"_
			"AutheTwoFactorPW^"_$$$AutheTwoFactorPW_"^"_$$$AutheTwoFactorPWStr_";"_
			"AutheTwoFactorSMS^"_$$$AutheTwoFactorSMS_"^"_$$$AutheTwoFactorSMSStr_";"_
			"AutheMutualTLS^"_$$$AutheMutualTLS_"^"_$$$AutheMutualTLSStr

		Set AutheEnabledCapabilities = +Properties("AutheEnabledCapabilities")
		
		For num=1:1:$L(..AuthList,";") {
			Set name = $P($P(..AuthList,";",num),"^",1)
			Set b = +$P($P(..AuthList,";",num),"^",2)
			// If the following two checks fail, then do not generate checkbox
			If $zb(AutheEnabledCapabilities,b,1),$zb(+SysProperties("AutheEnabled"),b,1) {
				Set ischecked = ($zb(+Properties("AutheEnabled"),b,1) = b)
				If name = "AutheUnauthenticated" {
					Set ..OldUnauthenticated = ischecked
				}
				Set component = ..%GetComponentById(name)
				Set component.value = ischecked
				Set component.caption = $P($P(..AuthList,";",num),"^",3)
				Set component.containerStyle = "padding:0 0 5px 10px;"
				Set component.hidden = 0
			}	
		 }
	}
	
	// Draw "Allowed Incoming Connections"
	If $zb(+Properties("Capabilities"),$$$EnableClientSystemSecurity,1) {
		Set ..EnableClientSystem = 1
		Set ..%GetComponentById("IncomingConnectionPane").hidden = 0
		Set ..%GetComponentById("ConnectionsLine").hidden = 0
		Set ..%GetComponentById("ConnectionTable").seed = $zb(+Properties("Capabilities"),$$$EnableClientSystemSecurityRoles,1)_"||"_..%GetComponentById("ClientSystems").value
	}

	Quit $$$OK
}

ClassMethod DrawCSPLink(pSeed As %String) As %Status
{
	Set text = $$$TextHTML("Note: To configure authentication mechanisms for a Web application")
	Set text2 = $$$TextHTML("use the Web Applications page")
	Set url = ..Link("%25CSP.UI.Portal.Applications.WebList.zen")
	&html<<span style="color:#404040;font-size:0.8em;font-weight:normal;">#(text)#, </span>>
	&html<<a href="#(url)#" target="_new" class="link">#(text2)#</a>>
	Quit $$$OK
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set tPageTitle = $$$FormatText($$$Text("Edit Definition for Service %1"),..EscapeHTML(%page.PID))_"<br/>"
	&html<<div class="Description">#(tPageTitle)#</div>
	<hr size="1"/>>
	Quit $$$OK
}

ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set tSC = ##class(Security.Services).Get(pProxy.PID,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set Properties("Description") = pProxy.Description
		Set Properties("Enabled") = pProxy.Enabled
		Set Properties("HttpOnlyCookies") = pProxy.HttpOnlyCookies
		
		If pProxy.EnableClientSystem {
			Set Properties("ClientSystems") = pProxy.ClientSystems
		}
		
		If $zb(+Properties("Capabilities"),$$$EnablePrivilegeBasedSecurity,1) {
			Set AuthList =
			"AutheUnauthenticated^"_$$$AutheUnauthenticated_"^"_$$$AutheUnauthenticatedStr_";"_
			"AutheOS^"_$$$AutheOS_"^"_$$$AutheOSStr_";"_
			"AutheOSDelegated^"_$$$AutheOSDelegated_"^"_$$$AutheOSDelegatedStr_";"_
			"AutheOSLDAP^"_$$$AutheOSLDAP_"^"_$$$AutheOSLDAPStr_";"_
			"AutheCache^"_$$$AutheCache_"^"_$$$AutheCacheStr_";"_
			"AutheKB^"_$$$AutheKB_"^"_$$$AutheKBStr_";"_
			"AutheK5API^"_$$$AutheK5API_"^"_$$$AutheK5APIStr_";"_
			"AutheK5Prompt^"_$$$AutheK5Prompt_"^"_$$$AutheK5PromptStr_";"_
			"AutheK5CCache^"_$$$AutheK5CCache_"^"_$$$AutheK5CCacheStr_";"_
			"AutheKBIntegrity^"_$$$AutheKBIntegrity_"^"_$$$AutheKBIntegrityStr_";"_
			"AutheKBEncryption^"_$$$AutheKBEncryption_"^"_$$$AutheKBEncryptionStr_";"_
			"AutheK5KeyTab^"_$$$AutheK5KeyTab_"^"_$$$AutheK5KeyTabStr_";"_
			"AutheDelegated^"_$$$AutheDelegated_"^"_$$$AutheDelegatedStr_";"_
			"AutheLDAP^"_$$$AutheLDAP_"^"_$$$AutheLDAPStr_";"_
			"AutheTwoFactorPW^"_$$$AutheTwoFactorPW_"^"_$$$AutheTwoFactorPWStr_";"_
			"AutheTwoFactorSMS^"_$$$AutheTwoFactorSMS_"^"_$$$AutheTwoFactorSMSStr_";"_
			"AutheMutualTLS^"_$$$AutheMutualTLS_"^"_$$$AutheMutualTLSStr
			For num=1:1:$L(AuthList,";") {
				Set name = $P($P(AuthList,";",num),"^",1)
				Set b = +$P($P(AuthList,";",num),"^",2)
				If $PROPERTY(pProxy,name) = 1 {
					Set Properties("AutheEnabled") = $zb(+Properties("AutheEnabled"),b,7)
				} Else {
					Set Properties("AutheEnabled") = $zb(+Properties("AutheEnabled"),b,2)
				}
	 		}
		}
		
		Set tSC = ##class(Security.Services).Modify(pProxy.PID,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

}
