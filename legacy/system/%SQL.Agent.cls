/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %BigData.ShardableEntity

///  This is an internal class used for distributed SQL processing.
///  This class contains no user-accessible methods.
Class %SQL.Agent [ Abstract, System = 4 ]
{

/// Given an array of vals and a function to call create the work manager IPQ object and schedule the work for this
/// return the IPQ object. On the event of any errors use standard SQL error handling (ZTrap).
ClassMethod %RunWorkVals2(type As %Integer, ByRef vals As %String, rtnidx As %Binary, function As %String, args As %String, ByRef extable As %String, ByRef groupID As %String = "", ByRef total As %Integer) As %SYSTEM.WorkMgrIPQ [ Internal ]
{
	Set val="",gbls=$$$GlobalRefs,total=0
	For count=0:1:128 {
		Set val=$order(vals(val)) Quit:val=""
	}
	#; No work so nothing to do
	If count=0 Quit $$$NULLOREF
	Set group=##class(%SYSTEM.WorkMgrIPQ).SQLInitialize(count,1,type,.extable,.groupID)
	Set val = ""
	For  {
		Set val = $O(vals(val)) QUIT:val=""
		Do BuildMultiArgs^%SYS.WorkQueueMgr(.total,val,args)
	}
	Set sc=group.QueueLocalEntryMulti(rtnidx,function,.total) If $$$ISERR(sc) Goto error
	#; Subtrack out globals referenced here as these are non-deterministic e.g. the use of the cache so throw off tests that validate global reference counts
	Try {
		Do $increment($system.Context.WorkMgr().GlobalReferences,gbls-$$$GlobalRefs)
	} Catch {}  ; Ignore errors due to failure to load context object in HALT processing
	Quit group
error	Set SQLCODE=$$StatusToSQLCODE^%apiOBJ(sc,.msg)
	Do SQERror^%apiSQL(242,"Parallel query run-time error: -"_SQLCODE_" "_msg)
}

ClassMethod %EndQuery(pTempIndex As %String, pQueryId As %Integer) As %Status [ Internal ]
{
	#INCLUDE %BigData.ShardedSQL ;
	#dim tSC As %Status
	
	$$$SNDebugTracePerf("Start %EndQuery tempIndex "_pTempIndex_" pQueryId:",pQueryId,10) 
	Set tSC = $$$OK
	Set tempGlobalName=($$$SSSQLTempGlobalName_pTempIndex)
	Try {
		$$$SNDebugTrace("%EndQuery tempIndex "_pTempIndex_" temp file defined:",$d(@tempGlobalName@(-1)))
		// Make sure temp file is complete, when done, kill it
		quit:'$d(@tempGlobalName@(-1))	// temp file never allocated/started!  why???
		set tLastRowData=""
		set tLastRow=$o(@tempGlobalName@(0,""),-1,tLastRowData)
		// IMPORTANT NOTE: The following logic is now generated as inlined code in %qaqcky.mac, and can be executed
		// either there, or here, depending on whether a query runs to completion or is closed prior to fetching all
		// rows.  Therefore, any change made to this logic must be made in both places.
		if $a(tLastRowData)=1 { 
			d:+$g(%SNGetQueryStats) getQueryStats^%SYS.SHARDSRV(pTempIndex) 
			$$$SNDebugTrace("%EndQuery killing "_tempGlobalName)
			kill:'+$g(%SNSaveTempFiles) @tempGlobalName@(0),@tempGlobalName@(-1) 
			$$$SNDebugTrace("%EndQuery calling cleanupQuery("_pTempIndex_","_pQueryId_")")
			set tSC=$$cleanupQuery^%SYS.SHARDSRV(pTempIndex,pQueryId,1) 
		}
		else {
			// We've been called before all result rows have been retrieved, so query may still be running,
			// and needs to be cancelled.
			$$$SNDebugTrace("%EndQuery calling cancelQuery^%SYS.SHARDSRV("_pTempIndex_","_pQueryId_")")
			set tSC=$$cancelQuery^%SYS.SHARDSRV(pTempIndex,pQueryId)
			$$$SNDebugTrace("%EndQuery tempIndex "_pTempIndex_" queryId "_pQueryId_" : cancelQuery returned:",tSC)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		$$$SNDebugTrace("%EndQuery caught exception:",tSC)
	}
	$$$SNDebugTracePerf("%EndQuery returning tempIndex: "_pTempIndex_" queryId: "_pQueryId_" tSC:",tSC,10)
	return tSC
}

///  Process the Status code error into an SQLCODE and %msg error.  %msg is a public variable.
ClassMethod ProcessError(pSC As %Status, ByRef SQLCODE As %Integer, ByRef %msg As %String) [ Internal ]
{
	#dim ex As %Exception.SystemException
	#dim i,ecode As %Integer
	#dim errlist As %String

	Try {
		set errlist=""
		set SQLCODE=-400
		do DecomposeStatus^%apiOBJ(pSC,.errlist)
		set ecode=$$$GETERRORCODE(pSC) if ecode=921||(ecode=922)||(ecode=923) set SQLCODE=-99
		for i=1:1:errlist set %msg=errlist(i)_$s(i>1:"  ",1:"")
	}
	Catch(ex) {
		set SQLCODE=-400, %msg="Error in %SQL.Agent.ProcessError():: "_$ze_"  Attempting to process status code "_$g(pSC)
	}
	Quit
}

///  This method executes the given query and writes the results to the specified temp global
///  location.<br/>
///  This is called by a background agent.
ClassMethod %ExecuteQuery(pSQL As %String, pTempIndex As %String, pSelectMode As %Integer = 0, pReadCommitted As %Integer = 0) As %Status [ Internal ]
{
	#dim tStatment As %SQL.Statement
	#dim tRSET As %SQL.StatementResult
	#dim tSC As %Library.Status
	
		// Name of the global to pipe the output to
	#def1arg pipe ^IRIS.Temp.IRIS.Sql
	
	Set tSC = $$$OK
	Try {
		// execute the query
		// For this implementation we are going to simply use %SQL.Statement.ExecDirect() to execute the pSQL statement.
		
		#; set zh=$zh
		set tCnt=0
		set $li($$$pipe(pTempIndex,-1),2)="Executed by PID: "_$j_"  SELECTMODE: "_pSelectMode
		if $d($$$pipe(pTempIndex,-2),tArgList) { set pArgs=$ll(tArgList) for i=1:1:$ll(tArgList) { set:$ld(tArgList,i) pArgs(i)=$li(tArgList,i) } }

		set tStatement = ##class(%SQL.Statement).%New(pSelectMode)
		do $zu(115,2,pReadCommitted)
		set tStatement.%msqlvar="""%sqldata"""
		set tSC = tStatement.%Prepare(.pSQL)
		if $$$ISERR(tSC) {
			new %msg
			do DecomposeStatus^%apiOBJ(tSC,.err,"-d")
			if $g(err(1,"code"))="5540"||($g(err(1,"code"))="5521") { 
				set SQLCODE=$g(err(1,"param",1)),%msg=$g(err(1,"param",2))
			}
			set:$g(SQLCODE)="" SQLCODE=-400
			set:$g(%msg)="" %msg=$g(err(1))
			set tCnt=tCnt+1
			set $$$pipe(pTempIndex,0,tCnt)=$lb(,SQLCODE,%msg)
			quit
		}

		set tRSET = tStatement.%Execute(pArgs...)
		set tNumColumns=tRSET.%ResultColumnCount
		if tRSET.%SQLCODE<0 {	// Error
			set tCnt=tCnt+1
			set $$$pipe(pTempIndex,0,tCnt)=$lb(,tRSET.%SQLCODE,tRSET.%Message)
			quit
		}

		// write results to temp global

		// Results should be be a $List of the fields in the SELECT list in the
		// order they appear in the SELECT list.
		// We should $Increment the temp global to get the subscript used to write out the $List
		// When we are done, or if there is an error set it into the second piece of the $List in the last row
		// If there is an error, we put the error message in the third column of the last row of the temp file data
		// When done with the query we put the following values in $$$pipe(pTempIndex,0,Counter) = $lb(,status,message)
		//   -  status = 100 - no [more] data
		//   -  status = -##, SQLCODE error value if error, piece 2 will have an error message

		if tRSET.%FetchIntoTemp(pTempIndex,.tCnt,.tSC) {}
		if tRSET.%SQLCODE=100 {	// No rows returned or some rows returned, but no error and we are done
			set tCnt=tCnt+1
			set $$$pipe(pTempIndex,0,tCnt)=$lb(,100)
		}
		elseif tRSET.%SQLCODE<0 {	// Error
			set tCnt=tCnt+1
			set $$$pipe(pTempIndex,0,tCnt)=$lb(,tRSET.%SQLCODE,tRSET.%Message)
		}
			// destuct the oref here to force a cursor close (%OnClose) here.
			// If we wait for the procedure to exit, it is too late as we have no chance to clean up the %sqldata## variables.
			// This is a special case ONLY for %parallel code.  The statement uses %sqldata## public variables instead of arrays for performance,
			// but the %sqldata## variables are not cleaned up by cursor close.  We clean them up here.
		set tRSET=""
		new %tVar
		set %tVar="%sqldata"
		for  { set %tVar=$o(@(%tVar)) quit:$e(%tVar,1,8)'="%sqldata"  kill @%tVar }
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Set tCnt=tCnt+1
		set $$$pipe(pTempIndex,0,tCnt)=$lb(,400,ex.DisplayString())
	}
	#; set $$$pipe(pTempIndex,-3)=($zh-zh)
	Quit tSC
}

}
