/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Class to provide information to build portal pages
Class EnsPortal.Utils Extends %RegisteredObject [ System = 4 ]
{

Parameter DOMAIN = "Ensemble";

ClassMethod GetCurrentProductionName() As %String [ CodeMode = expression ]
{
$G(^Ens.Configuration("csp","LastProduction"))
}

/// Note that this method does NOT log any data to the Event Log if the call to
/// GetProductionStatus() returns an error.
ClassMethod GetCurrentProductionState() As %String
{
	Set tSC=##class(Ens.Director).GetProductionStatus(.tName,.tState)
	Quit:$$$ISERR(tSC) "unqueryable"
	Quit ##class(Ens.Config.Production).ProductionStateToText(tState)
}

/// correlate the status with a color, for quick scanning of the enterprise monitor table
/// this is redundant data, repeated by the status column, so if a user is color-blind,
/// they will still be able to use the page.
ClassMethod getProductionStateColor(pState As %Integer, pNeedsUpdate As %Integer) As %String
{
	Quit $Case(pState
		,$$$eProductionStateRunning: $S(pNeedsUpdate:"orange", 1:"green")
		,$$$eProductionStateStopped: "yellow"
		,$$$eProductionStateSuspended: "yellow"
		,$$$eProductionStateTroubled: "red"
		,:"purple")
}

/// Turn the Production State integer into a human-readable state string.
ClassMethod resolveProductionStateName(pState As %Integer) As %String [ CodeMode = expression ]
{
##class(Ens.Config.Production).ProductionStateToText(pState)
}

/// Turn the host BusinessType integer into a human-readable type string
ClassMethod resolveHostType(pBusinessType As %Integer) As %String
{
 Quit $Case(pBusinessType
	,$$$eHostTypeService  :$$$Text("Service")
	,$$$eHostTypeProcess  :$$$Text("Process")
	,$$$eHostTypeOperation:$$$Text("Operation")
	,$$$eHostTypeActor    :$$$Text("Actor")
	,:$$$Text("Unrecognized")_":"_pBusinessType)
}

/// Convert host BusinessType integer into a canonical (non-localized) string
ClassMethod getHostTypeString(pBusinessType As %Integer) As %String
{
 Quit $Case(pBusinessType
	,$$$eHostTypeService  : "service"
	,$$$eHostTypeProcess  : "process"
	,$$$eHostTypeOperation: "operation"
	,$$$eHostTypeActor    : "actor"
	,:"unrecognized"_":"_pBusinessType)
}

/// Return a list of all the config items defined in the given Production
ClassMethod ProductionItems(pProductionName As %String, Output pList, Output pColNames) As %Status
{
	Set tSC=$$$OK  Kill pList  
	Set pColNames=$LB("name","hostType","enabled","position","status","connectStatus","id","commentOrClassname","classname","busPartner","category","isMissingClass")
	Set tIsRunning = ($G($$$EnsRuntime("Name")) = pProductionName)

	#; Enumerate all primary config items in the given Production.
	#; Construct list of all matching enabled items, and the first we find that's a perfect match
	Set tProduction=##class(Ens.Config.Production).%OpenId(pProductionName,,.tSC)
	Quit:'$IsObject(tProduction)||$$$ISERR(tSC) $$$ADDSC(tSC,$$$ERROR($$$EnsErrProductionNotRegistered,pProductionName,$$$StatusDisplayString(tSC)))
	Quit:'$IsObject(tProduction.Items) $$$ADDSC(tSC,$$$ERROR($$$GeneralError,$$$Text("Data inconsistency detected - Production items not found")))
	Set tCount=tProduction.Items.Count()
	Set i=0  For iItem=1:1:tCount {
		Set tItem = tProduction.Items.GetAt(iItem)
		If '$IsObject(tItem) Return $$$ADDSC(tSC,$$$ERROR($$$GeneralError,$$$Text("Data inconsistency detected - Production items not found, may require recompilation")))
		Set tName = tItem.Name
		Set j=$G(entries(tName))
		If 'j {
			Set i=i+1, pList(i)=tItem, entries(tName,"seq")=iItem, entries(tName)=i
			If ##class(Ens.Config.DefaultSettings).%GetSetting(tItem.Production.Name,tItem.Name,tItem.ClassName,"","Enabled",.tSDSEnabled) {
				Set tEnabled = tSDSEnabled
			} Else {
				Set tEnabled = tItem.Enabled
			}
			Set entries(tName,"priority")=$S(tItem.%Id()=$G($$$ConfigId(tName)):2, tEnabled:1, 1:0)
		} Else {
			#; See if this one supersedes the best one found so far
			#; prefer the one that's running or one that's enabled
			Set tOldPriority=$G(entries(tName,"priority"))
			If tOldPriority<2 {
				If ##class(Ens.Config.DefaultSettings).%GetSetting(tItem.Production.Name,tItem.Name,tItem.ClassName,"","Enabled",.tSDSEnabled) {
					Set tEnabled = tSDSEnabled
				} Else {
					Set tEnabled = tItem.Enabled
				}
				Set tPriority = $S(tItem.%Id()=$G($$$ConfigId(tName)):2, tEnabled:1, 1:0)
				Set:tPriority>tOldPriority pList(j)=tItem, entries(tName,"seq")=iItem, entries(tName,"priority")=tPriority
			}
		}
	}
	#; For the qualifying items, get the item info
	For j=1:1:i {
		Set tItem=pList(j)
		Set tSC1 = ..ProductionOneItem(tItem,tIsRunning,entries(tItem.Name,"seq"),.tEntry)
		If $$$ISERR(tSC1) { Set tSC=$$$ADDSC(tSC,tSC1), pList(j)="" }
		Else { Set pList(j)=tEntry }
	}
	Quit tSC
}

/// Return information for one item of a Production.
ClassMethod ProductionOneItem(pItem As Ens.Config.Item, pIsRunning As %Boolean = 0, seq As %Integer, Output pEntry As %String) As %Status [ Internal ]
{
	Set tID = pItem.%Id()
	Set tName=pItem.Name
	Set tType=..getHostTypeString(pItem.BusinessType())
	Quit:tType="actor" $$$OK
	If ##class(Ens.Config.DefaultSettings).%GetSetting(pItem.Production.Name,pItem.Name,pItem.ClassName,"","Enabled",.tSDSEnabled) {
		Set tEnabled = +tSDSEnabled
	} Else {
		Set tEnabled = +pItem.Enabled
	}
	Set tPartner=pItem.FindSettingByName("BusinessPartner","Host")
	Set tPartner=$S($IsObject(tPartner):tPartner.Value,1:"")
	Set statuses = ..ItemStatuses(tName,pIsRunning,tEnabled,tID)
	Set tStatus = $P(statuses,",",1)
	Set tIOStatus = $P(statuses,",",2)
	Set cls = pItem.ClassName
	Set isMissingClass = 0
	If (cls '= "") && ('##class(%Dictionary.CompiledClass).%ExistsId(cls)) {
		If ##class(%Dictionary.ClassDefinition).%ExistsId(cls) {
			Set isMissingClass = 2 // class is defined but not properly compiled
		} Else {
			Set isMissingClass = 1 // class does not exist
		}
	}
	Set pEntry=$LB(tName,tType,tEnabled,seq,tStatus,tIOStatus,tID,$S(""'=pItem.Comment:pItem.Comment, 1:pItem.ClassName),cls,tPartner,pItem.Category,isMissingClass)
	Quit $$$OK
}

ClassMethod ItemStatuses(pName As %String, pIsRunning As %Boolean = 0, pEnabled As %String, pID As %String) As %String [ Internal ]
{
	If pEnabled="" {
		// used by the status refresh logic
		Set tItem = ##class(Ens.Config.Item).%OpenId(pID,,.tSC)
		Quit:$$$ISERR(tSC) "NOTFOUND,NOTFOUND"
		If $IsObject(tItem) {
			If ##class(Ens.Config.DefaultSettings).%GetSetting(tItem.Production.Name,tItem.Name,tItem.ClassName,"","Enabled",.tSDSEnabled) {
				Set pEnabled = tSDSEnabled
			} Else {
				Set pEnabled = tItem.Enabled
			}
		}
	}
	If 'pIsRunning {
		Set tStatus= $select('pEnabled: "disabled", 1: "stopped")
		Set tIOStatus=tStatus
	} Else {
		Set tConfigId=$G($$$DispatchNameToConfigName(pName))
		If ""=tConfigId {
			Set tStatus="N/A"
			Set tIOStatus="N/A"
		} Else {
			Set tStatus = $ZCVT($$$GetHostMonitor(pName,$$$eMonitorStatus),"L") If tStatus="" Set tStatus="error"
			If 'pEnabled {
				If ((tStatus="ok")||(tStatus="inactive")) {
					Set tStatus = "disabled"
				}
			} Else {
				#; look to see if stopped - either because of schedule or temporary stop api
				If ($$$OrderHostMonitor(pName,$$$eMonitorJob,"") = "") && ($$$ConfigPoolSize(pName)>0) {
					/*	InProc items and adapterless business services might
						be configured with pool size which is ignored.
					*/
					Try {
						If '(($$$ConfigBusinessType(pName)=$$$eHostTypeService)&&($parameter($$$ConfigClassName(pName),"ADAPTER")="")) && 
							($parameter($$$ConfigClassName(pName),"INVOCATION")="Queue") {
								Set tStatus = "stopped"
							}
					} Catch {}
				}
			}
			// adapter status
			Set tIOStatus = "N/A"
			Set tStayConnected=$G($$$ConfigSetting(pName,"Adapter","StayConnected"))
			If tStayConnected'="" {
				// loop over Job status for this item to find out the adapter status
				Set j="" For { Set j=$$$OrderHostMonitor(pName,$$$eMonitorJob,j) Quit:""=j
					Set c = $$$GetJobMonitor(pName,j,$$$eMonitorConnected)
					If (+c) {
						Set tIOStatus="OK"
					}
					ElseIf $e(c)="." { ; "." means "listening for a connection"
						If tIOStatus="N/A" {
							// if listening in JobPerConnection mode w/ no connections, or not trying to always Stay Connected, show inactive
							Set tJobPer=$G($$$ConfigSetting(pName,"Adapter","JobPerConnection"))
							If tStayConnected>=0||tJobPer { Set tIOStatus="Inactive" }
							Else { Set tIOStatus="Error" }
						} ; else ignore it and let the other jobs determine the status
					}
					ElseIf (c '= "") { ; not connected
						If tStayConnected<0 {
							Set tIOStatus="Error"
							Quit
						}
						#; Disconnected items with queued stuff are in Error state
						Set tQName=$G($$$ConfigQueueName(pName)," ")
						Set tQLen=$G($$$EnsQueue(tQName,0,"count"))
						If tQLen {
							Set tIOStatus="Error"
							Quit
						}
						If tIOStatus="N/A" {
							Set tIOStatus="Inactive"
							Quit
						} ; else ignore it and let the other jobs determine the status
					} ; Else no connection info - remain N/A
				}
			}
		}
	}
	Set str = tStatus_","_tIOStatus
	If $G(%session.Data("ProdConf_Status",$NAMESPACE,pName))'=str {
		Set %session.Data("ProdConf_Status",$NAMESPACE,pName) = str
		Set %session.Data("ProdConf_Status",$NAMESPACE,pName,"id") = pID
	}
	Quit str
}

/// Return a flag indicating if the Production state has changed 
/// concatenated with a list of items whose status have changed.
ClassMethod CheckForProductionStatusChange(pProductionName As %String) As %String
{
	Set tHasChanged = 0
	Kill tName, tState
	Set tSC = ##class(Ens.Director).GetProductionStatus(.tName, .tState,,1)
	If ($G(tName)'=pProductionName) {
		Set tState = $$$eProductionStateStopped
	}
	ElseIf $$$ISERR(tSC) || ($G(tName)="") || ($G(tState)="") {
		Quit "0#" // Cannot determine
	}

	If tState=$$$eProductionStateRunning {
		Set tProdModified = $$$EnsProdModChanged
		If tProdModified {
			#; Start at -100 because 0 is $$$eProductionStateUnknown
			Set tState = -100 - $$$EnsProdModCounterGet
		}
		Else {
			// Production is running; check if there is at least one dead job
			Set tHasDeadJobs = 0
			Set tDeadPrefix = $$$SystemName_":Z"
			Set tPrefixLen = $L(tDeadPrefix)
			Set tJob=tDeadPrefix
			For {
				Set tJob = $$$OrderJobMonitor(tJob)
				Quit:tJob=""
				If $E(tJob,1,tPrefixLen)=tDeadPrefix {
					Set tHasDeadJobs = 1
					Quit
				}
			}
			If tHasDeadJobs {
				// We found dead job(s)
				// (other kinds of needed updates are not detected by this method)
				Set tState = "?"
			}
		}
	}

	If $G(%session.Data("ProdConf_Status",$NAMESPACE,"$Production"))=tState {
		Set tHasChanged = 0 // Production status is the same
	}
	Else {
		Set %session.Data("ProdConf_Status",$NAMESPACE,"$Production") = tState
		Set tHasChanged = 1 // Production status has changed
	}
	Set tIsRunning = (tState=$$$eProductionStateRunning)||(tState="?")||$get(tProdModified)

	//Quit tHasChanged_"#"_..CheckForItemStatusChanges(tIsRunning)
	Set itemStatus = ..CheckForItemStatusChanges(tIsRunning)
	If itemStatus = "NOTFOUND,NOTFOUND" {
		Quit "@"
	} Else {
		Quit tHasChanged_"#"_itemStatus
	}
}

/// Return a string containing a delimited list of items whose status has changed since last check.
/// A maximum of ~32000 characters is returned; in general a few characters will be sufficient,
/// but if not, in the next check the remaining chunk of changes will be returned.
ClassMethod CheckForItemStatusChanges(pIsRunning As %Boolean = 0) As %String
{
	Set ret = ""
	Try {
		Set name=""
		For {
			Set name = $O(%session.Data("ProdConf_Status",$NAMESPACE,name))
			Quit:name=""
			Continue:name="$Production"
			Set status = $G(%session.Data("ProdConf_Status",$NAMESPACE,name))
			Set id = +$G(%session.Data("ProdConf_Status",$NAMESPACE,name,"id"))
			Set str = ..ItemStatuses(name, pIsRunning, "", id)
			If str = "NOTFOUND,NOTFOUND" {
				Set ret = str
				Quit
			}
			If str'=status {
				Set:ret'="" ret = ret_";"
				Set ret = ret_id_","_str
			}
			Quit:$L(ret)>32000
		}
	}
	Catch {
	}
	Quit ret
}

/// The pConfigItemName argument may contain the following elements:
///   ProductionName||ConfigName|CommentOrClassname
/// Only the ConfigName portion is required.
/// If ProductionName is not given, then the currently running or last run Production will be used.
/// CommentOrClassname is the name shown in the Config page's dropdown list for multiple items having the
///  same ConfigName. If it is not given, then if more than one item of the given ConfigName exists, all will match.
///  
/// In order for this method to work properly, none of the names of the items in your production should 
///  contain the '|' character.
ClassMethod ItemLineConnections(pConfigItem As %String, Output pList, Output pColNames) As %Status
{
	Set tSC=$$$OK  Kill pList
	Set pColNames=$LB("itemName","isTarget")

	If $IsObject(pConfigItem) {
		Set tItem=pConfigItem
	} Else {
		#; Get the named item
		Set tItem=##class(Ens.Config.Production).OpenItemByConfigName(pConfigItem,.tSC)  Quit:$$$ISERR(tSC) tSC
	}
	Set tProduction=tItem.Production

	#; Get the outgoing connections
	Do ##class(Ens.Config.Production).GetConnections(.tArray,tItem.ClassName,tItem)
	#; invoke additional callback to pick up instance-specific connections
	try { If $$$comClassDefined(tItem.ClassName) Do $classmethod(tItem.ClassName,"OnGetConnections",.tArray,tItem) } catch {}
	#; Remove potential self reference
	Kill tArray(tItem.Name)
	Merge tClassCache(tItem.ClassName,"data") = tArray
	Set name="" For { Set name=$O(tArray(name))  Quit:""=name ; name of connected item
		Set pList($I(tCounter))=$LB(name,1)
	}
	#; Get the incoming connections
	Kill %objlasterror
	Set tRS = ##class(%ResultSet).%New("Ens.Config.Production:EnumerateConfigItems")
	If '$IsObject(tRS) Quit $$$ERROR($$$EnsErrGeneral,"Failed to create ResultSet for query Ens.Config.Production:EnumerateConfigItems : "_$$$StatusDisplayString($G(%objlasterror)))
	Do tRS.Execute(tProduction.Name,,1)
	Set i=0  While tRS.Next(.tSC) && $$$ISOK(tSC) {
		Set tHost = tRS.Data("ConfigName")
		Continue:tHost=tItem.Name
		Set tClass = tRS.Data("ClassName")
		Kill tArray
		If ('$D(tClassCache(tClass))) {
			Do ##class(Ens.Config.Production).GetConnections(.tArray,tClass)
			Set tClassCache(tClass) = ""
			Merge tClassCache(tClass,"data") = tArray
		} Else {
			Merge tArray = tClassCache(tItem.ClassName,"data")
		}
		If $D(tArray(tItem.Name)) {
			Set pList($I(tCounter))=$LB(tHost,0)
		} Else {
			#; invoke additional callback to pick up instance-specific connections
			Set tItem2=##class(Ens.Config.Item).%OpenId(tRS.Data("ItemId"),,.tSC)
			try { If $$$comClassDefined(tClass) Do $classmethod(tClass,"OnGetConnections",.tArray,tItem2) } catch ex {}
			If $D(tArray(tItem.Name)) {
				Set pList($I(tCounter))=$LB(tHost,0)
			}
		}
	}
	Quit tSC
}

/// Givem an item id, return a list of the items that are connected to it.
ClassMethod ItemLineConnectionsById(pItemId As %String, pProd As %String, pCat As %String = "", Output pList, Output pColNames) As %Status
{
	Set tSC = $$$OK
	Kill pList
	Set pColNames=$LB("itemName","isTarget","itemId")

	Set tItem = ##class(Ens.Config.Item).%OpenId(pItemId,,.tSC)
	Quit:$$$ISERR(tSC) tSC

	#; Get the outgoing connections
	Do ##class(Ens.Config.Production).GetConnections(.tArray,tItem.ClassName,tItem)
	Set tClassCache(tItem.ClassName) = ""
	Merge tClassCache(tItem.ClassName,"data") = tArray
	#; invoke additional callback to pick up instance-specific connections
	try { If $$$comClassDefined(tItem.ClassName) Do $classmethod(tItem.ClassName,"OnGetConnections",.tArray,tItem) } catch {}
	Set tName = tItem.Name
	#; Remove potential self reference
	Kill tArray(tName)
	Set name="" For { Set name=$O(tArray(name))  Quit:""=name ; name of connected item
		Set pList($I(tCounter))=$LB(name,1,"")
	}
	#; Get the incoming connections
	Kill %objlasterror
	Set tRS = ##class(%ResultSet).%New("Ens.Config.Production:EnumerateConfigItems")
	If '$IsObject(tRS) Quit $$$ERROR($$$EnsErrGeneral,"Failed to create ResultSet for query Ens.Config.Production:EnumerateConfigItems : "_$$$StatusDisplayString($G(%objlasterror)))
	Do tRS.Execute(pProd,,1)
	Set i=0  While tRS.Next(.tSC) && $$$ISOK(tSC) {
		Set tHost = tRS.Data("ConfigName")
		Continue:tHost=tName

		// If filtered by category, skip items that do not match
		If pCat'="" {
			Set tMatch = 0
			Set tCat =tRS.Data("Categories")
			For i = 1:1:$L(tCat,",") {
				If $ZStrip($P(tCat,",",i),"<>W")=pCat {
					Set tMatch = 1
					Quit
				}
				Quit:tMatch
			}
			Continue:'tMatch
		}

		Set tClass = tRS.Data("ClassName")
		Kill tArray
		If ('$D(tClassCache(tClass))) {
			Do ##class(Ens.Config.Production).GetConnections(.tArray,tClass)
			Set tClassCache(tClass) = ""
			Merge tClassCache(tClass,"data") = tArray
		} Else {
			Merge tArray = tClassCache(tClass,"data")
		}
		If $D(tArray(tName)) && (tName'="Ens.Alert") {
			Set pList($I(tCounter))=$LB(tHost,0)
		} Else {
			#; invoke additional callback to pick up instance-specific connections
			Set tItem2=##class(Ens.Config.Item).%OpenId(tRS.Data("ItemId"),,.tSC)
			try { If $$$comClassDefined(tClass) Do $classmethod(tClass,"OnGetConnections",.tArray,tItem2) } catch ex {}
			If $D(tArray(tName)) {
				Set pList($I(tCounter))=$LB(tHost,0,tItem2.%Id())
			}
		}
	}

	Quit tSC
}

/// Return a list of different settings that apply to the given item -- by item name.
ClassMethod ItemSettings(pConfigItemName As %String, Output pList, Output pColNames) As %Status
{
	Set tSC=$$$OK  Kill pList  Set pColNames=$LB("IsAdapter","Name","Value","ValueSource","DefaultValue","DefaultSource","Description","DataType","MAXLEN","MINVAL","MAXVAL","VALUELIST","DISPLAYLIST","IsRequired","LocalizedName","Category","LocalizedCategory","EditorContext")

	Do ##class(Ens.Director).ParseConfigItemName(pConfigItemName,.tProductionName,.tItemName,.tCommentOrClass)
	If tItemName="$Production" {
		Set tItem=##class(Ens.Config.Production).%OpenId(tProductionName,,.tSC)  Quit:$$$ISERR(tSC) tSC
	} Else {
		Set tItem=##class(Ens.Config.Production).OpenItemByConfigName(pConfigItemName,.tSC)  Quit:$$$ISERR(tSC) tSC
	}
	Set tSC=tItem.GetStaticSettings(.pList)  Quit:$$$ISERR(tSC) tSC

	Do tItem.PopulateVirtualSettings()
	Set n0=$O(pList(""),-1)
	Set n=tItem.VirtualSettings.Count()
	For i=1:1:n {
		Set pList(n0+i)=tItem.VirtualSettings.GetAt(i)
	}
	Quit tSC
}

/// Return a list of different settings that apply to the given item -- by item Id.
ClassMethod ItemSettingsById(pItemId As %String, pProd As %String, Output pList, Output pColNames) As %Status
{
	Set tSC = $$$OK
	Kill pList
	Set pColNames = $LB("IsAdapter","Name","Value","ValueSource","DefaultValue","DefaultSource","Description","DataType","MAXLEN","MINVAL","MAXVAL","VALUELIST","DISPLAYLIST","IsRequired","LocalizedName","Category","LocalizedCategory","EditorContext")

	If pItemId=-1 {
		Set tItem = ##class(Ens.Config.Production).%OpenId(pProd,,.tSC)  Quit:$$$ISERR(tSC) tSC
	} Else {
		Set tItem = ##class(Ens.Config.Item).%OpenId(pItemId,,.tSC)  Quit:$$$ISERR(tSC) tSC
	}
	Set tSC = tItem.GetStaticSettings(.pList)  Quit:$$$ISERR(tSC) tSC

	Do tItem.PopulateVirtualSettings()
	Set n0 = $O(pList(""),-1)
	Set n = tItem.VirtualSettings.Count()
	For i = 1:1:n {
		Set pList(n0+i) = tItem.VirtualSettings.GetAt(i)
	}
	Quit tSC
}

/// pConfigItemName is in the form ProductionName||ItemName.  When ItemName is null, a summary of the queues for the Production is returned, 
/// otherwise the queue contents for the given item are returned. <br>
/// Returns pNumItems entries for the given config item's primary queue or the Production, starting after entry ID pPrevId.
/// If pPrevId is empty, starts from the beginning.
/// The pNumItems+1 output list element will be $LB("More...") if there are more entries. <br>
/// pMsg may contain an output informative message complementing the data array returned if any. <br>
/// pContinueIfItemMissing, if set to true, will allow the list to be populated if a message header object referenced 
/// in the queue is not found. If the message header is not found either *Deleted* (if the object is not there) or *Error* 
/// (if a SQL error was encountered) will be returned in the list structure via the source config item position.
/// The default for backwards compatibility is false. The Production configuration
/// portal page calls this method with pContinueIfItemMissing true. <br>
ClassMethod ItemQueueList(pConfigItemName As %String = "", Output pList, Output pColNames, Output pQueueName As %String, Output pQueueCount As %Integer, pNumItems As %Integer = 100, pPrevId As %String = "", Output pMsg As %String = "", pEnsActorQueueLimit As %Integer = 0, pContinueIfItemMissing As %Boolean = 0) As %Status
{
	Set tSC = $$$OK
	Kill pList
	Set pQueueName = ""
	Set pQueueCount = ""
	Set pColNames = ""

	Set tProductionName = $get($$$EnsRuntime("Name"),$get($$$EnsSuspended))
	Set tConfigProduction = $P(pConfigItemName,"||",1)
	Set tJustConfigItemName = $P(pConfigItemName,"||",2)
	If (tProductionName'=tConfigProduction) {
		Quit tSC
	}
	If tJustConfigItemName="" {
		// Production queues' summary
		Set pColNames = $LB("Queue","Count","Created")
		Set tRS = ##class(%ResultSet).%New("Ens.Queue:Enumerate")
		If '$IsObject(tRS) Quit $$$ERROR($$$EnsErrGeneral,"Failed to create ResultSet for query Ens.Queue:Enumerate : "_$$$StatusDisplayString($G(%objlasterror)))
		Do tRS.Execute()
		Set i=0  While tRS.Next(.tSC) && $$$ISOK(tSC) {
			Set tId=tRS.Data("Name")
			Continue:""'=pPrevId&&(tId'=pPrevId)
			If tId=pPrevId Set pPrevId=0  Continue
			Set i=i+1  Quit:i>pNumItems
			Set pList(i)=$LB(tId,tRS.Data("Count"),tRS.Data("Created"))
		}
		Set:i&&$$$ISOK(tSC)&&tRS.Next() pList(i+1)=$LB("more...")
		Set pQueueCount = i
		Set pQueueName = "Production"
		Quit tSC
	} Else {
		// Item's queue
		Set pColNames = $LB("QId","QCount","HeaderId","IsRequest","TimeCreated","Source","Target","Status","Error","BPId","BodyClass","Priority","Index")

		#; Get the named item
		Set tItem=##class(Ens.Config.Production).OpenItemByConfigName(pConfigItemName,.tSC)  Quit:$$$ISERR(tSC) tSC
		Set tIsMsgBankOperation = 0
		Try {
			Set tIsMsgBankOperation = $classmethod(tItem.ClassName,"%Extends","Ens.Enterprise.OperationBase")
		}
		Catch {}

		#; For BP items using Actor pool, only return headers addressed to this config item.
		Set pQueueName=$$$getConfigQueueName(tItem.Name,"")
		If ""=pQueueName&&$D($$$EnsSuspended($$$SystemName,"Ens.Queue")) {
			If $$$eHostTypeProcess=tItem.BusinessType()&&'tItem.PoolSize {
				Set pQueueName="Ens.Actor"
			} Else {
				Set pQueueName=tItem.QueueName()
			}
		}
		If pQueueName="" {
			If '##class(Ens.Director).IsProductionRunning() {
				Set pMsg = $$$TextHTML("Production is not running")
			}
			Else {
				Set tErrMsg = $$$TextHTML("No queue found for this item")
				Set tSC = $$$ERROR($$$EnsErrGeneral,tErrMsg)
			}
			Quit tSC
		}
		Set pQueueCount=##class(Ens.Queue).GetCount(pQueueName)
		
		/* If a large queue then need to change way to find items but this method does return in queue order */
		If (pQueueName="Ens.Actor") {
			Set tSQL = "Select count(*) As TotalCount FROM Ens.MessageHeader Where Status=2 And TargetConfigName = ?"
			Set tStatement = ##class(%SQL.Statement).%New()
			Set tSC = tStatement.%Prepare(tSQL)
			If $$$ISERR(tSC) Quit tSC
			Set tRS = tStatement.%Execute(tJustConfigItemName)
			If tRS.%Next() Set tActorQueueCount = pQueueCount, pQueueCount = tRS.TotalCount
			/* no need to look if this item has none in the Ens.Actor queue */
			If pQueueCount = 0 Quit tSC
			/* Do not go through queue but search MessageHeader status to prevent delay if pEnsActorQueueLimit is positive.
				This can show items not in the actual queue so Config page uses time.
			*/
			If (pEnsActorQueueLimit>0) && (tActorQueueCount>pEnsActorQueueLimit) {
				Set tSQL = "Select top ? ID As MessageId, Priority,Type,TimeCreated,SourceConfigName,TargetConfigName,Status,IsError,BusinessProcessId,MessageBodyClassName,MessageBodyId FROM Ens.MessageHeader Where Status=2 And TargetConfigName = ? ORDER BY ID ASC"
				Set tSC = tStatement.%Prepare(tSQL)
				If $$$ISERR(tSC) Quit tSC
				Set tRS = tStatement.%Execute((pNumItems+2),tJustConfigItemName)
				Set i=0  While tRS.%Next(.tSC) && $$$ISOK(tSC) {
					/* we do not know the entry id on the Ens.Queue global so it can't be aborted from this information so prepend an * to indicate that this is a message header id and not index */
					Set tHdrId=tRS.MessageId
					Set tId=tRS.Priority_":"_"*"_tHdrId, tIndex = "*"_tHdrId
					If tIsMsgBankOperation Set tHdrId=$P(tHdrId,"_",3,99)
					Set i=i+1  Quit:i>pNumItems
					Set pList(i)=$LB(tId,pQueueCount,tHdrId,tRS.Type,$$$timeUTCtoLocal(tRS.TimeCreated),tRS.SourceConfigName,tRS.TargetConfigName,tRS.Status,tRS.IsError,tRS.BusinessProcessId,tRS.MessageBodyClassName,tRS.Priority,tIndex)
				}
				If (i>pNumItems)&&$$$ISOK(tSC) Set pList(i)=$LB("more...")
				Quit tSC
			}
		}
		Set tRS = ##class(%ResultSet).%New("Ens.Queue:EnumerateItem")
		If '$IsObject(tRS) Quit $$$ERROR($$$EnsErrGeneral,"Failed to create ResultSet for query Ens.Queue:EnumerateItem : "_$$$StatusDisplayString($G(%objlasterror)))
		Do tRS.Execute(pQueueName)
		Set tTime0=$ZH
		Set i=0  While tRS.Next(.tSC) && $$$ISOK(tSC) {
			Set tId=tRS.Data("Priority")_":"_tRS.Data("Index")
			Continue:""'=pPrevId&&(tId'=pPrevId)
			If tId=pPrevId Set pPrevId=0  Continue
			Set tHdrId=tRS.Data("MessageId")
			If tIsMsgBankOperation Set tHdrId=$P(tHdrId,"_",3,99)
			&sql(SELECT Type,TimeCreated,SourceConfigName,TargetConfigName,Status,IsError,BusinessProcessId,MessageBodyClassName,MessageBodyId INTO :tType,:tTimeCreated,:tSourceConfigName,:tTargetConfigName,:tStatus,:tIsError,:tBusinessProcessId,:tMessageBodyClassName,:tMessageBodyId FROM Ens.MessageHeader WHERE ID = :tHdrId)
			If SQLCODE {
				If pContinueIfItemMissing {
					Set (tType,tTimeCreated,tTargetConfigName,tStatus,tIsError,tBusinessProcessId,tMessageBodyClassName,tMessageBodyId)=""
					If SQLCODE=100 {
						Set tSourceConfigName = "*Deleted*"
					} Else {
						Set tSourceConfigName = "*Error*"
					}
				} Else {
					Set tSC=$$$ERROR($$$EnsErrGeneral,"Query for queued message header with ID "_tHdrId_" failed with SQLCODE "_SQLCODE_" / "_$G(%msg))
					Quit
				}
			} Else {
				#; We don't do this if SQLCODE & pContinueIfItemMissing
				If (pQueueName="Ens.Actor") {
					#;Time limit in seconds to retrieve if pEnsActorQueueLimit is negative
					If (pEnsActorQueueLimit<0)&&((tTime0-$ZH)<pEnsActorQueueLimit) {
						#; If we timed out before we found at least one use the code path to find 1 based on Ens MessageHeader
						If (i=0) Return ..ItemQueueList(pConfigItemName, .pList, .pColNames, .pQueueName, .pQueueCount, 1, pPrevId, .pMsg,1)
						Quit
					}
					If (""'=tTargetConfigName)&&(tTargetConfigName'=tJustConfigItemName) Continue
				}
			}
			Set i=i+1  Quit:i>pNumItems
			Set pList(i)=$LB(tId,pQueueCount,tHdrId,tType,$$$timeUTCtoLocal(tTimeCreated),tSourceConfigName,tTargetConfigName,tStatus,tIsError,tBusinessProcessId,tMessageBodyClassName,tRS.Data("Priority"),tRS.Data("Index"))
			If (pQueueName="Ens.Actor") {If (i>=pQueueCount) Quit}
		}
		Set:i&&$$$ISOK(tSC)&&tRS.Next() pList(i+1)=$LB("more...")
		Quit tSC
	}
}

/// Returns <var>pNumItems</var> event log entries for the given config item, starting after entry ID <var>pPrevId</var>.
/// If <var>pPrevId</var> is empty, starts from the beginning.
/// The <var>pNumItems</var>+1 output list element will be $LB("more...") if there are more entries for this config item in the event log.
/// If <var>pConfigItemName</var> is an empty string, gets all available event log entries regardless of config item.
/// If <var>pEventsCount</var> is passed in as 0, <var>pEventsCount</var> will NOT be calculated, as the query may be expensive on very large systems;
/// in this case the value of <var>pEventsCount</var>, if passed by reference, will be the actual number of rows returned.
ClassMethod ItemEventLog(pConfigItemName As %String = "", Output pList, Output pColNames, ByRef pEventsCount As %Integer, pNumItems As %Integer = 100, pPrevId As %String = "") As %Status
{
	Set tSC = $$$OK  
	Kill pList
	Set tGetEventCount = ($get(pEventsCount,"") '= 0)
	Set pEventsCount = 0
	Set pColNames = $LB("Id","Seq","TimeLogged","TraceCat","Type","Job","Session","Source","Method","Stack","MessageId","Text")
	Set tTop = pNumItems+1

	If (""=pPrevId) {
		If (""=pConfigItemName) {
			&sql(DECLARE C1 CURSOR FOR
				SELECT TOP :tTop ID,%EXTERNAL(TimeLogged),TraceCat,%EXTERNAL(Type),Job,SessionId,ConfigName,SourceClass,SourceMethod,Text,Stack,MessageId
					INTO :tID,:tTimeLogged,:tTraceCat,:tType,:tJob,:tSessionId,:tConfigName,:tSourceClass,:tSourceMethod,:tText,:tStack,:tMessageId
					FROM Ens_Util.Log ORDER BY ID DESC
				)
			&sql(OPEN C1)
			For i = 1:1:pNumItems {
				&sql(FETCH C1)
				Quit:SQLCODE
				Set pEventsCount = pEventsCount+1
				Set pList(i)=$LB(tID,pEventsCount,tTimeLogged,tTraceCat,tType,tJob,tSessionId,tConfigName,tSourceClass_":"_tSourceMethod_"()",tStack,tMessageId,tText)
			}
			Set tCode=SQLCODE
			&sql(CLOSE C1)
			Set:'SQLCODE SQLCODE = tCode
		}
		Else {
			&sql(DECLARE C2 CURSOR FOR
				SELECT TOP :tTop ID,%EXTERNAL(TimeLogged),TraceCat,%EXTERNAL(Type),Job,SessionId,ConfigName,SourceClass,SourceMethod,Text,Stack,MessageId
					INTO :tID,:tTimeLogged,:tTraceCat,:tType,:tJob,:tSessionId,:tConfigName,:tSourceClass,:tSourceMethod,:tText,:tStack,:tMessageId
					FROM Ens_Util.Log WHERE ConfigName=:pConfigItemName ORDER BY ID DESC
				)
			&sql(OPEN C2)
			For i = 1:1:pNumItems {
				&sql(FETCH C2)
				Quit:SQLCODE
				Set pEventsCount = pEventsCount+1
				Set pList(i)=$LB(tID,pEventsCount,tTimeLogged,tTraceCat,tType,tJob,tSessionId,tConfigName,tSourceClass_":"_tSourceMethod_"()",tStack,tMessageId,tText)
			}
			Set tCode=SQLCODE
			&sql(CLOSE C2)
			Set:'SQLCODE SQLCODE = tCode
		}
	}
	Else {
		If (""=pConfigItemName) {
			&sql(DECLARE C3 CURSOR FOR
				SELECT TOP :tTop ID,%EXTERNAL(TimeLogged),TraceCat,%EXTERNAL(Type),Job,SessionId,ConfigName,SourceClass,SourceMethod,Text,Stack,MessageId
					INTO :tID,:tTimeLogged,:tTraceCat,:tType,:tJob,:tSessionId,:tConfigName,:tSourceClass,:tSourceMethod,:tText,:tStack,:tMessageId
					FROM Ens_Util.Log WHERE ID < :pPrevId ORDER BY ID DESC
				)
			&sql(OPEN C3)
			For i = 1:1:pNumItems {
				&sql(FETCH C3)
				Quit:SQLCODE
				Set pEventsCount = pEventsCount+1
				Set pList(i) = $LB(tID,pEventsCount,tTimeLogged,tTraceCat,tType,tJob,tSessionId,tConfigName,tSourceClass_":"_tSourceMethod_"()",tStack,tMessageId,tText)
			}
			Set tCode=SQLCODE
			&sql(CLOSE C3)
			Set:'SQLCODE SQLCODE = tCode
		}
		Else {
			&sql(DECLARE C4 CURSOR FOR
				SELECT TOP :tTop ID,%EXTERNAL(TimeLogged),TraceCat,%EXTERNAL(Type),Job,SessionId,ConfigName,SourceClass,SourceMethod,Text,Stack,MessageId
					INTO :tID,:tTimeLogged,:tTraceCat,:tType,:tJob,:tSessionId,:tConfigName,:tSourceClass,:tSourceMethod,:tText,:tStack,:tMessageId
					FROM Ens_Util.Log WHERE ConfigName=:pConfigItemName AND ID < :pPrevId ORDER BY ID DESC
				)
			&sql(OPEN C4)
			For i = 1:1:pNumItems {
				&sql(FETCH C4)
				Quit:SQLCODE
				Set pEventsCount = pEventsCount+1
				Set pList(i) = $LB(tID,pEventsCount,tTimeLogged,tTraceCat,tType,tJob,tSessionId,tConfigName,tSourceClass_":"_tSourceMethod_"()",tStack,tMessageId,tText)
			}
			Set tCode=SQLCODE
			&sql(CLOSE C4)
			Set:'SQLCODE SQLCODE = tCode
		}
	}

	Set:pEventsCount&&'SQLCODE pEventsCount = pEventsCount+1, pList(pEventsCount) = $LB("more...")

	If (""=pConfigItemName) {
		Set:SQLCODE&&(100'=SQLCODE) tSC = $$$ERROR($$$EnsErrGeneral,"Event Log full query failed with SQLCODE "_SQLCODE)
	}
	Else {
		Set:SQLCODE&&(100'=SQLCODE) tSC = $$$ERROR($$$EnsErrGeneral,"Event Log query failed for item "_pConfigItemName_" with SQLCODE "_SQLCODE)
	}

	If $$$ISOK(tSC) && (tGetEventCount) {
		If (""=pConfigItemName) {
			&sql(SELECT Count(*) INTO :tCount FROM Ens_Util.Log)
			Set:SQLCODE tSC = $$$ERROR($$$EnsErrGeneral,"Event Log full count query failed with SQLCODE "_SQLCODE)
		}
		Else {
			&sql(SELECT Count(*) INTO :tCount FROM Ens_Util.Log WHERE ConfigName=:pConfigItemName)
			Set:SQLCODE tSC = $$$ERROR($$$EnsErrGeneral,"Event Log count query failed for item "_pConfigItemName_" with SQLCODE "_SQLCODE)
		}
		Set pEventsCount = tCount
	}
	
	Quit tSC
}

/// Return all config jobs for the given config item
ClassMethod ItemJobs(pConfigItemName As %String, Output pList, Output pColNames) As %Status
{
	Set tSC=$$$OK  Kill pList  Set pColNames=$LB("Job","Name","Status","AdapterState","LastActivity","Count","Method","Retry","ActiveMessage")

	#; Get the named item
	Set tItem=##class(Ens.Config.Production).OpenItemByConfigName(pConfigItemName,.tSC)  Quit:$$$ISERR(tSC) tSC

	Set tRS = ##class(%ResultSet).%New("Ens.Util.Statistics:EnumerateJobStatus")
	If '$IsObject(tRS) Quit $$$ERROR($$$EnsErrGeneral,"Failed to create ResultSet for query Ens.Util.Statistics:EnumerateJobStatus : "_$$$StatusDisplayString($G(%objlasterror)))
	Do tRS.Execute(pConfigItemName)
	Set i=0  While tRS.Next(.tSC) && $$$ISOK(tSC) {
	; Name:%String,Job:%String,Status:%String,AdapterState:%String,LastActivity:%TimeStamp,Count:%Integer,Method:%String,Retry:%Integer,ActiveMessage:%String")
		Set i=i+1
	; $LB("Job","Name","Status","AdapterState","LastActivity","Count","Method","Retry","ActiveMessage")
		Set pList(i)=$LB(tRS.Data("Job"),tRS.Data("Name"),tRS.Data("Status"),tRS.Data("AdapterState"),tRS.Data("LastActivity"),tRS.Data("Count"),tRS.Data("Method"),tRS.Data("Retry"),tRS.Data("ActiveMessage"))
	}
	Quit tSC
}

ClassMethod HistoryList(pConfigItemName As %String, Output pList, Output pColNames) As %Status
{
	Set tSC=$$$OK  Kill pList  Set pColNames=$LB()

	#; Get the named item
	Set tItem=##class(Ens.Config.Production).OpenItemByConfigName(pConfigItemName,.tSC)  Quit:$$$ISERR(tSC) tSC

	Quit tSC
}

/// Utility method used to write out the HTML for a specific
/// Message Header in the Trace and Message Viewer pages.
/// <var>pID</var> is the message header ID.
ClassMethod DrawItemDetails(pID As %String = "", pClassname As %String = "Ens.MessageHeader") As %Status
{
	If (pID = "") {
		&html<<div class="detailContents">#($$$Text("Details for selected item"))#</div>>
		Quit $$$OK
	}

	Set tResource = $case(pClassname,	"Ens.MessageHeader": "%Ens_MessageHeader",
										"Ens.Util.Log": "%Ens_EventLog",
										: "%Ens_MessageContent")
	If ('$system.Security.Check(tResource,"USE")) || ('##class(%Dictionary.CompiledClass).%ExistsId(pClassname)) {
		&html<<div class="detailContents">#($$$Text("Not permitted to view message contents"))#</div>>
	}
	Else {
		Set tObject = $classmethod(pClassname,"%OpenId", pID)
		If '$IsObject(tObject) {
			&html<<div class="detailContents detailContentsError">#($$$FormatTextHTML($$$Text("Unable to open %1 object %2"), pClassname, pID))#</div>>
			Quit $$$OK
		}
		If pClassname '= "Ens.MessageHeader" {
			&html<<div class="detailContents"><b>#($zconvert(pClassname,"O","HTML"))#</b></div>>
		}
		Do:tObject.%Extends("EnsLib.EDI.Segmented") tObject.BuildMap()

		Set tDone = 1
		&html<<div class="detailContents">>
		Do ##class(%CSP.Util.AutoFormDynamic).DrawHTMLTable(tObject)
		&html<</div>>
		&html<</div>>
	}
	Quit $$$OK
}

/// Write out contents of body details panel.
/// <var>pHeaderID</var> is the message id.
ClassMethod DrawBodyInfo(pHeaderID As %String, pHeaderClass As %String = "Ens.MessageHeader") As %Status
{
	If (pHeaderID = "") {
		&html<<div class="detailContents">#($$$Text("Details for selected item"))#</div>>
	}
	ElseIf $case(pHeaderClass, "Ens.MessageHeader": 0, "Ens.Enterprise.MsgBank.MessageHeader": 0, : 1) 
			|| '$system.Security.Check("%Ens_"_$select(pHeaderClass="Ens.Enterprise.MsgBank.MessageHeader": "MsgBank_", 1:"")_"MessageContent","USE") {
		&html<<div class="detailContents">#($$$Text("Not permitted to view message contents"))#</div>>
	}
	Else {
		Try {
			Set tDone = 0
			Set tError = ""
			Set tSQL = "SELECT MessageBodyClassName, MessageBodyId FROM "_$select(pHeaderClass="Ens.MessageHeader": pHeaderClass, 1: "Ens_Enterprise_MsgBank.MessageHeader")_" WHERE %ID = ?"
			Set tRS = ##class(%SQL.Statement).%ExecDirect(,tSQL,pHeaderID)
			If tRS.%Next() {
				If tRS.MessageBodyClassName = "" {
					&html<<div class="detailContents">#($$$TextHTML("There is no message body associated with this message."))#</div>>
					Quit
				}
				&html<<div class="detailContents"><b>#(tRS.MessageBodyClassName)#</b></div>>
				If '##class(%Dictionary.CompiledClass).%ExistsId(tRS.MessageBodyClassName) {
					Set tError = $system.Status.GetErrorText($$$ERROR($$$ClassDoesNotExist, tRS.MessageBodyClassName))
					Quit
				}
				Set tBody = $classmethod(tRS.MessageBodyClassName, "%OpenId", tRS.MessageBodyId,0,.tSC)
				If $$$ISERR(tSC) {
					Set tError = $$$StatusDisplayString(tSC)
					Quit
				}
				Set tDone = 1
				&html<<div class="detailContents">>
				Do ##class(%CSP.Util.AutoFormDynamic).DrawHTMLTable(tBody)
				&html<</div>>
			}
			If 'tDone {
				Set tError = $$$TextHTML("Unable to display message body.")
			}
		}
		Catch {
			Set tError = $$$StatusDisplayString($$$SystemError)
		}
		If tError '= "" {
			&html<<div class="detailContents detailContentsError">#($zcvt(tError, "O", "HTML"))#</div>>
		}
	}
	Quit $$$OK
}

/// Common API to draw links for multiple pages in the portal.
ClassMethod DrawFullContentLinks() As %Status
{
	&html<
		<div id="contentLink_full" style="float: left;" title="Open a new tab to show full message in this default format">
			<a class="ribbonSortOption fullMessageLink" href="#" onclick="zenPage.showFullContent(false); return false;">#($$$TextHTML("View Full Contents","Ensemble"))#</a>
		</div>
		<div id="contentLink_raw" style="float: right;" title="RAW format is available for non XML Virtual Documents. JSON format is available for certain non EDI Documents.">
		  <label class="ribbonSortOption fullMessageLink" for="contentLink_options" onclick="zenPage.showFullContent((document.getElementById('contentLink_options').value==='RAW'),(document.getElementById('contentLink_options').value==='JSON')); return false;">View Format </label>
		  <select id="contentLink_options">
			<option class="ribbonSortOption fullMessageLink" value="RAW">#($$$TextHTML("Raw","Ensemble"))#</option>
			<option class="ribbonSortOption fullMessageLink" value="JSON">#($$$TextHTML("JSON","Ensemble"))#</option>
		  </select>
		</div>
		<div id="contentLink_clear" style="clear: both;"></div>
	>
	Quit $$$OK
}

ClassMethod DrawEventInfoStyle() As %Status
{
	&html<<style type="text/css">
/* styles for Event Information */
table.eventInfoTable {
	font-size: 0.9em;
}

table.eventInfoTable td {
	padding: 2px;
}

.eventCaption {
	font-weight: bold;
	font-size: 10pt;
}

.eventValue {
	font-weight: normal;
	font-size: 10pt;
}
.eventValue.eventType {
	font-weight: bold;
}
.eventType.eventWarning {
	color: darkred;
	background-color: orange;
}
.eventType.eventError {
	color: darkred;
	background-color: pink;
}
.eventType.eventAlert {
	color: darkred;
	background-color: yellow;
}
.eventType.eventTrace {
	color: darkblue;
	background-color: lightblue;
}
.eventText {
	padding: 5px;
	background-color: ivory;
	border: 1px solid gray;
}
.eventTextAction {
	cursor: pointer;
}

.eventTraceLink {
	font-size:9pt;
	padding: 10px 10px 10px 10px;
}
ul.eventStack {
	list-style: disc outside none;
	margin: 0 0 0 0.6em;
	padding-left: 0.6em;
}
.eventStack li {
	margin: 0;
	padding: 0;
}
.dynaGridLink {
	font-size: 9pt;
	/* background-color: white; */
	text-decoration: none;
	/* padding: 10px 0px 10px 10px; */
	color: #3B84BC;
}
</style>>
	Quit $$$OK
}

ClassMethod DrawRuleInfo(pRuleID As %String = "", pShowHeaderLinks As %Boolean = 0, pNarrowDisplay As %Boolean = 0) As %Status
{
	If (pRuleID = "") {
		&html<<div class="detailContents">#($$$Text("Details for selected item"))#</div>>
	}
	ElseIf ('$system.Security.Check("%Ens_RuleLog","USE")) {
		&html<<div class="detailContents">#($$$Text("You are not permitted to view Rule Log entries"))#</div>>
	}
	Else {
		// Get relevant properties of Ens_Rule.Log class to use in the detailed display
		Set qSQL = "SELECT * FROM Ens_Rule.Log WHERE %ID = ?"
		Set tRS = ##class(%ResultSet).%New()
		Set:tRS pSC = tRS.RuntimeModeSet(2) // display mode
		Set:tRS pSC = tRS.Prepare(qSQL)
		Set:pSC pSC = tRS.Execute(pRuleID)

		If (pSC && tRS.Next(.pSC)) {

			Set tRuleName = $G(tRS.Data("RuleName"))
			Set tSessionId = $G(tRS.Data("SessionId"))
			Set tRuleSet = $G(tRS.Data("RuleSet"))
			// action links 
			If pShowHeaderLinks {
				Set tTraceLinkStyle = ""
				#; Don't show the link if the user can't view the Visual Trace
				If $system.Security.Check("%Ens_MessageTrace","USE") {
					Set tTraceTitle = $$$TextHTML("Click to view a visual trace of the session")
					Set tTraceOnClick = "zenPage.showTrace('"_$zconvert($zconvert(tSessionId,"O","JS"),"O","HTML")_"');"
				}
				Else {
					Set tTraceTitle = $$$TextHTML("You are not permitted to view the Visual Trace page")
					Set tTraceOnClick = "alert('"_$zconvert($$$TextJS("You are not permitted to view the Visual Trace page"),"O","HTML")_"');"
					Set tTraceLinkStyle = "color: #777;"
				}

				Set tRuleLinkStyle = ""
				#; Don't show the link if the user can't view the Rule Editor
				If ($system.Security.Check("%Ens_Code","READ") || $system.Security.Check("%Ens_Rules","READ") || $system.Security.Check("%Ens_RoutingRules","READ",) || $system.Security.Check("%Ens_BusinessRules","READ")) {
					Set tRuleTitle = $$$TextHTML("Click to view the definition of the rule that fired")
					Set tRuleOnClick = "zenPage.showRule('" _ $zconvert($zconvert(tRuleName,"O","JS"),"O","HTML") _ "');"
				}
				Else {
					Set tRuleTitle = $$$TextHTML("You are not permitted to view the Rule Editor")
					Set tRuleOnClick = "alert('"_$zconvert($$$TextJS("You are not permitted to view the Rule Editor"),"O","HTML")_"');"
					Set tRuleLinkStyle = "color: #777;"
				}
				&html<
					<div class="eventTraceLink" style="background:white;">
						<a href="#" title="#(tTraceTitle)#" class="dynaGridLink" style="padding-left: 60px; padding-right: 50px; #(tTraceLinkStyle)#" onclick="#(tTraceOnClick)# return false;">#($$$TextHTML("Visual Trace"))#</a>
						<a href="#" title="#(tRuleTitle)#" class="dynaGridLink" style="#(tRuleLinkStyle)#" onclick="#(tRuleOnClick)# return false;">#($$$TextHTML("Rule Definition"))#</a>
					</div>
				>
			}
			
			// display table 
			Set tProps = $LB(   $LB(tSessionId, $$$Text("Session ID")),
								$LB($G(tRS.Data("TimeExecuted")), $$$Text("Time Executed")),
								$LB(..CleanEventText(tRuleName, pNarrowDisplay), $$$Text("Rule Name")),
								$LB(tRuleSet, $$$Text("Rule Set")),
								$LB($G(tRS.Data("Reason")), $$$Text("Reason")),
								$LB($G(tRS.Data("IsError")), $$$Text("Error?")),
								$LB(..CleanEventText($G(tRS.Data("ErrorMsg")), pNarrowDisplay), $$$Text("Error Message")),
								$LB(..CleanEventText($G(tRS.Data("ReturnValue")), pNarrowDisplay), $$$Text("Return Value")),
								$LB($G(tRS.Data("ActivityName")), $$$Text("Activity Name")),
								$LB($G(tRS.Data("ConfigName")), $$$Text("Source")),
								$LB($G(tRS.Data("CurrentHeaderId")), $$$Text("Current Header Id")),
								$LB($G(tRS.Data("EffectiveBegin")), $$$Text("Effective Begin Date/Time")),
								$LB($G(tRS.Data("EffectiveEnd")), $$$Text("Effective End Date/Time"))				
								)
			&html<
			<table border="0" cellpadding="0" cellspacing="0">
			<tr valign="top"><td>
				<table class="eventInfoTable" border="0" cellpadding="0" cellspacing="0">
					<tr valign="top">
						<td class="eventCaption">#($REPLACE($$$Text("Execution ID"), " ", "&nbsp;"))#:</td>
						<td class="eventValue">#(pRuleID)#</td>
					</tr>
			>
			Set tNamePos = 3
			Set tReasonPos = 5
			Set tErrorMsgPos = 7
			For i=1:1:$LL(tProps) {
				Set tCurrentProp = $LG(tProps, i)
				Set tPropName = $LG(tCurrentProp, 1)
				Set tTitle = $LG(tCurrentProp, 2)

				// Special logic to link to original condition in RuleEditor
				If (i = tReasonPos) {
					Set tPropName = ..GetRuleReasonLink(tRS.Get("Reason"),tRuleSet,tRuleName)
				}
				If (tTitle [ "?") {
					If (tPropName) { Set tPropName = $$$Text("Yes") }
					Else { Set tPropName = $$$Text("No") }
				}
				ElseIf (tPropName = "") {
					Set tPropName = "("_$$$Text("none")_")"
				}

				If (i = tErrorMsgPos) {
					Set tValueJS = ..PrepareJSText(tPropName) 
					Set tCellClass = " eventText"
					If (tValueJS = ("("_$$$Text("none")_")")) {
						Set tOnClick = ""
					}
					Else {
						Set tCellClass = tCellClass _ " eventTextAction"
						Set tOnClick = "onclick=""ensShowEventText('"_tValueJS_"','"_tPropName_"','"_pRuleID_"');"""
					}
				}
				Else {
					Set tCellClass = ""
					Set tOnClick = ""
				}
				&html<
					<tr valign="top">
						<td class="eventCaption">#($REPLACE(tTitle, " ", "&nbsp;"))#:</td>
						<td class="eventValue#(tCellClass)#" #(tOnClick)#>#(tPropName)#</td>
					</tr>
				>
			}
			&html<</table>>
			&html<</td></tr></table>>
			Set tDebugId = $get(tRS.Data("DebugId"))
			If (tDebugId '= "") && ##class(Ens.Rule.DebugLog).DebugIdExists(tDebugId) {
				&html<<div class="ruleDebugWrapper">
					<div class="ruleDebugHeader">#($$$TextHTML("Detailed Logging"))#</div>
					<table class="ruleDebugData">
						<tr>
							<th>#($$$TextHTML("Log Level"))#</th>
							<th>#($$$TextHTML("Source"))#</th>
							<th>#($$$TextHTML("Message"))#</th>
						</tr>>
				Set tLogTypes($$$eRuleLogTypeUserDebug) = $$$TextHTML("Debug")
				Set tLogTypes($$$eRuleLogTypeConditionDebug) = $$$TextHTML("Condition")
				Set tDebugRS = ##class(%SQL.Statement).%ExecDirect(,"SELECT LogType,Source,Message,IsOtherwise FROM Ens_Rule.DebugLog WHERE DebugId = ? ORDER BY ID ASC",tDebugId)
				While tDebugRS.%Next() {
					&html<<tr>
					<td>#($get(tLogTypes(tDebugRS.LogType)))#</td>
					<td>#(..GetRuleReasonLink(tDebugRS.Source,tRuleSet,tRuleName,tDebugRS.IsOtherwise))#</td>
					<td>#($zconvert(tDebugRS.Message,"O","HTML"))#</td>
					</tr>>
				}
				&html<
					</table>
				</div>>
			}
		}
	}
	Quit $$$OK
}

ClassMethod GetRuleReasonLink(pReason As %String = "", pRuleSet As %String = "", pRuleName As %String = "", pAssumeOtherwise As %Boolean = 1) As %String
{
	Set tLink = pReason
	#; Don't show the link if the user can't view the Rule Editor
	If (pReason '= "") && ($system.Security.Check("%Ens_Code","READ") || $system.Security.Check("%Ens_Rules","READ") || $system.Security.Check("%Ens_RoutingRules","READ",) || $system.Security.Check("%Ens_BusinessRules","READ")) {
		Set tReason = pReason
		If (pRuleSet = "") {
			Set tRuleSet = 1
		}
		Else {
			Set tRuleSet = $piece(pRuleSet,"ruleSet: ",2,999)
			If tRuleSet ? 1"(#"1.N1")" {
				Set tRuleSet = +$extract(tRuleSet,3,*)
			}
		}
		Set tRuleSet = $zconvert($zconvert(tRuleSet,"O","JS"),"O","HTML")
		Set tFocusPath = ""
		If $extract(tReason,1,5) = "rule#" {
			Set tReason = $extract(tReason,6,*)
		}
		Set tPairLen = $length(tReason,"-rule#")
		For j=1:1:tPairLen {
			Set tCurrPair = $piece(tReason,"-rule#",j)
			Set tRuleNum = +tCurrPair
			Set tFocusPath = tFocusPath _ ":" _ tRuleNum
			Set tWhen = $piece(tCurrPair,":",$length(tCurrPair,":"))
			If (tWhen [ "#") {
				Set tWhen = +$piece(tWhen,"#",$length(tWhen,"#"))
			}
			Else {
				Set tWhen = $select(pAssumeOtherwise: "ow", 1: 0)
			}
			Set tFocusPath = tFocusPath _ "|" _ tWhen
		}
		Set tFocusPath = $extract(tFocusPath,2,*)
		Set tFocusPath = $zconvert($zconvert(tFocusPath,"O","JS"),"O","HTML")
		Set tLink = "<a href=""#"" style=""color: #3B84BC;"" title="""_$$$TextHTML("View this condition in the Rule Editor")_""" onclick=""zenPage.showRule('"_$zconvert($zconvert(pRuleName,"O","JS"),"O","HTML")_"',null,'"_tRuleSet_"','"_tFocusPath_"'); return false;"">"_$zconvert(pReason,"O","HTML")_"</a>"
	}
	Quit tLink
}

ClassMethod DrawEventInfo(pEventID As %String = "", pShowTraceLink As %Boolean = 0, pNarrowDisplay As %Boolean = 0, pIsEnterprise As %Boolean = 0) As %Status
{
		// Get relevant properties of Ens.Util.Log class to use in the detailed display
	If (pEventID = "") {
		&html<<div class="detailContents">#($$$TextHTML("Details for selected item"))#</div>>
	}
	ElseIf '$system.Security.Check("%Ens_"_$select(pIsEnterprise: "MsgBank_", 1: "")_"EventLog","USE") {
		&html<<div class="detailContents">#($$$TextHTML("You are not permitted to view Event Log entries"))#</div>>
	}
	Else {
		If pIsEnterprise {
			Set tEvent = ##class(Ens.Enterprise.MsgBank.Log).%OpenId(pEventID)
		}
		Else {
			Set tEvent = ##class(Ens.Util.Log).%OpenId(pEventID,,.tSC)
		}
		If '$IsObject(tEvent) {
			&html<<div class="detailContents">#($$$TextHTML("Unable to open requested Event Log entry"))#>
			If $$$ISERR(tSC) {
				Write "&nbsp;",$zconvert($system.Status.GetErrorText(tSC),"O","HTML")
			}
			&html<</div>>
			Quit $$$OK
		}

		// Format is $lb(<PropName>,<PropTitle>,<IsCollection>,<MustFormat>)
		Set tProps = $lb($lb("Type", $$$TextHTML("Type")),
						$lb("Text", $$$TextHTML("Text"), 0, 1),
						$lb("TimeLogged", $$$TextHTML("Logged")),
						$lb("ConfigName", $$$TextHTML("Source")),
						$lb("SessionId", $$$TextHTML("Session")),
						$lb("Job", $$$TextHTML("Job")),
						$lb("SourceClass", $$$TextHTML("Class")),
						$lb("SourceMethod", $$$TextHTML("Method")),
						$lb("TraceCat", $$$TextHTML("Trace")),
						$lb("StatusValue", $$$TextHTML("Stack From Status Value"),-1,1),
						$lb("Stack", $$$TextHTML("Stack When Logged"), 1, 1))
		If pShowTraceLink && (tEvent.SessionId '= "") {
			&html<<!-- action links -->
			<div class="tpAction" >
				<a href="#" class="eventTraceLink" onclick="zenPage.showTrace(#($ZCVT($ZCVT(tEvent.SessionId,"O","JS"),"O","HTML"))#);return false;">
					#($$$TextHTML("Trace"))#
				</a>
			</div>>
		}
		&html<
			<!-- detailed display table -->
			<table border=0 cellpadding=0 cellspacing=0>
			<tr valign="top"><td>
				<table class="eventInfoTable" border=0 cellpadding=0 cellspacing=0>
					<tr valign="top">
						<td class="eventCaption">#($$$TextHTML("ID"))#:</td>
						<td class="eventValue">#($ZCVT((pEventID),"O","HTML"))#</td>
					</tr>
		>
		For i=1:1:$ll(tProps) {
			Set tCurrentProp = $lg(tProps, i)
			Set tPropName = $lg(tCurrentProp, 1)
			Set tTitle = $lg(tCurrentProp, 2)

			If $lg(tCurrentProp, 3) { // Is a collection
				Set tColl = $property(tEvent, tPropName)
				/* needs converting to a collection to display */
				If $li(tCurrentProp, 3) = -1 {
					If tPropName = "StatusValue" {
						Set tColl = ##class(Ens.Util.Trace).GetStackInfoAsCollection(tColl)
					} Else {
						/* Unsupported -1 type  */
						Continue
					}
				}
				/*	skip display if nothing to show	*/
				If 'tColl.Count() Continue

				Set tValue = "<ul class=""eventStack"">"
				For j=1:1:tColl.Count() {
					Set tRealVal = tColl.GetAt(j)
					Set tRealVal = $select($extract(tRealVal,*)=":" : $extract(tRealVal, 1, *-1), 1: tRealVal)
					Set tValue = tValue _ "<li>"_..CleanEventText(tRealVal, pNarrowDisplay) _ "</li>"
				}
				Set tValue = tValue_"</ul>"
			}
			Else {
				Set tValue = $classmethod("Ens.Util.Log",tPropName_"LogicalToDisplay",$property(tEvent, tPropName))
				If $lg(tCurrentProp, 4) { // needs to be formatted
					Set tValue = ..CleanEventText(tValue, pNarrowDisplay)
				} Else {
					Set tValue = $ZCVT((tValue),"O","HTML")
				}
			}
			If (tValue = "") { Set tValue = "("_$$$TextHTML("none")_")" }
			Set tCellClass = $case(tPropName,
										"Type": "eventType event"_tValue,
										"Text": "eventText",
										: "")
			If (tPropName = "Type") { // We always retrieve Type before Text
				Set tPropText = tValue
			}
			Set tOnClick = ""
			If (tPropName = "Text") && (tValue '= ("("_$$$Text("none")_")")) {
				Set tCellClass = tCellClass _ " eventTextAction"
				Set tValueJS = ..PrepareJSText(tValue) 
				Set tOnClick = "onclick=""ensShowEventText('"_tValueJS_"','"_tPropText_"','"_$ZCVT(pEventID,"O","HTML")_"');"""
			}

			// Localize type names
			If (tPropName = "Type")	{ 
				Set tValue = $CASE(tValue,
								"Alert": $$$TextHTML("Alert"),
								"Assert": $$$TextHTML("Assert"),
								"Error": $$$TextHTML("Error"),
								"Info": $$$TextHTML("Info"),
								"Trace": $$$TextHTML("Trace"),
								"TraceCat": $$$TextHTML("Trace"),
								"Warning": $$$TextHTML("Warning"),
								: tValue)
			}

			// Draw the row
			&html<<tr valign="top">
					<td class="eventCaption">#(tTitle)#:</td>
					<td class="eventValue #(tCellClass)#" #(tOnClick)#>#(tValue)#</td>
				  </tr>>
		}
		&html<</table>>
		&html<</td></tr></table>>
	}
	Quit $$$OK
}

/// Prepare HTML text from CleanEventText() to be supplied to the JavaScript method ensShowEventText() as a JavaScript string
ClassMethod PrepareJSText(pText As %String) As %String [ Private ]
{
	set pText = $REPLACE(pText, "\", "\\")
	set pText = $REPLACE(pText, "&#39;", "\'")
	set pText = $REPLACE(pText, "<br/>", "\n")
	Quit pText
}

/// Prepare text to be displayed in HTML
ClassMethod CleanEventText(pText As %String, pNarrowDisplay As %Boolean) As %String [ Private ]
{
	// Find replacement character for newlines
	Set tRepChar = ""
	For i=0:1:31 {
		If (i '= 10) && '$find(pText,$char(i)) {
			Set tRepChar = $char(i)
			Quit
		}
	}
	
	// If it's a narrow display, insert a space for lines with a "^" after position 20
	If pNarrowDisplay {
		Set tTextOut = ""
		Set tRemText = pText
		Set tCount = 0
		For {
			Set tPos = $find(tRemText, "^")
			If 'tPos {
				Set tTextOut = tTextOut _ tRemText
				Quit
			}
			If ((tCount + tPos) <= 20) {
				Set tTextOut = tTextOut _ $extract(tRemText, 1, tPos - 1)
				Set tCount = tCount + tPos
			}
			Else {
				Set tTextOut = tTextOut _ $extract(tRemText, 1, tPos - 2) _ " ^"
				Set tCount = 0
			}
			Set tRemText = $extract(tRemText, tPos, *)
		}
		Set tTextOut = $replace(tTextOut, "' ", "'"_tRepChar)
	}
	Else {
		Set tTextOut = pText
	}
	
	Set tTextOut = $translate(tTextOut, $char(13))
	Set tTextOut = $replace(tTextOut, $char(10), tRepChar)
	Set tTextOut = $replace(tTextOut, "<br/>", tRepChar)
	Set tTextOut = $replace(tTextOut, "<br>", tRepChar)
	Set tTemp = tTextOut
	Set tTextOut = ""
	For {
		Set tPos = $find(tTemp, tRepChar)
		If 'tPos {
			Set tTextOut = tTextOut _ $zconvert(tTemp,"O","HTML")
			Quit
		}
		Set tTextOut = tTextOut _ $zconvert($extract(tTemp, 1, tPos-2),"O","HTML") _ "<br/>"
		Set tTemp = $extract(tTemp, tPos, *)
	}
	Quit tTextOut
}

/// Get a list of current productions.
ClassMethod GetProductionList(Output pProdList As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tRS = ##class(%ResultSet).%New("Ens.Config.Production:ProductionStatus")
		Set tSC = tRS.Execute()
		If $$$ISERR(tSC) Quit

		While (tRS.Next()) {
			Set tName = tRS.Data("Production")
			Set pProdList(tName) = ""
		}
	}
	Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

/// Get a list of BPL "components" within a given production.
ClassMethod GetItemsForProduction(pProdName As %String, pType As %String, Output pHostList As %String)
{
	Set tSC = $$$OK
	Try {
		Kill pHostList

		Set tProd = ##class(Ens.Config.Production).%OpenId(pProdName)
		If '$IsObject(tProd) {
			Set tSC = $$$ERROR($$$GeneralError,"Unable to open production: " _ pProdName)
			Quit
		}

		Set tCount = tProd.Items.Count()
		For i = 1:1:tCount {
			Set tItem = tProd.Items.GetAt(i)
			Set tItemType = tItem.BusinessType()
			Set tName = $S(tItem.Name="":tItem.ClassName,1:tItem.Name)

			If ((pType = "process") && (tItemType = $$$eHostTypeProcess)) {
				If ('..IsComponent(tItem.ClassName)) {
					Set pHostList(tName) = ""
				}
			}
			ElseIf ((pType = "component") && (tItemType = $$$eHostTypeProcess)) {
				If (..IsComponent(tItem.ClassName)) {
					Set pHostList(tName) = ""
				}
			}
			ElseIf ((pType = "operation") && (tItemType = $$$eHostTypeOperation)) {
				Set pHostList(tName) = ""
			}
		}

	}
	Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

/// Given a business process class name, return if it is a component
ClassMethod IsComponent(pClass As %String) As %Boolean
{
	Set tRet = 0
	Try {
		Set tRet = $classmethod(pClass,"IsComponent")
	}
	Catch(ex) {
		#; the error is most likely that this host does not
		#; support the IsComponent API.
		Set tRet = 0
	}
	Quit tRet
}

/// Method to check a comma-delimited list of resources in the format used for the
/// Zen RESOURCE parameter. The method returns true/1 if the user has the specified
/// privileges on any of the listed resources.
ClassMethod CheckResourceList(pResources As %String = "") As %Boolean
{
	If (pResources = "") || $$$IOwnAllRole Quit 1
	
	Set tPermitted = 0
	For i=1:1:$length(pResources,",") {
		Set tPiece = $piece(pResources, ",", i)
		Set tResource = $piece(tPiece, ":", 1)
		If tResource = "" Continue
		Set tPermission = $piece(tPiece, ":", 2)
		If tPermission = "" Set tPermission = "USE"
		Set tPermitted = $system.Security.Check(tResource, tPermission)
		If tPermitted Quit
	}
	Quit tPermitted
}

/// Category:<br/>
/// = "request" for request messages<br/>
/// = "response" for response messages<br/>
/// = "messages" for request messages and response messages<br/>
/// = "persistentvdoc" for subclasses of Ens.VDoc.Interface that are also persistent<br/>
/// = "persistentselect" for persistent classes with the unlikely prospects weeded out<br/>
/// = "classselect" for both persistent and non-persistent classes, with the unlikely prospects weeded out<br/>
/// = "classvdoc" for both persistent and non-persistent subclasses of Ens.VDoc.Interface, with some weeding out<br/>
Query EnumerateMessageClasses(Mode As %String, Category As %String) As %Query(ROWSPEC = "Name:%String,Type:%String")
{
}

ClassMethod EnumerateMessageClassesExecute(ByRef qHandle As %Binary, Mode As %String, Category As %String) As %Status
{
	Kill qHandle
	Set qHandle = ""
	Set tKey = $increment(^||%EnsMessageClasses)
	Set qHandle("key") = tKey
	Set tCount = 0
	
	If (Category = "request") {
		// Get Ens.Request and subclasses
		Set tCount = tCount + 1
		Set ^||%EnsMessageClasses(tKey,tCount) = "Ens.Request"
		Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		Do tRS.Execute("Ens.Request")
		While (tRS.Next()) {
			Set tName = tRS.Data("Name")
			If (..IsOKForMode(tName, Mode, Category)) {
				Set tCount = tCount + 1
				Set ^||%EnsMessageClasses(tKey,tCount) = tName
			}
		}
	}
	ElseIf (Category = "response") {
		// Get Ens.Response and subclasses
		Set tCount = tCount + 1
		Set ^||%EnsMessageClasses(tKey,tCount) = "Ens.Response"
		Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		Do tRS.Execute("Ens.Response")
		While (tRS.Next()) {
			Set tName = tRS.Data("Name")
			If (..IsOKForMode(tName, Mode, Category)) {
				Set tCount = tCount + 1
				Set ^||%EnsMessageClasses(tKey,tCount) = tName
			}
		}
	}
	ElseIf (Category = "messages") {
		// Get subclasses of Ens.MessageBody
		Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		Do tRS.Execute("Ens.Util.MessageBodyMethods")
		While (tRS.Next()) {
			Set tName = tRS.Data("Name")
			If $$$comClassKeyGet(tName,$$$cCLASSabstract) Continue
			Set tCount = tCount + 1
			Set ^||%EnsMessageClasses(tKey,tCount) = tRS.Data("Name")
		}
	}
	ElseIf (Category = "persistentvdoc") {
		// Get VDoc subclasses
		Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		Do tRS.Execute("Ens.VDoc.Interface")
		While (tRS.Next()) {
			Set tName = tRS.Data("Name")
			If $E(tName,1,15) = "EnsLib.EDI.XML." {
				If $E(tName,16,18) = "DOM"  Continue
				If $E(tName,16,19) = "Prop"  Continue
			}
			If ($$$comClassKeyGet(tName,$$$cCLASSclasstype) = "persistent") { // if the class is persistent
				If (..IsOKForMode(tName, Mode, Category)) {
					Set tCount = tCount + 1
					Set ^||%EnsMessageClasses(tKey,tCount) = tName
				}
			}
		}
	}
	ElseIf (Category = "persistentselect") {
		// Get persistent subclasses with the unlikely prospects weeded out
		Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		Do tRS.Execute("%Persistent")
		While (tRS.Next()) { Set tName = tRS.Data("Name")
			Continue:"%"=$E(tName,1) 
			Continue:"CSPX."=$E(tName,1,5)
			If $E(tName,1,3)="Ens" {
				#; Continue:"Portal."=$E(tName,4,10) ; no persistent portal classes
				If $E(tName,4)="." {
					Continue:"BP."=$E(tName,5,7)
					Continue:"Rule."=$E(tName,5,9) ; old Rules are persistent
					Continue:"Util."=$E(tName,5,9)
					Continue:"Config."=$E(tName,5,11)
					Continue:"Archive."=$E(tName,5,12)
					Continue:"Registry"=$E(tName,5,12)
					Continue:"Milestone"=$E(tName,5,13)
					Continue:"RecordMap."=$E(tName,5,14)
					Continue:"Deployment"=$E(tName,5,14)
					Continue:"Enterprise."=$E(tName,5,15)
					Continue:"MessageBody"=$E(tName,5,15)
					Continue:"GenericObject"=$E(tName,5,17)
					Continue:"MessageHeader"=$E(tName,5,17)
				}
			}
			If ##class(%ZEN.FinderUtils).isSubclassOf(tName,"Ens.BP.Context") Continue
			If ##class(%ZEN.FinderUtils).isSubclassOf(tName,"Ens.BP.Thread") Continue
			If ##class(%ZEN.FinderUtils).isSubclassOf(tName,"Ens.BusinessProcess") Continue
			If ##class(%ZEN.FinderUtils).isSubclassOf(tName,"Ens.VDoc.SearchTable") Continue
			If (..IsOKForMode(tName, Mode, Category)) {
				Set tCount = tCount + 1
				Set ^||%EnsMessageClasses(tKey,tCount) = tName
			}
		}
	}
	ElseIf (Category = "classselect") {
		// Get persistent and non-persistent classes with the unlikely message prospects weeded out
		Set tClass=""  For { Set tClass=$O(^rINDEXCLASS(tClass),1,tValue)  Quit:tClass=""
			Continue:$LG(tValue,3) ; System
			Continue:$LG(tValue,4) ; Hidden
			Set tName=$LG(tValue,2)
			Continue:"%"=$E(tName,1) 
			Continue:$$$comClassKeyGet(tName,$$$cCLASSabstract)
			Continue:""'=$$$comClassKeyGet(tName,$$$cCLASSgeneratedby)
			##; All IRIS classes have the system flag set
			Continue:##class(%ZEN.FinderUtils).isSubclassOf(tName,"Ens.BP.Context")
			Continue:##class(%ZEN.FinderUtils).isSubclassOf(tName,"Ens.BP.Thread")
			Continue:##class(%ZEN.FinderUtils).isSubclassOf(tName,"Ens.BusinessProcess")
			Continue:##class(%ZEN.FinderUtils).isSubclassOf(tName,"Ens.VDoc.SearchTable")
			Continue:##class(%ZEN.FinderUtils).isSubclassOf(tName,"Ens.DataTransform")
			Continue:##class(%ZEN.FinderUtils).isSubclassOf(tName,"Ens.Production")
			Set tCount = tCount + 1
			Set ^||%EnsMessageClasses(tKey,tCount) = tName
		}
	}
	ElseIf (Category = "classvdoc") {
		// Get persistent and non-persistent VDoc subclasses with some weeding out
		Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		Do tRS.Execute("Ens.VDoc.Interface")
		While (tRS.Next()) {
			Set tName = tRS.Data("Name")
			If $$$comClassKeyGet(tName,$$$cCLASSabstract) Continue
			If $E(tName,1,15) = "EnsLib.EDI.XML." {
				If $E(tName,16,18) = "DOM"  Continue
				If $E(tName,16,19) = "Prop"  Continue
			}
			Set tCount = tCount + 1
			Set ^||%EnsMessageClasses(tKey,tCount) = tName
		}
	}
	
	Quit $$$OK
}

ClassMethod EnumerateMessageClassesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateMessageClassesExecute ]
{
	Kill Row
	Set tSC = $$$OK
	Try {
		If ($get(qHandle("key")) = "") {
			Set qHandle = ""
		}
		Else {
			Set qHandle = $O(^||%EnsMessageClasses(qHandle("key"),qHandle),1,val)
		}
		If qHandle = "" {
			Set Row = ""
			Set AtEnd = 1
		}
		Else {
			Set Row = $LB(val,"cls")
			Set AtEnd = 0
		}
	}
	Catch ex {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

ClassMethod EnumerateMessageClassesClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateMessageClassesFetch ]
{
	If ($get(qHandle("key")) '= "") {
		Kill ^||%EnsMessageClasses(qHandle("key"))
	}
	Kill qHandle
	Quit $$$OK
}

/// Helper method to determine whether <var>pClassname</var> is actually a subclass of <var>pSuper</var>.
/// Its primary purpose is to determine whether uncompiled classes are valid DTLs and/or BPLs.
/// <var>pIsRegistered</var> is an indication of whether <var>pSuper</var> extends <class>%Library.RegisteredObject</class>
/// and should thus implement the %Extends classmethod.
/// This can be slow if used as not intended, so it is best to use it only for its primary purpose.
ClassMethod IsSubclass(pClassname As %String, pSuper As %String) As %Boolean [ Internal ]
{
	Set tIsSub = 0
	Try {
		If ##class(%Dictionary.CompiledMethod).IDKEYExists(pClassname,"%Extends") {
			Try {
				Set tIsSub = $classmethod(pClassname,"%Extends",pSuper)
			}
			Catch {
				Set tIsSub = 0
			}
			Quit
		}
	
		If ##class(%Dictionary.ClassDefinition).%ExistsId(pClassname) {
			Set tClasses = 1
			Set tClasses(1) = $lb(pClassname)
			Set tIsSub = 0
			Set tLevel = 1
			For {
				For i=1:1:$listlength(tClasses(tLevel)) {
					Set tClass = $listget(tClasses(tLevel), i)
					If $data(tSeen(tClass)) { Continue }
					Set tSeen(tClass) = ""
					If ##class(%Dictionary.CompiledMethod).IDKEYExists(tClass,"%Extends") {
						Set tIsSub = $classmethod(tClass,"%Extends",pSuper)
						If tIsSub Quit  ; May be wrong branch
					}
					Else {
						Set tSuper = $$$defClassKeyGet(tClass,$$$cCLASSsuper)
						If (tSuper = "") { Continue }
						Set tSuper = $listfromstring(tSuper)
						If $listfind(tSuper, pSuper) {
							Set tIsSub = 1
							Quit
						}
					}
					Set tClasses(tLevel + 1) = $get(tClasses(tLevel + 1)) _ tSuper
					Set tClasses = (tLevel + 1)
				}
				If tIsSub Quit
				Set tLevel = tLevel + 1
				If '$data(tClasses(tLevel)) Quit
			}
		}
	}
	Catch ex {
		Set tIsSub = 0
	}
	Quit tIsSub
}

/// Some finder searches want only request messages, or only response messages.
/// Based on that, this method determines whether we want the message class that we are looking at.
ClassMethod IsOKForMode(pClassname As %String, pMode As %String, pCategory As %String) As %Boolean
{
	If (pMode = "request") { // exclude responses from the finder
		Quit $S(##class(%ZEN.FinderUtils).isSubclassOf(pClassname, "Ens.Response"):0, 1:1)
	}
	ElseIf (pMode = "response") { // exclude requests from the finder
		Quit $S(##class(%ZEN.FinderUtils).isSubclassOf(pClassname, "Ens.Request"):0, 1:1)
	}
	ElseIf (pMode = "allmessages") { // include all messages in the finder, but separate groups by request and response
		If (pCategory = "request") { // exclude responses from this group
			Quit $S(##class(%ZEN.FinderUtils).isSubclassOf(pClassname, "Ens.Response"):0, 1:1)
		}
		ElseIf (pCategory = "response") { // exclude requests from this group
			Quit $S(##class(%ZEN.FinderUtils).isSubclassOf(pClassname, "Ens.Request"):0, 1:1)
		}
		Else { // default OK
			Quit 1
		}
	}
	Else { // default OK
		Quit 1
	}
}

/// Used to support import operations. Returns a string: 
/// "None" if there is no file by the name given by pFilename,
/// "Invalid" if the file exists and export syntax is valid but it is not a subclass of pSuperClass,
/// "Ok" if the file exists and seems to contain an exported subclass of pSuperClass,
/// "Open" if we could not open the file, 
/// "Syntax" if the file exists but does not contain valid syntax for an exported subclass of pSuperClass,
/// "Duplicate" if a class with the name supplied in the file already exists.
ClassMethod ValidImportFileExists(pFilename As %String, pSuperClass As %String) As %String
{
	Set tState = "Ok"
	Set tFile = ""
	Try {
		If (##class(%File).Exists(pFilename)) { // see what the file contains

			// open the file and get the encoding
			Set tFile = ##class(%IO.FileStream).%New()
			If '$IsObject(tFile) {
				Set tState = "Open"
				Quit
			}
			Do tFile.Open(pFilename, , , , .tSC) 
			If $$$ISERR(tSC) {
				Set tState = "Open"
				Quit
			}
			Set tFile.CharEncoding = "UTF-8"
			Set tLine = ""
			Set tSC = $$$OK
			Set tLine = tFile.Read(50, 100, .tSC)
			If $$$ISERR(tSC) {
				Set tState = "Read"
				Quit
			}
			If (tLine [ "encoding") { // get the encoding
				Set tLine = $P(tLine, "encoding=""", 2)	
				Set tLine = $P(tLine, """", 1)	
				If ('(tLine = "UTF-8")) {
					Do tFile.Close()
					Kill tFile
					Set tFile = ##class(%IO.FileStream).%New()
					Do tFile.Open(pFilename, , , , .tSC) 
					If $$$ISERR(tSC) {
						Set tState = "Open"
						Quit
					}
					Set tFile.CharEncoding = tLine
					Set tLine = ""
				}
			} // if no encoding was specified assume UTF-8

			// Reset for read
			Do tFile.Rewind()
			Set tLine = ""
			Set tSC = $$$OK
			Set tLine = tFile.Read(750, 100, .tSC)
			If $$$ISERR(tSC) {
				Set tState = "Read"
				Quit
			}

			// Handle files exported as Studio documents, i.e. BPL, DTL and RUL.
			// Note that each branch of this IF is responsible for populating tName with the
			// eventual class name.

			Set tPos = $FIND(tLine,"<Document ")
			If (tPos > 1) {
				Set tNewLine = $E(tLine,tPos,*)
				Set tName = $P(tNewLine,"name=""",2)
				Set tName = $P(tName,"""",1)
				Set tExtension = $zcvt($P(tName,".",$L(tName,".")),"U")
				Set tName = $P(tName,".",1,$L(tName,"."))
				Set tExpectedExtension = $case(pSuperClass,	"Ens.DataTransform": "DTL",
										"Ens.BusinessProcess": "BPL",
										"Ens.Rule.Definition": "RUL",
										: "")
				If (tExpectedExtension = "") || (tExtension '= tExpectedExtension) {
					Set tState = "Invalid"
					Quit
				}
			}
			Else { // Handle standard class exports
				Set tPos = $FIND(tLine,"<Super>")
				If (tPos < 2) {
					Set tState = "Syntax"
					Quit
				}
				Set tSuperList = $P(tLine, "<Super>", 2)
				Set tSuperList = $P(tSuperList, "</Super>", 1)
				For i=1:1:$length(tSuperList,",") {
					Set tSuper = $P(tSuperList,",",i)
					If (('##class(%ZEN.FinderUtils).isSubclassOf(tSuper, pSuperClass)) && ('(tSuper = pSuperClass))) {
						Set tState = "Invalid"
						Quit
					}
				}
				If tState '= "Ok" Quit

				// get the class name
				Set tName = $P(tLine, "<Class name=""", 2)
				Set tName = $P(tName, """>", 1)
			}
			
			// find out if a class of this name already exists
			If ##class(%Dictionary.ClassDefinition).%ExistsId(tName) {
				Set tState = "Duplicate"
				Quit
			}
		}
		Else { // file does not exist
			Set tState = "None"
			Quit
		}
	}
	Catch {
		Set tState = "Syntax"
	}
	If $IsObject(tFile) Do tFile.Close()
	Quit tState
}

/// pSuperclass is either "Ens.BusinessProcess" or "Ens.DataTransform".
/// The purpose of this query is to exclude the base classes
/// Ens.BusinessProcessBPL and Ens.DataTransformDTL from the list.
Query EnumerateEditableSubclasses(pSuperclass As %String) As %Query(ROWSPEC = "Name:%String,Modified:%TimeStamp")
{
}

/// pSuperclass is either "Ens.BusinessProcess" or "Ens.DataTransform".
/// The purpose of this query is to exclude the base classes
/// Ens.BusinessProcessBPL and Ens.DataTransformDTL from the list.
ClassMethod EnumerateEditableSubclassesExecute(ByRef qHandle As %Binary, pSuperclass As %String) As %Status
{
	$$$KillRootNode(^IRIS.Temp.EditableSubclasses)
	Set qHandle=""
	
	If (pSuperclass = "Ens.BusinessProcess") {
		// Get subclasses but exclude Ens.BusinessProcessBPL
		Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		Do tRS.Execute(pSuperclass)
		While (tRS.Next()) {
			Set tName = tRS.Data("Name")
			If (tName '= "Ens.BusinessProcessBPL") {
				Set tClassIndex = $GET(^rINDEXCLASS($zconvert(tName,"U")))
				Set tModified = $LISTGET(tClassIndex,1)
				Set ^IRIS.Temp.EditableSubclasses($I(^IRIS.Temp.EditableSubclasses)) = $LB(tName,tModified)
			}
		}
	}
	ElseIf (pSuperclass = "Ens.DataTransform") {
		// Get subclasses but exclude Ens.DataTransformDTL
		Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		Do tRS.Execute(pSuperclass)
		While (tRS.Next()) {
			Set tName = tRS.Data("Name")
			If (tName '= "Ens.DataTransformDTL") {
				Set tClassIndex = $GET(^rINDEXCLASS($zconvert(tName,"U")))
				Set tModified = $LISTGET(tClassIndex,1)
				Set ^IRIS.Temp.EditableSubclasses($I(^IRIS.Temp.EditableSubclasses)) = $LB(tName,tModified)
			}
		}
	}
	ElseIf (pSuperclass = "Ens.Rule.Definition") {
		// Get subclasses 
		Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		Do tRS.Execute(pSuperclass)
		While (tRS.Next()) {
			Set tName = tRS.Data("Name")
			Set tClassIndex = $GET(^rINDEXCLASS($zconvert(tName,"U")))
			Set tModified = $LISTGET(tClassIndex,1)
			Set ^IRIS.Temp.EditableSubclasses($I(^IRIS.Temp.EditableSubclasses)) = $LB(tName,tModified)
		}
	}
	
	Quit $$$OK
}

ClassMethod EnumerateEditableSubclassesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateMessageClassesExecute ]
{
	Kill Row
	Set tSC = $$$OK
	Try {
		Set qHandle = $O(^IRIS.Temp.EditableSubclasses(qHandle),1,val)
		If qHandle = "" {
			Set Row = ""
			Set AtEnd = 1
		}
		Else {
			Set Row = val
			Set AtEnd = 0
		}
	}
	Catch ex {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

ClassMethod EnumerateEditableSubclassesClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateMessageClassesFetch ]
{
	$$$KillRootNode(^IRIS.Temp.EditableSubclasses)
	Kill qHandle
	Quit $$$OK
}

}
