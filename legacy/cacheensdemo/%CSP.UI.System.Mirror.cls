/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

/// Methods used by mirror pages.
Class %CSP.UI.System.Mirror [ Abstract, System = 4 ]
{

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

/// Activate and/or catchup Mirror DBs.
ClassMethod MirrorActivateCatchupDB(ByRef pParms, ByRef pItems) As %Status
{
	Set tSC = $$$OK
	#; If any error occurs, we set the RESULT equal to %Status.
	Set RESULT = 1
	#; If Activate included, activate db first
	If pParms("Action") [ "A" {
		Set Dir = ""
		Set tRow = $O(pItems(""))
		If tRow '= "" Set Dir = pItems(tRow)
		If Dir '= "" Set Details = ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details") _ " "_$$$Text("Activate: ")
		While Dir '= "" { 
			Set obj = ##Class(SYS.Database).%OpenId(Dir,,.tSC)
			If $$$ISOK(tSC) {
				Set actStatus = obj.InActiveMirror
				Set nowStatus = obj.MirrorActivationRequired
				#;SML2678
				Set mirdbname = obj.MirrorDBName
				Kill obj
				#; only activate if DB requires activation
				If (actStatus = 0) && (nowStatus = 1) {
					#; This method returns 1 = success; 0,RESULTmsg = fail
					Set tSC = $SYSTEM.Mirror.DBActivate(Dir)
					#; if error, log error message and remove the dir from the array so Catchup won't process it.
					If tSC '= 1 {
						#; if error, log error message to Background Task so user can view individual errors.
						Set err = $P(tSC,",",2)
						Do ..LogMsg(err)
						Set RESULT = $$$ERROR($$$GeneralError,err)
						Set pItems(Dir) = ""
					} Else {
						#;SML1504 ; make this mirrored DB if this is a ReadWrite Reporting async member.
						d:##class(Config.MirrorMember).IsReadWriteReportingMember() $SYSTEM.Mirror.ClearFailoverDBFlag(Dir)
						#; SML2678 ; Audit the mirrored DB is removed.
						d ##Class(%SYS.Audit).WriteToAuditFile($$$SourceSystem,$$$TypeSystem,$$$NameConfigChange,Dir,"Activate mirrored database "_mirdbname)
						Set Details = Details _ " "_Dir
						Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details") = Details
					}
				}
			}
			Set tRow = $O(pItems(tRow))
			If tRow '= "" Set Dir = pItems(tRow)
			Else  Set Dir = ""
		}
	}
	Set Details = ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details")
	If pParms("Action") [ "C" {
		Set Dir = ""
		Set tRow = $O(pItems(""))
		If tRow '= "" Set Dir = pItems(tRow)
		If Dir '= "" Set Details = Details _ " "_$$$Text("Catchup: ")
		Set (DirList,DirString) = "" 
		Set DirList = ""
		Set index = 1
		While Dir '= "" {
			Set obj = ##Class(SYS.Database).%OpenId(Dir,,.tSC)
			If $$$ISOK(tSC) {
				Set actStatus = obj.InActiveMirror
				Set nowStatus = obj.MirrorActivationRequired
				Kill obj
				#; only add DB to the list if it is not caught up
				If (actStatus = 0) && (nowStatus = 0) {
					#; temp node for catchup running on directory
					#;SML1802 Set ^|"%SYS"|IRIS.Temp.MgtPortalMirrorTask("Catchup",Dir) = 1
					Set $list(DirList,index) = +$ZU(49,Dir)
					Set DirString = DirString _ $S(DirString'="":", ",1:"")_Dir
					Set index = index + 1
				}
			}
			Set tRow = $O(pItems(tRow))
			If tRow '= "" Set Dir = pItems(tRow)
			Else  Set Dir = ""
		}
		#; only run catchup if there are DBs in the list
		If index '= 1 {
			Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details") = Details _ DirString
			#;SML1802 Set ^|"%SYS"|IRIS.Temp.MgtPortalMirrorTask("Catchup") = $J_"^"_$H
			Set tSC = ##class(SYS.Mirror).CatchupDB(DirList)
			#; if error, log error message to Background Task so user can view individual errors.
			If tSC '= 1 {
				Set err = $P(tSC,",",2)
				Do ..LogMsg(err)
				Set RESULT = $$$ERROR($$$GeneralError,err)
			}
		}
		#;SML1802 Kill ^|"%SYS"|IRIS.Temp.MgtPortalMirrorTask("Catchup")
	}
	Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") = $S(RESULT=1:$$$Text("Done"),1:$$$Text("ERROR"))
	Quit RESULT
}

/// Download Mirror DBs.
ClassMethod MirrorDownloadDB(ByRef pParms, ByRef pItems) As %Status
{
	Set tSC = $$$OK
	#; If any error occurs, we set the RESULT equal to %Status.
	Set RESULT = 1
	Set Dir = ""
	Set tRow = $O(pItems(""))
	If tRow '= "" Set Dir = pItems(tRow)
	If Dir '= "" {
		Set Details = ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details") _ " "_$$$Text("Download: ")
		Set obj = ##Class(SYS.Database).%OpenId(Dir,,.tSC)
		If $$$ISOK(tSC) {
			Set Downloading = obj.MirrorDBDownload
			Set mirdbname = obj.MirrorDBName
			Set mirname = obj.MirrorSetName
			Kill obj
			s NeedDownload=$s(Downloading:##class(SYS.Mirror).NeedDownload(mirname,mirdbname),1:0)
			If NeedDownload && Downloading && (mirdbname=$G(pParms("MirrorDBName"))) && (mirname=$G(pParms("MirrorSetName"))) {
				#; RUnning in foreground
				Set tSC = ##class(SYS.Mirror).DownloadMirrorDatabase(mirname,mirdbname,0)
				#; if error, log error message and remove the dir from the array so Catchup won't process it.
				If '$$$ISOK(tSC) {
					#; if error, log error message to Background Task so user can view individual errors.
					Set err = $SYSTEM.Status.GetErrorText(tSC)
					Do ..LogMsg(err)
					Set RESULT = tSC
				} Else {
					#;make this mirrored DB if this is a ReadWrite Reporting async member.
					d:##class(Config.MirrorMember).IsReadWriteReportingMember() $SYSTEM.Mirror.ClearFailoverDBFlag(Dir)
					#; Audit the mirrored DB is added
					d ##Class(%SYS.Audit).WriteToAuditFile($$$SourceSystem,$$$TypeSystem,$$$NameConfigChange,Dir,"Download mirrored database "_mirdbname)
					Set Details = Details _ " "_Dir
					Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details") = Details
				}
			}
		}
	}
	Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") = $S(RESULT=1:$$$Text("Done"),1:$$$Text("ERROR"))
	Quit RESULT
}

/// Mount mirrored databases
ClassMethod MirrorMountDB(ByRef pParms, ByRef pItems) As %Status
{
	Set tSC = $$$OK
	#; If any error occurs, we set the RESULT equal to %Status.
	Set RESULT = 1
	
	Set tRow = $O(pItems(""))
	While tRow '= "" { 
		Set Dir = pItems(tRow)
		Set Details = ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details")_" "
		
		Set tSC = ##class(SYS.Database).MountDatabase(Dir,$G(pParms("ReadOnly"),0),,$G(pParms("Catchup"),1))
		#; if error, log error message and remove the dir from the array so Catchup won't process it.
		If $$$ISERR(tSC) {
			#; if error, log error message to Background Task so user can view individual errors.
			Do ..LogMsg($System.Status.GetErrorText(tSC))
			Set RESULT = tSC
			Set pItems(tRow) = ""
		} Else {
			Set Details = Details _ " "_Dir
			Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details") = Details
		}
		Set tRow = $O(pItems(tRow))
	}
	Set Details = ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details")
	Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") = $S(RESULT=1:$$$Text("Done"),1:$$$Text("ERROR"))
	Quit RESULT
}

/// Remove databases from the mirror
ClassMethod MirrorRemoveDB(ByRef pParms, ByRef pItems) As %Status
{
	Set tSC = $$$OK
	#; If any error occurs, we set the RESULT equal to %Status.
	Set RESULT = 1
	
	Set tRow = $O(pItems(""))
	While tRow '= "" { 
		Set Dir = pItems(tRow)
		Set Details = ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details")_" "
		
		Set tSC = ##class(SYS.Mirror).RemoveMirroredDatabase(Dir)
		#; if error, log error message and remove the dir from the array so Catchup won't process it.
		If $$$ISERR(tSC) {
			#; if error, log error message to Background Task so user can view individual errors.
			Do ..LogMsg($System.Status.GetErrorText(tSC))
			Set RESULT = tSC
			Set pItems(tRow) = ""
		} Else {
			Set Details = Details _ " "_Dir
			Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details") = Details
		}
		Set tRow = $O(pItems(tRow))
	}
	Set Details = ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details")
	Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") = $S(RESULT=1:$$$Text("Done"),1:$$$Text("ERROR"))
	Quit RESULT
}

/// Add databases to the mirror
ClassMethod MirrorAddDatabases(ByRef pParms, ByRef pItems) As %Status
{
	Set tSC = $$$OK
	#; If any error occurs, we set the RESULT equal to %Status.
	Set RESULT = 1
	
	Set DBName = $O(pItems(""))
	While DBName '= "" { 
		Set Dir = pItems(DBName)
		Set Details = ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details")_" "
		
		Set tSC = ##class(SYS.MirrorConfiguration).AddDatabaseToMirrorSet(Dir,DBName)
		#; if error, log error message and remove the dir from the array so Catchup won't process it.
		If $$$ISERR(tSC) {
			#; if error, log error message to Background Task so user can view individual errors.
			Do ..LogMsg($System.Status.GetErrorText(tSC))
			Set RESULT = tSC
			Set pItems(DBName) = ""
		} Else {
			Set Details = Details _ " "_Dir
			Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details") = Details
		}
		Set DBName = $O(pItems(DBName))
	}
	Set Details = ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details")
	Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") = $S(RESULT=1:$$$Text("Done"),1:$$$Text("ERROR"))
	Quit RESULT
}

/// Log msg into ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"ErrorCount") and ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details")
ClassMethod LogMsg(Msg As %String, ERROR As %String = "")
{
	Set ErrorCount = $O(^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"ErrorLog",""),-1) + 1
	Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"ErrorLog") = ErrorCount
	Set $li(ErrMsg,1) = $S(ERROR="":$$$TextHTML("Msg"),1:ERROR)
	Set $li(ErrMsg,2) = "0"
	Set $li(ErrMsg,3) = Msg
	Set $li(ErrMsg,4) = ErrorCount
	Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"ErrorLog",ErrorCount) = ErrMsg
	//If ERROR '= "" Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") = ERROR
}

/// Return DB array for Mirrorred DBs. Sort it so that the ones that need work are on top.<br>
/// In this order: Dismounted; those that need Activate and/or Catchup.
ClassMethod GetDBs(ByRef DBArray, SelectedMirror) As %Integer
{
	Set tTotal = 0
	Set DBArray = ""
	If SelectedMirror = "" Set SelectedMirror = "*"
	Set tRS = ##class(%ResultSet).%New("SYS.Mirror:MirroredDatabaseDisplay")
	Do tRS.Execute("*",SelectedMirror)
	While tRS.Next() {
		Set name = tRS.Data("Name")
		Set dir = tRS.Data("Directory")
		Set status = tRS.Data("MirrorStatus")
		#;SML1478,SML1824
		Set Latency = tRS.Data("LastDejournalRecord")
		Set obj = ##Class(SYS.Database).%OpenId(dir,,.rc)
		If $$$ISOK(rc) {
			Set actStatus = obj.InActiveMirror
			#;SML1292 ; Use MirrorActivationRequired to indicate the DB needs to be activated or not.
			#;  it if is true then it needs to be activated. This is to replace the MirrorNoWrite flag.
			Set nowStatus = obj.MirrorActivationRequired
			Set MountStatus = obj.Mounted
			#;SML1478
			Set DBArray(actStatus,MountStatus,name) = nowStatus _ "^" _ status _ "^"_ dir_"^"_Latency
			Set tTotal = tTotal + 1
		}
	}
	Quit tTotal
}

/// Return Mirrorred DBs. Sort it so that the ones that need work are on top.<br>
/// In this order: Dismounted; those that need Activate and/or Catchup.<br>
/// MirrorSetName can be passed in for async members.<br>
/// Action is (M)ount, (A)ctivate, (C)atchup, or (R)emove.<br>
/// Specifying one of these will only return DBs on which that action can currently be performed.
Query MirroredDatabaseList(MirrorSetName As %String = "*", Name As %String = "*", Action As %String = "") As %Query(ROWSPEC = "Name:%String,Directory:%String,MirrorStatus:%String,LastDejournalRecord:%String,Mounted:%Boolean,InActiveMirror:%Boolean,ActivationRequired:%Boolean,CatchupRunning:%Boolean,NeedCatchup:%Boolean,Downloading:%Boolean,NeedDownload:%Boolean") [ Internal ]
{
}

ClassMethod MirroredDatabaseListExecute(ByRef qHandle As %Binary, MirrorSetName As %String = "*", Name As %String = "*", Action As %String = "") As %Status [ Internal ]
{
	Set Index = $i($$$ISCQUERYTEMP)
	Set tmpIndex = 0
	Set tRS = ##class(%ResultSet).%New("SYS.Mirror:MirroredDatabaseDisplay")
	Do tRS.Execute(Name,MirrorSetName)
	While tRS.Next() {
		Set dbName = tRS.Data("Name")
		Set Dir = tRS.Data("Directory")
		Set MirrorStatus = tRS.Data("MirrorStatus")
		#;SML1802+ ; Use the status from query in SYS.Mirror
		Set MirrorStatusInt = tRS.Data("MirrorStatusInt")
		#;SML1824
		Set DejrnRecord = tRS.Data("LastDejournalRecord")
		#;SML1802-
		Set obj = ##Class(SYS.Database).%OpenId(Dir,,.rc)
		If $$$ISOK(rc) {
			Set Mounted = obj.Mounted
			Set ActivationRequired = obj.MirrorActivationRequired
			Set InActiveMirror = obj.InActiveMirror
			#;SML1802
			Set CatchupRunning = (MirrorStatusInt=3) ;($G(^|"%SYS"|IRIS.Temp.MgtPortalMirrorTask("Catchup",Dir))=1)
			#;SML2522
			#;SML2823+ ; No Catchup if DBNoWrite is set.
			Set NeedCatchup=0
			if MirrorStatusInt=2 {
				if obj.MirrorNoWrite {
					s MirrorStatus=$$$Text("DBNoWrite")
				} else {
					Set NeedCatchup=1
				}
			}
			#;SML3207+
			s Downloading=(MirrorStatusInt=8)
			s NeedDownload=(MirrorStatusInt=9)
			#;SML3207-
			#;SML2823-
			If (Action = "") || 
				((Action = "M") && ('Mounted)) ||
				((Action = "A") && (Mounted && ActivationRequired)) ||
				((Action = "D") && (Mounted && NeedDownload)) ||
				((Action = "C") && (Mounted && 'InActiveMirror && 'CatchupRunning && NeedCatchup )) ||
				((Action = "R") && (Mounted && 'CatchupRunning)) {
				#;SML1824 ; Replace Latency with DejrnRecord.
				Set tmpArray($i(tmpIndex)) = $LB(dbName,Dir,MirrorStatus,DejrnRecord,Mounted,InActiveMirror,ActivationRequired,CatchupRunning,NeedCatchup,Downloading,NeedDownload)
			}
		}
	}
	Do tRS.Close()
	
	If tmpIndex {
		For i=1:1:tmpIndex {
			If ($LIST(tmpArray(i),5) = 0) {
				// mount required
				Set $$$ISCQUERYTEMP(Index,$I(Index1)) = tmpArray(i)
				Set done(i) = 1
			} 
		}
		For i=1:1:tmpIndex {
			If ($G(done(i)) = 1) continue
			If ($LIST(tmpArray(i),7) = 1) {
				// activation required
				Set $$$ISCQUERYTEMP(Index,$I(Index1)) = tmpArray(i)
				Set done(i) = 1
			}
		}
		For i=1:1:tmpIndex {
			If ($G(done(i)) = 1) continue
			#;SML2522
			If ($LIST(tmpArray(i),9) = 1) {
				// catchup required
				Set $$$ISCQUERYTEMP(Index,$I(Index1)) = tmpArray(i)
				Set done(i) = 1
			} 
		}
		#;SML3207+
		For i=1:1:tmpIndex {
			If ($G(done(i)) = 1) continue
			If ($LIST(tmpArray(i),11) = 1) {
				// download required
				Set $$$ISCQUERYTEMP(Index,$I(Index1)) = tmpArray(i)
				Set done(i) = 1
			} 
		}
		#;SML3207-
		For i=1:1:tmpIndex {
			If ($G(done(i)) = 1) continue
			Set $$$ISCQUERYTEMP(Index,$I(Index1)) = tmpArray(i)
		}
	}
	
	Set qHandle=Index_"^"
	Quit $$$OK
}

ClassMethod MirroredDatabaseListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = MirroredDatabaseListExecute ]
{
	$$$DEFAULTFETCHPPG
	Quit $$$OK
}

ClassMethod MirroredDatabaseListClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = MirroredDatabaseListExecute ]
{
	Set Index=$p(qHandle,"^",1)
	Kill $$$ISCQUERYTEMP(Index)
	Quit $$$OK
}

/// Wrapper for ##class(SYS.Mirror).MemberStatusList() to be used on failover members.<br>
/// It adds columns for Async Type and X.509 DN.
Query MemberStatusList(MirrorName As %String = "") As %Query(ROWSPEC = "MemberName:%String,CurrentRole:%String,CurrentStatus:%String,AsyncType:%String,JournalTimeLatency:%String,DatabaseTimeLatency:%String,X509DN:%String") [ Internal ]
{
}

ClassMethod MemberStatusListExecute(ByRef qHandle As %Binary, MirrorName As %String = "") As %Status [ Internal ]
{
	Set Index = $i($$$ISCQUERYTEMP)
	Set NAText = $$$Text("N/A")
	Set tRS = ##class(%ResultSet).%New("SYS.Mirror:MemberStatusList")
	Do tRS.Execute(MirrorName)
	While tRS.Next() {
		Set MemberName = tRS.Data("MemberName")
		#;JO2632+
		Set role = tRS.Data("CurrentRole")
		Set status = tRS.Data("CurrentStatus")
		Set CurrentRole = tRS.Data("DisplayType")
		Set CurrentStatus = tRS.Data("DisplayStatus")
		#;JO2632-
		Set JournalLatency = tRS.Data("JournalTimeLatency")
		Set DatabaseLatency = tRS.Data("DatabaseTimeLatency")
		#;SML3000+ ; Use Config.MapMirrors to get the X509DN and Async type of the members.
		Kill Properties
		if MirrorName="" s MirrorName=##class(Config.Mirrors).GetMirrorName()
		Set Status=##Class(Config.MapMirrors).Get(MirrorName,MemberName,.Properties)
		If '$$$ISOK(Status) {
			Set (AsyncType,X509DN) = NAText
		} Elseif Properties("MemberType")=2 {
			Set AType=$case(Properties("AsyncMemberType"),0:"Disaster Recovery",1:"Read-Only Reporting",2:"Read-Write Reporting",:"Unknown")
			Set CurrentRole = ##class(SYS.Mirror).LocalizeMemberType(AType)
			Set X509DN = Properties("SSLComputerName")
		} Else {
			Set X509DN = Properties("SSLComputerName")
		}
		#;SML3000-
		
		Set $$$ISCQUERYTEMP(Index,$I(Index1)) = $lb(MemberName,CurrentRole,CurrentStatus,AsyncType,JournalLatency,DatabaseLatency,X509DN)
	}
	
	Set qHandle=Index_"^"
	Quit $$$OK
}

ClassMethod MemberStatusListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = MemberStatusListExecute ]
{
	$$$DEFAULTFETCHPPG
	Quit $$$OK
}

ClassMethod MemberStatusListClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = MemberStatusListExecute ]
{
	Set Index=$p(qHandle,"^",1)
	Kill $$$ISCQUERYTEMP(Index)
	Quit $$$OK
}

/// Return localized text representing the current mirror member status.
ClassMethod MemberStatus() As %String
{
	Quit:'##class(%SYSTEM.Mirror).IsMember() $$$TextHTML("This system is not a mirror member")
	Set type=$system.Mirror.GetMemberType()
	Set stat=$system.Mirror.GetMemberStatus()
	If $listget(stat,2)="" { 
		Set extra=""
	} Else { 
		Set extra="("_$listget(stat,2)_")"
	}
	Set stat=$listget(stat,1)
	Quit $$$FormatTextHTML("Member Type = %1; Status = %2 %3",type,stat,extra)
}

}
