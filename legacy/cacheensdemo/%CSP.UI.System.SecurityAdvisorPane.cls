/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>This pane is used by the Security Advisor page
/// It displays recommendations for system security settings.
Class %CSP.UI.System.SecurityAdvisorPane Extends %CSP.Util.Pane [ System = 4 ]
{

/// Overwritten by subclasses to draw anything this pane needs for the HEAD section.
Method DrawHEAD(pInstance As PageInstance) As %Status
{
	&html<
<style type="text/css">

h2 {
	color: #888888;
	border-top: 1px solid #888888;
	font-weight: bold;
	font-size: 1.2em;
}

.Text {
	font-size: 0.8em;
	color: #888888;
	margin-left: 20px;
}

table.DetailTable {
	border: 1px solid black;
	width: 80%;
	background: #FFFAE7;
}

table.DetailTable th {
	border-bottom: 1px solid gray;
	border-right: 1px solid gray;
	padding-left: 2px;
	padding-right: 8px;
	font-weight: bold;
	text-align: left;
}

table.DetailTable td {
	border-bottom: 1px solid gray;
	border-right: 1px solid gray;
	padding-left: 0px;
	padding-right: 0px;
}

table.RecommendList {
	border: none;
	font-size: 1.0em;
}

table.RecommendList td {
	border: none;
	border-bottom: 1px solid gray;
}

table.RecommendList td.Ignore {
	border: none;
	border-bottom: 1px solid gray;
	font-size: 0.8em;
	color: blue;
}

.Alert {
	background: #f3e799;
}

.Ignored {
	background: #D0D0D0;
	color: gray;
}

.DetailLink {
	font-size: 0.6em;
	color: #888888;
}

.DetailLink:visited {
	color: #888888;
}

.DetailLink:hover {
	color: #DA4848;
}

</style>
<script language="javascript">
function ignoreClick(ctrl,type,element,msg, id)
{
	// call server function
	setIgnoreFlag(type,element,msg,ctrl.checked ? 1 : 0, id)
}
</script>
>	

	// write out methods that perform the hyper-calls
	Write "<script language=""javascript"">",!
	Write "function setIgnoreFlag(type,element,msg,flag,id)",!
	Write "{",!
	Write ##class(%CSP.Page).HyperEventCall("%CSP.UI.System.SecurityAdvisorPane.SetIgnoreFlag","type,element,msg,flag,id",0)
 	Write ";",!
	Write "}",!
	Write "</script>",!

 	Quit $$$OK
}

/// Draw the BODY of the detail pane
Method DrawBODY(pInstance As PageInstance) As %Status
{
	Set tSC = $$$OK

	Set msgTitle = $$$Text("Welcome to the Security Advisor.")
	Set msgTitle2 = $$$Text("The Security Advisor will make a series of recommendations on how you can improve the security settings for this system. ")
	Set msgTitle2 = msgTitle2 _ $$$Text("Note that these are only general recommendations and that you may choose to ignore any or all of them depending on your specific requirements. ")
	Set msgTitle2 = msgTitle2 _ $$$Text("These recommendations are provided in order to assist with the process of securing your system; you should not consider this to be an exhaustive list of potential security risks.")

	// help message for each type
	Set msgType("Auditing") = $$$Text("The following recommendations apply to the system audit log and the various auditing event types")
	Set msgType("Services") = $$$Text("The following recommendations apply to the various services enabled on this system")
	Set msgType("Users") = $$$Text("The following information and recommendations apply to users defined on this system")
	Set msgType("Roles") = $$$Text("The following information and recommendations apply to roles defined on this system")
	Set msgType("AppsCSP") = $$$Text("The following recommendations apply to the various applications defined on this system")
	Set msgType("AppsRoutine") = $$$Text("The following recommendations apply to the privileged routine applications defined on this system")
	Set msgType("AppsExecutable") = $$$Text("The following recommendations apply to the client applications defined on this system")

	// caption for each type
	Set title("Auditing") = $$$Text("Auditing")
	Set title("Services") = $$$Text("Services")
	Set title("Users") = $$$Text("Users")
	Set title("Roles") = $$$Text("Roles")
	Set title("AppsCSP") = $$$Text("Web Applications")
	Set title("AppsRoutine") = $$$Text("Privileged Routine Applications")
	Set title("AppsExecutable") = $$$Text("Client Applications")

	// optional hyper-link for each type
	Set link("Auditing") = ##class(%CSP.Page).Link("%25CSP.UI.Portal.Audit.SystemEvents.zen")
	Set link("Services") = ##class(%CSP.Page).Link("%25CSP.UI.Portal.Services.zen")
	Set link("Users") = ##class(%CSP.Page).Link("%25CSP.UI.Portal.Users.zen")
	Set link("Roles") = ##class(%CSP.Page).Link("%25CSP.UI.Portal.Roles.zen")
	Set link("AppsCSP") = ##class(%CSP.Page).Link("%25CSP.UI.Portal.Applications.WebList.zen")
	Set link("AppsRoutine") = ##class(%CSP.Page).Link("%25CSP.UI.Portal.Applications.PrivRoutineList.zen")
	Set link("AppsExecutable") = ##class(%CSP.Page).Link("%25CSP.UI.Portal.Applications.ClientList.zen")

	Set msgNoRecommendations = $$$Text("There are no recommendations.")
	Set msgNone = $$$Text("None")
	Set msgYes = $$$Text("Yes")
	Set msgNo = $$$Text("No")

	Set cmdName = $$$Text("Name")
	Set cmdPublic = $$$Text("Public")
	Set cmdResource = $$$Text("Resource")
	Set cmdRecommend = $$$Text("Recommendation")
	Set cmdIgnore = $$$Text("Ignore")
	Set cmdDetails = $$$Text("details")

	Set showPublic("Services") = 0
	Set showPublic("Applications") = 0

	Set showResource("Applications") = 0

	//<-- auditing -->
	Set TextMsg("AuditingSBON") = $$$Text("Auditing should be enabled")
 	Set TextMsg("AuditingTypeSBON") = $$$Text("Auditing for this event type should be enabled")
 	Set TextMsg("AuditingON" )= $$$Text("Auditing is enabled")
 	Set TextMsg("AuditingOFF") = $$$Text("Auditing is disabled")
	//<!-- services -->
	Set TextMsg("ServiceSBOFF") = $$$Text("Service should be disabled unless required")
	Set TextMsg("UnauthenticatedSBOFF") = $$$Text("Unauthenticated should be off")
	Set TextMsg("ServiceSHClientIPS") = $$$Text("Service should have client IP addresses assigned")
	Set TextMsg("ServiceSHKerberos") = $$$Text("Service should use Kerberos authentication where possible")
	Set TextMsg("ServicePublic") = $$$Text("Service should not be Public where possible")
	Set TextMsg("ServiceOneAuthentication") = $$$Text("Service should only have one authentication mode on")
	Set TextMsg("ServiceNoAuthentication") = $$$Text("Service has no authentication modes enabled")
	//<!-- Users and Roles -->
	Set TextMsg("PasswordSBChanged") = $$$Text("Password should be changed from default password")
	Set TextMsg("DormantCount") = $$$Text("Dormant users should be disabled or deleted")
	Set TextMsg("NotUsedCount") = $$$Text("Users who never logged in should be disabled or deleted")
	Set TextMsg("UserIsDormant") = $$$Text("User appears dormant and should be disabled or deleted")
	Set TextMsg("UserNotUsed") = $$$Text("User has never logged in and should be disabled or deleted")
	Set TextMsg("UserNoNamespace") = $$$Text("User has a default namespace which does not exist")
	Set TextMsg("AllCountMinMax") = $$$Text("At least 2 and at most 5 users should have the %All role")
	Set TextMsg("PUBLICHasRoles") = $$$PUBLICUsername_$$$Text(" user should not have roles")
	s TextMsg("PUBLICRolesList")=$$$Text("All users are granted the following roles from ")_$$$PUBLICUsername_$$$Text(":")
	i ##Class(Security.Users).Exists($$$PUBLICUsername,.User) {
		i User.Roles.Count() {
			s Roles=""
			f i=1:1:User.Roles.Count() s Roles=Roles_User.Roles.GetAt(i)_","
			s Roles=$e(Roles,1,*-1)
			s TextMsg("PUBLICRolesList1")="--> "_Roles
		}
		k User
	}	 
	Set TextMsg("MGRCount") = $$$Text("WRITE privilege to IRISSYS should be restricted")
	Set TextMsg("SecureCount") = $$$Text("WRITE privilege to system security settings should be restricted")
	Set TextMsg("AuditCount") = $$$Text("READ and WRITE privilege to the audit database should be restricted")
	Set TextMsg("UnknownUserHasAll") = $$$Text("UnknownUser user should not have the %All role")
	Set TextMsg("AAllUsersInherit") = ("All user's inherit the following roles from ")_$$$PUBLICUsername
	Set TextMsg("PercentGlobalWrite") = $$$Text("Ability to set % globals should be turned off")
	Set TextMsg("UserHasAll") = $$$Text("This user holds the %All role")
	Set TextMsg("UserHasAudit") = $$$Text("This user holds READ or WRITE privileges on the Audit database")
	Set TextMsg("UserHasSys") = $$$Text("This user holds WRITE privilege on the IRISSYS database")
	Set TextMsg("UserHasSecure") = $$$Text("This user holds WRITE privilege on the system security settings")
	Set TextMsg("RoleHasAudit") = $$$Text("This role holds READ or WRITE privileges on the Audit database")
	Set TextMsg("RoleHasSys") = $$$Text("This role holds WRITE privilege on the IRISSYS database")
	Set TextMsg("RoleHasSecure") = $$$Text("This role holds WRITE privilege on the system security settings")

	Set TextMsg("AppIsPublic") = $$$Text("Application is Public")
	Set TextMsg("AppCondGrantsAll") = $$$Text("Application conditionally grants the %All role")
	Set TextMsg("AppGrantsAll") = $$$Text("Application grants the %All role")
	Set TextMsg("AppSHKerberos") = $$$Text("Application should use Kerberos authentication where possible")
	Set TextMsg("AppOneAuthentication") = $$$Text("Application should only have one authentication mode on")
	Set TextMsg("AppNoAuthentication") = $$$Text("Application has no authentication modes enabled")

	// calculate recommendations
	// tRecommend is an array with following subscripts:
	// tRecommend(type,element,prop,[recommend]
	// 	type is "Services", etc.
	// 	element is name of element within type: e.g., Service name
	//  prop is a "property of this node: "enabled"
	//  if prop is "list", then recommend is a specific recommendation code

	Do ..GetRecommendations(.tRecommend)

	Do ..DrawCommands(pInstance)

	// get page ID values
	Merge tID = pInstance.IDValues
	
	// ignore Text, show custom message
	// test for privilege (should not be needed)
	If ('$system.Security.Check("%Admin_Secure","USE")) {
		// unauth: show nothing
		Quit 0
	}

	&html<<div class="Text1" style="line-height: 120%;">#(msgTitle)#</div>
	<div class="Text2" style="font-size: 0.8em; margin-right: 150px; line-height: 120%;">#(msgTitle2)#</div>>

	// special link logic if auditing is not enabled
	// send user to sys-wide settings page
	If ('##class(Security.System).%OpenId($$$SystemSecurityName).AuditEnabled) {
		Set link("Auditing") = ##class(%CSP.Page).Link("%25CSP.UI.Portal.Parameters.zen")
	}

	&html<<br>>

	// display details
	Set elid = 0
	For tType = "Auditing","Services","Roles","Users","AppsCSP","AppsRoutine","AppsExecutable" {
		&html<<h2>#($G(title(tType)))#>
		If ($G(link(tType)) '= "") {
			&html<&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
				<a class="DetailLink" href="#(link(tType))#">#(cmdDetails)#</a>>
		}
		&html<</h2>
		<div class="Text">#($G(msgType(tType)))#:</div><br>>
		If '$D(tRecommend(tType)) {
			&html<<div class="Text"><i>#(msgNoRecommendations)#</i></div><br>>
		}
		Else {
			&html<<table class="DetailTable" border="0" cellspacing="0">
				<tr>
					<th width="25%">&nbsp;#(cmdName)#</th>>
						
				If (+$g(showPublic(tType))) {
					&html<<th>&nbsp;#(cmdPublic)#</th>>
				}
				If (+$g(showResource(tType))) {
					&html<<th>&nbsp;#(cmdResource)#</th>>
				}
				&html<<th>&nbsp;#(cmdRecommend)#</th>
				</tr>>
			Set tElement = $O(tRecommend(tType,""))
			While (tElement '= "") {
	
					// look at specific properties
				Set tEnabled = +$G(tRecommend(tType,tElement,"enabled"))
				Set tEnabledMsg = $S(tEnabled:msgYes,1:msgNo)

				Set tPublic = +$G(tRecommend(tType,tElement,"public"))
				Set tPublic = $Case(tPublic,1:$$$Text("Yes"),:$$$Text("No"))

				Set tResource = $G(tRecommend(tType,tElement,"resource"))

				// for 'general' element, skip enabled
				Set:tElement=" " tEnabledMsg=""

				// link?
				Set tLink = tElement,url=""
				If (tElement '= " ") {
					If (tType = "Auditing") {
						Set url = ##class(%CSP.Page).Link("%25CSP.UI.Portal.Audit.SystemEvents.zen")
					}
					ElseIf (tType = "Users") {
						Set parms("PID")=tElement
						Set url = ##class(%CSP.Page).Link("%25CSP.UI.Portal.User.zen",.parms,1)
					}
					ElseIf (tType = "Roles") {
						Set parms("PID")=tElement
						Set url = ##class(%CSP.Page).Link("%25CSP.UI.Portal.Role.zen",.parms,1)
					}
					ElseIf (tType = "Services") {
						Set url = ##class(%CSP.Page).Link("%25CSP.UI.Portal.Services.zen")
					}
					ElseIf (tType = "AppsCSP") {
						Set parms("PID")=tElement
						Set url = ##class(%CSP.Page).Link("%25CSP.UI.Portal.Applications.Web.zen",.parms,1)
					}
					ElseIf (tType = "AppsRoutine") {
						Set parms("PID")=tElement
						Set parms("ID2")=2
						Set url = ##class(%CSP.Page).Link("%25CSP.UI.Portal.Applications.PrivRoutine.zen",.parms,1)
					}
					ElseIf (tType = "AppsExecutable") {
						Set parms("PID")=tElement
						Set parms("ID2")=3
						Set url = ##class(%CSP.Page).Link("%25CSP.UI.Portal.Applications.Client.zen",.parms,1)
					}

					If (url '= "") {
						Set tLink = "<a title="""_$$$Text("Edit this item.")_""" href="""_url_""">"_$ZCVT(tElement,"O","HTML")_"</a>"
					}
				}

				&html<<tr>
					<td width="25%" nowrap>&nbsp;#(tLink)#&nbsp;</td>>
				If (+$g(showPublic(tType))) {
					&html<<td>#(tPublic)#&nbsp;</td>>
				}
				If (+$G(showResource(tType))) {
					&html<<td>#(tResource)#&nbsp;</td>>
				}
				&html<<td>
					>
					
				If ('$D(tRecommend(tType,tElement,"list"))) {
					&html<#(msgNone)#&nbsp;>
				}
				Else {
					&html<<table class="RecommendList" border="0" cellspacing="0" width="100%">>
					
					// list recommendations
					Set r = $O(tRecommend(tType,tElement,"list",""))
					While (r '= "") {
						Set rec = TextMsg(r)  //$$$GetMsg($$$AdvisorMsg,r)
						Set ig = tRecommend(tType,tElement,"list",r)
						Set marker = "*"
						Set rowState = $S(ig:"Ignored",1:"Alert")
	
						Set elid = elid + 1
	
						&html<<tr id="id_#(elid)#" class="#(rowState)#">
							<td nowrap>&nbsp;#(marker)#&nbsp;#(rec)#</td>
							<td align="right" class="Ignore" nowrap>&nbsp;
							<input #($S(ig:"checked",1:""))# type="checkbox" onclick="ignoreClick(this,'#(tType)#','#(tElement)#','#(r)#','id_#(elid)#');">#(cmdIgnore)#&nbsp;</td>
							</tr>>
	
						Set r = $O(tRecommend(tType,tElement,"list",r))
					}
					&html<</table>>
				}
	
				&html<</td></tr>>
	
				Set tElement = $O(tRecommend(tType,tElement))
			}
			&html<</table><br>>
		}
	}
	Quit $$$OK
}

/// Calculate security recommendations
ClassMethod GetRecommendations(Output recommend) As %Status
{
	Set tSC = $$$OK
	Do {
		Set tSC = ..GetServiceRecommendations(.recommend)
		If $$$ISERR(tSC) Quit

		Set tSC = ..GetAuditRecommendations(.recommend)
		If $$$ISERR(tSC) Quit

		Set tSC = ..GetUserRecommendations(.recommend)
		If $$$ISERR(tSC) Quit

		Set tSC = ..GetApplicationRecommendations(.recommend)
		If $$$ISERR(tSC) Quit

	} While(0)
	
	Quit tSC
}

/// Calculate service recommendations
ClassMethod GetServiceRecommendations(ByRef recommend) As %Status
{
	Set tSC = $$$OK
	Set tType = "Services"
	
	Set aRecommend($$$ServiceConsoleResourceName)=""
	Set aRecommend($$$ServiceTerminalResourceName)=""
	Set aRecommend($$$ServiceWebGatewayResourceName)=""
	Set aClients($$$ServiceCSP)=""
	/* YSD2314
	Set aClients($$$ServiceDCP)=""
	Set aClients($$$ServiceDDP)=""
	*/
	Set aClients($$$ServiceECP)=""
	Set aClients($$$ServiceShadow)=""
	// special check for writable % globals (no place else to put this!)
	If ($ZU(69,64)) {
		// writes to % globals should be turned off
		Do ..AddRecommendation(.recommend,tType," ","PercentGlobalWrite")
	}

	// now check services
	Set rs = ##class(%ResultSet).%New("Security.Services:List")
	Set tSC = rs.Execute()
	If $$$ISERR(tSC) Quit tSC
	i ##Class(Security.System).Exists($$$SystemSecurityName,.System)
	While rs.Next() {
		Set name = $G(rs.Data("Name"))
		i '##Class(Security.Services).Exists(name,.Service) continue
		If Service.Enabled {
			s AutheEnabled=$zb(+Service.AutheEnabled,+System.AutheEnabled,1)
			If $zb(AutheEnabled,$$$AutheUnauthenticated,1) {
				Do ..AddRecommendation(.recommend,tType,name,"UnauthenticatedSBOFF")
			}
			If '$d(aRecommend(name)) {
				Do ..AddRecommendation(.recommend,tType,name,"ServiceSBOFF")
			}
			If Service.IsPublic() {
				Do ..AddRecommendation(.recommend,tType,name,"ServicePublic")
			}
			If $D(aClients(name)) {
				i Service.ClientSystems.Count()=0 {
					Do ..AddRecommendation(.recommend,tType,name,"ServiceSHClientIPS")
				}
			}
#;See if only one bit is set. Ignore AutheSystem(1024)
			s Found=0
			f i=1,2,4,8,16,32,64,128,256,512,2048,4096,8192 {
				i $zb(+AutheEnabled,i,1) s Found=Found+1
			}
			i Found>1 Do ..AddRecommendation(.recommend,tType,name,"ServiceOneAuthentication")
			i +AutheEnabled=0 {
				Do ..AddRecommendation(.recommend,tType,name,"ServiceNoAuthentication")
			}
#;If the service can have kerberos, and it is enabled
#;system wide, then Recommend if it is not set, 
			s ServiceAutheKB=$zb(+Service.Capabilities,$$$AutheKBAll,1)
			If (ServiceAutheKB'=0),
			($zb(+System.AutheEnabled,ServiceAutheKB,1)'=0),
			($zb(+AutheEnabled,ServiceAutheKB,1)=0) {
				Do ..AddRecommendation(.recommend,tType,name,"ServiceSHKerberos")
			}
		}
	}
	
 	Quit tSC
}

/// Calculate auditing recommendations
ClassMethod GetAuditRecommendations(ByRef recommend) As %Status
{
	Set tSC = $$$OK
	Set tType = "Auditing"

	Set aRecommend($$$SourceSystem_"/"_$$$TypeDirectMode_"/"_$$$NameDirectMode)=""
 	Set aRecommend($$$SourceSystem_"/"_$$$TypeLogin_"/"_$$$NameLogin)=""
 	Set aRecommend($$$SourceSystem_"/"_$$$TypeLogin_"/"_$$$NameLoginFail)=""

	// see if auditing is turned on
	Set sys = ##Class(Security.System).%OpenId($$$SystemSecurityName,,.tSC)
	If $$$ISERR(tSC) Quit tSC
		
	Set ig = 0

	If 'sys.AuditEnabled {
		Set ig = ..AddRecommendation(.recommend,tType," ","AuditingSBON")
	}

	Kill sys
		
	If (ig) {
		// skip this is user ignores auditing
		Quit ig
	}

	Set rs = ##class(%ResultSet).%New("Security.Events:ListActivate")
	Set tSC = rs.Execute()
	If $$$ISERR(tSC) Quit tSC

	While rs.Next() {
		Set name = $G(rs.Data("Source"))_"/"_$G(rs.Data("Type"))_"/"_$G(rs.Data("Name"))
		If '$G(rs.Data("Enabled")) && $D(aRecommend(name)) {
			Do ..AddRecommendation(.recommend,tType,name,"AuditingTypeSBON")
		}
	}
	
 	Quit tSC
}

/// Calculate user recommendations (also figures out ROLE recommendations)
ClassMethod GetUserRecommendations(ByRef recommend) As %Status
{
	Set tSC = $$$OK

	Set MGRCount=0
	Set AuditCount=0
	Set SecureCount=0
	// loop over roles to find those with Audit privilege
	Set tType = "Roles"
	Set rs = ##class(%ResultSet).%New("Security.Roles:List")
	s AuditResource=$p($zu(49,$zu(179,15)),",",$$$resourcepiece)
	Set tSC = rs.Execute(,AuditResource)
	If $$$ISERR(tSC) Quit tSC
	s AuditRoles=""
	While rs.Next() {
		Set name = $G(rs.Data("Name"))
		Do ..AddRecommendation(.recommend,tType,name,"RoleHasAudit")
		s AuditRoles=AuditRoles_name_","
		s AuditCount=AuditCount+1
	}

	// loop over roles to find thouse with MgrDatabase privilege
	Set rs = ##class(%ResultSet).%New("Security.Roles:List")
	s MGRDBResource=$p($zu(49,$zu(12)),",",$$$resourcepiece)

	Set tSC = rs.Execute(,MGRDBResource_":W")
	If $$$ISERR(tSC) Quit tSC
	s MGRDBRoles=""
	While rs.Next() {
		Set name = $G(rs.Data("Name"))
		Do ..AddRecommendation(.recommend,tType,name,"RoleHasSys")
		s MGRDBRoles=MGRDBRoles_name_","
		s MGRCount=MGRCount+1
	}

	// loop over roles to find thouse with AdminSecure privilege
	Set rs = ##class(%ResultSet).%New("Security.Roles:List")
	Set tSC = rs.Execute(,$$$AdminSecureResourceName_":U")
	If $$$ISERR(tSC) Quit tSC
	s SecureRoles=""
	While rs.Next() {
		Set name = $G(rs.Data("Name"))
		Do ..AddRecommendation(.recommend,tType,name,"RoleHasSecure")
		s SecureRoles=SecureRoles_name_","
		s SecureCount=SecureCount+1
	}
	If MGRCount Do ..AddRecommendation(.recommend,tType," ","MGRCount")
	If AuditCount Do ..AddRecommendation(.recommend,tType," ","AuditCount")
	If SecureCount Do ..AddRecommendation(.recommend,tType," ","SecureCount")
	
#;Now handle the USERS
	Set tType = "Users"

	Set aRecommend($$$SYSTEMUsername)=""
 	Set aRecommend($$$SuperUserUsername)=""
 	Set aRecommend($$$AdminUsername)=""

	// loop over users
	Set rs = ##class(%ResultSet).%New("Security.Users:List")
	Set tSC = rs.Execute()
	If $$$ISERR(tSC) Quit tSC
	Set Count = 0

	Set Today = +$H
	Set AllCount = 0
	Set MGRCount=0
	Set AuditCount=0
	Set SecureCount=0
	Set NotUsedCount=0
	Set DormantCount=0
	While rs.Next() {
		If (Count > $G($$$IRISTempMgt($Username,"MaxUsers"),1000)) Quit
		Set name = $G(rs.Data("Name"))
		i (name="_Ensemble") continue
		i '##Class(Security.Users).Exists(name,.User) continue
		Set LastLogin = $zdh($G(rs.Data("LastLoginTime")),3,,,,,,,0)
		Set NotUsed = (LastLogin=0)
		Set Dormant = $S((LastLogin=0)||((Today-LastLogin)<31):0,1:1)
		
		i User.Name[$$$PUBLICUsername {
			i User.Roles.Count() {
				Do ..AddRecommendation(.recommend,tType,name,"PUBLICHasRoles")
				Do ..AddRecommendation(.recommend,tType," ","PUBLICRolesList")
				Do ..AddRecommendation(.recommend,tType," ","PUBLICRolesList1")
			}
		}
		
		i User.Name[$$$UnknownUserUsername {
			If User.SuperUser {
				Do ..AddRecommendation(.recommend,tType,"UnknownUser","UnknownUserHasAll")
			}
		}
		i (User.NameSpace'=""),($zu(90,10,User.NameSpace)=0) {
			Do ..AddRecommendation(.recommend,tType,name,"UserNoNamespace")
		}
		i User.Enabled {
			// test against default
			If ##Class(Security.Users).CheckPassword(User,"SYS") {
					Do ..AddRecommendation(.recommend,tType,name,"PasswordSBChanged")
			}
			If Dormant 	Do ..AddRecommendation(.recommend,tType,name,"UserIsDormant") s DormantCount=DormantCount+1
			If NotUsed	Do ..AddRecommendation(.recommend,tType,name,"UserNotUsed") s NotUsedCount=NotUsedCount+1
			i User.SuperUser {
				s AllCount=AllCount+1
				s MGRCount=MGRCount+1
				s AuditCount=AuditCount+1
				s SecureCount=SecureCount+1
				Do ..AddRecommendation(.recommend,tType,name,"UserHasAll")
				Do ..AddRecommendation(.recommend,tType,name,"UserHasAudit")
				Do ..AddRecommendation(.recommend,tType,name,"UserHasSys")
				Do ..AddRecommendation(.recommend,tType,name,"UserHasSecure")
			} else {
				f i=1:1:$l(AuditRoles,",") i User.Roles.Find($p(AuditRoles,",",i),"") Do ..AddRecommendation(.recommend,tType,name,"UserHasAudit") s AuditCount=AuditCount+1 q
				f i=1:1:$l(MGRDBRoles,",") i User.Roles.Find($p(MGRDBRoles,",",i),"") Do ..AddRecommendation(.recommend,tType,name,"UserHasSys") s MGRCount=MGRCount+1 q
				f i=1:1:$l(SecureRoles,",") i User.Roles.Find($p(SecureRoles,",",i),"") Do ..AddRecommendation(.recommend,tType,name,"UserHasSecure") s SecureCount=SecureCount+1 q
			}
		}
		Set Count = Count + 1
	}
	// check number of users holding %All
	If ((AllCount<2) || (AllCount>5))  {
		Do ..AddRecommendation(.recommend,tType," ","AllCountMinMax")
	}	
	If MGRCount Do ..AddRecommendation(.recommend,tType," ","MGRCount")
	If AuditCount Do ..AddRecommendation(.recommend,tType," ","AuditCount")
	If SecureCount Do ..AddRecommendation(.recommend,tType," ","SecureCount")
	If DormantCount Do ..AddRecommendation(.recommend,tType," ","DormantCount")
	If NotUsedCount Do ..AddRecommendation(.recommend,tType," ","NotUsedCount")
 	Quit tSC
}

/// Calculate application recommendations
ClassMethod GetApplicationRecommendations(ByRef recommend) As %Status
{
	Set tSC = $$$OK
	Set tBaseType = "Apps"

	i ##Class(Security.System).Exists($$$SystemSecurityName,.System)
	Set rs = ##class(%ResultSet).%New("Security.Applications:List")
	Set tSC = rs.Execute("*")
	If $$$ISERR(tSC) Quit tSC

	While rs.Next() {
		Set name = $G(rs.Data("Name"))
		i '##Class(Security.Applications).Exists(name,.App) continue
		Set type = $G(rs.Data("Type"))
		i type["CSP" s type="CSP"

			// type of recommendation depends on type of application
		Set tType = tBaseType _ type

		If (App.Enabled) {
			i App.IsPublic() {
				Do ..AddRecommendation(.recommend,tType,name,"AppIsPublic")
			}
			// test if this app grants %All
			For n=1:1:App.MatchRoles.Count() {
				Set mr = App.MatchRoles.GetAt(n)
				i $p(mr,":",1)="",($P(mr,":",2) = "%All") {
					Do ..AddRecommendation(.recommend,tType,name,"AppGrantsAll")
					q
				}
				i $P(mr,":",2) = "%All" {
					Do ..AddRecommendation(.recommend,tType,name,"AppCondGrantsAll")
					q
				}
			}
			i type'="CSP" continue
			s AutheEnabled=$zb(+App.AutheEnabled,+System.AutheEnabled,1)
			If $zb(AutheEnabled,$$$AutheUnauthenticated,1) {
				Do ..AddRecommendation(.recommend,tType,name,"UnauthenticatedSBOFF")
			}
#;See if only one bit is set. Ignore AutheSystem(1024)
			s Found=0
			f i=1,2,4,8,16,32,64,128,256,512,2048,4096,8192 {
				i $zb(+AutheEnabled,i,1) s Found=Found+1
			}
			i Found>1 Do ..AddRecommendation(.recommend,tType,name,"AppOneAuthentication")
			i +AutheEnabled=0 {
				Do ..AddRecommendation(.recommend,tType,name,"AppNoAuthentication")
			}
#;If the Application can have kerberos, then Recommend if it is not set.
			If ($zb(+System.AutheEnabled,$$$AutheK5API,1)'=0),
			($zb(+AutheEnabled,$$$AutheK5API,1)=0) {
				Do ..AddRecommendation(.recommend,tType,name,"AppSHKerberos")
			}
		}
	}
	
 	Quit tSC
}

ClassMethod AddRecommendation(ByRef recommend, pType As %String, pElement As %String, pMessage As %String) As %Boolean
{
	//Set recommend(pType,pElement,"state")="Alert"
	// see if we are ignored?
	Set ignore = ""
	If ($D($$$SecurityAdvisorGlobal(pType,pElement,pMessage))){
		Set ignore = 1
	}

	Set recommend(pType,pElement,"list",pMessage) = ignore
	
	Quit ignore
}

/// Called from client to set ignore flag.
/// <var>id</id> is id of corresponding HTML element.
ClassMethod SetIgnoreFlag(pType, pElement, pMessage, pFlag, id)
{
	If (pFlag) {
		Set cls = "Ignored"
		Set $$$SecurityAdvisorGlobal(pType,pElement,pMessage) = ""
	}
	Else {
		Set cls = "Alert"
		Kill $$$SecurityAdvisorGlobal(pType,pElement,pMessage)
	}
	
	Set reload = 0

	// some items require page reload
	If (pMessage = "AuditingSBON") {
		Set reload = 1
	}

	If ('reload) {
		// update element
		&js<if (CSPPage.document.getElementById('#(id)#')) {
			CSPPage.document.getElementById('#(id)#').className = '#(cls)#';
		}>
	}
	Else {
		// reload page
		&js<CSPPage.document.location.reload();>
	}
}

}
