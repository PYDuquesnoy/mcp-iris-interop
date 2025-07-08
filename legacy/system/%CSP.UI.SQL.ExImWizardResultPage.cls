/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>This page process Link Table/Procedure Wizard Result.
Class %CSP.UI.SQL.ExImWizardResultPage Extends %CSP.Page [ System = 4 ]
{

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

ClassMethod OnPage() As %Status
{
	Set tMode = $G(%request.Data("Wizard",1),"Export")
	Set NAMESPACE = $G(%request.Data("$NAMESPACE",1))
	Set Schema = $G(%request.Data("Schema",1))
	Set Table = $G(%request.Data("Table",1))
	Set tTitle = $S(tMode="Export":$$$TextHTML("Export Result"),1:$$$TextHTML("Import Result"))
	&html<<html>
	<head>
	<title>#(tTitle)#</title>
	<link rel="stylesheet" type="text/css" href="#(..Link("/csp/sys/csputils.css"))#" title="Standard Style" >

	<script language="javascript">
	function popupClose()
	{
		window.close();
	}
	</script>

	<style>

pre {
	border: 1px black solid;
	background: white;
	margin: 20px;
}	

div.div {
	margin: 20px;
}

	</style>
	</head>
	<body onload="self.focus();">
	>
	Set msg1 = $$$TextHTML("This task will be run in the background.")
	Set msg2 = $$$TextHTML("Click here to view the background tasks page.")
	Set msg3 = $$$TextHTML("File does not exist")
	Set msg4 = $$$TextHTML("File extension is not allowed")
	Set msgPreview = $$$TextHTML("Data may be shown up to 10 rows")
	Set cmdClose = $$$TextHTML("Close")
	Set linkpage = ..Link("/csp/sys/%25CSP.UI.Portal.BackgroundTaskListPopup.zen")		
	Kill tParms
	Set FileName = $G(%request.Data("RemoteFileName",1))
	Set tParms("Wizard") = tMode
	Set tParms("NAMESPACE") = NAMESPACE
	Set tParms("FileName") = FileName
	Set tParms("Schema") = Schema
	Set tParms("Table") = Table
	Set tParms("Delimiter") = $G(%request.Data("Delimiter",1))
	Set tParms("StringQuote") = $G(%request.Data("StringQuote",1))
	Set tParms("DateFormat") = $G(%request.Data("DateFormat",1))
	Set tParms("TimeFormat") = $G(%request.Data("TimeFormat",1))
	Set tParms("TimeStampFormat") = $G(%request.Data("TimeStampFormat",1))
	Set tParms("NoCheck") = $S($G(%request.Data("NoCheck",1))'="":1,1:0)
	Set tParms("DeferIndices") = $S($G(%request.Data("DeferIndex",1))'="":1,1:0)
	Set tParms("HasHeaders") = $S($G(%request.Data("HasHeaders",1))'="":1,1:0)
	Set tParms("DelimiterChar") = $G(%request.Data("DelimiterChar",1))
	Set tParms("Charset") = $G(%request.Data("Charset",1))
	Set i = 1
	Set coldata = $G(%request.Data("selList",i))
	While coldata '= "" {
		Set colname = $P(coldata,"^",1)
		Set colfw = "fw"_colname
		// replace the coldata with user defined fixed width from the wizard
		If $G(%request.Data(colfw,1)) '= "" Set $P(coldata,"^",3) = $G(%request.Data(colfw,1))
		Set $li(tParms("Columns"),i) = coldata
		Set i = i + 1 
		Set coldata = $G(%request.Data("selList",i))
	}
 	Set tParms("TotalColumns") = i - 1
	If (tMode = "Export") {
		If $G(%request.Data("Preview",1)) '= "" {
			&html<<h1>#($$$TextHTML("Export Preview"))#</h1>
			<div class="Text1">#($zconvert(Schema,"O","HTML"))#.#($zconvert(Table,"O","HTML"))# #(msgPreview)#</div><hr>>
			Do ..ExportPreview(Schema,Table)
		} Else {
 			Set status = ##class(%CSP.UI.System.BackgroundTask).RunTask("SQLExport",NAMESPACE,.tParms,.tJob)
			If $$$ISERR(status) Do ..LogMsg($System.Status.GetErrorText(status))
 			&html<<h2>#(msg1)# &nbsp;<a href="#(linkpage)#">#(msg2)#</a></h2>>
		}
	} Else {
		Set FileName = ..GetFileName(.TempFileName)
		Set FileExists = ##class(%File).Exists(TempFileName)
		Set IsLocal = $G(%request.Data("InputType",1)) = "Local"
		Set tParms("IsLocal") = IsLocal
		Set tParms("TempFileName") = TempFileName
		Set tParms("FileName") = FileName
		
		// Verify that file extension is in the whitelist
		Set AllowedExts = $lb(".txt",".csv")
		Set FileAllowed = 0
		Set FileNameLower = $ZCVT(TempFileName,"L")
		For i=1:1:$ListLength(AllowedExts) {
			Set ext = $li(AllowedExts,i)
			If $E(FileNameLower,*-$Length(ext)+1,*)=ext {
				Set FileAllowed = 1
				Quit
			}
		}

		If $G(%request.Data("Preview",1)) '= "" {
			&html<<h1>#($$$TextHTML("Import Preview"))#</h1>
			<div class="div">#($zconvert(FileName,"O","HTML"))# - #(msgPreview)#</div><hr>
			>
						
			If 'FileExists {
				&html<<h2>#(msg3)#: #($ZCVT(TempFileName,"O","HTML"))#</h2>>
			} ElseIf 'IsLocal,'FileAllowed {
				&html<<h2>#(msg4)#: #($ZCVT(FileName,"O","HTML"))#</h2>>
			} Else {
				Do ..ImportPreview(TempFileName,IsLocal)
			}
		} Else {
 			If 'FileExists {
	 			&html<<h2>#(msg3)#: #($ZCVT(FileName,"O","HTML"))#</h2>>
 			} ElseIf 'IsLocal,'FileAllowed {
	 			&html<<h2>#(msg4)#: #($ZCVT(FileName,"O","HTML"))#</h2>>
 			} Else {
	 			Set status = ##class(%CSP.UI.System.BackgroundTask).RunTask("SQLImport",NAMESPACE,.tParms,.tJob)
				If $$$ISERR(status) Do ..LogMsg($System.Status.GetErrorText(status))
				&html<<h2>#(msg1)#<a href="#(linkpage)#">#(msg2)#</a></h2>>
 			}
		}
	}
	&html<<form>
		<div class="div" align="left">
		<input type="hidden" name="$NAMESPACE" id="$NAMESPACE" value="#($ZCVT(NAMESPACE,"O","HTML"))#">
		<input type="button" name="btnClose" value="#(cmdClose)#" onclick="popupClose();">
		</div>
		</form><br>
	>
	
	&html<</body>
	</html>>
	Quit $$$OK
}

ClassMethod ExportPreview(Schema As %String, Table As %String) As %String
{
	Set $ZT = "Trap1"
	Set tSC = $$$OK
	$$$ChangeNamespace
	Do {
		// Construct columns
		Set tCols = ""
		Set tCol = $O(%request.Data("selList",0))
		While tCol '= "" {
			Set tColName = $P(%request.Data("selList",tCol),"^",1)
			Set tCols = tCols _ tColName
			Set tCol = $O(%request.Data("selList",tCol))
			If $P(tCol,"^",1) '= "" Set tCols = tCols _ ","	
		}
		Do ##class(%SQL.Manager.API).CheckIdentifier(.tCols)
		// Construct table name
		Do ##class(%SQL.Manager.API).CheckIdentifier(.Schema)
		Do ##class(%SQL.Manager.API).CheckIdentifier(.Table)
		Set tQuery = "select top 10 " _ tCols _ " from "_Schema_"."_Table
		Set tRS = ##class(%ResultSet).%New("%DynamicQuery:SQL")
		Set tSC = tRS.Prepare(tQuery)
		If $$$ISERR(tSC) {
			Write !,$zconvert($System.Status.GetErrorText(tSC),"O","HTML")
			Quit	
		}
		Do tRS.Execute()
		If $$$ISERR(tRS) {
			Write !,$zconvert($System.Status.GetErrorText(tRS),"O","HTML")
			Quit
		}
		&html<<table width="95%" border="1" cellpadding="2" cellspacing="2" align="center"><tr>>
		For tCol=1:1:tRS.GetColumnCount() &html<<th>#($zconvert(tRS.GetColumnName(tCol),"O","HTML"))#</th>>
		While tRS.Next()
		{
			&html<<tr>>
			For tCol=1:1:tRS.GetColumnCount() &html<<td>#($S(tRS.GetData(tCol)'="":$zconvert(tRS.GetData(tCol),"O","HTML"),1:"&nbsp;"))#</td>>
			&html<</tr>>
		}
		Kill tRS,tSC	
	} While(0)
Done1
	Quit	
Trap1
	Set $ZT=""
	Write $ZE,!
	Goto Done1
}

/// Method to Export or Import in the background
ClassMethod Export(Wizard As %String, SchemaName As %String, TableName As %String, ByRef pParms As %String)
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		#; YSD2862 - audit what user wants to be done (user's selectiosn), regardless of actual result.
		Set EventDesc = "SQL "_Wizard
		Set EventData = ""
		Set p1 = ""
		For  Set p1 = $O(pParms(p1)) Quit:p1=""  Set EventData = EventData_p1_": "_pParms(p1)_$$$CRLF
		If Wizard = "Export" $$$SMPAuditExport
		Else  $$$SMPAuditImport	
		If pParms("FileName") = "" {
			Do ..LogMsg($$$Text("File Name is empty. Unable to continue."))
			Quit
		} Else {
			If Wizard = "Export" {
				#; If directory doesn't exists, create it now
				Set Dir = ##class(%File).GetDirectory(pParms("FileName"),1)
				Set tSC = ##class(%File).CreateDirectoryChain(Dir)
				If tSC '= 1 {
					Do ..LogMsg(Dir_": "_$$$Text("Could not create this directory. Please check the directory and try again."))
					Quit
				}
			}  
		}
		If Wizard = "Export" set mgr = ##class(%SQL.Export.Mgr).%New()
		Else  Set mgr = ##class(%SQL.Import.Mgr).%New()
		If mgr = "" {
			If Wizard["Import" { Set tmsg = $$$Text("Error creating object for SQL Import.") } 
			Else { Set tmsg = $$$Text("Error creating object for SQL Export.") }
			Do ..LogMsg(tmsg)
			Quit
		}
		Set mobj = ##class(%SQL.Manager.API).%New()
		Set mgr.IQN=$$$BuildIQN(SchemaName,TableName)
		Set ok = mobj.CheckIdentifier(.SchemaName)
		Set ok = mobj.CheckIdentifier(.TableName)
		Set classname = mobj.FindClassName(SchemaName_"."_TableName)
		If classname = "" Do ..LogMsg($$$Text("Class name is empty.")) Quit
	 	If $G(pParms("IsLocal")) = 1 Set pParms("FileName") = pParms("TempFileName")
		Set mgr.FileName = pParms("FileName")
		Set mgr.Charset = pParms("Charset")
		Set mgr.TableName = SchemaName_"."_TableName
		Set mgr.ClassName = classname
		Set mgr.Delimiter = ..ConvertDelimiter(.pParms)
		Set delim = pParms("StringQuote")
		Set mgr.StringQuote = $s(delim="":"",delim="double":"""",1:"'")
	 	Set mgr.DateFormat = pParms("DateFormat")
	 	Set mgr.TimeFormat = pParms("TimeFormat")
	 	Set mgr.TimeStampFormat = pParms("TimeStampFormat")
	 	Set mgr.NoCheck = pParms("NoCheck")
	  	Set mgr.HasHeaders = pParms("HasHeaders")
		For i = 1:1:pParms("TotalColumns") {
			Set coldata = $li(pParms("Columns"),i)
			Set colname = $p(coldata,"^",1)
			Set datatype = $p(coldata,"^",2)
		 	Set ok = mobj.CheckIdentifier(.colname)
		 	Do mgr.ColumnNames.Insert(colname)
		 	Set datatype = ..ConvertDataType(datatype)
		 	Do mgr.ColumnTypes.Insert(datatype)
		 	If mgr.Delimiter = "" do mgr.ColumnWidths.Insert($p(coldata,"^",3))
		}
 
		Set rows = 1000
		Set done = 0
		Set total = 0
		Set totalbytes = 0
		Set totalinserted = 0
		Set numerr = 0
		Set size = 0
		Set header = ""
		If Wizard = "Export" {
			Set result = mgr.GenerateExportRoutine()
			If result '= 1 {
				Set tmsg = $$$Text("Error generating export routine: ")_result
				Do ..LogMsg(tmsg)
				Quit
			}
			Set sta = mgr.OpenExport()
			If $$$ISERR(sta) {
				Set ErrMsg = $$$Text("Unable to open export file")
				Set msgError = $$$Text("ERROR")
				Do ##class(%CSP.UI.SQL.LinkWizardResultPage).LogMsg(ErrMsg,msgError)
			} Else {
				Set sta = mgr.GetExportSize(.size)
				If size = 0 {
					Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") = $$$Text("No data to export")
				} Else {
					Set tSC = $$$OK
					Do {
						Set tSC = mgr.ExportRows(.rows,.done)
						Set total = total + rows
						If $$$ISERR(tSC) Do ..LogMsg($System.Status.GetErrorText(tSC)) Quit
					} While done = 0
					If $$$ISOK(tSC) {
						Set tmsg = $$$FormatText($$$Text("Completed at %1"),$zdt($h))
					} Else {
						Set tmsg = $$$Text("Error occurred during export.")
					}
					Set statusmsg = $$$FormatText($$$Text("Exported: %1 rows"),total)
					Do ..LogMsg(tmsg,statusmsg)
				}
				Do mgr.CloseExport()
			}
			Do mgr.DeleteExportRoutine()
		} 
		Else {	// Import
		 	Set mgr.DeferIndices = pParms("DeferIndices")
			Set result = mgr.GenerateImportRoutine()
			If result '= 1 {
				Set tmsg = $$$Text("Error generating import routine: ")_result
				Do ..LogMsg(tmsg)
				Quit
			}
			Set sta = mgr.OpenImport()
			If $$$ISERR(sta) {
				Set ErrMsg = $$$Text("Unable to open import file")
				Set msgError = $$$Text("ERROR")
				Do ##class(%CSP.UI.SQL.LinkWizardResultPage).LogMsg(ErrMsg,msgError)
			} Else {
				If mgr.HasHeaders = 1 Set sta = mgr.ReadHeader(.header,.size)
				//pgbFinish.max = mgr.filesize()
				Set tSC = $$$OK
				Do {
					Set tSC = mgr.ImportRows(.rows,.inserted,.bytes,.done,.numerr,total)
					Set total = total + rows
					Set totalinserted = totalinserted + inserted
					Set totalbytes = totalbytes + bytes
					If $$$ISERR(tSC) Do ..LogMsg($System.Status.GetErrorText(tSC)) Quit
				} While done = 0
				Do mgr.BuildIndices()
				If mgr.ErrorCount() > 0 {
					Do ..LogMsg(,"ERROR")
					Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"ErrorLog") = mgr.ErrorCount()
					Merge ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"ErrorLog")=^IRIS.TempSQLImp($J)
				} Else {
					If $$$ISOK(tSC) {
						Set tmsg = $$$FormatText($$$Text("Completed at %1"),$zdt($h))
					} Else {
						Set tmsg = $$$Text("Error occurred during import.")		 	
					}
					Set statusmsg = $$$FormatText($$$Text("Imported: %1 rows"),totalinserted)
					Do ..LogMsg(tmsg,statusmsg)
				}	 	
				Do mgr.CloseImport(0)
			}
			Do mgr.DeleteImportRoutine()
		}
		Set mobj = ""		
	} While(0)
Done
	Quit	
Trap
	Set $ZT=""
	Do ..LogMsg($ZE)
	Goto Done
}

/// Method to Export dynamic query result in the background 
ClassMethod QueryExport(ByRef pParms) As %String
{
	Set $ZT = "Trap"
	Do {
	    If pParms("FileName") = "" {
		    Do ..LogMsg($$$Text("FileName is empty. Unable to continue."))
		    Quit
	    } 
	    Set Dir = ##class(%File).GetDirectory(pParms("FileName"),1)
 		Set tSC = ##class(%File).CreateDirectoryChain(Dir)
		If tSC '= 1 {
			Do ..LogMsg(Dir_": "_$$$Text("Could not create this directory. Please check the directory and try again."))
			Quit
		}
		#;YSD2777 Set Query = $G(^mqh($UserName,+$G(pParms("HistoryId"))))
		Set Query = ##class(%CSP.UI.Portal.SQL.Home).GetText(+$G(pParms("HistoryId")))
		If Query = "" {
		    Do ..LogMsg($$$Text("Cannot find Query. Unable to continue.")_" HistoryId="_$G(pParms("HistoryId")))
		    Quit			
		}
		Set EventDesc = "SQL Query Export"
		Set EventData = "Query text: "_$$$CRLF_Query_$$$CRLF
		Set EventData = EventData _ "RuntimeMode: "_pParms("RuntimeMode")_$$$CRLF
		Set EventData = EventData _ "Dialect: "_pParms("Dialect")_$$$CRLF
		Set EventData = EventData _ "ObjectSelectMode: "_pParms("ObjectSelectMode")_$$$CRLF
		Set EventData = EventData _ "DisplayMode: "_pParms("DisplayMode")_$$$CRLF
		Set EventData = EventData _ "FileName: "_pParms("FileName")_$$$CRLF
		$$$SMPAuditExport

		Set tStatement = ##class(%SQL.Statement).%New()
		Set tStatement.%SelectMode = pParms("RuntimeMode")
		Set tStatement.%Dialect = pParms("Dialect")
		Set tStatement.%ObjectSelectMode = pParms("ObjectSelectMode")
		Do tStatement.prepare(.Query)
		Set tResult = tStatement.%Execute()
		
		#; extract the extention from the DisplayFile as %SQL.Shell does not use it and will not create file if you have it.
		Set File = ##class(%File).GetFilename(pParms("FileName"))
		Set Mode = pParms("DisplayMode")
		Set ext = $Case(Mode,"0":"xml","1":"html","2":"pdf","99":"txt",:"csv")
		Set File = $P(File,"."_ext,1)
		#; generate random filename if only have directory path
		If File = "" {
			Set File = $translate($zstrip($SYSTEM.Encryption.Base64Encode($system.Encryption.GenCryptRand(10)),">","="), "+/", "ab")
		}
		Set tFileName = ##class(%File).NormalizeFilename(File_"."_ext,Dir)
		
		#; Test if valid directory for writing
		If '##class(%File).Writeable(Dir) {
			Do ..LogMsg($$$Text("Export Directory is not writeable"))
			Quit
		}

		If (Mode '= "100") {

			#; Test if valid file name - note actual filename may be slightly different
			If (tFileName'="")&&'##class(%File).Exists(tFileName) {
				Try {
					Open tFileName:"WNS":1
					If '$Test {
						Do ..LogMsg($$$Text("Unable to create export file. Check if filename valid."))
						Return
					}
					Close tFileName
					Do ##class(%File).Delete(tFileName)
				} Catch { 
					Do ..LogMsg($$$Text("Unable to create export file."))
					Return
				}
			}
			#; End of valid filename test

			Set tShell = ##class(%SQL.Shell).%New()
			Set tShell.DisplayMode = Mode
			Set tShell.SelectMode = pParms("RuntimeMode")
			Set tShell.DisplayPath = Dir
			Set tShell.DisplayFile = File
			Do tShell.displayResult(tResult)
		} Else {
			#; duplicate behavior of %SQL.Shell, but with comma-delimited header and data
			Set tMessages = ##class(%SQL.Manager.Messages).%New()
			If (pParms("RuntimeMode") = 0) {
				Do tMessages.Insert("WARNING: Formatted display of results in LOGICAL mode might fail if the results contain control characters!")
				Do tMessages.Insert("         A common result column containing a $List value, such as a list collection, will contain control characters")
				Do tMessages.Insert("         and an empty result file will be displayed.")
			}

			If tResult.%SQLCODE < 0 {
				Do tMessages.Insert("[SQLCODE: <"_tResult.%SQLCODE_">:<"_$$sqlcode^%apiSQL(tResult.%SQLCODE)_">]")
				If tResult.%Message '= "" { Do tMessages.Insert("[%msg: <" _ tResult.%Message _ ">]") }
			} Else {
				Open tFileName:"WNS":1
				If '$Test {
					Do ..LogMsg($$$Text("Unable to create export file. Check if filename valid."))
					Quit	
				}
				Set tFileOpen = 1
				Use tFileName
				#; write the header row
                #define CSVEscapeValue(%elem) if (%elem [ ",")  || (%elem [ $Char(10)) || (%elem [ $Char(13)) || (%elem [ """") { set %elem = $zu(144,1,%elem) }
				Set tMetadata = tResult.%GetMetadata()
				Set tColumnCount = tMetadata.columnCount
				Set line = ""
				For i=1:1:tColumnCount {
					Set line = $S(""=line: "", 1: line_","), colName = tMetadata.columns.GetAt(i).colName
                    $$$CSVEscapeValue(colName)
                    Set line = line_colName
				}
				Write line_$$$CRLF
				#; write out the comma-delimited results
				While tResult.%Next(.tSC) && '$$$ISERR(tSC) {
                    #; duplicate behavior of %SQL.IResultSet::%Print(), but with quoting of values that contain "
					set tRSMD = tResult.%GetMetadata()
                    set tColumns = tRSMD.columns.Count()
                    if tColumns {
                        set tValue = tResult.%GetData(1)
                        $$$CSVEscapeValue(tValue)
                        try { if tValue'="",$listvalid(tValue) { set tValue=$$Quote^%qcr(tValue) } } catch { }	// write out $list values in readable format
                        write tValue
                        for tPtr = 2:1:tColumns {
                            set tValue = tResult.%GetData(tPtr)
                            $$$CSVEscapeValue(tValue)
                            try { if tValue'="",$listvalid(tValue) { set tValue=$$Quote^%qcr(tValue) } } catch { }	// write out $list values in readable format
                            write ",",tValue
                        }
                        write !
                    }
				}
                #undef CSVEscapeValue
				Close tFileName
				Set tFileOpen = 0

				If tResult.%SQLCODE < 0 {
					Do tMessages.Insert("[SQLCODE: <"_tResult.%SQLCODE_">:<"_$$sqlcode^%apiSQL(tResult.%SQLCODE)_">]")
					If tResult.%Message '= "" { Do tMessages.Insert("[%msg: <" _ tResult.%Message _ ">]") }
				}

				Do tMessages.Insert(+(tResult.%ROWCOUNT) _ " row(s) affected.")
			}
			Set tMessagesFile = ##class(%File).NormalizeFilename(File_"Messages",Dir)
			Do tMessages.%DisplayFormatted("100",tMessagesFile)
		}

		Set tmsg = $$$FormatText($$$Text("Completed at %1"),$zdt($h))
		Do ..LogMsg(tmsg,$$$Text("Done"))
	} While(0)
Done
	Quit 
Trap
	Set $ZT=""
	Do ..LogMsg($$$Text("Error occurred")_": "_$ZE)
	If $Get(tFileOpen) {
		Close tFileName
	}
	Goto Done
}

ClassMethod ImportPreview(FileName As %String, IsLocal As %Boolean, tMaxRows As %Integer = 10) As %String
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	$$$ChangeNamespace
	Do {
		set thisdevice = $i
		&html<
		<table class="box"><tr><td><pre>
		>
		open FileName::5 if '$t &html<<br>#($$$TextHTML("Cannot open file"))#> quit
		set line = "",tRow = 0
		if tMaxRows = 0 {
			for  use FileName read line use thisdevice set line = $ZCVT(line,"O","HTML") Write "<br>"_(line),! 
		} else {
			Do {
				set tRow = tRow + 1
				use FileName read line
				use thisdevice set line = $ZCVT(line,"O","HTML") s:line="" line="&nbsp;" Write "<br>"_(line),!
			} While tRow '> tMaxRows
		}
		close FileName
		use thisdevice 
		
		&html<</pre></td></tr></table>>	

		If IsLocal {
			Do ##class(%CSP.UI.System.Utils).DeleteLocalUpload(FileName)
		}
	} While(0)
Done
	Quit	
Trap
	close FileName
	use thisdevice 
	Set $ZT=""
	Write "</pre></td></tr></table>"
	Quit
}

ClassMethod ConvertDelimiter(ByRef pParms As %String) As %String
{
	
	if pParms("Delimiter") = 0 quit $c(9)
	if pParms("Delimiter") = 1 quit " "
	//fixed width
	if pParms("Delimiter") = 2 quit ""
	if pParms("Delimiter") = 3 quit pParms("DelimiterChar")
  quit $c(9)
}

ClassMethod DelimiterMeaning(ByRef pParms As %String) As %String
{
	if pParms("Delimiter") = 0 quit $$$Text("Tab")
	if pParms("Delimiter") = 1 quit $$$Text("Space")
	//fixed width
	if pParms("Delimiter") = 2 quit $$$Text("Fixed Width")
	if pParms("Delimiter") = 3 quit pParms("DelimiterChar")
  quit $c(9)
}

/// Convert cache data type properties to SQL Manager Export/Import class method data type
ClassMethod ConvertDataType(datatype As %String) As %String
{
	QUIT:datatype="%Library.Date" "D"
	QUIT:datatype="%Library.Time" "T"
	QUIT:datatype="%Library.TimeStamp" "TS"
	QUIT:$$checkDataType^%apiDDL2(datatype,$lb("%Library.Vector")) "V"
	QUIT:$$$getClassType(datatype)=$$$cCLASSCLASSTYPESTREAM "STREAM"
	if datatype = "%Library.Integer" || (datatype = "%Library.Boolean") || (datatype = "%Library.Float") || (datatype = "%Library.Numeric") || (datatype = "%Library.SmallInt") || (datatype = "%Library.TinyInt") || (datatype = "%Library.Currency") QUIT "N"
 	QUIT "S"
}

/// Given internal value of date format, return displable date format
ClassMethod DateFormatMeaning(dateformat As %String) As %String
{
	set sFormat = "MM/DD/{YY}YY|DD Mmm {YY}YY|YYYY-MM-DD|DD/MM/{YY}YY|Mmm D,YYYY|Mmm D YYYY|Mmm DD {YY}YY|YYYYMMDD|Mmmmm D YYYY|YYYY/MM/DD"
	quit $p(sFormat,"|",dateformat)
}

/// Given internal value of timestamp format, return displable timestamp format
ClassMethod TimeStampFormatMeaning(timestampformat As %String) As %String
{
	set sFormat = "ODBC Format|T-SQL Format [MDY]|T-SQL Format [DMY]|T-SQL Format [YMD]|T-SQL Format [YDM]|T-SQL Format [MYD]|T-SQL Format [DYM]|YYYY-MM-DD-HH:MI:SS|YYYY-MM-DDTHH:MI:SS"
	QUIT $p(sFormat,"|",timestampformat)
}

/// Given internal value of time format, return displable time format
ClassMethod TimeFormatMeaning(timeformat As %String) As %String
{
	set sFormat = "hh:mm:ss|hh:mm|hh:mm:ss[AM/PM]|hh:mm[AM/PM]"
	quit $p(sFormat,"|",timeformat)
}

/// Return file name for Import (if it's Local then move the file to the remote instance)
ClassMethod GetFileName(ByRef TempFileName As %String) As %String
{
	Set (FileName,TempFileName) = $G(%request.Data("RemoteFileName",1))
	If $G(%request.Data("InputType",1)) = "Local" {
		Set FileName = %request.MimeData("LocalFileName",1).FileName
		If FileName = "" Quit FileName
		Set dir = ##class(%File).SubDirectoryName($zu(12),"Temp")
		Set dir = ##class(%File).NormalizeDirectory(dir)
		If ##class(%File).DirectoryExists(dir) = 0 {
			Do ##class(%File).CreateDirectory(dir)
		}
		Set file = ##class(%FileBinaryStream).%New()
		#;YSD1685 If $$$isVMS Set TempFileName = dir_$P(FileName,"]",2)
		#;YSD1685 Else  Set TempFileName = dir_$P(FileName,$E(dir,$L(dir)),$L(FileName,$E(dir,$L(dir))))
		Set TempFileName = dir_##class(%File).GetFilename(FileName)
		Set status = file.LinkToFile(TempFileName)
		Set stream = %request.GetMimeData("LocalFileName",1)
		Set status = file.CopyFrom(stream)
		If status Set status = file.SaveStream()
		Do stream.Clear()  // erase the source file	
	}
	Quit FileName
}

/// Log error into ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") and ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details")
ClassMethod LogMsg(ErrMsg As %String = "", Status As %String = "ERROR")
{
	Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details") = $G(^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details")) _" " _ ErrMsg
	Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") = Status
}

/// Ensure user has %Development:USE.
/// Set cookie to remember file for mode.
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	If '$system.Security.Check($$$DevelopmentResourceName,"USE") Quit 0
	Set tMode = $G(%request.Data("Wizard",1),"Export")
	Set FileName = $G(%request.Data("RemoteFileName",1))
	Set $$$IRISTempMgt($UserName,"LastFile","SQL",tMode) = FileName
	Quit 1
}

}
