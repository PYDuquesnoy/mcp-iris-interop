/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Class for Log Daemon Settings
Class %CSP.UI.Portal.Config.LogDaemon Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.Config.Advanced) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Config.LogDaemon.zen";

Parameter HELPADDRESS = "Home,Configuration,Log Daemon Settings";

Parameter EMSSERVICE = "Config";

/// Displayed name of this page.
Parameter PAGENAME = "Log Daemon";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

/// Subject name for the setting page. 
Property Subject As %String [ InitialExpression = "Logging" ];

Property Status As %Boolean;

Property StatusTimestamp As %TimeStamp;

Property DaemonPID As %Integer;

Method DaemonPIDGet() As %Integer
{
	Return ##class(SYS.LogDmn).Status()
}

Method StatusGet() As %Boolean
{
  set statusResult = ##class(SYS.LogDmn).Status()
	Return (statusResult > 0)
}

Method StatusTimestampGet() As %TimeStamp
{
	set unixSecs = ##class(%UTC).SecondsSinceUnixEpoch()
  Return ##class(%PosixTime).LogicalToTimeStamp(##class(%PosixTime).UnixTimeToLogical(unixSecs))
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane   xmlns="http://www.intersystems.com/zen"  cellVAlign="top" containerStyle="padding:10px">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<html OnDrawContent="DrawStatusComponent" />
<html>
<div>
<h2>Daemon Configuration</h2>
</div>
</html>
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<form id="fld">
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<select id="Enabled" label="Enabled" valueList="1,0" displayList="YES,NO"
hintClass="helpText" showEmpty="false" 
 onchange="zenPage.doModified();"/>
<text id="ChildProcessLaunchCommand" label="Child Process Launch Command" size="32" onchange="zenPage.doModified();"/>
<select id="Level" label="Level" valueList="FATAL,SEVERE,WARN,INFO,DEBUG,DEBUG2" displayList="FATAL,SEVERE,WARN,INFO,DEBUG,DEBUG2"
hintClass="helpText" showEmpty="false" 
 onchange="zenPage.doModified();"/>
<select id="Format" label="Format" valueList="NVP,JSON" displayList="NVP,JSON"
hintClass="helpText" showEmpty="false" 
 onchange="zenPage.doModified();"/>
<text id="Interval" label="Interval" size="5" 
 onchange="zenPage.doModified();"/>
 <text id="EventFilter" label="Event Filter" size="32" onchange="zenPage.doModified();"/>
</group>
</form>
</pane>
}

/// This method can be called by the doSave() function to handle what the ZenMethod of server Save returned. 
/// The method expects a proxy object to be passed.
/// result.ok = 1 indicates save is successful. result.Message is a message (not an error message) that should be displayed.
/// result.ok = 0 indicates save has failed. result.ErrorMessage should be displayed.
/// If result.ok = 1 and result.Message is null then the edit form is closed and the ParentURL is displayed.
/// Although this method is inherited from <class>%CSP.UI.Portal.Template</class>
/// we override it to prevent returning to the home page after click save for better UX
ClientMethod afterSave(result As %ZEN.proxyObject) [ Language = javascript ]
{
	if (result) {
		if (result.ok == 1){
			this.setModified(false);
			this.showMsg("Successfully updated Log Deamon Settings",0);
		} else {
			this.showMsg(result.ErrorMessage,1);
		}
	} else {
		this.showMsg($$$Text("Unexpected error while attempting to save"),1);
	}
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
  this.pollStatus();
}

Method DrawStatusComponent(arg) As %Status
{
	&html<
<div>
	<h2>Daemon Status</h2>
	<div id="daemon-state" class="flex-initial flex flex-col">
  	<div id="daemon-state-badge">
  	  #(..RenderStatusBadge(..Status, ..StatusTimestamp, ..DaemonPID))#
  	</div>
  <div>
  	<span id="daemon-state-timestamp" class="text-sm">
  	#(..RenderTimestampText(..Status, ..StatusTimestamp))#
  	</span>
  </div>
</div>
	>
	return $$$OK
}

ClassMethod RenderStatusBadge(status As %Boolean, timestamp As %TimeStamp, otherInfo As %String = "") As %String
{
	set html = "<div> The Log Daemon is <span style=""vertical-align:middle;"">"
  If (status) {
			set badge = "<span class=""c-pill c-pill--success"">Running</span>"
			set html = html_badge_"</span><span> (At PID: "_otherInfo_")</span>"
  } Else {
      set badge = "<span class=""c-pill c-pill--inactive"">Stopped</span>"
			set html = html_badge_"</span>"
	}
	set html = html_"</div>"
	return html
}

ClassMethod RenderTimestampText(status, timestamp) As %String
{
  Return "Status was last polled on "_timestamp_" UTC"
}

ClientMethod pollStatus() [ Language = javascript ]
{
  return setInterval(() => {
    let badge = document.getElementById("daemon-state-badge")
    if (badge != null) {
      badge.innerHTML = zenPage.RenderStatusBadgeZEN()
    }
    let timestampText = document.getElementById("daemon-state-timestamp")
    if (timestampText != null) {
      timestampText.innerHTML = zenPage.RenderTimestampTextZEN()
    }
  }, 1000)
}

Method RenderStatusBadgeZEN() As %String [ ZenMethod ]
{
  Return ..RenderStatusBadge(..Status, ..StatusTimestamp, ..DaemonPID)
}

Method RenderTimestampTextZEN() As %String [ ZenMethod ]
{
  Return ..RenderTimestampText(..Status, ..StatusTimestamp)
}

/// If any required field failed, the hint for the field will be turned to red. 
/// The first one failed should have focus.
ClientMethod validate() As %Boolean [ Language = javascript ]
{
	try {
		var pass = true;
		// if (!this.validateRequired(zen("Port"),pass,"S")) pass = false;
		return pass;
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Subclass can override.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..lblTitle = $$$Text("Use the form below to edit the log daemon settings for the instance")
	
	Set tSC = ..PopulateFields()
	If $$$ISERR(tSC) Quit tSC
	
	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	 Quit $$$Text("Log Daemon")
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

XData Style
{
<style type="text/css">
	.c-pill {
  	align-items: center;
		font-family: "Open Sans", Arial, Verdana, sans-serif;
		font-weight: bold;
		font-size: 11px;
  	display: inline-block;
  	height: 100%;
  	white-space: nowrap;
  	width: auto;

  	position: relative;
  	border-radius: 100px;
  	line-height: 1;
  	overflow: hidden;
  	padding: 0px 12px 0px 20px;
  	text-overflow: ellipsis;
		line-height: 1.25rem;
		color: #595959;
	
    word-break: break-word;
 
	}
  	.c-pill--success {
    	background: #b4eda0; }
    	.c-pill--success:before {
			border-radius: 50%;
    	content: '';
    	height: 10px;
    	left: 6px;
    	margin-top: -5px;
    	position: absolute;
    	top: 50%;
    	width: 10px;
      	background: #6BC167; }
  	.c-pill--inactive {
    	background: #BEBEBE; 
			padding:  0px 12px 0px 12px;
			}
</style>
}

}
