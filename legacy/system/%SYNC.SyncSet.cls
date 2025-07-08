/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syNLS

/// <p><b>For information on this class</b>, see
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=CLASSES+%25SYNC.SyncSet">Using Object Synchronization</a>.</p>
/// ObjectScript provides a toolkit for synchronizing objects of selected types between namespaces
/// containing compatible type classes. The core of the synchronization toolkit is the SyncSet. A
/// SyncSet contains all the objects of selected types that have been filed in the local database
/// from a defined starting time up to an ending time. "Time" in the context of synchronization means
/// a sequencing value and is not an "hours-minutes-seconds" value.
/// Object Synchronization consists of three primary tasks. The first task is to build the SyncSet.
/// That task involves determining which objects are to included in the SyncSet. %SYNC uses a transaction
/// journal for that purpose. The transaction journal is implemented as %Library.ObjectJournalTransaction.
/// Any persistent or serial class that declares the class parameter OBJJOURNAL as true will record all
/// filing events in %Library.ObjectJournalTransaction.
/// The second task is to add changed objects to the SyncSet. The most common mechanism for performing this
/// task is to retrieve the object state from the system journal using information recorded in %Library.ObjectJournalTransaction.
/// This mechanism allows historical object data to be included in the SyncSet. If the system journal is
/// not available, there is a provision to include the current object state.
/// The third task is to import the SyncSet into the namespace being synchronized. This involves loading the
/// SyncSet global into the target namespace and then importing each object contained in the SyncSet. If an object
/// being imported already exists in the target namespace then the timestamp for the imported object
/// is compared to the timestamp of the existing object. If a conflict is detected then user implemented code
/// is called to resolve the conflict. This is essentially an optimistic concurrency mechanism. If the conflict
/// is not resolved successfully then a concurrency error is reported and the object is not synchronized. 
Class %SYNC.SyncSet Extends %RegisteredObject [ System = 3 ]
{

Property LastTransaction As %Integer [ Private ];

Property FirstTransaction As %Integer [ Private ];

Method GetLastTransaction() As %Integer
{
	
	Quit ..LastTransaction
}

Method GetFirstTransaction() As %Integer
{
	
	Quit ..FirstTransaction
}

Property Exclude As %String [ Private ];

/// Unresolved is set to point to the first unresolved object in the sync set once
/// Import() has completed. If there are no unresolved objects then this value will be
/// empty (not > 0).
Property Unresolved As %Integer;

/// <b>Sync Set ID</b><br>
/// <p>
/// This is a string value used to identify the Sync Set object. This value is used as the suffix
/// to the global name root of <var>^OBJ.SYNC.</var>. For example, if the <property>sId</property> is
/// set to the integer 1 then the global name will be <var>^OBJ.SYNC.1</var>.
/// </p>
Property sId As %String;

Property FilterObject As %RegisteredObject;

Property ResolveConflictEnv As %RegisteredObject;

/// This is the sysID of the system that produced the SyncSet
Property SyncSystem As %String;

/// Return the pointer to the first unresolved object in the sync set.
/// This is only valid if Import() has been run to completion before calling
/// this method.
Method UnresolvedFirst() As %SYNC.SyncSetObject
{
	Set i%Unresolved = "" 
	Quit ..UnresolvedNext()
}

/// Return the pointer to the last unresolved object in the sync set.
/// This is only valid if Import() has been run to completion before calling
/// this method.
Method GetLatestUnresolved() As %ArrayOfObjects
{
	s tmp=i%Unresolved
	Set i%Unresolved = "" 
	s coll=##class(%ArrayOfObjects).%New()

	f i=1:1   {
		s oref=..UnresolvedNext()
		q:oref=""
		s guid=oref.GUID
		if $d(aa(guid)) {
			d coll.SetAt(oref,aa(guid))
			s aa(guid)=aa(guid)
		}
		else {
			d coll.SetAt(oref,i)
			s aa(guid)=i
		}		
	}
	s i%Unresolved=tmp
	QUIT coll
}

/// Return the pointer to the next unresolved object.
/// This is only valid if Import() has been run to completion before calling
/// this method and ..UnresolvedFirst() has been called to initialize the unresolved object
/// iterator.
Method UnresolvedNext() As %SYNC.SyncSetObject
{
	Set %objsync = ..GlobalName()
	If i%Unresolved = "" { Set i%Unresolved = $Get(@%objsync@(0,"unresolved")) }
	Else { Set i%Unresolved = i%Unresolved + 1 }
	If i%Unresolved > $g(@%objsync) { Set i%Unresolved = "" }
	If i%Unresolved Quit ##class(%SYNC.SyncSetObject).%New($Lb(i%sId,i%Unresolved))
	Quit ""
}

/// <p>
/// This method synchronizes each object contained in the sync set with the current database. Each object is first checked for concurrency. 
/// Concurrency conflicts occur when the object is modified on the local system after the object was last synchronized with the remote system 
/// where the sync set originated. If a concurrency conflict is detected, the object is passed to the <var>%ResolveConcurrencyConflict</var> 
/// method in <class>%Library.SwizzleObject</class>. If the conflict cannot be resolved, the object is requeued for later 
/// processing and the concurrency error is reported in the %%SERR error log. Otherwise, the object is synchronized by passing it to the 
/// <var>%SyncObjectIn</var> method in <class>%Library.SwizzleObject.</class>. If the synchronization fails, then the object is requeued for 
/// later processing.</p>
/// <br>
/// <p>There are two types of common synchronization errors. The first is an unresolved dependency. This type of error occurs when an object 
/// references another object and the referencing property is part of a REQUIRED constraint. That means the object cannot be saved 
/// until the reference can be resolved. This problem is often caused by a reference to an object that is in the sync set but has not yet been processed. The second 
/// type of problem is an unresolved reference. This type of problem occurs in the same was as an unresolved dependency but the reference is not required in order 
/// for the object to be saved. An object with an unresolved reference is partially synchronized and only the reference is requeued for later processing.</p> 
/// <br>
/// <p>Once all of the objects in the sync set have been processed, the Import method attempts to synchronize all objects that were requeued. During this phase, 
/// all of the unresolved dependencies and references are expected to be resolved. Any objects that fail to synchronize during this phase are left in an 
/// unresolved state. Unresolved objects and errors reported during synchronization can be accessed by using the <query>Unresolved</query> query 
/// or the <query>Errors</query> query.</p>
/// <br>
/// <p>
/// When all of the objects contained in the Sync Set have been processed the time stamps in the <class>%SYNC.SyncTime</class> class are updated using 
/// the <var>maxTS</var> value.
/// </p>
/// <p>Formal parameters:</p>
/// <table border="1">
/// 	<tr><td><var>file</var></td>
/// 			<td>The name of a file containing a sync set. If a file name is specified, then that file will be loaded into the global. 
/// 			If no file is specified, then the global is expected to already exist in the current namespace.</p>
/// 			</td>
/// 		</tr>
/// 	<tr><td><var>lastSync</var></td>
/// 			<td><p>An integer value indicating the <var>SyncTime</var> value when this System.Namespace was last 
/// 				synchronized with the System.Namespace that generated the sync set being imported. If this value is not 
/// 				specified, then it will be retrieved from <class>%SYNC.SyncTime</class></p>
/// 			</td>
/// 		</tr>
/// 	<tr><td><var>maxTS</var></td>
/// 			<td><p>The highest transaction ID contained in the sync set. It is used to set the rTrn property 
/// 				in the <class>%SYNC.SyncTime</class> class. This value is not used for any purpose during import and is 
/// 				maintained for informational purposes only. This value is specified by the user and is expected to be 
/// 				the ID of the last <class>%Library.ObjectJournal</class> object included in the sync set. 
/// 					See the <class>%SYNC.SyncTime</class> for more information on the rTrn and lTrn properties.</p>
/// 			</td>
/// 		</tr>
/// 	<tr><td><var>qspec</var></td>
/// 			<td><p>Option flags. This formal argument is maintained for backward compatibility only.</p>
/// 			</td>
/// 		</tr>
/// 	<tr><td><var>errorlog</var></td>
/// 			<td><p>Array of errors encountered during import. These are not errors encountered during synchronization but are 
/// 				errors reported doing tasks like opening the file.</p>
/// 			</td>
/// 		</tr>
/// 	<tr><td><var>diag</var></td>
/// 			<td><p>If true, then Import will display status information on the current device.</p>
/// 			</td>
/// 		</tr>
/// 	<tr><td><var>trace</var></td>
/// 			<td><p>If true, then Import will record all import activity in the sync set global under the "Trace" subscript.</p>
/// 			</td>
/// 		</tr>
/// </table>
Method Import(file As %String = "", lastSync As %Integer = 0, maxTS As %Integer, qspec As %String = "", ByRef errorlog As %String, diag As %Integer = 0, trace As %Integer = 0) As %Status
{
	// Generic trace message
#define TRACE(%msg)	set:trace @%objsync@("Trace",$Increment(@%objsync@("Trace"))) = %msg
	// SyncObject specific trace message
#define TRACESYNC(%ptr,%action,%msg)	$$$TRACE(%action_": SyncPtr = '"_%ptr_"', "_%msg)

		#; If given a file will import the file, otherwise assume the structure already exists
	new %ROWID, %ROWCOUNT
	set tIdentityInsert = $system.SQL.SetIdentityInsert(1,.rc)
	if $$$ISERR(rc) { quit rc }
    set rc = $$$OK
	if $g(file)'="" Set sc = ..OpenFile(file,qspec,.errorlog) If $$$ISERR(sc) Quit sc
	Set $ZTrap = "CatchError"
	Set localSID = $$$txSIDlocal, localNSID = $$$txNSIDlocal
	Set %objsync = ..GlobalName()
	$$$TRACE("SyncSet Import starting using global '"_%objsync)
	if ($g(@%objsync@("%%LOCALE"))'=$$$LOCALENAME){
		set rc=$$$ERROR($$$SyncDiffLocales,$g(@%objsync@("%%LOCALE")))
		$$$TRACE("%%LOCALE from source is different from current locale")
	}
	If $Data(@%objsync@(0)) { Set %objtxSID = $List(@%objsync@(0),1), %objtxNSID = $List(@%objsync@(0),2) }
	If ((%objtxSID '= localSID) || (%objtxNSID '= localNSID)) {
		if 'lastSync {
			&sql(select lTRN into :ltrn from SyncTime where Namespace=:%objtxNSID and SysId=:%objtxSID)
			if 'SQLCODE { set lastSync=ltrn }
		}
		$$$TRACE("LAST SYNC = "_$Select(lastSync'="":lastSync,1:"Never"))
			#; PASS 1:	%SyncObjectIn each object in the initial partition
		Set iPtr = $Order(@%objsync@(0)) 
		if (iPtr'=+iPtr) {s iPtr=""}
		s iEnd = $Get(@%objsync), synccount = 0
		if diag {Write !,"Processing pass #1: beginning with: ",iPtr," and going through: ",iEnd }
		$$$TRACE("Processing pass #1: beginning with: "_iPtr_" and going through: "_iEnd)
		While (iPtr) && ( iPtr '> iEnd ) {
			Set synccount = synccount + 1
			Set %objtxOSID = $Get(@%objsync@(iPtr,"%%OSID"))
			Set %objtxONSID = $Get(@%objsync@(iPtr,"%%ONSID"))
			If ((%objtxOSID '= localSID) || (%objtxONSID '= localNSID)) {
				Set type = $Get(@%objsync@(iPtr,"%%CLASS"))
				Set guid = $Get(@%objsync@(iPtr,"%GUID"))
				If (type = "") && (guid '= "") { Set oid = ##class(%Library.GUID).%GUIDFind(guid) If oid '= "" { set type = $$$oidClassName(oid) } }
				$$$TRACESYNC(iPtr,"PROCESSING","Type = '"_type_"', GUID = '"_guid_"'")
				If (type '= "") {
					if (guid = "") || ('($Data(@%objsync@("Requeue",guid)))) {
						Set cok = 1
							#; Optimistic concurrency check. If the lastSync time is less than the last journaled file operation then we have a conflict
						If guid '= "" { 
							Set lastVer = $Order(^OBJ.GUID(0,guid,""),-1)
							If (lastVer > lastSync) {
									#; This might be a concurrency failure if the lastVer was not a sync from SyncSet(SYSID,NSID)
								Set lastTran = $Order(^OBJ.JournalT(lastVer),-1)
								While lastTran && ('$Data(^OBJ.JournalT(lastTran,lastVer))) { Set lastTran = $Order(^OBJ.JournalT(lastTran),-1) }
								If 'lastTran {
									Set cok = 0
									$$$TRACESYNC(iPtr,"ERROR","Cannot resolve last version from Journal")
								}
								ElseIf ($ListGet(^OBJ.JournalT(lastTran,lastVer),4) '= %objtxSID) || ($ListGet(^OBJ.JournalT(lastTran,lastVer),5) '= %objtxNSID) {
									Set cok = 0
									$$$TRACESYNC(iPtr,"ERROR","Concurrency conflict")
								}
							}
						}
						If cok {
							Set fileop = $Get(@%objsync@(iPtr),0)
							$$$TRACESYNC(iPtr,"IMPORT","FILEOP = '"_fileop_"'")
							try {
								Set sc = $classmethod(type,"%SyncObjectIn",$this,iPtr,,fileop)
							} catch ex {
								Set sc=ex.AsStatus()
							}
							If $$$ISERR(sc) { 
								Set @%objsync@(iPtr,"%%SERR")=$lb("s",sc)
								Do ..Requeue(iPtr)
								$$$TRACESYNC(iPtr,"REQUEUE","%SyncObjectIn failed with status, requeued. Status = "_$system.Status.GetErrorText(sc))
							}
							elseif guid '= "" {
								kill @%objsync@("Requeue",guid,iPtr)
								$$$TRACESYNC(iPtr,"SUCCESS","Successfully imported, purging requeued entry.")
							}
						}
						Else {
								#; Concurrency failure
							Set oid = ##class(%Library.GUID).%GUIDFind(guid)
							$$$TRACESYNC(iPtr,"RESOLVE","Attempting to resolve concurrency conflict for OID = '"_$ListToString(oid)_"'.")
							Set sc = $classmethod(type,"%ResolveConcurrencyConflict",oid,$this,iPtr,.bAccept)
							If $$$ISERR(sc) { 
								Set @%objsync@(iPtr,"%%SERR")=$lb("c",sc)
								Do ..Requeue(iPtr)
								$$$TRACESYNC(iPtr,"REQUEUE","Concurrency conflict unresolved, requeued. Status = "_$system.Status.GetErrorText(sc))
							}
							ElseIf bAccept {
								Set fileop = $Get(@%objsync@(iPtr),0)
								$$$TRACESYNC(iPtr,"IMPORT","Concurrency conflict resolved. Attempting IMPORT. FILEOP = '"_fileop_"'")
								try {
									Set sc = $classmethod(type,"%SyncObjectIn",$this,iPtr,,fileop)
								} catch ex {
									Set sc=ex.AsStatus()
								}
								If $$$ISERR(sc) {
									Set @%objsync@(iPtr,"%%SERR")=$lb("s",sc)
									Do ..Requeue(iPtr)
									$$$TRACESYNC(iPtr,"REQUEUE","%SyncObjectIn failed with status, requeued. Status = "_$system.Status.GetErrorText(sc))
								}
								elseif guid '= "" {
									kill @%objsync@("Requeue",guid,iPtr)
									$$$TRACESYNC(iPtr,"SUCCESS","Successfully imported, purging requeued entry.")
								}
							}
							elseif guid '= "" {
								kill @%objsync@("Requeue",guid,iPtr)
								$$$TRACESYNC(iPtr,"SUCCESS","Successfully imported, purging requeued entry.")
							}
						}
					}
					else {
						do ..Requeue(iPtr)
						$$$TRACE("REQUEUED: SyncPtr = "_iPtr_", GUID = "_guid)
					}
				}
				else {
						// This is very unusual - no GUID to resolve and no type specified in the Syncset
					$$$TRACE("ERROR: SyncPtr = "_iPtr_", no GUID specified and no TYPE specified")
				}
			}
			If diag { Write !,"Objects processed: ",synccount }
			$$$TRACE("Objects processed during first pass: "_synccount)
			Set iPtr = $Order(@%objsync@(iPtr))
		}
			#; PASS 2:	Topologically order the objects in suspense and attempt to %SyncObjectIn those objects
	
			#; PASS 3:	At this point all of the objects in the SyncSet have been looked at once. There are now two suspense queues to deal with
			#; 			The first is a queue of objects with dependencies.
			#; 			and the second is a queue of objects with unresolved references. They should all be resolvable now.
			// The requeued items are already in the natural order so we need to initialize the requeue index
		kill @%objsync@("Requeue")
		Set iPtr = $Order(@%objsync@(iEnd)), iEnd = $Get(@%objsync)
		if (iPtr'=+iPtr) {s iPtr=""}
		if diag {Write !,"Processing pass #3: beginning with: ",iPtr," and going through: ",iEnd }
		$$$TRACE("Processing requeued items: beginning with: "_iPtr_" and going through: "_iEnd)
		While (iPtr) && ( iPtr '> iEnd ) {
			Set type = $Get(@%objsync@(iPtr,"%%CLASS"))
			Set guid = $Get(@%objsync@(iPtr,"%GUID"))
			Set cok = 1
			if (guid = "") || ('($Data(@%objsync@("Requeue",guid)))) {
					#; Optimistic concurrency check. If the lastSync time is less than the last journaled file operation then we have a conflict
				If guid '= "" {
					Set lastVer = $Order(^OBJ.GUID(0,guid,""),-1)
					If lastVer > lastSync {
							#; This might be a concurrency failure if the lastVer was not a sync from SyncSet(SYSID,NSID)
						Set lastTran = $Order(^OBJ.JournalT(lastVer),-1)
						While lastTran && ('$Data(^OBJ.JournalT(lastTran,lastVer))) { Set lastTran = $Order(^OBJ.JournalT(lastTran),-1) }
						If 'lastTran { Set cok = 0 }
						//ElseIf ($ListGet(^OBJ.JournalT(lastTran,lastVer),4) '= syncSYSID) || ($ListGet(^OBJ.JournalT(lastTran,lastVer),5) '= syncNSID) { Set cok = 0 }
						ElseIf ($ListGet(^OBJ.JournalT(lastTran,lastVer),4) '= %objtxSID) || ($ListGet(^OBJ.JournalT(lastTran,lastVer),5) '= %objtxNSID) { Set cok = 0 }
					}
				}
				If cok {
					Set fileop = $Get(@%objsync@(iPtr),0)
					$$$TRACESYNC(iPtr,"IMPORT","FILEOP = '"_fileop_"'")
					try {
						Set sc = $classmethod(type,"%SyncObjectIn",$this,iPtr,,fileop)
					} catch ex {
						Set sc=ex.AsStatus()
					}
					If $$$ISERR(sc) { 
						Set @%objsync@(iPtr,"%%SERR")=$lb("s",sc)
						Do ..Requeue(iPtr)
						$$$TRACESYNC(iPtr,"REQUEUE","%SyncObjectIn failed with status, requeued. Status = "_$system.Status.GetErrorText(sc))
					}
					elseif guid '= "" {
						kill @%objsync@("Requeue",guid,iPtr)
						$$$TRACESYNC(iPtr,"SUCCESS","Successfully imported, purging requeued entry.")
					}
				}
				Else {
						#; Concurrency failure
					Set oid = ##class(%Library.GUID).%GUIDFind(guid)
					$$$TRACESYNC(iPtr,"RESOLVE","Attempting to resolve concurrency conflict for OID = '"_$ListToString(oid)_"'.")
					Set sc = $classmethod(type,"%ResolveConcurrencyConflict",oid,$this,iPtr,.bAccept)
					If $$$ISERR(sc) { 
						Set @%objsync@(iPtr,"%%SERR")=$lb("s",sc)
						Do ..Requeue(iPtr)
						$$$TRACESYNC(iPtr,"REQUEUE","Concurrency conflict unresolved, requeued. Status = "_$system.Status.GetErrorText(sc))
					}
					ElseIf bAccept {
						Set fileop = $Get(@%objsync@(iPtr),0)
						$$$TRACESYNC(iPtr,"IMPORT","Concurrency conflict resolved. Attempting IMPORT. FILEOP = '"_fileop_"'")
						try {
							Set sc = $classmethod(type,"%SyncObjectIn",$this,iPtr,,fileop)
						} catch ex {
							Set sc=ex.AsStatus()
						}
						If $$$ISERR(sc) {
							Set @%objsync@(iPtr,"%%SERR")=$lb("s",sc)
							Do ..Requeue(iPtr)
							$$$TRACESYNC(iPtr,"REQUEUE","%SyncObjectIn failed with status, requeued. Status = "_$system.Status.GetErrorText(sc))
						}
						elseif guid '= "" {
							kill @%objsync@("Requeue",guid,iPtr)
							$$$TRACESYNC(iPtr,"SUCCESS","Successfully imported, purging requeued entry.")
						}
					}
					elseif guid '= "" {
						kill @%objsync@("Requeue",guid,iPtr)
						$$$TRACESYNC(iPtr,"SUCCESS","Successfully imported, purging requeued entry.")
					}
				}
			}
			Set iPtr = $Order(@%objsync@(iPtr))
		}
		If $g(@%objsync) > iEnd { Set @%objsync@(0,"unresolved") = iEnd + 1, ..Unresolved = iEnd + 1 }
		//  Record the maximal transaction # in SyncTime
		&sql(select %ID into :stid from SyncTime where Namespace=:%objtxNSID and SysId=:%objtxSID)
		if 'SQLCODE {
			&sql(update SyncTime set rTRN=:maxTS where %ID =:stid)
		}
		Else {
			&sql(insert into SyncTime (SysId, NameSpace, rTRN) values(:%objtxSID,:%objtxNSID,:maxTS) )
		}
		Kill $$$txSID, $$$txNSID, $$$txOSID, $$$txONSID
	}
	Kill %objGUID
	do $system.SQL.SetIdentityInsert(tIdentityInsert)
	Quit rc
CatchError
	Set $ZTrap=""
	set @%objsync@("ImportLastError")=$g(sc)
	set @%objsync@("ImportLastError","iPtr" ) = $g(iPtr)
	Kill %objtxSID, %objtxNSID, $$$txOSID, $$$txONSID, %objGUID
	if $Data(tIdentityInsert) { do $system.SQL.SetIdentityInsert(tIdentityInsert) }
	If $Extract($ZError,1,5) = "<ZSS>" Quit $g(sc)
	Quit $$$ERROR($$$ObjectScriptError,$ZError)
}

Method Requeue(iPtr As %Integer) As %Status
{
	Set %objsync = ..GlobalName()
	Set iNewPtr=$I(@%objsync)
	Merge @%objsync@(iNewPtr)=@%objsync@(iPtr)
	set @%objsync@(iNewPtr,"%%BLINK") = iPtr, @%objsync@(iPtr,"%%FLINK") = iNewPtr
	Set tObjectGUID = $Get(@%objsync@(iPtr,"%GUID"))
	if tObjectGUID '= "" { set @%objsync@("Requeue",tObjectGUID,iNewPtr) = iPtr }
	Quit $$$OK
}

Method GetLastTransactionTime() As %Integer
{
	Quit ..LastTransaction
}

/// <p>For information on <var>qSpec</var>, see 
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=ObjectScript+qspec">System Flags and Qualifiers</a>.</p>
Method ExportFile(file As %String = "", qspec As %String = "", bUpdate As %Boolean = 1) As %Status
{
	new %ROWID, %ROWCOUNT
	//Set sc = $system.OBJ.Export("^OBJ.SYNC("""_i%SysGUID_""").gbl",file,qspec)
	Set sc = ##class(%Library.Global).Export(,..GlobalName()_".gbl",file,7,0,qspec)
	if bUpdate && (..Exclude'="") {
		s iTranEnd=..LastTransaction
		s syncSYSID=$lg(..Exclude,1)
		s syncNSID=$lg(..Exclude,2)
		&sql(select %ID,  lTRN into :stid,:ltrn from SyncTime where Namespace=:syncNSID and SysId=:syncSYSID)
		if 'SQLCODE {
			&sql(update SyncTime set lTRN=:iTranEnd where %ID =:stid) 
		}
		Else {
			&sql(insert into SyncTime (SysId, NameSpace, lTRN) values(:syncSYSID,:syncNSID,:iTranEnd) )
		}
	}
	Quit sc
}

/// Open a file containing a sync set global and load it into the current sync set global.
/// Files containing sync set globals are typically in GOF format and are produced by exporting
/// a sync set on another system.
Method OpenFile(file As %String = "", qspec As %String = "", ByRef errorlog) As %Status
{
	Set %objsync = ..GlobalName()

	//If file '= "" { Set sc = $system.OBJ.Load(file,qspec,.errorlog) }
	If file '= "" { Set sc = ##class(%Global).Import(,"",file,7,0,$e(%objsync,2,*)) }
	Else { Set sc = $$$ERROR($$$GeneralError,"No sync set specified") }
	Quit sc
}

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	
	If $G(initvalue)="" Set initvalue=$I(^OBJ.SYNCJOB)
	//Lock +^OBJ.SYNC(initvalue):1 If '$T Quit $$$ERROR($$$GeneralError,"No sync set specified")
	Set i%sId=initvalue
	Set %objsync = ..GlobalName()
	Kill @%objsync
	Set @%objsync@(0) = $ListBuild($$$txSIDlocal,$$$txNSIDlocal)
	Set @%objsync@("%%LOCALE")=$$$LOCALENAME
	Quit $$$OK
}

/// This method should be used for data removal when the syncset is no longer needed.  It deletes all the persistent data
/// and makes impossible further usage of the object.
Method Clear() As %Status
{
	Set %objsync = ..GlobalName()
	Kill @%objsync
	Quit $$$OK
}

/// This method returns the name of the global used for the sync set.
Method GlobalName() As %String [ CodeMode = expression ]
{
"^OBJ.SYNC."_i%sId
}

ClassMethod GetNextTRN(ByRef num As %String) As %RawString
{
	Set num=$order(^OBJ.JournalT(num))
	Quit num
}

ClassMethod GetLastTRN(ByRef num As %String) As %RawString
{
	set num=$order(^OBJ.JournalT(""),-1)
	quit num
}

/// Add %Library.ObjectJournalTransactions to the current SyncSet. Each transaction in the %ObjectJournalTransaction extent is identified
/// by an integer that is incremented for each new transaction. This ID assignment mechanism places transactions in chronological order, that is,
/// the order in which the transactions are created. Transactions are expected to be in that order when later imported and sync'ed into another
/// namespace. This method adds a range of transactions, beginning with <var>iTranLast</var> and ending with <var>iTranEnd</var>. The <var>TNumber</var>
/// argument, if specified and is not zero, limits the number of transactions added. When that number of transactions has been added the method will
/// return to the caller, even if the <var>iTranEnd</var> value has not yet been reached.
/// The LastTransaction property is set to the ID of the last transaction added to the SyncSet.
Method AddTransactions(iTranLast As %Integer = 0, iTranEnd As %Integer = 0, lExclude As %List = "", TNumber As %Integer = 0) As %Integer
{
	new %ROWID, %ROWCOUNT
	set iTranStart=0
	if iTranLast { set iTranStart=$order(^OBJ.JournalT(iTranLast)) }
	set %objsync = ..GlobalName()
	if 'iTranEnd { set iTranEnd = $get(^OBJ.JournalT) }
	if iTranEnd>$get(^OBJ.JournalT) set iTranEnd=$get(^OBJ.JournalT)
	set ..LastTransaction=iTranEnd
	set ..FirstTransaction=iTranStart
	set ..Exclude=lExclude
	if lExclude'="" {
		set syncSYSID=$listget(lExclude,1)
		set syncNSID=$listget(lExclude,2)
		&sql(select %ID,  lTRN into :stid,:ltrn from SyncTime where Namespace=:syncNSID and SysId=:syncSYSID)
		if 'SQLCODE {
			if 'iTranStart { set iTranStart = $order(^OBJ.JournalT(ltrn)) }
		}
		elseif SQLCODE'=100 { set @%objsync@("%%ERR","SQLERROR")=SQLCODE }
		set ..FirstTransaction=iTranStart
		set ..LastTransaction=iTranEnd
	}
	set iCount = 0, iTranLast = iTranEnd
	set rs = 1, rsat=1
	if iTranStart="" quit iCount
	
	if '$data(^OBJ.JournalT(iTranStart)) { set iTranPtr = $order(^OBJ.JournalT(iTranStart)) }
	else { set iTranPtr = iTranStart }

	while (iTranPtr '= "") && (iTranPtr '> iTranEnd)&& rs && rsat {
		lock +^OBJ.JournalT(iTranPtr,$job)#"S":1
			#; stop if we cannot lock the transaction node
		if '$test { quit }
		lock -^OBJ.JournalT(iTranPtr,$job)#"S"
		if $order(^OBJ.JournalT(iTranPtr,""),1,row)="" {
			do ..nextPointer(.iTranPtr,.iTranLast)
			continue
		}
			#; exclude 
		if lExclude'="" && (( ($listget(lExclude,1)=$listget(row,6)) && ($listget(lExclude,2)=$listget(row,7)))||( ($listget(lExclude,1)=$listget(row,4)) && ($listget(lExclude,2)=$listget(row,5)))) do ..nextPointer(.iTranPtr,.iTranLast) continue

		set objJTran = ##class(%Library.ObjectJournalTransaction).%OpenId(iTranPtr)
		set rs = $isobject(objJTran)
		set status = objJTran.AddJrnTranToSyncSet($this, lExclude)
		set rsat = $$$ISOK(status)
		if ('rsat) { //log errors
			set ii= $increment(@%objsync@("%%ERR"))
			set @%objsync@("%%ERR",ii)=iTranPtr
			set @%objsync@("%%ERR",ii,"Status")=status
		}
		if (rs) {
			if (rsat){set iCount = iCount + 1}
			do ..nextPointer(.iTranPtr,.iTranLast)
			// keep current journal file open (do this before objJTran is destroyed)
			if '$get(CurrentJournalFile) { set CurrentJournalFile=objJTran.SysTranId.File }
			elseif CurrentJournalFile'=objJTran.SysTranId.File {
				// keep the old journal file open for transactions that are relocated to next file
				kill PreviousJournalFile set PreviousJournalFile=CurrentJournalFile
				kill CurrentJournalFile // close the old journal file
				set CurrentJournalFile=objJTran.SysTranId.File
			}
		}
		if TNumber && (TNumber = iCount) quit
	}
	set ..LastTransaction=iTranLast
	quit iCount
}

Method AddJournaledTransaction(iTranPtr As %Integer = 0, lExclude As %List = "") As %Integer
{
	If ('iTranPtr) { Quit 0 }
	Set objJTran = ##class(%Library.ObjectJournalTransaction).%OpenId(iTranPtr)
	If ($isobject(objJTran)) { Quit objJTran.AddJrnTranToSyncSet($this, lExclude) }
	Else { Quit $$$OK }
}

Method AddJournaledObject(iTranPtr As %Integer = 0, iObjPtr As %Integer = 0, srcSystem As %String, srcNS As %String) As %Integer
{
	If ('iTranPtr) || ('iObjPtr) || ('$Data(^OBJ.Journal(iTranPtr,iObjPtr))) { Quit 0 }
  	if ..FilterObject'=""{
		Set value = ^OBJ.Journal(iTranPtr,iObjPtr)
  		s oid = $List(value,4)
  		s classname=$List(value,2)
  		s guid=$Get(^OBJ.GUID(1,oid),$Get(^OBJ.JournalG(oid)))
  		i $classmethod(classname,"Filter",guid,..FilterObject,iTranPtr) {Quit 0}
  	}
	Quit ##class(%Library.ObjectJournal).AddJrnRecToSyncSet(i%sId,iTranPtr,iObjPtr,srcSystem,srcNS)
}

/// Add an object to the current SyncSet. This method can be used to force an object to be included in the
/// SyncSet when it isn't recorded in the ObjectJournal. It should not be used for normal situations since
/// the ObjectJournal is expected to be complete. Normally, an object that is added to the SyncSet is a
/// <i>versioned object</i> meaning that the object state is recovered from history (normally, from the system
/// journal). AddObject causes the object as it currently exists in the extent to be added to the SyncSet, breaking
/// the natural chronology of the SyncSet.
/// Parameters:
/// 		class - the object's type class;
/// 		id		- the object's ID value;
/// 		fileop	- the filing operation that caused this object to be added to the sync set
/// 					0 - update
/// 					1 - insert
/// 					2 - delete
/// 		guid	- the object's GUID
Method AddObject(class As %String = "", id As %String = "", fileop As %Integer = 0, guid As %String = "") As %Integer
{
	Set %objsync = ..GlobalName()
	If (class = "") || (id = "") { Quit 0 }
	If fileop = 2 {
		If guid '= "" { Set iPtr = $Increment(@%objsync), @%objsync@(iPtr) = 2, @%objsync@(iPtr,"%%CLASS") = class, @%objsync@(iPtr,"%GUID") = guid Quit iPtr }
		Else { Quit 0 }
	}
	Else {
		Set oref = $classmethod(class,"%OpenId",id)
		If oref '= $$$NULLOREF { Quit $classmethod(class,"%AddToSyncSet",$this,oref,fileop) }
		Else { Quit 0 }
	}
}

/// This callback method is invoked by the <METHOD>%Close</METHOD> method to 
/// provide notification that the current object is being closed.
/// 
/// <P>The return value of this method is ignored.
Method %OnClose() As %Status [ Private, ProcedureBlock = 1 ]
{
	//Lock -^OBJ.SYNC(i%SysGUID)
    Quit $$$OK
}

Query PropertyValues(sid As %String, iObjPtr As %Integer) As %Query(ROWSPEC = "Property:%String,Value:%String")
{
}

ClassMethod PropertyValuesExecute(ByRef qHandle As %Binary, sid As %String = "0", iObjPtr As %Integer = 0) As %Status
{
	Set %objsync = "^OBJ.SYNC."_sid
	If sid]"" && iObjPtr]"" && $Data(@%objsync@(iObjPtr)) { Set qHandle = $ListBuild(sid,iObjPtr, "") }
	Else { Set qHandle = $ListBuild("","","") }
	Quit $$$OK
}

ClassMethod PropertyValuesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = PropertyValuesExecute ]
{
	Set sid = $List(qHandle,1), iObjPtr = $List(qHandle,2), property = $List(qHandle,3)
	Set %objsync = "^OBJ.SYNC."_sid
	If (sid="")  || (iObjPtr="") { Set Row = "", AtEnd = 1 }
	Else {
		Set property = $Order(@%objsync@(iObjPtr,property))
		If property '= "" { Set value = @%objsync@(iObjPtr,property), Row = $lb(property,value), $List(qHandle,3) = property }
		Else { Set AtEnd = 1, Row = "" }
	}
	Quit $$$OK
}

ClassMethod PropertyValuesClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = PropertyValuesExecute ]
{
	Set qHandle = $ListBuild(0,0,"")
	Quit $$$OK
}

Query CollectionValues(sid As %String, iObjPtr As %Integer, CollName As %String) As %Query(ROWSPEC = "Key:%String,Value:%String")
{
}

ClassMethod CollectionValuesExecute(ByRef qHandle As %Binary, sid As %String = "0", iObjPtr As %Integer = 0, CollName = "") As %Status
{
	Set %objsync = "^OBJ.SYNC."_sid
	If sid]"" && iObjPtr]"" &&(CollName'="")&& $Data(@%objsync@(iObjPtr,CollName)) { Set qHandle = $ListBuild(sid,iObjPtr,CollName, "") }
	Else { Set qHandle = $ListBuild("","","","") }
	Quit $$$OK
}

ClassMethod CollectionValuesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = PropertyValuesExecute ]
{
	Set sid = $List(qHandle,1), iObjPtr = $List(qHandle,2), property = $List(qHandle,3),key=$List(qHandle,4)
	Set %objsync = "^OBJ.SYNC."_sid
	If (sid="")  || (iObjPtr="") { Set Row = "", AtEnd = 1 }
	Else {
		Set key = $Order(@%objsync@(iObjPtr,property,key))
		If key '= "" { Set value = @%objsync@(iObjPtr,property,key), Row = $lb(key,value), $List(qHandle,4) = key }
		Else { Set AtEnd = 1, Row = "" }
	}
	Quit $$$OK
}

ClassMethod CollectionValuesClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = PropertyValuesExecute ]
{
	Set qHandle = $ListBuild("","","")
	Quit $$$OK
}

/// Find the last synchronization record for a particular GUID
Method FindLastGUID(guid As %String) As %Integer
{
	Set %objsync = ..GlobalName()
	Set iPtr=""
	For  {
		Set iPtr = $Order(@%objsync@(iPtr),-1)
		Quit:iPtr="" 
		If $G(@%objsync@(iPtr,"%GUID"))=guid Quit
	}
	Quit iPtr
}

Method IsEmpty() As %Boolean
{
	Set %objsync = ..GlobalName()
	Set iPtr = $Order(@%objsync@(0))
	QUIT $s(iPtr:0,1:1)
}

Method nextPointer(ByRef iTranPtr, ByRef iTranLast)
{
 	Set iTranLast=iTranPtr
	Set iTranPtr = $Order(^OBJ.JournalT(iTranPtr))
}

Method ErrCount() As %Integer
{
 Set %objsync = ..GlobalName()
 QUIT +$g(@%objsync@("%%ERR"))
}

Query Errors() As %Query(ROWSPEC = "Ptr:%String,Status:%String")
{
}

ClassMethod ErrorsExecute(ByRef qHandle As %Binary, sid As %String = "0") As %Status
{
	Set %objsync = "^OBJ.SYNC."_sid
	If sid]""  && $Get(@%objsync@("%%ERR")) { Set qHandle = $ListBuild(sid,0) }
	Else { Set qHandle = $ListBuild("","","") }
	Quit $$$OK
}

ClassMethod ErrorsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = ErrorsExecute ]
{
	Set sid = $List(qHandle,1), ind = $List(qHandle,2)
	Set %objsync = "^OBJ.SYNC."_sid
	If (sid="")  || (ind="") { Set Row = "", AtEnd = 1 }
	Else {
		Set ind = $Order(@%objsync@("%%ERR",ind))
		If ind '= "" { Set Row=$lb(@%objsync@("%%ERR",ind),@%objsync@("%%ERR",ind,"Status")), $List(qHandle,2) = ind }
		Else { Set AtEnd = 1, Row = "" }
	}
	Quit $$$OK
}

ClassMethod ErrorsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = ErrorsExecute ]
{
	Set qHandle = $ListBuild(0,0,"")
	Quit $$$OK
}

/// Queue an error to the current sync set
Method QueueError(pTranPtr As %Integer, pStatus As %Status = "") As %Status [ ProcedureBlock = 1 ]
{
	set %objsync = ..GlobalName()
	set ii= $increment(@%objsync@("%%ERR"))
	set @%objsync@("%%ERR",ii) = pTranPtr
	set @%objsync@("%%ERR",ii,"Status") = pStatus
	quit $$$OK
}

ClassMethod GetLastInfo(guid As %String, ByRef lastver As %Integer, ByRef sid As %String, ByRef nmsid As %String) As %Status
{
	set lastVer = $order(^OBJ.GUID(0,guid,""),-1)
	set sid=""
	set nmsid=""
	set lastTran = $order(^OBJ.JournalT(lastVer),-1)
	while lastTran && ('$data(^OBJ.JournalT(lastTran,lastVer))) { set lastTran = $order(^OBJ.JournalT(lastTran),-1) }
	if 'lastTran { set cok = 0 }
	if lastTran {
		set sid=$listget(^OBJ.JournalT(lastTran,lastVer),4) 
	 	set nmsid = ($listget(^OBJ.JournalT(lastTran,lastVer),5) ) 
 	}
	quit $$$OK
}

}
