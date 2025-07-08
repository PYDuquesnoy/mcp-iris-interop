/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>This pane is used by the User Profile page
/// It displays a summary of system privileges for a given user.
Class %CSP.UI.System.UserProfilePane Extends %CSP.Util.Pane [ System = 4 ]
{

/// Overwritten by subclasses to draw anything this pane needs for the HEAD section.
Method DrawHEAD(pInstance As PageInstance) As %Status
{
	&html<
<style type="text/css">
table.UserSummary {
	font-size: 0.8em;
	border: 1px solid black;
	background: #EEFFFF;
}

table.UserSummary th {
	font-weight: bold;
	text-align: right;
	padding: 2px;
	border-bottom: 1px solid gray;
}

table.UserSummary td {
	padding: 2px;
	border-bottom: 1px solid gray;
}

table.RscSummary {
	font-size: 0.8em;
	border: 1px solid black;
	background: silver;
}

table.RscSummary th {
	font-weight: bold;
	text-align: left;
	padding: 2px;
	padding-left: 5px;
	padding-right: 5px;
	border-bottom: 1px solid gray;
	background: blue;
	color: white;
}

table.RscSummary td {
	padding: 2px;
	padding-left: 5px;
	padding-right: 5px;
	border-bottom: 1px solid gray;
	border-right: 1px solid gray;
}

table.RscSummary td.Cat {
	padding: 2px;
	padding-left: 5px;
	padding-right: 5px;
	text-align: center;
	font-size: 0.8em;
	background: blue;
	background: lightblue;
}

table.RscSummary td.assets {
	padding: 0px;
}

table.assets {
	border: none;
}

table.assets th {
	color: black;
	background: none;
	font-size: 0.7em;
	border: none;
	font-weight: normal;
	font-style: italic;
}

table.assets td {
	font-size: 0.8em;
	border: none;
}


.HASPRIV {
	background: #EEFFFF;
}

.HOLD {
	font-weight: bold;
	background: yellow;
}

.NOHOLD {
	background: silver;
}

</style>
>	

	Quit $$$OK
}

/// Draw the BODY of the detail pane
Method DrawBODY(pInstance As PageInstance) As %Status
{
	Set tSC = $$$OK

	Do ..DrawCommands(pInstance)
	// get page ID values
	Merge tID = pInstance.IDValues
	Set tUser = $G(tID(1))
	Set tName = $ZCVT(tUser,"L")
	
	Set msgTitle = $ZCVT($$$FormatText($$$Text("This page displays summary privilege information for user %1:"),tUser),"O","HTML")
	Set msgNoUser = $ZCVT($$$FormatText($$$Text("User, %1, does not exist."),tUser),"O","HTML")

	Set msgTitle2 = $ZCVT($$$FormatText($$$Text("User, %1, holds the following privileges:"),tUser),"O","HTML")
	Set msgTitleAll = $ZCVT($$$FormatText($$$Text("User, %1, is a member of the %All role and holds ALL privileges."),tUser),"O","HTML")
	Set cmdName = $$$Text("Name")
	Set msgName = $$$Text("User")
	Set cmdDesc = $$$Text("Full Name")
	Set msgDesc = $$$Text("User's Full Name")
	Set cmdRoles = $$$Text("Roles")
	Set msgRoles = $$$Text("Roles this user belongs to")
	Set msgNoRoles = $$$Text("none")
	Set cmdLastLogin = $$$Text("Last Login")
	Set msgLastLogin = $$$Text("Time of last successful login for this user")
	Set cmdLastDevice = $$$Text("Last Login Device")
	Set msgLastDevice = $$$Text("Device of last successful login for this user")
	Set msgNever = $$$Text("Never")
	Set cmdLastBadLogin = $$$Text("Last Invalid Login")
	Set msgLastBadLogin = $$$Text("Time of last unsuccessful login for this user")
	Set cmdLastBadDevice = $$$Text("Last Invalid Login Device")
	Set msgLastBadDevice = $$$Text("Device of last unsuccessful login for this user")
	Set cmdBadAttempts = $$$Text("Invalid Login Attempts")
	Set msgBadAttempts = $$$Text("Number of invalid login attempts since last successful login")
	Set cmdLastPwdChange = $$$Text("Last Password Change")
	Set msgLastPwdChange = $$$Text("Time of last password change for this user")
	Set cmdInvalidLoginStatus = $$$Text("Reason for Failing to Login")
	Set msgInvalidLoginStatus = $$$Text("Reason the system denied the user's last login")
	
	Set cmdResource  = $$$Text("Resource")
	Set cmdAsset  = $$$Text("Protects")
	Set cmdByRole  = $$$Text("Granted by role")
	Set cmdByRsc  = $$$Text("Granted by public resource")
	Set cmdDatabases = $$$Text("Databases")
	Set cmdApplications = $$$Text("Applications")
	
	Set msgResource = $$$Text("List of resource names")
	Set msgAsset = $$$Text("List of items protected by a resource")
	Set msgR = $$$Text("Items on which user holds Read privilege")
	Set msgW = $$$Text("Items on which user holds Write privilege")
	Set msgU = $$$Text("Items on which user holds Use privilege")
	Set msgByRole  = $$$Text("List of roles that have granted privileges for a resource")
	Set msgByRsc  = $$$Text("List of public privileges granted a resource")
	
	// table of built-in resources and what they protect
	Set builtIn("%Admin_Manage") = $$$Text("System manager tasks")
	Set builtIn("%Admin_Operate") = $$$Text("System operator tasks")
	Set builtIn("%Admin_Secure") = $$$Text("System security management")
	Set builtIn("%Development") = $$$Text("Application development")

	Set builtIn("%Service_WebGateway") = $$$Text("Web usage")
	Set builtIn("%Service_CacheDirect") = $$$Text("CacheDirect usage")
	Set builtIn("%Service_CallIn") = $$$Text("Callin usage")
	Set builtIn("%System_CallOut") = $$$Text("Callout usage")
	Set builtIn("%Service_ComPort") = $$$Text("COM Port usage")
	Set builtIn("%Service_Console") = $$$Text("System console usage")
	Set builtIn("%Service_LAT") = $$$Text("LAT usage")
	Set builtIn("%Service_Object") = $$$Text("Object/SQL client access")
	Set builtIn("%Service_SQL") = $$$Text("SQL xDBC access")
	Set builtIn("%Service_Telnet") = $$$Text("TELNET access")
	Set builtIn("%Service_Terminal") = $$$Text("Terminal usage")
	
	Set thAsset = $$$Text("Asset")
	Set thPrivileges = $$$Text("Privileges")
	Set thSource = $$$Text("Source")

	// ignore Text, show custom message
	Do {
		// test for privilege (should not be needed)
		If ('$system.Security.Check("%Admin_Secure","USE")) {
			// unauth: show nothing
			Quit
		}

		If ((tUser = "") || '##class(Security.Users).%ExistsId(tName)) {
			&html<<div class="Text1">#(msgNoUser)#</div>>
			Quit
		}
		
		Set tUserDef = ##class(Security.Users).%OpenId(tName)
		If '$IsObject(tUserDef) Quit

		&html<<div class="Text1">#(msgTitle)#</div>>
		
		// find complete set of roles this user belongs to
		Set tSC = ##class(Security.Users).GetRoleSet(tName, .tRoles)
		If $$$ISERR(tSC) QUIT
		
		#; YSD1607: added the following
		Set all = tRoles [ "%All"
		
		Set tLastLog = $Case(tUserDef.LoginDateTime,"":"n/a",0:msgNever,:$zdatetime($zu(193,tUserDef.LoginDateTime,0),3,,3))
		Set tLastDevice = $Case(tUserDef.LoginDevice,"":"n/a",0:msgNever,:tUserDef.LoginDevice)
		Set tLastBadLog = $Case(tUserDef.InvalidLoginDateTime,"":"n/a",0:msgNever,:$zdatetime($zu(193,tUserDef.InvalidLoginDateTime,0),3,,3))
		Set tLastBadLogDevice = $Case(tUserDef.InvalidLoginDevice,"":"n/a",0:msgNever,:tUserDef.InvalidLoginDevice)
		Set tLastPwdChange = $Case(tUserDef.PasswordChangedDateTime,"":"n/a",0:msgNever,:$zdatetime($zu(193,tUserDef.PasswordChangedDateTime,0),3,,3))
		Set tInvalidLoginStatus = $Case(tUserDef.InvalidLoginStatus,"1":"n/a",:$ZCVT($System.Status.GetErrorText(tUserDef.InvalidLoginStatus),"O","HTML"))

		&html<<hr>
			<table class="UserSummary" border="0" cellpadding="0" cellspacing="0">
			<tr><th title="#(msgName)#">#(cmdName)#:</th><td>#($ZCVT(tUserDef.Name,"O","HTML"))#&nbsp;</td></tr>
			<tr><th title="#(msgDesc)#">#(cmdDesc)#:</th><td>#($ZCVT(tUserDef.FullName,"O","HTML"))#&nbsp;</td></tr>
			<tr><th title="#(msgRoles)#">#(cmdRoles)#:</th><td>#($Case(tRoles,"":"<i>"_msgNoRoles_"</i>",:tRoles))#&nbsp;</td></tr>
			<tr><th title="#(msgLastPwdChange)#">#(cmdLastPwdChange)#:</th><td>#(tLastPwdChange)#</td></tr>
			<tr><th title="#(msgLastLogin)#">#(cmdLastLogin)#:</th><td>#(tLastLog)#&nbsp;</td></tr>
			<tr><th title="#(msgLastDevice)#">#(cmdLastDevice)#:</th><td>#(tLastDevice)#&nbsp;</td></tr>
			<tr><th title="#(msgBadAttempts)#">#(cmdBadAttempts)#:</th><td>#(tUserDef.InvalidLoginAttempts)#&nbsp;</td></tr>
			<tr><th title="#(msgLastBadLogin)#">#(cmdLastBadLogin)#:</th><td>#(tLastBadLog)#&nbsp;</td></tr>
			<tr><th title="#(msgLastBadDevice)#">#(cmdLastBadDevice)#:</th><td>#(tLastBadLogDevice)#&nbsp;</td></tr>
			<tr><th title="#(msgInvalidLoginStatus)#">#(cmdInvalidLoginStatus)#:</th><td>#(tInvalidLoginStatus)#&nbsp;</td></tr>
			</table>>

		// get list of privileges granted by roles
		// accumulate details
		
 		Set tRS = ##class(%ResultSet).%New("Security.Roles:Detail")
		If '$IsObject(tRS) Quit

		Set tSC = tRS.Execute(tRoles)
		If $$$ISERR(tSC) QUIT
		
		#; YSD1607 Set all = 0
	 		
		While(tRS.Next()) {
			Set role = $G(tRS.Data("Name"))
			Set rsc = $P($G(tRS.Data("Resources")),":",1)
			Set priv = $P($G(tRS.Data("Resources")),":",2)
			
			// test for special roles
			#; YSD1607 If (role = "%All") {
			#; YSD1607	Set all = 1
			#; YSD1607 }
			
			If (rsc '= "") {
				// source of privilege (list of roles) (with priv tacked on)
				Set:priv'="" tResources(rsc,"role") = $G(tResources(rsc,"role")) _ $S($D(tResources(rsc,"role")):"<br>",1:"") _ role _ ":" _ priv

				// privileges
				Set:priv["U" tResources(rsc,"U") = "U"
				Set:priv["R" tResources(rsc,"R") = "R"
				Set:priv["W" tResources(rsc,"W") = "W"
			}
		}

		// get list of privileges granted by virtue of public resources
 		Set tRS = ##class(%ResultSet).%New("Security.Resources:List")
		If '$IsObject(tRS) Quit

		Set tSC = tRS.Execute()
		If $$$ISERR(tSC) QUIT

		While(tRS.Next()) {
			Set rsc = $G(tRS.Data("Name"))
			Set priv = $G(tRS.Data("PublicPermission"))
			
			If (rsc '= "") {
				// make all resources show up in the list???
				Set tResources(rsc) = ""

				// source of privilege (with priv tacked on)
				Set:priv'="" tResources(rsc,"rsc") = $G(tResources(rsc,"rsc")) _ $S($D(tResources(rsc,"rsc")):"<br>",1:"") _ rsc _ ":" _ priv

				// privileges
				Set:priv["U" tResources(rsc,"U") = "U"
				Set:priv["R" tResources(rsc,"R") = "R"
				Set:priv["W" tResources(rsc,"W") = "W"
			}
		}
		
		// build list of databases and which resource protects them...
 		Set tRS = ##class(%ResultSet).%New("SYS.Database:List")
		If '$IsObject(tRS) Quit

		Set tSC = tRS.Execute("*",0)
		If $$$ISERR(tSC) QUIT

		While(tRS.Next()) {
			Set dir = $G(tRS.Data("Directory"))
			Set db = ##class(SYS.Database).%OpenId(dir)
			
			If ((dir '= "") && $IsObject(db) && (db.ResourceName '= "")) {
				Set tAssets(db.ResourceName,cmdDatabases,dir) = ""
			}
		}
		Set db = ""

		// build list of applications and which resource protects them...
 		Set tRS = ##class(%ResultSet).%New("Security.Applications:List")
		If '$IsObject(tRS) Quit

		Set tSC = tRS.Execute()
		If $$$ISERR(tSC) QUIT

		While(tRS.Next()) {
			Set app = $G(tRS.Data("Name"))
			Set rsc = $G(tRS.Data("Resource"))
			If ((app '= "") && (rsc '= "")) {
				Set tAssets(rsc,cmdApplications,app) = ""
			}
		}

		// display results
		
		&html<<hr>>
		
		If (all) {
			&html<<div class="Text">#(msgTitleAll)#</div>>
		}
		ElseIf ($D(tResources)) {
			&html<<div class="Text">#(msgTitle2)#</div>>
			&html<<br>
				<table class="RscSummary" border="0" cellpadding="0" cellspacing="0">
				<tr><td class="Cat" colspan="2">#(thAsset)#</td><td class="Cat" colspan="3">#(thPrivileges)#</td><td class="Cat" colspan="2">#(thSource)#</td></tr>
				<tr><th title="#(msgResource)#">#(cmdResource)#</th>
					<th title="#(msgAsset)#">#(cmdAsset)#</th>
					<th title="#(msgR)#">R</th>
					<th title="#(msgW)#">W</th>
					<th title="#(msgU)#">U</th>
					<th title="#(msgByRole)#">#(cmdByRole)#</th>
					<th title="#(msgByRsc)#">#(cmdByRsc)#</th></tr>
				>
	
			Set rsc = $O(tResources(""))
			While (rsc '= "") {
				// do we have *any* privileges?
				Set pr = $D(tResources(rsc,"R")) || $D(tResources(rsc,"W")) || $D(tResources(rsc,"U"))
				
				
				&html<<tr #($S(pr:"class=""HASPRIV""",1:""))#><td>#(rsc)#</td>>
				
				If ('$D(tAssets(rsc)) && '$D(builtIn(rsc))) {
					&html<<td>&nbsp;</td>>
				}
				Else {
					&html<<td class="assets">
						<table class="assets" border="0" width="100%" cellspacing="0" cellpadding="0">>
					
					// built in resource?
					If ($G(builtIn(rsc)) '="") {
						&html<<tr><th>#(builtIn(rsc))#</th></tr>>
					}

					Set atype = $O(tAssets(rsc,""))
					While (atype '= "") {
						&html<<tr><th>#(atype)#:</th></tr>>

						// list assets of this type protected by this resource
						Set asset = $O(tAssets(rsc,atype,""))
						While (asset '= "") {
							&html<<tr><td width="100%">&nbsp;#($ZCVT(asset,"O","HTML"))#</td></tr>>
							Set asset = $O(tAssets(rsc,atype,asset))
						}
						Set atype = $O(tAssets(rsc,atype))
					}

					&html<</table></td>>
				}
				
				For p="R","W","U" {
					Set hold = $D(tResources(rsc,p))
					&html<<td class="#($S(hold:"HOLD",1:"NOHOLD"))#">#($S(hold:p,1:"&nbsp;"))#</td>>
				}
				
				&html<
				<td>#($G(tResources(rsc,"role"),"&nbsp;"))#</td>
				<td>#($G(tResources(rsc,"rsc"),"&nbsp;"))#</td>
				</tr>>
	
				Set rsc = $O(tResources(rsc))
			}
			&html<</table><br>>
		}
	}
	While(0)
	

	Quit $$$OK
}

}
