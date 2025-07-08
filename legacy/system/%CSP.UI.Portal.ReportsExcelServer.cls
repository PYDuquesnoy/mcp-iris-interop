/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Management Portal - Create or edit/manage a Reports Excel Server.
Class %CSP.UI.Portal.ReportsExcelServer Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

/// Displayed name of this page.
Parameter PAGENAME = "Reports Excel Server";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.ReportsExcelServer.zen";

Parameter HELPADDRESS = "Home,Configuration,Reports Excel Servers,New Reports Excel Server";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.ReportsExcelServers.zen";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter JSINCLUDES = "zenCSLM.js";

Parameter RECENT = 0;

/// Indicates an Excel Server
Parameter TYPE = 3;

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property isNew As %ZEN.Datatype.boolean(ZENURL = "isNew") [ InitialExpression = 0 ];

/// Is the current print server running
Property IsRunning As %Boolean [ InitialExpression = 0 ];

Property msgConfirmRunning As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("This Reports Excel Server is currently running! In order to edit, you must stop it first.")} ];

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
<form id="fld">
<label id="idRespond" enclosingClass="errorNote" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<spacer height="2px"/>
<group id="idForm" enclosingClass="EditForm" cellStyle="padding:5px;padding-bottom:0px;" labelPosition="left" hidden="false">
 <text id="Name" label="Name" size="20" value="" hint="Required." title="Name that uniquely identifies this Reports Server definition." onchange="zenPage.doModified();" />
 <text id="Server" hidden="true" label="Server Machine" size="20" value="127.0.0.1" readOnly="true" title="Host name or IP address of the machine where the JVM is located.  Currently we only support the local machine so this field is read-only." onchange="zenPage.doModified();" />
 <text id="Port" label="Port" size="20" hint="Required."  title="TCP port number for communication with the Excel Server." onchange="zenPage.doModified();" />
 <text id="PingPort" label="Ping Port" size="20" hint="Required."  title="TCP port number for pinging the Excel Server." onchange="zenPage.doModified();" />
 <text id="NumThreads" label="Num. Threads" size="20" value="5" hint=""  title="Number of JVM threads dedicated for report printing." onchange="zenPage.doModified();" />
 <text id="NumPingThreads" label="Num. Ping Threads" size="20" value="5" hint=""  title="Number of JVM threads dedicated for PING." onchange="zenPage.doModified();" />
<select id="LogLevel" label="Log Level" valueList="0,1,2,3" displayList="No logging,Log errors,Log warnings,Log info" showEmpty="false" value="3" onchange="zenPage.doModified();zenPage.changeLogLevel();" hint="" title="What kind of information to include in the log file." /> 
<fieldSet id="id_LogOptions" legend="" enclosingClass="normal" containerStyle="padding:2px;" label="Log Options" labelPosition="left" title="Settings that apply to the log file.">
 <hgroup id="id_LogFile" labelPosition="left" valign="middle" label="Log File" labelClass="normal" title="Fully qualified name of the log file.">
<text id="LogFile" size="70" valign="middle" maxlength="260" hint="" onchange="zenPage.doModified();" title="Fully qualified name of the log file." />
<button id="LogDirBrowse" caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('LogFile','*.*');" />
</hgroup>
 <text id="MaxLogFileSize" label="Max. File Size" labelClass="normal" size="20" value="32000" valign="middle" hint="" title="Maximum size, in bytes, for each log file. The default is 32000 bytes and the maximum allowed is 2147483647 bytes (2 GB). A value of 0 indicates no maximum defined." onchange="zenPage.doModified();" />
 <text id="LogRotationCount" label="Rotation Count" labelClass="normal" size="20" value="100" valign="middle" hint="" title="Number of log files accumulated before we recycle through log files. The default is 100. A numerical suffix is automatically added to the specified logfile name, to enable log rotation (n=0 for the current log)." onchange="zenPage.doModified();" />
</fieldSet>
<text id="InitializationTimeout" label="Initialization Timeout" size="20" value="5" hint="" title="Number of seconds to wait for the Excel Server to start up." onchange="zenPage.doModified();" /> 
<text id="ConnectionTimeout" label="Connection Timeout" size="20" value="5" hint="" title="Number of seconds to wait for a connection to be established with the Excel Server." onchange="zenPage.doModified();" /> 
<hgroup id="id_JavaHome" hidden="true" labelPosition="left" label="JavaHome" cellVAlign="top" title="Directory that is the JavaHome of the JVM to be used by this Excel Server.  If there is a default JVM on the machine this field may be left blank.">
<text id="JavaHome" size="70" maxlength="260" hint="" onchange="zenPage.doModified();" />
<button id="JavaHomeBrowse" caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('JavaHome','showdirectoryonly');" />
</hgroup>
<text id="JVMArgs" hidden="true" label="JVM Additional Args." size="70" hint="" title="Optional additional arguments to be passed to the JVM." onchange="zenPage.doModified();" /> 
<spacer height="2px" />
</group>
</form>
 <html id="AdditionalInfo" OnDrawContent="DrawInfo" hidden="true" />
</pane>
}

/// User clicked one of the Browse buttons.
/// Save the name of the textfield so that when you return you know which textfield to update.
ClientMethod browseSelect(name, wildcard) [ Language = javascript ]
{
	zenPage.getComponentById('browseselect').setValue(name);
	var Dir = zenPage.getComponentById(name).getValue();
	var url = '%ZEN.Dialog.fileSelect.zen?Dir='+Dir;
	if (wildcard == 'showdirectoryonly') url = url + '&showdirectoryonly=1';
	else  url = url + '&wildcard=' + wildcard;
	zenLaunchPopupWindow(url,'FileSelect','resizable,width=600,height=700');
}

/// User changed the log level. Hide log options if no logging was selected.
ClientMethod changeLogLevel() [ Language = javascript ]
{
	var ll = zen('LogLevel').getValue();
	if (ll != '0') {
		zenSetProp('id_LogOptions','hidden',false);
	}
	else {
		zenSetProp('id_LogOptions','hidden',true);
	}
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if ((this.isNew == 1) || this.InvalidParam) {
		this.disableCommandButton("btnDelete");
		this.disableCommandButton("btnStart");
		this.disableCommandButton("btnStop");
		this.disableCommandButton("btnVerify");
		this.disableCommandButton("btnActivity");
		this.disableCommandButton("btnLog");
	} else {
		if (this.IsRunning == 1) {
			this.disableCommandButton("btnSave");
			this.disableCommandButton("btnDelete");
			this.disableCommandButton("btnStart");
		} else {
			this.disableCommandButton("btnStop");
			self.document.getElementById("command_btnDelete").className = "commandButtonRemove";
		} 
	}
	if (zen("idRespond").getValue() != "") {
		this.disableCommandButton("btnSave");
		zen("idRespond").setHidden(false);
	}
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {

	case 'FileSelect':
		try {
			if (action == "ok") {
				var name = zenPage.getComponentById("browseselect").getValue();
				zenPage.getComponentById(name).setValue(value);
				this.doModified();
			}
		} catch (ex) {
			alert("Error: " + ex);
		}
		break;

	case 'StartServer':
		self.document.location.reload();
		break;

	case 'StopServer':
		self.document.location.reload();
		break;

	case 'ShowLog':
		break;
	}
	
	return true;
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	If ..PID = "" Set ..isNew = 1
	If ..isNew = 1 {
		Set ..lblTitle = $$$Text("Use the form below to create a new Reports Excel Server definition:")
		Set ..IsRunning = 0
	} Else {
		Set ..lblTitle = $$$Text("Use the form below to manage an existing Reports Excel Server definition:")
	}

	Set (..LocatorHeader,..StdTitle) = $$$Text("Reports Excel Server")

	// Adjust tooltip for Log File according to platform Windows/Unix
	Set tHelp = ..GetLogFileHelp()
	Set ..%GetComponentById("id_LogFile").title = tHelp
	Set ..%GetComponentById("LogFile").title = tHelp

	// Load data into fields
	Set tMsg = ..LoadData(..PID)
	If tMsg'="" {
		Set ..%GetComponentById("idRespond").value = tMsg
	}

	// If print server is currently running, then do not allow edit.
	If ..IsRunning {
		Set ..%GetComponentById("idRespond").value = $$$Text(" This Excel Server is currently running.")
		For tProperty = "Name","Server","Port","PingPort","NumThreads","NumPingThreads","LogLevel","id_LogOptions","InitializationTimeout","ConnectionTimeout","id_JavaHome","JVMArgs" {
			Set ..%GetComponentById(tProperty).disabled = 1
		}
	}

	Set ..%GetComponentById("AdditionalInfo").hidden = 0

	Quit $$$OK
}

Method %OnGetTitle() As %String
{
	If ..isNew = 1 {
		Quit $$$Text("New Reports Excel Server")
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
	if (!this.validateRequired(zenPage.getComponentById("Port"),pass,"N")) pass = false;
	if (!this.validateRequired(zenPage.getComponentById("PingPort"),pass,"N")) pass = false;
	return pass;
}

/// Check if print server is running.
ClientMethod checkIsRunning() [ Language = javascript ]
{
	var isrunning = 0;
	if (this.IsRunning == 0) return isrunning;
	alert(this.msgConfirmRunning);
	return 1;
}

/// Load values into fields.
Method LoadData(PID As %String) As %String
{
	Set ret = ""
	Try {
		If PID = "" {
			Set sys = ##class(%ZEN.Report.ExcelServer).%New()
		}
		ElseIf ##class(%ZEN.Report.ExcelServer).%ExistsId(PID) {
			Set sys = ##class(%ZEN.Report.ExcelServer).%OpenId(PID)
			Set ..%GetComponentById("Name").disabled = 1
			Set state = ##class(%ZEN.Report.ExcelServer).GetState(sys.Port,sys.PingPort,sys.ConnectionTimeout)
			If (state=4) || (state=5) {
				Set ..%GetComponentById("idRespond").value = " "_$$$Text("Error state, mismatch or invalid configuration - click button [Verify] for details")
			}
			If (state=0) || (state=4) || (state=5) {
				Set %page.IsRunning = 0
			}
			Else {
				Set %page.IsRunning = 1
			}
		}
		Else {
			Set ..%GetComponentById("fld").hidden = 1
			Set ..InvalidParam = 1
			Set ret = $$$Text("Invalid Server Name")
		}
		If ..InvalidParam = 0 {
			Set ..%GetComponentById("Name").value = sys.Name
			Set ..%GetComponentById("Server").value = sys.Server
			Set ..%GetComponentById("Port").value = sys.Port
			Set ..%GetComponentById("PingPort").value = sys.PingPort
			Set ..%GetComponentById("NumThreads").value = sys.NumThreads
			Set ..%GetComponentById("NumPingThreads").value = sys.NumPingThreads
			Set ..%GetComponentById("LogLevel").value = sys.LogLevel
			Set ..%GetComponentById("LogFile").value = sys.LogFile
			Set ..%GetComponentById("MaxLogFileSize").value = sys.MaxLogFileSize
			Set ..%GetComponentById("LogRotationCount").value = sys.LogRotationCount
			If sys.LogLevel=0 {
				Set ..%GetComponentById("id_LogOptions").hidden = 1
			}
			Set ..%GetComponentById("InitializationTimeout").value = sys.InitializationTimeout
			Set ..%GetComponentById("ConnectionTimeout").value = sys.ConnectionTimeout
			Set ..%GetComponentById("JavaHome").value = sys.JavaHome
			Set ..%GetComponentById("JVMArgs").value = sys.JVMArgs
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
		if (this.checkIsRunning()) return;
		if (!this.formValidationHandler()) {
			this.afterValidate();
			return;
		}		
		zenPage.getComponentById("idRespond").setValue("");
		var Name = zenPage.getComponentById("Name").getValue();
		var Server = zenPage.getComponentById("Server").getValue();
		var Port = zenPage.getComponentById("Port").getValue();
		var PingPort = zenPage.getComponentById("PingPort").getValue();
		var NumThreads = zenPage.getComponentById("NumThreads").getValue();
		var NumPingThreads = zenPage.getComponentById("NumPingThreads").getValue();
		var LogLevel = zenPage.getComponentById("LogLevel").getValue();
		var LogFile = zenPage.getComponentById("LogFile").getValue();
		var MaxLogFileSize = zenPage.getComponentById("MaxLogFileSize").getValue();
		var LogRotationCount = zenPage.getComponentById("LogRotationCount").getValue();
		var InitializationTimeout = zenPage.getComponentById("InitializationTimeout").getValue();
		var ConnectionTimeout = zenPage.getComponentById("ConnectionTimeout").getValue();
		var JavaHome = zenPage.getComponentById("JavaHome").getValue();
		var JVMArgs = zenPage.getComponentById("JVMArgs").getValue();

		var proxy = this.SaveData(this.PID, Name, Server, Port, PingPort, NumThreads, NumPingThreads, LogLevel, LogFile, MaxLogFileSize, LogRotationCount, InitializationTimeout, ConnectionTimeout, JavaHome, JVMArgs);
		this.afterSave(proxy);
		
	} 
  catch(ex) {
	alert("Error in doSave: " + ex);
	}
}

/// Save Reports Excel Server definition.
ClassMethod SaveData(PID, Name, Server, Port, PingPort, NumThreads, NumPingThreads, LogLevel, LogFile, MaxLogFileSize, LogRotationCount, InitializationTimeout, ConnectionTimeout, JavaHome, JVMArgs) As %ZEN.proxyObject [ ZenMethod ]
{
	Try {	
		#dim sys as %ZEN.Report.ExcelServer
		#; Initialize return proxy object
		Set tProxy = ##class(%ZEN.proxyObject).%New()
		Set tProxy.ok = 0
		Set tProxy.PID = PID
		Set tProxy.Message = ""
		Set tSC = $$$OK
		If PID'="",##class(%ZEN.Report.ExcelServer).%ExistsId(PID) {
			Set sys = ##class(%ZEN.Report.ExcelServer).%OpenId(PID)
		}
		Else {
			Set sys = ##class(%ZEN.Report.ExcelServer).%New()
			Set sys.Name = $zstrip(Name,"<>W")
		}
		Set sys.Server = $zstrip(Server,"<>W")
		Set sys.Port = $zstrip(Port,"<>W")
		Set sys.PingPort = $zstrip(PingPort,"<>W")
		Set sys.NumThreads = $zstrip(NumThreads,"<>W")
		Set sys.NumPingThreads = $zstrip(NumPingThreads,"<>W")
		Set sys.LogLevel = $zstrip(LogLevel,"<>W")
		Set sys.LogFile = $zstrip(LogFile,"<>W")
		Set sys.MaxLogFileSize = $zstrip(MaxLogFileSize,"<>W")
		Set sys.LogRotationCount = $zstrip(LogRotationCount,"<>W")
		Set sys.InitializationTimeout = $zstrip(InitializationTimeout,"<>W")
		Set sys.ConnectionTimeout = $zstrip(ConnectionTimeout,"<>W")
		Set sys.JavaHome = $zstrip(JavaHome,"<>W")
		Set sys.JVMArgs = $zstrip(JVMArgs,"<>W")
		Set tSC = sys.%Save()
		If $$$ISERR(tSC) {
			Set tProxy.ErrorMessage = $System.Status.GetErrorText(tSC)
		}
		Else {
			Set tProxy.ok = 1
			Set tProxy.PID = sys.%Id()
		}
	}
	Catch {
		Do BACK^%ETN
		Set tProxy.ErrorMessage = $ZE
	}
	Quit tProxy
}

/// Delete print server definition and return to the list of print servers.
ClientMethod deleteServer() [ Language = javascript ]
{
	if (!confirm($$$Text("Do you wish to permanently delete this Reports Excel Server?"))) return;
	try {
		var msg = zenPage.DeleteExcelServer(zenPage.PID);
		if (msg == '') {
			alert($$$Text("Deleted"));
			zenPage.doCancel();
		} else {
			this.showMsg(msg);
		}
	}
	catch(ex) {
		alert("Error in deleteServer: " + ex);
	}
}

/// Delete Reports Excel Server definition.
ClassMethod DeleteExcelServer(PID As %String) As %String [ ZenMethod ]
{
	Set tMsg = ""
	Try {
		Set tSC = ##class(%ZEN.Report.ExcelServer).%DeleteId(PID)
		If $$$ISERR(tSC) {
			Set tMsg = $system.Status.GetErrorText(tSC)
		}
	}
	Catch {
		Do BACK^%ETN
		Set tMsg = $ZE
	}
	Quit tMsg
}

/// Start the Excel Server.
ClientMethod startServer() [ Language = javascript ]
{
	if (!confirm($$$Text("Do you wish to start this Reports Excel Server?"))) return;
	zenLaunchPopupWindow('%CSP.UI.Portal.Dialog.ReportsExcelServerAction.zen?PID=' + encodeURIComponent(zenPage.PID) + '&ACTION=start','StartServer','resizable,width=900,height=700');
	return;
}

/// Stop the Excel Server.
ClientMethod stopServer() [ Language = javascript ]
{
	if (!confirm($$$Text("Do you really wish to stop this Reports Excel Server?"))) return;
	zenLaunchPopupWindow('%CSP.UI.Portal.Dialog.ReportsExcelServerAction.zen?PID=' + encodeURIComponent(zenPage.PID) + '&ACTION=stop','StopServer','resizable,width=900,height=700');
	return;
}

ClientMethod verify() [ Language = javascript ]
{
	zenLaunchPopupWindow('%CSP.UI.Portal.Dialog.ReportsExcelServerAction.zen?PID=' + encodeURIComponent(zenPage.PID) + '&ACTION=verify','ShowLog','resizable,width=900,height=700');
}

ClientMethod showStats() [ Language = javascript ]
{
	zenLaunchPopupWindow('%CSP.UI.Portal.Dialog.ReportsExcelServerAction.zen?PID=' + encodeURIComponent(zenPage.PID) + '&ACTION=stats','ShowLog','resizable,width=900,height=700');
}

ClientMethod showLog() [ Language = javascript ]
{
	zenLaunchPopupWindow('%CSP.UI.Portal.Dialog.ReportsExcelServerAction.zen?PID=' + encodeURIComponent(zenPage.PID) + '&ACTION=log','ShowLog','resizable,width=900,height=700');
}

/// Provide additional information below the settings form, according to the button pressed.
Method DrawInfo(pSeed As %String) As %Status
{
	If $G(pSeed)="start" {
		&html<
		<div class="boxedArea"><pre>>
		Set Name = %page.PID
		Set tSC = ##class(%ZEN.Report.ExcelServer).Start(Name, .Return, 1)
		If ($$$ISOK(tSC)) && ($G(Return)="") {
			Write !,"Successfully started"
		}
		&html<</pre></div>>
	}
	ElseIf $G(pSeed)="stop" {
		&html<
		<div class="boxedArea"><pre>>
		Set Name = %page.PID
		Set tSC = ##class(%ZEN.Report.ExcelServer).Stop(Name, 1)
		If $$$ISERR(tSC) {
			Write "<br>",$ZCVT($system.Status.GetErrorText(tSC),"O","HTML")
		}
		Else  {
			Write "<br>Successfully stopped"
		}
		&html<</pre></div>>
	}

	Quit $$$OK
}

ClassMethod GetLogFileHelp() As %String [ Internal ]
{
	If $$$isWINDOWS {
		Quit $$$Text("Fully qualified name of the log file. If blank, log files with name ExcelServer.log will be created in the root directory.")
	}
	ElseIf $$$isUNIX {
		Quit $$$Text("Fully qualified name of the log file. In most cases it is necessary to provide a value for this field to avoid access issues. If blank, log files with name ExcelServer.log will be created in the home directory of the user that the Excel Server runs as, if such directory exists.")
	}
	Else {
		Quit $$$Text("Fully qualified name of the log file.")
	}
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

	Set tPageName = $$$Text("Reports Excel Servers","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?isNew="_..isNew_"&PID="_$ZCVT($ZCVT(..PID,"O","UTF8"),"O","URL")_"&"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_NAMESPACE)))
	Quit $$$OK
}

///  Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick,disabled)
	Set pCommands(1) = $LB("btnSave",$$$Text("Save"),$$$Text("Save the definition below."),"zenPage.doSave();")
	Set pCommands(2) = $LB("btnCancel",$$$Text("Cancel"),$$$Text("Return to the list of Excel Servers."),"zenPage.doCancel();")
	Set pCommands(3) = $LB("btnDelete",$$$Text("Delete"),$$$Text("Permanently delete this definition."),"zenPage.deleteServer();")
	Set pCommands(4) = $LB("btnStart",$$$Text("Start"),$$$Text("Start this Excel Server."),"zenPage.startServer();")
	Set pCommands(5) = $LB("btnStop",$$$Text("Stop"),$$$Text("Shutdown this Excel Server."),"zenPage.stopServer();")
	Set pCommands(6) = $LB("btnVerify",$$$Text("Verify"),$$$Text("Verify the state of this Excel Server."),"zenPage.verify();")
	Set pCommands(7) = $LB("btnActivity",$$$Text("Activity"),$$$Text("Display information about state, number of reports and average report time."),"zenPage.showStats();")
	Set pCommands(8) = $LB("btnLog",$$$Text("Log"),$$$Text("View the current log file."),"zenPage.showLog();")

	Quit $$$OK
}

}
