/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

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
/// 
/// <p class="info-head">
/// Class:        %SYS.PTools.StatsSQL
/// Replaces:     <class>%SYS.PTools.SQLStats</class>  <DEP>[DEPRECATED]</DEP>
/// Purpose:      
///    This class contains the Optimal (new) Performance Tools for collecting
///    statistics on SQL Queries.  Since this class extends <class>%SYS.PTools.Stats</class>,
///    it uses the properties from this class and its extent class to record 
///    these individual performance statistics details for each execution of
///    a SQL Query, since its last compilation.
/// 
///    To collect statistical data on SQL Query executions for the entire
///    System, you can invoke different levels of statistics collecting via 
///    several different methods described in the next section.
/// 
///    One of these methods, <method>SetSQLStats</method> for example, creates the 'SQLStats-flag'
///    which controls whether or not SQL Statistics are collected for each SQL 
///    Query execution by anybody on the system, and which performance statistics 
///    details are to be collected.
/// 
///    The SQLStats-flag is a colon (:) delimited string comprised of the following
///    individual components:
/// 
///       SQLStats-flag={action-flag}:{collect-flag}:{condition-flag}:{condition-value}:{terminate-flag}:{flag-type}
/// 
///    The {action-flag} portion of the SQLStats-flag is represented by the 1st
///    colon (:) piece, and can have one of the following values:
/// 
///    <u>System Setting</u>
///       0 - Query Compilation: Don't generator SQLStats collection code for
///                              any Query Modules
///           Query Execution:   Don't collect SQLStats for any Query Modules
///       1 - Query Compilation: Generator SQLStats collection code for MAIN  
///                              Query Module (Start & Stop)
///           Query Execution:   Don't collect SQLStats for any Query Modules
///       2 - Query Compilation: Generator SQLStats collection code for MAIN 
///                              Query Module (Start & Stop)
///           Query Execution:   Collect SQLStats for MAIN Query Module 
///                              (Start & Stop)
///       3 - Query Compilation: Generator SQLStats collection code for ALL
///                              Query Modules
///           Query Execution:   Collect SQLStats for ALL Query Modules
/// 
///    <u>Process/Job Setting</u>
///      -1 - Query Compilation: Turn SQLStats Off for this Process/Job
///           Query Execution:   Turn SQLStats Off for this Process/Job
///       0 - Query Compilation: Use the {action-flag} (System) setting
///           Query Execution:   Use the {action-flag} (System) setting
///   
///    The {collect-flag} portion of the SQLStats-flag is represented by the
///    2nd colon (:) piece, and is a numeric value representing which SQL 
///    Performance Statistics/Metrics to collect, as specified below:
/// 
///       {collect-flag} = SUM(MVal)
/// 
///    In general, all of the following performance metrics are collected
///    for each SQL module, along with a cumulative value representing
///    all SQL modules, when the SQLStats-flag is turned on:
/// 
///      MVal  Metric Name                   Metric Description
///      ----  ----------------------------  ----------------------------------
///       1    Query Execution Time          Total number of seconds elapsed
///       2    Total Global References       Total number of global references
///       4    Total Commands Executed       Total number of OS commands executed
///       8    Total Disk Read Latency Time  Total milliseconds spent waiting 
///      ====                                for Disk Reads
///       15   ALL                           Collect all Performance Metrics
/// 
///    This flag provides a mechanism by which to choose a combination of
///    which performance metrics to collect, by specifying a SUM of the
///    performance metrics MVal numbers (specified above) that you wish 
///    to collect.
/// 
///    EXAMPLE #1:
///    The following example represents the collection of 2 performance
///    metrics, 'Query Execution Time' & 'Total Disk Read Latency Time':
/// 
///      MVal  Metric Name
///      ----  ----------------------------
///       1    Query Execution Time
///      +8    Total Disk Read Latency Time
///      ===
///       9    Collect both of these performance metrics
/// 
///    By passing 9 for the value of the {collect-flag}, the sum of the
///    aforementioned performance metrics MVal numbers, the SQLStats
///    PTool application will only collect statistical data for these
///    two performance metrics whenever an SQL Query is invoked.
/// 
///    EXAMPLE #2:
///    The following example represents the collection of 3 performance
///    metrics, 'Query Execution Time', 'Total Global References' & 
///    'Total Commands Executed':
/// 
///      MVal  Metric Name
///      ----  ----------------------------
///       1    Query Execution Time
///       2    Total Global References
///      +4    Total Commands Executed
///      ===
///       7    Collect both of these performance metrics
/// 
///    By passing 9 for the value of the {collect-flag}, the sum of the
///    aforementioned performance metrics MVal numbers, the SQLStats
///    PTool application will only collect statistical data for these
///    three performance metrics whenever an SQL Query is invoked.
///   
///    The {condition-flag} portion of the SQLStats-flag is represented by the 3rd
///    colon (:) piece, and can have one of the following values:
///   
///       0 - No addition conditions, other than the ones specified by the
///           following two flags: {action-flag} & {collect-flag}              [DEFAULT]
///       1 - Namespace-Condition specified by the 'SetSQLStatsFlagByNS()' 
///           method
///   
///    The {condition-value} portion of the SQLStats-flag is represented by the 4th
///    colon (:) piece, and can have one of the following values:
///   
///       The {condition-value} is based on the {condition-flag} and represents the
///       way in which to further conditionalize/constrain whether SQLStats, by way
///       of the SQLStats-flag, can collect statistical information for SQL Query 
///       executions within a given IRIS environment.
///       For example, if the {condition-flag} is set to the value one (1), which is
///       the Namespace-Condition, then the {condition-value} would be set to a 
///       Namespace in which SQLStats is authorized to collect statistical information 
///       about SQL Queries. (e.g. "USER")
/// 
///    The {terminate-flag} portion of the SQLStats-flag is represented by the 5th
///    colon (:) piece, and can have one of the following values:
/// 
///       0 - No Action
///       n - A termination flag, represented by the number of minutes from the starting
///           $HOROLOG date, to determine when to terminate the SQLStats collection,
///           by turning off the SQLStats-flag (System), or by setting it to a specified 
///           reset value.
/// 
///    The {flag-type} portion of the SQLStats-flag is represented by the 6th
///    colon (:) piece, and can have one of the following values:
/// 
///       "" - Indeterminate (Older version of PTools/SQLStats)
///        0 - System Flag
///        1 - Process/Job Flag
/// 
///    -------------------------------------------------------------------------------
/// 
///    You can invoke different levels of SQL Statistics collection by setting 
///    the SQLStats-flags, either for the entire System, for your current 
///    Process/Job, or for a specified Namespace.  
/// 
///    To collect SQL Statistics for the entire System, invoke the following 
///    method:
/// 
/// Object Script: ##class(%SYS.PTools.StatsSQL).SetSQLStats(...)
///                $SYSTEM.SQL.SetSQLStats(...)
///           SQL: SELECT %SYS_PTools.StatsSQL_SetSQLStats(...)
/// 
///         (...): (actionFlag[,returnActionFlag,collectFlag,terminateCond,ptInfo])
/// 
///    To collect SQL Statistics for the current Process/Job, invoke the following 
///    method:
/// 
/// Object Script: ##class(%SYS.PTools.StatsSQL).SetSQLStats[Flag]Job(...)
///                $SYSTEM.SQL.SetSQLStats[Flag]Job(...)
///           SQL: SELECT %SYS_PTools.StatsSQL_SetSQLStats[Flag]Job(...)
/// 
///         (...): (actionFlag[,returnActionFlag,collectFlag,p4,ptInfo])
/// 
///    To collect SQL Statistics for a specific Process/Job, invoke the following 
///    method:
/// 
/// Object Script: ##class(%SYS.PTools.StatsSQL).SetSQLStatsFlagByPID(...)
///                $SYSTEM.SQL.SetSQLStatsFlagByPID(...)
///           SQL: SELECT %SYS_PTools.StatsSQL_SetSQLStatsFlagByPID(...)
/// 
///         (...): (pid,actionFlag[,returnActionFlag,collectFlag,p5,ptInfo])
/// 
///    <b>RESTRICTION: This method invocation requires %Admin_Operate:Use privilege</b>
/// 
///    To collect SQL Statistics within a specific Namespace, invoke the following 
///    method:
/// 
/// Object Script: ##class(%SYS.PTools.StatsSQL).SetSQLStatsFlagByNS(...)
///                $SYSTEM.SQL.SetSQLStatsFlagByNS(...)
///           SQL: SELECT %SYS_PTools.StatsSQL_SetSQLStatsFlagByNS(...)
/// 
///         (...): (ns,actionFlag[,returnActionFlag,collectFlag,terminateCond,ptInfo])
/// 
///    <u>Returns</u>
///    All of the aforementioned methods return the value of the SQLStats-flag 
///    before setting it to the new value; Otherwise, return an error message if 
///    an error occurred
///   
///    <u>SQLStats-flag RULES</u>
///    Whether to use the SQLStats-flag (System) or the SQLStats-flag (Process/Job)
///    is determined by the following rules:
///       IF {action-flag} (Process/Job) = 0, then use SQLStats-flag (System)
///       ELSE use SQLStats-flag (Process/Job)
///    NOTE: The 'GetSQLStatsFlag(flagType,...)' method has the following
///          additional rule when passed the parameter: flagType=""
///            RULE-G1:
///              If {action-flag}=-1, then return zero (0) for each
///              component-flag of the SQLStats-flag, except for the
///              {flag-type} which is one (1) [indicating a Process/Job
///              Flag setting], as in the following example:
///                 write $SYSTEM.SQL.GetSQLStatsFlag("")  =>  "0:0:0::0:1"
/// 
///              To retrieve the actual value for each component-flag of
///              the SQLStats-flag in this example, pass a one (1) for
///              the 'flagType' parameter:
///                 write $SYSTEM.SQL.GetSQLStatsFlag(1)   =>  "-1:0:0::0:1"
/// 
///    -------------------------------------------------------------------------------
/// 
///    When the SQLStats-flag is on, statistical data will be collected in the
///    '%SYS.PTools.StatsSQL' class, which can be interrogated during the analysis
///    phase to determine a way to achieve optimal query performance.  The following
///    simple SQL Query displays all of the properties within the '%SYS.PTools.StatsSQL'
///    class:
/// 
///       SELECT *
///       FROM %SYS_PTools.StatsSQL
///       ORDER BY Namespace, RoutineName, CursorName, StatsGroup
/// 
///    The following properties are important for statistical analysis and are 
///    aggregated for a given SQL Query in the row WHERE ModuleName = 'INFO':
/// 
///       - TotalRowCount         - The total number of rows returned in the MAIN Module for the given query
///       - TotalCounter          - The total number of times the query has been run since it's last compilation
///       - TotalModuleCount      - The total number of times we entered a given module for the run of the query
///       - TotalTimeToFirstRow   - The total time spent finding the first row in the MAIN Module for the given query
///       - TotalTimeSpent        - The total time spent in a given Module for the given query
///       - TotalGlobalRefs       - The total number of global references done in a given Module for the given query
///       - TotalCommandsExecuted - The total number of ObjectScript commands executed in a given Module for the given query
///       - TotalDiskWait         - The total number of Milliseconds spent waiting for Disk reads in a given Module for the given query
///       - VarianceTimeSpent     - The variance of the time spent in a given Module for the given query
/// 
///    These properties are initialized to zero (0) for the 'INFO' row and are only 
///    set to their proper value via the invocation of the 'aggregateSQLStats()'
///    method.  Therefore, in order to directly use the data in these properties, 
///    the following method must first be invoked:
/// 
/// Object Script: set status=##class(%SYS.PTools.StatsSQL).aggregateSQLStats(NameSpace, RoutineName, CursorName)
///           SQL: SELECT %SYS_PTools.PT_aggregateSQLStats(NameSpace, RoutineName, CursorName)
/// 
///       NOTE: To aggregate the SQL Statistics for all queries within a 'RoutineName',
///             omit passing the 'CursorName' to the 'aggregateSQLStats' method.
/// 
///    The Mean/Average and Variance for the property {TimeSpent}, {GlobalRefs}, 
///    {CommandsExecuted}, and {DiskWait} can be obtained via the following computations:
/// 
///         {Mean-expr} =  SUM({expr}) / {Counter}
///         {Variance-expr} = (1 / {Counter)) * SUM(({expr} - {Mean-expr})**2)
/// 
///    Where 'expr' is one of either: TimeSpent, GlobalRefs, CommandsExecuted, or DiskWait
/// 
///    NOTE: The 'TotalTime' property is maintained for backward-compatibility
///          and should not be use in this context.  Use the 'TimeSpent' 
///          property for the proper value, and the 'TotalTimeSpent' for the
///          'INFO' row.
/// 
/// 
///    All of the data that is stored in this class can be accessed in a number of 
///    predefined ways:
/// 
///       - By invoking the <method>exportStatsSQL</method> method, which creates a
///         file in many formats that contains the data from this method.
///            Example:
///                  ObjectScript: set tSC=##class(%SYS.PTools.StatsSQL).exportStatsSQL(...)
///                    SQL: CALL %SYS_PTools.PT_exportStatsSQL(...)
/// 
///       - By invoking a query against the data within this class:
///            Examples:
///               #1:   Raw Class Query
/// 
///                        SELECT * FROM %SYS_PTools.StatsSQL
/// 
///               #2:   Aggregated Class View Query
/// 
///                        SELECT * FROM %SYS_PTools.StatsSQLView
/// 
///               #3:   General Result-Set Query
/// 
///                        SELECT * FROM %SYS_PTools.StatsSQL_ViewStatsSQL([namespace])
/// 
///               #4:   Specific Result-Set Query
/// 
///                        SELECT * FROM %SYS_PTools.StatsSQL_ViewStatsSQLDetails(cursor,rtn)
/// 
///            NOTE: All of these examples use the properties that are aggregated by
///                  the 'aggregateSQLStats()' method.  Only example #1 requires this
///                  method to be invoked for the 'Total*' properties to have usable
///                  data.  The other three examples would benefit by the invocation
///                  of this method, but will generate the totals on the fly if this
///                  method has not been adequately run.
/// 
/// 
///    It's important to note that whenever you collect statistical data for SQL 
///    Query executions via this tool, each collection which performs the last row 
///    INSERT into the <class>%SYS.PTools.StatsSQL</class> class will populate the
///    following array reference with the corresponding definition:
/// 
///       %SQLStats("LastRow") = "||" Pieces:  (%ROWID of the last row INSERTed)
///                               1) SQLStats Marker (statsSQLMarker)
///                               2) Namespace       (ns)
///                               3) Routine         (rtn)
///                               4) Cursor          (curs)
///                               5) SQLStats Group  (statsGroup)
/// 
///    The information contained within this array reference can be used to see 
///    the SQLStats Result Set from the last invoked SQL Statement, by invoking
///    one of the following methods:
/// 
///       set tSC=##class(%SYS.PTools.StatsSQL).GetLastSQLStats() do %sqlcontext.DumpResults()
///          OR
///       set tSC=##class(%SYS.PTools.StatsSQL).GetLastSQLStats(1)  // Automatically invokes DumpResults()
/// 
///     NOTE: For additional details about the <method>GetLastSQLStats</method> method,
///           please refer to the actual methods documentation contain herein
/// 
/// 
///    The PTools/SQLStats data is collected in the following globals:
///   
///       Data Storage:  ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S}")
///       Error Storage: ^%sqlcq($NAMESPACE,"PTools","Error"[...])=$LIST Info
/// 
/// </p>
Class %SYS.PTools.StatsSQL Extends %SYS.PTools.Stats [ System = 4 ]
{

/// <PROP>
/// This marker indicates if the statistical data is from a SQL Query, in which case 
/// the '%SYS.PTools.StatsSQL' class should be use, or if these stats
/// are general purpose stats for non-SQL modules, in which case the
/// <class>%SYS.PTools.Stats</class> class should be use.
/// </PROP>
Property StatsMarker As %Boolean [ InitialExpression = 1, Required ];

/// The NameSpace in which the SQL query resides
Property NameSpace As %String(MAXLEN = 2000) [ InitialExpression = {$NAMESPACE}, Required ];

/// The name of the routine in which the SQL query resides
Property RoutineName As %String(MAXLEN = 2000) [ Required ];

/// <PROP>
/// The SQL Cursor name for the given SQL Statement
/// NOTE: For a <declare-cursor> statement of the form 'DECLARE cursor-name CURSOR FOR query'
///       use the specified <cursor-name>
///       For a <select-statement>, use the lettered position (A, B, ..., Z) of the statement 
///       within the {RoutineName} 
/// </PROP>
Property CursorName As %String(MAXLEN = 2000) [ Required ];

/// <PROP>
/// This is a unique number that specifies the Stats Collection Group for each query run
/// The counter comes from bumping the following global: 
///    ^%sqlcq($NAMESPACE,"PTools","db","StatsZ","StatsGroup",1,{NameSpace},{RoutineName},{CursorName})
///      USE: $$$bumpStatsSQLStatsGroup({NameSpace},{RoutineName},{CursorName})
/// </PROP>
Property StatsGroup As %Integer [ Required, SqlComputeCode = { Set {*} = $$$bumpStatsSQLStatsGroup({NameSpace},{RoutineName},{CursorName}) }, SqlComputed ];

/// <PROP>
/// Sections of the SQL statement, these should match up the the Module names in the Query Plan output
/// The SQL Module Name stores the internal 'mod' value with the following external values:
/// int=ext: -1=INFO, 0=MAIN, 1=FIRST, 2=B, ..., 26=Z, 27=27, ..., n=n
/// </PROP>
Property ModuleName As %SYS.PTools.ModuleName;

/// <PROP>
/// The type of SQL Query for which stats will be recorded: 
///    SQL-Statement=>SQLType  ->  mt("t")=>SQLType
///    SEL=>SELECT | DEC=>SELECT | INS=>INSERT | UPD=>UPDATE | DEL=>DELETE
/// </PROP>
Property QueryType As %String(MAXLEN = 100);

/// ImportSchema is used in generated code to handle SQL statements that have 
/// unqualified table names
Property ImportSchema As %String(MAXLEN = 2000);

/// Raw SQL Statement Text stored as a $LIST string
///   **NOTE: If this property changes position/location within the data storage global, 
///           ensure that the following MACROS are updated accordingly: 
///              - SYSPToolsStatsSQLPropSQLTextRawPos
///              - getSYSPToolsStatsSQLPropSQLTextRawValue(...)
///              - getSYSPToolsStatsSQLPropSQLTextRaw(...)
Property SQLTextRaw As list Of %String(MAXLEN = 30000, SQLPROJECTION = "table/column", TRUNCATE = 1, XMLPROJECTION = "wrapped");

/// External SQL Statement as a single string
Property QueryText As %String(COLLATION = "SQLUPPER(255)", MAXLEN = 30000, TRUNCATE = 1) [ Calculated, SqlComputeCode = { if {SQLTextRaw}'="" { set {*}=$LISTTOSTRING({SQLTextRaw}," ") } else { set {*}=$$$getSYSPToolsStatsSQLPropSQLTextRaw($g({NameSpace},"*"),$g({RoutineName},"*"),$g({CursorName},"*"),$$$StatsGroupInfo,$$$ModuleNameINFOInt),{*}=$s({*}'="":$LISTTOSTRING({*}," "),1:$p($g($$$CQ("QueryText",$s({RoutineName}[".cls":$e({RoutineName},1,*-2),1:{RoutineName}),1)),"~RUNTIME~",1)) } }, SqlComputed ];

/// hash the SQL so we can match incoming SQL with already stored Stats [<BC>Maintained for Backward-Compatibility</BC>]
Property Hash As %String(MAXLEN = 500);

/// <PROP>
/// Internal unique statement hash used as the ID for the SQL Statement Index (DPV4651):
///    ^rINDEXSQL("sqlidx",1,{SQLIndexHash},...)
///    ^rINDEXSQL("sqlidx",2,{rtn},{SQLIndexHash})
///    ^rINDEXSQL("sqlidx",3,{table},{SQLIndexHash})
/// For additional details, refer to the following: http://twiki.iscinternal.com/twiki/bin/view/ISC/SQL20Statement20Indexing
/// </PROP>
Property SQLIndexHash As %String(MAXLEN = 32);

/// Number of Seconds it takes to compile the query
Property QueryCompileTime As %Float;

/// List of Query Parameters
Property Parameters As list Of %String(SQLPROJECTION = "table/column", XMLPROJECTION = "wrapped");

/// <PROP>
/// A flag that controls whether or not SQL Statistics are collected for each
/// SQL Query execution (by anybody on the system, by a given Process/Job, or
/// for a given Namespace), and which performance statistics to be collected.
/// 
/// The SQLStatsFlag is a colon (:) delimited string comprised of the following
/// individual flags:
/// 
///     SQLStatsFlag={action-flag}:{collect-flag}:{condition-flag}:{condition-value}:{terminate-flag}:{flag-type}
/// 
/// The {action-flag}     portion of the SQLStatsFlag is represented by 1st colon piece
/// The {collect-flag}    portion of the SQLStatsFlag is represented by 2nd colon piece
/// The {condition-flag}  portion of the SQLStatsFlag is represented by 3nd colon piece
/// The {condition-value} portion of the SQLStatsFlag is represented by 4nd colon piece
/// The {terminate-flag}  portion of the SQLStatsFlag is represented by 5nd colon piece
/// The {flag-type}       portion of the SQLStatsFlag is represented by 6nd colon piece
/// 
/// Internal: $$$getSQLStatsFlagForJob | $$$getSQLStatsFlagForSystem
/// </PROP>
Property SQLStatsFlag As %String(MAXLEN = 1000);

/// The total number of rows returned in the MAIN Module for the given query
Property TotalRowCount As %Integer;

/// The total number of times the query has been run since it's last compilation
Property TotalCounter As %Integer;

/// The total number of times we entered this module for the run of the query
Property TotalModuleCount As %Integer;

/// The total time spent finding the first row in the MAIN Module for the given query
Property TotalTimeToFirstRow As %Float;

/// The total time spent in this Module for the given query
Property TotalTimeSpent As %Float;

/// The total number of global references done in this Module for the given query
Property TotalGlobalRefs As %Integer;

/// The total number of ObjectScript commands that were executed in this Module for the given query
Property TotalCommandsExecuted As %Integer;

/// *** DEPRECATED via MRP1300 as of 05/30/2022 ***
/// The 'TotalLinesOfCode' property has been deprecated and replaced by the 'TotalCommandsExecuted'
/// property, but is left here for backwards compatibility and returns the 'TotalCommandsExecuted' value.
/// At some point in the future this property will be removed from the product, so users 
/// should not rely on its availability going forward and should use the 'TotalCommandsExecuted'
/// property instead.
Property TotalLinesOfCode As %Integer [ Deprecated, ReadOnly, SqlComputeCode = { set {*} = {TotalCommandsExecuted} }, SqlComputed, Transient ];

/// The total number of Milliseconds spent waiting for Disk reads in this Module for the given query
Property TotalDiskWait As %Integer;

/// The variance of the time spent in this Module for the given query
Property VarianceTimeSpent As %Float;

/// Creation Date: $HOROLOG date format
Property creationDate As %Date(FORMAT = 1) [ InitialExpression = {+$h}, Required ];

/// Creation Time: $HOROLOG time format
Property creationTime As %Time [ InitialExpression = {$p($h,",",2)}, Required ];

/// <PROP>
/// The name of the Routine/Class in which the Embedded SQL Statement resides, and which ultimately
/// calls/invokes the Universal Cached Query [UCQ] created as the class container to compile
/// and code-generate the Embedded SQL Statement's query code.
/// The value stored in this property will have the following format:
///    - routineName.RTN  (e.g. MRProutine.RTN) - A routine that contains an Embedded SQL Statement
///    - className.CLS    (e.g. MRP.class.CLS)  - A class that contains an Embedded SQL Statement
/// 
/// NOTE: This property will only have a value if a Routine/Class contains an Embedded SQL 
///       Statement within one of its methods which calls/invokes a Universal Cached Query [UCQ].
///       This property will be stored within the following row of this class/table:
///          WHERE     StatsMarker = 1 /* '%SYS.PTools.StatsSQL' */
///                AND StatsGroup = 0  /* 'INFO' */
///                AND ModuleName = -1 /* 'INFO' */
/// 
///       This property will also be stored in the following 'Conditional Index', which
///       will be maintained via Triggers:
///          ^%sqlcq($NAMESPACE,"PTools","db","StatsI","rtnUCQCaller",{RoutineNameUCQCaller},...)
/// </PROP>
Property RoutineNameUCQCaller As %String(MAXLEN = 2000);

/// <p class="info-head">
/// Method:       SetSQLStats [SQL: StatsSQL_SetSQLStats]
/// Replaces:     N/A
/// Status:       New Functionality
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
///               The SQLStats-flag is a colon (:) delimited string comprised of 
///               the following individual components:
/// 
///                  SQLStats-flag={action-flag}:{collect-flag}:{condition-flag}:{condition-value}:{terminate-flag}:{flag-type}
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).SetSQLStats(...)
///                         $SYSTEM.SQL.SetSQLStats(...)
///                    SQL: SELECT %SYS_PTools.StatsSQL_SetSQLStats(...)
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Turn PTools ON to collects stats for all SQL modules (System):
/// 
///               set oldStats=##class(%SYS.PTools.StatsSQL).SetSQLStats(3)
/// 
/// Data Storage: N/A
/// 
/// Parameters:
///    actionFlag       - The portion of the SQLStats-flag which is represented by the 
///                       1st colon (:) piece, and can have one of the following values:
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
///    returnActionFlag - 0  = Return the entire SQLStats-flag value           [DEFAULT]
///                       1  = Return only the {action-flag} value, which is the portion
///                            of the SQLStats-flag represented by the 1st colon (:) piece
///                            NOTE: This is the backward-compatible value
///    collectFlag      - The portion of the SQLStats-flag which is represented by the 2nd 
///                       colon (:) piece, and is a numeric value representing which SQL 
///                       Performance Statistics/Metrics to collect, with one of the 
///                       following values:
///                          "" = Collect All SQL Performance Metrics                       [DEFAULT]
///                          n  = Where n=SUM(MVal)                       [See Below]
/// 
///                       In general, all of the following performance metrics are collected
///                       for each SQL module, along with a cumulative value representing
///                       all SQL modules, when the SQLStats-flag is turned on:
/// 
///                         MVal  Metric Name                   Metric Description
///                         ----  ----------------------------  ----------------------------------
///                          1    Query Execution Time          Total number of seconds elapsed
///                          2    Total Global References       Total number of global references
///                          4    Total Commands Executed       Total number of OS commands executed
///                          8    Total Disk Read Latency Time  Total milliseconds spent waiting 
///                         ====                                for Disk Reads
///                          15   ALL                           Collect all Performance Metrics
/// 
///                       This parameter provides a mechanism by which to choose a
///                       combination of which performance metrics to collect, by specifying 
///                       a SUM of the performance metrics MVal numbers (specified above) 
///                       that you wish to collect.
/// 
///                       EXAMPLE #1:
///                       The following example represents the collection of 2 performance
///                       metrics, 'Query Execution Time' & 'Total Disk Read Latency Time':
/// 
///                         MVal  Metric Name
///                         ----  ----------------------------
///                          1    Query Execution Time
///                         +8    Total Disk Read Latency Time
///                         ===
///                          9    Collect both of these performance metrics
/// 
///                       By passing 9 for the value of the 'collectFlag' parameter, the
///                       sum of the two aforementioned performance metrics MVal numbers,
///                       the SQLStats PTool application will only collect statistical data 
///                       for these two performance metrics whenever an SQL Query is invoked.
/// 
///                       EXAMPLE #2:
///                       The following example represents the collection of 3 performance
///                       metrics, 'Query Execution Time', 'Total Global References' & 
///                       'Total Commands Executed':
/// 
///                         MVal  Metric Name
///                         ----  ----------------------------
///                          1    Query Execution Time
///                          2    Total Global References
///                         +4    Total Commands Executed
///                         ===
///                          7    Collect both of these performance metrics
/// 
///                       By passing 7 for the value of the 'collectFlag' parameter, the
///                       sum of the three aforementioned performance metrics MVal numbers,
///                       the SQLStats PTool application will only collect statistical data 
///                       for these two performance metrics whenever an SQL Query is invoked.
///    terminateCond    - The portion of the SQLStats-flag which is represented by the 
///                       5th colon (:) piece, and is determined by this parameter value.
///                       An optional condition to determine when to terminate the SQLStats
///                       collection, by turning off the SQLStats-flag (System), or by setting
///                       it to a specified reset value.  This parameter accepts the following
///                       values:
///                          0       No Action                                              [DEFAULT]
///                          M:<min>:<raf> 
///                                  Where <min>=# of minutes from 1..n
///                                     When specified, this value will terminate the SQLStats
///                                     collection the number of minutes <min> after the current $H
///                                  Where <raf>=Reset {action-flag} value from 0..3
///                                     When specified, this is the value to which the {action-flag}
///                                     portion of the SQLStats-flag will be set upon expiration
///                                     If not specified, default <raf> to zero (0)
///                                  (e.g. "M:120:1"  => Terminate 120minutes after the current $H
///                                                      and reset SQLStats-flag/{action-flag} to 1)
///                          T:<ts>:<raf>
///                                  Where <ts>=Timestamp with the format: YYYYMMDD HHMM
///                                     When specified, this value will terminate the SQLStats
///                                     collection after the timestamp value
///                                  Where <raf>=Reset {action-flag} value from 0..3
///                                     When specified, this is the value to which the {action-flag}
///                                     portion of the SQLStats-flag will be set upon expiration 
///                                     If not specified, default <raf> to zero (0)
///                                  (e.g. "T:20171018 1330:1"  => Terminate after 10/18/2017 01:30PM
///                                                                and reset SQLStats-flag/{action-flag}
///                                                                to 1)
///    ptInfo           - A Pass By Reference information array that returns to the user detailed 
///                       information in the following format:
///                          ptInfo(category,variable)=value
///                             Where category = { "current" | "terminate" | ... }
///                                   variable = A variable that corresponds to the given 'category'
/// 
///                       Example:
///                          ptInfo("current","SQLStatsFlag")=The SQLStats-flag value after method execution
///    
/// RETURN Value: The value of the SQLStats-flag before setting it to the new value;
///               Otherwise, return an error message if an error occurred
/// </p>
ClassMethod SetSQLStats(actionFlag As %Integer = 0, returnActionFlag As %Integer = 0, collectFlag As %String = "", terminateCond As %String = 0, ByRef ptInfo As %RawString) As %Integer [ SqlName = StatsSQL_SetSQLStats, SqlProc ]
{
	QUIT $$SetSQLStatsFlag^%SYS.PToolsUtil(0,actionFlag,returnActionFlag,collectFlag,,,terminateCond,.ptInfo)
}

/// <p class="info-head">
/// Method:       SetSQLStatsFlag [SQL: StatsSQL_SetSQLStatsFlag]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      See <method>SetSQLStats</method> for details!
/// </p>
ClassMethod SetSQLStatsFlag(actionFlag As %Integer = 0, returnActionFlag As %Integer = 0, collectFlag As %String = "", terminateCond As %String = 0, ByRef ptInfo As %RawString) As %Integer [ SqlName = StatsSQL_SetSQLStatsFlag, SqlProc ]
{
	QUIT $$SetSQLStatsFlag^%SYS.PToolsUtil(0,actionFlag,returnActionFlag,collectFlag,,,terminateCond,.ptInfo)
}

/// <p class="info-head">
/// Method:       SetSQLStatsJob [SQL: StatsSQL_SetSQLStatsJob]
/// Replaces:     SetSQLStatsJob [SQL: SetSQLStatsJob]  (<class>%SYS.PTools.SQLStats</class>)  <DEP>[DEPRECATED]</DEP>
/// Replaced By:  SetSQLStatsFlagJob [SQL: StatsSQL_SetSQLStatsFlagJob]
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// Purpose:      This method sets the flag that controls whether or not this 
///               Process/Job collects SQL Statistics about each run of a query
/// 
///               You can invoke different levels of SQL Statistics collection by 
///               setting the SQLStats-flag, for your current Process/Job with this
///               method.
/// 
///               The SQLStats-flag controls whether or not SQL Statistics are 
///               collected for each SQL Query execution, and which performance 
///               statistics to collect.
/// 
///               The SQLStats-flag is a colon (:) delimited string comprised of 
///               the following individual components:
/// 
///                  SQLStats-flag={action-flag}:{collect-flag}:{condition-flag}:{condition-value}:{terminate-flag}:{flag-type}
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).SetSQLStatsJob(...)
///                         $SYSTEM.SQL.SetSQLStatsJob(...)
///                    SQL: SELECT %SYS_PTools.StatsSQL_SetSQLStatsJob(...)
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Turn PTools ON to collects stats for all SQL modules:
/// 
///               set oldStats=##class(%SYS.PTools.StatsSQL).SetSQLStatsJob(3)
/// 
/// Data Storage: N/A
/// 
/// Parameters:
///    actionFlag       - The portion of the SQLStats-flag which is represented by the 
///                       1st colon (:) piece, and can have one of the following values:
///                         -1 = Query Compilation: Turn SQLStats Off for this Process/Job
///                              Query Execution:   Turn SQLStats Off for this Process/Job
///                                 [-1 ONLY when flagType=1]
///                          0 = Query Compilation: Use the {action-flag} (System) setting
///                              Query Execution:   Use the {action-flag} (System) setting
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
///    returnActionFlag - 0  = Return the entire SQLStats-flag value           [DEFAULT]
///                       1  = Return only the {action-flag} value, which is the portion
///                            of the SQLStats-flag represented by the 1st colon (:) piece
///                            NOTE: This is the backward-compatible value
///    collectFlag      - The portion of the SQLStats-flag which is represented by the 2nd 
///                       colon (:) piece, and is a numeric value representing which SQL 
///                       Performance Statistics/Metrics to collect, with one of the 
///                       following values:
///                          "" = Collect All SQL Performance Metrics                       [DEFAULT]
///                          n  = Where n=SUM(MVal)                       [See Below]
/// 
///                       In general, all of the following performance metrics are collected
///                       for each SQL module, along with a cumulative value representing
///                       all SQL modules, when the SQLStats-flag is turned on:
/// 
///                         MVal  Metric Name                   Metric Description
///                         ----  ----------------------------  ----------------------------------
///                          1    Query Execution Time          Total number of seconds elapsed
///                          2    Total Global References       Total number of global references
///                          4    Total Commands Executed       Total number of OS commands executed
///                          8    Total Disk Read Latency Time  Total milliseconds spent waiting 
///                         ====                                for Disk Reads
///                          15   ALL                           Collect all Performance Metrics
/// 
///                       This parameter provides a mechanism by which to choose a
///                       combination of which performance metrics to collect, by specifying 
///                       a SUM of the performance metrics MVal numbers (specified above) 
///                       that you wish to collect.
/// 
///                       EXAMPLE #1:
///                       The following example represents the collection of 2 performance
///                       metrics, 'Query Execution Time' & 'Total Disk Read Latency Time':
/// 
///                         MVal  Metric Name
///                         ----  ----------------------------
///                          1    Query Execution Time
///                         +8    Total Disk Read Latency Time
///                         ===
///                          9    Collect both of these performance metrics
/// 
///                       By passing 9 for the value of the 'collectFlag' parameter, the
///                       sum of the two aforementioned performance metrics MVal numbers,
///                       the SQLStats PTool application will only collect statistical data 
///                       for these two performance metrics whenever an SQL Query is invoked.
/// 
///                       EXAMPLE #2:
///                       The following example represents the collection of 3 performance
///                       metrics, 'Query Execution Time', 'Total Global References' & 
///                       'Total Commands Executed':
/// 
///                         MVal  Metric Name
///                         ----  ----------------------------
///                          1    Query Execution Time
///                          2    Total Global References
///                         +4    Total Commands Executed
///                         ===
///                          7    Collect both of these performance metrics
/// 
///                       By passing 7 for the value of the 'collectFlag' parameter, the
///                       sum of the three aforementioned performance metrics MVal numbers,
///                       the SQLStats PTool application will only collect statistical data 
///                       for these two performance metrics whenever an SQL Query is invoked.
///    p4               - Placeholder Parameter for future extensibility
///    ptInfo           - A Pass By Reference information array that returns to the user detailed 
///                       information in the following format:
///                          ptInfo(category,variable)=value
///                             Where category = { "current" | "terminate" | ... }
///                                   variable = A variable that corresponds to the given 'category'
/// 
///                       Example:
///                          ptInfo("current","SQLStatsFlag")=The SQLStats-flag value after method execution
///    
/// RETURN Value: The value of the SQLStats-flag before setting it to the new value;
///               Otherwise, return an error message if an error occurred
/// </p>
ClassMethod SetSQLStatsJob(actionFlag As %Integer = 0, returnActionFlag As %Integer = 0, collectFlag As %String = "", p4 As %String = "", ByRef ptInfo As %RawString) As %Integer [ SqlName = StatsSQL_SetSQLStatsJob, SqlProc ]
{
	QUIT $$SetSQLStatsFlag^%SYS.PToolsUtil(1,actionFlag,returnActionFlag,collectFlag,,,,.ptInfo)
}

/// <p class="info-head">
/// Method:       SetSQLStatsFlagJob [SQL: StatsSQL_SetSQLStatsFlagJob]
/// Replaces:     SetSQLStatsJob [SQL: StatsSQL_SetSQLStatsJob]
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      This method sets the flag that controls whether or not this 
///               Process/Job collects SQL Statistics about each run of a query
/// 
///               You can invoke different levels of SQL Statistics collection by 
///               setting the SQLStats-flag, for your current Process/Job with this
///               method.
/// 
///               The SQLStats-flag controls whether or not SQL Statistics are 
///               collected for each SQL Query execution, and which performance 
///               statistics to collect.
/// 
///               The SQLStats-flag is a colon (:) delimited string comprised of 
///               the following individual components:
/// 
///                  SQLStats-flag={action-flag}:{collect-flag}:{condition-flag}:{condition-value}:{terminate-flag}:{flag-type}
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).SetSQLStatsFlagJob(...)
///                         $SYSTEM.SQL.SetSQLStatsFlagJob(...)
///                    SQL: SELECT %SYS_PTools.StatsSQL_SetSQLStatsFlagJob(...)
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Turn PTools ON to collects stats for all SQL modules:
/// 
///               set oldStats=##class(%SYS.PTools.StatsSQL).SetSQLStatsFlagJob(3)
/// 
/// Data Storage: ^%SYS("sql","sys","SQLStats")
/// 
/// Parameters:
///    actionFlag       - The portion of the SQLStats-flag which is represented by the 
///                       1st colon (:) piece, and can have one of the following values:
///                         -1 = Query Compilation: Turn SQLStats Off for this Process/Job
///                              Query Execution:   Turn SQLStats Off for this Process/Job
///                                 [-1 ONLY when flagType=1]
///                          0 = Query Compilation: Use the {action-flag} (System) setting
///                              Query Execution:   Use the {action-flag} (System) setting
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
///    returnActionFlag - 0  = Return the entire SQLStats-flag value           [DEFAULT]
///                       1  = Return only the {action-flag} value, which is the portion
///                            of the SQLStats-flag represented by the 1st colon (:) piece
///                            NOTE: This is the backward-compatible value
///    collectFlag      - The portion of the SQLStats-flag which is represented by the 2nd 
///                       colon (:) piece, and is a numeric value representing which SQL 
///                       Performance Statistics/Metrics to collect, with one of the 
///                       following values:
///                          "" = Collect All SQL Performance Metrics                       [DEFAULT]
///                          n  = Where n=SUM(MVal)                       [See Below]
/// 
///                       In general, all of the following performance metrics are collected
///                       for each SQL module, along with a cumulative value representing
///                       all SQL modules, when the SQLStats-flag is turned on:
/// 
///                         MVal  Metric Name                   Metric Description
///                         ----  ----------------------------  ----------------------------------
///                          1    Query Execution Time          Total number of seconds elapsed
///                          2    Total Global References       Total number of global references
///                          4    Total Commands Executed       Total number of OS commands executed
///                          8    Total Disk Read Latency Time  Total milliseconds spent waiting 
///                         ====                                for Disk Reads
///                          15   ALL                           Collect all Performance Metrics
/// 
///                       This parameter provides a mechanism by which to choose a
///                       combination of which performance metrics to collect, by specifying 
///                       a SUM of the performance metrics MVal numbers (specified above) 
///                       that you wish to collect.
/// 
///                       EXAMPLE #1:
///                       The following example represents the collection of 2 performance
///                       metrics, 'Query Execution Time' & 'Total Disk Read Latency Time':
/// 
///                         MVal  Metric Name
///                         ----  ----------------------------
///                          1    Query Execution Time
///                         +8    Total Disk Read Latency Time
///                         ===
///                          9    Collect both of these performance metrics
/// 
///                       By passing 9 for the value of the 'collectFlag' parameter, the
///                       sum of the two aforementioned performance metrics MVal numbers,
///                       the SQLStats PTool application will only collect statistical data 
///                       for these two performance metrics whenever an SQL Query is invoked.
/// 
///                       EXAMPLE #2:
///                       The following example represents the collection of 3 performance
///                       metrics, 'Query Execution Time', 'Total Global References' & 
///                       'Total Commands Executed':
/// 
///                         MVal  Metric Name
///                         ----  ----------------------------
///                          1    Query Execution Time
///                          2    Total Global References
///                         +4    Total Commands Executed
///                         ===
///                          7    Collect both of these performance metrics
/// 
///                       By passing 7 for the value of the 'collectFlag' parameter, the
///                       sum of the three aforementioned performance metrics MVal numbers,
///                       the SQLStats PTool application will only collect statistical data 
///                       for these two performance metrics whenever an SQL Query is invoked.
///    p4               - Placeholder Parameter for future extensibility
///    ptInfo           - A Pass By Reference information array that returns to the user detailed 
///                       information in the following format:
///                          ptInfo(category,variable)=value
///                             Where category = { "current" | "terminate" | ... }
///                                   variable = A variable that corresponds to the given 'category'
/// 
///                       Example:
///                          ptInfo("current","SQLStatsFlag")=The SQLStats-flag value after method execution
///    
/// RETURN Value: The value of the SQLStats-flag before setting it to the new value;
///               Otherwise, return an error message if an error occurred
/// </p>
ClassMethod SetSQLStatsFlagJob(actionFlag As %Integer = 0, returnActionFlag As %Integer = 0, collectFlag As %String = "", p4 As %String = "", ByRef ptInfo As %RawString) As %Integer [ SqlName = StatsSQL_SetSQLStatsFlagJob, SqlProc ]
{
	QUIT $$SetSQLStatsFlag^%SYS.PToolsUtil(1,actionFlag,returnActionFlag,collectFlag,,,,.ptInfo)
}

/// <p class="info-head">
/// Method:       SetSQLStatsFlagByPID [SQL: StatsSQL_SetSQLStatsFlagByPID]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method sets the flag that controls whether or not to collect 
///               SQL Statistics about each run of a query for the given 'pid'
/// 
///               You can invoke different levels of SQL Statistics collection by 
///               setting the SQLStats-flag, for a given 'pid'.
/// 
///               The SQLStats-flag (Process/Job) controls whether or not SQL Statistics 
///               are collected for each SQL Query execution, and which performance
///               statistics to be collected. 
/// 
///               The SQLStats-flag is a colon (:) delimited string comprised of 
///               the following individual components:
/// 
///                  SQLStats-flag={action-flag}:{collect-flag}:{condition-flag}:{condition-value}:{terminate-flag}:{flag-type}
/// 
/// NOTE:         This method ONLY applies to the SQLStats-flag for the given 
///               'pid' (Process/Job) and NOT the SQLStats-flag for the (System)!
/// 
/// <b>RESTRICTION:  This method invocation requires %Admin_Operate:Use privilege</b>
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).SetSQLStatsFlagByPID(...)
///                         $SYSTEM.SQL.SetSQLStatsFlagByPID(...)
///                    SQL: SELECT %SYS_PTools.StatsSQL_SetSQLStatsFlagByPID(...)
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Turn PTools ON to collects stats for all SQL modules for
///               PID# 12345:
/// 
///               set oldStats=##class(%SYS.PTools.StatsSQL).SetSQLStatsFlagByPID(12345,3)
/// 
/// Data Storage: N/A
/// 
/// Parameters:
///    pid              - The process ID ($JOB) for which to set the SQLStats-flag
///                           [DEFAULT: Current $JOB]
///    actionFlag       - The portion of the SQLStats-flag which is represented by the 
///                       1st colon (:) piece, and can have one of the following values:
///                          -1 = Query Compilation: Turn SQLStats Off for the given 'pid'
///                               Query Execution:   Turn SQLStats Off for the given 'pid'
///                           0 = Query Compilation: Use the {action-flag} (System) setting
///                               Query Execution:   Use the {action-flag} (System) setting
///                           1 = Query Compilation: Generator SQLStats collection code for 
///                                                  MAIN Query Module (Start & Stop)
///                               Query Execution:   Don't collect SQLStats for any Query 
///                                                  Modules
///                           2 = Query Compilation: Generator SQLStats collection code for 
///                                                  MAIN Query Module (Start & Stop)
///                               Query Execution:   Collect SQLStats for MAIN Query Module 
///                                                  (Start & Stop)
///                           3 = Query Compilation: Generator SQLStats collection code for 
///                                                  ALL Query Modules
///                               Query Execution:   Collect SQLStats for ALL Query Modules
///    returnActionFlag - 0  = Return the entire SQLStats-flag value           [DEFAULT]
///                       1  = Return only the {action-flag} value, which is the portion
///                            of the SQLStats-flag represented by the 1st colon (:) piece
///                            NOTE: This is the backward-compatible value
///    collectFlag      - The portion of the SQLStats-flag which is represented by the 2nd 
///                       colon (:) piece, and is a numeric value representing which SQL 
///                       Performance Statistics/Metrics to collect, with one of the 
///                       following values:
///                          "" = Collect All SQL Performance Metrics                       [DEFAULT]
///                          n  = Where n=SUM(MVal)                       [See Below]
/// 
///                       In general, all of the following performance metrics are collected
///                       for each SQL module, along with a cumulative value representing
///                       all SQL modules, when the SQLStats-flag is turned on:
/// 
///                         MVal  Metric Name                   Metric Description
///                         ----  ----------------------------  ----------------------------------
///                          1    Query Execution Time          Total number of seconds elapsed
///                          2    Total Global References       Total number of global references
///                          4    Total Commands Executed       Total number of OS commands executed
///                          8    Total Disk Read Latency Time  Total milliseconds spent waiting 
///                         ====                                for Disk Reads
///                          15   ALL                           Collect all Performance Metrics
/// 
///                       This parameter provides a mechanism by which to choose a
///                       combination of which performance metrics to collect, by specifying 
///                       a SUM of the performance metrics MVal numbers (specified above) 
///                       that you wish to collect.
/// 
///                       EXAMPLE #1:
///                       The following example represents the collection of 2 performance
///                       metrics, 'Query Execution Time' & 'Total Disk Read Latency Time':
/// 
///                         MVal  Metric Name
///                         ----  ----------------------------
///                          1    Query Execution Time
///                         +8    Total Disk Read Latency Time
///                         ===
///                          9    Collect both of these performance metrics
/// 
///                       By passing 9 for the value of the 'collectFlag' parameter, the
///                       sum of the two aforementioned performance metrics MVal numbers,
///                       the SQLStats PTool application will only collect statistical data 
///                       for these two performance metrics whenever an SQL Query is invoked.
/// 
///                       EXAMPLE #2:
///                       The following example represents the collection of 3 performance
///                       metrics, 'Query Execution Time', 'Total Global References' & 
///                       'Total Commands Executed':
/// 
///                         MVal  Metric Name
///                         ----  ----------------------------
///                          1    Query Execution Time
///                          2    Total Global References
///                         +4    Total Commands Executed
///                         ===
///                          7    Collect both of these performance metrics
/// 
///                       By passing 7 for the value of the 'collectFlag' parameter, the
///                       sum of the three aforementioned performance metrics MVal numbers,
///                       the SQLStats PTool application will only collect statistical data 
///                       for these two performance metrics whenever an SQL Query is invoked.
///    p5               - Placeholder Parameter for future extensibility
///    ptInfo           - A Pass By Reference information array that returns to the user detailed 
///                       information in the following format:
///                          ptInfo(category,variable)=value
/// 
///                       NOTE: This method currently returns no 'ptInfo', but is
///                             included for future extensibility
///    
/// RETURN Value: The value of the SQLStats-flag before setting it to the new value;
///               Otherwise, return an error message if an error occurred
/// </p>
ClassMethod SetSQLStatsFlagByPID(pid As %String = "", actionFlag As %Integer = 0, returnActionFlag As %Integer = 0, collectFlag As %String = "", p5 As %String = "", ByRef ptInfo As %RawString) As %Integer [ SqlName = StatsSQL_SetSQLStatsFlagByPID, SqlProc ]
{
	QUIT $$SetSQLStatsFlagByPID^%SYS.PToolsUtil(pid,actionFlag,returnActionFlag,collectFlag,,,,.ptInfo)
}

/// <p class="info-head">
/// Method:       SetSQLStatsFlagByNS [SQL: StatsSQL_SetSQLStatsFlagByNS]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method sets the flag that controls whether or not to collect 
///               SQL Statistics about each run of a query within the given 'ns'
///               (Namespace)
/// 
///               You can invoke different levels of SQL Statistics collection by 
///               setting the SQLStats-flag, for a given 'ns'.
/// 
///               The SQLStats-flag (System) controls whether or not SQL Statistics 
///               are collected for each SQL Query execution, and which performance
///               statistics to be collected. 
/// 
///               The SQLStats-flag is a colon (:) delimited string comprised of 
///               the following individual components:
/// 
///                  SQLStats-flag={action-flag}:{collect-flag}:{condition-flag}:{condition-value}:{terminate-flag}:{flag-type}
/// 
/// NOTE:         This method ONLY applies to the SQLStats-flag (System) for the 
///               given 'ns' and NOT the SQLStats-flag (Process/Job)!
/// 
/// Invocation:   This method can be invoked in the following ways:
///          Object Script: ##class(%SYS.PTools.StatsSQL).SetSQLStatsFlagByNS(...)
///                         $SYSTEM.SQL.SetSQLStatsFlagByNS(...)
///                    SQL: SELECT %SYS_PTools.StatsSQL_SetSQLStatsFlagByNS(...)
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Turn PTools ON to collects stats for all SQL modules within the
///               "USER" Namespace:
/// 
///               set oldStats=##class(%SYS.PTools.StatsSQL).SetSQLStatsFlagByNS("USER",3)
/// 
/// Data Storage: N/A
/// 
/// Parameters:
///    ns		        - The Namespace ($NAMESPACE) for which to set the SQLStats-flag
///                           [REQUIRED]
///    actionFlag       - The portion of the SQLStats-flag which is represented by the 
///                       1st colon (:) piece, and can have one of the following values:
///                           0 = Query Compilation: Don't generator SQLStats collection
///                                                  code for any Query Modules
///                               Query Execution:   Don't collect SQLStats for any Query 
///                                                  Modules
///                           1 = Query Compilation: Generator SQLStats collection code for 
///                                                  MAIN Query Module (Start & Stop)
///                               Query Execution:   Don't collect SQLStats for any Query 
///                                                  Modules
///                           2 = Query Compilation: Generator SQLStats collection code for 
///                                                  MAIN Query Module (Start & Stop)
///                               Query Execution:   Collect SQLStats for MAIN Query Module 
///                                                  (Start & Stop)
///                           3 = Query Compilation: Generator SQLStats collection code for 
///                                                  ALL Query Modules
///                               Query Execution:   Collect SQLStats for ALL Query Modules
///    returnActionFlag - 0  = Return the entire SQLStats-flag value           [DEFAULT]
///                       1  = Return only the {action-flag} value, which is the portion
///                            of the SQLStats-flag represented by the 1st colon (:) piece
///                            NOTE: This is the backward-compatible value
///    collectFlag      - The portion of the SQLStats-flag which is represented by the 2nd 
///                       colon (:) piece, and is a numeric value representing which SQL 
///                       Performance Statistics/Metrics to collect, with one of the 
///                       following values:
///                          "" = Collect All SQL Performance Metrics                       [DEFAULT]
///                          n  = Where n=SUM(MVal)                       [See Below]
/// 
///                       In general, all of the following performance metrics are collected
///                       for each SQL module, along with a cumulative value representing
///                       all SQL modules, when the SQLStats-flag is turned on:
/// 
///                         MVal  Metric Name                   Metric Description
///                         ----  ----------------------------  ----------------------------------
///                          1    Query Execution Time          Total number of seconds elapsed
///                          2    Total Global References       Total number of global references
///                          4    Total Commands Executed       Total number of OS commands executed
///                          8    Total Disk Read Latency Time  Total milliseconds spent waiting 
///                         ====                                for Disk Reads
///                          15   ALL                           Collect all Performance Metrics
/// 
///                       This parameter provides a mechanism by which to choose a
///                       combination of which performance metrics to collect, by specifying 
///                       a SUM of the performance metrics MVal numbers (specified above) 
///                       that you wish to collect.
/// 
///                       EXAMPLE #1:
///                       The following example represents the collection of 2 performance
///                       metrics, 'Query Execution Time' & 'Total Disk Read Latency Time':
/// 
///                         MVal  Metric Name
///                         ----  ----------------------------
///                          1    Query Execution Time
///                         +8    Total Disk Read Latency Time
///                         ===
///                          9    Collect both of these performance metrics
/// 
///                       By passing 9 for the value of the 'collectFlag' parameter, the
///                       sum of the two aforementioned performance metrics MVal numbers,
///                       the SQLStats PTool application will only collect statistical data 
///                       for these two performance metrics whenever an SQL Query is invoked.
/// 
///                       EXAMPLE #2:
///                       The following example represents the collection of 3 performance
///                       metrics, 'Query Execution Time', 'Total Global References' & 
///                       'Total Commands Executed':
/// 
///                         MVal  Metric Name
///                         ----  ----------------------------
///                          1    Query Execution Time
///                          2    Total Global References
///                         +4    Total Commands Executed
///                         ===
///                          7    Collect both of these performance metrics
/// 
///                       By passing 7 for the value of the 'collectFlag' parameter, the
///                       sum of the three aforementioned performance metrics MVal numbers,
///                       the SQLStats PTool application will only collect statistical data 
///                       for these two performance metrics whenever an SQL Query is invoked.
///    terminateCond    - The portion of the SQLStats-flag which is represented by the 
///                       5th colon (:) piece, and is determined by this parameter value.
///                       An optional condition to determine when to terminate the SQLStats
///                       collection, by turning off the SQLStats-flag (System), or by setting
///                       it to a specified reset value.  This parameter accepts the following
///                       values:
///                          0       No Action                                              [DEFAULT]
///                          M:<min>:<raf> 
///                                  Where <min>=# of minutes from 1..n
///                                     When specified, this value will terminate the SQLStats
///                                     collection the number of minutes <min> after the current $H
///                                  Where <raf>=Reset {action-flag} value from 0..3
///                                     When specified, this is the value to which the {action-flag}
///                                     portion of the SQLStats-flag will be set upon expiration
///                                     If not specified, default <raf> to zero (0)
///                                  (e.g. "M:120:1"  => Terminate 120minutes after the current $H
///                                                      and reset SQLStats-flag/{action-flag} to 1)
///                          T:<ts>:<raf>
///                                  Where <ts>=Timestamp with the format: YYYYMMDD HHMM
///                                     When specified, this value will terminate the SQLStats
///                                     collection after the timestamp value
///                                  Where <raf>=Reset {action-flag} value from 0..3
///                                     When specified, this is the value to which the {action-flag}
///                                     portion of the SQLStats-flag will be set upon expiration 
///                                     If not specified, default <raf> to zero (0)
///                                  (e.g. "T:20171018 1330:1"  => Terminate after 10/18/2017 01:30PM
///                                                                and reset SQLStats-flag/{action-flag}
///                                                                to 1)
///    ptInfo           - A Pass By Reference information array that returns to the user detailed 
///                       information in the following format:
///                          ptInfo(category,variable)=value
///                             Where category = { "current" | "terminate" | ... }
///                                   variable = A variable that corresponds to the given 'category'
/// 
///                       Example:
///                          ptInfo("current","SQLStatsFlag")=The SQLStats-flag value after method execution
///    
/// RETURN Value: The value of the SQLStats-flag before setting it to the new value;
///               Otherwise, return an error message if an error occurred
/// </p>
ClassMethod SetSQLStatsFlagByNS(ns As %String = "", actionFlag As %Integer = 0, returnActionFlag As %Integer = 0, collectFlag As %String = "", terminateCond As %String = 0, ByRef ptInfo As %RawString) As %Integer [ SqlName = StatsSQL_SetSQLStatsFlagByNS, SqlProc ]
{
	QUIT $$SetSQLStatsFlagByNS^%SYS.PToolsUtil(ns,actionFlag,returnActionFlag,collectFlag,,,terminateCond,.ptInfo)
}

/// <p class="info-head">
/// Method:       GetSQLStatsFlag [SQL: StatsSQL_GetSQLStatsFlag]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method gets the flag that controls whether or not we collect 
///               SQL Statistics for each SQL Query execution
/// 
///               Get the current value of the SQLStats-flag for the given 
///               'flagType'.
/// 
///               The SQLStats-flag (System/Job) controls whether or not SQL 
///               Statistics are collected for each SQL Query execution, and which
///               performance statistics to be collected.
/// 
///               The SQLStats-flag is a colon (:) delimited string comprised of 
///               the following individual components:
/// 
///                  SQLStats-flag={action-flag}:{collect-flag}:{condition-flag}:{condition-value}:{terminate-flag}:{flag-type}
/// 
/// RULES:        When (flagType=""), whether to use the SQLStats-flag (System) or
///               the SQLStats-flag (Process/Job) is determined by the following rules:
///                  IF {action-flag} (Process/Job) = 0, then use SQLStats-flag (System)
///                  ELSE use SQLStats-flag (Process/Job)
///                     NOTE: This method has the following additional rule when passed
///                           the parameter: flagType=""
///                             RULE-G1:
///                               If {action-flag}=-1, then return zero (0) for each
///                               component-flag of the SQLStats-flag, except for the
///                               {flag-type} which is one (1) [indicating a Process/Job
///                               Flag setting], as in the following example:
///                                  write $SYSTEM.SQL.GetSQLStatsFlag("")  =>  "0:0:0::0:1"
///        
///                               To retrieve the actual value for each component-flag of
///                               the SQLStats-flag in this example, pass a one (1) for
///                               the 'flagType' parameter:
///                                  write $SYSTEM.SQL.GetSQLStatsFlag(1)   =>  "-1:0:0::0:1"
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).GetSQLStatsFlag(...)
///                         $SYSTEM.SQL.GetSQLStatsFlag(...)
///                    SQL: SELECT %SYS_PTools.StatsSQL_GetSQLStatsFlag(...)
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Get the current value of the SQLStats-flag for the
///               Job/System Flag based on SQLStats-flag Rules:
/// 
///               set SQLStatsFlag=##class(%SYS.PTools.StatsSQL).GetSQLStatsFlag("")
/// 
/// Data Storage: ^%SYS("sql","sys","SQLStats")
/// 
/// Parameters:
///    flagType          - "" = Job/System Flag based on SQLStats-flag Rules    [DEFAULT]
///                        0  = System Flag
///                        1  = Process/Job Flag
///    returnActionFlag  - 0  = Return the entire SQLStats-flag value           [DEFAULT]
///                        1  = Return only the {action-flag} value, which is the portion
///                             of the SQLStats-flag represented by the 1st colon (:) piece
///                             NOTE: This is the backward-compatible value
///    ptInfo            - A Pass By Reference information array that returns to the user detailed 
///                        information in the following format:
///                           ptInfo(category,variable)=value
///                              Where category = { "current" | "terminate" | ["expired"] | ... }
///                                    variable = A variable that corresponds to the given 'category'
/// 
///                        Example:
///                           ptInfo("current","SQLStatsFlag")=The SQLStats-flag value after method execution
///    
/// RETURN Value: The current value of the SQLStats-flag;
///               Otherwise, return an error message if an error occurred
/// </p>
ClassMethod GetSQLStatsFlag(flagType As %Integer = "", returnActionFlag As %Integer = 0, ByRef ptInfo As %RawString) As %Integer [ SqlName = StatsSQL_GetSQLStatsFlag, SqlProc ]
{
	QUIT $$GetSQLStatsFlag^%SYS.PToolsUtil(flagType,returnActionFlag,.ptInfo)
}

/// <p class="info-head">
/// Method:       GetSQLStatsFlagByPID [SQL: StatsSQL_GetSQLStatsFlagByPID]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method gets the flag that controls whether or not we collect 
///               SQL Statistics about each SQL Query execution for the given 'pid'
/// 
///               Get the current value of the SQLStats-flag for the given 'pid'.
/// 
///               The SQLStats-flag (Process/Job) controls whether or not SQL 
///               Statistics are collected for each SQL Query execution, and which
///               performance statistics to be collected.
/// 
///               The SQLStats-flag is a colon (:) delimited string comprised of 
///               the following individual components:
/// 
///                  SQLStats-flag={action-flag}:{collect-flag}:{condition-flag}:{condition-value}:{terminate-flag}:{flag-type}
/// 
/// NOTE:         This method ONLY applies to the SQLStats-flag for the given 
///               'pid' (Process/Job) and NOT the SQLStats-flag for the (System)!
/// 
/// <b>RESTRICTION:  This method invocation requires %Admin_Operate:Use privilege</b>
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).GetSQLStatsFlagByPID(...)
///                         $SYSTEM.SQL.GetSQLStatsFlagByPID(...)
///                    SQL: SELECT %SYS_PTools.StatsSQL_GetSQLStatsFlagByPID(...)
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Get the current value of the SQLStats-flag for the
///               Job/System Flag based on SQLStats-flag Rules for
///               PID# 12345:
/// 
///               set SQLStatsFlag=##class(%SYS.PTools.StatsSQL).GetSQLStatsFlagByPID(12345)
/// 
/// Data Storage: ^%SYS("sql","sys","SQLStats")
/// 
/// Parameters:
///    pid               - The process ID ($JOB) for which to set the SQLStats-flag
///                           [DEFAULT: Current $JOB]
///    returnActionFlag  - 0  = Return the entire SQLStats-flag value           [DEFAULT]
///                        1  = Return only the {action-flag} value, which is the portion
///                             of the SQLStats-flag represented by the 1st colon (:) piece
///                             NOTE: This is the backward-compatible value
///    ptInfo            - A Pass By Reference information array that returns to the user detailed 
///                        information in the following format:
///                           ptInfo(category,variable)=value
/// 
///                        NOTE: This method currently returns no 'ptInfo', but is
///                              included for future extensibility
///    
/// RETURN Value: The current value of the SQLStats-flag;
///               Otherwise, return an error message if an error occurred
/// </p>
ClassMethod GetSQLStatsFlagByPID(pid As %String = "", returnActionFlag As %Integer = 0, ByRef ptInfo As %RawString) As %Integer [ SqlName = StatsSQL_GetSQLStatsFlagByPID, SqlProc ]
{
	QUIT $$GetSQLStatsFlagByPID^%SYS.PToolsUtil(pid,returnActionFlag,.ptInfo)
}

/// <p class="info-head">
/// Method:       SetSQLStatsSaveFlag [SQL: StatsSQL_SetSQLStatsSaveFlag]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method sets the flag that controls what type of SQL 
///               Statistics the System collects about each run of a query
/// 
///               The SQLStatsSave-flag controls what type of SQL Statistics are 
///               saved, either Optimal (new) or Original (backward-compatible).
/// 
///               The SQLStatsSave-flag is a colon (:) delimited string comprised 
///               of the following individual flags: {type-flag} & {method-flag}
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).SetSQLStatsSaveFlag(...)
///                         $SYSTEM.SQL.SetSQLStatsSaveFlag(...)
///                    SQL: SELECT %SYS_PTools.StatsSQL_SetSQLStatsSaveFlag(...)
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Set the PTools SQL Stats save flag (System) to 'Optimal'
/// 
///               set oldFlag=##class(%SYS.PTools.StatsSQL).SetSQLStatsSaveFlag(1)
/// 
/// Data Storage: ^%SYS("sql","sys","SQLStatsSave")
/// 
/// Parameters:
///    typeFlag      - 1 = Optimal (new)                            [DEFAULT]
///                    2 = Original (backward-compatible)
/// [Optional Parameters]
///    methodFlag    - 0 = Save the collected SQL Performance       [DEFAULT]
///                        Statistics via SQL (SQL-Set)
///                    1 = Save the collected SQL Performance 
///                        Statistics via COS (Direct-Set)
///                    NOTE: This parameter is only applicable when 'typeFlag=1'
///                    <IMP>NOTE: This parameter should only be used when advised by InterSystems Staff!</IMP>
///    
/// RETURN Value: The value of the SQLStatsSave-flag before setting to the new value;
///               Otherwise, return an error message if an error occurred
/// </p>
ClassMethod SetSQLStatsSaveFlag(typeFlag As %Integer = 1, methodFlag As %Integer = 0) As %Integer [ SqlName = StatsSQL_SetSQLStatsSaveFlag, SqlProc ]
{
	QUIT $$SetSQLStatsSaveFlag^%SYS.PToolsUtil(0,typeFlag,methodFlag)
}

/// <p class="info-head">
/// Method:       SetSQLStatsSaveFlagJob [SQL: StatsSQL_SetSQLStatsSaveFlagJob]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method sets the flag that controls what type of SQL 
///               Statistics this Process/Job collects about each run of a query
/// 
///               The SQLStatsSave-flag controls what type of SQL Statistics are 
///               saved, either Optimal (new) or Original (backward-compatible).
/// 
///               The SQLStatsSave-flag is a colon (:) delimited string comprised 
///               of the following individual flags: {type-flag} & {method-flag}
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).SetSQLStatsSaveFlagJob(...)
///                         $SYSTEM.SQL.SetSQLStatsSaveFlagJob(...)
///                    SQL: SELECT %SYS_PTools.StatsSQL_SetSQLStatsSaveFlagJob(...)
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Set the PTools SQL Stats save flag (Process/Job) to 'Optimal'
/// 
///               set oldFlag=##class(%SYS.PTools.StatsSQL).SetSQLStatsSaveFlagJob(1)
/// 
/// Data Storage: N/A
/// 
/// Parameters:
///    typeFlag      - 0 = Use the {type-flag} (System) value   [DEFAULT]
///                    1 = Optimal (new)
///                    2 = Original (backward-compatible)
/// [Optional Parameters]
///    methodFlag    - 0 = Save the collected SQL Performance       [DEFAULT]
///                        Statistics via SQL (SQL-Set)
///                    1 = Save the collected SQL Performance 
///                        Statistics via COS (Direct-Set)
///                    NOTE: This parameter is only applicable when 'typeFlag=1'
///                    <IMP>NOTE: This parameter should only be used when advised by InterSystems Staff!</IMP>
///    
/// RETURN Value: The value of the SQLStatsSave-flag before setting to the new value;
///               Otherwise, return an error message if an error occurred
/// </p>
ClassMethod SetSQLStatsSaveFlagJob(typeFlag As %Integer = 1, methodFlag As %Integer = 0) As %Integer [ SqlName = StatsSQL_SetSQLStatsSaveFlagJob, SqlProc ]
{
	QUIT $$SetSQLStatsSaveFlag^%SYS.PToolsUtil(1,typeFlag,methodFlag)
}

/// <p class="info-head">
/// Method:       GetSQLStatsSaveFlag [SQL: StatsSQL_GetSQLStatsSaveFlag]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This methods gets the flag that controls what type of SQL 
///               Statistics to collect about each run of a query
/// 
///               Get the current value of the SQLStatsSave-flag for the given 
///               'flagType'.
/// 
///               The SQLStatsSave-flag (System/Job) controls what type of SQL 
///               Statistics are saved, either Original (backward-compatible) or 
///               Optimal (new).
/// 
///               The SQLStatsSave-flag is a colon (:) delimited string comprised 
///               of the following individual flags: {type-flag} & {method-flag}
/// 
/// RULES:        When (flagType=""), whether to use the SQLStatsSave-flag (System) or
///               the SQLStatsSave-flag (Job) is determined by the following rules:
///                  IF {type-flag} (JOB) = 0, then use SQLStatsSave-flag (System)
///                  ELSE use SQLStatsSave-flag (Job)
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).GetSQLStatsSaveFlag(...)
///                         $SYSTEM.SQL.GetSQLStatsSaveFlag(...)
///                    SQL: SELECT %SYS_PTools.StatsSQL_GetSQLStatsSaveFlag(...)
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Get the current SQLStatsSave-flag value based on the
///               aforementioned 'flagType' Rules:
/// 
///               set SQLStatsSaveFlag=##class(%SYS.PTools.StatsSQL).GetSQLStatsSaveFlag()
/// 
/// Data Storage: ^%SYS("sql","sys","SQLStatsSave")
/// 
/// Parameters:
///    flagType      - "" = Job/System Flag based on SQLStatsSave-flag Rules    [DEFAULT]
///                    0  = System Flag
///                    1  = Job Flag
///    
/// RETURN Value: The current value of the SQLStatsSave-flag;
///               Otherwise, return an error message if an error occurred
/// </p>
ClassMethod GetSQLStatsSaveFlag(flagType As %Integer = "") As %Integer [ SqlName = StatsSQL_GetSQLStatsSaveFlag, SqlProc ]
{
	QUIT $$GetSQLStatsSaveFlag^%SYS.PToolsUtil(flagType)
}

/// <p class="info-head">
/// Method:       aggregateSQLStats [SQL: PT_aggregateSQLStats]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This function aggregates all of the statistical properties for 
///               each SQL Query where data was collected
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).aggregateSQLStats(...)
///                    SQL: CALL %SYS_PTools.PT_aggregateSQLStats(...)
///                         SELECT %SYS_PTools.PT_aggregateSQLStats(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Aggregate all of the statistical properties for the
///               'SAMPLES' namespace:
/// 
///               set status=##class(%SYS.PTools.StatsSQL).aggregateSQLStats("SAMPLES")
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
/// 
/// Parameters:
///   ns         - The namespace in which to aggregate SQL Statistics
///                If none provided, spin through all namespaces where SQL Stats collected
///   rtn        - The routine in which to aggregate SQL Statistics
///                If none provided, spin through all routines where SQL Stats collected
///   curs       - The cursor in which to aggregate SQL Statistics
///                If none provided, spin through all cursor where SQL Stats collected
/// 
/// Return: Error Status
/// </p>
ClassMethod aggregateSQLStats(ns = "", rtn = "", curs = "") As %Status [ SqlName = PT_aggregateSQLStats, SqlProc ]
{
	new %objlasterror,%sqlcontext
	set tSC=$$$OK,%msg="",SQLCODE="",errRowID="",errRowIDList=""
	set thisMethod="aggregateSQLStats"
	$$$AddAllRoleTemporary

 try {

	$$$setSQLStatsFlagOFF(zu115x12)	// Turn off SQLState for current JOB
	set nsNULL=(ns=""),rtnNULL=(rtn=""),cursNULL=(curs="")
	set statsSQLMarker=$$$StatsSQLMarker	// 1=>%SYS.PTools.StatsSQL
	set statsGroup=$$$StatsGroupInfo		// 0=>INFO
	set modNameINFO=$$$ModuleNameExtToInt("INFO")
	set modNameMAIN=$$$ModuleNameExtToInt("MAIN")

	GOTO:'nsNULL aggrStatsNS

	While 1 {
		set ns=$o($$$SYSPToolsStatsSQLDataSub1Glo(ns))
		QUIT:ns=""
aggrStatsNS	// --- Entry Point: 'ns' parameter invoked with non-null value ---
		QUIT:'$d($$$SYSPToolsStatsSQLDataSub1Glo(ns))
		GOTO:'rtnNULL aggrStatsRTN
		
		While 1 {
			set rtn=$o($$$SYSPToolsStatsSQLDataSub2Glo(ns,rtn))
			QUIT:rtn=""
aggrStatsRTN	// --- Entry Point: 'rtn' parameter invoked with non-null value ---
			QUIT:'$d($$$SYSPToolsStatsSQLDataSub2Glo(ns,rtn))
			GOTO:'cursNULL aggrStatsCURS
			
			While 1 {
				set curs=$o($$$SYSPToolsStatsSQLDataSub3Glo(ns,rtn,curs))
				QUIT:curs=""
aggrStatsCURS	// --- Entry Point: 'curs' parameter invoked with non-null value ---
				QUIT:'$d($$$SYSPToolsStatsSQLDataSub3Glo(ns,rtn,curs))
								
				if ..useAggregatedData(ns,rtn,curs) { QUIT:'cursNULL  CONTINUE  }  // Aggregated Data Up To Date!
				
				kill sum,var
				
				&sql(SELECT SUM(RowCount), SUM(Counter), SUM(ModuleCount), 
				            SUM(TimeToFirstRow), SUM(TimeSpent), 
				            SUM(GlobalRefs), SUM(CommandsExecuted), SUM(DiskWait),
				            VARIANCE(TimeSpent)
				     INTO :sum("RowCount"), :sum("Counter"), :sum("ModuleCount"), 
				          :sum("TimeToFirstRow"), :sum("TimeSpent"), 
				          :sum("GlobalRefs"), :sum("CommandsExecuted"), :sum("DiskWait"),
				          :var("TimeSpent")
				     FROM %SYS_PTools.StatsSQL
				     WHERE     StatsMarker = :statsSQLMarker
				           AND NameSpace = :ns
				           AND RoutineName = :rtn
				           AND CursorName = :curs
				           AND StatsGroup > :statsGroup
				           AND ModuleName = :modNameMAIN		/* 'MAIN' */
				    )
				    				
				if SQLCODE=0 {

					set fld="",sumTot=0
					for  { set fld=$o(sum(fld)) QUIT:fld=""  set sumTot=sumTot+sum(fld) }
					
					if sumTot>0 {

						set sqlAction="UPDATE",sqlClass="%SYS.PTools.StatsSQL",sqlTable="%SYS_PTools.StatsSQL",SQLCODE=0,%ROWID=""
					
						&sql(UPDATE %SYS_PTools.StatsSQL
						        SET TotalRowCount = :sum("RowCount"),
						        	TotalCounter = :sum("Counter"),
						            TotalModuleCount = :sum("ModuleCount"),
						            TotalTimeToFirstRow = :sum("TimeToFirstRow"),
					    	        TotalTimeSpent = :sum("TimeSpent"),
						            TotalGlobalRefs = :sum("GlobalRefs"),
						            TotalCommandsExecuted = :sum("CommandsExecuted"),
						            TotalDiskWait = :sum("DiskWait"),
						            VarianceTimeSpent = :var("TimeSpent")
						     WHERE     StatsMarker = :statsSQLMarker
						           AND NameSpace = :ns
						           AND RoutineName = :rtn
						           AND CursorName = :curs
						           AND StatsGroup = :statsGroup
						           AND ModuleName = :modNameINFO	/* 'INFO' */
						    )

						if SQLCODE'=0 { // --- SQL Error or Missing 'INFO' Row ---
							set errMsg="SQL Error: Failed to "_sqlAction_" into <table>"_sqlTable_"</table>"_$s(SQLCODE=100:".  The 'INFO' row (ModuleName = 'INFO') is Missing!",1:"")
							kill errLog	// Tabula Rasa
							set errLog("param-vals")=ns_"||"_rtn_"||"_curs
							set errRowID=$$setPToolsError^%SYS.PTools(ns,$JOB,rtn,curs,"",thisMethod,$ZE,errMsg,sqlClass,sqlTable,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%SYS.PTools(SQLCODE)),.errLog)
							set:errRowID'="" $LIST(errRowIDList,*+1)=errRowID
						}
						else {	// --- Record the PTools SQLStats information in the SQL Statement Index ---
					
							&sql(SELECT SQLIndexHash
							     INTO :SQLIndexHash
							     FROM %SYS_PTools.StatsSQL
							     WHERE ID = :%ROWID
							    )
						    
							#;------------------------------------------------------------
							#;                          statsData
							#;------------------------------------------------------------
							#; The statistics collected for the SQLStats, in the 
							#; following $LIST format:
							#;
							#;   1) Counter                     SUM(Counter)
 							#;   2) TimeSpent                   SUM(TimeSpent)
 							#;   3) VarianceTimeSpent           VARIANCE(TimeSpent)
 							#;   4) GlobalRefs                  SUM(GlobalRefs)
 							#;   5) VarianceGlobalRefs          VARIANCE(GlobalRefs)
 							#;   6) CommandsExecuted            SUM(CommandsExecuted)
 							#;   7) VarianceCommandsExecuted    VARIANCE(CommandsExecuted)
 							#;   8) DiskLatency                 SUM(DiskWait)
 							#;   9) VarianceDiskLatency         VARIANCE(DiskWait)
							#;------------------------------------------------------------

							set statsData=$LB(sum("Counter"),sum("TimeSpent"),var("TimeSpent"),sum("GlobalRefs"),"",sum("CommandsExecuted"),"",sum("DiskWait"),"")
						
							set tSC=$$recordSQLStatsInStmtIndx^%SYS.PTools(SQLIndexHash,$HOROLOG,statsData)
						}
					}
				}
			
				QUIT:'cursNULL
			}

			QUIT:'rtnNULL
		}
		
		QUIT:'nsNULL
	}

 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }
 
 $$$resetSQLStatsFlag(zu115x12)		// Reset SQLStats flag for current JOB to original value

 if errRowIDList'="" { set tSC=$$$ERROR($$$ObjectScriptError,"SQL error(s) have occurred during the running of this method.  Invoke the following method for additional details: set errID=##class(%SYS.PTools.Stats).getPToolsError(...)  WHERE errRowID={"_$LTS(errRowIDList,"|")_"}") }
 
 QUIT tSC
}

/// If Aggregated Data can be used for the given 'ns', 'rtn', and 'curs', then
/// return 1; Otherwise, return 0
ClassMethod useAggregatedData(ns = "", rtn = "", curs = "") As %Integer [ SqlName = PT_useAggregatedData, SqlProc ]
{
	QUIT $s((ns'="")&&(rtn'="")&&(curs'=""):$$$useStatsSQLAggregatedData(ns,rtn,curs),1:0)
}

/// <p class="info-head">
/// Method:       ExportAll [SQL: StatsSQL_ExportAll]
/// Replaces:     ExportAll [SQL: SQLStats_ExportAll]  (<class>%SYS.PTools.SQLStats</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       <BC>Maintained for Backward-Compatibility.</BC>  See exportStatsSQL(...)
/// Purpose:      This method generates two Performance Tool files containing 
///               the data from the '%SYS.PTools.StatsSQL' class and return a $LIST
///               of the output locations
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).ExportAll(...)
///                    SQL: CALL %SYS_PTools.StatsSQL_ExportAll(...)
///                         SELECT %SYS_PTools.StatsSQL_ExportAll(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Display this export file to the screen via a InterSystems IRIS Terminal:
/// 
///               set io=##class(%SYS.PTools.StatsSQL).ExportAll($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYS_PTools.StatsSQL_ExportAll('$IO')
/// 
///               Where: '$IO' = Output to the current device
///                              NOTE: '$IO' can be omitted, as it is the default
///                                    'file' when invoked via the CALL interface
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
/// 
/// Parameters:
///   filePrefix - The path in which to create and store the data from the 
///                   '%SYS.PTools.StatsSQL' class (e.g. C:\)
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
///                   ptInfo(method,statsType,variable)=value
///                   ptInfo(method,statsType,"outputFile")=The canonical name of the Export/Reporting file
/// 
/// RETURN Value: A $LIST of the output locations of the exported data; Otherwise, 
///               return the error status if one occurred
///                  $LB(filePrefix_"StatsSQL_Qry.txt",filePrefix_"StatsSQL_Stats.txt")
/// </p>
ClassMethod ExportAll(filePrefix = "", delim = "", exportPlan = 0, silent = 0, rtnName = "", modName = "", ByRef conds As %RawString, ByRef ptInfo As %RawString) As %String [ SqlName = StatsSQL_ExportAll, SqlProc ]
{
	set:delim="" delim=$C(9)	// Tab-Delimited
 	set filePrefix=$s($$$UPPER(filePrefix)="$IO":$IO,(filePrefix="")&&$ISOBJECT($g(%request)):$IO,",$DEF,,"[(","_$$$UPPER(filePrefix)_","):$$$currentDir,1:filePrefix)
	set dlm=$s(filePrefix["/":"/",1:"\")
	//MRP1096+ set:($e(filePrefix,*)'=dlm)&&(filePrefix'=$IO) filePrefix=filePrefix_dlm
	set SQLQueryFile=$s(filePrefix=$IO:$IO,1:filePrefix_"StatsSQL_Qry.txt")
	if (filePrefix=$IO)&&$ISOBJECT($g(%request)) { set format="H" }
	else { set format="Z",format(0)=delim }
	if exportPlan=0 { 
		write:'silent !,"Exporting SQL Querys to ",$s(SQLQueryFile=$IO:"(Terminal IO)",1:SQLQueryFile)
	}
	else  { 
		write:'silent !,"Exporting SQL Query Plans to ",$s(SQLQueryFile=$IO:"(Terminal IO)",1:SQLQueryFile)
	}
	set tSC=..exportStatsSQL(SQLQueryFile,.format,silent,1,exportPlan,rtnName,modName,.conds,.ptInfoSQF,,"StatsSQL.ExportAll")
	set SQLQueryFile=$s($$$ISERR(tSC):tSC,1:$g(ptInfoSQF("outputFile")))
	merge ptInfo("exportStatsSQL",1)=ptInfoSQF  // Record 'ptInfo()' from 'exportStatsSQL()' method invocation with 'statsType=1' (SQL Query Stmt/Plan rows from %SYS.PTools.StatsSQL)
	
	set SQLStatsFile=$s(filePrefix=$IO:$IO,1:filePrefix_"StatsSQL_Stats.txt")
	write:'silent !!,"Exporting SQL Stats to ",$s(SQLStatsFile=$IO:"(Terminal IO)",1:SQLStatsFile)
	set tSC=..exportStatsSQL(SQLStatsFile,.format,silent,0,0,rtnName,modName,.conds,.ptInfoSSF,,"StatsSQL.ExportAll")
	set SQLStatsFile=$s($$$ISERR(tSC):tSC,1:$g(ptInfoSSF("outputFile")))
	merge ptInfo("exportStatsSQL",0)=ptInfoSSF  // Record 'ptInfo()' from 'exportStatsSQL()' method invocation with 'statsType=0' (SQL Query Stats rows from %SYS.PTools.StatsSQL)
	
	QUIT $LB(SQLQueryFile,SQLStatsFile)
}

/// <p class="info-head">
/// Method:       Export [SQL: StatsSQL_Export]
/// Replaces:     Export [SQL: SQLStats_Export]  (<class>%SYS.PTools.SQLStats</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       <BC>Maintained for Backward-Compatibility.</BC>  See exportStatsSQL(...)
/// Purpose:      This method generates a comma delimited file containing the data
///               from the '%SYS.PTools.StatsSQL' class
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).Export(...)
///                    SQL: CALL %SYS_PTools.StatsSQL_Export(...)
///                         SELECT %SYS_PTools.StatsSQL_Export(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Display this export file to the screen via a InterSystems IRIS Terminal:
/// 
///               set io=##class(%SYS.PTools.StatsSQL).Export($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYS_PTools.StatsSQL_Export('$IO')
/// 
///               Where: '$IO' = Output to the current device
///                              NOTE: '$IO' can be omitted, as it is the default
///                                    'file' when invoked via the CALL interface
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
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
ClassMethod Export(file = "", delim = "", ByRef conds As %RawString, ByRef ptInfo As %RawString) As %String [ SqlName = StatsSQL_Export, SqlProc ]
{
	set:delim="" delim=$C(9)	// Tab-Delimited
	set logDir=$$$SYSMgrDir,hostName=$$$localHost,configName=$$$configurationName,hDate8=$zd($h,8),hTime=$tr($zt($p($h,",",2)),":","")
	set outputFileName=hostName_"_"_configName_"_"_hDate8_"_"_hTime_"_StatsSQL.psql"
 	set file=$s($$$UPPER(file)="$IO":$IO,(file="")&&$ISOBJECT($g(%request)):$IO,",$DEF,,"[(","_$$$UPPER(file)_","):$$$currentDir,1:file)
	set outputFile=$s(file="":logDir_outputFileName,1:file)
	if (outputFile=$IO)&&$ISOBJECT($g(%request)) { set format="H" }
	else { set format="Z",format(0)=delim }
	
	set tSC=..exportStatsSQL(outputFile,.format,1,,,,,.conds,.ptInfo,,"StatsSQL.Export")
	
	QUIT $s($$$ISERR(tSC):tSC,1:$g(ptInfo("outputFile")))
}

/// <p class="info-head">
/// Method:       ExportSQLQuery [SQL: StatsSQL_ExportSQLQuery]
/// Replaces:     Export [SQL: SQLQuery_Export]  (<class>%SYS.PTools.SQLQuery</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      This method generates a comma delimited file containing the SQL
///               Query data from the '%SYS.PTools.StatsSQL' class
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).ExportSQLQuery(...)
///                    SQL: CALL %SYS_PTools.StatsSQL_ExportSQLQuery(...)
///                         SELECT %SYS_PTools.StatsSQL_ExportSQLQuery(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Display this export file to the screen via a InterSystems IRIS Terminal:
/// 
///               set io=##class(%SYS.PTools.StatsSQL).ExportSQLQuery($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYS_PTools.StatsSQL_ExportSQLQuery('$IO')
/// 
///               Where: '$IO' = Output to the current device
///                              NOTE: '$IO' can be omitted, as it is the default
///                                    'file' when invoked via the CALL interface
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
/// 
/// Parameters:
///   file       - The path and file in which to create and store the data from the 
///                %SYS.PTools.SQLStats class:  (e.g. C:\exportFile.txt)
///                NOTE:    $IO = Outputs the data to the screen
///                       '$IO' = Output the data to the current device when invoked from the CALL/SELECT-interface
///                      '$DEF' = Ouput the data to the DEFAULT file when invoked from the CALL/SELECT-interface
///                   [DEFAULT: {MGR-Directory}\{computerName}_{ConfigName}_YYYYMMDD_HHMMSS_ExportSQLQuery.psql]
///   delim      - The delimiter by which to delimit the data of the exported file
///                   [DEFAULT: $C(9)  // TAB]
///   exportPlan - 0 - Export the SQL Query Text [DEFAULT]
///                1 - Export the SQL Query Plan
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
ClassMethod ExportSQLQuery(file = "", delim = "", exportPlan = 0, ByRef conds As %RawString, ByRef ptInfo As %RawString) As %String [ SqlName = StatsSQL_ExportSQLQuery, SqlProc ]
{
	set:delim="" delim=$C(9)	// Tab-Delimited
	set logDir=$$$SYSMgrDir,hostName=$$$localHost,configName=$$$configurationName,hDate8=$zd($h,8),hTime=$tr($zt($p($h,",",2)),":","")
	set outputFileName=hostName_"_"_configName_"_"_hDate8_"_"_hTime_"_StatsSQL_ExportSQLQuery.psql"
 	set file=$s($$$UPPER(file)="$IO":$IO,(file="")&&$ISOBJECT($g(%request)):$IO,",$DEF,,"[(","_$$$UPPER(file)_","):$$$currentDir,1:file)
	set outputFile=$s(file="":logDir_outputFileName,1:file)
	if (outputFile=$IO)&&$ISOBJECT($g(%request)) { set format="H" }
	else { set format="Z",format(0)=delim }
	
	set tSC=..exportStatsSQL(outputFile,.format,1,1,exportPlan,,,.conds,.ptInfo,,"StatsSQL.Export")
	
	QUIT $s($$$ISERR(tSC):tSC,1:$g(ptInfo("outputFile")))
}

/// <p class="info-head">
/// Method:       exportStatsSQL [SQL: PT_exportStatsSQL]
/// Replaces:     Export & ExportAll  (<class>%SYS.PTools.SQLStats</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      Create a Performance Tool file containing the data 
///               from the '%SYS.PTools.StatsSQL' and return the output location...
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
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).exportStatsSQL(...)
///                    SQL: CALL %SYS_PTools.PT_exportStatsSQL(...)
///                         SELECT %SYS_PTools.PT_exportStatsSQL(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Display this export file to the screen via a InterSystems IRIS Terminal:
/// 
///               set tSC=##class(%SYS.PTools.StatsSQL).exportStatsSQL($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYS_PTools.PT_exportStatsSQL('$IO','H')
/// 
///               Where: '$IO' = Output to the current device
///                              NOTE: '$IO' can be omitted, as it is the default
///                                    'file' when invoked via the CALL interface
///                       'H'  = Output the format in HTML format
///                              NOTE: 'H' can be omitted, as it is the default
///                                    'format' when invoked via the CALL interface
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
/// 
/// Parameters:
///   file       - The path and file in which to create and store the data from the 
///                %SYS.PTools.StatsSQL class:  (e.g. C:\exportFile.txt)
///                NOTE:    $IO = Outputs the data to the screen
///                       '$IO' = Output the data to the current device when invoked from the CALL/SELECT-interface
///                      '$DEF' = Ouput the data to the DEFAULT file when invoked from the CALL/SELECT-interface
///                   [DEFAULT: {Current-Directory}\PT_StatsSQL_exportStatsSQL[_{Stmt|Plan}]_YYYYMMDD_HHMMSS.{ext}]
///                WHERE {Current-Directory} = The directory of the Namespace in which
///                                            this method is invoked (e.g. $ZU(12,""))
///                NOTE 2: If Passed By Reference, then 'file' will be returned as the
///                        canonical name of the Export/Reporting file
///   format     - The output format of the Export/Reporting file
///                This parameter has the following structure of constituent elements:
///                   format=<data-format>[:$LB(<delim>,<csv-header>,<csv-footer>)]
///                Where the constituent elements have the following values:
///                   <data-format> - The format of the Export/Reporting file:
///                      - P = Printable/Viewable report file (.txt file, no pagination)
///                      - D = Comma-delimited data file (.csv file) which can be read into a spreadsheet
///                      - X = Microsoft Excel XML markup file suitable for import into Excel (.xml file)
///                      - H = HTML page file (.html file)
///                      - Z = User-defined delimiter "P" formatted file (.dlm file)
///                             NOTE: The <delim> element is required or defaulted to $C(9) (TAB)
///                Optional Elements:
///                   <delim> - User-defined delimiter  [DEFAULT: $C(9) (TAB)]
///                              NOTE: This is generally used for <data-format>="Z"
///                   <csv-header> - .csv file header for <data-format>="D":
///                      - 0 = Don't add non-standard information header to file  [DEFAULT]
///                      - 1 = Add non-standard information header to file
///                   <csv-footer> - .csv file footer for <data-format>="D":
///                      - 0 = Don't add non-standard information footer to file  [DEFAULT]
///                      - 1 = Add non-standard information footer to file
///                EXAMPLES:
///                   Valid 'format' values:
///                      - "H"             // HTML file
///                      - "D"             // CSV file with No information header or footer
///                      - "D:"_$LB(,1,1)  // CSV file with information header & footer
///                      - "Z:"_$LB("^")   // User-defined delimiter file (delim="^")
///   silent     -  0 - Display all messages during the running of this method
///                 1 - Don't display any messages during the running of this method
///   statsType  -  0 - Return SQL Query Stats rows from %SYS.PTools.StatsSQL  [DEFAULT]
///                 1 - Return SQL Query Stmt/Plan rows from %SYS.PTools.StatsSQL
///   exportPlan -  0 - Export the SQL Query Stmt Text [DEFAULT]
///                 1 - Export the SQL Query Plan
///                 NOTE: This parameter is ONLY applicable when statsType=1
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
///                   ptInfo(variable)=value
///                   ptInfo("outputFile")=The canonical name of the Export/Reporting file
///   contRowCnt -  "" - No Action
///                >=0 - Continuation from another Export, so skip the preamble code
///                   [InterSystems: Internal Purposes ONLY]
///   bcFlag     - This is a Backward-Compatibility flag used for 
///                   [InterSystems: Internal Purposes ONLY]
/// 
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod exportStatsSQL(file = "", format = "P", silent = 0, statsType = 0, exportPlan = 0, rtnName = "", modName = "", ByRef conds As %RawString, ByRef ptInfo As %RawString, contRowCnt = "", bcFlag = "") As %Status [ PublicList = (d, outputFile, thisMethod, tSC, version), SqlName = PT_exportStatsSQL, SqlProc ]
{
	set continue=(contRowCnt'=""),rowCnt=+contRowCnt
	 
 	GOTO:continue exportStatsSQLCont	// --- Skip Preamble for special case ---

 	new %msg,%objlasterror,%sqlcontext
 	new d,outputFile,thisMethod,tSC,version
 	
	set tSC=$$$OK,%msg="",SQLCODE="",outputFile=""
	set thisMethod="exportStatsSQL"
	set start=$$$sysTimestamp

 try {

	$$$setSQLStatsFlagOFF(zu115x12)	// Turn off SQLState for current JOB
	
 	set className="StatsSQL"
 	set version=$$$StatsSQLVersion
	set format=$s(format="":$s($ISOBJECT($g(%request)):"H",1:"P"),("Pp"[$e(format,1))&&$ISOBJECT($g(%request)):"H"_$e(format,2,*),1:$$$UPPER($p(format,":",1))_$s(format[":":":"_$p(format,":",2,*),1:""))
	
	set outputFile=..getOutputFile(file,className,thisMethod_"_"_$CASE(+statsType,1:$CASE(exportPlan,0:"Stmt",1:"Plan",:""),:""),format,,.tSC) THROW:$$$ISERR(tSC)
 	
	if 'silent { USE 0 write !,"Creating '%SYS.PTools.StatsSQL' Report...",!,?3,"Output File: ",$s(outputFile="":"(Terminal IO)",1:outputFile),!! }

 	if outputFile'="" { set tSC=..createAndOpenFile(outputFile) THROW:$$$ISERR(tSC) }

exportStatsSQLCont	// --- Continue Here if continue=1 ---
 	
	set statsSQLMarker=$$$StatsSQLMarker	// %SYS.PTools.StatsSQL
	set modNameINFO=$$$ModuleNameExtToInt("INFO")
	set modNameMAIN=$$$ModuleNameExtToInt("MAIN")

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
 	#;        10) Supress Output    (If 1, don't display <select-list> item)
 	#; d(1,#)=Column Data
 	#; d(2,"sort")=$LIST of #'s or Heading
 	#; d("x-heading",{Heading})=#
 	#;
 	#;--------------------------------------------------------------------------------
 	
 	if +statsType=0 {	// --- SQL Query Stats ---
	 	kill d	// Tabula Rasa!
	 	if (",StatsSQL.ExportAll,StatsSQL.Export,"[(","_bcFlag_",")) {
			set d(0,$i(d(0)))=$LB("RoutineName","Routine",30)					// 1
			set d(0,$i(d(0)))=$LB("CursorName","Cursor",15)						// 2
			set d(0,$i(d(0)))=$LB("Counter","Run Count",8)						// 3
			set d(0,$i(d(0)))=$LB("ModuleName","Module",10)						// 4
			set d(0,$i(d(0)))=$LB("StartTime","Start Time",20)					// 5
			set d(0,$i(d(0)))=$LB("GlobalRefs","Global Refs",10)				// 6
			set d(0,$i(d(0)))=$LB("CommandsExecuted","Commands Executed",12)	// 7
			set d(0,$i(d(0)))=$LB("TimeSpent","Total Time",10)					// 8
			set d(0,$i(d(0)))=$LB("RowCount","ROWCOUNT",10)						// 9
			set d(0,$i(d(0)))=$LB("Pid","Process ID",10)						// 10
			set d(0,$i(d(0)))=$LB("UserName","User Name",12)					// 11
			set d(0,$i(d(0)))=$LB("MachineName","Machine Name",12)				// 12
			set d(0,$i(d(0)))=$LB("IPAddress","IP Address",10)					// 13
			set d(0,$i(d(0)))=$LB("ExeName","EXE Name",8)						// 14

			set d(0,$i(d(0)))=$LB("StatsMarker","SQL",3,,,,,,,1)				// 15
			set d(0,$i(d(0)))=$LB("NameSpace",,20,,,,,,,1)						// 16
			set d(0,$i(d(0)))=$LB("StatsGroup","Group",8,,,,,,,1)				// 17
			set d(0,$i(d(0)))=$LB("DiskWait",,10,,,,,,,1)						// 18
			set d(0,$i(d(0)))=$LB("Parameters",,20,,,,,,,1)						// 19
	 	}
	 	else {
			set d(0,$i(d(0)))=$LB("StatsMarker","SQL",3)
			set d(0,$i(d(0)))=$LB("NameSpace",,20)
			set d(0,$i(d(0)))=$LB("RoutineName",,30)
			set d(0,$i(d(0)))=$LB("CursorName","Cursor",15)
			set d(0,$i(d(0)))=$LB("StatsGroup","Group",8)
			set d(0,$i(d(0)))=$LB("ModuleName","Module",10)
			set d(0,$i(d(0)))=$LB("StartTime",,20)
			set d(0,$i(d(0)))=$LB("RowCount",,10)
			set d(0,$i(d(0)))=$LB("Counter","RunCount",8)
			set d(0,$i(d(0)))=$LB("TimeSpent",,10)
			set d(0,$i(d(0)))=$LB("GlobalRefs",,10)
			set d(0,$i(d(0)))=$LB("CommandsExecuted",,12)
			set d(0,$i(d(0)))=$LB("DiskWait",,10)
			set d(0,$i(d(0)))=$LB("Pid",,10)
			set d(0,$i(d(0)))=$LB("IPAddress",,10)
			set d(0,$i(d(0)))=$LB("UserName",,12)
			set d(0,$i(d(0)))=$LB("MachineName",,12)
			set d(0,$i(d(0)))=$LB("ExeName",,8)
			set d(0,$i(d(0)))=$LB("Parameters",,20)
			set d(2,"sort")=$LB("RoutineInfo","Module")
	 	}
		for col=1:1:d(0) { 
			set dInfo=d(0,col),dHeader=$LG(dInfo,2) set:dHeader="" dHeader=$LG(dInfo,1),$LIST(d(0,col),2)=dHeader set d("x-heading",dHeader)=col 
			#; --- IF continue=1 ==> Populate {Output Length} since 'TXTtabHead()' isn't invoked here! ---
			if continue { set dHeaderLen=$l(dHeader),dLen=$LG(dInfo,3) set:dLen="" dLen=$$$PTSColLengthDefault set:dHeaderLen>dLen dLen=dHeaderLen set $LIST(d(0,col),4)=dLen }
		}
		set tSC=..condsMatch(.conds,.d,.condValExp)
	
		&SQL(DECLARE statsSQLCUR CURSOR FOR
		     SELECT StatsMarker, NameSpace, RoutineName, CursorName, StatsGroup, %External(ModuleName) AS ModuleName, StartTime,

			        CASE 
			           WHEN ModuleName = :modNameINFO AND %SYS_PTools.PT_useAggregatedData(NameSpace,RoutineName,CursorName)=1 
			              THEN TotalRowCount
			           WHEN ModuleName = :modNameINFO
			              THEN (SELECT SUM(RowCount)
			                    FROM %SYS_PTools.StatsSQL AS sqSSQL
			                    WHERE     sqSSQL.NameSpace = SSQL.NameSpace
                                      AND sqSSQL.RoutineName = SSQL.RoutineName
                                      AND sqSSQL.CursorName = SSQL.CursorName
			                          AND ModuleName = :modNameMAIN
			                    )
			           ELSE RowCount
			        END AS RowCount, 

			        CASE 
			           WHEN ModuleName = :modNameINFO AND %SYS_PTools.PT_useAggregatedData(NameSpace,RoutineName,CursorName)=1 
			              THEN TotalCounter
			           WHEN ModuleName = :modNameINFO 
			              THEN (SELECT SUM(Counter)
			                    FROM %SYS_PTools.StatsSQL AS sqSSQL
			                    WHERE     sqSSQL.NameSpace = SSQL.NameSpace
                                      AND sqSSQL.RoutineName = SSQL.RoutineName
                                      AND sqSSQL.CursorName = SSQL.CursorName
			                          AND ModuleName = :modNameMAIN
			                    )
			           ELSE Counter
			        END AS RunCount, 
	            
			        CASE 
			           WHEN ModuleName = :modNameINFO AND %SYS_PTools.PT_useAggregatedData(NameSpace,RoutineName,CursorName)=1 
			              THEN ROUND(TotalTimeSpent/TotalCounter,5)
			           WHEN ModuleName = :modNameINFO 
			              THEN (SELECT ROUND(AVG(TimeSpent),5)
			                    FROM %SYS_PTools.StatsSQL AS sqSSQL
			                    WHERE     sqSSQL.NameSpace = SSQL.NameSpace
                                      AND sqSSQL.RoutineName = SSQL.RoutineName
                                      AND sqSSQL.CursorName = SSQL.CursorName
			                          AND ModuleName = :modNameMAIN
			                    )
			           ELSE ROUND(TimeSpent,5)
			        END AS TimeSpent, 
		        
			        CASE 
			           WHEN ModuleName = :modNameINFO AND %SYS_PTools.PT_useAggregatedData(NameSpace,RoutineName,CursorName)=1 
			              THEN ROUND(TotalGlobalRefs/TotalCounter,2)
			           WHEN ModuleName = :modNameINFO 
			              THEN (SELECT ROUND(AVG(GlobalRefs),2)
			                    FROM %SYS_PTools.StatsSQL AS sqSSQL
			                    WHERE     sqSSQL.NameSpace = SSQL.NameSpace
                                      AND sqSSQL.RoutineName = SSQL.RoutineName
                                      AND sqSSQL.CursorName = SSQL.CursorName
			                          AND ModuleName = :modNameMAIN
			                    )
			           ELSE ROUND(GlobalRefs,2)
			        END AS GlobalRefs, 

			        CASE 
			           WHEN ModuleName = :modNameINFO AND %SYS_PTools.PT_useAggregatedData(NameSpace,RoutineName,CursorName)=1 
			              THEN ROUND(TotalCommandsExecuted/TotalCounter,2)
			           WHEN ModuleName = :modNameINFO 
			              THEN (SELECT ROUND(AVG(CommandsExecuted),2)
			                    FROM %SYS_PTools.StatsSQL AS sqSSQL
			                    WHERE     sqSSQL.NameSpace = SSQL.NameSpace
                                      AND sqSSQL.RoutineName = SSQL.RoutineName
                                      AND sqSSQL.CursorName = SSQL.CursorName
			                          AND ModuleName = :modNameMAIN
			                    )
			           ELSE ROUND(CommandsExecuted,2)
			        END AS CommandsExecuted, 

			        CASE 
			           WHEN ModuleName = :modNameINFO AND %SYS_PTools.PT_useAggregatedData(NameSpace,RoutineName,CursorName)=1 
			              THEN ROUND(TotalDiskWait/TotalCounter,5)
			           WHEN ModuleName = :modNameINFO 
			              THEN (SELECT ROUND(AVG(DiskWait),5)
			                    FROM %SYS_PTools.StatsSQL AS sqSSQL
			                    WHERE     sqSSQL.NameSpace = SSQL.NameSpace
                                      AND sqSSQL.RoutineName = SSQL.RoutineName
                                      AND sqSSQL.CursorName = SSQL.CursorName
			                          AND ModuleName = :modNameMAIN
			                    )
			           ELSE ROUND(DiskWait,5)
			        END AS DiskWait, 

		            pid, IPAddress, UserName, MachineName, ExeName,
		            $LISTTOSTRING(Parameters) AS Parameters
		     FROM %SYS_PTools.StatsSQL AS SSQL
		     WHERE StatsMarker = :statsSQLMarker
		     ORDER BY NameSpace, RoutineName, CursorName, StatsGroup
		    )
	
		set:'continue tSC=..fileHeader(outputFile,.format,"",$CLASSNAME(),thisMethod,version,.d,bcFlag) THROW:$$$ISERR(tSC)
 
	 	// --- Return rows from %SYS.PTools.StatsSQL ---
 	
		&SQL(OPEN statsSQLCUR)
		if SQLCODE<0 { set tSC=$$$ERROR($$$SQLError,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%apiSQL(SQLCODE))) THROW }
	
		FOR {
			if (",StatsSQL.ExportAll,StatsSQL.Export,"[(","_bcFlag_",")) { 
				&SQL(FETCH statsSQLCUR INTO :d(1,15), :d(1,16), :d(1,1), :d(1,2), :d(1,17), :d(1,4), :d(1,5), :d(1,9), :d(1,3), :d(1,8), :d(1,6), :d(1,7), :d(1,18), :d(1,10), :d(1,13), :d(1,11), :d(1,12), :d(1,14), :d(1,19))
			}
			else {
				&SQL(FETCH statsSQLCUR INTO :d(1,1), :d(1,2), :d(1,3), :d(1,4), :d(1,5), :d(1,6), :d(1,7), :d(1,8), :d(1,9), :d(1,10), :d(1,11), :d(1,12), :d(1,13), :d(1,14), :d(1,15), :d(1,16), :d(1,17), :d(1,18), :d(1,19))
			}
			QUIT:SQLCODE'=0
			
			CONTINUE:(rtnName'="")&&(rtnName'=d(1,3))		// RoutineName doesn't match specified 'rtnName'
			CONTINUE:(modName'="")&&(modName'=d(1,6))		// ModuleName doesn't match specified 'modName'
			if condValExp'="" { // --- Check Condition(s) via the 'conds()' array ---
				try { if @condValExp { } else { CONTINUE } } catch { } // Check if condition(s) in 'conds()' array Succeeded/Failed
			}

			set tSC=..fileBody(outputFile,.format,.d)

			set rowCnt=$I(rowCnt)	// Count Rows Processed!
 		}
	
 		set:SQLCODE<0 tSC=$$$ADDSC(tSC,$$$ERROR($$$SQLError,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%apiSQL(SQLCODE))))

		&sql(CLOSE statsSQLCUR)
 		set:SQLCODE<0 tSC=$$$ADDSC(tSC,$$$ERROR($$$SQLError,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%apiSQL(SQLCODE))))
 	}
 	elseif statsType=1 {	// --- SQL Query Stmt/Plan ---
	 	kill d	// Tabula Rasa!
		set d(0,$i(d(0)))=$LB("NameSpace",,20,,,,,,,(",StatsSQL.ExportAll,StatsSQL.Export,"[(","_bcFlag_",")))
		set d(0,$i(d(0)))=$LB("RoutineName","Routine",30)
		set d(0,$i(d(0)))=$LB("CursorName","Cursor",15)
		set d(0,$i(d(0)))=$LB("TotalCounter","RunCount",8)
		set d(0,$i(d(0)))=$LB("QueryType",,10)
		set qryCol=$i(d(0))
		set d(0,qryCol)=$LB("QueryText",$s(exportPlan:"QueryPlan",1:"QueryText"),30)
		set d(2,"sort")=$LB("Routine","Cursor")
		for col=1:1:d(0) { set dInfo=d(0,col),dHeader=$LG(dInfo,2) set:dHeader="" dHeader=$LG(dInfo,1) set d("x-heading",dHeader)=col }
		set tSC=..condsMatch(.conds,.d,.condValExp)
		
		&SQL(DECLARE statsQryCUR CURSOR FOR
		     SELECT ImportSchema, Namespace, RoutineName, CursorName, 
		            CASE 
		               WHEN %SYS_PTools.PT_useAggregatedData(NameSpace,RoutineName,CursorName)=1 THEN TotalCounter
		               ELSE (SELECT SUM(Counter)
		                     FROM %SYS_PTools.StatsSQL AS sqSSQL
			                 WHERE     sqSSQL.NameSpace = SSQL.NameSpace
                                   AND sqSSQL.RoutineName = SSQL.RoutineName
                                   AND sqSSQL.CursorName = SSQL.CursorName
		                           AND ModuleName = :modNameMAIN	/* 'MAIN' */
		                    )
		            END AS RunCount, 
		            QueryType, QueryText
		     INTO :schema, :d(1,1), :d(1,2), :d(1,3), :d(1,4), :d(1,5), :d(1,6)
		     FROM %SYS_PTools.StatsSQL AS SSQL
		     WHERE     StatsMarker = :statsSQLMarker
		           AND ModuleName = :modNameINFO					/* 'INFO' */
		     ORDER BY Namespace, RoutineName, CursorName, StatsGroup
		    )
		
		
		set tSC=..fileHeader(outputFile,.format,"",$CLASSNAME(),thisMethod,version,.d,bcFlag) THROW:$$$ISERR(tSC)
 
		set rowCnt=0
		&SQL(OPEN statsQryCUR)
		if SQLCODE<0 { set tSC=$$$ERROR($$$SQLError,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%apiSQL(SQLCODE))) THROW }
	
		FOR {
			&SQL(FETCH statsQryCUR)
			QUIT:SQLCODE'=0
			
			if condValExp'="" { // --- Check Condition(s) via the 'conds()' array ---
				try { if @condValExp { } else { CONTINUE } } catch { } // Check if condition(s) in 'conds()' array Succeeded/Failed
			}
		
			set query=d(1,qryCol)
			set queryUPPER=$$$UPPER(query)
		
			if queryUPPER["CURSOR FOR" {
				set selectLen=$l($p(queryUPPER,"CURSOR FOR",2))
				set query=$e(query,($l(query)-selectLen+1),*)
			}
			set queryUPPER=$$$UPPER(query)
			if queryUPPER["INTO ?" {
				set selectLen=$l($p(queryUPPER,"INTO ?",1))
				set queryUPPER=$p(queryUPPER,"INTO ?",2,*)
				set fromLen=$l($p(queryUPPER,"FROM",2,*))
				set part1=$e(query,($l(query)-fromLen+1),*)
				set query=part1_part2
			}
		
			kill sql,%plan set d(1,qryCol)=""	// Tabula Rasa!
			set sql($i(sql))=query
		
			do:exportPlan ShowPlan^%apiSQL(.sql,1,"",0,"",schema,1,,,silent)
		
			if +$g(%plan)'=0 { for pos=1:1:%plan set d(1,qryCol)=d(1,qryCol)_%plan(pos)_"<br/>" }
			else { set d(1,qryCol)=query_"<br/>" }
				
			set tSC=..fileBody(outputFile,.format,.d)

			set rowCnt=$I(rowCnt)	// Count Rows Processed!
 		}
	
 		set:SQLCODE<0 tSC=$$$ADDSC(tSC,$$$ERROR($$$SQLError,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%apiSQL(SQLCODE))))

		&sql(CLOSE statsQryCUR)	
 		set:SQLCODE<0 tSC=$$$ADDSC(tSC,$$$ERROR($$$SQLError,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%apiSQL(SQLCODE))))
	 	}
 		
		THROW:$$$ISERR(tSC)
 	}
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
	
	if 'silent { USE 0 write ! do $system.Status.DisplayError(tSC) }
 }
 
 	if continue { set contRowCnt=rowCnt QUIT tSC }	// Return 'rowCnt' via 'contRowCnt' [PBR]
 
 	set stop=$$$sysTimestamp
 	
 	do:$$$ISOK(tSC)&&(",StatsSQL.ExportAll,StatsSQL.Export,"'[(","_bcFlag_",")) ..fileFooter(outputFile,.format,"End of stats collection for: ##class("_$CLASSNAME()_")."_thisMethod_"(...)",.d,stop-start,rowCnt)
 
 	if outputFile'="" {		// Return to Terminal IO & Close File
 		USE 0
 		CLOSE outputFile
 	}
 	
 	$$$resetSQLStatsFlag(zu115x12)	// Reset SQLStats flag for current JOB to original value
	
	set (file,ptInfo("outputFile"))=$s(outputFile="":$IO,1:##class(%Library.File).CanonicalFilename(outputFile))
 	set ptInfo("className")=$CLASSNAME(),ptInfo("methodName")=$g(thisMethod),ptInfo("rowCnt")=$g(rowCnt),ptInfo("totalTime")=$g(stop)-$g(start)

 	QUIT tSC
}

/// <p class="info-head">
/// Method:       GetStats [SQL: N/A]
/// Replaces:     GetStats (<class>%SYS.PTools.SQLStats</class>)  <DEP>[DEPRECATED]</DEP>
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
///                  CommandsExecuted,Commands,41,311
///                  DiskWait,Disk Wait,1
///                  RowCount,Row Count,400
///                  ModuleCount,Mod Execs,1
///                  Counter,Run Count,1
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
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
ClassMethod GetStats(ByRef SQLText As %String = 0, mod As %String, showStats As %Integer = 0) As %String
{
	QUIT $$GetStats^%SYS.PTools(.SQLText,mod,showStats)
}

/// <p class="info-head">
/// Method:       GetLastSQLStats [SQL: StatsSQL_GetLastSQLStats]
/// Replaces:     GetLastSQLStats [SQL: SQLStats_GetLastSQLStats]  (<class>%SYS.PTools.SQLStats</class>)  <DEP>[DEPRECATED]</DEP>
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
///                    SQL: CALL %SYS_PTools.StatsSQL_GetLastSQLStats(...)
///                         SELECT %SYS_PTools.StatsSQL_GetLastSQLStats(...)
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
///               set tSC=##class(%SYS.PTools.StatsSQL).GetLastSQLStats() do %sqlcontext.DumpResults()
///                  OR
///               set tSC=##class(%SYS.PTools.StatsSQL).GetLastSQLStats(1)  // Automatically invokes DumpResults()
///                  OR
///               set tSC=##class(%SQL.Statement).%ExecDirect(,"CALL %SYS_PTools.GetLastSQLStats(1)")
/// 
///               %sqlcontext: The variable containing the instantiated object of the class
///                            %Library.SQLProcContext when a stored procedure is called.
///                            %sqlcontext consists of several properties, including an Error 
///                            object, the SQLCODE error status, the SQL row count, and an 
///                            error message.  This variable is reset before each execution.
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
/// 
/// Parameters:
///    dumpResults   - 1 = Automatically invoke the 'DumpResults()' if '%sqlcontext'
///                        is set to a valid value
/// 
/// RETURN Value: The status of this method's execution
/// </p>
ClassMethod GetLastSQLStats(dumpResults = 0) As %Integer [ ReturnResultsets, SqlName = StatsSQL_GetLastSQLStats, SqlProc ]
{
	QUIT $$GetLastSQLStats^%SYS.PTools(dumpResults)
}

/// <p class="info-head">
/// Query:        StatsSQLView [SQL: StatsSQLView]
/// Replaces:     SQLStatsView [SQL: SQLStatsView]  (<class>%SYS.PTools.SQLStats</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Query to replicate Backward-Compatible Query it 'Replaces'
/// Purpose:      This is a View Query that aggregates all of the data from
///               the <class>%SYS.PTools.StatsSQL</class> and presents it in
///               a precise and meaningful way.
/// 
/// Invocation:   This View Query can be invoked in the following ways:
///                  ObjectScript: N/A
///                    SQL: SELECT * FROM %SYS_PTools.StatsSQLView
/// 
/// Examples:     The following examples shows the use of this View Query:
/// 
///    #1         Aggregated Class View Query
/// 
///                  SELECT * FROM %SYS_PTools.StatsSQLView
/// 
///  Parameters:
///   N/A
/// </p>
Query StatsSQLView() As %SQLQuery(CONTAINID = 1) [ SqlView, SqlViewName = StatsSQLView ]
{
   SELECT ID, NameSpace, RoutineName, CursorName, StatsGroup, ModuleName,
          QueryCompileTime, StartTime, ImportSchema, UserName, ExeName, MachineName, IPAddress, Pid, 
          SQLStatsFlag,
       
          CASE 
            WHEN $PIECE(SQLStatsFlag,':',1)=3
              THEN 1
            ELSE 0
          END AS Details,

          CASE 
             WHEN ModuleName = -1 AND %SYS_PTools.PT_useAggregatedData(NameSpace,RoutineName,CursorName)=1 
                THEN TotalRowCount
             WHEN ModuleName = -1 
                THEN (SELECT SUM(RowCount)
                      FROM %SYS_PTools.StatsSQL AS sqSSQL
			          WHERE     sqSSQL.NameSpace = SSQL.NameSpace
                            AND sqSSQL.RoutineName = SSQL.RoutineName
                            AND sqSSQL.CursorName = SSQL.CursorName
                            AND ModuleName = 0
                      )
             ELSE RowCount
          END AS RowCount, 

          CASE 
             WHEN ModuleName = -1 AND %SYS_PTools.PT_useAggregatedData(NameSpace,RoutineName,CursorName)=1 
                THEN TotalCounter
             WHEN ModuleName = -1 
                THEN (SELECT SUM(Counter)
                      FROM %SYS_PTools.StatsSQL AS sqSSQL
			          WHERE     sqSSQL.NameSpace = SSQL.NameSpace
                            AND sqSSQL.RoutineName = SSQL.RoutineName
                            AND sqSSQL.CursorName = SSQL.CursorName
                            AND ModuleName = 0
                      )
             ELSE Counter
          END AS RunCount, 
	            
          CASE 
             WHEN ModuleName = -1 AND %SYS_PTools.PT_useAggregatedData(NameSpace,RoutineName,CursorName)=1 
                THEN TotalModuleCount
             WHEN ModuleName = -1 
                THEN (SELECT SUM(ModuleCount)
                      FROM %SYS_PTools.StatsSQL AS sqSSQL
			          WHERE     sqSSQL.NameSpace = SSQL.NameSpace
                            AND sqSSQL.RoutineName = SSQL.RoutineName
                            AND sqSSQL.CursorName = SSQL.CursorName
                            AND ModuleName = 0
                      )
             ELSE Counter
          END AS ModuleCount, 

          CASE 
             WHEN ModuleName = -1 AND %SYS_PTools.PT_useAggregatedData(NameSpace,RoutineName,CursorName)=1 
                THEN TotalTimeToFirstRow
             WHEN ModuleName = -1 
                THEN (SELECT SUM(TimeToFirstRow)
                      FROM %SYS_PTools.StatsSQL AS sqSSQL
			          WHERE     sqSSQL.NameSpace = SSQL.NameSpace
                            AND sqSSQL.RoutineName = SSQL.RoutineName
                            AND sqSSQL.CursorName = SSQL.CursorName
                            AND ModuleName = 0
                      )
             ELSE TimeToFirstRow
          END AS TimeToFirstRow, 

          CASE 
             WHEN ModuleName = -1 AND %SYS_PTools.PT_useAggregatedData(NameSpace,RoutineName,CursorName)=1 
                THEN TotalTimeSpent
             WHEN ModuleName = -1 
                THEN (SELECT SUM(TimeSpent)
                      FROM %SYS_PTools.StatsSQL AS sqSSQL
			          WHERE     sqSSQL.NameSpace = SSQL.NameSpace
                            AND sqSSQL.RoutineName = SSQL.RoutineName
                            AND sqSSQL.CursorName = SSQL.CursorName
                            AND ModuleName = 0
                      )
             ELSE TimeSpent
          END AS TimeSpent, 
          
          CASE 
             WHEN ModuleName = -1 AND %SYS_PTools.PT_useAggregatedData(NameSpace,RoutineName,CursorName)=1 
                THEN TotalGlobalRefs
             WHEN ModuleName = -1 
                THEN (SELECT SUM(GlobalRefs)
                      FROM %SYS_PTools.StatsSQL AS sqSSQL
			          WHERE     sqSSQL.NameSpace = SSQL.NameSpace
                            AND sqSSQL.RoutineName = SSQL.RoutineName
                            AND sqSSQL.CursorName = SSQL.CursorName
                            AND ModuleName = 0
                      )
             ELSE GlobalRefs
          END AS GlobalRefs, 

          CASE 
             WHEN ModuleName = -1 AND %SYS_PTools.PT_useAggregatedData(NameSpace,RoutineName,CursorName)=1 
                THEN TotalCommandsExecuted
             WHEN ModuleName = -1 
                THEN (SELECT SUM(CommandsExecuted)
                      FROM %SYS_PTools.StatsSQL AS sqSSQL
			          WHERE     sqSSQL.NameSpace = SSQL.NameSpace
                            AND sqSSQL.RoutineName = SSQL.RoutineName
                            AND sqSSQL.CursorName = SSQL.CursorName
                            AND ModuleName = 0
                      )
             ELSE CommandsExecuted
          END AS CommandsExecuted, 

          CASE 
             WHEN ModuleName = -1 AND %SYS_PTools.PT_useAggregatedData(NameSpace,RoutineName,CursorName)=1 
                THEN TotalDiskWait
             WHEN ModuleName = -1 
                THEN (SELECT SUM(DiskWait)
                      FROM %SYS_PTools.StatsSQL AS sqSSQL
			          WHERE     sqSSQL.NameSpace = SSQL.NameSpace
                            AND sqSSQL.RoutineName = SSQL.RoutineName
                            AND sqSSQL.CursorName = SSQL.CursorName
                            AND ModuleName = 0
                      )
             ELSE DiskWait
          END AS DiskWait,
          
          QueryType, QueryText, Parameters
   FROM %SYS_PTools.StatsSQL AS SSQL
}

/// <p class="info-head">
/// Query:        ViewStatsSQL [SQL: StatsSQLView]
/// Replaces:     ViewStats [SQL: ViewStats]  (<class>%SYS.PTools.SQLStats</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Query to replicate Backward-Compatible Query it 'Replaces'
/// Purpose:      This is a General Result-Set Query that aggregates all of the 
///               data from the <view>%SYS_PTools.StatsSQLView<view> and presents
///               it in a precise and meaningful way.
/// 
/// Invocation:   This General Result-Set Query can be invoked in the following 
///               ways:
///                  ObjectScript: N/A
///                    SQL: SELECT * FROM %SYS_PTools.StatsSQL_ViewStatsSQL([namespace])
/// 
/// Examples:     The following examples shows the use of this Result-Set Query:
/// 
///    #1         General Result-Set Query
/// 
///                  SELECT * FROM %SYS_PTools.StatsSQL_ViewStatsSQL()
/// 
///  Parameters:
///   ns         - The namespace from which to retrieve the SQL Query data
///                   "" = All Namespaces                    [DEFAULT]
/// </p>
Query ViewStatsSQL(ns As %String = "") As %SQLQuery(ROWSPEC = "RoutineName:%String,QueryText:%String,RunCount:%Integer,AvgRows:%Integer,AvgGlobalRefs:%Integer,AvgDiskWait:%Integer,AvgCommands:%Integer,AvgTime:%Integer,Details:%Integer,CursorName:%Integer,RoutineCursor:%Integer,ImportSchema:%String")
{
	SELECT RoutineName, QueryText, RunCount,
		  {fn round(RowCount/RunCount,2)} AS AvgRows,
		  {fn round(GlobalRefs/RunCount,2)} AS AvgGlorefs,
		  {fn round(DiskWait/RunCount,2)} AS AvgDiskWait,
		  {fn round(CommandsExecuted/RunCount,2)} AS AvgCommands,
		  {fn round(TimeSpent/RunCount,5)} AS AvgTime,
 		  Details, CursorName,RoutineName||'^'||CursorName AS RoutineCursor, ImportSchema
		
	FROM %SYS_PTools.StatsSQLView Main
	WHERE     (Namespace = :ns OR :ns IS NULL)
	      AND ModuleName = -1	/* 'INFO' */
    ORDER BY NameSpace, RoutineName, CursorName, StatsGroup
}

/// <BC>Backward-Compatible Query</BC>
Query ViewStats(NameSpace As %String = "") As %SQLQuery(ROWSPEC = "RoutineName:%String,QueryText:%String,RunCount:%Integer,AvgRows:%Integer,AvgGlobalRefs:%Integer,AvgDiskWait:%Integer,AvgCommands:%Integer,AvgTime:%Integer,Details:%Integer,CursorName:%Integer,RoutineCursor:%Integer,ImportSchema:%String")
{
	SELECT * FROM %SYS_PTools.StatsSQL_ViewStatsSQL(:NameSpace)
}

/// <p class="info-head">
/// Query:        ViewStatsSQLDetails [SQL: ViewStatsSQLDetails
/// Replaces:     ViewStatsDetails [SQL: ViewStatsDetails  (<class>%SYS.PTools.SQLStats</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Query to replicate Backward-Compatible Query it 'Replaces'
/// Purpose:      This is a Specific Result-Set Query that aggregates all of the 
///               data from the <view>%SYS_PTools.StatsSQLView<view> and presents
///               it in a precise and meaningful way.
/// 
/// Invocation:   This Specific Result-Set Query can be invoked in the following 
///               ways:
///                  ObjectScript: N/A
///                    SQL: SELECT * FROM %SYS_PTools.StatsSQL_ViewStatsSQLDetails(cursor,rtn)
/// 
/// Examples:     The following examples shows the use of this Result-Set Query:
/// 
///    #1         Specific Result-Set Query
/// 
///                  SELECT * FROM %SYS_PTools.StatsSQL_ViewStatsSQLDetails('QRS0','%sqlcq.USER.cls1.1')
/// 
///                  NOTE: The 'cursor' (QRS0) and 'rtn' (%sqlcq.USER.cls1.1) used
///                        in this example can be retrieved from the following query:
/// 
///                           SELECT * FROM %SYS_PTools.StatsSQL_ViewStatsSQL([namespace])
/// 
///  Parameters:
///   curs       - The cursor name to match against the CursorName field
///   rtn        - The routine name to match against the RoutineName field
/// </p>
Query ViewStatsSQLDetails(curs As %String, rtn As %String) As %SQLQuery(ROWSPEC = "QueryText:%String,RunCount:%Integer,AvgRows:%Integer,AvgGlobalRefs:%Integer,AvgDiskWait:%Integer,AvgCommands:%Integer,AvgTime:%Integer,ModuleName:%String,AvgModCount:%Integer") [ SqlProc ]
{
	SELECT QueryText, RunCount,
           CASE 
              WHEN ModuleName = -1	/* 'INFO' */
                 THEN {fn round(RowCount/RunCount,2)}
              ELSE {fn round(RowCount,2)}
           END AS AvgRows,

           CASE 
              WHEN ModuleName = -1	/* 'INFO' */
                 THEN {fn round(GlobalRefs/RunCount,2)}
              ELSE {fn round(GlobalRefs,2)}
           END AS AvgGlorefs,
           
           CASE 
              WHEN ModuleName = -1	/* 'INFO' */
                 THEN {fn round(DiskWait/RunCount,2)}
              ELSE {fn round(DiskWait,2)}
           END AS AvgDiskWait,

           CASE 
              WHEN ModuleName = -1	/* 'INFO' */
                 THEN {fn round(CommandsExecuted/RunCount,2)}
              ELSE {fn round(CommandsExecuted,2)}
           END AS AvgCommands,

           CASE 
              WHEN ModuleName = -1	/* 'INFO' */
                 THEN {fn round(TimeSpent/RunCount,5)}
              ELSE {fn round(TimeSpent,5)}
           END AS AvgTime,

		   %External(ModuleName),

           CASE 
              WHEN ModuleName = -1	/* 'INFO' */
                 THEN {fn round(ModuleCount/RunCount,2)}
              ELSE {fn round(ModuleCount,2)}
           END AS AvgModCount

	FROM %SYS_PTools.StatsSQLView
	WHERE     CursorName = :curs
	      AND RoutineName = :rtn
}

/// <BC>Backward-Compatible Query</BC>
Query ViewStatsDetails(CursorName As %String = "", RoutineName As %String = "") As %SQLQuery(ROWSPEC = "QueryText:%String,RunCount:%Integer,AvgRows:%Integer,AvgGlobalRefs:%Integer,AvgDiskWait:%Integer,AvgCommands:%Integer,AvgTime:%Integer,ModuleName:%String,AvgModCount:%Integer") [ SqlProc ]
{
	SELECT * FROM %SYS_PTools.StatsSQL_ViewStatsSQLDetails(:CursorName,:RoutineName)
}

/// <p class="info-head">
/// Method:       QueryText [SQL: N/A]
/// Replaced By:  getQueryText (<class>%SYS.PTools.StatsSQL</class>) 
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// Purpose:      This method retrieves the SQL Query Text given the parameters:
///               'CN', 'Rtn', & 'Internal'
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).QueryText(...)
///                    SQL: N/A
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Retrieve the SQL Text for any of the data rows retrieved
///               from invoking the 'exportStatsSQL()' method:
/// 
///               CALL %SYS_PTools.PT_exportStatsSQL()
///               set sql=##class(%SYS.PTools.StatsSQL).QueryText("SQLStats0","PToolsSQLStats"_$JOB)
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
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
ClassMethod QueryText(CN As %String, Rtn As %String, Internal As %Boolean = 0) As %String
{
	set qt=..getQueryText($NAMESPACE,$g(Rtn),$g(CN),Internal)

	QUIT $S(qt?1"0 ".e:"",1:qt)
}

/// <p class="info-head">
/// Method:       getQueryText [SQL: N/A]
/// Replaces:     QueryText (<class>%SYS.PTools.SQLStats</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Functionality
/// Purpose:      This method retrieves the SQL Query Text given the parameters:
///               'ns', 'rtn', 'curs', & 'getInt'
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).getQueryText(...)
///                    SQL: N/A
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Retrieve the SQL Text for any of the data rows retrieved
///               from invoking the 'exportStatsSQL()' method:
/// 
///               CALL %SYS_PTools.PT_exportStatsSQL()
///               set sql=##class(%SYS.PTools.StatsSQL).getQueryText($NAMESPACE,"PToolsSQLStats"_$JOB,"SQLStats0")
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
/// 
/// Parameters:
///   ns         - The namespace from which to retrieve the SQL Query Text
///   rtn        - The routine from which to retrieve the SQL Query Text
///   curs       - The cursor from which to retrieve the SQL Query Text
///   getInt     - 0 = Return the External Query Text
///                1 = Return the Internal Query Text
/// 
/// Return: Return either the Internal or External SQL Query Text; Otherwise,
///         return the Error Status if an error occurs.
/// </p>
ClassMethod getQueryText(ns As %String = "", rtn As %String = "", curs As %String = "", getInt As %Boolean = 0) As %String [ PublicList = (curs, ns, rtn, sqlExt, sqlInt) ]
{
	new %msg,%objlasterror
	new sqlExt,sqlInt
	set tSC=$$$OK,%msg="",SQLCODE=""
	set thisMethod="getQueryText"
	set:ns="" ns=$NAMESPACE
	set modNameINFO=$$$ModuleNameExtToInt("INFO")
	$$$AddAllRoleTemporary

 try {

	$$$setSQLStatsFlagOFF(zu115x12)	// Turn off SQLState for current JOB

	&SQL(SELECT SQLTextRaw, QueryText
		 INTO :sqlInt, :sqlExt
		 FROM %SYS_PTools.StatsSQL
		 WHERE     Namespace = :ns
		       AND RoutineName = :rtn
		       AND CursorName = :curs
		       AND ModuleName = :modNameINFO
		)

 	set:SQLCODE'=0 tSC=$$$ERROR($$$SQLError,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%SYS.PTools(SQLCODE)))
 		
	THROW:$$$ISERR(tSC)
	
	set:getInt&&$LL(sqlInt) $LIST(sqlInt,1)=$$$StripLeadingWhiteSpace($LG(sqlInt,1))

 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }
 
 $$$resetSQLStatsFlag(zu115x12)		// Reset SQLStats flag for current JOB to original value

 QUIT $s($$$ISERR(tSC):tSC,getInt=0:$$$StripLeadingWhiteSpace(sqlExt),1:sqlInt)
}

/// <p class="info-head">
/// Method:       ImportSchema [SQL: N/A]
/// Replaced By:  getImportSchema (<class>%SYS.PTools.StatsSQL</class>) 
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// Purpose:      This method retrieves the Import Schema given the parameters:
///               'CN', 'Rtn', & 'Internal'
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).ImportSchema(...)
///                    SQL: N/A
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Retrieve the SQL Text for any of the data rows retrieved
///               from invoking the 'exportStatsSQL()' method:
/// 
///               CALL %SYS_PTools.PT_exportStatsSQL()
///               set iSchema=##class(%SYS.PTools.StatsSQL).ImportSchema("SQLStats0","PToolsSQLStats"_$JOB)
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
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
ClassMethod ImportSchema(CN As %String, Rtn As %String, Internal As %Boolean = 0) As %String
{
	set is=..getImportSchema($NAMESPACE,$g(Rtn),$g(CN))
	
	QUIT $S(is?1"0 ".e:"",1:is)
}

/// <p class="info-head">
/// Method:       getImportSchema [SQL: N/A]
/// Replaces:     ImportSchema (<class>%SYS.PTools.SQLStats</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Functionality
/// Purpose:      This method retrieves the Import Schema given the parameters:
///               'ns', 'rtn', & 'curs'
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).getImportSchema(...)
///                    SQL: N/A
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Retrieve the SQL Text for any of the data rows retrieved
///               from invoking the 'exportStatsSQL()' method:
/// 
///               CALL %SYS_PTools.PT_exportStatsSQL()
///               set iSchema=##class(%SYS.PTools.StatsSQL).getImportSchema($NAMESPACE,"PToolsSQLStats"_$JOB,"SQLStats0")
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
/// 
/// Parameters:
///   ns         - The namespace from which to retrieve the SQL Query Text
///   rtn        - The routine from which to retrieve the SQL Query Text
///   curs       - The cursor from which to retrieve the SQL Query Text
/// 
/// Return: Return the Import Schema; Otherwise, return the Error Status if 
///         an error occurs.
/// </p>
ClassMethod getImportSchema(ns As %String = "", rtn As %String = "", curs As %String = "") As %String [ PublicList = (curs, ns, rtn, schema) ]
{
	new %msg,%objlasterror
	new schema
	set tSC=$$$OK,%msg="",SQLCODE=""
	set thisMethod="getImportSchema"
	set:ns="" ns=$NAMESPACE
	set modNameINFO=$$$ModuleNameExtToInt("INFO")
	$$$AddAllRoleTemporary

 try {

	$$$setSQLStatsFlagOFF(zu115x12)	// Turn off SQLState for current JOB

	&SQL(SELECT ImportSchema
		 INTO :schema
		 FROM %SYS_PTools.StatsSQL
		 WHERE     Namespace = :ns
		       AND RoutineName = :rtn
		       AND CursorName = :curs
		       AND ModuleName = :modNameINFO
		)

 	set:SQLCODE'=0 tSC=$$$ERROR($$$SQLError,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%SYS.PTools(SQLCODE)))
 		
	THROW:$$$ISERR(tSC)

 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }
 
 $$$resetSQLStatsFlag(zu115x12)		// Reset SQLStats flag for current JOB to original value

 QUIT $s($$$ISERR(tSC):tSC,1:schema)
}

/// <p class="info-head">
/// Method:       clearStatsSQL [SQL: PT_clearStatsSQL]
/// Replaces:     Purge [SQL: StatsSQL_Purge] (<class>%SYS.PTools.SQLStats</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      This method deletes all of the data stored in the 
///               '%SYS.PTools.StatsSQL' class, based on the specified parameters:
///               'ns' & 'rtn'
/// 
///               This method clears SQLStats which are gathered when the 
///               SQLStats-flag is turned ON, a SQL Statement is invoked, and the 
///               SQLStats-flag is turned OFF, as in the following example:
///                  set SQLStatsJOB=$SYSTEM.SQL.SetSQLStatsFlagJob(3) // SQLStats-flag ON
///                  set sql($i(sql))="SELECT COUNT(*) FROM Sample.Person"
///                  // Use Dynamic SQL Query Interface (%SQL.Statement) to invoke 
///                  // SQL Statement & collect SQLStats data:
///                  //   %New() ... %Prepare(.sql) ... %Execute() ... %Next() ... %OnClose()
///                  set SQLStatsJOB=$SYSTEM.SQL.SetSQLStatsFlagJob(0) // SQLStats-flag OFF
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).clearStatsSQL(...)
///                    SQL: CALL %SYS_PTools.PT_clearStatsSQL(...)
///                         SELECT %SYS_PTools.PT_clearStatsSQL(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Delete all of the data stored in the '%SYS.PTools.StatsSQL' 
///               class in the 'SAMPLES' namespace:
/// 
///               set stats=##class(%SYS.PTools.StatsSQL).clearStatsSQL("SAMPLES")
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
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
///                     following class: %SYS.PTools.StatsSQL
///                    [DEFAULT: 0]
///   ptInfo      - A Pass By Reference information array that returns
///                 detailed information to the user in the following format:
///                    ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                 Where category = { "cnt" | "curr" | "term" | ... }
///                       variable = A var corresponding to the given 'category'
/// 
///                 Example:
///                    ptInfo("cnt","clearStatsSQL")=The number of rows deleted 
///                                                  via this method
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the number of Stats rows deleted from the following class; 
///               Otherwise, return an error message if an error occurred:
///                  %SYS.PTools.StatsSQL
/// </p>
ClassMethod clearStatsSQL(ns As %String = "", rtn As %String = "", ph3 As %Integer = 0, clearAll As %Integer = 0, clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_clearStatsSQL, SqlProc ]
{
	QUIT $$clearStatsSQL^%SYS.PTools(ns,rtn,ph3,clearAll,clearErrs,returnType,.ptInfo)
}

/// <p class="info-head">
/// Method:       clearStatsSQLAllNS [SQL: PT_clearStatsSQLAllNS]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method deletes all of the data stored in the 
///               '%SYS.PTools.StatsSQL' class in All Namespaces on a system for 
///               which the user has Write Privileges (Write infers Read), based 
///               on the optional 'rtn' parameter...
/// 
///               This method clears SQLStats in all namespaces which are gathered 
///               when the SQLStats-flag is turned ON, a SQL Statement is invoked, 
///               and the SQLStats-flag is turned OFF, as in the following example:
///                  set SQLStatsJOB=$SYSTEM.SQL.SetSQLStatsFlagJob(3) // SQLStats-flag ON
///                  set sql($i(sql))="SELECT COUNT(*) FROM Sample.Person"
///                  // Use Dynamic SQL Query Interface (%SQL.Statement) to invoke 
///                  // SQL Statement & collect SQLStats data:
///                  //   %New() ... %Prepare(.sql) ... %Execute() ... %Next() ... %OnClose()
///                  set SQLStatsJOB=$SYSTEM.SQL.SetSQLStatsFlagJob(0) // SQLStats-flag OFF
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).clearStatsSQLAllNS(...)
///                    SQL: CALL %SYS_PTools.PT_clearStatsSQLAllNS(...)
///                         SELECT %SYS_PTools.PT_clearStatsSQLAllNS(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Delete all of the data stored in the '%SYS.PTools.StatsSQL' class
///               in all namespaces on the system:
/// 
///               set status=##class(%SYS.PTools.StatsSQL).clearStatsSQLAllNS()
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
/// 
/// Parameters:
///   rtn         - The routine in which to clear SQL Statistics
///                 If none provided, clear all routines in all appropriate
///                 namespaces
///                    [OPTIONAL]
///   ph2         - Placeholder Parameter for future extensibility
///   ph3         - Placeholder Parameter for future extensibility
///   clearAll    - 0 = Perform a normal clear, but leave the 'INFO' rows
///                 1 = Clear everything including the 'INFO' rows
///                    [DEFAULT: 0]
///   clearErrs   - 0 = Don't delete the 'PTools' Application Errors
///                 1 = Delete all of the 'PTools' Application Errors
///                    [DEFAULT: 0]
///   returnType  - 0 = Return a %Status code of either $$$OK or $$$ERROR()
///                 1 = Return the total number of Stats rows deleted from the 
///                     following class, for each namespace: %SYS.PTools.StatsSQL
///                    [DEFAULT: 0]
///   ptInfo      - A Pass By Reference information array that returns
///                 detailed information to the user in the following format:
///                    ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                 Where category = { "cnt" | "curr" | "term" | ... }
///                       variable = A var corresponding to the given 'category'
/// 
///                 Example:
///                    ptInfo("cnt","clearStatsSQLAllNS")=The number of rows deleted 
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the number of Stats rows deleted from the following class; 
///               Otherwise, return an error message if an error occurred:
///                  %SYS.PTools.StatsSQL
/// </p>
ClassMethod clearStatsSQLAllNS(rtn As %String = "", ph2 As %Integer = 0, ph3 As %String = "", clearAll As %Integer = 0, clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_clearStatsSQLAllNS, SqlProc ]
{
	QUIT $$clearStatsSQLAllNS^%SYS.PTools(rtn,ph2,ph3,clearAll,clearErrs,returnType,.ptInfo)
}

/// <p class="info-head">
/// Method:       Purge [SQL: StatsSQL_Purge]
/// Replaced BY:  clearStatsSQL [SQL: PT_clearStatsSQL] (<class>%SYS.PTools.StatsSQL</class>) 
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// Purpose:      This method deletes all of the data stored in the 
///               '%SYS.PTools.StatsSQL' class, based on the specified parameters:
///               'ns' & 'rtn'
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.StatsSQL).Purge(...)
///                    SQL: CALL %SYS_PTools.StatsSQL_Purge(...)
///                         SELECT %SYS_PTools.StatsSQL_Purge(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Delete all of the data stored in the '%SYS.PTools.StatsSQL' 
///               class in the 'SAMPLES' namespace:
/// 
///               set stats=##class(%SYS.PTools.StatsSQL).Purge("SAMPLES")
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
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
///                     following class: %SYS.PTools.StatsSQL
///                    [DEFAULT: 0]
///   ptInfo      - A Pass By Reference information array that returns
///                 detailed information to the user in the following format:
///                    ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                 Where category = { "cnt" | "curr" | "term" | ... }
///                       variable = A var corresponding to the given 'category'
/// 
///                 Example:
///                    ptInfo("cnt","clearStatsSQL")=The number of rows deleted 
///                                                  via this method [Routine Method]
///                    ptInfo("cnt","Purge")=The number of rows deleted 
///                                          via this method         [Class Method]
///    
/// RETURN Value: Return a %Status code of either $$$OK or $$$ERROR()
/// </p>
ClassMethod Purge(ns As %String = "", rtn As %String = "", ph3 As %Integer = 0, clearAll As %Integer = 0, clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = StatsSQL_Purge, SqlProc ]
{
	set tSC=$$clearStatsSQL^%SYS.PTools(ns,rtn,ph3,clearAll,clearErrs,returnType,.ptInfo)
	
	set ptInfo("cnt","Purge")=$g(ptInfo("cnt","clearStatsSQL"))
	
	QUIT tSC
}

/// <p class="info-head">
/// <STUB>Stub:    For the 'newSQLStats()' method in the '%SYS.PTools.MAC' routine</STUB>
/// Status:  New Method to replicate Backward-Compatible Method it 'Replaces'
/// </p>
ClassMethod newSQLStats(SQLText, SQLType, ns, rtn, curs, compTime = 0, SQLIndexHash = "", ucqInfo = "")
{
	do newSQLStats^%SYS.PTools(SQLText, SQLType, ns, rtn, curs, compTime, SQLIndexHash, ucqInfo)
}

/// <p class="info-head">
/// <STUB>Stub:    For the 'startSQLStats()' method in the '%SYS.PTools.MAC' routine</STUB>
/// Status:  New Method to replicate Backward-Compatible Method it 'Replaces'
/// </p>
ClassMethod startSQLStats(ns, rtn, curs, params, SQLIndexHash, flag, collect)
{
	do startSQLStats^%SYS.PTools(ns, rtn, curs, params, SQLIndexHash, flag, collect)
}

/// <p class="info-head">
/// <STUB>Stub:    For the 'stopSQLStats()' method in the '%SYS.PTools.MAC' routine</STUB>
/// Status:  New Method to replicate Backward-Compatible Method it 'Replaces'
/// </p>
ClassMethod stopSQLStats(ns, rtn, curs, rowCount = 0, SQLIndexHash, flag, collect)
{
	do stopSQLStats^%SYS.PTools(ns, rtn, curs, rowCount, SQLIndexHash, flag, collect)
}

/// <p class="info-head">
/// <STUB>Stub:    For the 'saveSQLStats()' method in the '%SYS.PTools.MAC' routine</STUB>
/// Status:  New Method to replicate Backward-Compatible Method it 'Replaces'
/// </p>
ClassMethod saveSQLStats(ns, rtn, curs, mod, rowCount, SQLIndexHash)
{
	do saveSQLStats^%SYS.PTools(ns, rtn, curs, mod, rowCount, SQLIndexHash)
}

/// <p class="section-head">
/// <b>                   ShowPlanAlt  U T I L I T I E S                          </b>
///                       ------------------------------
/// </p>
/// 
/// <p class="info-head">
/// Method:       possiblePlans
/// Replaces:     PossiblePlans (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      Generate a %plan() arrays for the SQL Plan Path specified for
///               the given 'sql' Query Statement.  This method processed by the 
///               ShowPlanAlt^%apiSQL() method and other such interfaces...
/// 
///  Parameters:
///    sql          - An array of the SQL Statement in the following format:
///                      sql={ln# counter}
///                      sql({ln#})={SQL Statement}
///    PPcost       - The cost of the SQL Plan Path specified 
///    num          - The cost number of the SQL Plan Path specified 
///    level        - The cost level of the SQL Plan Path specified 
///    arr          - 0 = Output the %plan(1:%plan) array via WRITE
///                   1 = Leave the resulting plan lines in the array %plan(1:%plan)
///    showStats    - 0 = Do not show stats as part of the plan  [DEFAULT]
///                   1 = Run the SQL query to generate stats and output the stats as part of the plan text
///                   2 = Lookup the stats in %SYS.PTools.StatsSQL
///                   3 = Generate alternate plan for the Portal
///    schemaImport - Used with the #IMPORT preprocessor directive, one or more schema  
///                   names to search to supply the schema name for an unqualified 
///                   table name in an Embedded SQL query. You can specify a single 
///                   schema name, or a comma-separated list of schema names. 
///                      NOTE: All schemas must be in the current namespace.
///                            #IMPORT directives are additive. Specifying a second 
///                            #IMPORT does not inactivate the list of schema names 
///                            specified in a prior #IMPORT.
///                     [DEFAULT: ""]
///    schemaPath   - Used with the #SQLCompile Path preprocessor directive, one or more
///                   schema names to search, refered to as the schema search path, for 
///                   any subsequent Embedded SQL query statements.  You can specify a 
///                   single schema name, or a comma-separated list of schema names.
///                       NOTE: #SQLCompile Path directive overwrites the path specified 
///                             in a prior #SQLCompile Path directive; it does not overwrite 
///                             schema names specified in prior #IMPORT directives.
///                      [DEFAULT: ""]
///    preparse     - 0 = Do not do any preparsing to the SQL statement  [DEFAULT]
///                   1 = Preparse the SQL statement to perform literal replacement
///                      NOTE: ShowPlan call from the SMP will call with preparse=1 so the
///                            plan reflects the same execution path as the Execute Query will 
///    hash         - A hash string of the %plan() array: $$Hash^%SYS.SQLSRV(str,.%plan,.Hval)
///                      [PASS BY REFERENCE]
///    silent       - 0 = Output information for this method invocation
///                   1 = Don't perform any writes within this method invocation
///    
/// RETURN Value: The status of this method; Otherwise, return an error message 
///               if an error occurred
/// </p>
ClassMethod possiblePlans(ByRef sql As %RawString, PPcost As %Integer = 0, num As %Integer = 0, level As %Integer = 0, arr As %Integer = 0, showStats As %Integer = 0, schemaImport As %String = "", schemaPath As %String = "", preparse As %Integer = 0, ByRef hash As %String = "", silent As %Integer = 0)
{
	QUIT $$possiblePlans^%SYS.PTools(.sql,PPcost,num,level,arr,showStats,schemaImport,schemaPath,preparse,.hash,silent)
}

/// <p class="info-head">
/// Query:        possiblePlans [SQL: PT_possiblePlans]
/// Replaces:     PossiblePlans [SQL: PossiblePlans]  (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Query to replicate Backward-Compatible Query it 'Replaces'
/// Purpose:      This is an Custom Class Query, and the Result-Set will be generated
///               and accessed by invoking the following methods, which mimic the
///               SQL OPEN/FETCH/CLOSE operations:
///                  - possiblePlansExecute(.qHandle,.sql)         [OPEN]
///                  - possiblePlansFetch(.qHandle,.Row,.AtEnd)    [FETCH]
///                  - possiblePlansClose(.qHandle)                [CLOSE]
/// 
///  Parameters:
///   sql          - An string or array of the SQL Statement in the following format:
///                      sql={SQL Statement}
///                         OR
///                      sql={ln# counter}
///                      sql({ln#})={SQL Statement}
/// </p>
Query possiblePlans(sql As %String) As %Query(ROWSPEC = "ID:%Integer,Cost:%Integer,MapType:%String(MAXLEN=15),StartingMap:%String(MAXLEN=30),Plan:%String(MAXLEN=15)") [ SqlName = PT_possiblePlans, SqlProc ]
{
}

/// <p class="info-head">
/// Method:       possiblePlansExecute
/// Replaces:     PossiblePlansExecute (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      Mimic an SQL OPEN and create a Result-Set by invoking the method
///               ShowPlanAlt^%apiSQL(...) for the specified 'sql' parameter.
///               The Result-Set created is in the following format:
///                  %AltPlan(qHandle,0)=$LIST(cost,num,$$map^%SYS.PTools(...))
///                  %AltPlan(qHandle)=%plan()
/// 
///  Parameters:
///   qHandle      - Query Handle
///   sql          - An string or array of the SQL Statement in the following format:
///                      sql={SQL Statement}
///                         OR
///                      sql={ln# counter}
///                      sql({ln#})={SQL Statement}
///   
/// RETURN Value: The status of this method; Otherwise, return an error message 
///               if an error occurred
/// </p>
ClassMethod possiblePlansExecute(ByRef qHandle As %Binary, sql As %String) As %Status [ PublicList = (backgrnd, showErr, wrtref) ]
{
	new backgrnd,showErr,wrtref
 	set tSC=$$$OK
	
 try {
	set:sql'=+sql sql(1)=sql,sql=1	
	set backgrnd=1,wrtref="showErr"	// Record any SQL errors in the 'showErr' array
	
	do ShowPlanAlt^%apiSQL(.sql,1,,,,,1,,1)
	do:$d(@wrtref)>1 ##class(%SQL.Manager.ShowPlan).ShowPlanSQLError(.@wrtref)	// Display SQL Errors with proper formatting!

	set qHandle=0
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }    
	QUIT tSC
}

/// <p class="info-head">
/// Method:       possiblePlansFetch
/// Replaces:     PossiblePlansFetch (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Query to replicate Backward-Compatible Query it 'Replaces'
/// Purpose:      Mimic an SQL FETCH and return a 'Row' of the Result-Set by 
///               iterating over the '%AltPlan(qHandle)' array with the 'qHandle'
///               The Result-Set 'Row' is returned in the following format:
///                  $LIST(qHandle,cost,map,type,"Plan")
/// 
///  Parameters:
///   qHandle      - Query Handle
///   Row          - A row of the SQL Query Result-Set in the following format:
///                     $LIST(qHandle,cost,map,type,"Plan")
///   AtEnd        - A FETCH marker with the following values:
///                     0 = More rows to FETCH    [DEFAULT]
///                     1 = No more rows to FETCH
///   
/// RETURN Value: The status of this method; Otherwise, return an error message 
///               if an error occurred
/// </p>
ClassMethod possiblePlansFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = possiblePlansExecute ]
{
	set qHandle=$O(%AltPlan(qHandle))
	If qHandle="" set AtEnd=1,Row="" QUIT $$$OK
	
	set cost=$FN($LG(%AltPlan(qHandle,0),1),"N",1)
	set map=$LG($LG(%AltPlan(qHandle,0),3),2)
	set type=$LG($LG(%AltPlan(qHandle,0),3),1)
	set Row=$LB(qHandle,cost,map,type,"Plan")
	
	Quit $$$OK
}

/// <p class="info-head">
/// Method:       possiblePlansClose
/// Replaces:     PossiblePlansClose (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      Mimic an SQL CLOSE by clearing the Result-Set
/// 
///  Parameters:
///   qHandle      - Query Handle
///   
/// RETURN Value: The status of this method; Otherwise, return an error message 
///               if an error occurred
/// </p>
ClassMethod possiblePlansClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = possiblePlansFetch ]
{
	kill %AltPlan
	Quit $$$OK
}

/// <p class="info-head">
/// Query:        possiblePlansStats [SQL: PT_possiblePlansStats]
/// Replaces:     PossiblePlansStats [SQL: PossiblePlansStats]  (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Query to replicate Backward-Compatible Query it 'Replaces'
/// Purpose:      This is an Custom Class Query, and the Result-Set will be generated
///               and accessed by invoking the following methods, which mimic the
///               SQL OPEN/FETCH/CLOSE operations:
///                  - possiblePlansStatsExecute(.qHandle,.sql)         [OPEN]
///                  - possiblePlansStatsFetch(.qHandle,.Row,.AtEnd)    [FETCH]
///                  - possiblePlansStatsClose(.qHandle)                [CLOSE]
/// 
///  Parameters:
///   sql	       - An string or array of the SQL Statement in the following format:
///                      sql={SQL Statement}
///                         OR
///                      sql={ln# counter}
///                      sql({ln#})={SQL Statement}
///   ids          - A comma (,) delimited list of Possible Plans IDs in the
///                  following format: ids="[,ID]...[,ID]"   (e.g. ",1,3")
/// </p>
Query possiblePlansStats(sql As %String, ids As %String) As %Query(ROWSPEC = "ID:%Integer,Cost:%Integer,StartingMap:%String,GlobalRef:%Integer,Commands:%Integer,TotalTime:%Integer,RowsReturned:%Integer,Plan:%String") [ SqlName = PT_possiblePlansStats, SqlProc ]
{
}

/// <p class="info-head">
/// Method:       possiblePlansStatsExecute
/// Replaces:     PossiblePlansStatsExecute (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      Mimic an SQL OPEN and create a Result-Set by invoking the method
///               ShowPlanAlt^%apiSQL(...) for the specified 'sql' & 'ids' parameters.
///               The Result-Set created is in the following format:
///                  %AltPlan(qHandle,0)=$LIST(cost,num,$$map^%SYS.PTools(...))
///                  %AltPlan(qHandle)=%plan()
/// 
///  Parameters:
///   qHandle      - Query Handle
///   sql          - An string or array of the SQL Statement in the following format:
///                      sql={SQL Statement}
///                         OR
///                      sql={ln# counter}
///                      sql({ln#})={SQL Statement}
///   ids          - A comma (,) delimited list of Possible Plans IDs in the
///                  following format: ids="[,ID]...[,ID]"   (e.g. ",1,3")
///   
/// RETURN Value: The status of this method; Otherwise, return an error message 
///               if an error occurred
/// </p>
ClassMethod possiblePlansStatsExecute(ByRef qHandle As %Binary, sql As %String, ids As %String) As %Status [ PublicList = (backgrnd, showErr, wrtref) ]
{
	new backgrnd,showErr,wrtref
 	set tSC=$$$OK
	
 try {
	set:sql'=+sql sql(1)=sql,sql=1	
	set idlist=""
	for pos=1:1:$L(ids,",") set:$p(ids,",",pos)'="" idlist=idlist_","_$P(ids,",",pos)
	set idlist=$e(idlist,2,*)
	set backgrnd=1,wrtref="showErr"	// Record any SQL errors in the 'showErr' array
	
	do ShowPlanAlt^%apiSQL(.sql,1,,1,,,0,idlist,1)
	do:$d(@wrtref)>1 ##class(%SQL.Manager.ShowPlan).ShowPlanSQLError(.@wrtref)	// Display SQL Errors with proper formatting!

	set qHandle=0
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }    
	QUIT tSC
}

/// <p class="info-head">
/// Method:       possiblePlansStatsFetch
/// Replaces:     PossiblePlansStatsFetch (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      Mimic an SQL FETCH and return a 'Row' of the Result-Set by 
///               iterating over the '%AltPlan(qHandle)' array with the 'qHandle'
///               The Result-Set 'Row' is returned in the following format:
///                  $LIST(qHandle,cost,map,globals,commands,time,rows,"Plan")
/// 
///  Parameters:
///   qHandle      - Query Handle
///   Row          - A row of the SQL Query Result-Set in the following format:
///                     $LIST(qHandle,cost,map,type,"Plan")
///   AtEnd        - A FETCH marker with the following values:
///                     0 = More rows to FETCH    [DEFAULT]
///                     1 = No more rows to FETCH
///   
/// RETURN Value: The status of this method; Otherwise, return an error message 
///               if an error occurred
/// </p>
ClassMethod possiblePlansStatsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = possiblePlansStatsExecute ]
{
	set qHandle=$O(%AltPlan(qHandle))
	If qHandle="" set AtEnd=1,Row="" QUIT $$$OK

	set line=1
	FOR {
		set line=$O(%AltPlan(qHandle,line),1,data)
		QUIT:line=""
		CONTINUE:data'="<stats>"
		
		FOR {
			set line=$o(%AltPlan(qHandle,line),1,data)
			QUIT:(data="</stats>")||(data="")	// End of Statistics Info!
			
			set:data["<TimeSpent" time=$p($p(data,">",2),"<",1)
			set:data["<GlobalRefs" globals=$p($p(data,">",2),"<",1)
			set:data["<CommandsExecuted" commands=$p($p(data,">",2),"<",1)
			set:data["<RowCount" rows=$p($p(data,">",2),"<",1)
		}
			
		QUIT
	}
	
	set cost=$FN($LG(%AltPlan(qHandle,0),1),"N",1)
	set map=$LG($LG(%AltPlan(qHandle,0),3),1)
	set Row=$LB(qHandle,cost,map,globals,commands,time,rows,"Plan")
	
	Quit $$$OK
}

/// <p class="info-head">
/// Method:       possiblePlansStatsClose
/// Replaces:     PossiblePlansStatsClose (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      Mimic an SQL CLOSE by clearing the Result-Set
/// 
///  Parameters:
///   qHandle      - Query Handle
///   
/// RETURN Value: The status of this method; Otherwise, return an error message 
///               if an error occurred
/// </p>
ClassMethod possiblePlansStatsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = possiblePlansStatsFetch ]
{
	kill %AltPlan
	Quit $$$OK
}

/// <p class="info-head">
/// Method:       changeCost
/// Replaces:     ChangeCost (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      * INTERNAL USE ONLY *
/// NOTE:         This method is ONLY provided as an interface for the purpose
///               of backward compatibility
/// 
///  Parameters:
///    PPcost       - The cost of the SQL Plan Path specified 
///    num          - The cost number of the SQL Plan Path specified 
///    level        - The cost level of the SQL Plan Path specified
///    dmt          - 
///    dmts         - 
///    dalg         - 
///    silent       - 0 = Output information for this method invocation
///                   1 = Don't perform any writes within this method invocation
///   
/// RETURN Value: The status of this method; Otherwise, return an error message 
///               if an error occurred
/// </p>
ClassMethod changeCost(PPcost As %Float, num As %Integer, level As %Integer, ByRef dmt As %RawString, ByRef dmts As %RawString, ByRef dalg As %RawString, silent As %Integer = 0)
{
	QUIT $$changeCost^%SYS.PTools(PPcost,num,level,.dmt,.dmts,.dalg,silent)
}

/// <p class="info-head">
/// Method:       buildPPcost
/// Replaces:     BuildPPcost (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      * INTERNAL USE ONLY *
/// NOTE:         This method is ONLY provided as an interface for the purpose
///               of backward compatibility
/// 
///  Parameters:
///    qoqn         - 
///    dmt          - 
///    dmts         - 
///    dalg         - 
///    PPcost       - An array of query cost details to return to the invoking method
///    silent       - 0 = Output information for this method invocation
///                   1 = Don't perform any writes within this method invocation
///   
/// RETURN Value: The status of this method; Otherwise, return an error message 
///               if an error occurred
/// </p>
ClassMethod buildPPcost(qoqn As %Float, ByRef dmt As %RawString, ByRef dmts As %RawString, ByRef dalg As %RawString, ByRef PPcost As %RawString, silent As %Integer = 0) [ PublicList = ptfjoo ]
{
	QUIT $$buildPPcost^%SYS.PTools(qoqn,.dmt,.dmts,.dalg,.PPcost,silent)
}

/// <p class="info-head">
/// Method:       map
/// Replaces:     map (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      * INTERNAL USE ONLY *
/// NOTE:         This method is ONLY provided as an interface for the purpose
///               of backward compatibility
/// 
///  Parameters:
///    data         - 
///    mt           - 
///    mts          - 
///    alg          -
///    qnum         - 
///    str          -  
///    silent       - 0 = Output information for this method invocation
///                   1 = Don't perform any writes within this method invocation
///   
/// RETURN Value: The status of this method; Otherwise, return an error message 
///               if an error occurred
/// </p>
ClassMethod map(data As %String, ByRef mt As %RawString, ByRef mts As %RawString, ByRef alg As %RawString, qnum As %Integer, str As %Integer, silent As %Integer = 0)
{
	QUIT $$map^%SYS.PTools(data,.mt,.mts,.alg,qnum,str,silent)
}

/// Provide the current version for the %SYS.PTools.StatsSQL class/section of the Performance Tools (PTools) Application
ClassMethod version() As %String [ SqlName = StatsSQL_version, SqlProc ]
{
	QUIT $$$StatsSQLVersion		//MRP878 - First Implementation of Versioning
}

Trigger OnInsertUpdate [ Event = INSERT/UPDATE, Time = AFTER ]
{
	#; --- Record the timestamp of the most recent INSERT & UPDATE --- 
	if {ModuleName}=-1 { // --- ModuleName = 'INFO' ---
		if ({TotalCounter}+{TotalModuleCount}+{TotalTimeSpent}+{TotalGlobalRefs}+{TotalCommandsExecuted}+{TotalDiskWait}+{VarianceTimeSpent})>0 { $$$setStatsSQLAggregationTimestamp({NameSpace},{RoutineName},{CursorName},$tr($zdt($H,8,1)," :")) }
		if {RoutineNameUCQCaller}'="" { $$$setSYSPToolsStatsSQLIndex($$$StatsSQLIndexRoutineUCQCaller,{RoutineNameUCQCaller},{NameSpace},{RoutineName},{CursorName},{StatsGroup},{ModuleName}) }
	}
	else { $$$setStatsSQLModificationTimestamp({NameSpace},{RoutineName},{CursorName},$tr($zdt($H,8,1)," :")) }
}

/// Perform the OnDelete Trigger operations for this class...
ClassMethod TriggerOnDelete(timing, ns, rtn, curs, sgrp, mod, rtnUCQCaller = "")
{
    #; --- If no Data exists for (ns,rtn,curs), delete the Data, Index, & Information/Counter globals ---
    if '$$$existsSYSPToolsStatsSQLDataSub3(ns,rtn,curs) { 
		if rtnUCQCaller'="" { $$$killSYSPToolsStatsSQLIndexSub3($$$StatsSQLIndexRoutineUCQCaller,rtnUCQCaller,ns,rtn,curs) }
    	$$$killStatsSQLStatsGroup(ns,rtn,curs) 
    	$$$killStatsSQLModificationTimestamp(ns,rtn,curs)
    	$$$killStatsSQLAggregationTimestamp(ns,rtn,curs)
    }
    
    #; --- If no more data rows exist, delete the Data, Index & Information/Counter globals ---
    if '$$$existsSYSPToolsStatsSQLData { 
    	$$$killSYSPToolsStatsSQLData 
		$$$killSYSPToolsStatsSQLIndexNoSubs
		$$$killStatsSQLStatsGroupTree
		$$$killStatsSQLModificationTimestampTree
		$$$killStatsSQLAggregationTimestampTree
    }
}

Trigger OnDelete [ Event = DELETE, Time = AFTER ]
{
    do ..TriggerOnDelete("AFTER",{NameSpace},{RoutineName},{CursorName},{StatsGroup},{ModuleName},{RoutineNameUCQCaller})
}

Storage Default
{
<Data name="StatsSQLDefaultData">
<Subscript>"StatsSQL"</Subscript>
<Value name="1">
<Value>QueryType</Value>
</Value>
<Value name="2">
<Value>ImportSchema</Value>
</Value>
<Value name="3">
<Value>SQLTextRaw</Value>
</Value>
<Value name="4">
<Value>Hash</Value>
</Value>
<Value name="5">
<Value>SQLIndexHash</Value>
</Value>
<Value name="6">
<Value>QueryCompileTime</Value>
</Value>
<Value name="7">
<Value>Parameters</Value>
</Value>
<Value name="8">
<Value>SQLStatsFlag</Value>
</Value>
<Value name="9">
<Value>TotalRowCount</Value>
</Value>
<Value name="10">
<Value>TotalCounter</Value>
</Value>
<Value name="11">
<Value>TotalModuleCount</Value>
</Value>
<Value name="12">
<Value>TotalTimeToFirstRow</Value>
</Value>
<Value name="13">
<Value>TotalTimeSpent</Value>
</Value>
<Value name="14">
<Value>TotalGlobalRefs</Value>
</Value>
<Value name="15">
<Value>TotalCommandsExecuted</Value>
</Value>
<Value name="16">
<Value>TotalDiskWait</Value>
</Value>
<Value name="17">
<Value>VarianceTimeSpent</Value>
</Value>
<Value name="18">
<Value>creationDate</Value>
</Value>
<Value name="19">
<Value>creationTime</Value>
</Value>
<Value name="20">
<Value>RoutineNameUCQCaller</Value>
</Value>
</Data>
<DefaultData>StatsSQLDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
