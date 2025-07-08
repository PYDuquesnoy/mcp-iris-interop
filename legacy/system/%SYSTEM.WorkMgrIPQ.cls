/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// For internal use only
Class %SYSTEM.WorkMgrIPQ Extends (WorkMgr, IPQSet)
{

Method %OnNew(ByRef qstruct As %String, numberjobs As %Integer, type As %String = 2) As %Status [ Internal, Private, ServerOnly = 1 ]
{
	$$$qualifierParseDirect(sc,qstruct) If $$$ISERR(sc) Quit sc
	Set group=-1
	Do ..Init()
	Set sc=$$CreateWorkers^%SYS.WorkQueueMgr(.group,,.numberjobs,type,,"SQL")
	#; Call DeleteAll on error in case %OnClose is not called for a partially constructed oref
	If $$$ISERR(sc) Do ..DeleteAll() Quit sc
	Merge i%group=group
	Set i%NumWorkers=numberjobs
	Quit sc
}

/// SQL Speicific queue function
Method SQLQueue(rtnidx As %Binary, work As %String, args... As %String) [ Internal ]
{
	Merge group=i%group
	Set sc=$$realQueue^%SYS.WorkQueueMgr(.group,,":"_$listbuild($piece(work,":"),rtnidx,$piece(work,":",2)),,.args)
	Kill i%group Merge i%group=group
	If $$$ISERR(sc) {
		Set SQLCODE=$$StatusToSQLCODE^%apiOBJ(sc,.msg)
		Do SQERror^%apiSQL(242,"Parallel query run-time error: -"_SQLCODE_" "_msg)
	}
}

/// This is called when the <var>data</var> received from the IPQ is "" in order to return
/// any error information or output anything to the current device and to take care of 
/// book keeping. It will set <var>AtEnd</var> if we are at the end of the data and will
/// run any callback methods and will return to the caller.
Method Decode(qspec As %String, ByRef AtEnd As %Boolean) As %Status
{
	Merge group=i%group
	Set sc=$$WaitForComplete^%SYS.WorkQueueMgr(,.group,-2,.AtEnd)
	Kill i%group Merge i%group=group
	RETURN sc
}

/// SQL Specific decode function. Returns true if we are at the end of the work.
/// Not for general use, use the <method>Decode</method> method.
/// <var>end</var> signals we believe all work is completed so we should be able to wait
/// for all complete and exit
Method SQLDecode() As %Boolean [ Internal ]
{
	Merge group=i%group
	Set sc=$$WaitForComplete^%SYS.WorkQueueMgr(,.group,-2,.atend)
	Kill i%group Merge i%group=group
	If $$$ISERR(sc) {
		Set SQLCODE=$$StatusToSQLCODE^%apiOBJ(sc,.msg)
		Do SQERror^%apiSQL(SQLCODE,msg)
	}
	Quit atend
}

/// SQL Specific decode function. Returns true if we are at the end of the work.
/// Not for general use, use the <method>Decode</method> method.
/// <var>end</var> signals we believe all work is completed so we should be able to wait
/// for all complete and exit
Method SQLDecode2(end = 0) As %Boolean [ Internal ]
{
	Merge group=i%group
	Set sc=$$WaitForComplete^%SYS.WorkQueueMgr(,.group,$s(end:-3,1:-4),.atend)
	Kill i%group Merge i%group=group
	If $$$ISERR(sc) {
		Set SQLCODE=$$StatusToSQLCODE^%apiOBJ(sc,.msg)
		Do SQERror^%apiSQL(SQLCODE,msg)
	}
	Quit $s(end:atend,1:0)  ; Never report 'AtEnd' unless caller thinks we are at the end so we can report errors or output
}

/// SQL Specific initialize function.
/// Not for general use, use the <method>Initialize</method> method.
ClassMethod SQLInitialize(numberjobs As %Integer, checkdefault As %Boolean = 0, type As %Integer = 2, ByRef extable As %String, ByRef groupID As %String) As WorkMgr [ Internal ]
{
	If $get(numberjobs)>1,checkdefault {
		Set defaultjobs=$$calcJobs^%SYS.WorkQueueMgr(,,"SQL")
		If numberjobs>defaultjobs Set numberjobs=defaultjobs
	}
	#; Hard code qualifiers to avoid having to parse them
	Set qstruct("multicompile")=1,qstruct("journal")=1,qstruct("displaylog")=0,qstruct("displayerror")=0
	Set oref=..%New(.qstruct,.numberjobs,.type)
	If oref=$$$NULLOREF {
		Set sc=$get(%objlasterror)
		If $$$ISERR(sc) {
			Set SQLCODE=$$StatusToSQLCODE^%apiOBJ(sc,.msg)
		} Else {
			Set SQLCODE=-400,msg="Unknown error creating WorkMmgrIPQ class"
		}
		Do SQERror^%apiSQL(242,"Parallel query run-time error: -"_SQLCODE_" "_msg)
	} Else {
		If $data(extable)||$data(%ISCSNShardMapVersion) {
			Set sc=oref.Setup("##class(%SYSTEM.WorkMgrIPQ).SQLSetup",.extable,$g(%ISCSNShardMapVersion))
			If $$$ISOK(sc) Set sc=oref.TearDown("##class(%SYSTEM.WorkMgrIPQ).SQLTearDown")
			If $$$ISERR(sc) {
				Set SQLCODE=$$StatusToSQLCODE^%apiOBJ(sc,.msg)
				Do SQERror^%apiSQL(242,"Parallel query run-time error: -"_SQLCODE_" "_msg)
			}
		}
	}
	set groupID = oref.group
	Quit oref
}

ClassMethod SQLSetup(args As %String, shardMapVersion As %String) As %Status [ Internal ]
{
	Kill %ISCSNRemoteTables
	Merge %ISCSNRemoteTables=args
	Set:$g(shardMapVersion)'="" %ISCSNShardMapVersion=shardMapVersion
	Quit $$$OK
}

ClassMethod SQLTearDown() As %Status [ Internal ]
{
	Kill %ISCSNRemoteTables
	Quit $$$OK
}

}
