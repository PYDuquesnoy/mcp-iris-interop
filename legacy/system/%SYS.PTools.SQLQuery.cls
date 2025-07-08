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
/// Class:        %SYS.PTools.SQLQuery
/// Replaced By:  <class>%SYS.PTools.StatsSQL</class>
/// Purpose:      
///    This is the parent class of <class>%SYS.PTools.SQLStats</class>.  
///    This class is used to store the the following general info of a query from 
///    compile time: 
///       <property>QueryText</property>, <property>QueryType</property>, <property>CursorName</property>, <property>RoutineName</property>, & <property>NameSpace</property>.
/// 
///    All of the run time data is stored in the <class>%SYS.PTools.SQLStats</class> class.
///    Error information is stored in the following error global:
/// 
///       ^%sqlcq(NAMESPACE,"PTools","Error",[...])=$LIST Info
/// </p>
Class %SYS.PTools.SQLQuery Extends (%Persistent, %SYS.PTools.FileCreation) [ Deprecated, System = 4 ]
{

/// Store the first 15000 charactors of the SQL Query in this field.
Property QueryText As %String(COLLATION = "SQLUPPER(255)", MAXLEN = 30000, TRUNCATE = 1) [ Calculated, SqlComputeCode = {s {*}=$S($D($$$CQ("QueryText",$S({RoutineName}[".cls":$E({RoutineName},1,*-2),1:{RoutineName}))):$P($$$CQ("QueryText",$S({RoutineName}[".cls":$E({RoutineName},1,*-2),1:{RoutineName}),1),"~RUNTIME~",1),1:{InternalQueryText})}, SqlComputed ];

Property InternalQueryText As %String(MAXLEN = 30000, TRUNCATE = 1);

/// Is the Query an INSERT UPDATE DELETE or SELECT query
Property QueryType As %String;

/// What NameSpace the SQL was generated in
Property NameSpace As %String;

/// What Routine is the SQL generated in
Property RoutineName As %String;

/// What is the name of the cursor for this SQL Statement
Property CursorName As %String;

/// Number of Seconds it takes to compile the query
Property CompileTime As %Numeric;

/// hash the SQL so we can match incoming SQL with already stored Stats
Property Hash As %String(MAXLEN = 500);

/// Internal unique statement hash used as the ID for the SQL Statement Index
Property SQLIndexHash As %String(MAXLEN = 32);

/// ImportSchema is used in generated code to handle sql statements that have unqualified table names.
Property ImportSchema As %String;

/// Number of times this query has be executed
Property RunCount As %Integer [ InitialExpression = 0 ];

/// Do we have level 3 stats for this query
Property details As %Integer;

Relationship SQLStatsPointer As %SYS.PTools.SQLStats [ Cardinality = children, Inverse = SQLQueryPointer ];

Index master On (RoutineName, CursorName) [ IdKey, Unique ];

/// <p class="info-head">
/// <DEP> -- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED --- DEPRECATED -- </DEP>
/// Method:       Export [SQL: SQLQuery_Export]
/// Replaces By:  Export [SQL: StatsSQL_Export]  (<class>%SYS.PTools.StatsSQL</class>)
/// Status:       <BC>Maintained for Backward-Compatibility</BC>  See exportSQLQuery(...)
/// Purpose:      This method generates a comma delimited file containing the data
///               from the '%SYS.PTools.SQLQuery' class
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLQuery).Export(...)
///                    SQL: CALL %SYS_PTools.SQLQuery_Export(...)
///                         SELECT %SYS_PTools.SQLQuery_Export(...)
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
///               set io=##class(%SYS.PTools.SQLQuery).Export($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYS_PTools.SQLQuery_Export('$IO')
/// 
///               Where: '$IO' = Output to the current device
///                              NOTE: '$IO' can be omitted, as it is the default
///                                    'file' when invoked via the CALL interface
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","RunTime","SQLQuery{C|D|I|S|Z}")
/// 
/// Parameters:
///   file       - The path and file in which to create and store the data from the 
///                    %SYS_PTools.SQLQuery class/table:  (e.g. C:\exportFile.txt)
///                NOTE:    $IO = Outputs the data to the screen
///                       '$IO' = Output the data to the current device when invoked from the CALL/SELECT-interface
///                      '$DEF' = Ouput the data to the DEFAULT file when invoked from the CALL/SELECT-interface
///                   [DEFAULT: {MGR-Directory}\{computerName}_{ConfigName}_YYYYMMDD_HHMMSS_SQLQuery.psql]
///   delim      - The delimiter by which to delimit the data of the exported file
///                   [DEFAULT: $C(9)  // TAB]
///   exportPlan - 0 - Export the SQL Query Text [DEFAULT]
///                1 - Export the SQL Query Plan
/// 
/// RETURN Value: The output locations of the exported data; Otherwise, return  
///               the error status if one occurred
/// </p>
ClassMethod Export(file = "", delim = "", exportPlan = 0) As %String [ Deprecated, SqlName = SQLQuery_Export, SqlProc ]
{
	set:delim="" delim=$C(9)	// Tab-Delimited
	set logDir=$$$SYSMgrDir,hostName=$$$localHost,configName=$$$configurationName,hDate8=$zd($h,8),hTime=$tr($zt($p($h,",",2)),":","")
	set outputFileName=hostName_"_"_configName_"_"_hDate8_"_"_hTime_"_SQLQuery.psql"
 	set file=$s($$$UPPER(file)="$IO":$IO,(file="")&&$ISOBJECT($g(%request)):$IO,",$DEF,,"[(","_$$$UPPER(file)_","):$$$currentDir,1:file)
	set outputFile=$s(file="":logDir_outputFileName,1:file)
	if (outputFile=$IO)&&$ISOBJECT($g(%request)) { set format="H" }
	else { set format="Z",format(0)=delim }
	
	set tSC=..exportSQLQuery(outputFile,.format,1,exportPlan,,.ptInfo,"SQLQuery.Export")

	QUIT $s($$$ISERR(tSC):tSC,1:$g(ptInfo("outputFile")))
}

/// <p class="info-head">
/// Method:       exportSQLQuery [SQL: PT_exportSQLQuery]
/// Replaces:     Export [SQL: SQLQuery_Export]  <DEP>[DEPRECATED]</DEP>
/// Replaced By:  exportStatsSQL [SQL: PT_exportStatsSQL]  (<class>%SYS.PTools.StatsSQL</class>)
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      Create a Performance Tool file containing the data 
///               from the '%SYS.PTools.SQLQuery' and return the output location...
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
///                  ObjectScript: ##class(%SYS.PTools.SQLQuery).exportSQLQuery(...)
///                    SQL: CALL %SYS_PTools.PT_exportSQLQuery(...)
///                         SELECT %SYS_PTools.PT_exportSQLQuery(...)
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
///               set tSC=##class(%SYS.PTools.SQLQuery).exportSQLQuery($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYS_PTools.PT_exportSQLQuery('$IO','H')
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
///   file       - The path and file in which to create and store the data from the
///                %SYS_PTools.SQLQuery class:  (e.g. C:exportFile.txt)
///                NOTE:    $IO = Outputs the data to the screen
///                       '$IO' = Output the data to the current device when invoked from the CALL/SELECT-interface
///                      '$DEF' = Ouput the data to the DEFAULT file when invoked from the CALL/SELECT-interface
///                   [DEFAULT: {Current-Directory}\PT_SQLQuery_exportSQLQuery_YYYYMMDD_HHMMSS.{ext}]
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
///   silent     - 0 - Display all messages during the running of this method
///                1 - Don't display any messages during the running of this method
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
///   bcFlag     - This is a Backward-Compatibility flag used for 
///                [Internal Purposes ONLY]
/// 
/// RETURN Value: The status from the invocation of this method
/// </p>
ClassMethod exportSQLQuery(file = "", format = "P", silent = 0, exportPlan = 0, ByRef conds As %RawString, ByRef ptInfo As %RawString, bcFlag = "") As %Status [ PublicList = d, SqlName = PT_exportSQLQuery, SqlProc ]
{
 	new %plan,%msg,%objlasterror,%sqlcodegen
 	new d
 	
	set tSC=$$$OK,%msg="",SQLCODE="",outputFile=""
	set thisMethod="exportSQLQuery"
	set start=$$$sysTimestamp

 try {

	$$$setSQLStatsFlagOFF(zu115x12)	// Turn off SQLState for current JOB
	
 	set className="SQLQuery"
 	set version=$$$PTStatsVersion
	set format=$s(format="":$s($ISOBJECT($g(%request)):"H",1:"P"),("Pp"[$e(format,1))&&$ISOBJECT($g(%request)):"H"_$e(format,2,*),1:$$$UPPER($p(format,":",1))_$s(format[":":":"_$p(format,":",2,*),1:""))
	set ns=$NAMESPACE
	
	set outputFile=..getOutputFile(file,className,thisMethod,format,,.tSC) THROW:$$$ISERR(tSC)
 	
	if 'silent { USE 0 write !,"Creating '%SYS.PTools.SQLQuery' Export...",!,?3,"Output File: ",$s(outputFile="":"(Terminal IO)",1:outputFile),!! }

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
	set d(0,$i(d(0)))=$LB("RoutineName","Routine",30)
	set d(0,$i(d(0)))=$LB("CursorName","Cursor",10)
	set d(0,$i(d(0)))=$LB("RunCount",,8)
	set d(0,$i(d(0)))=$LB("QueryType",,10)
	set d(0,$i(d(0)))=$LB("QueryText",$s(exportPlan:"QueryPlan",1:"QueryText"),30)
	set d(2,"sort")=$LB("QueryType","QueryText")
	for col=1:1:d(0) { set dInfo=d(0,col),dHeader=$LG(dInfo,2) set:dHeader="" dHeader=$LG(dInfo,1) set d("x-heading",dHeader)=col }
	set tSC=..condsMatch(.conds,.d,.condValExp)
	
	&SQL(DECLARE statsCUR CURSOR FOR
	     SELECT ImportSchema, RoutineName, CursorName, RunCount, QueryType, QueryText
	     INTO :schema, :d(1,1), :d(1,2), :d(1,3), :d(1,4), :d(1,5)
	     FROM %SYS_PTools.SQLQuery
	     WHERE Namespace = :ns
	     ORDER BY QueryType, QueryText
	    )
	
	set tSC=..fileHeader(outputFile,.format,"",$CLASSNAME(),thisMethod,version,.d,bcFlag) THROW:$$$ISERR(tSC)
 
	set rowCnt=0
	&SQL(OPEN statsCUR)
	if SQLCODE<0 { set tSC=$$$ERROR($$$SQLError,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%apiSQL(SQLCODE))) THROW }
	
	FOR {
		&SQL(FETCH statsCUR)
		QUIT:SQLCODE'=0
		
		if condValExp'="" { // --- Check Condition(s) via the 'conds()' array ---
			try { if @condValExp { } else { CONTINUE } } catch { } // Check if condition(s) in 'conds()' array Succeeded/Failed
		}
		
		set query=d(1,5)
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
		
		kill sql,%plan set d(1,5)=""	// Tabula Rasa!
		set sql($i(sql))=query
		
		do:exportPlan ShowPlan^%apiSQL(.sql,1,"",0,"",schema,1,,,silent)
		
		if +$g(%plan)'=0 { for pos=1:1:%plan set d(1,5)=d(1,5)_%plan(pos)_"<br/>" }
		else { set d(1,5)=query_"<br/>" }
				
		set tSC=..fileBody(outputFile,.format,.d)
		
		set rowCnt=$I(rowCnt)	// Count Rows Processed!
 	}
	
 	set:SQLCODE<0 tSC=$$$ADDSC(tSC,$$$ERROR($$$SQLError,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%apiSQL(SQLCODE))))

	&sql(CLOSE statsCUR)
 	set:SQLCODE<0 tSC=$$$ADDSC(tSC,$$$ERROR($$$SQLError,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%apiSQL(SQLCODE))))
	
	THROW:$$$ISERR(tSC)
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
	
	if 'silent { USE 0 write ! do $system.Status.DisplayError(tSC) }
 }
 
 	set stop=$$$sysTimestamp
 	
 	do:$$$ISOK(tSC)&&(",SQLQuery.Export,SQLStats.ExportAll,"'[(","_bcFlag_",")) ..fileFooter(outputFile,.format,"End of stats collection for: ##class("_$CLASSNAME()_")."_thisMethod_"(...)",.d,stop-start,rowCnt)
 
 	if outputFile'="" {		// Return to Terminal IO & Close File
 		USE 0
 		CLOSE outputFile
 	}
 	
 	$$$resetSQLStatsFlag(zu115x12)		// Reset SQLStats flag for current JOB to original value

	set (file,ptInfo("outputFile"))=$s(outputFile="":$IO,1:##class(%Library.File).CanonicalFilename(outputFile))
 	set ptInfo("className")=$CLASSNAME(),ptInfo("methodName")=$g(thisMethod),ptInfo("rowCnt")=$g(rowCnt),ptInfo("totalTime")=$g(stop)-$g(start)
	
 	QUIT tSC
}

/// <p class="info-head">
/// Method:       clearSQLQuery [SQL: PT_clearSQLQuery]
/// Replaced BY:  N/A
/// Status:       New Functionality
/// Purpose:      Delete all of the data stored in the '%SYS.PTools.SQLQuery' 
///               class, based on the specified parameters...
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.SQLQuery).clearSQLQuery(...)
///                           SQL: CALL %SYS_PTools.PT_clearSQLQuery(...)
///                                SELECT %SYS_PTools.PT_clearSQLQuery(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Delete all of the data stored in the '%SYS.PTools.SQLQuery' 
///               class in the 'SAMPLES' namespace:
/// 
///               set stats=##class(%SYS.PTools.SQLQuery).clearSQLQuery("SAMPLES")
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","RunTime","SQLQuery{C|D|I|S|Z}")
/// 
/// Parameters:
///   ns          - The namespace in which to clear SQLQuery data
///                 If none provided, use the current namespaces where SQLQuery 
///                 data collected
///                    [DEFAULT: Current Namespace]
///   rtn         - The routine for which to clear SQLQuery data
///                 If none provided, clear all routines in the given 'ns'
///                    [OPTIONAL]
///   ph3         - Placeholder Parameter for future extensibility
///   clearErrs   - 0 = Don't delete the 'PTools' Application Errors
///                 1 = Delete all of the 'PTools' Application Errors
///                    [DEFAULT: 0]
///   returnType  - 0 = Return a %Status code of either $$$OK or $$$ERROR()
///                 1 = Return the number of Stats rows deleted from the 
///                     following class: %SYS.PTools.SQLQuery
///                    [DEFAULT: 0]
///   ptInfo      - A Pass By Reference information array that returns
///                 detailed information to the user in the following format:
///                    ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                 Where category = { "cnt" | "curr" | "term" | ... }
///                       variable = A var corresponding to the given 'category'
/// 
///                 Example:
///                    ptInfo("cnt","clearSQLQuery")=The number of rows deleted
///                                                  via this method [Routine Method]
///                    ptInfo("cnt","purgeSQLQuery")=The number of rows deleted
///                                                  via this method [Class Method]
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the number of Stats rows deleted from the following class; 
///               Otherwise, return an error message if an error occurred:
///                  %SYS.PTools.SQLQuery
/// </p>
ClassMethod clearSQLQuery(ns As %String = "", rtn As %String = "", ph3 As %Integer = 0, clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_clearSQLQuery, SqlProc ]
{
	QUIT $$clearSQLQuery^%SYS.PToolsDEP(ns,rtn,ph3,clearErrs,returnType,.ptInfo)
}

/// Entry Point providing new functionality to delete Backward-compatible data:
///    NOTE: See the <method>clearSQLQuery</method> method above for more details.
ClassMethod purgeSQLQuery(ns As %String = "", rtn As %String = "", ph3 As %Integer = 0, clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_purgeSQLQuery, SqlProc ]
{
	QUIT $$clearSQLQuery^%SYS.PToolsDEP(ns,rtn,ph3,clearErrs,returnType,.ptInfo)
}

/// Provide the current version for the %SYS.PTools.SQLQuery class/section of the Performance Tools (PTools) Application
ClassMethod version() As %String [ SqlName = SQLQuery_version, SqlProc ]
{
	QUIT $$$SQLQueryVersion		//MRP990 - Update Versioning
}

Storage Default
{
<CounterLocation>^%sqlcq($NAMESPACE,"PTools","RunTime","SQLQueryC")</CounterLocation>
<Data name="SQLQueryDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>InternalQueryText</Value>
</Value>
<Value name="3">
<Value>QueryType</Value>
</Value>
<Value name="4">
<Value>CompileTime</Value>
</Value>
<Value name="5">
<Value>Hash</Value>
</Value>
<Value name="6">
<Value>NameSpace</Value>
</Value>
<Value name="7">
<Value>RoutineName</Value>
</Value>
<Value name="8">
<Value>CursorName</Value>
</Value>
<Value name="9">
<Value>QueryText</Value>
</Value>
<Value name="10">
<Value>ImportSchema</Value>
</Value>
<Value name="11">
<Value>RunCount</Value>
</Value>
<Value name="12">
<Value>details</Value>
</Value>
<Value name="13">
<Value>SQLIndexHash</Value>
</Value>
</Data>
<DataLocation>^%sqlcq($NAMESPACE,"PTools","RunTime","SQLQueryD")</DataLocation>
<DefaultData>SQLQueryDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%sqlcq($NAMESPACE,"PTools","RunTime","SQLQueryD")</IdLocation>
<IndexLocation>^%sqlcq($NAMESPACE,"PTools","RunTime","SQLQueryI")</IndexLocation>
<StreamLocation>^%sqlcq($NAMESPACE,"PTools","RunTime","SQLQueryS")</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
