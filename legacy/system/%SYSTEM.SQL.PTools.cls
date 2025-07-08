/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlx

/// <style type="text/css"> 
///    .section-head { color: darkblue; white-space: pre; font-family:  'Courier New'; }
///    .info-head { white-space: pre; font-family: 'Courier New'; }
///    DEP { color: red; font-weight: bold; }
///    IMP { color: darkblue; background-color: #D3D3D3; border: 1px solid black; font-size: 1.05em; line-height: 100%; margin-left: 0px; margin-top: 0px; margin-bottom: 0px; padding-bottom: 15px; width: 80%; white-space: pre; display: block; }
/// </style>
/// 
/// <p class="info-head">
/// Class:        %SYSTEM.SQL.PTools
/// Replaces:     %SYSTEM.SQL  [PTools/SQLStats Methods]
/// Purpose:      
///    This class is designed to provides an interface for all of the 
///    PTools/SQLStats runtime methods.  While most of these methods remain
///    available from the classes in which they are defined, this interface
///    is provided as a quick way to invoke these methods in one central
///    location.
/// 
///    The special <b>$SYSTEM</b> variable, which is an alias for the %SYSTEM 
///    package containing classes that provide methods for a wide variety of
///    needs, can be used to invoke methods within this class:
/// 
/// <IMP>
///       do $SYSTEM.SQL.PTools.<i>method</i>(...)
/// </IMP>
/// 
///    Since this class extends the <class>%SYSTEM.Help</class> class, the following method
///    can be invoked to display all of the <i>method</i> Entry Points available 
///    to this class:
/// 
/// <IMP>
///       do $SYSTEM.SQL.PTools.Help()
/// </IMP>
/// 
///   The following example demonstrates how this class can be used to display
///   the current SQLStats-flag setting:
/// 
/// <IMP>
///      write $SYSTEM.SQL.PTools.getSQLStatsFlag()
/// </IMP>
/// 
/// </p>
Class %SYSTEM.SQL.PTools Extends %SYSTEM.Help [ Abstract, Not ProcedureBlock, System = 4 ]
{

/// This method is used to START the PTools statistics collection
/// General Stats Methods
/// <p class="section-head">
/// <b>                  G E N E R A L   S T A T S   M E T H O D S                </b>
///                      =========================================
/// 
/// <b>                           %SYS.PTools.Stats CLASS                         </b>
///                               -----------------------
/// The following methods are defined in the <class>%SYS.PTools.Stats</class> class and
/// are designed to gather performance statistics for any type of routine
/// or code block.  Additional details can be found within the defining class.
/// </p>
/// 
/// <p class="info-head">
/// Method:       startGeneralStats
/// Replaces:     N/A
/// Status:       Original Functionality
/// Purpose:      This method is used to START the PTools statistics collection
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: $SYSTEM.SQL.PTools.startGeneralStats(...)
///                           SQL: N/A
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Start collecting stats to analyze the class 'Populate' method:
/// 
///               do $SYSTEM.SQL.PTools.startGeneralStats($NAMESPACE,"Test","Populate")
///               do ##class(Sample.Person).Populate(100)
///               do $SYSTEM.SQL.PTools.stopGeneralStats($NAMESPACE,"Test","Populate")
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
/// 
/// Parameters:
///    ns        - The namespace in which the stats collection is occurring
///    rtn       - The routine name for which the stats collection is occurring
///    mod       - The module name for which the stats collection is occurring
///                   [DEFAULT: 1]
/// 
/// RETURN Value: (NONE)
/// </p>
ClassMethod startGeneralStats(ns As %String, rtn As %String, mod As %String = 1) [ ProcedureBlock = 1 ]
{
	do ##class(%SYS.PTools.Stats).Start(ns,rtn,mod)
 	QUIT
}

/// This method is used to STOP the PTools statistics collection
/// <p class="info-head">
/// Method:       stopGeneralStats
/// Replaces:     N/A
/// Status:       Original Functionality
/// Purpose:      This method is used to STOP the PTools statistics collection
///               This method INSERTs the stats information into the 
///               %SYS_PTools.Stats table
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: $SYSTEM.SQL.PTools.stopGeneralStats(...)
///                           SQL: N/A
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Stop collecting stats to analyze the class 'Populate' method:
/// 
///               do $SYSTEM.SQL.PTools.startGeneralStats($NAMESPACE,"Test","Populate")
///               do ##class(Sample.Person).Populate(100)
///               do $SYSTEM.SQL.PTools.stopGeneralStats($NAMESPACE,"Test","Populate")
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
/// 
/// Parameters:
///    ns        - The namespace in which the stats collection is occurring
///    rtn       - The routine name for which the stats collection is occurring
///    mod       - The module name for which the stats collection is occurring
///                   [DEFAULT: 1]
/// 
/// RETURN Value: (NONE)
/// </p>
ClassMethod stopGeneralStats(ns As %String, rtn As %String, mod As %String = 1) [ ProcedureBlock = 1 ]
{
 	do ##class(%SYS.PTools.Stats).Stop(ns,rtn,mod)
 	QUIT
}

/// Create a file containing the data from the '%SYS.PTools.Stats' class
/// <p class="info-head">
/// Method:       exportGeneralStats [SQL: PTools_exportGeneralStats]
/// Replaces:     Report  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      Create a Performance Tool file containing the data 
///               from the '%SYS.PTools.Stats' class and return the output location...
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
///                  ObjectScript: $SYSTEM.SQL.PTools.exportGeneralStats(...)
///                           SQL: CALL %SYSTEM_SQL.PTools_exportGeneralStats(...)
///                                SELECT %SYSTEM_SQL.PTools_exportGeneralStats(...)
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
///               set tSC=$SYSTEM.SQL.PTools.exportGeneralStats($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYSTEM_SQL.PTools_exportGeneralStats('$IO','H')
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
///    file      - The path and file in which to create and store the data from the 
///                %SYS.PTools.Stats class:  (e.g. C:\exportFile.txt)
///                NOTE:    $IO = Outputs the data to the screen
///                       '$IO' = Output the data to the current device when invoked from the CALL/SELECT-interface
///                      '$DEF' = Ouput the data to the DEFAULT file when invoked from the CALL/SELECT-interface
///                   [DEFAULT: {Current-Directory}\PT_Stats_exportStats_YYYYMMDD_HHMMSS.{ext}]
///                WHERE {Current-Directory} = The directory of the Namespace in which
///                                            this method is invoked (e.g. $ZU(12,""))
///                NOTE 2: If Passed By Reference, then 'file' will be returned as the
///                        canonical name of the Export/Reporting file
///    format    - The output format of the Export/Reporting file
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
///    silent    -  0 - Display all messages during the running of this method
///                 1 - Don't display any messages during the running of this method
///    statsType -  0 - Return all rows from %SYS.PTools.Stats ONLY       [DEFAULT]
///                 1 - Return all rows from %SYS.PTools.StatsSQL ONLY
///                 2 - Return all rows from %SYS.PTools.Stats & %SYS.PTools.StatsSQL
///    rtnName   - If specified, return only the rows where the 'RoutineName' matches
///                the value of this parameter; Otherwise, return rows for all 'RoutineName' values
///    modName   - If specified, return only the rows where the 'ModuleName' matches
///                the value of this parameter; Otherwise, return rows for all 'ModuleName' values
///    conds     - A string/array of possible conditions by which to restrict the
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
///    ptInfo    - A Pass By Reference information array that returns to the user 
///                the following details:
///                   ptInfo(variable)=value
///                   ptInfo("outputFile")=The canonical name of the Export/Reporting file
///    bcFlag    - This is a Backward-Compatibility flag used for 
///                [Internal Purposes ONLY]
/// 
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod exportGeneralStats(file = "", format = "P", silent = 0, statsType = 0, rtnName = "", modName = "", ByRef conds As %RawString, ByRef ptInfo As %RawString) As %Status [ SqlName = PTools_exportGeneralStats, SqlProc ]
{
	QUIT ##class(%SYS.PTools.Stats).exportStats(file,format,silent,statsType,rtnName,modName,.conds,.ptInfo)
}

/// Delete all of the data stored in the '%SYS.PTools.Stats' class
/// <p class="section-head">
/// <b>                    C L E A R  'Stats'  D A T A                            </b>
///                        ---------------------------
/// The following methods are used to remove all of the 'Stats' data:
/// 
///    - clearStatsALL()        <class>%SYS.PTools.Stats</class>
///       - clearStats()        <class>%SYS.PTools.Stats</class>
///       - clearStatsAllNS()   <class>%SYS.PTools.Stats</class>
/// 
/// The aforementioned methods remove data stored in the following classes:
///    - %SYS.PTools.Stats (old/new)
///  NOTE: old = Backward-compatible data
/// </p>
/// 
/// <p class="info-head">
/// Method:       clearGeneralStats [SQL: PTools_clearGeneralStats]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method deletes all of the data stored in the '%SYS.PTools.Stats'
///               class, based on the specified 'ns' and 'rtn' parameters...
/// 
///               This method clears statistics which are gathered by the 
///               invocation of the following two methods:
///                  do $SYSTEM.SQL.PTools.startGeneralStats(namespace,routine,mod)  // Start Stats Collection
///                  // Invoke the method in which statistics are to be collected
///                  do $SYSTEM.SQL.PTools.stopGeneralStats(namespace,routine,mod)   // Stop Stats Collection
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: $SYSTEM.SQL.PTools.clearGeneralStats(...)
///                           SQL: CALL %SYSTEM_SQL.PTools_clearGeneralStats(...)
///                                SELECT %SYSTEM_SQL.PTools_clearGeneralStats(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
/// 
/// Parameters:
///    ns          - The namespace in which to clear Statistics
///                  If none provided, use the current namespaces where Stats collected
///                     [DEFAULT: Current Namespace]
///    rtn         - The routine for which to clear Statistics
///                  If none provided, clear all routines in the given 'namespace'
///                     [OPTIONAL]
///    ph3         - Placeholder Parameter for future extensibility
///    clearErrs   - 0 = Don't delete the 'PTools' Application Errors
///                  1 = Delete all of the 'PTools' Application Errors
///                     [DEFAULT: 0]
///    returnType  - 0 = Return a %Status code of either $$$OK or $$$ERROR()
///                  1 = Return the number of Stats rows deleted from the 
///                      following class: %SYS.PTools.Stats
///                     [DEFAULT: 0]
///    ptInfo      - A Pass By Reference information array that returns
///                  detailed information to the user in the following format:
///                     ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                  Where category = { "cnt" | "curr" | "term" | ... }
///                        variable = A var corresponding to the given 'category'
/// 
///                  Example:
///                     ptInfo("cnt","clearStats")=The number of rows deleted 
///                                                via this method
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the number of Stats rows deleted from the following class; 
///               Otherwise, return an error message if an error occurred:
///                  %SYS.PTools.Stats
/// </p>
ClassMethod clearGeneralStats(ns As %String = "", rtn As %String = "", ph3 As %Integer = 0, clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PTools_clearGeneralStats, SqlProc ]
{
	QUIT $$clearStats^%SYS.PTools(ns,rtn,ph3,clearErrs,returnType,.ptInfo)
}

/// Delete all of the data stored in the SQL Stats classes
/// <p class="section-head">
/// <b>                   C L E A R  'SQL Stats'  D A T A                         </b>
///                       -------------------------------
/// The following methods are used to remove all of the 'SQL Stats' data:
/// 
///    - clearStatsSQLALL()              <class>%SYS.PTools.Stats</class>
///       - clearStatsSQLOLD()           <class>%SYS.PTools.Stats</class>
///          - clearSQLStats()           <class>%SYS.PTools.SQLStats</class>
///          - clearSQLQuery()           <class>%SYS.PTools.SQLQuery</class>
///          - clearSQLBenchMarkQry()    <class>%SYS.PTools.SQLBenchMarkQueries</class>
///          - clearSQLBenchMarkRslt()   <class>%SYS.PTools.SQLBenchMarkResults</class>
///       - clearStatsSQLNEW()           <class>%SYS.PTools.Stats</class>
///          - clearStatsSQL()           <class>%SYS.PTools.StatsSQL</class>
///          - clearStatsSQLAllNS()      <class>%SYS.PTools.StatsSQL</class>
/// 
/// The aforementioned methods remove data stored in the following classes:
/// 
///    - %SYS.PTools.SQLStats (old)
///    - %SYS.PTools.SQLQuery (old)
///    - %SYS.PTools.SQLBenchMarkQueries (old)
///    - %SYS.PTools.SQLBenchMarkResults (old)
///    - %SYS.PTools.StatsSQL (new)
/// 
/// Optional:
///    - %SYS.PTools.SQLUtilities (old)
///    - %SYS.PTools.SQLUtilResults (old)
///    - %SYS.PTools.UtilSQLStatements (new)
///    - %SYS.PTools.UtilSQLAnalysisDB (new)
/// 
///  NOTE: old = Backward-compatible data
/// </p>
/// 
/// <p class="info-head">
/// Method:       clearSQLStatsALL [SQL: PTools_clearSQLStatsALL]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method deletes all of the data stored in the Optimal (new)
///               PTools SQL Stats classes, based on the specified parameters...
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: $SYSTEM.SQL.PTools.clearSQLStatsALL(...)
///                           SQL: CALL %SYSTEM_SQL.PTools_clearSQLStatsALL(...)
///                                SELECT %SYSTEM_SQL.PTools_clearSQLStatsALL(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools",...)
/// 
/// Parameters:
///    ns             - The namespace in which to clear PTools SQL Statistics        [DEFAULT: $NAMESPACE]
///    rtn            - The routine in which to clear PTools SQL Statistics          [DEFAULT: ""]
///                     If none provided, clear all routines in the given 'ns'
///    ph3            - Placeholder Parameter for future extensibility
///    clearAll       - 0 = Delete all of the data, except the 'INFO' rows,
///                         stored in the StatsSQL class:
///                            - %SYS.PTools.StatsSQL (new)
///                     1 = Delete all of the data, including the 'INFO' rows,       [DEFAULT]
///                         stored in the StatsSQL class:
///                            - %SYS.PTools.StatsSQL (new)
///    clearSQLIndex  - 0 = Don't delete the data stored in the Utility SQL          [DEFAULT]
///                         Index/Analysis classes:
///                            - %SYS.PTools.UtilSQLStatements (new)
///                            - %SYS.PTools.UtilSQLAnalysisDB (new)
///                     1 = Delete all of the data stored in the Utility SQL 
///                         Index/Analysis classes:
///                            - %SYS.PTools.UtilSQLStatements (new)
///                            - %SYS.PTools.UtilSQLAnalysisDB (new)
///    clearErrs      - 0 = Don't delete the 'PTools' Application Errors
///                     1 = Delete all of the 'PTools' Application Errors            [DEFAULT]
///    purgeCQ        - 0 = Don't purge all of the Cached Queries                    [DEFAULT]
///                     1 = Purge all of the Cached Queries
///    silent         - 0 = Display all messages during this method invocation       [DEFAULT]
///                     1 = Don't display any messages during this method invocation
///    returnType     - 0 = Return a %Status code of either $$$OK or $$$ERROR()      [DEFAULT]
///                     1 = Return the total number of Stats rows deleted
///    ptInfo         - A Pass By Reference information array that returns
///                     detailed information to the user in the following format:
///                        ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                     Where category = { "cnt" | "curr" | "term" | ... }
///                           variable = A var corresponding to the given 'category'
/// 
///                     Example:
///                        ptInfo("cnt","clearSQLStatsALL")=The number of rows deleted 
///                                                         via this method
/// 
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the total number of Stats rows deleted; 
///               Otherwise, return an error message if an error occurred
/// </p>
ClassMethod clearSQLStatsALL(ns As %String = "", rtn As %String = "", ph3 As %Integer = 0, clearAll As %Integer = 1, clearSQLIndex As %Integer = 0, clearErrs As %Integer = 1, purgeCQ As %Integer = 0, silent As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PTools_clearSQLStatsALL, SqlProc ]
{
	QUIT $$clearStatsSQLNEW^%SYS.PToolsUtil(ns,rtn,ph3,clearAll,clearSQLIndex,clearErrs,purgeCQ,silent,returnType,.ptInfo)
}

/// Delete all of the data stored in the SQL Index/Analysis Stats classes
/// <p class="section-head">
/// <b>                C L E A R  'SQL Index Stats'  D A T A                      </b>
///                    -------------------------------------
/// The following methods are used to remove all of the 'SQL Index Stats' data: 
/// 
///    - clearStatsSQLIndexALL()      <class>%SYS.PTools.Stats</class>
///       - clearStatsSQLIndexOLD()   <class>%SYS.PTools.Stats</class>
///          - ClearStatements()      <class>%SYS.PTools.SQLUtilities</class>
///          - ClearResults()         <class>%SYS.PTools.SQLUtilities</class>
///       - clearStatsSQLIndexNEW()   <class>%SYS.PTools.Stats</class>
///          - clearSQLStatements()   <class>%SYS.PTools.UtilSQLAnalysis</class>
///          - clearSQLAnalysisDB()   <class>%SYS.PTools.UtilSQLAnalysis</class>
/// 
/// The aforementioned methods remove data stored in the following classes:
/// 
///    - %SYS.PTools.SQLUtilities (old)
///    - %SYS.PTools.SQLUtilResults (old)
///    - %SYS.PTools.UtilSQLStatements (new)
///    - %SYS.PTools.UtilSQLAnalysisDB (new)
/// 
///  NOTE: old = Backward-compatible data
/// </p>
/// 
/// <p class="info-head">
/// Method:       clearSQLIndexStats [SQL: PTools_clearSQLIndexStats]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method deletes all of the data stored in the Optimal
///               (new) PTools Utility SQL Index/Analysis Stats classes, based
///               on the specified parameters...
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: $SYSTEM.SQL.PTools.clearSQLIndexStats(...)
///                           SQL: CALL %SYSTEM_SQL.PTools_clearSQLIndexStats(...)
///                                SELECT %SYSTEM_SQL.PTools_clearSQLIndexStats(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
///                  Since this method returns a $LIST() of %Status codes,
///                  the output can be converted to a comma-delimited string
///                  by using the $LISTTOSTRING(...) function on the ObjectScript
///                  or SQL result. 
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools",...)
/// 
/// Parameters:
///    ns             - The namespace in which to clear PTools Stats                 [DEFAULT: $NAMESPACE]
///    clearErrs      - 0 = Don't delete the 'PTools' Application Errors
///                     1 = Delete all of the 'PTools' Application Errors            [DEFAULT]
///    silent         - 0 = Display all messages during this method invocation       [DEFAULT]
///                     1 = Don't display any messages during this method invocation
///    returnType     - 0 = Return a %Status code of either $$$OK or $$$ERROR()      [DEFAULT]
///                     1 = Return the total number of Stats rows deleted
///    ptInfo         - A Pass By Reference information array that returns
///                     detailed information to the user in the following format:
///                        ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                     Where category = { "cnt" | "curr" | "term" | ... }
///                           variable = A var corresponding to the given 'category'
/// 
///                     Example:
///                        ptInfo("cnt","clearStatsSQLIndexALL")=The number of rows deleted 
///                                                             via this method
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the total number of Stats rows deleted; 
///               Otherwise, return an error message if an error occurred
/// </p>
ClassMethod clearSQLIndexStats(ns As %String = "", clearErrs As %Integer = 1, silent As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PTools_clearSQLIndexStats, SqlProc ]
{
	QUIT $$clearStatsSQLIndexNEW^%SYS.PToolsUtil(ns,clearErrs,silent,returnType,.ptInfo)
}

/// Retrieve 'PTools/SQLStats' Application Error(s)
/// <p class="section-head">
/// <b>                G E T / C L E A R  'PToolsError'  D A T A                  </b>
///                    -----------------------------------------
/// The following methods are used to retrieve & remove all of the 'PToolsError' 
/// data:
/// 
///    - getPToolsError()     <class>%SYS.PTools.Stats</class>
///    - clearPToolsError()   <class>%SYS.PTools.Stats</class>
/// 
/// The aforementioned methods remove data stored in the following global:
/// 
///    - ^%sqlcq($NAMESPACE,"PTools","Error",{errRowID}) (old/new)
/// 
///  NOTE: old = Backward-compatible data
/// </p>
/// 
/// <p class="info-head">
/// Method:       getError [SQL: PTools_getError]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method retrieve a specific 'PTools' Application Error for 
///               the given 'errRowID' or retrieve all errors if no 'errRowID' 
///               is provided.
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: $SYSTEM.SQL.PTools.getError(...)
///                           SQL: SELECT %SYSTEM_SQL.PTools_getError(...)
/// 
/// NOTE: 'PTools' Application Errors will be returned in the 'PToolsErr' array 
///       as follows:
///             PToolsErr={errRowID}    [Counter]
///             PToolsErr({errRowID},0)=$LIST:
/// 
///                         1) $HOROLOG                 [Timestamp Internal]
///                         2) Timestamp External       [Timestamp External: YYYY-MM-DD HH:MM:SS]
///                         3) $NAMESPACE               [Current Namespace]
///                         4) $JOB                     [Current $JOB]
///                         5) $ZN                      [Current Routine]
///                         6) $zu(41)                  [Stack Level]
/// 
///             PToolsErr({errRowID},1)=$LIST:
/// 
///                         1) {ns}                     [Error Namespace]
///                         2) {job}                    [Error $JOB]
///                         3) {rtn}                    [Error Routine]
///                         4) {curs}                   [Error SQL Cursor]
///                         5) {mod}                    [Error SQL Module]
///                         6) {func}                   [Error Function/Method]
///                         7) {ze}                     [Error $ZE]
///                         8) {errMsg}                 [Error Message]
///                                     --- SQL Errors ---
///                         9) {class}                  [Error Class]
///                        10) {table}                  [Error Table]
///                        11) {SQLCODE}                [Error SQLCODE]
///                        12) {%msg}                   [Error SQL Message]
/// 
///             PToolsErr({errRowID},2)=errLog(errLogID)=errLogMsg
///             PToolsErr({errRowID},2,{errLogID})={errLogMsg}
/// 
/// Parameters:
///    errRowID      - The 'PTools' Error RowID to retrieve; If none specified,
///                    then retrieve all errors into the 'PToolsErr()' array
///    PToolsErr     - An array in which the 'PTools' Application Errors will 
///                    be returned
///                       [PASS BY REFERENCE]
///    
/// RETURN Value: The 'PTools' Error RowID ({errRowID}) retrieved, the
///               empty string ("") if {errRowID} invalid, or the word
///               'all' indicating an array of all errors returned.
/// </p>
ClassMethod getError(errRowID As %String = "", PToolsErr As %RawString) As %Integer [ SqlName = PTools_getError, SqlProc ]
{
	QUIT $$getPToolsError^%SYS.PTools2(errRowID,.PToolsErr)
}

/// Delete 'PTools/SQLStats' Application Error(s)
/// <p class="info-head">
/// Method:       clearError [SQL: PTools_clearError
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method deletes a specific 'PTools' Application Error for 
///               the given 'errRowID' or Deletes all errors if no 'errRowID' is 
///               provided.
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: $SYSTEM.SQL.PTools.clearError(...)
///                           SQL: SELECT %SYSTEM_SQL.PTools_clearError(...)
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","Error",{errRowID})
/// 
/// Parameters:
///    errRowID      - The 'PTools' Error RowID to delete; If none specified,
///                    then delete all recorded PTools errors
///    
/// RETURN Value: The 'PTools' Error RowID ({errRowID}) deleted, the
///               empty string ("") if {errRowID} invalid, or the word
///               'all' indicating an array of all errors deleted.
/// </p>
ClassMethod clearError(errRowID As %String = "") As %Integer [ SqlName = PTools_clearError, SqlProc ]
{
	QUIT $$clearPToolsError^%SYS.PTools2(errRowID)
}

/// Provide the current version for the %SYS.PTools.Stats class/section of the Performance Tools (PTools) Application
ClassMethod version() As %String [ SqlName = PTools_version, SqlProc ]
{
	QUIT ##class(%SYS.PTools.Stats).version()
}

/// Set the SQLStats-flag that controls whether or not the System collects SQL Statistics about each run of a query
/// <p class="section-head">
/// <b>                     S Q L   S T A T S   M E T H O D S                     </b>
///                         =================================
/// 
/// <b>                        %SYS.PTools.StatsSQL CLASS                         </b>
///                            --------------------------
/// The following methods are defined in the <class>%SYS.PTools.StatsSQL</class> class and
/// are designed to gather performance statistics for SQL Queries.  Additional
/// details can be found within the defining class.
/// </p>
/// 
/// <p class="info-head">
/// Method:       setSQLStatsFlag [SQL: PTools_setSQLStatsFlag]
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
///          Object Script: $SYSTEM.SQL.PTools.setSQLStatsFlag(...)
///                    SQL: SELECT %SYSTEM_SQL.PTools_setSQLStatsFlag(...)
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Turn PTools ON to collects stats for all SQL modules (System):
/// 
///                  set oldStats=$SYSTEM.SQL.PTools.setSQLStatsFlag(3)
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
///                          4    Total Lines of Code Executed  Total number of COS lines executed
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
///                       'Total Lines of Code Executed':
/// 
///                         MVal  Metric Name
///                         ----  ----------------------------
///                          1    Query Execution Time
///                          2    Total Global References
///                         +4    Total Lines of Code Executed
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
/// RETURN:
///    The value of the SQLStats-flag before setting it to the new value;
///    Otherwise, return an error message if an error occurred
/// </p>
ClassMethod setSQLStatsFlag(actionFlag As %Integer = 0, collectFlag As %String = "", terminateCond As %String = 0, ByRef ptInfo As %RawString) As %String [ SqlName = PTools_setSQLStatsFlag, SqlProc ]
{
	QUIT $$SetSQLStatsFlag^%SYS.PToolsUtil(0,actionFlag,0,collectFlag,,,terminateCond,.ptInfo)
}

/// Set the SQLStats-flag that controls whether or not this Process/Job collects SQL Statistics about each run of a query
/// <p class="info-head">
/// Method:       setSQLStatsFlagJob [SQL: PTools_setSQLStatsFlagJob]
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
///          Object Script: $SYSTEM.SQL.PTools.setSQLStatsFlagJob(...)
///                    SQL: SELECT %SYSTEM_SQL.PTools_setSQLStatsFlagJob(...)
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Turn PTools ON to collects stats for all SQL modules:
/// 
///                  set oldStats=$SYSTEM.SQL.PTools.setSQLStatsFlagJob(3)
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
///                          4    Total Lines of Code Executed  Total number of COS lines executed
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
///                       'Total Lines of Code Executed':
/// 
///                         MVal  Metric Name
///                         ----  ----------------------------
///                          1    Query Execution Time
///                          2    Total Global References
///                         +4    Total Lines of Code Executed
///                         ===
///                          7    Collect both of these performance metrics
/// 
///                       By passing 7 for the value of the 'collectFlag' parameter, the
///                       sum of the three aforementioned performance metrics MVal numbers,
///                       the SQLStats PTool application will only collect statistical data 
///                       for these two performance metrics whenever an SQL Query is invoked.
///    p3               - Placeholder Parameter for future extensibility
///    ptInfo           - A Pass By Reference information array that returns to the user detailed 
///                       information in the following format:
///                          ptInfo(category,variable)=value
///                             Where category = { "current" | "terminate" | ... }
///                                   variable = A variable that corresponds to the given 'category'
/// 
///                       Example:
///                          ptInfo("current","SQLStatsFlag")=The SQLStats-flag value after method execution
/// 
/// RETURN:
///    The value of the SQLStats-flag before setting it to the new value;
///    Otherwise, return an error message if an error occurred
/// </p>
ClassMethod setSQLStatsFlagJob(actionFlag As %Integer = 0, collectFlag As %String = "", p3 As %String = "", ByRef ptInfo As %RawString) As %String [ SqlName = PTools_setSQLStatsFlagJob, SqlProc ]
{
	QUIT $$SetSQLStatsFlag^%SYS.PToolsUtil(1,actionFlag,0,collectFlag,,,,.ptInfo)
}

/// Set the SQLStats-flag that controls whether or not to collect SQL Statistics about each run of a query for the given 'pid'
/// <p class="info-head">
/// Method:       setSQLStatsFlagByPID [SQL: PTools_setSQLStatsFlagByPID]
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
/// <i style="color: red;">RESTRICTION:  This method invocation requires %Admin_Operate:Use privilege</i>
/// 
/// Invocation:   This method can be invoked in the following ways:
///          Object Script: $SYSTEM.SQL.PTools.setSQLStatsFlagByPID(...)
///                    SQL: SELECT %SYSTEM_SQL.PTools_setSQLStatsFlagByPID(...)
///  
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Turn PTools ON to collects stats for all SQL modules for
///                  PID# 12345:
/// 
///                  set oldStats=$SYSTEM.SQL.PTools.setSQLStatsFlagByPID(12345,3)
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
///                          4    Total Lines of Code Executed  Total number of COS lines executed
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
///                       'Total Lines of Code Executed':
/// 
///                         MVal  Metric Name
///                         ----  ----------------------------
///                          1    Query Execution Time
///                          2    Total Global References
///                         +4    Total Lines of Code Executed
///                         ===
///                          7    Collect both of these performance metrics
/// 
///                       By passing 7 for the value of the 'collectFlag' parameter, the
///                       sum of the three aforementioned performance metrics MVal numbers,
///                       the SQLStats PTool application will only collect statistical data 
///                       for these two performance metrics whenever an SQL Query is invoked.
///    ptInfo           - A Pass By Reference information array that returns to the user detailed 
///                       information in the following format:
///                          ptInfo(category,variable)=value
/// 
///                       NOTE: This method currently returns no 'ptInfo', but is
///                             included for future extensibility
/// 
/// RETURN:
///     The value of the SQLStats-flag before setting it to the new value;
///     Otherwise, return an error message if an error occurred
/// </p>
ClassMethod setSQLStatsFlagByPID(pid As %String = "", actionFlag As %Integer = 0, collectFlag As %String = "", ByRef ptInfo As %RawString) As %String [ SqlName = PTools_setSQLStatsFlagByPID, SqlProc ]
{
	QUIT $$SetSQLStatsFlagByPID^%SYS.PToolsUtil(pid,actionFlag,0,collectFlag,,,,.ptInfo)
}

/// Set the flag that controls whether or not to collect SQL Statistics about each run of a query within the given 'ns' (namespace)
/// <p class="info-head">
/// Method:       setSQLStatsFlagByNS [SQL: PTools_setSQLStatsFlagByNS]
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
///               given 'namespace' and NOT the SQLStats-flag (Process/Job)!
/// 
/// Invocation:   This method can be invoked in the following ways:
///          Object Script: $SYSTEM.SQL.PTools.setSQLStatsFlagByNS(...)
///                    SQL: SELECT %SYSTEM_SQL.PTools_setSQLStatsFlagByNS(...)
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Turn PTools ON to collects stats for all SQL modules within the
///                  "USER" Namespace:
/// 
///                  set oldStats=$SYSTEM.SQL.PTools.setSQLStatsFlagByNS("USER",3)
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
///                          4    Total Lines of Code Executed  Total number of COS lines executed
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
///                       'Total Lines of Code Executed':
/// 
///                         MVal  Metric Name
///                         ----  ----------------------------
///                          1    Query Execution Time
///                          2    Total Global References
///                         +4    Total Lines of Code Executed
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
/// RETURN:
///     The value of the SQLStats-flag before setting it to the new value;
///     Otherwise, return an error message if an error occurred
/// </p>
ClassMethod setSQLStatsFlagByNS(ns As %String = "", actionFlag As %Integer = 0, collectFlag As %String = "", terminateCond As %String = 0, ByRef ptInfo As %RawString) As %String [ SqlName = PTools_setSQLStatsFlagByNS, SqlProc ]
{
	QUIT $$SetSQLStatsFlagByNS^%SYS.PToolsUtil(ns,actionFlag,0,collectFlag,,,terminateCond,.ptInfo)
}

/// Get the SQLStats-flag that controls whether or not we collect SQL Statistics for each SQL Query execution
/// <p class="info-head">
/// Method:       getSQLStatsFlag [SQL: PTools_getSQLStatsFlag]
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
///                                  write $SYSTEM.SQL.PTools.getSQLStatsFlag("")  =>  "0:0:0::0:1"
///        
///                               To retrieve the actual value for each component-flag of
///                               the SQLStats-flag in this example, pass a one (1) for
///                               the 'flagType' parameter:
///                                  write $SYSTEM.SQL.PTools.getSQLStatsFlag(1)   =>  "-1:0:0::0:1"
/// 
/// Invocation:   This method can be invoked in the following ways:
///          Object Script: $SYSTEM.SQL.PTools.getSQLStatsFlag(...)
///                    SQL: SELECT %SYSTEM_SQL.PTools_getSQLStatsFlag(...)
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Get the current value of the SQLStats-flag for the
///                  Job/System Flag based on SQLStats-flag Rules:
/// 
///                  set SQLStatsFlag=$SYSTEM.SQL.PTools.getSQLStatsFlag("")
/// 
/// Parameters:
///    flagType           - "" = Job/System Flag based on SQLStats-flag Rules    [DEFAULT]
///                         0  = System Flag
///                         1  = Process/Job Flag
///    ptInfo             - A Pass By Reference information array that returns to the user detailed 
///                         information in the following format:
///                            ptInfo(category,variable)=value
///                               Where category = { "current" | "terminate" | ["expired"] | ... }
///                                     variable = A variable that corresponds to the given 'category'
/// 
///                         Example:
///                            ptInfo("current","SQLStatsFlag")=The SQLStats-flag value after method execution
/// 
/// RETURN:
///     The current value of the SQLStats-flag;
///     Otherwise, return an error message if an error occurred
/// </p>
ClassMethod getSQLStatsFlag(flagType As %Integer = "", ByRef ptInfo As %RawString) As %String [ SqlName = PTools_getSQLStatsFlag, SqlProc ]
{
	QUIT $$GetSQLStatsFlag^%SYS.PToolsUtil(flagType,0,.ptInfo)
}

/// Get the SQLStats-flag that controls whether or not we collect SQL Statistics about each SQL Query execution for the given 'pid'
/// <p class="info-head">
/// Method:       getSQLStatsFlagByPID [SQL: PTools_getSQLStatsFlagByPID]
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
/// <i style="color: red;">RESTRICTION:  This method invocation requires %Admin_Operate:Use privilege</i>
/// 
/// Invocation:   This method can be invoked in the following ways:
///          Object Script: $SYSTEM.SQL.PTools.getSQLStatsFlagByPID(...)
///                    SQL: SELECT %SYSTEM_SQL.PTools_getSQLStatsFlagByPID(...)
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Get the current value of the SQLStats-flag for the
///                  Job/System Flag based on SQLStats-flag Rules for
///                  PID# 12345:
/// 
///                  set SQLStatsFlag=$SYSTEM.SQL.PTools.getSQLStatsFlagByPID(12345)
/// 
/// Parameters:
///    pid               - The process ID ($JOB) for which to set the SQLStats-flag
///                           [DEFAULT: Current $JOB]
///    ptInfo            - A Pass By Reference information array that returns to the user detailed 
///                        information in the following format:
///                           ptInfo(category,variable)=value
/// 
///                        NOTE: This method currently returns no 'ptInfo', but is
///                              included for future extensibility
/// 
/// RETURN:
///     The current value of the SQLStats-flag;
///     Otherwise, return an error message if an error occurred
/// </p>
ClassMethod getSQLStatsFlagByPID(pid As %String = "", ByRef ptInfo As %RawString) As %String [ SqlName = PTools_getSQLStatsFlagByPID, SqlProc ]
{
	QUIT $$GetSQLStatsFlagByPID^%SYS.PToolsUtil(pid,0,.ptInfo)
}

/// Aggregate all of the statistical properties for each SQL Query where data was collected
/// <p class="info-head">
/// Method:       aggregateSQLStats [SQL: PTools_aggregateSQLStats]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This function aggregates all of the statistical properties for 
///               each SQL Query where data was collected
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: $SYSTEM.SQL.PTools.aggregateSQLStats(...)
///                    SQL: CALL %SYSTEM_SQL.PTools_aggregateSQLStats(...)
///                         SELECT %SYSTEM_SQL.PTools_aggregateSQLStats(...)
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
///               set status=$SYSTEM.SQL.PTools.aggregateSQLStats("SAMPLES")
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
ClassMethod aggregateSQLStats(ns = "", rtn = "", curs = "") As %Status [ SqlName = PTools_aggregateSQLStats, SqlProc ]
{
	QUIT ##class(%SYS.PTools.StatsSQL).aggregateSQLStats(ns,rtn,curs)
}

/// Export the data from the '%SYS.PTools.StatsSQL' class and return the output location
/// <p class="info-head">
/// Method:       exportSQLStats [SQL: PTools_exportSQLStats]
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
///                  ObjectScript: $SYSTEM.SQL.PTools.exportSQLStats(...)
///                    SQL: CALL %SYSTEM_SQL.PTools_exportSQLStats(...)
///                         SELECT %SYSTEM_SQL.PTools_exportSQLStats(...)
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
///               set tSC=$SYSTEM.SQL.PTools.exportSQLStats($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYSTEM_SQL.PTools_exportSQLStats('$IO','H')
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
/// 
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod exportSQLStats(file = "", format = "P", silent = 0, statsType = 0, exportPlan = 0, rtnName = "", modName = "", ByRef conds As %RawString, ByRef ptInfo As %RawString) As %Status [ SqlName = PTools_exportSQLStats, SqlProc ]
{
	QUIT ##class(%SYS.PTools.StatsSQL).exportStatsSQL(file,format,silent,statsType,exportPlan,rtnName,modName,.conds,.ptInfo)
}

/// Retrieves the SQL Query Text
/// <p class="info-head">
/// Method:       getQueryText [SQL: N/A]
/// Replaces:     QueryText (<class>%SYS.PTools.SQLStats</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Functionality
/// Purpose:      This method retrieves the SQL Query Text given the parameters:
///               'ns', 'rtn', 'curs', & 'getInt'
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: $SYSTEM.SQL.PTools.getQueryText(...)
///                    SQL: N/A
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Retrieve the SQL Text for any of the data rows retrieved
///               from invoking the 'exportStatsSQL()' method:
/// 
///               CALL %SYSTEM_SQL.PTools_exportSQLStats('$IO')
///               set sql=$SYSTEM.SQL.PTools.getQueryText($NAMESPACE,"%sqlcq.<namespace>.cls<#>.1","QRS0")
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
ClassMethod getQueryText(ns As %String = "", rtn As %String = "", curs As %String = "", getInt As %Boolean = 0) As %String
{
	QUIT ##class(%SYS.PTools.StatsSQL).getQueryText(ns,rtn,curs,getInt)
}

/// Retrieves the Import Schema
/// <p class="info-head">
/// Method:       getImportSchema [SQL: N/A]
/// Replaces:     ImportSchema (<class>%SYS.PTools.SQLStats</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Functionality
/// Purpose:      This method retrieves the Import Schema given the parameters:
///               'ns', 'rtn', & 'curs'
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: $SYSTEM.SQL.PTools.getImportSchema(...)
///                    SQL: N/A
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Retrieve the SQL Text for any of the data rows retrieved
///               from invoking the 'exportStatsSQL()' method:
/// 
///               CALL %SYSTEM_SQL.PTools_exportSQLStats('$IO')
///               set iSchema=$SYSTEM.SQL.PTools.getImportSchema($NAMESPACE,"%sqlcq.<namespace>.cls<#>.1","QRS0")
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
ClassMethod getImportSchema(ns As %String = "", rtn As %String = "", curs As %String = "") As %String
{
	QUIT ##class(%SYS.PTools.StatsSQL).getImportSchema(ns,rtn,curs)
}

/// Provide the current version for the %SYS.PTools.StatsSQL class/section of the Performance Tools (PTools) Application
ClassMethod versionSQLStats() As %String [ SqlName = PTools_versionSQLStats, SqlProc ]
{
	QUIT ##class(%SYS.PTools.StatsSQL).version()
}

/// Get all of the SQL Statements from the IRIS database
/// <p class="section-head">
/// <b>                   A L L   S Q L   S T A T E M E N T S                     </b>
///                       -----------------------------------
/// Gather SQL Statements from all places within InterSystems IRIS and add them
/// to the <class>%SYS.PTools.UtilSQLStatements</class> class for Index Analysis and additional 
/// processing...
/// </p>
/// 
/// <p class="info-head">
/// Method:       getAllSQLStmts [SQL: PTools_getAllSQLStmts]
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
///                  ObjectScript: $SYSTEM.SQL.PTools.getAllSQLStmts(...)
///                    SQL: CALL %SYSTEM_SQL.PTools_getAllSQLStmts(...)
///                         SELECT %SYSTEM_SQL.PTools_getAllSQLStmts(...)
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
///               class in the following <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$LIST</a> format; Otherwise, return an error 
///               message if an error occurred.
/// 
///                  $LIST() pieces:
///                        1) Grand Total of all SQL Query Statements added
///                        2) Total of all cached query Statements added
///                        3) Total of all Class Method Statements added
///                        4) Total of all Class Query Statements added
///                        5) Total of all Routine Statements added
/// </p>
ClassMethod getAllSQLStmts(clearData As %Integer = 1, skipSysObj As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PTools_getAllSQLStmts, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getAllSQLStmts^%SYS.PTools2(clearData,skipSysObj,skipInsStmts,display,returnType,.ptInfo)
}

/// Get the SQL Statements from the IRIS database
/// <p class="info-head">
/// Method:       getSQLStmts [SQL: PTools_getSQLStmts]
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
///                  ObjectScript: $SYSTEM.SQL.PTools.getSQLStmts(...)
///                    SQL: CALL %SYSTEM_SQL.PTools_getSQLStmts(...)
///                         SELECT %SYSTEM_SQL.PTools_getSQLStmts(...)
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
///               class in the following <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$LIST</a> format; Otherwise, return an error 
///               message if an error occurred.
/// 
///                  $LIST() pieces:
///                        1) Grand Total of all SQL Query Statements added
///                        2) Total of all cached query Statements added
///                        3) Total of all Class Method Statements added
///                        4) Total of all Class Query Statements added
///                        5) Total of all Routine Statements added
/// </p>
ClassMethod getSQLStmts(clearData As %Integer = 1, skipSysObj As %Integer = 1, skipInsStmts As %Integer = 1, getCachedQry As %Integer = 1, getClassMethQry As %Integer = 1, getClassQry As %Integer = 1, getRtnQry As %Integer = 1, display As %Integer = 1, returnType As %Integer = 0) As %Status [ SqlName = PTools_getSQLStmts, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getSQLStmts^%SYS.PTools2(clearData,skipSysObj,skipInsStmts,getCachedQry,getClassMethQry,getClassQry,getRtnQry,display,returnType)
}

/// Get the SQL Statements from all of the Cached Queries
/// <p class="section-head">
/// <b>                      C A C H E D   Q U E R I E S                          </b>
///                          ---------------------------
/// Gather SQL Statements from all of the Cached Queries within InterSystems IRIS 
/// and add them to the <class>%SYS.PTools.UtilSQLStatements</class> class for Index Analysis 
/// and additional processing...
/// </p>
/// 
/// <p class="info-head">
/// Method:       getAllCachedQrySQLStmts [SQL: PTools_getAllCachedQrySQLStmts]
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
ClassMethod getAllCachedQrySQLStmts(clearData As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1) As %Integer [ SqlName = PTools_getAllCachedQrySQLStmts, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getAllCachedQrySQLStmts^%SYS.PTools2(clearData,skipInsStmts,display)
}

/// Get the SQL Statements from all of the Cached Queries that have had a Prepare in the last 'days' days
/// <p class="info-head">
/// Method:       getCachedQrySQLStmtsByDays [SQL: PTools_getCachedQrySQLStmtsByDays]
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
ClassMethod getCachedQrySQLStmtsByDays(days As %Integer = 0, clearData As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1) As %Integer [ SqlName = PTools_getCachedQrySQLStmtsByDays, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getCachedQrySQLStmtsByDays^%SYS.PTools2(days,clearData,skipInsStmts,display)
}

/// Get the SQL Statements from all Cached Queries provided in the 'items' array
/// <p class="info-head">
/// Method:       getCachedQrySQLStmtsByClass [SQL: PTools_getCachedQrySQLStmtsByClass
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
ClassMethod getCachedQrySQLStmtsByClass(ByRef items As %RawString, clearData As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1) As %Integer [ SqlName = PTools_getCachedQrySQLStmtsByClass, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getCachedQrySQLStmtsByClass^%SYS.PTools2(.items,clearData,skipInsStmts,display)
}

/// Get the SQL Statements from all of the Class Methods
/// <p class="section-head">
/// <b>                      C L A S S   M E T H O D S                            </b>
///                          -------------------------
///  Gather SQL Statements from all of the Class Methods within InterSystems IRIS 
///  and add them to the <class>%SYS.PTools.UtilSQLStatements</class> class for Index Analysis 
///  and additional processing...
/// </p>
/// 
/// <p class="info-head">
/// Method:       getAllClassMethSQLStmts [SQL: PTools_getAllClassMethSQLStmts]
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
ClassMethod getAllClassMethSQLStmts(clearData As %Integer = 1, skipSysClass As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1) As %Integer [ SqlName = PTools_getAllClassMethSQLStmts, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getAllClassMethSQLStmts^%SYS.PTools2(clearData,skipSysClass,skipInsStmts,display)
}

/// Get the SQL Statements from all Class Methods provided in the 'items' array
/// <p class="info-head">
/// Method:       getClassMethSQLStmtsByClass [SQL: PTools_getClassMethSQLStmtsByClass]
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
ClassMethod getClassMethSQLStmtsByClass(ByRef items As %RawString, clearData As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1) As %Integer [ SqlName = PTools_getClassMethSQLStmtsByClass, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getClassMethSQLStmtsByClass^%SYS.PTools2(.items,clearData,skipInsStmts,display)
}

/// Get the SQL Statements from all of the Class Queries
/// <p class="section-head">
/// <b>                      C L A S S   Q U E R Y                                </b>
///                          ---------------------
///  Gather SQL Statements from all of the Class Queries within InterSystems IRIS 
///  and add them to the <class>%SYS.PTools.UtilSQLStatements</class> class for Index Analysis 
///  and additional processing...
/// </p>
/// 
/// <p class="info-head">
/// Method:       getAllClassQrySQLStmts [SQL: PTools_getAllClassQrySQLStmts]
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
ClassMethod getAllClassQrySQLStmts(clearData As %Integer = 1, skipSysClass As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1) As %Integer [ SqlName = PTools_getAllClassQrySQLStmts, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getAllClassQrySQLStmts^%SYS.PTools2(clearData,skipSysClass,skipInsStmts,display)
}

/// Get the SQL Statements from all Class Queries provided in the 'items' array
/// <p class="info-head">
/// Method:       getClassQrySQLStmtsByClass [SQL: PTools_getClassQrySQLStmtsByClass]
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
ClassMethod getClassQrySQLStmtsByClass(ByRef items As %RawString, clearData As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1) As %Integer [ SqlName = PTools_getClassQrySQLStmtsByClass, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getClassQrySQLStmtsByClass^%SYS.PTools2(.items,clearData,skipInsStmts,display)
}

/// Get the Embedded SQL Statements from all of the MAC Routines
/// <p class="section-head">
/// <b>                      R O U T I N E   Q U E R Y                            </b>
///                          -------------------------
///  Gather SQL Statements from all of the MAC Routines within InterSystems IRIS 
///  and add them to the <class>%SYS.PTools.UtilSQLStatements</class> class for Index Analysis 
///  and additional processing...
/// </p>
/// 
/// <p class="info-head">
/// Method:       getAllRtnQrySQLStmts [SQL: PTools_getAllRtnQrySQLStmts]
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
ClassMethod getAllRtnQrySQLStmts(clearData As %Integer = 1, skipSysRtn As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1) As %Integer [ SqlName = PTools_getAllRtnQrySQLStmts, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getAllRtnQrySQLStmts^%SYS.PTools2(clearData,skipSysRtn,skipInsStmts,display)
}

/// Get the Embedded SQL Statements from all of the MAC Routines provided in the 'items' array
/// <p class="info-head">
/// Method:       getRtnQrySQLStmtsByRtn [SQL: PTools_getRtnQrySQLStmtsByRtn]
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
ClassMethod getRtnQrySQLStmtsByRtn(ByRef items As %RawString, clearData As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1) As %Integer [ SqlName = PTools_getRtnQrySQLStmtsByRtn, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getRtnQrySQLStmtsByRtn^%SYS.PTools2(.items,clearData,skipInsStmts,display)
}

/// Get SQL Indexes from all classes
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
/// Method:       getAllIndices [SQL: PTools_getAllIndices]
/// Replaces:     N/A  [AllIndices^%SYS.PToolsDEP]
/// Status:       New Functionality
/// Purpose:      This method processes all of the classes/tables on the system
///               and collects all of the defined Indexes and adds them to
///               the <class>%SYS.PTools.UtilSQLAnalysisDB</class> class for
///               future processing...
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: $SYSTEM.SQL.PTools.getAllIndices(...)
///                           SQL: CALL %SYSTEM_SQL.PTools_getAllIndices(...)
///                                SELECT %SYSTEM_SQL.PTools_getAllIndices(...)
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
ClassMethod getAllIndices(clearData As %Integer = 1, skipSysClass As %Integer = 1, skipIDKeys As %Integer = 1, display As %Integer = 1) As %Integer [ SqlName = PTools_getAllIndices, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$getAllIndices^%SYS.PTools2(clearData,skipSysClass,skipIDKeys,display)
}

/// Generate a ShowPlan for each query and keep a count of how many times each index is used by each query
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
/// Method:       indexUsage [SQL: PTools_indexUsage]
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
///                  ObjectScript: $SYSTEM.SQL.PTools.indexUsage(...)
///                           SQL: CALL %SYSTEM_SQL.PTools_indexUsage(...)
///                                SELECT %SYSTEM_SQL.PTools_indexUsage(...)
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
ClassMethod indexUsage(clearData As %Integer = 1, getIndices As %Integer = 0, getSQLStmts As %Integer = 0, skipSysObj As %Integer = 1, skipIDKeys As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1, ByRef ptInfo As %RawString) As %Status [ SqlName = PTools_indexUsage, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!
	
	QUIT $$indexUsage^%SYS.PTools2(clearData,getIndices,getSQLStmts,skipSysObj,skipIDKeys,skipInsStmts,display,.ptInfo)
}

/// Identify all queries that perform a table scan
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
/// Method:       tableScans [SQL: PTools_tableScans]
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
///                  ObjectScript: $SYSTEM.SQL.PTools.tableScans(...)
///                           SQL: CALL %SYSTEM_SQL.PTools_tableScans(...)
///                                SELECT %SYSTEM_SQL.PTools_tableScans(...)
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
///    
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod tableScans(clearData As %Integer = 1, getSQLStmts As %Integer = 0, skipSysObj As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1, ByRef ptInfo As %RawString) As %Status [ SqlName = PTools_tableScans, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$tableScans^%SYS.PTools2(clearData,getSQLStmts,skipSysObj,skipInsStmts,display,.ptInfo)
}

/// Identify all queries that build a Temp Index/Table
/// <p class="section-head">
/// <b>           Q U E R I E S   W I T H   T E M P   I N D I C E S               </b>
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
/// Method:       tempIndices [SQL: PTools_tempIndices]
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
///                  ObjectScript: $SYSTEM.SQL.PTools.tempIndices(...)
///                           SQL: CALL %SYSTEM_SQL.PTools_tempIndices(...)
///                                SELECT %SYSTEM_SQL.PTools_tempIndices(...)
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
///    
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod tempIndices(clearData As %Integer = 1, getSQLStmts As %Integer = 0, skipSysObj As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1, ByRef ptInfo As %RawString) As %Status [ SqlName = PTools_tempIndices, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$tempIndices^%SYS.PTools2(clearData,getSQLStmts,skipSysObj,skipInsStmts,display,.ptInfo)
}

/// Identify all queries that perform a JOIN between tables, where their joined-fields use an index that supports the join
/// <p class="section-head">
/// <b>   Q U E R I E S   W I T H   M I S S I N G   J O I N   I N D I C E S       </b>
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
/// Method:       joinIndices [SQL: PTools_joinIndices]
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
///                  ObjectScript: $SYSTEM.SQL.PTools.joinIndices(...)
///                           SQL: CALL %SYSTEM_SQL.PTools_joinIndices(...)
///                                SELECT %SYSTEM_SQL.PTools_joinIndices(...)
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
ClassMethod joinIndices(clearData As %Integer = 1, getSQLStmts As %Integer = 0, skipSysObj As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1, ByRef ptInfo As %RawString) As %Status [ SqlName = PTools_joinIndices, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$joinIndices^%SYS.PTools2(clearData,getSQLStmts,skipSysObj,skipInsStmts,display,.ptInfo)
}

/// Identify all queries that have outliers, and determines if there is an index defined to support the Outlier Condition
/// <p class="section-head">
/// <b> Q U E R I E S   W I T H   M I S S I N G   O U T L I E R   I N D I C E S   </b>
///     -----------------------------------------------------------------------
/// For each of the SQL Statements saved in the <class>%SYS.PTools.UtilSQLStatements</class> class,
/// identify all queries that have outliers, and determines if there is an index 
/// defined to support that outlier.  It ranks the indices available to support
/// the outlier from 0 (no index present) to 4 (index fully supports the outlier). 
/// </p>
/// 
/// <p class="info-head">
/// Method:       outlierIndices [SQL: PTools_outlierIndices]
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
///                  ObjectScript: ##class(%SYSTEM.SQL.PTools).outlierIndices(...)
///                           SQL: CALL %SYSTEM_SQL.PTools_outlierIndices(...)
///                                SELECT %SYSTEM_SQL.PTools_outlierIndices(...)
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
ClassMethod outlierIndices(clearData As %Integer = 1, getSQLStmts As %Integer = 0, skipSysObj As %Integer = 1, skipInsStmts As %Integer = 1, display As %Integer = 1, ByRef ptInfo As %RawString) As %Status [ SqlName = PTools_outlierIndices, SqlProc ]
{
	if $ISOBJECT($g(%request)) { &html<<pre style="font-family: 'Courier New'; ">> }  // Provide HTML wrapper when invoked via the CALL Interface!

	QUIT $$outlierIndices^%SYS.PTools2(clearData,getSQLStmts,skipSysObj,skipInsStmts,display,.ptInfo)
}

/// Get the specific information requested about an Index Analyzer Method
/// <p class="info-head">
/// Method:       getIndexFlagInfo [SQL: PTools_getIndexFlagInfo]
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
ClassMethod getIndexFlagInfo(flagInt As %Integer = "", indexMeth As %String = "", returnInfo As %Integer = 3) As %String [ SqlName = PTools_getIndexFlagInfo, SqlProc ]
{
	QUIT $$getIndexFlagInfo^%SYS.PTools2(flagInt,indexMeth,returnInfo)
}

/// Export all of the SQL Statements data
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
/// Method:       exportSQLStatements [SQL: PTools_exportSQLStatements]
/// Replaces:     exportSQLUtilStmts [SQL: PT_exportSQLUtilStmts]  (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      Create a file containing all the data from the 
///               <class>%SYS.PTools.UtilSQLStatements</class> class & return the output 
///               location...
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: $SYSTEM.SQL.PTools.exportSQLStatements(...)
///                           SQL: CALL %SYSTEM_SQL.PTools_exportSQLStatements(...)
///                                SELECT %SYSTEM_SQL.PTools_exportSQLStatements(...)
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
///               set tSC=$SYSTEM.SQL.PTools.exportSQLStatements($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYSTEM_SQL.PTools_exportSQLStatements('$IO','H')
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
ClassMethod exportSQLStatements(file As %String = "", format As %String = "", silent As %Integer = 0, type As %String = "", ByRef conds As %RawString, ByRef ptInfo As %RawString) As %Status [ SqlName = PTools_exportSQLStatements, SqlProc ]
{
	QUIT $$exportUtilSQLStatements^%SYS.PTools2(.file,.format,silent,type,.conds,.ptInfo)
}

/// Export all of the SQL Analysis data
/// <p class="info-head">
/// Method:       exportSQLAnalysisDB [SQL: PTools_exportSQLAnalysisDB]
/// Replaces:     exportSQLUtilStmts [SQL: PT_exportSQLUtilStmts]  (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      Create a file containing all the data from the 
///               <class>%SYS.PTools.UtilSQLAnalysisDB</class> class & return the
///               output location...
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: $SYSTEM.SQL.PTools.exportSQLAnalysisDB(...)
///                           SQL: CALL %SYS_PTools.PTools_exportSQLAnalysisDB(...)
///                                SELECT %SYS_PTools.PTools_exportSQLAnalysisDB(...)
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
///               set tSC=$SYSTEM.SQL.PTools.exportSQLAnalysisDB($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYS_PTools.PTools_exportSQLAnalysisDB('$IO','H')
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
ClassMethod exportSQLAnalysisDB(file As %String = "", format As %String = "", silent As %Integer = 0, option As %String = "", ByRef conds As %RawString, ByRef ptInfo As %RawString) As %Status [ SqlName = PTools_exportSQLAnalysisDB, SqlProc ]
{
	QUIT $$exportUtilSQLAnalysisDB^%SYS.PTools2(.file,.format,silent,option,.conds,.ptInfo)
}

/// Export all of the data from joining both the SQL Statements & SQL Analysis tables
/// <p class="info-head">
/// Method:       exportSQLAnalysis [SQL: PTools_exportSQLAnalysis]
/// Replaces:     exportSQLUtilities [SQL: PT_exportSQLUtilities]  (<class>%SYS.PTools.SQLUtilities</class>)  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      Create a file containing all the data from joining both the 
///               <class>%SYS.PTools.UtilSQLStatements</class> and <class>%SYS.PTools.UtilSQLAnalysisDB</class> 
///               classes & return the output location...
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: $SYSTEM.SQL.PTools.exportSQLAnalysis(...)
///                           SQL: CALL %SYS_PTools.PTools_exportSQLAnalysis(...)
///                                SELECT %SYS_PTools.PTools_exportSQLAnalysis(...)
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
///               set tSC=$SYSTEM.SQL.PTools.exportSQLAnalysis($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYS_PTools.PTools_exportSQLAnalysis('$IO','H')
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
ClassMethod exportSQLAnalysis(file As %String = "", format As %String = "", silent As %Integer = 0, type As %String = "", option As %String = "", ByRef conds As %RawString, includeSQL As %Integer = 1, ByRef ptInfo As %RawString) As %Status [ SqlName = PTools_exportSQLAnalysis, SqlProc ]
{
	QUIT $$exportUtilSQLAnalysis^%SYS.PTools2(.file,.format,silent,type,option,.conds,includeSQL,.ptInfo)
}

/// Export all of the analysis data from the invocation of the 'indexUsage(...)' method
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
/// Method:       exportIUAnalysis [SQL: PTools_exportIUAnalysis]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Create a file containing all the data from joining both the 
///               <class>%SYS.PTools.UtilSQLStatements</class> and <class>%SYS.PTools.UtilSQLAnalysisDB</class> 
///               classes & return the output location...
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: $SYSTEM.SQL.PTools.exportIUAnalysis(...)
///                           SQL: CALL %SYSTEM_SQL.PTools_exportIUAnalysis(...)
///                                SELECT %SYSTEM_SQL.PTools_exportIUAnalysis(...)
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
///               set tSC=$SYSTEM.SQL.PTools.exportIUAnalysis($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYSTEM_SQL.PTools_exportIUAnalysis('$IO','H')
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
ClassMethod exportIUAnalysis(file As %String = "", format As %String = "", silent As %Integer = 0, p4 As %String = "", orderBy As %String = "", ByRef conds As %RawString, ByRef ptInfo As %RawString) As %Status [ SqlName = PTools_exportIUAnalysis, SqlProc ]
{
	QUIT $$exportIUAnalysis^%SYS.PTools2(.file,.format,silent,p4,orderBy,.conds,.ptInfo)
}

/// Export all of the analysis data from the invocation of the 'tableScans(...)' method
/// <p class="info-head">
/// Method:       exportTSAnalysis [SQL: PTools_exportTSAnalysis]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Create a file containing all the data from joining both the 
///               <class>%SYS.PTools.UtilSQLStatements</class> and <class>%SYS.PTools.UtilSQLAnalysisDB</class> 
///               classes & return the output location...
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: $SYSTEM.SQL.PTools.exportTSAnalysis(...)
///                           SQL: CALL %SYS_PTools.PTools_exportTSAnalysis(...)
///                                SELECT %SYS_PTools.PTools_exportTSAnalysis(...)
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
///               set tSC=$SYSTEM.SQL.PTools.exportTSAnalysis($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYS_PTools.PTools_exportTSAnalysis('$IO','H')
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
ClassMethod exportTSAnalysis(file As %String = "", format As %String = "", silent As %Integer = 0, type As %String = "", orderBy As %String = "", ByRef conds As %RawString, includeSQL As %Integer = 1, ByRef ptInfo As %RawString) As %Status [ SqlName = PTools_exportTSAnalysis, SqlProc ]
{
	QUIT $$exportTSAnalysis^%SYS.PTools2(.file,.format,silent,type,orderBy,.conds,includeSQL,.ptInfo)
}

/// Export all of the analysis data from the invocation of the 'tempIndices(...)' method
/// <p class="info-head">
/// Method:       exportTIAnalysis [SQL: PTools_exportTIAnalysis]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Create a file containing all the data from joining both the 
///               <class>%SYS.PTools.UtilSQLStatements</class> and <class>%SYS.PTools.UtilSQLAnalysisDB</class> 
///               classes & return the output location...
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: $SYSTEM.SQL.PTools.exportTIAnalysis(...)
///                           SQL: CALL %SYSTEM_SQL.PTools_exportTIAnalysis(...)
///                                SELECT %SYSTEM_SQL.PTools_exportTIAnalysis(...)
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
///               set tSC=$SYSTEM.SQL.PTools.exportTIAnalysis($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYSTEM_SQL.PTools_exportTIAnalysis('$IO','H')
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
ClassMethod exportTIAnalysis(file As %String = "", format As %String = "", silent As %Integer = 0, type As %String = "", orderBy As %String = "", ByRef conds As %RawString, includeSQL As %Integer = 1, ByRef ptInfo As %RawString) As %Status [ SqlName = PTools_exportTIAnalysis, SqlProc ]
{
	QUIT $$exportTIAnalysis^%SYS.PTools2(.file,.format,silent,type,orderBy,.conds,includeSQL,.ptInfo)
}

/// Export all of the analysis data from the invocation of the 'joinIndices(...)' method
/// <p class="info-head">
/// Method:       exportJIAnalysis [SQL: PTools_exportJIAnalysis]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Create a file containing all the data from joining both the 
///               <class>%SYS.PTools.UtilSQLStatements</class> and <class>%SYS.PTools.UtilSQLAnalysisDB</class> 
///               classes & return the output location...
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: $SYSTEM.SQL.PTools.exportJIAnalysis(...)
///                           SQL: CALL %SYSTEM_SQL.PTools_exportJIAnalysis(...)
///                                SELECT %SYSTEM_SQL.PTools_exportJIAnalysis(...)
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
///               set tSC=$SYSTEM.SQL.PTools.exportJIAnalysis($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYSTEM_SQL.PTools_exportJIAnalysis('$IO','H')
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
ClassMethod exportJIAnalysis(file As %String = "", format As %String = "", silent As %Integer = 0, type As %String = "", orderBy As %String = "", ByRef conds As %RawString, includeSQL As %Integer = 1, skipJIF4 As %Integer = 1, indxFlgInfo As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PTools_exportJIAnalysis, SqlProc ]
{
	QUIT $$exportJIAnalysis^%SYS.PTools2(.file,.format,silent,type,orderBy,.conds,includeSQL,skipJIF4,indxFlgInfo,.ptInfo)
}

/// Export all of the analysis data from the invocation of the 'outlierIndices(...)' method
/// <p class="info-head">
/// Method:       exportOIAnalysis [SQL: PTools_exportOIAnalysis]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Create a file containing all the data from joining both the 
///               <class>%SYS.PTools.UtilSQLStatements</class> and <class>%SYS.PTools.UtilSQLAnalysisDB</class> 
///               classes & return the output location...
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: $SYSTEM.SQL.PTools.exportOIAnalysis(...)
///                           SQL: CALL %SYSTEM_SQL.PTools_exportOIAnalysis(...)
///                                SELECT %SYSTEM_SQL.PTools_exportOIAnalysis(...)
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
///               set tSC=$SYSTEM.SQL.PTools.exportOIAnalysis($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYSTEM_SQL.PTools_exportOIAnalysis('$IO','H')
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
ClassMethod exportOIAnalysis(file As %String = "", format As %String = "", silent As %Integer = 0, type As %String = "", orderBy As %String = "", ByRef conds As %RawString, includeSQL As %Integer = 1, skipOIF4 As %Integer = 1, indxFlgInfo As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PTools_exportOIAnalysis, SqlProc ]
{
	QUIT $$exportOIAnalysis^%SYS.PTools2(.file,.format,silent,type,orderBy,.conds,includeSQL,skipOIF4,indxFlgInfo,.ptInfo)
}

/// Delete all of the SQL Statements data stored in the '%SYS.PTools.UtilSQLStatements' class
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
/// Method:       clearSQLStatements [SQL: PTools_clearSQLStatements]
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
///                  ObjectScript: $SYSTEM.SQL.PTools.clearSQLStatements(...)
///                           SQL: CALL %SYSTEM_SQL.PTools_clearSQLStatements(...)
///                                SELECT %SYSTEM_SQL.PTools_clearSQLStatements(...)
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
///               set status=$SYSTEM.SQL.PTools.clearSQLStatements()
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
ClassMethod clearSQLStatements(ns As %String = "", clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PTools_clearSQLStatements, SqlProc ]
{
	QUIT $$clearSQLStatements^%SYS.PTools2(ns,clearErrs,returnType,.ptInfo)
}

/// Delete all of the SQL Index Usage Analytical data stored in the '%SYS.PTools.UtilSQLAnalysisDB' class
/// <p class="info-head">
/// Method:       clearSQLAnalysisDB [SQL: PTools_clearSQLAnalysisDB]
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
///                  ObjectScript: $SYSTEM.SQL.PTools.clearSQLAnalysisDB(...)
///                           SQL: CALL %SYSTEM_SQL.PTools_clearSQLAnalysisDB(...)
///                                SELECT %SYSTEM_SQL.PTools_clearSQLAnalysisDB(...)
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
///               set status=$SYSTEM.SQL.PTools.clearSQLAnalysisDB()
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
ClassMethod clearSQLAnalysisDB(ns As %String = "", clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PTools_clearSQLAnalysisDB, SqlProc ]
{
	QUIT $$clearSQLAnalysisDB^%SYS.PTools2(ns,clearErrs,returnType,.ptInfo)
}

/// <p class="info-head">
/// Method:       versionSQLAnalysis [SQL: PTools_versionSQLAnalysis]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      Get the current version for the <class>%SYS.PTools.UtilSQLStatements</class> &
///               <class>%SYS.PTools.UtilSQLAnalysisDB</class> classes/sections of the 
///               Performance Tools (PTools) Application...
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: $SYSTEM.SQL.PTools.versionSQLAnalysis(...)
///                           SQL: SELECT %SYSTEM_SQL.PTools_versionSQLAnalysis(...)
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Display the UtilSQLAnalysis version to the screen via an 
///               InterSystems IRIS Terminal:
/// 
///               write $SYSTEM.SQL.PTools.versionSQLAnalysis()   // Simple Version
///               write $SYSTEM.SQL.PTools.versionSQLAnalysis(1)  // Full Version
/// 
///    #2         Display the UtilSQLAnalysis version via the SQL Query Page of the
///               Management Portal:
/// 
///               SELECT %SYSTEM_SQL.PTools_versionSQLAnalysis()   /* Simple Version */
///               SELECT %SYSTEM_SQL.PTools_versionSQLAnalysis(1)  /* Full Version */
/// 
/// Data Storage: N/A
/// 
/// Parameters:
///    fullVer      - 0 = Display the UtilSQLAnalysis Simple Version  [DEFAULT]
///                   1 = Display the UtilSQLAnalysis Full Version
///    
/// RETURN Value: The UtilSQLAnalysis {Simple | Full} Version
/// </p>
ClassMethod versionSQLAnalysis(fullVer = 0) As %String [ SqlName = PTools_versionSQLAnalysis, SqlProc ]
{
	QUIT ##class(%SYS.PTools.UtilSQLAnalysis).version(fullVer)
}

}
