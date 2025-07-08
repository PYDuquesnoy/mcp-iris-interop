/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base procedure context interface
Class %Library.IProcedureContext Extends %SQL.StatementResult [ Abstract, System = 2 ]
{

/// Holds oref of the current resultset currently bound. Deprecated - use %CurrentResult.
Property CurrentResult As %RegisteredObject [ Deprecated, Internal ];

Method CurrentResultGet() As %Library.RegisteredObject [ CodeMode = expression, Internal ]
{
..%CurrentResult
}

Method CurrentResultSet(value As %RawString) As %Library.Status [ CodeMode = expression, Internal ]
{
..%CurrentResultSet(value)
}

Property Error As %SYSTEM.Error;

Method ErrorSet(newvalue As %RawString) As %Status [ Internal, ServerOnly = 1 ]
{
		#; if newvalue if not a valid oref, quit with error, or if new value is same as old value we are done
	if newvalue'=$$$NULLOREF { If '$$$objExists(newvalue) { Quit $$$ERROR($$$OrefInvalid,newvalue) } if r%Error=newvalue { Quit $$$OK } }
	set r%Error=newvalue,i%Error=1,i%Error=$$$NULLOID
	if $isobject(newvalue) { do newvalue.getOdbcError(.tSQLCODE,.tMessage) set ..%SQLCODE = tSQLCODE, ..%Message = tMessage } else { set ..%SQLCODE = 0, ..%Message = "" }
	quit $$$OK
}

/// Called to return the next resultset object.
/// This also removes the reference to the existing object so it can cleanup and close itself
Method NextResult() As %RegisteredObject
{
	Quit $$$NULLOREF
}

/// Close the current resultset object, used to allow the cleanup code to run and the cursor to close
Method CloseCurrentResult() As %Status
{
	Quit $$$OK
}

Method %ResultColumnCountGet() [ CodeMode = expression, Internal ]
{
..%ProcCursor.%ResultColumnCount
}

Method %ProcCursorGet() [ Internal ]
{
	If r%%ProcCursor = "" { set ..%ProcCursor=..%NextResult() set:$isobject(r%%ProcCursor)=1 ..%SQLCODE = ..%ProcCursor.%SQLCODE, ..%Message = ..%ProcCursor.%Message } Quit r%%ProcCursor
}

/// %MoreResults() will serially bind the next result set to the result object cursor
/// (implemented as %Next()). If a result set was previously bound to the result object
/// cursor (referred to as the "procedural cursor" by the SQL Standard) then it will be
/// unbound and the reference to that result set removed. Under normal circumstances the previously
/// bound result set is destructed.
Method %MoreResults() As %Integer
{
	set tProcCursor = ..%NextResult(), ..%ProcCursor = tProcCursor
	if $Isobject(tProcCursor) { set ..%SQLCODE = tProcCursor.%SQLCODE, ..%Message = tProcCursor.%Message, ..%ROWCOUNT = tProcCursor.%ROWCOUNT } else { set ..%ROWCOUNT = 0 }
	quit $IsObject(tProcCursor)
}

/// Advance the procedural result set cursor to the next row. Returns 0 if the cursor is at the end of the 
/// result set or if an error was encountered. Errors are reported in dynamic SQL using the %SQLCODE and %Message 
/// properties of the statement result. An optional argument will contain a %Status value on return. This %Status value 
/// indicates success or failure of the %Next call but it should be considered to be a secondary error reporting interface, 
/// <property>%SQLCODE</property> being the primary error reporting mechanism. 
/// This implementation can be overridden by classes that implement the procedural cursor interface. 
Method %Next(ByRef pStatus As %Library.Status) As %Library.Integer
{
	try {
		set pStatus = $$$OK
		if $Isobject(..%ProcCursor) {
			set tReturn = ..%ProcCursor.%Next(.pStatus)
			set ..%SQLCODE = ..%ProcCursor.%SQLCODE, ..%Message = ..%ProcCursor.%Message
			if $$$ISERR(pStatus) {
				$$$ThrowStatus(pStatus)
			}
			set ..%ROWCOUNT = ..%ProcCursor.%ROWCOUNT
		}
		else { set tReturn = 0 }
	}
	catch tException {
		#dim tException as %Exception.AbstractException
		set ..%SQLCODE = tException.AsSQLCODE(), ..%Message = tException.AsSQLMessage()
		set pStatus = tException.AsStatus()
		set tReturn = 0
	}
	quit tReturn
}

/// Returns the value of the column with the name <var>pColumnName</var> in the current row of the result set.
/// <p>If <var>pColumnName</var> is not a valid column name, this method returns an empty string.
Method %Get(pColumnName As %String = "") As %Library.String [ CodeMode = expression ]
{
..%ProcCursor.%Get(.pColumnName)
}

/// Returns the value of column <var>pColumnNumber</var> in the current row of the result set.
Method %GetData(pColumnNumber As %Integer = 0) As %Library.String [ CodeMode = expression ]
{
..%ProcCursor.%GetData(.pColumnNumber)
}

/// Return the result set metadata as a %SQL.StatementMetadata instance.
Method %GetMetadata() As %SQL.StatementMetadata [ CodeMode = expression ]
{
$Select($Isobject(..%ProcCursor):..%ProcCursor.%GetMetadata(),1:$$$NULLOREF)
}

/// Fetch and send a series of rows for the ODBC/JDBC server. For internal use only.
Method %SendODBC() As %Library.Integer [ CodeMode = expression, Internal ]
{
..%ProcCursor.%SendODBC()
}

/// Fetch and send a series of rows for continuous query client. For internal use only.
Method %SendDelimitedRows(pMaxRows As %Integer = 0, pDelimiter As %String = "", ByRef pReturnCount As %Integer = 0) As %Status [ CodeMode = expression, Internal ]
{
..%ProcCursor.%SendDelimitedRows(.pMaxRows,.pDelimiter,.pReturnCount)
}

/// %SendObjects iterates over the rows in the result set and calls object export (quick load) on
/// each column that is present in ..%Objects. For internal use only.
Method %SendObjects(pObjectCount As %Integer = 0, pLock As %Integer = 0) As %Library.Integer [ CodeMode = expression, Internal ]
{
..%ProcCursor.%SendObjects(.pObjectCount,.pLock)
}

/// Print the contents of the current row on the current device.
Method %Print(pDelimiter As %String = " ") As %Status [ CodeMode = expression ]
{
..%ProcCursor.%Print(.pDelimiter)
}

Method %DispatchGetProperty(pProperty As %String(MAXLEN=255)) [ Internal ]
{
	set tPROPERTY = $$$ucase(pProperty)
	if (tPROPERTY = "SQLCODE") || (tPROPERTY = "%SQLCODE") { quit ..%SQLCODE }
	elseif (tPROPERTY = "%ROWID") { quit ..%ROWID }
	elseif (tPROPERTY = "%ROWCOUNT") || (tPROPERTY = "ROWCOUNT") { quit ..%ROWCOUNT }
	elseif (tPROPERTY = "%MESSAGE") || (tPROPERTY = "MESSAGE") { quit ..%Message }
	else { $$$ThrowPropertyDoesNotExistError(pProperty) }
	quit ""
}

/// Property dispatch method to catch references to 
/// virtual properties.<br>
/// This should not be called directly.<br>
Method %DispatchSetProperty(pProperty As %String, pValue As %String) [ Internal ]
{
	set tPROPERTY = $$$ucase(pProperty)
	if (tPROPERTY = "SQLCODE") || (tPROPERTY = "%SQLCODE") { set ..%SQLCODE = pValue }
	elseif (tPROPERTY = "%ROWID") { set ..%ROWID = pValue }
	elseif (tPROPERTY = "%ROWCOUNT") || (tPROPERTY = "ROWCOUNT") { set ..%ROWCOUNT = pValue }
	elseif (tPROPERTY = "%MESSAGE") || (tPROPERTY = "MESSAGE") { set ..%Message = pValue }
	else { $$$ThrowPropertyDoesNotExistError(pProperty) }
	quit ""
}

/// Display the contents of this object on the current device
Method %Display(pDelimiter As %String = {$Char(9)})
{
	new %sqlcontext
	set %sqlcontext = $this
	if ..%SQLCODE < 0 {
		write !!,"[SQLCODE: <",..%SQLCODE,">:<",$$sqlcode^%apiSQL(..%SQLCODE),">]",!
		if ..%Message'="" { write "[%msg: <",..%Message,">]",! }
	}
	else {
		if $Data(..%OutputValues) {
			write !!,"Output Values: ",!
			set tPtr = $Order(..%OutputValues(""))
			while tPtr '= "" {
				write !,$justify(tPtr,2),". ",..%OutputValues(tPtr)
				set tPtr = $Order(..%OutputValues(tPtr))
			}
		}
		For tPtr = 1:1 {
			set tRS = ..%NextResult()
			If '$isobject(tRS) Quit
			Write !!,"Dumping result #",tPtr,!
			do tRS.%Display(pDelimiter)
		}
	}
	Quit
}

/// <p>Display the contents of the %OutputValues() multidimentional property. If formatted display is available then format the results
/// using the requested format and, if appropriate, open the formatted results using the host OS. The output
/// is directed to one or more files and messages are placed in a result set object. All file names used
/// are returned in an array.</p>
/// <br>
/// 	<p>
/// 		<h4>Parameters</h4><br>
/// 		<table border="1" title="Parameters">
/// 			<tr>
/// 				<th>Name</th><th>Description</th>
/// 			</tr>
/// 			<tr>
/// 				<td>pFormat</td>
/// 				<td>
/// 					<p>The format applied to the result content. This parameter is also used to determine the file name extension.</p>
/// 				<p>Supported formats are:<br>
/// 						<table>
/// 						<tr><td>-1</td><td>%Display() format</td></tr>
/// 						<tr><td>0</td><td>XML</td></tr>
/// 						<tr><td>1</td><td>HTML</td></tr>
/// 						<tr><td>2</td><td>PDF (requires a renderer such as FOP)</td></tr>
/// 						<tr><td>99</td><td>TXT</td></tr>
/// 						<tr><td>100</td><td>CSV</td></tr>
/// 						</table>
/// 					</p>
/// 				<p>If <var>pFormat</var> is specified as any number not listed above then it will default to TXT.</p>
/// 					<p><var>pFormat</var> can also be specified as XML, HTML, PDF, TXT or CSV.</p>
/// 					<p><i>NOTE: <var>pFormat</var> of CSV/100 is not a true comma separated value, but instead behaves the same as TXT, displaying each %OutputValues() on a numbered line.</i></p>
/// 				</td>
/// 		</tr>
/// 			<tr>
/// 				<td>pFileName</td>
/// 				<td>
/// 					<p>The base file name to be used to generate actual file names used for output. If no value is specified
/// 						then a file name will be generated, using the TEMP folder defined for the InterSystems IRIS instance.
/// 						This value is not expected to include an extension. An extension is added to this value to form the actual
/// 						file used. Also, if nested results exist then a number is appended to the file name specified to produce a unique
/// 						name for each result.
/// 					</p>
/// 				</td>
/// 		</tr>
/// 			<tr>
/// 				<td>pMessages</td>
/// 				<td>
/// 					<p>Instance of a system result set class. If no value is passed then the system message result class is instantiated.
/// 						This parameter is passed by reference. It is up to the caller to process the result set oref that is returned.
/// 						pMessages.Count() returns the number of messages contained in the result set. pMessages.%Display() will display the
/// 						messages on the current device. pMessages.%DisplayFormatted() is also implemented and can be used to display the
/// 						messages using the selected format.
/// 					</p>
/// 				</td>
/// 		</tr>
/// 			<tr>
/// 				<td>pFilesUsed</td>
/// 				<td>
/// 					<p>This pass-by-reference parameter will contain the number of files used to display the result content and the name of
/// 						each file. pFilesUsed is the number of files and pFilesUsed(<var>file_number</var>) is the name of the file. The
/// 						sequence of the files is the same sequence as the results are processed. For simple result objects, there is a single
/// 						file. For context objects that can contain result set sequences, the results are output in the order they are returned
/// 						and the files used are present in pFilesUsed in that same order.
/// 					</p>
/// 				</td>
/// 		</tr>
///  			<tr>
///  				<td>pTranslateTable</td>
///  				<td>
///  					<p>This is the translate table used for the output files when the format is CSV or TXT. This parameter is optional. 
///  					</p>
///  				</td>
///  		</tr>
/// 		</table>
/// </p>
/// <br>
Method %DisplayFormatted(pFormat As %String = -1, ByRef pFileName As %String(MAXLEN="") = "", ByRef pMessages As %SQL.Manager.Messages = "", ByRef pFilesUsed As %String(MAXLEN="") = 0, pTranslateTable As %String(MAXLEN="") = "", pDelimiter As %String)
{
#define NewFileRoot					$translate($zstrip($SYSTEM.Encryption.Base64Encode($system.Encryption.GenCryptRand(10)),">","="), "+/", "ab")
#define TempFilePath				##class(%File).NormalizeDirectory(##class(%ZEN.Report.reportPage).%GetTempDir())
	if '$IsObject(pMessages) { set pMessages = ##class(%SQL.Manager.Messages).%New() }
		// Convert a text pFormat to integer
	if +pFormat '= pFormat { set pFormat = $Case($$$ucase(pFormat),"XML":0,"HTML":1,"PDF":2,"CSV":100,:99) }
	new %context,%count,%filter,%report,%sqlcontext
	set %sqlcontext = $this, tFileOpen = 0
	try {
		set tExtension = $Case(pFormat,0: "xml", 1: "html", 2: "pdf", 100: "csv", :"txt")
		if pFileName '= "" { if '$Find("/\",$Extract(pFileName,*)) { set tFileRoot = pFileName } else { set tFileRoot = pFileName _ $$$NewFileRoot } }
		else { set tFileRoot = $$$TempFilePath _ $$$NewFileRoot }
		if ..%SQLCODE < 0 {
			do pMessages.Insert("[SQLCODE: <"_..%SQLCODE_">:<"_$$sqlcode^%apiSQL(..%SQLCODE)_">]")
			if ..%Message'="" {do pMessages.Insert("[%msg: <" _ ..%Message _ ">]") }
		}
		if ..%OutputColumnCount > 0 {
			set tFileName = tFileRoot _ "." _ tExtension
			if (pFormat < 99) && (pFormat '= -1) {
				/*
					// Retrieve or generate a formatted report display for this context object
				set tClassDefinitionId = ##class(%SYS.SQLStatementCache).FormattedDisplayClassGet(..%ClassName(1))
				if tClassDefinitionId = "" { set tClassDefinitionId = ##class(%SQL.DynamicStatement).GenerateFormattedDisplay($this) }
				if tClassDefinitionId '= "" {
					set tReturn = 1
					set tReport = $zobjclassmethod(tClassDefinitionId,"%New")
					set tReport.ResultSet = $this, tReport.ResultTitle = "Result #"_pFilesUsed
					do tReport.GenerateReport(tFileName,pFormat)
				}
				else {
					*/
					open tFileName:("WNS"_$Select(pTranslateTable="":"",1:"K\"_pTranslateTable_"\"))
					set tFileOpen = 1
					use tFileName
					set pFilesUsed = pFilesUsed + 1, pFilesUsed(pFilesUsed) = tFileName
					write !!,"Output Values: ",!
					set tPtr = $Order(..%OutputValues(""))
					while tPtr '= "" {
						write !,$justify(tPtr,2),". ",..%OutputValues(tPtr)
						set tPtr = $Order(..%OutputValues(tPtr))
					}
					close tFileName
					set tFileOpen = 0
			/*
				}
				*/
			}
			else {
				open tFileName:("WNS"_$Select(pTranslateTable="":"",1:"K\"_pTranslateTable_"\"))
				set tFileOpen = 1
				use tFileName
				set pFilesUsed = pFilesUsed + 1, pFilesUsed(pFilesUsed) = tFileName
				write !!,"Output Values: ",!
				set tPtr = $Order(..%OutputValues(""))
				while tPtr '= "" {
					write !,$justify(tPtr,2),". ",..%OutputValues(tPtr)
					set tPtr = $Order(..%OutputValues(tPtr))
				}
				close tFileName
				set tFileOpen = 0
			}
		}
			// Results will display to their own file name.
		set tResult = ..%NextResult(), tResultCounter = 0
		while $Isobject(tResult) {
			try {
				set tResultCounter = tResultCounter + 1
				do tResult.%DisplayFormatted(pFormat,tFileRoot _ tResultCounter,pMessages,.pFilesUsed,.pTranslateTable,.pDelimiter)
			}
			catch tExceptionInner {
				set tSQLCODE = tExceptionInner.AsSQLCODE()
				set tSQLMessage = tExceptionInner.AsSQLMessage()
				do pMessages.Insert("[SQLCODE: <"_tSQLCODE_">:<"_$$sqlcode^%apiSQL(tSQLCODE)_">]")
				if tSQLMessage'="" {do pMessages.Insert("[%msg: <" _ tSQLMessage _ ">]") }
			}
			set tResult = ..%NextResult()
		}
	}
	catch tException {
		set tSQLCODE = tException.AsSQLCODE()
		set tSQLMessage = tException.AsSQLMessage()
		if '$IsObject($Get(pMessages)) {
			if $Get(tFileOpen) { use tFileName }
			write !!,"[SQLCODE: <",tSQLCODE,">:<",$$sqlcode^%apiSQL(tSQLCODE),">]",!
			if tSQLMessage'="" { write "[%msg: <",tSQLMessage,">]",! }
		}
		else {
			do pMessages.Insert("[SQLCODE: <"_..%SQLCODE_">:<"_$$sqlcode^%apiSQL(..%SQLCODE)_">]")
			if ..%Message'="" {do pMessages.Insert("[%msg: <" _ ..%Message _ ">]") }
		}
		if $Get(tFileOpen) { close tFileName }
	}
}

}
