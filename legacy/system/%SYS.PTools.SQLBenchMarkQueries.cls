/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%SYS.PTools.Stats, %quoter)

/// <style type="text/css"> 
///    DEP { color: red; font-weight: bold; }
///    BC { color: green; font-weight: bold; }
///    PROP { display: block; white-space: pre; font-size: 16px; font-family: monospace; }
///    STUB { color: DarkGoldenRod ; }
///    IMP { color: red; font-style: italic; }
///    .dep-head { color: red; white-space: pre; font-family:  'Courier New'; }
///    .section-head { color: blue; white-space: pre; font-family:  'Courier New'; }
///    .info-head { white-space: pre; font-family: 'Courier New'; }
/// </style>
/// <p>This Class gets populated from the <method>%SYS.PTools.SQLStats.startSQLStats()</method> method when gathering stats is turned on.
///    There is more info on how to run Stats in <class>%SYS.PTools.SQLStats</class>.
/// 
/// <p>The class contains the SQLText, the Job Number, the Time Stamp from when the query was run, the SQLIndexHash, which is a unique ID for the SQL Statement Index, and the Parameters that were used.
/// 
/// <p>The Method <method>Run</method> will loop over all the saved queries and execute them one after the other.
/// 
/// <p>Because ^%SYS.PTools.BenchMarkResults stores data in the "IRISLOCALDATA" database you need to have %All to execute the Run() method.
Class %SYS.PTools.SQLBenchMarkQueries Extends %Persistent [ System = 4 ]
{

Property QueryText As %String(MAXLEN = 15000);

Property NameSpace As %String;

Property PValues As array Of %String(MAXLEN = 2000);

Property RunTime As %TimeStamp;

Property JobNumber As %String;

/// Internal unique statement hash used as the ID for the SQL Statement Index (DPV4651):
///    ^rINDEXSQL("sqlidx",1,{SQLIndexHash},...)
///    ^rINDEXSQL("sqlidx",2,{rtn},{SQLIndexHash})
///    ^rINDEXSQL("sqlidx",3,{table},{SQLIndexHash})
/// For additional details, refer to the following: http://twiki.iscinternal.com/twiki/bin/view/ISC/SQL20Statement20Indexing
/// Also, refer to the following methods in the <rtn>%SYS.SQLSRVR.MAC<rtn> routine:
///    - SaveSQLIndex(...)			- UnfreezePlan(...)		- FreezePlanSchema(...)		- CleanSQLIndex(...)
///    - SaveSQLIndexImport(...)	- FreezePlan(...)		- FreezePlanRelation(...)	- ...
///    - UpdateSQLIndex(...) 		- FreezePlanAll(...)	- DeleteSQLIndex(...)
/// 
Property SQLIndexHash As %String(MAXLEN = 32);

Query QueryWithParameters() As %SQLQuery [ SqlView, SqlViewName = Query_With_Parameters ]
{
SELECT P.Id, P.NameSpace, P.QueryText, P.RunTime, P.JobNumber, P.SQLIndexHash, PV.PValues
FROM %SYS_PTools.SQLBenchMarkQueries P 
LEFT OUTER JOIN %SYS_PTools.SQLBenchMarkQueries_PValues PV ON P.ID = PV.SQLBenchMarkQueries
}

/// <p>This is a simple example of what can be done with the data stored in this table.
/// <p>This methods take 2 parameters:
/// <ul>
/// <li>NameSpace - the NameSpace where you want to run the Benchmark</li>
/// <li>Display   - 1 or 0 to control output to the screen</li>
/// </ul>
/// <p>This method will loop over the queries that are stored in this classes
/// and execute them as Dynamic SQL statements
/// SQLStats is turned off for this run and the state is returned when the code finishes
/// The code will display and save data for fetching the first row and for fetching all the rows
/// The data saved will be:  Global Refs, Lines of Code, Rows Returned, and Total Time.
/// All the results are stored in the <class>%SYS.SQLBenchMarkResults</class> class.
ClassMethod Run(NameSpace As %String, Display As %Integer = 1) As %Status
{
	&SQL(DECLARE query1 CURSOR FOR
	     SELECT ID, QueryText, RunTime
	     INTO :Pid, :sql, :TS
	     FROM %SYS_PTools.SQLBenchMarkQueries  
	     WHERE NameSpace=:NameSpace
	     ORDER BY RunTime)
	     
	&SQL(DECLARE query2 CURSOR FOR
	     SELECT PV.PValues
	     INTO :param
		 FROM %SYS_PTools.SQLBenchMarkQueries_PValues PV 
		 WHERE PV.SQLBenchMarkQueries = :Pid)
		 
 s status=$$$OK
 set query1OPEN=0
 Try {	 
     s currentNS=$NameSpace
	 s NameSpace=$ZU(5,NameSpace)
	 s SQLStats=$SYSTEM.SQL.SetSQLStats(0)
	 s Run=$i(^%sqlcq($NAMESPACE,"PTools","Bench","Results","C","Run"))
	 s StartTS=$ZDATETIME($ZTIMESTAMP,3)
	 &SQL(Open query1)
	 if SQLCODE<0 { set status=$$$ERROR($$$SQLError,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%apiSQL(SQLCODE))) THROW }
	 set query1OPEN=1
	 f QueryCount=1:1 {
		 QUIT:$$$ISERR(status)  // Error Occurred!
		 ; get a query to run
		 &SQL(FETCH query1) 
		 Q:SQLCODE'=0 	
		 i Display w !,"Query# ",QueryCount,!,?2,sql,!
		 &SQL(OPEN query2)
		 QUIT:SQLCODE<0  // OPEN Failed so QUIT for-loop & fall thru to ERROR!
		 ; build a comma delimited list of parameter values
		 s values=""
		 f  &SQL(FETCH query2) Q:SQLCODE'=0  s values=values_","_$$quoter(param,1) 
		 set:SQLCODE<0 status=$$$ADDSC(status,$$$ERROR($$$SQLError,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%apiSQL(SQLCODE))))
		 s values=$e(values,2,*)
		 i Display w !,?5,"Parameter values:  ",values
		 s execute="set %tResult = %tStatement.%Execute("_values_")"
		 &SQL(CLOSE query2)
		 set:SQLCODE<0 status=$$$ADDSC(status,$$$ERROR($$$SQLError,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%apiSQL(SQLCODE)))),SQLCODE=0
		 ; make the query all upper case
		 s sql=$zu(28,sql,5)
		 ; If this was embedded SQL we need to remove the DECLARE and the INTO
		 s:sql["CURSOR FOR" sql=$P(sql,"CURSOR FOR",2)
		 s:sql[" INTO " sql=$P(sql," INTO ",1)_" FROM "_$P(sql," FROM ",2)
		 ; call the Parse function to parameterize the query
		 i sql [ ":" s sql=..Parse(sql)
		 i sql'="" {
		 	set %tStatement = ##class(%SQL.Statement).%New()
	 	 	set %tStatus = %tStatement.%Prepare(sql)
	 	 	if $$$ISERR(%tStatus) w:Display=1 !,"Error preparing SQL Statement:  ",$SYSTEM.OBJ.DisplayError(%tStatus) CONTINUE
 			s SQLStats("Stime")=$ZH
 			s SQLStats("Sline")=$ZU(67,8,$j)
 			s SQLStats("Sglo")=$$$GlobalRefs
 			x execute
 			
 			; calculate time to first row
 			d %tResult.%Next()
 			s SQLStats("Etime")=$ZH
 			s SQLStats("Eline")=$ZU(67,8,$j)
 			s SQLStats("Eglo")=$$$GlobalRefs
 			s FGlo=(SQLStats("Eglo")-SQLStats("Sglo"))
 			s FLines=(SQLStats("Eline")-SQLStats("Sline"))
 			s FTime=(SQLStats("Etime")-SQLStats("Stime"))
 			
 			i Display w !,!,?5,"Stats:"
 			i Display w !,?10,"Global Refs to First Row:  ",?45,FGlo
 			i Display w !,?10,"Lines Executed to get First Row:  ",?45,FLines
 			i Display w !,?10,"Time to First Row: ",?45,FTime
 			
 			;Calculate time to last row
	 	 	if %tResult.%SQLCODE '< 0 {
				While %tResult.%Next() {}
	 	 	}
	 	 	s SQLStats("Etime")=$ZH
 			s SQLStats("Eline")=$ZU(67,8,$j)
 			s SQLStats("Eglo")=$$$GlobalRefs
 			s Glo=(SQLStats("Eglo")-SQLStats("Sglo"))
 			s Lines=(SQLStats("Eline")-SQLStats("Sline"))
 			s Time=(SQLStats("Etime")-SQLStats("Stime"))
 			s RowCount=%tResult.%ROWCOUNT
			i Display w !,!,?5,"Stats:"
 			i Display w !,?10,"Total Global Refs:  ",?45,Glo
 			i Display w !,?10,"Total Lines Executed:  ",?45,Lines
 			i Display w !,?10,"Total Time to Last Row: ",?45,Time
 			i Display w !,?10,"Rows Returned:  ",?45, RowCount
 			i Display w !,!,!
 			&SQL(INSERT %NOCHECK %NOLOCK INTO %SYS_PTools.SQLBenchMarkResults 
 			(QueryId,Run,StartTS,FRGlobalRefs,GlobalRefs,FRLines,Lines,FRRunTime,RunTime,Rowcount) 
 			VALUES (:Pid,:Run,:StartTS,:FGlo,:Glo,:FLines,:Lines,:FTime,:Time,:RowCount))
		 }
	 }
	 set:SQLCODE<0 status=$$$ADDSC(status,$$$ERROR($$$SQLError,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%apiSQL(SQLCODE))))
	 THROW:$$$ISERR(status)
 }
 
 Catch exception {
	set:status=$$$OK status=$$$ERROR($$$ObjectScriptError,$ze)
 }
 
 if query1OPEN {
 	&SQL(CLOSE query1)
 	set:SQLCODE<0 status=$$$ADDSC(status,$$$ERROR($$$SQLError,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%apiSQL(SQLCODE))))
 }
 s SQLStats=$SYSTEM.SQL.SetSQLStats(SQLStats)
 s NameSpace=$ZU(5,currentNS)
 
 QUIT status
}

ClassMethod Parse(sql) As %String
{
	s sql(1)=sql,sql=1
	s sc=$$dynamic^%qaqpreparser(.sql,.psql,.args)
	if sc'=0 QUIT ""
	QUIT psql
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// 
/// Method:       clearSQLBenchMarkQry [SQL: PT_clearSQLBenchMarkQry]
/// Replaced BY:  N/A
/// Status:       New Functionality
/// Purpose:      Delete all of the data stored in the '%SYS.PTools.SQLBenchMarkQueries' 
///               class, based on the specified parameters...
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLBenchMarkQueries).clearSQLBenchMarkQry(...)
///                           SQL: CALL %SYS_PTools.PT_clearSQLBenchMarkQry(...)
///                                SELECT %SYS_PTools.PT_clearSQLBenchMarkQry(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Delete all of the data stored in the '%SYS.PTools.SQLBenchMarkQueries' 
///               class in the 'SAMPLES' namespace:
/// 
///               set stats=##class(%SYS.PTools.SQLBenchMarkQueries).clearSQLBenchMarkQry("SAMPLES")
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","Bench","Queries","{D|I|C|S}")
/// 
/// Parameters:
///   ns          - The namespace in which to clear SQL Statistics
///                 If none provided, use the current namespaces where SQL Stats collected
///                    [DEFAULT: Current Namespace]
///   rtn         - The routine for which to clear SQL Statistics
///                 If none provided, clear all routines in the given 'ns'
///                    [OPTIONAL]
///   ph3         - Placeholder Parameter for future extensibility
///   clearAll    - 0 = Perform a normal clear, but leave the 'INFO' rows
///                 1 = Clear everything including the 'INFO' rows
///                    [DEFAULT: 0]
///   clearErrs   - 0 = Don't delete the 'PTools' Application Errors
///                 1 = Delete all of the 'PTools' Application Errors
///                    [DEFAULT: 0]
///   returnType  - 0 = Return a %Status code of either $$$OK or $$$ERROR()
///                 1 = Return the number of Stats rows deleted from the 
///                     following class: %SYS.PTools.SQLBenchMarkQueries
///                    [DEFAULT: 0]
///   ptInfo      - A Pass By Reference information array that returns
///                 detailed information to the user in the following format:
///                    ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                 Where category = { "cnt" | "curr" | "term" | ... }
///                       variable = A var corresponding to the given 'category'
/// 
///                 Example:
///                    ptInfo("cnt","clearSQLBenchMarkQry")=The number of rows deleted
///                                                         via this method [Routine Method]
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the number of Stats rows deleted from the following class; 
///               Otherwise, return an error message if an error occurred:
///                  %SYS.PTools.SQLBenchMarkQueries
/// </p>
ClassMethod clearSQLBenchMarkQry(ns As %String = "", rtn As %String = "", ph3 As %Integer = 0, clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ Deprecated, SqlName = PT_clearSQLBenchMarkQry, SqlProc ]
{
	QUIT $$clearSQLBenchMarkQry^%SYS.PToolsDEP(ns,rtn,ph3,clearErrs,returnType,.ptInfo)		// MRP963  [DEPRECATED]
}

/// This method is called to remove SQL Benchmark Stats data from the following
/// two classes:
///    - <class>%SYS.PTools.SQLBenchMarkQueries</class>
///    - <class>%SYS.PTools.SQLBenchMarkResults</class>
/// 
/// Backward-compatible Entry Point:
///    NOTE: For additional details, see the following methods in their respective
///          aforementioned classes:
///             - <method>clearSQLBenchMarkQry</method>
///             - <method>clearSQLBenchMarkRslt</method>
ClassMethod Purge(ns As %String = "", rtn As %String = "", ph3 As %Integer = 0, clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PurgeBench, SqlProc ]
{
	QUIT $$PurgeBench^%SYS.PToolsDEP(ns,rtn,ph3,clearErrs,returnType,.ptInfo)		// MRP963  [DEPRECATED]
}

/// Perform the OnDelete Trigger operations for this class...
ClassMethod TriggerOnDelete(timing)
{
    #; --- If no more data rows exist, delete the ID/Data Counter global ---
    if '$$$existsSYSPToolsSQLBenchMarkQryData {
    	$$$killSYSPToolsSQLBenchMarkQryData
    }
}

Trigger OnDelete [ Event = DELETE, Time = AFTER ]
{
	do ..TriggerOnDelete("AFTER")
}

Storage Default
{
<CounterLocation>^%sqlcq($NAMESPACE,"PTools","Bench","Queries","C")</CounterLocation>
<Data name="PValues">
<Attribute>PValues</Attribute>
<Structure>subnode</Structure>
<Subscript>"PValues"</Subscript>
</Data>
<Data name="SQLBenchMarkQueriesDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>QueryText</Value>
</Value>
<Value name="3">
<Value>NameSpace</Value>
</Value>
<Value name="4">
<Value>RunTime</Value>
</Value>
<Value name="5">
<Value>JobNumber</Value>
</Value>
<Value name="6">
<Value>SQLIndexHash</Value>
</Value>
</Data>
<DataLocation>^%sqlcq($NAMESPACE,"PTools","Bench","Queries","D")</DataLocation>
<DefaultData>SQLBenchMarkQueriesDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%sqlcq($NAMESPACE,"PTools","Bench","Queries","D")</IdLocation>
<IndexLocation>^%sqlcq($NAMESPACE,"PTools","Bench","Queries","I")</IndexLocation>
<StreamLocation>^%sqlcq($NAMESPACE,"PTools","Bench","Queries","S")</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
