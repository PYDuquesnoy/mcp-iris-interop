/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %SYS.PTools.Stats

/// <style type="text/css"> 
///    DEP { color: red; font-weight: bold; }
///    BC { color: green; font-weight: bold; }
///    PROP { display: block; white-space: pre; font-size: 16px; font-family: monospace; }
///    .dep-head { color: red; white-space: pre; font-family:  'Courier New'; }
///    .info-head { white-space: pre; font-family: 'Courier New'; }
/// </style>
/// 
/// <p class="dep-head">
/// <b> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </b>
/// 
/// Starting with ver '2.0' of the PTools application, this class is considered
/// to be DEPRECATED and is replaced by the <class>%SYS.PTools.UtilSQLAnalysisDB</class> class.
/// 
/// <b> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </b>
/// ------------------------------------------------------------------------------
/// </p>
/// 
/// <p class="info-head">
/// Class:        %SYS.PTools.SQLUtilResults
/// Replaced By:  <class>%SYS.PTools.UtilSQLAnalysisDB</class>
/// Purpose:      
///    This class is used by the following methods to store the SQL Analysis
///    details collected against the SQL Statements stored in the 
///    <class>%SYS.PTools.SQLUtilities</class> class:
///       - IndexUsage()
///       - TableScans()
///       - TempIndices()
///       - JoinIndices()
///    
/// Data Storage:  ^%sqlcq("SAMPLES","PTools","Utils","Results","{C|D|I|S}")
/// Error Storage: ^%sqlcq($NAMESPACE,"PTools","Error"[...])=$LIST Info
/// </p>
Class %SYS.PTools.SQLUtilResults Extends %Persistent [ Deprecated, System = 4 ]
{

/// <PROP>
/// 1st piece of the IDKey
/// 
/// The value for this property indicates the SQL Statement Analysis Method producinc the result row:
///     IndexUsage()        => 'IU'
///     TableScans()        => 'TS'
///     TempIndices()       => 'TI'
///     JoinIndices()       => 'JI'
///     OutlierIndices()    => 'OI'
/// </PROP>
Property OptionName As %String(VALUELIST = ",IU,TS,TI,JI,OI,");

/// <PROP>
/// 2nd piece of the IDKey
/// 
/// A unique ID counter which comprises the data row's IDKey
/// </PROP>
Property Counter As %Integer [ InitialExpression = {$I(^%sqlcq($NAMESPACE,"PTools","Utils","Results","D"))} ];

/// <PROP>
/// Set in the following methods: tableScans(), tempIndices(), joinIndices(), outlierIndices()
/// 
/// Reference to the %SYS.PTools.SQLUtilities class which is a pointer back to the SQL Statement
/// </PROP>
Property SQLPointer As %SYS.PTools.SQLUtilities;

/// The schema of the table being queried in the SQL Statement
Property SchemaName As %String;

/// The table being queried in the SQL Statement
Property TableName As %String;

/// Set by the TableScan class method
/// Name of the Module that is doing the Table Scan
Property ModuleName As %String;

/// <PROP>
/// Set by the follow methods: tableScans(), tempIndices(), joinIndices(), outlierIndices()
/// 
/// One of the following Map Types: { "master map " | "extent bitmap " | "bitmap index " | "index map " }
/// </PROP>
Property MapType As %String;

/// <PROP>
/// Set by the follow methods: tableScans(), tempIndices(), joinIndices(), outlierIndices()
/// 
/// The Number of Rows in the Table Based on TuneTable Data or set by the user
Property ExtentSize As %Integer;

/// <PROP>
/// The approximate numbers of map blocks used by each SQL map
///    NOTE: The size of all SQL map blocks is 2048 bytes (2K bytes).
/// </PROP>
Property BlockCount As %Integer;

Property IndexName As %String;

/// Used by both IndexUsage() and TempIndices() class methods
/// Number of times the index was used in the sql.
Property UsageCount As %Integer;

/// $LISTBUILD of the Properties that will make up the Subscripts of the {IndexName}
/// Every Index will have ID as the final subscript
Property IndexFields As list Of %String;

/// $LISTBUILD of the Properties that will be the data node of the {IndexName}
/// The extra data is stored as part of the index to avoid reading from the Data Map
Property DataValues As list Of %String;

/// <PROP>
/// Set by joinIndices() method to one of the following values:
/// 
/// Flag has 4 values:
/// 0 - No index to support the JOIN
/// 1 - There is an index to support the join but it is not an exact match, the first index field is not part of the join.
/// 2 - There is an index to support the join and all of its fields, but it is not an exact match, the first index field is part of the join.
/// 3 - There is an index to support the join and all of its fields, but it is not an exact match, the first index field is start of all the join fields.
/// 4 - Index fully supports the join, this is not included in the table as there is nothing to improve.
/// </PROP>
Property JoinIndexFlag As %Integer;

Index Master On (OptionName, Counter) [ IdKey ];

/// <p class="info-head">
/// Method:       exportSQLUtilStmtRslts [SQL: PT_exportSQLUtilStmtRslts]
/// Replaced By:  exportUtilSQLAnalysisDB [SQL: PT_exportUtilSQLAnalysisDB]  (<class>%SYS.PTools.UtilSQLAnalysis</class>)
/// Purpose:      Create a file containing all the data from the 
///               <class>%SYS.PTools.SQLUtilResults</class> class & return the
///               output location...
/// Status:       New Functionality
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLUtilResults).exportSQLUtilStmtRslts(...)
///                    SQL: CALL %SYS_PTools.PT_exportSQLUtilStmtRslts(...)
///                         SELECT %SYS_PTools.PT_exportSQLUtilStmtRslts(...)
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
///               set tSC=##class(%SYS.PTools.SQLUtilResults).exportSQLUtilStmtRslts($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYS_PTools.PT_exportSQLUtilStmtRslts('$IO','H')
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
///               %SYS.PTools.SQLUtilResults class:  (e.g. C:\exportFile.txt) 
///               NOTE:    $IO = Outputs the data to the screen
///                      '$IO' = Output the data to the current device when invoked from the CALL/SELECT-interface
///                     '$DEF' = Ouput the data to the DEFAULT file when invoked from the CALL/SELECT-interface
///                  [DEFAULT: {Current-Directory}\PT_exportSQLUtilStmtRslts_YYYYMMDD_HHMMSS.{ext}]
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
///   option    -  A single option, or a comma-delimited list of {OptionName} values
///                to restrict the output of rows from the '%SYS.PTools.SQLUtilResults'
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
ClassMethod exportSQLUtilStmtRslts(file As %String = "", format As %String = "", silent As %Integer = 0, option As %String = "", ByRef conds As %RawString, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_exportSQLUtilStmtRslts, SqlProc ]
{
	QUIT $$exportSQLUtilStmtRslts^%SYS.PToolsDEP(.file,.format,silent,option,.conds,.ptInfo)
}

/// Provide the current version for the SQLUtilResults class/section of the Performance Tools (PTools) Application
ClassMethod version() As %String [ SqlName = SQLUtilResults_version, SqlProc ]
{
	QUIT $$$SQLUtilRsltsVersion		//MRP878 - First Implementation of Versioning
}

Trigger OnDelete [ Event = DELETE, Time = AFTER ]
{
    #; --- If no more data rows exist, delete the ID Counter global ---
    if '$$$existsSYSPToolsSQLUtilRsltsData { 
    	$$$killSYSPToolsSQLUtilRsltsData 
    }
}

Storage Default
{
<CounterLocation>^%sqlcq($NAMESPACE,"PTools","Utils","Results","C")</CounterLocation>
<Data name="SQLUtilResultsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>SQLPointer</Value>
</Value>
<Value name="3">
<Value>SchemaName</Value>
</Value>
<Value name="4">
<Value>TableName</Value>
</Value>
<Value name="5">
<Value>ModuleName</Value>
</Value>
<Value name="6">
<Value>MapType</Value>
</Value>
<Value name="7">
<Value>ExtentSize</Value>
</Value>
<Value name="8">
<Value>BlockCount</Value>
</Value>
<Value name="9">
<Value>IndexName</Value>
</Value>
<Value name="10">
<Value>UsageCount</Value>
</Value>
<Value name="11">
<Value>IndexFields</Value>
</Value>
<Value name="12">
<Value>DataValues</Value>
</Value>
<Value name="13">
<Value>JoinIndexFlag</Value>
</Value>
</Data>
<DataLocation>^%sqlcq($NAMESPACE,"PTools","Utils","Results","D")</DataLocation>
<DefaultData>SQLUtilResultsDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%sqlcq($NAMESPACE,"PTools","Utils","Results","D")</IdLocation>
<IndexLocation>^%sqlcq($NAMESPACE,"PTools","Utils","Results","I")</IndexLocation>
<StreamLocation>^%sqlcq($NAMESPACE,"PTools","Utils","Results","S")</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
