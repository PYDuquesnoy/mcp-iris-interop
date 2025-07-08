/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// New Remote Database Dialog for Management Portal
Class %CSP.UI.Portal.Dialog.RemoteDatabase Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

/// Displayed name of this page.
Parameter PAGENAME = "RemoteDatabase";

Parameter AUTONS As BOOLEAN = 0;

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Parameter EMSSERVICE = "Namespace";

/// User must hold at least operator privilege to use this dialog.
Parameter RESOURCE = "%Admin_Manage";

Parameter HELPID = "GSA_config_databases_remote";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Dialog.RemoteDatabase.zen";

/// Database for edit. Null if adding new database.
Property PID As %String(ZENURL = "PID");

Property SelectedServer As %String;

Property SelectedServerNotNormal As %Boolean [ InitialExpression = 0 ];

Property MsgDisabled As %String [ InitialExpression = {$$$Text("The selected server connection is disabled.")} ];

Property MsgNotConnected As %String [ InitialExpression = {$$$Text("The selected server cannot be reached.")} ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* Progress message style */
.progress { 
	color: green; 
	font-weight: bold;
}
/* style for title instructions */
div.Description	{
	font-size: 0.9em; 
	padding: 5px;
}
.labelText {
	font-size: 0.9em;
}
a.radioSetCaptionDisabled {
	color: black;
}
.zenLabelDisabled {
	color: #404040;
	font-weight: bold;
}
.comboboxTable th {
	background: #E0E0E0;
}
</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane id="body" xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<form cellStyle="padding:4px;" enclosingClass="EditForm" enclosingStyle="padding-top:2px;" labelPosition="left">
<dataCombo
id="Server"
queryClass="Config.ECPServers"
queryName="StatusList"
label="Remote Server"
size="40"
choiceColumn="1"
displayColumns="1,2,3,5"
auxColumn="6"
showEmpty="false"
hint="Required."
onchange="zenPage.changeServer(zenThis);"
maxRows="0"
/>
<label id="ServerWarning" controlClass="rednote" hidden="true" containerStyle="padding:0px;"/>
<radioSet id="selectList" 
label="Remote Directory"
displayList="Select databases from a list,Enter your own database specification"
valueList="1,0" value="1"
onchange="zenPage.changeSelectList(zenThis);"/>
<remoteDatabaseSelect
id="DirectorySelect"
queryClass="SYS.Database"
queryName="RemoteDatabaseListSMP"
label="Directory"
displayColumns="1,2"
valueColumn="2"
auxColumn="1"
choiceColumn="2"
maxRows="100000"
size="40"
hint="Required."
onchange="zenPage.changeDirectory(zenThis);"
disabled="true"
>
<parameter value="#(%page.SelectedServer)#"/>
</remoteDatabaseSelect>
<text id="Directory" label="Directory" hidden="true" size="60" hint="Required."/>
<text id="NameRemoteDatabase" label="Database Name" hint="Required."/>
<text id="StreamLocation" label="Stream Location" size="60"/>
</form>
</pane>
}

/// This is called when the template is first displayed;
/// This provides a chance to set focus etc.
ClientMethod onstartHandler() [ Language = javascript ]
{
	zen('Server').focus();
	zenPage.changeSelectList(zen('selectList'));
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.<br/>
/// If this returns false, then the action is cancelled.
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		return this.doSave();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return zen('NameRemoteDatabase').getValue();
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	var wd = zenGetWindowWidth() - 80;
	var ht = zenGetWindowHeight() - 210;
	if (wd < 100) wd = 100;
	if (ht < 100) ht = 100;
}

ClientMethod changeServer(dataCombo) [ Language = javascript ]
{
	zenPage.SelectedServer = dataCombo.getValue();
	zen('DirectorySelect').setValue('');
	zen('Directory').setValue('');
	zen('NameRemoteDatabase').setValue('');
	zen('StreamLocation').setValue('');
	var serverStatus = dataCombo.getAuxValue();
	if (serverStatus == "Disabled") {
		zenPage.disableDatabaseSelect(1);
	} else if ((serverStatus == "Invalid connection name") || (serverStatus == "Invalid") || (serverStatus == "Connection Failed")) {
		zenPage.disableDatabaseSelect(0);
	} else {
		zen('DirectorySelect').setDisabled(false);
		zenPage.SelectedServerNotNormal = false;
		zen('ServerWarning').setHidden(true);
	}
}

ClientMethod disableDatabaseSelect(flag) [ Language = javascript ]
{
	zen('DirectorySelect').setDisabled(true);
	zenPage.showServerWarning(flag);
}

ClientMethod showServerWarning(flag) [ Language = javascript ]
{
	if (flag == 0) {
		var msg = zenPage.MsgNotConnected;
	} else if (flag == 1) {
		var msg = zenPage.MsgDisabled;
	}
	zenPage.SelectedServerNotNormal = true;
	zen('ServerWarning').setValue(msg);
	zen('ServerWarning').setHidden(false);
}

ClientMethod changeDirectory(dataCombo) [ Language = javascript ]
{
	zen('Directory').setValue(dataCombo.getValue());
}

ClientMethod changeSelectList(radioSet) [ Language = javascript ]
{
	var v = radioSet.getValue() == 1;
	zen('DirectorySelect').setHidden(!v);
	zen('Directory').setHidden(v);
	if (!v) {
		zen('ServerWarning').setHidden(!v);
	} else if (zenPage.SelectedServerNotNormal) {
		zen('ServerWarning').setHidden(!v);
	}
	
	zen('DirectorySelect').setProperty("hintClass","helpText");
	zen('Directory').setProperty("hintClass","helpText");
	zen('Server').setProperty("hintClass","helpText");
	zen('NameRemoteDatabase').setProperty("hintClass","helpText");
}

ClientMethod validate() As %Boolean [ Language = javascript ]
{
	try {
		
		var pass = true;
		if (!this.validateRequired(zen("NameRemoteDatabase"),pass,"S")) pass = false;
		if (zen('selectList').getValue() == 1) {
			if (!this.validateRequired(zen("DirectorySelect"),pass,"S")) pass = false;
		} else {
			if (!this.validateRequired(zen("Directory"),pass,"S")) pass = false;
		}
		if (!this.validateRequired(zen("Server"),pass,"S")) pass = false;
		
		var nameRemote = zen('NameRemoteDatabase');
		var dbName = nameRemote.getValue();
		
		if ((dbName != '') && (dbName != this.PID)) {
			if (!this.CheckDBName(dbName)) {
				nameRemote.setProperty("hintClass","redText");
				nameRemote.setProperty("controlClass","zenInvalid");
				this.showMsg($$$Text('Database name is not unique.'),1);
				if (pass) this.FirstFailed = 'NameRemoteDatabase';
				pass = false;
			} else {
				nameRemote.setProperty("hintClass","helpText");
				nameRemote.setProperty("controlClass","");
			}
		}
		
		return pass;
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

ClientMethod doSave() [ Language = javascript ]
{
	try {
		this.resetMsg();
		if (!this.validate()) {
			var id = this.FirstFailed;
			if (id != "") zen(id).focus();
			return false;
		}
		var newName = zen("NameRemoteDatabase").getValue();
		if ((this.PID != "") && (newName != this.PID)) {
			var msg =  $$$Text("Are you sure you want to change the database name to %1?");
			msg = msg.replace(/%1/g,newName);
			if (!confirm(msg)) {
				zen("NameRemoteDatabase").focus();
				return false;
			}
		}
		
		var proxy = new zenProxy();
		proxy.Name = zen("NameRemoteDatabase").getValue();
		proxy.Server = zen("Server").getValue();
		proxy.Directory = zen("Directory").getValue();
		proxy.StreamLocation = zen("StreamLocation").getValue();
				
		var ok = this.SaveData(this.PID,proxy);
		if (ok != 1) {
			this.showMsg(ok,1);
			return false;
		}
		return true;		
	} catch (ex) {
		alert("Error: " + ex);
	}
}

/// Call server save method.
/// Subclass may override.
ClassMethod SaveData(PID As %String, pProxy As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	
	Try {
		Set Properties("Server") = pProxy.Server
		Set Properties("Directory") = pProxy.Directory
		Set Properties("StreamLocation") = pProxy.StreamLocation
		
		If PID = "" {
			Set tSC = ##class(Config.Databases).Create(pProxy.Name,.Properties)
			If $$$ISERR(tSC) Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		} Else {
			Set tSC = ##class(Config.Databases).Modify(PID,.Properties)
			If $$$ISERR(tSC) Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			
			If pProxy.Name '= PID {
				Set tSC = ##Class(Config.Databases).Rename(PID,pProxy.Name)
				If $$$ISERR(tSC) Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			}
		}
	} Catch Error {
		Set tSC = ..EvalResult(Error.AsStatus())
	}
	Quit tSC
}

/// Return 1 if the database name is OK
ClassMethod CheckDBName(Name As %String) As %Boolean [ ZenMethod ]
{
	Quit '##class(Config.Databases).Exists(Name)
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	If (..PID = "") {
		Quit $$$TextHTML("Create Remote Database")
	} Else {
		Quit $$$TextHTML("Edit Remote Database")
	}
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
	
	Set ..%GetComponentById("Server").columnHeaders = $$$Text("Name")_","_$$$Text("Address")_","_$$$Text("Port")_","_$$$Text("Status")
	
	If ..PID '= "" {
		Set tSC = ##class(Config.Databases).Get(..PID,.Properties)
		If $$$ISERR(tSC) {
			Quit $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
		}
		Set ..%GetComponentById("NameRemoteDatabase").value = ..PID
		Set tProperty = ""
		Set tProperty = $O(Properties(tProperty)) 
		While tProperty '= ""  {
			Set Component = ..%GetComponentById(tProperty)
			If $ISO(Component) {
				Set Component.value = Properties(tProperty)
				If ..IsEMSReadOnly Set Component.disabled = 1
			}
			Set tProperty = $O(Properties(tProperty)) 
		}
	}
	If (..PID '= "") {
		// hiding DB dropdown for edit:
		Set ..%GetComponentById("selectList").hidden = 1
		Set ..%GetComponentById("selectList").containerStyle = "padding:0px;"
		Set ..%GetComponentById("selectList").value = 0
		Set ..%GetComponentById("DirectorySelect").hidden = 1
		Set ..%GetComponentById("DirectorySelect").containerStyle = "padding:0px;"
		Set ..%GetComponentById("Directory").hidden = 0
	}
	
	Quit $$$OK
}

}
