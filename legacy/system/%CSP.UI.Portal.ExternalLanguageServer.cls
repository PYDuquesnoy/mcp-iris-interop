/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occJava

/// Zen page for System Management Portal - Edit an External Language Server
Class %CSP.UI.Portal.ExternalLanguageServer Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Object Gateway";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.ExternalLanguageServer.zen";

Parameter HELPADDRESS = "System Administration, Configuration, Connectivity, External Language Servers";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.ExternalLanguageServers.zen";

/// Security requirement
Parameter RESOURCE = {$$$AdminExternalLanguageServerEditResourceName};

Parameter RECENT = 0;

/// ID for edit.
Property PID As %String(ZENURL = "PID");

Property isNew As %ZEN.Datatype.boolean(ZENURL = "isNew") [ InitialExpression = "0" ];

Property IsEditForm As %Boolean(ZENURL = "IsEditForm") [ InitialExpression = 1 ];

/// Is this a Unix system
Property IsUnix As %Boolean [ InitialExpression = "0" ];

Property msgActionsDisplay As %String [ InitialExpression = {$$$Text("None,Restart,Alert,Restart and Alert")} ];

Property msgActionsValue As %String [ InitialExpression = "N,R,A,RA" ];

XData Style
{
<style type="text/css">
/* override the image because this form is too tall */
.EditForm {
	background-image: url('');
	padding: 4px;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px;padding-top:10px;">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:0px;"/>
<hidden name="browseselect" id="browseselect"/>
<form id="fld">
<label id="idRespond" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group id="mainGroup" enclosingClass="EditForm" cellStyle="padding-top:0px;padding-bottom:5px;" labelPosition="left">
<spacer height="2"/>
 <text id="Name" label="Server Name"  hint="Required." onchange="zenPage.doModified();" />
 <select id="Type" label="Server Type" valueList="Java,JDBC,ODBC,ML,XSLT,.NET,Python,R,Remote" displayList="Java,JDBC,ODBC,ML,XSLT,.NET,Python,R,Remote" 
 showEmpty="false" value="Java" hint="" onchange="zenPage.changeType();"/> 
<spacer height="10"/>
<text id="Address" label="Remote Server Address" size="20" value="127.0.0.1" hint="Required." onchange="zenPage.doModified();"/> 
 <text id="Port" label="Port" size="20" hint="Required." onchange="zenPage.doModified();"/> 
 
<!-- The following are .NET ONLY Properties -->
<hgroup id="id_FilePath" labelPosition="left" label="File Path" cellVAlign="top" hidden="true">
<text id="FilePath" size="60" onchange="zenPage.doModified();"/>
<button id="FilePathBrowse" caption="Browse..." onclick="zenPage.browseSelect('FilePath','showdirectoryonly');"/>
</hgroup>
<select id="DotNetVersion" label=".NET Version" valueList="N6.0,N7.0,N8.0,F4.6.2,F3.5,N5.0" displayList=".NET 6.0,.NET 7.0,.NET 8.0,Framework 4.6.2,Framework 3.5,.NET 5.0" 
 showEmpty="false" value="N6.0" hint="" hidden="true" onchange="zenPage.doModified();"/> 

<!-- The following are JAVA,JDBC, ML, and XSLT ONLY Properties -->
<hgroup id="id_ClassPath" labelPosition="left" label="Class Path" cellVAlign="top" hidden="true">
<text id="ClassPath" size="60" onchange="zenPage.doModified();"/>
<button id="ClassPathBrowse" caption="Browse..." onclick="zenPage.browseSelect('ClassPath','*.jar');"/>
</hgroup>
<text id="JVMArgs" label="JVM arguments" size="60" hint="" hidden="true" onchange="zenPage.doModified();"/> 
<hgroup id="id_JavaHome" labelPosition="left" label="Java Home Directory" cellVAlign="top" hidden="true">
<text id="JavaHome" size="60" onchange="zenPage.doModified();"/> 
<button id="JavaHomeBrowse" caption="Browse..." onclick="zenPage.browseSelect('JavaHome','showdirectoryonly');"/>
</hgroup>

<!-- The following are PYTHON ONLY Properties -->
<hgroup id="id_PythonPath" labelPosition="left" label="Python Executable Path" cellVAlign="top" hidden="true">
<text id="PythonPath" size="60" onchange="zenPage.doModified();"/> 
<button id="PythonPathBrowse" caption="Browse..." onclick="zenPage.browseSelect('PythonPath','*.*');"/>
</hgroup>
<text id="PythonOptions" label="Python Options" size="60" hint="" hidden="true" onchange="zenPage.doModified();"/>
 <spacer height="2"/>
 </group>
<!-- The following are in a collapsible Advanced Settings section -->
<spacer height="2"/>
<hgroup labelPosition="left">
<link id="AdvancedSettingsShow" label="Advanced Settings" caption="Show" hidden="true" href="#" onclick="zenPage.toggleAdvancedSettings();" showLabel="true"/>
<link id="AdvancedSettingsHide" label="Advanced Settings" caption="Hide" hidden="true" href="#" onclick="zenPage.toggleAdvancedSettings();" showLabel="true"/>
</hgroup>
<spacer height="2"/>
<group id="advancedGroup" enclosingClass="EditForm" cellStyle="padding-top:0px;padding-bottom:5px;" labelPosition="left">
<spacer height="2"/>
<hgroup id="id_Resource" labelPosition="left" label="Resource Required" hidden="true" cellVAlign="top">
<select id="Resource"
title="Specifies a resource for which users must have the Use permission (enabled as part of a privilege in a role) in order to use this Gateway."
onchange="zenPage.doModified();"
/>
</hgroup>
<hgroup id="id_LogFile" labelPosition="left" label="Log File" hidden="true" cellVAlign="top" >
<text id="LogFile" size="60" onchange="zenPage.doModified();"/>
<button id="LogFileBrowse" caption="Browse..." onclick="zenPage.browseSelect('LogFile','*.log');"/>
</hgroup>
<text id="AllowedIPAddresses" label="Allowed IP Addresses" size="60" value="127.0.0.1" hidden="true" onchange="zenPage.doModified();"/> 
<checkbox id="UseSharedMemory" label="Use Shared Memory" hint="Use shared memory if possible." hidden="true" onchange="zenPage.doModified();"/>
<text id="SSLConfigurationServer" label="SSL Server Configuration" hidden="true" size="20" onchange="zenPage.doModified();"/>
<text id="SSLConfigurationClient" label="SSL Client Configuration" hidden="true" size="20" onchange="zenPage.doModified();"/>
<checkbox id="VerifySSLHostName" label="Verify SSL Host Name" value="false" hidden="true" onchange="zenPage.doModified();"/>
<checkbox id="Exec32" label="Execute as 32-bit" value="false" hidden="true" onchange="zenPage.doModified();"/>
<text id="InitializationTimeout" label="Initialization Timeout" hidden="true" size="20" value="10" onchange="zenPage.doModified();"/> 
<text id="ConnectionTimeout" label="Connection Timeout" hidden="true" size="20" value="5" onchange="zenPage.doModified();"/> 
<spacer height="2"/>
</group>
</form>
</pane>
}

/// User clicked one of the Browse buttons.
/// Save the name of the textfield so that when you return you know which textfield to update.
ClientMethod browseSelect(name, wildcard) [ Language = javascript ]
{
	zenPage.getComponentById('browseselect').setValue(name);
	var Dir = zenPage.getComponentById(name).getValue();
	var url = '%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir);
	if (wildcard == "showdirectoryonly") url = url + '&showdirectoryonly=1';
	else  url = url + '&wildcard=' + wildcard;
	zenLaunchPopupWindow(url,'FileSelect','resizable,width=680,height=750');
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action == "ok") {
			var name = zenPage.getComponentById("browseselect").getValue();
			zenPage.getComponentById(name).setValue(value);
			this.doModified();
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	// Populate the Resource dropdown
	Set tRS = ##class(%ResultSet).%New("Security.Resources:List")
	Do tRS.Execute(,,$$$ServiceResourceType+$$$ApplicationResourceType+$$$UserResourceType)
	Set valueList = ""
	While tRS.Next() {
		Set name = tRS.GetData(1)
		If valueList = "" {
			Set valueList = name
		} Else {
			Set valueList = valueList_","_name
		}
	}
	Set (..%GetComponentById("Resource").displayList,..%GetComponentById("Resource").valueList) = valueList

	#; If a PID is purposely removed when this page is rendered, then set isNew to true.
	If ..PID = "" Set ..isNew = 1
	
	If ..isNew {
		Set ..lblTitle = $$$Text("Use the form below to create a new External Language Server definition:")
	} Else {
		Set ..lblTitle = $$$Text("Use the form below to edit an existing External Language Server definition:")
	}
		
	// Load data into fields
	Set tSC = ..LoadData(%page.PID)

	if ##class(%Net.Remote.Service).IsGatewayRunning("",..PID) && (..%GetComponentById("Type").value '= "Remote") {
		set ..IsEditForm = 0
	}

	If tSC '= 1 {
		Set ..%GetComponentById("idRespond").value = tSC,..%GetComponentById("btnSave").disabled = 1
	} 
	Quit $$$OK
}

ClassMethod RemoveType(Type As %String, pListIn As %String) As %String
{
	set tListOut = ""
	for i=1:1:$length(pListIn,",") {
		Set tGW = $s($piece(pListIn,",",i)'=Type:$piece(pListIn,",",i),1:"")
		Set tListOut = tListOut _ tGW
		If (i '= $length(pListIn,",")) && (tGW '= "") {
			Set tListOut = tListOut _ ","	
		}
	}
	quit tListOut
}

///  Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set tSC = ##super(.pDisplay,.pViewIcons,.pSortOptions,.pSearchBox,.pRibbonTitle,.pCommands)
	Quit:..IsEditForm tSC

	// commands: $LB(id,caption,help,onclick)
	Kill pCommands
	Set pCommands(1) = $LB("btnCancel",$$$Text("Close"),$$$Text("Return to the list of External Language Server definitions."),"zenPage.doCancel();")

	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	If ..isNew {
		Quit $$$Text("New External Language Server")
	} Else {
		Quit $$$Text("Edit External Language Server")
	}
}

ClientMethod toggleAdvancedSettings() [ Language = javascript ]
{
	var type = zenPage.getComponentById('Type').getValue();
	var newHidden = zen("AdvancedSettingsShow").hidden;
	var advancedSettings = ["id_LogFile","AllowedIPAddresses","Exec32","UseSharedMemory","id_Resource","SSLConfigurationServer","SSLConfigurationClient","VerifySSLHostName","InitializationTimeout","ConnectionTimeout"];
	for (var i=0; i<advancedSettings.length; i++) {
		name = advancedSettings[i]
		var hideThisOne = newHidden
		if (!hideThisOne) {
			if (type=="Remote") {
				// Remote type is special. Most of the fields are suppressed.
				if (name!="SSLConfigurationClient" && name!="VerifySSLHostName" && name!="ConnectionTimeout" && name!="id_Resource" && name!="UseSharedMemory") {
					hideThisOne = true;
				}
			} else {
				// This section is for non-Remote types, we decide based on field names
				switch (name) {
					case "SSLConfigurationServer":
					case "SSLConfigurationClient":
					case "VerifySSLHostName":
						// SSLConfigurationServer, SSLConfigurationClient and VerifySSLHostName are only shown in Python
						if (type!="Python") { hideThisOne = true; }
						break;
					case "Exec32":
						// Exec32 is only shown in .NET
						if (type!=".NET") { hideThisOne = true; }
					default:
						break;
				}
			}
		}
		zen(name).setHidden(hideThisOne);
	}
	zen("AdvancedSettingsShow").setHidden(!newHidden);
	zen("AdvancedSettingsHide").setHidden(newHidden);
	zen("advancedGroup").setProperty("enclosingClass",(newHidden?"":"EditForm"));
}

/// User changed Type. Show/hide client/server credentials related fields.
ClientMethod changeType() [ Language = javascript ]
{
	if (zenPage.getComponentById('Type').getValue() == "Java") {
		var hidejava = false;
		var hidenet = true;
		var hidepython = true;
		var hideaddress = true;
		var resource = "%Gateway_Object";
	}
	else if (zenPage.getComponentById('Type').getValue() == "XSLT") {
		var hidejava = false;
		var hidenet = true;
		var hidepython = true;
		var hideaddress = true;
		var resource = "%Gateway_Object";
	}
	else if (zenPage.getComponentById('Type').getValue() == "JDBC") {
		var hidejava = false;
		var hidenet = true;
		var hidepython = true;
		var hideaddress = true;
		var resource = "%Gateway_SQL";
	}
	else if (zenPage.getComponentById('Type').getValue() == "ODBC") {
		var hidejava = true;
		var hidenet = true;
		var hidepython = true;
		var hideaddress = true;
		var resource = "%Gateway_SQL";
	}
	else if (zenPage.getComponentById('Type').getValue() == "ML") {
		var hidejava = false;
		var hidenet = true;
		var hidepython = true;
		var hideaddress = true;
		var resource = "%Gateway_ML";
	}
	else if (zenPage.getComponentById('Type').getValue() == ".NET") {
		var hidejava = true;
		var hidenet = false;
		var hidepython = true;
		var hideaddress = true;
		var resource = "%Gateway_Object";
	}
	else if (zenPage.getComponentById('Type').getValue() == "Python") {
		var hidejava = true;
		var hidenet = true;
		var hidepython = false;
		var hideaddress = true;
		var resource = "%Gateway_Object";
	}
	else if (zenPage.getComponentById('Type').getValue() == "R") {
		var hidejava = false;
		var hidenet = true;
		var hidepython = true;
		var hideaddress = true;
		var resource = "%Gateway_Object";
	}
	else if (zenPage.getComponentById('Type').getValue() == "Remote") {
		var hidejava = true;
		var hidenet = true;
		var hidepython = true;
		var hideaddress = false;
		var resource = "%Gateway_Object";
	}
	else if (zenPage.getComponentById('Type').getValue() == "") {
		var hidejava = true;
		var hidenet = true;
		var hidepython = true;
		var hideaddress = false;
	}
	else {
		alert('Unexpected Server type in method changeType');
		return;
	}

	if (zen("AdvancedSettingsShow").hidden) zenPage.toggleAdvancedSettings();
	zenPage.getComponentById('Address').setHidden(hideaddress);
	
	zenPage.getComponentById('id_JavaHome').setHidden(hidejava);
	zenPage.getComponentById('id_ClassPath').setHidden(hidejava);
	zenPage.getComponentById('JVMArgs').setHidden(hidejava);

	zenPage.getComponentById('id_FilePath').setHidden(hidenet);
	zenPage.getComponentById('DotNetVersion').setHidden(hidenet);
	
	zenPage.getComponentById('id_PythonPath').setHidden(hidepython);
	zenPage.getComponentById('PythonOptions').setHidden(hidepython);
	
	if (!zenPage.getComponentById('Type').disabled) {
		// change to default Resource when we are in "New External Language Server" mode
		zenPage.getComponentById('Resource').setValue(resource);
	}
}

/// Validation handler for form.
ClientMethod formValidationHandler() [ Language = javascript ]
{
	var pass = true;
	if (!this.validateRequired(zenPage.getComponentById("Name"),pass,"S")) pass = false;
	if (!this.validateRequired(zenPage.getComponentById("Port"),pass,"S")) pass = false;
	return pass;
}

/// Get user input and send to server to save settings.
ClientMethod doSave() [ Language = javascript ]
{
	var pProxy = new zenProxy();

	try {
		//if (this.checkIsRunning()) return;
		if (!this.formValidationHandler()) {
			this.afterValidate();
			return;
		} 
		//Common properties to all types
		//Keep these in alphabetical order
		pProxy.AllowedIPAddresses=zenPage.getComponentById("AllowedIPAddresses").getValue();
		pProxy.ConnectionTimeout = zenPage.getComponentById("ConnectionTimeout").getValue();
		pProxy.InitializationTimeout = zenPage.getComponentById("InitializationTimeout").getValue();
		pProxy.LogFile = zenPage.getComponentById("LogFile").getValue();
		pProxy.Name = zenPage.getComponentById("Name").getValue();
		pProxy.Port = zenPage.getComponentById("Port").getValue();
		pProxy.Type = zenPage.getComponentById("Type").getValue();
		pProxy.Resource = zenPage.getComponentById("Resource").getValue();
		pProxy.SSLConfigurationServer = zenPage.getComponentById("SSLConfigurationServer").getValue();
		pProxy.SSLConfigurationClient = zenPage.getComponentById("SSLConfigurationClient").getValue();
		pProxy.VerifySSLHostName = zenPage.getComponentById("VerifySSLHostName").getValue();
		pProxy.UseSharedMemory = zenPage.getComponentById("UseSharedMemory").getValue();
		
		// Java,XSLT,JDBC,ML only parameters
		pProxy.ClassPath=zenPage.getComponentById("ClassPath").getValue();
		pProxy.JavaHome=zenPage.getComponentById("JavaHome").getValue();
		pProxy.JVMArgs=zenPage.getComponentById("JVMArgs").getValue();

		// .NET parameters
		pProxy.DotNetVersion=zenPage.getComponentById("DotNetVersion").getValue();
		pProxy.Exec32=zenPage.getComponentById("Exec32").getValue();
		pProxy.FilePath=zenPage.getComponentById("FilePath").getValue();

		// Python parameters
		pProxy.PythonOptions=zenPage.getComponentById("PythonOptions").getValue();
		pProxy.PythonPath=zenPage.getComponentById("PythonPath").getValue();

		// Remote parameters
		pProxy.Address = zenPage.getComponentById("Address").getValue();

		var proxy = this.SaveData(pProxy, this.isNew);
		this.afterSave(proxy);
	} 
  catch(ex) {
	alert("ERROR: " + ex);
	}
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	
	if ( this.IsEditForm == 0 ) {
		this.showMsg("You are in read-only mode!",1);
		zen("mainGroup").setProperty("disabled",true);
		zen("advancedGroup").setProperty("disabled",true);
		zen("id_LogFile").setProperty("labelClass","zenLabelDisabled");
		zen("id_ClassPath").setProperty("labelClass","zenLabelDisabled");
		zen("id_JavaHome").setProperty("labelClass","zenLabelDisabled");
	}

	// update hidden fields
	this.changeType();
}

/// Load values into fields.
Method LoadData(PID As %String) As %String
{
	Set $ZT="Error"
	Set %page.IsUnix = $zversion(1)=3
	If PID = "" {
		Set sys = ##class(Config.Gateways).%New()
		Set sys.Type = "Java"
	} ElseIf ##class(Config.Gateways).Exists(PID,.sys) {
		Set ..%GetComponentById("Name").disabled = 1
		Set ..%GetComponentById("Type").disabled = 1
	} Else {
		Set ..%GetComponentById("fld").hidden = 1
		Set ..InvalidParam = 1
		Quit $$$OK
	}

	Set ..%GetComponentById("AllowedIPAddresses").value = sys.AllowedIPAddresses
	Set ..%GetComponentById("ConnectionTimeout").value = sys.ConnectionTimeout
	Set ..%GetComponentById("InitializationTimeout").value = sys.InitializationTimeout
	Set ..%GetComponentById("LogFile").value = sys.LogFile
	Set ..%GetComponentById("Name").value = sys.Name
	Set ..%GetComponentById("Port").value = sys.Port
	Set ..%GetComponentById("Type").value = sys.Type
	Set ..%GetComponentById("Resource").value = sys.Resource
	Set ..%GetComponentById("SSLConfigurationServer").value = sys.SSLConfigurationServer
	Set ..%GetComponentById("SSLConfigurationClient").value = sys.SSLConfigurationClient
	Set ..%GetComponentById("VerifySSLHostName").value = sys.VerifySSLHostName
	Set ..%GetComponentById("UseSharedMemory").value = sys.UseSharedMemory

	// Java Server specific properties
	i (sys.Type="Java")||(sys.Type="XSLT")||(sys.Type="JDBC")||(sys.Type="ML")||(sys.Type="R") {
		Set ..%GetComponentById("ClassPath").value = sys.ClassPath
		Set ..%GetComponentById("JavaHome").value = sys.JavaHome
		Set ..%GetComponentById("JVMArgs").value = sys.JVMArgs
	} else {
		Set ..%GetComponentById("ClassPath").value = ""
		Set ..%GetComponentById("JavaHome").value = ""
		Set ..%GetComponentById("JVMArgs").value = ""
		
	}
	// .NET Server specific properties
	i sys.Type=".NET" {
		i sys.DotNetVersion'="" {
			Set ..%GetComponentById("DotNetVersion").value = sys.DotNetVersion
		} else {
			Set ..%GetComponentById("DotNetVersion").value = "N6.0"
		}
		i sys.Exec32'="" {
			Set ..%GetComponentById("Exec32").value = sys.Exec32
		} else {
			Set ..%GetComponentById("Exec32").value = 0
		}
		Set ..%GetComponentById("FilePath").value = sys.FilePath
	} else {
		Set ..%GetComponentById("DotNetVersion").value = "N6.0"
		Set ..%GetComponentById("Exec32").value = 0
		Set ..%GetComponentById("FilePath").value =""
	}
		
	// Python Server specific properties
	i sys.Type="Python" {
		Set ..%GetComponentById("PythonOptions").value = sys.PythonOptions
		Set ..%GetComponentById("PythonPath").value = sys.PythonPath
	} else {
		Set ..%GetComponentById("PythonOptions").value = ""
		Set ..%GetComponentById("PythonPath").value = ""
	}

	// Remote Server specific properties
	i sys.Type="Remote" {
		Set ..%GetComponentById("Address").value = sys.Address
	} else {
		Set ..%GetComponentById("Address").value = ""
	}

	// Other properties
	Set tAction = ..%GetComponentById("DotNetVersion")
	i %page.IsUnix {
		Set tAction.displayList = ".NET 6.0,.NET 7.0,.NET 8.0,.NET 5.0,"
		Set tAction.valueList = "N6.0,N7.0,N8.0,N5.0"
	} else {
		Set tAction.displayList = ".NET 6.0,.NET 7.0,.NET 8.0,Framework 4.6.2,Framework 3.5,.NET 5.0"
		Set tAction.valueList = "N6.0,N7.0,N8.0,F4.6.2,F3.5,N5.0"
	}
	Quit $$$OK
Error	///
	Set $ZT="" Do BACK^%ETN
	Quit $ZCVT($ZE,"O","HTML")
}

/// Save External Language Server definition to server
ClassMethod SaveData(pProxy As %ZEN.proxyObject, isNew As %Boolean) As %ZEN.proxyObject [ ZenMethod ]
{
	
	Set $ZT="Error"
	
	Set Name=$zstrip(pProxy.Name,"<>W")

	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.PID = Name
	Set tProxy.Message = ""
	Set tSC = $$$OK
	
	if ##class(%Net.Remote.Service).IsGatewayRunning("",Name) {
		set tProxy.ErrorMessage = $$$FormatText($$$Text("Saving error: server '%1' is running."),Name)
		quit tProxy
	}
	
	if isNew && ##class(Config.Gateways).Exists(Name) {
		set tProxy.ErrorMessage = $$$FormatText($$$Text("Server name '%1' already exists."),Name)
		quit tProxy
	}
	
	If ##class(Config.Gateways).Exists(Name) {
		Set sys = ##class(Config.Gateways).Open(Name)
	} Else {
		Set sys = ##class(Config.Gateways).%New()
		Set sys.Name = Name
	}
#;Set Type First
	Set sys.Type = $zstrip(pProxy.Type,"<>W")
	Set sys.AllowedIPAddresses = $zstrip(pProxy.AllowedIPAddresses,"<>W")
	Set sys.ConnectionTimeout = $zstrip(pProxy.ConnectionTimeout,"<>W")
	Set sys.InitializationTimeout = $zstrip(pProxy.InitializationTimeout,"<>W")
	Set sys.LogFile = $zstrip(pProxy.LogFile,"<>W")
	Set sys.Port = +$zstrip(pProxy.Port,"<>W")
	Set sys.Resource = $zstrip(pProxy.Resource,"<>W")
	Set sys.SSLConfigurationServer = pProxy.SSLConfigurationServer
	Set sys.SSLConfigurationClient = pProxy.SSLConfigurationClient
	Set sys.VerifySSLHostName = pProxy.VerifySSLHostName
	Set sys.UseSharedMemory = +$zstrip(pProxy.UseSharedMemory,"<>W")

	//Careful here, the types all map onto the same fields in storage (field1-Field3)
	//so make sure you set the properties by type.
	//
	//Java only properties
	i (sys.Type="Java")||(sys.Type="XSLT")||(sys.Type="JDBC")||(sys.Type="ML")||(sys.Type="R") {
		Set sys.ClassPath = $zstrip(pProxy.ClassPath,"<>W")
		Set sys.JavaHome = $zstrip(pProxy.JavaHome,"<>W")
		Set sys.JVMArgs = $zstrip(pProxy.JVMArgs,"<>W")
	}
	//.NET only properties
	i sys.Type=".NET" {
		Set sys.DotNetVersion = $zstrip(pProxy.DotNetVersion,"<>W")
		Set sys.Exec32 = $zstrip(pProxy.Exec32,"<>W")
		Set sys.FilePath = $zstrip(pProxy.FilePath,"<>W")
	}
	//Python only properties
	i sys.Type="Python" {
		Set sys.PythonOptions = $zstrip(pProxy.PythonOptions,"<>W")
		Set sys.PythonPath = $zstrip(pProxy.PythonPath,"<>W")
		Set sys.Field3=""
	}
	i sys.Type="Remote" {
		Set sys.Address = $zstrip(pProxy.Address,"<>W")
		Set sys.Field2=""	
		Set sys.Field3=""	
	}
	Set tSC = sys.%Save()
	If $$$ISERR(tSC) {
		Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
	} Else {
		Set tProxy.ok = 1
		Set tProxy.PID = Name
	}
	Kill sys
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	Quit tProxy
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

	Set tPageName = $$$Text("External Language Servers","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?PID="_..EscapeURL(..PID)_$S(NAMESPACE="":"",1:"&$NAMESPACE="_..EscapeURL(NAMESPACE))))
	Quit $$$OK
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
