/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%DeepSee, %products)

/// APIs used by the UserPortal.
Class %DeepSee.UserPortal.Utils Extends %RegisteredObject [ Abstract, System = 4 ]
{

Parameter DOMAIN = "%DeepSee";

/// Return the URL for the user portal home page.
ClassMethod %GetUserHomePageURL() As %String
{
	Quit "_DeepSee.UserPortal.Home.zen"
}

/// Return the URL for the dashboard viewer.
ClassMethod %GetViewerURL() As %String
{
	Quit "_DeepSee.UserPortal.DashboardViewer.zen"
}

/// Return the URL for the user portal error page.
ClassMethod %GetErrorPageURL(pError As %String) As %String
{
	Quit "_DeepSee.UserPortal.ErrorPage.zen?ERROR="_$ZCVT(pError,"O","URL")
}

/// Return an array containing the system preferences for the portal.
ClassMethod %GetPreferences(Output pPrefs) As %Status
{
	Set pPrefs("Scheme") = $G(^DeepSee.UserPortalSettings("Scheme"),"simple")
	Set pPrefs("CompanyImage") = $G(^DeepSee.UserPortalSettings("CompanyImage"))
	Set pPrefs("CompanyName") = $G(^DeepSee.UserPortalSettings("CompanyName"),"InterSystems IRIS")
	Set pPrefs("CompanyNameStyle") = $G(^DeepSee.UserPortalSettings("CompanyNameStyle"))
	Set pPrefs("CompanyLink") = $G(^DeepSee.UserPortalSettings("CompanyLink"))
	Set pPrefs("ChartSeriesScheme") = $G(^DeepSee.UserPortalSettings("ChartSeriesScheme"))
	Quit $$$OK
}

/// Return the name of the current user (or given user name).
/// Return their full name if registered, otherwise return the login name.
ClassMethod %GetUserName(pUserName As %String = "") As %String
{
	Set tUserName = pUserName
	Set:tUserName="" tUserName = $UserName
	Set tUser = ##class(%DeepSee.UserPortal.Data.User).%OpenId(tUserName)
	If $IsObject(tUser) {
		Set tName = $ZSTRIP(tUser.fullName,"<>W")
		Set:tName'="" tUserName = tName
	}
	Quit tUserName
}

/// Return a list of DeepSee users.<br/>
/// pUsers(n) = $LB(id,name,icon)<br/>
/// If <var>pAlertsEnabled</var> is true, then only return users that have enabled alerts.
ClassMethod %GetUserList(Output pUsers, pSearchKey As %String = "", pAlertsEnabled As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tFlag = $zu(115,8,0)
		Set pNewCount = 0
		Kill pUsers
		Set pSearchKey = $$$UPPER(pSearchKey)

		// first build list local list of users
		Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
		If (pAlertsEnabled) {
			Set tSC = tStatement.%Prepare("SELECT userId,fullName FROM %DeepSee_UserPortal_Data.UserName WHERE alertsEnabled = 1 ORDER BY fullName")
		}
		Else {
			Set tSC = tStatement.%Prepare("SELECT userId,fullName FROM %DeepSee_UserPortal_Data.UserName ORDER BY fullName")
		}
		If $$$ISERR(tSC) Quit

		Set n = 0
		Set tRS = tStatement.%Execute()
		While (tRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			Set n = n + 1
			Set tName = tRS.fullName
			Set:tName="" tName = tRS.userId
			Set tNameU = $$$UPPER(tName)
			If ((pSearchKey="")||(tNameU[pSearchKey)) {
				Set tList(tNameU,n) = $LB(tRS.userId,tName)
			}
		}
		If $$$ISERR(tSC) Quit

		// now sort and return
		Set k = $O(tList(""))
		While (k'="") {
			Set n = $O(tList(k,""))
			While (n'="") {
				Set pUsers($I(i)) = tList(k,n)
				Set n = $O(tList(k,n))
			}
			Set k = $O(tList(k))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Set tFlag = $zu(115,8,tFlag)
	Quit tSC
}

/// Return the current alerts list for the current user:
/// pAlerts(n) = $LB(alertId,from,subject,date,url,priority,icon,iconTip)
ClassMethod %GetAlertsForUser(Output pAlerts, Output pNewCount As %Integer, pMaxItems As %Integer = 25) As %Status
{
	Set tSC = $$$OK
	Set pNewCount = 0
	Kill pAlerts

	Set tNewIcon = "deepsee/ds2_note_44.png"

	Set SQLCODE = 0
	Set (tAlertId,tSenderId,tCreateDate,tSubject,tIsNew,tPriority,tDataId) = ""
	Set tUserId = $UserName

	&sql(DECLARE sql1 CURSOR FOR
		SELECT %ID,senderId,createDate,subject,isNew,priority,comments,dataId
		INTO :tAlertId,:tSenderId,:tCreateDate,:tSubject,:tIsNew,:tPriority,:tComments,:tDataId
		FROM %DeepSee_UserPortal_Data.Alert
		WHERE userId = :tUserId
	)
	&sql(OPEN sql1)
	if SQLCODE<0 q $$$ERROR($$$SQLError,SQLCODE,$g(%msg)) 
	
	Set n = 0
	&sql(FETCH sql1)
	While (SQLCODE = 0) {
		Set n = n + 1
		If ((pMaxItems'="")&&(n > pMaxItems)) {
			Quit
		}
		// lookup up sender name
		Set tSenderName = tSenderId
		Set tUser = ##class(%DeepSee.UserPortal.Data.User).%OpenId(tSenderId)
		If $IsObject(tUser) {
			Set tSenderName = tUser.fullName
			Set:tSenderName="" tSenderName = tUser.userId
		}
		Set tURL = ""
		If (tDataId'="") {
			Set tURL=##class(%DeepSee.UserPortal.Utils).%GetViewerURL()_"?DASHBOARD="_$ZCVT(tDataId,"O","URL")_"&ALERT="_$ZCVT(tAlertId,"O","URL")
		}

		If (tIsNew) {
			Set pNewCount = pNewCount + 1
			Set pAlerts(n) = $LB(tAlertId,tSenderName,tSubject,tCreateDate,tURL,tPriority,tNewIcon,$$$Text("New item"))
		}
		Else {
			Set pAlerts(n) = $LB(tAlertId,tSenderName,tSubject,tCreateDate,tURL,tPriority)
		}
		&sql(FETCH sql1)
	}
	if SQLCODE<0 s tSC=$$$ADDSC(tSC,$$$ERROR($$$SQLError,SQLCODE,$g(%msg)))
	&sql(CLOSE sql1)
	if SQLCODE<0 s tSC=$$$ADDSC(tSC,$$$ERROR($$$SQLError,SQLCODE,$g(%msg)))
	Quit tSC
}

/// Return the current favorites list for the current user:
/// pItems(n) = $LB(fullName,name,folder,title,type,icon,date,url)
ClassMethod %GetFavoritesForUser(Output pFavorites) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pNewCount = 0
		Kill pFavorites

		Set tSC = ##class(%DeepSee.UserLibrary.Utils).%GetFavoriteList(.tItems)
		If $$$ISERR(tSC) Quit
	
		Set n = 0
		Set k = $O(tItems(""))
		While (k'="") {
			Set tItem = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(k)
			If '$IsObject(tItem) {
				Set tSC = ##class(%DeepSee.UserLibrary.Utils).%RemoveFavorite(k)
				If $$$ISERR(tSC) Quit
			}
			Else {
				Set n = n + 1
				Set tIcon = tItem.%GetLargeIcon()
				Set tDate = tItem.timeModified
				Set tType = tItem.%GetTypeName()
				Set tURL = tItem.%GetURL()
				Set tShortName = $S(tItem.title'="":tItem.title,1:tItem.name)
				Set tTip = tItem.description
				Set:tTip="" tTip = $S(tItem.title'="":tItem.title,1:tItem.name)
				Set tFolder = tItem.folder.fullName
				Set:tShortName["$$$" tShortName = ##class(%DeepSee.UserPortal.Utils).%ResolveText($TR(tShortName,"#","/"))
				Set:tTip["$$$" tTip = ##class(%DeepSee.UserPortal.Utils).%ResolveText($TR(tTip,"#","/"))
				Set pFavorites(n) = $LB(tItem.fullName,tShortName,tFolder,tTip,tType,tIcon,tDate,tURL)
			}
			Set k = $O(tItems(k))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the recent items list for the current user:
/// pItems(n) = $LB(fullName,name,folder,title,type,icon,date,url)
ClassMethod %GetRecentItemsForUser(Output pItems) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pNewCount = 0
		Kill pItems

		Set tSC = ##class(%DeepSee.UserLibrary.Utils).%GetRecentItemList(.tItems)
		If $$$ISERR(tSC) Quit
	
		Set n = 0
		Set k = $O(tItems(""))
		While (k'="") {
			Set tName = tItems(k)
			Set tExt = $P(tName,".",$L(tName,"."))
			If (tExt'="") {
				Set tItem = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tName)
				If '$IsObject(tItem) {
					Set tSC = ##class(%DeepSee.UserLibrary.Utils).%RemoveRecentItem(tName)
					If $$$ISERR(tSC) Quit
				}
				Else {
					Set n = n + 1
					Set tIcon = tItem.%GetLargeIcon()
					Set tDate = $P(k,"?",1)
					Set tType = tItem.%GetTypeName()
					Set tURL = tItem.%GetURL()
					Set tShortName = $S(tItem.title'="":tItem.title,1:tItem.name)
					Set tTip = tItem.description
					Set:tTip="" tTip = $S(tItem.title'="":tItem.title,1:tItem.name)
					Set tFolder = tItem.folder.fullName
					Set:tShortName["$$$" tShortName = ##class(%DeepSee.UserPortal.Utils).%ResolveText($TR(tShortName,"#","/"))
					Set:tTip["$$$" tTip = ##class(%DeepSee.UserPortal.Utils).%ResolveText($TR(tTip,"#","/"))

					Set pItems(n) = $LB(tItem.fullName,tShortName,tFolder,tTip,tType,tIcon,tDate,tURL)
				}
			}
			Set k = $O(tItems(k))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Format a $H value.
ClassMethod %FormatDate(pDate As %String, pUTCtoLocal As %Boolean = 0) As %String
{
	Set tDate = ""
	Try {
		If (pDate="") Quit
		// test if pDate is in xDBC format
		Set tTest = $ZDTH(pDate,3,,,,,,,,"x")
		If (tTest'="x") {
			Set pDate = tTest
		}
		Set:pUTCtoLocal pDate = $ZDTH(pDate,-3)

		Set tH = $H
		Set tTime = $S($P(pDate,",",2)="":"",1:$P($ZDT(pDate,11)," ",2))

		If (+pDate=+tH) {
			If (tTime="") {
				Set tDate = $$$Text("Today","%DeepSee")
			}
			Else {
				Set tDate = $$$FormatText($$$Text("Today at %1","%DeepSee"),tTime)
			}
		}
		ElseIf (+pDate=(+tH-1)) {
			If (tTime="") {
				Set tDate = $$$Text("Yesterday","%DeepSee")
			}
			Else {
				Set tDate = $$$FormatText($$$Text("Yesterday at %1","%DeepSee"),tTime)
			}
		}
		Else {
			Set tDate = $ZDT(pDate)
		}
	}
	Catch(ex) {
		Set tDate = ""
	}
	Quit tDate
}

/// Return a list of folder items for the current user:<br/>
/// pItems(n) = $LB(name,type,tip,date,url,icon,keywords,public,title,createdBy,resource,cover,category,owner,write,lastAccessed)<br/>
/// This list is returned in ID order; the caller will sort it.
/// If <var>pShowAll</var> is true, list items for all users.
ClassMethod %GetFolderItemsForUser(Output pItems, pFolderName As %String, pSearchKey As %String = "", pIncludePrivate As %Boolean = 0, pShowAll As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pItems

		Set tSC = ##class(%DeepSee.UserLibrary.Utils).%GetFolderItemList(.tItemIDs,,pShowAll)
		If $$$ISERR(tSC) Quit

		Set n = 0
		Set k = $O(tItemIDs(""))
		While (k'="") {
			Set tSkip = 0
			Set tID = tItemIDs(k)
			Set tItem = ##class(%DeepSee.UserLibrary.FolderItem).%OpenId(tID)

			Set tFID = tItem.folderGetObjectId()
			If (tFID'="") {
				// test if folder exists
				If ('##class(%DeepSee.UserLibrary.Folder).%ExistsId(tFID)) {
					// orphaned item
					Set tSkip = 1
				}
			}
			
			If ('tSkip && (pShowAll || pIncludePrivate || tItem.public || (tItem.public=""))) {
				Set tFName = $P(tItem.folderName,"/",1)
				If (pShowAll || ($E(tFName,1)'="$")|| ($E(tFName,1,3)="$$$")) {
					Set n = n + 1
					// $LB(name,type,tip,date,url,icon,keywords,public,title,createdBy,resource,cover,category,owner,write,lastAccessed)
					Set tTip = ..%ResolveText(tItem.description)
					Set:tTip="" tTip = ..%ResolveText(tItem.title)
					Set:tTip="" tTip = tItem.name
					Set tCoverSpec = tItem.%GetCoverSpec()
					Set tCategory = ..%ResolveText(tItem.category)
					Set pItems(n) = $LB(tItem.fullName,tItem.%GetTypeName(),tTip,tItem.timeModified,tItem.%GetURL(),tItem.%GetIcon(),..%ResolveTextList(tItem.keywords),tItem.public,..%ResolveText(tItem.title),tItem.createdBy,tItem.%GetResource(),tCoverSpec,tCategory,tItem.owner,tItem.%CheckResource("WRITE"),tItem.lastAccessed)
				}
			}
			Set k = $O(tItemIDs(k))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get the values of any SETTINGS parameters within the current URL and pull them apart.
/// A dashboard URL may contain any number of parameters called SETTINGS. Each takes the form:<br/>
/// SETTINGS=parm:value;parm:value;<br/>
/// Supported parameters and values include:<br/>
/// 
/// TARGET:widgetName;  ("*" if not specified)<br/>
/// FILTER:spec;<br/>
/// VARIABLE:pivotVar; (default value for pivot variable)<br/>
/// ROWCOUNT:#;<br/>
/// COLCOUNT:#;<br/>
/// ROWSORT:Measure;<br/>
/// COLSORT:Measure;<br/>
/// ROWSORTDIR:ASC|DESC;<br/>
/// COLSORTDIR:ASC|DESC;<br/>
/// <br/>
/// For some items, such as FILTER, there can be multiple values separated by ~<br/>
/// <br/>
/// ;; is an escape for ";"<br/>
/// ~~ is an escape for "~"<br/>
/// <br/>
/// A FILTER spec is of the form:<br/>
/// Name.Value or [Name].[Value], [Name].&[Value]<br/>
/// For an MDX-based filter, Name may have multiple pieces:<br/>
/// [DIM].[Hier].[Level].[Value]<br/>
/// 
/// A VARIABLE (pivot variable) spec is of the form:<br/>
/// VarName.Value<br/>
/// 
/// On return, <var>pSettings</var> will contain:<br/>
/// pSettings(target,parm) = "value"</br>
///  
ClassMethod %GetSettingsFromURL(Output pSettings) As %Status
{
	Set tSC = $$$OK
	Try {
		// Pull values from URL
		Set n = $O(%request.Data("SETTINGS",""))
		While (n'="") {
			Set tSetting = $G(%request.Data("SETTINGS",n))
			Set tSetting = $Replace(tSetting,";;",$C(1))
			// keep ~~ in place

			For p = 1:1:$L(tSetting,";") {
				Set tName = $P($P(tSetting,";",p),":",1)
				Set tValue = $P($P(tSetting,";",p),":",2,9999)
				Set tName = $TR(tName,$C(1),";")
				Set tValue = $TR(tValue,$C(1),";")
				If ((tName'="")&&(tValue'="")) {
					Set tOptions(n,tName) = tValue
				}
			}
			Set n = $O(%request.Data("SETTINGS",n))
		}

		// Copy value to pSettings
		Set n = $O(tOptions(""))
		While (n'="") {
			Set tTarget = $G(tOptions(n,"TARGET"))
			Set:tTarget="" tTarget = "*"

			Set tName = $O(tOptions(n,""))
			While (tName'="") {
				If (tName'="TARGET") {
					Set pSettings(tTarget,tName) = tOptions(n,tName)
				}
				Set tName = $O(tOptions(n,tName))
			}
			Set n = $O(tOptions(n))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Register a DeepSee user.
ClassMethod %RegisterUser(pUserId As %String, pUserName As %String = "", pEMail As %String = "", pEnabled As %Boolean = 1) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tUser = ##class(%DeepSee.UserPortal.Data.User).%OpenId(pUserId)
		If '$IsObject(tUser) {
			Set tUser = ##class(%DeepSee.UserPortal.Data.User).%New()
			Set tUser.userId = pUserId
		}
		Set tUser.fullName = pUserName
		Set tUser.email = pEMail
		Set tUser.alertsEnabled = pEnabled

		Set tSC = tUser.%Save()
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Send a new alert.
ClassMethod %SendAlert(pAlert As %DeepSee.UserPortal.Data.Alert) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = pAlert.%Save()
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Delete the given alert.
ClassMethod %DeleteAlert(pAlertId As %String) As %Status
{
	Quit ##class(%DeepSee.UserPortal.Data.Alert).%DeleteId(pAlertId)
}

/// Delete all alerts in this namespace.
ClassMethod %KillAlerts() As %Status
{
	Quit ##class(%DeepSee.UserPortal.Data.Alert).%KillExtent()
}

/// Delete the current user settings for the current namespace.
ClassMethod %ClearUserSettings() As %Status
{
	Kill ^DeepSee.User.Settings
	Quit $$$OK
}

/// Delete the given user setting for the current namespace.
ClassMethod %RemoveUserSetting(pName As %String) As %Status
{
	Kill ^DeepSee.User.Settings(pName)
	Quit $$$OK
}

/// Return a list of the current user settings in the form:
/// pData(n) = $LB(name,value,comment,context)
ClassMethod %GetUserSettingsList(Output pData, pContext As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pData
		Set tName = $O(^DeepSee.User.Settings(""))
		While (tName '= "") {
			Set tValue = $G(^DeepSee.User.Settings(tName,"value"))
			Set tComment = $G(^DeepSee.User.Settings(tName,"comment"))
			Set tContext = $G(^DeepSee.User.Settings(tName,"context"))
			If ((pContext="")||(tContext="")||(tContext=pContext)) {
				Set pData($I(n)) = $LB(tName,tValue,tComment,tContext)
			}
			Set tName = $O(^DeepSee.User.Settings(tName))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Set the value and comment for the given user-defined setting.<br/>
/// <var>pName</var> is the name of the setting. This must be unique.<br/>
/// <var>pValue</var> is the value of the setting. This is in ObjectScript expression that is evaluated at run-time.<br/>
/// <var>pComment</var> is a comment.<br/>
/// <var>pContext</var> is the name of the context in which this setting is expected to be used. This allows the user to be presented with a limited set of settings.<br/>
ClassMethod %SetUserSetting(pName As %String, pValue As %String, pComment As %String = "", pContext As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		If (pName '= "") {
			Set ^DeepSee.User.Settings(pName,"value") = pValue
			Set ^DeepSee.User.Settings(pName,"comment") = pComment
			Set ^DeepSee.User.Settings(pName,"context") = pContext
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get the value of the given user-defined setting.
/// A user-setting is an expression. This method evaluates the expression and returns the result.
ClassMethod %GetUserSetting(pName As %String, Output pSC As %Status) As %String
{
	Set pSC = $$$OK
	Set tValue = ""
	Try {
		Set tExpr = $G(^DeepSee.User.Settings(pName,"value"))
		If (tExpr'="") {
			New %out
			X "Set %out="_tExpr
			Set tValue = $G(%out)
		}
	}
	Catch(ex) {
		Set tValue = ""
		Set pSC = ex.AsStatus()
	}
	Quit tValue
}

/// Delete the current user icons for the current namespace.
ClassMethod %ClearUserIcons() As %Status
{
	Kill ^DeepSee.User.Icons
	Quit $$$OK
}

/// Delete the given user icon for the current namespace.
ClassMethod %RemoveUserIcon(pName As %String) As %Status
{
	Kill ^DeepSee.User.Icons(pName)
	Quit $$$OK
}

/// Return a list of the current user icons in the form:
/// pData(n) = $LB(name,path)
ClassMethod %GetUserIconList(Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pData
		Set tName = $O(^DeepSee.User.Icons(""))
		While (tName '= "") {
			Set tPath = $G(^DeepSee.User.Icons(tName))
			Set pData($I(n)) = $LB(tName,tPath)
			Set tName = $O(^DeepSee.User.Icons(tName))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Set the path for the given user-defined icon.<br/>
/// <var>pName</var> is the name of the icon. This must be unique.<br/>
/// <var>pValue</var> is the path for the icon.<br/>
ClassMethod %SetUserIcon(pName As %String, pPath As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		If (pName '= "") {
			Set ^DeepSee.User.Icons(pName) = pPath
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get the path of the given user-defined icon.
ClassMethod %GetUserIcon(pName As %String, Output pSC As %Status) As %String
{
	Set pSC = $$$OK
	Set tPath = ""
	Try {
		Set tPath = $G(^DeepSee.User.Icons(pName))
	}
	Catch(ex) {
		Set tPath = ""
		Set pSC = ex.AsStatus()
	}
	Quit tPath
}

/// Clear dashboard settings for the given dashboard (If <var>pUser</var> is "", then for all users).
ClassMethod %ClearDashboardSettings(pDashboard As %String, pUser As %String = "", pSaveLocalDataSource As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		// JMD1074
		If (pSaveLocalDataSource) {
			Set tUser = $O(^DeepSee.DashboardSettings(pDashboard,""))
			While (tUser'="") {
				If ((pUser="")||(tUser=pUser)) {
					Set tKey = $O(^DeepSee.DashboardSettings(pDashboard,tUser,""))
					While (tKey'="") {
						// JMD1128 add $G
						Set tLocal = $G(^DeepSee.DashboardSettings(pDashboard,tUser,tKey,"localDataSource"))
						If (tLocal'="") {
							Set tOldValues(tUser,tKey,"localDataSource") = tLocal
						}
						Set tKey = $O(^DeepSee.DashboardSettings(pDashboard,tUser,tKey))
					}
				}
				Set tUser = $O(^DeepSee.DashboardSettings(pDashboard,tUser))
			}
		}

		If (pUser="") {
			Kill ^DeepSee.DashboardSettings(pDashboard)
		}
		Else {
			Kill ^DeepSee.DashboardSettings(pDashboard,pUser)
		}

		If (pSaveLocalDataSource) {
			Merge ^DeepSee.DashboardSettings(pDashboard) = tOldValues
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Clear the localDataSource for a specific user and widget.
ClassMethod %ClearLocalDataSource(pDashboard As %String, pWidgetKey As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		// JMD1413
		Set tUser = $UserName
		Kill ^DeepSee.DashboardSettings(pDashboard,tUser,pWidgetKey,"localDataSource")
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// A dashboard setting is a set of name/value pairs saved for a specific
/// dashboard and user. This lets the user save filters values, positions, etc.
ClassMethod %SaveDashboardSettings(ByRef pSettings As %String, pDashboard As %String, pUser As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Set:pUser="" pUser = $UserName
		Kill ^DeepSee.DashboardSettings(pDashboard,pUser)
		Merge ^DeepSee.DashboardSettings(pDashboard,pUser) = pSettings
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// A dashboard setting is a set of name/value pairs saved for a specific
/// dashboard and user. This lets the user save filters values, positions, etc.
ClassMethod %LoadDashboardSettings(Output pSettings As %String, pDashboard As %String, pUser As %String = "") As %String
{
	Set tSC = $$$OK
	Try {
		Kill pSettings
		Set:pUser="" pUser = $UserName
		Merge pSettings = ^DeepSee.DashboardSettings(pDashboard,pUser)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Print a list of all folder items to the console.<br/>
ClassMethod %ListFolderItems(pSearchKey As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Set tFolder = ""
		Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetFolderItemsForUser(.tList,tFolder,pSearchKey,1,1)
		If $$$ISERR(tSC) Quit

		Write "Folder Items",!
		Write "----------------------------------------",!
		Set k = $O(tList(""))
		While (k'="") {
			Set tName = $LG(tList(k),1)
			Set tType = $LG(tList(k),2)
			Write "* ",$E(tName,1,50),$S($L(tName)>50:"...",1:"")
			Write ?60,tType
			Write !
			Set k = $O(tList(k))
		}

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// For the given folder item, <var>pName</var>, return a list of other items it depends upon.
ClassMethod %FindDependencies(pName As %String, Output pList As %String, pVerbose As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pList
		Set tItem = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pName)
		If $IsObject(tItem) {
			Set tSC = tItem.%GetDependencies(.pList)
			If $$$ISERR(tSC) Quit
		}
		Else {
			If (pVerbose) {
				Write !,pName," does not exist or cannot be opened.",!
			}
		}
		
		If (pVerbose) {
			If $D(pList) {
				Write !,pName," depends on the following items:",!
				Write "----------------------------------------",!
				Set tID = $O(pList(""))
				While (tID'="") {
					Write "* ",pList(tID),!
					Set tID = $O(pList(tID))
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// For the given folder item, <var>pName</var>, return a list of other items that use it.
/// This method does a full scan of all dashboard items, so use sparingly.
ClassMethod %FindIsUsedBy(pName As %String, Output pList As %String, pVerbose As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pList

		Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetFolderItemsForUser(.tList,"","",1,1)
		If $$$ISERR(tSC) Quit

		Set k = $O(tList(""))
		While (k'="") {
			Set tName = $LG(tList(k),1)
			Set tItem = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tName)
			If $IsObject(tItem) {
				// !!! do not recurse??
				Kill tDepList
				Set tSC = tItem.%GetDependencies(.tDepList)
				If $$$ISERR(tSC) Quit
				
				If $D(tDepList($$$UPPER(pName))) {
					// add to list
					Set pList($$$UPPER(tItem.fullName)) = tItem.fullName
				}
			}
			If $$$ISERR(tSC) Quit
			Set k = $O(tList(k))
		}

		If (pVerbose) {
			If $D(pList) {
				Write !,pName," is used by the following items:",!
				Write "----------------------------------------",!
				Set tID = $O(pList(""))
				While (tID'="") {
					Write "* ",pList(tID),!
					Set tID = $O(pList(tID))
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return an array the list of defined dashboard color schemes:
/// pScheme(n) = $LB(name,caption,jsFile,cssFile)
ClassMethod %GetColorSchemes(Output pScheme) As %Status
{
	Kill pScheme
	Set pScheme($I(n)) = $LB("simple",$$$Text("Simple"),"skin_simple.js","skin_simple.css")
	Set pScheme($I(n)) = $LB("bluechip",$$$Text("Bluechip"),"skin_bluechip.js","skin_bluechip.css")
	Set pScheme($I(n)) = $LB("chrome",$$$Text("Chrome"),"skin_chrome.js","skin_chrome.css")
	Set pScheme($I(n)) = $LB("contemporary",$$$Text("Contemporary"),"skin_contemporary.js","skin_contemporary.css")
	Set pScheme($I(n)) = $LB("mba",$$$Text("MBA"),"skin_mba.js","skin_mba.css")
	Set pScheme($I(n)) = $LB("roswell",$$$Text("Roswell"),"skin_roswell.js","skin_roswell.css")

	// merge in user-extensions
	// ^DeepSee.UserPortalSchemes(n) = $LB(name,caption,jsFile,cssFile)
	Set k = $O(^DeepSee.UserPortalSchemes(""))
	While (k'="") {
		Set pScheme($I(n)) = $G(^DeepSee.UserPortalSchemes(k))
		Set k = $O(^DeepSee.UserPortalSchemes(k))
	}
	Quit $$$OK
}

/// Find info on the given dashboard color scheme.
ClassMethod %GetColorSchemeInfo(pScheme As %String, Output pInfo) As %Status
{
	Set tSC = ..%GetColorSchemes(.tList)
	Set tIndex = 1
	Set k = $O(tList(""))
	While (k'="") {
		If ($LG(tList(k),1)=$$$LOWER(pScheme)) {
			Set tIndex = k
			Quit
		}
		Set k = $O(tList(k))
	}
	Set pInfo("js") = $LG($G(tList(tIndex)),3)
	Set pInfo("css") = $LG($G(tList(tIndex)),4)
	Quit tSC
}

/// Return an array of the defined chart series color schemes:
/// pScheme(n) = $LB(name,caption,[colorList])
ClassMethod %GetChartSeriesSchemes(Output pScheme) As %Status
{
	Kill pScheme
	// built-in list
	Set pScheme($I(n)) = $LB("",$$$Text("Default"))
	Set pScheme($I(n)) = $LB("urban",$$$Text("Urban"))
	Set pScheme($I(n)) = $LB("tuscan",$$$Text("Tuscan"))
	Set pScheme($I(n)) = $LB("caribbean",$$$Text("Caribbean"))
	Set pScheme($I(n)) = $LB("rustbelt",$$$Text("Rustbelt"))
	Set pScheme($I(n)) = $LB("bright",$$$Text("Bright"))
	// Set pScheme($I(n)) = $LB("glow",$$$Text("Glow"))
	Set pScheme($I(n)) = $LB("gray",$$$Text("Gray"))
	Set pScheme($I(n)) = $LB("pastel",$$$Text("Pastel"))
	Set pScheme($I(n)) = $LB("solid",$$$Text("Solid"))

	// merge in user-extensions
	// ^DeepSee.UserPortalSeriesColors(n) = $LB(name,caption,colorList)
	Set k = $O(^DeepSee.UserPortalSeriesColors(""))
	While (k'="") {
		Set pScheme($I(n)) = $G(^DeepSee.UserPortalSeriesColors(k))
		Set k = $O(^DeepSee.UserPortalSeriesColors(k))
	}
	Quit $$$OK
}

/// Find info on the given chart series color scheme.
ClassMethod %GetChartSeriesSchemeInfo(pScheme As %String, Output pSchemeName, Output pColorList) As %Status
{
	Set pSchemeName=""
	Set pColorList=""
	Set tSC = ..%GetChartSeriesSchemes(.tList)
	Set k = $O(tList(""))
	While (k'="") {
		If ($LG(tList(k),1)=$$$LOWER(pScheme)) {
			Set pSchemeName = $LG($G(tList(k)),1)
			Set pColorList = $LG($G(tList(k)),3)
			Quit
		}
		Set k = $O(tList(k))
	}
	Quit tSC
}

/// Return an array of the defined color sets.
/// A color set is a name list of up to 256 colors used by a color picker.
/// pSet(n) = $LB(name,caption,;-delimited list of colors)
ClassMethod %GetColorSets(Output pSet) As %Status
{
	Kill pSet

	// deepsee
	Set tColors = ""
	Set tColors = tColors_"rgb(231,192,80);rgb(210,156,80);rgb(56,85,47);rgb(56,57,45);rgb(55,42,15);rgb(164,57,39);rgb(190,226,250);rgb(226,226,199);"
	Set tColors = tColors_"rgb(71,89,104);rgb(169,141,109);rgb(156,152,142);rgb(91,89,83);rgb(43,59,64);rgb(71,89,83);rgb(127,136,126);rgb(192,204,173);"
	Set tColors = tColors_"rgb(0,167,153);rgb(0,220,216);rgb(0,185,255);rgb(0,91,102);rgb(0,80,35);rgb(127,166,69);rgb(255,245,199);rgb(230,199,145);"
	Set tColors = tColors_"rgb(156,51,11);rgb(110,11,0);rgb(41,41,42);rgb(62,49,46);rgb(109,109,111);rgb(156,157,156);rgb(208,208,207);"
	Set tColors = tColors_"rgb(10,92,116);rgb(136,50,10);rgb(100,108,108);rgb(47,60,53);rgb(216,215,175);rgb(107,163,161);rgb(54,30,8);rgb(90,63,20);"
	Set tColors = tColors_"rgb(220,88,0);rgb(38,62,86);rgb(57,79,36);rgb(57,81,106);rgb(0,75,152);rgb(218,129,61);rgb(92,142,43);rgb(200,60,0);"
	Set tColors = tColors_"rgb(50,50,28);rgb(103,118,89);rgb(123,161,161);rgb(56,145,234);rgb(63,63,35);rgb(130,44,0);rgb(171,12,0);"
	Set tColors = tColors_"rgb(251,200,120);rgb(63,119,7);rgb(107,116,116);rgb(133,133,124);rgb(95,119,144);rgb(80,122,164);rgb(103,127,80);rgb(209,29,0);rgb(123,0,0);rgb(15,39,64);"

	Set pSet($I(pSet)) = $LB("deepsee",$$$PRODUCT1,tColors)

	// standard
	Set pSet($I(pSet)) = $LB("",$$$Text("Standard"))

	// computed sets
	// gray
	Set tColors = ""
	For n = 1:1:64 {
		Set v = (n-1)*4
		Set $P(tColors,";",n) = "rgb("_v_","_v_","_v_")"
	}
	Set pSet($I(pSet)) = $LB("gray",$$$Text("Gray House"),tColors)

	// blue
	Set tColors = ""
	For n = 1:1:64 {
		Set v = (n-1)*4
		Set $P(tColors,";",n) = "rgb(0,0,"_v_")"
	}
	Set pSet($I(pSet)) = $LB("blue",$$$Text("Blue Period"),tColors)

	// red
	Set tColors = ""
	For n = 1:1:64 {
		Set v = (n-1)*4
		Set $P(tColors,";",n) = "rgb("_v_",0,0)"
	}
	Set pSet($I(pSet)) = $LB("red",$$$Text("Red Zone"),tColors)

	// other sets
	Set tColors = "aqua;black;blue;fuchsia;gray;grey;green;lime;maroon;navy;olive;purple;red;silver;teal;white;yellow;"
	Set tColors = tColors_"chocolate;azure;chartreuse;crimson;gold;indigo;mediumpurple;palegreen;papayawhip;peru;moccasin;"
	Set tColors = tColors_"skyblue;powderblue;seashell;tomato;"
	Set pSet($I(pSet)) = $LB("carnival",$$$Text("Carnival"),tColors)

	// merge in user-extensions
	// ^DeepSee.UserPortalColorSets(n) = $LB(name,caption,colorList)
	Set k = $O(^DeepSee.UserPortalColorSets(""))
	While (k'="") {
		Set pSet($I(pSet)) = $G(^DeepSee.UserPortalColorSets(k))
		Set k = $O(^DeepSee.UserPortalColorSets(k))
	}
	Quit $$$OK
}

/// Resolve a csv-list of localized text strings at run time.
ClassMethod %ResolveTextList(pText As %String) As %String
{
	Quit:pText'["$$$" pText

	Set tText = ""
	For n=1:1:$L(pText,",") {
		Set p = $P(pText,",",n)
		Set $P(tText,",",n) = ..%ResolveText(p)
	}
	Quit tText
}

/// Resolve a localized text string at run time.
/// A localized string can take the following forms:<br/>
/// "String" -- not localized.<br/>
/// "$$$String" -- equivalent to $$$Text("String","DeepSeeUser")<br/>
/// "$$$String/Domain" -- equivalent to $$$Text("String","Domain")<br/>
ClassMethod %ResolveText(pText As %String) As %String
{
	Quit:$E(pText,1,3)'="$$$" pText

	// pull apart text
	Set pText = $E(pText,4,*)
	Quit:pText="" "$$$"
	Set tKey = $P(pText,"/")
	Set tDomain = $P(pText,"/",2,999)
	Set:tDomain="" tDomain = "DeepSeeUser"
	If ($E(tKey)="@") {
		Set tTextId = $E(tKey,2,*)
	}
	Else {
		Set tTextId = $ZCRC(tKey,7)
	}
	Set tLang = ##class(%DeepSee.Query.query).%GetLanguage()

	// look up string in localization global
	Quit $G(^IRIS.Msg(tDomain,tLang,tTextId),tKey)
}

ClassMethod %ResolveName(pName) As %String
{
	/*
		pName must be of the form: 
			$$$A#Domain/$$$B#Domain/$$$C#Domain...
		where each "#Domain" is optional. If not specified, the default domain will be used.	
	*/
	If $E(pName, 1, 3)'="$$$" Quit pName
	Set tNumParts=$L(pName, "/")
	Set tResolvedString = ""
	For i=1:1:tNumParts{
		Set tUnresolvedPart=$P(pName,"/",i)
		Set tResolvedString=tResolvedString_##class(%DeepSee.UserPortal.Utils).%ResolveText($Replace(tUnresolvedPart,"#","/"))_$s(i=tNumParts:"",1:"/")
	}
	Quit tResolvedString
}

/// This is a special parser for handling the filter context of selected
/// cells produced during a detail listing. This is designed to parse a 
/// pExpression provided in the pivotTable.listingFilters property into 
/// display Level-Member name pairs to provide context for a listing export or
/// display.
ClassMethod %ParseCellSelectionContext(pExpression = "", pCubeName = "", Output pContextFilters) [ Internal ]
{
	// Method added by DTB115
	Set tSC = $$$OK
	
	Set pFilterNames = ""
	Set pFilterValues = ""
	Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
	Kill pContextFilters
	
	Try {
		If (pExpression="") {
			Set pContextFilters=0
			Quit
		}
		If (pCubeName="") {
			Set tSC = $$$ERROR($$$GeneralError,"cubeName must be supplied")
			Quit
		}
		Else {
			// DTB195 - All low-level methods expect the unquoted cube index
			If $E(pCubeName)="[" {
				Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(pCubeName,.tInfo)
				If $$$ISERR(tSC) Quit
				
				Set pCubeName = tInfo(1) 
			}
		}
		
		// +DTB648 - Use %DeepSee.ResultSet to process an expression that comes in via an 
		// onClick filter expression: %FILTER xxx %FILTER yyy %FILTER zzz
		If ($$$UPPER(pExpression)["%FILTER") {
			// DTB662 - PLace everything on columns by parsing the expression into query as a filter
			Set tMDX = "SELECT FROM [" _ $$$dsEscapeIdent(pCubeName) _ "] " _ pExpression
			Set tRS = ##class(%DeepSee.ResultSet).%New()
			Set tSC = tRS.%PrepareMDX(tMDX)
			
			Set pExpression = $ZSTRIP($P(tRS.%Query.%ToString(),"WHERE",2),"<>W") _ " ON 0"
		}
		Else {
			Set pExpression = pExpression _ " ON 0"
		}
		// -DTB648

		// Build an MDX expression that can be parsed and construct a resultset with it.
		// The creation of this resultset will translate the multiple %FILTER statements into
		// a single axis clause that can be executed on rows and read as labels.
		Set tMDX = "SELECT " _ pExpression _ " FROM [" _ $$$dsEscapeIdent(pCubeName) _ "]"		// DTB195 - Quote the cube name to protect it in the parsing
		
		Set tRS = ##class(%DeepSee.ResultSet).%New()
		Set tSC = tRS.%PrepareMDX(tMDX)
			If $$$ISERR(tSC) Quit
		Set tSC = tRS.%ExecuteAsynch(,,1)
			If $$$ISERR(tSC) Quit
		
		For c=1:1:tRS.%GetAxisSize(1) {
			// DTB662 - Translate labels for chained context cells. Each in the original context
			// selection cells will be represented by a separate branch of children in the 
			// pCintext array
			Set tLabelCount = 0
			Kill tParent
			
			// DTB662 - Directly read the axis nodes from the resultset to get the labels
			Set tSC = tRS.%GetOrdinalLabelNodes(1,c,.tNodes)
			If $$$ISERR(tSC) Quit
			
			// DTB248 - Go back through the labels last-to-first with new skip information
			Set tNodeNo=$O(tNodes(""),-1,tNode)
			While tNodeNo'="" {
				Set tType = $LG(tNode,1)
				Set tLabel = $LG(tNode,5)
				Set tDimNo = +$LG(tNode,9)
				Set tHierNo = +$LG(tNode,10)
				Set tLevelNo = +$LG(tNode,11)
				
				// DTB662 - Look up the caption from the numeric 
				Set tLevelNode = $G($$$DeepSeeMetaGLVN("cubes",tCubeIndex,"mbr#",tDimNo,tHierNo,tLevelNo))
				Set tDim = $LG(tLevelNode,2)
				Set tHier = $LG(tLevelNode,3)
				Set tLevel = $LG(tLevelNode,4)
				
				Set tSC = ##class(%DeepSee.Utils).%GetMemberCaption(tCubeIndex,tDim,tHier,tLevel,.tCaption)
				If $$$ISERR(tSC) Quit

				If (tLabel'="") {
					Set tLabelCount = tLabelCount + 1
					
					Set pContextFilters($I(pContextFilters)) = $LB(tCaption,tLabel)
					Set:+$G(tParent) pContextFilters(tParent,"ch") = pContextFilters		// All context filters in a single cell are chained
					
					// Remember this as a parent in the group of labels
					Set tParent = $G(pContextFilters,0)
				}
				
				Set tNodeNo=$O(tNodes(tNodeNo),-1,tNode)
			}	
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Inspect an open dashboard definition object and add names to any widgets that do not have names. All widgets
/// that are assigned new names will have a name of the form <var>WidgetXXX</var> that is unique to the dashboard
/// assigned. All names assigned in this manner will be returned in an index available through the by reference argument<br>
/// <var>pNewWidgetNames</var>(widgetPosition) = newName<br>
/// This method will not change the stored dashboard definition DFI document.
ClassMethod AddWidgetNames(pDashboard As %DeepSee.Dashboard.Definition = "", ByRef pNewWidgetNames) As %Status
{
	// Method added by DTB471
	Set tSC = $$$OK
	Kill pNewWidgetNames
	Try {
		If '$IsObject(pDashboard)||'pDashboard.%IsA("%DeepSee.Dashboard.Definition") {
			Set tSC = $$$ERROR($$$GeneralError,$$$Text("Argument is not a valid dashboard definition."))
			Quit
		}
		Set tWidgetCount = pDashboard.widgets.Count()
		Set tNamedWidgetCount = 0
		
		For w=1:1:tWidgetCount {
			// Do a first pass to collect any widget names that already exist
			Set tWidgetName = pDashboard.widgets.GetAt(w).name
			If (tWidgetName'="") {
				Set x = $I(tNamedWidgetCount)
				Set tAlreadyNamed(tWidgetName) = ""
			}
		}
		
		// If not all widgets already have names, fill in any that are missing
		If (tNamedWidgetCount<tWidgetCount) {
			For w=1:1:tWidgetCount {
				If (pDashboard.widgets.GetAt(w).name="") {
					Set tNewWidgetName = "Widget"_$I(tNameCounter)
					While $D(tAlreadyNamed(tNewWidgetName)) {
						// If the first attempt at a generated name already exists, keep trying until a new name
						// is discovered
						Set tNewWidgetName = "Widget"_$I(tNameCounter)
					}

					Set pDashboard.widgets.GetAt(w).name = tNewWidgetName
					Set pNewWidgetNames(w) = tNewWidgetName			// Return an index of which names were assigned to which widgets
				}
			}
		}
		
		// DTB544 - Make sure keys are added to all widgets
		Set tSC = ..AddWidgetKeys(pDashboard)
		If $$$ISERR(tSC)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Look through all of the widgets in a dashboard and make sure each that has a logical name also has a defined key.
ClassMethod AddWidgetKeys(pDashboard As %DeepSee.Dashboard.Definition = "") As %Status
{
	// Method added by DTB544
	Set tSC = $$$OK
	Kill pNewWidgetNames
	Try {
		If '$IsObject(pDashboard)||'pDashboard.%IsA("%DeepSee.Dashboard.Definition") {
			Set tSC = $$$ERROR($$$GeneralError,$$$Text("Argument is not a valid dashboard definition."))
			Quit
		}
		
		For w=1:1:pDashboard.widgets.Count() {
			Set tWidget = pDashboard.widgets.GetAt(w)
			If (tWidget.name'="")&&(tWidget.key="") {
				Set tWidget.key = $ZCRC(tWidget.name,7)
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

}
