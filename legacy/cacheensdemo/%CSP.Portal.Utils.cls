/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// APIs used by the System Management Portal.
Class %CSP.Portal.Utils Extends %RegisteredObject [ Abstract, System = 4 ]
{

Parameter DOMAIN = "%Utility";

/// Add item to favorites list.
ClassMethod %AddFavorite(pName As %String, pLink As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		If (pName="") Quit
		Set tSC = ##class(%SYS.Portal.Users).%AddFavorite(pName,pLink)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the current favorites list for the current user:
/// pItems(n) = $LB(name,date,url)
ClassMethod %GetFavoritesForUser(Output pFavorites) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pFavorites
		Set tSC = ##class(%SYS.Portal.Users).%GetFavoritesForUser(.tFavorites)
		If $$$ISERR(tSC) Quit

		If $IsObject($get(%response)) {
			Set tContextNS = $get(%response.Context("$NAMESPACE"))
			Kill %response.Context("$NAMESPACE")
		}
		Set n = 0
		Set tName = $O(tFavorites(""))
		While (tName'="") {
			Set tLink = $G(tFavorites(tName))
			Set tLink = ##class(%CSP.Page).Link(tLink)
			Set pFavorites($I(n)) = $LB(tName,"",tLink)
			Set tName = $O(tFavorites(tName))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $IsObject($get(%response)) && ($get(tContextNS) '= "") {
		Set %response.Context("$NAMESPACE") = tContextNS
	}
	Quit tSC
}

/// Return the recent items list for the current user:<br/>
/// pItems(n) = $LB(name,date,url)<br/>
/// These are reset on system restart.
ClassMethod %GetRecentItemsForUser(Output pItems) As %Status
{
	Set tSC = $$$OK
	Try {
		Set n = 0
		Set tName = $O(^IRIS.Temp.Portal.UserPreferences($UserName,"recent",""),1,t)
		While (tName'="") {
			Set n = n + 1
			Set ts = $ZDT($LG(t,1),3)
			Set tURL = $LG(t,2)
			Set tList(ts_"?"_n) = $LB(tName,ts,tURL)
			Set tName = $O(^IRIS.Temp.Portal.UserPreferences($UserName,"recent",tName),1,t)
		}

		Set n = 0
		Set k = $O(tList(""),-1)
		While (k'="") {
			Set pItems($I(n)) = tList(k)
			Set k = $O(tList(k),-1)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Add this item to the recent item list.
ClassMethod %RegisterRecentItem(pName As %String, pURL As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tRecentCount = 6
		If ((pName="")||(pURL="")) Quit

		Set ^IRIS.Temp.Portal.UserPreferences($UserName,"recent",pName) = $LB($H,pURL)

		// clear out old items
		Set tCount = 0
		Set tName = $O(^IRIS.Temp.Portal.UserPreferences($UserName,"recent",""),1,t)
		While (tName'="") {
			If ($G(t)'="") {
				Set ts = $ZDT($LG(t,1),3)
				If (ts'="") {
					Set tList(ts) = tName
					Set tCount = tCount + 1
				}
			}
			Set tName = $O(^IRIS.Temp.Portal.UserPreferences($UserName,"recent",tName),1,t)
		}

		While (tCount > tRecentCount) {
			Set t = $O(tList(""),1,tName)
			Kill:tName'="" ^IRIS.Temp.Portal.UserPreferences($UserName,"recent",tName)
			Set tCount = tCount - 1
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Delete recent item list for given user. If user is not specified, delete all items.
ClassMethod %ClearRecentItems(pUser As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		If (pUser="") {
			Set tUser = $O(^IRIS.Temp.Portal.UserPreferences(""))
			While (tUser'="") {
				Kill ^IRIS.Temp.Portal.UserPreferences(tUser,"recent")
				Set tUser = $O(^IRIS.Temp.Portal.UserPreferences(tUser))
			}
		}
		Else {
			Kill ^IRIS.Temp.Portal.UserPreferences(pUser,"recent")
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Delete favorite item list for given user. If user is not specified, delete all items.
ClassMethod %ClearFavoriteItems(pUser As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		If (pUser="") {
			Set tSC = ##class(%SYS.Portal.Users).%RemoveFavoritesForUsers()
			If $$$ISERR(tSC) Quit
		}
		Else {
			Set tSC = ##class(%SYS.Portal.Users).%RemoveFavoritesForUser()
			If $$$ISERR(tSC) Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Delete a recent item for the current user.
ClassMethod %RemoveRecentItem(pName As %String) As %Status
{
	Kill ^IRIS.Temp.Portal.UserPreferences($UserName,"recent",pName)
	Quit $$$OK
}

/// Delete a favorite item for the current user.
ClassMethod %RemoveFavoriteItem(pName As %String) As %Status
{
	Set tSC = ##class(%SYS.Portal.Users).%RemoveFavorite(pName)
	Quit tSC
}

/// Get a list of namespaces which the current user may access.
/// <var>pNamespaces</var> is returned as an array with the following structure:
/// pNamespaces("NAMESPACE") = $lb(enabled,remote)
ClassMethod %GetNamespaceList(Output pNamespaces As %String) As %Status
{
	Kill pNamespaces
	Set Type = 5   		// 5 - Returns array of all namespaces on the system we have access to plus remote unmounted ones (YSD2523)
	Set Remote = 1 		// 1 - Return remote namespaces as well (YSD2663)
	Set DontConnect = 1	// 1 - Do not attempt to connect 
	Do List^%SYS.NAMESPACE(.pNamespaces,Type,Remote,DontConnect)
	Quit $$$OK
}

/// Get the custom resource assigned to a given id (url).
/// Note that <var>pID</var> should be URL-encoded.
ClassMethod %GetCustomResource(pID As %String) As %String
{
	Set tResource = ""
	Set tSC = $$$OK
	Try {
		Set tResource = ##class(%SYS.Portal.Resources).%GetCustomResource(pID)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Set tResource = ""
	}
	Quit tResource
}

/// Set the custom resource assigned to a given id (url).
/// Note that <var>pID</var> should be URL-encoded.
ClassMethod %SetCustomResource(pID As %String, pResource As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ##class(%SYS.Portal.Resources).%SetCustomResource(pID,pResource)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Check the custom resource (if any) assigned to a given URL.
/// Note that <var>pURL</var> should be URL-encoded.
ClassMethod %CheckCustomResource(pURL As %String) As %Boolean
{
	Set tResource = ..%GetCustomResource(pURL)
	If tResource '= "" {
		Quit $system.Security.Check(tResource,"USE")
	}
	Quit 1
}

ClassMethod %CheckTaskResource() As %Boolean
{
	Quit $system.Security.Check("%Admin_Task","USE")
}

ClassMethod %DrawError(pStatus As %Status) As %Status
{
	Set errText = $system.Status.GetErrorText(pStatus)
	Write !,"<html><head></head><body><div>",errText,"</div></body></html>"
	Quit $$$OK
}

/// Return a list of all currently used custom resource names.
ClassMethod %GetCustomResourceList(pList As %String) As %Status
{
	Kill pList
	Set tSC = $$$OK
	Try {
		Set tRS = ##class(%ResultSet).%New("%SYS.Portal.Resources:List")
		Set tSC = tRS.Execute()
		If $$$ISERR(tSC) Quit

		While (tRS.Next()) {
			Set tResource = tRS.Data("Resource")
			Set:tResource'="" pList(tResource) = ""
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return a boolean to indicate whether a supplied URL/Link is a page in the ISC portals.<br/>
/// <var>pPage</var> should be URL-encoded.<br/>
/// If the URL is in the portal, then <var>pNormPage</var> is the classname of the class that handles requests for the URL.
ClassMethod %IsPortalPage(pPage As %String = "", Output pNormPage As %String) As %Boolean [ Internal ]
{
	Set tPage = ##class(%SYS.Portal.Resources).NormalizePage(pPage)
	Set tInPortal = 0
	Try {
		If tPage = "" Quit
		Set tPackage = $piece(tPage,".",1)
		Set tFirstSub = $piece(tPage,".",2)
		Set tSecondSub = $piece(tPage,".",3)
		Set tInPortal = $case(tPackage,
							"%cspapp": 		1,
							"%CSP": 		(tFirstSub = "Portal") || (tFirstSub = "UI"),
							"%DeepSee":		$case(tFirstSub, "UI": 1, "UserPortal": 1, "Report": 1, : 0) || ((tFirstSub="PMML")&&(tSecondSub="UI")),		// DTB612 - Allow assignment for PMML
							"%WebStress":	(tFirstSub = "Portal"),
							"%UnitTest":	(tFirstSub = "Portal"),
							"EnsPortal":	##class(%Library.EnsembleMgr).IsEnsembleInstalled(),
							"EnsLib":		##class(%Library.EnsembleMgr).IsEnsembleInstalled(),
							"Ens":			##class(%Library.EnsembleMgr).IsEnsembleInstalled() && (tFirstSub = "Enterprise") && (tSecondSub = "Portal"),
							"HS":			(tFirstSub = "UI") && ##class(%Library.EnsembleMgr).IsHealthShareInstalled(),
							"%MPRL":		(tFirstSub = "UI"),
							"HSPI":			(tFirstSub = "UI"),
                            "%iKnow":       ((tFirstSub = "Classification") && (tSecondSub = "UI")) || (tFirstSub = "UI"),
									: 0)
	}
	Catch {
		Set tInPortal = 0
	}
	Set pNormPage = $select(tInPortal: tPage, 1: "")
	Quit tInPortal
}

/// CheckLinkAccess determines whether the target user is permitted
///    to view a given CSP or Zen page based on the security requirements 
///   for the relevant target Web application, the underlying page class, 
///   and any custom resources applied to the link.
/// <p>Returns 0 if the link is not to a csp application. (enable)</p>
/// <p>Returns 1 if the user is permitted access to the page. (enable) </p>
/// <p>Returns 2 if could not determine Target User. Clicking on link will bring up login page. (choice: enable or disable)</p>
/// <p>Returns 3 if the user doesn't have access to the CSP application.(disable)</p>
/// <p>Returns 4 if the user doesn't have resources specific to the page.(disable)</p>
/// <ol>
/// <li>It is assumed the CheckLinkAccess is called from a context in which 
///    %session and %request are available, ie, from callpage in the CSP Server </li>
/// <li>In order to minimize information trolling, CheckLinkAccess will just return
///    a bit indicating if the link should be enabled in the current calling context.</li>
/// <li>Definitions:
///    <ol><li>Source application - application in which the current caller is being run</li>
///    <li>Current user - ($Username) the user currently logged into the Source Application</li>
///   <li>Target Application - the application pointed to by the link</li>
///    <li>Target User - the computed username under which the user will be logged 
///       into the Target Application</li>
///    <li>Target Page: the page portion of the link, e.g., /csp/app/mypage.csp:  mypage.csp</li>
///   </ol></ol>
/// <p>This method is meant to be called from the link's containing page 
///   within the context of the CSP server. The containing page is part of a 
///   source application.</p>
/// <p>We must be able to detemine which target user will be used to check privileges. The target user cannot be 
/// determined if the source and target applications are different and the target is neither part of an active 
/// by-id group nor sharing-sessions with the source application.</p>
/// <p>Applications share sessions when:</p>
/// <ul>
/// <li>The source and target are the same application.</li>
/// <li>The link to the target page contains CSPSHARE=1.</li>
/// <li>Source and target applications have the same Session Cookie Path.</li>
/// </ul>
/// <h3>Who is the target user?</h3>
///  <p>Since this is called from with a CSP session, there are the following situations:</p>
///  <ol>
/// <li>The target application is a member of an authenticated by-id group. That group's
///  authenticated user is the Target User.</li>
/// <li>The target application will be in the current session. The CSP server has already 
/// handled logic for determing the user.
///  <ol>
///   <li>The session's user is not UnknownUser. The target user is $Username.</li>
///   <li>The session's user is UnknownUser
/// <ul>
/// <li>If the target application is the source application, the Target User is UnknownUser.</li>
/// <li>If the target application is different, the target user is the user from the session's Sticky-context.
/// If the session has no sticky-context, the Target User will be UnknownUser</li>
/// </ul></li>
/// </li></ol></li></ol>
///  <h3>CheckLinkAccess Policy</h3>
/// <ul>
/// <li>If the Target Application is not a CSP Application, return ENABLE/UNKNOWN	</li>	
/// <li>If the Source and Target application are the same, skip to check resources.</li> 		
/// <li>If the Target Application is neither in an authenticated by-id group nor in the 
///  Source Application's session, return ENABLE/UNKNOWN</li>		
/// <li>Compute the Target User. See 'Who is Target User?' above.</li>	
/// <li>If the Target Application is two-factor enabled and the Target User is not, return NO_APP_ACCESS.</li>	
/// <li>Get any application-defined and user-defined 
///   resources assigned to the Target Page.</li>		
/// <li>If Source and Target Applications are different, check that the Target User has 
///   the right roles to enter the Target Application. 
///   If not, return NO_APP_ACCESS.</li>
/// <li>Check Resources:		
/// <p>If the Target User can access the Target Page's Resources after escalating roles 
///   from the Target Application, return ENABLE/UNKNOWN. Else return NO_PAGE_ACCESS.</p>
/// </li>
/// </ul>
ClassMethod CheckLinkAccess(link As %String) As %Integer
{
	#Dim targetUsername,targetAppName,targetNamespace,accessStatus,resource,ext,cls,tPrimarySuper,targetResources,customResource
	
	#; If not link, then just return the no-link value
  	If $get(link) = "" {
		#; no value in link: can access
		Quit $$$caNoAccessToRes  
  	}

    try {
		Set accessStatus = %session.GetLinkTargets( link, .targetUsername, .targetAppName, .targetNamespace)
		#; negative values indicate that further analysis is necessary.
 		if ( accessStatus < 0 ) 
 			{
	 		
	 		// Check if user has the %All role before retrieving resources.
	 		If (accessStatus = $$$caCheckResourcesOnly) && $$$IOwnAllRole {
	 		 	Set accessStatus = $$$caCanAccessRes
	 			Quit
	 		}
	 		ElseIf (accessStatus = $$$caCheckAll) && ('$System.Context.Security().IsEscalated()) {
		 		// If we need to check all, we can skip further checks if
		 		// the user's login roles include the %All role
	 			Set tHaveAllRole = 0
		 		Do 
		 		. New $roles
		 		. $$$ResetToLoginRoles
		 		. If $$$IOwnAllRole Set tHaveAllRole = 1
			 	If tHaveAllRole {
				 	Set accessStatus = $$$caCanAccessRes
				 	Quit
			 	}
	 		}
	 		
	 		/************* Compute Target Resources **********************/
 			// Let's get the set of resources against which we will check
			// Get the page resource for Zen pages
			Set resource = ""
			Set link = $piece(link,"?",1)
			Set ext = $zcvt($piece(link,".",$length(link,".")),"l")
			If (ext = "zen") || (ext = "cls") {
				Set cls = $extract($piece(link,"/",$length(link,"/")),1,*-4)
				Set cls = $zconvert(cls,"I","URL")
				Set cls = $translate(cls,"_","%")
				Try {
					// Only get RESOURCE for Zen pages and SVG components; note that extended references are used to avoid changing namespaces
					If $data(^|targetNamespace|oddCOM(cls)) {
						Set tPrimarySuper = $get(^|targetNamespace|oddCOM(cls,$$$cCLASSprimarysuper))
						If (  (tPrimarySuper ["~%ZEN.Component.abstractPage~") 
							|| (tPrimarySuper ["~%ZEN.SVGComponent.svgPage~") ) {
							Set resource =$s($d(^|targetNamespace|oddCOM(cls,$$$cCLASSparameter,"RESOURCE",$$$cPARAMdefault))#2: ^($$$cPARAMdefault),
											$d(^|targetNamespace|oddCOM($g(^($$$cPARAMorigin),cls),$$$cCLASSparameter,"RESOURCE",$$$cPARAMdefault))#2: ^($$$cPARAMdefault),
											1: $s($d(^|targetNamespace|oddDEF($g(^|targetNamespace|oddCOM(cls,$$$cCLASSparameter,"RESOURCE",$$$cPARAMorigin),cls),$$$cCLASSparameter,"RESOURCE",$$$cPARAMdefault))#2: ^($$$cPARAMdefault), 1: ""))
						}
					}
	      		} 
	      		Catch {
		      	}
			}
			Set targetResources = $case(resource,"":"",:$lb(resource))

			Set customResource = ##class(%SYS.Portal.Resources).%GetCustomResource(link)
			if (customResource '= "" ) {
				Set targetResources = targetResources_$lb(customResource)
			}
	 		/************* End Compute Target Resources **********************/
	 		#; Are there any resources to check?
			if ( targetResources="") {
				#; No resource to check.
				if (accessStatus = $$$caCheckResourcesOnly) {
					#; we are already logged into the target application: we're good.
					Set accessStatus = $$$caCanAccessRes 
				}
				else {
					#; We just need to check if we can log into the target application
					If $System.Context.Security().IsEscalated() {
						Set accessStatus = $$CheckCSPResourceEscalationRole^%SYS.SECURITY($System.Context.Security().EscalationRole, targetAppName, "")
					} else {
						Set accessStatus = $case($$CheckCSPApplication^%SYS.SECURITY(targetAppName, targetUsername ), 0:$$$caNoAccessToApp, :$$$caCanAccessRes )	
					}
				}
			}
			else {
				#; We have resources to check.
				if (accessStatus = $$$caCheckResourcesOnly) {
					#; we are just checking the resources for the session's currently logged in user
					Set accessStatus = ##class(%CSP.Portal.Utils).CheckLoggedInResources(targetResources)
				}
				else {
					#; make the big call which will simulate logging in to a different application.
					If $System.Context.Security().IsEscalated() {
						Set accessStatus = $$CheckCSPResourceEscalationRole^%SYS.SECURITY($System.Context.Security().EscalationRole, targetAppName, targetResources) 
					} Else {
						Set accessStatus = $$CheckCSPResources^%SYS.SECURITY( targetUsername, targetAppName, targetResources )
					}
				}
			}
 		}
	} Catch {
         Set accessStatus = $$$caNoAccessToRes  // some error occurred:  no access to page
     }
	Quit accessStatus
}

ClassMethod CheckLoggedInResources(targetResources As %List) As %Integer
{
#; We call this when the target User is $Username and the target application is the current session's application.
#; Everything is set up (we're jumping to another page in the same application).
#; We just have to check if the user has proper access to the resource Targets.
	#; Resource targets is a list of resource sets which are required. 
	#; Check each set;
	#; There must be one match per set
	If $$$IOwnAllRole Quit $$$caCanAccessRes
	#Dim accessStatus,iii,resourceSet,jjj,element,resource,permission
	Set accessStatus = $$$caCanAccessRes
	For iii=1:1:$ll(targetResources) {
		Set resourceSet = $lg(targetResources,iii)
		if ( resourceSet '= "" ) {
			#; $User must have access to at least one resource in this set
			Set accessStatus = $$$caNoAccessToRes

			For jjj=1:1:$length(resourceSet,",") {
	        	Set element = $piece(resourceSet,",",jjj)
				Set resource = $piece(element,":",1)
				Set permission = $piece(element,":",2)
				If permission = "" {
			      	Set permission = "USE"
				}
				#; check if $Username has the correct permission on this resource
				If $system.Security.Check(resource,permission) {
	            	Set accessStatus = $$$caCanAccessRes
					Quit
				}
			}
		}
		if (accessStatus '= $$$caCanAccessRes ) {
			Quit
		}
	}
	Quit accessStatus
}

ClassMethod GetValidatedLink(refreshpage As %String) As %String
{
	// If it's empty or contains "://", then it's invalid
	If refreshpage="" quit ""
	
	// Do not allow javascript in url
	If $zcvt(refreshpage,"l")["javascript:"||($zcvt(refreshpage,"l")["script%3a")||($zcvt(refreshpage,"l")["script>") quit ""
	
	// Is it a URL-encoded fully qualified URL?
	If $zconvert(refreshpage,"l")["%3a%2f%2f"
	{
		Set tmp = $zconvert(refreshpage,"I","URL")
	}
	Else
	{
		Set tmp = refreshpage
	}
	
	// If it's fully qualified, just get the path part
	If tmp["://"
	{
		Do ##class(%Net.URLParser).Parse(tmp,.destination)
		If $G(destination("host"),"") '= $P($G(%request.CgiEnvs("HTTP_HOST")),":") quit ""
		If $ZCVT($G(destination("port"),""),"l") '= $ZCVT($P($G(%request.CgiEnvs("HTTP_HOST"),""),":",2),"l") quit ""
		If $G(destination("port"),"") '= $P($G(%request.CgiEnvs("HTTP_HOST"),""),":",2) quit ""
		Set tmp = $G(destination("path"),"")
	}
	
	// Convert relative URLs to absolute
	Set tmp = $zconvert($$CSPNormalizeURL^%SYS.cspServer(tmp, %request.URL),"l")

	// Now compare with application path, ignoring the actual page name
	If $extract(tmp,1,$length(%request.Application))=$zconvert(%request.Application,"l")
	{
		Quit refreshpage
	}
	
	// Try the session CookiePath
	Set tCookiePath = $zconvert($select($isobject($get(%session)): %session.CookiePath, 1: ""),"l")
	If (tCookiePath '= "") && ($extract(tmp,1,$length(tCookiePath))=tCookiePath)
	{
		Quit refreshpage
	}
	
	Quit ""
}

/// Helper method to indicate whether pages in the management portal are allowed to perform
/// automatic refreshes that poll the server.
ClassMethod %IsAutoRefreshEnabled() As %Boolean
{
	Quit ''$get(^%SYS("Portal","EnableAutoRefresh"),0)
}

ClassMethod %IsConnectivityPopupDisabled() As %Boolean [ Internal ]
{
	Quit ''$get(^%SYS("Portal","DisableConnectivityPopup"),0)
}

/// This method will retrieve the set of root directories that are visible
/// by the <Class>%ZEN.Dialog.fileSelect</Class> page. If the system is configured
/// to restrict the directories that are visible the method will return 1 (true) and
/// <b>dirs</b> will contain the set of root directories. Otherwise it will return 0 (false),
/// and all directories will be visible. 
ClassMethod GetAllowedDirectories(Output dirs) As %Boolean
{
	Kill dirs
	If '$get(^%SYS("Portal","RestrictDirs"),0) {
		Return 0
	}

	Set dir=""
	For {
		Set dir = $order(^%SYS("Portal","RestrictDirs",dir))
		If dir="" Quit

		Set dir = ##class(%File).NormalizeDirectory(dir)
		If '##class(%File).DirectoryExists(dir) Continue
		Set dirs(dir)=""
	}
	Return 1
}

/// This method will allow the given directory (and its descendants) to be visible
/// by the <Class>%ZEN.Dialog.fileSelect</Class> page. If the set of directories was 
/// previously unrestricted, and if the restriction was not explicitly disabled by 
/// calling <Method>RestrictDirectories</Method> then only this directory and its descendants 
/// will be visible. If the specified directory is invalid or does not exist, this method will
/// return 0 (false), and no change is made. 
ClassMethod AllowDirectory(dir As %String) As %Boolean
{
	Set dir = $select(dir="":"", 1:##class(%File).NormalizeDirectory(dir))
	If (dir="") || ('##class(%File).DirectoryExists(dir)) {
		Return 0
	}
	// Automatically restrict directories if this is the first dir 
	// added, and no one has explicitly forbidden it:
	If '$data(^%SYS("Portal","RestrictDirs")) {
		Do ..RestrictDirectories(1)		
	}
	Set ^%SYS("Portal","RestrictDirs",dir) = ""
	
	Set String=$$$FormatMsg($$$AuditMsg,"AllowlistAdd",dir)
	Do $SYSTEM.Security.AuditID($$$AUDITRESTRICTDIRECTORIES,String,$$$FormatMsg($$$AuditMsg,"AllowDirectory"))
	Return 1
}

/// This method will remove the given directory from the set of root directories that 
/// are visible by the <Class>%ZEN.Dialog.fileSelect</Class> page. If the given directory
/// was not previously configured as an available root directory, this will have no effect. 
ClassMethod RemoveDirectory(dir As %String)
{
	Kill ^%SYS("Portal","RestrictDirs",dir)
	Set String=$$$FormatMsg($$$AuditMsg,"AllowlistRemove",dir)
	Do $SYSTEM.Security.AuditID($$$AUDITRESTRICTDIRECTORIES,String,$$$FormatMsg($$$AuditMsg,"RemoveDirectory"))
}

/// This method will clear the set of directories that are visible by the 
/// <Class>%ZEN.Dialog.fileSelect</Class> page. After this all directories
/// available to the system will be visible in the fileSelect page.
ClassMethod ClearDirectories()
{
	Kill ^%SYS("Portal","RestrictDirs")
	Set String=$$$FormatMsg($$$AuditMsg,"Purged")
	Do $SYSTEM.Security.AuditID($$$AUDITRESTRICTDIRECTORIES,String,$$$FormatMsg($$$AuditMsg,"ClearDirectories"))
}

/// If <b>flag</b> is true then the <Class>%ZEN.Dialog.fileSelect</Class> page will only 
/// allow navigation to the set of directories configured by <Method>AddDirectory</Method>. 
/// If no directories are configured, then the fileSelect page will
/// not display any files.<br>
/// If <b>flag</b> is false, then the fileSelect page will allow navigation to all files. 
/// The set of directories configured by <Method>AddDirectory</Method> (if any) is not removed.
/// Return 1 (true) if we were previously configured to use restricted directories, 0 (false) otherwise.
ClassMethod RestrictDirectories(flag As %Boolean) As %Boolean
{
	Set oldvalue = $get(^%SYS("Portal","RestrictDirs"),0)
	Set ^%SYS("Portal","RestrictDirs")=(flag>0)
	Set String=$$$FormatMsg($$$AuditMsg,"OldValue",oldvalue)_$c(13,10)
	Set String=String_$$$FormatMsg($$$AuditMsg,"NewValue",(flag>0))_$c(13,10)
	Do $SYSTEM.Security.AuditID($$$AUDITRESTRICTDIRECTORIES,String,$$$FormatMsg($$$AuditMsg,"RestrictDirectories"))
	Return oldvalue
}

/// This method will allow <Class>%CSP.UI.Dialog.Import</class> to validate an import path
/// Return 0 (false) if directories are restricted and <b>dirs</b> is not found in set of 
/// root directories that are visible by the <Class>%ZEN.Dialog.fileSelect</Class> page. 
/// Return 1 (true) if <b>dirs</b> is an allowed root directory 
/// or if <b>dirs</b> is a subdirectory of an allowed root directory 
/// or if directories are not restricted
ClassMethod IsDirectoryAllowed(dir As %String) As %Boolean
{
	Set dir = $select(dir="":"", 1:##class(%File).NormalizeDirectory(dir))
	If (dir="") || ('##class(%File).DirectoryExists(dir)) {
		Return 0
	}
	
	Set hasRestrictDirs = ##class(%CSP.Portal.Utils).GetAllowedDirectories(.restrictDirs)
	If 'hasRestrictDirs Return 1 // no directory restrictions, so all dirs allowed
	If $data(restrictDirs(dir)) Return 1 // found dir in allowed root directories

	// dir is not in root directories and allowlist is not empty
	// search if dir is in a subdirectory of the root directories
	Set root=""
	While ($ORDER(restrictDirs(root))'="") {
		Set root = $ORDER(restrictDirs(root))
		If $EXTRACT(dir,1,$LENGTH(root))=root {
			// dir is a subdirectory for a root directory found in allowlist
			Return 1
		}
	}
	// dir was not found to be a subdirectory for any element of allowlist
	Return 0
}

}
