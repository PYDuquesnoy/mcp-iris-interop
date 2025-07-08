/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %SYS.PTools.Stats

/// <style type="text/css"> 
///    DEP { color: red; font-weight: bold; }
///    BC { color: green; font-weight: bold; }
///    PROP { display: block; white-space: pre; font-size: 16px; font-family: monospace; }
///    .dep-head { color: red; white-space: pre; font-family:  'Courier New'; }
///    .section-head { color: blue; white-space: pre; font-family:  'Courier New'; }
///    .info-head { white-space: pre; font-family: 'Courier New'; }
/// </style>
/// 
/// <p class="info-head">
/// Class:        %SYS.PTools.Stats
/// Replaces:     N/A
/// Purpose:      
///    This class is designed to gather performance statistics for any type of 
///    routine or code block.
/// 
///    The data for this class is stored in the following optimized global: 
///       ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
///  
///    By calling pairs of the Start() and Stop() methods we will record 
///    GlobalRef, commands executed, TimeSpent, and some additional process info 
///    for each code block.
/// 
///    You need to manually add the calls to the Start() and Stop() methods to 
///    your code.
/// 
///    Each method takes 3 parameters:
/// 
///       NS    - The namespace in which the stats collection is occurring
///       Rou   - The routine name for which the stats collection is occurring
///       Mod   - The module name for which the stats collection is occurring
///                  [DEFAULT: 1]
/// 
///    For example, when the following code is executed, the three entries will
///    be recorded into the %SYS_PTools.Stats table, one for each call to Stop().
/// 
/// 
/// <example>
///    Test ;
///       new ns
///       set ns=$NAMESPACE
///       if ns'="SAMPLES" new $NAMESPACE set $NAMESPACE="SAMPLES"  // Change to 'SAMPLES' NS
/// 
///       do ##class(%SYS.PTools.Stats).Start($NAMESPACE,"Test","Full_Module")
///       do ##class(%SYS.PTools.Stats).Start($NAMESPACE,"Test","Populate")
///     
///       do ##class(Sample.Person).Populate(100)
///     
///       do ##class(%SYS.PTools.Stats).Stop($NAMESPACE,"Test","Populate")
///       do ##class(%SYS.PTools.Stats).Start($NAMESPACE,"Test","PrintPersons")
///     
///       do ##class(Sample.Person).PrintPersons()
///     
///       do ##class(%SYS.PTools.Stats).Stop($NAMESPACE,"Test","PrintPersons")
///       do ##class(%SYS.PTools.Stats).Stop($NAMESPACE,"Test","Full_Module")
///    QUIT
/// 
/// </example>
/// </p>
Class %SYS.PTools.Stats Extends (%Persistent, %SYS.PTools.FileCreation) [ System = 4 ]
{

/// The NameSpace in which the Stats collection is being invoked
Property NameSpace As %String(MAXLEN = 2000) [ InitialExpression = {$NAMESPACE}, Required ];

/// The name of the routine in which the Stats collection is being invoked
Property RoutineName As %String(MAXLEN = 2000) [ Required ];

/// Placeholder (*) indicating that this is not a Cursor Name for an SQL Statement [Used in %SYS.PTools.StatsSQL]
Property CursorName As %String(MAXLEN = 2000) [ InitialExpression = "*", Required ];

/// <PROP>
/// This is a unique number that specifies the Stats Collection Group for each query run
/// The counter comes from bumping the following global: 
///    ^%sqlcq($NAMESPACE,"PTools","db","StatsZ","StatsGroup",0,{NameSpace},{RoutineName},{ModuleName})
///      USE: $$$bumpSYSPToolsStatsGroup({NameSpace},{RoutineName},{ModuleName})
/// </PROP>
Property StatsGroup As %Integer [ Required, SqlComputeCode = { Set {*} = $$$bumpSYSPToolsStatsGroup({NameSpace},{RoutineName},{ModuleName}) }, SqlComputed ];

/// <PROP>
/// Contains the NameSpace and Routine these stats are for
/// The format is NameSpace|RoutineName
/// 
/// This is not used in the %SYS.PTools.SQLStats class
/// </PROP>
Property RoutineInfo As %String(MAXLEN = 4000);

/// This is the name of the method within a given routine to be analyzed [DEFAULT: 1]
/// This name can be used to distinguish a block of code within a give routine
Property ModuleName As %String(MAXLEN = 2000) [ SqlColumnNumber = 6 ];

/// This is the number of times the query has been run since the last compile.
/// 
Property Counter As %Integer [ SqlColumnNumber = 5 ];

/// How many rows did the query return for this run
/// Used only by Sub class
Property RowCount As %Integer [ SqlColumnNumber = 7 ];

/// The number globals that were referenced in this Module for the given query
/// The Modules are nested and the count for the outer ones is cumulative
Property GlobalRefs As %Integer [ SqlColumnNumber = 8 ];

/// The number of ObjectScript commands that were executed in this Module for the given query
/// The Modules are nested and the count for the outer ones is cumulative
Property CommandsExecuted As %Integer [ SqlColumnNumber = 9 ];

/// *** DEPRECATED via MRP1300 as of 05/30/2022 ***
/// The 'LinesOfCode' property has been deprecated and replaced by the 'CommandsExecuted'
/// property, but is left here for backwards compatibility and returns the 'CommandsExecuted' value.
/// At some point in the future this property will be removed from the product, so users 
/// should not rely on its availability going forward and should use the 'CommandsExecuted'
/// property instead.
Property LinesOfCode As %Integer [ Deprecated, ReadOnly, SqlColumnNumber = 19, SqlComputeCode = { set {*} = {CommandsExecuted} }, SqlComputed, Transient ];

/// Number of Milliseconds spent waiting for Disk reads in this Module for the given query
/// the Modules are nested and the count for the outer ones is cumulative
Property DiskWait As %Integer [ SqlColumnNumber = 18 ];

/// How much time was spent in this Module for the given query
/// the Modules are nested and the count for the outer ones is cumulative
Property TimeSpent As %Float [ SqlColumnNumber = 10 ];

/// <BC>Maintained for Backward-Compatibility</BC>.  See 'TimeSpent'
Property TotalTime As %Float [ SqlComputeCode = { Set {*} = {TimeSpent} }, SqlComputed, Transient ];

/// How much time was spent finding the first row
/// This is only set for Module Main
Property TimeToFirstRow As %Float;

/// TimeStamp of when the query was compiled/run
Property StartTime As %TimeStamp [ SqlColumnNumber = 11 ];

/// InterSystems IRIS UserName of the person who ran this query
Property UserName As %String(MAXLEN = 2000) [ InitialExpression = {$UserName}, SqlColumnNumber = 12 ];

/// IP Address of the machine that ran this query
Property IPAddress As %String(MAXLEN = 100) [ SqlColumnNumber = 13 ];

/// Name of the machine that ran this query
Property MachineName As %String(MAXLEN = 2000) [ SqlColumnNumber = 14 ];

/// Name of the executable that ran this query
Property ExeName As %String(MAXLEN = 2000) [ SqlColumnNumber = 15 ];

/// OS level Process ID
Property Pid As %String(MAXLEN = 2000) [ SqlColumnNumber = 17 ];

/// Number of times we entered this module for the run of the query
/// Used only by Sub class
Property ModuleCount As %String(MAXLEN = 100) [ SqlColumnNumber = 16 ];

/// <PROP>
/// This marker indicates if the statistical data is from an SQL Query, in
/// which case the <class>%SYS.PTools.StatsSQL</class> class should be use, or if these
/// stats are general purpose stats for non-SQL modules, in which case the
/// '%SYS.PTools.Stats' class should be use.
/// </PROP>
Property StatsMarker As %Boolean [ InitialExpression = 0, Required ];

Index IDKEY On (StatsMarker, NameSpace, RoutineName, CursorName, StatsGroup, ModuleName) [ IdKey ];

/// <p class="info-head">
/// Method:       Start
/// Replaces:     N/A
/// Status:       Original Functionality
/// Purpose:      This method is used to START the PTools statistics collection
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.Stats).Start(...)
///                    SQL: N/A
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Start collecting stats to analyze the class 'Populate' method:
/// 
///               do ##class(%SYS.PTools.Stats).Start($NAMESPACE,"Test","Populate")
///               do ##class(Sample.Person).Populate(100)
///               do ##class(%SYS.PTools.Stats).Stop($NAMESPACE,"Test","Populate")
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
/// 
/// Parameters:
///   NS        - The namespace in which the stats collection is occurring
///   Rou       - The routine name for which the stats collection is occurring
///   Mod       - The module name for which the stats collection is occurring
///                  [DEFAULT: 1]
/// 
/// RETURN Value: (NONE)
/// </p>
ClassMethod Start(NS As %String, Rou As %String, Mod As %String = 1)
{
	$$$killPTStatsTop(NS,Rou,Mod)			// Tabula Rasa
	$$$setPTStatsInit(NS,Rou,Mod,$JOB,$ZDATETIME($H,3,1))
	$$$setPTStatsStart(NS,Rou,Mod,$JOB,"")
}

/// <p class="info-head">
/// Method:       Stop
/// Replaces:     N/A
/// Status:       Original Functionality
/// Purpose:      This method is used to STOP the PTools statistics collection
///               This method INSERTs the stats information into the 
///               %SYS_PTools.Stats table
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.Stats).Stop(...)
///                    SQL: N/A
/// 
/// Examples:     The following examples shows the use of this method:
/// 
///    #1         Stop collecting stats to analyze the class 'Populate' method:
/// 
///               do ##class(%SYS.PTools.Stats).Start($NAMESPACE,"Test","Populate")
///               do ##class(Sample.Person).Populate(100)
///               do ##class(%SYS.PTools.Stats).Stop($NAMESPACE,"Test","Populate")
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
/// 
/// Parameters:
///   NS        - The namespace in which the stats collection is occurring
///   Rou       - The routine name for which the stats collection is occurring
///   Mod       - The module name for which the stats collection is occurring
/// 
/// RETURN Value: (NONE)
/// </p>
ClassMethod Stop(NS As %String, Rou As %String, Mod As %String = 1)
{
 	set job=$JOB
 	set start=$$$getPTStatsStart(NS,Rou,Mod)
 	set gloRefs=$s(start="":0,1:$$$processGlobalReferences(job)-$LG(start,$$$PTStatsStartProcessGlobalReferences))
 	set commandsExecuted=$s(start="":0,1:$$$processCommandsExecuted(job)-$LG(start,$$$PTStatsStartProcessCommandsExecuted))
 	set timeSpent=$s(start="":0,1:$$$sysTimestamp-$LG(start,$$$PTStatsStartSysTimestamp))
 	set readLatency=$s(start="":0,1:$$$processDiskReadMilliseconds(job)-$LG(start,$$$PTStatsStartProcessDiskReadMilliseconds))
	set statsGroup=$$$bumpSYSPToolsStatsGroup(NS,Rou,Mod)
 	set ipAddress=$$$processClientIPAddress(job)
 	set nodeName=$$$processClientNodeName(job)
 	set execName=$$$processClientExecutableName(job)
 	set routineInfo=NS_"|"_Rou
 	set startTime=$LG($$$getPTStatsInit(NS,Rou,Mod),$$$PTStatsInfoTimestampPiece)
 	set counter=$$$bumpSYSPToolsStatsCounter(NS,Rou,Mod)
 	
 	&SQL(INSERT INTO %SYS_PTools.Stats 
	            (NameSpace, RoutineName, CursorName, StatsGroup, ModuleName, 
 			     RoutineInfo, StartTime, Counter, GlobalRefs, CommandsExecuted, DiskWait, TimeSpent, 
 			     IPAddress, MachineName, ExeName, Pid
 			    )
 		 VALUES (:NS, :Rou, '*', :statsGroup, :Mod,
 		         :routineInfo, :startTime, :counter, :gloRefs, :commandsExecuted, :readLatency, :timeSpent, 
 		         :ipAddress, :nodeName, :execName, :job
 		        )
 		)

	$$$killPTStatsTop(NS,Rou,Mod)			// Tabula Rasa
}

/// <p class="info-head">
/// Method:       Report [SQL: Stats_Report]
/// Replaces:     N/A
/// Status:       <BC>Maintained for Backward-Compatibility</BC>. See exportStats(...)  <DEP>[DEPRECATED]</DEP>
/// Purpose:      This method generates a comma delimited file containing the data 
///               from the '%SYS.PTools.Stats' class
///               By default the file will be created in the MGR directory of the 
///               InterSystems IRIS instance.
///               You can pass a different value for the 'file' parameters if you 
///               wish to override the default location and file name.
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.Stats).Report(...)
///                    SQL: CALL %SYS_PTools.Stats_Report(...)
///                         SELECT %SYS_PTools.Stats_Report(...)
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
///               set io=##class(%SYS.PTools.Stats).Report($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYS_PTools.Stats_Report('$IO')
/// 
///               Where: '$IO' = Output to the current device
///                              NOTE: '$IO' can be omitted, as it is the default
///                                    'file' when invoked via the CALL interface
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
/// 
/// Parameters:
///   file      - The path and file in which to create and store the data from the 
///               %SYS.PTools.Stats class:  (e.g. C:\exportFile.txt)
///               NOTE:    $IO = Outputs the data to the screen
///                      '$IO' = Output the data to the current device when invoked from the CALL/SELECT-interface
///                     '$DEF' = Ouput the data to the DEFAULT file when invoked from the CALL/SELECT-interface
///                  [DEFAULT: {MGR-Directory}\{computerName}_{ConfigName}_YYYYMMDD_HHMMSS.Stats]
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
/// RETURN Value: The output locations of the exported data; Otherwise, return 
///               the error status if one occurred
/// </p>
ClassMethod Report(file = "", ByRef conds, ByRef ptInfo) As %String [ SqlName = Stats_Report, SqlProc ]
{
	set logDir=$$$SYSMgrDir,hostName=$$$localHost,configName=$$$configurationName,hDate8=$zd($h,8),hTime=$tr($zt($p($h,",",2)),":","")
	set outputFileName=hostName_"_"_configName_"_"_hDate8_"_"_hTime_".Stats"
 	set file=$s($$$UPPER(file)="$IO":$IO,(file="")&&$ISOBJECT($g(%request)):$IO,",$DEF,,"[(","_$$$UPPER(file)_","):$$$currentDir,1:file)
	set outputFile=$s(file="":logDir_outputFileName,1:file)
	if (outputFile=$IO)&&$ISOBJECT($g(%request)) { set format="H" }
	else { set format="D" }
	
	set tSC=..exportStats(outputFile,format,,,,,.conds,.ptInfo,"Stats.Report")
	
	QUIT $s($$$ISERR(tSC):tSC,1:$g(ptInfo("outputFile")))
}

/// <p class="info-head">
/// Method:       exportStats [SQL: PT_exportStats]
/// Replaces:     Report  <DEP>[DEPRECATED]</DEP>
/// Status:       New Method to replicate Backward-Compatible Method it 'Replaces'
/// Purpose:      Create a Performance Tool file containing the data 
///               from the '%SYS.PTools.Stats' and return the output location...
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
///                  ObjectScript: ##class(%SYS.PTools.Stats).exportStats(...)
///                    SQL: CALL %SYS_PTools.PT_exportStats(...)
///                         SELECT %SYS_PTools.PT_exportStats(...)
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
///               set tSC=##class(%SYS.PTools.Stats).exportStats($IO)
/// 
///    #2         Display this export file via the SQL Query Page of the
///               Management Portal:
/// 
///               CALL %SYS_PTools.PT_exportStats('$IO','H')
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
///   file      - The path and file in which to create and store the data from the 
///               %SYS.PTools.Stats class:  (e.g. C:\exportFile.txt)
///               NOTE:    $IO = Outputs the data to the screen
///                      '$IO' = Output the data to the current device when invoked from the CALL/SELECT-interface
///                     '$DEF' = Ouput the data to the DEFAULT file when invoked from the CALL/SELECT-interface
///                  [DEFAULT: {Current-Directory}\PT_Stats_exportStats_YYYYMMDD_HHMMSS.{ext}]
///               WHERE {Current-Directory} = The directory of the Namespace in which
///                                           this method is invoked (e.g. $ZU(12,""))
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
///   statsType -  0 - Return all rows from %SYS.PTools.Stats ONLY       [DEFAULT]
///                1 - Return all rows from %SYS.PTools.StatsSQL ONLY
///                2 - Return all rows from %SYS.PTools.Stats & %SYS.PTools.StatsSQL
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
ClassMethod exportStats(file = "", format = "P", silent = 0, statsType = 0, rtnName = "", modName = "", ByRef conds As %RawString, ByRef ptInfo As %RawString, bcFlag = "") As %Status [ ProcedureBlock = 1, PublicList = (d, thisMethod, outputFile, statsMarker, tSC, version), SqlName = PT_exportStats, SqlProc ]
{
 
 	new %msg,%objlasterror,%sqlcontext
 	new d,thisMethod,outputFile,statsMarker,tSC,version
 	
	set tSC=$$$OK,%msg="",SQLCODE="",outputFile=""
	set thisMethod="exportStats"
	set start=$$$sysTimestamp

 try {

	$$$setSQLStatsFlagOFF(zu115x12)	// Turn off SQLState for current JOB

	if (statsType'=0) && (statsType'=1) && (statsType'=2) { set tSC=$$$ERROR($$$ObjectScriptError,"The 'statsType' parameter must be one of the following values: { 0 | 1 | 2 }") THROW }

 	set className="Stats"
 	set version=$$$PTStatsVersion
	set format=$s(format="":$s($ISOBJECT($g(%request)):"H",1:"P"),("Pp"[$e(format,1))&&$ISOBJECT($g(%request)):"H"_$e(format,2,*),1:$$$UPPER($p(format,":",1))_$s(format[":":":"_$p(format,":",2,*),1:""))
	
	set outputFile=..getOutputFile(file,className,thisMethod,format,,.tSC) THROW:$$$ISERR(tSC)

	if 'silent { USE 0 write !,"Creating '%SYS.PTools.Stats' Report...",!,?3,"Output File: ",$s(outputFile="":"(Terminal IO)",1:outputFile),!! }

 	if outputFile'="" { set tSC=..createAndOpenFile(outputFile) THROW:$$$ISERR(tSC) }
 	
	set statsMarker=$$$StatsMarker	// %SYS.PTools.Stats

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
 	
 	kill d	// Tabula Rasa!
	if (",Stats.Report,"[(","_bcFlag_",")) {
		set d(0,$i(d(0)))=$LB("NameSpace",,20)								// 1
		set d(0,$i(d(0)))=$LB("RoutineName","Routine",30)					// 2
		set d(0,$i(d(0)))=$LB("ModuleName","Module",10)						// 3
		set d(0,$i(d(0)))=$LB("Counter",,8)									// 4
		set d(0,$i(d(0)))=$LB("StartTime","Start Time",20)					// 5
		set d(0,$i(d(0)))=$LB("GlobalRefs","Global Refs",10)				// 6
		set d(0,$i(d(0)))=$LB("CommandsExecuted","Commands Executed",12)	// 7
		set d(0,$i(d(0)))=$LB("TimeSpent","Total Time",10)					// 8
		set d(0,$i(d(0)))=$LB("UserName","User Name",12)					// 9
		set d(0,$i(d(0)))=$LB("MachineName","Machine Name",12)				// 10
		set d(0,$i(d(0)))=$LB("IPAddress","IP Address",10)					// 11
		set d(0,$i(d(0)))=$LB("ExeName","EXE Name",8)						// 12

		set d(0,$i(d(0)))=$LB("StatsMarker","SQL",3,,,,,,,1)				// 13
		set d(0,$i(d(0)))=$LB("CursorName","Cursor",15,,,,,,,1)				// 14
		set d(0,$i(d(0)))=$LB("StatsGroup","Group",8,,,,,,,1)				// 15
		set d(0,$i(d(0)))=$LB("RowCount",,10,,,,,,,1)						// 16
		set d(0,$i(d(0)))=$LB("DiskWait",,10,,,,,,,1)						// 17
		set d(0,$i(d(0)))=$LB("Pid","Process ID",10,,,,,,,1)				// 18
	}
	else {
		set d(0,$i(d(0)))=$LB("StatsMarker","SQL",3)
		set d(0,$i(d(0)))=$LB("NameSpace",,20)
		set d(0,$i(d(0)))=$LB("RoutineName",,30)
		set d(0,$i(d(0)))=$LB("CursorName","Cursor",15,,,,,,,(statsType=0))
		set d(0,$i(d(0)))=$LB("StatsGroup","Group",8)
		set d(0,$i(d(0)))=$LB("ModuleName","Module",10)
		set d(0,$i(d(0)))=$LB("StartTime",,20)
		set d(0,$i(d(0)))=$LB("RowCount",,10,,,,,,,(statsType=0))
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
		set d(2,"sort")=$LB("RoutineInfo","Module")
	}
	for col=1:1:d(0) { set dInfo=d(0,col),dHeader=$LG(dInfo,2) set:dHeader="" dHeader=$LG(dInfo,1) set d("x-heading",dHeader)=col }
	set tSC=..condsMatch(.conds,.d,.condValExp)
	set rowCnt=0
	
	&SQL(DECLARE statsCUR CURSOR FOR
	     SELECT StatsMarker, $PIECE(RoutineInfo,'|',1) AS NameSpace, $PIECE(RoutineInfo,'|',2) AS RoutineName, 'N/A' AS CursorName, StatsGroup, ModuleName, StartTime,
	            'N/A' AS RowCount, Counter AS RunCount, TimeSpent, GlobalRefs, CommandsExecuted, DiskWait,
	            pid, IPAddress, UserName, MachineName, ExeName
	     FROM %SYS_PTools.Stats
	     WHERE StatsMarker = :statsMarker
	     ORDER BY NameSpace, RoutineName
	    )

	set tSC=..fileHeader(outputFile,.format,"",$CLASSNAME(),thisMethod,version,.d,bcFlag) THROW:$$$ISERR(tSC)

 	set tSCs=$$$OK
 	if "02"[statsType {	// --- Return rows from both %SYS.PTools.Stats ---

 	  try {
 	
		&SQL(OPEN statsCUR)
		if SQLCODE<0 { set tSCs=$$$ERROR($$$SQLError,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%apiSQL(SQLCODE))) THROW }
	
		FOR {
			if (",Stats.Report,"[(","_bcFlag_",")) { 
				&SQL(FETCH statsCUR INTO :d(1,13), :d(1,1), :d(1,2), :d(1,14), :d(1,15), :d(1,3), :d(1,5), :d(1,16), :d(1,4), :d(1,8), :d(1,6), :d(1,7), :d(1,17), :d(1,18), :d(1,11), :d(1,9), :d(1,10), :d(1,12))
			}
			else {
				&SQL(FETCH statsCUR INTO :d(1,1), :d(1,2), :d(1,3), :d(1,4), :d(1,5), :d(1,6), :d(1,7), :d(1,8), :d(1,9), :d(1,10), :d(1,11), :d(1,12), :d(1,13), :d(1,14), :d(1,15), :d(1,16), :d(1,17), :d(1,18))
			}
			QUIT:SQLCODE'=0
			
			CONTINUE:(rtnName'="")&&(rtnName'=d(1,3))		// RoutineName doesn't match specified 'rtnName'
			CONTINUE:(modName'="")&&(modName'=d(1,6))		// ModuleName doesn't match specified 'modName'
			if condValExp'="" { // --- Check Condition(s) via the 'conds()' array ---
				try { if @condValExp { } else { CONTINUE } } catch { } // Check if condition(s) in 'conds()' array Succeeded/Failed
			}
				
			set tSCs=..fileBody(outputFile,.format,.d)

			set rowCnt=$I(rowCnt)	// Count Rows Processed!
 		}
	
 		set:SQLCODE<0 tSCs=$$$ADDSC(tSCs,$$$ERROR($$$SQLError,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%apiSQL(SQLCODE))))

		&sql(CLOSE statsCUR)
 		set:SQLCODE<0 tSCs=$$$ADDSC(tSCs,$$$ERROR($$$SQLError,SQLCODE,$s($g(%msg)'="":%msg,1:$$sqlcode^%apiSQL(SQLCODE))))
 		THROW:$$$ISERR(tSCs)
 	  }
 	  catch StatsErr {
	 	  set:tSCs=$$$OK tSCs=$$$ERROR($$$ObjectScriptError,$ze)
 	  }
 	}

 	set tSCss=$$$OK
 	if "12"[statsType {	// --- Return rows from %SYS.PTools.StatsSQL ---
 	
 		set tSCss=##class(%SYS.PTools.StatsSQL).exportStatsSQL(outputFile,.format,silent,0,0,rtnName,modName,.conds,.ptInfo,.rowCnt)
  	}
	set tSC=$$$ADDSC(tSCs,tSCss)
	
	if bcFlag="Stats.Report" { USE $s(outputFile="":$IO,1:outputFile) write "</Stats>",! }

	THROW:$$$ISERR(tSC)
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
	
	if 'silent { USE 0 write ! do $system.Status.DisplayError(tSC) }
 }
 
 	set stop=$$$sysTimestamp
 	
 	do:$$$ISOK(tSC)&&(bcFlag'="Stats.Report") ..fileFooter(outputFile,.format,"End of stats collection for: ##class("_$CLASSNAME()_")."_thisMethod_"(...)",.d,stop-start,rowCnt)
 
 	if outputFile'="" {		// Return to Terminal IO & Close File
 		USE 0
 		CLOSE outputFile
 	}
 	
 	$$$resetSQLStatsFlag(zu115x12)		// Reset SQLStats flag for current JOB to original value
	
	set (file,ptInfo("outputFile"))=$s(outputFile="":$IO,1:##class(%Library.File).CanonicalFilename(outputFile))
 	set ptInfo("className")=$CLASSNAME(),ptInfo("methodName")=$g(thisMethod),ptInfo("rowCnt")=$g(rowCnt),ptInfo("totalTime")=$g(stop)-$g(start)
	
 	QUIT tSC
}

/// <p class="section-head">
/// <b>                    C L E A R  'Stats'  D A T A                            </b>
///                        ---------------------------
/// The following methods are used to remove all of the 'Stats' data:
/// 
///    - clearStatsALL()
///       - clearStats()
///       - clearStatsAllNS()
/// 
/// The aforementioned methods remove data stored in the following classes:
/// 
///    - %SYS.PTools.Stats (old/new)
/// 
///  NOTE: old = Backward-compatible data
/// 
/// </p>
/// 
/// <p class="info-head">
/// Method:       clearStatsALL [SQL: PT_clearStatsALL]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method deletes all of the data stored in the Original 
///               (backward-compatible) and the Optimal (new) PTools Stats class
///               (%SYS.PTools.Stats), based on the specified parameters...
/// 
///               NOTE: Clear ALL PTools Stats data: OLD & NEW (By Default)
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.Stats).clearStatsALL(...)
///                                ..clearStatsALL(...)
///                           SQL: CALL %SYS_PTools.PT_clearStatsALL(...)
///                                SELECT %SYS_PTools.PT_clearStatsALL(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
/// 
/// Parameters:
///   ns             - The namespace in which to clear PTools Stats                 [DEFAULT: $NAMESPACE]
///   rtn            - The routine in which to clear PTools SQL Statistics          [DEFAULT: ""]
///                    If none provided, clear all routines in the given 'ns'
///   ph3            - Placeholder Parameter for future extensibility
///   clearErrs      - 0 = Don't delete the 'PTools' Application Errors
///                    1 = Delete all of the 'PTools' Application Errors            [DEFAULT]
///   silent         - 0 = Display all messages during this method invocation       [DEFAULT]
///                    1 = Don't display any messages during this method invocation
///   returnType     - 0 = Return a %Status code of either $$$OK or $$$ERROR()      [DEFAULT]
///                    1 = Return the total number of Stats rows deleted
///   ptInfo         - A Pass By Reference information array that returns
///                    detailed information to the user in the following format:
///                       ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                    Where category = { "cnt" | "curr" | "term" | ... }
///                          variable = A var corresponding to the given 'category'
/// 
///                    Example:
///                       ptInfo("cnt","clearStatsALL")=The number of rows deleted 
///                                                     via this method
/// 
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the total number of Stats rows deleted; 
///               Otherwise, return an error message if an error occurred
/// </p>
ClassMethod clearStatsALL(ns As %String = "", rtn As %String = "", ph3 As %Integer = 0, clearErrs As %Integer = 1, silent As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_clearStatsALL, SqlProc ]
{
	QUIT $$clearStatsALL^%SYS.PToolsUtil(ns,rtn,ph3,clearErrs,silent,returnType,.ptInfo)
}

/// <p class="info-head">
/// Method:       clearStats [SQL: PT_clearStats]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method deletes all of the data stored in the '%SYS.PTools.Stats' 
///               class, based on the specified 'ns' and 'rtn' parameters...
/// 
///               This method clears statistics which are gathered by the 
///               invocation of the following two methods:
///                  do ##class(%SYS.PTools.Stats).Start(NS,Rou,Mod)  // Start Stats Collection
///                  // Invoke the method in which statistics are to be collected
///                  do ##class(%SYS.PTools.Stats).Stop(NS,Rou,Mod)   // Stop Stats Collection
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.Stats).clearStats(...)
///                           SQL: CALL %SYS_PTools.PT_clearStats(...)
///                                SELECT %SYS_PTools.PT_clearStats(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools","db","Stats{C|D|I|S|Z}")
/// 
/// Parameters:
///   ns          - The namespace in which to clear Statistics
///                 If none provided, use the current namespaces where Stats collected
///                    [DEFAULT: Current Namespace]
///   rtn         - The routine for which to clear Statistics
///                 If none provided, clear all routines in the given 'ns'
///                    [OPTIONAL]
///   ph3         - Placeholder Parameter for future extensibility
///   clearErrs   - 0 = Don't delete the 'PTools' Application Errors
///                 1 = Delete all of the 'PTools' Application Errors
///                    [DEFAULT: 0]
///   returnType  - 0 = Return a %Status code of either $$$OK or $$$ERROR()
///                 1 = Return the number of Stats rows deleted from the 
///                     following class: %SYS.PTools.Stats
///                    [DEFAULT: 0]
///   ptInfo      - A Pass By Reference information array that returns
///                 detailed information to the user in the following format:
///                    ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                 Where category = { "cnt" | "curr" | "term" | ... }
///                       variable = A var corresponding to the given 'category'
/// 
///                 Example:
///                    ptInfo("cnt","clearStats")=The number of rows deleted 
///                                               via this method
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the number of Stats rows deleted from the following class; 
///               Otherwise, return an error message if an error occurred:
///                  %SYS.PTools.Stats
/// </p>
ClassMethod clearStats(ns As %String = "", rtn As %String = "", ph3 As %Integer = 0, clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_clearStats, SqlProc ]
{
	QUIT $$clearStats^%SYS.PTools(ns,rtn,ph3,clearErrs,returnType,.ptInfo)
}

/// <p class="info-head">
/// Method:       clearStatsAllNS [SQL: PT_clearStatsAllNS]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method deletes all of the data stored in the '%SYS.PTools.Stats' 
///               class in All Namespaces on a system for which the user has Write 
///               privileges (Write infers Read), based on the optional 'rtn' 
///               parameter.
/// 
///               This method clears statistics in all namespaces which are 
///               gathered by the invocation of the following two methods:
///                  do ##class(%SYS.PTools.Stats).Start(NS,Rou,Mod)  // Start Stats Collection
///                  // Invoke the method in which statistics are to be collected
///                  do ##class(%SYS.PTools.Stats).Stop(NS,Rou,Mod)   // Stop Stats Collection
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.Stats).clearStatsAllNS(...)
///                           SQL: CALL %SYS_PTools.PT_clearStatsAllNS(...)
///                                SELECT %SYS_PTools.PT_clearStatsAllNS(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
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
///   clearErrs   - 0 = Don't delete the 'PTools' Application Errors
///                 1 = Delete all of the 'PTools' Application Errors
///                    [DEFAULT: 0]
///   returnType  - 0 = Return a %Status code of either $$$OK or $$$ERROR()
///                 1 = Return the total number of Stats rows deleted from the 
///                     following class, for each namespace: %SYS.PTools.Stats
///                    [DEFAULT: 0]
///   ptInfo      - A Pass By Reference information array that returns
///                 detailed information to the user in the following format:
///                    ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                 Where category = { "cnt" | "curr" | "term" | ... }
///                       variable = A var corresponding to the given 'category'
/// 
///                 Example:
///                    ptInfo("cnt","clearStatsAllNS")=The number of rows deleted
///                                                    via this method
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the number of Stats rows deleted from the following class; 
///               Otherwise, return an error message if an error occurred:
///                  %SYS.PTools.Stats
/// </p>
ClassMethod clearStatsAllNS(rtn As %String = "", ph2 As %Integer = 0, ph3 As %String = "", clearErrs As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_clearStatsAllNS, SqlProc ]
{
	QUIT $$clearStatsAllNS^%SYS.PTools(rtn,ph2,ph3,clearErrs,returnType,.ptInfo)
}

/// <p class="section-head">
/// <b>                   C L E A R  'SQL Stats'  D A T A                         </b>
///                       -------------------------------
/// The following methods are used to remove all of the 'SQL Stats' data:
/// 
///    - clearStatsSQLALL()
///       - clearStatsSQLOLD()
///          - clearSQLStats()         <class>%SYS.PTools.SQLStats</class>
///          - clearSQLQuery()         <class>%SYS.PTools.SQLQuery</class>
///          - clearSQLBenchMarkQry()  <class>%SYS.PTools.SQLBenchMarkQueries</class>
///          - clearSQLBenchMarkRslt() <class>%SYS.PTools.SQLBenchMarkResults</class>
///       - clearStatsSQLNEW()
///          - clearStatsSQL()         <class>%SYS.PTools.StatsSQL</class>
///          - clearStatsSQLAllNS()    <class>%SYS.PTools.StatsSQL</class>
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
/// 
/// </p>
/// 
/// <p class="info-head">
/// Method:       clearStatsSQLALL [SQL: PT_clearStatsSQLALL]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method deletes all of the data stored in the Original 
///               (backward-compatible) and the Optimal (new) PTools SQL Stats
///               classes, based on the specified parameters...
/// 
///               NOTE: Clear ALL PTools SQL Stats data: OLD & NEW (By Default)
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.Stats).clearStatsSQLALL(...)
///                                ..clearStatsSQLALL(...)
///                           SQL: CALL %SYS_PTools.PT_clearStatsSQLALL(...)
///                                SELECT %SYS_PTools.PT_clearStatsSQLALL(...)
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
/// PARAMETERS:
///   ns             - The namespace in which to clear PTools SQL Statistics        [DEFAULT: $NAMESPACE]
///   rtn            - The routine in which to clear PTools SQL Statistics          [DEFAULT: ""]
///                    If none provided, clear all routines in the given 'ns'
///   ph3            - Placeholder Parameter for future extensibility
///   clearAll       - 0 = Delete all of the data, except the 'INFO' rows,
///                        stored in the StatsSQL class:
///                           - %SYS.PTools.StatsSQL (new)
///                    1 = Delete all of the data, including the 'INFO' rows,       [DEFAULT]
///                        stored in the StatsSQL class:
///                           - %SYS.PTools.StatsSQL (new)
///   clearSQLQuery  - 0 = Don't delete the data stored in the SQLQuery class:
///                           - %SYS.PTools.SQLQuery (old)
///                    1 = Delete all of the data stored in the SQLQuery class:     [DEFAULT]
///                           - %SYS.PTools.SQLQuery (old)
///   clearBench     - 0 = Don't delete the data stored in the SQLBenchmark class:
///                           - %SYS.PTools.SQLBenchMarkQueries (old)
///                    1 = Delete all of the data stored in the SQLBenchmark class: [DEFAULT]
///                           - %SYS.PTools.SQLBenchMarkQueries (old)
///   clearSQLIndex  - 0 = Don't delete the data stored in the Utility SQL          [DEFAULT]
///                        Index/Analysis classes:
///                           - %SYS.PTools.SQLUtilities (old)
///                           - %SYS.PTools.SQLUtilResults (old)
///                           - %SYS.PTools.UtilSQLStatements (new)
///                           - %SYS.PTools.UtilSQLAnalysisDB (new)
///                    1 = Delete all of the data stored in the Utility SQL
///                        Index/Analysis classes:
///                           - %SYS.PTools.SQLUtilities (old)
///                           - %SYS.PTools.SQLUtilResults (old)
///                           - %SYS.PTools.UtilSQLStatements (new)
///                           - %SYS.PTools.UtilSQLAnalysisDB (new)
///   clearErrs      - 0 = Don't delete the 'PTools' Application Errors
///                    1 = Delete all of the 'PTools' Application Errors            [DEFAULT]
///   purgeCQ        - 0 = Don't purge all of the Cached Queries                    [DEFAULT]
///                    1 = Purge all of the Cached Queries
///   silent         - 0 = Display all messages during this method invocation       [DEFAULT]
///                    1 = Don't display any messages during this method invocation
///   returnType     - 0 = Return a %Status code of either $$$OK or $$$ERROR()      [DEFAULT]
///                    1 = Return the total number of Stats rows deleted
///   ptInfo         - A Pass By Reference information array that returns
///                    detailed information to the user in the following format:
///                       ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                    Where category = { "cnt" | "curr" | "term" | ... }
///                          variable = A var corresponding to the given 'category'
/// 
///                    Example:
///                       ptInfo("cnt","clearStatsSQLALL")=The number of rows deleted 
///                                                        via this method
/// 
///   NOTE: old = Backward-compatible data
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the total number of Stats rows deleted; 
///               Otherwise, return an error message if an error occurred
/// </p>
ClassMethod clearStatsSQLALL(ns As %String = "", rtn As %String = "", ph3 As %Integer = 0, clearAll As %Integer = 1, clearSQLQuery As %Integer = 1, clearBench As %Integer = 1, clearSQLIndex As %Integer = 0, clearErrs As %Integer = 1, purgeCQ As %Integer = 0, silent As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_clearStatsSQLALL, SqlProc ]
{
	QUIT $$clearStatsSQLALL^%SYS.PToolsUtil(ns,rtn,ph3,clearAll,clearSQLQuery,clearBench,clearSQLIndex,clearErrs,purgeCQ,silent,returnType,.ptInfo)
}

/// <p class="info-head">
/// Method:       clearStatsSQLOLD [SQL: PT_clearStatsSQLOLD]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method deletes all of the data stored in the Original 
///               (backward-compatible) PTools SQL Stats classes, based on
///               the specified parameters...
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.Stats).clearStatsSQLOLD(...)
///                                ..clearStatsSQLOLD(...)
///                           SQL: CALL %SYS_PTools.PT_clearStatsSQLOLD(...)
///                                SELECT %SYS_PTools.PT_clearStatsSQLOLD(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools",...)
/// 
/// PARAMETERS:
///   ns             - The namespace in which to clear PTools SQL Statistics        [DEFAULT: $NAMESPACE]
///   rtn            - The routine in which to clear PTools SQL Statistics          [DEFAULT: ""]
///                    If none provided, clear all routines in the given 'ns'
///   ph3            - Placeholder Parameter for future extensibility
///   clearSQLQuery  - 0 = Don't delete the data stored in the SQLQuery class:
///                           - %SYS.PTools.SQLQuery (old)
///                    1 = Delete all of the data stored in the SQLQuery class:     [DEFAULT]
///                           - %SYS.PTools.SQLQuery (old)
///   clearBench     - 0 = Don't delete the data stored in the SQLBenchmark class:
///                           - %SYS.PTools.SQLBenchMarkQueries (old)
///                    1 = Delete all of the data stored in the SQLBenchmark class: [DEFAULT]
///                           - %SYS.PTools.SQLBenchMarkQueries (old)
///   clearSQLIndex  - 0 = Don't delete the data stored in the Utility SQL          [DEFAULT]
///                        Index/Analysis classes:
///                           - %SYS.PTools.SQLUtilities (old)
///                           - %SYS.PTools.SQLUtilResults (old)
///                    1 = Delete all of the data stored in the Utility SQL Index 
///                        Analysis classes:
///                           - %SYS.PTools.SQLUtilities (old)
///                           - %SYS.PTools.SQLUtilResults (old)
///   clearErrs      - 0 = Don't delete the 'PTools' Application Errors
///                    1 = Delete all of the 'PTools' Application Errors            [DEFAULT]
///   purgeCQ        - 0 = Don't purge all of the Cached Queries                    [DEFAULT]
///                    1 = Purge all of the Cached Queries
///   silent         - 0 = Display all messages during this method invocation       [DEFAULT]
///                    1 = Don't display any messages during this method invocation
///   returnType     - 0 = Return a %Status code of either $$$OK or $$$ERROR()      [DEFAULT]
///                    1 = Return the total number of Stats rows deleted
///   ptInfo         - A Pass By Reference information array that returns
///                    detailed information to the user in the following format:
///                       ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                    Where category = { "cnt" | "curr" | "term" | ... }
///                          variable = A var corresponding to the given 'category'
/// 
///                    Example:
///                       ptInfo("cnt","clearStatsSQLOLD")=The number of rows deleted 
///                                                        via this method
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the total number of Stats rows deleted; 
///               Otherwise, return an error message if an error occurred
/// </p>
ClassMethod clearStatsSQLOLD(ns As %String = "", rtn As %String = "", ph3 As %Integer = 0, clearSQLQuery As %Integer = 1, clearBench As %Integer = 1, clearSQLIndex As %Integer = 0, clearErrs As %Integer = 1, purgeCQ As %Integer = 0, silent As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_clearStatsSQLOLD, SqlProc ]
{
	QUIT $$clearStatsSQLOLD^%SYS.PToolsUtil(ns,rtn,ph3,clearSQLQuery,clearBench,clearSQLIndex,clearErrs,purgeCQ,silent,returnType,.ptInfo)
}

/// <p class="info-head">
/// Method:       clearStatsSQLNEW [SQL: PT_clearStatsSQLNEW]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method deletes all of the data stored in the Optimal (new)
///               PTools SQL Stats classes, based on the specified parameters...
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.Stats).clearStatsSQLNEW(...)
///                                ..clearStatsSQLNEW(...)
///                           SQL: CALL %SYS_PTools.PT_clearStatsSQLNEW(...)
///                                SELECT %SYS_PTools.PT_clearStatsSQLNEW(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools",...)
/// 
/// PARAMETERS:
///   ns             - The namespace in which to clear PTools SQL Statistics        [DEFAULT: $NAMESPACE]
///   rtn            - The routine in which to clear PTools SQL Statistics          [DEFAULT: ""]
///                    If none provided, clear all routines in the given 'ns'
///   ph3            - Placeholder Parameter for future extensibility
///   clearAll       - 0 = Delete all of the data, except the 'INFO' rows,
///                        stored in the StatsSQL class:
///                           - %SYS.PTools.StatsSQL (new)
///                    1 = Delete all of the data, including the 'INFO' rows,       [DEFAULT]
///                        stored in the StatsSQL class:
///                           - %SYS.PTools.StatsSQL (new)
///   clearSQLIndex  - 0 = Don't delete the data stored in the Utility SQL          [DEFAULT]
///                        Index/Analysis classes:
///                           - %SYS.PTools.UtilSQLStatements (new)
///                           - %SYS.PTools.UtilSQLAnalysisDB (new)
///                    1 = Delete all of the data stored in the Utility SQL 
///                        Index/Analysis classes:
///                           - %SYS.PTools.UtilSQLStatements (new)
///                           - %SYS.PTools.UtilSQLAnalysisDB (new)
///   clearErrs      - 0 = Don't delete the 'PTools' Application Errors
///                    1 = Delete all of the 'PTools' Application Errors            [DEFAULT]
///   purgeCQ        - 0 = Don't purge all of the Cached Queries                    [DEFAULT]
///                    1 = Purge all of the Cached Queries
///   silent         - 0 = Display all messages during this method invocation       [DEFAULT]
///                    1 = Don't display any messages during this method invocation
///   returnType     - 0 = Return a %Status code of either $$$OK or $$$ERROR()      [DEFAULT]
///                    1 = Return the total number of Stats rows deleted
///   ptInfo         - A Pass By Reference information array that returns
///                    detailed information to the user in the following format:
///                       ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                    Where category = { "cnt" | "curr" | "term" | ... }
///                          variable = A var corresponding to the given 'category'
/// 
///                    Example:
///                       ptInfo("cnt","clearStatsSQLNEW")=The number of rows deleted 
///                                                        via this method
/// 
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the total number of Stats rows deleted; 
///               Otherwise, return an error message if an error occurred
/// </p>
ClassMethod clearStatsSQLNEW(ns As %String = "", rtn As %String = "", ph3 As %Integer = 0, clearAll As %Integer = 1, clearSQLIndex As %Integer = 0, clearErrs As %Integer = 1, purgeCQ As %Integer = 0, silent As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_clearStatsSQLNEW, SqlProc ]
{
	QUIT $$clearStatsSQLNEW^%SYS.PToolsUtil(ns,rtn,ph3,clearAll,clearSQLIndex,clearErrs,purgeCQ,silent,returnType,.ptInfo)
}

/// <p class="section-head">
/// <b>                C L E A R  'SQL Index Stats'  D A T A                      </b>
///                    -------------------------------------
/// The following methods are used to remove all of the 'SQL Index Stats' data: 
/// 
///    - clearStatsSQLIndexALL()
///       - clearStatsSQLIndexOLD()
///          - ClearStatements()      <class>%SYS.PTools.SQLUtilities</class>
///          - ClearResults()         <class>%SYS.PTools.SQLUtilities</class>
///       - clearStatsSQLIndexNEW()
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
/// 
/// </p>
/// 
/// <p class="info-head">
/// Method:       clearStatsSQLIndexALL [SQL: PT_clearStatsSQLIndexALL]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method deletes all of the data stored in the Original 
///               (backward-compatible) and the Optimal (new) PTools Utility 
///               SQL Index/Analysis Stats classes, based on the specified
///               parameters...
/// 
///               NOTE: Clear ALL PTools Utility SQL Index/Analysis Stats: OLD & NEW (By Default)
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.Stats).clearStatsSQLIndexALL(...)
///                                ..clearStatsSQLIndexALL(...)
///                           SQL: CALL %SYS_PTools.PT_clearStatsSQLIndexALL(...)
///                                SELECT %SYS_PTools.PT_clearStatsSQLIndexALL(...)
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
/// PARAMETERS:
///   ns             - The namespace in which to clear PTools Stats                 [DEFAULT: $NAMESPACE]
///   clearErrs      - 0 = Don't delete the 'PTools' Application Errors
///                    1 = Delete all of the 'PTools' Application Errors            [DEFAULT]
///   silent         - 0 = Display all messages during this method invocation       [DEFAULT]
///                    1 = Don't display any messages during this method invocation
///   returnType     - 0 = Return a %Status code of either $$$OK or $$$ERROR()      [DEFAULT]
///                    1 = Return the total number of Stats rows deleted
///   ptInfo         - A Pass By Reference information array that returns
///                    detailed information to the user in the following format:
///                       ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                    Where category = { "cnt" | "curr" | "term" | ... }
///                          variable = A var corresponding to the given 'category'
/// 
///                    Example:
///                       ptInfo("cnt","clearStatsSQLIndexALL")=The number of rows deleted 
///                                                             via this method
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the total number of Stats rows deleted; 
///               Otherwise, return an error message if an error occurred
/// </p>
ClassMethod clearStatsSQLIndexALL(ns As %String = "", clearErrs As %Integer = 1, silent As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_clearStatsSQLIndexALL, SqlProc ]
{
	QUIT $$clearStatsSQLIndexALL^%SYS.PToolsUtil(ns,clearErrs,silent,returnType,.ptInfo)
}

/// <p class="info-head">
/// Method:       clearStatsSQLIndexOLD [SQL: PT_clearStatsSQLIndexOLD]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method deletes all of the data stored in the Original 
///               (backward-compatible) PTools Utility SQL Index/Analysis Stats 
///               classes, based on the specified parameters...
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.Stats).clearStatsSQLIndexOLD(...)
///                                ..clearStatsSQLIndexOLD(...)
///                           SQL: CALL %SYS_PTools.PT_clearStatsSQLIndexOLD(...)
///                                SELECT %SYS_PTools.PT_clearStatsSQLIndexOLD(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools",...)
/// 
/// PARAMETERS:
///   ns             - The namespace in which to clear PTools Stats                 [DEFAULT: $NAMESPACE]
///   clearErrs      - 0 = Don't delete the 'PTools' Application Errors
///                    1 = Delete all of the 'PTools' Application Errors            [DEFAULT]
///   silent         - 0 = Display all messages during this method invocation       [DEFAULT]
///                    1 = Don't display any messages during this method invocation
///   returnType     - 0 = Return a %Status code of either $$$OK or $$$ERROR()      [DEFAULT]
///                    1 = Return the total number of Stats rows deleted
///   ptInfo         - A Pass By Reference information array that returns
///                    detailed information to the user in the following format:
///                       ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                    Where category = { "cnt" | "curr" | "term" | ... }
///                          variable = A var corresponding to the given 'category'
/// 
///                    Example:
///                       ptInfo("cnt","clearStatsSQLIndexOLD")=The number of rows deleted 
///                                                             via this method
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the total number of Stats rows deleted; 
///               Otherwise, return an error message if an error occurred
/// </p>
ClassMethod clearStatsSQLIndexOLD(ns As %String = "", clearErrs As %Integer = 1, silent As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_clearStatsSQLIndexOLD, SqlProc ]
{
	QUIT $$clearStatsSQLIndexOLD^%SYS.PToolsUtil(ns,clearErrs,silent,returnType,.ptInfo)
}

/// <p class="info-head">
/// Method:       clearStatsSQLIndexNEW [SQL: PT_clearStatsSQLIndexNEW]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method deletes all of the data stored in the Optimal
///               (new) PTools Utility SQL Index/Analysis Stats classes, based
///               on the specified parameters...
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.Stats).clearStatsSQLIndexNEW(...)
///                                ..clearStatsSQLIndexNEW(...)
///                           SQL: CALL %SYS_PTools.PT_clearStatsSQLIndexNEW(...)
///                                SELECT %SYS_PTools.PT_clearStatsSQLIndexNEW(...)
/// 
///       NOTE:      This 'SqlProc' method can be invoked with either the 
///                  CALL-interface or the SELECT-interface.  Both interfaces
///                  execute the method: the CALL-interface does not return
///                  any resulting value, while the SELECT-interface does.
/// 
/// Data Storage: ^%sqlcq($NAMESPACE,"PTools",...)
/// 
/// PARAMETERS:
///   ns             - The namespace in which to clear PTools Stats                 [DEFAULT: $NAMESPACE]
///   clearErrs      - 0 = Don't delete the 'PTools' Application Errors
///                    1 = Delete all of the 'PTools' Application Errors            [DEFAULT]
///   silent         - 0 = Display all messages during this method invocation       [DEFAULT]
///                    1 = Don't display any messages during this method invocation
///   returnType     - 0 = Return a %Status code of either $$$OK or $$$ERROR()      [DEFAULT]
///                    1 = Return the total number of Stats rows deleted
///   ptInfo         - A Pass By Reference information array that returns
///                    detailed information to the user in the following format:
///                       ptInfo(category,variable)=value OR $LB(val1,...,valn)
///                    Where category = { "cnt" | "curr" | "term" | ... }
///                          variable = A var corresponding to the given 'category'
/// 
///                    Example:
///                       ptInfo("cnt","clearStatsSQLIndexNEW")=The number of rows deleted 
///                                                             via this method
///    
/// RETURN Value: Based on the value of the 'returnType' parameter, return one of
///               the following:
///           0:  Return a %Status code of either $$$OK or $$$ERROR()
///       
///           1:  Return the total number of Stats rows deleted; 
///               Otherwise, return an error message if an error occurred
/// </p>
ClassMethod clearStatsSQLIndexNEW(ns As %String = "", clearErrs As %Integer = 1, silent As %Integer = 0, returnType As %Integer = 0, ByRef ptInfo As %RawString) As %Status [ SqlName = PT_clearStatsSQLIndexNEW, SqlProc ]
{
	QUIT $$clearStatsSQLIndexNEW^%SYS.PToolsUtil(ns,clearErrs,silent,returnType,.ptInfo)
}

/// <p class="section-head">
/// <b>                G E T / C L E A R  'PToolsError'  D A T A                  </b>
///                    -----------------------------------------
/// The following methods are used to retrieve & remove all of the 'PToolsError' 
/// data:
/// 
///    - getPToolsError()
///    - clearPToolsError()
/// 
/// The aforementioned methods remove data stored in the following global:
/// 
///    - ^%sqlcq($NAMESPACE,"PTools","Error",{errRowID}) (old/new)
/// 
///  NOTE: old = Backward-compatible data
/// 
/// </p>
/// 
/// <p class="info-head">
/// Method:       getPToolsError [SQL: PT_getPToolsError]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method retrieve a specific 'PTools' Application Error for 
///               the given 'errRowID' or retrieve all errors if no 'errRowID' 
///               is provided.
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.Stats).getPToolsError(...)
///                           SQL: SELECT %SYS_PTools.PT_getPToolsError(...)
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
///                          [PASS BY REFERENCE]
///    
/// RETURN Value: The 'PTools' Error RowID ({errRowID}) retrieved, the
///               empty string ("") if {errRowID} invalid, or the word
///               'all' indicating an array of all errors returned.
/// </p>
ClassMethod getPToolsError(errRowID As %String = "", PToolsErr As %RawString) As %Integer [ SqlName = PT_getPToolsError, SqlProc ]
{
	QUIT $$getPToolsError^%SYS.PTools2(errRowID,.PToolsErr)
}

/// <p class="info-head">
/// Method:       clearPToolsError [SQL: PT_clearPToolsError]
/// Replaces:     N/A
/// Status:       New Functionality
/// Purpose:      This method deletes a specific 'PTools' Application Error for 
///               the given 'errRowID' or Deletes all errors if no 'errRowID' is 
///               provided.
/// 
/// Invocation:   This method can be invoked in the following ways:
///                  ObjectScript: ##class(%SYS.PTools.Stats).clearPToolsError(...)
///                           SQL: SELECT %SYS_PTools.PT_clearPToolsError(...)
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
ClassMethod clearPToolsError(errRowID As %String = "") As %Integer [ SqlName = PT_clearPToolsError, SqlProc ]
{
	QUIT $$clearPToolsError^%SYS.PTools2(errRowID)
}

/// Provide the current version for the %SYS.PTools.Stats class/section of the Performance Tools (PTools) Application
ClassMethod version() As %String [ SqlName = Stats_version, SqlProc ]
{
	QUIT $$$PTStatsVersion		//MRP878 - First Implementation of Versioning
}

/// Perform the OnDelete Trigger operations for this class...
ClassMethod TriggerOnDelete(timing, ns, rtn, curs, sgrp, mod)
{
	#; --- If no Data exists for (ns,rtn,curs,sgrp,mod), delete the Information/Counter globals ---
	if '$$$existsSYSPToolsStatsDataIdGlo(ns,rtn,curs,sgrp,mod) {
		$$$killSYSPToolsStatsGroup(ns,rtn,mod)
		$$$killSYSPToolsStatsCounter(ns,rtn,mod)
	}
	
	#; --- If no more data rows exist, delete the Information/Counter globals ---
	if '$$$existsSYSPToolsStatsData {
		$$$killSYSPToolsStatsGroupTree
		$$$killSYSPToolsStatsCounterTree
	}
}

Trigger OnDelete [ Event = DELETE, Time = AFTER ]
{
    do ..TriggerOnDelete("AFTER",{NameSpace},{RoutineName},{CursorName},{StatsGroup},{ModuleName})
}

Storage Default
{
<Data name="StatsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="3">
<Value>Counter</Value>
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
<Value>StartTime</Value>
</Value>
<Value name="9">
<Value>UserName</Value>
</Value>
<Value name="10">
<Value>IPAddress</Value>
</Value>
<Value name="11">
<Value>MachineName</Value>
</Value>
<Value name="12">
<Value>ExeName</Value>
</Value>
<Value name="13">
<Value>ModuleCount</Value>
</Value>
<Value name="15">
<Value>RoutineInfo</Value>
</Value>
<Value name="16">
<Value>TimeToFirstRow</Value>
</Value>
<Value name="17">
<Value>Pid</Value>
</Value>
<Value name="18">
<Value>DiskWait</Value>
</Value>
</Data>
<DataLocation>^%sqlcq($NAMESPACE,"PTools","db","StatsD")</DataLocation>
<DefaultData>StatsDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%sqlcq($NAMESPACE,"PTools","db","StatsD")</IdLocation>
<IndexLocation>^%sqlcq($NAMESPACE,"PTools","db","StatsI")</IndexLocation>
<StreamLocation>^%sqlcq($NAMESPACE,"PTools","db","StatsS")</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
