/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Management Portal - Create or edit/manage a Report Server
Class %CSP.UI.Portal.ReportServer Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

/// 
/// Displayed name of this page.
Parameter PAGENAME = "InterSystems Reports";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.ReportServer.zen";

Parameter HELPADDRESS = "Home,Configuration,InterSystems Reports,New Report Server";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.ReportServers.zen";

/// 
/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

/// 
/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter RECENT = 0;

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property isNew As %ZEN.Datatype.boolean(ZENURL = "isNew") [ InitialExpression = 0 ];

Property disableDelete [ InitialExpression = 0 ];

XData Style
{
<style type="text/css">
/* override the image because this form is too tall */
.EditForm {
	background-image: url('');
}
.EditForm td > * {
}

.boxedArea {
	border: 1px solid black;
	margin-left: 5px;
	padding: 3px;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px;padding-top:10px;">
<hidden id="firstFailed" />
<label id="Text1" value="#(%page.lblTitle)#" />
<hidden name="browseselect" id="browseselect" />
<label id="idRespond" enclosingClass="errorNote" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<form id="fld">
<spacer height="2px"/>
<group id="idForm" enclosingClass="EditForm" cellStyle="padding:5px;padding-bottom:0px;" labelPosition="left" hidden="false">
 <text id="Name" label="Name" size="20" value="" hint="Required." title="Name that uniquely identifies this Reports Server definition." onchange="zenPage.doModified();" />
 <text id="Host" label="Host" size="20" value="" hint="Required." title="Host name or IP address of the machine where the Report Server is located" onchange="zenPage.doModified();" />
 <text id="Port" label="Port" size="20" value="" hint="Required."  title="TCP port number for communication with the Report Server." onchange="zenPage.doModified();" />
 <checkbox id="SSO" label="SSO Enabled" value="false"  title="Enable to allow single sign on to Report Server." onchange="zenPage.doModified();"/>
</group>
</form>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if ((this.isNew == 1) || this.InvalidParam || (this.isNew == 0 && this.disableDelete == 1)) {
		this.disableCommandButton("btnDelete");
	} else {
		self.document.getElementById("command_btnDelete").className = "commandButtonRemove"; // ???
	}
	if (zen("idRespond").getValue() != "") {
		this.disableCommandButton("btnSave");
		zen("idRespond").setHidden(false);
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	If ..PID = "" Set ..isNew = 1
	If ..isNew = 1 {
		Set ..lblTitle = $$$Text("Use the form below to create a new Report Server definition:")
	} Else {
		Set ..lblTitle = $$$Text("Use the form below to manage an existing Report Server definition:")
	}

	Set (..LocatorHeader,..StdTitle) = $$$Text("InterSystems Reports")

	// Load data into fields
	Set tMsg = ..LoadData(..PID)
	If tMsg'="" {
		Set ..%GetComponentById("idRespond").value = tMsg
	}

	// Disable role modifying operations if non-privledged user
	If ('$SYSTEM.Security.Check("%Admin_Secure", "USE")) {
        Set ..disableDelete = 1 // disable deletion
        Set ..%GetComponentById("SSO").disabled = 1 // disable SSO toggling
        Set:('..isNew) ..%GetComponentById("Name").disabled = 1 // disable name editing
    }
	
	Quit $$$OK
}

Method %OnGetTitle() As %String
{
	If ..isNew = 1 {
		Quit $$$Text("New Report Server")
	}
	Else {
		Quit ..EscapeHTML(..PID)
	}
}

/// Validation handler for form.
ClientMethod formValidationHandler() [ Language = javascript ]
{
	var pass = true;
	if (!this.validateRequired(zenPage.getComponentById("Name"),pass,"S")) pass = false;
	if (!this.validateRequired(zenPage.getComponentById("Host"),pass,"S")) pass = false;
	if (!this.validateRequired(zenPage.getComponentById("Port"),pass,"N")) pass = false;
	return pass;
}

/// Load values into fields.
Method LoadData(PID As %String) As %String
{
	Set ret = ""
	Try {
		If PID = "" {
			Set sys = ##class(%Report.ServerDefinition).%New()
		}
		ElseIf ##class(%Report.ServerDefinition).%ExistsId(PID) {
			Set sys = ##class(%Report.ServerDefinition).%OpenId(PID)
		}
		Else {
			Set ..%GetComponentById("fld").hidden = 1
			Set ..InvalidParam = 1
			Set ret = $$$Text("Invalid Server Definition")
		}
		If ..InvalidParam = 0 {
			Set ..%GetComponentById("Name").value = sys.Name
			Set ..%GetComponentById("Host").value = sys.Host
			Set ..%GetComponentById("Port").value = sys.Port
			Set ..%GetComponentById("SSO").value = sys.SSOEnabled
		}
	}
	Catch {
		Do BACK^%ETN
		Set ret = $ZE
	}
	Quit ret
}

/// Get user input and send to server to save settings.
ClientMethod doSave() [ Language = javascript ]
{
	try {
		if (!this.formValidationHandler()) {
			this.afterValidate();
			return;
		}		
		
		zen('idRespond').setValue('');
		
		var name = zen('Name').getValue();
		var host = zen('Host').getValue();
		var port = zen('Port').getValue();
		var sso = 0;
        if (zen('SSO').getValue() === true) sso = 1;
        
        var proxy = this.SaveData(this.PID, name, host, port, sso);
		this.afterSave(proxy);
		
	} 
  catch(ex) {
	zenPage.showMsg('Error in doSave: ' + ex);
  }
}

/// Save Reports Render Server definition.
ClassMethod SaveData(PID, name, host, port, sso) As %ZEN.proxyObject [ ZenMethod ]
{
	Try {			
		Set proxy = ##class(%ZEN.proxyObject).%New()
		Set proxy.ok = 0
		Set proxy.PID = PID
		Set proxy.Message = ""
		
		Set sc = $$$OK
		If PID'="",##class(%Report.ServerDefinition).%ExistsId(PID) {
			Set sys = ##class(%Report.ServerDefinition).%OpenId(PID)
		}
		Else {
			Set sys = ##class(%Report.ServerDefinition).%New()
		}
		
		Set sys.Name = name
		Set sys.Host = host
		Set sys.Port = port
		Set sys.SSOEnabled = sso
		
		Set sc = sys.%Save()
		If $$$ISERR(sc) {
			Set proxy.ErrorMessage = $System.Status.GetErrorText(sc)
		}
		Else {
			Set proxy.ok = 1
			Set proxy.PID = sys.%Id()
		}
	}
	Catch {
		Do BACK^%ETN
		Set proxy.ErrorMessage = $ZERROR
	}
	Quit proxy
}

/// Delete render server definition and return to the list of render servers.
ClientMethod doDelete() [ Language = javascript ]
{
	if (!confirm($$$Text("Do you wish to permanently delete this Report Server?"))) return;
	try {
		var msg = zenPage.DeleteServer(zenPage.PID);
		if (msg == '') {
			alert($$$Text("Deleted"));
			zenPage.doCancel();
		} else {
			this.showMsg(msg);
		}
	}
	catch(ex) {
		zenPage.showMsg("Error in deleteServer: " + ex);
	}
}

/// Delete Reports Render Server definition.
ClassMethod DeleteServer(PID As %String) As %String [ ZenMethod ]
{
	Set tMsg = ""
	Try {
		Set tSC = ##class(%Report.ServerDefinition).%DeleteId(PID)
		If $$$ISERR(tSC) {
			Set tMsg = $system.Status.GetErrorText(tSC)
		}
	}
	Catch {
		Set tMsg = $ZE
	}
	Quit tMsg
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Configuration","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("InterSystems Reports","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?isNew="_..isNew_"&PID="_$ZCVT($ZCVT(..PID,"O","UTF8"),"O","URL")_"&"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_NAMESPACE)))

	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick,disabled)
	Set pCommands(1) = $LB("btnSave",$$$Text("Save"),$$$Text("Save the definition below."),"zenPage.doSave();")
	Set pCommands(2) = $LB("btnCancel",$$$Text("Cancel"),$$$Text("Return to the list of Report Servers."),"zenPage.doCancel();")
	Set pCommands(3) = $LB("btnDelete",$$$Text("Delete"),$$$Text("Permanently delete this definition."),"zenPage.doDelete();")
	
	Quit $$$OK
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
