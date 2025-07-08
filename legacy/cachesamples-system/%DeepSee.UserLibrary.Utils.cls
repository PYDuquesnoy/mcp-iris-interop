/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// This class contains API method for the DeepSee User Component library.
Class %DeepSee.UserLibrary.Utils Extends %RegisteredObject [ Abstract, System = 4 ]
{

/// Deletes all folders and folder items in the current namespace.
ClassMethod %KillFolders() As %Status
{
	Do ##class(Folder).%KillExtent()
	Do ##class(FolderItem).%KillExtent()
	Quit $$$OK
}

ClassMethod %KillAutosaveFolders(pFolder As %String = "$Temp") As %Status
{
	// Method added by WAL123
	If ($E(pFolder,1,5) '= "$Temp") Quit $$$OK
	// need to delete this folder as well
	Set tSC = ##class(%DeepSee.UserLibrary.Utils).%GetSubFolderList(.tSubFolderList,pFolder) 
	Set tSubFolder = $O(tSubFolderList(""))
	While (tSubFolder '= "") {
		// Recurse
		Set tSC = ..%KillAutosaveFolders(tSubFolderList(tSubFolder)) // + WAL153
		If (($G(tSubFolderList(tSubFolder))'="") && ($E($G(tSubFolderList(tSubFolder)),1,5) = "$Temp")) {
			Set tSC = ##class(%DeepSee.UserLibrary.Utils).%DeleteFolderContents(tSubFolderList(tSubFolder))
			Set tFolder = ##class(%DeepSee.UserLibrary.Utils).%FindFolder(tSubFolderList(tSubFolder))
			If $IsObject(tFolder) {
				Set tSC = ##class(%DeepSee.UserLibrary.Folder).%DeleteId(tFolder.%Id())
			}
		}
		Set tSubFolder = $O(tSubFolderList(tSubFolder))
	}
	// Delete this folder
	Set tSC = ##class(%DeepSee.UserLibrary.Utils).%DeleteFolderContents(pFolder)
	Set tFolder = ##class(%DeepSee.UserLibrary.Utils).%FindFolder(pFolder)
	If $IsObject(tFolder) {
		Set tSC = ##class(%DeepSee.UserLibrary.Folder).%DeleteId(tFolder.%Id())
	}
	Quit $$$OK
}

/// Deletes all user preference info in the current namespace.
ClassMethod %KillUserPreferences() As %Status
{
	Kill ^DeepSee.UserPreferences
	Quit $$$OK
}

/// Make note that the given item was accessed recently.
ClassMethod %RegisterRecentItem(pType As %String, pName As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		If ((pType="")||(pName="")) Quit

		// do not register "system" items
		If (($E(pName,1)="$")&&($E(pName,1,3)'="$$$")) Quit

		Set ^DeepSee.UserPreferences($UserName,"recent",pType,pName) = $ZDT($H,3)

		// clear out old items
		// JMD1211: loop over type
		Set tCount = 0
		Set tType = $O(^DeepSee.UserPreferences($UserName,"recent",""))
		While (tType'="") {
			Set tName = $O(^DeepSee.UserPreferences($UserName,"recent",tType,""),1,t)
			While (tName'="") {
				Set tList(t) = $LB(tType,tName)
				Set tCount = tCount + 1
				Set tName = $O(^DeepSee.UserPreferences($UserName,"recent",tType,tName),1,t)
			}
			Set tType = $O(^DeepSee.UserPreferences($UserName,"recent",tType))
		}
		While (tCount > 30) {
			Set t = $O(tList(""),1,tNode)
			Set tType = $LG(tNode,1)
			Set tName = $LG(tNode,2)
			Kill:tType'=""&&tName'="" ^DeepSee.UserPreferences($UserName,"recent",tType,tName)
			Set tCount = tCount - 1
		}

		// DP-419954 - Set folder item's lastAccessed property
		If ##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(pName) {
			Set tFolderItem = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pName)
			Set tFolderItem.lastAccessed = $ZDT($H,3,3)
			Set tSC = tFolderItem.%Save()
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get list of recent items for user.
/// This takes the form:<br/>
/// pList(time) = name<br/>
/// If <var>pType</var> is missing, list all types. <var>pType</var> can contain a csv
/// list of types.
ClassMethod %GetRecentItemList(Output pList As %String, pType As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		
		If (pType="") {
			Set tType = $O(^DeepSee.UserPreferences($UserName,"recent",""))
		}
		Else {
			Set p = 1
			Set tType = $P(pType,",",p)
		}
		
		Set n = 0
		While (tType '= "") {
			Set tName = $O(^DeepSee.UserPreferences($UserName,"recent",tType,""),1,t)
			While (tName'="") {
				Set n = n + 1
				Set pList(t_"?"_n) = tName
				Set tName = $O(^DeepSee.UserPreferences($UserName,"recent",tType,tName),1,t)
			}
			If (pType="") {
				Set tType = $O(^DeepSee.UserPreferences($UserName,"recent",tType))
			}
			Else {
				Set p = p + 1
				Set tType = $P(pType,",",p)
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Remove item from recent items list.
ClassMethod %RemoveRecentItem(pName As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		If (pName="") Quit
		Set tType = $O(^DeepSee.UserPreferences($UserName,"recent",""))
		While (tType '= "") {
			Set tName = $O(^DeepSee.UserPreferences($UserName,"recent",tType,""))
			While (tName'="") {
				If (tName = pName) {
					Kill ^DeepSee.UserPreferences($UserName,"recent",tType,tName)
				}
				Set tName = $O(^DeepSee.UserPreferences($UserName,"recent",tType,tName))
			}
			Set tType = $O(^DeepSee.UserPreferences($UserName,"recent",tType))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Add item to favorites list.
ClassMethod %AddFavorite(pName As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		If (pName="") Quit
		Set ^DeepSee.UserPreferences($UserName,"favorite",pName) = $ZDT($H,3)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Remove item from favorites list.
ClassMethod %RemoveFavorite(pName As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		If (pName="") Quit
		Kill ^DeepSee.UserPreferences($UserName,"favorite",pName)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get list of favorite items for user.
/// This takes the form:<br/>
/// pList(name) = time
ClassMethod %GetFavoriteList(Output pList As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tName = $O(^DeepSee.UserPreferences($UserName,"favorite",""),1,t)
		While (tName'="") {
			Set pList(tName) = t
			Set tName = $O(^DeepSee.UserPreferences($UserName,"favorite",tName),1,t)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Open the folder item with the given full name.
ClassMethod %OpenFolderItem(pFullName As %String, Output pStatus As %Status) As FolderItem
{
	Set tItem = ""
	Kill %objlasterror
	If ((pFullName'="")&&((..%FolderItemExists(pFullName,.tID)=1)||(..%FolderItemExists(pFullName,.tID)=3))) {		// DP-432616 - Return when locked also
		Set:tID'="" tItem = ##class(FolderItem).%OpenId(tID,,.pStatus)
	}
	Else {
		// DTB922 - Return error when an invalid name is supplied
		Set pStatus = $$$ERROR($$$NoFolderItem, pFullName)
	}

	Quit tItem
}

/// Check if a there is a folder item with the given name.<br/>
/// Returns 0 if the item does not exist; returns 1 if it exists and is visible to the
/// current user; returns 2 if it exists but is not visible to the current user; returns 3 if the pivot is locked.<br/>
/// Return its id by reference as a convenience.<br/>
ClassMethod %FolderItemExists(pFullName As %String, Output pID As %String) As %Integer
{
	Set pID = ""
	If ($G(pFullName) = "") Quit 0
	Set tSC = ##class(FolderItem).%ParseFullName(pFullName,.tFolderName,.tItemName,.tExt)
	Quit:$$$ISERR(tSC) 0

	Set tFolder = ##class(%DeepSee.UserLibrary.Utils).%FindFolder(tFolderName)
	Set tFolderId = $S($IsObject(tFolder):tFolder.%Id(),1:"")
	If ((tFolderName'="")&&(tFolderId="")) {
		// if the folder does not yet exist, then the item does not exist!
		Quit 0
	}
	// check each item with given name (but different extension)
	Set tID = ""
	Set SQLCODE = ""
	&sql(DECLARE sql1 CURSOR FOR
		SELECT %ID INTO :tID FROM %DeepSee_UserLibrary.FolderItem 
		WHERE ((folder->fullName = :tFolderName) OR (:tFolderName IS NULL AND folder IS NULL)) 
			AND (name = :tItemName)
			ORDER BY timeModified DESC)

	Set tFound = 0
	&sql(OPEN sql1)
	&sql(FETCH sql1)
	While ('tFound && (SQLCODE = 0)) {
		Set tItem = ##class(FolderItem).%OpenId(tID,,.pStatus)
		If ($$$UPPER(tItem.fullName) = $$$UPPER(pFullName)) {
			Set pID = tID
			If (tItem.locked) {
				// DP-432616 - Return indication that the table is locked
				Set tFound = 3
			}
			ElseIf (tItem.%CheckResource()) {
				Set tFound = 1
			}
			Else {
				Set tFound = 2
			}
		}
		&sql(FETCH sql1)
	}
	&sql(CLOSE sql1)
	Quit tFound
}

/// Delete all the items within the given folder.
ClassMethod %DeleteFolderContents(pFolderName As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		// get *all* items in this folder
		Set tSC = ..%GetFolderItemList(.tList,pFolderName,1)
		If $$$ISERR(tSC) Quit

		// n.b. this will delete all items in this folder
		// even those not visible to the current user
		Set k = $O(tList(""))
		
		While (k'="") {
			// JMD1333 make sure to use correct id
			Set tItem = ##class(FolderItem).%OpenId(tList(k))
			If $IsObject(tItem) {
				Set tSC = ..%DeleteFolderItem(tItem.fullName)
				If $$$ISERR(tSC) Quit
			}
			Set k = $O(tList(k))
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Delete the folder item with the given full name.
/// <var>pCount</var> returns the number of items actually deleted.
ClassMethod %DeleteFolderItem(pFullName As %String, Output pCount As %Integer) As %Status
{
	Set tSC = $$$OK
	Set pCount = 0
	// If there are multiple items with the same name, delete all of them!
	While ((pFullName'="")&&(..%FolderItemExists(pFullName,.tID)=1)) {
		// clear any settings for this item
		// if the item is not a dashboard, there is no harm done!
		Do ##class(%DeepSee.UserPortal.Utils).%ClearDashboardSettings(pFullName)
		Set tSC = ##class(FolderItem).%DeleteId(tID)
		If $$$ISOK(tSC) {
			Set pCount = pCount + 1
		}
		ElseIf (tID'="")&&##class(FolderItem).%ExistsId(tID) {
			// DTB860 - Throw the error if there is a failure to delete the folder item
			Quit
		}
	}
	Quit tSC
}

ClassMethod %GetXMLNamesForClasses(Output pList, Output pNonFolderItem) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pList	
		Set tSC = ..%GetFolderItemClasses(.pList)
		If $$$ISERR(tSC) Quit
		// WAL301 -- handle other types; these should be a subclass of something else
		Set tIdx = $O(pList(""),-1)
		Set pList($i(tIdx)) = $LB($$$DSPVCls,$$$DSPVExt)
		Set pList($i(tIdx)) = $LB($$$DSNFCls,$$$DSNFExt)
		Set pList($i(tIdx)) = $LB($$$DSSCMCls,$$$DSSCMExt)
		Set pList($i(tIdx)) = $LB($$$DSTLCls,$$$DSTLExt)
		Set pList($i(tIdx)) = $LB($$$DSLGCls,$$$DSLGExt)
		Set pList($i(tIdx)) = $LB($$$DSUSCls,$$$DSUSExt)
		Set pNonFolderItem($$$DSPVCls)=1
		Set pNonFolderItem($$$DSNFCls)=1
		Set pNonFolderItem($$$DSSCMCls)=1
		Set pNonFolderItem($$$DSTLCls)=1
		Set pNonFolderItem($$$DSLGCls)=1
		Set pNonFolderItem($$$DSUSCls)=1
		// - WAL301
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return a list of all folder item classes.<br/>
/// pList(n) = $LB(classname,xmlname)
ClassMethod %GetFolderItemClasses(Output pList) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pList

		// find all subclasses of FolderItem
		Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		Set tSC = tRS.Execute("%DeepSee.UserLibrary.FolderItem")
		If $$$ISERR(tSC) Quit
		While (tRS.Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			Set tName = $G(tRS.Data("Name"))
			Set tClasses(tName) = ""
		}

		Set n = 0
		Set tClass = $O(tClasses(""))
		While (tClass'="") {
			Set n = n + 1
			Set tXMLName = $zobjclassmethod(tClass,"%GetParameter","XMLNAME")
			Set pList(n) = $LB(tClass,tXMLName)
			Set tClass = $O(tClasses(tClass))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return an array of all folders visible to the current user within the given folder.
/// This list is in the form:<br/>
/// pList(n) = name
ClassMethod %GetFolderList(Output pList As %String, pFolderName As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Set tFlag = $zu(115,8,0)
		Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
		Set tSC = tStatement.%Prepare("SELECT ID,fullName FROM %DeepSee_UserLibrary.Folder ORDER BY fullName")
		If $$$ISERR(tSC) Quit

		Set n = 0
		Set tRS = tStatement.%Execute()
		While (tRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			If (tRS.fullName '="") {
				// names starting with $ are private
				// JMD1344: test localized name
				Set tDName = ##class(%DeepSee.UserPortal.Utils).%ResolveText(tRS.fullName)
				If ($E(tDName,1)'="$") {
					Set tFolder = ##class(%DeepSee.UserLibrary.Folder).%OpenId(tRS.ID)
					If ($IsObject(tFolder)) {
						Set tResource = tFolder.%GetResource()
						If ((tResource="")||$System.Security.Check(tResource,"USE")) {
							Set n = n + 1
							Set pList(n) = tFolder.fullName
						}
					}
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Set tFlag = $zu(115,8,tFlag)
	Quit tSC
}

/// Return an array of all categories that have been assigned to Folder Items.
/// This list is in the form:<br/>
/// pList(n) = category
ClassMethod %GetCategoryList(Output pList) As %Status
{
	// Method added by DTB102
	Kill pList
	Set tSC = $$$OK
	Set tFlag = $zu(115,8,0)
	Try {
		Set tSQL = "SELECT Category FROM %DeepSee_UserLibrary.FolderItem WHERE Category IS NOT NULL GROUP BY %EXACT(Category) ORDER BY Category"
		Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
		Set tSC = tStatement.%Prepare(tSQL)
		If $$$ISERR(tSC) Quit

		Set n = 0
		Set tRS = tStatement.%Execute()
		While (tRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			
			Set pList($I(n)) = tRS.%Get("Category")
		}
	}
	Catch ex {
		Set tSC = ex.Status()
	}
	Set tFlag = $zu(115,8,tFlag)
	Quit tSC
}

ClassMethod %GetSubFolderList(Output pList As %String, pFolderName As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Set tFlag = $zu(115,8,0)
		Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
		Set tSQL = "SELECT ID,fullName FROM %DeepSee_UserLibrary.Folder WHERE fullname %STARTSWITH '"
		Set tSQL = tSQL _ pFolderName _ "' Order By fullName"
		Set tSC = tStatement.%Prepare(tSQL)
		If $$$ISERR(tSC) Quit

		Set n = 0
		Set tRS = tStatement.%Execute()
		While (tRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			If tRS.fullName=pFolderName Continue 		// DP-427970 - Do not include the requested folder in the list of subfolders

			If (tRS.fullName '="") {
				// names starting with $ are private
				// JMD1344: test localized name
				Set tDName = ##class(%DeepSee.UserPortal.Utils).%ResolveText(tRS.fullName)
				
				/// WAL053 -- show $temp
				If (($E(tDName,1)'="$")||($E(tDName,1,5)="$Temp")) {
					Set tFolder = ##class(%DeepSee.UserLibrary.Folder).%OpenId(tRS.ID)
					If ($IsObject(tFolder)) {
						Set tResource = tFolder.%GetResource()
						If ((tResource="")||$System.Security.Check(tResource,"USE")) {
							Set n = n + 1
							Set pList(n) = tFolder.fullName
						}
					}
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Set tFlag = $zu(115,8,tFlag)
	Quit tSC
}

/// Return an array of all folder items visible to the current user within the given folder.
/// This list is in the form:<br/>
/// pList(n) = id<br/>
/// If <var>pShowAll</var> is true, list items for all users.<br/>
/// If <var>pFolderClass</var> is provided, only list items of the given type.<br/>
ClassMethod %GetFolderItemList(Output pList As %String, pFolderName As %String = "", pShowAll As %Boolean = 0, pFolderClass As %String = "") As %Status [ PublicList = SQLCODE ]
{
	Set tSC = $$$OK
	Try {
		New SQLCODE
		Set tFlag = $zu(115,8,0)
		Set tSQL = "SELECT ID FROM %DeepSee_UserLibrary.FolderItem"
		Set tWHERE = ""
		If (pFolderName'="") {
			Set tWHERE = tWHERE _ $S(tWHERE="":"",1:" AND ") _ "folder->fullName %STARTSWITH "_ ##class(%ZEN.Auxiliary.QueryInfo).QuoteSQL(pFolderName)
		}
		If (pFolderClass'="") {
			Set tWHERE = tWHERE _ $S(tWHERE="":"",1:" AND ") _ "x__classname['"_pFolderClass_"'"
		}
		Set:tWHERE'="" tSQL = tSQL_" WHERE "_tWHERE

		Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
		Set tSC = tStatement.%Prepare(tSQL)
		If $$$ISERR(tSC) Quit

		Set n = 0
		Set tRS = tStatement.%Execute()
		While (tRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			If (tRS.ID '="") {
				Set tItem = ##class(FolderItem).%OpenId(tRS.ID)
				If ($IsObject(tItem)&&(tItem.%IsVisibleToPortal()||pShowAll)) {
					If (pShowAll||tItem.%CheckResource()) {
						Set n = n + 1
						Set pList(n) = tRS.ID
					}
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Set:$D(tFlag) tFlag = $zu(115,8,tFlag)
	Quit tSC
}

/// Find the folder with the given full name.
/// If <var>pCreate</var> is true, then create the folder if it does not exist.
ClassMethod %FindFolder(pName As %String, pCreate As %Boolean = 0, Output pSC As %Status, pParent As Folder = "") As Folder
{
	Set tFolder = ""
	Set pSC = $$$OK
	Try {
		Set tParentId = $S($IsObject(pParent):pParent.%Id(),1:"")
		Set tRoot = $P(pName,"/",1)
		Set tPath = $P(pName,"/",2,$L(pName,"/"))
		If (##class(%DeepSee.UserLibrary.Folder).nameExists(tParentId,tRoot,.tFolderId)) {
			Set tFolder = ##class(%DeepSee.UserLibrary.Folder).nameOpen(tParentId,tRoot)
		}
		If ('$IsObject(tFolder) && pCreate) {
			Set tFolder = ##class(%DeepSee.UserLibrary.Folder).%New()
			Set tFolder.name = tRoot
			Set tFolder.folder = pParent
			Set pSC = tFolder.%Save()
			If $$$ISERR(pSC) Quit
		}

		If ($IsObject(tFolder) && (tPath'="")) {
			// recurse
			Set tFolder = ..%FindFolder(tPath,pCreate,.pSC,tFolder)
			If $$$ISERR(pSC) Quit
		}
	}
	Catch(ex) {
		Set pSC = ex.AsStatus()
	}
	If $$$ISERR(pSC) {
		Set tFolder = ""
	}
	Quit tFolder
}

/// Export the items in the list to a container
ClassMethod %ExportContainer(ByRef pItemList As %String, pFileName As %String, pContainerClassName As %String = "", pVerbose As %Boolean = 1) As %Status
{
	// Method added by WAL301 -- adapted general API style method from folder manager
	Set tSC = $$$OK
	Try {
		Set tItemsExported=0
		Set tProblemItems=0
		// DTB514 - The input may be either a by-reference array or a comma-delimited list.
		// Normalize either into an array for firther processing.
 		If $D(pItemList)=10 {
	 		// Input is an array, use it.
			Merge tItemList = pItemList
		}
		ElseIf $D(pItemList)=1 {
			// Input is a comma-delimeted list. Convert it to an array.
			For ii=1:1:$L(pItemList,",") {
				Set tItemList($ZSTRIP($P(pItemList,",",ii),"<>W")) = ""
			}
		}
		Else {
			Set tSC = $$$ERROR($$$GeneralError,"Invalid format for item list")
			Quit
		}
		
		// DTB514 - Normalize the item names
		Set tItemName = $O(tItemList(""))
		While tItemName'="" {
			Kill tItemList(tItemName)
			Set tTempName = $$$UPPER($P(tItemName,".",1,*-1)) _ "." _ $P(tItemName,".",*)
			Set tTempList(tTempName) = ""
			Set tItemName = $O(tItemList(tItemName))
		}
		Merge tItemList = tTempList
		
		Set tSC = ..%ExpandItemList(.tItemList,pVerbose)
		If $$$ISERR(tSC) Quit
		If (pContainerClassName'="") {
			Set tClassDefName = pContainerClassName
		}
		Else {
			Set tClassDefName = "DeepSee.ContainerExport"_$P($H,",",2)	
		}
		#; Create a new class definition
		Set tClassDef = ##class(%Dictionary.ClassDefinition).%New(tClassDefName)
		If tClassDef = $$$NULLOREF Set tSC=$$$ERROR($$$CannotCreateObject,"%Dictionary.ClassDefinition") Quit
		Set tClassDef.Super = "%DeepSee.UserLibrary.Container"
        Set tClassDef.IncludeCode = "%DeepSee"
        
        // Create items XDATA Block
		Set tExportData = ##class(%Dictionary.XDataDefinition).%New()
		Set tExportData.Description = $c(10,13)_"DeepSee Manifest Export"
		Set tExportData.XMLNamespace = "http://www.intersystems.com/deepsee"
		Set tExportData.Name = "Contents"
		Set tExportData.parent = tClassDef
		
		// The Utils Export can handle a stream. So let's get a stream going
		Set tTempStream = ##class(%Stream.TmpCharacter).%New()
		// Write in items tag
		Do tTempStream.Write("<items>")
		Set tName = $O(tItemList(""))
		While tName'="" {
			// + WAL315 -- continue even if there is a problem
			Try{
				// Assume full names
				Set tType=$P(tName,".",*)
				Set tShortName = $P(tName,".",1,*-1)
				
				// WAL315 -- set pVerbose to 0 and handle error reporting here
				Set tSC = ##class(%DeepSee.UserLibrary.Utils).%Export(tName,tTempStream,0,.tXMLName)
				If $$$ISERR(tSC) $$$ThrowStatus(tSC)		// DTB514 - Report error
				
				// Log for manifest output
				Set:tXMLName'="" tType = tXMLName
				Set tManifestLog(tType,tShortName)=""
				Set tItemsExported=$i(tItemsExported)
				Write:pVerbose !,"Exporting: ",tName		// DTB514
				Set tName = $O(tItemList(tName))
			}
			Catch ex {
				Set tSC = ex.AsStatus()
				Write:pVerbose !!,"Unable to export item "_tName_": "
				Do:pVerbose $system.Status.DisplayError(tSC) 
				Write !
				Set tName = $O(tItemList(tName))
				Set tProblemItems = $i(tProblemItems)
			}
			Set tSC = $$$OK
			// - WAL315
		}
		Do tTempStream.Write("</items>")
		
		// WAL301 -- write a description of the "manifest", i.e. what was exported
		Set tDescription = ""
		Set tType= $O(tManifestLog(""))
		While tType'="" {
			Set tDescription = tDescription_$c(10,13)_"     "_$$$UPPER(tType)
			Set tShortName = $O(tManifestLog(tType,""))
			While tShortName'="" {
				Set tDescription = tDescription_$c(10)_"          "_tShortName
				Set tShortName = $O(tManifestLog(tType,tShortName))	
			}
			Set tType= $O(tManifestLog(tType))	
		}
		Set tDescription = tDescription_$c(10,13)
		Set tExportData.Description = tExportData.Description_tDescription
		
		Set tSC = tExportData.Data.CopyFrom(tTempStream)
		If $$$ISERR(tSC) Quit
		
		Set tSC = tClassDef.%Save()
		If $$$ISERR(tSC) Quit
		
		// Export to a file and then delete the class
		Set tClassName = tClassDefName_".cls"
		Set tSC = $system.OBJ.Export(tClassName,pFileName,"/display=none")
		If $$$ISERR(tSC) Quit
		
		If $$$defClassDefined(tClassDefName) {
		    Set tSC = $$Delete^%apiOBJ(tClassDefName,"-d")
		    If $$$ISERR(tSC) Quit
		}
		// WAL315 -- report
		Write:pVerbose !!,tItemsExported_" item"_$S(tItemsExported'=1:"s",1:"")_"  exported.",!
		Write:pVerbose "Encountered "_tProblemItems_" error"_$S(tProblemItems'=1:"s",1:"")_" during export.",!
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Export FolderItem or Folder information to an XML file.
ClassMethod %Export(pFullName As %String, pFile As %String = "", pVerbose As %Boolean = 1, Output pXMLName As %String) As %Status
{
	Set tSC = $$$OK
	Set io = ""
	Set tXMLName = ""
	
	Try {
		// WAL301 -- Handle different types of items
		If ..%IsNotFolderItem(pFullName) {
			Set tItem = ..%OpenItem(pFullName,.tSC)	
			If $$$ISERR(tSC) Quit		// DTB514 - Report error
			If '$IsObject(tItem) {
				Set tSC = $$$ERROR($$$GeneralError,"Unable to open item: "_pFullName)
				Quit		// DTB514 - Report error
			}
		}
		Else {
			// DP-405411 - Look to see if this is a folder first. If it is a folder, export it.
			// If it is not a folder, try to open a folderItem using the provided name.
			Set tItem = ..%FindFolder(pFullName,,.tSC)
			If $$$ISERR(tSC) Quit		// DTB514 - Report error
			If $IsObject(tItem) {
				Set tItem.%exportName = tItem.fullName
			}
			Else {
				Set tItem = ..%OpenFolderItem(pFullName,.tSC)
				If $$$ISERR(tSC) Quit		// DTB514 - Report error
				If '$IsObject(tItem) {
					Set tSC = $$$ERROR($$$GeneralError,"Unable to open folder item: "_pFullName)
					Quit
				}
			}
		}
		Set pXMLName = tItem.#XMLNAME

		Set tWriter = ##class(%XML.Writer).%New()
		Set tWriter.Indent = 1

		If $IsObject(pFile) {
			Set tSC = tWriter.OutputToStream(pFile)
			If $$$ISERR(tSC) Quit
		}
		Else {
			// make sure we can open the file
			Open pFile:"WNU":0 Else  Set tSC = $$$ERROR($$$GeneralError,"Unable to open file: "_pFile) Quit
			Close pFile

			Set tWriter = ##class(%XML.Writer).%New()
			Set tWriter.Indent = 1
			Set tSC = tWriter.OutputToFile(pFile)
			If $$$ISERR(tSC) Quit
		}
		Set tSC = tWriter.StartDocument()  
		If $$$ISERR(tSC) Quit
		Set tSC = tWriter.RootObject(tItem)
		If $$$ISERR(tSC) Quit
		Set tSC = tWriter.EndDocument()
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If ($$$ISERR(tSC)&&pVerbose) {
		Write !
		Do $System.Status.DisplayError(tSC)
	}
	Quit tSC
}

/// Import a folder item definition from an XML file.<br/>
/// If <var>pReplace</var> is true, replace an existing item with the same name.<br/>
/// If <var>pVerbose</var> is true, write status to the console.<br/>
/// If <var>pKill</var> is true, then delete all existing items before import!<br/>
/// If <var>pForceItemName</var> is given, import the item using that name.<br/>
/// If type-extension is not present in <var>pForceItemName</var> supply it automatically<br/>
ClassMethod %Import(pFile As %String = "", pReplace As %Boolean = 0, pVerbose As %Boolean = 1, pKill As %Boolean = 0, pForceItemName As %String = "", ByRef pItemsLoaded As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill %objlasterror

		// Create an instance of %XML.Reader
		Set tReader = ##class(%XML.Reader).%New()
	
		// Begin processing of the file
		If $IsObject(pFile) {
			Set tSC = tReader.OpenStream(pFile)
		} Else {
			Set tSC = tReader.OpenFile(pFile)
		}
		If $$$ISERR(tSC) Quit

		If (pKill) {
			Write:pVerbose "Deleting existing folder contents",!
			Set tSC = ..%KillFolders()
			If $$$ISERR(tSC) Quit
		}

		// Associate possible class names with their XML element names
		Set tSC = ..%GetFolderItemClasses(.tClasses)
		If $$$ISERR(tSC) Quit

		Set n = $O(tClasses(""))
		While (n'="") {
			Set tClassName = $LG(tClasses(n),1)
			Set tXMLName = $LG(tClasses(n),2)
			Do tReader.Correlate(tXMLName,tClassName)
			Set n = $O(tClasses(n))
		}

		Do tReader.Correlate("folder","%DeepSee.UserLibrary.Folder")

		// Read objects (folders or folderItems) from xml file
		While (tReader.Next(.tItem,.tSC)) {
			// JMD1379 reset force name for each item
			Set tForceItemName = pForceItemName
			If (tItem.%IsA("%DeepSee.UserLibrary.Folder")) {
				Set tFolder = ##class(%DeepSee.UserLibrary.Utils).%FindFolder(tItem.%exportName,1)
				If $IsObject(tFolder) {
					// update
					Write:pVerbose "Updating: ",tFolder.fullName,!
					Set tFolder.resource = tItem.resource
					Set tItem = tFolder
					Set tSC = tItem.%Save()
					If $$$ISERR(tSC) Quit
					Set pItemsLoaded($I(pItemsLoaded)) = tFolder.fullName
				}
			}
			Else { // an item not a folder
				If (""=tForceItemName) {
					Set tForceItemName=tItem.fullName
				}
				Else { // if needed add type extension from item to pForceItemName
					Set tSC = ##class(FolderItem).%ParseFullName(tForceItemName,.tFolderName,.tItemName,.tExt)
					Set:""=tExt tForceItemName=tForceItemName_"."_$$$comMemberKeyGet(tItem.%ClassName(1),$$$cCLASSparameter,"ITEMTYPE",$$$cPARAMdefault)
				}
				Set tExists = ..%FolderItemExists(tForceItemName)
				If (tExists=2) {
					Set tSC = $$$ERROR($$$GeneralError,"Folder item with given name "_tForceItemName_" already exists and you do not have permission to replace it"_$S(pForceItemName=tItem.fullName:"",1:" with imported item "_tItem.fullName))
					Quit
				}
				ElseIf (tExists=1) {
					If (pReplace) {
						Write:pVerbose "Replacing: "_tForceItemName_$S(tForceItemName=tItem.fullName:"",1:" with imported item "_tItem.fullName)
						Set tSC = ..%DeleteFolderItem(tForceItemName)
						If $$$ISERR(tSC) Quit
					}
					Else {
						Set tSC = $$$ERROR($$$GeneralError,"Folder item with given name "_tForceItemName_" already exists; not replacing"_$S(tForceItemName=tItem.fullName:"",1:" with imported item "_tItem.fullName))
						Quit
					}
				}
				Else {
					Write:pVerbose "Importing to "_tForceItemName_$S(tForceItemName=tItem.fullName:"",1:" from imported item "_tItem.fullName),!
				}
				Set tSC = tItem.%OnAfterImport(tForceItemName)
				If $$$ISERR(tSC) Quit

				Set tItem.fullName=tForceItemName

				Set tSC = tItem.%Save()
				If $$$ISERR(tSC) Quit

				Set pItemsLoaded($I(pItemsLoaded)) = tItem.fullName

				// JMD1211 register the recent item
				Set tType = $P(tItem.fullName,".",2)
				Set tSC = ##class(%DeepSee.UserLibrary.Utils).%RegisterRecentItem(tType,tItem.fullName)
				If $$$ISERR(tSC) Quit
			}
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If ($$$ISERR(tSC)&&pVerbose) {
		Write !
		Do $System.Status.DisplayError(tSC)
	}
	Quit tSC
}

/// This method may be called to import a container class from an xml file. This will execute
/// the <method>%OnLoad</var> method if it is defined in the container class.<br>
/// The <var>pReplace</var> parameter is deprecated in this method but remains for compatibility purposes.
ClassMethod %ImportContainer(pFileName As %String = "", pReplace As %Boolean = 1, pVerbose As %Boolean = 1) As %Status
{
	// Method added by WAL301 for symmetry
	Set tSC = $$$OK
	Set tFileNotFound = 0
	Set tClassNotFound = 0
	Try {
		Set tSC = $system.OBJ.Load(pFileName,"cf/display=none",,.tLoadedList)
	}
	Catch exFile {
		Set tSC = exFile.AsStatus()
	}
	// WAL312 -- add fallback logic so that %ImportContainer is backwards compatible
	//           If file not found, attempt to load a class as would happen before WAL301
	If ($G(exFile)="") && $$$ISERR(tSC) {
		Do DecomposeStatus^%apiOBJ(tSC,.err) 
		For i=1:1:err {
			Set:err(i,"code")=5012 tFileNotFound = 1
		}
	}
	// WAL312 -- fallback to old behavior by invoking %ProcessContainer
	Set tResourceName = $S(tFileNotFound:pFileName,1:tLoadedList)
	Set:$O(tLoadedList(""))="" tLoadedList(tResourceName_".cls")=""		// DTB542 - Add the "cls" extension to the manufactured tLoadedList
	Try {
		Set tSC = ..%ProcessContainer(tResourceName,pReplace,pVerbose,1)	
	}
	Catch exClass {
		Set tSC = exClass.AsStatus()
	}	
	If ($G(exClass)="") && $$$ISERR(tSC) {
		Do:pVerbose $system.Status.DisplayError(tSC)
		Set tClassError=1
		Set tClassErrorCode = tSC
		Do DecomposeStatus^%apiOBJ(tSC,.err) 
		For i=1:1:err {
			// WAL312 -- search string comes from %ProcessContainer below
			Set:err(i)["Class not found" tClassNotFound = 1
		}
	}
	If tClassNotFound && tFileNotFound {
		Set tSC = $$$ERROR($$$GeneralError,"Resource not found: "_tResourceName)	
	}
	// WAL312 -- Run DTB499 logic on the list of loaded files
	If '$$$ISERR(tSC) {
		If $D(tLoadedList) {
			// DTB499 - Call the %OnLoad method for each container loaded once the compile has completed
			Set tClass = $O(tLoadedList("")) 
			While tClass'="" {
				Set tClassDef = ##class(%Dictionary.CompiledClass).%OpenId($P(tClass,".",1,*-1))
				If $IsObject(tClassDef) {		// DTB542 - Final protection against a bad file name
					Write:pVerbose !," Checking "_tClassDef.Name_" for %OnLoad method"
					
					If tClassDef.Methods.FindObjectId(tClassDef.Name_"||%OnLoad") {
						Write:pVerbose !,"  Calling "_tClassDef.Name_":%OnLoad"
						
						Set tSC = $classmethod(tClassDef.Name,"%OnLoad")
						If $$$ISERR(tSC) Quit
					}
				}
				Set tClass = $O(tLoadedList(tClass))
			}
		}
	}
	Quit tSC
}

/// Import a folder item definition from the Contents XData block of the given class.<br/>
/// If <var>pReplace</var> is true, replace an existing item with the same name.<br/>
/// If <var>pVerbose</var> is true, write status to the console.<br/>
ClassMethod %ProcessContainer(pClass As %String = "", pReplace As %Boolean = 0, pVerbose As %Boolean = 1, pSuppressForCaller As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill %objlasterror
		
		// WAL312 -- be nice
		Set:$E(pClass,*-3,*)=".cls" pClass = $P(pClass,".cls",1,*-1)

		Set tClassDef = ##class(%Dictionary.ClassDefinition).%OpenId(pClass)
		If '$IsObject(tClassDef) {
			Set tSC = $$$ERROR($$$GeneralError,"Class not found: ",pClass)
			Quit
		}
		
		#; find XDATA block named Contents
		Set tIndex = tClassDef.XDatas.FindObjectId(pClass_"||Contents")

		If (tIndex '= "") {
			#; get XDATA as stream
			Set tStream = tClassDef.XDatas.GetAt(tIndex).Data
			Do tStream.Rewind()

			If (tStream.Size > 0) {
				// Create an instance of %XML.Reader
				Set tReader = ##class(%XML.Reader).%New()
	
				// Begin processing of the file
				Set tSC = tReader.OpenStream(tStream)
				If $$$ISERR(tSC) Quit

				// + WAL301 -- includes types for  non folder items now
				Set tSC = ..%GetXMLNamesForClasses(.tClasses,.tNonFolderItem)
				// - WAL301
				If $$$ISERR(tSC) Quit
				
				Set n = $O(tClasses(""))
				While (n'="") {
					Set tClassName = $LG(tClasses(n),1)
					Set tXMLName = $LG(tClasses(n),2)
					Do tReader.Correlate(tXMLName,tClassName)
					Set n = $O(tClasses(n))
				}
				
				// WAL315
				Set tItemsImported=0
				Set tProblemItems=0
				
				// Read objects from xml file
				// WAL315 -- the condition means stop the loop if we are done, but continue if we hit an error
				While (tReader.Next(.tItem,.tSC)||(tSC'=$$$OK)) {
					// + WAL301 -- check type here and hand non-folder item case
					// + WAL315 -- continue processing even if a given item fails
					Try{
						If $$$ISERR(tSC) $$$ThrowStatus(tSC) // WAL315 -- if the reader itself has a problem log it and move on
						If tItem.%IsA($$$DSLGCls) {
							Set tExists = ##class(%DeepSee.ListingGroup).%ListingGroupExists(tItem.name)
							Set tClassName = tItem.className
							Set tItem.className = ""
							If (tExists && 'pReplace) {
								Set tSC = $$$ERROR($$$GeneralError,"Item with given ID already exists and you do not have permission to replace it: "_$$$DSLGExt_" : "_tItem.name)
								$$$ThrowStatus(tSC)
							}
							ElseIf (tExists) {
								Write:pVerbose "Replacing: ",$$$DSLGExt_" : "_tItem.name,!
								Set tSC = ##class(%DeepSee.ListingGroup).%SaveListingGroup(tItem,tClassName)
								If $$$ISERR(tSC) $$$ThrowStatus(tSC)
							}
							Set tSC = ##class(%DeepSee.ListingGroup).%SaveListingGroup(tItem,tClassName)
							If $$$ISERR(tSC) $$$ThrowStatus(tSC)
							Write:pVerbose "Importing: ",$$$DSLGExt_" : "_tItem.name,!
						}
						ElseIf ($G(tNonFolderItem(tItem.%ClassName(1)))'="") {
							Set tID = tItem.getIdentifier()
							Set tExists=$classmethod(tItem.%ClassName(1),"%ExistsId",tID) 
							If (tExists && 'pReplace) {
								Set tSC = $$$ERROR($$$GeneralError,"Item with given ID already exists and you do not have permission to replace it: "_tItem.%ClassName(1)_" : "_tID)
								$$$ThrowStatus(tSC)
							}
							ElseIf (tExists) {
								Write:pVerbose "Replacing: ",tItem.%ClassName(1)_" : "_tID,!
								Set tSC = $classmethod(tItem.%ClassName(1),"%DeleteId",tID)
								If $$$ISERR(tSC) $$$ThrowStatus(tSC)
							}
							// Check pVerbose and write what is being imported
							Set tSC = tItem.%Save()
							If $$$ISERR(tSC) $$$ThrowStatus(tSC)
							Write:pVerbose "Importing: ",tItem.%ClassName(1)_" : "_tID,!
						}
						/// - WAL301
						Else {
							Set tExists = ..%FolderItemExists(tItem.fullName)
							If (tExists=2) {
								Set tSC = $$$ERROR($$$GeneralError,"Folder item with given name already exists and you do not have permission to replace it: "_tItem.fullName)
								$$$ThrowStatus(tSC)
							}
							ElseIf (tExists=1) {
								If (pReplace) {
									Write:pVerbose "Replacing: ",tItem.fullName,!
									Set tSC = ..%DeleteFolderItem(tItem.fullName)
									If $$$ISERR(tSC) $$$ThrowStatus(tSC)
								}
								Else {
									Set tSC = $$$ERROR($$$GeneralError,"Folder item with given name already exists: "_tItem.fullName)
									$$$ThrowStatus(tSC)
								}
							}
							Else {
								Write:pVerbose "Importing: ",tItem.fullName,!
							}

							// JMD1202: invoke callback
							Set tSC = tItem.%OnAfterImport()
							If $$$ISERR(tSC) $$$ThrowStatus(tSC)

							If $IsObject(tItem)&&tItem.%IsA("%DeepSee.Dashboard.Definition") {
								// DTB544 - Generate missing widget names and keys on load
								Set tSC = ##class(%DeepSee.UserPortal.Utils).AddWidgetNames(tItem)
								If $$$ISERR(tSC) $$$ThrowStatus(tSC)
							}

							Set tSC = tItem.%Save()
							If $$$ISERR(tSC) $$$ThrowStatus(tSC)

							// JMD1211 register the recent item
							Set tType = $P(tItem.fullName,".",2)
							Set tSC = ##class(%DeepSee.UserLibrary.Utils).%RegisterRecentItem(tType,tItem.fullName)
							If $$$ISERR(tSC) $$$ThrowStatus(tSC)
						}
					}
					Catch ex {
						Set tSC = ex.AsStatus()
						Do:pVerbose $system.Status.DisplayError(tSC) 
						Write:pVerbose !
						Set tProblemItems = $i(tProblemItems)
					}
					// WAL315
					If $$$ISOK(tSC) Set tItemsImported = $i(tItemsImported)
					Set tSC = $$$OK
				}
			}
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If ($$$ISERR(tSC)&&pVerbose&&'pSuppressForCaller) {
		Write !
		Do $System.Status.DisplayError(tSC)
	}
	ElseIf pVerbose {
		Write !,"Imported "_$G(tItemsImported,0)_ " item"_$S($G(tItemsImported,0)'=1:"s",1:"")_".",!	
		Write:pVerbose "Encountered "_$G(tProblemItems,0)_" error"_$S($G(tProblemItems,0)'=1:"s",1:"")_" during import.",!		// DTB659 - Protect reference
	}
	Quit tSC
}

/// Diagnostic method. Display the contents of a folder item to the console.
ClassMethod %Dump(pFolderItemName As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Set tItem = ..%OpenFolderItem(pFolderItemName,.tSC)
		If $$$ISERR(tSC) Quit

		If '$IsObject(tItem) {
			Write "Unable to find item: ",pFolderItemName,!
			Quit
		}

		Set tSC = tItem.%Dump()
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Do $System.Status.DisplayError(tSC)
	}
	Quit tSC
}

/// Does the current user have "WRITE" access to a folder?
ClassMethod %CanWriteToFolder(pFolderName As %String) As %Boolean
{
	Set tWrite = 1

	Set tFolder = ##class(%DeepSee.UserLibrary.Utils).%FindFolder(pFolderName)
	If $IsObject(tFolder) {
		Set tResource = tFolder.%GetResource()
		If ((tResource'="") && '$System.Security.Check(tResource,"WRITE")) {
			Set tWrite = 0
		}
	}
	Quit tWrite
}

ClassMethod %OpenItem(pFullName As %String = "", ByRef pStatus As %Status) As %String
{
	// Added by WAL301
	Set tTestType = $P(pFullName,".",*)
	Set tOpenName = $P(pFullName,".",1,*-1)
	If tTestType=$$$DSPVExt {
		Set tClassName = $$$DSPVCls
	}
	ElseIf tTestType=$$$DSNFExt {
		Set tClassName = $$$DSNFCls
	}
	ElseIf tTestType=$$$DSSCMExt {
		Set tClassName = $$$DSSCMCls
	}
	ElseIf tTestType=$$$DSTLExt {
		Set tClassName = $$$DSTLCls
	}
	ElseIf tTestType=$$$DSUSExt {
		Set tClassName = $$$DSUSCls
	}
	ElseIf tTestType=$$$DSLGExt {
		// No %OpenId, so grab model and bail out
		// Also use interface, not model class
		Set tClassName = ##class(%DeepSee.ListingGroup).%GetClassName(tOpenName)
		Set tItem = ##class(%DeepSee.ListingGroup).%GetModel(tClassName)
		Set tItem.className = tClassName
		Quit tItem
	}
	Else {
		Quit ""	
	}
	Quit $classmethod(tClassName,"%OpenId",tOpenName)
}

ClassMethod %IsNotFolderItem(pFullName As %String = 0) As %Boolean
{
	// Added by WAL301
	Set tTestName = $P(pFullName,".",*)
	Set tNFITypes($$$DSPVExt)=1
	Set tNFITypes($$$DSNFExt)=1
	Set tNFITypes($$$DSSCMExt)=1
	Set tNFITypes($$$DSTLExt)=1
	Set tNFITypes($$$DSLGExt)=1
	Set tNFITypes($$$DSUSExt)=1
	Quit $G(tNFITypes(tTestName))'=""
}

ClassMethod %ExpandItemList(ByRef pItemList As %String, pVerbose As %Boolean = 1) As %Status
{
	// Method added by WAL301
	Set tSC = $$$OK
	Try {
		// Iterate through item list
		Set tName = $O(pItemList(""))
		While tName'="" {
			// Assume full names
			Set tType=$P(tName,".",*)
			Set tShortName = $P(tName,".",1,*-1)
			
			// + WAL315 -- validate types, skip non-existent types
			If ('..%ValidateItemType(tType,.tProblem)) {
				Write:(pVerbose && ($G(tProblem)'="")) !,"Type "_$P(tProblem,":",1)_" does not exist, did you mean: "_$P(tProblem,":",2)_"?"
				Write:pVerbose !,"Type: "_tType_" not found, skipping export.",!
				Kill pItemList(tName)
				Set tName = $O(pItemList(tName))
				Continue
			}
			// - WAL315
			
			// Get everything
			If (tType="*")&&(tShortName="*") {
				Kill pItemList(tName)
				Set tSC = ..%GetItemsForType("*",.pItemList,pVerbose)
			}
			// Get all of this type
			ElseIf (tShortName="*")&&(tType'="*") {
				Kill pItemList(tName)
				Write:pVerbose !,"Exporting every item of type '" _ tType _ "'..."		// DTB514 - 
				Set tSC = ..%GetItemsForType(tType,.pItemList,pVerbose)
			}
			If $$$ISERR(tSC) Quit
			Set tName = $O(pItemList(tName))
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()	
	}
	Quit tSC
}

ClassMethod %GetItemsForType(pType, ByRef pItemList, pVerbose As %Boolean = 1)
{
	// Method added by WAL301
	Set tSC = $$$OK
	Try {
		// Get mappings
		Set tSC = ..%GetXMLNamesForClasses(.tClasses)
		If $$$ISERR(tSC) Quit
		
		Set tIdx = $O(tClasses(""))
		While tIdx'="" {
			Set tInfo = tClasses(tIdx)
			Set tInfoClass = $LG(tInfo,1)
			Set tInfoType = $LG(tInfo,2)
			
			// WAL301
			// Don't expand termlist or listing group -- need to handle these two types
			If (tInfoType'=$$$DSTLExt)&&(tInfoType'=$$$DSLGExt) {
				Set tInfoTable = ##class(%DeepSee.Utils).%GetSQLTableName(tInfoClass)
				If (pType=tInfoType)||(pType="*") {
					Set tQuery="SELECT FULLNAME FROM "_ tInfoTable
	  				Set tRS=##class(%ResultSet).%New()
	  				Set tSC=tRS.Prepare(tQuery)
	  				If $$$ISERR(tSC) Quit
	  				Set tSC=tRS.Execute()
	  				If $$$ISERR(tSC) Quit
	     			While tRS.Next() {
	     				Set:tRS.GetData(1)'="" pItemList(tRS.GetData(1))=""
	     			}
				}
			}
			ElseIf ((pType=tInfoType)||(pType="*"))&&(tInfoType=$$$DSTLExt) {
				K tTL
				Set tSC = ##class(%DeepSee.TermList).%GetTermLists(.tTL)
				Set tTLIdx = $O(tTL(""))	
				While tTLIdx'="" {
					Set tTLInfo = tTL(tTLIdx)
					Set pItemList($LG(tTLInfo,1)_"."_$$$DSTLExt)=""
					Set tTLIdx = $O(tTL(tTLIdx))	
				}
			}
			ElseIf ((pType=tInfoType)||(pType="*"))&&(tInfoType=$$$DSLGExt) {
				K tLG
				Set tSC = ##class(%DeepSee.ListingGroup).%GetListingGroups(.tLG)
				Set tLGName = $O(tLG(""))	
				While tLGName'="" {
					Set pItemList(tLGName_"."_$$$DSLGExt)=""
					Set tLGName = $O(tLG(tLGName))	
				}
			}
			Set tIdx = $O(tClasses(tIdx))
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()	
	}
	Quit tSC
}

ClassMethod %ValidateItemType(pType As %String, ByRef pProblem As %String) As %Boolean
{
	Kill pProblem
	Set tMatch = 0
	Set tSC = ..%GetXMLNamesForClasses(.tTypeList)
	// Ignore status
	Set tTypeIdx = $O(tTypeList(""))
	While tTypeIdx'="" {
		Set tType = $LG(tTypeList(tTypeIdx),2)
		If ((pType="*") || (pType=tType)) { 
			Set tMatch=1
			Quit
		}
		ElseIf ($$$UPPER(pType)=$$$UPPER(tType)) {
			Set pProblem = pType_":"_tType
			Quit
		}
		Set tTypeIdx = $O(tTypeList(tTypeIdx))
	}
	Quit tMatch
}

/// Get the related DeepSee items for a dashboard or pivot table. All items related to the
/// target item <var>pItem</var> will be returned in the <var>pRelItems</var> array. Related
/// items are returned indexed by a single "all" node and by type:<br>
/// <var>pRelItems</var>("all",<var>pItem</var>)=""<br>
/// <var>pRelItems</var>("type","itemType",<var>pItem</var>)=""<br>
ClassMethod %GetRelatedItems(pItem As %String, ByRef pRelItems, pVerbose As %Boolean = 1) As %Status
{
	// Method added by DTB514
	// check the type, then call the method for that type (pivot or dashboard)
	Set tSC = $$$OK
	
	Try {
		Set tType = $p(pItem,".",*)
		If tType = "pivot" {
			Set tSC = ..%GetRelatedItemsForPivot(pItem,.pRelItems,pVerbose)
			If $$$ISERR(tSC) Quit
		}
		ElseIf tType = "dashboard" {
			Set tSC = ..%GetRelatedItemsForDashboard(pItem,.pRelItems,pVerbose)
			If $$$ISERR(tSC) Quit
		}
		Else {
			Set tErrorMsg = "Unsupported type for %GetRelatedItems: '"_tType_"'"
			Write:pVerbose !,tErrorMsg
			Set tSC = $$$ERROR($$$GeneralError,tErrorMsg)
			Quit
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get the related DeepSee items for a pivot table.
ClassMethod %GetRelatedItemsForPivot(pItem As %String, ByRef pRelItems, pVerbose As %Boolean = 1) As %Status
{
	// Method added by DTB514
	Set tSC = $$$OK
	
	Try {
		// Open the pivot
		Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pItem,.tSC)
		If '$IsObject(tPivot) {
			Do:pVerbose $system.OBJ.DisplayError(tSC) 
			Quit 
		}
		Write:pVerbose !,"Pivot Name: ",tPivot.fullName
		
		// Get cube/subject for the pivot
		set tCubeName = tPivot.cubeName
		
		Set tSC = ..%GetRelatedItemsForCube(tCubeName,.pRelItems,pVerbose)
		If $$$ISERR(tSC) Quit
		
		// If tCubeName is a subject area, then get related items for the base cube
		Set tBaseCube = ##class(%DeepSee.Utils).%GetBaseCube(tCubeName)	
		If tBaseCube '= "" {
			Set tSC = ..%GetRelatedItemsForCube(tBaseCube,.pRelItems,pVerbose)
			If $$$ISERR(tSC) Quit
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get the related DeepSee items for a cube/subject area.
ClassMethod %GetRelatedItemsForCube(pCubeName As %String, ByRef pRelItems, pVerbose As %Boolean = 1) As %Status
{
	// Method added by DTB514
	Set tSC = $$$OK
	Try {
		Write:pVerbose !,"Cube: ",pCubeName

		// Get related items for cube/subject (pivot variables, named filters, shared calculated members)

		// Get pivot variables for the cube/subject
		Set tSC = ##class(%DeepSee.Utils).%GetPivotVariables(pCubeName,.tVars)
		If $$$ISERR(tSC) Quit
		If $$$ISERR(tSC) Quit
		If pVerbose {
			Write !,"Pivot Variables:",!
			ZW tVars
		}
		
		Set tVariable = $O(tVars(""),1,tVariableInfo)
		While (tVariable'="") {
			// The same item name across multiple cubes is supported. Exports require the 
			//   CubeName||ItemName.type
			// construct.
			Set tVariableName = $List(tVariableInfo,1)
			
			If $D($$$DeepSeeVariablesGLVN($$$UPPER(pCubeName),$$$UPPER(tVariableName))) {
				Set tVariableIdent = pCubeName_"||"_tVariableName_".pivotVariable"
				Set tSC = ..%AddRelatedItem(tVariableIdent,.pRelItems,pVerbose)
				If $$$ERROR(tSC) $$$ThrowStatus(tSC)
			}
			
			Set tVariable = $O(tVars(tVariable),1,tVariableInfo)
		}


		// Get named filters for the cube/subject
		Set tSC = ##class(%DeepSee.Utils).%GetNamedFilters(pCubeName,.tNamedFilters)
		If $$$ISERR(tSC) Quit
		If pVerbose { 
			Write !,"Named Filters:",! 
			ZW tNamedFilters
		}
		
		Set tFilter = $O(tNamedFilters(""),1,tFilterInfo)
		While (tFilter'="") {
			// The same item name across multiple cubes is supported. Exports require the 
			//   CubeName||ItemName.type
			// construct.
			Set tFilterName = $List(tFilterInfo,1)
			
			If $D($$$DeepSeeFiltersGLVN($$$UPPER(pCubeName),$$$UPPER(tFilterName))) {
				Set tFilterIdent = pCubeName_"||"_tFilterName_".namedFilter"
				Set tSC = ..%AddRelatedItem(tFilterIdent,.pRelItems,pVerbose)
				If $$$ERROR(tSC) $$$ThrowStatus(tSC)
			}
			
			Set tFilter = $O(tNamedFilters(tFilter),1,tFilterInfo)
		}
		
		
		// Get shared calculated members for the cube/subject
		Set tSC = ##class(%DeepSee.Utils).%GetSharedCalcMembers(pCubeName,.tSharedCalcMbrs)
		If $$$ISERR(tSC) Quit
		If pVerbose {
			Write !,"Shared Calc Members:",! 
			ZW tSharedCalcMbrs
		}
		
		Set tCalcMbr = $O(tSharedCalcMbrs(""),1,tCalcMbrInfo)
		While (tCalcMbr'="") {
			// The same item name across multiple cubes is supported. Exports require the 
			//   CubeName||Dimension||ItemName.type
			// construct.
			Set tCalcMbrDim = $LG(tCalcMbrInfo,1)
			Set tCalcMbrName = $LG(tCalcMbrInfo,2)
			
			If $D($$$DeepSeeSharedCalcGLVN($$$UPPER(pCubeName),$$$UPPER(tCalcMbrDim),$$$UPPER(tCalcMbrName))) {
				Set tCalcMbrIdent = pCubeName_"||"_tCalcMbrDim_"||"_tCalcMbrName_".sharedCalcMember"		// DTB667 - Fix the ID to correct the lookup
				Set tSC = ..%AddRelatedItem(tCalcMbrIdent,.pRelItems,pVerbose)
				If $$$ERROR(tSC) $$$ThrowStatus(tSC)
			}
			
			Set tCalcMbr = $O(tSharedCalcMbrs(tCalcMbr),1,tCalcMbrInfo)
		}
		
		// DTB539 - Get listing groups for the cube/subject
		Set tSC = ##class(%DeepSee.ListingGroup).%GetListingGroups(.tListingGroups,1,pCubeName)
		If $$$ISERR(tSC) Quit
		If pVerbose {
			Write !,"Listing Groups:",! 
			ZW tListingGroups
		}
		
		Set tLgId = $O(tListingGroups(""),1,tListingGroupInfo)
		While (tLgId'="") {
			// Only a single item of the same name per cube is supported. Exports require the
			//   ItemName.type
			// identifier.
			Set tListingGroupName = $List(tListingGroups(tLgId,1),2)
			
			Set tListingGroupIdent = tListingGroupName_".listingGroup"
			Set tSC = ..%AddRelatedItem(tListingGroupIdent,.pRelItems,pVerbose)
			If $$$ERROR(tSC) $$$ThrowStatus(tSC)
						
			Set tLgId = $O(tListingGroups(tLgId),1,tListingGroupInfo)
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get the related DeepSee items for a dashboard.
ClassMethod %GetRelatedItemsForDashboard(pItem As %String, ByRef pRelItems, pVerbose As %Boolean = 1) As %Status
{
	// Method added by DTB514
	Set tSC = $$$OK
	
	Try {
		Set tDash = ##class(%DeepSee.Dashboard.Utils).%OpenDashboard(pItem,.tSC)
		If '$IsObject(tDash) {
			Quit
		}
		Write:pVerbose !,"Dashboard Name: ",tDash.fullName
		// Loop through all widgets on the dashboard
		Set tWidgetCount = tDash.widgets.Count()
		For tWidgetIndex=1:1:tWidgetCount {
			Set tWidget = tDash.widgets.GetAt(tWidgetIndex)

			// Widget data source
			Set tDataSource = tWidget.dataSource
			If ($P(tDataSource,".",*)="pivot") {
				Set tSC = ..%AddRelatedItem(tDataSource,.pRelItems,pVerbose)
				If $$$ISERR(tSC) $$$ThrowStatus(tSC)
				
				Set tSC = ..%GetRelatedItemsForPivot(tDataSource,.pRelItems,pVerbose)
				If $$$ISERR(tSC) $$$ThrowStatus(tSC)
			}
			
			// Widget theme
			Set tTheme = tWidget.theme
			If (tTheme'="") { 
				Set tSC = ..%AddRelatedItem(tTheme,.pRelItems,pVerbose)
				If $$$ISERR(tSC) $$$ThrowStatus(tSC)
			}
			
			// Data Driven Colors
			Set tColorsList = tWidget.dataColorList
			If (tColorsList'="") { 
				Set tSC = ..%AddRelatedItem(tColorsList,.pRelItems,pVerbose)
				If $$$ISERR(tSC) $$$ThrowStatus(tSC)
			}

			If pVerbose {
				Write !
				Write:(tDataSource'="") ?5,"Data Source: ",tDataSource,!
				Write:(tTheme'="") ?5,"Theme: ",tTheme,!
				Write:(tColorsList'="") ?5,"Data Colors: ",tColorsList,!
			}

			//loop through the widget controls
			Set tControlCount = tWidget.controls.Count()
	 		For c=1:1:tControlCount {
				Set tControl = tWidget.controls.GetAt(c)
				Set tControlAction = tControl.action
				Write:pVerbose ?10,"Control Action: ",tControlAction,!

				// Some control actions reference pivots, dashboards, termlists, pivot variables
				If (tControlAction="setDataSource") {
					Set tSetDataSource = tControl.targetProperty
					// If the data source is a pivot, add it, then get related items for the pivot
					If ($P(tSetDataSource,".",*)="pivot") {
						Set tSC = ..%AddRelatedItem(tSetDataSource,.pRelItems,pVerbose)
						If $$$ISERR(tSC) $$$ThrowStatus(tSC)
						
						Set tSC = ..%GetRelatedItemsForPivot(tSetDataSource,.pRelItems,pVerbose)
						If $$$ISERR(tSC) $$$ThrowStatus(tSC)
					}
				} 
				ElseIf (tControlAction="viewDashboard") {
					Set tViewDashboard = tControl.targetProperty
					If (tViewDashboard'="") {
						Set tSC = ..%AddRelatedItem(tViewDashboard,.pRelItems,pVerbose)
						If $$$ISERR(tSC) $$$ThrowStatus(tSC)
					}
					// Get related items for the viewDashboard target
					Set tSC = ..%GetRelatedItemsForDashboard(tViewDashboard,.pRelItems,pVerbose)
					If $$$ISERR(tSC) $$$ThrowStatus(tSC)
				}
				ElseIf tControlAction = "chooseDataSource" {
					Set tDataSourceList = tControl.targetProperty
					Kill tDataSourceArray
					If (tDataSourceList'="") {
						Set tSC = ..%AddRelatedItem(tDataSourceList,.pRelItems,pVerbose)
						If $$$ISERR(tSC) $$$ThrowStatus(tSC)
						
						// If termlist exists, Add the data sources from the termlist
						Set tDataSourceListName = $P(tDataSourceList,".termlist",1)
						If ##class(%DeepSee.TermList).%TermListExists(tDataSourceListName) {
							Set tSC = ##class(%DeepSee.TermList).%GetValueArray(tDataSourceListName,.tDataSourceArray)
							If $$$ISERR(tSC) $$$ThrowStatus(tSC)
							ZW:pVerbose tDataSourceArray
							
							Set tListItem = $O(tDataSourceArray(""),1,tListDataSource)
							While (tListItem'="") {
								// If the data source is a pivot, then get related items for the pivot
								If ($P(tListDataSource,".",*)="pivot") {
									Set tSC = ..%AddRelatedItem(tListDataSource,.pRelItems,pVerbose)
									If $$$ISERR(tSC) $$$ThrowStatus(tSC)
									
									Set tSC = ..%GetRelatedItemsForPivot(tListDataSource,.pRelItems,pVerbose)
									If $$$ISERR(tSC) $$$ThrowStatus(tSC)
								}
								
								Set tListItem = $O(tDataSourceArray(tListItem),1,tListDataSource)
							}
						}
					}
				}
				ElseIf tControlAction = "chooseRowSpec" {
					Set tRowSpecList = tControl.targetProperty
					If (tRowSpecList'="") {
						Set tSC = ..%AddRelatedItem(tRowSpecList,.pRelItems,pVerbose)
						If $$$ISERR(tSC) $$$ThrowStatus(tSC)
					}
				}
				ElseIf tControlAction = "chooseColumnSpec" {
					Set tColumnSpecList = tControl.targetProperty
					If (tColumnSpecList'="") {
						Set tSC = ..%AddRelatedItem(tColumnSpecList,.pRelItems,pVerbose)
						If $$$ISERR(tSC) $$$ThrowStatus(tSC)
					}
				}
				ElseIf tControlAction = "applyVariable" {
					Set tPivotVariable = tControl.targetProperty
					If (tPivotVariable'="") {
						// DTB514 - Omit this from the list at this time. In order to be effective a pivot variable *must*
						// be defined in one of the dataSOurces as well and it will be added to the list on a per-cube
						// basis later.
						
						//Set tPivotVariable = $P(tPivotVariable,"$variable.",*)_".pivotVariable"
						//Set tSC = ..%AddRelatedItem(tPivotVariable,.pRelItems,pVerbose)
						//If $$$ISERR(tSC) $$$ThrowStatus(tSC)
					}
				}
			}
		}
		
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Add a new <var>pItem</var> to the <var>pRelItems</var> array. A type extension is expected on the
/// <var>pItem</var> input, for example
/// <example language=cos>Set status = ##class(%DeepSee.UserLibrary.Utils).%AddRelatedItem("itemName.itemType",.relatedItems)
/// </example>
ClassMethod %AddRelatedItem(pItem As %String, ByRef pRelItems, pVerbose As %Boolean = 1) As %Status [ Internal ]
{
	// Method added by DTB514
	// The "all" nodes indicate all related items regardless of type
	Set tSC = $$$OK
	
	Try {
		Write:pVerbose !,?4,"Adding item: ",pItem		// DTB667 - Make verbose more informative
		
		Set pRelItems("all",pItem)=""
		
		// The "type" nodes group the items by type
		Set tType = $p(pItem,".",*)
		If tType'="" {
			Set pRelItems("type",tType,pItem)=""
		}
		Else {
			Set tSC = $$$ERROR($$$GeneralError,"Type must be defined for related export item: " _ pItem)
			Quit
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

}
