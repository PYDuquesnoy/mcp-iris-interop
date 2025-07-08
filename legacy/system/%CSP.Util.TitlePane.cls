/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sqlui, %sySystem)

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Details for the Title pane of a CSP AutoPage used by Interoperability.
Class %CSP.Util.TitlePane Extends Pane [ ServerOnly = 1, System = 4 ]
{

/// A collection of Links used to draw the locator within the title pane.
Property Locator As list Of Link;

/// Control whether or not User/Namespace is displayed or not.
Property ShowUsrNsp As %Boolean [ InitialExpression = 1 ];

/// Draw the HTML to display a title pane for this object.
Method DrawBODY(pInstance As PageInstance) As %Status
{
 	i $ZS<$$$MAXBBSZ { d $ZU(163,$$$MAXBBSZ) }
	Set actionText = $ZCVT(..Text,"O","HTML")
	Set IsLogout = $G(%request.Data("LOGOUT",1)) = 1

	// test if user can use About box
	Set aboutPage = ##class(%CSP.Page).Link("_CSP.UI.Portal.About.cls")
	Set aboutLink = "HREF="""_aboutPage_""""
	Set aboutStyle = ""
	
	// if you are here without privilege, then no about
	If ('$System.Security.Check("%Admin_Manage","USE") &&
		'$System.Security.Check("%Admin_Operate","USE") &&
		'$System.Security.Check("%Admin_Secure","USE") &&
		'$System.Security.Check("%Development","USE") &&
		'$System.Security.Check("%DB_IRISSYS","READ")) {
		Set aboutLink = ""
		Set aboutStyle = "color: gray;"
	}
	
	// Call this method once to establish remote namespace asynchronous connection
	/* YSD844 If $G(%session.Data("$REMOTECONCALLED")) = "" {
		Set tSC = $$Connect^%SYS.NAMESPACE()
		If $$$ISERR(tSC) Set %session.Data("$REMOTECONCALLED") = 0 &html<<div class="ErrorBox">#($ZCVT($System.Status.GetErrorText(tSC),"O","HTML"))#</div>>
		Else  Set %session.Data("$REMOTECONCALLED") = 1
	} */
	Set ServerName = $zu(110)
	Set InstanceName = $P($zu(86),"*",2)

	// YSD918 - Set %session.Data("$NAMESPACE") for future use
	Set defaultNS = $G(%session.Data("$NAMESPACE"))
	If defaultNS = "" Set defaultNS = ##class(%CSP.Util.TitlePane).GetDefaultNamespace()
	
	Set HomePage = ##class(%CSP.Page).Link("/csp/sys/UtilHome.csp")
	// find help URL for this page
	Set tHelp(1) = "MgtPortal"
	Set tHelp(2) = pInstance.Address
	Set helpURL = ##class(%CSP.Util.Librarian).FindDocBookLink(.tHelp)
	#; YSD1581 Remove the $NAMESPACE from the URL returned
	If helpURL [ "?$NAMESPACE=" Set helpURL = $P(helpURL,"?$NAMESPACE=",1)_"');"
	#; YSD1653 Set link1 = $P(##class(%CSP.Page).Link("/csp/sys/%25CSP.Login.cls"),"?",1)
	Set link2 = $P(##class(%CSP.Page).Link("/csp/sys/UtilHome.csp"),"?",1)
	Set logXURL = link2_"?IRISLogout=end"
	Set cmdHome = $$$TextHTML("Home")
	Set cmdAbout = $$$TextHTML("About")
	Set cmdHelp = $$$TextHTML("Help")
	Set cmdLogX = $$$TextHTML("Logout")
	
	Set cmdJumpTask = $$$TextHTML("Go to")
	Set msgJumpTask = $$$TextHTML("Go directly to the selected task")
	
	Set msgHome = $$$TextHTML("Go to the Management Portal Home Page")
	Set msgAbout = $$$TextHTML("Display the System Overview page")
	Set msgHelp = $$$TextHTML("Launch the Documentation page")
	Set msgLogX = $$$TextHTML("End this Management Portal session")
	
	Set cmdServer = $$$TextHTML("Server")
	Set cmdInstance = $$$TextHTML("Instance")
	Set cmdLicense = $$$TextHTML("Licensed to")

	Set msgServer = $$$TextHTML("Name of the machine this system is running on")
	Set msgInstance = $ZCVT($ZV,"O","HTML")
	Set msgLicense = $$$TextHTML("Name associated with current system license")

	If (IsLogout) {
		// show login command
		Set cmdLogX = $$$TextHTML("Login")
		Set logXURL = HomePage
		Set msgLogX = $$$TextHTML("Start a new Management Portal session")
	}
	&html<
	<tr><td colspan="10"><a name="top"></a>
   <table width="100%" border="0" cellpadding="0" cellspacing="0" style="font-size: 10pt;">
   <tr>
   <td nowrap width="205" bgcolor="#FFFAE7" valign="bottom" align="left" style='background-repeat: no-repeat; background-image: url("#(##class(%CSP.Page).Link("/csp/sys/images/logo-topl-intersystems.gif"))#");'>
   <nobr>&nbsp;
   <span style="color: gray;">
   <a target="_top" title="#(msgHome)#" class="buttonStyleON" href='#(HomePage)#'>#(cmdHome)#</a>|<a target="_top" title="#(msgAbout)#" class="buttonStyleON" style="#(aboutStyle)#" #(aboutLink)#>#(cmdAbout)#</a>|<a title="#(msgHelp)#" class="buttonStyleON" href="#(helpURL)#">#(cmdHelp)#</a>|<a target="_top" title="#(msgLogX)#" class="buttonStyleON" href="#(logXURL)#">#(cmdLogX)#</a>
   </span></nobr>
   </td>
   <td nowrap bgcolor="#FFFAE7" valign="top" align="left">
   <div style="color: darkblue; margin-top:18px; font-weight: bold; font-size:11pt;">#(actionText)#</div>
   <div title="#(msgLicense)#" class="wizardltlabel" style="margin-top:10px;"><span style="font-size:8pt; padding-right:5px;">#(cmdLicense)#:</span><b>#($ZCVT($$CustomerName^%SYS.LICENSE,"O","HTML"))#</b>&nbsp;</div>
   </td>
   <td nowrap width="308" height="78" bgcolor="#FFFAE7" valign="bottom" align="left" style='background-repeat: repeat-y; background-image: url("#(##class(%CSP.Page).Link("/csp/sys/images/opposite-pic-intersys.jpg"))#");'>&nbsp;</td>
   <td width="2%" bgcolor="#388CCC">&nbsp;</td>
   <td bgcolor="#388CCC" valign="bottom">
   <table bgcolor="#388CCC" border="0">>
   If 'IsLogout {
		&html<
   		<tr><td title="#(msgServer)#" class="quote-name" style="text-align: left;" nowrap><span style="color:#FFFAE7; font-size:8pt; padding-right:5px;">#(cmdServer)#:</span><b>#(ServerName)#</b></td></tr>
   		<tr><td title="#(msgInstance)#" class="quote-name" style="text-align: left;" nowrap><span style="color:#FFFAE7; font-size:8pt; padding-right:5px;">#(cmdInstance)#:</span><b>#(InstanceName)#</b></td></tr>>
   		Do ..DrawUsername()
   }
   &html<
   </table>
   </td>
   <td bgcolor="#388CCC">&nbsp;</td>
	</tr>
	</tr>
	<table width="100%" border="0" cellpadding="0" cellspacing="0" style="font-size: 10pt;">
	<tr>
	<td colspan="6" bgcolor="#D36D00"><img src='#(##class(%CSP.Page).Link("/csp/sys/images/spacer.gif"))#' width="100%" height="2" alt="-" border="0"></td>
	</tr>>

	Set tCount = ..Locator.Count()
	Merge tID = pInstance.IDValues

	&html<<tr><td class="LocatorBar" colspan="2" valign="middle" nowrap>
		<div align="LEFT" class="Locator">&nbsp;>

	If (tCount > 0) {
		For i = 1:1:tCount {
			If (i > 1) {
				&html<&gt;>
			}

			Set tLink = ..Locator.GetAt(i)
			//Merge tID = tLink.IDValues
			&html<[<a target="_top" href="#(pInstance.MakeLink(tLink.HREF,.tID))#">#($zconvert(tLink.Caption,"O","HTML"))#</a>]>
		} 
	}

	&html<</div></td>
		<td class="LocatorBar" title="#(msgJumpTask)#" nowrap align="right" valign="middle" colspan="2">
	>

	Do ..DrawNSList()

	&html<&nbsp;#(cmdJumpTask)#:>

	Do ..DrawQuickJumpList()

	&html<</td>
		<td class="LocatorBar" colspan="2">&nbsp;</td>
		</tr>>

	&html<</table>>
	Quit $$$OK
}

/// Draw list of namespaces for user.
Method DrawNSList() [ Internal ]
{
	#; show combo box for namespaces
	Set nsHelp = $$$Text("Switch to a different namespace")
	Set lblNamespace = $$$Text("Namespace")
	&html<&nbsp;<span title="#(nsHelp)#">#(lblNamespace)#:</span>>
	Set tCurrNS = $namespace
	&html<<select id="nscombo" style="font-size: 12px; color: darkblue; font-weight: bold;" onchange="self.top.document.location=this.value;">>
	Set tNS = $O(^%SYS("Ensemble","InstalledNamespace",""))
	While (tNS '= "") {
		Set tSel = $S(tNS=tCurrNS:"selected",1:"")
		#; YSD2544 Set tURL = ##class(%CSP.Page).Link(##class(%EnsembleMgr).DetermineMgmtURLForNamespace(tNS),,1)_"CSPCHD="_%session.CSPSessionCookie_"&CSPSHARE=1"
		Set tURL = ##class(%CSP.Page).Link(##class(%EnsembleMgr).DetermineMgmtURLForNamespace(tNS),,1)
		&html<<option value="#(tURL)#" #(tSel)#>#($ZCVT(tNS,"O","HTML"))#>
		Set tNS = $O(^%SYS("Ensemble","InstalledNamespace",tNS))
	}
	&html<</select>>
}

/// Draw username or server name depend on setup.
Method DrawUsername()
{
	Set msgUser = $$$TextHTML("User")
	Set msgServer = $$$TextHTML("Server")
	Set msgInstance = $$$TextHTML("Instance")
	Set hlpUser = $$$TextHTML("Name of user logged into this session")

	if (..ShowUsrNsp) {		
		If (%session.Username '= "") {
			&html<<tr><td title="#(hlpUser)#" class="quote-name" style="text-align: left;">
			<span style="color:#FFFAE7; font-size:8pt; padding-right:5px;">#(msgUser)#:</span><b>#(%session.Username)#</b></td></tr>
			>
		}
	}
	else {
		/* YSD2289
		// Use SERVER and Instance otherwise
		set defaultServer = $G(%session.Data("SERVER"))
		set:defaultServer="" defaultServer = ##Class(%SYS.System).GetNodeName(1),%session.Data("SERVER") = defaultServer 
		&html<<tr><td class="quote-name">#(msgServer)#: #(defaultServer)#</td></tr>>

		set defaultCfg = $G(%session.Data("CONFIG"))
		set:defaultCfg="" defaultCfg = $p($zu(86),"*",2),%session.Data("CONFIG") = defaultCfg
		&html<<tr><td class="quote-name">#(msgInstance)#: #(defaultCfg)#</td></tr>>
		*/
	}
}

/// Handle ShowUsrNsp
Method OnGenerateCode() As %String
{
	Set code = ""

	// ShowUsrNsp
	If (..ShowUsrNsp '= "") {
		Set code = code _ " Set tPane.ShowUsrNsp = " _ +..ShowUsrNsp _ $$$EOL
	}

	Quit code
}

/// Get default namespace for this session:<br>
/// <ul>
/// <li> If NAMESPACE is passed in that means user has changed namespace from
/// the drop-down. Update the session data $NAMESPACE.</li>
/// <li> Else If this is not a new session, then use the previous saved session NAMESPACE</li>
/// <li>      Else this is a new new session, but it is production-enabled, then use the current namespace</li>
/// <li>      Else this is a new new session, and it is CSP GUI Utility, then return the first available namespace from namespace list. </li>
/// </ul>
ClassMethod GetDefaultNamespace() As %String
{
	//YSD1472
	If ##class(%EnsembleMgr).IsEnsembleInstalled() {
		Set defaultNS = $namespace Quit defaultNS
	}
	Set defaultNS = $G(%request.Data("$NAMESPACE",1))
	If defaultNS '= "" {
		Set %session.Data("$NAMESPACE") = defaultNS
	} Else {
		Set defaultNS = $G(%session.Data("$NAMESPACE"))
		If defaultNS = "" {
			If $namespace '= "%SYS" Set defaultNS = $namespace  // for Ensemble
			//Load the first available local namespace
			If defaultNS = "" {
				Do List^%SYS.NAMESPACE(.NspList,0)
				Set defaultNS = $O(NspList(""))	
			}
			Set %session.Data("$NAMESPACE") = defaultNS
		}
	}
	Quit defaultNS
}

/// Draw a combobox of quick jump options.
Method DrawQuickJumpList()
{
	#; This is the Ensemble list;
	#; Cache list is in SMTitlePane

	// create list of jump targets and associated URL
	// Manager tasks
	// If $system.Security.Check("%Admin_Manage","USE") && $$CheckCSPApplication^%SYS.SECURITY("/csp/sys/mgr") {
	#; YSD2323
	Set tEnsLink = ##class(%EnsembleMgr).DetermineMgmtURLForNamespace()
	Set tEnsLink = $p(tEnsLink,"/",1,$l(tEnsLink,"/")-1)_"/"
	Set jump($$$Text("Ensemble Home")) = $LB(##class(%CSP.Page).Link(tEnsLink_"UtilEnsHome.csp"))
	Set jump($$$Text("System Management")) = $LB(##class(%CSP.Page).Link("/csp/sys/UtilHome.csp"))
	Set jump($$$Text("Productions")) = $LB(##class(%CSP.Page).Link("UtilEnsProductions.csp"))
	Set jump($$$Text("Monitor")) = $LB(##class(%CSP.Page).Link(tEnsLink_"UtilEnsMonitor.csp"))
	Set jump($$$Text("Event Log")) = $LB(##class(%CSP.Page).Link(tEnsLink_"UtilEnsLog.csp"))
	Set jump($$$Text("Queues")) = $LB(##class(%CSP.Page).Link(tEnsLink_"UtilEnsQueues.csp"))
	Set jump($$$Text("Workflow")) = $LB(##class(%CSP.Page).Link(tEnsLink_"WFHome.csp"))

	&html<<select 
		onchange="gotoTask(this.options[this.selectedIndex].value);" 
		style="color: darkblue; font-size: 0.8em;" >>
	&html<<option >   </option>>  // initial blank to force onchange event

	Set j = $O(jump(""))
	While (j '= "") {
		Set tJumpLink = ##class(%CSP.Page).Link($LG(jump(j),1),.query)
		&html<<option value="#(tJumpLink)#">#($ZCVT(j,"O","HTML"))#</option>>
		Set j = $O(jump(j))
	}

	&html<</select>>

	// extra JS
	&html<
<script language="javascript">
// jump directly to requested task
function gotoTask(task)
{
	if ('' != task) {
		self.top.document.location = task;
	}
	return true;
}

/// Call by parent window to find our size
function getPreferredHeight()
{
	return self.document.body.clientHeight + 20;
}
</script>
	>
}

}
