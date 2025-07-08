/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Dialog popup for Zen Report Render Server actions.
Class %CSP.UI.Portal.Dialog.ZenReportPrintServerAction Extends %CSP.Portal.standardDialog [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Dialog.ZenReportPrintServerAction.zen";

/// Displayed name of this page.
Parameter PAGENAME = "Zen Report Print Server";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Parameter APPLYBUTTON = 0;

Parameter TYPE = 2;

Property Action As %ZEN.Datatype.string(ZENURL = "ACTION");

Property PID As %ZEN.Datatype.string(ZENURL = "PID");

Property parm1 As %ZEN.Datatype.string(ZENURL = "P1");

Property parm2 As %ZEN.Datatype.string(ZENURL = "P2");

Property Draw1 As %Boolean [ InitialExpression = 1 ];

Property Draw2 As %Boolean [ InitialExpression = 0 ];

Property Draw3 As %Boolean [ InitialExpression = 0 ];

Property Draw4 As %Boolean [ InitialExpression = 0 ];

Property filename As %String;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
body {
	margin: 0px;
	overflow: auto;
}
.txt {
	font-size: 0.9em;
	white-space: pre-wrap;
}
pre {
	white-space: pre-wrap;
	word-wrap: break-word;
}
.boxed {
	border: 1px solid black;
	padding-left: 5px;
}
#stats {
	font-size: 0.9em;
}
table.tActivity, table.tPingDetails {
	color: #606060;
	background: white;
	border: 1px solid black;
	padding: 0px;
	border-spacing: 0px;
	font-size: 0.8em;	
}
table td.tCaption, table th.tCaption {
	font-weight: bold;
	border-bottom: 1px solid darkgray;
	border-right: 1px solid darkgray;
	padding: 3px;
	white-space: nowrap;
}
table td.tValue {
	font-weight: normal;
	border-bottom: 1px solid darkgray;
	padding: 3px;
}
</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<spacer height="10" />
<vgroup id="id_LogFile" hidden="true">
<hgroup labelPosition="left" label="Display Contents of File:" labelClass="normal" cellVAlign="top" title="Fully qualified name of a file.">
<hidden name="browseselect" id="browseselect" />
<text id="LogFile" name="LogFile" size="70" value="" hint="After selecting a file, press Open to view its contents" title="Fully qualified name of a file." />
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('LogFile','*.*');" />
<spacer height="10" />
</hgroup>
<spacer height="10" />
<button caption="Open" controlClass="commandButton" containerStyle="padding-left:2px;" onclick="zenPage.drawLog();" />
<group id="id_NoFile" hidden="true">
<spacer height="5" />
<label label="The log file location is not currently specified." labelClass="normal" />
<label id="id_Info" label="" labelClass="normal" />
</group>
</vgroup>
<html id="Area1" OnDrawContent="DrawArea1" enclosingClass="txt" hidden="false" />
<spacer height="10" />
<html id="Area2" OnDrawContent="DrawArea2" hidden="true" />
<spacer height="10" />
<html id="Area3" OnDrawContent="DrawArea3" hidden="true" />
<spacer height="10" />
<html id="Area4" OnDrawContent="DrawArea4" hidden="true" />
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set ..%GetComponentById("btnCancel").hidden = 1 // Hide button "Cancel"
	If (%page.Action="start") || (%page.Action="stop") {
		//Set ..%GetComponentById("btnOK").hidden = 1
		//Set ..%GetComponentById("btnOK").controlClass = "commandButtonDisabled"
	}
	ElseIf %page.Action="log" {
		Set ..%GetComponentById("id_LogFile").hidden = 0
		Set r = ..GetServerObject()
		If $IsObject(r) {
			Set log = r.LogFile
			Set:log'="" log = log_".0"
			Set ..%GetComponentById("LogFile").value = log
			Set %page.filename = log
			If log="" {
				Set ..%GetComponentById("id_NoFile").hidden = 0
			}
		}
		// Adjust info for empty Log File according to platform Windows/Unix
		Set tHelp = ..GetLogFileHelp()
		Set ..%GetComponentById("id_Info").label = tHelp
	}
	Quit $$$OK
}

ClassMethod GetLogFileHelp() As %String [ Internal ]
{
	If $$$isWINDOWS {
		Quit $$$Text("On Windows servers, there may be log files with name printserver.log.* in the root directory.")
	}
	ElseIf $$$isUNIX {
		Quit $$$Text("On UNIX/Linux/MacOSX servers, in most cases it is necessary to provide a value for this field to avoid access issues. There may be log files with name printserver.log.* in the home directory of the user that the Print Server runs as, if such directory exists.")
	}
	Else {
		Quit ""
	}
}

/// Provide HTML content according to the action.
Method DrawArea1(pSeed As %String) As %Status
{
	If '%page.Draw1 Quit $$$OK

	If %page.Action="start" {
		Write $$$TextHTML("Please wait while this Print Server is being started."),"<br>"
		Write $$$TextHTML("The time taken depends on the configured initialization timeout."),"<br><hr>"
	}
	ElseIf %page.Action="stop" {
		Write $$$TextHTML("Please wait while this Print Server is being stopped."),"<br><hr>"
	}
	ElseIf %page.Action="verify" {
		Set r = ..GetServerObject()
		If $IsObject(r) {
			Do ..Verify(r.Port, r.PingPort, r.ConnectionTimeout)
		}
	}
	ElseIf %page.Action="stats" {
		Set r = ..GetServerObject()
		If $IsObject(r) {
			Do ..ViewActivity(r.Name, r.Port)
		}
	}
	ElseIf %page.Action="log" {
		Set file = %page.filename
		Do ..ViewLogContent(file)
	}

	Quit $$$OK
}

/// Provide HTML content according to the action.
Method DrawArea2(pSeed As %String) As %Status
{
	If '%page.Draw2 Quit $$$OK

	If %page.Action="start" {
		&html<<pre>>
		Set Name = %page.PID
		Set EscapeObj = ##class(%CSP.HTMLEscape).%New()
		Set tSC = ##class(%ZEN.Report.PrintServer).Start(Name, .State, .Return, 1)
		Kill EscapeObj
		If ($$$ISOK(tSC)) {
			If $G(State)=1 {
				Write !!,$$$TextHTML("The Print Server was already running.")
			}
			Else {		
				 If ($G(Return)["INFO: Ping Server Listening on port ") && ($G(Return)["INFO: Listening on port ") && ($G(Return)'["SEVERE: ") {
					 Write !!,$$$TextHTML("The Print Server has been successfully started.")
				 }
			}
		}
		ElseIf $G(Return)="" {
			Write !!,$$$TextHTML("The startup command did not receive any response.")
		}
		Else  {
			Write !!,$$$TextHTML("Please check the messages returned by the start up command.")
			Write !,$$$TextHTML("The Print Server may not have started successfully.")
		}
		&html<</pre>>
	}
	ElseIf %page.Action="stop" {
		&html<<pre>>
		Set Name = %page.PID
		Set EscapeObj = ##class(%CSP.HTMLEscape).%New()
		Set tSC = ##class(%ZEN.Report.PrintServer).Stop(Name, 1)
		Kill EscapeObj
		&html<</pre>>
	}
	ElseIf %page.Action="verify" {
	}
	ElseIf %page.Action="stats" {
	}
	ElseIf %page.Action="log" {
	}

	Quit $$$OK
}

/// User clicked one of the Browse buttons.
/// Save the name of the textfield so that when you return you know which textfield to update.
ClientMethod browseSelect(name, wildcard) [ Language = javascript ]
{
	zenPage.getComponentById('browseselect').setValue(name);
	var Dir = zenPage.getComponentById(name).getValue();
	var url = '%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir);
	if (wildcard == 'showdirectoryonly') url = url + '&showdirectoryonly=1';
	else  url = url + '&wildcard=' + wildcard;
	zenLaunchPopupWindow(url,'FileSelect','resizable,width=680,height=750,top=200,left=400');
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
				zenPage.getComponentById('LogFile').setValue(value);
			}
		} catch (ex) {
			alert("Error: " + ex);
		}
		break;
	}

	return true;
}

ClientMethod drawLog() [ Language = javascript ]
{
	zenPage.filename = zen('LogFile').value;
	var html = zen('Area1');
	html.refreshContents();
}

ClassMethod GetServerObject() As %ZEN.Report.RenderServer
{
	Set r = $$$NULLOREF
	If %page.PID="" {
		Write $$$TextHTML("The name of the Hot Server is missing.")
	}
	Else {
		Set r = ##class(%ZEN.Report.RenderServer).%OpenId(%page.PID)
		If '$IsObject(r) {
			Write $$$TextHTML("Unable to open the Hot Server configuration object.")
		}
	}
	Quit r
}

ClassMethod ViewLogContent(filename As %String = "")
{
	If $G(filename)="" Quit
	Set maxsize = 1*1024*1024 // 1MB
	&html<<br><div class="boxed">>
	If '##class(%File).Exists(filename) Write $$$FormatTextHTML($$$Text("File '%1' does not exist"),filename),"<br>",! Quit
	Write $$$TextHTML("Contents of file: "),"<b>",$zconvert(filename,"O","HTML"),"</b><pre>"
	Set Len = 0
 	Set stream = ##class(%FileCharacterStream).%New()
 	Set stream.Filename = filename
 	While 'stream.AtEnd {
 		Set line = stream.ReadLine()
 		&html<#($ZCVT(line,"O","HTML"))#>
 		Set Len = Len+$L(line)
 		If Len>maxsize &html<<br><i>#($$$TextHTML("Contents truncated after 1 MB characters."))#</i>> Quit
	}
	&html<</pre></div>>
	Quit
}

ClassMethod Verify(port As %String = "", pingport As %String = "", timeout As %String = "")
{
	Set state = ""
	// Check main port
	Write "<br>",$$$TextHTML("Checking main port")_" '",port,"': "
	If '$G(port) || ($G(port)>65535) {
		Write "<br>",$$$TextHTML("Error with the main port configuration!")
		Set PortCheck = "error"
		Set state = 4
	}
	Else {
		Set tDevice = "|TCP|"_+port
		Close tDevice Open tDevice:(:+port:"S"):0 Close tDevice
		If $T { Write $$$TextHTML("NOT IN USE") Set PortCheck = "free" }
		Else  { Write $$$TextHTML("IN USE") Set PortCheck = "ok" }
	}
	// Check ping port
	Write "<br><br>",$$$TextHTML("Checking ping port")_" '",pingport,"': "
	If '$G(pingport) || ($G(pingport)>65535) {
		Write "<br>",$$$TextHTML("Error with the ping port configuration!")
		Set PingPortCheck = "error"
		Set state = 4
	}
	Else {
		Set tDevice = "|TCP|"_+pingport
		Close tDevice Open tDevice:(:pingport:"S"):0 Close tDevice
		If $T { Write $$$TextHTML("NOT IN USE") Set PingPortCheck = "free" }
		Else  { Write $$$TextHTML("IN USE") Set PingPortCheck = "ok" }
	}
	// Check response to PING
	Set PingResponse = "no"
	If PingPortCheck="ok" {
		Write "<br><br>",$$$TextHTML("Checking response to PING:")," "
		Set:timeout<2 timeout = 2
		Set tSC = ##class(%ZEN.Report.Ping).ping(pingport, timeout, .mainport, .servertype, .memmax, .memcommitted, .memuse, .runtimename)
		If $$$ISOK(tSC) {
			// maximum memory available, the committed memory, amount of memory used, pid@hostname
			Write $$$TextHTML("OK")
			&html<<table class="tPingDetails" style="margin-left:40px;margin-top:10px;"><tr><th colspan="2" class="tCaption">#($$$TextHTML("PING Details"))#</th>
			<tr><td class="tCaption">#($$$TextHTML("Main port"))#</td><td class="tValue">#($G(mainport))#</td>
			<tr><td class="tCaption">#($$$TextHTML("Server type"))#</td><td class="tValue">#($G(servertype)_" "_$Case($G(servertype),0:$$$TextHTML("(Render Server)"),1:$$$TextHTML("(Queueing Render Server)"),2:$$$TextHTML("(Print Server)"),:""))#</td>
			<!-- PING does not return the fields below for Print Servers
			<tr><td class="tCaption">#($$$TextHTML("Maximum memory available"))#</td><td class="tValue">#($G(memmax)_" ")#</td>
			<tr><td class="tCaption">#($$$TextHTML("Committed memory"))#</td><td class="tValue">#($G(memcommitted)_" ")#</td>
			<tr><td class="tCaption">#($$$TextHTML("Memory used"))#</td><td class="tValue">#($G(memuse)_" ")#</td>
			<tr><td class="tCaption">#($$$TextHTML("Process"))#</td><td class="tValue">#($P($G(runtimename),"@",1)_" ")#</td>
			<tr><td class="tCaption">#($$$TextHTML("Host name"))#</td><td class="tValue">#($P($G(runtimename),"@",2)_" ")#</td>
			-->
			</table>>
			If $G(mainport)=port, $G(servertype)=..#TYPE { Set PingResponse = "yes" }
			Else  { Set PingResponse="wrong" }
		}
		Else {
			Write $$$TextHTML("NOT RESPONDING!")
			Write " (",$zconvert($system.Status.GetErrorText(tSC),"O","HTML"),")"
		}
	}
	Else {
		Write "<br><br>",$$$TextHTML("Response to PING cannot be checked!")
	}
	If state="" {
		// Determine state
		If (PingResponse="yes") {
			If PortCheck = "ok" { Set state = 1 }
			Else  { Set state = 3 }
		}
		ElseIf (PingResponse="wrong") {
			Set state = 5
		}
		Else {
			// Didn't try to PING or failed to get a response
			Set state = 2
			If PortCheck="free" {
				If PingPortCheck="free" { Set state = 0 }
			}
		}
	}
	Write "<br><br><b>",$$$TextHTML("State:")," ",$Case(state,0:$$$TextHTML("Inactive; Ready to be started"), 1:$$$TextHTML("Active; Responsive to PING"), 2:$$$TextHTML("Unresponsive to PING"), 3:$$$TextHTML("Troubled (main port is not in use but it is responsive to PING)"), 4:$$$TextHTML("Problem with main port and/or ping port configuration"), 5:$$$TextHTML("Mismatching main port and/or server type"), :"?"),"</b>"
	Quit
}

ClassMethod ViewActivity(name As %String = "", port As %String = "")
{
	Set repOK = +$G(^IRIS.Temp.ZRServer.Report(name,"report",1))
	Set repErr = +$G(^IRIS.Temp.ZRServer.Report(name,"report",0))
	Set msgNA = $$$TextHTML("N/A")
	&html<<div style="margin: 10px;"><b>#($$$TextHTML("Activity since system start:"))#</b>
	<table id="stats" class="tActivity" cellpadding="0" cellspacing="0">
	<tr><td class="tCaption">#("&nbsp;"_$$$TextHTML("Number of times started"))#</td><td class="tValue">#("&nbsp;"_+$G(^IRIS.Temp.ZRServer.StartStop(name,"start")))#</td></tr>
	<tr><td class="tCaption">#("&nbsp;"_$$$TextHTML("Number of failed attempts to start"))#</td><td class="tValue">#("&nbsp;"_+$G(^IRIS.Temp.ZRServer.StartStop(name,"startfailure")))#</td></tr>
	<tr><td class="tCaption">#("&nbsp;"_$$$TextHTML("Number of times stopped"))#</td><td class="tValue">#("&nbsp;"_+$G(^IRIS.Temp.ZRServer.StartStop(name,"stop")))#</td></tr>
	<tr><td class="tCaption">#("&nbsp;"_$$$TextHTML("Number of reports printed successfully"))#</td><td class="tValue">#("&nbsp;"_repOK)#</td></tr>
	<tr><td class="tCaption">#("&nbsp;"_$$$TextHTML("Average time per successful printing"))#</td><td class="tValue">#("&nbsp;"_$S(repOK:$J(+$G(^IRIS.Temp.ZRServer.Report(name,"report",1,"duration"))/repOK,0,1),1:msgNA))#</td></tr>
	<tr><td class="tCaption">#("&nbsp;"_$$$TextHTML("Number of reports with error"))#</td><td class="tValue">#("&nbsp;"_repErr)#</td></tr>
	<tr><td class="tCaption">#("&nbsp;"_$$$TextHTML("Average time per errored report"))#</td><td class="tValue">#("&nbsp;"_$S(repErr:$J(+$G(^IRIS.Temp.ZRServer.Report(name,"report",0,"duration"))/repErr,0,1),1:msgNA))#</td></tr>
	</table></div>>
	Quit
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $S(%page.Action="start":$$$TextHTML("Start Print Server"),%page.Action="stop":$$$TextHTML("Stop Print Server"),%page.Action="verify":$$$TextHTML("Verify State"),%page.Action="stats":$$$TextHTML("Activity Information"),%page.Action="log":$$$TextHTML("View Log File"),1:"?")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$FormatText($$$Text("Zen Report Print Server Name: %1"),..EscapeHTML(%page.PID))
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// If the user presses the ENTER key, this popup window will close.
ClientMethod onkeydownHandler(evt) [ Language = javascript ]
{
	if (evt.keyCode == zenESC) {
		zenPage.dialogFinish();
	}
	else if (evt.keyCode == zenENTER && zenPage.Action != 'log') {
		zenPage.dialogFinish();
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (zenPage.Action == 'start' || zenPage.Action == 'stop') {
		//zenSetProp('btnOK','controlClass','commandButtonDisabled');
		//zenSetProp('btnOK','hidden',true);
		zenPage.Draw2 = 1;
		var html = zen('Area2');
		zenSetProp('Area2','hidden',false);
		//setTimeout(function() { html.refreshContents(); }, 50);
	    html.refreshContents();
	    //zenSetProp('btnOK','controlClass','commandButton');
	    //zenSetProp('btnOK','hidden',false);
	}
}

/// If user closes the window after starting or stopping a server, simulate that button OK was pressed.
ClientMethod onunloadHandler() [ Language = javascript ]
{
	if (zenPage.Action == 'start' || zenPage.Action == 'stop') {
		zenPage.dialogFinish();
	}
	return true;
}

}
