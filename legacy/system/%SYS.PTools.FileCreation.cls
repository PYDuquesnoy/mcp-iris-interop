/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %SYS.PTools.Stats

/// This class is a place to create File Creation & Formatting methods used by 
/// the PTools Application Package, which was designed to gather performance 
/// statistics for any type of Routine, Code Block or SQL Statement.  
/// 
/// The following methods are written to be used within Class Definitions, and the
/// equivalent methods within the %SYS.PTools.FileCreation.INC file are written to be
/// used within MAC Routines and are written as pure COS methods.
/// 
/// The file formatted that these methods support are driven by the 'format'
/// parameter and support the following formats:
/// 
///   format - The output format of the Export/Reporting file
///            This parameter has the following structure of constituent elements:
///               format=<data-format>[:$LB(<delim>,<csv-header>,<csv-footer>)]
///            Where the constituent elements have the following values:
///               <data-format> - The format of the Export/Reporting file:
///                  - P = Printable/Viewable report file (.txt file, no pagination)
///                  - D = Comma-delimited data file (.csv file) which can be read into a spreadsheet
///                  - X = Microsoft Excel XML markup file suitable for import into Excel (.xml file)
///                  - H = HTML page file (.html file)
///                  - Z = User-defined delimiter "P" formatted file (.dlm file)
///                         NOTE: The <delim> element is required or defaulted to $C(9) (TAB)
///            Optional Elements:
///               <delim> - User-defined delimiter  [DEFAULT: $C(9) (TAB)]
///                          NOTE: This is generally used for <data-format>="Z"
///               <csv-header> - .csv file header for <data-format>="D":
///                  - 0 = Don't add non-standard information header to file  [DEFAULT]
///                  - 1 = Add non-standard information header to file
///               <csv-footer> - .csv file footer for <data-format>="D":
///                  - 0 = Don't add non-standard information footer to file  [DEFAULT]
///                  - 1 = Add non-standard information footer to file
/// 
///            EXAMPLES:
///               Valid 'format' values:
///                  - "H"             // HTML file
///                  - "D"             // CSV file with No information header or footer
///                  - "D:"_$LB(,1,1)  // CSV file with information header & footer
///                  - "Z:"_$LB("^")   // User-defined delimiter file (delim="^")
/// 
/// This class is Super-Class, and is used as part of the EXTENDS directive for the
/// following classes:
///    - %SYS.PTools.SQLQuery
///    - %SYS.PTools.Stats
///         - %SYS.PTools.StatsSQL
///         - %SYS.PTools.SQLStats
/// 
Class %SYS.PTools.FileCreation [ Abstract, System = 4 ]
{

/// Create a valid SQL <order-by-list>
ClassMethod createOrderByList(orderBy = "", d) As %String
{
	#; -------------------------------------------------------------------------------
	#; Function:     createOrderByList
	#; Purpose:      Create a valid SQL <order-by-list> from the given parameters...
	#;
	#; Parameters:
	#;   orderBy   - A single <order-by> field, or a comma-delimited list of <order-by>
	#;               fields in the format: field#[a|d][,field#[a|d],...,field#[a|d]]
	#;   d         - An array of table definitions & data as defined by the invoking
	#;               method.
	#;                  NOTE: The SQL <select-list> fields used to build the
	#;                        <order-by-list> are stored in the following structure:
	#;                           d(0)=# of Columns
	#;                           d(0,#)=$LIST of Column Definitions
	#;                                   1) Name
	#;                                   2) Heading			("" - {Name})
	#;   
	#; Return: A $LIST() containing the following information:
	#;            - orderByPosList
	#;            - orderByFldList
	#;            - orderByFldListAbr    // $LIST {field} without [ASC | DESC]
	#;            - orderADList          // $LIST {ASC | DESC}
	#;         Otherwise, return an error message if an error occurred
	#; -------------------------------------------------------------------------------
	
	set tSC=$$$OK,$ZE=""
	set thisMethod="createOrderByList"
	set orderByPosList="",orderByFldList="",orderByFldListAbr="",orderADList=""
	
	RETURN:"0"[orderBy $LB(orderByPosList,orderByFldList,orderByFldListAbr,orderADList)	// No <order-by-list>!

 try {
	 
	set colTot=+$g(d(0))
	if $l(orderBy,",")>colTot { set tSC=$$$ERROR($$$GeneralError,"The specified 'orderBy' list has too many items: "_orderBy) THROW } 
	set orderBy=$tr(orderBy," ",""),orderByUPPER=$$$UPPER(orderBy)
	 
	for pos=1:1 {
		set orderItem=$p(orderByUPPER,",",pos)
		QUIT:orderItem=""
		 
		set orderNum=+orderItem if (orderNum<1)||(orderNum>colTot) { set tSC=$$$ERROR($$$GeneralError,"Item ("_pos_") of the specified 'orderBy' list is invalid: "_orderBy) THROW }
		set orderAD=$p(orderItem,orderNum,2) if ",,A,D,"'[(","_orderAD_",") { set tSC=$$$ERROR($$$GeneralError,"Item ("_pos_") of the specified 'orderBy' list is invalid: "_orderBy) THROW }
		set orderAD=$CASE(orderAD,"A":"ASC","D":"DESC",:"")
		set orderByPosList=orderByPosList_$s(pos>1:",",1:"")_orderNum_$s(orderAD="":"",1:" "_orderAD)
		set orderByFldList=orderByFldList_$s(pos>1:",",1:"")_$LG($g(d(0,orderNum)),1)_$s(orderAD="":"",1:" "_orderAD)
		set $LIST(orderByFldListAbr,*+1)=$LG($g(d(0,orderNum)),1)
		set $LIST(orderADList,*+1)=$s(orderAD="":"ASC",1:orderAD)
	}
	 
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }
 	QUIT $s($$$ISERR(tSC):tSC,1:$LB(orderByPosList,orderByFldList,orderByFldListAbr,orderADList))
}

/// Check Conditional Matches
ClassMethod condsMatch(conds, d, condValExp = "") As %Status [ PublicList = (conds, condValExp, d) ]
{
	#; -------------------------------------------------------------------------------
	#; Function:     condsMatch
	#; Purpose:      Check to make sure that all of the given 'conds()' match
	#;               their conditions and return a Status Code
	#; Parameters:
	#;   conds     - A string/array of possible conditions by which to restrict the
	#;               output of the Export file, in the following format:
	#;
	#;                  conds=<full condition>
	#;                      OR
	#;                  conds(0)=pos Count (WHERE pos = {1...n})
	#;                  conds(pos)=$LIST() Pieces:
	#;                                1) [<logical operator>]  (Assumed Default: &&)
	#;                                2) [{Heading}]           (Omit for override cond)
	#;                                3) <simple condition> | <complex condition>
	#;
	#;                  WHERE:
	#;                     <full condition>       := <full condition expression>
	#;                     <logical operator>     := {&& | ||}  (&& = AND | || = OR)
	#;                     <simple condition>@*   := <oper><value expression>
	#;                     <complex condition>@   := <complex condition expression>
	#;
	#;                    @ = Contains no references to {Heading}
	#;                    * = Contains no references to {*}
	#;
	#;                  EXAMPLE:
	#;                     <full condition>
	#;                        conds="("",INFO,MAIN,""[("",""_{Module}_"",""))||({GlobalRefs}>20)"
	#;                     <simple condition>
	#;                        conds(0)=3
	#;                        conds(1)=$LB(,"Module","=""INFO""")
	#;                        conds(2)=$LB("||","Module","=""MAIN""")
	#;                        conds(3)=$LB("||","GlobalRefs",">20")
	#;                     <complex condition>
	#;                        conds(0)=2
	#;                        conds(1)=$LB(,"Module",""",INFO,MAIN,""[("",""_{*}_"","")")
	#;                        conds(2)=$LB("||","GlobalRefs","{*}>20")
	#;                           WHERE: {*} = value substitution for the 'Module' & 'GlobalRefs' fields
	#;                           NOTE: Conditions that don't contain any references to
	#;                                 {Heading} fields, often called <override condition>s,
	#;                                 can be included as <complex condition>s, as in
	#;                                 the following example:
	#;                                    conds(pos)=$LB(,,"$g(^zAction(""runIt""))=1") 
	#;
	#;                  NOTE: All conditions must be satisfied for the conds() to
	#;                        be considered true and for the row to be exported
	#;   d		   - An array of table definitions & data in the following format:
	#;
	#;                  d(0)=# of Columns
	#;                  d(0,#)=$LIST of Column Definitions
	#;                          1) Name
	#;                          2) Heading			("" - {Name})
	#;                          3) Length			("" - XML:AutoFitWidth)
	#;                          4) Output Length	(Internally set & used)
	#;                          5) Datatype			("" - %String)
	#;                         10) Supress Output   (If 1, don't display <select-list> item)
	#;                  d(1,#)=Column Data
	#;                  d(2,"sort")=$LIST of #'s or Heading
	#;                  d(2,"sort","order")=$LIST of {ASC | DESC}
	#;                  d("x-heading",{Heading})=#
	#;   condValExp - A condition value expression created from the conds() array
	#;                to be returned via Pass By Reference (PBR) as a quick way to
	#;                evaluate all of the conditions via a simple indirection
	#;                invocation. (if @condValExp)
	#;
	#; Return: The status of the conditions check
	#; -------------------------------------------------------------------------------

	set tSC=$$$OK
	
 try {
	set sub1=$o(conds(""))
	if (sub1'="")&&(sub1'=+sub1) { // --- Convert Backward-Compatible conds() Array ---
		for start="","%override" {
			set head=start
			for {
				set cond="",head=$o(conds(head),1,cond)
				if start="" { CONTINUE:$e(head,1,9)="%override" }  // Process "%override?" Last!
				else { QUIT:$e(head,1,9)'="%override" }            // Process "%override?" Only!
				QUIT:head=""  // No more conditions!
				
				set condsNew($i(condsNew(0)))=$LB("&&",$s($e(head,1,9)="%override":"",1:head),cond)
			}
		}
		kill conds merge conds=condsNew	// Forward-Compatible conds() Array
	}
	
	if $g(conds)'="" { // --- Process <full condition> Here ---
		set condsNew=conds
		set condValExp=""
		for { // --- Process {Heading} Substitutions ---
			QUIT:condsNew'["{"  // No more {Heading} substitutions!
			
			set p1=$p(condsNew,"{",1),p2=$p(condsNew,"{",2,*),head=$p(p2,"}",1),condsNew=$p(p2,"}",2,*)
			set condValExp=condValExp_p1_$s(head="":"""{}""",$d(d("x-heading",head)):"$g(d(1,"_(+$g(d("x-heading",head)))_"))",1:"""{"_head_"}""")
		}
		set condValExp=condValExp_condsNew
	}
	else { // --- Process <simple condition>s & <complex condition>s Here ---
		set pos=0
		for {
			set condRow="",pos=$o(conds(pos),1,condRow)
			QUIT:pos=""  // No more conditions!
			
			set condLogOper="&&",head="",cond=""	// Defaults!
			set $LB(condLogOper,head,cond)=condRow
			
			set headVal=$s(head="":"",$d(d("x-heading",head)):"$g(d(1,"_(+$g(d("x-heading",head)))_"))",1:"")
			if (headVal'="")&&("'=<>[]?"[$e(cond)) { // --- <simple condition> ---
				set condValExpOne=$s(headVal'="":"("_headVal_cond_")",1:1)
			}
			elseif (headVal'="") { // --- <complex condition> ---
				set:(cond["{*}")&&(headVal'="") cond=$REPLACE(cond,"{*}",headVal)
				set condValExpOne="("_cond_")"
			}
			elseif (head="") { // --- <complex condition> ---
				set condValExpOne="("_cond_")"
			}
			else { // --- Unknown {Heading} ---
				CONTINUE
			}
			
		 	try {
				if @condValExpOne	// Valid Condition!
				set condValExp=condValExp_$s(condValExp'="":condLogOper,1:"")_condValExpOne
	 		}
 			catch {
				set tSC=$$$ERROR("condition-failed/invalid","head="_$$$quote(head)_",cond="_$$$quote(cond))
				set condValExp=1	// Invalid conds() Conditions!
				QUIT
 			}
 			QUIT:'tSC	// Failed conditions so exit FOR Loop!
		}
	}
	
	if condValExp'="" { // --- Validate 'condValExp' ---
		try {
			if @condValExp {	}  // --- Condition(s) Succeeded ---
			else { set tSC=0 }	   // --- Condition(s) Failed ---
		}
		catch {
			set tSC=$$$ERROR("condition-failed/invalid","condValExp="_$$$quote(condValExp))
			set condValExp=""	// Invalid conds() Conditions!
		}
	}
	set:condValExp=1 condValExp=""
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
	set condValExp=""	// Invalid conds() Conditions!
 }    
	QUIT tSC
}

/// Create & Open File
ClassMethod createAndOpenFile(file, timeout = {$$$PTSOpenTimeout}) As %Status
{
	#; -------------------------------------------------------------------------------
	#; Function:     createAndOpenFile
	#; Purpose:      Create the specified 'file', leave the device IO OPEN, and 
	#;               return a Status Code
	#; Parameters:
	#;   file      - The File to create and OPEN, specified as a full reference
	#;                 (e.g. C:\reporFile.txt)
	#;   timeout   - The number of seconds to wait for the 'file' to OPEN
	#;               before timing-out with an error.        [DEFAULT: 5]
	#;
	#; Return: The status of this method; Either $$$OK or $$$ERROR if an error occurs
	#; -------------------------------------------------------------------------------

	set tSC=$$$OK
	
 try {
	set delim=$s(file["\":"\",1:"/"),dir=$p(file,delim,1,*-1)_delim
	if '$$$FileDirectoryExists(dir) { set tSC=$$$ERROR($$$DirectoryNotExist,dir) THROW }

	CLOSE file	// Close in case it's already open!
	OPEN file:"WNS":timeout if '$T { set tSC=$$$ERROR($$$FileCanNotOpen,file) THROW }
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }    
	QUIT tSC
}

/// Open File For Read
ClassMethod openFileForRead(file, timeout = {$$$PTSOpenTimeout}) As %Status
{
	#; -------------------------------------------------------------------------------
	#; Function:     openFileForRead
	#; Purpose:      OPEN the specified 'file' and return a Status Code
	#; Parameters:
	#;   file      - The File to OPEN, specified as a full reference
	#;                 (e.g. C:\dir\file.txt)
	#;   timeout   - The number of seconds to wait for the 'file' to OPEN
	#;               before timing-out with an error.        [DEFAULT: 5]
	#;
	#; Return: The status of this method; Either $$$OK or $$$ERROR if an error occurs
	#; -------------------------------------------------------------------------------

	set tSC=$$$OK

 try {
	set delim=$s(file["\":"\",1:"/"),dir=$p(file,delim,1,*-1)_delim
	if '$$$FileDirectoryExists(dir) { set tSC=$$$ERROR($$$DirectoryNotExist,dir) THROW }

	CLOSE file	// Close in case it's already open!
	OPEN file:"RS":timeout if '$T { set tSC=$$$ERROR($$$FileCanNotOpen,file) THROW }
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }
	QUIT tSC
}

/// Get the 'outputFile'
ClassMethod getOutputFile(file = "", className = "", methodName = "", format = "", hDate = "", tSC = {$$$OK}) As %String
{
	#; -------------------------------------------------------------------------------
	#; Function:     getOutputFile
	#; Purpose:      Get the 'outputFile', which is the path and file in which 
	#;               to create and store the Export/Reporting data
	#; Parameters:
	#;   file       - The path and file in which to create and store the data
	#;   className  - The name of the invoking Export/Reporting class
	#;   methodName - The name of the invoking Export/Reporting method
	#;   format     - The output format of the Export/Reporting file
	#;   hDate      - An optional $HOROLOG date
	#;   tSC        - A Pass By Reference status of this method's invocation
	#;
	#; Return: The 'outputFile', which is the path and file in which
	#;         to create and store the Export/Reporting data
	#; -------------------------------------------------------------------------------
	
	set tSC=$$$OK,$ZE=""

 try {
	set outputFile=""
	set currDir=$$$currentDir set:hDate="" hDate=$HOROLOG set dateTime=$tr($zdt(hDate,8,1)," :","_")
 	set fileFmt=$$$formatIt($p(format,":",1),".txt",".csv",".xml",".html",".dlm",".txt")
 	set fileFullName="PT_"_$s(className'="":className_"_",1:"")_methodName_"_"_dateTime
 	set outputFile=$s(file=$IO:"",$$$UPPER(file)="$IO":"",(file="")&&$ISOBJECT($g(%request)):"",",$DEF,,"[(","_$$$UPPER(file)_","):currDir_fileFullName,"\/"[$e(file,*):file_fileFullName,1:file)
 	if outputFile'="" {	// --- 'outputFile' Defined ---
		set delim=$s(outputFile["\":"\",1:"/")
		set dir=$p(outputFile,delim,1,*-1)_delim,fileName=$p(outputFile,delim,*)
		set outputFile=dir_fileName_$s(fileName'[".":fileFmt,1:"")
 		set:outputFile'[delim outputFile=$$defdir^%SYS.GLO($NAMESPACE)_outputFile
 	}
 }
 catch {
	set tSC=$$$ERROR($$$ObjectScriptError,"The 'getOutputFile()' method failed to create the 'outputFile' due to the following error: "_$ZE)
	set outputFile=""
 }
	QUIT outputFile
}

/// File Header
ClassMethod fileHeader(file, format, title = "", class, method, version, metadata, bcFlag = "") As %Status
{
	#; -------------------------------------------------------------------------------
	#; Function:     fileHeader
	#; NOTE:         Assume 'file' is open and writable
	#; Purpose:      Create the Header for the specified file
	#; Parameters:
	#;   file        - The File in which to write the Header
	#;                  (e.g. C:\reportFile.txt)
	#;   format      - The output format of the Export/Reporting file
	#;                 This parameter has the following structure of constituent elements:
	#;                    format=<data-format>[:$LB(<delim>,<csv-header>,<csv-footer>)]
	#;                 Where the constituent elements have the following values:
	#;                    <data-format> - The format of the Export/Reporting file:
	#;                       - P = Printable/Viewable report file (.txt file, no pagination)
	#;                       - D = Comma-delimited data file (.csv file) which can be read into a spreadsheet
	#;                       - X = Microsoft Excel XML markup file suitable for import into Excel (.xml file)
	#;                       - H = HTML page file (.html file)
	#;                       - Z = User-defined delimiter "P" formatted file (.dlm file)
	#;                              NOTE: The <delim> element is required or defaulted to $C(9) (TAB)
	#;                 Optional Elements:
	#;                    <delim> - User-defined delimiter  [DEFAULT: $C(9) (TAB)]
	#;                               NOTE: This is generally used for <data-format>="Z"
	#;                    <csv-header> - .csv file header for <data-format>="D":
	#;                       - 0 = Don't add non-standard information header to file  [DEFAULT]
	#;                       - 1 = Add non-standard information header to file
	#;                    <csv-footer> - .csv file footer for <data-format>="D":
	#;                       - 0 = Don't add non-standard information footer to file  [DEFAULT]
	#;                       - 1 = Add non-standard information footer to file
	#;                 EXAMPLES:
	#;                    Valid 'format' values:
	#;                       - "H"             // HTML file
	#;                       - "D"             // CSV file with No information header or footer
	#;                       - "D:"_$LB(,1,1)  // CSV file with information header & footer
	#;                       - "Z:"_$LB("^")   // User-defined delimiter file (delim="^")
	#;   title       - The title of the report being created
	#;   class       - The class name who's 'method' is being invoked
	#;   method      - The method within the specified 'class' being invoked
	#;   version     - The version of the tools being invoked
	#;   metadata    - An array of the table metadata definitions
	#;                    [PASS BY REFERENCE]
	#;   bcFlag      - This is a Backward-Compatibility flag used for 
	#;                 [Internal Purposes ONLY]
	#;
	#; Return: The status of this method; Either $$$OK or $$$ERROR if an error occurs
	#; -------------------------------------------------------------------------------

	new %objlasterror,%msg,%ROWCOUNT,%ROWID
	set tSC=$$$OK,%msg=""
	set currDevice=$IO
	set:file="" file=currDevice
	USE file

 try {
	 
	merge fileFormat=format set formatInfo=$p(fileFormat,":",2),fileFormat=$p(fileFormat,":",1)
	set $LG(delim,csvHeader,csvFooter)=formatInfo set:delim="" delim=$g(fileFormat(0))

	set desc=0
	if bcFlag="Stats.Report" {	// --- Backward-Compatibility: See ##class(%SYS.PTools.Stats).Report() ---
		set title=file_" , "_version
		write !
	}
	elseif bcFlag="SQLQuery.Export" {	// --- Backward-Compatibility: See ##class(%SYS.PTools.SQLQuery).Export() ---
		set:delim="" delim=$c(9)	// DEFAULT: <tab>

		set title=file_delim_version_delim_"NameSpace = "_$NAMESPACE
	}
	elseif ",StatsSQL.ExportAll,StatsSQL.Export,SQLStats.ExportAll,SQLStats.Export,"[(","_bcFlag_",") {	// --- Backward-Compatibility: See ##class(%SYS.PTools.{StatsSQL|SQLStats}).ExportAll() & ##class(%SYS.PTools.{StatsSQL|SQLStats}).Export() ---
		set:delim="" delim=$c(9)	// DEFAULT: <tab>

		set title=file_delim_version_delim_"NameSpace = "_$NAMESPACE
	}
	else {
		set:title="" title=$$$Text("IRIS Performance Tools: Statistical Report/Data Export","%SYS.PTools")
		set desc($i(desc))=$$$FormatText($$$Text("Class: %1  Method: %2  Version: %3","%SYS.PTools"),class,method,version)
		set desc($i(desc))=$$$FormatText($$$Text("Configuration: %1  System: %2  Namespace: %3","%SYS.PTools"),$$$configurationName,$$$computerName,$NAMESPACE)
		set desc($i(desc))=$$$FormatText($$$Text("Started: %1","%SYS.PTools"),$ZDT($H,2,3))
	}

	if fileFormat="P" {		// --- Text ---
		set:delim="" delim="  "	// DEFAULT: <space><space>
		write title,!
		for sub=1:1:desc write ?3,desc(sub),!
		write !

		do ..TXTtabHead(.metadata,delim)
	}
	elseif fileFormat="D" {	// --- Comma-Delimited ---
		set:delim="" delim=","	// DEFAULT: <comma>
		write:bcFlag'="Stats.Report" "sep=",delim,!	// Specify CSV field/data [sep]arator
		if +csvHeader { // --- Add Non-standard Information Header ---
			write title,!
			for sub=1:1:desc write ?3,desc(sub),!
			write:bcFlag'="Stats.Report" !

			write:bcFlag="Stats.Report" "<Stats>",!
		}

		do ..CSVtabHead(.metadata,delim)
	}
	elseif fileFormat="X" {	// --- Excel XML Spreadsheet ---
		&html<<?xml version="1.0"?>>
		&html<<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
		  xmlns:o="urn:schemas-microsoft-com:office:office"
		  xmlns:x="urn:schemas-microsoft-com:office:excel"
		  xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"
		  xmlns:html="http://www.w3.org/TR/REC-html40">>
		&html< <DocumentProperties xmlns="urn:schemas-microsoft-com:office:office">>
		&html<  <Title>#(title)#</Title>>
		&html<  <Description>>
		   for sub=1:1:desc &html<   #(desc(sub))#>
		&html<  </Description>>
		&html<  <Author>#(class_" with Configuration '"_$$$configurationName_"' on System '"_$$$computerName_"' in Namespace '"_$NAMESPACE_"'")#</Author>>
		&html<  <Created>#($ZDT($H,4))#</Created>>
		&html<  <Company>InterSystems</Company>>
		&html<  <Version>#(version)#</Version>>
		&html< </DocumentProperties>>
		&html< <Styles>>
		&html<  <Style>>
		&html<   <Alignment ss:Vertical="Bottom"/>>
		&html<   <Borders/>>
		&html<   <Font/>>
		&html<   <Interior/>>
		&html<   <NumberFormat/>>
		&html<   <Protection/>>
		&html<  </Style>>
		&html<  <Style ss:ID="s21">>
		&html<   <Font x:Family="Swiss" ss:Bold="1"/>>
		&html<  </Style> >
		&html< </Styles>>

		do ..XMLsheet(title)
		do ..XMLtable($g(metadata(0)),"")
		#; MRP882: *** Remove the following code after the proper 'width' is defined: ,width="" ***
		for col=1:1:metadata(0) { set width=$LG(metadata(0,col),3),width="" if width { do ..XMLcolWidth(width) } else { do ..XMLcolAuto() }}
		do ..XMLrowHeader(.metadata)
	}
	elseif fileFormat="H" { // --- HTML ---
		&html<<html>>
		&html< <head>>
		&html<  <a name="top"></a>>
		&html<  <title>#(title)#</title>>
		&html<  <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">>
		&html<  <meta #(class_" with Configuration '"_$$$configurationName_"' on System '"_$$$computerName_"' in Namespace '"_$NAMESPACE_"'")# />>
		&html< </head>>
		&html< <body bgcolor="#FFFFFF" text="#000000">>
		&html<  <p style="font-family: Arial, Helvetica, sans-serif; font-size: 20px; color: #0000FF"><b>#(title)#</b></p>>
		&html<  <p>>

		for sub=1:1:desc &html<   #(desc(sub))#<br/>>

		&html<  </p>>

		do ..HTMLtabHead("data", title, .metadata)
	}
	elseif fileFormat="Z" {	// --- User-defined <delim>-Delimited ---
		set:delim="" delim=$c(9)	// DEFAULT: <tab>

		write title,!
		for sub=1:1:desc write ?3,desc(sub),!
		write:",SQLQuery.Export,StatsSQL.ExportAll,StatsSQL.Export,SQLStats.ExportAll,SQLStats.Export,"'[(","_bcFlag_",") !

		do ..DLMtabHead(.metadata,delim)
	}
	else {				// --- Other (Text) ---
		set:delim="" delim="  "	// DEFAULT: <space><space>
		write title,!
		for sub=1:1:desc write ?3,desc(sub),!
		write !

		do ..TXTtabHead(.metadata,delim)
	}
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }
	
	USE currDevice
	QUIT tSC
}

/// File Body
ClassMethod fileBody(file, format, metadata)
{
	#; -------------------------------------------------------------------------------
	#; Function:     fileBody
	#; NOTE:         Assume 'file' is open and writable
	#; Purpose:      Create the Body for the specified file
	#; Parameters:
	#;   file        - The File in which to write the Footer
	#;                  (e.g. C:\reportFile.txt)
	#;   format      - The output format of the Export/Reporting file
	#;                 This parameter has the following structure of constituent elements:
	#;                    format=<data-format>[:$LB(<delim>,<csv-header>,<csv-footer>)]
	#;                 Where the constituent elements have the following values:
	#;                    <data-format> - The format of the Export/Reporting file:
	#;                       - P = Printable/Viewable report file (.txt file, no pagination)
	#;                       - D = Comma-delimited data file (.csv file) which can be read into a spreadsheet
	#;                       - X = Microsoft Excel XML markup file suitable for import into Excel (.xml file)
	#;                       - H = HTML page file (.html file)
	#;                       - Z = User-defined delimiter "P" formatted file (.dlm file)
	#;                              NOTE: The <delim> element is required or defaulted to $C(9) (TAB)
	#;                 Optional Elements:
	#;                    <delim> - User-defined delimiter  [DEFAULT: $C(9) (TAB)]
	#;                               NOTE: This is generally used for <data-format>="Z"
	#;                    <csv-header> - .csv file header for <data-format>="D":
	#;                       - 0 = Don't add non-standard information header to file  [DEFAULT]
	#;                       - 1 = Add non-standard information header to file
	#;                    <csv-footer> - .csv file footer for <data-format>="D":
	#;                       - 0 = Don't add non-standard information footer to file  [DEFAULT]
	#;                       - 1 = Add non-standard information footer to file
	#;                 EXAMPLES:
	#;                    Valid 'format' values:
	#;                       - "H"             // HTML file
	#;                       - "D"             // CSV file with No information header or footer
	#;                       - "D:"_$LB(,1,1)  // CSV file with information header & footer
	#;                       - "Z:"_$LB("^")   // User-defined delimiter file (delim="^")
	#;   metadata    - An array of the table metadata definitions
	#;
	#; Return: The status of this method; Either $$$OK or $$$ERROR if an error occurs
	#; -------------------------------------------------------------------------------

	new %objlasterror,%msg,%ROWCOUNT,%ROWID
	set tSC=$$$OK,%msg=""
	set currDevice=$IO
	set:file="" file=currDevice
	USE file

 try {
	 
	merge fileFormat=format set formatInfo=$p(fileFormat,":",2),fileFormat=$p(fileFormat,":",1)
	set $LG(delim,csvHeader,csvFooter)=formatInfo set:delim="" delim=$g(fileFormat(0))

	if fileFormat="P" {		// --- Text ---
		set:delim="" delim="  "	// DEFAULT: <space><space>
		do ..TXTtabRow(.metadata,delim)
	}
	elseif fileFormat="D" {	// --- Comma-Delimited ---
		set:delim="" delim=","	// DEFAULT: <comma>
		do ..CSVtabRow(.metadata,delim)
	}
	elseif fileFormat="X" {	// --- Excel XML Spreadsheet ---
		do ..XMLtabRow(.metadata)
	}
	elseif fileFormat="H" { // --- HTML ---
		do ..HTMLtabRow(.metadata)
	}
	elseif fileFormat="Z" {	// --- User-defined <delim>-Delimited ---
		set:delim="" delim=$c(9)	// DEFAULT: <tab>
		do ..DLMtabRow(.metadata,delim)
	}
	else {				// --- Other (Text) ---
		set:delim="" delim="  "	// DEFAULT: <space><space>
		do ..TXTtabRow(.metadata,delim)
	}
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }

	USE currDevice
	QUIT tSC
}

/// File Footer
ClassMethod fileFooter(file, format, footerMsg, metadata, elapseTime, rowCnt) As %Status
{
	#; -------------------------------------------------------------------------------
	#; Function:     fileFooter
	#; NOTE:         Assume 'file' is open and writable
	#; Purpose:      Create the Footer for the specified file
	#; Parameters:
	#;   file        - The File in which to write the Footer
	#;                  (e.g. C:\reportFile.txt)
	#;   format      - The output format of the Export/Reporting file
	#;                 This parameter has the following structure of constituent elements:
	#;                    format=<data-format>[:$LB(<delim>,<csv-header>,<csv-footer>)]
	#;                 Where the constituent elements have the following values:
	#;                    <data-format> - The format of the Export/Reporting file:
	#;                       - P = Printable/Viewable report file (.txt file, no pagination)
	#;                       - D = Comma-delimited data file (.csv file) which can be read into a spreadsheet
	#;                       - X = Microsoft Excel XML markup file suitable for import into Excel (.xml file)
	#;                       - H = HTML page file (.html file)
	#;                       - Z = User-defined delimiter "P" formatted file (.dlm file)
	#;                              NOTE: The <delim> element is required or defaulted to $C(9) (TAB)
	#;                 Optional Elements:
	#;                    <delim> - User-defined delimiter  [DEFAULT: $C(9) (TAB)]
	#;                               NOTE: This is generally used for <data-format>="Z"
	#;                    <csv-header> - .csv file header for <data-format>="D":
	#;                       - 0 = Don't add non-standard information header to file  [DEFAULT]
	#;                       - 1 = Add non-standard information header to file
	#;                    <csv-footer> - .csv file footer for <data-format>="D":
	#;                       - 0 = Don't add non-standard information footer to file  [DEFAULT]
	#;                       - 1 = Add non-standard information footer to file
	#;                 EXAMPLES:
	#;                    Valid 'format' values:
	#;                       - "H"             // HTML file
	#;                       - "D"             // CSV file with No information header or footer
	#;                       - "D:"_$LB(,1,1)  // CSV file with information header & footer
	#;                       - "Z:"_$LB("^")   // User-defined delimiter file (delim="^")
	#;   footerMsg   - The footer message
	#;   metadata    - An array of the table metadata definitions
	#;                    [PASS BY REFERENCE]
	#;   elapseTime  - The total number of seconds elapsed
	#;   rowCnt      - The number of rows processeda
	#;
	#; Return: The status of this method; Either $$$OK or $$$ERROR if an error occurs
	#; -------------------------------------------------------------------------------

	new %objlasterror,%msg,%ROWCOUNT,%ROWID
	set tSC=$$$OK,%msg=""
	set currDevice=$IO
	set:file="" file=currDevice
	USE file

 try {

	merge fileFormat=format set formatInfo=$p(fileFormat,":",2),fileFormat=$p(fileFormat,":",1)
	set $LG(delim,csvHeader,csvFooter)=formatInfo set:delim="" delim=$g(fileFormat(0))

	set elapseTimeFooter=$$$FormatText($$$Text("%1 rows processed in %2 seconds","%SYS.PTools"),rowCnt,elapseTime)
	set sortList=$g(metadata(2,"sort")),sortOrderList=$g(metadata(2,"sort","order"))
	for pos=1:1:$LL(sortList) { set sortCol=$LG(sortList,pos) set $LIST(sortColList,pos)=$s(sortCol=+sortCol:$LG(metadata(0,sortCol),1),1:sortCol) }

	if fileFormat="P" {		// --- Text ---
		write !,"-------------------------------------------------------------------------------"
		write !,footerMsg
		write !,elapseTimeFooter
	}
	elseif fileFormat="D" {	// --- Comma-Delimited ---
		if +csvFooter { // --- Add Non-standard Information Footer ---
			write !!,footerMsg
			write !,elapseTimeFooter
		}
	}
	elseif fileFormat="X" {	// --- Excel XML Spreadsheet ---
		&html<  </Table>>

		do:sortColList'="" ..XMLsort(sortColList,sortOrderList)

		&html< </Worksheet>>
		&html< <FooterMsg>#(footerMsg)#</FooterMsg>>
		&html< <FooterTime>#(elapseTimeFooter)#</FooterTime>>
		&html<</Workbook>>
	}
	elseif fileFormat="H" { // --- HTML ---
		&html<  </table>>
		&html<  <br/>>
		&html<  <a href="#top">top</a>>
		&html<  <br/>>
		&html<  <hr size="4" noshade/>>
		&html<  <p style="font-family: Arial, Helvetica, sans-serif; font-size: 14px; color: #0000FF">>
		&html<   <b>#(footerMsg)#</b><br/>>
		&html<   #(elapseTimeFooter)#>
		&html<  </p>>
		&html< </body>>
		&html<</html>>
	}
	elseif fileFormat="Z" {	// --- User-defined <delim>-Delimited ---
		write !!,footerMsg
		write !,elapseTimeFooter
	}
	else {				// --- Other (Text) ---
		write !,"-------------------------------------------------------------------------------"
		write !,footerMsg
		write !,elapseTimeFooter
	}
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }

	USE currDevice
	QUIT tSC
}

/// Text Table Header
ClassMethod TXTtabHead(metadata, delim)
{
	#; -------------------------------------------------------------------------------
	#; Function:     TXTtabHead
	#; NOTE:         Assume 'file' is open and writable
	#; Purpose:      Create the Table Header for the specified Text file
	#; Parameters:
	#;   metadata    - An array of the table metadata definitions
	#;                    [PASS BY REFERENCE]
	#;   delim       - The delimiter used to separate data elements
	#;
	#; Return: (NONE)
	#; -------------------------------------------------------------------------------

 try {
	set dashes="-------------------------------------------------------------------------------"

	for col=1:1:metadata(0) {	// --- Column Headers ---
		set colDef=$g(metadata(0,col))
		CONTINUE:colDef=""  		// Column contains NO Definition!
		CONTINUE:+$LG(colDef,10)	// Supress Output
		
		set colHead=$LG(colDef,2) if colHead="" { set colHead=$LG(colDef,1),$LIST(metadata(0,col),2)=colHead }
		set colHeadLen=$l(colHead)
		set colOutLen=$LG(colDef,3) set:colOutLen="" colOutLen=$$$PTSColLengthDefault set:colHeadLen>colOutLen colOutLen=colHeadLen
		set $LIST(metadata(0,col),4)=colOutLen
		write:$i(colPos)>1 delim write colHead,$j("",colOutLen-colHeadLen)
	}	
	write !
	
	set colPos=0	// Reset to zero
	for col=1:1:metadata(0) {	// --- Column Dashes ---
		set colDef=$g(metadata(0,col))
		CONTINUE:colDef=""  		// Column contains NO Definition!
		CONTINUE:+$LG(colDef,10)	// Supress Output
		
		set colOutLen=$LG(colDef,4)
		write:$i(colPos)>1 delim write $e(dashes,1,colOutLen)
	}
	write !
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }

	QUIT
}

/// Text Table Data Row
ClassMethod TXTtabRow(metadata, delim)
{
	#; -------------------------------------------------------------------------------
	#; Function:     TXTtabRow
	#; NOTE:         Assume 'file' is open and writable
	#; Purpose:      Create the Table Data Row for the specified Text file
	#; Parameters:
	#;   metadata    - An array of the table metadata definitions
	#;                    [PASS BY REFERENCE]
	#;   delim       - The delimiter used to separate data elements
	#;
	#; Return: (NONE)
	#; -------------------------------------------------------------------------------

 try {
	for col=1:1:metadata(0) {
		set colDef=$g(metadata(0,col))
		set colData=$g(metadata(1,col))
		CONTINUE:colDef="" 			// Row contains NO Information!
		CONTINUE:+$LG(colDef,10)	// Supress Output
		
		set colOutLen=$LG(colDef,4)
		write:$i(colPos)>1 delim write colData,$j("",colOutLen-$l(colData))
	}
	write !
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }

	QUIT
}

/// CSV Table Header
ClassMethod CSVtabHead(metadata, delim)
{
	#; -------------------------------------------------------------------------------
	#; Function:     CSVtabHead
	#; NOTE:         Assume 'file' is open and writable
	#; Purpose:      Create the Table Header for the specified CSV file
	#; Parameters:
	#;   metadata    - An array of the table metadata definitions
	#;                    [PASS BY REFERENCE]
	#;   delim       - The delimiter used to separate data elements
	#;
	#; Return: (NONE)
	#; -------------------------------------------------------------------------------

 try {
	for col=1:1:metadata(0) {	// --- Column Headers ---
		set colDef=$g(metadata(0,col))
		CONTINUE:colDef=""  		// Column contains NO Definition!
		CONTINUE:+$LG(colDef,10)	// Supress Output
		
		set colHead=$LG(colDef,2) if colHead="" { set colHead=$LG(colDef,1),$LIST(metadata(0,col),2)=colHead }
		write:$i(colPos)>1 delim write colHead
	}	
	write !
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }
	
	QUIT
}

/// CSV Table Data Row
ClassMethod CSVtabRow(metadata, delim)
{
	#; -------------------------------------------------------------------------------
	#; Function:     CSVtabRow
	#; NOTE:         Assume 'file' is open and writable
	#; Purpose:      Create the Table Data Row for the specified CSV file
	#; Parameters:
	#;   metadata    - An array of the table metadata definitions
	#;                    [PASS BY REFERENCE]
	#;   delim       - The delimiter used to separate data elements
	#;
	#; Return: (NONE)
	#; -------------------------------------------------------------------------------

 try {
	for col=1:1:metadata(0) {
		set colDef=$g(metadata(0,col))
		set colData=$g(metadata(1,col))
		CONTINUE:colDef=""  		// Row contains NO Information!
		CONTINUE:+$LG(colDef,10)	// Supress Output
		
		write:$i(colPos)>1 delim write colData
	}
	write !
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }
	
	QUIT
}

/// DLM Table Header
ClassMethod DLMtabHead(metadata, delim)
{
	#; -------------------------------------------------------------------------------
	#; Function:     DLMtabHead
	#; NOTE:         Assume 'file' is open and writable
	#; Purpose:      Create the Table Header for the specified DLM file
	#; Parameters:
	#;   metadata    - An array of the table metadata definitions
	#;                    [PASS BY REFERENCE]
	#;   delim       - The delimiter used to separate data elements
	#;
	#; Return: (NONE)
	#; -------------------------------------------------------------------------------

 try {
	for col=1:1:metadata(0) {	// --- Column Headers ---
		set colDef=$g(metadata(0,col))
		CONTINUE:colDef=""  		// Column contains NO Definition!
		CONTINUE:+$LG(colDef,10)	// Supress Output
		
		set colHead=$LG(colDef,2) if colHead="" { set colHead=$LG(colDef,1),$LIST(metadata(0,col),2)=colHead }
		write:$i(colPos)>1 delim write colHead
	}	
	write !
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }
	
	QUIT
}

/// DLM Table Data Row
ClassMethod DLMtabRow(metadata, delim)
{
	#; -------------------------------------------------------------------------------
	#; Function:     DLMtabRow
	#; NOTE:         Assume 'file' is open and writable
	#; Purpose:      Create the Table Data Row for the specified DLM file
	#; Parameters:
	#;   metadata    - An array of the table metadata definitions
	#;                    [PASS BY REFERENCE]
	#;   delim       - The delimiter used to separate data elements
	#;
	#; Return: (NONE)
	#; -------------------------------------------------------------------------------

 try {
	for col=1:1:metadata(0) {
		set colDef=$g(metadata(0,col))
		set colData=$g(metadata(1,col))
		CONTINUE:colDef=""  		// Row contains NO Information!
		CONTINUE:+$LG(colDef,10)	// Supress Output
		
		write:$i(colPos)>1 delim write colData
	}
	write !
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }
	
	QUIT
}

/// XML Worksheet Element
ClassMethod XMLsheet(name)
{
	#; -------------------------------------------------------------------------------
	#; Function:     XMLsheet
	#; NOTE:         Assume 'file' is open and writable
	#; Purpose:      Create the Worksheet Element for the specified XML file
	#; Parameters:
	#;   name    - The property name for the given <Worksheet> element
	#;
	#; Return: (NONE)
	#; -------------------------------------------------------------------------------

 try {
	&html< <Worksheet ss:Name="#(name)#">>
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }
	QUIT
}

/// XML Table Element
ClassMethod XMLtable(colCnt = 0, rowCnt = 0)
{
	#; -------------------------------------------------------------------------------
	#; Function:     XMLtable
	#; NOTE:         Assume 'file' is open and writable
	#; Purpose:      Create the Table Element for the specified XML file
	#; Parameters:
	#;   colCnt  - The number of columns for the table
	#;   rowCnt  - The number of rows for the table
	#;
	#; Return: (NONE)
	#; -------------------------------------------------------------------------------

 try {
	&html<  <Table ss:ExpandedColumnCount="#(colCnt)#" ss:ExpandedRowCount="#(rowCnt)#" x:FullColumns="1" x:FullRows="1">>
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }
	QUIT
}

/// XML Header Row Element
ClassMethod XMLrowHeader(metadata)
{
	#; -------------------------------------------------------------------------------
	#; Function:     XMLrowHeader
	#; NOTE:         Assume 'file' is open and writable
	#; Purpose:      Create the Header Row Element for the specified XML file
	#; Parameters:
	#;   metadata    - An array of the table metadata definitions
	#;                    [PASS BY REFERENCE]
	#;
	#; Return: (NONE)
	#; -------------------------------------------------------------------------------

 try {
	&html<   <Row ss:StyleID="s21">>
		for col=1:1:metadata(0) { 
	   		set colDef=$g(metadata(0,col))
			CONTINUE:colDef=""  		// Column contains NO Definition!
			CONTINUE:+$LG(colDef,10)	// Supress Output
			
			set colHead=$LG(colDef,2) if colHead="" { set colHead=$LG(colDef,1),$LIST(metadata(0,col),2)=colHead }
	   		&html<    <Cell><Data ss:Type="String">#(colHead)#</Data></Cell>> 
	   	}
	&html<   </Row>>
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }
	QUIT
}

/// XML Table Data Row Element
ClassMethod XMLtabRow(metadata)
{
	#; -------------------------------------------------------------------------------
	#; Function:     XMLtabRow
	#; NOTE:         Assume 'file' is open and writable
	#; Purpose:      Create the Table Data Row Element for the specified XML file
	#; Parameters:
	#;   metadata    - An array of the table metadata definitions
	#;                    [PASS BY REFERENCE]
	#;
	#; Return: (NONE)
	#; -------------------------------------------------------------------------------

 try {
	&html<   <Row>>
		for col=1:1:metadata(0) {
			set colDef=$g(metadata(0,col))
			set colData=$g(metadata(1,col))
			CONTINUE:colDef=""  		// Row contains NO Information!
			CONTINUE:+$LG(colDef,10)	// Supress Output
		
			set colType=$s($ISVALIDNUM(colData):"Number",1:"String")
			&html<    <Cell><Data ss:Type="#(colType)#">#(colData)#</Data></Cell>>
		}
	&html<   </Row>>
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }

	QUIT
}

/// XML Column Width Element
ClassMethod XMLcolWidth(width)
{
	#; -------------------------------------------------------------------------------
	#; Function:     XMLcolWidth
	#; NOTE:         Assume 'file' is open and writable
	#; Purpose:      Create the Column Width Element for the specified XML file
	#; Parameters:
	#;   width       - The width for the XML <Column> element
	#;
	#; Return: (NONE)
	#; -------------------------------------------------------------------------------

	&html<   <Column ss:Width="#(width)#"/>>

	QUIT
}

/// XML Column AutoFit Width Element
ClassMethod XMLcolAuto()
{
	#; -------------------------------------------------------------------------------
	#; Function:     XMLcolAuto
	#; NOTE:         Assume 'file' is open and writable
	#; Purpose:      Create the Column AutoFit Width Element for the specified XML file
	#; Parameters:
	#;   N/A
	#;
	#; Return: (NONE)
	#; -------------------------------------------------------------------------------

	&html<   <Column ss:AutoFitWidth="1"/>>

	QUIT
}

/// XML Sorting Element
ClassMethod XMLsort(sortColList, sortOrderList)
{
	#; -------------------------------------------------------------------------------
	#; Function:     XMLsort
	#; NOTE:         Assume 'file' is open and writable
	#; Purpose:      Create the Sorting Element for the specified XML file
	#; Parameters:
	#;   sortColList   - A $LIST of columns on which to sort the data
	#;   sortOrderList - A $LIST of {ASC | DESC} for each column
	#;
	#; Return: (NONE)
	#; -------------------------------------------------------------------------------

 try {
	for pos=1:1:$LL(sortColList) {
		&html<  <Sorting xmlns="urn:schemas-microsoft-com:office:excel"> <Sort>#($LG(sortColList,pos))#</Sort> <#($CASE($LG(sortOrderList,pos),"ASC":"Ascending","DESC":"Descending",:"Ascending"))#/> </Sorting>>
	}
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }
	QUIT
}

/// HTML Table Header
ClassMethod HTMLtabHead(aTag, title, metadata)
{
	#; -------------------------------------------------------------------------------
	#; Function:     HTMLtabHead
	#; NOTE:         Assume 'file' is open and writable
	#; Purpose:      Create the Table Header Element for the specified HTML file
	#; Parameters:
	#;   aTag        - The <a> tag name property value
	#;   title       - The Table Header title
	#;   metadata    - An array of the table metadata definitions
	#;                    [PASS BY REFERENCE]
	#;
	#; Return: (NONE)
	#; -------------------------------------------------------------------------------

 try {
	&html<  <a name="#(aTag)#"></a>>
	//&html<  <h3>#(title)#</h3>>
	&html<  <table border="2">>
	&html<   <tr>>
		for col=1:1:metadata(0) { 
	   		set colDef=$g(metadata(0,col))
			CONTINUE:colDef=""  		// Row contains NO Information!
			CONTINUE:+$LG(colDef,10)	// Supress Output

			set colHead=$LG(colDef,2) if colHead="" { set colHead=$LG(colDef,1),$LIST(metadata(0,col),2)=colHead }
	   		&html<    <th>#(colHead)#</th>> 
	   	}
	&html<   </tr>>
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }
	QUIT
}

/// HTML Table Row
ClassMethod HTMLtabRow(metadata)
{
	#; -------------------------------------------------------------------------------
	#; Function:     HTMLtabRow
	#; NOTE:         Assume 'file' is open and writable
	#; Purpose:      Create the Table Data Row Element for the specified HTML file
	#; Parameters:
	#;   aTag        - The <a> tag name property value
	#;   title       - The Table Header title
	#;   metadata    - An array of the table metadata definitions
	#;                    [PASS BY REFERENCE]
	#;
	#; Return: (NONE)
	#; -------------------------------------------------------------------------------

 try {
	&html<   <tr>>
		for col=1:1:metadata(0) {
			set colDef=$g(metadata(0,col))
			set colData=$g(metadata(1,col))
			CONTINUE:colDef=""  		// Row contains NO Information!
			CONTINUE:+$LG(colDef,10)	// Supress Output
		
			&html<    <td>#(colData)#</td>>
		}
	&html<   </tr>>
 }
 catch {
	set:tSC=$$$OK tSC=$$$ERROR($$$ObjectScriptError,$ze)
 }
	QUIT
}

}
