/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Atelier.v1.Utils.Extension Extends %RegisteredObject [ Owner = {%Developer} ]
{

/// For use from the Query API
/// Through DocDB ExecuteQuery, items (a JSON string) is automatically converted to a nested object.
Query GetMenus(pMenuType As %String = "", pInternalName As %String = "", pSelectedText As %String = "") As %Query(ROWSPEC = "id:%String,name:%String,type:%String,items:%String") [ Internal, SqlProc ]
{
}

ClassMethod GetMenusExecute(ByRef qHandle As %Binary, pMenuType As %String = "", pInternalName As %String = "", pSelectedText As %String = "") As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tMenuPart As %DynamicObject
	#dim e As %Exception.AbstractException
	
	Try {
		Set tSC = ..GetMenuHelper(pMenuType, pInternalName, pSelectedText, .tMenuPart)
		Quit:$$$ISERR(tSC)
		
		// Technically, Studio extensions can output to the console while the menu is being rendered.
		// This is kind of weird, and isn't worth supporting going forward unless there's a *really* good reason.
		// Anyway, just render the menu part for now.
		// Each menu is a row in the result set.
		Set qHandle = {
			"iterator":(tMenuPart.menus.%GetIterator()),
			"key":"",
			"collection":(tMenuPart.menus)
		}
	} Catch (e) {
		Set tSC = e.AsStatus()
	}
	Quit tSC
}

ClassMethod GetMenusFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = ExtensionMenusExecute ]
{
	#dim tRow As %DynamicObject
	
	Do qHandle.iterator.%GetNext(,.tRow)
	If '$IsObject(tRow) {
		Set AtEnd = 1
	} Else {
		Set Row = $ListBuild(tRow.id,tRow.name,tRow.type,tRow.items.%ToJSON())
	}
	Quit $$$OK
}

ClassMethod GetMenusClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = ExtensionMenusExecute ]
{
	Quit $$$OK
}

/// Core code for getting menus
ClassMethod GetMenuHelper(pMenuType As %String, pInternalName As %String, pSelectedText As %String, Output pMenuPart As %DynamicObject) As %Status
{
	#define Domain "%Studio"
	#define MenuMessage(%id) $Case(%id,"":"",:$Get(^IRIS.Msg($$$Domain,$$$SessionLanguage,%id),$Get(^%qMsg($$$Domain,$$$SessionLanguage,%id),%id)))
	
	#dim tSC As %Status
	#dim tMenuList As %DynamicArray
	#dim %SourceControl As %Studio.Extension.Base
	#dim tMenuListResult,tMenuItemResult As %SQL.StatementResult
	#dim tEnabled As %Boolean
	#dim tDisplayName As %String
	#dim e As %Exception.AbstractException
	
	Try {
		
		#; If no current instance, create a new one
		If '$IsObject($Get(%SourceControl)) {
			New %SourceControl
			Set tSC = ..InitializeSourceControl()
			Quit:$$$ISERR(tSC)
		}
		
		// Ensure internal name is in correct format.
		Set pInternalName = ..ExtensionDocName(pInternalName)
		
		// Get list of menus with their items
		Set tMenuList=##class(%DynamicArray).%New()
		If $IsObject($Get(%SourceControl)) { //No-op if source control isn't enabled for the namespace
			Set tMenuListQuery=##class(%SQL.Statement).%New()
			Set tMenuItemQuery=##class(%SQL.Statement).%New()
			Set tSC = tMenuListQuery.%PrepareClassQuery("%Studio.SourceControl.Interface","MainMenus")
			If $$$ISERR(tSC) Quit
			Set tSC = tMenuItemQuery.%PrepareClassQuery("%Studio.SourceControl.Interface","MenuItems")
			If $$$ISERR(tSC) Quit
			Set tMenuListResult=tMenuListQuery.%Execute()
			While (tMenuListResult.%Next(.tSC)) {
				If $$$ISERR(tSC) Quit
				If (pMenuType = "") || (tMenuListResult.%Get("Type") = $Case(pMenuType,"main":0,"context":1)) {
					Set tMenu = ##class(%DynamicObject).%New()
					Set tMenu.id = tMenuListResult.%Get("Name")
					Set tMenu.name = tMenuListResult.%Get("DisplayName")
					Set tMenu.type = $Case(tMenuListResult.%Get("Type"),0:"main",1:"context")
					Set tMenu.items = ##class(%DynamicArray).%New()
					Set tMenuItemResult=tMenuItemQuery.%Execute(tMenuListResult.%Get("Name"),pInternalName,pSelectedText)
					While (tMenuItemResult.%Next(.tSC)) {
						If $$$ISERR(tSC) Quit
						
						Set tMenuItem = ##class(%DynamicObject).%New()
						Set tMenuItem.id = tMenuItemResult.%Get("Name")
						Set tMenuItem.enabled = +tMenuItemResult.%Get("Type")
						Set tMenuItem.name = tMenuItemResult.%Get("DisplayName")
						Set tMenuItem.save = +tMenuItemResult.%Get("SaveFlag")
						Set tMenuItem.separator = tMenuItemResult.%Get("Separator")
						
						Do tMenu.items.%Push(tMenuItem)
					}
					Do tMenuList.%Push(tMenu)
					
					// The following kill is necessary to force %Close, which cleans up some % variables
					// used in the Fetch method of %Studio.SourceControl.Interface:MenuItems.
					// Otherwise, this would happen at a different point and cause <UNDEFINED> errors in
					// that method.
					Kill tMenuItemResult
				}
				If $$$ISERR(tSC) Quit
			}
			If $$$ISERR(tSC) Quit
		}

		Set pMenuPart=##class(%DynamicObject).%New()
		Set pMenuPart.menus = tMenuList
	} Catch (e) {
		Set tSC = e.AsStatus()
	}
	
	Quit tSC
}

/// For use from the Query API
/// Submits a user action in a Studio Extension
Query UserAction(pSystem As %Boolean, pAction As %String, pInternalName As %String, pSelectedText As %String) As %Query(ROWSPEC = "action:%Integer,target:%String,message:%String,reload:%Boolean,doc:%String,errorText:%String") [ Internal, SqlProc ]
{
}

ClassMethod UserActionExecute(ByRef qHandle As %Binary, pSystem As %Boolean, pAction As %String, pInternalName As %String, pSelectedText As %String) As %Status
{
	#dim tSC,tActionStatus As %Status = $$$OK
	#dim %SourceControl As %Studio.Extension.Base
	#dim tAction As %Boolean
	#dim tTarget,tMsg As %String
	#dim tReload As %Boolean
	#dim e As %Exception.AbstractException
	
	Try {
		
		#; If no current instance, create a new one
		If '$IsObject($Get(%SourceControl)) {
			New %SourceControl
			Set tSC = ..InitializeSourceControl()
			Quit:$$$ISERR(tSC)
		}
		
		Set qHandle=##class(%DynamicObject).%New()
		If $IsObject($Get(%SourceControl)) {
			Set pInternalName = ..ExtensionDocName(pInternalName)
			Set tActionStatus = ##class(%Studio.SourceControl.Interface).UserAction(pSystem, pAction, pInternalName, pSelectedText, .tAction, .tTarget, .tMsg, .tReload)

			If $$$ISOK(tSC) {
				#; Transform result of executing the action to the http response
				Set qHandle.action = +$Get(tAction)
				Set qHandle.target = $Get(tTarget)
				Set qHandle.message = $Get(tMsg)
				Set qHandle.reload = +$Get(tReload)
				If qHandle.reload {
					Set tSC = ..AppendDocument(qHandle,pInternalName)
					If $$$ISERR(tSC) Quit
				}
			}
			
			Do ..AppendStatusContent(qHandle,tActionStatus) //An error message from UserAction is an error message the user should see.
		} Else {
			Set qHandle = ""
		}
	} Catch (e) {
		Set tSC = e.AsStatus()
	}
	Quit tSC
}

ClassMethod UserActionFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = UserActionExecute ]
{
	#dim tDocJSON As %String
	If $IsObject(qHandle) {
		Set tDocJSON = $Select($IsObject(qHandle.doc):qHandle.doc.%ToJSON(),1:"")
		Set Row = $ListBuild(qHandle.action,qHandle.target,qHandle.message,qHandle.reload,tDocJSON,qHandle.errorText)
	}
	Set AtEnd = 1 //This query only ever returns one row.
	Quit $$$OK
}

ClassMethod UserActionClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = UserActionExecute ]
{
	Quit $$$OK
}

/// For use from the Query API
/// Handles a user's response after a user action in a Studio Extension
Query AfterUserAction(pSystem As %Boolean, pAction As %String, pInternalName As %String, pAnswer As %Integer, pMessage As %String) As %Query(ROWSPEC = "message:%String,reload:%Boolean,doc:%String,errorText:%String") [ Internal, SqlProc ]
{
}

ClassMethod AfterUserActionExecute(ByRef qHandle As %Binary, pSystem As %Boolean, pAction As %String, pInternalName As %String, pAnswer As %Integer, pMessage As %String) As %Status
{
	#dim tSC,tActionStatus As %Status = $$$OK
	#dim %SourceControl As %Studio.Extension.Base
	#dim tReload As %Boolean
	#dim e As %Exception.AbstractException
	
	Try {
		
		#; If no current instance, create a new one
		If '$IsObject($Get(%SourceControl)) {
			New %SourceControl
			Set tSC = ..InitializeSourceControl()
			Quit:$$$ISERR(tSC)
		}
		
		Set qHandle=##class(%DynamicObject).%New()
		If $IsObject($Get(%SourceControl)) {
			Set pInternalName = ..ExtensionDocName(pInternalName)
			Set tActionStatus = ##class(%Studio.SourceControl.Interface).AfterUserAction(pSystem, pAction, pInternalName, pAnswer, .pMessage, .tReload)

			If $$$ISOK(tSC) {
				#; Transform result of executing the action to the http response
				Set qHandle.message = $Get(pMessage)
				Set qHandle.reload = +$Get(tReload)
				If qHandle.reload {
					Set tSC = ..AppendDocument(qHandle,pInternalName)
					If $$$ISERR(tSC) Quit
				}
			}
			
			Do ..AppendStatusContent(qHandle,tActionStatus) //An error message from UserAction is an error message the user should see.
		} Else {
			Set qHandle = ""
		}
	} Catch (e) {
		Set tSC = e.AsStatus()
	}
	Quit tSC
}

ClassMethod AfterUserActionFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = AfterUserActionExecute ]
{
	#dim tDocJSON As %String
	If $IsObject(qHandle) {
		Set tDocJSON = $Select($IsObject(qHandle.doc):qHandle.doc.%ToJSON(),1:"")
		Set Row = $ListBuild(qHandle.message,qHandle.reload,tDocJSON,qHandle.errorText)
	}
	Set AtEnd = 1 //This query only ever returns one row.
	Quit $$$OK
}

ClassMethod AfterUserActionClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = AfterUserActionExecute ]
{
	Quit $$$OK
}

/// For use from the Query API
/// Gets status of one or more (comma-separated) items
/// May be multiple items to reduce network traffic if refactoring/etc. would edit many files at the same time.
Query GetStatus(pInternalNames As %String) As %Query(ROWSPEC = "name:%String,inSourceControl:%Boolean,editable:%Boolean,isCheckedOut:%Boolean,checkedOutBy:%String") [ Internal, SqlProc ]
{
}

ClassMethod GetStatusExecute(ByRef qHandle As %Binary, pInternalNames As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim %SourceControl As %Studio.Extension.Base
	#dim tPtr As %Integer
	#dim tName,checkedOutBy As %String
	#dim inSourceControl,editable,checkedOut As %Boolean
	#dim tItemList As %List
	#dim e As %Exception.AbstractException
	
	Try {
		
		#; If no current instance, create a new one
		If '$IsObject($Get(%SourceControl)) {
			New %SourceControl
			Set tSC = ..InitializeSourceControl()
			Quit:$$$ISERR(tSC)
		}
		
		If $IsObject($Get(%SourceControl)) {
			Set pInternalNames = $ListFromString(..ExtensionDocName(pInternalNames))
			Set tPtr = 0
			Set tItemList = ""
			While $ListNext(pInternalNames,tPtr,tName) {
				$$$ThrowOnError(##class(%Studio.SourceControl.Interface).GetStatus(tName,.inSourceControl,.editable,.checkedOut,.checkedOutBy))
				Set tItemList = tItemList_$ListBuild($ListBuild(tName,inSourceControl,editable,checkedOut,checkedOutBy))
			}
			
			Set qHandle = $ListBuild(tItemList,0)
		} Else {
			// Show no results.
			Set qHandle = $ListBuild("",0)
		}
	} Catch (e) {
		Set tSC = e.AsStatus()
	}
	Quit tSC
}

ClassMethod GetStatusFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = GetStatusExecute ]
{
	#dim tPtr As %Integer
		
	Set tPtr = $ListGet(qHandle,2)
	If $ListNext($ListGet(qHandle),tPtr,Row) {
		Set $List(qHandle,2) = tPtr
	} Else {
		Set AtEnd = 1
	}
	Quit $$$OK
}

ClassMethod GetStatusClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = GetStatusExecute ]
{
	Quit $$$OK
}

/// Returns 0 if no source control class is configured in the current namespace, and 1 if one is.
ClassMethod ExtensionEnabled() As %Boolean [ SqlProc ]
{
	Set tClass = ##class(%Studio.SourceControl.Interface).SourceControlClassGet()
	Quit (tClass '= "")
}

/// Initializes the Source Control object.
/// Returns an error status if there was an error doing so.
ClassMethod InitializeSourceControl() As %Status [ Internal, Private ]
{
	#dim tSC As %Status = $$$OK
	#dim %SourceControl As %Studio.SourceControl.Base
	#dim e As %Exception.AbstractException
	
	Try {
		#; Create the source control class (if any)
		Set tSC=##class(%Api.Atelier.v1).CreateSourceControlClass()
	} Catch (e) {
		Set tSC=e.AsStatus()
	}
	
	Quit tSC
}

/// <b>ExtensionDocName</b> Up cases DocName type, the way Studio extensions expect to deal with.<br />
/// If there are multiple document names, all extensions are up-cased.<br />
/// CSP files (those starting with a forward slash) are an exception - the case is unchanged, to match Studio's behavior.
ClassMethod ExtensionDocName(pDocName As %String) As %String [ Internal, Private ]
{
	#dim tDocList,tDocs,tPtr,tDoc,tValue
	Set tDocList = $ListFromString(pDocName), tDocs = "", tPtr = 0
	While $ListNext(tDocList,tPtr,tValue) {
		Set:$Extract(tValue)'="/" $Piece(tValue,".",*) = $Zcvt($Piece(tValue,".",*),"U")
		Set tDocs = tDocs_$Case(tDocs,"":"",:",")_tValue
	}
	Quit tDocs
}

/// Appends a %DynamicArray (pSourceArray) to another (pTargetArray); returns pTargetArray.
ClassMethod AppendArray(pTargetArray As %DynamicArray, pSourceArray As %DynamicArray) As %DynamicArray [ Internal, Private ]
{
	#dim tKey,tValue
	#dim tIter As %Iterator.Array = pSourceArray.%GetIterator()
	
	While tIter.%GetNext(.tKey,.tValue) {
		Do pTargetArray.%Push(tValue)
	}
	Quit pTargetArray
}

/// Sets the text of the document named by pInternalName as the doc property of pResponseObject.
ClassMethod AppendDocument(pResponseObject As %DynamicObject, pInternalName As %String) As %Status [ Internal, Private ]
{
	#dim tSC As %Status = $$$OK
	#dim tTextArray
	#dim tHash As %String
	#dim tDocObject As %DynamicObject
	#dim e As %Exception.AbstractException
	
	Try {
		If '##class(%Atelier.v1.Utils.General).ValidateDocName(pInternalName,.tSC,,.tBinary) {
			Quit
		}
		If $$$ISERR(tSC) Quit
		Set tSC = ##class(%Atelier.v1.Utils.TextServices).GetTextAsArray(pInternalName,,.tTextArray,tBinary)
		If $$$ISERR(tSC) Quit
		Set tHash=##class(%Atelier.v1.Utils.General).TS(pInternalName)
	    Set tSC=##class(%Atelier.v1.Utils.General).CreateDocumentObject(.tDocObject,.tTextArray,pInternalName,$$$OK,tHash)
	    If $$$ISERR(tSC) Quit
		Set pResponseObject.doc = tDocObject
	} Catch (e) {
		Set tSC = e.AsStatus()
	}
	Quit $$$OK
}

/// Sets the error text of pStatus as the errorText property of pResponseObject if pStatus is an error.
ClassMethod AppendStatusContent(pResponseObject As %DynamicObject, pStatus As %Status) [ Internal, Private ]
{
	Set pResponseObject.errorText = $Select(pStatus:"",1:$System.Status.GetErrorText(pStatus))
}

}
