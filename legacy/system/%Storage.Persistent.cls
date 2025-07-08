/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %systemInclude

/// This class contains the storage interface methods 
/// for the default storage structure. The storage interface 
/// methods, which are implemented as method generators, work in conjunction 
/// with the persistent interface methods of the <class>%Persistent</class> class to 
/// provide persistent behavior for objects. 
/// 
/// <p>The methods of this class are not meant to be called directly. 
/// Use the methods of the <class>%Persistent</class> class which, in turn, call the 
/// appropriate method. 
Class %Storage.Persistent Extends %Storage [ Abstract, Not ProcedureBlock, System = 2 ]
{

Parameter STORAGECOMPILERCLASS = "%Compiler.Storage.Persistent";

/// STORAGEINTERFACE defines the type of serialization implemented by this class.
/// The value has to match the classtype of the class that is inheriting the serialization
/// interface.
Parameter STORAGEINTERFACE As STRING [ Constraint = ",persistent,serial", Flags = ENUM ] = "persistent";

/// %AncestryStorageToLogical
ClassMethod "%%CLASSNAMEStorageToLogical"(%val) As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
	set %code=0
	merge %code=$$$tEXTcode("%%CLASSNAMEStorageToLogical")
	RETURN $$$OK
}

/// %AncestryLogicalToStorage
ClassMethod "%%CLASSNAMELogicalToStorage"(%val) As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
	set %code=0
	merge %code=$$$tEXTcode("%%CLASSNAMELogicalToStorage")
	RETURN $$$OK
}

ClassMethod %BMEBuilt(ByRef bmeName As %String) As %Boolean [ CodeMode = generator, ServerOnly = 1 ]
{
	If $Data($$$tEXTcode("BMEBuilt")) { m %code=$$$tEXTcode("BMEBuilt") }
	Else { $$$GENERATE("	Quit 1") }
	QUIT $$$OK
}

/// This method will build the indexes requested for the range of ID's requested. If it is prudent to do this work in the background 
/// using multiple processes then it will be done using $system.WorkMgr. 
/// If doing the work in the background then the extent will be partitioned using one of four different algorithms.
/// 1) Integer ID, no bitmap extent index present - compute the difference between the first ID and the last, divide by partition size;
/// 2) Integer ID, bitmap extent index present - chunk up using bitmap chunk size and the bitmap extent;
/// 3) Single non-integer property - 
/// 4) Composite ID on non-integer property -
ClassMethod %BuildIndices(pIndexList As %RawString = "", pAutoPurge As %Integer = 1, pLockFlag As %Integer = 0, pJournalFlag As %Integer = "", pStartID As %RawString = "", pEndID As %RawString = "", pIgnoreIndexList As %RawString = "", pKeepSelectability As %Integer = 0, pNumberJobs As %Integer = "") As %Status [ CodeMode = generator, Internal, ProcedureBlock = 1, ServerOnly = 1 ]
{
	If $Data($$$tEXTcode("BuildIndices")) { m %code=$$$tEXTcode("BuildIndices") }
	Else { $$$GENERATE($Char(9)_"Quit 1") }
	QUIT $$$OK
}

ClassMethod %BuildDeferredIndices(lockFlag As %Integer = 0, journalFlag As %Integer = 1) As %Status [ CodeMode = generator, Internal, ProcedureBlock = 1 ]
{
	// Make sure that we actually need to generate filing code for this class
	if ($$$getClassType(%class)'=$$$cCLASSCLASSTYPEPERSISTENT) || ($$$comClassKeyGet(%class,$$$cCLASSnoextent)) {
		$$$GENERATE($char(9)_"return $$$OK")
		return $$$OK
	}
	if $$$comMemberKeyGet(%class,$$$cCLASSparameter,"READONLY",$$$cPARAMdefault) {
		$$$GENERATE($char(9)_"return $$$ERROR($$$ClassIsReadOnly,$$$objClass)")
		return $$$OK
	}
	set didiLoc = $get($$$EXTdeferredlocation($$$pEXT,%class))
	if didiLoc = "" {
		$$$GENERATE($char(9)_"return $$$ERROR($$$MethodNotImplemented,""%Storage.Persistent::%BuildDeferredIndices"")")
		return $$$OK
	}
	
	set idkeyname = $$$EXTidkey($$$pEXT,%class)
	if '$$$comMemberKeyGet(%class,$$$cCLASSindex,idkeyname,$$$cINDEXposint) {
		$$$GENERATE($char(9)_"return $$$ERROR($$$MethodNotImplemented,""%Storage.Persistent::%BuildDeferredIndices"")")
	}

	set tIsRoot = $get($$$EXTrootclass($$$pEXT,%class))
		// build a list of indexes
	set tAddress = $order($$$EXTADDR($$$pEXT,%class,"")), tIndexList = 0
	while tAddress '= "" {
		set tAddressType = $$$EXTADDRtype($$$pEXT,%class,tAddress)
		if (tAddressType '= $$$cEXTADDRADDRESSTYPEDATA) {
			if ($$$EXTADDRorigin($$$pEXT,%class,tAddress) = %class) || tIsRoot {
				set tIndexList = 1
				quit
			}
		}
		set tAddress = $order($$$EXTADDR($$$pEXT,%class,tAddress))
	}
		// Early exit if there are no indexes in the index list
	if 'tIndexList {
		$$$GENERATE($char(9)_"return $$$OK")
		return $$$OK
	}
 
	// process restrictions, compute DII reference
	set diiglobal = $$$EXTdataglobal($$$pEXT, %class) _ ".0"
	$$$GENERATE($char(9)_"try {")
	$$$GENERATE($char(9, 9)_"set status = $$$OK, class = $classname()")
	$$$GENERATE($char(9,9)_"if lockFlag=1||(lockFlag=3) {")
	$$$GENERATE($char(9,9,9)_"$$$THROWONERROR(status,..%LockExtent($select(lockFlag=1:0,1:1)))")
	$$$GENERATE($char(9,9,9)_"set tLocked=1")
	$$$GENERATE($char(9,9)_"}")
	$$$GENERATE($char(9,9)_"set journal = $$$JournalState")
	$$$GENERATE($char(9,9)_"try {")
	$$$GENERATE($char(9,9,9)_"if journalFlag=0,journal do DISABLE^%SYS.NOJRN()")
	$$$GENERATE($char(9,9,9)_"if journalFlag=1,'journal do ENABLE^%SYS.NOJRN()")
	$$$GENERATE($char(9,9)_"} catch {")
	$$$GENERATE($char(9,9,9)_"set status=$$$ERROR($$$UserInsufficientPrivsDisableJournal) goto exit")
	$$$GENERATE($char(9,9)_"}")
	$$$GENERATE($char(9,9)_"new %objlasterror")
	$$$GENERATE($char(9,9)_"set queue=$SYSTEM.WorkMgr.%New("""",,""Utility"")")
	$$$GENERATE($char(9,9)_"set:queue="""" status=$s($g(%objlasterror)'="""":%objlasterror,1:$$$ERROR($$$GeneralError,""Unknown error creating work queue group $zerror=""_$ze))")
	$$$GENERATE($char(9,9)_"if $$$JournalState'=journal {")
	$$$GENERATE($char(9,9,9)_"try {")
	$$$GENERATE($char(9,9,9,9)_"if journal { do ENABLE^%SYS.NOJRN() } else { do DISABLE^%SYS.NOJRN() }")
	$$$GENERATE($char(9,9,9)_"} catch {")
	$$$GENERATE($char(9,9,9,9)_"set status=$$$ERROR($$$UserInsufficientPrivsDisableJournal) goto exit")
	$$$GENERATE($char(9,9,9)_"}")
	$$$GENERATE($char(9,9)_"}")
	$$$GENERATE($char(9,9)_"if $$$ISERR(status) goto exit")
	$$$GENERATE($char(9,9)_"kill ^IRIS.TempIndexBuild($job)")
	$$$GENERATE($char(9,9)_"set chunkPtr = $order("_diiglobal_"(""""),1,chunk)")
	$$$GENERATE($char(9,9)_"while chunkPtr {")
	$$$GENERATE($char(9,9,9)_"set status = queue.Queue(""##class("_%class_").%BuildDeferredSegment"",chunkPtr,chunk,lockFlag,$job)")
	$$$GENERATE($char(9,9,9)_"if $$$ISERR(status) goto exit")
	$$$GENERATE($char(9,9,9)_"set chunkPtr = $order("_diiglobal_"(chunkPtr),1,chunk)")
	$$$GENERATE($char(9,9)_"}")
	$$$GENERATE($char(9,9)_"if $$$ISOK(status) set status = queue.Sync()")
	$$$GENERATE($char(9)_"} catch tException {")
	$$$GENERATE($char(9,9)_"set status = tException.AsStatus()")
	$$$GENERATE($char(9)_"}")
	$$$GENERATE("exit	if $get(tLocked) {")
	$$$GENERATE($char(9,9)_"do ..%UnlockExtent($select(lockFlag=1:0,1:1))")
	$$$GENERATE($char(9)_"}")
	$$$GENERATE($char(9)_"set i=""""")
	$$$GENERATE($char(9)_"for {")
	$$$GENERATE($char(9,9)_"set i=$order(^IRIS.TempIndexBuild($job,i),1,val) quit:i=""""")
	$$$GENERATE($char(9,9)_"if val'=0 do $system.Event.Delete($name(^IRIS.TempIndexBuild($job,i)))")
	$$$GENERATE($char(9)_"}")
	$$$GENERATE($char(9)_"kill ^IRIS.TempIndexBuild($job)")
	$$$GENERATE($char(9)_"return status")
	return $$$OK
}

/// This function generates the code to iterate over a range of ID values, invoking the index filer for each ID.
ClassMethod %BuildIndicesSegment(pStartID As %Integer, pEndID As %Integer, ByRef pIndexHandle As %Binary = 0, pLockFlag As %Integer = 1, pFirstRange As %Boolean = 0, pJob As %RawString = "", pTableConversion As %String = "") As %Status [ CodeMode = generator, Internal, ProcedureBlock = 1, ServerOnly = 1 ]
{
	If $Data($$$tEXTcode("BuildIndicesSegment")) { m %code=$$$tEXTcode("BuildIndicesSegment") }
	Else { $$$GENERATE($Char(9)_"Quit 1") }
	QUIT $$$OK
}

ClassMethod %BuildDeferredSegment(chunkPtr As %Integer, chunk As %Binary, pLockFlag As %Integer = 1, pJob As %RawString = "") As %Status [ CodeMode = generator, Internal, ProcedureBlock = 1, ServerOnly = 1 ]
{
	If $Data($$$tEXTcode("BuildDeferredSegment")) { m %code=$$$tEXTcode("BuildDeferredSegment") }
	// Else { $$$GENERATE($Char(9)_"Quit 1") }
	QUIT $$$OK
}

/// %DeleteData()
/// 	Delete object from persistent storage
/// 	The caller is responsible for calling %IdSet()
/// 	Don't include class name with id in input parameter
ClassMethod %DeleteData(id As %String, concurrency As %Integer) As %Status [ CodeMode = generator, Final, Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
 s %code=0
 m %code=$$$tEXTcode("DeleteData")
 QUIT $$$OK
}

/// %Exists()
/// 	Check to see if an OID exists in the extent of this class...
ClassMethod %Exists(oid As %ObjectIdentity = "") As %Boolean [ Final, ProcedureBlock = 1, ServerOnly = 0 ]
{
	Quit ..%ExistsId($$$oidPrimary(oid))
}

/// %ExistsId()
/// 	Check to see if an ID exists in the extent of this class...
ClassMethod %ExistsId(id As %String) As %Boolean [ CodeMode = generator, Final, ProcedureBlock = 1, ServerOnly = 0 ]
{
	If $Data($$$tEXTcode("ExistsId")) {
		Kill %code
		Merge %code = $$$tEXTcode("ExistsId")
		If $Data(%code) = 1 { Set %codemode=$$$cMETHCODEMODEEXPRESSION }
	}
	ElseIf $$$CLASSabstract($$$gMGINFO,%class) {
		Set %code = "$isobject(..%OpenId(id,0))", %codemode = $$$cMETHCODEMODEEXPRESSION
	}
	Else { Set %code = 0 }
	QUIT $$$OK
}

/// Files each index for the object identified by <var>id</var>. <var>pIndexHandle</var> is for internal use only.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
/// This method is normally generated by the storage class for persistent classes using
/// <class>%Storage.Persistent</class> or <class>%Storage.SQL</class>.
ClassMethod %FileIndices(id As %String(MAXLEN=""), ByRef pIndexHandle As %Binary = 0, ByRef pVectorBuffer As %RawString) As %Status [ CodeMode = generator, Internal, ProcedureBlock = 1, ServerOnly = 1 ]
{
	If $Data($$$tEXTcode("FileIndices")) { m %code=$$$tEXTcode("FileIndices") }
	Else { $$$GENERATE($Char(9)_"quit 1") }
	QUIT $$$OK
}

ClassMethod %FileIndicesBuffered(id As %String(MAXLEN=""), ByRef pIndexHandle As %Binary = 0, ByRef pIndexBuffer As %RawString = "", ByRef pVectorBuffer As %RawString) As %Status [ CodeMode = generator, Internal, ProcedureBlock = 1, ServerOnly = 1 ]
{
	If $Data($$$tEXTcode("FileIndicesBuffered")) { m %code=$$$tEXTcode("FileIndicesBuffered") }
	Else {
		set %codemode = $$$cMETHCODEMODEEXPRESSION
		set %code="..%FileIndices(.id,.pIndexHandle,.pVectorBuffer)"
	}
	QUIT $$$OK
}

/// Initialize the data global for extent root classes.
/// Return an error if the class is not the extent root class.
ClassMethod %InitExtentData() As %Status [ CodeMode = generator, Final, ServerOnly = 1 ]
{
	set %code=0
	merge %code=$$$tEXTcode("InitExtent")
	RETURN $$$OK
}

/// Kill the data, index, and idlocations for extent root classes. Return an error if the class
/// is not the extent root class.
/// If <var>killstreams</var> is true (default is false) it will also kill the default stream storage global.
/// If <var>reinitialize</var> is true (default is false) it will also call %InitExtent to re-define the globals.
ClassMethod %KillExtentData(killstreams As %Boolean = 0, reinitialize As %Boolean = 0) As %Status [ CodeMode = generator, Final, ServerOnly = 1 ]
{
	set %code=0
	merge %code=$$$tEXTcode("KillExtent")
	RETURN $$$OK
}

/// 	Load object from persistent storage into memory. The caller is responsible for calling %IdSet()
/// 	Don't include class name with id in input parameter
Method %LoadData(id As %String) As %Status [ CodeMode = generator, Final, Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
 s %code=0
 m %code=$$$tEXTcode("LoadData")
 QUIT $$$OK
}

/// 	Load object from persistent storage into memory. The caller is responsible for calling %IdSet()
/// 	Don't include class name with id in input parameter
/// 	state is the physical data where the structure of state mirrors the structure of the object on disk
/// 	obj is an array, subscripted by property name where each array element is equal to the property value named as the subscript.
ClassMethod %LoadFromMemory(id As %String, ByRef objstate As %String, ByRef obj As %String) As %Status [ Final, ProcedureBlock = 1, ServerOnly = 1 ]
{
	If $Get(id)="" Quit $$$ERROR($$$NullOid,$classname())
	Set oref=$$$CreateObject($classname()) If oref=$$$NULLOREF Set sc = $$$ERROR($$$AbstractClassNotInstantiable,$classname()) Quit oref
	Set sc=oref.%LoadInit(,$zu(115,10)) If $$$ISERR(sc) Quit $$$NULLOREF
	Set sc=oref.%LoadDataFromMemory(id,.objstate,.obj) If $$$ISERR(sc) Quit $$$NULLOREF
	#; set object as not modified
	Do $system.CLS.SetModified(oref,0)
	Quit oref
}

Method %LoadDataFromMemory(id As %String, ByRef objstate As %String, ByRef obj As %String) As %Status [ CodeMode = generator, Final, Internal, Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
 s %code=0
 m %code=$$$tEXTcode("LoadDataFromMemory")
 QUIT $$$OK
}

/// 	Load object from persistent storage into memory.  The caller is responsible for calling %IdSet()
/// 	Don't include class name with id in input parameter
ClassMethod %PhysicalAddress(id As %String, ByRef paddr As %String) As %Status [ CodeMode = generator, Final, ServerOnly = 1 ]
{
 s %code=0
 m %code=$$$tEXTcode("PhysicalAddress")
 QUIT $$$OK
}

/// %OnDetermineClass - find the most-specific-type-class for the given OID.
ClassMethod %OnDetermineClass(oid As %ObjectIdentity, ByRef class As %String) As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
 s %code=0
 m %code=$$$tEXTcode("OnDetermineClass")
 QUIT $$$OK
}

ClassMethod %PurgeIndices(idxlist As %List = "", lockExtent As %Boolean = 0, pIgnoreIndexList As %RawString = "", pJournalFlag As %Library.Integer = "") As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
 s %code=0
 m %code=$$$tEXTcode("PurgeIndices")
 QUIT $$$OK
}

/// Acquire (s)hared or (e)xclusive locks based on locktype parameter
ClassMethod %LockExtent(shared As %Boolean = 0) As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
	if $$$comSharded(%class)=1 { // JMM1160= JMM1281=
		set %code=1
		set %code(1)=$c(9)_"RETURN $$$ERROR($$$MethodNotImplemented,""%Persistent::%LockExtent (for sharded classes)"")"
	} else {
		set %code=0
		merge %code=$$$tEXTcode("LockExtent")
	}
	RETURN $$$OK
}

/// Release (s)hared or (e)xclusive locks based on locktype parameter
ClassMethod %UnlockExtent(shared As %Boolean = 0, immediate As %Boolean = 0) As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
	if $$$comSharded(%class)=1 { // JMM1160= JMM1281=
		set %code=1
		set %code(1)=$c(9)_"RETURN $$$ERROR($$$MethodNotImplemented,""%Persistent::%LockExtent (for sharded classes)"")"
	} else {
		set %code=0
		merge %code=$$$tEXTcode("UnlockExtent")
	}
	RETURN $$$OK
}

/// %LockId() - Obtain an exclusive or shared lock on the object identified by <var>id</var>.  The type	of lock obtained is determined by <var>shared</var>.  This method overrides the implementation from %Library.Persistent.
ClassMethod %LockId(id As %String, shared As %Boolean = 0, timeout As %Integer = {$$$LockTimeout}) As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 0 ]
{
 s %code=0
 m %code=$$$tEXTcode("LockId")
 QUIT $$$OK
}

/// %UnlockId() - Release an exclusive or shared lock on the object identified by <var>id</var>.  The type of lock released is determined by <var>shared</var>.  This method overrides the implementation from %Library.Persistent.
ClassMethod %UnlockId(id As %String, shared As %Boolean = 0, immediate As %Boolean = 0) As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 0 ]
{
 s %code=0
 m %code=$$$tEXTcode("UnlockId")
 QUIT $$$OK
}

/// %SaveData() - Save the object to a persistent state (e.g. store it on disk).
/// Returns: oid or "" if save fails
Method %SaveData(id As %String) As %Status [ CodeMode = generator, Final, Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	set %code=0
	merge %code=$$$tEXTcode("SaveData")
	QUIT $$$OK
}

ClassMethod %InsertBatch(objects As %List, concurrency As %Integer = 0, useTransactions As %Boolean = 0) As %List [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
	set %code = 0, tStatus = $$$OK
	if ($$$getClassType(%class)=$$$cCLASSCLASSTYPEPERSISTENT) && ('$$$comClassKeyGet(%class,$$$cCLASSnoextent)) {
		try {
			set mvEnabled = $$$comMemberKeyGet(%class,$$$cCLASSparameter,"MVENABLED",$$$cPARAMdefault)
			set tGenerator = ##class(%Compiler.Storage.Generator.Persistent).%New(0,%class,mvEnabled,,1)
				#; triggers will hold 6 bits with the following meaning:
				#;  Positions:  1 BeforeIns, 2 AfterIns, 3 BeforeUpd, 4 AfterUpd, 5 BeforeDel, 6 AfterDel
				#;  Values:     0 no object trigger, 1 object trigger ObjectScript, 2 object Trigger Python
			if $Find($Extract(tGenerator.triggers,1,4),$Char(1))||$Find($Extract(tGenerator.triggers,1,4),$Char(2)) { $$$tMetadataUses("PrecompileTriggerCode^%occTrigger(%class)") }
			do tGenerator.generateInsertBatch(.%code)
		}
		catch tException {
			set tStatus = tException.AsStatus()
		}
	}
	quit tStatus
}

/// %SaveDirect() - saves an object to disk, checks uniqueness and referential
/// integrity constraints, and maintains index structures. This method is
/// implemented by the storage class.
ClassMethod %SaveDirect(ByRef id As %String = "", idList As %List = "", ByRef data As %Binary, concurrency As %Integer = -1) As %Status [ CodeMode = generator, Final, ProcedureBlock = 1, ServerOnly = 1 ]
{
	set %code = 0, tStatus = $$$OK
	if ($$$getClassType(%class)=$$$cCLASSCLASSTYPEPERSISTENT) && ('$$$comClassKeyGet(%class,$$$cCLASSnoextent)) {
		try {
			set mvEnabled = $$$comMemberKeyGet(%class,$$$cCLASSparameter,"MVENABLED",$$$cPARAMdefault)
			set tGenerator = ##class(%Compiler.Storage.Generator.Persistent).%New(0,%class,mvEnabled)
				#; triggers will hold 6 bits with the following meaning:
				#;  Positions:  1 BeforeIns, 2 AfterIns, 3 BeforeUpd, 4 AfterUpd, 5 BeforeDel, 6 AfterDel
				#;  Values:     0 no object trigger, 1 object trigger ObjectScript, 2 object Trigger Python
			if $Find($Extract(tGenerator.triggers,1,4),$Char(1))||($Find($Extract(tGenerator.triggers,1,4),$Char(2))) { $$$tMetadataUses("PrecompileTriggerCode^%occTrigger(%class)") }
			do tGenerator.generateSaveDirect(.%code)
		}
		catch tException {
			set tStatus = tException.AsStatus()
		}
	}
	quit tStatus
}

/// Files the indices for all objects whose ID is in the range defined by <var>pStartId</var> and <var>pEndId</var>.
/// If <var>pEndID</var> is null then it defaults to <var>pStartId</var>. If <var>pStartId</var> is null then the
/// range is empty and no filing will occur.
/// 
/// If <var>lockExtent</var> is true then an extent lock will be acquired before the indices
/// are built. If the lock cannot be acquired then an error is returned. The lock is released
/// after the index filing is completed.
/// 
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
ClassMethod %SaveIndices(pStartId As %String(MAXLEN="") = "", pEndId As %String(MAXLEN="") = "", lockExtent As %Boolean = 0) As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 0 ]
{
	set %code=0
	merge %code=$$$tEXTcode("SaveIndices")
	QUIT $$$OK
}

/// %SortBegin()
/// This method will start a system merge sort for all indices (idxlist is null) or for specified indices
ClassMethod %SortBegin(idxlist As %List = "", excludeunique As %Integer = 0) As %Status [ CodeMode = generator, ServerOnly = 1 ]
{
 s %code=0
 m %code=$$$tEXTcode("SortBegin")
 QUIT $$$OK
}

/// %SortEnd()
/// This method will end a system merge sort for all indices (idxlist is null) or for specified indices
ClassMethod %SortEnd(idxlist As %List = "", commit As %Integer = 1, excludeunique As %Integer = 0) As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
 s %code=0
 m %code=$$$tEXTcode("SortEnd")
 QUIT $$$OK
}

}
