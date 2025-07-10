/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsSR)

/// This class is for InterSystems internal use.
Class Ens.Setting.Reporter Extends %RegisteredObject [ System = 4 ]
{

/// This can be used to override the SettingNamePattern parameter from report class.
Property SettingNamePattern As %String;

/// If AllNamespaces then SearchNamespaces array will be rebuilt for each search.
Property AllNamespaces As %Boolean [ InitialExpression = 0 ];

/// If not searching all namespaces  and SearchNamespaces not defined specify one namespace to search - or populate ..SearchNamespaces() array
Property SpecificNamespace As %String(MAXLEN = 255) [ InitialExpression = {$Namespace} ];

/// Namespaces on this instance to search
/// Subscripted by Namespace. Data is Production to search.
/// If Data empty then the active production for the namespace is used.
Property SearchNamespaces As %String [ MultiDimensional ];

/// Array of local instance results subscripted by Namespace
Property LocalResults As %String [ MultiDimensional ];

/// After searching convert LocalResults to an array of
/// %DynamicArray objects in  <property>LocalResultsAsJSON</property>
Property StoreLocalResultsAsJSON As %Boolean [ InitialExpression = 0 ];

/// If <property>StoreLocalResultsAsJSON</property> is true then this property
/// allows for removing contents of LocalResults
Property RemoveLocalResultsAfterCopyToJSON As %Boolean [ InitialExpression = 0 ];

/// Array of local instance results as %DynamicArray objects subscripted by Namespace
Property LocalResultsAsJSON As %String [ MultiDimensional ];

/// Whether to include External Clients in search
Property IncludeExternalClients As %Boolean [ InitialExpression = 0 ];

/// At the start of a search of ExternalClients if this is set then search is limited to this client
/// whether or not it has property RESTClient of true. The Client is the Registry ID
Property ExternalClientRegistryID As %String(MAXLEN = 254);

/// %Dynamic array of %Doc objects subscripted by External Registry ID if retrieved from external system
Property ExternalResultsAsJSON As %String [ MultiDimensional ];

/// Override path for REST call to External client.
/// Default is first to use the Client's RESTPath value and if that is
/// empty string use /api/docdb/v1/<namespace>/find/<docdbname>
Property ExternalClientRESTPath As %String;

/// required to extend Ens.Setting.Report.base
Property SettingReportClass As %String(MAXLEN = 254) [ InitialExpression = "Ens.Setting.Report.Port" ];

/// If the Document database for the Setting Report does not exist when saving create the document database and application
Property CreateDocDBAndApplication As %Boolean [ InitialExpression = 1 ];

/// If this is true then Event Log Warnings will be used to report REST Call errors
Property LogExternalCallErrors As %Boolean [ InitialExpression = 0 ];

/// Timeout used REST connect to External Clients
Property RemoteTimeout As %Integer [ InitialExpression = 5 ];

/// Allows control of calling onFinishSave of the Setting Report class
/// after saving saving search results
Property CallonFinishSave As %Boolean [ InitialExpression = 1 ];

Property startingNamespace As %String [ InitialExpression = {$Namespace}, Internal, Private ];

Property recordingNamespace As %String [ InitialExpression = {$Namespace}, Internal, Private ];

/// Needed to clean up in %OnClose and when carry out a new search or do a save.
/// Expect most times only one entry if there is a lock taken out but allows for multiple.
Property locksTaken As %String [ Internal, MultiDimensional, Private ];

/// This is used to identify the External Registry Entry
Parameter RESTVERSION = 1;

/*
	All non Private methods must check that ..validSettingReportClass() is true before proceeding
*/
/// Search the specified namespaces and clients examining active/registered production
Method SearchSettings(pKeepExclusive As %Boolean = 0) As %Status
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		If ..SettingReportClass = "" Quit

		Set tSC = ..UseExclusively()
		If $$$ISERR(tSC) Quit

		Kill ..LocalResults
		Kill ..LocalResultsAsJSON

		#; Public Method
		If '..validSettingReportClass(.tSC) Quit

		Set tSC = ..populateSearchNamespaces()  Quit:$$$ISERR(tSC)

		Set tSC = ..searchNamespaces()  Quit:$$$ISERR(tSC)

		If ..StoreLocalResultsAsJSON Set tSC = ..storeLocalResultsAsJSON()

		If ..IncludeExternalClients && ($parameter(..SettingReportClass,"DocDBName") '= "" ) {

			Do ..searchExternalClients()

		}

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	If 'pKeepExclusive Do ..AllowOthers()

	Return tSC
}

/// Save contents of LocalResults array and External Results if specified to persistent table.
/// pKeepExclusive flag will keep exclusive lock at end of save if required. Default is not to keep lock.
/// If property AllNamespaces is true then existing data for local namespaces that are
/// no longer present will be deleted.
Method SaveSearchResults(pIncludeExternalResults As %Boolean = 1, pKeepExclusive As %Boolean = 0) As %Status
{

	/*

		Check that the namespace we are in is the namespace used to record the data for the instance.

		Update ..SettingReportClass table with ..LocalResults array

		Go through ..LocalResults()

		We will only store one Production per Namespace, mirror/instance, production combo

	*/

	#dim tSC = $$$OK
	#dim tSCCleanup = $$$OK
	#dim ex As%Exception.AbstractException

	#dim tServer
	#dim tInstance
	#dim tMirror
	#dim tProduction

	#dim tInTrans = 0

	#dim tLocation, tItems
	#dim tListOfUpdatedNamespaces

	Try {

		#; Public Method
		If '..validSettingReportClass(.tSC) Quit

		#dim tLockNamespace
		If '$Data(..locksTaken(..SettingReportClass),tLockNamespace) || (tLockNamespace '= $Namespace) {

			Set tSC = ..UseExclusively()
			If $$$ISERR(tSC) Quit

		}

		#; If mirror primary and failed over and SYS control data not set create
		#dim tCreateSYSControlDataIfNeeded = $SYSTEM.Mirror.IsPrimary()
		If '..canSave(.tSC, tCreateSYSControlDataIfNeeded) Quit

		TSTART
		Set tInTrans = 1
		#dim tNamespace = $Order(..LocalResults(""))
		While tNamespace '= "" {

			Set tServer = $Get(..LocalResults(tNamespace,"location","server"))
			Set tInstance = $Get(..LocalResults(tNamespace,"location","instance"))
			Set tMirror = $Get(..LocalResults(tNamespace,"location","mirror"))
			If ..AllNamespaces Set tListOfUpdatedNamespaces(tNamespace) = $LB(tServer,tInstance,tMirror)
			#; Remove for any production name defined for the unique namespace identifier
			Set tSC = $ClassMethod(..SettingReportClass,"RemoveEntries",tServer,tInstance,tNamespace,tMirror,"")  Quit:$$$ISERR(tSC)

			/*
				Location properties Common to all items in the given namespace
					..LocalResults(tNamespace,"location",<prop>) = <value>
				Individual:
					..LocalResults($Namespace, "items", tMatchedItemIndex,<prop>) = <value>
			*/

			Kill tLocation, tItems

			Merge tLocation = ..LocalResults(tNamespace,"location")

			Merge tItems = ..LocalResults(tNamespace, "items")

			Set tSC = ..saveLocalResults(.tLocation, .tItems)  Quit:$$$ISERR(tSC)

			Set tNamespace = $Order(..LocalResults(tNamespace))

		}

		/*	If searched all namespaces then can remove entries both primary and reservation from mirror/namespace or server/instance/namespace\
			combos that are not listed in the list of updated namespaces.
		*/
		If ..AllNamespaces {
			Set tSCCleanup = $ClassMethod(..SettingReportClass,"RemoveNamespacesNotInList",.tListOfUpdatedNamespaces)
			If $$$ISERR(tSCCleanup) $$$LOGWARNING("Failed to remove data from any deleted namespaces: "_$system.Status.GetErrorText(tSCCleanup))
		}

		If pIncludeExternalResults && ..IncludeExternalClients && $Data(..ExternalResultsAsJSON) {

			Set tSC = ..saveExternalResults()
			If $$$ISERR(tSC) Quit
		}

		If ..CallonFinishSave Set tSC = $ClassMethod(..SettingReportClass,"onFinishSave",$this)  Quit:$$$ISERR(tSC)

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	If tInTrans {
		If $$$ISERR(tSC) {
			TROLLBACK
		} Else {
			TCOMMIT
		}
	}

	If 'pKeepExclusive Do ..AllowOthers()

	Return tSC
}

/// Adds data to the DocDB from array
Method saveLocalResults(ByRef pLocation, ByRef pSpecific) As %Status [ Internal, Private ]
{
	Return ..arraysToObjectsWithSaveOption(.pLocation, .pSpecific, 1)
}

/// convert the 2 arrays to a dynamic object with optional save and return of entries in dynamic array
/// Called by either saveLocalResults or storeLocalResultsAsJSON
Method arraysToObjectsWithSaveOption(ByRef pLocation, ByRef pSpecific, pSaveToDocDB As %Boolean = 1, ByRef pEntriesAsJSON As %Library.DynamicArray = "") As %Status [ Internal, Private ]
{
	/*
		Location properties common to all in pSpecific
			pLocation(<prop>) = <value>

		Item Specific
			pSpecific(tMatchedItemIndex,<prop>) = <value>

	*/

	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		#; check first if anything to save
		#dim tItemNumber = $Order(pSpecific(""))
		If tItemNumber = "" Quit

		/*	The location data is common to all in the Specific array
			Start each new item entry as a clone of the location data
		*/
		#dim tLocationAsJSON = ..locationAsJSON(.pLocation)

		#dim tDocDB As %DocDB.Database

		#dim tItemEntry As %Library.DynamicObject

		#dim tPropertyName
		#dim tPropertyValue

		While tItemNumber'="" {

			Set tItemEntry = {}.%FromJSON(tLocationAsJSON)

			Set tPropertyName = "", tPropertyValue = ""

			Set tPropertyName = $Order(pSpecific(tItemNumber,tPropertyName),1,tPropertyValue)

			While tPropertyName '= "" {

				Do tItemEntry.%Set(tPropertyName, tPropertyValue)

				Set tPropertyName = $Order(pSpecific(tItemNumber,tPropertyName),1,tPropertyValue)

			}

			If pSaveToDocDB Set tSC = $ClassMethod(..SettingReportClass,"AddDocumentEntry", tItemEntry, .tDocDB)  Quit:$$$ISERR(tSC)

			If $IsObject(pEntriesAsJSON) Do pEntriesAsJSON.%Push(tItemEntry)

			Set tItemNumber = $Order(pSpecific(tItemNumber))
		}

		If $$$ISERR(tSC) Quit

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Return tSC
}

Method storeLocalResultsAsJSON() As %Status [ Internal, Private ]
{
	#dim tSC = $$$OK

	#dim tNamespace = $Order(..LocalResults(""))
	#dim tLocation, tItems
	#dim tEntriesAsObjects As %Library.DynamicArray

	While tNamespace '= "" {

		Kill tLocation, tItems

		Merge tLocation = ..LocalResults(tNamespace,"location")

		Merge tItems = ..LocalResults(tNamespace, "items")

		Set tEntriesAsObjects = []
		Set tSC = ..arraysToObjectsWithSaveOption(.tLocation, .tItems, 0, .tEntriesAsObjects)  Quit:$$$ISERR(tSC)

		Kill ..LocalResultsAsJSON(tNamespace)
		Set ..LocalResultsAsJSON(tNamespace) = tEntriesAsObjects

		If ..RemoveLocalResultsAfterCopyToJSON Kill ..LocalResults(tNamespace)

		Set tNamespace = $Order(..LocalResults(tNamespace))

	}
	Return tSC
}

ClassMethod locationAsJSON(ByRef pLocation As %String) As %String [ Internal ]
{
	#dim tPropertyName = ""
	#dim tPropertyValue = ""

	#dim tLocationObject = {}

	Set tPropertyName = $Order(pLocation(tPropertyName),1,tPropertyValue)

	While tPropertyName '= "" {

		Do tLocationObject.%Set(tPropertyName, tPropertyValue)

		Set tPropertyName = $Order(pLocation(tPropertyName),1,tPropertyValue)

	}

	Return tLocationObject.%ToJSON()
}

/// Pass one entry at a time to the SettingReportClass for saving
/// after filtering out those that are on same instance or those in same mirror
/// as this instance.
Method saveExternalResults() As %Status [ Internal, Private ]
{
	#dim tSC = $$$OK
	#; Errors thrown will be caught by caller


	#dim tThisServer = ##class(%SYS.System).GetNodeName()
	#dim tThisMirror = $system.Mirror.MirrorName()
	#dim tThisInstance = ##class(%SYS.System).GetInstanceName()

	#dim tJSONResponse As %DynamicArray
	#dim tClient = $Order(..ExternalResultsAsJSON(""),1,tJSONResponse)

	#; Find  namespaces so can skip if mirrored and same namespace name
	If (tThisMirror'="") && (tClient'="") {

		#dim tLocalNamespaces
		Do List^%SYS.NAMESPACE(.tLocalNamespaces)

	}

	#dim tServer, tInstance, tMirror, tNamespace
	#dim tArrayIterator, tKey, tOneDoc, tOneItem, tOneItemJSON
	#dim tRemovedAlready
	#dim tDocDB As %DocDB.Database
	#dim tDocType

	While tClient'="" {

		Set tArrayIterator = tJSONResponse.%GetIterator()

		While tArrayIterator.%GetNext(.tKey,.tOneDoc) {
			Set tOneItemJSON = tOneDoc.%Get("%Doc")
			Set tOneItem = {}
			Try {
				Set tOneItem = tOneItem.%FromJSON(tOneItemJSON)
			} Catch { /* Ignore bad data from client */ Continue }

			Set tServer = tOneItem.server
			Set tInstance = tOneItem.instance
			Set tNamespace = tOneItem.namespace
			Set tMirror = tOneItem.mirror
			Set tDocType = tOneItem.document

			#; Skip unexpected bad data from remote server for primary documents
			If (tDocType = "primary") {

				If (tNamespace = "") || (tServer = "") || (tInstance = "") Continue

				#; Skip if this computer and instance - cannot do this filter in REST restriction
				If ((tServer = tThisServer) && (tInstance = tThisInstance)) Continue

				#; Skip if in same mirror and the item namespace is a local namespace - assume mirrored.
				If (tThisMirror'="") && (tMirror = tThisMirror) && ($Data(tLocalNamespaces(tNamespace))#2) Continue

				If '$Data(tRemovedAlready($LB(tServer,tInstance,tNamespace,tMirror))) {

					Set tRemovedAlready($LB(tServer,tInstance,tNamespace,tMirror)) = ""
					#; Remove for any production name defined for the unique namespace identifier
					Set tSC = $ClassMethod(..SettingReportClass,"RemoveEntries",tServer,tInstance,tNamespace,tMirror,"")  Quit:$$$ISERR(tSC)

				}
			} else {

				#; Only save remote primary data
				Continue

			}

			#; Pass tDocDB by reference so that AddDocumentEntry can reuse for multiple items
			Set tSC = $ClassMethod(..SettingReportClass, "AddDocumentEntry", tOneItem, .tDocDB, tDocType)  Quit:$$$ISERR(tSC)

		}

		Set tClient = $Order(..ExternalResultsAsJSON(tClient),1,tJSONResponse)

	}

	Return tSC
}

/*
	Internal Methods for searching
*/
Method populateSearchNamespaces() As %Status [ Internal ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	If ..AllNamespaces Kill ..SearchNamespaces

	#dim tProductionName = ""

	If ..AllNamespaces {

		#dim tAllProductionInfo As %String

		#; Requires %Ens_Portal:USE
		Set tSC = ##class(%SYS.Ensemble).GetStatusAll(.tAllProductionInfo)

		If $$$ISOK(tSC) {

			#dim tOneNamespace As %String = ""
			For {

				Set tOneNamespace = $Order(tAllProductionInfo(tOneNamespace))
				If tOneNamespace = "" Quit

				Set tProductionName = $LG(tAllProductionInfo(tOneNamespace),1)

				Set ..SearchNamespaces(tOneNamespace) = tProductionName

			}

		}

	} Else {

		If '$Data(..SearchNamespaces) && (..SpecificNamespace '= "") Set ..SearchNamespaces(..SpecificNamespace) = ""

		Set tSC = ..assignProductionsToSearchNamespaces()

	}

	Return tSC
}

/*
	Internal Methods for searching that are Private
*/
/// If user did not supply a production name when specifying namespaces
/// to use either with SpecificNamespace or populating ..SearchNamespaces array
/// then assign current active.
Method assignProductionsToSearchNamespaces() As %Status [ Internal, Private ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException


	#dim tOneNamespace As %String = ""
	#dim tProductionName

	For {

		Set tOneNamespace = $Order(..SearchNamespaces(tOneNamespace),1,tProductionName)

		If tOneNamespace = "" Quit

		If tProductionName = "" {

			Try {

				New $Namespace
				Set $Namespace = tOneNamespace

				If ##class(%Library.EnsembleMgr).IsEnsembleNamespace() {

					Set tProductionName = ##class(Ens.Director).GetActiveProductionName()

					If tProductionName = "" {

						#; Remove from list
						Kill ..SearchNamespaces(tOneNamespace)

					} Else {

						Set ..SearchNamespaces(tOneNamespace) = tProductionName
					}

				}

			} Catch ex {

				Set tSC = ex.AsStatus()

			}

			If $$$ISERR(tSC) Quit

		}

	}
	Return tSC
}

Method searchNamespaces() As %Status [ Internal, Private ]
{
	#dim tSC = $$$OK

	#dim tOneNamespace As %String = ""
	#dim tProductionName

	For {

		Set tOneNamespace = $Order(..SearchNamespaces(tOneNamespace),1,tProductionName)
		If tOneNamespace = "" Quit

		Set tSC = ..searchProduction(tOneNamespace,tProductionName)  Quit:$$$ISERR(tSC)

	}

	Return tSC
}

Method searchProduction(pNamespace As %String = {$Namespace}, pProductionName As %String = "") As %Status [ Internal, Private ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		If pProductionName = "" Quit

		If $Namespace '= pNamespace {

			#; Requires priv on namespace
			New $Namespace
			Set $Namespace = pNamespace

		}

		#dim tProductionObject As Ens.Config.Production
		Set tProductionObject = ##class(Ens.Config.Production).%OpenId(pProductionName,0,.tSC)
		If $$$ISERR(tSC) {
			#; We may have been passed stale information by ##class(%SYS.Ensemble).GetStatusAll()
			If $system.Status.Equals(tSC,$$$LoadObjectNotFound) Set tSC = $$$OK
			Quit
		}

		#dim tItemCounter As %Integer
		#dim tItemObject As Ens.Config.Item

		For tItemCounter=1:1:tProductionObject.Items.Count() {

			#; IDs can change so we obtain snapshot of item
			Set tItemObject=tProductionObject.Items.GetAt(tItemCounter)

			Set tSC = ..processItem(tItemObject)

			Do tProductionObject.Items.%UnSwizzleAt(tItemCounter)

		}

		If $$$ISERR(tSC) Quit

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Return tSC
}

Method processItem(pItem As Ens.Config.Item) As %Status [ Internal, Private ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	#dim tItemConfigName As %String

	#dim tSettingList

	#; Index of SettingNames to number in list. Root value is matched setting number
	#dim tSettingsNameIndex
	#; Array of data to record e.g. Port listener. Uses ReportTableClass
	#dim tSpecificSettingData
	#; Array of common item data = Enabled, Name
	#dim tItemData
	#; Array of common location properties for all matching items in the production
	#dim tLocationData

	#; Increment of ..LocalResults($Namespace, "matched")
	#dim tMatchedItemIndex

	Try {
		#; Similar to EnsPortal.Utils methods
		Set tSC = ..getItemSettings(pItem,.tSettingList)  Quit:$$$ISERR(tSC)

		If ..settingMatchesPattern(.tSettingList,.tSettingsNameIndex) {

			/*  Process all settings for the matched setting.
				We may decide not to record in which case tItemData will be undefined
				tSettingList might have been modified
			*/
			Set tSC = ..getSpecificSettingData(pItem, .tSettingsNameIndex, .tSettingList, .tSpecificSettingData)  Quit:$$$ISERR(tSC)

			If $Data(tSpecificSettingData) {

				Set tSC = ..getItemData(pItem, .tSettingsNameIndex, .tSettingList, .tItemData)  Quit:$$$ISERR(tSC)

				If '$Data(..LocalResults($Namespace,"location")) {

					Set tSC = ..getProductionLocationData(pItem.Production.Name,.tLocationData)  Quit:$$$ISERR(tSC)
					Merge ..LocalResults($Namespace, "location") = tLocationData

				}

				Set tMatchedItemIndex = $Increment(..LocalResults($Namespace, "matched"))

				#; Record general item properties for report
				Merge ..LocalResults($Namespace, "items", tMatchedItemIndex) = tItemData

				#; Record specific properties for report
				Merge ..LocalResults($Namespace, "items", tMatchedItemIndex) = tSpecificSettingData

			}

		}

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Return tSC
}

Method getItemSettings(pItem As Ens.Config.Item, ByRef pSettingList) As %Status [ Internal, Private ]
{
	#dim tSC = $$$OK

	Kill pSettingList

	Set tSC = pItem.GetStaticSettings(.pSettingList)
	If $$$ISERR(tSC) Return tSC

	Do pItem.PopulateVirtualSettings()
	#dim n0 = $Order(pSettingList(""),-1)
	#dim n = pItem.VirtualSettings.Count()
	#dim i

	For i = 1:1:n {
		Set pSettingList(n0+i) = pItem.VirtualSettings.GetAt(i)
	}

	Return tSC
}

Method settingMatchesPattern(ByRef pSettingList As %String, ByRef pSettingsNameIndex) As %Boolean [ Internal, Private ]
{
	Kill pSettingsNameIndex

	#dim tMatches = 0
	#dim tSettingNumber = 0
	#dim tListData
	#dim tSettingName

	#dim tSettingNamePattern = ..SettingNamePattern
	If tSettingNamePattern = "" Set tSettingNamePattern = $Parameter(..SettingReportClass,"SettingNamePattern")
	Set tRegex=##class(%Regex.Matcher).%New(tSettingNamePattern)

	For {

		Set tSettingNumber = $Order(pSettingList(tSettingNumber),1,tListData)
		If tSettingNumber = "" Quit

		Set tSettingName = $ListGet(tListData,2)

		#; Only look for first match
		If 'tMatches && tRegex.Match(tSettingName) {

			Set pSettingsNameIndex = tSettingNumber
			Set tMatches = 1

		}

		Set pSettingsNameIndex(tSettingName) = tSettingNumber

	}

	Return tMatches
}

Method getSpecificSettingData(pItem As Ens.Config.Item, ByRef pSettingNameIndex, ByRef pSettingsList, Output pSpecificItemData As %String) As %Status [ Internal, Private ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		#; Examine the setting names that need to pull out and get data and obtain properties to set
		Set tSC = $ClassMethod(..SettingReportClass,"onGetSpecificSettingData",pItem,.pSettingNameIndex,.pSettingsList,.pSpecificItemData)

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Return tSC
}

Method getItemData(pItem As Ens.Config.Item, ByRef pSettingNameIndex, ByRef pSettingsList, Output pItemData As %String) As %Status [ Internal, Private ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		Set tSC = $ClassMethod(..SettingReportClass,"onGetItemData",pItem,.pSettingNameIndex,.pSettingsList,.pItemData)

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Return tSC
}

Method getProductionLocationData(pProductionName As %String, Output pLocationData As %String) As %Status [ Internal, Private ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		#; Examine the setting names that need to pull out and get data and obtain properties to set
		Set tSC = $ClassMethod(..SettingReportClass,"onGetProductionLocationData",pProductionName,.pLocationData)

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Return tSC
}

/*
	Internal Method for saving
*/
Method canSave(Output pSC As %Status, pSetIfHaveData As %Boolean = 0) As %Boolean [ Internal, Private ]
{
	#dim tCanSave = 0
	#dim ex As %Exception.AbstractException
	Set pSC = $$$OK

	Try {

		If $parameter(..SettingReportClass,"DocDBName") = "" {

			Set pSC = $$$ERROR($$$EnsSRErrSettingReportDBNotDefined,..SettingReportClass)
			Quit

		}

		If '$Data(..LocalResults) && '$Data(..ExternalResultsAsJSON) {

			Set pSC = $$$ERROR($$$EnsSRErrSettingReportNothingToSave, ..SettingReportClass)
			Quit

		}

		#dim tPersistentReportNamespace As %String = ""

		If '..inPersistentReportNamespace(.pSC, .tPersistentReportNamespace, pSetIfHaveData) {

			If $$$ISERR(pSC) Quit

			If tPersistentReportNamespace '= "" {

				Set pSC = $$$ERROR($$$EnsSRErrNotInSettingReportNamespace, $namespace, ..SettingReportClass)

			} Else {

				Set pSC = $$$ERROR($$$EnsSRErrSettingReportNamespaceNotDefined,..SettingReportClass)

			}

			Quit
		}

		#dim tDocDBName = $parameter(..SettingReportClass,"DocDBName")

		If '$SYSTEM.DocDB.Exists(tDocDBName) {

			If '..CreateDocDBAndApplication {

				Set pSC = $$$ERROR($$$EnsSRErrSettingReportDBNotExist,..SettingReportClass)
				Quit

			} Else {

				Set pSC = $classmethod(..SettingReportClass,"CreateDocDBAndApplication")
				If $$$ISERR(pSC) Quit

			}

		}

		Set tCanSave = 1

	} Catch ex {

		Set pSC = ex.AsStatus()
		Set tCanSave = 0

	}

	Return tCanSave
}

Method validSettingReportClass(Output pSC As %Status = {$$$OK}) As %Boolean [ Internal ]
{
	#dim valid = 0
	#dim e As %Exception.AbstractException

	Try {

		Set valid = $ClassMethod(..SettingReportClass,"%Extends","Ens.Setting.Report.base")

	} Catch e {

		Set pSC = e.AsStatus()

	}

	Return valid
}

Method inPersistentReportNamespace(Output pSC As %Status = {$$$OK}, Output pPersistentNamespace As %String = "", pSetIfHaveData As %Boolean = 0) As %Boolean [ Internal, Private ]
{
	#dim inPersistentNamespace = 0

	Set pPersistentNamespace = ..GetPersistentReportNamespace(.pSC, pSetIfHaveData)

	If $$$ISOK(pSC) && (pPersistentNamespace'="") {
		If $Namespace = pPersistentNamespace Set inPersistentNamespace = 1
	}

	Return inPersistentNamespace
}

/*
	Managing storage location
*/
Method GetPersistentReportNamespace(Output pSC As %Status = {$$$OK}, pSetIfHaveData As %Boolean = 0) As %String
{
	#dim namespace = ""
	#dim e As %Exception.AbstractException

	Try {

		#; Public Method
		If '..validSettingReportClass(.pSC) Quit

		Set namespace = $ClassMethod(..SettingReportClass,"GetPersistentReportNamespace",.pSC, pSetIfHaveData)

	} Catch e{

		Set pSC = e.AsStatus()

	}

	Return namespace
}

Method SetPersistentReportNamespace(pNamespace As %String = "", pChangeNamespace As %Boolean = 0) As %Status
{
	#dim tSC = ""
	#dim e As %Exception.AbstractException

	Try {

		#; Public Method
		If '..validSettingReportClass(.tSC) Quit

		Set tSC = $ClassMethod(..SettingReportClass,"SetPersistentReportNamespace",pNamespace,pChangeNamespace)

	} Catch e{

		Set tSC = e.AsStatus()

	}

	Return tSC
}

/*
	Managing link to user application
*/
Method SetReportAppURL(pWebServer As %String, pWebPort As %String, pWebPath As %String, pUseSSL As %Boolean) As %Status
{
	#dim tSC = ""
	#dim e As %Exception.AbstractException

	Try {

		#; Public Method
		If '..validSettingReportClass(.tSC) Quit

		Set tSC = $ClassMethod(..SettingReportClass, "SetReportAppURL", pWebServer, pWebPort, pWebPath, pUseSSL)

	} Catch e{

		Set tSC = e.AsStatus()

	}

	Return tSC
}

Method GetReportAppURL(Output pWebServer As %String = "", Output pWebPort As %String = "", pWebPath As %String = "", pUseSSL As %Boolean = "") As %Status
{
	#dim tSC = ""
	#dim e As %Exception.AbstractException

	Try {

		#; Public Method
		If '..validSettingReportClass(.tSC) Quit

			Set tSC = $ClassMethod(..SettingReportClass, "GetReportAppURL", .pWebServer, .pWebPort, .pWebPath, .pUseSSL)

	} Catch e{

		Set tSC = e.AsStatus()

	}

	Return tSC
}

/*
	Searching other instances
	Always returns OK
	Errors can be recorded in the event log as Warnings if LogExternalCallErrors.
*/
Method searchExternalClients() As %Status [ Internal, Private ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	/*
		Use External Service Registry in this namespace
	*/

	Try {

		If ..ExternalClientRegistryID = "" {

			#dim tSearchCriteria

			Set tSearchCriteria("Version") = ..#RESTVERSION
			Set tSearchCriteria("Protocols", "REST") = 1

			Set tSearchCriteria("DomainMatch") = $parameter(..SettingReportClass,"DocDBName")

			#; Want all Stages except Defunct
			#dim tStage
			For tStage = "Concept", "Deprecated", "Development","Live", "Staging", "Test" {

				Set tSearchCriteria("Stages",tStage) = 1

				}

			#dim tExternalRS = ##class(Ens.ServiceRegistry.External.API).PerformSearch(.tSearchCriteria, , .tSC)

			While tExternalRS.%Next(.tSC) && $$$ISOK(tSC) {

				Set tSC = ..processExternalClient(tExternalRS.ID)

				Set ..ExternalClientRegistryID = ""

			}

		} Else {

				#; If set a specific RegistryID ignore criteria
				Set tSC = ..processExternalClient(..ExternalClientRegistryID)

		}


	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	If $$$ISERR(tSC) {

		If ..LogExternalCallErrors $$$LOGWARNING("Failed to make REST Call to "_tExternalRS.ID_" for setting report . "_$System.Status.GetErrorText(tSC))

	}

	Return $$$OK
}

Method processExternalClient(pExternalRegistryID As %String) As %Status [ Internal, Private ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		#dim tRESTRequest = ..buildRESTRequestToClient()

		#dim tRESTResponse = ..makeRESTRequestCallToClient(pExternalRegistryID, tRESTRequest, .tSC)
		If $$$ISERR(tSC) Quit

		If $IsObject(tRESTResponse) {

			If tRESTResponse.HTTPHeaders.GetAt("StatusLine") [ "200" {

				Try {

					#; Array of %Doc
					Set ..ExternalResultsAsJSON(pExternalRegistryID) = [].%FromJSON(tRESTResponse.Stream).%Get("content").%Get("content")

				} Catch {

					Kill ..ExternalResultsAsJSON(pExternalRegistryID)

				}

			} Else {

				#dim tHTTPStatus = $Piece(tRESTResponse.HTTPHeaders.GetAt("StatusLine"), " ", 2 ,*)
				Set tSC = $$$ERROR($$$EnsSRErrSettingReportRESTError, pExternalRegistryID, ..SettingReportClass, tHTTPStatus)

			}
		}

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Return tSC
}

Method buildRESTRequestToClient() As EnsLib.REST.GenericMessage [ Internal, Private ]
{

	#dim tRESTHTTPHeaders
	Set tRESTHTTPHeaders("HttpRequest")="POST"
	Set tRESTHTTPHeaders("HTTPVersion")="1.1"
	#dim tPOSTStream = ##class(%Stream.GlobalCharacter).%New()
	#dim tPOSTJSON = {}
	Set tPOSTJSON.projection = []

	#; By getting just %Doc we will not error if client is on a different version of the DocDB
	Do tPOSTJSON.projection.%Push("%Doc")

	Do tPOSTJSON.%ToJSON(.tPOSTStream)
	Set tRESTHTTPHeaders("content-length") = tPOSTStream.Size
	Set tRESTHTTPHeaders("content-type") = "application/json"

	Return ##class(EnsLib.REST.GenericMessage).%New(tPOSTStream,,.tRESTHTTPHeaders)
}

Method makeRESTRequestCallToClient(pExternalRegistryID As %String, pRESTRequest As EnsLib.HTTP.GenericMessage, Output pSC As %Status) As EnsLib.HTTP.GenericMessage [ Internal, Private ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	#dim tRESTResponse As EnsLib.HTTP.GenericMessage = $$$NULLOREF

	Try {

		#dim tExternalClient As Ens.ServiceRegistry.External.Service = ##class(Ens.ServiceRegistry.External.Service).%OpenId(pExternalRegistryID,,.pSC)
		If $$$ISERR(pSC) || '$IsObject(tExternalClient) Quit

		#dim tURLProtocol, tHTTPServer, tHTTPPort, tHTTPURL
		Set tSC = ##class(Ens.ServiceRegistry.External.API).ParseHTTPEndPoint(tExternalClient.Endpoint,.tURLProtocol,.tHTTPServer,.tHTTPPort,.tHTTPURL)

		#dim tSender=##class(Ens.Host).GetShadowInstance("class ||EnsLib.REST.GenericOperation",.pSC)
		If $$$ISERR(pSC) Quit

		Do tSender.OnInit()

		Set tSender.ReadRawMode = 0

		Set tSender.Adapter.HTTPServer = tHTTPServer
		Set tSender.Adapter.HTTPPort = tHTTPPort

		Set tSender.Adapter.ConnectTimeout = ..RemoteTimeout

		Do ..configureSenderFromAttributes(tSender, tExternalClient)

		If tHTTPURL '= "" {

			Set tSender.Adapter.URL = tHTTPURL

		} ElseIf ..ExternalClientRESTPath '= "" {

			Set tSender.Adapter.URL = ..ExternalClientRESTPath

		} Else {

			Set tSender.Adapter.URL = ..docDBAPIPath()

		}

		Set pSC = tSender.OnMessage(pRESTRequest,.tRESTResponse)

	} Catch ex {

		Set pSC = ex.AsStatus()

	}

	Return tRESTResponse
}

Method configureSenderFromAttributes(pSender As Ens.Host, pExternalRegistryService As Ens.ServiceRegistry.External.Service)
{
	// Free form entry to protect in try/catch
	Try {

		#dim tAttributeNumber
		#dim tAttribute As Ens.ServiceRegistry.External.Attribute
		#dim ex As %Exception.AbstractException

		For tAttributeNumber = 1:1:pExternalRegistryService.Attributes.Count() {

			Set tAttribute =pExternalRegistryService.Attributes.GetAt(tAttributeNumber)

			Try {

				Set $property(pSender.Adapter,tAttribute.Name) = tAttribute.Value

			} Catch ex {

				/* 	If property not defined look at name using case insensitivity for common properties.
					trap any errors since this is a best attempt
				*/
				If ex.Name = "<PROPERTY DOES NOT EXIST>" {

					Try {

						If $ZCVT(tAttribute.Name, "l") = "credentials" {

							Set pSender.Adapter.Credentials = tAttribute.Value

						} ElseIf $ZCVT(tAttribute.Name,"l") = "sslconfig" {

							Set pSender.Adapter.SSLConfig = tAttribute.Value

						} ElseIf $ZCVT(tAttribute.Name,"l") = "sslcheckserveridentity" {

							Set pSender.Adapter.SSLCheckServerIdentity = tAttribute.Value

						}
   
					} Catch {}

				}

			}

		}

	} Catch {}
}

/// REST API path
Method docDBAPIPath() As %String [ Internal ]
{
	Quit "/api/docdb/v1/namespaceplaceholder/find/"_$parameter(..SettingReportClass,"DocDBName")
}

/// Clean up code to help mechanism for preventing more than one running search or save
Method %OnClose() As %Status [ Private, ServerOnly = 1 ]
{
	Do ..AllowOthers()
	Quit $$$OK
}

Method UseExclusively() As %Status
{
	#; first clear any other locks we might have
	Do ..AllowOthers()

	#dim tSC = $$$OK
	Set ..locksTaken(..SettingReportClass) = $Namespace
	Lock +^Ens.Setting.Reporter(..SettingReportClass):$SYSTEM.SQL.GetProcessLockTimeout()
	If '$Test {
		Set tSC = $$$ERROR($$$LockFailedToAcquireExclusive, $name(^Ens.Setting.Reporter(..SettingReportClass)))
		Kill ..locksTaken(..SettingReportClass)
	}

	Return tSC
}

Method AllowOthers()
{
	#dim tNamespace
	#dim tLockSubscript = $Order(..locksTaken(""),1,tNamespace)
	While tLockSubscript '= "" {
		Lock -^|tNamespace|Ens.Setting.Reporter(tLockSubscript)
		Kill ..locksTaken(tLockSubscript)
		Set tLockSubscript = $Order(..locksTaken(tLockSubscript),1,tNamespace)
	}
}

}
