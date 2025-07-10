/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsSR)

/// This class is for InterSystems internal use.
Class Ens.Setting.Report.base Extends %RegisteredObject [ System = 4 ]
{

/// Regular expression to find particular setting names for one type of setting
Parameter SettingNamePattern;

/// The DocDB Name
Parameter DocDBName;

/// The resource to protect the DocDB.
Parameter DocDBResource;

/// Subclasses will implement the required key/value data generation.
/// This implementation returns just the one setting and uses the setting name
/// in lower case to return the value
ClassMethod onGetSpecificSettingData(pItem As Ens.Config.Item, ByRef pSettingNameIndex, ByRef pSettingsList, Output pSpecificSettingData As %String) As %Status [ Internal ]
{
	#; Access List from PopulateVirtualSettings()
	#define settingValue(%lv)	$ListGet(%lv,3)
	#; Use lower case setting name
	#define settingName(%lv)	$ZCVT($ListGet(%lv,2),"L")

	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		Kill pSpecificSettingData

		#dim tSettingValue = $$$settingValue(pSettingsList(pSettingNameIndex))
		#dim tSettingName = $$$settingName(pSettingsList(pSettingNameIndex))

		Set pSpecificSettingData(tSettingName) = tSettingValue

		Set pSpecificSettingData("document") = "primary"

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Return tSC
}

/// Gets location data for the production assumed to be in this namespace
ClassMethod onGetProductionLocationData(pProductionName As %String, Output pLocationData As %String) As %Status [ Internal ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		Kill pLocationData

		#; Production
		Set pLocationData("production") = pProductionName

		#; Machine Name
		Set pLocationData("server") = ##class(%SYS.System).GetNodeName()

		#; Instance Name
		Set pLocationData("instance") = ##class(%SYS.System).GetInstanceName()

		#; Namespace
		Set pLocationData("namespace") = $namespace

		#; Mirror Name
		Set pLocationData("mirror") = $SYSTEM.Mirror.MirrorName()

		#; System Mode
		Set pLocationData("mode") = ..SystemMode()

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Return tSC
}

/// Override in sub class if want a different value for 'mode'
ClassMethod SystemMode() As %String
{
	Return $Get(^%SYS("SystemMode"))
}

/// Gets general Item data
ClassMethod onGetItemData(pItem As Ens.Config.Item, ByRef pSettingNameIndex, ByRef pSettingsList, Output pItemData As %String) As %Status [ Internal ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	#; Access List from PopulateVirtualSettings()
	#define settingValue(%lv)	$ListGet(%lv,3)

	Try {

		Kill pItemData

		#; Item Name
		Set pItemData("itemName") = pItem.Name

		#; Categories
		Set pItemData("categories") = pItem.Category

		#; Enabled Property - point in time status
		Set pItemData("enabled") = pItem.Enabled

		#; BusinessPartner
		#dim tSettingIndex
		If $Data(pSettingNameIndex("BusinessPartner"),tSettingIndex)#2 {

			Set pItemData("partner") = $$$settingValue(pSettingsList(tSettingIndex))

		}

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Return tSC
}

/// Removes data from DocDB
/// Based on server/instance or mirror/namespace combination.
/// Must provide pNamespace and pDocType and either pMirror or both pServer and pInstance
ClassMethod RemoveEntries(pServer As %String = "", pInstance As %String = "", pNamespace As %String = "", pMirror As %String = "", pProduction As %String = "", pDocType As %String = "primary") As %Status [ Internal ]
{
	#dim tSC = $$$OK

	#dim ex As %Exception.AbstractException

	Try {

		If ..#DocDBName = "" {

			Set tSC = $$$ERROR($$$EnsSRErrSettingReportDBNotDefined, $Classname())
			Quit

		}

		If '$SYSTEM.DocDB.Exists(..#DocDBName) {

			Set tSC = $$$ERROR($$$EnsSRErrSettingReportDBNotExist, $Classname())
			Quit

		}

		#dim tDocDB = ##class(%DocDB.Database).%GetDatabase(..#DocDBName)
		#dim tSQL = "SELECT %DocumentId FROM "_tDocDB.SqlNameQualified_" WHERE namespace = ?"
		#dim tToDeleteRS As %SQL.StatementResult
		#dim tParameters

		Set tParameters($Increment(tParameters)) = pNamespace

		If pProduction '= "" {

			Set tSQL = tSQL _" AND production = ?"
			Set tParameters($Increment(tParameters)) = pProduction

		}

		If pMirror = "" {

			Set tSQL = tSQL _" AND server = ? AND instance = ?"
			Set tParameters($Increment(tParameters)) = pServer
			Set tParameters($Increment(tParameters)) = pInstance

		} Else {

			/*	Since we could be updating after failing over we 
				use the mirror name since server and instance might not
				be this node.
				We also look for this node in case this node was
				added to a mirror after a report had already been run.
				It is necessary to delete the entries with a manual
				api call if the mirror was added after a report was
				created and this is being run on a different node in
				the new mirror configuration.
			*/
			Set tSQL = tSQL _" AND ((mirror = ?) OR (server = ? AND instance = ?))"
			Set tParameters($Increment(tParameters)) = pMirror
			Set tParameters($Increment(tParameters)) = pServer
			Set tParameters($Increment(tParameters)) = pInstance

		}

		Set tSQL = tSQL _" AND document = ?"
		Set tParameters($Increment(tParameters)) = pDocType

		Set tToDeleteRS = tDocDB.%ExecuteQuery(tSQL,tParameters...)

		While (tToDeleteRS.%Next(.tSC) && $$$ISOK(tSC)) {

			Do tDocDB.%DeleteDocument(tToDeleteRS.%DocumentId)

		}

	} Catch ex {

		Set tSC = ex.AsStatus()

	}
	Return tSC
}

/// Add a dynamic object to the DocDB
ClassMethod AddDocumentEntry(pOneItem As %DynamicObject, ByRef pDocDB As %DocDB.Database = "", pDocType As %String = "primary") As %Status [ Internal ]
{

	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		If '$IsObject(pDocDB) {

			If ..#DocDBName = "" {

				Set tSC = $$$ERROR($$$EnsSRErrSettingReportDBNotDefined, $Classname())
				Quit

			}

			If '$SYSTEM.DocDB.Exists(..#DocDBName) {

				Set tSC = $$$ERROR($$$EnsSRErrSettingReportDBNotExist, $Classname())
				Quit

			}

			Set pDocDB = ##class(%DocDB.Database).%GetDatabase(..#DocDBName)
		}

		Do pOneItem.%Set("document", pDocType)
		Do pDocDB.%SaveDocument(pOneItem)

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Return tSC
}

/// Optional Implement in sub class.
ClassMethod onFinishSave(pReporter As Ens.Setting.Reporter = {$$$NULLOREF}) As %Status
{
	Return $$$OK
}

/// This returns the namespace where the data can be stored.
/// This is used to limit the saving to one namespace per instance.
/// If pSetIfHaveData is 1 and the central namespace is not set but there are documents then
/// register the central namespace and create the DocDB Application - this is to aid mirroring setup.
ClassMethod GetPersistentReportNamespace(Output pSC As %Status = {$$$OK}, pSetIfHaveData As %Boolean = 0) As %String
{
	#dim tNamespace = ""
	#dim e As %Exception.AbstractException
	Try {

		If ..#DocDBName = "" {

			Set pSC = $$$ERROR($$$EnsSRErrSettingReportDBNotDefined, $Classname())
			Quit

		}

		If '$$$EnsAllowedSRCentralNamepaceConfig("R") {Set pSC = $$$ERROR($$$InsufficientPrivilegeForOperation)  Quit}

		Set tNamespace = $$$EnsGetSRCentralNamespace
		If (tNamespace = "") && pSetIfHaveData && $$$EnsAllowedSRCentralNamepaceConfig("W") && $SYSTEM.DocDB.Exists(..#DocDBName) {

			#dim tDocDB = ##class(%DocDB.Database).%GetDatabase(..#DocDBName)
			If (tDocDB.%Size() > 0) {
				Set tNamespace = $Namespace
				$$$LOGINFO("Setting Report namespace location and Creating DocDB Application for "_..#DocDBName)
				$$$EnsSetSRCentralNamespace(tNamespace)
				#; Create the DocDBApplication. If already exist OK - just trap for thrown error.
				Try { Do ..CreateDocDBApplication() } Catch {}
			}
		}

	} Catch e {

		Set pSC = e.AsStatus()

	}

	Return tNamespace
}

/// This sets in a central location the namespace where the data can be stored.
/// This is used to limit the saving to one namespace per instance.
ClassMethod SetPersistentReportNamespace(ByRef pNamespace As %String = {$Namespace}, pChangeNamespace As %Boolean = 0) As %Status
{
	#dim tSC = $$$OK
	#dim e As %Exception.AbstractException
	Try {

		If ..#DocDBName = "" {

			Set tSC = $$$ERROR($$$EnsSRErrSettingReportDBNotDefined, $Classname())
			Quit

		}

		If '$$$EnsAllowedSRCentralNamepaceConfig("W") {Set tSC = $$$ERROR($$$InsufficientPrivilegeForOperation)  Quit}

		If ($$$EnsGetSRCentralNamespace '= "") && 'pChangeNamespace {Set tSC = $$$ERROR($$$EnsSRErrSettingReportNamespaceAlreadySet, $Classname())  Quit}

		If pNamespace = "" Set pNamespace = $Namespace

		$$$EnsSetSRCentralNamespace(pNamespace)

	} Catch e {

		Set tSC = e.AsStatus()

	}

	Return tSC
}

/// This clears from the central location the name of the namespace
/// where the data can be stored.
/// It does not remove the actual data.
ClassMethod ClearPersistentReportNamespace() As %Status
{
	#dim tSC = $$$OK
	#dim e As %Exception.AbstractException

	Try {

		If ..#DocDBName = "" {

			Set tSC = $$$ERROR($$$EnsSRErrSettingReportDBNotDefined, $Classname())
			Quit

		}

		If '$$$EnsAllowedSRCentralNamepaceConfig("W") {Set tSC = $$$ERROR($$$InsufficientPrivilegeForOperation)  Quit}

		$$$EnsClearSRCentralNamespace

	} Catch e {

		Set tSC = e.AsStatus()

	}

	Return tSC
}

/// This sets the URL details for the Setting Report Application
ClassMethod SetReportAppURL(pWebServer As %String, pWebPort As %String, pWebPath As %String, pUseSSL As %Boolean) As %Status
{
	#dim tSC = $$$OK
	#dim e As %Exception.AbstractException
	Try {

		If ..#DocDBName = "" {

			Set tSC = $$$ERROR($$$EnsSRErrSettingReportDBNotDefined, $Classname())
			Quit

		}

		If '$$$EnsAllowedSRCentralNamepaceConfig("W") {Set tSC = $$$ERROR($$$InsufficientPrivilegeForOperation)  Quit}

		$$$EnsSetSRWebServer(pWebServer)

		$$$EnsSetSRWebPort(pWebPort)

		$$$EnsSetSRWebPath(pWebPath)

		$$$EnsSetSRWebSSL(pUseSSL)


	} Catch e {

		Set tSC = e.AsStatus()

	}

	Return tSC
}

/// Find the URL of the application external to the SMP
ClassMethod GetReportAppURL(Output pWebServer As %String = "", Output pWebPort As %String = "", pWebPath As %String = "", pUseSSL As %Boolean = "") As %Status
{
	#dim tSC = $$$OK
	#dim e As %Exception.AbstractException

	Try {

		If ..#DocDBName = "" {

			Set tSC = $$$ERROR($$$EnsSRErrSettingReportDBNotDefined, $Classname())
			Quit

		}

		If '$$$EnsAllowedSRCentralNamepaceConfig("W") {Set tSC = $$$ERROR($$$InsufficientPrivilegeForOperation)  Quit}

		Set pWebServer = $$$EnsGetSRWebServer

		Set pWebPort = $$$EnsGetSRWebPort

		Set pWebPath = $$$EnsGetSRWebPath

		Set pUseSSL = $$$EnsGetSRWebSSL

	} Catch e{

		Set tSC = e.AsStatus()

	}

	Return tSC
}

/// Class method to create or recreate DocDB application
/// Uses the definition in XDATA DocDBDefinitions equal to parameter DocDBName
ClassMethod CreateDocDBAndApplication(pRecreate As %Boolean = 0) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		If ..#DocDBName = "" {

			Set tSC = $$$ERROR($$$EnsSRErrSettingReportDBNotDefined, $Classname())
			Quit

		}

		If $SYSTEM.DocDB.Exists(..#DocDBName) && pRecreate {

			Do ##class(%DocDB.Database).%DropDatabase(..#DocDBName)

		}

		If '$SYSTEM.DocDB.Exists(..#DocDBName) {

			#dim tDocDBDefinitions
			Set tSC = ..getDocDBDefinitions(.tDocDBDefinitions)

			If $$$ISOK(tSC) && $Data(tDocDBDefinitions) {

				#dim tDocDB = ##class(%DocDB.Database).%CreateDatabase(..#DocDBName,,..#DocDBResource)

				Set tSC = ..addPropertiesToDocDB(tDocDB, tDocDBDefinitions(..#DocDBName))

			}

		}

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Return tSC
}

ClassMethod addPropertiesToDocDB(pDocDB As %DocDB.Database, pDocDBDefinition As %Library.DynamicObject) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		#dim tListOfProperties

		Set tSC = ..getPropertiesOfDocDBFromDefinition(pDocDBDefinition, .tListOfProperties)
		If $$$ISERR(tSC) Quit

		#dim tType
		#dim tProperty = $Order(tListOfProperties(""),1,tType)

		While tProperty '= "" {

				Do pDocDB.%CreateProperty(tProperty,tType,"$."_tProperty,0)

				Set tProperty = $Order(tListOfProperties(tProperty),1,tType)

		}

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Return tSC
}

ClassMethod getPropertiesOfDocDBFromDefinition(pDocDBDefinition As %Library.DynamicObject, Output pListOfProperties As %String) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		Kill pListOfProperties

		#dim tProperties = pDocDBDefinition.%Get("properties")

		#dim tIterator

		Set tIterator=tProperties.%GetIterator()

		#dim tKey, tProperty, tPropertyType, tPropertyMaxLength, tType

		While tIterator.%GetNext(.tKey,.tProperty) {

			If tKey '= "ID" {

				Set tPropertyType = tProperty.%Get("type")

				If tPropertyType = "boolean" {

					Set tType = "%Boolean"

				} ElseIf tPropertyType = "integer" {

					Set tType = "%Integer"

				} ElseIf tPropertyType = "number" {

					Set tType = "%Numeric"

				} Else {

					Set tPropertyMaxLength = +tProperty.%Get("maximumLength")

					If tPropertyMaxLength = 0 {

						Set tType = "%String(MAXLEN=32767)"

					} Else {

						Set tType = "%String(MAXLEN="_tPropertyMaxLength_")"

					}
				}

				Set pListOfProperties(tKey) = tType

			}
		}

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Return tSC
}

/// Get array  by name of DocDB definitions as Dynamic Objects
ClassMethod getDocDBDefinitions(Output pDocDBDefinitions As %String) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	Kill pDocDBDefinitions

	Try {

		#dim tCompiledXdata=##class(%Dictionary.CompiledXData).%OpenId($Classname()_"||DocDBDefinitions")

		#dim tDefinitions = ##class(%DynamicAbstractObject).%FromJSON(tCompiledXdata.Data).%Get("definitions")

		#dim tIterator = tDefinitions.%GetIterator()

		#dim tDocDBName, tDefinition

		While tIterator.%GetNext(.tDocDBName, .tDefinition) {

			Set pDocDBDefinitions(tDocDBName) = tDefinition

		}

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Return tSC
}

/// Class method to create just DocDB application
/// Uses the definition in XDATA DocDBDefinitions equal to parameter DocDBName
ClassMethod CreateDocDBApplication() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		If ..#DocDBName = "" {

			Set tSC = $$$ERROR($$$EnsSRErrSettingReportDBNotDefined, $Classname())
			Quit

		}

		#dim tProperties
		Set tProperties("resource") = ..#DocDBResource

		Set tSC = $$Create^%SYS.DOCDB(..#DocDBName,$namespace,.tProperties)

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Return tSC
}

XData DocDBDefinitions [ MimeType = application/json ]
{
{
		"definitions": {
		}
	}
}

/// Provide pListOfUpdatedNamespaces as an array of namespaces = $LB(Server,Instance,Mirror)
/// which ought to be the current list of namespaces with data based on server/instance or mirror namespace combination.
/// This method will remove data associated with Namespaces in the DocDB that match the server/instance
/// or mirror namespace combination that are not in the pListOfUpdatedNamespaces array.
/// All Server,Instance, Mirror values in the array must be the same.
/// For each namespace removed the method invokes the callback onRemoveNamespace() which can be overridden
/// in the specific setting subclass to perform custom cleanup.
ClassMethod RemoveNamespacesNotInList(ByRef pListOfUpdatedNamespaces) As %Status [ Internal ]
{
	#dim tSC = $$$OK

	#dim tNamespacesToRemove
	#dim tIdList
	#dim tServer
	#dim tInstance
	#dim tMirror

	Set tSC = ..FindNamespacesNotInList(.pListOfUpdatedNamespaces,.tNamespacesToRemove)
	If $$$ISOK(tSC) {
		Set tIdList = ""
		Set tNamespaceToRemove = $Order(tNamespacesToRemove(""),1,tIdList)
		While tNamespaceToRemove '= "" {
			Set tServer = $LG(tIdList,1)
			Set tInstance = $LG(tIdList,2)
			Set tMirror = $LG(tIdList,3)
			If (tServer="")&&(tInstance="")&&(tMirror="") Quit
			#; remove default 'primary' documents
			Set tSC = ..RemoveEntries(tServer,tInstance,tNamespaceToRemove,tMirror)  Quit:$$$ISERR(tSC)
			Set tSC = ..onRemoveNamespace(tServer,tInstance,tNamespaceToRemove,tMirror)  Quit:$$$ISERR(tSC)
			Set tNamespaceToRemove = $Order(tNamespacesToRemove(tNamespaceToRemove),1,tIdList)
		}
	}
	Return tSC
}

/// Finds (based on server/instance or mirror namespace combination) the
/// list of namespaces that are in DocDB but not in the list
/// of pListOfUpdatedNamespaces.  pListOfUpdatedNamespaces is an array of
/// namespaces = $LB(Server,Instance,Mirror).
/// All Server,Instance, Mirror values in the array must be the same.
ClassMethod FindNamespacesNotInList(ByRef pListOfUpdatedNamespaces, ByRef pNamespacesToRemove) As %Status [ Internal ]
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		#dim tNamespace As %String = ""
		#dim tIdList As %String = ""
		#dim tServer As %String = ""
		#dim tInstance As %String = ""
		#dim tMirror As %String = ""
		#dim tFirst As %Boolean = 0
		#dim tInconsistentData As %Boolean = 0
 
		#; Check list provided for same combination of Server,Instance and Mirror values
		Set tNamespace = $Order(pListOfUpdatedNamespaces(""),1,tIdList)
		Set tFirst = 1	
		While tNamespace '= "" {
			If 'tFirst {
				If (tServer'=$LG(tIdList,1))||(tInstance'=$LG(tIdList,2))||(tMirror'=$LG(tIdList,3)) {
					Set tInconsistentData = 1
					Quit
				}
			}
			Set tServer = $LG(tIdList,1)
			Set tInstance = $LG(tIdList,2)
			Set tMirror = $LG(tIdList,3)
			Set tNamespace = $Order(pListOfUpdatedNamespaces(tNamespace),1,tIdList)
			Set tFirst = 0
		}

		#; Empty list or unable to identify instance
		If tFirst || tInconsistentData Quit

		Kill pNamespacesToRemove

		If ..#DocDBName = "" {

			Set tSC = $$$ERROR($$$EnsSRErrSettingReportDBNotDefined, $Classname())
			Quit

		}

		If '$SYSTEM.DocDB.Exists(..#DocDBName) {

			Set tSC = $$$ERROR($$$EnsSRErrSettingReportDBNotExist, $Classname())
			Quit

		}

		#dim tDocDB = ##class(%DocDB.Database).%GetDatabase(..#DocDBName)
		#dim tSQL = "SELECT DISTINCT(namespace) FROM "_tDocDB.SqlNameQualified_" WHERE "
		#dim tToDeleteRS As %SQL.StatementResult
		#dim tParameters



		If tMirror = "" {

			Set tSQL = tSQL _" server = ? AND instance = ?"
			Set tParameters($Increment(tParameters)) = tServer
			Set tParameters($Increment(tParameters)) = tInstance

		} Else {

			/*	See comment in RemoveEntries */
			Set tSQL = tSQL _" ((mirror = ?) OR (server = ? AND instance = ?))"
			Set tParameters($Increment(tParameters)) = tMirror
			Set tParameters($Increment(tParameters)) = tServer
			Set tParameters($Increment(tParameters)) = tInstance

		}

		Set tSQL = tSQL _" AND document = 'primary'"

		Set tToDeleteRS = tDocDB.%ExecuteQuery(tSQL,tParameters...)

		While (tToDeleteRS.%Next(.tSC) && $$$ISOK(tSC)) {
 
 			Set tNamespace = tToDeleteRS.namespace
			If (tNamespace'="") && '$Data(pListOfUpdatedNamespaces(tNamespace)) Set pNamespacesToRemove(tNamespace)=$LB(tServer,tInstance,tMirror)

		}

	} Catch ex {

		Set tSC = ex.AsStatus()

	}
	Return tSC
}

/// Callback when removing deleted namespaces.
/// Override to remove document types other than 'primary' or perform other cleanup.
ClassMethod onRemoveNamespace(pServer As %String = "", pInstance As %String = "", pNamespace As %String = "", pMirror As %String = "") As %Status [ Internal ]
{
	Return $$$OK
}

}
