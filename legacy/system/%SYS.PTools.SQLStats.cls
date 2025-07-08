/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %SYS.PTools.Stats

/// <style type="text/css"> 
///    DEP { color: red; font-weight: bold; }
///    BC { color: green; font-weight: bold; }
///    STUB { color: DarkGoldenRod ; }
///    .dep-head { color: red; white-space: pre; font-family:  'Courier New'; }
///    .info-head { white-space: pre; font-family: 'Courier New'; }
/// </style>
/// 
/// <p class="dep-head">
/// <b> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </b>
/// 
/// Starting with ver '2.0' of the PTools application, this class is considered
/// to be DEPRECATED and is replaced by the <class>%SYS.PTools.StatsSQL</class> class.
/// 
/// This class is still usable under extreme circumstances when invoking the 
/// 'SetSQLStatsSaveFlag()' method and passing to the (saveType) parameter the
/// following value: 
///    2 = Original (backward-compatible)
/// 
/// <b> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </b>
/// </p>
/// 
/// <p class="info-head">
/// Class:        %SYS.PTools.SQLStats
/// Replaced By:  <class>%SYS.PTools.StatsSQL</class>
/// Purpose:      
///    This class can be used to collect statistical information on SQL queries 
///    run on a give InterSystems IRIS system.
/// 
///    The modules can be nested in one another. The outer module will display 
///    inclusive numbers, so the Module MAIN will be the overall results for the 
///    full query. 
/// 
///    Upon first enabling SQLStats, you should Purge cached queries in order to 
///    force code regeneration.  The following commands demonstrate how to
///    perform these tasks:
/// 
///       >DO $SYSTEM.SQL.Purge()
///       >DO $SYSTEM.SQL.SetSQLStatsJob(3)
/// 
/// <i>      NOTE: To see the definition and details on how to use these methods, 
///             either view this information in the <b>Class Reference</b>
///             documentation for the <class>%SYSTEM.SQL</class> class, or review
///             the help via the following method invocations:
///             
///                >DO $SYSTEM.SQL.Help("Purge")
///                >DO $SYSTEM.SQL.Help("SetSQLStatsJob")                          </i> 
/// 
///    When you're finished collectinging statistics, disable SQLStats by using the 
///    following command: 
/// 
///       >DO $SYSTEM.SQL.SetSQLStatsJob(0) 
/// 
/// <i>      NOTE: There is no need to Purge cached queries after disabling 
///             SQLStats, because the small number of additional code-lines
///             generated should not affect query performance.                     </i>
/// 
///    All of the PTools statistical and query informational data is stored in 
///    the <class>%SYS.PTools.SQLQuery</class> and '%SYS.PTools.SQLStats' classes.  The
///    <class>%SYS.PTools.SQLQuery</class> class holds the text of the SQL Statement, 
///    the routine name, and the module information.  The '%SYS.PTools.SQLStats' 
///    class, on the other hand, holds the statistical details for each run. You 
///    can query these tables from any directory on the system, or use xDBC to
///    view this information. 
///  
///    The view, <query>SQLStatsView</query>, has been defined to make looking at 
///    the pertinent data in these classes easier.
/// 
///    For Example:
/// 
///       <example>
///       #INCLUDE %msql
///       &SQL(DECLARE cur1 CURSOR FOR
///            SELECT RoutineName, ModuleName, ModuleCount, GlobalRefs, DiskWait
///                   LinesOfCode, TimeSpent, RowCount, QueryType, QueryText 
///            FROM %SYS_PTools.SQLStatsView 
///            WHERE Namespace= 'SAMPLES'
///           )
/// 
///       &SQL(OPEN cur1)
///       for  &SQL(FETCH cur1 INTO :A,:B,:C,:D,:E,:F,:G,:H,:I) QUIT:SQLCODE'=0  WRITE !,A,"  ",B,"  ",C,"  ",D,"  ",E,"  ",F,"  ",G,"  ",H,"  ",I
///       &SQL(CLOSE cur1)
///       </example>
/// </p>
/// <p class="info-head">
///    or for a more condensed output:
/// 
///       <example>
///       #INCLUDE %msql
///       &SQL(DECLARE cur2 CURSOR FOR
///            SELECT V.RoutineName, V.QueryText,
///                   (SELECT COUNT(*) 
///                    FROM %SYS_PTools.SQLStatsView Sub
///                    WHERE Sub.ModuleName = 'Main' AND Sub.RoutineName = V.RoutineName 
///                    GROUP BY Sub.CursorName, Sub.ModuleName
///                   ) as RunCount, 
///                   {fn round(avg(V.RowCount),2)} as AvgRows,  
///                   {fn round(avg(V.GlobalRefs),2)} as AvgGlorefs,    
///                   {fn round(avg(V.LinesOfCode),2)} as AvgLines, 
///                   {fn round(avg(V.DiskWait),2)} as AvgDiskWait,  
///                   {fn round(avg(V.TimeSpent),5)} as AvgTime 
///            FROM %SYS_PTools.SQLStatsView V
///            GROUP BY V.RoutineName, V.CursorName
///           )
/// 
///       &SQL(OPEN cur2)
///       For  &SQL(FETCH cur2 INTO :A,:B,:C,:D,:E,:F,:G) QUIT:SQLCODE'=0  WRITE !,A,"  ",B,"  ",C,"  ",D,"  ",E,"  ",F,"  ",G
///       &SQL(CLOSE cur2)
///       </example>
/// </p>
/// <p class="info-head">
///    Error Storage: ^%sqlcq($NAMESPACE,"PTools","Error"[...])=$LIST Info
/// </p>
Class %SYS.PTools.SQLStats Extends (%Persistent, %SYS.PTools.Stats) [ CompileAfter = %SYS.PTools.SQLQuery, Deprecated, Inheritance = right, System = 4 ]
{

Relationship SQLQueryPointer As %SYS.PTools.SQLQuery [ Cardinality = parent, Inverse = SQLStatsPointer ];

/// This is the number of times the query has been run since the last compile.
Property Counter As %Integer [ SqlColumnNumber = 5 ];

Property ChildSub As %Integer [ InitialExpression = {$$$bumpSYSPToolsSQLStatsChildSub} ];

Index MasterIndex On (Counter, ChildSub) [ IdKey, Unique ];

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// 
/// Method:       Init [SQL: N/A]
/// Replaced By:  startSQLStats^%SYS.PTools()
/// Status:       <DEP>[DEPRECATED]</DEP>
/// Purpose:      Invoked by the OPEN Cursor to initializes local variables
///               and calles Start() for the MAIN loop to start collecting stats
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","RunTime","SQLStats{C|D|I|S|Z}")
/// </p>
ClassMethod Init(NS As %String, Rou As %String, Cur As %String, ByRef Parms As %RawString) [ Deprecated ]
{
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       Start [SQL: N/A]
/// Replaced By:  %statsStart^%SYS.PTools()
/// Status:       <DEP>[DEPRECATED]</DEP>
/// Purpose:      Invoked every time you enter a module to collect statistics
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","RunTime","SQLStats{C|D|I|S|Z}")
/// -------------------------------------------------------------------------------
/// </p>
ClassMethod Start(NS As %String, Rou As %String, Cur As %String, ModString As %String) [ Deprecated ]
{
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       Stop [SQL: N/A]
/// Replaced By:  %statsStop^%SYS.PTools()
/// Status:       <DEP>[DEPRECATED]</DEP>
/// Purpose:      Invoked every time you exit a module to collect statistics
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","RunTime","SQLStats{C|D|I|S|Z}")
/// </p>
ClassMethod Stop(NS As %String, Rou As %String, Cur As %String, ModString As %String) [ Deprecated ]
{
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       Report [SQL: N/A]
/// Replaced By:  stopSQLStats^%SYS.PTools()
/// Status:       <DEP>[DEPRECATED]</DEP>
/// Purpose:      Invoked by the CLOSE Cursor to tidy up statistics collection
///               OR <class>%SYS.PTools.StatsSQL</class> table
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","RunTime","SQLStats{C|D|I|S|Z}")
/// </p>
ClassMethod Report(NS As %String, Rou As %String, Cur As %String, RowCount As %Integer = 0) As %String [ Deprecated ]
{
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       GlobalSave [SQL: N/A]
/// Replaced By:  saveSQLStats^%SYS.PTools()
/// Status:       <DEP>[DEPRECATED]</DEP>
/// Purpose:      Invoked by the Report() method to store all of the runtime data 
///               in the '%SYS.PTools.SQLStats' OR <class>%SYS.PTools.StatsSQL</class> table
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","RunTime","SQLStats{C|D|I|S|Z}")
/// </p>
ClassMethod GlobalSave(ns, rou, cur, mod, rows) [ Deprecated ]
{
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       GetStats [SQL: N/A]
/// Replaced By:  GetStats (<class>%SYS.PTools.StatsSQL</class>)
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// Purpose:      Returns the Stats for a given module of a given SQL statement 
///               Invoked by the Show Plan code when Stats are to be included
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).GetStats(...)
///                    SQL: N/A
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Get the stats for the 'MAIN' module of the following
///               SQL Statement from the 'SAMPLES' namespace:
/// 
///               zn "SAMPLES"
///               kill sql set sql($i(sql))="SELECT ID, Name FROM Sample.Person"
///               set statsList=##class(%SYS.PTools.StatsSQL).GetStats(.sql,"MAIN",1)
/// 
///               for pos=1:1:$LL(statsList) write !?3,$LTS($LG(statsList,pos))
///                  ModuleName,Module,MAIN
///                  TimeSpent,Time,0.00999
///                  GlobalRefs,Globals,1,201
///                  LinesOfCode,Commands,41,311
///                  DiskWait,Disk Wait,1
///                  RowCount,Row Count,400
///                  ModuleCount,Mod Execs,1
///                  Counter,Run Count,1
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","RunTime","SQLStats{C|D|I|S|Z}")
/// 
/// Parameters:
///   SQLText      - An array of the SQL Statement in the following format:
///                     SQLText={ln# counter}
///                     SQLText({ln#})={SQL Statement}
///   mod          - SQL Module being processed
///   showStats    - 0 = Don't show any stats with the query plan
///                  1 = Execute a query and get/show stats with the query plan
///                       [FROM: Query Test or ShowPlan^%apiSQL]
///                  2 = Retrieve existing stats and show the averages with the 
///                      query plan
///                         [NOTE: Query Info from ^mqh($UserName,"id") set in
///                                ##class(%CSP.UI.Portal.SQL.QButtons.RuntimeStats).PrepareShowPlan(...)
///                         [FROM: SQL Runtime Statistics->{View Stats}->Show Plan]
///                  3 = Generate and show stats for an alternate Show Plan with 
///                      the query plan
/// 
/// RETURN Value: Query Stats as a $LIST with the following format:
///               1) $LIST({Property},{Header},{Value})
///                       ...
///               n) $LIST({Property},{Header},{Value})
/// </p>
ClassMethod GetStats(ByRef SQLText As %String = 0, mod As %String, showStats As %Integer = 0) As %String [ Deprecated ]
{
	QUIT $$GetStats^%SYS.PTools(.SQLText,mod,showStats)
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       SetSQLStats [SQL: SetSQLStats]
/// Replaced By:  SetSQLStats [SQL: StatsSQL_SetSQLStats]  (<class>%SYS.PTools.StatsSQL</class>)
/// Status:       <BC>New functionality added for Backward-Compatibility</BC>
/// Purpose:      This method sets the flag that controls whether or not the 
///               System collects SQL Statistics about each run of a query
/// 
///               You can invoke different levels of SQL Statistics collection by 
///               setting the SQLStats-flag, for the System with this method.
/// 
///               The SQLStats-flag controls whether or not SQL Statistics are 
///               collected for each SQL Query execution, and which performance 
///               statistics to collect.
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLStats).SetSQLStats(...)
///                    SQL: SELECT %SYS_PTools.SetSQLStats(...)
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Turn PTools ON to collects stats for all SQL modules (System):
/// 
///               set oldStats=##class(%SYS.PTools.SQLStats).SetSQLStats(3)
/// 
/// Data Storage: N/A
/// 
/// Parameters:
///    actionFlag       - This parameter can have one of the following values:
///                          0 = Query Compilation: Don't generator SQLStats collection 
///                                                 code for any Query Modules
///                              Query Execution:   Don't collect SQLStats for any Query 
///                                                 Modules
///                          1 = Query Compilation: Generator SQLStats collection code for 
///                                                 MAIN Query Module (Start & Stop)
///                              Query Execution:   Don't collect SQLStats for any Query 
///                                                 Modules
///                          2 = Query Compilation: Generator SQLStats collection code for 
///                                                 MAIN Query Module (Start & Stop)
///                              Query Execution:   Collect SQLStats for MAIN Query Module 
///                                                 (Start & Stop)
///                          3 = Query Compilation: Generator SQLStats collection code for 
///                                                 ALL Query Modules
///                              Query Execution:   Collect SQLStats for ALL Query Modules
///    
/// RETURN Value: The value of the SQLStats-flag before setting it to the new value;
///               Otherwise, return an error message if an error occurred
/// </p>
ClassMethod SetSQLStats(actionFlag As %Integer = 0) As %Integer [ Deprecated, SqlName = SetSQLStats, SqlProc ]
{
	QUIT $$SetSQLStatsFlag^%SYS.PToolsUtil(0,actionFlag,1)
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       SetSQLStatsJob [SQL: SetSQLStatsJob]
/// Replaced By:  SetSQLStatsJob [SQL: StatsSQL_SetSQLStatsJob]  (<class>%SYS.PTools.StatsSQL</class>)
///               SetSQLStatsFlagJob [SQL: StatsSQL_SetSQLStatsFlagJob]  (<class>%SYS.PTools.StatsSQL</class>)
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// Purpose:      This method sets the flag that controls whether or not this 
///               Process/Job collects SQL Statistics about each run of a query
/// 
///               You can invoke different levels of SQL Statistics collection by 
///               setting the SQLStats-flag, for your current process/job with this
///               method.
/// 
///               The SQLStats-flag controls whether or not SQL Statistics are 
///               collected for each SQL Query execution, and which performance 
///               statistics to collect.
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLStats).SetSQLStatsJob(...)
///                    SQL: SELECT %SYS_PTools.SetSQLStatsJob(...)
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Turn PTools ON to collects stats for all SQL modules:
/// 
///               set oldStats=##class(%SYS.PTools.SQLStats).SetSQLStatsJob(3)
/// 
/// Data Storage: N/A
/// 
/// Parameters:
///    actionFlag       - This parameter can have one of the following values:
///                         -1 = Query Compilation: Turn SQLStats Off for this Job
///                              Query Execution:   Turn SQLStats Off for this Job
///                          0 = Query Compilation: Don't generator SQLStats collection 
///                                                 code for any Query Modules
///                              Query Execution:   Don't collect SQLStats for any Query 
///                                                 Modules
///                          1 = Query Compilation: Generator SQLStats collection code for 
///                                                 MAIN Query Module (Start & Stop)
///                              Query Execution:   Don't collect SQLStats for any Query 
///                                                 Modules
///                          2 = Query Compilation: Generator SQLStats collection code for 
///                                                 MAIN Query Module (Start & Stop)
///                              Query Execution:   Collect SQLStats for MAIN Query Module 
///                                                 (Start & Stop)
///                          3 = Query Compilation: Generator SQLStats collection code for 
///                                                 ALL Query Modules
///                              Query Execution:   Collect SQLStats for ALL Query Modules
///    
/// RETURN Value: The value of the SQLStats-flag before setting it to the new value;
///               Otherwise, return an error message if an error occurred
/// </p>
ClassMethod SetSQLStatsJob(actionFlag As %Integer = 0) As %Integer [ Deprecated, SqlName = SetSQLStatsJob, SqlProc ]
{
	QUIT $$SetSQLStatsFlag^%SYS.PToolsUtil(1,actionFlag,1)
}

/// <STUB>Stub:    For the 'newSQLStats()' method in the '%SYS.PTools.MAC' routine</STUB>
ClassMethod newSQLStats(SQLText, SQLType, ns, rtn, curs, compTime = 0, SQLIndexHash = "")
{
	do newSQLStats^%SYS.PTools(SQLText, SQLType, ns, rtn, curs, compTime, SQLIndexHash)
}

/// <STUB>Stub:    For the 'startSQLStats()' method in the '%SYS.PTools.MAC' routine</STUB>
ClassMethod startSQLStats(ns, rtn, curs, params, SQLIndexHash, flag, collect)
{
	do startSQLStats^%SYS.PTools(ns, rtn, curs, params, SQLIndexHash, flag, collect)
}

/// <STUB>Stub:    For the 'stopSQLStats()' method in the '%SYS.PTools.MAC' routine</STUB>
ClassMethod stopSQLStats(ns, rtn, curs, rowCount = 0, SQLIndexHash, flag, collect)
{
	do stopSQLStats^%SYS.PTools(ns, rtn, curs, rowCount, SQLIndexHash, flag, collect)
}

/// <STUB>Stub:    For the 'saveSQLStats()' method in the '%SYS.PTools.MAC' routine</STUB>
ClassMethod saveSQLStats(ns, rtn, curs, mod, rowCount, SQLIndexHash)
{
	do saveSQLStats^%SYS.PTools(ns, rtn, curs, mod, rowCount, SQLIndexHash)
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       ExportAll [SQL: SQLStats_ExportAll]
/// Replaced By:  ExportAll [SQL: StatsSQL_ExportAll]  (<class>%SYS.PTools.StatsSQL</class>)
/// Status:       <BC>Maintained for Backward-Compatibility.</BC>  See exportSQLStats(...)
/// Purpose:      This method generates two Performance Tool files containing 
///               the data from both the '%SYS.PTools.SQLQuery' & '%SYS.PTools.SQLStats' 
///               classes & return a $LIST of the output locations
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLStats).ExportAll(...)
///                    SQL: CALL %SYS_PTools.SQLStats_ExportAll(...)
///                         SELECT %SYS_PTools.SQLStats_ExportAll(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Display this export file to the screen via a InterSystems IRIS Terminal:
///               set io=##class(%SYS.PTools.SQLStats).ExportAll($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
///               CALL %SYS_PTools.SQLStats_ExportAll('$IO')
/// 
///               Where: '$IO' = Output to the current device
///                              NOTE: '$IO' can be omitted, as it is the default
///                                    'file' when invoked via the CALL interface
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","RunTime","SQLStats{C|D|I|S|Z}")
/// 
/// Parameters:
///   filePrefix - The path in which to create and store the data from the 
///                '%SYS.PTools.SQLQuery' & '%SYS.PTools.SQLStats' classes (e.g. C:\)   
///                NOTE:    $IO = Outputs the data to the screen
///                       '$IO' = Output the data to the current device when invoked from the CALL/SELECT-interface
///                      '$DEF' = Ouput the data to the DEFAULT file when invoked from the CALL/SELECT-interface
///                   [DEFAULT: {Current-Directory}\SQLQuery.{ext} & {Current-Directory}\StatsSQL.{ext}]
///                WHERE {Current-Directory} = The directory of the Namespace in which
///                                            this method is invoked (e.g. $ZU(12,""))
///   delim      - The delimiter by which to delimit the data of the exported file
///                   [DEFAULT: $C(9)  // TAB]
///   exportPlan -  0 - Export the SQL Query Text
///                 1 - Export the SQL Query Plan
///                   [DEFAULT: 0]
///   silent     -  0 - Display all messages during the running of this method
///                 1 - Don't display any messages during the running of this method
///   rtnName    - If specified, return only the rows where the 'RoutineName' matches
///                the value of this parameter; Otherwise, return rows for all 'RoutineName' values
///   modName    - If specified, return only the rows where the 'ModuleName' matches
///                the value of this parameter; Otherwise, return rows for all 'ModuleName' values
///   conds      - A string/array of possible conditions by which to restrict the
///                output of the Export file, in the following format:
/// 
///                   conds=<full condition>
///                       OR
///                   conds(0)=pos Count (WHERE pos = {1...n})
///                   conds(pos)=$LIST() Pieces:
///                                 1) [<logical operator>]  (Assumed Default: &&)
///                                 2) [{Heading}]           (Omit for override cond)
///                                 3) <simple condition> | <complex condition>
/// 
///                   WHERE:
///                      <full condition>       := <full condition expression>
///                      <logical operator>     := {&& | ||}  (&& = AND | || = OR)
///                      <simple condition>@*   := <oper><value expression>
///                      <complex condition>@   := <complex condition expression>
/// 
///                     @ = Contains no references to {Heading}
///                     * = Contains no references to {*}
/// 
///                   EXAMPLE:
///                      <full condition>
///                         conds="("",INFO,MAIN,""[("",""_{Module}_"",""))||({GlobalRefs}>20)"
///                      <simple condition>
///                         conds(0)=3
///                         conds(1)=$LB(,"Module","=""INFO""")
///                         conds(2)=$LB("||","Module","=""MAIN""")
///                         conds(3)=$LB("||","GlobalRefs",">20")
///                      <complex condition>
///                         conds(0)=2
///                         conds(1)=$LB(,"Module",""",INFO,MAIN,""[("",""_{*}_"","")")
///                         conds(2)=$LB("||","GlobalRefs","{*}>20")
///                            WHERE: {*} = value substitution for the 'Module' & 'GlobalRefs' fields
///                            NOTE: Conditions that don't contain any references to
///                                  {Heading} fields, often called <override condition>s,
///                                  can be included as <complex condition>s, as in
///                                  the following example:
///                                     conds(pos)=$LB(,,"$g(^zAction(""runIt""))=1") 
/// 
///                   NOTE: All conditions must be satisfied for the conds() to
///                         be considered true and for the row to be exported
///                   [PASS BY REFERENCE]
///   ptInfo     - A Pass By Reference information array that returns to the user 
///                the following details:
///                   ptInfo(method,variable)=value
///                   ptInfo(method,"outputFile")=The canonical name of the Export/Reporting file
/// 
/// RETURN Value: A $LIST of the output locations of the exported data; Otherwise, 
///               return the error status if one occurred
///                  $LB(filePrefix_"SQLStats_Qry.txt",filePrefix_"SQLStats_Stats.txt")
/// </p>
ClassMethod ExportAll(filePrefix = "", delim = "", exportPlan = 0, silent = 0, rtnName = "", modName = "", ByRef conds As %RawString, ByRef ptInfo As %RawString) As %String [ Deprecated, SqlName = SQLStats_ExportAll, SqlProc ]
{
	set:delim="" delim=$C(9)	// Tab-Delimited
 	set filePrefix=$s($$$UPPER(filePrefix)="$IO":$IO,(filePrefix="")&&$ISOBJECT($g(%request)):$IO,",$DEF,,"[(","_$$$UPPER(filePrefix)_","):$$$currentDir,1:filePrefix)
	set dlm=$s(filePrefix["/":"/",1:"\")
	//MRP1093+ set:($e(filePrefix,*)'=dlm)&&(filePrefix'=$IO) filePrefix=filePrefix_dlm
	set SQLQueryFile=$s(filePrefix=$IO:$IO,1:filePrefix_"SQLStats_Qry.txt")
	if (filePrefix=$IO)&&$ISOBJECT($g(%request)) { set format="H" }
	else { set format="Z",format(0)=delim }
	if exportPlan=0 { 
		write:'silent !,"Exporting SQL Querys to ",$s(SQLQueryFile=$IO:"(Terminal IO)",1:SQLQueryFile)
	}
	else  { 
		write:'silent !,"Exporting SQL Query Plans to ",$s(SQLQueryFile=$IO:"(Terminal IO)",1:SQLQueryFile)
	}
	set tSC=##class(%SYS.PTools.SQLQuery).exportSQLQuery(SQLQueryFile,.format,silent,exportPlan,.conds,.ptInfoSQ,"SQLStats.ExportAll")
	set SQLQueryFile=$s($$$ISERR(tSC):tSC,1:$g(ptInfoSQ("outputFile")))
	merge ptInfo("exportSQLQuery")=ptInfoSQ  // Record 'ptInfo()' from 'exportSQLQuery()' method invocation
	
	set SQLStatsFile=$s(filePrefix=$IO:$IO,1:filePrefix_"SQLStats_Stats.txt")
	write:'silent !!,"Exporting SQL Stats to ",$s(SQLStatsFile=$IO:"(Terminal IO)",1:SQLStatsFile)
	set tSC=..exportSQLStats(SQLStatsFile,.format,silent,rtnName,modName,.conds,.ptInfoSS,"SQLStats.ExportAll")
	set SQLStatsFile=$s($$$ISERR(tSC):tSC,1:$g(ptInfoSS("outputFile")))
	merge ptInfo("exportSQLStats")=ptInfoSS  // Record 'ptInfo()' from 'exportSQLStats()' method invocation
	
	QUIT $LB(SQLQueryFile,SQLStatsFile)
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       Export [SQL: SQLStats_Export]
/// Replaces By:  Export [SQL: StatsSQL_Export]  (<class>%SYS.PTools.StatsSQL</class>)
/// Status:       <BC>Maintained for Backward-Compatibility.</BC>  See exportSQLStats(...)
/// Purpose:      This method generates a delimited file containing the data
///               from the '%SYS.PTools.SQLStats' class
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLStats).Export(...)
///                    SQL: CALL %SYS_PTools.SQLStats_Export(...)
///                         SELECT %SYS_PTools.SQLStats_Export(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Display this export file to the screen via a InterSystems IRIS Terminal:
///               set io=##class(%SYS.PTools.SQLStats).Export($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
///               CALL %SYS_PTools.SQLStats_Export('$IO')
/// 
///               Where: '$IO' = Output to the current device
///                              NOTE: '$IO' can be omitted, as it is the default
///                                    'file' when invoked via the CALL interface
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","RunTime","SQLStats{C|D|I|S|Z}")
/// 
/// Parameters:
///   file       - The path and file in which to create and store the data from the 
///                %SYS.PTools.SQLStats class:  (e.g. C:\exportFile.txt)
///                NOTE:    $IO = Outputs the data to the screen
///                       '$IO' = Output the data to the current device when invoked from the CALL/SELECT-interface
///                      '$DEF' = Ouput the data to the DEFAULT file when invoked from the CALL/SELECT-interface
///                   [DEFAULT: {MGR-Directory}\{computerName}_{ConfigName}_YYYYMMDD_HHMMSS_StatsSQL.psql]
///   delim      - The delimiter by which to delimit the data of the exported file
///                   [DEFAULT: $C(9)  // TAB]
///   conds      - A string/array of possible conditions by which to restrict the
///                output of the Export file, in the following format:
/// 
///                   conds=<full condition>
///                       OR
///                   conds(0)=pos Count (WHERE pos = {1...n})
///                   conds(pos)=$LIST() Pieces:
///                                 1) [<logical operator>]  (Assumed Default: &&)
///                                 2) [{Heading}]           (Omit for override cond)
///                                 3) <simple condition> | <complex condition>
/// 
///                   WHERE:
///                      <full condition>       := <full condition expression>
///                      <logical operator>     := {&& | ||}  (&& = AND | || = OR)
///                      <simple condition>@*   := <oper><value expression>
///                      <complex condition>@   := <complex condition expression>
/// 
///                     @ = Contains no references to {Heading}
///                     * = Contains no references to {*}
/// 
///                   EXAMPLE:
///                      <full condition>
///                         conds="("",INFO,MAIN,""[("",""_{Module}_"",""))||({GlobalRefs}>20)"
///                      <simple condition>
///                         conds(0)=3
///                         conds(1)=$LB(,"Module","=""INFO""")
///                         conds(2)=$LB("||","Module","=""MAIN""")
///                         conds(3)=$LB("||","GlobalRefs",">20")
///                      <complex condition>
///                         conds(0)=2
///                         conds(1)=$LB(,"Module",""",INFO,MAIN,""[("",""_{*}_"","")")
///                         conds(2)=$LB("||","GlobalRefs","{*}>20")
///                            WHERE: {*} = value substitution for the 'Module' & 'GlobalRefs' fields
///                            NOTE: Conditions that don't contain any references to
///                                  {Heading} fields, often called <override condition>s,
///                                  can be included as <complex condition>s, as in
///                                  the following example:
///                                     conds(pos)=$LB(,,"$g(^zAction(""runIt""))=1") 
/// 
///                   NOTE: All conditions must be satisfied for the conds() to
///                         be considered true and for the row to be exported
///                   [PASS BY REFERENCE]
///   ptInfo     - A Pass By Reference information array that returns to the user 
///                the following details:
///                   ptInfo(variable)=value
///                   ptInfo("outputFile")=The canonical name of the Export/Reporting file
/// 
/// RETURN Value: The output locations of the exported data; Otherwise, return  
///               the error status if one occurred
/// </p>
ClassMethod Export(file = "", delim = "", ByRef conds As %RawString, ByRef ptInfo As %RawString) As %String [ Deprecated, SqlName = SQLStats_Export, SqlProc ]
{
	set:delim="" delim=$C(9)	// Tab-Delimited
	set logDir=$$$SYSMgrDir,hostName=$$$localHost,configName=$$$configurationName,hDate8=$zd($h,8),hTime=$tr($zt($p($h,",",2)),":","")
	set outputFileName=hostName_"_"_configName_"_"_hDate8_"_"_hTime_"_SQLStats.psql"
 	set file=$s($$$UPPER(file)="$IO":$IO,(file="")&&$ISOBJECT($g(%request)):$IO,",$DEF,,"[(","_$$$UPPER(file)_","):$$$currentDir,1:file)
	set outputFile=$s(file="":logDir_outputFileName,1:file)
	if (outputFile=$IO)&&$ISOBJECT($g(%request)) { set format="H" }
	else { set format="Z",format(0)=delim }
	
	set tSC=..exportSQLStats(outputFile,.format,1,,,.conds,.ptInfo,"SQLStats.Export")
	
	QUIT $s($$$ISERR(tSC):tSC,1:$g(ptInfo("outputFile")))
}

/// <p class="info-head">
/// Method:       exportSQLStats [SQL: PT_exportSQLStats]
/// Replaces:     ExportAll [SQL: SQLStats_ExportAll] & Export [SQL: SQLStats_Export]  <DEP>[DEPRECATED]</DEP>
/// Replaced By:  exportStatsSQL [SQL: PT_exportStatsSQL]  (<class>%SYS.PTools.StatsSQL</class>)
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      Create a Performance Tool file containing the data 
///               from the '%SYS.PTools.SQLStats' and return the output location...
///               By default, the file will be created in the current directory 
///               of the InterSystems IRIS instance.
/// 
///               NOTE: Current directory can be obtained in the following way, 
///                     from a InterSystems IRIS Terminal:
///                        >write $ZU(12,"")
/// 
///               You can pass a different value for the 'file' parameters if you 
///               wish to override the default location and file name.
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLStats).exportSQLStats(...)
///                    SQL: CALL %SYS_PTools.PT_exportSQLStats(...)
///                         SELECT %SYS_PTools.PT_exportSQLStats(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Display this export file to the screen via a InterSystems IRIS Terminal:
///               set tSC=##class(%SYS.PTools.SQLStats).exportSQLStats($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
///               CALL %SYS_PTools.PT_exportSQLStats('$IO','H')
/// 
///               Where: '$IO' = Output to the current device
///                              NOTE: '$IO' can be omitted, as it is the default
///                                    'file' when invoked via the CALL interface
///                       'H'  = Output the format in HTML format
///                              NOTE: 'H' can be omitted, as it is the default
///                                    'format' when invoked via the CALL interface
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","RunTime","SQLStats{C|D|I|S|Z}")
/// 
/// Parameters:
///   file      - The path and file in which to create and store the data from the
///               %SYS.PTools.SQLStats class:  (e.g. C:\exportFile.txt)
///               NOTE:    $IO = Outputs the data to the screen
///                      '$IO' = Output the data to the current device when invoked from the CALL/SELECT-interface
///                     '$DEF' = Ouput the data to the DEFAULT file when invoked from the CALL/SELECT-interface
///                  [DEFAULT: {Current-Directory}\PT_SQLStats_ExportSQLStats_YYYYMMDD_HHMMSS.{ext}]
///                WHERE {Current-Directory} = The directory of the Namespace in which
///                                            this method is invoked (e.g. $ZU(12,""))
///               NOTE 2: If Passed By Reference, then 'file' will be returned as the
///                       canonical name of the Export/Reporting file
///   format    - The output format of the Export/Reporting file
///               This parameter has the following structure of constituent elements:
///                  format=<data-format>[:$LB(<delim>,<csv-header>,<csv-footer>)]
///               Where the constituent elements have the following values:
///                  <data-format> - The format of the Export/Reporting file:
///                     - P = Printable/Viewable report file (.txt file, no pagination)
///                     - D = Comma-delimited data file (.csv file) which can be read into a spreadsheet
///                     - X = Microsoft Excel XML markup file suitable for import into Excel (.xml file)
///                     - H = HTML page file (.html file)
///                     - Z = User-defined delimiter "P" formatted file (.dlm file)
///                            NOTE: The <delim> element is required or defaulted to $C(9) (TAB)
///               Optional Elements:
///                  <delim> - User-defined delimiter  [DEFAULT: $C(9) (TAB)]
///                             NOTE: This is generally used for <data-format>="Z"
///                  <csv-header> - .csv file header for <data-format>="D":
///                     - 0 = Don't add non-standard information header to file  [DEFAULT]
///                     - 1 = Add non-standard information header to file
///                  <csv-footer> - .csv file footer for <data-format>="D":
///                     - 0 = Don't add non-standard information footer to file  [DEFAULT]
///                     - 1 = Add non-standard information footer to file
///               EXAMPLES:
///                  Valid 'format' values:
///                     - "H"             // HTML file
///                     - "D"             // CSV file with No information header or footer
///                     - "D:"_$LB(,1,1)  // CSV file with information header & footer
///                     - "Z:"_$LB("^")   // User-defined delimiter file (delim="^")
///   silent    -  0 - Display all messages during the running of this method
///                1 - Don't display any messages during the running of this method
///   rtnName   - If specified, return only the rows where the 'RoutineName' matches
///               the value of this parameter; Otherwise, return rows for all 'RoutineName' values
///   modName   - If specified, return only the rows where the 'ModuleName' matches
///               the value of this parameter; Otherwise, return rows for all 'ModuleName' values
///   conds     - A string/array of possible conditions by which to restrict the
///               output of the Export file, in the following format:
/// 
///                  conds=<full condition>
///                      OR
///                  conds(0)=pos Count (WHERE pos = {1...n})
///                  conds(pos)=$LIST() Pieces:
///                                1) [<logical operator>]  (Assumed Default: &&)
///                                2) [{Heading}]           (Omit for override cond)
///                                3) <simple condition> | <complex condition>
/// 
///                  WHERE:
///                     <full condition>       := <full condition expression>
///                     <logical operator>     := {&& | ||}  (&& = AND | || = OR)
///                     <simple condition>@*   := <oper><value expression>
///                     <complex condition>@   := <complex condition expression>
/// 
///                    @ = Contains no references to {Heading}
///                    * = Contains no references to {*}
/// 
///                  EXAMPLE:
///                     <full condition>
///                        conds="("",INFO,MAIN,""[("",""_{Module}_"",""))||({GlobalRefs}>20)"
///                     <simple condition>
///                        conds(0)=3
///                        conds(1)=$LB(,"Module","=""INFO""")
///                        conds(2)=$LB("||","Module","=""MAIN""")
///                        conds(3)=$LB("||","GlobalRefs",">20")
///                     <complex condition>
///                        conds(0)=2
///                        conds(1)=$LB(,"Module",""",INFO,MAIN,""[("",""_{*}_"","")")
///                        conds(2)=$LB("||","GlobalRefs","{*}>20")
///                           WHERE: {*} = value substitution for the 'Module' & 'GlobalRefs' fields
///                           NOTE: Conditions that don't contain any references to
///                                 {Heading} fields, often called <override condition>s,
///                                 can be included as <complex condition>s, as in
///                                 the following example:
///                                    conds(pos)=$LB(,,"$g(^zAction(""runIt""))=1") 
/// 
///                  NOTE: All conditions must be satisfied for the conds() to
///                        be considered true and for the row to be exported
///                  [PASS BY REFERENCE]
///   ptInfo    - A Pass By Reference information array that returns to the user 
///               the following details:
///                  ptInfo(variable)=value
///                  ptInfo("outputFile")=The canonical name of the Export/Reporting file
///   bcFlag    - This is a Backward-Compatibility flag used for 
///               [Internal Purposes ONLY]
/// 
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod exportSQLStats(file = "", format = "P", silent = 0, rtnName = "", modName = "", ByRef conds As %RawString, ByRef ptInfo As %RawString, bcFlag = "") As %Status [ Deprecated, PublicList = d, SqlName = PT_exportSQLStats, SqlProc ]
{
 	new %msg,%objlasterror
 	new d
 	
	set tSC=$$$OK,%msg="",SQLCODE="",outputFile=""
	set thisMethod="exportSQLStats"
	set start=$$$sysTimestamp

 try {

	$$$setSQLStatsFlagOFF(zu115x12)	// Turn off SQLState for current JOB
	
 	set className="SQLStats"
 	set version=$$$PTStatsVersion
	set format=$s(format="":$s($ISOBJECT($g(%request)):"H",1:"P"),("Pp"[$e(format,1))&&$ISOBJECT($g(%request)):"H"_$e(format,2,*),1:$$$UPPER($p(format,":",1))_$s(format[":":":"_$p(format,":",2,*),1:""))
	set ns=$NAMESPACE
	
	set outputFile=..getOutputFile(file,className,thisMethod,format,,.tSC) THROW:$$$ISERR(tSC)
 	
	if 'silent { USE 0 write !,"Creating '%SYS.PTools.SQLStats' Export...",!,?3,"Output File: ",$s(outputFile="":"(Terminal IO)",1:outputFile),!! }

 	if outputFile'="" { set tSC=..createAndOpenFile(outputFile) THROW:$$$ISERR(tSC) }
 	
 	// --- Table Column Definitions ---
 	#;--------------------------------------------------------------------------------
 	#;
 	#; d(0)=# of Columns
 	#; d(0,#)=$LIST of Column Definitions
 	#;         1) Name
 	#;         2) Heading			("" - {Name})
 	#;         3) Length			("" - XML:AutoFitWidth)
 	#;         4) Output Length		(Internally set & used)
 	#;         5) Datatype			("" - %String)
 	#; d(1,#)=Column Data
 	#; d(2,"sort")=$LIST of #'s or Heading
 	#; d("x-heading",{Heading})=#
 	#;
 	#;--------------------------------------------------------------------------------
 	
 	kill d	// Tabula Rasa!
	set d(0,$i(d(0)))=$LB("SQLQueryPointer->RoutineName","Routine",30)
	set d(0,$i(d(0)))=$LB("SQLQueryPointer->CursorName","Cursor",10)
	set d(0,$i(d(0)))=$LB("ModuleName","Module",10)
	set d(0,$i(d(0)))=$LB("StartTime",,20)
	set d(0,$i(d(0)))=$LB("ROWCOUNT",,10)
	set d(0,$i(d(0)))=$LB("SQLQueryPointer->RunCount","RunCount",8)
	set d(0,$i(d(0)))=$LB("TimeSpent",,10)
	set d(0,$i(d(0)))=$LB("GlobalRefs",,10)
	set d(0,$i(d(0)))=$LB("LinesOfCode",,12)
	set d(0,$i(d(0)))=$LB("DiskWait",,10)
	set d(0,$i(d(0)))=$LB("Pid",,10)
	set d(0,$i(d(0)))=$LB("IPAddress",,10)
	set d(0,$i(d(0)))=$LB("UserName",,12)
	set d(0,$i(d(0)))=$LB("MachineName",,12)
	set d(0,$i(d(0)))=$LB("ExeName",,8)
	set d(2,"sort")=$LB("Routine","Cursor","Module")
	for col=1:1:d(0) { set dInfo=d(0,col),dHeader=$LG(dInfo,2) set:dHeader="" dHeader=$LG(dInfo,1) set d("x-heading",dHeader)=col }
	set tSC=..condsMatch(.conds,.d,.condValExp)
	
	&SQL(DECLARE statsCUR CURSOR FOR
	     SELECT SQLQueryPointer->RoutineName, SQLQueryPointer->CursorName, ModuleName, StartTime,
	            ROWCOUNT, SQLQueryPointer->RunCount, TimeSpent, GlobalRefs, LinesofCode, DiskWait,
	            Pid, IPAddress, UserName, MachineName, EXEName
	     INTO :d(1,1), :d(1,2), :d(1,3), :d(1,4), 
	          :d(1,5), :d(1,6), :d(1,7), :d(1,8), :d(1,9), :d(1,10), 
	          :d(1,11), :d(1,12), :d(1,13), :d(1,14), :d(1,15)
	     FROM %SYS_PTools.SQLStats
	     WHERE SQLQueryPointer->Namespace = :ns
	    )
	
	set tSC=..fileHeader(outputFile,.format,"",$CLASSNAME(),thisMethod,version,.d,bcFlag) THROW:$$$ISERR(tSC)
 
	&SQL(OPEN statsCUR)
	if SQLCODE<0 { set tSC=$$$ERROR($$$SQLError,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%apiSQL(SQLCODE))) THROW }
	
	set rowCnt=0
	FOR {
		&SQL(FETCH statsCUR)
		QUIT:SQLCODE'=0

		CONTINUE:(rtnName'="")&&(rtnName'=d(1,1))	  	// RoutineName doesn't match specified 'rtnName'
		CONTINUE:(modName'="")&&(modName'=d(1,3))	  	// ModuleName doesn't match specified 'modName'
		if condValExp'="" { // --- Check Condition(s) via the 'conds()' array ---
			try { if @condValExp { } else { CONTINUE } } catch { } // Check if condition(s) in 'conds()' array Succeeded/Failed
		}
				
		set tSC=..fileBody(outputFile,.format,.d)
		
		set rowCnt=$I(rowCnt)	// Count Rows Processed!
 	}
	
 	set:SQLCODE<0 tSC=$$$ADDSC(tSC,$$$ERROR($$$SQLError,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%apiSQL(SQLCODE))))

	&sql(CLOSE statsCUR)
 	set:SQLCODE<0 tSC=$$$ADDSC(tSC,$$$ERROR($$$SQLError,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%apiSQL(SQLCODE))))
	
	THROW:$$$ISERR(tSC)
 }
 catch {
	if tSC=1 {
		set %msg=$ZE
		set tSC=$$$ERROR($$$ObjectScriptError,%msg)
	}
	
	if 'silent { USE 0 write ! do $system.Status.DisplayError(tSC) }
 }
 
 	set stop=$$$sysTimestamp
 	
 	do:$$$ISOK(tSC)&&(",SQLStats.ExportAll,SQLStats.Export,"'[(","_bcFlag_",")) ..fileFooter(outputFile,.format,"End of data collection for: ##class("_$CLASSNAME()_")."_thisMethod_"(...)",.d,stop-start,rowCnt)
 
 	if outputFile'="" {		// Return to Terminal IO & Close File
 		USE 0
 		CLOSE outputFile
 	}
 	
 	$$$resetSQLStatsFlag(zu115x12)		// Reset SQLStats flag for current JOB to original value

	set (file,ptInfo("outputFile"))=$s(outputFile="":$IO,1:##class(%Library.File).CanonicalFilename(outputFile))
 	set ptInfo("className")=$CLASSNAME(),ptInfo("methodName")=$g(thisMethod),ptInfo("rowCnt")=$g(rowCnt),ptInfo("totalTime")=$g(stop)-$g(start)
	
 	QUIT tSC
}

/// This query def joins <class>%SYS.PTools.SQLQuery</class> and '%SYS.PTools.SQLStats' to make SQL reporting on the data easier.
Query SQLStatsView() As %SQLQuery(CONTAINID = 1) [ SqlView, SqlViewName = SQLStatsView ]
{
SELECT S.ID, Q.NameSpace, Q.RoutineName, Q.CursorName, Q.CompileTime, Q.ImportSchema,
       S.StartTime, S.Counter, S.ModuleName, S.ModuleCount,
       S.GlobalRefs, S.LinesOfCode, S.CommandsExecuted, S.DiskWait, S.TimeSpent, S.TimeToFirstRow, S.RowCount, 
       S.UserName, S.ExeName, S.MachineName, S.IPAddress, S.Pid, Q.QueryType, Q.QueryText, Q.Details, Q.RunCount 
       FROM %SYS_PTools.SQLQuery Q LEFT OUTER JOIN %SYS_PTools.SQLStats S ON Q.ID = S.SQLQueryPointer
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       clearSQLStats [SQL: PT_clearSQLStats]
/// Replaced BY:  clearStatsSQL [SQL: PT_clearStatsSQL] (<class>%SYS.PTools.StatsSQL</class>) 
/// Status:       <BC>New Entry Point added to mimic <method>Purge</method> for Backward-Compatibility</BC>
/// Purpose:      Delete all of the data stored in the '%SYS.PTools.SQLStats' 
///               class, based on the specified parameters...
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLStats).clearSQLStats(...)
///                           SQL: CALL %SYS_PTools.PT_clearSQLStats(...)
///                                SELECT %SYS_PTools.PT_clearSQLStats(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Delete all of the data stored in the '%SYS.PTools.SQLStats' 
///               class in the 'SAMPLES' namespace:
/// 
///               set stats=##class(%SYS.PTools.SQLStats).clearSQLStats("SAMPLES")
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","RunTime","SQLStats{C|D|I|S|Z}")
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
///                     following class: %SYS.PTools.SQLStats
///                    [DEFAULT: 0]
///   ptInfo      - A Pass By Reference information array that returns
///                 detailed information to the user in the following format:
///                    ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                 Where category = { "cnt" | "curr" | "term" | ... }
///                       variable = A var corresponding to the given 'category'
/// 
///                 Example:
///                    ptInfo("cnt","clearSQLStats")=The number of rows deleted
///                                                  via this method [Routine Method]
///                    ptInfo("cnt","Purge")=The number of rows deleted
///                                          via this method         [Class Method]
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the number of Stats rows deleted from the following class; 
///               Otherwise, return an error message if an error occurred:
///                  %SYS.PTools.SQLStats
/// </p>
ClassMethod clearSQLStats(ns As %String = "", rtn As %String = "", ph3 As %Integer = 0, clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ Deprecated, SqlName = PT_clearSQLStats, SqlProc ]
{
	QUIT $$clearSQLStats^%SYS.PToolsDEP(ns,rtn,ph3,clearErrs,returnType,.ptInfo)		// MRP963  [DEPRECATED]
}

/// Backward-compatible Entry Point:
///    NOTE: See the <method>clearSQLStats</method> method above for more details.
ClassMethod Purge(ns As %String = "", rtn As %String = "", ph3 As %Integer = 0, clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = Purge, SqlProc ]
{
	QUIT $$clearSQLStats^%SYS.PToolsDEP(ns,rtn,ph3,clearErrs,returnType,.ptInfo)		// MRP963  [DEPRECATED]
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       GetLastSQLStats [SQL: GetLastSQLStats]
/// Replaced By:  GetLastSQLStats [SQL: StatsSQL_GetLastSQLStats]  (<class>%SYS.PTools.StatsSQL</class>)
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// Purpose:      This method return the SQLStats Result Set from the last invoked 
///               SQL Statement
/// 
/// NOTE:         This method makes use of a local variable '%sqlcontext' that
///               gets set when the stats data is saved.
///               This only works if you are running in the same process.
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).GetLastSQLStats(...)
///                    SQL: CALL %SYS_PTools.GetLastSQLStats(...)
///                         SELECT %SYS_PTools.GetLastSQLStats(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         To see the SQLStats Result Set from the last invoked SQL Statement, 
///               invoke one of the following methods:
/// 
///               // First invoke a query with SQLStats turned on, such that the following
///               // array value gets set:  %SQLStats("LastRow")
///               set tSC=##class(%SYS.PTools.SQLStats).GetLastSQLStats() do %sqlcontext.DumpResults()
///                  OR
///               set tSC=##class(%SYS.PTools.SQLStats).GetLastSQLStats(1)  // Automatically invokes DumpResults()
///                  OR
///               set tSC=##class(%SQL.Statement).%ExecDirect(,"CALL %SYS_PTools.GetLastSQLStats(1)")
/// 
///               %sqlcontext: The variable containing the instantiated object of the class
///                            %Library.SQLProcContext when a stored procedure is called.
///                            %sqlcontext consists of several properties, including an Error 
///                            object, the SQLCODE error status, the SQL row count, and an 
///                            error message.  This variable is reset before each execution.
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","RunTime","SQLStats{C|D|I|S|Z}")
/// 
/// Parameters:
///    dumpResults   - 1 = Automatically invoke the 'DumpResults()' if '%sqlcontext'
///                        is set to a valid value
/// 
/// RETURN Value: The status of this method's execution
/// </p>
ClassMethod GetLastSQLStats(dumpResults = 0) As %Integer [ Deprecated, ReturnResultsets, SqlName = GetLastSQLStats, SqlProc ]
{
	QUIT $$GetLastSQLStats^%SYS.PTools(dumpResults)
}

/// <BC>Backward-Compatible Query</BC>
Query ViewStats(NameSpace As %String) As %SQLQuery(ROWSPEC = "RoutineName:%String,QueryText:%String,RunCount:%Integer,AvgRows:%Integer,AvgGlobalRefs:%Integer,AvgDiskWait:%Integer,AvgCommands:%Integer,AvgTime:%Integer,Details:%Integer,CursorName:%Integer,RoutineCursor:%Integer,ImportSchema:%String")
{
	SELECT Main.RoutineName, Main.QueryText, RunCount,
		{fn round(avg(Main.RowCount),2)} as AvgRows,
		{fn round(avg(Main.GlobalRefs),2)} as AvgGlorefs,
		{fn round(avg(Main.DiskWait),2)} as AvgDiskWait,
		{fn round(avg(Main.LinesOfCode),2)} as AvgCommands,
		{fn round(avg(Main.TimeSpent),5)} as AvgTime,
 		Details, CursorName,RoutineName||'^'||CursorName, ImportSchema
		
		FROM %SYS_PTools.SQLStatsView Main
		WHERE Main.Namespace= :NameSpace
		AND RoutineName <> 'source lines'
		AND ModuleName = 'Main'
		GROUP BY Main.RoutineName, Main.CursorName
}

/// <BC>Backward-Compatible Query</BC>
Query ViewStatsDetails(CursorName As %String, RoutineName As %String) As %SQLQuery(ROWSPEC = "QueryText:%String,RunCount:%Integer,AvgRows:%Integer,AvgGlobalRefs:%Integer,AvgDiskWait:%Integer,AvgCommands:%Integer,AvgTime:%Integer,ModuleName:%String,AvgModCount:%Integer") [ SqlProc ]
{
	SELECT QueryText, RunCount,
		{fn round(avg(RowCount),2)} as AvgRows,
		{fn round(avg(GlobalRefs),2)} as AvgGlorefs,
		{fn round(avg(DiskWait),2)} as AvgDiskWait,
		{fn round(avg(LinesOfCode),2)} as AvgCommands,
		{fn round(avg(TimeSpent),5)} as AvgTime,
		ModuleName,
		{fn round(avg(ModuleCount),2)} as AvgModCount
		FROM %SYS_PTools.SQLStatsView 
		WHERE CursorName= :CursorName
		AND RoutineName = :RoutineName
		GROUP BY CursorName, ModuleName
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       QueryText [SQL: N/A]
/// Replaced By:  getQueryText (<class>%SYS.PTools.StatsSQL</class>) 
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// Purpose:      This method retrieves the SQL Query Text given the parameters:
///               'CN', 'Rtn', & 'Internal'
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLStats).QueryText(...)
///                    SQL: N/A
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Retrieve the SQL Text for any of the data rows retrieved
///               from invoking the 'exportSQLStats()' method:
/// 
///               CALL %SYS_PTools.PT_exportSQLStats()
///               set sql=##class(%SYS.PTools.SQLStats).QueryText("SQLStats0","PToolsSQLStats"_$JOB)
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","RunTime","SQLStats{C|D|I|S|Z}")
/// 
/// Parameters:
///   CN         - The cursor name from which to retrieve the SQL Query Text
///   Rtn        - The routine from which to retrieve the SQL Query Text
///   Internal   - 0 = Return the External Query Text  [DEFAULT]
///                1 = Return the Internal Query Text
/// 
/// Return: Return either the Internal or External SQL Query Text; Otherwise,
///         return the Error Status if an error occurs.
/// </p>
ClassMethod QueryText(CN As %String, Rtn As %String, Internal As %Boolean = 0) As %String [ Deprecated ]
{
	s status=$zu(115,12,-1)
		&SQL(SELECT QueryText,InternalQueryText
		INTO :sql1,:sql2
		FROM %SYS_PTools.SQLQuery
		WHERE CursorName= :CN
		AND RoutineName = :Rtn)
	s status=$zu(115,12,status)
	i SQLCODE'=0 QUIT ""
	QUIT $S(Internal=0:$ZSTRIP(sql1,"<W"),1:$ZSTRIP(sql2,"<W"))
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       ImportSchema [SQL: N/A]
/// Replaced By:  getImportSchema (<class>%SYS.PTools.StatsSQL</class>) 
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// Purpose:      This method retrieves the Import Schema given the parameters:
///               'CN', 'Rtn', & 'Internal'
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLStats).ImportSchema(...)
///                    SQL: N/A
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Retrieve the SQL Text for any of the data rows retrieved
///               from invoking the 'exportSQLStats()' method:
/// 
///               CALL %SYS_PTools.PT_exportSQLStats()
///               set iSchema=##class(%SYS.PTools.SQLStats).ImportSchema("SQLStats0","PToolsSQLStats"_$JOB)
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","RunTime","SQLStats{C|D|I|S|Z}")
/// 
/// Parameters:
///   CN         - The cursor name from which to retrieve the Import Schema
///   Rtn        - The routine from which to retrieve the Import Schema
///   Internal   - 0 = Return the External Query Text  [DEFAULT]
///                1 = Return the Internal Query Text
/// 
/// Return: Return either the Internal or External Import Schema; Otherwise,
///         return the Error Status if an error occurs.
/// </p>
ClassMethod ImportSchema(CN As %String, Rtn As %String, Internal As %Boolean = 0) As %String [ Deprecated ]
{
	s status=$zu(115,12,-1)
		&SQL(SELECT ImportSchema
		INTO :sql1
		FROM %SYS_PTools.SQLQuery
		WHERE CursorName= :CN
		AND RoutineName = :Rtn)
	s status=$zu(115,12,status)
	i SQLCODE'=0 QUIT ""
	QUIT sql1
}

/// Provide the current version for the %SYS.PTools.SQLStats class/section of the Performance Tools (PTools) Application
ClassMethod version() As %String [ SqlName = SQLStats_version, SqlProc ]
{
	QUIT $$$SQLStatsVersion		//MRP878 - First Implementation of Versioning
}

/// Perform the OnDelete Trigger operations for this class...
ClassMethod TriggerOnDelete(timing, ns, rtn, curs)
{
 
    #; --- If no more data rows exist, delete the Data Counter global ---
    if (rtn'="")&&(curs'="")&&'$$$existsSYSPToolsSQLStatsCounterData(rtn,curs,"") {
	    $$$killSYSPToolsSQLStatsCounter(rtn,curs)
    }
    
    #; --- If no more data rows exist, delete the Information/Counter globals ---
    if '$$$existsSYSPToolsSQLStatsData {
    	$$$killSYSPToolsSQLStatsChildSub
    }
}

Trigger OnDelete [ Event = DELETE, Time = AFTER ]
{
    do ..TriggerOnDelete("AFTER",$NAMESPACE,$p({ID},"||",1),$p({ID},"||",2))
}

Storage Default
{
<Data name="SQLStatsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>RoutineInfo</Value>
</Value>
<Value name="3">
<Value>ModuleName</Value>
</Value>
<Value name="4">
<Value>RowCount</Value>
</Value>
<Value name="5">
<Value>GlobalRefs</Value>
</Value>
<Value name="6">
<Value>CommandsExecuted</Value>
</Value>
<Value name="7">
<Value>TimeSpent</Value>
</Value>
<Value name="8">
<Value>TimeToFirstRow</Value>
</Value>
<Value name="9">
<Value>StartTime</Value>
</Value>
<Value name="10">
<Value>UserName</Value>
</Value>
<Value name="11">
<Value>IPAddress</Value>
</Value>
<Value name="12">
<Value>MachineName</Value>
</Value>
<Value name="13">
<Value>ExeName</Value>
</Value>
<Value name="14">
<Value>ModuleCount</Value>
</Value>
<Value name="15">
<Value>Pid</Value>
</Value>
<Value name="16">
<Value>DiskWait</Value>
</Value>
<Value name="17">
<Value>SQLStats</Value>
</Value>
<Value name="18">
<Value>NameSpace</Value>
</Value>
<Value name="19">
<Value>RoutineName</Value>
</Value>
<Value name="20">
<Value>CursorName</Value>
</Value>
<Value name="21">
<Value>StatsGroup</Value>
</Value>
<Value name="22">
<Value>StatsMarker</Value>
</Value>
</Data>
<DataLocation>^%sqlcq($NAMESPACE,"PTools","RunTime","SQLStatsD")</DataLocation>
<DefaultData>SQLStatsDefaultData</DefaultData>
<ExtentSize>68</ExtentSize>
<IdLocation>^%sqlcq($NAMESPACE,"PTools","RunTime","SQLStatsD")</IdLocation>
<IndexLocation>^%sqlcq($NAMESPACE,"PTools","RunTime","SQLStatsI")</IndexLocation>
<Property name="%%CLASSNAME">
<AverageFieldSize>1</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="%%ID">
<AverageFieldSize>38.87</AverageFieldSize>
<Selectivity>1</Selectivity>
</Property>
<Property name="ChildSub">
<AverageFieldSize>2</AverageFieldSize>
<Selectivity>1.4706%</Selectivity>
</Property>
<Property name="Counter">
<AverageFieldSize>1.87</AverageFieldSize>
<Selectivity>1.4706%</Selectivity>
</Property>
<Property name="DiskWait">
<AverageFieldSize>1</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="ExeName">
<AverageFieldSize>1</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="GlobalRefs">
<AverageFieldSize>1</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="IPAddress">
<AverageFieldSize>1</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="LinesOfCode">
<AverageFieldSize>2</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="MachineName">
<AverageFieldSize>1</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="ModuleCount">
<AverageFieldSize>1</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="ModuleName">
<AverageFieldSize>4</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="Pid">
<AverageFieldSize>5</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="RoutineInfo">
<AverageFieldSize>1</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="RowCount">
<AverageFieldSize>1</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="SQLQueryPointer">
<AverageFieldSize>31</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="StartTime">
<AverageFieldSize>19</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="TimeToFirstRow">
<AverageFieldSize>1</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="TotalTime">
<AverageFieldSize>6.99</AverageFieldSize>
<Selectivity>4.5455%</Selectivity>
</Property>
<Property name="UserName">
<AverageFieldSize>11</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<StreamLocation>^%sqlcq($NAMESPACE,"PTools","RunTime","SQLStatsS")</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
