/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// Utility page that does the real work after being invoked from EnsPortal.Dialog.UpdateProduction.
/// That dialog captures and displays all output from the real work commands invoked here.
Class EnsPortal.StartStopFrame Extends EnsPortal.Template.standardPage [ System = 4 ]
{

/// User needs USE permissions on the %Ens_ProductionRun or the %Ens_ConfigItemRun resource to view this page.
Parameter RESOURCE = "%Ens_ProductionRun:USE,%Ens_ConfigItemRun:USE";

Parameter RECENT = 0;

ClassMethod OnPage() As %Status
{
	#dim tSC As %Status
	Set tProdName = $G(%request.Data("PRODUCTION",1))
	Set tAction = $G(%request.Data("ACTION",1),"missing")
	If $IsObject($get(%session)) {
		Do %session.Unlock()
	}
	Set tMayStartStop = $system.Security.Check("%Ens_ProductionRun","USE")
	Set tMayUpdate = (tMayStartStop || $system.Security.Check("%Ens_ConfigItemRun","USE"))
	&html<<html>
<head>
<style type="text/css">
pre {
	background: white;
	margin: 0px;
	padding: 4px;
	white-space: pre-line;
	word-wrap: break-word;
}
.largerText {
	font-size: 14px;
	font-style: bold;
}
.commandButton {
    background: none repeat scroll 0 0 #356B8D;
    border-color: lightgray gray gray lightgray;
    border-radius: 5px 5px 5px 5px;
    border-style: solid;
    border-width: 1px 2px 2px 1px;
    color: #E0E0E0;
    cursor: pointer;
    padding: 3px 10px;
    text-decoration: none;
}
.commandButton:hover {
	background: rgb(53,107,141);
	color: white;
	background-image: url(portal/button_hover.png);
	background-repeat: repeat-x;
}
.commandButtonDisabled {
	background: darkgray;
	color: #545454;
	text-decoration: none;
	padding: 3px;
	padding-left: 10px;
	padding-right: 10px;
	border-radius: 5px;
	border-top: 1px solid lightgray;
	border-left: 1px solid lightgray;
	border-right: 2px solid gray;
	border-bottom: 2px solid gray;
}
</style>>
	Set tLT = "<"
	Write ..%StartScript()
	&js<
var portsArray = [];

function finishPage()
{
	var baseURL = '';
	var url = '';
	var useIRISTerm = (navigator.platform.indexOf("Win") != -1);
	if (useIRISTerm) {
		baseURL = 'iristerm:///console=cn_iptcp:';
	} else {
		baseURL = 'telnet://';
	}
	// Launch a iristerm/telnet console for each foreground job
	for (var i = 0; i #(tLT)# portsArray.length; i++) {
		var ipAddr = portsArray[i];
		url = baseURL + ipAddr;
		if (!useIRISTerm) url=url.replace(/\[/,':').replace(/\]/,'');
		// use setTimeout() with different time slots because Chrome ignores all but 
		// the first if they happen immediately
		setTimeout("launchTerminal('" + url + "','foreground_"+i+"');", i*50);
	}
	self.document.body.scrollTop = self.document.body.scrollHeight;
}

function launchTerminal(url,frameId)
{
	var frameWrapper = document.getElementById('launchFrameDiv');
	if (!frameWrapper) {
		frameWrapper = document.createElement('div');
		frameWrapper.setAttribute('id','launchFrameDiv');
		document.body.appendChild(frameWrapper);
		frameWrapper.style.display = 'none';
	}
	var dummyFrame = document.createElement('iframe');
	if (frameId) dummyFrame.setAttribute('id',frameId);
	frameWrapper.appendChild(dummyFrame);
	dummyFrame.src = url;	
}

function retryWithForceOption(url)
{
	var button = document.getElementById('btnForce');
	button.disabled = 'true';
	button.className = 'commandButtonDisabled';
	setTimeout(function() {
		self.document.location = url;
	}, 300);
	self.document.body.innerHTML='';
}

>
	Write ..%EndScript()
	&html<</head>
	<body topmargin="0" leftmargin="0" onload="finishPage();">>

	Set tSC = $$$OK
	Set tPermitted = 1
	If '(tMayStartStop || tMayUpdate) {
		Set tPermitted = 0
	}
	If tPermitted {
		Set tPermitted = $case(tAction,
								"start": tMayStartStop,
								"stop": tMayStartStop,
								"force": tMayStartStop,
								"recover": tMayStartStop,
								"update": tMayUpdate,
								"updateforce": tMayUpdate,
								: 0)
	}
	If (tAction '= "missing") && tPermitted {
		#dim tRestartingAnItem,tRestartedAnItem As %Boolean = 0
		Set $$$EnsJobLocal($$$CurrentClass)=1 ; signal to called code that it was called from the portal
		&html<<pre>>
		Set tTraceDevice=$G($$$JobTraceDevice,0), $$$JobTraceDevice=$IO
		Kill $$$EnsRuntime("FGTelnetPort") ; clean before starting
		If (tAction = "start") {
			Set tSC = ..StartProduction(tProdName)
		} ElseIf (tAction = "stop"){
			Set tSC = ..StopProduction(##class(Ens.Director).GetRunningProductionShutdownTimeout(),0)
		} ElseIf  (tAction = "update") {
			Set tRestartingAnItem = ($G(%request.Data("ITEMRESTART",1),0) = "true")
			#dim tRedirecting As %Boolean = 0
			#dim tIn As %String
			#dim tOutputStream As %Stream.TmpBinary
			#dim tSC1 As %Status
			#dim tIO As %Stream.Object
			#dim tLineNum As %Integer
			If tRestartingAnItem {
				Try {
					Set tOutputStream = ##class(%Stream.TmpBinary).%New()
					Set tSC1 = ##class(Ens.Util.IO).Redirect(.tIO,,tOutputStream)
					If $$$ISERR(tSC1){Do:$IsObject($G(tIO)) tIO.StopRedirect()  Set tRedirecting = 0} Else {Set tRedirecting = 1}
				} Catch {}
			}

			If $D(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"UpdateWarnings")) {
				Set tLineNum = $O(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"UpdateWarnings",""),1,tIn)
				While tLineNum '="" {
					Do ##class(Ens.Util.Trace).WriteTrace("nolog",$lg(tIn,1),$lg(tIn,2),$REPLACE($lg(tIn,3),"<","&lt;"))
					Set tLineNum = $O(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"UpdateWarnings",tLineNum),1,tIn)
				}
				Kill ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"UpdateWarnings")
			}

			If 'tRestartingAnItem {
				If $D(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"RestartStatus")) {
					Set tRestartedAnItem = 1
					Set tLineNum = $O(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"RestartStatus",""),1,tIn)
					While tLineNum '="" {
						Write $REPLACE(tIn,"<","&lt;") /* output from UpdateProduction ought not to include <script> but safeguard against temporary global access */
						Set tLineNum = $O(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"RestartStatus",tLineNum),1,tIn)
					}
					Kill ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"RestartStatus")
				}
			}
			
			Set tSC = ..UpdateProduction(##class(Ens.Director).GetRunningProductionUpdateTimeout(),0)
			
			If tRedirecting {
				Try {
					Do tIO.StopRedirect()
					Do tOutputStream.Rewind()
					Kill ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"RestartStatus")
					While 'tOutputStream.AtEnd {
    					Set tIn = tOutputStream.Read(4000)
    					Write tIn
    					If $$$ISOK(tSC) Set ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"RestartStatus",$I(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"RestartStatus")))=tIn    					
  					}
				} Catch {}
			}
		} ElseIf  (tAction = "recover") {
			Set tSC = ..RecoverProduction()
		} ElseIf  (tAction = "force") {
			Set tSC = ..StopProduction(10,1)
		} ElseIf  (tAction = "updateforce") {
			Set tSC = ..UpdateProduction(10,1)
		}
		If 0=tTraceDevice { Kill $$$JobTraceDevice } Else { Set $$$JobTraceDevice=tTraceDevice } 
		If $$$ISERR(tSC) {
			Set Err = $$$Text("Error")
			Set tFinishedMsg = "<span style=""color:red;"">"_Err_"</span>"
		}
		&html<</pre>>
		Kill $$$EnsJobLocal($$$CurrentClass)

		#; Write out list of FG job telnet ports
		If $Case(tAction,"start":1,"update":1,"updateforce":1,:0) {
			Write ..%StartScript(),!
			Set tPort="" For {
				Set tPort =$O($$$EnsRuntime("FGTelnetPort",tPort))  Quit:""=tPort
				&js<portsArray.push('#($zconvert(tPort,"O","JS"))#');>
			}
			Write !,..%EndScript()
		}
		If (tAction="update")&&$$$ISOK(tSC)&&(tRestartingAnItem||(tRestartedAnItem&&$G(^EnsPortal.Settings($USERNAME,"CloseRestartUpdate")))) {
			Write ..%StartScript(),!
			&js<setTimeout(function() {
				try {parent.document.getElementById('btnOK').getElementsByTagName('input')[0].click();} catch (err) {}
			}, 100);>
			Write !,..%EndScript()
		}
	}
	If 'tPermitted {
		&html<<pre>>
		Write $ZCVT($system.Status.GetErrorText($system.Status.Error($$$InsufficientPrivilegeForOperation)),"O","HTML")
		&html<</pre>>
	}
	&html<</body>
	</html>>
	Quit $$$OK
}

/// Start a production
ClassMethod StartProduction(pName As %String) As %Status
{
	Set $ZT = "Trap"
	Set tSC = ##class(Ens.Director).StartProduction(pName)
Exit
	If $$$ISERR(tSC) {
		Write !,$ZCVT($$$FormatText($$$Text("Production '%1' not started:"),$G(pName)),"O","HTML"),!
		Write $ZCVT($$$StatusDisplayString(tSC),"O","HTML"),!
	} Else {
		Write !,$$$TextHTML("Done."),!
	}
	Quit tSC
Trap
	Set $ZT="", tSC=$$$SystemError
	Goto Exit
}

/// Stop the production
ClassMethod StopProduction(pTimeout, pForce) As %Status
{
	Set $ZT = "Trap"
	If $G(%request.Data("ACTION",1))="force" {
		Write !,$$$TextHTML("Forcing Production to stop."),!
	}
	Set tSC = ##class(Ens.Director).StopProduction(pTimeout, pForce)
Exit
	If $$$ISERR(tSC) {
		Write !,$$$TextHTML("Production not stopped:"),!
		Write $ZCVT($$$StatusDisplayString(tSC),"O","HTML"),!
		Set btnForce = $$$TextHTML("Yes - Force to Shut Down")
		Set tQuery("ACTION") = "force"
		Set tQuery("PRODUCTION") = $G(%request.Data("PRODUCTION",1))
		Set tSrc = ..Link(%request.PageName, .tQuery)
		&html<
			<h2>#($ZCVT($$$FormatText($$$Text("Production could not stop within %1 seconds. Do you want to force a shut down?"),pTimeout),"O","HTML"))#</h2>
			<input type="button" id="btnForce" class="commandButton" value="#(btnForce)#" onclick="retryWithForceOption('#(tSrc)#');">
		>
	} Else {
		Write !!,$$$TextHTML("Done."),!
	}
	Quit tSC
Trap
	Set $ZT="", tSC=$$$SystemError
	Goto Exit
}

/// Update the production
ClassMethod UpdateProduction(pTimeout, pForce) As %Status
{
	Set $ZT = "Trap"
	If $G(%request.Data("ACTION",1))="updateforce" {
		Write !,$$$TextHTML("Forcing Production to update."),!
	}
	Set tSC = ##class(%SYS.Ensemble).UpdateProduction(pTimeout, pForce)
Exit
	If $$$ISERR(tSC) {
		Write !,$$$TextHTML("Production update failed:"),!
		Write $ZCVT($$$StatusDisplayString(tSC),"O","HTML"),!
		Set btnForce = $$$TextHTML("Yes - Force to Update")
		Set tQuery("ACTION") = "updateforce"
		Set tQuery("PRODUCTION") = $G(%request.Data("PRODUCTION",1))
		Set tSrc = ..Link(%request.PageName, .tQuery)
		&html<
			<h2>#($$$TextHTML("Production could not update, do you want to force an update?"))#</h2>
			<input type="button" id="btnForce" class="commandButton" value="#(btnForce)#" onclick="retryWithForceOption('#(tSrc)#');">
		>
	} Else {
		If $G(%request.Data("ITEMRESTART",1),0) = "true" {
			Write !!,$$$TextHTML("Finished first part of Restart."),!
		} Else  {
			Write !!,$$$TextHTML("Done."),!
		}
	}
	Quit tSC
Trap
	Set $ZT="", tSC=$$$SystemError
	Goto Exit
}

/// Recover the production
ClassMethod RecoverProduction() As %Status
{
	Set $ZT = "Trap"
	Set tSC = ##class(Ens.Director).RecoverProduction()
Exit
	If $$$ISERR(tSC) {
		Write !,$$$TextHTML("Production Recovery failed:"),!
		Write $ZCVT($$$StatusDisplayString(tSC),"O","HTML"),!
	} Else {
		Write !,$$$TextHTML("Done."),!
	}
	Quit tSC
Trap
	Set $ZT="", tSC=$$$SystemError
	Goto Exit
}

ClassMethod %OnPreHTTP() As %Boolean
{
	Set tResult = ##super()

	If %response.Redirect = "" {
		// Adjust page timeout if needed
		Set tAction = $G(%request.Data("ACTION",1))
		If tAction = "stop" {
			Set tTimeout = ##class(Ens.Director).GetRunningProductionShutdownTimeout()
		}
		ElseIf tAction = "update" {
			Set tTimeout = ##class(Ens.Director).GetRunningProductionUpdateTimeout()
		}
		Else  {
			Set tTimeout = 120
		}
		Set tTimeout = tTimeout+10
		Set:%request.GatewayTimeout<tTimeout %response.Timeout = tTimeout
	}

	Quit tResult
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Production update status")
}

/// Get information to display in the ribbon bar.
/// Make appropriate choices for Production Delete. 
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String) As %Status
{
	Quit $$$OK
}

}
