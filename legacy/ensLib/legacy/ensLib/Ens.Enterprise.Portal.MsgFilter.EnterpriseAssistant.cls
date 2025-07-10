/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEntErrors

Class Ens.Enterprise.Portal.MsgFilter.EnterpriseAssistant Extends EnsPortal.MsgFilter.Assistant [ System = 4 ]
{

/// Name of <class>Filter</class> to use for searches.
Parameter FilterClass = "Ens.Enterprise.Portal.MsgFilter.EnterpriseFilter";

/// List the messages matching the given filter object.
Query Enumerate(Filter As Ens.Enterprise.Portal.MsgFilter.EnterpriseFilter) As %Query(ROWSPEC = "System,ID,TimeCreated,Session,Status,Error,Source,Target") [ SqlProc ]
{
}

ClassMethod EnumerateExecute(ByRef qHandle As %Binary, Filter As Ens.Enterprise.Portal.MsgFilter.EnterpriseFilter) As %Status
{
	Set qHandle = 0
	Set qHandle("Filter") = Filter
	Set tSC = $$$OK

	// Build local list of servers
	If Filter.ClientIDs.Count() = 0 {
		Set tStatement = ##class(%SQL.Statement).%New()
		Set tSC = tStatement.%Prepare("SELECT ID As ClientID FROM Ens_Enterprise.MonitorClient ORDER BY ID")
		If $$$ISERR(tSC) Quit tSC
		Set tRS = tStatement.%Execute()
		Set tCount = 0
		While tRS.%Next() {
			Set tCount = tCount + 1
			Set qHandle(tCount) = tRS.ClientID
			Set qHandle("clientIndex",tRS.ClientID) = tCount
		}
	}
	Else {
		Set tCount = 0
		For i=1:1:Filter.ClientIDs.Count() {
			Set tID = Filter.ClientIDs.GetAt(i)
			If (tID = "") || '##class(Ens.Enterprise.MonitorClient).%ExistsId(tID) Continue
			Set tCount = tCount + 1
			Set qHandle(tCount) = tID
			Set qHandle("clientIndex",tID) = tCount
		}
	}
	Set qHandle = tCount
	Set tTempNode = ##class(EnsPortal.SessionEvents).GetTempNode()
	Set Filter.TempNode = tTempNode
	Do Filter.SaveToVirtualSession(.tVirtualKey)
	Do Filter.SetVirtualSessionTempNode(tTempNode,tVirtualKey)
	
	Set tNullDevice = ##class(%Library.Device).GetNullDevice()
	Set tHaveDisplayValues = 0
	Set tCheckedForDisplay = 0
	New %ref
	Set %ref = ##class(Ens.Enterprise.Portal.MsgFilter.EnterpriseFilter).GetReference(tTempNode,tVirtualKey)
	Set @%ref@("clientCount") = qHandle
	// Send requests to the Servers
	For iCli=1:1:qHandle {
		Set tClientID = qHandle(iCli)
		Set @%ref@("clients",tClientID) = ""
		Set tClientVersion = ##class(Ens.Enterprise.MonitorClient).VersionGetStored(tClientID)
		// Check for display values.
		If (tClientVersion < 2012.2) {
			If 'tCheckedForDisplay {
				Set tHaveDisplayValues = ..checkDisplayValues(Filter)
				Set tCheckedForDisplay = 1
			}
			If tHaveDisplayValues {
				// Only a problem for this client
				Set @%ref@("result",tClientID) = $$$ERROR($$$EnsEntErrDisplayNotSupported,tClientID)
				Continue
			}
		}

		If (tClientVersion < 2011) {
			Set tSC1 = ##class(Ens.Enterprise.Portal.MsgFilter.LegacyFilter).CreateFromNewFilter(Filter,.tFilterObject)
			If $$$ISERR(tSC1) {
				Set tSC = $$$ADDSC(tSC,tSC1)
				Set @%ref@("result",tClientID) = tSC1
				If $increment(@%ref@("resultCount"))
				Continue
			}
		}
		Else {
			// Make sure we don't send the subclass via SOAP
			Set tSC1 = Filter.GetBasicFilter(.tBasicFilter)
			If $$$ISERR(tSC1) {
				Set tSC = $$$ADDSC(tSC,tSC1)
				Set @%ref@("result",tClientID) = tSC1
				If $increment(@%ref@("resultCount"))
				Continue
			}
			Set tFilterObject = tBasicFilter
		}
		Set tFilterObject.TimeFormat = tFilterObject.TimeFormatDisplayToLogical("Complete")
		Set tSC1 = tFilterObject.XMLExportToString(.tFilterString)
		If $$$ISERR(tSC1) {
			Set tSC = $$$ADDSC(tSC,tSC1)
			Set @%ref@("result",tClientID) = tSC1
			If $increment(@%ref@("resultCount"))
			Continue
		}
		Set tJobTimeout = 2
		Set tQueryTimeout = $select(Filter.Timeout = "": 1, Filter.Timeout <= 0: 1, 1: Filter.Timeout)
		Job ..queryClient(tClientID,tFilterString,%session.SessionId,tTempNode,tQueryTimeout,iCli=1,tVirtualKey):(::tNullDevice:tNullDevice):tJobTimeout
		If '$Test {
			Set @%ref@("result",tClientID) = $$$ERROR($$$EnsEntErrQueryJobFailed,tJobTimeout)
			If $increment(@%ref@("resultCount"))
			Continue
		}
	}

	// Poll for completion
	Set t0 = $ZH
	Set tTimedOut = 0
	Set qHandle("numDone") = 0
	While qHandle("numDone") < qHandle {
		For iCli=1:1:qHandle {
			Set tClientID = qHandle(iCli)
			If ('$get(tCliDone(iCli))) && $data(@%ref@("result",tClientID),tClientStatus) {
				Set tCliDone(iCli) = 1
				Set qHandle("numDone") = qHandle("numDone") + 1
			}
			If ($ZH - (Filter.Timeout + 2)) > t0 {
				Set tTimedOut = 1
				Quit
			}
		}
		If tTimedOut Quit
		Hang 0.1
	}
	Set tDirection = $select(Filter.SortOrder = Filter.SortOrderDisplayToLogical("Newest First"): -1, 1: 1)
	Set qHandle("currTime") = $order(@%ref@("rows",""),tDirection)
	Set qHandle("next") = "client"
	Set qHandle("currClient") = ""
	Set qHandle("currID") = ""
	Set qHandle("direction") = tDirection
	Set qHandle("ref") = %ref
	Quit tSC
}

ClassMethod EnumerateFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Set Row = ""
		Set AtEnd = 0
		If qHandle("currTime") = "" {
			Set AtEnd = 1
			Quit
		}
		Set tDone = 0
		New %ref
		Set %ref = qHandle("ref")
		While 'tDone {
			If qHandle("next") = "time" {
				Set qHandle("currTime") = $order(@%ref@("rows",qHandle("currTime")),qHandle("direction"))
				If qHandle("currTime") = "" {
					Set tDone = 1
					Set AtEnd = 1
					Quit
				}
				Else {
					Set qHandle("next") = "client"
				}
			}
			If qHandle("next") = "client" {
				Set qHandle("currClient") = $order(@%ref@("rows",qHandle("currTime"),qHandle("currClient")),qHandle("direction"))
				If qHandle("currClient") = "" {
					Set qHandle("next") = "time"
					Continue
				}
				Else {
					Set qHandle("next") = "ID"
				}
			}
			If qHandle("next") = "ID" {
				Set qHandle("currID") = $order(@%ref@("rows",qHandle("currTime"),qHandle("currClient"),qHandle("currID")),qHandle("direction"))
				If qHandle("currID") = "" {
					Set qHandle("next") = "client"
					Continue
				}
				Else {
					Set tDone = 1
					Set qHandle("next") = "ID"
					Set Row = $LB(qHandle("currClient"),qHandle("currID"),qHandle("currTime"))_$get(@%ref@("rows",qHandle("currTime"),qHandle("currClient"),qHandle("currID")))
				}
			}
		}
	}
	Catch {
		Set tSC = $$$EnsSystemError
	}
	Quit tSC
}

ClassMethod EnumerateGetInfo(colinfo As %List, parminfo As %List, idinfo As %List, qHandle As %Binary, extoption As %Integer = 0, extinfo As %List) As %Status
{
	Quit ..GetClassQueryInfo("Enumerate",.colinfo,.parminfo,.idinfo,.qHandle,.extoption,.extinfo)
}

/// Helper method to check whether the filter supplied in <var>pFilter</var> contains any Display values.
ClassMethod checkDisplayValues(pFilter As EnsPortal.MsgFilter.Filter) As %Boolean
{
	Set tHaveDisplayValues = 0
	For tTermPos = 1:1:pFilter.Terms.Count() {
		Set tTerm = pFilter.Terms.GetAt(tTermPos)
		If $IsObject(tTerm) {
			For tCondPos = 1:1:tTerm.Conditions.Count() {
				Set tCond = tTerm.Conditions.GetAt(tCondPos)
				If $IsObject(tCond) && tCond.DisplayOnly {
					Set tHaveDisplayValues = 1
					Quit
				}
			}
			If tHaveDisplayValues Quit
		}
	}
	Quit tHaveDisplayValues
}

/// Callback to create a Zen proxyObject from a supplied <class>EnterpriseFilter</class>.
ClassMethod CreateProxy(pFilter As Ens.Enterprise.Portal.MsgFilter.EnterpriseFilter, Output pSearchCriteria As %ZEN.proxyObject, pExcludeSequenceManager As %Boolean = 1) As %Status
{
	Set tStatus = ##super(pFilter,.pSearchCriteria,pExcludeSequenceManager)
	If $$$ISERR(tStatus) Quit tStatus
	
	Set tClientList = ""
	Set tClientCount = pFilter.ClientIDs.Count()
	For i=1:1:tClientCount {
		Set tName = pFilter.ClientIDs.GetAt(i)
		If "" '= tName Set tClientList = tClientList _ "," _ tName
	}
	If $extract(tClientList) = "," Set tClientList = $extract(tClientList,2,*)
	Set pSearchCriteria.clientList = tClientList

	If pFilter.TempNode Set pSearchCriteria.TempNode = +pFilter.TempNode

	Quit $$$OK
}

/// Callback to create the <class>Filter</class> class for this Assistant.
/// The paging logic is implemented in this method based on the nextPageStartId
/// and nextPageEndId properties of the supplied proxyObject.
ClassMethod CreateFilter(pSearchCriteria As %ZEN.proxyObject, Output pFilter As Ens.Enterprise.Portal.MsgFilter.EnterpriseFilter, pExcludeSequenceManager As %Boolean = 1, pVirtualKey As %Integer = 0) As %Status
{
	Set tStatus = ##super(pSearchCriteria,.pFilter,pExcludeSequenceManager,pVirtualKey)
	If $$$ISERR(tStatus) Quit tStatus

	Do pFilter.ClientIDs.Clear()
	If pSearchCriteria.clientList '= "" {
		Set tLength = $length(pSearchCriteria.clientList,",")
		For i=1:1:tLength {
			Set tClient = $piece(pSearchCriteria.clientList,",",i)
			If tClient '= "" Do pFilter.ClientIDs.Insert(tClient)
		}
	}
	
	If pSearchCriteria.TempNode && pSearchCriteria.%pageChange && (pSearchCriteria.currPageLastSystem '= "") {
		Set pFilter.TempNode = pSearchCriteria.TempNode
		Set pFilter.CurrSystem = pSearchCriteria.currPageLastSystem
	}
	ElseIf 'pSearchCriteria.%pageChange {
		Set pFilter.TempNode = ""
	}
	
	If (pSearchCriteria.nextPageStartTime '= "") && ((pSearchCriteria.nextPageStartTime >= pFilter.StartTime) || (pFilter.StartTime = "")) {
		Set pFilter.StartTime = pSearchCriteria.nextPageStartTime
	}
	If pSearchCriteria.nextPageEndTime && ((pSearchCriteria.nextPageEndTime <= pFilter.EndTime) || (pFilter.EndTime = "")) {
		Set pFilter.EndTime = pSearchCriteria.nextPageEndTime
	}

	Quit $$$OK
}

ClassMethod queryClient(pClientID As %String, pFilterString As %String, pSessionID As %String, pTempNode As %Integer, pTimeout As %Numeric = 5, pGetColInfo As %Boolean = 0, pVirtualKey As %Integer = 0)
{
	New %ref
	Set tStatus = $$$OK
	Try {
		Set %ref = $name(^IRIS.Temp.EnsPortal.Data(pSessionID,0,"Enterprise",pVirtualKey,pTempNode))
		Set tClient = ##class(Ens.Enterprise.MonitorClient).%OpenId(pClientID,,.tStatus)
		If $$$ISERR(tStatus) || '$IsObject(tClient) Quit
	
		//Set tNextId=$G(pNextIds(tClient.Name))
		Set tMonitor = ##class(%CSP.Monitor.Client).%New()
		Set tMonitor.Timeout = pTimeout
		Set tMonitor.OpenTimeout = pTimeout
		Set tFullLocation = tClient.GetURLPath(1) _ "_CSP.Monitor.Server.cls"
		Set tMonitor.Location  = tFullLocation
		Set tFilterStream = ##class(%Stream.TmpCharacter).%New()
		Do tFilterStream.Write(pFilterString)
		Do tFilterStream.Rewind()
		
		Set tCreds = ""
		If tClient.SOAPCredentials '= "" {
			Set tStatus = ##Class(Ens.Config.Credentials).GetCredentialsObj(.tCreds,$$$CurrentClass,"Ens.Config.Credentials",tClient.SOAPCredentials)
			If $$$ISERR(tStatus) Quit
			If '$IsObject(tCreds) {
				Set tStatus = $$$ERROR($$$EnsErrNoCredentials,tClient.SOAPCredentials)
				Quit
			}
		}
		If $IsObject(tCreds) && (tCreds.Username '= "") && (tMonitor.SessionCookie = "") {
			Do tMonitor.WSSecurityLogin(tCreds.Username,tCreds.Password)
		}
		Set tMonitor.SSLConfiguration = tClient.SSLConfig
		Set tMonitor.SSLCheckServerIdentity=tClient.SSLCheckServerIdentity
		Set tHasTargetColumn = 0
		Set tMetadata = ""
		Try {
			Set tRS = tMonitor.MessageSearch(tFilterStream,pTimeout,,"Search")
			Set tHasTargetColumn = ("Target" = tRS.GetColumnName(7))
			Set tColCount = 0
			If pGetColInfo {
				Set tColCount = tRS.GetColumnCount()
				Set tExtraCols = ""
				For i=(7+tHasTargetColumn):1:tColCount {
					Set tExtraCols = tExtraCols _ $lb(tRS.GetColumnName(i))
				}
				If tExtraCols '= "" Set @%ref@("extraCols") = tExtraCols
			}
			While tRS.Next() {
				If 'tColCount Set tColCount = tRS.GetColumnCount()
				Set tTimestamp = tRS.GetData(2)
				#; Check for alternate end marker(s)
				If (tTimestamp = "<to>") {
					Set tStatus = $$$ERROR($$$CSPTimeout)
					Quit
				}
				ElseIf $extract(tTimestamp)?1N {
					Set tData = ""
					Set tOffset = 0
					For i=3:1:tColCount {
						If (i=7)&&('tHasTargetColumn) {
							Set tData = tData _ $listbuild("")
							Set tOffset = 1
						}
						Else {
							Set tData = tData _ $listbuild(tRS.GetData(i-tOffset))
						}
					}
					
					Set @%ref@("rows",tTimestamp,pClientID,tRS.GetData(1)) = tData
				}
			}
			If $$$ISERR(tStatus) Quit
			
		} Catch ex {
			Set tSOAPStatus = $$$OK
			If (ex.Name [ "ZSOAP") && ($get(%objlasterror) '= "") {
				Set tSOAPStatus = %objlasterror
			}
			If $system.Status.Equals(tSOAPStatus,$$$CSPTimeout) {
				Set tStatus = tSOAPStatus
			}
			Else {
				Set tStatus = $$$SystemError
				Set tStatus = $$$ADDSC(tSOAPStatus,tStatus)
			}
		}
	}
	Catch {
		Set tStatus = $$$SystemError
	}
	If tHasTargetColumn { Set @%ref@("hasTarget",pClientID) = tHasTargetColumn }
	Set @%ref@("result",pClientID) = tStatus
	Set @%ref@("colInfo",pClientID) = tMetadata
	If $increment(@%ref@("resultCount"))
}

/// Helper method to return a valid ResultSet for the supplied <class>Filter</class> object.
/// The result set construction itself is wrapped by the <query>Enumerate</query> query.
/// The main goal is to branch the Sequence Manager the logic in this method, but
/// subclasses can implement any logic they see fit to create a result set object.
ClassMethod GetResultSet(pFilter As Ens.Enterprise.Portal.MsgFilter.EnterpriseFilter, Output pResultSet As %ResultSet, pExecute As %Boolean = 1) As %Status
{
	If pFilter.TempNode {
		Set pResultSet = ##class(%ResultSet).%New($classname($this)_":EnumerateTempResults")
		If pExecute {
			Quit pResultSet.Execute(pFilter)
		}
		Quit $$$OK
	}
	Else {
		Quit ##super(pFilter,.pResultSet,pExecute)
	}
}

Query EnumerateTempResults(Filter As Ens.Enterprise.Portal.MsgFilter.EnterpriseFilter) As %Query(ROWSPEC = "System,ID,TimeCreated,Session,Status,Error,Source,Target") [ SqlProc ]
{
}

ClassMethod EnumerateTempResultsExecute(ByRef qHandle As %Binary, Filter As Ens.Enterprise.Portal.MsgFilter.EnterpriseFilter) As %Status
{
	Set qHandle("ref") = ""
	If Filter.TempNode {
		New %ref
		Set %ref = ##class(Ens.Enterprise.Portal.MsgFilter.EnterpriseFilter).GetReference(Filter.TempNode,Filter.searchIdentifier)
		If $data(@%ref@("rows")) {
			Set qHandle("ref") = %ref
			Set tDirection = $select(Filter.SortOrder = Filter.SortOrderDisplayToLogical("Newest First"): -1, 1: 1)
			Set qHandle("direction") = tDirection
			Set qHandle("currTime") = $select(tDirection = -1: Filter.EndTime, 1: Filter.StartTime)
			Set qHandle("currClient") = Filter.CurrSystem
			// Shift ID by one to include the first (or last) value
			Set qHandle("currID") = $select(tDirection = -1: Filter.EndId, 1: Filter.StartId) + (tDirection * -1)
			Set qHandle("next") = "ID"
		}
	}
	Quit $$$OK
}

ClassMethod EnumerateTempResultsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	If qHandle("ref") = "" {
		Set Row = ""
		Set AtEnd = 1
		Quit $$$OK
	}
	Quit ..EnumerateFetch(.qHandle,.Row,.AtEnd)
}

ClassMethod EnumerateTempResultsGetInfo(colinfo As %List, parminfo As %List, idinfo As %List, qHandle As %Binary, extoption As %Integer = 0, extinfo As %List) As %Status
{
	Quit ..GetClassQueryInfo("EnumerateTempResults",.colinfo,.parminfo,.idinfo,.qHandle,.extoption,.extinfo)
}

ClassMethod GetClassQueryInfo(pQueryName As %String = "Enumerate", colinfo As %List, parminfo As %List, idinfo As %List, qHandle As %Binary, extoption As %Integer = 0, extinfo As %List) As %Status [ Private ]
{
	New %ref
	Set clientinfo = $$$comMemberKeyGet($classname($this),$$$cCLASSquery,pQueryName,$$$cQUERYclientinfo)
	If clientinfo '= "" {
		
		Set colinfo = $listget(clientinfo,1)
		Set parminfo = $listget(clientinfo,2)
		Set idinfo = $listget(clientinfo,3)
		Set extent = $listget(clientinfo,4)
		
		Set %ref = $get(qHandle("ref"))
		If %ref '= "" {
			Set tExtraColNames = $get(@%ref@("extraCols"))
			If (tExtraColNames '= "") && $listvalid(tExtraColNames) {
				For i=1:1:$listlength(tExtraColNames) {
					Set tColName = $listget(tExtraColNames,i)
					Set colinfo = colinfo _ $lb($lb(tColName,10,tColName))
				}
			}
		}
		If $get(extinfo) {
			Set extinfo = $$$comMemberKeyGet($classname($this),$$$cCLASSquery,pQueryName,$$$cQUERYextendedinfo)
		}
		Quit $$$OK
	}
	Quit $$GetInfo^%SYS.DynamicQuery($classname($this),pQueryName,.colinfo,.parminfo,.idinfo,.qHandle,extoption,.extinfo)
}

}
