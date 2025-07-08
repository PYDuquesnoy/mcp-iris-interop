/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%msql, %sqlcode, %SYS.PTools.Stats)

/// <style type="text/css"> 
///    DEP { color: red; font-weight: bold; }
///    BC { color: green; font-weight: bold; }
///    .dep-head { color: red; white-space: pre; font-family:  'Courier New'; }
///    .section-head { color: blue; white-space: pre; font-family:  'Courier New'; }
///    .info-head { white-space: pre; font-family: 'Courier New'; }
/// </style>
/// 
/// <p class="info-head">
/// Class:        %SYS.PTools.UtilSQLAnalysis
/// Replaces:     <class>%SYS.PTools.SQLUtilities</class> & <class>%SYS.PTools.SQLUtilResults</class>  <DEP>[DEPRECATED]</DEP>
/// Purpose:      
///    This class provides an abstract interface to all of the information  
///    defined in the <class>%SYS.PTools.UtilSQLStatements</class> and
///    <class>%SYS.PTools.UtilSQLAnalysisDB</class> classes, and provides the
///    following Methods and Queries to the collect, analyze, and optimize the 
///    SQL Statement within a given InterSystems IRIS namespace:
/// 
///    Methods                                        Queries
///    -----------------------------------            -----------------------------
///  - <method>getAllSQLStmts</method>
///  - <method>getSQLStmts</method>                                  - <query>getSQLStmts</query>
///  - <method>getAllCachedQrySQLStmts</method>           
///  - <method>getCachedQrySQLStmtsByDays</method>         
///  - <method>getCachedQrySQLStmtsByClass</method>        
///  - <method>getAllClassMethSQLStmts</method>            
///  - <method>getClassMethSQLStmtsByClass</method>        
///  - <method>getAllClassQrySQLStmts</method>
///  - <method>getClassQrySQLStmtsByClass</method>
///  - <method>getAllRtnQrySQLStmts</method>
///  - <method>getRtnQrySQLStmtsByRtn</method>
///  - <method>getAllIndices</method>
/// 
///  - <method>indexUsage</method>                                   - <query>indexUsage</query>
///  - <method>tableScans</method>                                   - <query>tableScans</query>
///  - <method>tempIndices</method>                                  - <query>tempIndices</query>
///  - <method>joinIndices</method>                                  - <query>joinIndices</query>
///  - <method>outlierIndices</method>                               - <query>outlierIndices</query>
///  - <method>getIndexFlagInfo</method>
/// 
///  - <method>exportUtilSQLStatements</method>
///  - <method>exportUtilSQLAnalysisDB</method>
///  - <method>exportUtilSQLAnalysis</method>
/// 
///  - <method>exportIUAnalysis</method>
///  - <method>exportTSAnalysis</method>
///  - <method>exportTIAnalysis</method>
///  - <method>exportJIAnalysis</method>
///  - <method>exportOIAnalysis</method>
/// 
///  - <method>clearSQLStatements</method>
///  - <method>clearSQLAnalysisDB</method>
///                                                 - <query>countSQLStmtTypes</query>
///                                                 - <query>UtilSQLStmtsAndAnalysisDBView</query>
/// 
/// </p>
Class %SYS.PTools.UtilSQLAnalysis [ Abstract, CompileAfter = (%SYS.PTools.UtilSQLStatements, %SYS.PTools.UtilSQLAnalysisDB), System = 4 ]
{

/// <p class="section-head">
/// <b>                 A N A L Y Z E   S Q L   S T A T E M E N T S               </b>
///                     ===========================================
/// 
/// <b>                            I N D E X   U S A G E                          </b>
///                                ---------------------
/// For each of the SQL Statements saved in the <class>%SYS.PTools.UtilSQLStatements</class> 
/// class, generates a ShowPlan and keeps a count of how many times each index is 
/// used by each query, along with the total usage for each index by all queries 
/// in the namespace, and store this information in the 
/// <class>%SYS.PTools.UtilSQLAnalysisDB</class> class.
/// </p>
/// 
/// <p class="info-head">
/// Method:       indexUsage [SQL: PT_indexUsage]
/// Replaces:     IndexUsage [SQL: IndexUsage] (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      This method uses the SQL Statement data stored in the 
///               <class>%SYS.PTools.UtilSQLStatements</class> class to generate a ShowPlan
///               for each query, and to keeps a count of how many times each 
///               index is used by each query.  This index usage count is 
///               subsequently stored in the 'UsageCount' field of the 
///               <class>%SYS.PTools.UtilSQLAnalysisDB</class> class, which can be 
///               used to find and remove unneeded indices in addition to being 
///               used for other analytical purposes...  
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.UtilSQLAnalysis).indexUsage(...)
///                    SQL: CALL %SYS_PTools.PT_indexUsage(...)
///                         SELECT %SYS_PTools.PT_indexUsage(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples provide analytical information
///               produced from the invocation of this method:
/// 
///    #1         Show info from where the SQL Statements were collected:
/// 
///               SELECT %EXACT(Type) AS QueryType, Count(*) AS QueryCount 
///               FROM %SYS_PTools.UtilSQLStatements 
///               GROUP BY Type
///         OR
///               SELECT * FROM %SYS_PTools.UtilSQLAnalysis_countSQLStmtTypes()
/// 
///    #2         Show the data collected from the running of this method:
/// 
///               SELECT * FROM %SYS_PTools.UtilSQLAnalysis_indexUsage()
/// 
///               NOTE: These queries can either be invoked from a number of
///                     tools, such as the SQL Query tool in the 'Management Portal'
///                     or via 'SQL Query Shell' within a 'InterSystems IRIS Terminal' as show
///                     below:
///                        >do $SYSTEM.SQL.Shell()
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","util","SQLAnlsys","{C|D|I|S}")
/// 
/// Parameters:
///    clearData    - 1 = Kill all of the existing data before re-populating
///                       with the results of this method invocation
///                          [DEFAULT: 1]
///    getIndices   - 1 = Get all the SQL Indexes from the Class Methods in this
///                       Namespace and add them to the <class>%SYS.PTools.UtilSQLAnalysisDB</class>
///                       class for additional processing of this method
///                          [DEFAULT: 0*]
///                              * - If '%SYS.PTools.UtilSQLAnalysisDB' contains NO 
///                                  Index Usage (IU) data, then DEFAULT 'getIndices'
///                                  to 1, even if a 0 is passed in for this paramter,
///                                  because this method requires Index Usage (IU) data
///                                  for processing!
///    getSQLStmts  - 1 = Get all the SQL Statements from InterSystems IRIS locations 
///                       (Cached Queries, Class Methods, Class Queries, MAC Routines)
///                       and add them to the <class>%SYS.PTools.UtilSQLStatements</class> class for 
///                       additional processing of this method
///                          NOTE: This is an all inclusive call which could be time
///                                consuming.  The <class>%SYS.PTools.UtilSQLStatements</class> class can
///                                populated via APIs that offer more precise collection
///                                alternatives which are less time consuming
///                          [DEFAULT: 0*]
///                              * - If '%SYS.PTools.UtilSQLStatements' contains NO data,
///                                  then DEFAULT 'getSQLStmts' to 1 because this method
///                                  requires SQL Statement data for processing!
///    skipSysObj   - 0 = Don't skip all System Objects (Classes & Routines)
///                   1 = Skip all System Objects (Classes & Routines) that
///                       start with: { % | DeepSee | Ens | HS | INFORMATION{.|_}SCHEMA }
///                   2 = Skip all System Objects that are not defined in
///                       the namespace in which this method is invoked
///                   3 = Skip all System Objects defined by InterSystems, even if
///                       the object is also defined in the namespace in which this
///                       method is invoked
///                   NOTE-1: Pass the combination of the specified options if more
///                           than one option desired (e.g. 13 => #1 & #3)
///                   NOTE-2: This only applies when retrieving SQL Indices (getIndices=1)
///                           and/or SQL Statements (getSQLStmts=1)
///                          [DEFAULT: 1]
///    skipIDKeys   - 1 = Skip all the index that will be used to form the Object Identity 
///                       value (IDKEY) for the given class
///                       NOTE: This only applies when retrieving SQL Indices (getIndices=1)
///                          [DEFAULT: 1]
///    skipInsStmts - 1 = Skip INSERT Statements, as they don't have looping logic
///                          [DEFAULT: 1]
///    display      - 1 = Display messages while processing method
///                          [DEFAULT: 1]
///    ptInfo       - A Pass By Reference information array that returns to the user 
///                   the following details:
///                      ptInfo("update-cnt")=The number of rows in the <class>%SYS.PTools.UtilSQLAnalysisDB</class>
///                                           class which were updated with their Index Usage details
///    
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod indexUsage(clearData As %Integer = 1, getIndices As %Integer = 0, getSQLStmts As %Integer = 0, skipSysObj As %Integer = 1, skipIDKeys As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_indexUsage, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!
	
	QUIT $$indexUsage^%SYS.PTools2(clearData,getIndices,getSQLStmts,skipSysObj,skipIDKeys,skipInsStmts,display,.ptInfo)
}

/// <p class="info-head">
/// Query:        indexUsage
/// Replaces:     IndexUsage (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Query to replicate Backward-Compatible Query it 'Replaces'
/// Purpose:      A query to return the results generated by the invocation of
///               the 'indexUsage()' method...
/// 
///  Parameters:
///   schema    - The schema of the table being queried in the SQL Statement
///               to match against the 'SchemaName' property/field
/// </p>
Query indexUsage(schema) As %SQLQuery(ROWSPEC = "SchemaName:%String,TableName:%String,IndexName:%String,Usage Count:%Integer")
{
	SELECT %Exact(SchemaName), %Exact(Tablename), 
	       %Exact(IndexName), UsageCount AS "Usage Count"
	FROM %SYS_PTools.UtilSQLAnalysisDB 
	WHERE     OptionName = 'IU' 
	      AND (SchemaName = :schema OR :schema IS NULL)
	ORDER BY UsageCount
}

/// <p class="section-head">
/// <b>             Q U E R I E S   W I T H   T A B L E   S C A N S               </b>
///                 -----------------------------------------------
/// For each of the SQL Statements saved in the <class>%SYS.PTools.UtilSQLStatements</class> 
/// class, identify all queries that do table scans. Table scans should be avoided 
/// if at all possible, but a table scan can't always be avoided.  However, if a 
/// table has a large number of table scans, the indices defined for that table 
/// should be reviewed.  Often the list of table scans and the list of temp 
/// indices will overlap; fixing one will remove the other.  The result set 
/// lists the tables from largest Block Count to smallest Block Count. 
/// </p>
/// 
/// <p class="info-head">
/// Method:       tableScans [SQL: PT_tableScans]
/// Replaces:     TableScans [SQL: TableScans] (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      This method uses the SQL Statement data stored in the 
///               <class>%SYS.PTools.UtilSQLStatements</class> class to pinpoint the 
///               queries that perform a table scan, which could be over an index or 
///               the master map.  
///               Pertinent information about these queries is subsequently 
///               stored in the the <class>%SYS.PTools.UtilSQLAnalysisDB</class> class
///               for future processing and analysis. 
///               For some queries a table scan can't be avoided, but any 
///               query that uses such a scan should be reviewed in order to
///               determine if an index could be added for performance 
///               optimizations.
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.UtilSQLAnalysis).tableScans(...)
///                    SQL: CALL %SYS_PTools.PT_tableScans(...)
///                         SELECT %SYS_PTools.PT_tableScans(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples provide analytical information
///               produced from the invocation of this method:
/// 
///    #1         Show info from where the SQL Statements were collected:
/// 
///               SELECT %EXACT(Type) AS QueryType, Count(*) AS QueryCount 
///               FROM %SYS_PTools.UtilSQLStatements 
///               GROUP BY Type
///         OR
///               SELECT * FROM %SYS_PTools.UtilSQLAnalysis_countSQLStmtTypes()
/// 
///    #2         Show the data collected from the running of this method:
/// 
///               SELECT SQLPointer->Type As "Routine Type", 
///                      SQLPointer->Name As "Routine Name", 
///                      SchemaName, TableName, ModuleName, 
///                      ExtentSize,
///                      SQLPointer->SQLTextExt AS "SQL Text"
///               FROM %SYS_PTools.UtilSQLAnalysisDB 
///               WHERE OptionName = 'TS' 
///               ORDER BY ExtentSize DESC
///         OR
///               SELECT * FROM %SYS_PTools.UtilSQLAnalysis_tableScans()
/// 
///         OR
///               SELECT SchemaName, TableName, Type, "Class/Routine Name",
///                      ModuleName, "Map Type" , ExtentSize, "Block Count",
///                      "SQL Text"
///               FROM %SYS_PTools.UtilSQLAnalysis_tableScans()
/// 
///               NOTE: These queries can be invoked from a number of tools,
///                     such as the SQL Query tool in the 'Management Portal'
///                     or via 'SQL Query Shell' within a 'InterSystems IRIS Terminal' as
///                     shown below:
///                        >do $SYSTEM.SQL.Shell()
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","util","SQLAnlsys","{C|D|I|S}")
/// 
/// Parameters:
///    clearData    - 1 = Kill all of the existing data before re-populating
///                       with the results of this method invocation
///                          [DEFAULT: 1]
///    getSQLStmts  - 1 = Get all the SQL Statements from InterSystems IRIS locations 
///                       (Cached Queries, Class Methods, Class Queries, MAC Routines)
///                       and add them to the <class>%SYS.PTools.UtilSQLStatements</class> class for 
///                       additional processing of this method
///                       NOTE: This is an all inclusive call which could be time
///                             consuming.  The <class>%SYS.PTools.UtilSQLStatements</class> class can
///                             populated via APIs that offer more precise collection
///                             alternatives which are less time consuming
///                          [DEFAULT: 0]
///    skipSysObj   - 0 = Don't skip all System Objects (Classes & Routines)
///                   1 = Skip all System Objects (Classes & Routines) that
///                       start with: { % | DeepSee | Ens | HS | INFORMATION{.|_}SCHEMA }
///                   2 = Skip all System Objects that are not defined in
///                       the namespace in which this method is invoked
///                   3 = Skip all System Objects defined by InterSystems, even if
///                       the object is also defined in the namespace in which this
///                       method is invoked
///                   NOTE-1: Pass the combination of the specified options if more
///                           than one option desired (e.g. 13 => #1 & #3)
///                   NOTE-2: This only applies when retrieving SQL Statements (getSQLStmts=1)
///                          [DEFAULT: 1]
///    skipInsStmts - 1 = Skip INSERT Statements, as they don't have looping logic
///                          [DEFAULT: 1]
///    display      - 1 = Display messages while processing method
///                          [DEFAULT: 1]
///    ptInfo       - A Pass By Reference information array that returns to the user 
///                   the following details:
///                      ptInfo("insert-cnt")=The number of rows inserted in the <class>%SYS.PTools.UtilSQLAnalysisDB</class>
///                                           class for queries that require a full table scan
///                   NOTE: If errors are found while processing an SQL Statement via
///                         the '$$findTableScans(...)' method, they will be returned
///                         in the following location:
///                            ptInfo("error")=errorID Count
///                            ptInfo("error",errorID)=tSC  // Error Details
///    
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod tableScans(clearData As %Integer = 1, getSQLStmts As %Integer = 0, skipSysObj As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_tableScans, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$tableScans^%SYS.PTools2(clearData,getSQLStmts,skipSysObj,skipInsStmts,display,.ptInfo)
}

/// <p class="info-head">
/// Query:        tableScans
/// Replaces:     TableScans (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      A query to return the results generated by the invocation of
///               the 'tableScans()' method...
/// 
///  Parameters:
///   schema    - The schema of the table being queried in the SQL Statement
///               to match against the 'SchemaName' property/field
/// </p>
Query tableScans(schema) As %SQLQuery(ROWSPEC = "SchemaName:%String,TableName:%String,Type:%String,Class/Routine Name:%String,ModuleName:%String,Map Type:%String,ExtentSize:%Integer,Block Count:%Integer,SQL Text:%String")
{
	SELECT %Exact(SchemaName), %Exact(TableName), SQLPointer->Type, SQLPointer->Name, 
	       ModuleName, MapType AS "Map Type", 
	       ExtentSize, BlockCount AS "Block Count", SQLPointer->SQLTextExt AS "SQL Text"
	FROM %SYS_PTools.UtilSQLAnalysisDB 
	WHERE     OptionName = 'TS' 
	      AND (SchemaName = :schema OR :schema IS NULL)
	ORDER BY BlockCount DESC
}

/// <p class="section-head">
///               Q U E R I E S   W I T H   T E M P   I N D I C E S
///               -------------------------------------------------
/// For each of the SQL Statements saved in the <class>%SYS.PTools.UtilSQLStatements</class> class,
/// identify all queries that build temporary indices to resolve the SQL. 
/// Sometimes the use of a temp index is helpful and improves performance, for 
/// example building a small index based on a range condition that InterSystems IRIS can 
/// then use to read the master map in order. Sometimes a temp index is simply 
/// a subset of a different index and might be very efficient. Other times a 
/// temporary index degrades performance, for example scanning the master map 
/// to build a temporary index on a property that has a condition. This situation 
/// indicates that a needed index is missing; you should add an index to the 
/// class that matches the temporary index. The result set lists the tables from 
/// largest Block Count to smallest Block Count.
/// </p>
/// 
/// <p class="info-head">
/// Method:       tempIndices [SQL: PT_tempIndices]
/// Replaces:     TempIndices [SQL: TempIndices] (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      This method uses the SQL Statement data stored in the 
///               <class>%SYS.PTools.UtilSQLStatements</class> class to pinpoint the 
///               queries that are building a Temp Index/Table.  
///               Pertinent information about these queries is subsequently 
///               stored in the the <class>%SYS.PTools.UtilSQLAnalysisDB</class> class
///               for future processing and analysis. 
///               It's worth noting that the results of this method and that of 
///               the 'tableScans()' method might have a large overlap.
///               For some queries the creation of a Temp Index/Table can be 
///               avoided, but often the creation of a Temp Index/Table is 
///               done so to provide optimal data traversal and retrieval.
///               These queries should be reviewed to determine if an index could 
///               be added to the class for performance optimizations, because 
///               often the structure of the Temp Index/Table is the basis for the 
///               creation of a class index to help with query performance.
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.UtilSQLAnalysis).tempIndices(...)
///                    SQL: CALL %SYS_PTools.PT_tempIndices(...)
///                         SELECT %SYS_PTools.PT_tempIndices(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples provide analytical information
///               produced from the invocation of this method:
/// 
///    #1         Show info from where the SQL Statements were collected:
/// 
///               SELECT %EXACT(Type) AS QueryType, Count(*) AS QueryCount 
///               FROM %SYS_PTools.UtilSQLStatements 
///               GROUP BY Type
///         OR
///               SELECT * FROM %SYS_PTools.UtilSQLAnalysis_countSQLStmtTypes()
/// 
///    #2         Show the data collected from the running of this method:
/// 
///               SELECT SchemaName, TableName, 
///                      $LISTTOSTRING(IndexFields) As "Index Fields", 
///                      $LISTTOSTRING(DataValues) As "Data Fields", 
///                      ExtentSize, BlockCount As "Block Count",
///                      SQLPointer->SQLTextExt AS "SQL Text"
///               FROM %SYS_PTools.UtilSQLAnalysisDB 
///               WHERE OptionName = 'TI' 
///               ORDER BY ExtentSize DESC
///         OR
///               SELECT * FROM %SYS_PTools.UtilSQLAnalysis_tempIndices()
/// 
///         OR
///               SELECT SchemaName, TableName, Type, "Class/Routine Name",
///                      IndexName, "Index Fields", "Data Fields",
///                      ExtentSize, "Block Count", 
///                      "SQL Text"
///               FROM %SYS_PTools.UtilSQLAnalysis_tempIndices()
/// 
///               NOTE: These queries can be invoked from a number of tools,
///                     such as the SQL Query tool in the 'Management Portal'
///                     or via 'SQL Query Shell' within a 'InterSystems IRIS Terminal' as
///                     shown below:
///                        >do $SYSTEM.SQL.Shell()
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","util","SQLAnlsys","{C|D|I|S}")
/// 
/// Parameters:
///    clearData    - 1 = Kill all of the existing data before re-populating
///                       with the results of this method invocation
///                          [DEFAULT: 1]
///    getSQLStmts  - 1 = Get all the SQL Statements from InterSystems IRIS locations 
///                       (Cached Queries, Class Methods, Class Queries, MAC Routines)
///                       and add them to the <class>%SYS.PTools.UtilSQLStatements</class> class for 
///                       additional processing of this method
///                       NOTE: This is an all inclusive call which could be time
///                             consuming.  The <class>%SYS.PTools.UtilSQLStatements</class> class can
///                             populated via APIs that offer more precise collection
///                             alternatives which are less time consuming
///                          [DEFAULT: 0]
///    skipSysObj   - 0 = Don't skip all System Objects (Classes & Routines)
///                   1 = Skip all System Objects (Classes & Routines) that
///                       start with: { % | DeepSee | Ens | HS | INFORMATION{.|_}SCHEMA }
///                   2 = Skip all System Objects that are not defined in
///                       the namespace in which this method is invoked
///                   3 = Skip all System Objects defined by InterSystems, even if
///                       the object is also defined in the namespace in which this
///                       method is invoked
///                   NOTE-1: Pass the combination of the specified options if more
///                           than one option desired (e.g. 13 => #1 & #3)
///                   NOTE-2: This only applies when retrieving SQL Statements (getSQLStmts=1)
///                          [DEFAULT: 1]
///    skipInsStmts - 1 = Skip INSERT Statements, as they don't have looping logic
///                          [DEFAULT: 1]
///    display      - 1 = Display messages while processing method
///                          [DEFAULT: 1]
///    ptInfo       - A Pass By Reference information array that returns to the user 
///                   the following details:
///                      ptInfo("insert-cnt")=The number of rows inserted in the <class>%SYS.PTools.UtilSQLAnalysisDB</class>
///                                           class for queries that build temporary indices to resolve the SQL.
///                   NOTE: If errors are found while processing an SQL Statement via
///                         the '$$findTempIndices(...)' method, they will be returned
///                         in the following location:
///                            ptInfo("error")=errorID Count
///                            ptInfo("error",errorID)=tSC  // Error Details
///    
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod tempIndices(clearData As %Integer = 1, getSQLStmts As %Integer = 0, skipSysObj As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_tempIndices, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$tempIndices^%SYS.PTools2(clearData,getSQLStmts,skipSysObj,skipInsStmts,display,.ptInfo)
}

/// <p class="info-head">
/// Query:        tempIndices
/// Replaces:     TempIndices (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Query to replicate Backward-Compatible Query it 'Replaces'
/// Purpose:      A query to return the results generated by the invocation of
///               the 'tempIndices()' method...
/// 
///  Parameters:
///   schema    - The schema of the table being queried in the SQL Statement
///               to match against the 'SchemaName' property/field
/// </p>
Query tempIndices(schema) As %SQLQuery(ROWSPEC = "SchemaName:%String,TableName:%String,Type:%String,Class/Routine Name:%String,IndexName:%String,Index Fields:%String,Data Fields:%String,ExtentSize:%Integer,Block Count:%Integer,SQL Text:%String")
{
	SELECT %Exact(SchemaName), %Exact(TableName), SQLPointer->Type, SQLPointer->Name, 
	        %Exact(IndexName), $LISTTOSTRING(IndexFields) As "Index Fields", $LISTTOSTRING(DataValues) As "Data Fields", 
	        ExtentSize, BlockCount AS "Block Count", SQLPointer->SQLTextExt AS "SQL Text"
	FROM %SYS_PTools.UtilSQLAnalysisDB  
	WHERE     OptionName = 'TI' 
	      AND (SchemaName = :schema OR :schema IS NULL)
	ORDER BY BlockCount DESC
}

/// <p class="section-head">
///       Q U E R I E S   W I T H   M I S S I N G   J O I N   I N D I C E S
///       -----------------------------------------------------------------
/// For each of the SQL Statements saved in the <class>%SYS.PTools.UtilSQLStatements</class> class,
/// identify all queries that have joins, and determines if there is an index 
/// defined to support that join.  It ranks the indices available to support the
/// joins from 0 (no index present) to 4 (index fully supports the join). Outer 
/// joins require an index in one direction. Inner joins require an index in 
/// both directions. The result set only contains rows that have a 
/// JoinIndexFlag < 4. JoinIndexFlag=4 means there is an index that fully 
/// supports the join; these are not listed.  
/// </p>
/// 
/// <p class="info-head">
/// Method:       joinIndices [SQL: PT_joinIndices]
/// Replaces:     JoinIndices [SQL: JoinIndices] (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      This method uses the SQL Statement data stored in the 
///               <class>%SYS.PTools.UtilSQLStatements</class> class to pinpoint the 
///               queries that perform a JOIN between tables where their 
///               joined-fields use an index that supports the join.  This method 
///               will then ranks the indices available to support the join from 
///               0 (no index present) to 4 (index fully supports the join).
///               Pertinent information about these queries is subsequently 
///               stored in the the <class>%SYS.PTools.UtilSQLAnalysisDB</class> class
///               for future processing and analysis. 
///               It's worth noting that OUTER JOINs require an index in one
///               direction, whereas INNER JOINs require an index in both 
///               directions. 
///               The result-set stored in the the <class>%SYS.PTools.UtilSQLAnalysisDB</class> 
///               class only contains rows that have a 'JoinIndexFlag < 4'. 
///               Rows that have a 'JoinIndexFlag = 4', which means that there
///               exists an index that fully supports the JOIN, are not stored 
///               since they are already fully optimized.
///               The stored queries should be reviewed to determine if an index 
///               could be added to the class to satisfy the highest 'JoinIndexFlag'
///               possible:
/// 
///               The 'JoinIndexFlag' property has the following 5 values:
///                  0 - No Match: No index exists to support the fields from the JOIN 
///                                conditions
///                         (Some version of the suggested index should be created 
///                          to improve this query's performance)
///                  1 - Partial Match: An index exists where its fields contains some 
///                                     of the fields from the JOIN conditions, but not 
///                                     the leading field
///                         (This will produce poor performance and for that reason 
///                          is rarely used)
///                  2 - Contains Match: An index exists where its fields contains all 
///                                      fields from the JOIN conditions, but not the 
///                                      leading fields
///                         (This might produce OK performance, but improvements 
///                          should be made)
///                  3 - Leading Match: An index exists where its leading fields match 
///                                     all fields from the JOIN conditions, but there 
///                                     are additional fields in the index
///                         (This will produce OK performance, but improvements can 
///                          be made)
///                  4 - Exact Match: An index exists where its fields match all fields 
///                                   from the JOIN conditions
///                         (This is a fully optimized index) 
/// 
///               Optimizations
///               -------------
///               - Creating a new index in the case of JoinIndexFlag = 0 or 1 
///                 should show good performance gains.
///               - Creating a new index for JoinIndexFlag = 2 will help, 
///                 improvements will depend on the number of leading subscripts 
///                 and their selectivity
///               - Creating a new index for JoinIndexFlag = 3 could help, in most 
///                 cases you will only see small improvements.
///               - The Order of the subscripts does not matter for the join, but 
///                 could make a difference in performance.
///               - The property with the lowest selectivity should be first.
/// 
///               NOTE: The fields returned by the query's 'Index Needed' could 
///                     be used to create an index that should help improve 
///                     performance.
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.UtilSQLAnalysis).joinIndices(...)
///                    SQL: CALL %SYS_PTools.PT_joinIndices(...)
///                         SELECT %SYS_PTools.PT_joinIndices(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples provide analytical information
///               produced from the invocation of this method:
/// 
///    #1         Show info from where the SQL Statements were collected:
/// 
///               SELECT %EXACT(Type) AS QueryType, Count(*) AS QueryCount 
///               FROM %SYS_PTools.UtilSQLStatements 
///               GROUP BY Type
///         OR
///               SELECT * FROM %SYS_PTools.UtilSQLAnalysis_countSQLStmtTypes()
/// 
///    #2         Show the data collected from the running of this method:
/// 
///               SELECT SchemaName, TableName, 
///                      SQLPointer->Type, SQLPointer->Name, 
///                      IndexName, $LISTTOSTRING(JoinFields) AS "Index Needed", 
///                      $LISTTOSTRING(IndexFields) AS "Indexed Fields", 
///                      $LISTTOSTRING(JoinFields) AS "JOIN Fields", 
///                      JoinIndexFlag AS "Join Index Flag",
///                      ExtentSize, BlockCount AS "Block Count", 
///                      SQLPointer->SQLTextExt AS "SQL Text"
///               FROM %SYS_PTools.UtilSQLAnalysisDB 
///               WHERE OptionName = 'JI' 
///               ORDER BY 1,2
///         OR
///               SELECT * FROM %SYS_PTools.UtilSQLAnalysis_joinIndices()
/// 
///               NOTE: This query will return JoinIndexFlag AS "Join Index Flag"
///                     as a numeric value (0-3) as specified above.  However,
///                     in order to return more specificity for this field,
///                     one of the following values can be passed to the 2nd
///                     parameter 'indexFlagInfo' of the joinIndices() query:
/// 
///                        0 = The Index-Flag Internal Value   [DEFAULT]
///                        1 = The Index-Flag Title
///                        2 = The Index-Flag Definition
///                        3 = The Index-Flag as 'Title: Definition'
/// 
///               EXAMPLE:
/// 
///                  SELECT * FROM %SYS_PTools.UtilSQLAnalysis_joinIndices(,3)
/// 
///         OR
///               SELECT SchemaName, TableName, Type, "Class/Routine Name",
///                      IndexName, "Index Needed", "Join Index Flag",
///                      ExtentSize, "Block Count", 
///                      "SQL Text"
///               FROM %SYS_PTools.UtilSQLAnalysis_joinIndices()
/// 
///    #3         Show joined-based tables with less than optimal indexes 
///               that support the JOIN specified in the query:
/// 
///               SELECT SchemaName, TableName, 
///                      $LISTTOSTRING(JoinFields) AS "Index Needed", 
///                      JoinIndexFlag AS "Join Index Flag", 
///                      COUNT(*) AS "Query Count"
///               FROM %SYS_PTools.UtilSQLAnalysisDB
///               WHERE JoinIndexFlag < 4 and OptionName = 'JI'
///               GROUP BY SchemaName, TableName, IndexFields
///               ORDER BY 4,5 DESC 
///                  -- These tables should be reviewed to see if a better
///                  -- index can be added to fully support the JOIN conditions
/// 
///               NOTE: These queries can be invoked from a number of tools,
///                     such as the SQL Query tool in the 'Management Portal'
///                     or via 'SQL Query Shell' within a 'InterSystems IRIS Terminal' as
///                     shown below:
///                        >do $SYSTEM.SQL.Shell()
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","util","SQLAnlsys","{C|D|I|S}")
/// 
/// Parameters:
///    clearData    - 1 = Kill all of the existing data before re-populating
///                       with the results of this method invocation
///                          [DEFAULT: 1]
///    getSQLStmts  - 1 = Get all the SQL Statements from InterSystems IRIS locations 
///                       (Cached Queries, Class Methods, Class Queries, MAC Routines)
///                       and add them to the <class>%SYS.PTools.UtilSQLStatements</class> class for 
///                       additional processing of this method
///                       NOTE: This is an all inclusive call which could be time
///                             consuming.  The <class>%SYS.PTools.UtilSQLStatements</class> class can
///                             populated via APIs that offer more precise collection
///                             alternatives which are less time consuming
///                          [DEFAULT: 0]
///    skipSysObj   - 0 = Don't skip all System Objects (Classes & Routines)
///                   1 = Skip all System Objects (Classes & Routines) that
///                       start with: { % | DeepSee | Ens | HS | INFORMATION{.|_}SCHEMA }
///                   2 = Skip all System Objects that are not defined in
///                       the namespace in which this method is invoked
///                   3 = Skip all System Objects defined by InterSystems, even if
///                       the object is also defined in the namespace in which this
///                       method is invoked
///                   NOTE-1: Pass the combination of the specified options if more
///                           than one option desired (e.g. 13 => #1 & #3)
///                   NOTE-2: This only applies when retrieving SQL Statements (getSQLStmts=1)
///                          [DEFAULT: 1]
///    skipInsStmts - 1 = Skip INSERT Statements, as they don't have looping logic
///                          [DEFAULT: 1]
///    display      - 1 = Display messages while processing method
///                          [DEFAULT: 1]
///    ptInfo       - A Pass By Reference information array that returns to the user 
///                   the following details:
///                      ptInfo("insert-cnt")=The number of rows inserted in the <class>%SYS.PTools.UtilSQLAnalysisDB</class>
///                                           class for queries that have joins indexing issues
///    
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod joinIndices(clearData As %Integer = 1, getSQLStmts As %Integer = 0, skipSysObj As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_joinIndices, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$joinIndices^%SYS.PTools2(clearData,getSQLStmts,skipSysObj,skipInsStmts,display,.ptInfo)
}

/// <p class="info-head">
/// Query:        joinIndices
/// Replaces:     JoinIndices (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Query to replicate Backward-Compatible Query it 'Replaces'
/// Purpose:      A query to return the results generated by the invocation of
///               the 'joinIndices()' method...
/// 
/// Invocation:   This Query can be invoked in the following way:
///                  SELECT * FROM %SYS_PTools.UtilSQLAnalysis_joinIndices()
/// 
///  Parameters:
///   schema          - The schema of the table being queried in the SQL Statement
///                     to match against the 'SchemaName' property/field
///                        "" = All Schemas                    [DEFAULT]
///   indexFlagInfo   - The specific information that should be returned for
///                     the "Join Index Flag" field:
///                        0 = The Index-Flag Internal Value   [DEFAULT]
///                        1 = The Index-Flag Title
///                        2 = The Index-Flag Definition
///                        3 = The Index-Flag as 'Title: Definition'
///   skipJIF4        - 0 - Export all rows regardless of the 'JoinIndexFlag' value
///                     1 - Export all rows where the value of the 'JoinIndexFlag' is not 4  [DEFAULT]
/// </p>
Query joinIndices(schema = "", indexFlagInfo = 0, skipJIF4 = 1) As %SQLQuery(ROWSPEC = "SchemaName:%String,TableName:%String,Type:%String,Class/Routine Name:%String,IndexName:%String,Index Needed:%String,Join Index Flag:%String,ExtentSize:%Integer,Block Count:%Integer,SQL Text:%String")
{
	SELECT %Exact(SchemaName), %Exact(TableName), SQLPointer->Type, SQLPointer->Name,
	       %Exact(IndexName), $LISTTOSTRING(JoinFields) AS "Index Needed",
	       CASE
	          WHEN :indexFlagInfo > 0
	             THEN %SYS_PTools.PT_getIndexFlagInfo(JoinIndexFlag,'joinIndices',:indexFlagInfo)
	          ELSE JoinIndexFlag 
	       END AS "Join Index Flag", 
	       ExtentSize, BlockCount AS "Block Count", SQLPointer->SQLTextExt AS "SQL Text"
	FROM %SYS_PTools.UtilSQLAnalysisDB
	WHERE     OptionName = 'JI' 
	      AND (SchemaName = :schema OR :schema IS NULL)
	      AND (JoinIndexFlag < 4 OR :skipJIF4 = 0) 
	-- MRP907 (DON'T USE): GROUP BY JoinIndexFlag, SchemaName, TableName, IndexFields
	ORDER BY JoinIndexFlag DESC
}

/// <p class="info-head">
/// Method:       getIndexFlagInfo [SQL: PT_getIndexFlagInfo]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Given an Index-Flag Internal Value 'flagInt', and the 
///               Index Analyzer Method 'indexMeth' for which this flag is 
///               associated, return the specific information requested by the 
///               'returnInfo' parameter
/// NOTE:         This is a helper-method for the following Queries:
///                  - joinIndices
///                  - outlierIndices
/// 
/// Parameters:
///    flagInt      - The Index-Flag Internal Value
///                   NOTE: The following example are the values specified for the
///                         'joinIndices()' method:
///                         4 = Exact Match: An index exists where its fields match all fields from the JOIN conditions
///                         3 = Leading Match: An index exists where its leading fields match all fields from the JOIN conditions, but there are additional fields in the index
///                         2 = Contains Match: An index exists where its fields contains all fields from the JOIN conditions, but not the leading fields
///                         1 = Partial Match: An index exists where its fields contains some of the fields from the JOIN conditions, but not the leading field
///                         0 = No Match: No index exists to support the fields from the JOIN conditions
///    indexMeth    - The Index Analyzer Method for which the 'flagInt' parameter
///                   is associated
///                      - joinIndices
///                      - outlierIndices
///    returnInfo   - The specific information that should be returned from this
///                   method:
///                      1 = The Index-Flag Title
///                      2 = The Index-Flag Definition
///                      3 = The Index-Flag as 'Title: Definition'
///    
/// RETURN Value: See the 'returnInfo' parameter for details ; Otherwise,
///               return an error message if an error occurred
/// </p>
ClassMethod getIndexFlagInfo(flagInt As %Integer = "", indexMeth As %String = "", returnInfo As %Integer = 3) As %String [ SqlName = PT_getIndexFlagInfo, SqlProc ]
{
	QUIT $$getIndexFlagInfo^%SYS.PTools2(flagInt,indexMeth,returnInfo)
}

/// <p class="section-head">
///    Q U E R I E S   W I T H   M I S S I N G   O U T L I E R   I N D I C E S
///    -----------------------------------------------------------------------
/// For each of the SQL Statements saved in the <class>%SYS.PTools.UtilSQLStatements</class> class,
/// identify all queries that have outliers, and determines if there is an index 
/// defined to support that outlier.  It ranks the indices available to support
/// the outlier from 0 (no index present) to 4 (index fully supports the outlier). 
/// </p>
/// 
/// <p class="info-head">
/// Method:       outlierIndices [SQL: PT_outlierIndices]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method uses the SQL Statement data stored in the 
///               <class>%SYS.PTools.UtilSQLStatements</class> class to pinpoint the 
///               queries that have outliers, and determines if there is an index 
///               defined to support the Outlier Condition.  This method 
///               will then ranks the indices available to support the Outlier 
///               Condition from 0 (no index present) to 4 (index fully supports 
///               the Outlier Condition).
///               Pertinent information about these queries is subsequently 
///               stored in the the <class>%SYS.PTools.UtilSQLAnalysisDB</class> class
///               for future processing and analysis. 
///               While the result-set stored in the the <class>%SYS.PTools.UtilSQLAnalysisDB</class> 
///               contains rows for all value of the 'OutlierIndexFlag' field, the
///               outlierIndices() Query for this class/table only returns the rows
///               that have the following <where-condition>: 'OutlierIndexFlag < 4'. 
///               Rows that have a 'OutlierIndexFlag = 4', which means that there
///               exists an index that fully supports the Outlier Condition, are 
///               not returned by the outlierIndices() Query, since they are already 
///               fully optimized, however this information can be obtained by 
///               directly querying the %SYS_PTools.UtilSQLAnalysisDB table.
///               The stored queries should be reviewed to determine if an index 
///               could be added to the class to satisfy the highest 
///               'OutlierIndexFlag' possible:
/// 
///               The 'OutlierIndexFlag' property has the following 5 values:
///                  0 - No Match: No index exists to support the fields from the 
///                                Outlier conditions
///                         (Some version of the suggested index should be created 
///                          to improve this query's performance)
///                  1 - Partial Match: An index exists where its fields contains 
///                                     some of the fields from the Outlier conditions, 
///                                     but not the leading field
///                         (This will produce poor performance and for that reason 
///                          is rarely used)
///                  2 - Contains Match: An index exists where its fields contains 
///                                      all fields from the Outlier conditions, but 
///                                      not the leading fields
///                         (This might produce OK performance, but improvements 
///                          should be made)
///                  3 - Leading Match: An index exists where its leading fields match 
///                                     all fields from the Outlier conditions, but 
///                                     there are additional fields in the index
///                         (This will produce OK performance, but improvements can 
///                          be made)
///                  4 - Exact Match: An index exists where its fields match all fields 
///                                   from the Outlier conditions
///                         (This is a fully optimized index) 
/// 
///               Optimizations
///               -------------
///               - Creating a new index in the case of OutlierIndexFlag = 0 or 1 
///                 should show good performance gains.
///               - Creating a new index for OutlierIndexFlag = 2 will help, 
///                 improvements will depend on the number of leading subscripts 
///                 and their selectivity
///               - Creating a new index for OutlierIndexFlag = 3 could help, in most 
///                 cases you will only see small improvements.
///               - The Order of the subscripts does not matter for the Outlier 
///                 Conditions, but could make a difference in performance.
///               - The property with the lowest selectivity should be first.
/// 
///               NOTE: The fields returned by the query's 'IndexFields' could 
///                     be used to create an index that should help improve 
///                     performance.
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.UtilSQLAnalysis).outlierIndices(...)
///                    SQL: CALL %SYS_PTools.PT_outlierIndices(...)
///                         SELECT %SYS_PTools.PT_outlierIndices(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples provide analytical information
///               produced from the invocation of this method:
/// 
///    #1         Show info from where the SQL Statements were collected:
/// 
///               SELECT %EXACT(Type) AS QueryType, Count(*) AS QueryCount 
///               FROM %SYS_PTools.UtilSQLStatements 
///               GROUP BY Type
///         OR
///               SELECT * FROM %SYS_PTools.UtilSQLAnalysis_countSQLStmtTypes()
/// 
///    #2         Show the data collected from the running of this method:
/// 
///               SELECT SchemaName, TableName, 
///                      SQLPointer->Type, SQLPointer->Name, 
///                      $LISTTOSTRING(IndexFields) As "Index Fields", 
///                      JoinIndexFlag As "Join Index Flag",
///                      ExtentSize, BlockCount As "Block Count", 
///                      SQLPointer->SQLTextExt AS "SQL Text"
///               FROM %SYS_PTools.UtilSQLAnalysisDB 
///               WHERE OptionName = 'OI' 
///               ORDER BY 1,2
///         OR
///               SELECT * FROM %SYS_PTools.UtilSQLAnalysis_outlierIndices()
/// 
///               NOTE: This query will return OutlierIndexFlag AS 
///                     "Outlier Index Flag" as a numeric value (0-3) as 
///                     specified above.  However, in order to return more 
///                     specificity for this field, one of the following 
///                     values can be passed to the 2nd parameter 
///                     'indexFlagInfo' of the outlierIndices() query:
/// 
///                        0 = The Index-Flag Internal Value   [DEFAULT]
///                        1 = The Index-Flag Title
///                        2 = The Index-Flag Definition
///                        3 = The Index-Flag as 'Title: Definition'
/// 
///               EXAMPLE:
/// 
///                  SELECT * FROM %SYS_PTools.UtilSQLAnalysis_outlierIndices(,3)
/// 
///         OR
///               SELECT SchemaName, TableName, Type, "Class/Routine Name",
///                      IndexName, "Index Fields", "Bias Outlier",
///                      "Outlier Index Flag", "Outlier Field", 
///                      "Outlier Condition", "Outlier Selectivity",
///                      "Outlier WHERE Condition", 
///                      ExtentSize, "Block Count", 
///                      "SQL Text"
///               FROM %SYS_PTools.UtilSQLAnalysis_outlierIndices()
/// 
///    #3         Show outlier-based tables with less than optimal indexes 
///               that support the Outlier Condition specified in the query:
/// 
///               SELECT SchemaName, TableName, IndexFields As "Index Fields", 
///                      OutlierIndexFlag AS "Outlier Index Flag", 
///                      COUNT(*) AS "Query Count"
///               FROM %SYS_PTools.UtilSQLAnalysisDB
///               WHERE OutlierIndexFlag < 4 and OptionName = 'OI'
///               GROUP BY SchemaName, TableName, IndexFields
///               ORDER BY 4,5 DESC 
///                  -- These tables should be reviewed to see if a better
///                  -- index can be added to fully support the Outlier Conditions
/// 
///               NOTE: These queries can be invoked from a number of tools,
///                     such as the SQL Query tool in the 'Management Portal'
///                     or via 'SQL Query Shell' within a 'InterSystems IRIS Terminal' as
///                     shown below:
///                        >do $SYSTEM.SQL.Shell()
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","util","SQLAnlsys","{C|D|I|S}")
/// 
///  Parameters:
///    clearData    - 1 = Kill all of the existing data before re-populating
///                       with the results of this method invocation
///                          [DEFAULT: 1]
///    getSQLStmts  - 1 = Get all the SQL Statements from InterSystems IRIS locations 
///                       (Cached Queries, Class Methods, Class Queries, MAC Routines)
///                       and add them to the <class>%SYS.PTools.UtilSQLStatements</class> class for 
///                       additional processing of this method
///                       NOTE: This is an all inclusive call which could be time
///                             consuming.  The <class>%SYS.PTools.UtilSQLStatements</class> class can
///                             populated via APIs that offer more precise collection
///                             alternatives which are less time consuming
///                          [DEFAULT: 0]
///    skipSysObj   - 0 = Don't skip all System Objects (Classes & Routines)
///                   1 = Skip all System Objects (Classes & Routines) that
///                       start with: { % | DeepSee | Ens | HS | INFORMATION{.|_}SCHEMA }
///                   2 = Skip all System Objects that are not defined in
///                       the namespace in which this method is invoked
///                   3 = Skip all System Objects defined by InterSystems, even if
///                       the object is also defined in the namespace in which this
///                       method is invoked
///                   NOTE-1: Pass the combination of the specified options if more
///                           than one option desired (e.g. 13 => #1 & #3)
///                   NOTE-2: This only applies when retrieving SQL Statements (getSQLStmts=1)
///                          [DEFAULT: 1]
///    skipInsStmts - 1 = Skip INSERT Statements, as they don't have looping logic
///                          [DEFAULT: 1]
///    display      - 1 = Display messages while processing method
///                          [DEFAULT: 1]
///    ptInfo       - A Pass By Reference information array that returns to the user 
///                   the following details:
///                      ptInfo("insert-cnt")=The number of rows inserted in the <class>%SYS.PTools.UtilSQLAnalysisDB</class>
///                                           class for queries that have outliers indexing issues
///    
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod outlierIndices(clearData As %Integer = 1, getSQLStmts As %Integer = 0, skipSysObj As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_outlierIndices, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$outlierIndices^%SYS.PTools2(clearData,getSQLStmts,skipSysObj,skipInsStmts,display,.ptInfo)
}

/// <p class="info-head">
/// Query:        outlierIndices
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      A query to return the results generated by the invocation of
///               the 'outlierIndices()' method...
/// 
/// Invocation:   This Query can be invoked in the following way:
///                  SELECT * FROM %SYS_PTools.UtilSQLAnalysis_outlierIndices()
/// 
///  Parameters:
///   schema          - The schema of the table being queried in the SQL Statement
///                     to match against the 'SchemaName' property/field
///                        "" = All Schemas                    [DEFAULT]
///   indexFlagInfo   - The specific information that should be returned for
///                     the "Outlier Index Flag" field:
///                        0 = The Index-Flag Internal Value   [DEFAULT]
///                        1 = The Index-Flag Title
///                        2 = The Index-Flag Definition
///                        3 = The Index-Flag as 'Title: Definition'
///   skipOIF4        - 0 - Export all rows regardless of the 'OutlierIndexFlag' value
///                     1 - Export all rows where the value of the 'OutlierIndexFlag' is not 4  [DEFAULT]
/// </p>
Query outlierIndices(schema = "", indexFlagInfo = 0, skipOIF4 = 1) As %SQLQuery(ROWSPEC = "SchemaName:%String,TableName:%String,Type:%String,Class/Routine Name:%String,IndexName:%String,Index Fields:%String,Bias Outlier:%Boolean,Outlier Index Flag:%String,Outlier Field:%String,Outlier Condition:%String,Outlier Selectivity:%Float,Outlier WHERE Condition:%String,ExtentSize:%Integer,Block Count:%Integer,SQL Text:%String")
{
	SELECT %Exact(SchemaName), %Exact(TableName), SQLPointer->Type AS Type, SQLPointer->Name, 
	       %Exact(IndexName), $LISTTOSTRING(IndexFields) As "Index Fields",
	       BiasQueriesAsOutlier AS "Bias Outlier", 	       
	       CASE
	          WHEN :indexFlagInfo > 0
	             THEN %SYS_PTools.PT_getIndexFlagInfo(OutlierIndexFlag,'outlierIndices',:indexFlagInfo)
	          ELSE OutlierIndexFlag 
	       END AS "Outlier Index Flag", 
	       OutlierField AS "Outlier Fields",
	       OutlierValue AS "Outlier Condition", OutlierSelectivity AS "Outlier Selectivity",
	       WhereCondition AS "Outlier WHERE Condition", 
	       ExtentSize, BlockCount AS "Block Count", SQLPointer->SQLTextExt AS "SQL Text"
	FROM %SYS_PTools.UtilSQLAnalysisDB
	WHERE     OptionName = 'OI' 
	      AND (SchemaName = :schema OR :schema IS NULL)
	      AND (OutlierIndexFlag < 4 OR :skipOIF4 = 0)
	-- MRP907 (DON'T USE): GROUP BY OutlierIndexFlag, SchemaName, TableName, IndexFields
	ORDER BY OutlierIndexFlag DESC
}

/// <p class="section-head">
/// <b>                   A L L   S Q L   S T A T E M E N T S                     </b>
///                       -----------------------------------
/// Gather SQL Statements from all places within InterSystems IRIS and add them
/// to the <class>%SYS.PTools.UtilSQLStatements</class> class for Index Analysis and additional 
/// processing...
/// </p>
/// 
/// <p class="info-head">
/// Method:       getAllSQLStmts [SQL: PT_getAllSQLStmts]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Get the SQL Statements from all of the following locations and 
///               add them to the <class>%SYS.PTools.UtilSQLStatements</class> class for 
///               additional processing:
///                  - Cached Queries
///                  - Class Methods
///                  - Class Queries
///                  - MAC Routines
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.UtilSQLAnalysis).getAllSQLStmts(...)
///                    SQL: CALL %SYS_PTools.PT_getAllSQLStmts(...)
///                         SELECT %SYS_PTools.PT_getAllSQLStmts(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples provide analytical information
///               produced from the invocation of this method:
/// 
///    #1         Show info from where the SQL Statements were collected:
/// 
///               SELECT %EXACT(Type) AS QueryType, Count(*) AS QueryCount 
///               FROM %SYS_PTools.UtilSQLStatements 
///               GROUP BY Type
///         OR
///               SELECT * FROM %SYS_PTools.UtilSQLAnalysis_countSQLStmtTypes()
/// 
///    #2         Show the data collected from the running of this method:
/// 
///               SELECT Type, Name, MethodName, ImportPackage, 
///                      SQLTextExt AS "SQL Text"
///               FROM %SYS_PTools.UtilSQLStatements
///               ORDER BY Type, Name
///         OR
///               SELECT * FROM %SYS_PTools.UtilSQLAnalysis_getAllSQLStmts()
/// 
///         OR
///               SELECT Type, "Class/Routine Name", "Method Name", ImportPackage,
///                      "SQL Text"
///               FROM %SYS_PTools.UtilSQLAnalysis_getAllSQLStmts()
/// 
///               NOTE: These queries can be invoked from a number of tools,
///                     such as the SQL Query tool in the 'Management Portal'
///                     or via 'SQL Query Shell' within a 'InterSystems IRIS Terminal' as
///                     shown below:
///                        >do $SYSTEM.SQL.Shell()
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","util","SQLStmts","{C|D|I|S}")
/// 
/// Parameters:
///    clearData    - 1 = Kill all of the existing data before re-populating
///                       with the results of this method invocation
///                          [DEFAULT: 1]
///    skipSysObj   - 0 = Don't skip all System Objects (Classes & Routines)
///                   1 = Skip all System Objects (Classes & Routines) that
///                       start with: { % | DeepSee | Ens | HS | INFORMATION{.|_}SCHEMA }
///                   2 = Skip all System Objects that are not defined in
///                       the namespace in which this method is invoked
///                   3 = Skip all System Objects defined by InterSystems, even if
///                       the object is also defined in the namespace in which this
///                       method is invoked
///                   NOTE: Pass the combination of the specified options if more
///                         than one option desired (e.g. 13 => #1 & #3)
///                          [DEFAULT: 1]
///    skipInsStmts - 1 = Skip INSERT Statements, as they don't have looping logic
///                          [DEFAULT: 1]
///    display      - 1 = Display messages while processing method
///                          [DEFAULT: 1]
///    returnType   - 0 = Return a %Status code of either $$$OK or $$$ERROR()
///                   1 = Return a $LIST of SQL Statements added to the 
///                       <class>%SYS.PTools.UtilSQLStatements</class> class
///                          [DEFAULT: 0]
///    ptInfo       - A Pass By Reference information array that returns to the user 
///                   the following details:
///                      ptInfo("insert-list")=The number of rows inserted in the '%SYS.PTools.UtilSQLStatements'
///                                            class in the following $LIST format
///                                               $LIST() pieces:
///                                                     1) Grand Total of all SQL Query Statements added
///                                                     2) Total of all Cached Query Statements added
///                                                     3) Total of all Class Method Statements added
///                                                     4) Total of all Class Query Statements added
///                                                     5) Total of all Routine Statements added
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
/// 
///           1:  Return the number of SQL Statements added to the <class>%SYS.PTools.UtilSQLStatements</class>
///               class in the following $LIST format; Otherwise, return an error 
///               message if an error occurred.
/// 
///                  $LIST() pieces:
///                        1) Grand Total of all SQL Query Statements added
///                        2) Total of all cached query Statements added
///                        3) Total of all Class Method Statements added
///                        4) Total of all Class Query Statements added
///                        5) Total of all Routine Statements added
/// </p>
ClassMethod getAllSQLStmts(clearData As %Integer = 1, skipSysObj As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_getAllSQLStmts, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getAllSQLStmts^%SYS.PTools2(clearData,skipSysObj,skipInsStmts,display,returnType,.ptInfo)
}

/// <p class="info-head">
/// Query:        getAllSQLStmts
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      A query to return the results generated by the invocation of
///               the 'getAllSQLStmts()' method...
/// 
///  Parameters:
/// </p>
Query getAllSQLStmts() As %SQLQuery(ROWSPEC = "Type:%String,Class/Routine Name:%String,Method Name:%String,ImportPackage:%String,SQL Text:%String")
{
	SELECT Type, Name, MethodName, ImportPackage, SQLTextExt
	FROM %SYS_PTools.UtilSQLStatements
	ORDER BY Type, Name
}

/// <p class="info-head">
/// Method:       getSQLStmts [SQL: PT_getSQLStmts]
/// Replaces:     GetSQLStatements (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      This method searches for at all of the SQL Statements in a 
///               namespace from the following locations based on the parameter 
///               values (getCachedQry,getClassMethQry,getClassQry,getRtnQry)
///               and adds information about the statements (e.g. Type, Name, 
///               SQLText) to the <class>%SYS.PTools.UtilSQLStatements</class> class 
///               for additional processing:
///                  - Cached Queries   [ if getCachedQry=1    ]
///                  - Class Methods    [ if getClassMethQry=1 ]
///                  - Class Queries    [ if getClassQry=1     ]
///                  - MAC Routines     [ if getRtnQry=1       ]
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.UtilSQLAnalysis).getSQLStmts(...)
///                    SQL: CALL %SYS_PTools.PT_getSQLStmts(...)
///                         SELECT %SYS_PTools.PT_getSQLStmts(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples provide analytical information
///               produced from the invocation of this method:
/// 
///    #1         Show info from where the SQL Statements were collected:
/// 
///               SELECT %EXACT(Type) AS QueryType, Count(*) AS QueryCount 
///               FROM %SYS_PTools.UtilSQLStatements 
///               GROUP BY Type
///         OR
///               SELECT * FROM %SYS_PTools.UtilSQLAnalysis_countSQLStmtTypes()
/// 
///    #2         Show the data collected from the running of this method:
/// 
///               SELECT Type, Name, MethodName, ImportPackage, 
///                      SQLTextExt AS "SQL Text"
///               FROM %SYS_PTools.UtilSQLStatements
///               ORDER BY Type, Name
///         OR
///               SELECT * FROM %SYS_PTools.UtilSQLAnalysis_getSQLStmts()
/// 
///         OR
///               SELECT Type, "Class/Routine Name", "Method Name", ImportPackage,
///                      "SQL Text"
///               FROM %SYS_PTools.UtilSQLAnalysis_getSQLStmts()
/// 
///               NOTE: These queries can be invoked from a number of tools,
///                     such as the SQL Query tool in the 'Management Portal'
///                     or via 'SQL Query Shell' within a 'InterSystems IRIS Terminal' as
///                     shown below:
///                        >do $SYSTEM.SQL.Shell()
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","util","SQLStmts","{C|D|I|S}")
/// 
/// Parameters:
///    clearData       - 1 = Kill all of the existing data before re-populating
///                          with the results of this method invocation
///                             [DEFAULT: 1]
///    skipSysObj      - 0 = Don't skip all System Objects (Classes & Routines)
///                      1 = Skip all System Objects (Classes & Routines) that
///                          start with: { % | DeepSee | Ens | HS | INFORMATION{.|_}SCHEMA }
///                      2 = Skip all System Objects that are not defined in
///                          the namespace in which this method is invoked
///                      3 = Skip all System Objects defined by InterSystems, even if
///                          the object is also defined in the namespace in which this
///                          method is invoked
///                      NOTE: Pass the combination of the specified options if more
///                            than one option desired (e.g. 13 => #1 & #3)
///                             [DEFAULT: 1]
///    skipInsStmts    - 1 = Skip INSERT Statements, as they don't have looping logic
///                             [DEFAULT: 1]
///    getCachedQry    - 1 = Get the SQL Statements from all Cached Queries
///                             [DEFAULT: 1]
///    getClassMethQry - 1 = Get the SQL Statements from all of the Class Methods
///                             [DEFAULT: 1]
///    getClassQry     - 1 = Get the SQL Statements from all of the Class Queries
///                             [DEFAULT: 1]
///    getRtnQry       - 1 = Get the Embedded SQL Statements from all of the MAC Routines
///                             [DEFAULT: 1]
///    display         - 1 = Display messages while processing method
///                             [DEFAULT: 1]
///    returnType      - 0 = Return a %Status code of either $$$OK or $$$ERROR()
///                      1 = Return a $LIST of SQL Statements added to the 
///                          <class>%SYS.PTools.UtilSQLStatements</class> class
///                             [DEFAULT: 0]
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return the status of this method; Otherwise, return an error 
///               message if an error occurred
/// 
///           1:  Return the number of SQL Statements added to the <class>%SYS.PTools.UtilSQLStatements</class>
///               class in the following $LIST format; Otherwise, return an error 
///               message if an error occurred.
/// 
///                  $LIST() pieces:
///                        1) Grand Total of all SQL Query Statements added
///                        2) Total of all cached query Statements added
///                        3) Total of all Class Method Statements added
///                        4) Total of all Class Query Statements added
///                        5) Total of all Routine Statements added
/// </p>
ClassMethod getSQLStmts(clearData As %Integer = 1, skipSysObj As %Integer = 1, skipInsStmts As %Integer = 1, getCachedQry As %Integer = 1, getClassMethQry As %Integer = 1, getClassQry As %Integer = 1, getRtnQry As %Integer = 1, display As %Integer = 1, returnType As %Integer = 0) As %Status [ SqlName = PT_getSQLStmts, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getSQLStmts^%SYS.PTools2(clearData,skipSysObj,skipInsStmts,getCachedQry,getClassMethQry,getClassQry,getRtnQry,display,returnType)
}

/// <p class="info-head">
/// Query:        getSQLStmts
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      A query to return the results generated by the invocation of
///               the 'getSQLStmts()' method...
/// 
///  Parameters:
///   N/A
/// </p>
Query getSQLStmts() As %SQLQuery(ROWSPEC = "Type:%String,Class/Routine Name:%String,Method Name:%String,ImportPackage:%String,SQL Text:%String")
{
	SELECT Type, Name, MethodName, ImportPackage, SQLTextExt
	FROM %SYS_PTools.UtilSQLStatements
	ORDER BY Type, Name
}

/// <p class="section-head">
/// <b>                      C A C H E D   Q U E R I E S                          </b>
///                          ---------------------------
/// Gather SQL Statements from all of the Cached Queries within InterSystems IRIS 
/// and add them to the <class>%SYS.PTools.UtilSQLStatements</class> class for Index Analysis 
/// and additional processing...
/// </p>
/// 
/// <p class="info-head">
/// Method:       getAllCachedQrySQLStmts [SQL: PT_getAllCachedQrySQLStmts]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Get the SQL Statements from all of the Cached Queries created 
///               and add them to the <class>%SYS.PTools.UtilSQLStatements</class> class for 
///               additional processing...
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","util","SQLStmts","{C|D|I|S}")
/// 
/// Parameters:
///    clearData    - 1 = Kill all of the existing data before re-populating
///                       with the results of this method invocation
///                           [DEFAULT: 1]
///    skipInsStmts - 1 = Skip INSERT Statements, as they don't have looping logic
///                           [DEFAULT: 1]
///    display      - 1 = Display messages while processing method
///                           [DEFAULT: 1]
///    
/// RETURN Value: The number of Cached Queries added to the <class>%SYS.PTools.UtilSQLStatements</class>
///               class; Otherwise, return an error message if an error occurred
/// </p>
ClassMethod getAllCachedQrySQLStmts(clearData As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1) As %Integer [ SqlName = PT_getAllCachedQrySQLStmts, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getAllCachedQrySQLStmts^%SYS.PTools2(clearData,skipInsStmts,display)
}

/// <p class="info-head">
/// Method:       getCachedQrySQLStmtsByDays [SQL: PT_getCachedQrySQLStmtsByDays]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Get the SQL Statements from all Cached Queries that have had a 
///               Prepare in the last 'days' days and add them to the 
///               <class>%SYS.PTools.UtilSQLStatements</class> class for additional processing...
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","util","SQLStmts","{C|D|I|S}")
/// 
/// Parameters:
///    days         - The number of days since the last Cached Query was Prepared.
///                   If days=0, then get all Cached Queries.
///                           [DEFAULT: 0 (All)]
///    clearData    - 1 = Kill all of the existing data before re-populating
///                       with the results of this method invocation
///                           [DEFAULT: 1]
///    skipInsStmts - 1 = Skip INSERT Statements, as they don't have looping logic
///                           [DEFAULT: 1]
///    display      - 1 = Display messages while processing method
///                           [DEFAULT: 1]
///    
/// RETURN Value: The number of Cached Queries added to the <class>%SYS.PTools.UtilSQLStatements</class>
///               class; Otherwise, return an error message if an error occurred
/// </p>
ClassMethod getCachedQrySQLStmtsByDays(days As %Integer = 0, clearData As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1) As %Integer [ SqlName = PT_getCachedQrySQLStmtsByDays, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getCachedQrySQLStmtsByDays^%SYS.PTools2(days,clearData,skipInsStmts,display)
}

/// <p class="info-head">
/// Method:       getCachedQrySQLStmtsByClass [SQL: PT_getCachedQrySQLStmtsByClass]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Get the SQL Statements from all Cached Queries provided in the 
///               'items' array and add them to the <class>%SYS.PTools.UtilSQLStatements</class> 
///               class for additional processing...
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","util","SQLStmts","{C|D|I|S}")
/// 
/// Parameters:
///    item         - A comma delimited list or array of Cached Query class names
///                   NOTE: The class names must either all contain class
///                         extensions (e.g. myClass.CLS) or none at all (e.g. myClass)
///                   EXAMPLE:
///                      items="%sqlcq.SAMPLES.cls1,%sqlcq.SAMPLES.cls2"
///                         OR
///                      items("%sqlcq.SAMPLES.cls1")=""
///                      items("%sqlcq.SAMPLES.cls2")=""
///    clearData    - 1 = Kill all of the existing data before re-populating
///                       with the results of this method invocation
///                           [DEFAULT: 1]
///    skipInsStmts - 1 = Skip INSERT Statements, as they don't have looping logic
///                           [DEFAULT: 1]
///    display      - 1 = Display messages while processing method
///                           [DEFAULT: 1]
///    
/// RETURN Value: The number of Cached Queries added to the <class>%SYS.PTools.UtilSQLStatements</class>
///               class; Otherwise, return an error message if an error occurred
/// </p>
ClassMethod getCachedQrySQLStmtsByClass(ByRef items As %RawString, clearData As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1) As %Integer [ SqlName = PT_getCachedQrySQLStmtsByClass, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getCachedQrySQLStmtsByClass^%SYS.PTools2(.items,clearData,skipInsStmts,display)
}

/// <p class="section-head">
/// <b>                      C L A S S   M E T H O D S                            </b>
///                          -------------------------
///  Gather SQL Statements from all of the Class Methods within InterSystems IRIS 
///  and add them to the <class>%SYS.PTools.UtilSQLStatements</class> class for Index Analysis 
///  and additional processing...
/// </p>
/// 
/// <p class="info-head">
/// Method:       getAllClassMethSQLStmts [SQL: PT_getAllClassMethSQLStmts]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Get the SQL Statements from all of the Class Methods created
///               and add them to the <class>%SYS.PTools.UtilSQLStatements</class> class for 
///               additional processing...
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","util","SQLStmts","{C|D|I|S}")
/// 
/// Parameters:
///    clearData    - 1 = Kill all of the existing data before re-populating
///                       with the results of this method invocation
///                           [DEFAULT: 1]
///    skipSysClass - 0 = Don't skip all System Classes
///                   1 = Skip all System Classes that start with:
///                          { % | DeepSee | Ens | HS | INFORMATION{.|_}SCHEMA }
///                   2 = Skip all System Classes that are not defined in the
///                       namespace in which this method is invoked
///                   3 = Skip all System Classes defined by InterSystems, even if
///                       the class is also defined in the namespace in which this
///                       method is invoked
///                   NOTE: Pass the combination of the specified options if more
///                         than one option desired (e.g. 13 => #1 & #3)
///                           [DEFAULT: 1]
///    skipInsStmts - 1 = Skip INSERT Statements, as they don't have looping logic
///                           [DEFAULT: 1]
///    display      - 1 = Display messages while processing method
///                           [DEFAULT: 1]
///    
/// RETURN Value: The number of cached queries added to the <class>%SYS.PTools.UtilSQLStatements</class>
///               class; Otherwise, return an error message if an error occurred
/// </p>
ClassMethod getAllClassMethSQLStmts(clearData As %Integer = 1, skipSysClass As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1) As %Integer [ SqlName = PT_getAllClassMethSQLStmts, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getAllClassMethSQLStmts^%SYS.PTools2(clearData,skipSysClass,skipInsStmts,display)
}

/// <p class="info-head">
/// Method:       getClassMethSQLStmtsByClass [SQL: PT_getClassMethSQLStmtsByClass]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Get the SQL Statements from all Class Methods provided in the 
///               'items' array and add them to the <class>%SYS.PTools.UtilSQLStatements</class> 
///               class for additional processing...
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","util","SQLStmts","{C|D|I|S}")
/// 
/// Parameters:
///    item         - A comma delimited list or array of Class Methods class names
///                   NOTE: The class names must either all contain class
///                         extensions (e.g. myClass.CLS) or none at all (e.g. myClass)
///                   EXAMPLE:
///                      items="Cinema.Film,Sample.Person"
///                         OR
///                      items("Cinema.Film")=""
///                      items("Sample.Person")=""
///    clearData    - 1 = Kill all of the existing data before re-populating
///                       with the results of this method invocation
///                           [DEFAULT: 1]
///    skipInsStmts - 1 = Skip INSERT Statements, as they don't have looping logic
///                           [DEFAULT: 1]
///    display      - 1 = Display messages while processing method
///                           [DEFAULT: 1]
///    
/// RETURN Value: The number of Class Methods added to the <class>%SYS.PTools.UtilSQLStatements</class>
///               class; Otherwise, return an error message if an error occurred
/// </p>
ClassMethod getClassMethSQLStmtsByClass(ByRef items As %RawString, clearData As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1) As %Integer [ SqlName = PT_getClassMethSQLStmtsByClass, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getClassMethSQLStmtsByClass^%SYS.PTools2(.items,clearData,skipInsStmts,display)
}

/// <p class="section-head">
/// <b>                      C L A S S   Q U E R Y                                </b>
///                          ---------------------
///  Gather SQL Statements from all of the Class Queries within InterSystems IRIS 
///  and add them to the <class>%SYS.PTools.UtilSQLStatements</class> class for Index Analysis 
///  and additional processing...
/// </p>
/// 
/// <p class="info-head">
/// Method:       getAllClassQrySQLStmts [SQL: PT_getAllClassQrySQLStmts]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Get the SQL Statements from all of the Class Queries created 
///               and add them to the <class>%SYS.PTools.UtilSQLStatements</class> class for 
///               additional processing...
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","util","SQLStmts","{C|D|I|S}")
/// 
/// Parameters:
///    clearData    - 1 = Kill all of the existing data before re-populating
///                       with the results of this method invocation
///                           [DEFAULT: 1]
///    skipSysClass - 0 = Don't skip all System Classes
///                   1 = Skip all System Classes that start with:
///                          { % | DeepSee | Ens | HS | INFORMATION{.|_}SCHEMA }
///                   2 = Skip all System Classes that are not defined in the
///                       namespace in which this method is invoked
///                   3 = Skip all System Classes defined by InterSystems, even if
///                       the class is also defined in the namespace in which this
///                       method is invoked
///                   NOTE: Pass the combination of the specified options if more
///                         than one option desired (e.g. 13 => #1 & #3)
///                           [DEFAULT: 1]
///    skipInsStmts - 1 = Skip INSERT Statements, as they don't have looping logic
///                           [DEFAULT: 1]
///    display      - 1 = Display messages while processing method
///                           [DEFAULT: 1]
///    
/// RETURN Value: The number of Class Queries added to the <class>%SYS.PTools.UtilSQLStatements</class>
///               class; Otherwise, return an error message if an error occurred
/// </p>
ClassMethod getAllClassQrySQLStmts(clearData As %Integer = 1, skipSysClass As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1) As %Integer [ SqlName = PT_getAllClassQrySQLStmts, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getAllClassQrySQLStmts^%SYS.PTools2(clearData,skipSysClass,skipInsStmts,display)
}

/// <p class="info-head">
/// Method:       getClassQrySQLStmtsByClass [SQL: PT_getClassQrySQLStmtsByClass]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Get the SQL Statements from all Class Queries provided in the 
///               'items' array and add them to the <class>%SYS.PTools.UtilSQLStatements</class> 
///               class for additional processing...
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","util","SQLStmts","{C|D|I|S}")
/// 
/// Parameters:
///    item         - A comma delimited list or array of Class Query class names
///                   NOTE: The class names must either all contain class
///                         extensions (e.g. myClass.CLS) or none at all (e.g. myClass)
///                   EXAMPLE:
///                      items="Cinema.Film,Sample.Person"
///                         OR
///                      items("Cinema.Film")=""
///                      items("Sample.Person")=""
///    clearData    - 1 = Kill all of the existing data before re-populating
///                       with the results of this method invocation
///                           [DEFAULT: 1]
///    skipInsStmts - 1 = Skip INSERT Statements, as they don't have looping logic
///                           [DEFAULT: 1]
///    display      - 1 = Display messages while processing method
///                           [DEFAULT: 1]
///    
/// RETURN Value: The number of Class Queries added to the <class>%SYS.PTools.UtilSQLStatements</class>
///               class; Otherwise, return an error message if an error occurred
/// </p>
ClassMethod getClassQrySQLStmtsByClass(ByRef items As %RawString, clearData As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1) As %Integer [ SqlName = PT_getClassQrySQLStmtsByClass, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getClassQrySQLStmtsByClass^%SYS.PTools2(.items,clearData,skipInsStmts,display)
}

/// <p class="section-head">
/// <b>                      R O U T I N E   Q U E R Y                            </b>
///                          -------------------------
///  Gather SQL Statements from all of the MAC Routines within InterSystems IRIS 
///  and add them to the <class>%SYS.PTools.UtilSQLStatements</class> class for Index Analysis 
///  and additional processing...
/// </p>
/// 
/// <p class="info-head">
/// Method:       getAllRtnQrySQLStmts [SQL: PT_getAllRtnQrySQLStmts]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Get the Embedded SQL Statements from all of the MAC Routines 
///               and add them to the <class>%SYS.PTools.UtilSQLStatements</class> class for 
///               additional processing...
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","util","SQLStmts","{C|D|I|S}")
/// 
/// Parameters:
///    clearData    - 1 = Kill all of the existing data before re-populating
///                       with the results of this method invocation
///                           [DEFAULT: 1]
///    skipSysRtn   - 0 = Don't skip all System Routines
///                   1 = Skip all System Routines that start with: 
///                       { % | DeepSee | Ens | HS | INFORMATION{.|_}SCHEMA }
///                   2 = Skip all System Routines that are not defined in the
///                       namespace in which this method is invoked
///                   3 = Skip all System Routines defined by InterSystems, even if
///                       the routine is also defined in the namespace in which this
///                       method is invoked
///                   NOTE: Pass the combination of the specified options if more
///                         than one option desired (e.g. 13 => #1 & #3)
///                           [DEFAULT: 1]
///    skipInsStmts - 1 = Skip INSERT Statements, as they don't have looping logic
///                           [DEFAULT: 1]
///    display      - 1 = Display messages while processing method
///                           [DEFAULT: 1]
///    
/// RETURN Value: The number of Embedded SQL Statements added to the <class>%SYS.PTools.UtilSQLStatements</class>
///               class; Otherwise, return an error message if an error occurred
/// </p>
ClassMethod getAllRtnQrySQLStmts(clearData As %Integer = 1, skipSysRtn As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1) As %Integer [ SqlName = PT_getAllRtnQrySQLStmts, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getAllRtnQrySQLStmts^%SYS.PTools2(clearData,skipSysRtn,skipInsStmts,display)
}

/// <p class="info-head">
/// Method:       getRtnQrySQLStmtsByRtn [SQL: PT_getRtnQrySQLStmtsByRtn]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Get the Embedded SQL Statements from all of the MAC Routines 
///               provided in the 'items' array and add them to the 
///               <class>%SYS.PTools.UtilSQLStatements</class> class for additional processing...
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","util","SQLStmts","{C|D|I|S}")
/// 
/// Parameters:
///    item         - A comma delimited list or array of MAC Routine names
///                   NOTE: The routine names must either all contain 
///                         extensions (e.g. myRtn.MAC) or none at all (e.g. myRtn)
///                   EXAMPLE:
///                      items="MRPtest1,MRPtest2"
///                         OR
///                      items("MRPtest1")=""
///                      items("MRPtest2")=""
///    clearData    - 1 = Kill all of the existing data before re-populating
///                       with the results of this method invocation
///                           [DEFAULT: 1]
///    skipInsStmts - 1 = Skip INSERT Statements, as they don't have looping logic
///                           [DEFAULT: 1]
///    display      - 1 = Display messages while processing method
///                           [DEFAULT: 1]
///    
/// RETURN Value: The number of Cached Queries added to the <class>%SYS.PTools.UtilSQLStatements</class>
///               class; Otherwise, return an error message if an error occurred
/// </p>
ClassMethod getRtnQrySQLStmtsByRtn(ByRef items As %RawString, clearData As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1) As %Integer [ SqlName = PT_getRtnQrySQLStmtsByRtn, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getRtnQrySQLStmtsByRtn^%SYS.PTools2(.items,clearData,skipInsStmts,display)
}

/// <p class="section-head">
/// <b>                   C O L L E C T   S Q L   I N D E X E S                   </b>
///                       =====================================
/// 
/// <b>                       A L L   S Q L   I N D E X E S                       </b>
///                           -----------------------------
///  Gather SQL Indexes from all classes within InterSystems IRIS and add them
///  to the <class>%SYS.PTools.SQLUtilResult</class> class for Index Analysis and additional 
///  processing
/// </p>
/// 
/// <p class="info-head">
/// Method:       getAllIndices [SQL: PT_getAllIndices]
/// Replaces:     N/A  [AllIndices^%SYS.PToolsDEP]
/// Status:       New Functionality
/// Purpose:      This method processes all of the classes/tables on the system
///               and collects all of the defined Indexes and adds them to
///               the <class>%SYS.PTools.UtilSQLAnalysisDB</class> class for
///               future processing...
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.UtilSQLAnalysis).getAllIndices(...)
///                    SQL: CALL %SYS_PTools.PT_getAllIndices(...)
///                         SELECT %SYS_PTools.PT_getAllIndices(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples provide analytical information
///               produced from the invocation of this method:
/// 
///    #1         Show the data collected from the running of this method:
/// 
///               SELECT * FROM %SYS_PTools.UtilSQLAnalysis_getAllIndices()
/// 
///               NOTE: These queries can either be invoked from a number of
///                     tools, such as the SQL Query tool in the 'Management Portal'
///                     or via 'SQL Query Shell' within a 'InterSystems IRIS Terminal' as show
///                     below:
///                        >do $SYSTEM.SQL.Shell()
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","util","SQLAnlsys","{C|D|I|S}")
/// 
/// Parameters:
///    clearData    - 1 = Kill all of the existing data before re-populating
///                       with the results of this method invocation
///                           [DEFAULT: 1]
///    skipSysClass - 0 = Don't skip all System Classes
///                   1 = Skip all System Classes that start with:
///                          { % | DeepSee | Ens | HS | INFORMATION{.|_}SCHEMA }
///                   2 = Skip all System Classes that are not defined in the
///                       namespace in which this method is invoked
///                   3 = Skip all System Classes defined by InterSystems, even if
///                       the class is also defined in the namespace in which this
///                       method is invoked
///                   NOTE: Pass the combination of the specified options if more
///                         than one option desired (e.g. 13 => #1 & #3)
///                           [DEFAULT: 1]
///    skipIDKeys   - 1 = Skip all the index that will be used to form the Object Identity 
///                       value (IDKEY) for the given class
///                           [DEFAULT: 1]
///    display      - 1 = Display messages while processing method
///                           [DEFAULT: 1]
///    
/// RETURN Value: The number of Indexes added to the <class>%SYS.PTools.UtilSQLAnalysisDB</class>
///               class; Otherwise, return an error message if an error occurred
/// </p>
ClassMethod getAllIndices(clearData As %Integer = 1, skipSysClass As %Integer = 1, skipIDKeys As %Integer = 1, display As %Integer = 1) As %Integer [ SqlName = PT_getAllIndices, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getAllIndices^%SYS.PTools2(clearData,skipSysClass,skipIDKeys,display)
}

/// <p class="info-head">
/// Query:        getAllIndices
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      A query to return the results generated by the invocation of
///               the 'getAllIndices()' method...
/// 
///  Parameters:
///   schema    - The schema of the table being queried in the SQL Statement
///               to match against the 'SchemaName' property/field
/// </p>
Query getAllIndices(schema) As %SQLQuery(ROWSPEC = "SchemaName:%String,TableName:%String,IndexName:%String,Usage Count:%Integer")
{
	SELECT %Exact(SchemaName), %Exact(Tablename), 
	       %Exact(IndexName), UsageCount AS "Usage Count"
	FROM %SYS_PTools.UtilSQLAnalysisDB 
	WHERE     OptionName = 'IU' 
	      AND (SchemaName = :schema OR :schema IS NULL)
	ORDER BY UsageCount
}

/// <p class="section-head">
/// <b>                         C L E A R   D A T A                               </b>
///                             -------------------
///  For each of the SQL Statements saved in the <class>%SYS.PTools.UtilSQLStatements</class> 
///  class, and each of the SQL Statement Results in the 
///  <class>%SYS.PTools.UtilSQLAnalysisDB</class> class, use one of the following 
///  methods to delete all of the data stored in these classes:
///     - clearSQLStatements()
///     - clearSQLAnalysisDB()
/// </p>
/// 
/// <p class="info-head">
/// Method:       clearSQLStatements [SQL: PT_clearSQLStatements]
/// Replaces:     ClearStatements [SQL: ClearStatements]  (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      Delete all of the data stored in the 
///               <class>%SYS.PTools.UtilSQLStatements</class> class, based 
///               on the specified parameters...
/// 
///               This method clears SQL Index Usage Analytical statistics which
///               are gathered when one of the following methods are invoked:
///                  - indexUsage()
///                  - tableScans()
///                  - tempIndices()
///                  - joinIndices()
///                  - outlierIndices()
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.UtilSQLAnalysis).clearSQLStatements(...)
///                           SQL: CALL %SYS_PTools.PT_clearSQLStatements(...)
///                                SELECT %SYS_PTools.PT_clearSQLStatements(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Delete all of the data stored in the '%SYS.PTools.UtilSQLStatements' 
///               class in the current namespace:
/// 
///               set status=##class(%SYS.PTools.UtilSQLAnalysis).clearSQLStatements()
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","util","SQLStmts","{C|D|I|S}")
/// 
///  Parameters:
///   ns          - The namespace in which to clear SQL Index/Analysis Statstics
///                    [DEFAULT: Current Namespace]
///   clearErrs   - 0 = Don't delete the 'PTools' Application Errors
///                 1 = Delete all of the 'PTools' Application Errors
///                    [DEFAULT: 0]
///   returnType  - 0 = Return a %Status code of either $$$OK or $$$ERROR()
///                 1 = Return the number of Stats rows deleted from the 
///                     following class: %SYS.PTools.UtilSQLStatements
///                    [DEFAULT: 0]
///   ptInfo      - A Pass By Reference information array that returns
///                 detailed information to the user in the following format:
///                    ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                 Where category = { "cnt" | "curr" | "term" | ... }
///                       variable = A var corresponding to the given 'category'
/// 
///                 Example:
///                    ptInfo("cnt","clearSQLStatements")=The number of rows deleted 
///                                                       via this method
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the number of Stats rows deleted from the following class; 
///               Otherwise, return an error message if an error occurred:
///                  %SYS.PTools.UtilSQLStatements
/// </p>
ClassMethod clearSQLStatements(ns As %String = "", clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_clearSQLStatements, SqlProc ]
{
	QUIT $$clearSQLStatements^%SYS.PTools2(ns,clearErrs,returnType,.ptInfo)
}

/// <p class="info-head">
/// Method:       clearSQLAnalysisDB [SQL: PT_clearSQLAnalysisDB]
/// Replaces:     ClearResults [SQL: ClearResults]  (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      Delete all of the data stored in the 
///               <class>%SYS.PTools.UtilSQLAnalysisDB</class> class, based
///               on the specified parameters...
/// 
///               This method clears SQL Index Usage Analytical statistics which
///               are gathered when one of the following methods are invoked:
///                  - indexUsage()
///                  - tableScans()
///                  - tempIndices()
///                  - joinIndices()
///                  - outlierIndices()
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.UtilSQLAnalysis).clearSQLAnalysisDB(...)
///                           SQL: CALL %SYS_PTools.PT_clearSQLAnalysisDB(...)
///                                SELECT %SYS_PTools.PT_clearSQLAnalysisDB(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Delete all of the data stored in the '%SYS.PTools.UtilSQLAnalysisDB' 
///               class in the current namespace:
/// 
///               set status=##class(%SYS.PTools.UtilSQLAnalysis).clearSQLAnalysisDB()
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","util","SQLAnlsys","{C|D|I|S}")
/// 
///  Parameters:
///   ns          - The namespace in which to clear SQL Index/Analysis Statstics
///                    [DEFAULT: Current Namespace]
///   clearErrs   - 0 = Don't delete the 'PTools' Application Errors
///                 1 = Delete all of the 'PTools' Application Errors
///                    [DEFAULT: 0]
///   returnType  - 0 = Return a %Status code of either $$$OK or $$$ERROR()
///                 1 = Return the number of Stats rows deleted from the 
///                     following class: %SYS.PTools.UtilSQLAnalysisDB
///                    [DEFAULT: 0]
///   ptInfo      - A Pass By Reference information array that returns
///                 detailed information to the user in the following format:
///                    ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                 Where category = { "cnt" | "curr" | "term" | ... }
///                       variable = A var corresponding to the given 'category'
/// 
///                 Example:
///                    ptInfo("cnt","clearSQLAnalysisDB")=The number of rows deleted 
///                                                       via this method
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the number of Stats rows deleted from the following class; 
///               Otherwise, return an error message if an error occurred:
///                  %SYS.PTools.UtilSQLAnalysisDB
/// </p>
ClassMethod clearSQLAnalysisDB(ns As %String = "", clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_clearSQLAnalysisDB, SqlProc ]
{
	QUIT $$clearSQLAnalysisDB^%SYS.PTools2(ns,clearErrs,returnType,.ptInfo)
}

/// <p class="section-head">
/// <b>                 E X P O R T I N G   /   R E P O R T I N G                 </b>
///                     -----------------------------------------
///  The following methods allow for the exporting and reporting of SQL Statements 
///  and accompanying data that have been saved in one of the following two
///  classes/tables:
///     - <class>%SYS.PTools.UtilSQLStatements</class> 
///     - <class>%SYS.PTools.UtilSQLAnalysisDB</class>
/// </p>
/// 
/// <p class="info-head">
/// Method:       exportUtilSQLStatements [SQL: PT_exportUtilSQLStatements]
/// Replaces:     exportSQLUtilStmts [SQL: PT_exportSQLUtilStmts]  (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      Create a file containing all the data from the 
///               <class>%SYS.PTools.UtilSQLStatements</class> class & return the output 
///               location...
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.UtilSQLAnalysis).exportUtilSQLStatements(...)
///                    SQL: CALL %SYS_PTools.PT_exportUtilSQLStatements(...)
///                         SELECT %SYS_PTools.PT_exportUtilSQLStatements(...)
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
///               set tSC=##class(%SYS.PTools.UtilSQLAnalysis).exportUtilSQLStatements($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYS_PTools.PT_exportUtilSQLStatements('$IO','H')
/// 
///               Where: '$IO' = Output to the current device
///                              NOTE: '$IO' can be omitted, as it is the default
///                                    'file' when invoked via the CALL interface
///                       'H'  = Output the format in HTML format
///                              NOTE: 'H' can be omitted, as it is the default
///                                    'format' when invoked via the CALL interface
/// 
///  Parameters:
///   file      - The path and file in which to create and store the data from the
///               %SYS.PTools.UtilSQLStatements class:  (e.g. C:\exportFile.txt) 
///               NOTE:    $IO = Outputs the data to the screen
///                      '$IO' = Output the data to the current device when invoked from the CALL/SELECT-interface
///                     '$DEF' = Ouput the data to the DEFAULT file when invoked from the CALL/SELECT-interface
///                 [DEFAULT: {Current-Directory}\PT_exportUtilSQLStatements_YYYYMMDD_HHMMSS.{ext}]
///                     WHERE {Current-Directory} = The directory of the Namespace in which
///                                                 this method is invoked (e.g. $ZU(12,""))
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
///   type      -  A single type, or a comma-delimited list of {Type} values to
///                restrict the output of rows from the <class>%SYS.PTools.UtilSQLStatements</class>
///                class. The {Type} is the location within InterSystems IRIS from where
///                the SQL Query was extracted:
///                   {Type} values: { cached query | Class Method | Class Query | Routine }
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
///    
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod exportUtilSQLStatements(file As %String = "", format As %String = "", silent As %Integer = 0, type As %String = "", ByRef conds As %RawString, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_exportUtilSQLStatements, SqlProc ]
{
	QUIT $$exportUtilSQLStatements^%SYS.PTools2(.file,.format,silent,type,.conds,.ptInfo)
}

/// <p class="info-head">
/// Method:       exportUtilSQLAnalysisDB [SQL: PT_exportUtilSQLAnalysisDB]
/// Replaces:     exportSQLUtilStmts [SQL: PT_exportSQLUtilStmts]  (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      Create a file containing all the data from the 
///               <class>%SYS.PTools.UtilSQLAnalysisDB</class> class & return the
///               output location...
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.UtilSQLAnalysis).exportUtilSQLAnalysisDB(...)
///                    SQL: CALL %SYS_PTools.PT_exportUtilSQLAnalysisDB(...)
///                         SELECT %SYS_PTools.PT_exportUtilSQLAnalysisDB(...)
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
///               set tSC=##class(%SYS.PTools.UtilSQLAnalysis).exportUtilSQLAnalysisDB($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYS_PTools.PT_exportUtilSQLAnalysisDB('$IO','H')
/// 
///               Where: '$IO' = Output to the current device
///                              NOTE: '$IO' can be omitted, as it is the default
///                                    'file' when invoked via the CALL interface
///                       'H'  = Output the format in HTML format
///                              NOTE: 'H' can be omitted, as it is the default
///                                    'format' when invoked via the CALL interface
/// 
///  Parameters:
///   file      - The path and file in which to create and store the data from the
///               %SYS.PTools.UtilSQLAnalysisDB class:  (e.g. C:\exportFile.txt) 
///               NOTE:    $IO = Outputs the data to the screen
///                      '$IO' = Output the data to the current device when invoked from the CALL/SELECT-interface
///                     '$DEF' = Ouput the data to the DEFAULT file when invoked from the CALL/SELECT-interface
///                 [DEFAULT: {Current-Directory}\PT_exportUtilSQLAnalysisDB_YYYYMMDD_HHMMSS.{ext}]
///                     WHERE {Current-Directory} = The directory of the Namespace in which
///                                                 this method is invoked (e.g. $ZU(12,""))
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
///   option    -  A single option, or a comma-delimited list of {OptionName} values
///                to restrict the output of rows from the <class>%SYS.PTools.UtilSQLAnalysisDB</class>
///                class.  The {OptionName} specifies the Index Usage Analysis method
///                used to collect the data:
///                   {OptionName} values: { IU - getAllIndices & indexUsage | 
///                                          TS - tableScans | TI - tempIndices | 
///                                          JI - joinIndices | OI - outlierIndices }
/// 
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
///    
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod exportUtilSQLAnalysisDB(file As %String = "", format As %String = "", silent As %Integer = 0, option As %String = "", ByRef conds As %RawString, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_exportUtilSQLAnalysisDB, SqlProc ]
{
	QUIT $$exportUtilSQLAnalysisDB^%SYS.PTools2(.file,.format,silent,option,.conds,.ptInfo)
}

/// <p class="info-head">
/// Method:       exportUtilSQLAnalysis [SQL: PT_exportUtilSQLAnalysis]
/// Replaces:     exportSQLUtilities [SQL: PT_exportSQLUtilities]  (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      Create a file containing all the data from joining both the 
///               <class>%SYS.PTools.UtilSQLStatements</class> and <class>%SYS.PTools.UtilSQLAnalysisDB</class> 
///               classes & return the output location...
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.UtilSQLAnalysis).exportUtilSQLAnalysis(...)
///                    SQL: CALL %SYS_PTools.PT_exportUtilSQLAnalysis(...)
///                         SELECT %SYS_PTools.PT_exportUtilSQLAnalysis(...)
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
///               set tSC=##class(%SYS.PTools.UtilSQLAnalysis).exportUtilSQLAnalysis($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYS_PTools.PT_exportUtilSQLAnalysis('$IO','H')
/// 
///               Where: '$IO' = Output to the current device
///                              NOTE: '$IO' can be omitted, as it is the default
///                                    'file' when invoked via the CALL interface
///                       'H'  = Output the format in HTML format
///                              NOTE: 'H' can be omitted, as it is the default
///                                    'format' when invoked via the CALL interface
/// 
/// NOTE:         To query this information via SQL, use the following View:
///                  %SYS_PTools.UtilSQLStmtsAndAnalysisDBView
/// 
///  Parameters:
///   file       - The path and file in which to create and store the data from the 
///                %SYS.PTools.UtilSQLStatements & %SYS.PTools.UtilSQLAnalysisDB classes:  (e.g. C:\exportFile.txt)
///                NOTE:    $IO = Outputs the data to the screen
///                       '$IO' = Output the data to the current device when invoked from the CALL/SELECT-interface
///                      '$DEF' = Ouput the data to the DEFAULT file when invoked from the CALL/SELECT-interface
///                   [DEFAULT: {Current-Directory}\PT_exportUtilSQLAnalysis_YYYYMMDD_HHMMSS.{ext}]
///                      WHERE {Current-Directory} = The directory of the Namespace in which
///                                                  this method is invoked (e.g. $ZU(12,""))
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
///   silent     - 0 - Display all messages during the running of this method
///                1 - Don't display any messages during the running of this method
///   type       - A single type, or a comma-delimited list of {Type} values to
///                restrict the output of rows from the <class>%SYS.PTools.UtilSQLStatements</class>
///                class. The {Type} is the location within InterSystems IRIS from where
///                the SQL Query was extracted:
///                   {Type} values: { cached query | Class Method | Class Query | Routine }
///   option     - A single option, or a comma-delimited list of {OptionName} values
///                to restrict the output of rows from the <class>%SYS.PTools.UtilSQLAnalysisDB</class>
///                class.  The {OptionName} specifies the Index Usage Analysis method
///                used to collect the data:
///                   {OptionName} values: { IU - getAllIndices & indexUsage | 
///                                          TS - tableScans | TI - tempIndices | 
///                                          JI - joinIndices | OI - outlierIndices }
/// 
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
///   includeSQL - 0 = Don't include the SQL Text in the output as the last field
///                1 = Include the SQL Text in the output as the last field [DEFAULT]
///   ptInfo     - A Pass By Reference information array that returns to the user 
///                the following details:
///                   ptInfo(variable)=value
///                   ptInfo("outputFile")=The canonical name of the Export/Reporting file
///    
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod exportUtilSQLAnalysis(file As %String = "", format As %String = "", silent As %Integer = 0, type As %String = "", option As %String = "", ByRef conds As %RawString, includeSQL As %Integer = 1, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_exportUtilSQLAnalysis, SqlProc ]
{
	QUIT $$exportUtilSQLAnalysis^%SYS.PTools2(.file,.format,silent,type,option,.conds,includeSQL,.ptInfo)
}

/// <p class="section-head">
/// <b>                 E X P O R T I N G   /   R E P O R T I N G                 </b>
///                     -----------------------------------------
///  The following Exporting/Reporting methods allow for the exporting & reporting 
///  of SQL Statements and accompanying SQL Index Usage Analytical data generated 
///  from the invocation of one of the following SQL Index Analyzer methods:
/// 
///     SQL Index Analyzer             Exporting/Reporting
///     ==================             ====================
///     - <method>indexUsage</method>                   - <method>exportIUAnalysis</method>
///     - <method>tableScans</method>                   - <method>exportTSAnalysis</method>
///     - <method>tempIndices</method>                  - <method>exportTIAnalysis</method>
///     - <method>joinIndices</method>                  - <method>exportJIAnalysis</method>
///     - <method>outlierIndices</method>               - <method>exportOIAnalysis</method>
/// 
///  NOTE: The data from the aforementioned methods are stored in the following
///        classes/tables, and output the data from each method's corresponding
///        Query with the same name:
///           - <class>%SYS.PTools.UtilSQLStatements</class>
///           - <class>%SYS.PTools.UtilSQLAnalysisDB</class>
/// </p>
/// 
/// <p class="info-head">
/// Method:       exportIUAnalysis [SQL: PT_exportIUAnalysis]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Create a file containing all the data from joining both the 
///               <class>%SYS.PTools.UtilSQLStatements</class> and <class>%SYS.PTools.UtilSQLAnalysisDB</class> 
///               classes & return the output location...
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.UtilSQLAnalysis).exportIUAnalysis(...)
///                    SQL: CALL %SYS_PTools.PT_exportIUAnalysis(...)
///                         SELECT %SYS_PTools.PT_exportIUAnalysis(...)
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
///               set tSC=##class(%SYS.PTools.UtilSQLAnalysis).exportIUAnalysis($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYS_PTools.PT_exportIUAnalysis('$IO','H')
/// 
///               Where: '$IO' = Output to the current device
///                              NOTE: '$IO' can be omitted, as it is the default
///                                    'file' when invoked via the CALL interface
///                       'H'  = Output the format in HTML format
///                              NOTE: 'H' can be omitted, as it is the default
///                                    'format' when invoked via the CALL interface
/// 
/// NOTE:         To query this information via SQL, use the following View:
///                  %SYS_PTools.UtilSQLAnalysis_indexUsage()
/// 
///  Parameters:
///   file       - The path and file in which to create and store the data from the 
///                %SYS.PTools.UtilSQLStatements & %SYS.PTools.UtilSQLAnalysisDB classes:  (e.g. C:\exportFile.txt)
///                NOTE:    $IO = Outputs the data to the screen
///                       '$IO' = Output the data to the current device when invoked from the CALL/SELECT-interface
///                      '$DEF' = Ouput the data to the DEFAULT file when invoked from the CALL/SELECT-interface
///                   [DEFAULT: {Current-Directory}\PT_exportIUAnalysis_YYYYMMDD_HHMMSS.{ext}]
///                      WHERE {Current-Directory} = The directory of the Namespace in which
///                                                  this method is invoked (e.g. $ZU(12,""))
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
///   silent     - 0 - Display all messages during the running of this method
///                1 - Don't display any messages during the running of this method
///   p4         - Placeholder Parameter for 'export*Analysis()' method conformity
///   orderBy    - A single <order-by> field, or a comma-delimited list of <order-by>
///                fields in the format: field#[a|d][,field#[a|d],...,field#[a|d]]
///                   field#   field Name
///                   ------   -------------
///                     0      NO <order by clause>
///                     1      SchemaName
///                     2      TableName
///                     3      IndexName
///                     4      UsageCount                             [DEFAULT: 4d,1,2,3]
/// 
///                   EXAMPLE:
///                      4d,1,2a => ORDER BY UsageCount DESC,SchemaName,TableName ASC
/// 
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
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod exportIUAnalysis(file As %String = "", format As %String = "", silent As %Integer = 0, p4 As %String = "", orderBy As %String = "", ByRef conds As %RawString, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_exportIUAnalysis, SqlProc ]
{
	QUIT $$exportIUAnalysis^%SYS.PTools2(.file,.format,silent,p4,orderBy,.conds,.ptInfo)
}

/// <p class="info-head">
/// Method:       exportTSAnalysis [SQL: PT_exportTSAnalysis]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Create a file containing all the data from joining both the 
///               <class>%SYS.PTools.UtilSQLStatements</class> and <class>%SYS.PTools.UtilSQLAnalysisDB</class> 
///               classes & return the output location...
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.UtilSQLAnalysis).exportTSAnalysis(...)
///                    SQL: CALL %SYS_PTools.PT_exportTSAnalysis(...)
///                         SELECT %SYS_PTools.PT_exportTSAnalysis(...)
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
///               set tSC=##class(%SYS.PTools.UtilSQLAnalysis).exportTSAnalysis($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYS_PTools.PT_exportTSAnalysis('$IO','H')
/// 
///               Where: '$IO' = Output to the current device
///                              NOTE: '$IO' can be omitted, as it is the default
///                                    'file' when invoked via the CALL interface
///                       'H'  = Output the format in HTML format
///                              NOTE: 'H' can be omitted, as it is the default
///                                    'format' when invoked via the CALL interface
/// 
/// NOTE:         To query this information via SQL, use the following View:
///                  %SYS_PTools.UtilSQLAnalysis_tableScans()
/// 
///  Parameters:
///   file       - The path and file in which to create and store the data from the 
///                %SYS.PTools.UtilSQLStatements & %SYS.PTools.UtilSQLAnalysisDB classes:  (e.g. C:\exportFile.txt)
///                NOTE:    $IO = Outputs the data to the screen
///                       '$IO' = Output the data to the current device when invoked from the CALL/SELECT-interface
///                      '$DEF' = Ouput the data to the DEFAULT file when invoked from the CALL/SELECT-interface
///                   [DEFAULT: {Current-Directory}\PT_exportTSAnalysis_YYYYMMDD_HHMMSS.{ext}]
///                      WHERE {Current-Directory} = The directory of the Namespace in which
///                                                  this method is invoked (e.g. $ZU(12,""))
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
///   silent     - 0 - Display all messages during the running of this method
///                1 - Don't display any messages during the running of this method
///   type       - A single type, or a comma-delimited list of {Type} values to
///                restrict the output of rows from the <class>%SYS.PTools.UtilSQLStatements</class>
///                class. The {Type} is the location within InterSystems IRIS from where
///                the SQL Query was extracted:
///                   {Type} values: { Cached Query | Class Method | Class Query | Routine }
///   orderBy    - A single <order-by> field, or a comma-delimited list of <order-by>
///                fields in the format: field#[a|d][,field#[a|d],...,field#[a|d]]
///                   field#   field Name
///                   ------   -------------
///                     0      NO <order by clause>
///                     1      SchemaName
///                     2      TableName
///                     3      Name AS QryLocName
///                     4      Type AS QryLocType
///                     5      ModuleName
///                     6      MapType
///                     7      ExtentSize
///                     8      BlockCount                             [DEFAULT: 8d,4,1,2,5,3]
/// 
///                   EXAMPLE:
///                      8d,1,2a => ORDER BY BlockCount DESC,SchemaName,TableName ASC
/// 
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
///   includeSQL - 0 = Don't include the SQL Text in the output as the last field
///                1 = Include the SQL Text in the output as the last field [DEFAULT]
///   ptInfo     - A Pass By Reference information array that returns to the user 
///                the following details:
///                   ptInfo(variable)=value
///                   ptInfo("outputFile")=The canonical name of the Export/Reporting file
///    
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod exportTSAnalysis(file As %String = "", format As %String = "", silent As %Integer = 0, type As %String = "", orderBy As %String = "", ByRef conds As %RawString, includeSQL As %Integer = 1, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_exportTSAnalysis, SqlProc ]
{
	QUIT $$exportTSAnalysis^%SYS.PTools2(.file,.format,silent,type,orderBy,.conds,includeSQL,.ptInfo)
}

/// <p class="info-head">
/// Method:       exportTIAnalysis [SQL: PT_exportTIAnalysis]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Create a file containing all the data from joining both the 
///               <class>%SYS.PTools.UtilSQLStatements</class> and <class>%SYS.PTools.UtilSQLAnalysisDB</class> 
///               classes & return the output location...
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.UtilSQLAnalysis).exportTIAnalysis(...)
///                    SQL: CALL %SYS_PTools.PT_exportTIAnalysis(...)
///                         SELECT %SYS_PTools.PT_exportTIAnalysis(...)
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
///               set tSC=##class(%SYS.PTools.UtilSQLAnalysis).exportTIAnalysis($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYS_PTools.PT_exportTIAnalysis('$IO','H')
/// 
///               Where: '$IO' = Output to the current device
///                              NOTE: '$IO' can be omitted, as it is the default
///                                    'file' when invoked via the CALL interface
///                       'H'  = Output the format in HTML format
///                              NOTE: 'H' can be omitted, as it is the default
///                                    'format' when invoked via the CALL interface
/// 
/// NOTE:         To query this information via SQL, use the following View:
///                  %SYS_PTools.UtilSQLAnalysis_tempIndices()
/// 
///  Parameters:
///   file       - The path and file in which to create and store the data from the 
///                %SYS.PTools.UtilSQLStatements & %SYS.PTools.UtilSQLAnalysisDB classes:  (e.g. C:\exportFile.txt)
///                NOTE:    $IO = Outputs the data to the screen
///                       '$IO' = Output the data to the current device when invoked from the CALL/SELECT-interface
///                      '$DEF' = Ouput the data to the DEFAULT file when invoked from the CALL/SELECT-interface
///                   [DEFAULT: {Current-Directory}\PT_exportTIAnalysis_YYYYMMDD_HHMMSS.{ext}]
///                      WHERE {Current-Directory} = The directory of the Namespace in which
///                                                  this method is invoked (e.g. $ZU(12,""))
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
///   silent     - 0 - Display all messages during the running of this method
///                1 - Don't display any messages during the running of this method
///   type       - A single type, or a comma-delimited list of {Type} values to
///                restrict the output of rows from the <class>%SYS.PTools.UtilSQLStatements</class>
///                class. The {Type} is the location within InterSystems IRIS from where
///                the SQL Query was extracted:
///                   {Type} values: { Cached Query | Class Method | Class Query | Routine }
///   orderBy    - A single <order-by> field, or a comma-delimited list of <order-by>
///                fields in the format: field#[a|d][,field#[a|d],...,field#[a|d]]
///                   field#   field Name
///                   ------   -------------
///                     0      NO <order by clause>
///                     1      SchemaName
///                     2      TableName
///                     3      Name AS QryLocName
///                     4      Type AS QryLocType
///                     5      IndexName
///                     6      IndexFields
///                     7      DataValues
///                     8      ExtentSize
///                     9      BlockCount                             [DEFAULT: 9d,4,1,2,5,3]
/// 
///                   EXAMPLE:
///                      9d,1,2a => ORDER BY BlockCount DESC,SchemaName,TableName ASC
/// 
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
///   includeSQL - 0 = Don't include the SQL Text in the output as the last field
///                1 = Include the SQL Text in the output as the last field [DEFAULT]
///   ptInfo     - A Pass By Reference information array that returns to the user 
///                the following details:
///                   ptInfo(variable)=value
///                   ptInfo("outputFile")=The canonical name of the Export/Reporting file
///    
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod exportTIAnalysis(file As %String = "", format As %String = "", silent As %Integer = 0, type As %String = "", orderBy As %String = "", ByRef conds As %RawString, includeSQL As %Integer = 1, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_exportTIAnalysis, SqlProc ]
{
	QUIT $$exportTIAnalysis^%SYS.PTools2(.file,.format,silent,type,orderBy,.conds,includeSQL,.ptInfo)
}

/// <p class="info-head">
/// Method:       exportJIAnalysis [SQL: PT_exportJIAnalysis]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Create a file containing all the data from joining both the 
///               <class>%SYS.PTools.UtilSQLStatements</class> and <class>%SYS.PTools.UtilSQLAnalysisDB</class> 
///               classes & return the output location...
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.UtilSQLAnalysis).exportJIAnalysis(...)
///                    SQL: CALL %SYS_PTools.PT_exportJIAnalysis(...)
///                         SELECT %SYS_PTools.PT_exportJIAnalysis(...)
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
///               set tSC=##class(%SYS.PTools.UtilSQLAnalysis).exportJIAnalysis($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYS_PTools.PT_exportJIAnalysis('$IO','H')
/// 
///               Where: '$IO' = Output to the current device
///                              NOTE: '$IO' can be omitted, as it is the default
///                                    'file' when invoked via the CALL interface
///                       'H'  = Output the format in HTML format
///                              NOTE: 'H' can be omitted, as it is the default
///                                    'format' when invoked via the CALL interface
/// 
/// NOTE:         To query this information via SQL, use the following View:
///                  %SYS_PTools.UtilSQLAnalysis_joinIndices()
/// 
///  Parameters:
///   file        - The path and file in which to create and store the data from the 
///                 %SYS.PTools.UtilSQLStatements & %SYS.PTools.UtilSQLAnalysisDB classes:  (e.g. C:\exportFile.txt)
///                 NOTE:    $IO = Outputs the data to the screen
///                        '$IO' = Output the data to the current device when invoked from the CALL/SELECT-interface
///                       '$DEF' = Ouput the data to the DEFAULT file when invoked from the CALL/SELECT-interface
///                    [DEFAULT: {Current-Directory}\PT_exportJIAnalysis_YYYYMMDD_HHMMSS.{ext}]
///                       WHERE {Current-Directory} = The directory of the Namespace in which
///                                                   this method is invoked (e.g. $ZU(12,""))
///                 NOTE 2: If Passed By Reference, then 'file' will be returned as the
///                         canonical name of the Export/Reporting file
///   format      - The output format of the Export/Reporting file
///                 This parameter has the following structure of constituent elements:
///                    format=<data-format>[:$LB(<delim>,<csv-header>,<csv-footer>)]
///                 Where the constituent elements have the following values:
///                    <data-format> - The format of the Export/Reporting file:
///                       - P = Printable/Viewable report file (.txt file, no pagination)
///                       - D = Comma-delimited data file (.csv file) which can be read into a spreadsheet
///                       - X = Microsoft Excel XML markup file suitable for import into Excel (.xml file)
///                       - H = HTML page file (.html file)
///                       - Z = User-defined delimiter "P" formatted file (.dlm file)
///                              NOTE: The <delim> element is required or defaulted to $C(9) (TAB)
///                 Optional Elements:
///                    <delim> - User-defined delimiter  [DEFAULT: $C(9) (TAB)]
///                               NOTE: This is generally used for <data-format>="Z"
///                    <csv-header> - .csv file header for <data-format>="D":
///                       - 0 = Don't add non-standard information header to file  [DEFAULT]
///                       - 1 = Add non-standard information header to file
///                    <csv-footer> - .csv file footer for <data-format>="D":
///                       - 0 = Don't add non-standard information footer to file  [DEFAULT]
///                       - 1 = Add non-standard information footer to file
///                 EXAMPLES:
///                    Valid 'format' values:
///                       - "H"             // HTML file
///                       - "D"             // CSV file with No information header or footer
///                       - "D:"_$LB(,1,1)  // CSV file with information header & footer
///                       - "Z:"_$LB("^")   // User-defined delimiter file (delim="^")
///   silent      - 0 - Display all messages during the running of this method
///                 1 - Don't display any messages during the running of this method
///   type        - A single type, or a comma-delimited list of {Type} values to
///                 restrict the output of rows from the <class>%SYS.PTools.UtilSQLStatements</class>
///                 class. The {Type} is the location within InterSystems IRIS from where
///                 the SQL Query was extracted:
///                    {Type} values: { Cached Query | Class Method | Class Query | Routine }
///   orderBy     - A single <order-by> field, or a comma-delimited list of <order-by>
///                 fields in the format: field#[a|d][,field#[a|d],...,field#[a|d]]
///                    field#   field Name
///                    ------   -------------
///                      0      NO <order by clause>
///                      1      SchemaName
///                      2      TableName
///                      3      Name AS QryLocName
///                      4      Type AS QryLocType
///                      5      IndexName
///                      6      JoinFields AS IndexNeeded
///                      7      JoinIndexFlag                          [DEFAULT: 7d,4,1,2,5,6,3,10]
///                      8      ExtentSize
///                      9      BlockCount
///                     10      SQLTextExt AS SQL
/// 
///                    EXAMPLE:
///                       7d,1,2a => ORDER BY JoinIndexFlag DESC,SchemaName,TableName ASC
/// 
///   conds       - A string/array of possible conditions by which to restrict the
///                 output of the Export file, in the following format:
/// 
///                    conds=<full condition>
///                        OR
///                    conds(0)=pos Count (WHERE pos = {1...n})
///                    conds(pos)=$LIST() Pieces:
///                                  1) [<logical operator>]  (Assumed Default: &&)
///                                  2) [{Heading}]           (Omit for override cond)
///                                  3) <simple condition> | <complex condition>
/// 
///                    WHERE:
///                       <full condition>       := <full condition expression>
///                       <logical operator>     := {&& | ||}  (&& = AND | || = OR)
///                       <simple condition>@*   := <oper><value expression>
///                       <complex condition>@   := <complex condition expression>
/// 
///                      @ = Contains no references to {Heading}
///                      * = Contains no references to {*}
/// 
///                    EXAMPLE:
///                       <full condition>
///                          conds="("",INFO,MAIN,""[("",""_{Module}_"",""))||({GlobalRefs}>20)"
///                       <simple condition>
///                          conds(0)=3
///                          conds(1)=$LB(,"Module","=""INFO""")
///                          conds(2)=$LB("||","Module","=""MAIN""")
///                          conds(3)=$LB("||","GlobalRefs",">20")
///                       <complex condition>
///                          conds(0)=2
///                          conds(1)=$LB(,"Module",""",INFO,MAIN,""[("",""_{*}_"","")")
///                          conds(2)=$LB("||","GlobalRefs","{*}>20")
///                             WHERE: {*} = value substitution for the 'Module' & 'GlobalRefs' fields
///                             NOTE: Conditions that don't contain any references to
///                                   {Heading} fields, often called <override condition>s,
///                                   can be included as <complex condition>s, as in
///                                   the following example:
///                                      conds(pos)=$LB(,,"$g(^zAction(""runIt""))=1") 
/// 
///                    NOTE: All conditions must be satisfied for the conds() to
///                          be considered true and for the row to be exported
///                    [PASS BY REFERENCE]
///   includeSQL  - 0 = Don't include the SQL Text in the output as the last field
///                 1 = Include the SQL Text in the output as the last field [DEFAULT]
///   skipJIF4    - 0 - Export all rows regardless of the 'JoinIndexFlag' value
///                 1 - Export all rows where the value of the 'JoinIndexFlag' is not 4 [DEFAULT]
///   indxFlgInfo - The specific information that should be returned for
///                 the 'JoinIndexFlag' field:
///                    0 = The Index-Flag Internal Value   [DEFAULT]
///                    1 = The Index-Flag Title
///                    2 = The Index-Flag Definition
///                    3 = The Index-Flag as 'Title: Definition'
///   ptInfo      - A Pass By Reference information array that returns to the user 
///                 the following details:
///                    ptInfo(variable)=value
///                    ptInfo("outputFile")=The canonical name of the Export/Reporting file
///    
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod exportJIAnalysis(file As %String = "", format As %String = "", silent As %Integer = 0, type As %String = "", orderBy As %String = "", ByRef conds As %RawString, includeSQL As %Integer = 1, skipJIF4 As %Integer = 1, indxFlgInfo As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_exportJIAnalysis, SqlProc ]
{
	QUIT $$exportJIAnalysis^%SYS.PTools2(.file,.format,silent,type,orderBy,.conds,includeSQL,skipJIF4,indxFlgInfo,.ptInfo)
}

/// <p class="info-head">
/// Method:       exportOIAnalysis [SQL: PT_exportOIAnalysis]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Create a file containing all the data from joining both the 
///               <class>%SYS.PTools.UtilSQLStatements</class> and <class>%SYS.PTools.UtilSQLAnalysisDB</class> 
///               classes & return the output location...
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.UtilSQLAnalysis).exportOIAnalysis(...)
///                    SQL: CALL %SYS_PTools.PT_exportOIAnalysis(...)
///                         SELECT %SYS_PTools.PT_exportOIAnalysis(...)
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
///               set tSC=##class(%SYS.PTools.UtilSQLAnalysis).exportOIAnalysis($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYS_PTools.PT_exportOIAnalysis('$IO','H')
/// 
///               Where: '$IO' = Output to the current device
///                              NOTE: '$IO' can be omitted, as it is the default
///                                    'file' when invoked via the CALL interface
///                       'H'  = Output the format in HTML format
///                              NOTE: 'H' can be omitted, as it is the default
///                                    'format' when invoked via the CALL interface
/// 
/// NOTE:         To query this information via SQL, use the following View:
///                  %SYS_PTools.UtilSQLAnalysis_outlierIndices()
/// 
///  Parameters:
///   file        - The path and file in which to create and store the data from the 
///                 %SYS.PTools.UtilSQLStatements & %SYS.PTools.UtilSQLAnalysisDB classes:  (e.g. C:\exportFile.txt)
///                 NOTE:    $IO = Outputs the data to the screen
///                        '$IO' = Output the data to the current device when invoked from the CALL/SELECT-interface
///                       '$DEF' = Ouput the data to the DEFAULT file when invoked from the CALL/SELECT-interface
///                    [DEFAULT: {Current-Directory}\PT_exportOIAnalysis_YYYYMMDD_HHMMSS.{ext}]
///                       WHERE {Current-Directory} = The directory of the Namespace in which
///                                                   this method is invoked (e.g. $ZU(12,""))
///                 NOTE 2: If Passed By Reference, then 'file' will be returned as the
///                         canonical name of the Export/Reporting file
///   format      - The output format of the Export/Reporting file
///                 This parameter has the following structure of constituent elements:
///                    format=<data-format>[:$LB(<delim>,<csv-header>,<csv-footer>)]
///                 Where the constituent elements have the following values:
///                    <data-format> - The format of the Export/Reporting file:
///                       - P = Printable/Viewable report file (.txt file, no pagination)
///                       - D = Comma-delimited data file (.csv file) which can be read into a spreadsheet
///                       - X = Microsoft Excel XML markup file suitable for import into Excel (.xml file)
///                       - H = HTML page file (.html file)
///                       - Z = User-defined delimiter "P" formatted file (.dlm file)
///                              NOTE: The <delim> element is required or defaulted to $C(9) (TAB)
///                 Optional Elements:
///                    <delim> - User-defined delimiter  [DEFAULT: $C(9) (TAB)]
///                               NOTE: This is generally used for <data-format>="Z"
///                    <csv-header> - .csv file header for <data-format>="D":
///                       - 0 = Don't add non-standard information header to file  [DEFAULT]
///                       - 1 = Add non-standard information header to file
///                    <csv-footer> - .csv file footer for <data-format>="D":
///                       - 0 = Don't add non-standard information footer to file  [DEFAULT]
///                       - 1 = Add non-standard information footer to file
///                 EXAMPLES:
///                    Valid 'format' values:
///                       - "H"             // HTML file
///                       - "D"             // CSV file with No information header or footer
///                       - "D:"_$LB(,1,1)  // CSV file with information header & footer
///                       - "Z:"_$LB("^")   // User-defined delimiter file (delim="^")
///   silent      - 0 - Display all messages during the running of this method
///                 1 - Don't display any messages during the running of this method
///   type        - A single type, or a comma-delimited list of {Type} values to
///                 restrict the output of rows from the <class>%SYS.PTools.UtilSQLStatements</class>
///                 class. The {Type} is the location within InterSystems IRIS from where
///                 the SQL Query was extracted:
///                    {Type} values: { Cached Query | Class Method | Class Query | Routine }
///   orderBy     - A single <order-by> field, or a comma-delimited list of <order-by>
///                 fields in the format: field#[a|d][,field#[a|d],...,field#[a|d]]
///                    field#   field Name
///                    ------   -------------
///                      0      NO <order by clause>
///                      1      SchemaName
///                      2      TableName
///                      3      Name AS QryLocName
///                      4      Type AS QryLocType
///                      5      IndexName
///                      6      IndexFields
///                      7      BiasQueriesAsOutlier AS BiasOutlier
///                      8      OutlierIndexFlag                       [DEFAULT: 8d,4,1,2,5,6,3,9]
///                      9      OutlierField
///                     10      OutlierValue AS OutlierCond
///                     11      OutlierSelectivity AS OutlierSel
///                     12      OutlierWhereCondition
///                     13      ExtentSize
///                     14      BlockCount
/// 
///                    EXAMPLE:
///                       8d,1,2a => ORDER BY OutlierIndexFlag DESC,SchemaName,TableName ASC
/// 
///   conds       - A string/array of possible conditions by which to restrict the
///                 output of the Export file, in the following format:
/// 
///                    conds=<full condition>
///                        OR
///                    conds(0)=pos Count (WHERE pos = {1...n})
///                    conds(pos)=$LIST() Pieces:
///                                  1) [<logical operator>]  (Assumed Default: &&)
///                                  2) [{Heading}]           (Omit for override cond)
///                                  3) <simple condition> | <complex condition>
/// 
///                    WHERE:
///                       <full condition>       := <full condition expression>
///                       <logical operator>     := {&& | ||}  (&& = AND | || = OR)
///                       <simple condition>@*   := <oper><value expression>
///                       <complex condition>@   := <complex condition expression>
/// 
///                      @ = Contains no references to {Heading}
///                      * = Contains no references to {*}
/// 
///                    EXAMPLE:
///                       <full condition>
///                          conds="("",INFO,MAIN,""[("",""_{Module}_"",""))||({GlobalRefs}>20)"
///                       <simple condition>
///                          conds(0)=3
///                          conds(1)=$LB(,"Module","=""INFO""")
///                          conds(2)=$LB("||","Module","=""MAIN""")
///                          conds(3)=$LB("||","GlobalRefs",">20")
///                       <complex condition>
///                          conds(0)=2
///                          conds(1)=$LB(,"Module",""",INFO,MAIN,""[("",""_{*}_"","")")
///                          conds(2)=$LB("||","GlobalRefs","{*}>20")
///                             WHERE: {*} = value substitution for the 'Module' & 'GlobalRefs' fields
///                             NOTE: Conditions that don't contain any references to
///                                   {Heading} fields, often called <override condition>s,
///                                   can be included as <complex condition>s, as in
///                                   the following example:
///                                      conds(pos)=$LB(,,"$g(^zAction(""runIt""))=1") 
/// 
///                    NOTE: All conditions must be satisfied for the conds() to
///                          be considered true and for the row to be exported
///                    [PASS BY REFERENCE]
///   includeSQL  - 0 = Don't include the SQL Text in the output as the last field
///                 1 = Include the SQL Text in the output as the last field [DEFAULT]
///   skipOIF4    - 0 - Export all rows regardless of the 'OutlierIndexFlag' value
///                 1 - Export all rows where the value of the 'OutlierIndexFlag' is not 4 [DEFAULT]
///   indxFlgInfo - The specific information that should be returned for
///                 the 'OutlierIndexFlag' field:
///                    0 = The Index-Flag Internal Value   [DEFAULT]
///                    1 = The Index-Flag Title
///                    2 = The Index-Flag Definition
///                    3 = The Index-Flag as 'Title: Definition'
///   ptInfo      - A Pass By Reference information array that returns to the user 
///                 the following details:
///                    ptInfo(variable)=value
///                    ptInfo("outputFile")=The canonical name of the Export/Reporting file
///    
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod exportOIAnalysis(file As %String = "", format As %String = "", silent As %Integer = 0, type As %String = "", orderBy As %String = "", ByRef conds As %RawString, includeSQL As %Integer = 1, skipOIF4 As %Integer = 1, indxFlgInfo As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_exportOIAnalysis, SqlProc ]
{
	QUIT $$exportOIAnalysis^%SYS.PTools2(.file,.format,silent,type,orderBy,.conds,includeSQL,skipOIF4,indxFlgInfo,.ptInfo)
}

/// <p class="info-head">
/// Query:        countSQLStmtTypes
/// Replaces:     FindSQL (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      Class Query to return the SQL Statement Types and the number of 
///               Statements collected for each Query Types.
/// 
/// Example:      The following example show the locations (QueryType) from which 
///               the SQL Statements were collected from the invocation of the 
///               'getSQLStmts()' methods:
///                  - Cached Queries
///                  - Class Methods
///                  - Class Queries
///                  - MAC Routines
/// 
///                  SELECT * FROM %SYS_PTools.UtilSQLAnalysis_countSQLStmtTypes()
/// </p>
Query countSQLStmtTypes() As %SQLQuery(ROWSPEC = "QueryType:%String,QueryCount:%Integer")
{
	SELECT %EXACT(Type), Count(*) 
    FROM %SYS_PTools.UtilSQLStatements
    GROUP BY Type
}

/// <p class="info-head">
/// Query/View:   UtilSQLStmtsAndAnalysisDBView
/// Replaces:     SQLUtilStmtsAndResultsView (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Query/View to replicate Backward-Compatible Query/View it 
///               'Replaces'
/// Purpose:      Class View which returns all of the SQL Statements information 
///               stored in both the '%SYS.PTools.UtilSQLStatements' 
///               and '%SYS.PTools.UtilSQLAnalysisDB' classes/tables
/// </p>
Query UtilSQLStmtsAndAnalysisDBView() As %SQLQuery(CONTAINID = 1) [ SqlView, SqlViewName = UtilSQLStmtsAndAnalysisDBView ]
{
	SELECT USS.ID AS Stmt_ID, USS.Type, USS.Name, USS.MethodName, USS.ImportPackage,
	       USA.ID AS Result_ID, USA.OptionName, USA.Counter,
	       USA.SchemaName, USA.TableName, USA.ModuleName, USA.MapType, USA.ExtentSize, USA.BlockCount,
	       USA.IndexName, USA.UsageCount, $LISTTOSTRING(USA.IndexFields,',') AS IndexFields, $LISTTOSTRING(USA.DataValues,',') AS DataValues, 
	       USA.JoinIndexFlag, $LISTTOSTRING(USA.JoinFields,',') As JoinFields, 
	       USA.OutlierField, USA.BiasQueriesAsOutlier, USA.OutlierSelectivity, NVL(USA.OutlierValue,'NULL') AS OutlierValue, USA.OutlierIndexFlag, $LISTTOSTRING(USA.OutlierCondFields,',') AS OutlierCondFields, 
	       USA.WhereOperator, USA.WhereValue, USA.WhereCondition,
	       USS.SQLTextExt
	FROM %SYS_PTools.UtilSQLStatements AS USS JOIN %SYS_PTools.UtilSQLAnalysisDB AS USA ON USS.ID = USA.SQLPointer
}

/// <p class="info-head">
/// Method:       version [SQL: UtilSQLAnalysis_version]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Get the current version for the <class>%SYS.PTools.UtilSQLStatements</class> &
///               <class>%SYS.PTools.UtilSQLAnalysisDB</class> classes/sections of the 
///               Performance Tools (PTools) Application...
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.UtilSQLAnalysis).version(...)
///                    SQL: SELECT %SYS_PTools.UtilSQLAnalysis_version(...)
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Display the UtilSQLAnalysis version to the screen via an 
///               InterSystems IRIS Terminal:
/// 
///               write ##class(%SYS.PTools.UtilSQLAnalysis).version()   // Simple Version
///               write ##class(%SYS.PTools.UtilSQLAnalysis).version(1)  // Full Version
/// 
///    #2         Display the UtilSQLAnalysis version via the SQL Query Page of the
///               Management Portal:
/// 
///               SELECT %SYS_PTools.UtilSQLAnalysis_version()   /* Simple Version */
///               SELECT %SYS_PTools.UtilSQLAnalysis_version(1)  /* Full Version */
/// 
/// Data Storage: N/A
/// 
/// Parameters:
///    fullVer      - 0 = Display the UtilSQLAnalysis Simple Version  [DEFAULT]
///                   1 = Display the UtilSQLAnalysis Full Version
///    
/// RETURN Value: The UtilSQLAnalysis {Simple | Full} Version
/// </p>
ClassMethod version(fullVer = 0) As %String [ SqlName = UtilSQLAnalysis_version, SqlProc ]
{
	QUIT $s(fullVer:$$$UtilSQLAnlsysFullVersion,1:$$$UtilSQLAnlsysVersion)		//MRP878|MRP963|MRP1073 - First Implementation of Versioning/Updated
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
