/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %systemInclude

/// The <b>%Storage.SQL</b> class contains a set of storage interface methods
/// that use embedded SQL statements, as well as an advanced set of data
/// mapping definition, to provide a way to layer objects on top of pre-existing
/// InterSystems IRIS data structures.
/// 
/// <p>The storage interface methods, which are implemented as
/// method generators, work in conjunction
/// with the persistent interface methods of the <class>%Persistent</class> class to
/// provide persistent behavior for objects.
/// 
/// <p>The methods of <b>%Storage.SQL</b> are not meant to be called directly.
/// Use the methods of the <class>%Persistent</class> class which, in turn, call the
/// appropriate <class>%Storage.Persistent</class> method.
Class %Storage.SQL Extends %Storage [ Abstract, Not ProcedureBlock, System = 2 ]
{

Parameter OBJECTSPULLTRIGGERS = 1;

Parameter STORAGECOMPILERCLASS = "%Compiler.Storage.SQL";

/// Acquire (s)hared or (e)xclusive locks based on locktype parameter
ClassMethod %LockExtent(shared As %Boolean = 0) As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
	set %codemode = $$$cMETHCODEMODEEXPRESSION
	if $$$comMemberKeyGet(%class,$$$cCLASSparameter,"CONNECTION",$$$cPARAMdefault)'="" s %code="$$$OK" q $$$OK
	set %code = "$Select(..%SQLAcquireTableLock(shared):$$$OK,1:$$$ERROR($Select('shared:$$$ERRORCODE($$$LockFailedToAcquireExclusive),1:$$$ERRORCODE($$$LockFailedToAcquireRead)),$classname()))"
	QUIT $$$OK
}

/// Release (s)hared or (e)xclusive locks based on locktype parameter
ClassMethod %UnlockExtent(shared As %Boolean = 0, immediate As %Boolean = 0) As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
	i $$$comMemberKeyGet(%class,$$$cCLASSparameter,"CONNECTION",$$$cPARAMdefault)'="" s %codemode=$$$cMETHCODEMODEEXPRESSION,%code="$$$OK" q $$$OK
	s %codemode=$$$cMETHCODEMODEEXPRESSION, %code = "$Select(..%SQLReleaseTableLock(shared,immediate):$$$OK,1:$$$ERROR($$$SQLCode,SQLCODE,%msg))"
	Quit $$$OK
}

/// Acquire (s)hared or (e)xclusive locks based on locktype parameter
ClassMethod %LockId(id As %String, shared As %Boolean = 0, timeout As %Integer) As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
	if $$$comMemberKeyGet(%class,$$$cCLASSparameter,"CONNECTION",$$$cPARAMdefault)'="" s %codemode=$$$cMETHCODEMODEEXPRESSION,%code="$$$OK" q $$$OK
	$$$GENERATE("	If id="""" Quit $$$ERROR($$$NullId)")
	$$$GENERATE("	If $get(timeout)'="""" Set oldtimeout=$zutil(115,4,timeout)")
	$$$GENERATE("	Try { Set rc=..%SQLAcquireLock(id,shared) Do:$get(timeout)'="""" $zutil(115,4,oldtimeout) } Catch { Do:$get(timeout)'="""" $zutil(115,4,oldtimeout) Throw }")
	$$$GENERATE("	If 'rc Quit $$$ERROR($Select('shared:$$$ERRORCODE($$$LockFailedToAcquireExclusive),1:$$$ERRORCODE($$$LockFailedToAcquireRead)),id_"":""_$classname())")
	$$$GENERATE("	Quit $$$OK")
	QUIT $$$OK
}

/// Release locks held on an object (identified by the id parameter).
/// If shared is true then the lock released is a shared lock. If immediate is
/// true then release the lock immediately (lock not held until completion of the
/// current transaction)
ClassMethod %UnlockId(id As %String, shared As %Boolean = 0, immediate As %Boolean = 0) As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
 i $$$comMemberKeyGet(%class,$$$cCLASSparameter,"CONNECTION",$$$cPARAMdefault)'="" s %codemode=$$$cMETHCODEMODEEXPRESSION,%code="$$$OK" q $$$OK
 $$$GENERATE("	Do ..%SQLReleaseLock(id,shared,immediate)")
 $$$GENERATE("	Quit $$$OK")
 Quit $$$OK
}

/// %BuildIndices
/// 	Build all the indices contained in idxlist. If idxlist is empty then all
/// 	indices will be built. If autoPurge is true then %PurgeIndices(idxlist) will
/// 	be called before starting to build.
ClassMethod %BuildIndices(pIndexList As %RawString = "", pAutoPurge As %Integer = 1, pLockFlag As %Integer = 0, pJournalFlag As %Integer = "", pStartID As %RawString = "", pEndID As %RawString = "", pIgnoreIndexList As %RawString = "", pKeepSelectability As %Integer = 0) As %Status [ CodeMode = generator, Internal, ProcedureBlock = 1, ServerOnly = 1 ]
{
	If $$$comMemberKeyGet(%class,$$$cCLASSparameter,"CONNECTION",$$$cPARAMdefault) = "" {
		$$$GENERATE($Char(9)_"try {")
		$$$GENERATE($Char(9,9)_"set journal=$$CURRENT^%SYS.NOJRN()")
		$$$GENERATE($Char(9,9)_"if ($ll(pIndexList)=1)&&($lg(pIndexList)="""") { return $$$OK }")
		$$$GENERATE($Char(9,9)_"set locked=0,sc=$$$OK,ptr=0")
		$$$GENERATE($Char(9,9)_"While $listnext(pIndexList,ptr,tIndex) {")
		$$$GENERATE($Char(9,9,9)_"continue:tIndex=""""")
		$$$GENERATE($Char(9,9,9)_"If "_$Select($get($$$EXTrootclass($$$pEXT,%class)):"'$$$comMemberDefined($classname(),$$$cCLASSindex,tIndex)",1:"$$$comMemberKeyGet($classname(),$$$cCLASSindex,tIndex,$$$cINDEXorigin)'=$classname()")_" {")
		$$$GENERATE($Char(9,9,9,9)_"Set sc=$$$ADDSC(sc,$$$ERROR($$$IndexNameInvalid,$classname()_""::""_tIndex))")
		$$$GENERATE($Char(9,9,9)_"}")
		$$$GENERATE($Char(9,9)_"}")
		$$$GENERATE($Char(9,9)_"If $$$ISERR(sc) { $$$ThrowStatus(sc) }")
		$$$GENERATE($Char(9,9)_"if pJournalFlag=0,journal { try { do DISABLE^%SYS.NOJRN() } catch { $$$ThrowStatus($$$ERROR($$$UserInsufficientPrivsDisableJournal)) } }")
		$$$GENERATE($Char(9,9)_"if pJournalFlag=1,'journal { try { do ENABLE^%SYS.NOJRN() } catch { $$$ThrowStatus($$$ERROR($$$UserInsufficientPrivsDisableJournal)) } }")
		$$$GENERATE($Char(9,9)_"if pLockFlag = 1||(pLockFlag=3) { set SQLCODE=0 do ..%SQLAcquireTableLock($select(pLockFlag=3:1,1:0),.SQLCODE) if SQLCODE { $$$ThrowStatus($$$ERROR($$$SQLCode,SQLCODE,$g(%msg))) } else { set locked=1 } }")
		$$$GENERATE($Char(9,9)_"if $system.CLS.IsMthd(""%OnBeforeBuildIndices"") { set sc=..%OnBeforeBuildIndices(.pIndexList) if $$$ISERR(sc) { $$$ThrowStatus(sc) } }")
		$$$GENERATE($Char(9,9)_"if ($ll(pIndexList)'=1)||($lg(pIndexList)'="""") {")
		$$$GENERATE($Char(9,9,9)_"if pAutoPurge,pStartID="""",pEndID="""" { set sc = ..%PurgeIndices(pIndexList,,pIgnoreIndexList) if $$$ISERR(sc) { $$$ThrowStatus(sc) } }")
		$$$GENERATE($Char(9,9,9)_"set sc=..%SQLBuildIndices(pIndexList,pLockFlag,pStartID,pEndID,pIgnoreIndexList,pKeepSelectability) if $$$ISERR(sc) { $$$ThrowStatus(sc) }")
		$$$GENERATE($Char(9,9,9)_"if $system.CLS.IsMthd(""%OnAfterBuildIndices"") { set sc=..%OnAfterBuildIndices(.pIndexList) if $$$ISERR(sc) { $$$ThrowStatus(sc) } }")
		$$$GENERATE($Char(9,9)_"}")
		$$$GENERATE($Char(9)_"}")
		$$$GENERATE($Char(9)_"catch tException {")
		$$$GENERATE($Char(9,9)_"set sc = tException.AsStatus()")
		$$$GENERATE($Char(9)_"}")
		$$$GENERATE($Char(9)_"if locked { do ..%SQLReleaseTableLock($select(pLockFlag=3:1,1:0)) }")
		$$$GENERATE($Char(9)_"if $$CURRENT^%SYS.NOJRN()'=journal { if journal { do ENABLE^%SYS.NOJRN() } else { do DISABLE^%SYS.NOJRN() } }")
		$$$GENERATE($Char(9)_"quit sc")
	}
	Else { Set %codemode = $$$cMETHCODEMODEEXPRESSION, %code="$$$OK" }
	QUIT $$$OK
}

/// %DeleteData()
/// 	Delete object from persistent storage
/// 	The caller is responsible for calling %IdSet()
/// 	Don't include class name with id in input parameter
ClassMethod %DeleteData(id As %String, concurrency As %Integer) As %Status [ Final, Private, ServerOnly = 1 ]
{
	Quit $$$OK
}

/// Load object from persistent storage into memory
/// The caller is responsible for calling %IdSet()
/// Don't include class name with id in input parameter
Method %LoadData(id As %String) As %Status [ Final, Private, ServerOnly = 1 ]
{
	Quit $$$OK
}

ClassMethod %PurgeIndices(idxlist As %List = "", lockExtent As %Boolean = 0, pIgnoreIndexList As %RawString = "") As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
	If $$$comMemberKeyGet(%class,$$$cCLASSparameter,"CONNECTION",$$$cPARAMdefault) = "" {
		$$$GENERATE($Char(9)_"if ($listlength(idxlist)=1)&&($listget(idxlist)="""") { return $$$OK }")
		$$$GENERATE("	s $ZTrap=""CatchError"",locked=0,sc=$$$OK")
		$$$GENERATE("	i lockExtent { d ..%SQLAcquireTableLock(0,.SQLCODE) i SQLCODE { q $$$ERROR($$$SQLCode,SQLCODE,$g(%msg)) } else { s locked=1 } }")
		$$$GENERATE($Char(9)_"if $system.CLS.IsMthd(""%OnBeforePurgeIndices"") { set sc=..%OnBeforePurgeIndices(.idxlist) i ($$$ISERR(sc))||(($ll(idxlist)=1)&&($lg(idxlist)="""")) { i locked { d ..%SQLReleaseTableLock(0) } quit sc } }")
		$$$GENERATE("	s sc=..%SQLPurgeIndices(idxlist,lockExtent,pIgnoreIndexList)")
		$$$GENERATE($Char(9)_"if $system.CLS.IsMthd(""%OnAfterPurgeIndices"") { set sc=..%OnAfterPurgeIndices(.idxlist) }")
		$$$GENERATE("	i locked { d ..%SQLReleaseTableLock(0) }")
		$$$GENERATE("	q sc")
		$$$GENERATE("CatchError	s $ZTrap="""" i $ZE'="""" { s sc = $$$ERROR($$$ObjectScriptError,$ZE) } i locked { d ..%SQLReleaseLock(0) } q sc")
	}
	Else { Set %codemode = $$$cMETHCODEMODEEXPRESSION, %code="$$$OK" }
	QUIT $$$OK
}

/// %SaveData()
/// Save the object to a persistent state (e.g. store it on disk)
/// return: oid or "" if save fails
Method %SaveData(id As %String) As %Status [ Final, Private, ServerOnly = 1 ]
{
	Quit $$$OK
}

/// %Exists()
/// 	Check to see if an OID exists in the extent of this class...
ClassMethod %Exists(oid As %ObjectIdentity = "") As %Boolean [ CodeMode = generator, ServerOnly = 0 ]
{
	New connection,qtable
	$$$comMemberKeyGetLvar(connection,%class,$$$cCLASSparameter,"CONNECTION",$$$cPARAMdefault)
	If $$$CLASSabstract($$$gMGINFO,%class)||(connection'="")||('$$$classIsPersistent(%class)) {
		Set %code = "$isobject(..%OpenId($$$oidPrimary(oid),0))", %codemode = $$$cMETHCODEMODEEXPRESSION
		Quit $$$OK
	}
	Set qtable=$$$CLASSsqlqualifiednameQ($$$gWRK,%class)
	$$$GENERATE("	New SQLCODE,id,id2,%ROWCOUNT,%ROWID,%msg")
	$$$GENERATE("	Set id=$$$oidPrimary(oid)")
	$$$GENERATE("	&sql(SELECT %ID INTO :id2 FROM "_qtable_" WHERE %ID=:id)")
	$$$GENERATE("	Quit $select(SQLCODE:0,id'=id2:0,1:1)")
	QUIT $$$OK
}

/// %KillExtentData() - kills extent data in storage. This method is
/// implemented by the storage class. If <var>killstreams</var> is true (default is false) it will also kill the default stream storage global.
ClassMethod %KillExtentData(killstreams As %Boolean = 0) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	RETURN $$$ERROR($$$MethodNotImplemented,"%Storage.SQL::%KillExtentData, in order to call %KillExtent() on a class using %Storage.SQL, %KillExtentData must be overridden and implemented in this class")
}

}
