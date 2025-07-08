/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sqlcode, %SYS.PTools.Stats)

/// <style type="text/css"> 
///    DEP { color: red; font-weight: bold; }
///    BC { color: green; font-weight: bold; }
///    .dep-head { color: red; white-space: pre; font-family:  'Courier New'; }
///    .info-head { white-space: pre; font-family: 'Courier New'; }
/// </style>
/// 
/// <p class="dep-head">
/// <b> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </b>
/// 
/// Starting with ver '2.0' of the PTools application, this class is considered
/// to be DEPRECATED and is replaced by the <class>%SYS.PTools.UtilSQLStatements</class> class.
/// 
/// <b> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </b>
/// </p>
/// 
/// <p class="info-head">
/// Class:        %SYS.PTools.SQLUtilities
/// Replaced By:  <class>%SYS.PTools.UtilSQLStatements</class>
/// Purpose:      
///    This class stores the SQL Statement details collected from the following 
///    locations by invoking the 'GetSQLStatements()' method:
///       - Cached Queries
///       - Class Methods
///       - Class Queries
///       - MAC Routines
/// 
///    Data Storage:  ^%sqlcq($NAMESPACE,"PTools","Utils","Queries","{C|D|I|S}")
///    Error Storage: ^%sqlcq($NAMESPACE,"PTools","Error"[...])=$LIST Info
/// ------------------------------------------------------------------------------
/// </p>
Class %SYS.PTools.SQLUtilities Extends %Persistent [ CompileAfter = %SYS.PTools.SQLUtilResults, Deprecated, System = 4 ]
{

Property Type As %String;

Property Name As %String;

/// comma delimited list of Package names to use compiling queries
Property ImportPackage As %String;

Property SQLText As %Stream.GlobalCharacter;

/// <p class="info-head">
/// Method:       SQLTextLogicalToDisplay
/// Replaced By:  N/A
/// Status:       New Functionality
/// Purpose:      Converts the value of the parameter '%val', which represents 
///               the 'SQLText' property in logical format (%Stream.GlobalCharacter), 
///               into a string value (%Library.String) and return that string.
/// 
/// Examples:     The following examples show how to return the 'SQLText'
///               property in different formats:
/// 
///    #1         Show 'SQLText' as a Stream ID:
/// 
///               SELECT ID, %EXACT(Type) AS QueryType, %Internal(SQLText) 
///               FROM %SYS_PTools.SQLUtilities 
/// 
///    #2         Show 'SQLText' as a String via the 'Execute Query' interface of
///               the 'Management Portal':
/// 
///               SELECT ID, %EXACT(Type) AS QueryType, SQLText
///               FROM %SYS_PTools.SQLUtilities 
/// 
///    #3         Show 'SQLText' as a String via Embedded SQL:
/// 
///               #SQLCompile Select=Display
///               &sql(DECLARE sqlCUR CURSOR FOR
///                    SELECT ID, %EXACT(Type) AS QueryType, SQLText
///                    FROM %SYS_PTools.SQLUtilities
///                   )
/// 
/// Parameters:
///    %val      - The value of the 'SQLText' property in logical format 
///                (%Stream.GlobalCharacter)
///    
/// RETURN Value: The SQL Statement Text in (%Library.String) format; Otherwise, 
///               return an error message if an error occurred
/// </p>
ClassMethod SQLTextLogicalToDisplay(%val As %String) As %String [ ServerOnly = 0 ]
{
	QUIT ..streamAsText(%val)
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       IndexUsage [SQL: IndexUsage]
/// Replaced By:  indexUsage [SQL: PT_indexUsage] (<class>%SYS.PTools.UtilSQLAnalysis</class>)
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// Purpose:      This method uses the SQL Statement data stored in the 
///               '%SYS.PTools.SQLUtilities' class to generate a ShowPlan for each
///               query, and to keeps a count of how many times each index is used 
///               by each query.  This index usage count is subsequently stored
///               in the 'UsageCount' field of the <class>%SYS.PTools.SQLUtilResults</class> 
///               class, which can be used to find and remove unneeded indices
///               in addition to being used for other analytical purposes...  
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLUtilities).IndexUsage(...)
///                    SQL: CALL %SYS_PTools.IndexUsage(...)
///                         SELECT %SYS_PTools.IndexUsage(...)
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
///               FROM %SYS_PTools.SQLUtilities 
///               GROUP BY Type
///         OR
///               SELECT * FROM %SYS_PTools.SQLUtilities_FindSQL()
/// 
///    #2         Show the data collected from the running of this method:
/// 
///               SELECT * FROM %SYS_PTools.SQLUtilities_IndexUsage()
/// 
///               NOTE: These queries can be invoked from a number of tools,
///                     such as the SQL Query tool in the 'Management Portal'
///                     or via 'SQL Query Shell' within a 'InterSystems IRIS Terminal' as
///                     shown below:
///                        >do $SYSTEM.SQL.Shell()
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","Utils","Queries","{C|D|I|S}")
/// 
/// Parameters:
///    PopTable      - 1 = Get all the SQL Statements from InterSystems IRIS locations 
///                        (Cached Queries, Class Methods, Class Queries, MAC Routines)
///                        and add them to the '%SYS.PTools.SQLUtilities' class for 
///                        additional processing of this method
///                           [DEFAULT: 0*]
///                              * - If '%SYS.PTools.SQLUtilities' contains NO data,
///                                  then DEFAULT 'PopTable' to 1 because this method
///                                  requires SQL Statement data for processing!
///    SystemTables  - 0 = Skip all System Objects (Classes & Routines) that 
///                        start with: { % | DeepSee | Ens | HS | INFORMATION{.|_}SCHEMA }
///                    1 = Get/Process all System Objects (Classes & Routines) that
///                        start with: { % | DeepSee | Ens | HS | INFORMATION{.|_}SCHEMA }
///                    2 = Skip all System Objects that are not defined in the
///                        namespace in which this method is invoked
///                    3 = Skip all System Objects defined by InterSystems, even if
///                        the object is also defined in the namespace in which this
///                        method is invoked
///                    NOTE-1: Pass the combination of the specified options if more
///                            than one option desired (e.g. 30 => #3 & #0)
///                    NOTE-2: This only applies when retrieving SQL Indices (getIndices=1)
///                            and/or SQL Statements (PopTable=1)
///                            [DEFAULT: 0]
///    IgnoreEns     - ???
///    IgnoreIDKeys  - 1 = Skip all the index that will be used to form the Object Identity 
///                        value (IDKEY) for the given class
///                        NOTE: This only applies when retrieving SQL Indices (getIndices=1)
///                           [DEFAULT: 1]
///    Display       - 1 = Display messages while processing method
///                           [DEFAULT: 1]
///    getIndices    - 1 = Get all the SQL Indexes from the Class Methods in this
///                        Namespace and add them to the '%SYS.PTools.SQLUtilResults'
///                        class for additional processing of this method
///                           [DEFAULT: 0*]
///                              * - If '%SYS.PTools.SQLUtilResults' contains NO 
///                                  Index Usage (IU) data, then DEFAULT 'getIndices'
///                                  to 1, even if a 0 is passed in for this paramter,
///                                  because this method requires Index Usage (IU) data
///                                  for processing!
///    skipInsStmts  - 1 = Skip INSERT Statements, as they don't have looping logic
///                           [DEFAULT: 1]
///    clearData     - 1 = Kill all of the existing data before re-populating
///                        with the results of this method invocation
///                           [DEFAULT: 1]
///    ptInfo        - A Pass By Reference information array that returns to the user 
///                    the following details:
///                       ptInfo("update-cnt")=The number of rows in the <class>%SYS.PTools.SQLUtilResults</class>
///                                            class which were updated with their Index Usage details
///    
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod IndexUsage(PopTable As %Integer = 0, SystemTables As %Integer = 0, IgnoreEns As %Integer = 1, IgnoreIDKeys As %Integer = 1, Display As %Integer = 1, getIndices As %Integer = 0, skipInsStmts As %Integer = 1, clearData As %Integer = 1, ByRef ptInfo As %RawString) As %Status [ Deprecated, SqlName = IndexUsage, SqlProc ]
{
	QUIT $$IndexUsage^%SYS.PToolsDEP(PopTable, SystemTables, IgnoreEns, IgnoreIDKeys, Display, getIndices, skipInsStmts, clearData, .ptInfo)
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Query:        IndexUsage
/// Replaced By:  indexUsage (<class>%SYS.PTools.UtilSQLAnalysis</class>)
/// DETAILS:      For additional details see the 'Replaced By' Class & Query!
/// </p>
Query IndexUsage(schema) As %SQLQuery(ROWSPEC = "SchemaName:%String,TableName:%String,IndexName:%String,Usage Count:%Integer") [ Deprecated ]
{
	SELECT %Exact(SchemaName), %Exact(Tablename), 
	       %Exact(IndexName), UsageCount AS "Usage Count"
	FROM %SYS_PTools.SQLUtilResults 
	WHERE     OptionName = 'IU' 
	      AND (SchemaName = :schema OR :schema IS NULL)
	ORDER BY UsageCount
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       TableScans [SQL: TableScans]
/// Replaced By:  tableScans [SQL: PT_tableScans] (<class>%SYS.PTools.UtilSQLAnalysis</class>)
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// Purpose:      This method uses the SQL Statement data stored in the 
///               '%SYS.PTools.SQLUtilities' class to pinpoint the queries that 
///               perform a table scan, which could be over an index or the master
///               map.  
///               Pertinent information about these queries is subsequently 
///               stored in the the <class>%SYS.PTools.SQLUtilResults</class> class
///               for future processing and analysis. 
///               For some queries a table scan can't be avoided, but any 
///               query that uses such a scan should be reviewed in order to
///               determine if an index could be added for performance 
///               optimizations.
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLUtilities).TableScans(...)
///                    SQL: CALL %SYS_PTools.TableScans(...)
///                         SELECT %SYS_PTools.TableScans(...)
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
///               FROM %SYS_PTools.SQLUtilities 
///               GROUP BY Type
///         OR
///               SELECT * FROM %SYS_PTools.SQLUtilities_FindSQL()
/// 
///    #2         Show the data collected from the running of this method:
/// 
///               SELECT SQLPointer->Type As "Routine Type", 
///                      SQLPointer->Name As "Routine Name", 
///                      SchemaName, TableName, ModuleName, 
///                      ExtentSize,
///                      SQLPointer->SQLText AS "SQL Text"
///               FROM %SYS_PTools.SQLUtilResults 
///               WHERE OptionName = 'TS' 
///               ORDER BY ExtentSize DESC
///         OR
///               SELECT * FROM %SYS_PTools.SQLUtilities_TableScans()
///                  -- This returns "SQL Text" in Logical Format
///         OR
///               SELECT * FROM %SYS_PTools.SQLUtilities_TableScans(,1)
///                  -- This returns "SQL Text" in External Format
///         OR
///               SELECT SchemaName, TableName, Type, "Class/Routine Name",
///                      ModuleName, "Map Type" , ExtentSize, "Block Count",
///                      %SYS_PTools.PT_streamAsText("SQL Text")
///               FROM %SYS_PTools.SQLUtilities_TableScans()
///                  -- This returns "SQL Text" in External Format
/// 
///               NOTE: These queries can be invoked from a number of tools,
///                     such as the SQL Query tool in the 'Management Portal'
///                     or via 'SQL Query Shell' within a 'InterSystems IRIS Terminal' as
///                     shown below:
///                        >do $SYSTEM.SQL.Shell()
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","Utils","Queries","{C|D|I|S}")
/// 
/// Parameters:
///    PopTable      - 1 = Get all the SQL Statements from InterSystems IRIS locations 
///                        (Cached Queries, Class Methods, Class Queries, MAC Routines)
///                        and add them to the '%SYS.PTools.SQLUtilities' class for 
///                        additional processing of this method
///                           [DEFAULT: 1]
///    SystemTables  - 0 = Skip all System Objects (Classes & Routines) that 
///                        start with: { % | DeepSee | Ens | HS | INFORMATION{.|_}SCHEMA }
///                    1 = Get/Process all System Objects (Classes & Routines) that
///                        start with: { % | DeepSee | Ens | HS | INFORMATION{.|_}SCHEMA }
///                    2 = Skip all System Objects that are not defined in the
///                        namespace in which this method is invoked
///                    3 = Skip all System Objects defined by InterSystems, even if
///                        the object is also defined in the namespace in which this
///                        method is invoked
///                    NOTE-1: Pass the combination of the specified options if more
///                            than one option desired (e.g. 30 => #3 & #0)
///                    NOTE-2: This only applies when retrieving SQL Statements (PopTable=1)
///                           [DEFAULT: 0]
///    IgnoreEns     - ???
///    Display       - 1 = Display messages while processing method
///                           [DEFAULT: 1]
///    skipInsStmts  - 1 = Skip INSERT Statements, as they don't have looping logic
///                           [DEFAULT: 1]
///    clearData     - 1 = Kill all of the existing data before re-populating
///                        with the results of this method invocation
///                           [DEFAULT: 1]
///    ptInfo        - A Pass By Reference information array that returns to the user 
///                    the following details:
///                       ptInfo("update-cnt")=The number of rows inserted in the <class>%SYS.PTools.SQLUtilResults</class>
///                                            class for queries that require a full table scan
///    
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod TableScans(PopTable As %Integer = 0, SystemTables As %Integer = 0, IgnoreEns As %Integer = 1, Display As %Integer = 1, skipInsStmts As %Integer = 1, clearData As %Integer = 1, ByRef ptInfo As %RawString) As %Status [ Deprecated, SqlName = TableScans, SqlProc ]
{
	QUIT $$TableScans^%SYS.PToolsDEP(PopTable, SystemTables, IgnoreEns, Display, skipInsStmts, clearData, .ptInfo)
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Query:        TableScans
/// Replaced By:  tableScans (<class>%SYS.PTools.UtilSQLAnalysis</class>)
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// DETAILS:      For additional details see the 'Replaced By' Class & Query!
/// 
///  Parameters:
///    schema      - The schema of the table being queried in the SQL Statement
///                  to match against the 'SchemaName' property/field
///    SQLTextExt  - 0 = Don't convert the 'SQLText' property; just return it as
///                      a stream (%Stream.GlobalCharacter) value
///                  1 = Converts the value of the 'SQLText' property from a logical 
///                      stream (%Stream.GlobalCharacter) format into a string
///                      (%Library.String) format, and return that string
/// </p>
Query TableScans(schema, SQLTextExt As %Integer = 0) As %SQLQuery(ROWSPEC = "SchemaName:%String,TableName:%String,Type:%String,Class/Routine Name:%String,ModuleName:%String,Map Type:%String,ExtentSize:%Integer,Block Count:%Integer,SQL Text:%String") [ Deprecated ]
{
	SELECT %Exact(SchemaName), %Exact(TableName), SQLPointer->Type, SQLPointer->Name, 
	       ModuleName, MapType AS "Map Type", 
	       ExtentSize, BlockCount AS "Block Count", 
	       CASE
	          WHEN :SQLTextExt = 1 THEN %SYS_PTools.PT_streamAsText(SQLPointer->SQLText)
	          ELSE SQLPointer->SQLText
	       END AS "SQL Text"
	FROM %SYS_PTools.SQLUtilResults 
	WHERE     OptionName = 'TS' 
	      AND (SchemaName = :schema OR :schema IS NULL)
	ORDER BY BlockCount DESC
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       TempIndices [SQL: TempIndices]
/// Replaced By:  tempIndices [SQL: PT_tempIndices] (<class>%SYS.PTools.UtilSQLAnalysis</class>)
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// Purpose:      This method uses the SQL Statement data stored in the 
///               '%SYS.PTools.SQLUtilities' class to pinpoint the queries that 
///               are building a Temp Index/Table.  
///               Pertinent information about these queries is subsequently 
///               stored in the the <class>%SYS.PTools.SQLUtilResults</class> class
///               for future processing and analysis. 
///               It's worth noting that the results of this method and that of 
///               the 'TableScans()' method might have a large overlap.
///               For some queries the creation of a Temp Index/Table can be 
///               avoided, but often the creation of a Temp Index/Table is 
///               done so to provide optimal data traversal and retrieval.
///               These queries should be reviewed to determine if an index could 
///               be added to the class for performance optimizations, because 
///               often the structure of the Temp Index/Table is the basis for the 
///               creation of a class index to help with query performance.
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLUtilities).TempIndices(...)
///                    SQL: CALL %SYS_PTools.TempIndices(...)
///                         SELECT %SYS_PTools.TempIndices(...)
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
///               FROM %SYS_PTools.SQLUtilities 
///               GROUP BY Type
///         OR
///               SELECT * FROM %SYS_PTools.SQLUtilities_FindSQL()
/// 
///    #2         Show the data collected from the running of this method:
/// 
///               SELECT SchemaName, TableName, 
///                      $LISTTOSTRING(IndexFields) As "Index Fields", 
///                      $LISTTOSTRING(DataValues) As "Data Fields", 
///                      ExtentSize, BlockCount As "Block Count",
///                      SQLPointer->SQLText AS "SQL Text"
///               FROM %SYS_PTools.SQLUtilResults 
///               WHERE OptionName = 'TI' 
///               ORDER BY ExtentSize DESC
///                  -- This returns "SQL Text" in External Format
///         OR
///               SELECT * FROM %SYS_PTools.SQLUtilities_TempIndices()
///                  -- This returns "SQL Text" in Logical Format
///         OR
///               SELECT * FROM %SYS_PTools.SQLUtilities_TempIndices(,1)
///                  -- This returns "SQL Text" in External Format
///         OR
///               SELECT SchemaName, TableName, Type, "Class/Routine Name",
///                      IndexName, "Index Fields", "Data Fields",
///                      ExtentSize, "Block Count", 
///                      %SYS_PTools.PT_streamAsText("SQL Text")
///               FROM %SYS_PTools.SQLUtilities_TempIndices()
///                  -- This returns "SQL Text" in External Format
/// 
///               NOTE: These queries can be invoked from a number of tools,
///                     such as the SQL Query tool in the 'Management Portal'
///                     or via 'SQL Query Shell' within a 'InterSystems IRIS Terminal' as
///                     shown below:
///                        >do $SYSTEM.SQL.Shell()
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","Utils","Queries","{C|D|I|S}")
/// 
/// Parameters:
///    PopTable      - 1 = Get all the SQL Statements from InterSystems IRIS locations 
///                        (Cached Queries, Class Methods, Class Queries, MAC Routines)
///                        and add them to the '%SYS_PTools.SQLUtilities' class for 
///                        additional processing of this method
///                           [DEFAULT: 1]
///    SystemTables  - 0 = Skip all System Objects (Classes & Routines) that 
///                        start with: { % | DeepSee | Ens | HS | INFORMATION{.|_}SCHEMA }
///                    1 = Get/Process all System Objects (Classes & Routines) that
///                        start with: { % | DeepSee | Ens | HS | INFORMATION{.|_}SCHEMA }
///                    2 = Skip all System Objects that are not defined in the
///                        namespace in which this method is invoked
///                    3 = Skip all System Objects defined by InterSystems, even if
///                        the object is also defined in the namespace in which this
///                        method is invoked
///                    NOTE-1: Pass the combination of the specified options if more
///                            than one option desired (e.g. 30 => #3 & #0)
///                    NOTE-2: This only applies when retrieving SQL Statements (PopTable=1)
///                           [DEFAULT: 0]
///    IgnoreEns     - ???
///    Display       - 1 = Display messages while processing method
///                           [DEFAULT: 1]
///    skipInsStmts  - 1 = Skip INSERT Statements, as they don't have looping logic
///                           [DEFAULT: 1]
///    clearData     - 1 = Kill all of the existing data before re-populating
///                        with the results of this method invocation
///                           [DEFAULT: 1]
///    ptInfo        - A Pass By Reference information array that returns to the user 
///                    the following details:
///                       ptInfo("update-cnt")=The number of rows inserted in the <class>%SYS.PTools.SQLUtilResults</class>
///                                            class for queries that build temporary indices to resolve the SQL
///    
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod TempIndices(PopTable As %Integer = 1, SystemTables As %Integer = 0, IgnoreEns As %Integer = 1, Display As %Integer = 1, skipInsStmts As %Integer = 1, clearData As %Integer = 1, ByRef ptInfo As %RawString) As %Status [ Deprecated, PublicList = SQLCODE, SqlName = TempIndices, SqlProc ]
{
	QUIT $$TempIndices^%SYS.PToolsDEP(PopTable, SystemTables, IgnoreEns, Display, skipInsStmts, clearData, .ptInfo)
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Query:        TempIndices
/// Replaced By:  tempIndices (<class>%SYS.PTools.UtilSQLAnalysis</class>)
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// DETAILS:      For additional details see the 'Replaced By' Class & Query!
/// 
///  Parameters:
///    schema      - The schema of the table being queried in the SQL Statement
///                  to match against the 'SchemaName' property/field
///    SQLTextExt  - 0 = Don't convert the 'SQLText' property; just return it as
///                      a stream (%Stream.GlobalCharacter) value
///                  1 = Converts the value of the 'SQLText' property from a logical 
///                      stream (%Stream.GlobalCharacter) format into a string
///                      (%Library.String) format, and return that string
/// </p>
Query TempIndices(schema, SQLTextExt As %Integer = 0) As %SQLQuery(ROWSPEC = "SchemaName:%String,TableName:%String,Type:%String,Class/Routine Name:%String,IndexName:%String,Index Fields:%String,Data Fields:%String,ExtentSize:%Integer,Block Count:%Integer,SQL Text:%String") [ Deprecated ]
{
	SELECT %Exact(SchemaName), %Exact(TableName), SQLPointer->Type, SQLPointer->Name, 
	        %Exact(IndexName), $LISTTOSTRING(IndexFields) As "Index Fields", $LISTTOSTRING(DataValues) As "Data Fields", 
	        ExtentSize, BlockCount AS "Block Count", 
	       CASE
	          WHEN :SQLTextExt = 1 THEN %SYS_PTools.PT_streamAsText(SQLPointer->SQLText)
	          ELSE SQLPointer->SQLText
	       END AS "SQL Text"
	FROM %SYS_PTools.SQLUtilResults 
	WHERE     OptionName = 'TI' 
	      AND (SchemaName = :schema OR :schema IS NULL)
	ORDER BY BlockCount DESC
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       JoinIndices [SQL: JoinIndices]
/// Replaced By:  joinIndices [SQL: PT_joinIndices] (<class>%SYS.PTools.UtilSQLAnalysis</class>)
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// Purpose:      This method uses the SQL Statement data stored in the 
///               '%SYS.PTools.SQLUtilities' class to pinpoint the queries that 
///               perform a JOIN between tables where their joined-fields use an
///               index that supports the join.  This method will then ranks the 
///               indices available to support the join from 0 (no index present) 
///               to 4 (index fully supports the join).
///               Pertinent information about these queries is subsequently 
///               stored in the the <class>%SYS.PTools.SQLUtilResults</class> class
///               for future processing and analysis. 
///               It's worth noting that OUTER JOINs require an index in one
///               direction, whereas INNER JOINs require an index in both 
///               directions. 
///               The result-set stored in the the <class>%SYS.PTools.SQLUtilResults</class> 
///               class only contains rows that have a 'JoinIndexFlag < 4'. 
///               Rows that have a 'JoinIndexFlag = 4', which means that there
///               exists an index that fully supports the JOIN, are not stored 
///               since they are already fully optimized.
///               The stored queries should be reviewed to determine if an index 
///               could be added to the class to satisfy the highest 'JoinIndexFlag'
///               possible:
/// 
///               The 'JoinIndexFlag' property has the following 4 values:
///                  0 - No index to support the join.
///                         (Some version of the suggested index should be created 
///                          to improve this query's performance)
///                  1 - There is an index to support the join but it does not 
///                      contain all the join fields.
///                         (This will produce poor performance and for that reason 
///                          is rarely used)
///                  2 - There is an index to support the join but it is not an exact 
///                      match - The first index field is not part of the join. 
///                         (This might produce OK performance, but improvements 
///                          should be made)
///                  3 - There is an index to support the join but it is not an exact 
///                      match - The first index field is part of the join but there 
///                      are additional fields in the index)
///                         (This will produce OK performance, but improvements can 
///                          be made)
///                  4 - Index fully supports the join. 
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
///               NOTE: The 'IndexFields' property would be an index we think could 
///                     help improve performance.
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLUtilities).JoinIndices(...)
///                    SQL: CALL %SYS_PTools.JoinIndices(...)
///                         SELECT %SYS_PTools.JoinIndices(...)
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
///               FROM %SYS_PTools.SQLUtilities 
///               GROUP BY Type
///         OR
///               SELECT * FROM %SYS_PTools.SQLUtilities_FindSQL()
/// 
///    #2         Show the data collected from the running of this method:
/// 
///               SELECT SchemaName, TableName, 
///                      $LISTTOSTRING(IndexFields) As "Index Needed", 
///                      JoinIndexFlag As "Join Index Flag",
///                      ExtentSize, BlockCount As "Block Count", 
///                      SQLPointer->SQLText AS "SQL Text"
///               FROM %SYS_PTools.SQLUtilResults 
///               WHERE OptionName = 'JI' 
///               ORDER BY 1,2
///                  -- This returns "SQL Text" in External Format
///         OR
///               SELECT * FROM %SYS_PTools.SQLUtilities_JoinIndices()
///                  -- This returns "SQL Text" in Logical Format
///         OR
///               SELECT * FROM %SYS_PTools.SQLUtilities_JoinIndices(,1)
///                  -- This returns "SQL Text" in External Format
///         OR
///               SELECT SchemaName, TableName, Type, "Class/Routine Name",
///                      IndexName, "Index Needed", "Join Index Flag",
///                      ExtentSize, "Block Count", 
///                      %SYS_PTools.PT_streamAsText("SQL Text")
///               FROM %SYS_PTools.SQLUtilities_JoinIndices()
///                  -- This returns "SQL Text" in External Format
/// 
///    #3         Show joined-based tables with less than optimal indexes 
///               that support the JOIN specified in the query:
/// 
///               SELECT SchemaName, TableName, IndexFields As "Index Needed", 
///                      JoinIndexFlag AS "Join Index Flag", 
///                      COUNT(*) AS "Query Count"
///               FROM %SYS_PTools.SQLUtilResults
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
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","Utils","Queries","{C|D|I|S}")
/// 
/// Parameters:
///    PopTable      - 1 = Get all the SQL Statements from InterSystems IRIS locations 
///                        (Cached Queries, Class Methods, Class Queries, MAC Routines)
///                        and add them to the '%SYS.PTools.SQLUtilities' class for 
///                        additional processing of this method
///                           [DEFAULT: 1]
///    SystemTables  - 0 = Skip all System Objects (Classes & Routines) that 
///                        start with: { % | DeepSee | Ens | HS | INFORMATION{.|_}SCHEMA }
///                    1 = Get/Process all System Objects (Classes & Routines) that
///                        start with: { % | DeepSee | Ens | HS | INFORMATION{.|_}SCHEMA }
///                    2 = Skip all System Objects that are not defined in the
///                        namespace in which this method is invoked
///                    3 = Skip all System Objects defined by InterSystems, even if
///                        the object is also defined in the namespace in which this
///                        method is invoked
///                    NOTE-1: Pass the combination of the specified options if more
///                            than one option desired (e.g. 30 => #3 & #0)
///                    NOTE-2: This only applies when retrieving SQL Statements (PopTable=1)
///                           [DEFAULT: 0]
///    IgnoreEns     - ???
///    Display       - 1 = Display messages while processing method
///                           [DEFAULT: 1]
///    skipInsStmts  - 1 = Skip INSERT Statements, as they don't have looping logic
///                           [DEFAULT: 1]
///    clearData     - 1 = Kill all of the existing data before re-populating
///                        with the results of this method invocation
///                           [DEFAULT: 1]
///    ptInfo        - A Pass By Reference information array that returns to the user 
///                    the following details:
///                       ptInfo("update-cnt")=The number of rows inserted in the <class>%SYS.PTools.SQLUtilResults</class>
///                                            class for queries that have joins indexing issues
///    
/// RETURN Value: The status from the invocation of this method
///    
/// RETURN Value: The number of rows inserted in the <class>%SYS.PTools.SQLUtilResults</class>
///               class for queries that have joins indexing issues; Otherwise, 
///               return an error message if an error occurred
/// </p>
ClassMethod JoinIndices(PopTable As %Integer = 1, SystemTables As %Integer = 0, IgnoreEns As %Integer = 1, Display As %Integer = 1, skipInsStmts As %Integer = 1, clearData As %Integer = 1, ByRef ptInfo As %RawString) As %Status [ Deprecated, PublicList = SQLCODE, SqlName = JoinIndices, SqlProc ]
{
	QUIT $$JoinIndices^%SYS.PToolsDEP(PopTable, SystemTables, IgnoreEns, Display, skipInsStmts, clearData, .ptInfo)
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Query:        JoinIndices
/// Replaced By:  joinIndices (<class>%SYS.PTools.UtilSQLAnalysis</class>)
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// DETAILS:      For additional details see the 'Replaced By' Class & Query!
/// 
///  Parameters:
///    schema      - The schema of the table being queried in the SQL Statement
///                  to match against the 'SchemaName' property/field
///    SQLTextExt  - 0 = Don't convert the 'SQLText' property; just return it as
///                      a stream (%Stream.GlobalCharacter) value
///                  1 = Converts the value of the 'SQLText' property from a logical 
///                      stream (%Stream.GlobalCharacter) format into a string
///                      (%Library.String) format, and return that string
/// </p>
Query JoinIndices(schema, SQLTextExt As %Integer = 0) As %SQLQuery(ROWSPEC = "SchemaName:%String,TableName:%String,Type:%String,Class/Routine Name:%String,IndexName:%String,Index Needed:%String,Join Index Flag:%Integer,ExtentSize:%Integer,Block Count:%Integer,SQL Text:%String") [ Deprecated ]
{
	SELECT %Exact(SchemaName), %Exact(TableName), SQLPointer->Type, SQLPointer->Name,
	       %Exact(IndexName), $LISTTOSTRING(IndexFields) As "Index Needed", 
	       JoinIndexFlag AS "Join Index Flag", 
           ExtentSize, BlockCount AS "Block Count", 
	       CASE
	          WHEN :SQLTextExt = 1 THEN %SYS_PTools.PT_streamAsText(SQLPointer->SQLText)
	          ELSE SQLPointer->SQLText
	       END AS "SQL Text"
	FROM %SYS_PTools.SQLUtilResults AS oq
	WHERE     OptionName = 'JI' 
	      AND (SchemaName = :schema OR :schema IS NULL)
	      AND JoinIndexFlag < 4
	-- MRP907 (DON'T USE): GROUP BY JoinIndexFlag, SchemaName, TableName, IndexFields
	ORDER BY JoinIndexFlag DESC
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       GetSQLStatements
/// Replaced By:  getSQLStmts [SQL: PT_getSQLStmts] (<class>%SYS.PTools.UtilSQLAnalysis</class>)
///               It is recommended that you use one of the following new methods 
///               which replaces the functionality of this method:
/// 
///                  ##class(%SYS.PTools.UtilSQLAnalysis).
/// 
///                     => getSQLStmts(...)                  [Cached Queries|Class Methods|Class Queries|MAC Routines]
///                     => getAllSQLStmts(...)               [Cached Queries|Class Methods|Class Queries|MAC Routines]
/// 
///                     => getAllCachedQrySQLStmts(...)      [Cached Queries]
///                     => getCachedQrySQLStmtsByDays(...)   [Cached Queries]
///                     => getCachedQrySQLStmtsByClass(...)  [Cached Queries]
///                     => getAllClassMethSQLStmts(...)      [Class Methods]
///                     => getClassMethSQLStmtsByClass(...)  [Class Methods]
///                     => getAllClassQrySQLStmts(...)       [Class Queries]
///                     => getClassQrySQLStmtsByClass(...)   [Class Queries]
///                     => getAllRtnQrySQLStmts(...)         [MAC Routines]
///                     => getRtnQrySQLStmtsByRtn(...)       [MAC Routines]
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// Purpose:      This method searches for at all of the SQL Statements in a 
///               namespace from the following locations and adds information
///               about the statements (e.g. Type, Name, SQLText) to the 
///               '%SYS.PTools.SQLUtilities' class for additional processing:
///                  - Cached Queries
///                  - Class Methods
///                  - Class Queries
///                  - MAC Routines
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLUtilities).GetSQLStatements(...)
///                    SQL: CALL %SYS_PTools.GetSQLStatements(...)
///                         SELECT %SYS_PTools.GetSQLStatements(...)
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
///               FROM %SYS_PTools.SQLUtilities 
///               GROUP BY Type
///         OR
///               SELECT * FROM %SYS_PTools.SQLUtilities_FindSQL()
/// 
///    #2         Show the data collected from the running of this method:
/// 
///               SELECT Type, Name, ImportPackage, 
///                      SQLText AS "SQL Text"
///               FROM %SYS_PTools.SQLUtilities
///               ORDER BY Type, Name
///                  -- This returns "SQL Text" in External Format
///         OR
///               SELECT * FROM %SYS_PTools.SQLUtilities_GetSQLStatements()
///                  -- This returns "SQL Text" in Logical Format
///         OR
///               SELECT * FROM %SYS_PTools.SQLUtilities_GetSQLStatements(1)
///                  -- This returns "SQL Text" in External Format
///         OR
///               SELECT Type, "Class/Routine Name", ImportPackage,
///                      %SYS_PTools.PT_streamAsText("SQL Text")
///               FROM %SYS_PTools.SQLUtilities_GetSQLStatements()
///                  -- This returns "SQL Text" in External Format
/// 
///               NOTE: These queries can be invoked from a number of tools,
///                     such as the SQL Query tool in the 'Management Portal'
///                     or via 'SQL Query Shell' within a 'InterSystems IRIS Terminal' as
///                     shown below:
///                        >do $SYSTEM.SQL.Shell()
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","Utils","Queries","{C|D|I|S}")
/// 
/// Parameters:
///    cachedQueries - 1 = Get the SQL Statements from all Cached Queries
///                           [DEFAULT: 1]
///    classQueries  - 1 = Get the SQL Statements from all of the Class Queries
///                           [DEFAULT: 1]
///    classMethods  - 1 = Get the SQL Statements from all of the Class Methods
///                           [DEFAULT: 1]
///    routines      - 1 = Get the Embedded SQL Statements from all of the MAC Routines
///                           [DEFAULT: 1]
///    SystemTables  - 0 = Skip all System Objects (Classes & Routines) that 
///                        start with: { % | DeepSee | Ens | HS | INFORMATION{.|_}SCHEMA }
///                    1 = Get/Process all System Objects (Classes & Routines)
///                    2 = Skip all System Objects that are not defined in the
///                        namespace in which this method is invoked
///                    3 = Skip all System Objects defined by InterSystems, even if
///                        the object is also defined in the namespace in which this
///                        method is invoked
///                    NOTE: Pass the combination of the specified options if more
///                          than one option desired (e.g. 30 => #3 & #0)
///                           [DEFAULT: 0]
///    Display       - 1 = Display messages while processing method
///                           [DEFAULT: 1]
///    skipInsStmts  - 1 = Skip INSERT Statements, as they don't have looping logic
///                           [DEFAULT: 1]
///    clearData     - 1 = Kill all of the existing data before re-populating
///                        with the results of this method invocation
///                           [DEFAULT: 1]
///    returnType    - 0 = Return a %Status code of either $$$OK or $$$ERROR()
///                    1 = Return a $LIST of SQL Statements added to the 
///                        '%SYS.PTools.UtilSQLStatements' class
///                           [DEFAULT: 0]
///    ptInfo        - A Pass By Reference information array that returns to the user 
///                    the following details:
///                       ptInfo("insert-list")=The number of rows inserted in the '%SYS.PTools.UtilSQLStatements'
///                                             class in the following $LIST format
///                                                $LIST() pieces:
///                                                      1) Grand Total of all SQL Query Statements added
///                                                      2) Total of all Cached Query Statements added
///                                                      3) Total of all Class Method Statements added
///                                                      4) Total of all Class Query Statements added
///                                                      5) Total of all Routine Statements added
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the number of SQL Statements added to the '%SYS.PTools.UtilSQLStatements'
///               class in the following $LIST format; Otherwise, return an error 
///               message if an error occurred.
/// </p>
ClassMethod GetSQLStatements(cachedQueries As %Integer = 1, classQueries As %Integer = 1, classMethods As %Integer = 1, routines As %Integer = 1, SystemTables As %Integer = 0, Display As %Integer = 1, skipInsStmts As %Integer = 1, clearData As %Integer = 1, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ Deprecated, PublicList = SQLCODE, ReturnResultsets, SqlName = GetSQLStatements, SqlProc ]
{
	QUIT $$GetSQLStatements^%SYS.PToolsDEP(cachedQueries, classQueries, classMethods, routines, SystemTables, Display, skipInsStmts, clearData, returnType, .ptInfo)
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Query:        GetSQLStatements
/// Replaced By:  getSQLStmts (<class>%SYS.PTools.UtilSQLAnalysis</class>)
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// DETAILS:      For additional details see the 'Replaced By' Class & Query!
/// 
///  Parameters:
///    SQLTextExt  - 0 = Don't convert the 'SQLText' property; just return it as
///                      a stream (%Stream.GlobalCharacter) value
///                  1 = Converts the value of the 'SQLText' property from a logical 
///                      stream (%Stream.GlobalCharacter) format into a string
///                      (%Library.String) format, and return that string
/// </p>
Query GetSQLStatements(SQLTextExt As %Integer = 0) As %SQLQuery(ROWSPEC = "Type:%String,Class/Routine Name:%String,ImportPackage:%String,SQL Text:%String") [ Deprecated ]
{
	SELECT Type, Name, ImportPackage, 
	       CASE
	          WHEN :SQLTextExt = 1 THEN %SYS_PTools.PT_streamAsText(SQLText)
	          ELSE SQLText
	       END AS "SQL Text"
	FROM %SYS_PTools.SQLUtilities
	ORDER BY Type, Name
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       clearSQLUtilStmts [SQL: PT_clearSQLUtilStmts]
/// Replaces:     ClearStatements [SQL: ClearStatements] (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Functionality
/// Purpose:      Delete all of the data stored in the '%SYS.PTools.SQLUtilities'
///               class, based on the specified parameters...
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLUtilities).clearSQLUtilStmts(...)
///                           SQL: CALL %SYS_PTools.clearSQLUtilStmts(...)
///                                SELECT %SYS_PTools.clearSQLUtilStmts(...)
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
///               set status=##class(%SYS.PTools.SQLUtilities).clearSQLUtilStmts()
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","Utils","Queries","{C|D|I|S}")
/// 
///  Parameters:
///   ns          - The namespace in which to clear SQL Index/Analysis Statstics
///                    [DEFAULT: Current Namespace]
///   clearErrs   - 0 = Don't delete the 'PTools' Application Errors
///                 1 = Delete all of the 'PTools' Application Errors
///                    [DEFAULT: 0]
///   returnType  - 0 = Return a %Status code of either $$$OK or $$$ERROR()
///                 1 = Return the number of Stats rows deleted from the 
///                     following class: %SYS.PTools.SQLUtilities
///                    [DEFAULT: 0]
///   ptInfo      - A Pass By Reference information array that returns
///                 detailed information to the user in the following format:
///                    ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                 Where category = { "cnt" | "curr" | "term" | ... }
///                       variable = A var corresponding to the given 'category'
/// 
///                 Example:
///                    ptInfo("cnt","clearSQLUtilStmts")=The number of rows deleted
///                                                      via this method [Routine Method]
///                    ptInfo("cnt","ClearStatements")=The number of rows deleted
///                                                    via this method   [Class Method]
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the number of Stats rows deleted from the following class; 
///               Otherwise, return an error message if an error occurred:
///                  %SYS.PTools.SQLUtilities
/// </p>
ClassMethod clearSQLUtilStmts(ns As %String = "", clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ Deprecated, SqlName = PT_clearSQLUtilStmts, SqlProc ]
{
	QUIT $$clearSQLUtilStmts^%SYS.PToolsDEP(ns,clearErrs,returnType,.ptInfo)
}

/// Backward-compatible Entry Point:
///    NOTE: See the <method>clearSQLUtilStmts</method> method above for more details.
ClassMethod ClearStatements(ns As %String = "", clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = ClearStatements, SqlProc ]
{
	QUIT $$clearSQLUtilStmts^%SYS.PToolsDEP(ns,clearErrs,returnType,.ptInfo)
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       clearSQLUtilStmtResults [SQL: PT_clearSQLUtilStmtResults]
/// Replaces:     ClearResults [SQL: ClearResults (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Functionality
/// Purpose:      Delete all of the data stored in the <class>%SYS.PTools.SQLUtilResults</class>
///               class, based on the specified parameters...
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLUtilities).clearSQLUtilStmtResults(...)
///                           SQL: CALL %SYS_PTools.clearSQLUtilStmtResults(...)
///                                SELECT %SYS_PTools.clearSQLUtilStmtResults(...)
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
///               set status=##class(%SYS.PTools.SQLUtilities).clearSQLUtilStmtResults()
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","Utils","Results","{C|D|I|S}")
/// 
///  Parameters:
///   ns          - The namespace in which to clear SQL Index/Analysis Statstics
///                    [DEFAULT: Current Namespace]
///   clearErrs   - 0 = Don't delete the 'PTools' Application Errors
///                 1 = Delete all of the 'PTools' Application Errors
///                    [DEFAULT: 0]
///   returnType  - 0 = Return a %Status code of either $$$OK or $$$ERROR()
///                 1 = Return the number of Stats rows deleted from the 
///                     following class: %SYS.PTools.SQLUtilResults
///                    [DEFAULT: 0]
///   ptInfo      - A Pass By Reference information array that returns
///                 detailed information to the user in the following format:
///                    ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                 Where category = { "cnt" | "curr" | "term" | ... }
///                       variable = A var corresponding to the given 'category'
/// 
///                 Example:
///                    ptInfo("cnt","clearSQLUtilStmtResults")=The number of rows deleted 
///                                                            via this method [Routine Method]
///                    ptInfo("cnt","ClearResults")=The number of rows deleted
///                                                 via this method            [Class Method]
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the number of Stats rows deleted from the following class; 
///               Otherwise, return an error message if an error occurred:
///                  %SYS.PTools.SQLUtilResults
/// </p>
ClassMethod clearSQLUtilStmtResults(ns As %String = "", clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ Deprecated, SqlName = PT_clearSQLUtilStmtResults, SqlProc ]
{
	QUIT $$clearSQLUtilStmtResults^%SYS.PToolsDEP(ns,clearErrs,returnType,.ptInfo)
}

/// Backward-compatible Entry Point:
///    NOTE: See the <method>clearSQLUtilStmtResults</method> method above for more details.
ClassMethod ClearResults(ns As %String = "", clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = ClearResults, SqlProc ]
{
	QUIT $$clearSQLUtilStmtResults^%SYS.PToolsDEP(ns,clearErrs,returnType,.ptInfo)
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       PossiblePlans
/// Replaced By:  possiblePlans (<class>%SYS.PTools.StatsSQL</class>)
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// DETAILS:      For additional details see the 'Replaced By' Class & Method!
/// </p>
ClassMethod PossiblePlans(sql, PPcost = 0, num = 0, level = 0, arr, showstats = 0, packages, schemapath = "", preparse = 0, hash = "", silent = 0) [ Deprecated, ProcedureBlock = 0 ]
{
	n dasl,data,dcost,dint,dmac,dmt,dsql,err,Hval,mtc,i,j,inclist,mcurs,mtag,ppsql,str,%substk,%SYSTEMINCLUDE
	if schemapath'="" new %sqlSchemaPath set %sqlSchemaPath=schemapath
	
	if silent&&'$g(backgrnd) {
		new backgrnd set backgrnd=1
		if $g(wrtref)="" new showErr,wrtref set wrtref="showErr"
	}
		
	if preparse {
		try {
			set ppsql=$$preparse^%qaqpreparser(.sql,1)
			kill sql
			set sql=1,sql(1)=$lg(ppsql,1)	// sql is now the preparsed version of the statement
		}
		catch {
			write:'silent !,"Unexpected Error:  ",$ze
			set:$g(wrtref)'="" @wrtref@($s($g(@wrtref@(0))&&'$d(@wrtref@(@wrtref@(0),"error")):@wrtref@(0),1:$i(@wrtref@(0))),"error")=$LB($ZE,$ZN,"PossiblePlans","Unexpected Error:  <<<1>>>")
			set ok=0
		}
	}
	try { 
		n %msg,ok,SQLCODE s ok=1
		d comp^%qaqqt("query",.sql,"info","",0,"","%qsc(%qscacn",,,$g(packages))
	}
	catch { 
		if $g(err)="qaqperr",$g(SQLCODE) { 
			write:'silent !,"SQLCODE = ",SQLCODE," ",$$sqlcode(SQLCODE),".  ",!,$g(%msg)
			set:$g(wrtref)'="" @wrtref@($s($g(@wrtref@(0))&&'$d(@wrtref@(@wrtref@(0),"error")):@wrtref@(0),1:$i(@wrtref@(0))),"error")=$LB($ZE,$ZN,"PossiblePlans","",SQLCODE,$$sqlcode(SQLCODE),$g(%msg))
		}
		else { 
			write:'silent !,"Unexpected Error:  ",$ze
			set:$g(wrtref)'="" @wrtref@($s($g(@wrtref@(0))&&'$d(@wrtref@(@wrtref@(0),"error")):@wrtref@(0),1:$i(@wrtref@(0))),"error")=$LB($ZE,$ZN,"PossiblePlans","Unexpected Error:  <<<1>>>")
		}
		set ok=0
	}
	QUIT:'ok
	s i="" 
	For  {
		s i=$o(mtc(0,0,"table",i),1,data)
		q:i=""  
		s data=$p(data,$c(1),4)	// data is now the extentname
		i data'="" {
			s j="" For  Set j=$o(^oddCOM(data,36,j)) Quit:j=""  Set inclist(j)=""
		}
	}
	i $d(inclist) s i="" f  s i=$o(inclist(i)) q:i=""  s dmac($i(dmac))="#INCLUDE "_i
	if $g(packages)'="" f i=1:1:$ll(packages) s dmac($i(dmac))="#import "_$lg(packages,i)
	if schemapath'="" s dmac($i(dmac))="#sqlcompile path="_$listtostring(schemapath)
	f i=1:1:$g(sql) s dmac($i(dmac))=$s(i=1:" &sql(",1:" ")_$g(sql(i))
	s dmac($i(dmac))=" )"	// DPV3472 - put closing ")" on line by itself in case SQL satemet ends with comment
	d LINES^%qarmac("dmac","dint",,,,,,,,,,,,,,,,,"ShowPlan4")  ;  run the compiler and collect data
	k %plan s %plan=0
	d:$g(dsql) nliz^%qaqplan(.dsql,.dasl,.dmt,dcost,showstats)  ;  analyze asl/mt
	s str=$LB("")
	s Hval=1,Hval(1)=$LB("")
	s hash=$$Hash^%SYS.SQLSRV(str,.%plan,.Hval)
	i '$g(arr) f %plan=1:1:%plan w !,%plan(%plan)  ;  output results
	QUIT
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Query:        PossiblePlans [SQL: PossiblePlans] 
/// Replaced By:  possiblePlans [SQL: PT_possiblePlans] (<class>%SYS.PTools.StatsSQL</class>)
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// DETAILS:      For additional details see the 'Replaced By' Class & Query!
/// </p>
Query PossiblePlans(sql As %String) As %Query(ROWSPEC = "ID:%Integer,Cost:%Integer,MapType:%String(MAXLEN=15),StartingMap:%String(MAXLEN=30),Plan:%String(MAXLEN=15)") [ Deprecated, SqlName = PossiblePlans, SqlProc ]
{
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       PossiblePlansExecute
/// Replaced By:  possiblePlansExecute (<class>%SYS.PTools.StatsSQL</class>)
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// DETAILS:      For additional details see the 'Replaced By' Class & Method!
/// </p>
ClassMethod PossiblePlansExecute(ByRef qHandle As %Binary, sql As %String) As %Status [ Deprecated, PublicList = (backgrnd, showErr, wrtref) ]
{
	new backgrnd,showErr,wrtref
	i sql'=+sql s sql(1)=sql,sql=1
	;m sql=^mqh($USERNAME)
	
	set backgrnd=1,wrtref="showErr"	// Record any SQL errors in the 'showErr' array
	do ShowPlanAlt^%apiSQL(.sql,1,,,,,,,1)
	do:$d(@wrtref)>1 ##class(%SQL.Manager.ShowPlan).ShowPlanSQLError(.@wrtref)	// Display SQL Errors with proper formatting!

	s qHandle=0
	Quit $$$OK
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       PossiblePlansFetch
/// Replaced By:  possiblePlansFetch (<class>%SYS.PTools.StatsSQL</class>)
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// DETAILS:      For additional details see the 'Replaced By' Class & Method!
/// </p>
ClassMethod PossiblePlansFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Deprecated, PlaceAfter = PossiblePlansExecute ]
{
	s qHandle=$O(%AltPlan(qHandle))
	If qHandle="" s AtEnd=1,Row="" QUIT $$$OK
	s cost=$FN($LG(%AltPlan(qHandle,0),1),"N",1)
	s map=$LG($LG(%AltPlan(qHandle,0),3),2)
	s type=$LG($LG(%AltPlan(qHandle,0),3),1)
	s Row=$LB(qHandle,cost,map,type,"Plan")
	Quit $$$OK
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       PossiblePlansClose
/// Replaced By:  possiblePlansClose (<class>%SYS.PTools.StatsSQL</class>)
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// DETAILS:      For additional details see the 'Replaced By' Class & Method!
/// </p>
ClassMethod PossiblePlansClose(ByRef qHandle As %Binary) As %Status [ Deprecated, PlaceAfter = PossiblePlansFetch ]
{
	k %AltPlan
	Quit $$$OK
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Query:        PossiblePlansStats [SQL: PossiblePlansStats]
/// Replaced By:  possiblePlansStats [SQL: PT_possiblePlansStats] (<class>%SYS.PTools.StatsSQL</class>)
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// DETAILS:      For additional details see the 'Replaced By' Class & Query!
/// </p>
Query PossiblePlansStats(sql As %String, ids As %String) As %Query(ROWSPEC = "ID:%Integer,Cost:%Integer,StartingMap:%String,GlobalRef:%Integer,Commands:%Integer,TotalTime:%Integer,RowsReturned:%Integer,Plan:%String") [ Deprecated, SqlName = PossiblePlansStats, SqlProc ]
{
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       PossiblePlansStatsExecute
/// Replaced By:  possiblePlansStatsExecute (<class>%SYS.PTools.StatsSQL</class>)
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// DETAILS:      For additional details see the 'Replaced By' Class & Method!
/// </p>
ClassMethod PossiblePlansStatsExecute(ByRef qHandle As %Binary, sql As %String, ids As %String) As %Status [ Deprecated, PublicList = (backgrnd, showErr, wrtref) ]
{
	new backgrnd,showErr,wrtref
	i sql'=+sql s sql(1)=sql,sql=1
	;m sql=^mqh($USERNAME,"stats",1)
	;s ids=^mqh($USERNAME,"stats",2)
	s idlist=""
	f i=1:1:$L(ids,",") s:$p(ids,",",i)'="" idlist=idlist_","_$P(ids,",",i)
	s idlist=$e(idlist,2,*)

	set backgrnd=1,wrtref="showErr"	// Record any SQL errors in the 'showErr' array
	do ShowPlanAlt^%apiSQL(.sql,1,,1,,,0,idlist,1)
	do:$d(@wrtref)>1 ##class(%SQL.Manager.ShowPlan).ShowPlanSQLError(.@wrtref)	// Display SQL Errors with proper formatting!

	s qHandle=0
	Quit $$$OK
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       PossiblePlansStatsFetch
/// Replaced By:  possiblePlansStatsFetch (<class>%SYS.PTools.StatsSQL</class>)
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// DETAILS:      For additional details see the 'Replaced By' Class & Method!
/// </p>
ClassMethod PossiblePlansStatsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Deprecated, PlaceAfter = PossiblePlansExecute ]
{
	s qHandle=$O(%AltPlan(qHandle))
	If qHandle="" s AtEnd=1,Row="" QUIT $$$OK
	s line=1
	f  {
		s line=$O(%AltPlan(qHandle,line),1,data)
		QUIT:line=""
		CONTINUE:data'="<stats>"
		
		FOR {
			set line=$o(%AltPlan(qHandle,line),1,data)
			QUIT:(data="</stats>")||(data="")	// End of Statistics Info!
			
			set:data["<TimeSpent" time=$p($p(data,">",2),"<",1)
			set:data["<GlobalRefs" globals=$p($p(data,">",2),"<",1)
			set:data["<LinesOfCode" commands=$p($p(data,">",2),"<",1)
			set:data["<CommandsExecuted" commands=$p($p(data,">",2),"<",1)
			set:data["<RowCount" rows=$p($p(data,">",2),"<",1)
		}
		
		QUIT
	}
	s cost=$FN($LG(%AltPlan(qHandle,0),1),"N",1)
	s map=$LG($LG(%AltPlan(qHandle,0),3),1)
	s Row=$LB(qHandle,cost,map,globals,commands,time,rows,"Plan")
	Quit $$$OK
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       PossiblePlansStatsClose
/// Replaced By:  possiblePlansStatsClose (<class>%SYS.PTools.StatsSQL</class>)
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// DETAILS:      For additional details see the 'Replaced By' Class & Method!
/// </p>
ClassMethod PossiblePlansStatsClose(ByRef qHandle As %Binary) As %Status [ Deprecated, PlaceAfter = PossiblePlansStatsFetch ]
{
	k %AltPlan
	Quit $$$OK
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       ChangeCost
/// Replaced By:  changeCost (<class>%SYS.PTools.StatsSQL</class>)
/// Purpose:      * INTERNAL USE ONLY *
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// DETAILS:      For additional details see the 'Replaced By' Class & Method!
/// </p>
ClassMethod ChangeCost(PPcost, num, level, dmt, dmts, dalg) [ Deprecated ]
{
	; if this is the first time in we need to loop over the %mcost array to get the different cost values

	; %mcost(qoqn,qojsn,numstream,streams,order,outtype,i) = solution
	try {
		if $g(num)=0 {
			k ^||PPcost
			m ^||PPcost("data",1)=%mcost(1)
			d ..BuildPPcost(1, .dmt, .dmts, .dalg, .cost)
			m ^||PPcost("cost")=cost
		}	; if
		; any other time in we modify the %mcost array to change the plan
		i num'=0 {
			s data=$g(^||PPcost("cost",level,PPcost,num))
			; to change the plan set all the sixth level to ""
			f i=0:1:2 s %mcost($LG(data,1),$LG(data,2),$LG(data,3),$LG(data,4),$LG(data,5),i)=""
			; then only set the one sixth level you want to the plan you want
			s %mcost($LG(data,1),$LG(data,2),$LG(data,3),$LG(data,4),$LG(data,5),$LG(data,6))=$LG(data,7)
		}
	}	;try
	
	catch {
		w !,"Error:  ",$ze
	}
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       BuildPPcost
/// Replaced By:  buildPPcost (<class>%SYS.PTools.StatsSQL</class>)
/// Purpose:      * INTERNAL USE ONLY *
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// DETAILS:      For additional details see the 'Replaced By' Class & Method!
/// </p>
ClassMethod BuildPPcost(qoqn, dmt, dmts, dalg, PPcost) [ Internal, PublicList = ptfjoo ]
{
 Try {	
	QUIT:qoqn=""
	s qojsn=""
	f  {
		s qojsn=$O(%mcost(qoqn,qojsn))		; always 1 yes!
		QUIT:qojsn=""
		s numstream=$O(%mcost(qoqn,qojsn,""),-1)			; this is the tables involved? don't loop $O(,-1)
		s streams=$O(%mcost(qoqn,qojsn,numstream,""))	; list of tables handled at this level
		s order=$S(ptfjoo(qoqn)'="":ptfjoo(qoqn),1:0)	; use 0 unless the query has an ORDER BY
		s outtype=""
		f  {
			s outtype=$O(%mcost(qoqn,qojsn,numstream,streams,order,outtype))	; 0, 1, or 2
			QUIT:outtype=""
			s i=""
			f  {
				s i=$O(%mcost(qoqn,qojsn,numstream,streams,order,outtype,i),1,data)	; loop over all the solutions for this output type
				QUIT:i=""
				s counter=$i(PPcost(numstream))
				s cost=$P($P(data,"^",1),",",1)
				s qosn=$P(data,"^",2)
				
				s PPcost(numstream,cost,counter)=$LB(qoqn,qojsn,numstream,streams,order,outtype,i)
				s parent=$P(data,"^",3)
				i qoqn=1 {								; need to go back up the tree to get the starting table
					f  {
						QUIT:parent=""					; we know we are at the top of the tree when parent is NULL
						s s1=$P(parent,":",1)
						s s2=$P(parent,":",2)
						s s3=$P(parent,":",3)
						s s4=$P(parent,":",4)
						s s5=$P(parent,":",5)
						s s6=$P(parent,":",6)
						s s7=$P(parent,":",7)
						s data=%mcost(s1,s2,s3,s4,s5,s6,s7),qosn=$P(data,"^",2),stnum=s2
						s parent=$P(%mcost(s1,s2,s3,s4,s5,s6,s7),"^",3)
					}
					s PPcost(numstream,cost,counter,"map")=..map(data,.dmt,.dmts,.dalg,qoqn,qosn)
				}
			} 	; i
		}	; outtype			
	}	; qojsn
 }
 	catch {
		w !,"Error:  ",$ze
	}
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       map
/// Replaced By:  map (<class>%SYS.PTools.StatsSQL</class>)
/// Purpose:      * INTERNAL USE ONLY *
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// DETAILS:      For additional details see the 'Replaced By' Class & Method!
/// </p>
ClassMethod map(data, mt, mts, alg, qnum, str) [ Deprecated ]
{
	if $g(mt("r",str,"q"))'="" {
		if $D(mt("union"))=0
		{
			; This is a view figure out the starting map
			s vqnum=mt("r",str,"q")
			; sort the %mcost array for the view
			d ..BuildPPcost(vqnum, .mt, .mts, .alg, .cost)
			s vqnum=$O(cost(""))
			s qcost=$O(cost(vqnum,""))
			s qcounter=$O(cost(vqnum,qcost,""),1,costdata)
			s qdata=%mcost($LG(costdata,1),$LG(costdata,2),$LG(costdata,3),$LG(costdata,4),$LG(costdata,5),$LG(costdata,6),$LG(costdata,7))
			s algnum=$P(qdata,"^",4)
			s imp=$P(alg(algnum),"^",12)
			s qstr=$P(qdata,"^",2)
			s irn=$P(mt("r",qstr),"^",1)
			s TableName=$$$smdSchema(1,irn)_"."_$$$smdName(1,irn)
	}
		else  {
			; this is a UNION OR optimization, not a real view.

			s vqnum=4 ;$O(mt("union",""))
			d ..BuildPPcost(vqnum, .mt, .mts, .alg, .cost)
			s vqnum=$O(cost(""))
			s qcost=$O(cost(vqnum,""))
			s qcounter=$O(cost(vqnum,qcost,""),1,costdata)
			s qdata=%mcost($LG(costdata,1),$LG(costdata,2),$LG(costdata,3),$LG(costdata,4),$LG(costdata,5),$LG(costdata,6),$LG(costdata,7))
			s algnum=$P(qdata,"^",4)
			s imp=$P(alg(algnum),"^",12)
			s qstr=$P(qdata,"^",2)
			s irn=$P(mt("r",qstr),"^",1)
			s TableName=$$$smdSchema(1,irn)_"."_$$$smdName(1,irn)

		}
	}
	ELSE {
		; this is a table, get the name and the map
		s algnum=$P(data,"^",4)
		s imp=$P(alg(algnum),"^",12)
		s irn=$P(mt("r",str),"^",1)
		s TableName=$$$smdSchema(1,irn)_"."_$$$smdName(1,irn)
	}
	If TableName="." QUIT $LB("Union Or Optimization","Not supported")
	If imp="" QUIT $LB(TableName, "Multi Index")
    ;  identify map:  master/index map "s.t.m"  *** check for virtual map!  JLF015
	i $d(mt("filterm",imp),filter) QUIT $LB(TableName_".%ID ",$s($e(filter,1,6)="%INBIT":"bitmap ",1:"")_"filter ")
	s smdimp=$s($d(mt("smdimp",imp)):mt("smdimp",imp),1:imp)
	i $$$smdG(12,+smdimp)="" QUIT $LB(TableName_"."_"?","?")
	s it=$$$smdMapIndexType(smdimp)
	s node=$s($$$smdMapMaster(smdimp)="Y":"master map ",it="BE":"extent bitmap ",it="B":"bitmap index ",1:"index map ")
	if node = "master map " {
		s idifn=$P(mts(qnum,str),"^",5)
		s idcon=$D(mts(qnum,str,"CON",idifn))				; is there a condition on the ID field
		s inherited=($p($g(mts(qnum,str,"MAP",imp),1),"^",5)=0) ;  it must be inherited
		i 'idcon&(inherited) {
			; see if there is a bitmap extent that will get used
			s ebm=$$$smdBitmapExtentMap(1,irn)
			if $d(mts(qnum,str,"MAP",+ebm))  s smdimp=ebm,node="extent bitmap"
		}

	}
	; QUIT $LB(Schema_"."_Table_"."_Map, MapType)
	QUIT $LB(TableName_"."_$$$smdMapName(smdimp), node)
}

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Query:        FindSQL
/// Replaced By:  countSQLStmtTypes (<class>%SYS.PTools.UtilSQLAnalysis</class>)
/// Status:       <BC>Maintained for Backward-Compatibility</BC>
/// Purpose:      Class Query to return the SQL Statement Types and the number of 
///               Statements collected for each Query Types.
/// 
/// Example:      The following example show the locations (QueryType) from which 
///               the SQL Statements were collected from the invocation of the 
///               'GetSQLStatements()' methods:
///                  - Cached Queries
///                  - Class Methods
///                  - Class Queries
///                  - MAC Routines
/// 
///                  SELECT * FROM %SYS_PTools.SQLUtilities_FindSQL()
/// </p>
Query FindSQL() As %SQLQuery(ROWSPEC = "QueryType:%String,QueryCount:%Integer") [ Deprecated ]
{
	SELECT %EXACT(Type), Count(*) 
    FROM %SYS_PTools.SQLUtilities 
    GROUP BY Type
}

/// <p class="info-head">
/// Method:       streamAsText [SQL: PT_streamAsText]
/// Replaced By:  N/A
/// Status:       New Functionality
/// Purpose:      This method is passed a valid Stream ID based on the
///               %Stream.GlobalCharacter datatype and returns the stream
///               text as a single String line (e.g. a SQL Statement)
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLUtilities).streamAsText({streamID})
///                    SQL: SELECT %SYS_PTools.PT_streamAsText({streamID})
///               Where {streamID} is a valid Stream ID
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Show all SQL Statements in this class:
/// 
///               SELECT ID, %EXACT(Type) AS QueryType, 
///                      %SYS_PTools.PT_streamAsText(SQLText) AS SQLText
///               FROM %SYS_PTools.SQLUtilities 
/// 
/// Parameters:
///    streamID   - A valid Stream ID based on the %Stream.GlobalCharacter datatype
///    
/// RETURN Value: The SQL Statement Text for the given 'streamID'; Otherwise, 
///               return an error message if an error occurred
/// </p>
ClassMethod streamAsText(streamID = "") As %String [ Deprecated, SqlName = PT_streamAsText, SqlProc ]
{
 set SQLText=""
 
 RETURN:'$LISTVALID(streamID) SQLText
 
 try {
	set strmRef=##class(%Stream.GlobalCharacter).%Open(streamID)
	
	While strmRef.AtEnd=0 { 
		set line=strmRef.Read() 
		set SQLText=SQLText_line
	}
 }
 catch ExStream {
	set status= ExStream.AsStatus()
    THROW ExStream
 }
 QUIT SQLText
}

/// <p class="info-head">
/// Method:       exportSQLUtilStmts [SQL: PT_exportSQLUtilStmts]
/// Replaced By:  exportUtilSQLStatements [SQL: PT_exportUtilSQLStatements]  (<class>%SYS.PTools.UtilSQLAnalysis</class>)
/// Status:       New Functionality
/// Purpose:      Create a file containing all the data from the 
///               <class>%SYS.PTools.SQLUtilities</class> class & return the output 
///               location...
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLUtilities).exportSQLUtilStmts(...)
///                    SQL: CALL %SYS_PTools.PT_exportSQLUtilStmts(...)
///                         SELECT %SYS_PTools.PT_exportSQLUtilStmts(...)
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
///               set tSC=##class(%SYS.PTools.SQLUtilities).exportSQLUtilStmts($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYS_PTools.PT_exportSQLUtilStmts('$IO','H')
/// 
///               Where: '$IO' = Output to the current device
///                              NOTE: '$IO' can be omitted, as it is the default
///                                    'file' when invoked via the CALL interface
///                       'H'  = Output the format in HTML format
///                              NOTE: 'H' can be omitted, as it is the default
///                                    'format' when invoked via the CALL interface
/// 
/// NOTE:         This method has been added to this DEPRECATED class to correspond
///               with the newly created 'export' method defined for the new &
///               improved interface in the '%SYS.PTools.UtilSQLAnalysis' class
/// 
///  Parameters:
///   file      - The path and file in which to create and store the data from the
///               %SYS.PTools.SQLUtilities class:  (e.g. C:\exportFile.txt) 
///               NOTE:    $IO = Outputs the data to the screen
///                      '$IO' = Output the data to the current device when invoked from the CALL/SELECT-interface
///                     '$DEF' = Ouput the data to the DEFAULT file when invoked from the CALL/SELECT-interface
///                  [DEFAULT: {Current-Directory}\PT_exportSQLUtilStmts_YYYYMMDD_HHMMSS.{ext}]
///                      WHERE {Current-Directory} = The directory of the Namespace in which
///                                                  this method is invoked (e.g. $ZU(12,""))
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
///                restrict the output of rows from the <class>%SYS.PTools.SQLUtilities</class>
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
ClassMethod exportSQLUtilStmts(file As %String = "", format As %String = "", silent As %Integer = 0, type As %String = "", ByRef conds As %RawString, ByRef ptInfo As %RawString) As %Status [ Deprecated, SqlName = PT_exportSQLUtilStmts, SqlProc ]
{
	QUIT $$exportSQLUtilStmts^%SYS.PToolsDEP(.file,.format,silent,type,.conds,.ptInfo)
}

/// <p class="info-head">
/// Method:       exportSQLUtilities [SQL: PT_exportSQLUtilities]
/// Replaced By:  exportUtilSQLAnalysis [SQL: PT_exportUtilSQLAnalysis]  (<class>%SYS.PTools.UtilSQLAnalysis</class>)
/// Status:       New Functionality
/// Purpose:      Create a file containing all the data from joining both the 
///               <class>%SYS.PTools.SQLUtilities</class> and <class>%SYS.PTools.SQLUtilResults</class> 
///               classes & return the output location...
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLUtilities).exportSQLUtilities(...)
///                    SQL: CALL %SYS_PTools.PT_exportSQLUtilities(...)
///                         SELECT %SYS_PTools.PT_exportSQLUtilities(...)
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
///               set tSC=##class(%SYS.PTools.SQLUtilities).exportSQLUtilities($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYS_PTools.PT_exportSQLUtilities('$IO','H')
/// 
///               Where: '$IO' = Output to the current device
///                              NOTE: '$IO' can be omitted, as it is the default
///                                    'file' when invoked via the CALL interface
///                       'H'  = Output the format in HTML format
///                              NOTE: 'H' can be omitted, as it is the default
///                                    'format' when invoked via the CALL interface
/// 
/// NOTE:         This method has been added to this DEPRECATED class to correspond
///               with the newly created 'export' method defined for the new &
///               improved interface in the '%SYS.PTools.UtilSQLAnalysis' class
/// 
///  Parameters:
///   file       - The path and file in which to create and store the data from the
///                %SYS.PTools.SQLUtilities & %SYS.PTools.SQLUtilResults classes:  (e.g. C:\exportFile.txt)
///                NOTE:    $IO = Outputs the data to the screen
///                       '$IO' = Output the data to the current device when invoked from the CALL/SELECT-interface
///                      '$DEF' = Ouput the data to the DEFAULT file when invoked from the CALL/SELECT-interface
///                   [DEFAULT: {Current-Directory}\PT_exportSQLUtilities_YYYYMMDD_HHMMSS.{ext}]
///                       WHERE {Current-Directory} = The directory of the Namespace in which
///                                                   this method is invoked (e.g. $ZU(12,""))
///                NOTE 2: If Passed By Reference, then 'file' will be returned as the
///                        canonical name of the Export/Reporting file
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
///   silent     - 0 - Display all messages during the running of this method
///                1 - Don't display any messages during the running of this method
///   type       - A single type, or a comma-delimited list of {Type} values to
///                restrict the output of rows from the <class>%SYS.PTools.SQLUtilities</class>
///                class. The {Type} is the location within InterSystems IRIS from where
///                the SQL Query was extracted:
///                   {Type} values: { cached query | Class Method | Class Query | Routine }
///   option     - A single option, or a comma-delimited list of {OptionName} values
///                to restrict the output of rows from the <class>%SYS.PTools.SQLUtilResults</class>
///                class.  The {OptionName} specifies the Index Usage Analysis method
///                used to collect the data:
///                   {OptionName} values: { IU - IndexUsage & AllIndices | 
///                                          TS - TableScans | TI - TempIndices | 
///                                          JI - JoinIndices }
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
///   includeSQL - 1 = Include the SQL Text in the output as the last field
///                   [DEFAULT: 1]
///   ptInfo     - A Pass By Reference information array that returns to the user 
///                the following details:
///                   ptInfo(variable)=value
///                   ptInfo("outputFile")=The canonical name of the Export/Reporting file
///    
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod exportSQLUtilities(file As %String = "", format As %String = "", silent As %Integer = 0, type As %String = "", option As %String = "", ByRef conds As %RawString, includeSQL As %Integer = 1, ByRef ptInfo As %RawString) As %Status [ Deprecated, SqlName = PT_exportSQLUtilities, SqlProc ]
{
	QUIT $$exportSQLUtilities^%SYS.PToolsDEP(.file,.format,silent,type,option,.conds,includeSQL,.ptInfo)
}

/// <p class="info-head">
/// Query/View:   SQLUtilStmtsAndResultsView
/// Replaced By:  UtilSQLStmtsAndAnalysisDBView (<class>%SYS.PTools.UtilSQLAnalysis</class>)
/// Purpose:      
/// </p>
Query SQLUtilStmtsAndResultsView() As %SQLQuery(CONTAINID = 1) [ SqlView, SqlViewName = SQLUtilStmtsAndResultsView ]
{
	SELECT SUS.ID AS Stmt_ID, SUS.Type, SUS.Name, '' AS MethodName, SUS.ImportPackage,
           SUR.ID AS Result_ID, SUR.OptionName, SUR.Counter,
           SUR.SchemaName, SUR.TableName, SUR.ModuleName, SUR.MapType, SUR.ExtentSize, SUR.BlockCount,
           SUR.IndexName, SUR.UsageCount, $LISTTOSTRING(SUR.IndexFields,',') AS IndexFields, $LISTTOSTRING(SUR.DataValues,',') AS DataValues,
           SUR.JoinIndexFlag, '' As JoinFields,
           SUS.SQLText AS SQLTextExt
	FROM %SYS_PTools.SQLUtilities AS SUS JOIN %SYS_PTools.SQLUtilResults AS SUR ON SUS.ID = SUR.SQLPointer
}

/// Provide the current version for the SQLUtilities class/section of the Performance Tools (PTools) Application
ClassMethod version() As %String [ SqlName = SQLUtilities_version, SqlProc ]
{
	QUIT $$$SQLUtilsVersion		//MRP878 - First Implementation of Versioning
}

Trigger OnDelete [ Event = DELETE, Time = AFTER ]
{
	#; --- If no more data rows exist, delete the Stream Counter global ---
	if '$$$existsSYSPToolsSQLUtilsStream  {
		$$$killSYSPToolsSQLUtilsStream
	}
	
    #; --- If no more data rows exist, delete the ID Counter global ---
    if '$$$existsSYSPToolsSQLUtilsData  { 
    	$$$resetSYSPToolsSQLUtilStream
    	$$$killSYSPToolsSQLUtilsData  
    }
}

Storage Default
{
<CounterLocation>^%sqlcq($NAMESPACE,"PTools","Utils","Queries","C")</CounterLocation>
<Data name="SQLUtilitiesDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Type</Value>
</Value>
<Value name="3">
<Value>Name</Value>
</Value>
<Value name="4">
<Value>SQLText</Value>
</Value>
<Value name="5">
<Value>ImportPackage</Value>
</Value>
</Data>
<DataLocation>^%sqlcq($NAMESPACE,"PTools","Utils","Queries","D")</DataLocation>
<DefaultData>SQLUtilitiesDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%sqlcq($NAMESPACE,"PTools","Utils","Queries","D")</IdLocation>
<IndexLocation>^%sqlcq($NAMESPACE,"PTools","Utils","Queries","I")</IndexLocation>
<StreamLocation>^%sqlcq($NAMESPACE,"PTools","Utils","Queries","S")</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
