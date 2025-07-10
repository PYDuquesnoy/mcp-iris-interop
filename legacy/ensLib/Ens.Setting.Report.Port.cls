/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is for InterSystems internal use.
Class Ens.Setting.Report.Port Extends Ens.Setting.Report.base [ System = 4 ]
{

/// Regular expression to find particular setting names for one type of setting
Parameter SettingNamePattern = "\b[A-Za-z]*Port\b";

/// Use the standard ISC.DM package
Parameter DocDBName = "IRISInteroperabilityPorts";

Parameter DocDBResource = "%Ens_PortSettingsReport";

/// Gets the Port specific data for pItem that matches the name pattern.
/// pSettingNameIndex is index of settings in pSettingsList
/// pSpecificSettingData is used to return the port specific report data:
/// port, inbound, interface, ipaddress
ClassMethod onGetSpecificSettingData(pItem As Ens.Config.Item, ByRef pSettingNameIndex, ByRef pSettingsList, Output pSpecificSettingData As %String) As %Status [ Internal ]
{
	#; Access List from PopulateVirtualSettings()
	#define settingValue(%lv)	$ListGet(%lv,3)

	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		Kill pSpecificSettingData

		#dim tPortValue = $$$settingValue(pSettingsList(pSettingNameIndex))

		#; Any erroneous string value will be saved as empty.
		#; 0 is reserved system port and not expected but do not make empty string.
		If (tPortValue '= +tPortValue) Set tPortValue = ""

		#dim tSettingIndex = 0
		#; Used to store a value from the list for a given setting
		#dim tIPAddressValue = ""

		#;inbound Property. Do first since may decide to not report.
		#dim tInbound = (pItem.BusinessType() = $$$eHostTypeService)

		#; Can have either IPAddress Or AllowedIPAddresses but if have both IPAddress is used
		If ($Data(pSettingNameIndex("IPAddress"),tSettingIndex)#2) || ($Data(pSettingNameIndex("AllowedIPAddresses"),tSettingIndex)#2) {

			Set tIPAddressValue = $$$settingValue(pSettingsList(tSettingIndex))
			If ($Extract(tIPAddressValue)="!") {
				Set tInbound = 'tInbound
				#; remove !
				Set $Extract(tIPAddressValue) = ""
			}

		}
		/*	If connecting out and port not defined do not report.
				OR
			If listener and pool size is 0 then do not report.
		*/
		If ('tInbound && (tPortValue=""))||(tInbound && 'pItem.PoolSize) {
			Quit
		}
		#; Port value.
		Set pSpecificSettingData("port") = tPortValue

		#; Outgoing IP Address value(s)
		If 'tInbound Set pSpecificSettingData("ipAddress") = tIPAddressValue

		#; Do more corrections for tInbound since not all BS are listeners
		If tInbound && (pItem.AdapterClassName()'="") && $CLASSMETHOD(pItem.AdapterClassName(),"%Extends","EnsLib.FTP.InboundAdapter") {

			Set tInbound = 0

			#; Check for blank port
			If pSpecificSettingData("port") = "" {

				/*
					Check if SFTP - use logic from EnsLib.FTP.Common::%isSFTPGet()
					("!SFTP"=$ZCVT($ZStrip(..SSLConfig,"<>WC"),"U"))||(..Protocol="SFTP")
				*/
				If (($Data(pSettingNameIndex("SSLConfig"),tSettingIndex)#2) &&
					($ZCVT($ZStrip($$$settingValue(pSettingsList(tSettingIndex)),"<>WC"),"U")="!SFTP")) ||
					(($Data(pSettingNameIndex("Protocol"),tSettingIndex)#2) &&
					($$$settingValue(pSettingsList(tSettingIndex))="SFTP")) {

						Set pSpecificSettingData("port") = 22

				} Else {

					Set pSpecificSettingData("port") = 21

				}

			}

		}

		Set pSpecificSettingData("inbound")= tInbound

		#; Interface Property - IPV4 or IPV6
		Set pSpecificSettingData("interface") = ""
		If $Data(pSettingNameIndex("LocalInterface"),tSettingIndex)#2 {

			#dim tInterface = $$$settingValue(pSettingsList(tSettingIndex))
			If tInterface '= "" {
				#; remove the <spaceInfo> from each interface
				Set pSpecificSettingData("interface") = $ZStrip($P(tInterface,"("),"*W")
			}

		}

		Set pSpecificSettingData("document") = "primary"

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Return tSC
}

ClassMethod onFinishSave(pReporter As Ens.Setting.Reporter = {$$$NULLOREF}) As %Status
{
	#dim tSC = $$$OK

	Set tSC = ..FindConflicts(1)

	Set tSC = $$$ADDSC(tSC,..FindAvailability(1))

	Set tSC = $$$ADDSC(tSC,..FindUsedReservations(1))

	Return tSC
}

/// Find possible port conflicts accounting for interfaces
/// This will search all data
/// If saving Clear the PortConflicts table and repopulate.
ClassMethod FindConflicts(pSaveData As %Boolean = 0, Output pConflicts As %Library.DynamicArray) As %Status
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException


	Try {

		If '$SYSTEM.DocDB.Exists(..#DocDBName) Quit
		#dim tDocDBPortSettings = ##class(%DocDB.Database).%GetDatabase(..#DocDBName)
		#dim tConflictObject As %Library.DynamicObject

		#; Find conflicts on this server only
		#dim tSQL = ""
		Set tSQL = tSQL_	"SELECT p.%Doc As conflict, p.id,p.server, p.port, p.interface, p.inbound"
		Set tSQL = tSQL_" "_	"FROM "_tDocDBPortSettings.SqlNameQualified_" p"
		Set tSQL = tSQL_" "_"INNER JOIN ("
		Set tSQL = tSQL_" "_	"SELECT server, port, inbound, COUNT(*) AS duplicates"
		Set tSQL = tSQL_" "_		"FROM "_tDocDBPortSettings.SqlNameQualified
		Set tSQL = tSQL_" "_			"WHERE inbound = 1 and (port > 0) AND document = 'primary'"
		Set tSQL = tSQL_" "_			"GROUP BY server, port"
		Set tSQL = tSQL_" "_			"HAVING COUNT(*) > 1"
		Set tSQL = tSQL_" "_			") d"
		Set tSQL = tSQL_" "_"ON (p.server = d.server) AND (p.port = d.port) and (p.inbound = d.inbound) and (p.document = 'primary')"
		Set tSQL = tSQL_" "_"ORDER BY server,port"

		#dim tDirectRS = ##class(%DocDB.Database).%ExecuteQuery(tSQL)

		If pSaveData {
			TSTART
			#; remove all entries where document="conflict"
			#dim tToDeleteRS As %SQL.StatementResult = ##class(%DocDB.Database).%ExecuteQuery("SELECT %DocumentId FROM "_tDocDBPortSettings.SqlNameQualified_" WHERE document = 'conflict'")
			While (tToDeleteRS.%Next(.tSC) && $$$ISOK(tSC)) {

				Do tDocDBPortSettings.%DeleteDocument(tToDeleteRS.%DocumentId)

			}

		}

		Set pConflicts = []
		#dim tDefinite, tSeen, tPos,tConflict

		While tDirectRS.%Next(.tSC) && $$$ISOK(tSC) {

			If (tDirectRS.interface = "") {

				Set tDefinite(tDirectRS.server,tDirectRS.port) = ""

			} Else {

				Do $Increment(tSeen(tDirectRS.server,tDirectRS.port,tDirectRS.interface))

			}

			Set tConflict = {}
			Do tConflict.%Set("server",tDirectRS.server)
			Do tConflict.%Set("port",tDirectRS.port)
			Do tConflict.%Set("interface",tDirectRS.interface)
			Do tConflict.%Set("%Doc",tDirectRS.conflict)

			Do pConflicts.%Push(tConflict)

		}

		#; No conflicts. DB has been cleared if saving data. tSC is OK
		If pConflicts.%Size() = 0 Quit

		#; Iterate over pConflicts removing any that are not listed in tDefinite or tSeen has other ids than this one.
		#dim tIterator = pConflicts.%GetIterator()
		#dim tKey
		#dim tRemove
		#dim tNumberSeen

		While tIterator.%GetNext(.tKey,.tConflict) {

			Set tRemove = 0

			If '$Data(tDefinite(tConflict.server,tConflict.port))#2 {

				#; look to see if others using same interface
				If $Data(tSeen(tConflict.server,tConflict.port,tConflict.interface),tNumberSeen)#2 && (tNumberSeen = 1) {

					Set tRemove = 1

				}

			}

			If tRemove {

				Do pConflicts.%Remove(tKey)

			} ElseIf pSaveData {

				#; Need to change document to "conflict" before saving copy.
				Set tConflictObject = {}.%FromJSON(tConflict.%Doc)
				Do tConflictObject.%Set("document","conflict")
				Do tDocDBPortSettings.%SaveDocument(tConflictObject)

			}

		}


	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	If pSaveData {

		If $$$ISOK(tSC) {TCommit} Else {TROLLBACK 1}

	}

	Return tSC
}

/// Find possible available ports by range.
/// ports bound to "", "0.0.0.0" for IPv4 count as unavailable
/// If saving Clear the PortAvailability table and repopulate.
ClassMethod FindAvailability(pSaveData As %Boolean = 0, Output pAvailability As %Library.DynamicArray) As %Status
{
	/*
		For each unique server we know about
			Go through ports from 1
			When find a gap create range
	*/
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	#define MinPort 1024


	Try {

		If '$SYSTEM.DocDB.Exists(..#DocDBName) Quit
		#dim tDocDBPortSettings = ##class(%DocDB.Database).%GetDatabase(..#DocDBName)

		#; Find availability on this server only
		#dim tSQL = ""
		Set tSQL = tSQL_		"SELECT p.port As port, p.id As id ,p.server As server, p.interface As interface, p.mirror As mirror"
		Set tSQL = tSQL_" "_	"FROM "_tDocDBPortSettings.SqlNameQualified_" p "
		Set tSQL = tSQL_" "_	"WHERE p.port > ? AND p.inbound = 1 AND p.document = 'primary'"
		Set tSQL = tSQL_" "_	"ORDER BY p.server, p.port asc "

		#dim tDirectRS = ##class(%DocDB.Database).%ExecuteQuery(tSQL, $$$MinPort)

		If pSaveData {
			TSTART
			#; Need to clear out availability entries
			#dim tToDeleteRS As %SQL.StatementResult = ##class(%DocDB.Database).%ExecuteQuery("SELECT %DocumentId FROM "_tDocDBPortSettings.SqlNameQualified_" WHERE document = 'available'")
			While (tToDeleteRS.%Next(.tSC) && $$$ISOK(tSC)) {

				Do tDocDBPortSettings.%DeleteDocument(tToDeleteRS.%DocumentId)

			}
		}

		Set pAvailability = []

		#dim tStart = 0
		#dim tEnd
		#dim tOneRange = {}

		#dim tLastServer = ""
		#dim tLastMirror = ""
		#dim tLastPort = ""

		While tDirectRS.%Next(.tSC) && $$$ISOK(tSC) {

			#; skip duplicate entries
			If tLastPort = tDirectRS.port  && (tDirectRS.server = tLastServer) Continue

			#; skip if interface not bound to all IPv4 interfaces since could be available
			If (tDirectRS.interface'="") && (tDirectRS.interface'="0.0.0.0") Continue

			Set tLastPort = tDirectRS.port

			If tDirectRS.server '= tLastServer {

				If tLastServer '= "" {

					#; save last range
					Do ..createRange(tStart, /* no End - use maximum */ , tLastServer, tLastMirror, .pAvailability, pSaveData, .tDocDBPortSettings)

				}

				Set tLastServer = tDirectRS.server
				Set tLastMirror = tDirectRS.mirror

				Set tStart = 1

			}

			If $Data(tStart) {

				If tDirectRS.port = tStart {

					Set tStart = tDirectRS.port  + 1

				} Else {

					Set tEnd = tDirectRS.port  - 1

				}

			}

			If $Data(tEnd)#2 {

				Do ..createRange(tStart, tEnd , tLastServer, tLastMirror, .pAvailability, pSaveData, .tDocDBPortSettings)

				Kill tEnd
				Set tStart = tDirectRS.port + 1

			}

		}

		If $$$ISERR(tSC) Quit

		#; save last range
		Do ..createRange(tStart, /* no End - use maximum */ , tLastServer, tLastMirror, .pAvailability, pSaveData, .tDocDBPortSettings)

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	If pSaveData {

		If $$$ISOK(tSC) {TCommit} Else {TROLLBACK 1}

	}

	Return tSC
}

/// Find reservations that are being used accounting for interfaces
/// This will search all data
/// If saving Clear the inUse column for reservations and repopulate.
ClassMethod FindUsedReservations(pSaveData As %Boolean = 0, Output pUsedReservations As %Library.DynamicArray) As %Status
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException


	Try {

		If '$SYSTEM.DocDB.Exists(..#DocDBName) Quit
		#dim tDocDBPortSettings = ##class(%DocDB.Database).%GetDatabase(..#DocDBName)
	
		#; Find inbound reservations that match in use
		#dim tSQL = ""
		Set tSQL = tSQL_	"SELECT r.%Doc, r.id, r.server, r.mirror, r.port, r.interface, r.inbound, r.document"
		Set tSQL = tSQL_" "_	"FROM "_tDocDBPortSettings.SqlNameQualified_" r"
		Set tSQL = tSQL_" "_"INNER JOIN ("
		Set tSQL = tSQL_" "_	"SELECT server, mirror, port, interface, inbound"
		Set tSQL = tSQL_" "_		"FROM "_tDocDBPortSettings.SqlNameQualified
		Set tSQL = tSQL_" "_			"WHERE inbound = 1 and (port > 0) AND document = 'primary'"
		Set tSQL = tSQL_" "_			") p"
		Set tSQL = tSQL_" "_"ON ((r.server = p.server) OR (r.mirror = p.mirror)) AND (r.port = p.port) and (r.inbound = 1) and (r.document = 'reservation')"
		Set tSQL = tSQL_" "_"	AND ((r.interface = p.interface) OR (r.interface IS NULL)  OR (p.interface IS NULL))"
		Set tSQL = tSQL_" "_"ORDER BY server,mirror,port"

		#dim tDirectRS = ##class(%DocDB.Database).%ExecuteQuery(tSQL)

		If pSaveData {

			TSTART
			#; set all in use flags to off
			
			#dim tSQLStatement = ##class(%SQL.Statement).%New()
			#dim tUpdateSQL = "UPDATE ISC_DM.IRISInteroperabilityPorts SET inuse = 0 WHERE document = 'reservation'"
			#dim tSQLStatementResult = ##class(%SQL.Statement).%ExecDirect(tSQLStatement, tUpdateSQL)
			
			#dim tReservationObject = {}
		}

		Set pUsedReservations = []

		While tDirectRS.%Next(.tSC) && $$$ISOK(tSC) {

			Do pUsedReservations.%Push(tDirectRS.%Doc)

			If pSaveData {

				#; Need to change inUse to 1 before saving copy.
				Set tReservationObject = {}.%FromJSON(tDirectRS.%Doc)
				Do tReservationObject.%Set("inUse","1")
				Do tDocDBPortSettings.%SaveDocument(tReservationObject,tDirectRS.id)

			}
		}

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	If pSaveData {

		If $$$ISOK(tSC) {TCommit} Else {TROLLBACK 1}

	}

	Return tSC
}

/// Save range. If EndPort not specified then we take as maximum
ClassMethod createRange(pStartPort As %Integer, pEndPort As %Integer = 65535, pServer As %String, pMirror As %String, ByRef pAvailability As %String, pSave As %Boolean = 0, ByRef pDocDB As %DocDB.Database) [ Internal, Private ]
{
	#; Validity check on data
	If (pStartPort <= pEndPort) {

		#dim tOneRange = {}

		Do tOneRange.%Set("startPort",pStartPort)
		Do tOneRange.%Set("endPort",pEndPort)
		Do tOneRange.%Set("server",pServer)
		Do tOneRange.%Set("mirror",pMirror)
		Do tOneRange.%Set("document","available")

		Do pAvailability.%Push(tOneRange)
		If pSave Do pDocDB.%SaveDocument(tOneRange)

	}
}

XData DocDBDefinitions [ MimeType = application/json ]
{
{
		"definitions": {
			"IRISInteroperabilityPorts": {
				"description": "This Port usage table. Generated data.",
				"type": "object",
				"properties": {
					"document": {
						"type": "string",
						"description": "Document type. Either 'primary' or an auxilliary type: reservation, advice, conflict, availability"
					},
					"port": {
						"type": "integer",
						"description": "Port value"
					},
					"interface": {
						"type": "string",
						"description": "network interface if any the port is bound to"
					},
					"inbound": {
						"type": "boolean",
						"description": "Whether this Port is being used as a listener or a target port if outbound"
					},
					"ipAddress": {
						"type": "string",
						"description": "IPAddress for outgoing connections"
					},
					"itemName": {
						"type": "string",
						"description": "The name of the IRIS Production Item from which the data point was retrieved"
					},
					"categories": {
						"type": "string",
						"description": "The categories of the Item from which the data point was retrieved"
					},
					"enabled": {
						"type": "boolean",
						"description": "Whether the Item was enabled when the data point was retrieved"
					},
					"partner": {
						"type": "string",
						"description": "Specific Business Partner ID if any"
					},
					"production": {
						"type": "string",
						"description": "The name of the IRIS Production from which the data point was retrieved"
					},
					"server": {
						"type": "string",
						"description": "The server name from which the data point was retrieved"
					},
					"mode": {
						"type": "string",
						"description": "The instance mode e.g. LIVE or DEVELOPMENT"
					},
					"instance": {
						"type": "string",
						"description": "The name of the IRIS instance from which the data point was retrieved"
					},
					"mirror": {
						"type": "string",
						"description": "The name of the IRIS MIRROR from which the data point was retrieved"
					},
					"namespace": {
						"type": "string",
						"description": "The name of the IRIS Namespace from which the data point was retrieved"
					},
					"expiryDate": {
						"type": "string",
						"format": "date-time",
						"description": "Expiration date"
					},
					"comment": {
						"type": "string",
						"description": "Comment"
					},
					"startPort": {
						"type": "integer",
						"description": "Port value - ought to be a valid integer in 0-65535"
					},
					"endPort": {
						"type": "integer",
						"description": "If advice concerns a range this is the end Port value - ought to be a valid integer in 0-65535"
					},
					"classification": {
						"type": "string",
						"description": "Free form text on type - used in advice"
					},
					"username": {
						"type": "string",
							"description": "IRIS Username of the reserver"
					},
					"inUse": {
						"type": "boolean",
							"description": "Flag to indicate if the reservation is in use"
					}
				}
			}
		}
	}
}

}
