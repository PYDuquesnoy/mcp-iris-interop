/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Dialog for checking in files to Perforce
Class %Studio.SourceControl.UI Extends %CSP.StudioTemplateSuper [ System = 4 ]
{

/// This Parameter should be updated when synced from Perforce
Parameter SrcVer = "$Id: //iris/2025.1.0/databases/sys/cls/Studio/SourceControl/UI.xml#1 $";

/// Revision number of this class when compiled as part of the //custom_ccrs/_common/config/... branch.  
/// This version will not be updated (by design) when the class is integrated to other branches.
/// This allows the user to tell what version of the Studio client tools are in use.
Parameter Version = 123;

/// Do not accept the default SECURITYRESOURCE from the superclass as this page handles it's own security to allow TrakCare use-cases
/// <p>NOTE - this parameter is not enforced until 2012.2
Parameter SECURITYRESOURCE;

/// Event handler for <b>PAGE</b> event: this is invoked in order to  
/// generate the content of a csp page.
ClassMethod OnPage() As %Status [ ServerOnly = 1 ]
{
	New $ROLES
	Do ..UpdateSession()
	If (%request.Get("EndTemplate") = 1) {
		If (%request.UserAgent [ " Code/") {
			// For VSCode only:
			Set %response.ContentType="text/html",%response.CharSet="UTF-8"
			Write "<html>",!
			Write "<script type=""text/javascript"">",!
			&js<if (window.parent) {
				window.parent.postMessage({"result":"done"},'*')
			}>
			Write "</script>",!
			Write "</html>",!
		} Else {
			Set %response.ContentType="text/xml",%response.CharSet="UTF-8"
			Set delim = ##class(%CSP.StudioTemplateError).#DELIM
			Write "<?xml version=""1.0""?>",!
			Write "<template><![CDATA[BODY",delim
			Write delim,"]]></template>",!
		}
		Quit $$$OK
	}
	Set action=$ZCVT($get(%request.Data("action",1)),"L")
	Set tEnsInclude = $select(##class(%Library.EnsembleMgr).IsEnsembleInstalled(): "<script type=""text/javascript"" src=""ensemble/Ens_SourceControl.js""></script>", 1: "")

	Set tMeta = "<meta http-equiv=""X-UA-Compatible"" content=""IE=edge"" />"
	Set tCSS = "<style type=""text/css"">" _
		" ins { background-color: #e6ffe6; } " _
		" del { background-color: #ffe6e6; } " _
		" ins[active] { background-color: #99EB99; font-weight: bolder; } " _
		" del[active] { background-color: #FF8080; font-weight: bolder; } " _
		" .frost-card {box-shadow: 0 2px 1px -1px #0003,0 1px 1px #00000024,0 1px 3px #0000001f; border-radius: 4px; min-width: 600px; max-width: min(1200px,84%); margin: 20px auto; padding: 0 0 16px; display: block; position: relative;} " _
		" .frost-outer-header {background-color: #f2f2f2; border-bottom: 1px solid #cbcbcb; position: sticky; top: 0; z-index: 1000; padding-right: 8px; display: flex; flex-direction: row;}" _
		" .frost-inner-header {width: 100%; display: flex; justify-content: space-between; margin: 0 16px;}" _
		" .frost-card-header {margin-top: 4px; margin-bottom: 0; font-weight: 550;  font-size: 1.25rem; display: block;}" _
		" .frost-card-content {padding: 0 16px; font-size: .8125rem;}" _
		" .frost-card-content-with-notifs {padding-left: 16px; z-index: 1; padding-top: 1px;}" _
		" .frost-card-content-no-top-margin {margin-top: 0px}" _
		" .frost-primary-button {background-color: #333694; box-shadow: 0 0 #0003, 0 0 #00000024, 0 0 #0000001f; color: #fff; font-size: 0.875pxpx; font-weight: 550; box-sizing: border-box; user-select: none; cursor: pointer; outline: none; border: none; -webkit-tap-highlight-color: rgba(0,0,0,0); display: inline-block; white-space: nowrap; text-decoration: none; vertical-align: baseline; text-align: center; margin: 0; min-width: 64px; line-height: 36px; padding: 0 16px; border-radius: 4px; overflow: visible;}" _
		" .frost-primary-button:hover {background-color: #2b2b2b}" _
		" .frost-primary-button:disabled {background-color: #cccccc; box-shadow: 0 0 #0003, 0 0 #00000024, 0 0 #0000001f; color: #fafafa; font-size: 0.875pxpx; font-weight: 550; box-sizing: border-box; user-select: none; cursor: pointer; outline: none; border: none; -webkit-tap-highlight-color: rgba(0,0,0,0); display: inline-block; white-space: nowrap; text-decoration: none; vertical-align: baseline; text-align: center; margin: 0; min-width: 64px; line-height: 36px; padding: 0 16px; border-radius: 4px; overflow: visible;}" _
		" .frost-secondary-button {color: #333694; border: 2px solid #333694; box-shadow: 0 0 #0003,0 0 #00000024,0 0 #0000001f; padding: 0 15px; line-height: 34px; box-sizing: border-box; user-select: none; cursor: pointer; outline: none; -webkit-tap-highlight-color: rgba(0, 0, 0, 0); display: inline-block; white-space: nowrap; text-decoration: none; vertical-align: baseline; text-align: center; margin: 0; min-width: 64px; border-radius: 4px; overflow: visible; font-size: 0.875rem; font-weight: 550; background: transparent}" _
		" .frost-secondary-button:hover {color: #2b2b2b; border: 2px solid #2b2b2b}" _
		" .frost-secondary-button-disabled {color: #b0b0b0; border: 2px solid #b0b0b0;  box-shadow: 0 0 #0003,0 0 #00000024,0 0 #0000001f; padding: 0 15px; line-height: 34px; box-sizing: border-box; user-select: none; cursor: pointer; outline: none; -webkit-tap-highlight-color: rgba(0, 0, 0, 0); display: inline-block; white-space: nowrap; text-decoration: none; vertical-align: baseline; text-align: center; margin: 0; min-width: 64px; border-radius: 4px; overflow: visible; font-size: 0.875rem; font-weight: 550; background: transparent}" _
		" .frost-tertiary-button {background-color: #f2f2f2; color: #333694; border: 1px solid #333694; box-shadow: 0 0 #0003,0 0 #00000024,0 0 #0000001f; padding: 0 15px; line-height: 34px; box-sizing: border-box; user-select: none; cursor: pointer; outline: none; -webkit-tap-highlight-color: rgba(0, 0, 0, 0); display: inline-block; white-space: nowrap; text-decoration: none; vertical-align: baseline; text-align: center; margin: 0; min-width: 64px; border-radius: 4px; overflow: visible; font-size: 0.875rem; font-weight: 550}" _
		" .frost-tertiary-button:hover {background-color: #ffffff; color: #2b2b2b; border: 1px solid #2b2b2b;}" _
		" .frost-table {border: thin #e0e0e0 solid; border-radius: 4px; display: inline-block inline-size: 100%; overflow-x: hidden; font-size: .875rem; line-height: 1.125rem;}" _
		" .frost-table-header-row {background-color: #f2f2f2}" _
		" .frost-table-header {padding: 6px 6px 6px 24px; border-block-end-width: 1px; border-block-end-style: solid; border-block-end-color: #e0e0e0; border-start-start-radius: 5px; border-stard-end-radius; 5px;}" _
		" .frost-table-header-cell {text-align: start; border-block-end: 1px solid #e0e0e0; padding-inline-end: 1rem; padding-block: .5rem; padding-block-end: .5rem; vertical-align: top; line-height: 1.125rem; font-size: .8125rem}" _
		" .frost-table-header-cell-left {text-align: start; border-block-end: 1px solid #e0e0e0; padding-inline-end: 1rem; padding-block: .5rem; padding-block-end: .5rem; vertical-align: top; line-height: 1.125rem; font-size: .8125rem; padding-left: 24px;}" _
		" .frost-table-row {block-size: auto; height: 2.25rem}"_
		" .frost-table-cell {padding-right: .5rem; padding-top: .5rem; padding-bottom: .5rem; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #0000001f; vertical-align: top; line-height: 1.125rem; font-size: .8125rem; font-weight: 400;}" _
		" .frost-failure-outer {position: fixed; z-index: 10000; inline-size: 400px; margin-inline-start: -200px; inset-block-start: 20px; inset-inline-start: 50%;}" _
		" .frost-failure-middle {margin: 10px 0; display: flex; flex-direction: row; align-items: center; padding: 4px 8px; border: 1px solid #c13527; background-color: #fbebea; border-radius: 4px;}" _
		" .frost-failure-inner {inline-size: 100%; display: flex; flex-direction: row; align-items: center; justify-content: flex-start; gap: 0.5em;}" _
		" .frost-failure-message {margin: 0; font-size: 0.875rem; padding-top: 5px; padding-bottom: 5px;}" _
		" .frost-warning-symbol {border-radius: 50%; border: 2px solid #cc0000; color: #cc0000; font-weight: bold; line-height: 1rem; width: 1rem; text-align: center;}" _
		" .frost-filename {width: 100%; word-break:break-all;}" _
		" .frost-fieldset {border-radius: 4px}" _
		" .frost-readonly-textarea {resize: none; background-color: #e0e0e0; border-radius: 2px;}" _
		" .frost-label {font-weight: 700}" _
		" .frost-text {font-size: .8125rem}" _
		" H3 {font-weight: 700}" _
		" table {font-size: .8125rem}" _
		"</style>"
	Set tScript = "<script>" _
		"function updateInfoPosition() { " _
		"	var bounds = document.getElementById('matCard').getBoundingClientRect();" _
		"	var rightDistance = window.innerWidth - bounds.right;" _
		"	document.getElementById('systemInfo').style.right= rightDistance + 10;" _
		"	document.getElementById('systemInfo').style.top= bounds.top +35;" _
		"}" _
		"</script>"
	Set tHeader = tMeta _ $char(13,10) _ tCSS _ tScript
	
	&html<<html>
			<head>
				<title>Source Control #($get(%request.Data("action",1)))#</title>
				#(tHeader)#
				#(tEnsInclude)#
			</head>
			<body style="background-color: #fff; font-family: Noto Sans, Noto Sans Arabic, Arial, 'Sans-Serif';">
			<span  id = "systemInfo" STYLE="position: absolute; right: 10px; text-align: right; font-size:.7em; z-index: 2" >
				Server: <strong>#($zu(110))#</strong><BR/>
				Instance: <strong>#($piece($zu(86),"*",2))#</strong><BR/>
				Namespace: <strong>#($namespace)#</strong><BR/>
				User: <strong>#($USERNAME)#</strong><BR/>
				#($select($data(^SYS("SourceControl","ItemSetConfig","Org")):"Org: <strong>"_^SYS("SourceControl","ItemSetConfig","Org")_"</strong><BR/>",1:""))#
				#($select($data(^SYS("SourceControl","ItemSetConfig","System")):"Sys: <strong>"_^SYS("SourceControl","ItemSetConfig","System")_"</strong><BR/>",1:""))#
				#($select($data(^SYS("SourceControl","ItemSetConfig","Environment")):"Env: <strong>"_^SYS("SourceControl","ItemSetConfig","Environment")_"</strong><BR/>",1:""))#
				#($select($data(^%SYS("SourceControl","InstanceWidePrimaryNamespace"),priNS):"Instance-wide Primary Namespace: <strong>"_priNS_"</strong><BR/>",1:""))#
				#($select($$CCRServer^%buildccr(1)'="":"CCRServer: <strong><A HREF='"_$$CCRServer^%buildccr_"' target='_blank'>"_$$CCRServer^%buildccr_"</A></strong><BR/>",1:""))#
				#($select($data(%request.Data("User",1)):"",1:"<A HREF='"_..SelfLink()_"&action=Logout'>Logout</A>"))#	<!--Don't show logout link when accessed via Studio-->
			</span>
	>
	&html<<pre style="font-size:0.6em">> Do ##class(ISC).CheckIndexes() &html<</pre>>
	#define StandardActions $LB("menu","login","checkin","download","load","bundle","upload","itemsethistory","itemsetlog","itemsetautodownload","summary","refresh","systemdefaults","diff","validatediff")
	#define RequireSources $LB("login","checkin","download","load","bundle","upload","itemsetlog","refresh","dscheckpoint")
	
	If action="" {
		Do ..MenuDisplay()
	} ElseIf (('$data(^Sources))&&($LF($$$RequireSources,action))) {
		&html<
			%Studio.SourceControl.UI cannot be used as ^Sources is not defined in #($namespace)#<P>
			<A HREF='#(..SelfLink())#'>Source Control Menu</A>>				
	} ElseIf $LF($$$StandardActions,action) {
		If (..InstanceVersion() = "2010.1")&&($zu(23,1)=32) { Set oldcol=$zu(23,1,5) }		; Spanish2 collation on 2010.1 must be avoided
		Try {
			Do $zobjclassmethod(..%ClassName(1),$ZCVT(action,"W")_"Display")
		} Catch err {
			Set err=$system.Status.GetErrorText(err.AsStatus())
			Write !,##class(%CSP.Page).EscapeHTML(err)
		}
		If $data(oldcol) { Set oldcol=$zu(23,1,oldcol) }
	} Else {
		Write "Unrecognized Action",!	
	}
	//Write "<pre>",! Do $SYSTEM.OBJ.Dump(%request),$SYSTEM.OBJ.Dump(%session) Write "</pre>",!
	&html<	</body>
		</html>
	>
	Quit $$$OK
}

ClassMethod UpdateSession()
{
	If $data(%request.Data("item",1)) Do %session.Set("item",%request.Data("item",1))
	If $data(%request.Data("User",1)) Do %session.Set("CacheUser",%request.Data("User",1))
	If %session.Get("CacheUser") '= "" {
		Do $system.Security.Login(%session.Get("CacheUser"))
	}
}

ClassMethod MenuDisplay()
{
	&html<
		<div class = "frost-card" id = "matCard">
		<script language='javascript'>
			try {
				window.onload = updateInfoPosition;
				window.onresize = updateInfoPosition;
			} catch (error) {
				// Handle Studio case
				document.getElementById('systemInfo').style.top= 110;
			}
		</script>
		<div class = "frost-outer-header" >
		<div class = "frost-inner-header" >
		<H2 class = "frost-card-header" >Source Control Menu</H2> 
		</div>
		</div>
		<div class = "frost-card-content" >
	>
	If %session.RunNamespace'="" {
		If $Get(^SYS("SourceControl","ItemSetConfig","NoUpload")) {
			&html<
				<p style='color:red'>
					No Upload flag is set for this Namespace
			>
			If $Get(^Sources("NoUploadOverride")) {
					&html<
					<br/>
					Bundle and Upload are allowed only for the following packages:
					<ul style='color:red; list-style:none;'>
					>
				Set name = $Order(^Sources("NoUploadOverride", ""))
				While name '= "" {
					If ^Sources("NoUploadOverride", name) {
						&html<
							<li>
								#(name)#.*
							</li>
						>
					}
					Set name = $Order(^Sources("NoUploadOverride",name))
				}
			}
			&html<
					</ul>
				</p>
			>
		}
		&html<<H3>Available Controls</H3>
				<UL>
		>
		If ('##class(%Studio.SourceControl.ISC).Disconnected()) {
			&html<<LI><A HREF='#(..SelfLink())#&action=Checkin'>Check In</A> - Check changes directly into Perforce</LI>>
		}
		If $get(^SYS("SourceControl","ItemSetConfig","Enabled")) {
			&html<
				<LI><A HREF='#(..SelfLink())#&action=Download'>ItemSet Download</A> - Download an ItemSet from CCR Server</LI>
				<LI><A HREF='#(..SelfLink())#&action=Load'>ItemSet Load</A> - Load ItemSet contents into Environment</LI>
				<LI><A HREF='#(..SelfLink())#&action=ItemsetHistory'>View ItemSet History</A> - Display the history and logs for imported ItemSets</LI>
			>
			If (##class(%Studio.SourceControl.ISC).Disconnected()) {
				If $Get(^SYS("SourceControl","ItemSetConfig","NoUpload")) && '$Get(^Sources("NoUploadOverride")) {
					&html<
						<LI><A disabled>ItemSet Bundle - (disabled for this Namespace)</A></LI>
						<LI><A disabled>ItemSet Upload - (disabled for this Namespace)</A></LI>
					>
				} Else {
					&html<
						<LI><A HREF='#(..SelfLink())#&action=Bundle'>ItemSet Bundle</A> - Bundle uncommitted changes into an ItemSet</LI>
						<LI><A HREF='#(..SelfLink())#&action=Upload'>ItemSet Upload</A> - Upload a created ItemSet to CCR Server</LI>
					>
				}
			}
			&html<
				<LI><A HREF='#(..SelfLink())#&action=ItemSetLog'>View ItemSet Log</A> - Find and display the log for an ItemSet</LI>
			>
			
			// Only call CCRItemSetTask methods if the class is compiled AND the namespace is configured for ItemSets
			do CSPCCRApp^%buildccr(.path, .root)
			Set acceptsItemSets = (root '= "")
			If ##class(%Dictionary.CompiledClass).%ExistsId("%Studio.SourceControl.CCRItemSetTask") && acceptsItemSets {
				do ##class(%Studio.SourceControl.CCRItemSetTask).GetLogDirName(.dir)
				If ##class(%File).DirectoryExists(dir) {
					&html<
						<LI><A HREF='#(..SelfLink())#&action=ItemSetAutoDownload'>View ItemSet AutoDownload Logs</A> - View logs of the ItemSet AutoDownload Task</LI>
					>
				}
			}
			&html<
				<LI><A HREF='#(..SelfLink())#&action=Summary'>Configuration Summary</A> - Display CCR client configuration details</LI>
			>
		}	
		&html<
			<LI><A HREF='#(..SelfLink())#&action=Refresh'>Refresh from Branch</A> - Sync (optional) then reload and compile all contents from disk</LI>
		>
		If $$$comClassDefined("Ens.Config.DefaultSettings") {
			&html<
				<LI><A HREF='#(..SelfLink())#&action=Systemdefaults'>Export Default Settings</A> - Export default settings for Productions to file</LI>
			>
		}
		
		&html<</UL>>
		Set locked=##class(%Studio.SourceControl.ISC).Locked()
		If (locked) {
			&html<
				<SPAN STYLE="font-size:.7em" >
				<STRONG>
				NOTE - Configuration is <FONT color='red'>#($select(locked=2:"ADMINLOCKED",1:"LOCKED"))#</FONT>;
				</STRONG>
			>
			If (locked<2) { Write "<br>Use the <code>##class(%Studio.SourceControl.ISC).Unlock()</code> method to change Lock state for this namespace",! }
			&html<
				</SPAN>
			>			
		}
		If $get(^SYS("SourceControl","ItemSetConfig","Enabled")) {
			&html<
				<H3>
					Current CCR Configuration
					<A href="#($$CCRServer^%buildccr)#/ccr/create.csp?SiteCode=#($G(^SYS("SourceControl","ItemSetConfig","Org")))#&SystemCode=#($G(^SYS("SourceControl","ItemSetConfig","System")))#&BypassPREP=1"
					rel="noopener noreferrer" target='_blank' onClick="window.parent.postMessage({ href: this.href }, '*')">[create new CCR]</A>
				</H3>
				<TABLE>
					<TR>
						<TD><label id="cOrg" class = "frost-label">Organization &nbsp &nbsp</label></TD>
						<TD align='left'><code>#($get(^SYS("SourceControl","ItemSetConfig","Org")))#</code></TD>
						<TD></TD>
					</TR>
					<TR>
						<TD><label id="cSystem" class = "frost-label">System</label></TD>
						<TD align='left'><code>#($get(^SYS("SourceControl","ItemSetConfig","System")))#</code></TD>
						<TD></TD>
					</TR>
					<TR>
						<TD><label id="cEnv" class = "frost-label">Environment</label></TD>
						<TD align='left'><code>#($G(^SYS("SourceControl","ItemSetConfig","Environment")))#</code></TD>
						<TD></TD>
					</TR>
				</TABLE>
			>			
		}
	}
	&html<<H3>Current Namespace: <code>#($S(%session.RunNamespace="":"[no namespace selected]",1:"<strong>"_$ZCVT(%session.RunNamespace,"U")_"</strong>"))#</code></H3>
		<P>Switch to Namespace:</P>
		<UL>
	>
	Set rset=##class(%ResultSet).%New("%SYS.Namespace:List")
	Set sc=rset.Prepare()
	Set sc=rset.Execute()	
	While (rset.Next()) {
		Set namespace=rset.Data("Nsp")
		Try {
			If $data(^|namespace|Sources) {
				; adding "Namespace" to the url will cause %CSP.StudioTeamplateSuper to change %session.RunNamespace to that value
				&html<<LI><CODE><A HREF='#(..SelfLink())#&Namespace=#(namespace)#'>#(namespace)#</A></CODE></LI>>
			}
		} Catch (err) { /*ignore errors from unmounted DBs */ }
	}
	&html<</UL> </div> </div>>
}

/// If login needed (connected multi-developer instance), displays/processes the login form.
/// Other UIs can call this and examine <var>pLoggedIn</var> to determine if processing should continue.
ClassMethod LoginDisplay(Output pContinue As %Boolean = 1)
{
	Set sc = $$$OK
	If '##class(%Studio.SourceControl.ISC).Disconnected() {
		If $Data(%request.Data("p4P")) {
			// Handles a password submit.
			Set password = %request.Get("p4P")
			Set sc = ..PerforceLogin(password)
		}
		If '(##class(%Studio.SourceControl.ISC).DefaultCredentialsDefined() || ..PerforceLoggedIn()) || $$$ISERR(sc) {
			Set pContinue = 0
			Do ##class(%Studio.SourceControl.ISC).GetCredentials(.user,,.workspace)
			Set message = %request.Get("message")
			If (message '= "") {
				&html<<p style="white-space: pre-wrap;">#(..EscapeHTML(message))#</pre>>
			}
			&html<Enter password for Perforce user: <code>'#(..EscapeHTML($get(user)))#'</code>
				<form id="loginForm" name="P4Pass" method="POST">>
			If $$$ISERR(sc) {
				&html<<p style="color: red">Invalid password.</p>>
			}
			&html<<input id="p4P" name="p4P" type='password' size='8'><p>
				<input type="hidden" name="CSPCHD" value="#($Piece(%session.CSPSessionCookie,";"))#" />
				<input type="hidden" name="CSPSHARE" value="1" />
				<input type="hidden" name="action" value="#(..EscapeHTML(%request.Get("action")))#">
				<input type="hidden" name="message" value="#(..EscapeHTML(%request.Get("message")))#">
				<input type="submit" name="setpass" value="Proceed">
				</form>
				<script language='javascript'>
				document.getElementById("p4P").focus();
				</script>
			>
			
			// Prevent redirection to template end
			Set sc = $$$ERROR($$$GeneralError,"Login required.")
		}
	}
	If $$$ISOK(sc) && (%request.Get("action") = "Login") {
		// Weird issue: With IE, template XML responses don't work with URL using %25, only _.
		set url = $Replace(..SelfLink(),"%25","_")_"&EndTemplate=1"
		&html<<form id="finishForm" action="#(..EscapeHTML(url))#" method="POST"></form>
		<script type="text/javascript">
		document.getElementById('finishForm').submit();
		</script>>
	}
}

/// Handles case of an invalid perforce ticket. Clears the cache and refreshes the page.
ClassMethod ClearP4Ticket()
{
	Do ..PerforceLogin() ; somehow an invalid ticket has been cached; force login logic with no password set which will clear the cached ticket
	&html<
	 <script language='javascript'>
	 window.location.href='#(..SelfLink())#&action=Checkin';
	 </script>
	>
}

/// Shelve a given file in the current selected changelist
ClassMethod ShelveFile(file As %String)
{
	Set args($i(args))="shelve"
	Set changelist = %session.Get("changelist")
	If changelist'="" {
		Set args($i(args)) = "-c", args($i(args)) = changelist
		Set args($i(args)) = "-f", args($i(args)) = "-Af", args($i(args)) = file
	}
	Set sc=##class(%Studio.SourceControl.ISC).SecureP4Cmd(.args, .out)
	If $$$ISERR(sc) {
		If ($system.Status.GetErrorText(sc)["P4PASSWD") {
			Do ..ClearP4Ticket()
		} Else {
			Do ..ShowError(sc)
		}
		Quit
	}
}

/// Unshelve a given shelved file from the current selected changelist, into the same changelist
ClassMethod UnshelveFile(file As %String)
{
	// revert files if already opened in workspace
	Set args($i(args)) = "revert", args($i(args)) = file
	Set sc = ##class(%Studio.SourceControl.ISC).SecureP4Cmd(.args, .out)
	If $$$ISERR(sc) && '($System.Status.GetErrorText(sc) [ "not opened") {
		If ($system.Status.GetErrorText(sc)["P4PASSWD") {
			Do ..ClearP4Ticket()
		} Else {
			Do ..ShowError(sc)
		}
		Quit
	}
	
	// unshelve files into current changelist
	Kill args, out
	Set changelist = %session.Get("changelist")
	Set args($i(args)) = "unshelve", args($i(args)) = "-s", args($i(args)) = changelist, args($i(args)) = "-f"
	Set args($i(args)) = "-c", args($i(args)) = changelist, args($i(args)) = "-Af", args($i(args)) = file
	Set sc = ##class(%Studio.SourceControl.ISC).SecureP4Cmd(.args, .out)
	If $$$ISERR(sc) {
		If ($system.Status.GetErrorText(sc)["P4PASSWD") {
			Do ..ClearP4Ticket()
		} Else {
			Do ..ShowError(sc)
		}
		Quit
	}
}

/// Store the new changelist number in %session.Data if switching
/// changelists on check-in page
ClassMethod SwitchChangelist(newChangelist)
{
	Set %session.Data("changelist") = newChangelist
}

/// Page for checking in files from perforce changelists in the current workspace.
/// Only valid for connected clients.
ClassMethod CheckinDisplay(DisplayForm As %Boolean)
{
	Do ..LoginDisplay(.continue)
	If 'continue {
		Quit
	}
	Set tShowForm='$data(%request.Data("submit"))		//if there was no submit button passed, show the initial form
	If $data(DisplayForm) Set tShowForm=DisplayForm		//if an explicit directive on showing the form was passed, follow that instruction
	If (tShowForm) {
		#; Display input form
		&html<
			<script language="JavaScript" type="text/javascript" src="cspxmlhttp.js"></script>
			<script language="JavaScript" type="text/javascript" src="cspbroker.js"></script>
			 
			<div class = "frost-card" id = "matCard">
			<script language='javascript'>
				try {
					window.onload = updateInfoPosition;
					window.onresize = updateInfoPosition;
				} catch (error) {
					// Handle Studio case
					document.getElementById('systemInfo').style.top= 110;
				}
			</script>
			<div class = "frost-outer-header" >
			<div class = "frost-inner-header" >
			<H2 class = "frost-card-header" >Perforce Check In</H2> 
			</div>
			</div>
			<div class = "frost-card-content">
		>
		
		If '##class(%Studio.SourceControl.ISC).Disconnected() {
		&html<
			  <div style = "height: 5px;"> </div>
			  <label for="changelist">Changelist: </label>
			  <script language='javascript'>
			  function updateChangelist() {
				  var changelist = document.getElementById('changelist');
				  #server(..SwitchChangelist(changelist.value))#;
				  window.location.href='#(..SelfLink())#&action=Checkin';
			  }
			  </script>
			  <select name='changelist' id='changelist' onchange='javascript:updateChangelist();'>
			  	<option value='default' selected='#($get(%session.Data("changelist"))="default")#'>Default</option>
		>
			Set ret=##class(%Studio.SourceControl.ISC).GetCredentials(.user,,.workspace)

				// Allow the user to select any pending changelist for their current user and workspace, otherwise restrict to default
		 		If (workspace'="") && (user'="") {
		 			Kill args Set args($i(args))="changes",args($i(args))="-s",args($i(args))="pending"
		 			Set args($i(args))="-c",args($i(args))=workspace,args($i(args))="-u",args($i(args))=user
		 			Set args($i(args))="-l",args($i(args))="-r"
		 			Set sc=##class(%Studio.SourceControl.ISC).SecureP4Cmd(.args,.changelists)
		 			If $$$ISERR(sc) {
			 			If ($system.Status.GetErrorText(sc)["P4PASSWD") {
				 			Do ..ClearP4Ticket()
			 			} Else {
				 			Do ..ShowError(sc)
			 			}
		 				Quit
		 			}
		 			For i=1:1:$get(changelists) {
			 			Set change = $get(changelists(i, "change"))
			 			Set desc = $get(changelists(i, "desc"))
			 			Write "<option title='",..EscapeHTML(desc),"' value='",..EscapeHTML(change),"'"
			 			If $get(%session.Data("changelist"))=change {
				 			Write " selected = 'selected'"
			 			}
			 			Write ">Change ",..EscapeHTML(change),"</option>",!
		 			}
		 		}
		&html<</select>>
				// Get the current open items for the selected changelist
				Set selectedChangelist = %session.Get("changelist","default")
				Kill args Set args($i(args))="opened",args($i(args))="-c",args($i(args))=selectedChangelist
				If $get(workspace)'="" Set args($i(args))="-C",args($i(args))=workspace
				If $get(user)'="" Set args($i(args))="-u",args($i(args))=user
				Set sc=##class(%Studio.SourceControl.ISC).SecureP4Cmd(.args,.opened)	
				If $$$ISERR(sc) {
					If ($system.Status.GetErrorText(sc)["P4PASSWD") {
						Do ..ClearP4Ticket()
					} Else {
						Do ..ShowError(sc)
					}
					Quit
				}
				
				// Get the current shelved files in the selected changelist
				Set nonDefault = selectedChangelist '= "default"
				If nonDefault {
					Kill args Set args($i(args))="describe",args($i(args))="-s",args($i(args))="-S",args($i(args))=selectedChangelist
					Set sc = ##class(%Studio.SourceControl.ISC).SecureP4Cmd(.args,.shelved)
					If $$$ISERR(sc) {
						If ($system.Status.GetErrorText(sc)["P4PASSWD") {
							Do ..ClearP4Ticket()
						} Else {
							Do ..ShowError(sc)
						}
						Quit
					}
				}
				&html<
					<script language='javascript'>
						function shelveFile(file) {
							#server(..ShelveFile(file))#;
	 						window.location.href='#(..SelfLink())#&action=Checkin';
						}
						function unshelveFile(file) {
							#server(..UnshelveFile(file))#;
							window.location.href='#(..SelfLink())#&action=Checkin';
						}
						function callUndo(internalName) {
							message = #server(..UndoItem(internalName))#;
							if (message != "") {
								alert(message);
							}
							window.location.href='#(..SelfLink())#&action=Checkin';
						}
						function getDescription() {
							var desc = document.getElementById('description');
							var changelists = document.getElementById('changelist');
							for (var i = 0; i < changelists.length; i++) {
								var change = changelists.options[i].value;
								if ('#(selectedChangelist)#'==change) {
									desc.value = changelists.options[i].title;
									break;
								}
							}
						}
					</script>
				>
				If $get(opened)<1 {
					Write " <br> </br> Nothing in the selected changelist to submit for Perforce user: <code>'"_$get(user)_"'</code>"
					If nonDefault {
						&html<
						<p><label for='description'>Description:</label></p>
						<textarea name="Comment" class = "frost-readonly-textarea" cols=90 rows=8 wrap=physical id='description' readonly> </textarea>
						<script language='javascript'>
							getDescription()
						</script>
						>
					}					
				} Else {
					Kill args Set args($i(args))="info"
					Set sc=##class(%Studio.SourceControl.ISC).SecureP4Cmd(.args,.clientInfo)
					If $$$ISERR(sc) Do ..ShowError(sc)
					If $get(clientInfo)<1 {
						Set srcRoot=$get(^%SYS("SourceRoot",$namespace),$get(^%SYS("SourceRoot"),"C:\Perforce\"))
					} Else {
						Set srcRoot=clientInfo(1,"clientRoot")
					}
					&html<<br/><br/>Select files to submit for Perforce user: <code>'#($get(user))#'</code>
						<script type="text/javascript">
						function toggleAll(flag) {
							var inputs = document.getElementsByTagName("input");
							for (var i = 0; i < inputs.length; i++) {
								if (inputs[i].type && inputs[i].type == "checkbox") {
									inputs[i].checked = flag;
								}
							}
							document.getElementById("submitBtn").disabled = !flag;
						}
						</script>
						<form name="P4Submit" method="POST">
							<input type='checkbox' onclick='toggleAll(this.checked)' />&nbsp;Select All<br />
							<table cellspacing=0 class = "frost-table">
					>
					Set checkFound=0
					For i=1:1:$get(opened) {
						If '$data(opened(i,"depotFile")) Continue
						Set checked=$select((%session.Get("item")'="")&&(opened(i,"depotFile")[%session.Get("item")):" checked",
							$Data(%request.Data(opened(i,"depotFile"))):" checked",
							1:"")
						If (checked'="") { Set checkFound=1 }
						Set rowColor = $S(i#2:"#e0e0ff", 1:"#ffffff")
						Write "<tr class = 'frost-table-row' BGCOLOR='" _ rowColor _ "'> <td class = 'frost-table-cell'> <input type='checkbox' name='",..EscapeHTML(opened(i,"depotFile")),"'",checked," onclick='javascript:document.getElementById(""submitBtn"").disabled = false;'> </td>",!
						Write "<td class = 'frost-table-cell'>" _ ..EscapeHTML(opened(i,"action"))_": "_..EscapeHTML(opened(i,"depotFile")) _ "</td>"
						Set file=##class(%File).NormalizeFilename(srcRoot_$P(opened(i,"clientFile"),opened(i,"client"),2))
						Set backupfile=##class(%File).NormalizeFilename(file_".bak")
						If ##class(%File).Exists(file)&&##class(%File).Exists(backupfile) {
							&html<<td class = 'frost-table-cell'> <a href='#(..SelfLink())#&action=Diff&file=#(..EscapeURL(file))#&return=Checkin'>diff</a> </td>>
						}
						
						// If file is currently checked out in another workspace, provide warning with user and workspace name
						// Check if item is already checked out and warn user
						Kill checkedOutArgs
						Set checkedOutArgs($i(checkedOutArgs)) = "opened", checkedOutArgs($i(checkedOutArgs)) = "-a"
						Set checkedOutArgs($i(checkedOutArgs)) = opened(i,"depotFile")
						Set sc = ##class(%Studio.SourceControl.ISC).SecureRunCmd("p4", .checkedOutArgs, .out, 0)
						If $$$ISERR(sc) && (sc '[ "not opened anywhere") {
							Do ..ShowError(sc)
						} Else {
							Set warningText = """This file is checked out in the following workspaces: "
							Set workspaces = ""
							Set line = ""
							Set line = $Order(out(line))
							While line '= "" {
								Set client = $Piece(out(line)," by ",2)
								If (user_"@"_workspace) '= client {
									Set workspaces = workspaces_"&#013"_client
								}
								Set line = $Order(out(line))
							}
							If workspaces '= "" {
								Set warningText = warningText_workspaces_""""
								Write "<td class = 'frost-table-cell' title = "_warningText_"><div class = 'frost-warning-symbol'> ! </div></td>"
							}
						}
						
						// Add option to shelve file in the current changelist
						If nonDefault {
							&html<
								<td class = 'frost-table-cell'><button class = "frost-tertiary-button" style = "line-height: 1.25rem;" type='button' onclick="javascript:shelveFile(#(..QuoteJS(file))#);">Shelve</button></td>
							>
						}
						
						// Add revert button for items under ^Sources and with non-null Internal Name
						Set internalName = ##class(%Studio.SourceControl.ISC).InternalNameFromExtName(file, 0, 0)
						Set filePrefix = $Extract(file, 1, $Length(^Sources))
						If '$$$isUNIX {
							Set filePrefix = $ZCVT(filePrefix, "L")
							Set inSources = (filePrefix = $ZCVT(^Sources, "L"))
						} Else {
							Set inSources = (filePrefix = ^Sources)
						}
						If (internalName '= "") && inSources {
							&html<
								<td class = 'frost-table-cell'><button type='button' class = "frost-tertiary-button" style = "line-height: 1.25rem;" onclick="javascript:callUndo(#(..QuoteJS(internalName))#);">Revert</button></td>
							>
						}
						
						Write "</tr>",!
					}
					Write "</table>"
					Set disabled=$select(checkFound:"",1:" disabled")
					&html<	
							<br> </br>
							<span> Description<span style = "color: #ff0000;">*</span> </span><br> 
							<textarea name="Comment" cols=90 rows=8 wrap=physical id='description' onchange='javascript:findJob();'></textarea><br/>
							<script language='javascript'>
							if (#(nonDefault)#) {
								getDescription();
							}
							</script>
							<div style = "height: 10px;"> </div>
							Perforce Job:
							<input name="job" size='8' id='perforceJob' value='#($get(%request.Data("job",1)))#'><p>
							<!-- Hidden <div> with text controls makes form submit on enter in "job" field work properly. -->
							<div style="display:none">
							<input type="text" name="action" value="Checkin">
							<input type="text" name="client" value="#($get(workspace))#">
							<input type="text" name="user" value="#($get(user))#">
							</div>
							<input type="hidden" name="CSPCHD" value="#($Piece(%session.CSPSessionCookie,";"))#" />
							<input type="hidden" name="CSPSHARE" value="1" />
							<input class = "frost-primary-button" type="submit" name="submit" id="submitBtn" value="Submit" #(disabled)#>
						</form>
						<script language="javascript">
						function findJob() {
							var desc=document.getElementById('description').value;
							var prefix = desc.substring(0,12);
							// find devkeys or CCRs as the first piece of the description
							var job=prefix.match(/\b[a-z]{2,4}-?[0-9]{3,6}/i);
							if (job != null) {
								document.getElementById('perforceJob').value = job;
							}
						}
						findJob();
						</script>						
					>
				}
				If $data(shelved(1, "depotFile0")) {
					&html<
					<p>Shelved files:
					>
					Set fileIndex = 0
					Write "<table cellspacing=0 class = 'frost-table'>"
					While $data(shelved(1, "depotFile"_fileIndex))#2 {
						Set rowColor = $S(fileIndex#2:"ffffff", 1:"#e0e0ff")
						Set shelvedFile = shelved(1, "depotFile"_fileIndex)
						Write "<tr class = 'frost-table-row' BGCOLOR='" _ rowColor _ "'> <td class = 'frost-table-cell' style='padding-inline-start: .5rem;'> ", shelvedFile, "</td>"
						&html<
							<td class = 'frost-table-cell'> <button class = "frost-tertiary-button" style = "line-height: 1.25rem;" type='button' onclick="javascript:unshelveFile(#(..QuoteJS(shelvedFile))#);">Unshelve</button> </td>
						>
						Set fileIndex = fileIndex + 1
					}
					Write "</table>"
					&html<</p>>
				}
		} Else {
			Write "Instance is in Disconnected mode.  Check-in commands cannot be sent to Perforce.",!
			Quit	
		}
		Write "</div> </div>"
	} ElseIf ('tShowForm) {
		Do ..PerforceLoggedIn() ;refresh the login credentials in the process if applicable

		#; Process form submission
		Set description=$translate($get(%request.Data("Comment",1)),$char(13))
		If $zstrip(description,"<>W")="" {
			&html<
			<div id = "failureNotif" class = "frost-failure-outer"> 
				<div class = "frost-failure-middle"> 
					<div class = "frost-failure-inner"> 
						<div class = "frost-failure-message" > You must enter a description </div>  
					</div>
				</div>
			</div>
			<script language='javascript'>
				if (document.addEventListener) {
					document.addEventListener('click', function(event) {
						var popup = document.getElementById('failureNotif');
						if (!popup.contains(event.target)) {
							popup.style.display = 'none'; // Hide the element when clicked outside
						}
					});
				} else if (document.attachEvent) { // Handle Studio case
					document.getElementById('systemInfo').style.top= 200;
					document.attachEvent('onclick', function(event) {
						var popup = document.getElementById('failureNotif');
						popup.style.display = 'none'; //Hide the element upon any page click
						document.getElementById('systemInfo').style.top= 110;
                	})
                }
			</script>>
			Do ..CheckinDisplay(1)
			Quit
		}

		&html<
			<script language="JavaScript" type="text/javascript" src="cspxmlhttp.js"></script>
			<script language="JavaScript" type="text/javascript" src="cspbroker.js"></script>
			 
			<div class = "frost-card" id = "matCard">
			<script language='javascript'>
				try {
					window.onload = updateInfoPosition;
					window.onresize = updateInfoPosition;
				} catch (error) {
					// Handle Studio case
					document.getElementById('systemInfo').style.top= 110;
				}
			</script>
			<div class = "frost-outer-header" >
			<div class = "frost-inner-header" >
			<H2 class = "frost-card-header" > Submit Details</H2> 
			</div>
			</div>
			<div class = "frost-card-content" id = "cardContent" >
			<div style = "height: 5px;"> </div>
		>

		Set client=$get(%request.Data("client",1))
		Set user=$get(%request.Data("user",1))
		Set job=$zstrip($get(%request.Data("job",1)),"<>W")
		Set file=##class(%FileCharacterStream).%New()
		Set file.Filename=^Sources_"submit"_$J_".txt"
		Do file.WriteLine("Change:	new")
		Do file.WriteLine("")
		Do file.WriteLine("Jobs: "_job)
		Do file.WriteLine("")
		Do file.WriteLine("Client: "_client)
		Do file.WriteLine("")
		Do file.WriteLine("User: "_user)
		Do file.WriteLine("")
		Do file.WriteLine("Status: new")
		Do file.WriteLine("")
		Do file.WriteLine("Description:")
		For line=1:1:$length(description,$char(10)) {
			Do file.WriteLine("	"_##class(%CSP.Page).EscapeHTML($piece(description,$char(10),line)))
		}
		Do file.WriteLine("")
		Do file.WriteLine("Files:")
		Set i=""
		Set nonDefault = (%session.Get("changelist", "default") '= "default")
		For  {
			Set i=$order(%request.Data(i)) Quit:i=""
			If $extract(i,1,2)'="//"||(%request.Data(i,1)'="on") Continue
			Do file.WriteLine("	"_i)
			// files in a non-default changelist need to be re-opened prior to submit
			If nonDefault {
				Kill args
				Set args($i(args))="reopen",args($i(args))="-c",args($i(args))="default",args($i(args))=i
				Set sc=##class(%Studio.SourceControl.ISC).SecureRunCmd("p4",.args,.output)
				If $$$ISERR(sc) {
					Do ..ShowError(sc)
					&html<
						<script language='javascript'>
							document.getElementById('matCard').style.paddingBottom= '0px';
							document.getElementById('cardContent').style.backgroundColor= '#ffe5e5';
						</script>
					>
				}
			}
		}
		Do file.SaveStream()
		Do file.Rewind()
		&html<<H3 style = "margin-top: 0px;">Submit Details:</H3><p>>	
		While 'file.AtEnd {
			Write file.ReadLine()_"<BR/>"
		}
		&html<<H3>Command Issued:</H3><p>>
		Kill args Set args($i(args))="submit",args($i(args))="-i"
		Set sc=##class(%Studio.SourceControl.ISC).SecureRunCmd("p4",.args,.output,,,file.Filename)
		Do file.Clear()
		If $$$ISERR(sc) {
			Do ..ShowError(sc) 
			&html<
				<script language='javascript'>
					document.getElementById('matCard').style.paddingBottom= '0px';
					document.getElementById('cardContent').style.backgroundColor= '#ffe5e5';
				</script>
			>
			Quit
		}
		&html<<H3>Change Submitted:</H3><p>>
		For i=1:1:output If $data(output(i),line) Write line,"<br>",!
		&html<</div> </div>>
		Quit		
	}
}

ClassMethod DownloadDisplay(DisplayForm As %Boolean)
{
	Set tShowForm='$data(%request.Data("submit"))				//if there was no submit button passed, show the initial form
	Set tShowForm=tShowForm&&('$data(%request.Data("ccr")))		//see if a ccr was passed
	Set tShowForm=tShowForm&&('$data(%request.Data("id")))		//see if an id of the ItemSet on the Server was passed
	If $data(DisplayForm) Set tShowForm=DisplayForm				//if an explicit directive on showing the form was passed, follow that instruction
	Set autoload = $data(%request.Data("autoload"))				//if set automatically Load the ItemSet following a successful Download
	Set sc=$$$OK
	If (tShowForm) {
		#; Display input form
		&html<
			<div class = "frost-card" id = "matCard" >
			<script language='javascript'>
				try {
					window.onload = updateInfoPosition;
					window.onresize = updateInfoPosition;
				} catch (error) {
					// Handle Studio case
					document.getElementById('systemInfo').style.top= 110;
				}
				
			</script>

			<div class = "frost-outer-header">
			<div class ="frost-inner-header">
			<H2 class = "frost-card-header" >Download ItemSet</H2> 
			</div>
			</div>
			<div class = "frost-card-content" >
			<FORM ACTION="" method=post name="download">
				<P>Fill in the fields to download the latest ItemSet for a given CCR and load it into this namespace.
				<TABLE>
					<TR> <TD> &nbsp </TD> </TR>
					<TR>
						<TD ><label class = "frost-label" id="cCCR">CCR</label></TD>
						<TD><input id="ccr" name="ccr" value="#($G(^SYS("SourceControl","ItemSetConfig","Org")))#xxxx"></input></TD>
					</TR>
					<TR>
						<TD><label class = "frost-label">Access Token &nbsp &nbsp </label></TD>
						<TD><input id="token" name="token" value="[retrieve from CCR]"></input></TD>
					</TR>
					<TR> <TD> &nbsp </TD> </TR>
					<TR>
						<TD></TD>
						<TD><input class = "frost-primary-button" type="Submit" id="Submit" name="submit" value="List ItemSets" title="List ItemSets"></input></TD>
					</TR>
				</TABLE>
			</FORM>	
			</div>
			</div>
		>
	} ElseIf ('tShowForm) {
		#; Process form submission
		&html<
			<div class = "frost-card" id = "matCard" >  
			
			<script language='javascript'>
				try {
					window.onload = updateInfoPosition;
					window.onresize = updateInfoPosition;
				} catch (error) {
					// Handle Studio case
					document.getElementById('systemInfo').style.top= 110;
				}
			</script>
			
			<div class = "frost-outer-header">
			<div class ="frost-inner-header">
			<H2 class = "frost-card-header" >ItemSet Download</H2>
			</div>
			</div>
			<div class = "frost-card-content-with-notifs" id="cardContent"> 
		>
		Set ccr=$zstrip($zcvt($get(%request.Data("ccr",1)),"U"),"<>W")
		Set ISid=$get(%request.Data("id",1))
		If (ISid="") {
			Set env=$get(^SYS("SourceControl","ItemSetConfig","Environment"))
			Set token=$zstrip($get(%request.Data("token",1)),"<>W")
			Set sc=##class(%Studio.SourceControl.ItemSet).WSList(ccr,env,token,.rs)
			Set errMessage = ""
			Set failed=0
			If $$$ISERR(sc) Set failed=1, errMessage = errMessage _ ..EscapeHTML($System.Status.GetErrorText(sc))
			If '$isobject(rs) Set failed=1, errMessage= errMessage _ "<PRE>ERROR: DataSet not returned from Web Service</PRE>"
			If (failed) {
				&html<<div> #(errMessage)# </div>
				<script language='javascript'>
					document.getElementById('matCard').style.paddingBottom= '0px';
					document.getElementById('cardContent').style.backgroundColor= '#ffe5e5';
				</script>
				</div>
				</div>
				>
				Quit
			}
			Set cnt=0
			&html<
				<H3>ItemSet Selection</H3>
				<FORM ACTION="" method=post name="download">
					<P>Select an ItemSet for Download
					<TABLE >
						<TR>
							<TD colSpan=2>
								<TABLE cellspacing=0 class = "frost-table">
									<THEAD>
										<TR>
											<TH style = "padding-inline-start: .5rem;" class = "frost-table-header-cell" NOWRAP align='left'>ID</TH>
											<TH class = "frost-table-header-cell" NOWRAP align='left'>Name</TH>
											<TH class = "frost-table-header-cell" NOWRAP align='left'>Timestamp</TH>
											<TH class = "frost-table-header-cell" NOWRAP align='left'>Download</TH>
										</TR>
									</THEAD>
			>
			While (rs.Next()) {
				Set cnt=$I(cnt)
				Set rowColor = $S(cnt#2:"#e0e0ff", 1:"#ffffff")
				Set lastID=rs.Get("ID")
				Set link=..SelfLink()_"&action=Download&id="_lastID_"&ccr="_ccr_"&token="_token
				&html<
					<TR class = "frost-table-row" BGCOLOR="#(rowColor)#">
						<TD class = "frost-table-cell" style="padding-inline-start: .5rem;">#(lastID)#</TD>
						<TD class = "frost-table-cell" >#(rs.Data("Name"))#</TD>
						<TD class = "frost-table-cell">#(rs.Data("CreateTimestamp"))#</TD>
						<TD class = "frost-table-cell"><A HREF="#(link)#">download</A></TD>
					</TR>
				>
			}
			&html<</TABLE>>
			If (cnt=0) {
				&html<<div class = "frost-text"> No ItemSets for CCR '#(ccr)#' to download </div>
				</div>
				</div>>
			} ElseIf (cnt=1) {
				Set ISid=lastID
				&html<
					<P class = "frost-text">Only one ItemSet exists for that CCR, downloading ItemSet #(lastID)#...
					<script language='Javascript'>
					setTimeout("window.location = '#(link)#'",2000);
					</script>
				>
			}
		} ElseIf (ISid'="") {
			Set ret=##class(%Studio.SourceControl.ISC).GetCredentials(.user,,.workspace)
			If $data(%request.Data("p4P")) {
				Set sc=..PerforceLogin(%request.Data("p4P",1))
				If $$$ISERR(sc) { Set badPassword=1, passwordSC=sc }
			}
			If ($get(badPassword)) {
				&html<
					<div class = "frost-text">
						Perforce returned the following error:<br/>
						#(..EscapeHTML($system.Status.GetErrorText(sc)))#
					</div>
				>	
			} ElseIf (('##class(%Studio.SourceControl.ISC).Disconnected())&&('##class(%Studio.SourceControl.ISC).DefaultCredentialsDefined())&&('..PerforceLoggedIn())) {
				&html<
					<div class = "frost-text">
							Environment is configured as Connected to Perforce, so p4 sync will be called for items in ItemSet.<br/>
						Enter password for Perforce user: <code>'#($get(user))#'</code>
						<form name="P4Pass" method="POST">
							<input id="p4P" name="p4P" type='password' size='8' tabindex='1'><p>
							<input type="hidden" name="action" value="Download">
							<input type="hidden" name="id" value="#(ISid)#">
							<input type="hidden" name="token" value="#($get(%request.Data("token",1)))#">
							<input type="hidden" name="ccr" value="#($get(%request.Data("ccr",1)))#">
							<input type="hidden" name="autoclose" value="#($get(%request.Data("autoclose",1)))#">
							<input type="hidden" name="CSPCHD" value="#($Piece(%session.CSPSessionCookie,";"))#" />
							<input type="hidden" name="CSPSHARE" value="1" />
							<input type="submit" name="setpass" value="Proceed">
						</form>
						<script language='javascript'>
						document.getElementById("p4P").focus();
						</script>
					</div>
				>
			} Else {
				&html<	
					<H3>ItemSet Download</H3>
					<P>Download Results:
					<PRE>
				>
				Do {
					Write !
					Set env=$G(^SYS("SourceControl","ItemSetConfig","Environment"))
					Set token=$zstrip($G(%request.Data("token",1)),"<>W")
					Write "Attempting to download ItemSet XML for ItemSet "_ISid_" from Server...",!
					Set sc=##class(%Studio.SourceControl.ItemSet).WSDownload(ccr,env,token,,ISid,.tFilename)
					If $$$ISERR(sc) Write ..EscapeHTML($system.Status.GetErrorText(sc)),! Continue 

					Write "ItemSet XML downloaded successfully:",!,"   ",tFilename,!
					Write "Download() of ItemSet XML to file system is complete.",!,!

					Set sc=##class(%Studio.SourceControl.ItemSet).Import(tFilename,.obj)
					If $$$ISERR(sc) Write ..EscapeHTML($system.Status.GetErrorText(sc)),! Continue 

					Set pNewID=obj.%Id()
					Write "New ItemSet Object created on system with local ID="_pNewID,!
					Write $C(9),"CCR:",obj.CCR,!
					Write $C(9),"Created By:",obj.CreatedBy,!
					Write $C(9),"Source:",obj.Source,!
					Write $C(9),"Target:",obj.Target,!
					Write "Import() of ItemSet object to DB is complete.",!,!
	
					Write "Creating preview of loading Payload to file system...",!
					Set sc=obj.LoadToOS(,,,.tReadWrite,1)
					Set output=..ConvertStreamToHTML(obj.Log)
					While ('output.AtEnd) {
						Write output.Read(8000)
					}
					&html<
						Preview of Load Complete.
					>
					If $$$ISERR(sc) Write ..EscapeHTML($system.Status.GetErrorText(sc)),! Continue 
					If (($zconvert(env,"U")="BASE")&&($D(tReadWrite)>1)) {		
						//On BASE environments we will not allow incoming ItemSets to blow away checked out (Read/Write) files as it can result in lost legitimate work
						//In non-BASE environments we will allow the incoming file to overwrite a local ReadWrite file as the assumption it was temporary (no legitimate changes should originate in non-BASE environments)
						Set logAddition = ""
						Set logAddition($increment(logAddition))=$ZDT($H,3)
						Set logAddition($increment(logAddition))="ERROR: The following items exist on the filesystem as Read/Write:"
						Set item="", item=$O(tReadWrite(item))
						While (item'="") {
							Set logAddition($increment(logAddition))=$char(9)_item
							Set item=$O(tReadWrite(item))
						}
						Set logAddition($increment(logAddition))="This means most likely they are currently being edited, and loading"
						Set logAddition($increment(logAddition))="a new copy could result in lost work."
						Set logAddition($increment(logAddition))=""
						Do obj.LogHistory.MoveToEnd()
						For line=1:1:logAddition {
							Write logAddition(line),!
							Do obj.LogHistory.WriteLine(logAddition(line))
						}
						Do obj.LogHistory.%Save(0)
				
						Set sc = $$$ERROR($$$GeneralError,"Cannot load ItemSet due to checked out item(s) in the Workspace in BASE Environment")
						Write ..EscapeHTML($system.Status.GetErrorText(sc)),! Continue 	
					}
					&html<</PRE>>
					if (autoload) {
						&html<<p>Automatically loading ItemSet...</p>>
					}
					&html<<FORM ACTION="" name="loadform" method=post name="download" action='#(..SelfLink())#'>
							<TABLE>
								<TR>
									<TD colspan='3'>
										Click the button below to Load the contents of this ItemSet into the #($namespace)# namespace
									</TD>
								</TR>
								<TR>
									<TD>&nbsp;
										<input id="action" name="action" type="hidden" value="Load">
										<input id="id" name="id" type="hidden" value="#(obj.%Id())#">
									</TD>
									<TD>
										<input class = "frost-primary-button" type="Submit" id="submitbtn" name="submitbtn" value="Load ItemSet" title="Load ItemSet" onclick="needToConfirm = false;" ></input>
									</TD>
								</TR>
							</TABLE>
						</FORM>			
						<script language="JavaScript">
						if(#(autoload)#) {
							// Hide the form to avoid the user clicking the button.
							document.forms["loadform"].style.display = 'none';
							document.forms["loadform"].submit();
						}						
						var needToConfirm = true;
						window.onbeforeunload = confirmExit;
						function confirmExit()
						{
							if (needToConfirm)
								return "You have attempted to leave this page but have not Loaded the ItemSet yet (this is only a preview).  Click 'Load ItemSet' to finish your task.\n\nAre you sure you want to exit this page without Loading the ItemSet?";
						}
						</script>
						</div>
						</div>
					>
				} While (0)
				If $$$ISERR(sc) {
					//caught error stopped workflow; send the details to the CCR Server
					Set logAddition = ""
					If (token'="") {
						Set env=$$Env^%buildccr
						If $isobject(obj) { Set history=obj.LogHistory }
						Set tSc=##class(%Studio.SourceControl.ItemSet).WSConfirmLoad(ISid,ccr,env,token,sc,$get(history))
						If $$$ISOK(tSc) { 
							Set logAddition = $ZDT($H,3)_": ConfirmLoad WS successfully called"
						} Else {
							Set logAddition = $ZDT($H,3)_": Error returned from ConfirmLoad WS: "_$system.Status.GetErrorText(tSc) 
						}
					} Else {
						Set logAddition = $ZDT($H,3)_": *** NOTE: ConfirmLoad WebService not called because ServerToken was not available ***"
					}
					Do obj.LogHistory.MoveToEnd()
					Do obj.LogHistory.WriteLine(logAddition)
					Do obj.LogHistory.%Save(0)		
				}
			}
		}
		If $$$ISERR(sc) {
			&html<
				<script language='javascript'>
				document.getElementById('matCard').style.paddingBottom= '0px';
				document.getElementById('cardContent').style.backgroundColor= '#ffe5e5';
				</script>
			>
		}
	}
}

ClassMethod LoadDisplay(DisplayForm As %Boolean)
{
	Set tShowForm='$data(%request.Data("submit"))				//if there was no submit button passed, show the initial form
	Set tShowForm=tShowForm&&('$data(%request.Data("id")))		//see if an id of a local ItemSet was passed
	Set autoclose = $data(%request.Data("autoclose"))			//if set automatically close the tab following successful ItemSet Download and Load
	If $data(DisplayForm) Set tShowForm=DisplayForm				//if an explicit directive on showing the form was passed, follow that instruction
	If (tShowForm) {
		#; Display input form
		&html<
			<script language="JavaScript" type="text/javascript" src="cspxmlhttp.js"></script>
			<script language="JavaScript" type="text/javascript" src="cspbroker.js"></script>
			<div class = "frost-card" id = "matCard" >
			<script language='javascript'>
				try {
					window.onload = updateInfoPosition;
					window.onresize = updateInfoPosition;
				} catch (error) {
					// Handle Studio case
					document.getElementById('systemInfo').style.top= 110;
				}
				
			</script>

			<div class = "frost-outer-header">
			<div class ="frost-inner-header">
			<H2 class = "frost-card-header" >Load ItemSet</H2> 
			</div>
			</div>
			<div class = "frost-card-content" >
			<P>Enter the ID of the ItemSet whose contents you wish to Load into the #($namespace)# Namespace

			<FORM ACTION="" method=post name="download">
				<P>
				<TABLE>
					<TR>
						<TD class = "frost-label"><label>ItemSet ID &nbsp</label></TD>
						<TD><input id="id" name="id"></input></TD>
					</TR>
					<TR>
						<TD  colspan='2'> &nbsp </TD>
					</TR>
					<TR>
						<TD></TD>
						<TD><input class = "frost-primary-button" type="Submit" id="submit" name="submit" value="Load ItemSet" title="Load ItemSet"></input></TD>
					</TR>
				</TABLE>
			</FORM>		
			</div>
			</div>
		>
	} ElseIf ('tShowForm) {
		#; Process form submission
		If (('##class(%Studio.SourceControl.ISC).Disconnected())&&('##class(%Studio.SourceControl.ISC).DefaultCredentialsDefined())&&('..PerforceLoggedIn())) {
			//TODO - refactor when above Form is refactored to allow ItemSet loading from random location on OS
			Write "ItemSet cannot be loaded into Connected namespace unless user is logged in!!"  
		}
		Set objId=$get(%request.Data("id",1))

		&html<
			<div class = "frost-card" id = "matCard" >  
			<script language='javascript'>
				try {
					window.onload = updateInfoPosition;
					window.onresize = updateInfoPosition;
				} catch (error) {
					// Handle Studio case
					document.getElementById('systemInfo').style.top= 110;
				}
			</script>
			<div class = "frost-outer-header">
			<div class ="frost-inner-header">
			<H2 class = "frost-card-header">ItemSet Load</H2>
			</div>
			</div>
			<div class = "frost-card-content-with-notifs" id="cardContent"> 
			<P class = "frost-text">Load Results:
			<PRE class = "frost-card-content-no-top-margin">
		>
		Do %session.Set("CHANGECONTROL.BYPASS",1)
		Do {
			Set obj=##class(%Studio.SourceControl.ItemSet).%OpenId(objId)
			If '$isobject(obj) {
				Set sc=$$$ERROR($$$GeneralError,"No Valid ItemSet Id passed to page")
				Continue
			}
			
			// Determine if ItemSet should use Environment Initialization logic. When available to client, check EnvInit Property instead
			Set isEnvInit = (obj.CCR = "") && (obj.Target = "Client")
			If isEnvInit {
				Write "Exporting to current Tier 1 items to backup directory.",!
				Set sc = obj.BackupBaseline(.backupSourcesDir)
				While ('obj.Log.AtEnd) {
					Write obj.Log.Read(8000)
				}
			}
			
			Write !,"Loading files to the OS from Payload file...",!
			Set sc=obj.LoadToOS(,,.itemlist,,,1)
			Set output=..ConvertStreamToHTML(obj.LogHistory)
			While ('output.AtEnd) {
				Write output.Read(8000)
			}
			If $$$ISERR(sc) Continue

			Write !,"Loading of Payload contents to file system is complete.",!
			
			Set pCompile=2 //might want to prompt for this on previous page in the future; use 2 to indicate that compile should not happen if it includes the %Studio.SourceControl.ItemSet class
			Set sc=obj.LoadToNS(,.itemlist,0,pCompile,.incPercent,,$get(backupSourcesDir))
			Set output=..ConvertStreamToHTML(obj.Log)
			While ('output.AtEnd) {
				Write output.Read(8000)
			}
			If $$$ISERR(sc) Continue
		} while (0)
		Do %session.Kill("CHANGECONTROL.BYPASS")
		If $isobject(obj) {
			Write "******   ItemSet Load() Method Complete: "_objId_"   ******",!,!

			Write $TRANSLATE($JUSTIFY(" ",80)," ","="),!
			Write "ItemSet Import Summary:",!
			Write "     ItemSet Name:        ",obj.Name,!
			Write "     New ItemSet Id:      ",objId,!
		}
		If $$$ISERR(sc) {
			Write "WARNING: Errors occurred during Load().",!
			Write "    Most recent error(s):",!,!
			Write "    ",..EscapeHTML($system.Status.GetErrorText(sc)),!,!
			Write "    Please carefully examine session details",!,!
			&html<
				<script language='javascript'>
				document.getElementById('matCard').style.paddingBottom= '0px';
				document.getElementById('cardContent').style.backgroundColor= '#ffe5e5';
				</script>
			>
		}
		&html<</PRE> </div> </div>>
		If $G(incPercent)&&(##class(%Studio.SourceControl.ItemSet).IRISLIBReadOnly()) {
			&html<
				NOTE: This ItemSet contains %routines or %classes which must be loaded to IRISLIB<BR>
				Please change IRISLIB to Read/Write and then try Loading ItemSet again: <A HREF="#(..SelfLink())#&action=Load&id=#(objId)#">Reload ItemSet #(objId)#</A>
			>
			Set autoclose=0
		} 
		If (autoclose) {
			&html<
				<script language='javascript'>
					window.close();
				</script>
			>			
		}
	}
}

/// Given an internal name of an item, determine if it is an exception for the NoUpload flag
ClassMethod IsNoUploadException(name As %String) As %Boolean
{
	// Start with name of the item and work backwards, this excludes irrelevant nodes
	Set exception = $Order(^Sources("NoUploadOverride",name))
	For {
		Set exception = $Order(^Sources("NoUploadOverride",exception),-1)
		If ($Piece(name, ".", 1, $length(exception,".")) = exception) && $Get(^Sources("NoUploadOverride",exception)) {
			Return 1
		} ElseIf exception = "" {
			Quit
		}
		
	}
	Return 0
}

/// Method to instantiate a source control object and call UndoCheckout for a given internal name
ClassMethod UndoItem(internalName As %String) As %String
{
	Set sc = $$$OK
	Set logMessage = ""
	Set sc = ##class(%Studio.SourceControl.Interface).SourceControlCreate()
	If $$$ISERR(sc) Do ..ShowError(sc)
	Set commandLog = ##class(%Stream.GlobalCharacter).%New()
	Kill io
	Set io = $select(##class(%Studio.SourceControl.ISC).Disconnected():"UndoCheckout", 1:"Revert")
	Do ##class(%Studio.SourceControl.ItemSet).LogToggleCore(.io, .commandLog)
	Set $ZT="Catch"
	Set tmpSourceControl = %SourceControl
	New %SourceControl
	Set sc = tmpSourceControl.UndoCheckout(internalName)
	If $$$ISERR(sc) Do $System.Status.DisplayError(sc) 
	Do ##class(%Studio.SourceControl.ItemSet).LogToggleCore(.io, .commandLog)
	Do commandLog.Rewind()
	While 'commandLog.AtEnd {
		Set logMessage = logMessage _ commandLog.ReadLine() _ $c(13,10)
	}
	Return logMessage
Catch s $ZT="" w "ERROR TRAPPED: ",$ZE,! d ##class(%Studio.SourceControl.ItemSet).LogToggleCore(.io) quit ""
}

ClassMethod BundleDisplay(DisplayForm As %Boolean)
{
	Set tShowForm='$data(%request.Data("submit"))				//if there was no submit button passed, show the initial form
	If $data(DisplayForm) Set tShowForm=DisplayForm				//if an explicit directive on showing the form was passed, follow that instruction
	If (tShowForm) {
		#; Display input form and pull in the scripts required to check the CCR Server for upload validation
		&html<
			<script language="JavaScript" type="text/javascript" src="cspxmlhttp.js"></script>
			<script language="JavaScript" type="text/javascript" src="cspbroker.js"></script>
			<div class = "frost-card" id = "matCard">
			<script language='javascript'>
				try {
					window.onload = updateInfoPosition;
					window.onresize = updateInfoPosition;
				} catch (error) {
					// Handle Studio case
					document.getElementById('systemInfo').style.top= 110;
				}
			</script>
			<div class = "frost-outer-header" >
			<div class = "frost-inner-header" >
			<H2 class = "frost-card-header" >Bundle and Upload ItemSet</H2> 
			</div>
			</div>
			<div class = "frost-card-content">
			<P>Select the Uncommitted Changes to Bundle into an ItemSet.<BR/>
				Then, fill in the fields at the bottom to upload the ItemSet 
				to the CCR Server and submit the selected changes into Perforce.
			<H3 >Filter Uncommitted Changes by:</H3>
			<FORM ACTION="" method=post name="filter">
				<TABLE>
					<TR>
						<TD><label id="cSourceFilter" class = "frost-label">Source &nbsp &nbsp &nbsp</label></TD>
						<TD><input id="SourceFilter" name="SourceFilter" size=10 value="#($G(%request.Data("SourceFilter",1)))#"></input></TD>
					</TR>
					<TR>
						<TD><label id="cChangedByFilter" class = "frost-label">Changed By &nbsp &nbsp &nbsp</label></TD>
						<TD>
							<input id="ChangedByFilter" name="ChangedByFilter" size=10 value="#($G(%request.Data("ChangedByFilter",1)))#"></input>
							<A HREF="Javascript:filterByMe('#($USERNAME)#');">[me]</A>
						</TD>
					</TR>
					<TR>
						<TD><label id="cCCRFilter" class = "frost-label">CCR &nbsp &nbsp &nbsp</label></TD>
						<TD><input id="CCRFilter" name="CCRFilter" size=10 value="#($G(%request.Data("CCRFilter",1)))#"></input></TD>
					</TR>
					<TR style = "height: 5px;"> </TR>
					<TR>
						<TD align='right'>&nbsp;</TD>
						<TD>
						<input class = "frost-secondary-button" type="Button" id="Filter" name="Filter" value="Filter" title="Filter Uncommitted Change list" onclick="javascript:document.filter.submit()"></input>
						&nbsp &nbsp &nbsp
						<input class = "frost-secondary-button" type="Button" id="Clear" name="Clear" value="Clear" title="Clear Filters" onclick="javascript:clearFilter()"></input>
						</TD>
					</TR>
					<TR style = "height: 5px;"> </TR>
				</TABLE>
			</FORM>
			<FORM ACTION="" method=post name="uncommitted" onsubmit="return checkSubmitted()">
				<TABLE>
					<TR>
						<TD>
							<TABLE width='100%'>
								<TR>
									<TD valign=top style='padding-left:0;'>
										<TABLE cellspacing=0 class = "frost-table">
											<THEAD>
												<TR align='left' class = "frost-table-header-row"> 
													<TH colspan = "10" class = "frost-table-header" > Uncommitted Queue </TH>
												</TR>
												<TR align='left'>
													<TH style='display:none;'></TH>
													<TH class = "frost-table-header-cell" style = "vertical-align: middle" id=1 NOWRAP><input name="allbox" type="checkbox" value="Check All" onclick="CheckAll(document.uncommitted);" /></TH>
													<TH class = "frost-table-header-cell" id=2 NOWRAP>Last Changed &nbsp</TH>
													<TH class = "frost-table-header-cell" id=3 NOWRAP>Source &nbsp</TH>
													<TH class = "frost-table-header-cell" id=4 NOWRAP>CCR &nbsp</TH>
													<TH class = "frost-table-header-cell" id=5 NOWRAP>Changed By &nbsp</TH>
													<TH class = "frost-table-header-cell" id=6 NOWRAP>Action &nbsp</TH>
													<TH class = "frost-table-header-cell" id=7 NOWRAP>Name &nbsp</TH>
													<TH class = "frost-table-header-cell" id=8 NOWRAP>Internal Name &nbsp</TH>
													<TH class = "frost-table-header-cell" id=9 NOWRAP>Diff &nbsp</TH>
													<TH class = "frost-table-header-cell" id=10 NOWRAP>Undo &nbsp</TH>
												</TR>
											</THEAD>
			>
			Set sourceFilter=$G(%request.Data("SourceFilter",1))
			Set userFilter=$G(%request.Data("ChangedByFilter",1))
			Set ccrFilter=$G(%request.Data("CCRFilter",1))
			Set query = "SELECT ID, UpdatedTime, Source, CCR, ChangedBy, Action, Name, InternalName, ItemFile, ExternalName, BackupName FROM %Studio_SourceControl.Change "
			Set query = query_"WHERE Committed='0' "
			If sourceFilter'="" Set query = query_"AND Source='"_sourceFilter_"' "
			If userFilter'="" Set query = query_"AND ChangedBy='"_userFilter_"' "
			If ccrFilter'="" Set query = query_"AND CCR='"_ccrFilter_"' "
			Set query = query_"ORDER BY UpdatedTime DESC"
			Set rset=##class(%ResultSet).%New("%DynamicQuery:SQL")
			Set sc=rset.Prepare(query)
			Set sc=rset.Execute()	
			Set i=0
			Kill uniqueList,deleteList
			Merge selected=%request.Data("check")
			Set cnt=$O(selected(""),1,key)
			While (cnt'="") {
				Set idxList=$get(idxList)_$LB(key)
				Set cnt=$O(selected(cnt),1,key)
			}
			Kill selected			
			While (rset.Next()) {
				Set i=$I(i)
	  			Set rowColor=$S(i#2:"#e0e0ff",1:"#ffffff")
				If $USERNAME=rset.Data("ChangedBy") {
					Set userCheckIds("check|"_i)=""
				}
				Set checked=$select($listfind($get(idxList),i):" checked",1:"")
				Set isConfig = $LV(rset.Data("InternalName"))
				Set internalName=$S(isConfig:$LTS(rset.Data("InternalName"),"@"),1:rset.Data("InternalName"))
				 
				// Disable and hide checkbox if NoUpload flag is set and InternalName is not a NoUpload exception
				// As of DP-428428, exceptions are restricted to exported classes
				If 'isConfig && $Get(^SYS("SourceControl", "ItemSetConfig", "NoUpload")) && $Get(^Sources("NoUploadOverride")) {
					Set disabledFlag = " disabled='disabled' style='display:none;'"
					Set ext = $Piece(internalName,".",*)
					Set ext = $ZConvert(ext, "U")
					If ext = "CLS" {
						// If internalName includes row ID, just get class name
						Set className = $Piece(internalName, ext, 1, *-1)
						If ..IsNoUploadException(className) {
							Set disabledFlag = ""
						}
					}
				}

				Set checkBoxHTML="<input name='check' value='"_i_"' id='check|"_i_"' type='checkbox' onclick='Javascript:checkbox();' "_checked_$Get(disabledFlag)_">"
				Set itemName=$S($LV(rset.Data("Name")):$LTS(rset.Data("Name"),"@"),1:rset.Data("Name"))
				Set diffcode=""
				Set undocode = ""
				If (rset.Data("ExternalName")'="") {
					If (rset.Data("BackupName")'="") {
						Set file=rset.Data("ExternalName")
						If ##class(%File).Exists(file) && ##class(%File).Exists(rset.Data("BackupName")) {
							Set diffcode="<a href='"_..SelfLink()_"&action=Diff&file="_..EscapeURL(file)_"&return=Bundle'>diff</a>"
						} 
					}
					If (rset.Data("ChangedBy") = $username) {
						Set undoText = $Select(rset.Data("Action")="add":"undo add", 1:"undo checkout")
						set undocode="<input class = ""frost-secondary-button"" type=""button"" id=""Undo"" name=""Undo"" value="""_undoText_""" title=""Undo change"""_
						"onmouseover=""this.style.color='#2b2b2b'; this.style.border='2px solid #2b2b2b'"" onmouseout=""this.style.color='#333694'; this.style.border='2px solid #333694'"""_
						"style=""font-size: 0.8125rem; font-weight: 400; line-height: 1.125rem;"" onclick=""javascript:callUndo("_..QuoteJS(internalName)_");""></input>"
					}
				}
				&html<
					<TR class = "frost-table-row" BGCOLOR="#(rowColor)#" title="#(rset.Data("ItemFile"))#" NOWRAP>
						<TD style='display:none;'><input id="ChangeId" name="ChangeId" type="hidden" value="#(rset.Data("ID"))#"></TD>
						<TD class = "frost-table-cell">#(checkBoxHTML)# &nbsp</TD>
						<TD class = "frost-table-cell">#(rset.Data("UpdatedTime"))# &nbsp</TD>
						<TD class = "frost-table-cell">#(rset.Data("Source"))# &nbsp</TD>
						<TD class = "frost-table-cell" ><a href='#($$CCRServer^%buildccr)#/ccr/view.csp?RID=#(rset.Data("CCR"))#' target='_blank'>#(rset.Data("CCR"))#</a> &nbsp</TD>
						<TD class = "frost-table-cell">#(rset.Data("ChangedBy"))# &nbsp</TD>
						<TD class = "frost-table-cell">#(rset.Data("Action"))# &nbsp</TD>
						<TD class = "frost-table-cell">#(itemName)# &nbsp</TD>
						<TD class = "frost-table-cell">#(internalName)# &nbsp</TD>
						<TD class = "frost-table-cell">#(diffcode)# &nbsp</TD>
						<TD class = "frost-table-cell">#($get(undocode))# &nbsp</TD>
					</TR>
				>
			}
			&html<
										</TABLE>
									</TD>
								</TR>
							</TABLE>
						</TD>
					</TR>
			>
			If (i>0) {
				&html<
					<TR>
						<TD><input class = "frost-secondary-button" type="button" id="Mine" name="Mine" value="Select Mine" title="Select Mine" onclick="CheckMine();"></input>   (#($USERNAME)#)</TD>
					</TR>
					<TR style = "height: 20px;"> </TR>
					<TR>
						<TABLE>
							<TR>
								<TD title='Provide an Access Token to enable Upload'><label id="cPath" class = "frost-label">Access Token &nbsp &nbsp</label></TD>
								<TD>
									<input id="token" name="token" size='16' onchange="javascript:ValidateToken();" value="#($get(%request.Data("token",1)))#"></input>
									<span id="tokenCheck">&nbsp;&nbsp;&nbsp;&nbsp;</span>
								</TD>
							</TR>
							<TR>
								<TD ><label id="cCCR" class = "frost-label">CCR &nbsp &nbsp</label></TD>
								<TD>
									<input id="ccr" name="ccr" size='16' onchange="javascript:ValidateCCR();" value="#($select($data(%request.Data("ccr",1)):$get(%request.Data("ccr",1)),1:$$Org^%buildccr_"xxxx"))#"></input>
									<span id="ccrCheck">&nbsp;&nbsp;&nbsp;&nbsp;</span>
								</TD>
							</TR>
							<TR>
								<TD>
								</TD>
								<TD>
									<div id='ccrCheckReason' align='right' style="display: none;">
										<code id="canUploadStatus"></code>
										<span id="Revalidate" name="Revalidate CCR" value="Revalidate" title="Rerun Upload Validation Check" 
													style="cursor:pointer;" onclick="javascript:ValidateCCR();">&#10227;</span>
									</div>
								</TD>
							</TR>
							<TR>
								<TD><input type="hidden" id='autoUpload' name="autoUpload" value="1" /></TD>	
								<TD>
									<div id='submitting' style="display: none;">Bundling ItemSet...</div>
									<input class = "frost-primary-button" type="submit" id="submitBtn" name="submit" disabled="true" value="Bundle Changes" title="Bundle changes into an ItemSet"></input>
									<input type="hidden" name="CSPCHD" value="#($Piece(%session.CSPSessionCookie,";"))#" />
									<input type="hidden" name="CSPSHARE" value="1" />
								</TD>
							</TR>
						</TABLE>
					</TR>
					<TR>
						<TD>&nbsp;</TD>
					</TR>
					<TR>
						<TD>
							<div id='ccrCCRDetails' align='left' style="display: none;">
							<div style = "height: 10px;"> </div>
							<TABLE cellspacing=0 class = "frost-table">
								<THEAD>
									<TR align='left' class = "frost-table-header-row">
										<TH class = "frost-table-header" colspan='2' NOWRAP>CCR Details</TH>
									</TR>
								</THEAD>
								<TR class = "frost-table-row">
									<TD class = "frost-table-header-cell-left"><Strong>CCR</Strong></TD>
									<TD class = "frost-table-header-cell" id='detailsRID'></TD>
								</TR>
								<TR class = "frost-table-row">
									<TD class = "frost-table-header-cell-left"><Strong>Title</Strong></TD>
									<TD class = "frost-table-header-cell" id='detailsTitle'></TD>
								</TR>
								<TR class = "frost-table-row">
									<TD class = "frost-table-header-cell-left"><Strong>Owner</Strong></TD>
									<TD class = "frost-table-header-cell" id='detailsUsername'></TD>
								</TR>
								<TR class = "frost-table-row">
									<TD class = "frost-table-header-cell-left"><Strong>State</Strong></TD>
									<TD class = "frost-table-header-cell" id='detailsCurrentState'></TD>
								</TR>
								<TR class = "frost-table-row">
									<TD class = "frost-table-header-cell-left"><Strong>SystemCode</Strong></TD>
									<TD class = "frost-table-header-cell" id='detailsSystemCode'></TD>
								</TR>
								<TR class = "frost-table-row">
									<TD class = "frost-table-header-cell-left"><Strong>SiteCode</Strong></TD>
									<TD class = "frost-table-header-cell" id='detailsSiteCode'></TD>
								</TR>
							</TABLE>
							</div>						
						</TD>
					</TR>
					<div style = "height: 10px;"> </div>
					<TR>
						<TD><label id="cPath" >Path:</label>&nbsp;<code>#(^Sources)#</code></TD>
					</TR>
					<!--tr><td><pre><script language='cache' runat='server'> zw </script></pre></td></tr-->
				>
			} Else {
				&html<
					<TR class = "frost-text">
						<TD>
							No uncommitted changes exist in this namespace
						</TD>
					</TR>						
				>
			}
			&html<
				</TABLE>
			</FORM>	
			</div>
			</div>
			<script language="javascript">
			function ValidateToken() {
				document.getElementById('tokenCheck').innerHTML='';
				document.getElementById('ccrCCRDetails').style.display='none';

				//FetchCCRDetails will update the form indicating the validity of the token
				FetchCCRDetails();
			}
			function ValidateCCR() {
				document.getElementById('ccrCheckReason').style.display='none';
				document.getElementById('ccrCCRDetails').style.display='none';
				document.getElementById('submitBtn').disabled=false;
				#server(..ValidateCCRUpload(document.getElementById('ccr').value))#;

				FetchCCRDetails();
			}
			function FetchCCRDetails() {
				if (document.getElementById('token').value!='') {
					document.getElementById('submitBtn').value='Bundle and Upload Changes';
					#server(..RetrieveCCRDetails(document.getElementById('ccr').value,document.getElementById('token').value))#;
				} else {
					document.getElementById('submitBtn').value='Bundle Changes';
				}
			}

			function checkbox() {
				CheckCheckAll(document.uncommitted);
			}
			function CheckAll(fmobj) {
			  for (var i=0;i<fmobj.elements.length;i++) {
			    var e = fmobj.elements[i];
			    if ((e.name != 'upload') && (e.name != 'allbox') && (e.type=='checkbox') && (!e.disabled) ) {
			      e.checked = fmobj.allbox.checked;
			    }
			  }
			}
			function CheckCheckAll(fmobj) {
			  var TotalBoxes = 0;
			  var TotalOn = 0;
			  for (var i=0;i<fmobj.elements.length;i++) {
			    var e = fmobj.elements[i];
			    if ((e.name != 'upload') && (e.name != 'allbox') && (e.type=='checkbox')) {
			      TotalBoxes++;
			      if (e.checked) {
			       TotalOn++;
			      }
			    }
			  }
			  if (TotalBoxes==TotalOn) {
			    fmobj.allbox.checked=true;
			  }
			  else {
			   fmobj.allbox.checked=false;
			  }
			}
			function filterByMe(user) {
				var el=document.getElementById('ChangedByFilter');
				el.value=user;
				document.filter.submit();	
			}
			function clearFilter() {
				var el1=document.getElementById('CCRFilter');
				var el2=document.getElementById('ChangedByFilter');
				var el3=document.getElementById('SourceFilter');
				el1.value="";
				el2.value="";
				el3.value="";
				document.filter.submit();	
			}
			var submitted = false;
			function checkSubmitted() {
				if(!submitted) {
					submitted = true;
					document.getElementById('submitBtn').style.display = 'none';
					document.getElementById('submitting').style.display='block';
					return submitted;
				}
				
				return false
			}
			function callUndo(internalName) {
				message = #server(..UndoItem(internalName))#;
				if (message != "") {
					alert(message);
				}
				window.location.href='#(..SelfLink())#&action=Bundle';
			}
			</script>
		>
		Write "<script language='javascript'>"
		Write "function CheckMine(fmobj) {",!
		Set id=""
		Set id=$O(userCheckIds(id))
		While (id'="") {
			Write "var el = document.getElementById('"_id_"');",!
			Write "el.checked=true;",!
			Set id=$O(userCheckIds(id))
		}
		Write "}",!
		If ($data(%request.Data("ccr",1))) {
			//A CCR was passed to the form, so validate it
			&js<ValidateCCR();>
		}
		Write "</script"_">"
	} ElseIf ('tShowForm) {
		#; Process form submission
		Set ccr=$zcvt($zstrip($get(%request.Data("ccr",1)),"<>W"),"U")
		Set token=$zstrip($get(%request.Data("token",1)),"<>W")
		Merge selected=%request.Data("check")
		Set failed=0
		If (ccr="")||($length(ccr)<8)||($extract(ccr,5,8)="XXXX") {
			Set failed=1, errMessage="You must enter a valid CCR to Bundle an ItemSet"
		} ElseIf ('$data(selected)) {
			Set failed=1, errMessage="You must select at least one item to Bundle into the ItemSet"	
		}
		Kill selected
		If (failed) {
			&html<	
			<div id = "failureNotif" class = "frost-failure-outer"> 
				<div class = "frost-failure-middle"> 
					<div class = "frost-failure-inner"> 
						<div class = "frost-failure-message" > #(errMessage)# </div>  
					</div>
				</div>
			</div>
			<script language='javascript'>
				if (document.addEventListener) {
					document.addEventListener('click', function(event) {
						var popup = document.getElementById('failureNotif');
						if (!popup.contains(event.target)) {
							popup.style.display = 'none'; // Hide the element when clicked outside
						}
					});
				} else if (document.attachEvent) { // Handle Studio case
					document.getElementById('systemInfo').style.top= 200;
					document.attachEvent('onclick', function(event) {
						var popup = document.getElementById('failureNotif');
						popup.style.display = 'none'; //Hide the element upon any page click
						document.getElementById('systemInfo').style.top= 110;
                	})
                }
			</script>
			>
			Do ..BundleDisplay(1)
			&html<
				<script language = 'javascript'>
				if (document.attachEvent) { //In Studio case, move system info down while displayed
					var popup = document.getElementById('failureNotif');
					if (popup.style.display !== 'none') {
						document.getElementById('systemInfo').style.top= 200;
					}
				}
				</script>
			>
			Quit
		}
		&html<
			<div id = "matCard" class ="frost-card">  
			
			<script language='javascript'>
				try {
					window.onload = updateInfoPosition;
					window.onresize = updateInfoPosition;
				} catch (error) {
					// Handle Studio case
					document.getElementById('systemInfo').style.top= 110;
				}
			</script>
			
			<div class = "frost-outer-header">
			<div class ="frost-inner-header">
			<H2 class = "frost-card-header" >Bundle ItemSet Results</H2>
			</div>
			</div>
			<div class = "frost-card-content-with-notifs" id="cardContent"> 
			<PRE class = "frost-card-content-no-top-margin">
		>
		Write !
		Do {
			Set log=##class(%GlobalCharacterStream).%New()
			Set env=$$Env^%buildccr
			Set token=$zstrip($get(%request.Data("token",1)),"<>W")
			//First confirm that the access token is valid if an upload will be attempted
			If token'="" {
				Set sc=##class(%Studio.SourceControl.ItemSet).WSList(ccr,env,token,.rs)
				If $$$ISERR(sc) {
					Set uploadStatus=$SYSTEM.Status.GetErrorText(sc)
					If uploadStatus["#6059" {
						Do log.WriteLine("NOTE:  Connectivity to CCR Server cannot be established")
						Do log.WriteLine("ItemSet will need to be uploaded to CCR Server from another machine")
					} Else {
						Do log.WriteLine($SYSTEM.Status.GetErrorText(sc)) Continue
					}
				}
			}
			Kill exportedlist,committedRows
			Merge selected=%request.Data("check")
			Merge ChangeIds=%request.Data("ChangeId")
			Do log.WriteLine($TRANSLATE($JUSTIFY(" ",80)," ","-")) 
			Do log.WriteLine("Processing list of changes to Bundle into an ItemSet") 
			Set cnt=$O(selected(""),1,key), cntIncluded=0
			While (cnt'="") {
				Set changeId=ChangeIds(key)
				Kill change
				Set change=##class(%Studio.SourceControl.Change).%OpenId(changeId)
				If '$isobject(change) {
					Do log.WriteLine($C(9)_"ERROR: Id='"_changeId_"' does not correspond to a %Studio.SourceControl.Change object") 
				} ElseIf change.Committed {
					Do log.WriteLine($C(9)_"ERROR: "_change.Name_" has already been committed") 
				} Else {
					Set cntIncluded=$I(cntIncluded)
					Set exportedlist(change.ItemFile)=change.Action
					Do log.WriteLine($C(9)_"Including "_change.Name_" stored in "_change.ItemFile)
				}
				Set cnt=$O(selected(cnt),1,key)
			}
			Do log.WriteLine($C(9)_cntIncluded_" changed items selected for inclusion") 
			If (cntIncluded>0) {
				Do log.WriteLine($TRANSLATE($JUSTIFY(" ",80)," ","="))
				Do log.WriteLine("Creating new Itemset...")
				Set objItemSet=##class(%Studio.SourceControl.ItemSet).%New()
				Set sc=objItemSet.Create(.exportedlist,ccr,$USERNAME,env,"Server",ccr,env)
				Do log.MoveToEnd() Do log.CopyFrom(objItemSet.LogHistory)
				If $$$ISERR(sc) Do log.WriteLine($SYSTEM.Status.GetErrorText(sc)) Kill objItemSet Continue
				Set pNewID=objItemSet.%Id()
				Do log.WriteLine("New ItemSet Object created on system with local ID="_pNewID)
				Do log.WriteLine("")

				Do log.WriteLine("Exporting ItemSet to XML ...")
				Set sc=objItemSet.ExportToFile(.file)
				Do log.MoveToEnd() Do log.CopyFrom(objItemSet.Log)
				If $$$ISERR(sc) Do log.WriteLine($SYSTEM.Status.GetErrorText(sc)) continue

				Do log.WriteLine("ItemSet [%Id="_objItemSet.%Id()_"] created, and exported as XML:")
				Do log.WriteLine($C(9)_objItemSet.ItemSetFile)
				Do log.WriteLine("")
			
				Do log.WriteLine("Removing items from local pending list, and changing files to ReadOnly...")
				Set sc=##class(%Studio.SourceControl.Change).RemoveUncommitted(.exportedlist,0)
				If $$$ISERR(sc) Do log.WriteLine($SYSTEM.Status.GetErrorText(sc)) Continue
				Do log.WriteLine("Local list and files have been updated.")
				Do log.WriteLine("")
			}
		} While (0)
		If $$$ISERR(sc) {
			&html<
				<script language='javascript'>
				document.getElementById('matCard').style.paddingBottom= '0px';
				document.getElementById('cardContent').style.backgroundColor= '#ffe5e5';
				</script>
			>
		}
		Do log.WriteLine($TRANSLATE($JUSTIFY(" ",80)," ","="))
		If $isobject($G(objItemSet)) {
			Do log.WriteLine("ItemSet Bundle Summary:")
			Do log.WriteLine("     ItemSet Created:     "_objItemSet.Name)
			Do log.WriteLine("     ItemSet File:        "_objItemSet.ItemSetFile)
			Do log.WriteLine("     Number of Items:     "_cntIncluded)
			Do log.WriteLine("     Upload Status:       "_$S(token'="":"Pending...",1:"Skipped"))
		}
		Else {
			Do log.WriteLine("ItemSet Bundle Summary:")
			Do log.WriteLine("     ERROR:  No ItemSet was created")
			If $G(cntIncluded)=0 Do log.WriteLine("     No items were selected to Bundle")
		}
		Do log.Rewind() 
		Set output=..ConvertStreamToHTML(log)
		While ('output.AtEnd) {
			Write output.Read(8000)
		}
		If $isobject($G(objItemSet)) {
			Do objItemSet.LogHistory.MoveToEnd() Do objItemSet.LogHistory.CopyFrom(log)
			Set sc=objItemSet.LogHistory.%Save()
			If $$$ISERR(sc) Write ..EscapeHTML($system.Status.GetErrorText(sc)),!
		}
		&html<</PRE>>
		If (token'="")&&$isobject($G(objItemSet)) {
			&html<	
				<FORM ACTION="" method=post name="upload" action='#(..SelfLink())#' onsubmit="document.getElementById('submit').setAttribute('disabled', 'disabled'); return true;">
					<TABLE>
						<div style = "height: 10px;"> </div>
						<TR>
							<TD colspan='2'>Click the button below to Upload this ItemSet to the CCR Server</TD>
						</TR>
						<TR>
							<TD>&nbsp;
								<input id="action" name="action" type="hidden" value="Upload">
								<input id="ccr" name="ccr" type="hidden" value="#(ccr)#">
								<input id="token" name="token" type="hidden" value="#(token)#">
								<input id="file" name="file" type="hidden" value="#(objItemSet.ItemSetFile)#">
								<input id="id" name="id" type="hidden" value="#(objItemSet.%Id())#">
							</TD>
							<TD><input class = "frost-primary-button"  type="Submit" id="submit" name="submit" value="Upload ItemSet" title="Upload ItemSet"></input></TD>
						</TR>
					</TABLE>
				</FORM>
			</div>
			</div>			
			>
			if %request.Get("autoUpload") {
				&html<
				<script type="text/javascript">
				document.getElementById("submit").click();
				</script>
				>
			}
		}
	}
}

ClassMethod UploadDisplay(DisplayForm As %Boolean)
{
	Set tShowForm='$data(%request.Data("submit"))				//if there was no submit button passed, show the initial form
	Set tShowForm=tShowForm&&('$data(%request.Data("ccr")))		//see if a ccr has been passed for the upload
	Set tShowForm=tShowForm&&('$data(%request.Data("token")))	//see if a token has been passed for the upload
	Set tShowForm=tShowForm&&('$data(%request.Data("file")))	//see if a file has been passed for the upload
	If $data(DisplayForm) Set tShowForm=DisplayForm				//if an explicit directive on showing the form was passed, follow that instruction
	Do ##class(%Studio.SourceControl.ItemSet).GetPathTranslation(.rootDir,.path)
	Set exportDirectory=##class(%File).NormalizeDirectory(rootDir_"ItemSets")
	Set exportDirectory=##class(%File).NormalizeDirectory(exportDirectory_"Export")
	Set ccrOrg = $G(^SYS("SourceControl","ItemSetConfig","Org"))
	Set exportDirectory=##class(%File).NormalizeDirectory(exportDirectory_ccrOrg)
	
	If (tShowForm) {
		#; Display input form
		&html<
			<div class = "frost-card" id = "matCard" >
			<script language='javascript'>
				try {
					window.onload = updateInfoPosition;
					window.onresize = updateInfoPosition;
				} catch (error) {
					// Handle Studio case
					document.getElementById('systemInfo').style.top= 110;
				}
				
			</script>

			<div class = "frost-outer-header">
			<div class ="frost-inner-header">
			<H2 class = "frost-card-header" >Upload ItemSet</H2> 
			</div>
			</div>
			<div class = "frost-card-content" >
			<FORM ACTION="" method=post name="upload" action='#(..SelfLink())#' onsubmit="document.getElementById('submit').setAttribute('disabled', 'disabled'); return true;">
				<TABLE>
					<TR>
						<TD colspan='2'>Fill in the details below to Upload an ItemSet to the CCR Server</TD>
					</TR>
					<TR>
						<TD colspan='2'>Please enter the filename of the ItemSet located in <code>#(exportDirectory)#</code> </TD>
					</TR>
					<TR>
						<TD  colspan='2'> &nbsp </TD>
					</TR>
					<TR>
						<TD class = "frost-label">ItemSet File</TD>
						<TD><input id="file" type='text' name="file" size='35'></TD>
					</TR>
					<TR>
						<TD class = "frost-label">Token</TD>
						<TD><input id="token" name="token"></input></TD>
					</TR>
					<TR>
						<TD  colspan='2'> &nbsp </TD>
					</TR>
					<TR>
						<TD><input id="action" name="action" type="hidden" value="Upload">
							<input type="hidden" name="CSPCHD" value="#($Piece(%session.CSPSessionCookie,";"))#" />
							<input type="hidden" name="CSPSHARE" value="1" />
						</TD>
						<TD><input class = "frost-primary-button" type="Submit" id="submit" name="submit" value="Upload ItemSet" title="Upload ItemSet"></input></TD>
					</TR>
				</TABLE>
			</FORM>			
			</div>
			</div>
		>
	} ElseIf ('tShowForm) {
		#; Process form submission
		Set failed=0
		Set token=$zstrip($get(%request.Data("token",1)),"<>W")
		Set file=$get(%request.Data("file",1))
		If ('##class(%File).Exists(file)) {
			// now assuming that file is NOT a full path and filename.  Therefore add path.
			Set file = ##class(%File).NormalizeFilename(exportDirectory_file)
		}

		&SQL(SELECT id INTO :ISId from %Studio_SourceControl.ItemSet WHERE ItemSetFile = :file)
		Set objItemSet=##class(%Studio.SourceControl.ItemSet).%OpenId(ISId)
		If ($isobject(objItemSet)) {
			Set ccr=objItemSet.CCR
		} Else {
			Set failed=1, notifWidth = 800, errMessage="<code>"_file_"</code> did not match ItemSetFile for any of the rows in the %Studio_SourceControl.ItemSet table "
		}
		If (token="") {
			Set failed=1,  notifWidth = 400, errMessage="You must enter a valid token to Upload an ItemSet"
		} ElseIf (file="")||('##class(%File).Exists(file)) {
			Set failed=1,  notifWidth = 800, errMessage="<code>"_file_"</code> does not exist and cannot be uploaded"
		}
		If (failed) {
			&html<<div id = "failureNotif" class = "frost-failure-outer" style = "inline-size: #(notifWidth)#px; margin-inline-start: #(-notifWidth/2)#px;"> 
				<div class = "frost-failure-middle"> 
					<div class = "frost-failure-inner"> 
						<div class = "frost-failure-message"> #(errMessage)# </div>  
					</div>
				</div>
			</div>
			<script language='javascript'>
				if (document.addEventListener) {
					document.addEventListener('click', function(event) {
						var popup = document.getElementById('failureNotif');
						if (!popup.contains(event.target)) {
							popup.style.display = 'none'; // Hide the element when clicked outside
						}
					});
				} else if (document.attachEvent) { // Handle Studio case
					document.getElementById('systemInfo').style.top= 200;
					document.attachEvent('onclick', function(event) {
						var popup = document.getElementById('failureNotif');
						popup.style.display = 'none'; //Hide the element upon any page click
						document.getElementById('systemInfo').style.top= 110;
                	})
                }
			</script>
			>
			Do ..UploadDisplay(1)
			&html<
				<script language = 'javascript'>
				if (document.attachEvent) { //In Studio case, move system info down while error is displayed
					var popup = document.getElementById('failureNotif');
					if (popup.style.display !== 'none') {
						document.getElementById('systemInfo').style.top= 200;
					}
				}
				</script>
			>
			Quit
		}
		&html<
			<div class = "frost-card" id = "matCard" >  
			
			<script language='javascript'>
				try {
					window.onload = updateInfoPosition;
					window.onresize = updateInfoPosition;
				} catch (error) {
					// Handle Studio case
					document.getElementById('systemInfo').style.top= 110;
				}
			</script>

			<div class = "frost-outer-header">
			<div class ="frost-inner-header">
			<H2 class = "frost-card-header">Upload ItemSet Results</H2>
			</div>
			</div>
			<div class = "frost-card-content-with-notifs" id="cardContent"> 
			<PRE class = "frost-card-content-no-top-margin">
		>
		Write !
		Set log=##class(%GlobalCharacterStream).%New()
		Set env=$G(^SYS("SourceControl","ItemSetConfig","Environment"))
		Do log.WriteLine("")
		Do log.WriteLine("******   ItemSet Upload() Method   ******")
		Do log.WriteLine("Attempting to upload ItemSet to CCR Server for "_ccr_"...")
		Set sc=##class(%Studio.SourceControl.ItemSet).Upload(0, ccr, token, file) 
		If $$$ISOK(sc) {
			Set uploadStatus="Success!"
		} Else {
			&html<
				<script language='javascript'>
				document.getElementById('matCard').style.paddingBottom= '0px';
				document.getElementById('cardContent').style.backgroundColor= '#ffe5e5';
				</script>
			>
			Set uploadStatus=$SYSTEM.Status.GetErrorText(sc)
			If uploadStatus["#6059" {
				Do log.WriteLine("NOTE:  Connectivity to CCR Server cannot be established")
				Do log.WriteLine("Please Upload ItemSet to CCR Server from another machine:")
				Do log.WriteLine($C(9)_file)
			} ElseIf uploadStatus["#5922" {
				// "<ZSOAP> ERROR Trapped: ERROR #5922: Timed out waiting for response" thrown
				Set uploadStatus="Check-in in progress; please see your CCR for final results"
			}
		}
		Do log.WriteLine("ItemSet Upload Summary:")
		Do log.WriteLine("     ItemSet File:        "_file)
		Do log.WriteLine("     Upload Status:       "_$G(uploadStatus))
		Do log.WriteLine("")
		Do log.WriteLine("******   ItemSet Upload() Method Complete   ******")
		Do log.Rewind() 
		Set output=..ConvertStreamToHTML(log)
		While ('output.AtEnd) {
			Write output.Read(8000)
		}
		If $isobject($G(objItemSet)) {
			Do objItemSet.LogHistory.MoveToEnd() Do objItemSet.LogHistory.CopyFrom(log)
			Set sc=objItemSet.LogHistory.%Save()
			If $$$ISERR(sc) Write ..EscapeHTML($system.Status.GetErrorText(sc)),!
		}
		&html<</PRE> </div> </div>>
	}
}

ClassMethod ItemsetlogDisplay(DisplayForm As %Boolean)
{
	Set tShowForm='$data(%request.Data("submit"))				//if there was no submit button passed, show the initial form
	Set tShowForm=tShowForm&&('$data(%request.Data("ccr")))		//see if a ccr was passed
	Set tShowForm=tShowForm&&('$data(%request.Data("id")))		//see if an id was passed
	If $data(DisplayForm) Set tShowForm=DisplayForm				//if an explicit directive on showing the form was passed, follow that instruction
	If (tShowForm) {
		#; Display input form
		&html<
			<h2>ItemSet Log Display</h2>
			<form name="LogView" Action="">
				CCR: <input name="ccr" size='8'><p>
				<input type="hidden" name="action" value="ItemSetLog">
				<input type="hidden" name="CSPCHD" value="#($Piece(%session.CSPSessionCookie,";"))#" />
				<input type="hidden" name="CSPSHARE" value="1" />
				<input type="submit" name="submit" value="Submit">
			</form>
		>
	} ElseIf ('tShowForm) {
		#; Process form submission
		Set ccr=$zstrip($zcvt($get(%request.Data("ccr",1)),"U"),"<>W")
		Set ISid=$get(%request.Data("id",1))
		If (ccr="")&&(ISid="") {
			&html<<DIV Style='color: red;'>You must enter a ccr</DIV>>
			Do ..ItemsetlogDisplay(1)
			Quit
		}
		If (ISid="") {
			&html<<H3>List of ItemSet Logs for #(ccr)#</H3><p>>
			Set sql="Select ID, Name, CreateTimestamp FROM %Studio_SourceControl.ItemSet WHERE CCR=?"
			Set cnt=0, query=##class(%ResultSet).%New("%DynamicQuery:SQL")
			Set sc=query.Prepare(sql) If $$$ISERR(sc) Do $System.OBJ.DisplayError(sc) Quit
			Set sc=query.Execute(ccr) If $$$ISERR(sc) Do $System.OBJ.DisplayError(sc) Quit
			&html<
				<TABLE border='1'>
					<THEAD>
						<TR>
							<TH NOWRAP align='left'>ID</TH>
							<TH NOWRAP align='left'>Name</TH>
							<TH NOWRAP align='left'>Timestamp</TH>
							<TH NOWRAP align='left'>&nbsp;</TH>
						</TR>
					</THEAD>
			>
			While (query.Next()) {	
				Set cnt=$I(cnt)
				Set lastID=query.Get("ID")
				&html<<TR><TD>>
				Do query.%Print("</TD><TD>")
				&html<</TD><TD><A HREF="#(..SelfLink())#&action=ItemSetLog&id=#(lastID)#">view log</A></TD></TR>>
			}
			&html<</TABLE>>
			If (cnt=0) {
				&html<No ItemSets for CCR '#(ccr)#' in #($namespace)# namespace>
			} ElseIf (cnt=1) {
				Set ISid=lastID
				&html<Only one ItemSet exists for that CCR, displaying log...>
			}
		} 
		If (ISid'="") {
			&html<<H3>ItemSet Log for ID=#(ISid)#</H3>>
			&html<<PRE>>
			Set sc=##class(%Studio.SourceControl.ItemSet).DisplayLog(ISid)
			&html<</PRE>>
		}
		Quit		
	}
}

ClassMethod ItemsetautodownloadDisplay()
{
	&html<<html><head><title>Demo</title></head><body>>
    &html<<TABLE border=1>>
    &html<<THEAD><TR><TH>Name</TH><TH>Size</TH></TH></THEAD>>
    do ##class(%Studio.SourceControl.CCRItemSetTask).GetLogDirName(.dir)
    set rs = ##class(%SQL.Statement).%ExecDirect(,"select * from %Library.File_FileSet(?) order by DateCreated desc",dir)
    while rs.%Next() {
        set oid = ..Encrypt($ListBuild(rs.Name,"%Stream.FileCharacter",""))
        if rs.Type = "D" { Continue }
        &html<<tr><td><a href="%25CSP.StreamServer.cls?STREAMOID=#(oid)#">#(..EscapeHTML(rs.ItemName))#</td>>
        &html<<td>#(..EscapeHTML(rs.Size))#</td></tr>>
    }
    &html<</table>>
    &html<</body></html>>
}

ClassMethod ItemsethistoryDisplay()
{
	&html<<H2>ItemSet History</H2>>
	set sql = "SELECT name, id, ccr, CreateTimestamp, "
	// set sql = "deployed, DeployedTimeStamp,"
	set sql = sql_"ImportTimestamp from %Studio_SourceControl.ItemSet "
	set sql = sql_"WHERE target='client' AND ImportTimeStamp IS NOT NULL ORDER BY ImportTimestamp DESC, id DESC"

	Set cnt=0, query=##class(%ResultSet).%New("%DynamicQuery:SQL")
	Set sc=query.Prepare(sql) If $$$ISERR(sc) Do $System.OBJ.DisplayError(sc) Quit
	Set sc=query.Execute() If $$$ISERR(sc) Do $System.OBJ.DisplayError(sc) Quit

	// Insert the following lines after 'Created At' after Deployed and DeployedTimeStamps are updated on the client
	// <TH NOWRAP align='left'>Deployed</TH>
	// <TH NOWRAP align='left'>Deployed At</TH>


	&html<
		<TABLE border='1'>
			<THEAD>
				<TR>
					<TH NOWRAP align='left'>Name</TH>
					<TH NOWRAP align='left'>ID</TH>
					<TH NOWRAP align='left'>CCR</TH>
					<TH NOWRAP align='left'>Created At</TH>
					<TH NOWRAP align='left'>Imported At</TH>
					<TH NOWRAP align='left'>Log History</TH>
				</TR>
			</THEAD>
	>
	While (query.Next()) {	
		Set cnt=$I(cnt)
		Set lastID=query.Get("ID")
		&html<<TR><TD>>
		Do query.%Print("</TD><TD>")
		&html<</TD><TD><A HREF="#(..SelfLink())#&action=ItemSetLog&id=#(lastID)#">view log</A></TD></TR>>
	}
	&html<</TABLE>>
}

ClassMethod SummaryDisplay()
{
	&html<<H2>CCR Configuration Summary</H2>>
	&html<<PRE>>
	Do Summary^%buildccr
	&html<</PRE>>
}

ClassMethod RefreshDisplay(DisplayForm As %Boolean)
{
	Do ..LoginDisplay(.continue)
	If 'continue {
		Quit
	}
	Set tShowForm='$data(%request.Data("submit"))		//if there was no submit button passed, show the initial form
	If $data(DisplayForm) Set tShowForm=DisplayForm		//if an explicit directive on showing the form was passed, follow that instruction
	&html<<h2>CCR Namespace Refresh</h2><p>>
	If (tShowForm) {
		#; Display input form
		If ('##class(%Studio.SourceControl.ISC).Disconnected()) {
			Set ret=##class(%Studio.SourceControl.ISC).GetCredentials(.user,,.workspace)
		}
		&html<
			<p>	This will refresh the contents of the namespace with the exported contents of the local Perforce workspace on disk </p>
			<p> Source is located in #(^Sources)# </p>
			<p> Click below to proceed: </p>
			<form name="P4Submit" onsubmit="return Refreshing()">
		>
		If '##class(%Studio.SourceControl.ISC).Disconnected() { &html<<div>Sync branch from Perforce <input name='sync' id='sync' value='1' type='checkbox' checked></div>> }
		&html<
				<input type="hidden" name="action" value="Refresh">
				<input type="hidden" name="client" value="#($get(workspace))#">
				<input type="hidden" name="user" value="#($get(user))#">
				<input type="hidden" name="CSPCHD" value="#($Piece(%session.CSPSessionCookie,";"))#" />
				<input type="hidden" name="CSPSHARE" value="1" />
				<div id="refreshing" style="display:none;">Refreshing...</div>
				<input type="submit" name="submit" id="submit" value="Refresh">
			</form>
		
		<script language="javascript">
			var refreshed = false;
			function Refreshing() {
				if(!refreshed) {
					refreshed = true;
					document.getElementById('submit').style.display = 'none';
					document.getElementById('refreshing').style.display = 'block';
					return refreshed;
				}
				
				return false
			}
		</script>
		>
	} ElseIf ('tShowForm) {
		#; Process form submission
		Set client=$get(%request.Data("client",1))
		Set user=$get(%request.Data("user",1))
		Set sync=$data(%request.Data("sync",1))
		&html<
			<H3>Refresh Details:</H3><p>
			<pre>
		>
		Try {
			Set sc=$$$OK
			Set sc=$$RefreshNamespace^%buildccrRefresh(0,sync)
		} Catch err {
			If (err.Name="<NOROUTINE>") {
				Write !,"ERROR: Refresh^%buildccr requires the %buildccrRefresh routine."
				Write !,"       Please install %buildccrRefresh.MAC and try again."
			}
		}
		If $$$ISERR(sc) {
			Write !,"Refresh encountered one or more errors:"
			Write !,..EscapeHTML($system.Status.GetErrorText(sc))
			&html<
				<script language='javascript'>
				document.bgColor='#FFB2B2';	//remove when updating min instance version past 2010
				document.body.style.backgroundColor='#FFB2B2';
				</script>
			>
		}
		&html<
			</pre>
		>
		Quit		
	}
}

/// Runs the Ens.Config.DefaultSettings.%Export method
ClassMethod SystemdefaultsDisplay(DisplayForm As %Boolean)
{
	Do ..LoginDisplay(.continue)
	If 'continue {
		Quit
	}
	
	Set tShowForm='$data(%request.Data("submit"))		//if there was no submit button passed, show the initial form
	If $data(DisplayForm) Set tShowForm=DisplayForm		//if an explicit directive on showing the form was passed, follow that instruction
	&html<<h2>Export System Default Settings</h2><p>>
	If tShowForm {
		#; Display input form
		&html<
			<p>	This will export Ensemble Production default settings to a file.</p>
			<p> Please select a Production below. Click "Export" to proceed:</p>
			<form name="SystemdefaultsSubmit">
		>
		&html<
				<input type="hidden" name="action" value="Systemdefaults">
				<input type="hidden" name="user" value="#($get(user))#">
				<input type="hidden" name="CSPCHD" value="#($Piece(%session.CSPSessionCookie,";"))#" />
				<input type="hidden" name="CSPSHARE" value="1" />
				<select name="production" id="productions" onchange="javascript:verifyExport();">
				<option value="">--Choose Production--</option>
				<option value="All">All Default Settings</option>
				<option value="SystemWide">System Wide Default Settings</option>
		>
		set productionIDs = ##class(%SQL.Statement).%ExecDirect(.tStatement,"SELECT ID FROM Ens_Config.Production")
		While productionIDs.%Next() {
			set production = productionIDs.%GetData(1)
			&html<
			<option value="#(production)#">#(production)#</option>
				>
		}
		&html<
				</select>
				<input type="submit" id = "submit" name="submit" value="Export" disabled="">
			</form>
			<script language='javascript'>
				function verifyExport() {
					if (document.getElementById("productions").getAttribute("value")=="") {
						document.getElementById("submit").setAttribute("disabled","true");
					} else {
						document.getElementById("submit").removeAttribute("disabled")
					}
				}
			</script>
		>
		
	}
	ElseIf ('tShowForm) {
		&html<
			<pre>
		>
		Try {
			Set productionName = $Get(%request.Data("production",1))
			Set sc = ##class(%Studio.SourceControl.ISC).ExportDefaults(productionName, .filename)
			If $$$ISERR(sc) {
				Do $System.OBJ.DisplayError(sc)
			} ElseIf productionName = "All" {
				Write "Exported all edited system default settings to directory "_^Sources_"backup/interop/defaults/"
			} Else {
				Write "Exported "_productionName_" system default settings to "_$TR(filename,"\","/")_"."
			}
		} Catch err {
			Do $System.OBJ.DisplayError(err.AsStatus())
		}
		&html<
			</pre>
		>
	}
	Quit
}

/// Displays a diff between the file passes in the file url parameter and file_".bak" if it exists
ClassMethod DiffDisplay()
{
	If ..DiffEnabled() {
		&html<
		<div class = "frost-card" id = "matCard">
		<script language='javascript'>
			try {
				window.onload = updateInfoPosition;
				window.onresize = updateInfoPosition;
			} catch (error) {
				// Handle Studio case
				document.getElementById('systemInfo').style.top= 110;
			}
		</script>
		<div class = "frost-outer-header" >
		<div class = "frost-inner-header" >
		<H2 class = "frost-card-header" >Quick Diff</H2> 
		</div>
		</div>
		<div class = "frost-card-content" >
		<p>>
		Do ..WriteDiffJS()
		Set abort=0
		If '$data(%request.Data("file",1)) Set abort=1, msg="No item to diff was passed to page"
		Set file=##class(%File).NormalizeFilename($get(%request.Data("file",1)))
		Set filelabel="File"
		Set perforceRoot = $get(^%SYS("SourceRoot",$zutil(5)),$get(^%SYS("SourceRoot"),"C:\Perforce\"))
		If ('abort) {
			Set backupFolder = $get(%request.Data("BackupSource",1))
			If backupFolder'="" {
				// diff against previously backed up source
				Set backupPath = perforceRoot _"BackupSources/" _ backupFolder _ "/"
				Set backupfile = ##class(%File).NormalizeFilename(backupPath _ $piece(file,^Sources,2))
				Set backuplabel="Backup (" _ backupFolder _ ") File"
				If '##class(%File).Exists(backupfile) Set abort=1, msg=backupfile_" does not exist"
				If $zstrip(backupFolder,"*E",,"\/.")'="" Set abort=1, msg=backupFolder_" is not a valid backup folder"
			} else {
				// normal diff against a .bak file
				Set backupfile=##class(%File).NormalizeFilename(file_".bak")
				Set backuplabel="Original File"
				If '##class(%File).Exists(backupfile) Set abort=1, msg=backupfile_" does not exist"
			}
		}
		If ('abort) {
			For filecheck=$ZCVT(file,"L"),$ZCVT(backupfile,"L") {
				Set fileallowed=0
				If $data(^Sources) {
					If filecheck[$ZCVT(^Sources,"L") Set fileallowed=1
				}
				If $data(^%SYS("TempDir")) {
					If filecheck[$ZCVT(^%SYS("TempDir"),"L") Set fileallowed=1
				}
				If $get(backupPath)'="" {
					If filecheck[$ZCVT(backupPath,"L") Set fileallowed=1
				}
				If 'fileallowed Set abort=1, msg=filecheck_" is not accessible for a diff" Quit
			}
		}
		If abort {
			Write "Illegal diff request: "_$get(msg)
		} Else {
			Set original=##class(%FileCharacterStream).%New()
			Set original.Filename=backupfile
			Set new=##class(%FileCharacterStream).%New()
			Set new.Filename=file
			&html<
				#(filelabel)#: #(file)#<BR/>
				#(backuplabel)#: #(backupfile)#<BR/>
		
				<SCRIPT TYPE="text/javascript" LANGUAGE="JavaScript">
				var dmp = new diff_match_patch();
				function launchDiff() {
				  var text1 = document.getElementById('text1').value;
				  var text2 = document.getElementById('text2').value;
				  dmp.Diff_Timeout = parseFloat(document.getElementById('timeout').value);
				  dmp.Diff_EditCost = parseFloat(document.getElementById('editcost').value);

				  var ms_start = (new Date()).getTime();
				  var d = dmp.diff_main(text1, text2);
				  var ms_end = (new Date()).getTime();

				  if (document.getElementById('semantic').checked) {
				    dmp.diff_cleanupSemantic(d);
				  }
				  if (document.getElementById('efficiency').checked) {
				    dmp.diff_cleanupEfficiency(d);
				  }
				  var diffHTML = getDiffHTML(d);
				  
				  var key = 'Key: <ins>added</ins>&nbsp;<del>deleted</del>';
				  adjustDiffOutputHeight();
				  document.getElementById('outputdiv').innerHTML = key + '&nbsp;(diff time: ' + (ms_end - ms_start) / 1000 + 's)' + '<HR><code id="diff_code" style="white-space: pre-wrap;">' + diffHTML + '</code>';
				  initDiffTracking();
				}
				function showDiv(Id, text) {
					var el=document.getElementById(Id);
					if (el.style.display != "none") {
						//items are currently displayed, so hide them
						el.style.display = "none";
						document.getElementById('toggle-'+Id).innerHTML = 'show '+text;
					}
					else {
						//items are currently hidden, so display them
						el.style.display = "";
						document.getElementById('toggle-'+Id).innerHTML = 'hide '+text;
					}
					adjustDiffOutputHeight();
				}
				/// helper function to adjust the height of the diff output so that it fits
				/// inside the current window - the only scrolling should be inside the diff
				function adjustDiffOutputHeight() {
					var outputDiv = document.getElementById('outputdiv');
					var windowHeight = window.innerHeight;
					if (outputDiv && windowHeight) {
						// check if we need to leave room for the "back" link below the output
						var returnLinkHeight = 0;
						var returnLinkPara = document.getElementById('return_link');
						if (returnLinkPara) {
							returnLinkHeight = Math.max(returnLinkPara.offsetHeight,returnLinkPara.clientHeight);
							returnLinkHeight+= 25;
						}
						var outputTop = getElementTop(outputDiv);
						var outputHeight = windowHeight - outputTop - returnLinkHeight - 10;
						outputDiv.style.height = outputHeight + 'px';
					}
				}
				// helper function to get the position of el relative to the top of the window
				function getElementTop(el) {
					var top = 0;
					while (el) {
						top += el.offsetTop;
						el = el.offsetParent;
					}
					return top;
				}
				// Based on the prettyHtml() function in the diff_match_patch library:
				// https://github.com/google/diff-match-patch/blob/a6367d7866833ac037fbdefcdbcbee4def86e326/javascript/diff_match_patch_uncompressed.js
				// Other than slightly different variable names, the following changes were made:
				//	= We don't replace `\n` with `&para;` because we're showing all whitespace in the output
				//	= We ignore diffs that have no content
				//	= We don't use hard-coded styles, but relay on separate CSS
				//  = We add a `pos` attribute to represent the position of the <ins> and <del> elements
				//		(This was present in a previous version of the `prettyHtml()` function)
				//  = We use a slightly different approach for adding the content to the array of HTML text
				function getDiffHTML(diffOutput) {
					var html        = [],
						pos         = 0,
					    pattern_amp = /&/g,
					    pattern_lt  = /</g,
  					    pattern_gt  = />/g;
  					    pattern_nl  = /\n/g;
  					    
  					var ignoreWhitespace = (document.getElementById('whitespace').checked === true);
					
					for (var diffPos = 0; diffPos < diffOutput.length; diffPos++) {
						// Operation (insert, delete, equal)
						var op   = diffOutput[diffPos][0],
						// Text of change
							data = diffOutput[diffPos][1];
						
						var escapedText = data
							.replace(pattern_amp, '&amp;')
							.replace(pattern_lt,  '&lt;')
							.replace(pattern_gt,  '&gt;');
						var isWhitespace = (escapedText.match(/^\s*$/g));
						if (!ignoreWhitespace) {
							// Show newline symbol to make it clear when a newline was added/removed
							escapedText = escapedText.replace(pattern_nl,  '\u23CE\n');
						}
						// Ignore empty text
						if (escapedText !== '') {
							var tag    = '',
								addPos = true;
							if (isWhitespace && ignoreWhitespace) {
								// Coerce back to DIFF_EQUAL.
								op = DIFF_EQUAL;
							}
						    switch (op) {
						      case DIFF_INSERT:
						        tag = 'ins';
						        break;
						      case DIFF_DELETE:
						        tag = 'del';
						        break;
						      case DIFF_EQUAL:
						        tag    = 'span';
						        addPos = false;
						        break;
						    }
						    var posAttribute = (addPos ? ' pos="' + pos + '"' : '');
						    html.push('<' + tag + posAttribute + '>' + escapedText + '</' + tag + '>');
						    pos = pos + escapedText.length;
						}
					}
					return html.join('');
				}
				/// initialize the variables that keep track of where we are in the diff
				/// all of this data is stored in window.diffTracking
				function initDiffTracking() {
					window.diffTracking = {
						elements: buildElementMap(),
						currPos: -1,
						currEl: null,
						outputTop: getElementTop(document.getElementById('outputdiv'))
					};
					var diffNav = document.getElementById('diff_nav');
					if (diffNav) {
						diffNav.style.display = '';
					}
					nextDiff();
				}
				/// Constructor for a helper object to help iterate over the INS and DEL elements
				/// found in the diff output. The main reason for the abstraction is to keep only one version
				/// of the next() function that finds the next element and extracts the numeric value
				/// stored in the title attribute of the underlying diff element. (This looks like the character
				/// position of the diff in the file, but it is sequential even if it is not.)
				function elData(nodeList) {
					this.nodeList = (nodeList ? nodeList : null);
					this.atEnd = !this.nodeList;
					this.pos = -1;
					this.index = -1;
					this.el = null;
					/// Function to shift to the next element and determine what its numeric index is.
					/// The index is needed for sorting and working out when an insertion and deletion occur
					/// at the "same" point in the document.
					this.next = function() {
						if (this.atEnd || (!this.nodeList)) return false;
						var newIndex = -1;
						if (this.pos == this.nodeList.length) {
							this.atEnd = true;
						}
						else {
							this.pos++;
							this.el = this.nodeList.item(this.pos);
							if (this.el) {
								var posAttribute = this.el.getAttribute('pos');
								if (posAttribute) {
									var posValue = parseInt(posAttribute,10);
									if (!isNaN(posValue)) {
										newIndex = posValue;
									}
								}
							}
							else {
								this.atEnd = true;
							}
						}
						this.index = newIndex;
						return this.atEnd;
					};
				}
				/// Function to identify all the insertions (INS elements) and deletions (DEL elements)
				/// in the diff output, and then build a sequential map of all the diffs.
				/// The sequencing uses the title attribute to sequence the two kinds of elements,
				/// and does a special grouping when a delete and an insert share the same index as we
				/// want to show those as a single diff when possible.
				/// Note that the "map" returned from this function includes references to the actual
				/// DOM elements so that we can rapidly change the element's style and shift focus to it.
				function buildElementMap() {
					var map = [];
					try {
						var codeEl = document.getElementById('diff_code');
						if (codeEl) {
							var insData = new elData(codeEl.getElementsByTagName('ins'));
							var delData = new elData(codeEl.getElementsByTagName('del'));
							insData.next();
							delData.next();
							while (insData.el || delData.el) {
								if (insData.index > -1) {
									if ((insData.index < delData.index) || (delData.index == -1)) {
										map.push(insData.el);
										insData.next();
									}
									else if (delData.index == insData.index) {
										delData.el._pairEl = insData.el;
										map.push(delData.el);
										delData.next();
										insData.next();
									}
									else { // (delData.index < insData.index)
										map.push(delData.el);
										delData.next();
									}
								}
								else if ((delData.index > -1) && ((delData.index < insData.index) || (insData.index == -1))) {
									map.push(delData.el);
									delData.next();
								}
								else {
									alert('Failed to process diff list');
									map = [];
									break;
								}
							}
						}
					} catch (ex) {
						alert('Exception in buildElementMap: ' + (window.JSON ? JSON.stringify(ex) : ex));
					}
					return map;
				}
				/// Function to update the next and previous diff buttons based on the data in window.diffTracking
				function updateDiffButtons() {
					var diffTracking = window.diffTracking;
					if (!diffTracking) return;

					var nextButton = document.getElementById('diff_nav_next');
					if (nextButton) {
						nextButton.disabled = (!diffTracking.elements) || (diffTracking.currPos >= (diffTracking.elements.length - 1)) || (diffTracking.currPos < 0);
						if (nextButton.disabled) {
							nextButton.classList.remove('frost-secondary-button'); 
    						nextButton.classList.add('frost-secondary-button-disabled');
						} else {
							nextButton.classList.remove('frost-secondary-button-disabled'); 
    						nextButton.classList.add('frost-secondary-button');
						}
					}
					var prevButton = document.getElementById('diff_nav_prev');
					if (prevButton) {
						prevButton.disabled = (!diffTracking.elements) || (diffTracking.currPos <= 0)
						if (prevButton.disabled) {
							prevButton.classList.remove('frost-secondary-button'); 
    						prevButton.classList.add('frost-secondary-button-disabled');
						} else {
							prevButton.classList.remove('frost-secondary-button-disabled'); 
    						prevButton.classList.add('frost-secondary-button');
						}
					}
					var diffPos = document.getElementById('diff_pos');
					if (diffPos) {
						var posText = 'No diffs';
						if (diffTracking.elements && (diffTracking.elements.length > 0)) {
							posText = '' + (diffTracking.currPos + 1) + ' of ' + diffTracking.elements.length;
						}
						diffPos.innerHTML = posText;
					}
				}
				/// Function to "jump" to the next or previous diff.
				/// In addition to calling updatNodeStyle(), it also shifts the scroll position
				/// of the page to bring the diff into focus.
				function shiftDiff(back) {
					var diffTracking = window.diffTracking;
					if ((!diffTracking) || (!diffTracking.elements)) return;

					var shift = (back ? -1 : 1);
					var newPos = diffTracking.currPos + shift;
					if (newPos < 0) {
						newPos = 0;
					}
					else if (newPos >= diffTracking.elements.length) {
						newPos = diffTracking.elements.length - 1;
					}
					if (diffTracking.currEl) {
						updateNodeStyle(diffTracking.currEl,false);
						if (diffTracking.currEl._pairEl) {
							updateNodeStyle(diffTracking.currEl._pairEl,false);
						}
					}
					diffTracking.currPos = newPos;
					updateDiffButtons();

					var outputDiv = document.getElementById('outputdiv');
					var newEl = diffTracking.elements[newPos];
					diffTracking.currEl = newEl;
					if (newEl) {
						updateNodeStyle(newEl,true);
						if (newEl._pairEl) updateNodeStyle(newEl._pairEl,true);
						if (outputDiv) {
							// leave a 40px buffer so you can see the code before and after the diff
							var newScrollTop = newEl.offsetTop - diffTracking.outputTop - 40;
							outputDiv.scrollTop = (newScrollTop < 0 ? 0 : newScrollTop);
						}
					}
				}
				/// Helper function to update node's style based on whether it should be highlighted
				/// or simply shown as a diff that isn't in focus.
				function updateNodeStyle(node,active) {
					if ((!node) || (!node.nodeName)) {
						return;
					}
					flagNodeAsActive(node,active);
					if (node._pairEl) {
						flagNodeAsActive(node._pairEl,active);
					}
				}
				function flagNodeAsActive(node,active) {
					if (active) {
						node.setAttribute('active',1);
					}
					else {
						node.removeAttribute('active');
					}
				}
				function nextDiff() {
					shiftDiff(false);
				}
				function prevDiff() {
					shiftDiff(true);
				}
				</SCRIPT>

				<FORM action="#" onsubmit="return false">
				<TABLE WIDTH="100%"  style = "table-layout: fixed;">
					<TR style = "height: 15px;">  </TR> 
					<TR>
						<TD colspan='2'>
							<A HREF='javascript:showDiv("files","files");' id="toggle-files">show files</A>
						</TD>
					</TR>
					<TR id="files" style='display: none' title='display of files to be diffed'>
						<TD WIDTH="50%">
							<H4>#(filelabel)#:</H4>
							<div class = "frost-filename"> #(file)# </div> <BR>
							<TEXTAREA ID="text2"class = "frost-filename" ROWS=30>>
			While 'new.AtEnd {
				Write ..EscapeHTML(new.ReadLine()),!
			}
			&html<</TEXTAREA>
						</TD>
						<TD WIDTH="50%">
							<H4>#(backuplabel)#:</H4>
							<div class = "frost-filename"> #(backupfile)# </div> <BR>
							<TEXTAREA ID="text1" class = "frost-filename" ROWS=30>>
			While 'original.AtEnd {
				Write ..EscapeHTML(original.ReadLine()),!
			}
			&html<</TEXTAREA>
						</TD>
					</TR>
					<TR>
						<TD colspan='2'>
							<A HREF='javascript:showDiv("controls","additional options");' id="toggle-controls">show additional options</A>
						</TD>
					</TR>
					<TR id="controls" style='display: none' title='additional diff controls'>
						<TD colspan='2'>
							<div style = "height: 10px;"> </div>
							<fieldset class = "frost-fieldset">
							<H4 style = "margin-top: 0px;">Diff settings:</H4>
							<P><INPUT TYPE="checkbox" ID="whitespace" /><LABEL FOR="whitespace">Ignore Whitespace</LABEL></P>
							<H4>Diff timeout:</H4>
							<P><INPUT TYPE="text" SIZE=3 MAXLENGTH=5 VALUE="0" ID="timeout"> seconds<BR>
							If the mapping phase of the diff computation takes longer than this, then the computation
							is truncated and the best solution to date is returned.  While guaranteed to be correct,
							it may not be optimal.  A timeout of '0' allows for unlimited computation.</P>
							<H4>Post-diff cleanup:</H4>
							<DL>
							<DT><INPUT TYPE="radio" NAME="cleanup" ID="semantic">
							<LABEL FOR="semantic">Semantic Cleanup</LABEL></DT>
							<DD>Increase human readability by factoring out commonalities which are likely to be
							coincidental.</DD>
							<DT><INPUT TYPE="radio" NAME="cleanup" ID="efficiency" CHECKED>
							<LABEL FOR="efficiency">Efficiency Cleanup</LABEL>,
							edit cost: <INPUT TYPE="text" SIZE=3 MAXLENGTH=5 VALUE="4" ID="editcost">
							<DD>Increase computational efficiency by factoring out short commonalities which are
							not worth the overhead.  The larger the edit cost, the more agressive the cleanup.</DD>
							<DT><INPUT TYPE="radio" NAME="cleanup" ID="raw">
							<LABEL FOR="raw">No Cleanup</LABEL></DT>
							<DD>Raw output.</DD>
							</DL>
							<button class = "frost-primary-button" onclick="launchDiff();">Recompute Diff</button>
							</fieldset>
						</TD>
					</TR>
					<TR style = "height: 15px;"> </TR> 
				</TABLE>
				<P><span id="diff_nav" style="display: none; padding-left: 20px;">
						<button class = "frost-secondary-button" id="diff_nav_prev" onclick="prevDiff();" accesskey="p"><u>P</u>revious Diff</button>
						&nbsp;&nbsp;
						<button class = "frost-secondary-button" id="diff_nav_next" onclick="nextDiff();" accesskey="n"><u>N</u>ext Diff</button>
						&nbsp;&nbsp;
					<span id="diff_pos">&nbsp;</span></span></P>
				</FORM>
				<DIV ID="outputdiv" style="overflow-y:auto;"></DIV>
			>
		}
		If $data(%request.Data("return",1)) {
			&html<<p id="return_link"><a href='#(..SelfLink())#&action=#($get(%request.Data("return",1)))#'>back</a>>
		}
		If 'abort {
		&html<
			<SCRIPT TYPE="text/javascript">
				launchDiff();
			</SCRIPT>
			</div>
			</div>
		>
		}
	} Else {
		&html<
		<div class = "frost-card" id = "matCard">
		<script language='javascript'>
			try {
				window.onload = updateInfoPosition;
				window.onresize = updateInfoPosition;
			} catch (error) {
				// Handle Studio case
				document.getElementById('systemInfo').style.top= 110;
			}
		</script>
		<div class = "frost-outer-header" >
		<div class = "frost-inner-header" >
		<H2 class = "frost-card-header" >Quick Diff</H2> 
		</div>
		</div>
		<div class = "frost-card-content" >
		<br> Diff function is disabled </div> </div>>
	}
}

/// Called from UI Bundle page to validate whether an ItemSet can be uploaded for a given CCR
/// Updates elements on the page according to the status
ClassMethod ValidateCCRUpload(pRID = "")
{
	Set tOrg = $$Org^%buildccr
	Set tSys = $$Sys^%buildccr
	Set sc=##class(%Studio.SourceControl.ItemSet).WSCanUpload(pRID,tOrg,tSys,.tReason)
	If $$$ISOK(sc) 
	{
		//show the check mark as confirmed
		Set symbol="&#10004;"	//'check' mark
		&js<document.getElementById('ccrCheck').innerHTML='#(symbol)#';>
	} Else {
		//show validation failed and why
		Set symbol="&#10008;"	//'x' mark
		&js<
			document.getElementById('ccrCheck').innerHTML='#(symbol)#';
			document.getElementById('ccrCheckReason').style.display='block';
			document.getElementById('canUploadStatus').innerHTML=#(..QuoteJS(..EscapeHTML($system.Status.GetErrorText(sc))))#;
			document.getElementById('submitBtn').disabled=true;
		>		
	}
}

/// Retrieve details of the requested CCR and update the UI with the details
ClassMethod RetrieveCCRDetails(pRID = "", pToken = "")
{
	Kill rs
	
	// Not valid to request details without an RID, prevents unnecessary calls to CCR server
	If pRID = "" {
		Quit
	}
	
	Set sc = ##class(%Studio.SourceControl.ItemSet).WSDetails(pRID,pToken,.rs)
	Set tokenSymbol = ""
	If (($$$ISOK(sc))&&(rs.Next())) 
	{
		//web service succeeded so the token is validated
		Set tokenSymbol = "&#10004;"	//'check' mark
		//web service returned a result-set so the CCR is valid; show the ccr details
		
		Set siteCode = rs.Data("SiteCode")
		Set systemCode = rs.Data("SystemCode")
		Set state = rs.Data("CurrentState")
		Set isValid = ##class(%Studio.SourceControl.ItemSet).ValidateCCR(siteCode, systemCode, state, .reasons)
		
		&js<
			document.getElementById('ccrCCRDetails').style.display='block';
			document.getElementById('detailsRID').innerHTML='<A href="#($$CCRServer^%buildccr)#/ccr/view.csp?RID=#(..EscapeHTML(rs.Data("RID")))#" target="_blank">#(..EscapeHTML(rs.Data("RID")))#</A>';
			document.getElementById('detailsTitle').innerHTML=#(..QuoteJS(..EscapeHTML(rs.Data("Title"))))#;
			document.getElementById('detailsUsername').innerHTML=#(..QuoteJS(..EscapeHTML(rs.Data("Username"))))#;
			document.getElementById('detailsCurrentState').innerHTML=#(..QuoteJS(..EscapeHTML(state)))#;
			document.getElementById('detailsCurrentState').style.color='#($Select(reasons [ "State":"red", 1: "black"))#';
			document.getElementById('detailsSystemCode').innerHTML=#(..QuoteJS(..EscapeHTML(systemCode)))#;
			document.getElementById('detailsSystemCode').style.color='#($Select(reasons [ "System":"red", 1:"black"))#';
			document.getElementById('detailsSiteCode').innerHTML=#(..QuoteJS(..EscapeHTML(siteCode)))#;
			document.getElementById('detailsSiteCode').style.color='#($Select(reasons [ "Site":"red", 1:"black"))#';
		>
	} ElseIf ($system.Status.GetErrorText(sc) [ "Invalid Token") {
		Set tokenSymbol="&#10008;"	//'x' mark
		&js<document.getElementById('submitBtn').disabled=true;>	
	} Else {
		//take no action	
	}
	&js<document.getElementById('tokenCheck').innerHTML='#(tokenSymbol)#';>
}

/// Returns boolean value indicated whether or not the diff UI can be displayed
/// <P>Set ^SYS("SourceControl","UIConfig","DisableDiff")=1 to disable diff for a specific namespace
/// <P>Set ^%SYS("SourceControl","UIConfig","DisableDiff")=1 to disable diff for the entire instance
ClassMethod DiffEnabled() As %Boolean [ CodeMode = expression ]
{
'($G(^SYS("SourceControl","UIConfig","DisableDiff"))||$G(^%SYS("SourceControl","UIConfig","DisableDiff")))
}

ClassMethod ConvertStreamToHTML(pStream) As %Stream.GlobalCharacter
{
 	Set newStream=##class(%Stream.GlobalCharacter).%New()
 	If '$isobject(pStream) quit newStream
 	Do pStream.Rewind()
 	While ('pStream.AtEnd) {
 		Set chunk=pStream.Read(500)
 		Set chunk=..EscapeHTML(chunk)
 		//make errors obvious
 		Set chunk=$REPLACE(chunk,"ERROR","<STRONG><font color='red'>ERROR</font></STRONG>")
 	/*	//convert $C(10) to "<BR/>"
 		s chunk=$REPLACE(chunk,$C(10),"<BR/>")
 		//convert " " to "&nbsp;"
 		s chunk=$REPLACE(chunk," ","&nbsp;")*/
 		//write it into the new stream
 		Do newStream.Write(chunk)
 	}
 	Do newStream.Rewind()
 	Quit newStream
}

/// Link to this page
ClassMethod SelfLink() [ CodeMode = expression ]
{
..EscapeURL(..%ClassName(1)_".cls")_"?CSPSHARE=1&CSPCHD="_$Piece(%session.CSPSessionCookie,";")
}

/// This method displays validation logic for the included diff_match_patch diff JS
/// To use, you must put the following into <Install Directory>/CSP/sys:
/// 	//custom_ccrs/_common/config/internal/testing/manual_tests/UI.diff_match_patch_test.html
/// 	//custom_ccrs/_common/config/internal/testing/manual_tests/diff_match_patch_test.js
/// NOTE: The above files are not to be distributed in product; they are only for manually validating the diff functionality
/// Access this test via http://localhost:<port>/csp/sys/%25Studio.SourceControl.UI.cls?action=validatediff
ClassMethod ValidateDiffDisplay() [ Internal ]
{
	&html<<H2>Quick Diff Validation</H2>
		(If this page is blank, then UI.diff_match_patch_test.html and diff_match_patch_test.js are missing from the CSP application's root directory)
	>
	Do ..WriteDiffJS()
	Do ..Include("UI.diff_match_patch_test.html")
}

/// Pages inheriting from %CSP.Page don't have a %GetParameter() method until 2010.2.  This method allows access to the parameter values in the class from  outside of the class
ClassMethod GetParameter(Parameter) As %String [ CodeMode = objectgenerator ]
{
	Set ver=$$$CacheVersionMajor_"."_$$$CacheVersionMinor
	If (ver<2010.1) {
 		Do %code.WriteLine(" $$$comMemberKeyGetLvar(ParmValue,..%ClassName(1),$$$cCLASSparameter,Parameter,$$$cPARAMdefault)")
 		Do %code.WriteLine(" Quit ParmValue")
	} ElseIf (ver=2010.1) { 
 		Do %code.WriteLine(" Quit $zobjparam(Parameter)")
	} Else {
		Do %code.WriteLine(" Quit $Parameter(,Parameter)")
	}
 	Quit $$$OK
}

/// CSP Applications allowed to access this UI.
/// <p>To add web applications to the return list, set <code>^%SYS("SourceControl","AllowedApps")=$lb(app1,app2,...)</code>.
/// NOTE: app1, app2, etc must have a trailing '/', e.g. <code>^%SYS("SourceControl","AllowedApps")=$lb("/csp/users/")</code>
ClassMethod AllowedApps() As %String [ CodeMode = expression ]
{
$listbuild("/csp/sys/","/isc/studio/templates/")_$select($listvalid($get(^%SYS("SourceControl","AllowedApps"))):$get(^%SYS("SourceControl","AllowedApps")),1:"")
}

/// Accepts the password for the current Perforce user (defined by $USERNAME) and validates password by attempting to log into Perforce and obtain a IP-bound ticket<br/>
/// If login is successful, ticket is stored in the session to be reused on later calls to Perforce<br/>
/// If <var>Password</var> is not defined, then the locally cached ticket will be cleared
ClassMethod PerforceLogin(Password) As %Status
{
	Set sc=$$$OK
	If ('$data(Password)) {
		Kill %session.Data("stP")
		Kill %stP
		Quit sc		
	}
	Set file=##class(%FileCharacterStream).%New()
	$$$QuitOnError(file.WriteLine(Password))
	$$$QuitOnError(file.%Save())
	Set file.RemoveOnClose = 1
	Set %stP=$System.Encryption.Base64Encode(Password)
	Kill args Set args($i(args))="login",args($i(args))="-p"
	Set sc=##class(%Studio.SourceControl.ISC).SecureRunCmd("p4",.args,.out,0,,file.Filename)
	/* 
		expected output of 'out' for correct login (sc will be an error for incorrect password or other error):
			out=2
			out(1)="Enter password: "
			out(2)="1F312B20CBC503C72DDA242EB267D2AE"
			
		NOTE - if Perforce ever changes this format the parsing logic below will break (I could not use the p4 -s flag because errors didn't get sent to errout so sc didn't contain any errors
	*/
	If ($$$ISOK(sc))&&($get(out)>1) {
		Set i="", i=$order(out(i),1,line)
		While (i'="")&&(line'["Enter password:"){
			Set i=$order(out(i),1,line)
		}
		Set i=$order(out(i),1,line)
		Set token=line
		If '##class(%Studio.SourceControl.ISC).DefaultCredentialsDefined() {
			// To avoid issues, only store per-user ticket if no default credentials are defined.
			Do ##class(%Studio.SourceControl.ISC).StorePerforceTicket(token)
		}
		Set %session.Data("stP")=$System.Encryption.Base64Encode(token)
		Set %stP=%session.Data("stP")
	} Else {
		Kill %session.Data("stP")
		Kill %stP
	}
	Quit sc
}

/// Returns true if the user has a valid Perforce ticket in the CSP session, otherwise returns false.<br/>
/// Also obtains and validate an existing ticket. <br />
/// This also inializes the process ticket variable, so this must be called whenever a server-side method requiring Perforce access is invoked
ClassMethod PerforceLoggedIn() As %Boolean
{
	If '##class(%Studio.SourceControl.ISC).DefaultCredentialsDefined() {
		// Check for Perforce ticket. (Will clear ticket if not defined.)
		Do ##class(%Studio.SourceControl.ISC).ValidatePerforceTicket()
		Do ##class(%Studio.SourceControl.ISC).GetCredentials(,.ticket)
		Set %session.Data("stP") = $System.Encryption.Base64Encode(ticket)
	}
	Set %stP=$get(%session.Data("stP"))
	Quit ($length($get(%stP))>0)
}

/// Ensure that this page is only accessible through approved CSP Applications
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	Set action=$ZCVT($get(%request.Data("action",1)),"L")
	If (action="logout") { // User logging out
		Set %session.EndSession = 1
		Set %response.Redirect = ..SelfLink()
		Quit $$$OK
	}
	Set ret=0
	If ($LF(..AllowedApps(),%request.AppMatch)) || ($LF(..AllowedApps(), %request.Application)) {
		//Allow access if the request is coming through one of the allowed CSP applications
		Set ret=1
	} ElseIf ((action="diff")&&(..DiffEnabled())) {
		//Allow access if the request is for the the 'diff' functionality, diff is enabled for this namespace
		Set ret=1
	} Else {
		Set %response.Redirect="/csp/sys/"_..EscapeURL(%request.PageName)
		Set ret=0
	}
	Set %response.Timeout = 300 // increase cspgateway timeout for long ItemSet loads 
	Set %session.UseSessionCookie = 1 // set UseSessionCookie for environments without BES224
	If (%request.Secure = 1) {
		Try {
			If (%request.UserAgent [ " Code/") {
				// Workaround for VSCode webview
				Set %session.SessionScope = 0 // none; allowed because...
				Set %session.SecureSessionCookie = 1 // secure flag on session cookie - will be ignored over http, but that's OK because we already have it
			}
		} Catch e {
		}
	}
	Quit ret
}

/// Handles all compile-time logic for this class
ClassMethod OnToolsCompile() [ CodeMode = objectgenerator, Internal ]
{
 	For i = 1:1:%class.Parameters.Count() {
        If %class.Parameters.GetAt(i).Name = "SrcVer" Set valSrcVer = %class.Parameters.GetAt(i).Default
        If %class.Parameters.GetAt(i).Name = "Version" Set indexVersion=i
    }
    If $D(indexVersion)&&($G(valSrcVer)["//custom_ccrs/_common/config/") {
	    Set %class.Parameters.GetAt(indexVersion).Default = $P($G(valSrcVer),"#",2)+1
	    Do %class.Parameters.GetAt(indexVersion).%Save()
    }
    Quit $$$OK
}

/// Returns value the Major.Minor version for this instance, so it can be used in comparison code which makes sure certain features are used in appropriate versions
ClassMethod InstanceVersion() As %Numeric [ CodeMode = expression ]
{
$P($SYSTEM.Version.GetNumber(),".",1,2)
}

/// //////////////////////////////////////////////////////////////////////////////////////////////////////////
/// diff-match-patch 
/// -------------------------------------------
/// Obtained from: https://github.com/google/diff-match-patch at commit a6367d7866833ac037fbdefcdbcbee4def86e326
/// Used under Apache License 2.0 (https://github.com/google/diff-match-patch/blob/0ae308daa77aeddb089cd6b7b0a443fca026266e/LICENSE)
/// -------------------------------------------
/// The Javascript code below is from https://github.com/google/diff-match-patch/blob/a6367d7866833ac037fbdefcdbcbee4def86e326/javascript/diff_match_patch.js
/// //////////////////////////////////////////////////////////////////////////////////////////////////////////
ClassMethod WriteDiffJS() [ Internal ]
{
	Write "<script language='javascript'>",!
	Write "var diff_match_patch=function(){this.Diff_Timeout=1;this.Diff_EditCost=4;this.Match_Threshold=.5;this.Match_Distance=1E3;this.Patch_DeleteThreshold=.5;this.Patch_Margin=4;this.Match_MaxBits=32},DIFF_DELETE=-1,DIFF_INSERT=1,DIFF_EQUAL=0;diff_match_patch.Diff=function(a,b){this[0]=a;this[1]=b};diff_match_patch.Diff.prototype.length=2;diff_match_patch.Diff.prototype.toString=function(){return this[0]+"",""+this[1]};",!
	Write "diff_match_patch.prototype.diff_main=function(a,b,c,d){""undefined""==typeof d&&(d=0>=this.Diff_Timeout?Number.MAX_VALUE:(new Date).getTime()+1E3*this.Diff_Timeout);if(null==a||null==b)throw Error(""Null input. (diff_main)"");if(a==b)return a?[new diff_match_patch.Diff(DIFF_EQUAL,a)]:[];""undefined""==typeof c&&(c=!0);var e=c,f=this.diff_commonPrefix(a,b);c=a.substring(0,f);a=a.substring(f);b=b.substring(f);f=this.diff_commonSuffix(a,b);var g=a.substring(a.length-f);a=a.substring(0,a.length-f);b=b.substring(0,",!
	Write "b.length-f);a=this.diff_compute_(a,b,e,d);c&&a.unshift(new diff_match_patch.Diff(DIFF_EQUAL,c));g&&a.push(new diff_match_patch.Diff(DIFF_EQUAL,g));this.diff_cleanupMerge(a);return a};",!
	Write "diff_match_patch.prototype.diff_compute_=function(a,b,c,d){if(!a)return[new diff_match_patch.Diff(DIFF_INSERT,b)];if(!b)return[new diff_match_patch.Diff(DIFF_DELETE,a)];var e=a.length>b.length?a:b,f=a.length>b.length?b:a,g=e.indexOf(f);return-1!=g?(c=[new diff_match_patch.Diff(DIFF_INSERT,e.substring(0,g)),new diff_match_patch.Diff(DIFF_EQUAL,f),new diff_match_patch.Diff(DIFF_INSERT,e.substring(g+f.length))],a.length>b.length&&(c[0][0]=c[2][0]=DIFF_DELETE),c):1==f.length?[new diff_match_patch.Diff(DIFF_DELETE,",!
	Write "a),new diff_match_patch.Diff(DIFF_INSERT,b)]:(e=this.diff_halfMatch_(a,b))?(b=e[1],f=e[3],a=e[4],e=this.diff_main(e[0],e[2],c,d),c=this.diff_main(b,f,c,d),e.concat([new diff_match_patch.Diff(DIFF_EQUAL,a)],c)):c&&100<a.length&&100<b.length?this.diff_lineMode_(a,b,d):this.diff_bisect_(a,b,d)};",!
	Write "diff_match_patch.prototype.diff_lineMode_=function(a,b,c){var d=this.diff_linesToChars_(a,b);a=d.chars1;b=d.chars2;d=d.lineArray;a=this.diff_main(a,b,!1,c);this.diff_charsToLines_(a,d);this.diff_cleanupSemantic(a);a.push(new diff_match_patch.Diff(DIFF_EQUAL,""""));for(var e=d=b=0,f="""",g="""";b<a.length;){switch(a[b][0]){case DIFF_INSERT:e++;g+=a[b][1];break;case DIFF_DELETE:d++;f+=a[b][1];break;case DIFF_EQUAL:if(1<=d&&1<=e){a.splice(b-d-e,d+e);b=b-d-e;d=this.diff_main(f,g,!1,c);for(e=d.length-1;0<=e;e--)a.splice(b,",!
	Write "0,d[e]);b+=d.length}d=e=0;g=f=""""}b++}a.pop();return a};",!
	Write "diff_match_patch.prototype.diff_bisect_=function(a,b,c){for(var d=a.length,e=b.length,f=Math.ceil((d+e)/2),g=2*f,h=Array(g),l=Array(g),k=0;k<g;k++)h[k]=-1,l[k]=-1;h[f+1]=0;l[f+1]=0;k=d-e;for(var m=0!=k%2,p=0,x=0,w=0,q=0,t=0;t<f&&!((new Date).getTime()>c);t++){for(var v=-t+p;v<=t-x;v+=2){var n=f+v;var r=v==-t||v!=t&&h[n-1]<h[n+1]?h[n+1]:h[n-1]+1;for(var y=r-v;r<d&&y<e&&a.charAt(r)==b.charAt(y);)r++,y++;h[n]=r;if(r>d)x+=2;else if(y>e)p+=2;else if(m&&(n=f+k-v,0<=n&&n<g&&-1!=l[n])){var u=d-l[n];if(r>=",!
	Write "u)return this.diff_bisectSplit_(a,b,r,y,c)}}for(v=-t+w;v<=t-q;v+=2){n=f+v;u=v==-t||v!=t&&l[n-1]<l[n+1]?l[n+1]:l[n-1]+1;for(r=u-v;u<d&&r<e&&a.charAt(d-u-1)==b.charAt(e-r-1);)u++,r++;l[n]=u;if(u>d)q+=2;else if(r>e)w+=2;else if(!m&&(n=f+k-v,0<=n&&n<g&&-1!=h[n]&&(r=h[n],y=f+r-n,u=d-u,r>=u)))return this.diff_bisectSplit_(a,b,r,y,c)}}return[new diff_match_patch.Diff(DIFF_DELETE,a),new diff_match_patch.Diff(DIFF_INSERT,b)]};",!
	Write "diff_match_patch.prototype.diff_bisectSplit_=function(a,b,c,d,e){var f=a.substring(0,c),g=b.substring(0,d);a=a.substring(c);b=b.substring(d);f=this.diff_main(f,g,!1,e);e=this.diff_main(a,b,!1,e);return f.concat(e)};",!
	Write "diff_match_patch.prototype.diff_linesToChars_=function(a,b){function c(a){for(var b="""",c=0,g=-1,h=d.length;g<a.length-1;){g=a.indexOf(""\n"",c);-1==g&&(g=a.length-1);var l=a.substring(c,g+1);(e.hasOwnProperty?e.hasOwnProperty(l):void 0!==e[l])?b+=String.fromCharCode(e[l]):(h==f&&(l=a.substring(c),g=a.length),b+=String.fromCharCode(h),e[l]=h,d[h++]=l);c=g+1}return b}var d=[],e={};d[0]="""";var f=4E4,g=c(a);f=65535;var h=c(b);return{chars1:g,chars2:h,lineArray:d}};",!
	Write "diff_match_patch.prototype.diff_charsToLines_=function(a,b){for(var c=0;c<a.length;c++){for(var d=a[c][1],e=[],f=0;f<d.length;f++)e[f]=b[d.charCodeAt(f)];a[c][1]=e.join("""")}};diff_match_patch.prototype.diff_commonPrefix=function(a,b){if(!a||!b||a.charAt(0)!=b.charAt(0))return 0;for(var c=0,d=Math.min(a.length,b.length),e=d,f=0;c<e;)a.substring(f,e)==b.substring(f,e)?f=c=e:d=e,e=Math.floor((d-c)/2+c);return e};",!
	Write "diff_match_patch.prototype.diff_commonSuffix=function(a,b){if(!a||!b||a.charAt(a.length-1)!=b.charAt(b.length-1))return 0;for(var c=0,d=Math.min(a.length,b.length),e=d,f=0;c<e;)a.substring(a.length-e,a.length-f)==b.substring(b.length-e,b.length-f)?f=c=e:d=e,e=Math.floor((d-c)/2+c);return e};",!
	Write "diff_match_patch.prototype.diff_commonOverlap_=function(a,b){var c=a.length,d=b.length;if(0==c||0==d)return 0;c>d?a=a.substring(c-d):c<d&&(b=b.substring(0,c));c=Math.min(c,d);if(a==b)return c;d=0;for(var e=1;;){var f=a.substring(c-e);f=b.indexOf(f);if(-1==f)return d;e+=f;if(0==f||a.substring(c-e)==b.substring(0,e))d=e,e++}};",!
	Write "diff_match_patch.prototype.diff_halfMatch_=function(a,b){function c(a,b,c){for(var d=a.substring(c,c+Math.floor(a.length/4)),e=-1,g="""",h,k,l,m;-1!=(e=b.indexOf(d,e+1));){var p=f.diff_commonPrefix(a.substring(c),b.substring(e)),u=f.diff_commonSuffix(a.substring(0,c),b.substring(0,e));g.length<u+p&&(g=b.substring(e-u,e)+b.substring(e,e+p),h=a.substring(0,c-u),k=a.substring(c+p),l=b.substring(0,e-u),m=b.substring(e+p))}return 2*g.length>=a.length?[h,k,l,m,g]:null}if(0>=this.Diff_Timeout)return null;",!
	Write "var d=a.length>b.length?a:b,e=a.length>b.length?b:a;if(4>d.length||2*e.length<d.length)return null;var f=this,g=c(d,e,Math.ceil(d.length/4));d=c(d,e,Math.ceil(d.length/2));if(g||d)g=d?g?g[4].length>d[4].length?g:d:d:g;else return null;if(a.length>b.length){d=g[0];e=g[1];var h=g[2];var l=g[3]}else h=g[0],l=g[1],d=g[2],e=g[3];return[d,e,h,l,g[4]]};",!
	Write "diff_match_patch.prototype.diff_cleanupSemantic=function(a){for(var b=!1,c=[],d=0,e=null,f=0,g=0,h=0,l=0,k=0;f<a.length;)a[f][0]==DIFF_EQUAL?(c[d++]=f,g=l,h=k,k=l=0,e=a[f][1]):(a[f][0]==DIFF_INSERT?l+=a[f][1].length:k+=a[f][1].length,e&&e.length<=Math.max(g,h)&&e.length<=Math.max(l,k)&&(a.splice(c[d-1],0,new diff_match_patch.Diff(DIFF_DELETE,e)),a[c[d-1]+1][0]=DIFF_INSERT,d--,d--,f=0<d?c[d-1]:-1,k=l=h=g=0,e=null,b=!0)),f++;b&&this.diff_cleanupMerge(a);this.diff_cleanupSemanticLossless(a);for(f=1;f<",!
	Write "a.length;){if(a[f-1][0]==DIFF_DELETE&&a[f][0]==DIFF_INSERT){b=a[f-1][1];c=a[f][1];d=this.diff_commonOverlap_(b,c);e=this.diff_commonOverlap_(c,b);if(d>=e){if(d>=b.length/2||d>=c.length/2)a.splice(f,0,new diff_match_patch.Diff(DIFF_EQUAL,c.substring(0,d))),a[f-1][1]=b.substring(0,b.length-d),a[f+1][1]=c.substring(d),f++}else if(e>=b.length/2||e>=c.length/2)a.splice(f,0,new diff_match_patch.Diff(DIFF_EQUAL,b.substring(0,e))),a[f-1][0]=DIFF_INSERT,a[f-1][1]=c.substring(0,c.length-e),a[f+1][0]=DIFF_DELETE,",!
	Write "a[f+1][1]=b.substring(e),f++;f++}f++}};",!
	Write "diff_match_patch.prototype.diff_cleanupSemanticLossless=function(a){function b(a,b){if(!a||!b)return 6;var c=a.charAt(a.length-1),d=b.charAt(0),e=c.match(diff_match_patch.nonAlphaNumericRegex_),f=d.match(diff_match_patch.nonAlphaNumericRegex_),g=e&&c.match(diff_match_patch.whitespaceRegex_),h=f&&d.match(diff_match_patch.whitespaceRegex_);c=g&&c.match(diff_match_patch.linebreakRegex_);d=h&&d.match(diff_match_patch.linebreakRegex_);var k=c&&a.match(diff_match_patch.blanklineEndRegex_),l=d&&b.match(diff_match_patch.blanklineStartRegex_);",!
	Write "return k||l?5:c||d?4:e&&!g&&h?3:g||h?2:e||f?1:0}for(var c=1;c<a.length-1;){if(a[c-1][0]==DIFF_EQUAL&&a[c+1][0]==DIFF_EQUAL){var d=a[c-1][1],e=a[c][1],f=a[c+1][1],g=this.diff_commonSuffix(d,e);if(g){var h=e.substring(e.length-g);d=d.substring(0,d.length-g);e=h+e.substring(0,e.length-g);f=h+f}g=d;h=e;for(var l=f,k=b(d,e)+b(e,f);e.charAt(0)===f.charAt(0);){d+=e.charAt(0);e=e.substring(1)+f.charAt(0);f=f.substring(1);var m=b(d,e)+b(e,f);m>=k&&(k=m,g=d,h=e,l=f)}a[c-1][1]!=g&&(g?a[c-1][1]=g:(a.splice(c-",!
	Write "1,1),c--),a[c][1]=h,l?a[c+1][1]=l:(a.splice(c+1,1),c--))}c++}};diff_match_patch.nonAlphaNumericRegex_=/[^a-zA-Z0-9]/;diff_match_patch.whitespaceRegex_=/\s/;diff_match_patch.linebreakRegex_=/[\r\n]/;diff_match_patch.blanklineEndRegex_=/\n\r?\n$/;diff_match_patch.blanklineStartRegex_=/^\r?\n\r?\n/;",!
	Write "diff_match_patch.prototype.diff_cleanupEfficiency=function(a){for(var b=!1,c=[],d=0,e=null,f=0,g=!1,h=!1,l=!1,k=!1;f<a.length;)a[f][0]==DIFF_EQUAL?(a[f][1].length<this.Diff_EditCost&&(l||k)?(c[d++]=f,g=l,h=k,e=a[f][1]):(d=0,e=null),l=k=!1):(a[f][0]==DIFF_DELETE?k=!0:l=!0,e&&(g&&h&&l&&k||e.length<this.Diff_EditCost/2&&3==g+h+l+k)&&(a.splice(c[d-1],0,new diff_match_patch.Diff(DIFF_DELETE,e)),a[c[d-1]+1][0]=DIFF_INSERT,d--,e=null,g&&h?(l=k=!0,d=0):(d--,f=0<d?c[d-1]:-1,l=k=!1),b=!0)),f++;b&&this.diff_cleanupMerge(a)};",!
	Write "diff_match_patch.prototype.diff_cleanupMerge=function(a){a.push(new diff_match_patch.Diff(DIFF_EQUAL,""""));for(var b=0,c=0,d=0,e="""",f="""",g;b<a.length;)switch(a[b][0]){case DIFF_INSERT:d++;f+=a[b][1];b++;break;case DIFF_DELETE:c++;e+=a[b][1];b++;break;case DIFF_EQUAL:1<c+d?(0!==c&&0!==d&&(g=this.diff_commonPrefix(f,e),0!==g&&(0<b-c-d&&a[b-c-d-1][0]==DIFF_EQUAL?a[b-c-d-1][1]+=f.substring(0,g):(a.splice(0,0,new diff_match_patch.Diff(DIFF_EQUAL,f.substring(0,g))),b++),f=f.substring(g),e=e.substring(g)),",!
	Write "g=this.diff_commonSuffix(f,e),0!==g&&(a[b][1]=f.substring(f.length-g)+a[b][1],f=f.substring(0,f.length-g),e=e.substring(0,e.length-g))),b-=c+d,a.splice(b,c+d),e.length&&(a.splice(b,0,new diff_match_patch.Diff(DIFF_DELETE,e)),b++),f.length&&(a.splice(b,0,new diff_match_patch.Diff(DIFF_INSERT,f)),b++),b++):0!==b&&a[b-1][0]==DIFF_EQUAL?(a[b-1][1]+=a[b][1],a.splice(b,1)):b++,c=d=0,f=e=""""}""""===a[a.length-1][1]&&a.pop();c=!1;for(b=1;b<a.length-1;)a[b-1][0]==DIFF_EQUAL&&a[b+1][0]==DIFF_EQUAL&&(a[b][1].substring(a[b][1].length-",!
	Write "a[b-1][1].length)==a[b-1][1]?(a[b][1]=a[b-1][1]+a[b][1].substring(0,a[b][1].length-a[b-1][1].length),a[b+1][1]=a[b-1][1]+a[b+1][1],a.splice(b-1,1),c=!0):a[b][1].substring(0,a[b+1][1].length)==a[b+1][1]&&(a[b-1][1]+=a[b+1][1],a[b][1]=a[b][1].substring(a[b+1][1].length)+a[b+1][1],a.splice(b+1,1),c=!0)),b++;c&&this.diff_cleanupMerge(a)};",!
	Write "diff_match_patch.prototype.diff_xIndex=function(a,b){var c=0,d=0,e=0,f=0,g;for(g=0;g<a.length;g++){a[g][0]!==DIFF_INSERT&&(c+=a[g][1].length);a[g][0]!==DIFF_DELETE&&(d+=a[g][1].length);if(c>b)break;e=c;f=d}return a.length!=g&&a[g][0]===DIFF_DELETE?f:f+(b-e)};",!
	Write "diff_match_patch.prototype.diff_prettyHtml=function(a){for(var b=[],c=/&/g,d=/</g,e=/>/g,f=/\n/g,g=0;g<a.length;g++){var h=a[g][0],l=a[g][1].replace(c,""&amp;"").replace(d,""&lt;"").replace(e,""&gt;"").replace(f,""&para;<br>"");switch(h){case DIFF_INSERT:b[g]='<ins style=""background:#e6ffe6;"">'+l+""</ins>"";break;case DIFF_DELETE:b[g]='<del style=""background:#ffe6e6;"">'+l+""</del>"";break;case DIFF_EQUAL:b[g]=""<span>""+l+""</span>""}}return b.join("""")};",!
	Write "diff_match_patch.prototype.diff_text1=function(a){for(var b=[],c=0;c<a.length;c++)a[c][0]!==DIFF_INSERT&&(b[c]=a[c][1]);return b.join("""")};diff_match_patch.prototype.diff_text2=function(a){for(var b=[],c=0;c<a.length;c++)a[c][0]!==DIFF_DELETE&&(b[c]=a[c][1]);return b.join("""")};",!
	Write "diff_match_patch.prototype.diff_levenshtein=function(a){for(var b=0,c=0,d=0,e=0;e<a.length;e++){var f=a[e][1];switch(a[e][0]){case DIFF_INSERT:c+=f.length;break;case DIFF_DELETE:d+=f.length;break;case DIFF_EQUAL:b+=Math.max(c,d),d=c=0}}return b+=Math.max(c,d)};",!
	Write "diff_match_patch.prototype.diff_toDelta=function(a){for(var b=[],c=0;c<a.length;c++)switch(a[c][0]){case DIFF_INSERT:b[c]=""+""+encodeURI(a[c][1]);break;case DIFF_DELETE:b[c]=""-""+a[c][1].length;break;case DIFF_EQUAL:b[c]=""=""+a[c][1].length}return b.join(""\t"").replace(/%20/g,"" "")};",!
	Write "diff_match_patch.prototype.diff_fromDelta=function(a,b){for(var c=[],d=0,e=0,f=b.split(/\t/g),g=0;g<f.length;g++){var h=f[g].substring(1);switch(f[g].charAt(0)){case ""+"":try{c[d++]=new diff_match_patch.Diff(DIFF_INSERT,decodeURI(h))}catch(k){throw Error(""Illegal escape in diff_fromDelta: ""+h);}break;case ""-"":case ""="":var l=parseInt(h,10);if(isNaN(l)||0>l)throw Error(""Invalid number in diff_fromDelta: ""+h);h=a.substring(e,e+=l);""=""==f[g].charAt(0)?c[d++]=new diff_match_patch.Diff(DIFF_EQUAL,h):c[d++]=",!
	Write "new diff_match_patch.Diff(DIFF_DELETE,h);break;default:if(f[g])throw Error(""Invalid diff operation in diff_fromDelta: ""+f[g]);}}if(e!=a.length)throw Error(""Delta length (""+e+"") does not equal source text length (""+a.length+"")."");return c};diff_match_patch.prototype.match_main=function(a,b,c){if(null==a||null==b||null==c)throw Error(""Null input. (match_main)"");c=Math.max(0,Math.min(c,a.length));return a==b?0:a.length?a.substring(c,c+b.length)==b?c:this.match_bitap_(a,b,c):-1};",!
	Write "diff_match_patch.prototype.match_bitap_=function(a,b,c){function d(a,d){var e=a/b.length,g=Math.abs(c-d);return f.Match_Distance?e+g/f.Match_Distance:g?1:e}if(b.length>this.Match_MaxBits)throw Error(""Pattern too long for this browser."");var e=this.match_alphabet_(b),f=this,g=this.Match_Threshold,h=a.indexOf(b,c);-1!=h&&(g=Math.min(d(0,h),g),h=a.lastIndexOf(b,c+b.length),-1!=h&&(g=Math.min(d(0,h),g)));var l=1<<b.length-1;h=-1;for(var k,m,p=b.length+a.length,x,w=0;w<b.length;w++){k=0;for(m=p;k<m;)d(w,",!
	Write "c+m)<=g?k=m:p=m,m=Math.floor((p-k)/2+k);p=m;k=Math.max(1,c-m+1);var q=Math.min(c+m,a.length)+b.length;m=Array(q+2);for(m[q+1]=(1<<w)-1;q>=k;q--){var t=e[a.charAt(q-1)];m[q]=0===w?(m[q+1]<<1|1)&t:(m[q+1]<<1|1)&t|(x[q+1]|x[q])<<1|1|x[q+1];if(m[q]&l&&(t=d(w,q-1),t<=g))if(g=t,h=q-1,h>c)k=Math.max(1,2*c-h);else break}if(d(w+1,c)>g)break;x=m}return h};",!
	Write "diff_match_patch.prototype.match_alphabet_=function(a){for(var b={},c=0;c<a.length;c++)b[a.charAt(c)]=0;for(c=0;c<a.length;c++)b[a.charAt(c)]|=1<<a.length-c-1;return b};",!
	Write "diff_match_patch.prototype.patch_addContext_=function(a,b){if(0!=b.length){if(null===a.start2)throw Error(""patch not initialized"");for(var c=b.substring(a.start2,a.start2+a.length1),d=0;b.indexOf(c)!=b.lastIndexOf(c)&&c.length<this.Match_MaxBits-this.Patch_Margin-this.Patch_Margin;)d+=this.Patch_Margin,c=b.substring(a.start2-d,a.start2+a.length1+d);d+=this.Patch_Margin;(c=b.substring(a.start2-d,a.start2))&&a.diffs.unshift(new diff_match_patch.Diff(DIFF_EQUAL,c));(d=b.substring(a.start2+a.length1,",!
	Write "a.start2+a.length1+d))&&a.diffs.push(new diff_match_patch.Diff(DIFF_EQUAL,d));a.start1-=c.length;a.start2-=c.length;a.length1+=c.length+d.length;a.length2+=c.length+d.length}};",!
	Write "diff_match_patch.prototype.patch_make=function(a,b,c){if(""string""==typeof a&&""string""==typeof b&&""undefined""==typeof c){var d=a;b=this.diff_main(d,b,!0);2<b.length&&(this.diff_cleanupSemantic(b),this.diff_cleanupEfficiency(b))}else if(a&&""object""==typeof a&&""undefined""==typeof b&&""undefined""==typeof c)b=a,d=this.diff_text1(b);else if(""string""==typeof a&&b&&""object""==typeof b&&""undefined""==typeof c)d=a;else if(""string""==typeof a&&""string""==typeof b&&c&&""object""==typeof c)d=a,b=c;else throw Error(""Unknown call format to patch_make."");",!
	Write "if(0===b.length)return[];c=[];a=new diff_match_patch.patch_obj;for(var e=0,f=0,g=0,h=d,l=0;l<b.length;l++){var k=b[l][0],m=b[l][1];e||k===DIFF_EQUAL||(a.start1=f,a.start2=g);switch(k){case DIFF_INSERT:a.diffs[e++]=b[l];a.length2+=m.length;d=d.substring(0,g)+m+d.substring(g);break;case DIFF_DELETE:a.length1+=m.length;a.diffs[e++]=b[l];d=d.substring(0,g)+d.substring(g+m.length);break;case DIFF_EQUAL:m.length<=2*this.Patch_Margin&&e&&b.length!=l+1?(a.diffs[e++]=b[l],a.length1+=m.length,a.length2+=m.length):",!
	Write "m.length>=2*this.Patch_Margin&&e&&(this.patch_addContext_(a,h),c.push(a),a=new diff_match_patch.patch_obj,e=0,h=d,f=g)}k!==DIFF_INSERT&&(f+=m.length);k!==DIFF_DELETE&&(g+=m.length)}e&&(this.patch_addContext_(a,h),c.push(a));return c};",!
	Write "diff_match_patch.prototype.patch_deepCopy=function(a){for(var b=[],c=0;c<a.length;c++){var d=a[c],e=new diff_match_patch.patch_obj;e.diffs=[];for(var f=0;f<d.diffs.length;f++)e.diffs[f]=new diff_match_patch.Diff(d.diffs[f][0],d.diffs[f][1]);e.start1=d.start1;e.start2=d.start2;e.length1=d.length1;e.length2=d.length2;b[c]=e}return b};",!
	Write "diff_match_patch.prototype.patch_apply=function(a,b){if(0==a.length)return[b,[]];a=this.patch_deepCopy(a);var c=this.patch_addPadding(a);b=c+b+c;this.patch_splitMax(a);for(var d=0,e=[],f=0;f<a.length;f++){var g=a[f].start2+d,h=this.diff_text1(a[f].diffs),l=-1;if(h.length>this.Match_MaxBits){var k=this.match_main(b,h.substring(0,this.Match_MaxBits),g);-1!=k&&(l=this.match_main(b,h.substring(h.length-this.Match_MaxBits),g+h.length-this.Match_MaxBits),-1==l||k>=l)&&(k=-1)}else k=this.match_main(b,h,",!
	Write "g);if(-1==k)e[f]=!1,d-=a[f].length2-a[f].length1;else if(e[f]=!0,d=k-g,g=-1==l?b.substring(k,k+h.length):b.substring(k,l+this.Match_MaxBits),h==g)b=b.substring(0,k)+this.diff_text2(a[f].diffs)+b.substring(k+h.length);else if(g=this.diff_main(h,g,!1),h.length>this.Match_MaxBits&&this.diff_levenshtein(g)/h.length>this.Patch_DeleteThreshold)e[f]=!1;else{this.diff_cleanupSemanticLossless(g);h=0;var m;for(l=0;l<a[f].diffs.length;l++){var p=a[f].diffs[l];p[0]!==DIFF_EQUAL&&(m=this.diff_xIndex(g,h));p[0]===",!
	Write "DIFF_INSERT?b=b.substring(0,k+m)+p[1]+b.substring(k+m):p[0]===DIFF_DELETE&&(b=b.substring(0,k+m)+b.substring(k+this.diff_xIndex(g,h+p[1].length)));p[0]!==DIFF_DELETE&&(h+=p[1].length)}}}b=b.substring(c.length,b.length-c.length);return[b,e]};",!
	Write "diff_match_patch.prototype.patch_addPadding=function(a){for(var b=this.Patch_Margin,c="""",d=1;d<=b;d++)c+=String.fromCharCode(d);for(d=0;d<a.length;d++)a[d].start1+=b,a[d].start2+=b;d=a[0];var e=d.diffs;if(0==e.length||e[0][0]!=DIFF_EQUAL)e.unshift(new diff_match_patch.Diff(DIFF_EQUAL,c)),d.start1-=b,d.start2-=b,d.length1+=b,d.length2+=b;else if(b>e[0][1].length){var f=b-e[0][1].length;e[0][1]=c.substring(e[0][1].length)+e[0][1];d.start1-=f;d.start2-=f;d.length1+=f;d.length2+=f}d=a[a.length-1];e=d.diffs;",!
	Write "0==e.length||e[e.length-1][0]!=DIFF_EQUAL?(e.push(new diff_match_patch.Diff(DIFF_EQUAL,c)),d.length1+=b,d.length2+=b):b>e[e.length-1][1].length&&(f=b-e[e.length-1][1].length,e[e.length-1][1]+=c.substring(0,f),d.length1+=f,d.length2+=f);return c};",!
	Write "diff_match_patch.prototype.patch_splitMax=function(a){for(var b=this.Match_MaxBits,c=0;c<a.length;c++)if(!(a[c].length1<=b)){var d=a[c];a.splice(c--,1);for(var e=d.start1,f=d.start2,g="""";0!==d.diffs.length;){var h=new diff_match_patch.patch_obj,l=!0;h.start1=e-g.length;h.start2=f-g.length;""""!==g&&(h.length1=h.length2=g.length,h.diffs.push(new diff_match_patch.Diff(DIFF_EQUAL,g)));for(;0!==d.diffs.length&&h.length1<b-this.Patch_Margin;){g=d.diffs[0][0];var k=d.diffs[0][1];g===DIFF_INSERT?(h.length2+=",!
	Write "k.length,f+=k.length,h.diffs.push(d.diffs.shift()),l=!1):g===DIFF_DELETE&&1==h.diffs.length&&h.diffs[0][0]==DIFF_EQUAL&&k.length>2*b?(h.length1+=k.length,e+=k.length,l=!1,h.diffs.push(new diff_match_patch.Diff(g,k)),d.diffs.shift()):(k=k.substring(0,b-h.length1-this.Patch_Margin),h.length1+=k.length,e+=k.length,g===DIFF_EQUAL?(h.length2+=k.length,f+=k.length):l=!1,h.diffs.push(new diff_match_patch.Diff(g,k)),k==d.diffs[0][1]?d.diffs.shift():d.diffs[0][1]=d.diffs[0][1].substring(k.length))}g=this.diff_text2(h.diffs);",!
	Write "g=g.substring(g.length-this.Patch_Margin);k=this.diff_text1(d.diffs).substring(0,this.Patch_Margin);""""!==k&&(h.length1+=k.length,h.length2+=k.length,0!==h.diffs.length&&h.diffs[h.diffs.length-1][0]===DIFF_EQUAL?h.diffs[h.diffs.length-1][1]+=k:h.diffs.push(new diff_match_patch.Diff(DIFF_EQUAL,k)));l||a.splice(++c,0,h)}}};diff_match_patch.prototype.patch_toText=function(a){for(var b=[],c=0;c<a.length;c++)b[c]=a[c];return b.join("""")};",!
	Write "diff_match_patch.prototype.patch_fromText=function(a){var b=[];if(!a)return b;a=a.split(""\n"");for(var c=0,d=/^@@ -(\d+),?(\d*) \+(\d+),?(\d*) @@$/;c<a.length;){var e=a[c].match(d);if(!e)throw Error(""Invalid patch string: ""+a[c]);var f=new diff_match_patch.patch_obj;b.push(f);f.start1=parseInt(e[1],10);""""===e[2]?(f.start1--,f.length1=1):""0""==e[2]?f.length1=0:(f.start1--,f.length1=parseInt(e[2],10));f.start2=parseInt(e[3],10);""""===e[4]?(f.start2--,f.length2=1):""0""==e[4]?f.length2=0:(f.start2--,f.length2=",!
	Write "parseInt(e[4],10));for(c++;c<a.length;){e=a[c].charAt(0);try{var g=decodeURI(a[c].substring(1))}catch(h){throw Error(""Illegal escape in patch_fromText: ""+g);}if(""-""==e)f.diffs.push(new diff_match_patch.Diff(DIFF_DELETE,g));else if(""+""==e)f.diffs.push(new diff_match_patch.Diff(DIFF_INSERT,g));else if("" ""==e)f.diffs.push(new diff_match_patch.Diff(DIFF_EQUAL,g));else if(""@""==e)break;else if(""""!==e)throw Error('Invalid patch mode ""'+e+'"" in: '+g);c++}}return b};",!
	Write "diff_match_patch.patch_obj=function(){this.diffs=[];this.start2=this.start1=null;this.length2=this.length1=0};",!
	Write "diff_match_patch.patch_obj.prototype.toString=function(){for(var a=[""@@ -""+(0===this.length1?this.start1+"",0"":1==this.length1?this.start1+1:this.start1+1+"",""+this.length1)+"" +""+(0===this.length2?this.start2+"",0"":1==this.length2?this.start2+1:this.start2+1+"",""+this.length2)+"" @@\n""],b,c=0;c<this.diffs.length;c++){switch(this.diffs[c][0]){case DIFF_INSERT:b=""+"";break;case DIFF_DELETE:b=""-"";break;case DIFF_EQUAL:b="" ""}a[c+1]=b+encodeURI(this.diffs[c][1])+""\n""}return a.join("""").replace(/%20/g,"" "")};",!
	Write "this.diff_match_patch=diff_match_patch;this.DIFF_DELETE=DIFF_DELETE;this.DIFF_INSERT=DIFF_INSERT;this.DIFF_EQUAL=DIFF_EQUAL;",!
	Write "</script>",!
}

}
