/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occDynamicDispatch, %occODBC)

///  <p>
///  A result set can be returned by executing a SELECT statement or a CALL statement.
///  	</p>
///  <p>A result set is a type of statement result (<class>%SQL.StatementResult</class>). A result set is a collection of rows, all of the same ROWTYPE.
///  The ROWTYPE is described by the result set's metadata. The result set metadata can be retrieved by calling
///  <method>%GetMetadata</method>. The OREF returned by <method>%GetMetadata</method> references an instance of %SQL.StatementMetadata.
///  </p>
///  <p>
///  A result set has an iterator that is initially positioned before the first row. The iterator is repositioned by calling <method>%Next</method>. 
///  <method>%Next</method> returns one (1) if the iterator is positioned at the next row or zero (0) indicating that the iterator is
///  positioned after the last row.
///  </p>
///  <p>
///  Column values from the current row can be accessed by column name by calling <method>%Get</method> or by column position by calling 
///  <method>%GetData</method>.
///  <pre>
///  	SAMPLES>set result = ##class(%SQL.Statement).%ExecDirect(,"select Name, SSN, DOB from Sample.Person where Age < 50")
///  	SAMPLES>write result.%SQLCODE
///  	0
///  	SAMPLES>write result.%Next()
///  	1
///  	SAMPLES>write result.%Get("Name")
///  	Zevon,Patricia L.
///  	SAMPLES>write result.%GetData(1)
///  	Zevon,Patricia L.
///  	SAMPLES>write result.Name
///  	Zevon,Patricia L.
///  </pre>
///  Column values can also be accessed by property name. The name of the property corresponding
///  to a column is based on the column name. If the column name is not a valid object identifier then it is transformed into
///  a valid object identifier. The column can still be accessed as a property through dynamic dispatch. If there are questions
///  about the property name that corresponds to a particular column then the statement can define an alias for the
///  column that is a valid object identifier.
///  </p>
///  <p>
///  If the result set is the result of executing a statement prepared with %ObjectSelectMode = 1 then any column whose type class is a
///  swizzleable class is bound to a swizzleable property.</p>
///  <example>
///  	set tStatement = ##class(%SQL.Statement).%New()
///  	set tStatement.%ObjectSelectMode = 1
///  	set tSC = tStatement.%Prepare("select %ID as ID, Spouse as Spouse from Sample.Person where Spouse IS NOT NULL")
///  	set tResult = tStatement.%Execute()
///  	if 'tResult.%SQLCODE {
///  		if tResult.%Next() {
///  			write "Person ID: ",tResult.ID.%Id()," Name: ",tResult.ID.Name," Spouse Name: ",tResult.Spouse.Name,!
///  		}
///  	}
///  </example>
///  <p>Executing this code in the SAMPLES namespace generates output similar to:
///  <pre>
///  	Person ID: 101 Name: Donaldson,Nataliya J. Spouse Name: Grabscheid,Dan L.
///  </pre>
///  </p>
///  <p>
///  The number of rows returned from a result set is available in the %ROWCOUNT property, which is inherited from the <CLASS>%SQL.StatementResult</CLASS> superclass.
///  </p>
Class %SQL.IResultSet Extends (%SQL.StatementResult, %ResultSet.QuerySuper) [ Abstract, ClientDataType = HANDLE, ClientName = ResultSet, OdbcType = RESULTSET, System = 3 ]
{

/// Hash of associated statement index entry
Parameter %StatementIndexHash;

/// Return the asscoaited statement index object
Method %GetStatement(ByRef sc As %Status) As INFORMATION.SCHEMA.STATEMENTS
{
	RETURN ##class(INFORMATION.SCHEMA.STATEMENTS).%OpenId(..#%StatementIndexHash,,.sc)
}

Property %CursorNumber As %Integer [ Internal ];

/// <p><b>DO NOT USE DIRECTLY</b> -- call <method>%GetMetadata</method> to get an Object representation of this
/// result set's metadata, or <method>%GetClientMetadata</method> for a serialized form.</p>
Property %Metadata As %Library.String(MAXLEN = "") [ Internal, MultiDimensional ];

///  %Objects is a list of column/extent pairs
Property %Objects As %Library.String(MAXLEN = "") [ Internal ];

///  %ExtendedMetadata includes additional details about each column.
Property %ExtendedMetadata As %Library.String(MAXLEN = "") [ Internal ];

///  %rsmd is an internal holding area for a %SQL.StatementMetadata reference. When %GetMetadata is called, this value
///  is returned if it has been set.
Property %rsmd As %SQL.StatementMetadata [ Internal, Private ];

///  %NextColumn is used internally for managing partial rows sent to the client
Property %NextColumn As %RawString [ Private ];

///  %Parameters is a parameter metadata string containing the parameter name and type. Since result sets can be instantiated
///  by multiple statement types (SELECT and CALL) there is a difference between the statement metadata and the result ROWTYPE
///  metadata. The ROWTYPE metadata (all columns of RETURNCOL type) is completely contained in %Metadata. All other columns
///  associated with the statement are described here. All of this behavior is encapsulated by %GetMetadata which returns a
///  %SYS.StatementMetadata object.
Property %Parameters As %Library.String(MAXLEN = "") [ Internal ];

///  %PrivateTables is an array of private temporary table orefs used by this result set subscripted by temp table name.
Property %PrivateTables As array Of %XSQL.DS.TempTable;

///  %LTT is an array of temporary table storage indexes subscripted by temp table name.
Property %LTT As %RawString [ Internal, MultiDimensional ];

///  This property is set on instantiation to the current value of $zu(115,5). It
///  cannot be set directly by the user. It is to be used by the result set object
///  to format column and parameter values. SQL based result sets using SELECTMODE=RUNTIME
///  will use this value.
/// 
///  Possible values are:
///  <ul>
///  <li> 0 for LOGICAL mode.</li>
///  <li> 1 for ODBC mode.</li>
///  <li> 2 for DISPLAY mode.</li>
///  </ul>
Property %SelectMode As %Library.String [ InitialExpression = {$zu(115,5)}, Private ];

Method getSelectMode() As %Library.String [ CodeMode = expression ]
{
..%SelectMode
}

///  %CreateSnapshot(storageOffset,lastRow)
/// 
///  Copy all rows from the current position to the end of the cursor into a temporary
///  global. Fetch <var>rowCount</var> rows into a temporary global. If the <var>rowCount</var> is -1 then all rows are fetched
Method %CreateSnapshot(storageOffset As %Integer, ByRef lastRow As %Integer, ByRef pRuntimeMode As %Integer = "", pStatic As %ResultSet.Static = "") As %Status [ Internal ]
{
#define tFileRowCol(%soff,%row,%col) $$$tFileRoot(%soff,%row,%col)
	set tRSMD = ..%GetMetadata()
	set tColumnCount = tRSMD.columns.Count()
	set tStreams = ""
	if $Isobject(pStatic) {
			// Streams-as-orefs is only supported if we have the oref of the static result object
			// Streams are ODBC type = -1 and -4.
		#dim tColumn as %ResultSet.MD.Column
		for tPtr = 1:1:tColumnCount { set tColumn = tRSMD.columns.GetAt(tPtr) if (tColumn.ODBCType = $$$ODBCTYPElongvarchar) || (tColumn.ODBCType = $$$ODBCTYPElongvarbinary) { set tStreams = tStreams _ $Char(1) } else { set tStreams = tStreams _ $Char(0) } }
		set pStatic.%streamColumns = tStreams
	}
	if $Length(tStreams,$Char(1)) > 1 {
		while ..%Next(.status) {
			set row = $increment($$$tFile(storageOffset))
			for column = 1:1:tColumnCount {
				if '$Ascii(tStreams,column) { set $$$tFileRowCol(storageOffset,row,column) = ..%GetData(column) }
				else { set tColumnValue = ..%GetData(column) if $Isobject(tColumnValue) { set pStatic.%streams(row,column) = tColumnValue } else { set $$$tFileRowCol(storageOffset,row,column) = tColumnValue } }
			}
		}
	}
	else { while ..%Next(.status) { set row = $increment($$$tFile(storageOffset)) for column = 1:1:tColumnCount { set $$$tFileRowCol(storageOffset,row,column) = ..%GetData(column) } } }
	set lastRow = $$$tFile(storageOffset)
	set pRuntimeMode = ..%SelectMode
	quit status
}

///  Fetch and send a series of rows for the ODBC/JDBC server. For internal use only.
Method %SendODBC() As %Library.Integer [ Abstract, Internal ]
{
}

///  Fetch and send all row's data to the ^IRIS.Temp.IRIS.Sql() global, used by %PARALLEL union queries. For internal use only.
Method %FetchIntoTemp() As %Library.Integer [ Abstract, Internal ]
{
}

///  Fetch and send a series of rows for continuous query client. For internal use only.
Method %SendDelimitedRows(pMaxRows As %Integer = 0, pDelimiter As %String = "", ByRef pReturnCount As %Integer = 0) As %Status [ Abstract, Internal ]
{
}

///  %SendObjects iterates over the rows in the result set and calls object export (quick load) on
///  each column that is present in ..%Objects. For internal use only.
Method %SendObjects(pObjectCount As %Integer = 0, pLock As %Integer = 0) As %Library.Integer [ Internal ]
{
	new %rowid,%nolock,%qrc
	set %qrc = 0, %nolock = 'pLock, tObjectCount = 0
	set tObjects = ..%Objects
	while ((pObjectCount > tObjectCount) || (pObjectCount = 0)) && (..%Next()) && ('%qrc) {
		set tObjectCount = tObjectCount + 1
		for tPtr = 1:1:$ListLength(tObjects) {
			set tColumn = $List($List(tObjects,tPtr),1), tExtent = $List($List(tObjects,tPtr),2), tCall = $List($List(tObjects,tPtr),3)
			if tCall = "" {
				$$$comClassKeyGetLvar(tSchema,tExtent,$$$cCLASSsqlschemaname)
				$$$comClassKeyGetLvar(tTable,tExtent,$$$cCLASSsqltablename)
				if (tSchema '= "") && (tTable '= "") { set tCall = $Get(^oddSQL(tSchema,tTable,"QL")) } else { set tCall = "" }
			}
			set %rowid = $Select(+tColumn=tColumn:..%GetData(tColumn),1:..%Get(tColumn))
			if %rowid '= "" { do $classmethod($lg(tCall),$lg(tCall,2),%rowid) if %qrc goto exit }
		}
	}
exit
	quit %qrc
}

///  Dispatch <property>Get calls when the <property> does not exist
///  in the class descriptor. This implementation normalizes case and
///  attempts to dispatch to the correct property, effectively making properties
///  corresponding to column values case insensitive. Also, SQLCODE, ROWID and ROWCOUNT
///  are case-normalized and dispatched to the correct property.
Method %DispatchGetProperty(pProperty As %String(MAXLEN=255)) [ Internal ]
{
	set tRSMD = ..%GetMetadata(), tPROPERTY = $$$ucase(pProperty)
	if $Data(tRSMD.columnIndex(tPROPERTY)) { quit $property($this,$List(tRSMD.columnIndex(tPROPERTY),2)) }
	elseif (tPROPERTY = "SQLCODE") || (tPROPERTY = "%SQLCODE") { quit ..%SQLCODE }
	elseif (tPROPERTY = "%ROWID") { quit ..%ROWID }
	elseif (tPROPERTY = "%ROWCOUNT") { quit ..%ROWCOUNT }
	else { $$$ThrowPropertyDoesNotExistError(pProperty) }
	quit ""
}

Method %DispatchMethod(pMethod As %String, Args...)
{
	if $$$ucase(pMethod) = "%GETMETADATA" { quit ..%GetMetadata() }
	$$$ThrowMethodDoesNotExistError(pMethod)
}

///  Return the result set metadata as a %SQL.StatementMetadata instance.
Method %GetMetadata() As %SQL.StatementMetadata
{
	if ..%rsmd = "" { 
		do ..%GetClientMetadata(.tMetadata)
		set ..%rsmd = ##class(%SQL.StatementMetadata).%New(1,.tMetadata,..%Parameters,..%Objects,,,..%ExtendedMetadata)
	}
	quit ..%rsmd
}

Method %Display(pDelimiter As %String = {$Char(9)}, colAlign As %Integer = 0)
{
#DEFINE SQLColLengthDefault 20
#DEFINE SQLColLengthMaxDisplay 128

	set tRSMD = ..%GetMetadata()
	set tColumns = tRSMD.columns.Count()
	for i=1:1:tColumns {
		set tColumn = tRSMD.columns.GetAt(i)
		set colHead=tColumn.colName
		if colAlign>0 {	// --- Collect Metadata Information & Align Column Headers ---
			set colHeadLen=$l(colHead)
			if colAlign=1 { set colDispLen=colHeadLen }
			elseif colAlign=2 { set colDispLen=tColumn.precision set:colDispLen="" colDispLen=$$$SQLColLengthDefault set:colDispLen>$$$SQLColLengthMaxDisplay colDispLen=$$$SQLColLengthMaxDisplay set:colHeadLen>colDispLen colDispLen=colHeadLen }
			else { set colDispLen=colHeadLen }
			set $LIST(metadata(0,i),1,4)=$LB(colHead,colHead,colHeadLen,colDispLen)
			set colHeadPadding=$j("",colDispLen-colHeadLen)
			write colHead,colHeadPadding
		}
		else { write colHead }
		write:i'=tColumns pDelimiter	// Don't write out extra delimiter after last column name
 	}
	if tColumns { write ! }
	set sc=$$$OK
	if ..%SQLCODE < 0 {
		write !!,"[SQLCODE: <",..%SQLCODE,">:<",$$sqlcode^%apiSQL(..%SQLCODE),">]",!
		if ..%Message'="" { write "[%msg: <",..%Message,">]" }
	}
	else {
		while ..%Next(.sc) { do ..%Print(pDelimiter,colAlign,.metadata) }
		if $$$ISERR(sc) { set ..%SQLCODE=$system.Status.StatusToSQLCODE(sc,.msg) set:$g(msg)'="" ..%Message=msg }
		if ..%SQLCODE < 0 {
			write !!,"[SQLCODE: <",..%SQLCODE,">:<",$$sqlcode^%apiSQL(..%SQLCODE),">]",!
			if ..%Message'="" { write "[%msg: <",..%Message,">]" }
		}
	}
	write !,+(..%ROWCOUNT)," Rows(s) Affected"
}

Method %DisplayMarkDown()
{
	set tRSMD = ..%GetMetadata()
	set tColumns = tRSMD.columns.Count()
	set dashes = ""
	for i=1:1:tColumns {
		set tColumn = tRSMD.columns.GetAt(i)
		if ($extract(tColumn.colName,1,3) = "rj_") {
			set dashes = dashes _ "| --: "
			set colHead = $extract(tColumn.colName, 4, *)
		} elseif ($extract(tColumn.colName,1,3) = "lj_") {
			set dashes = dashes _ "| :-- "
			set colHead = $extract(tColumn.colName, 4, *)
		} elseif ($extract(tColumn.colName,1,3) = "cj_") {
			set dashes = dashes _ "| :--: "
			set colHead = $extract(tColumn.colName, 4, *)
		} else {
			set dashes = dashes _ "| -- "
			set colHead = tColumn.colName
		}
		write "| ",colHead," "
 	}
	if tColumns {
		write "|", !
		write dashes,"|",!
	}
	if ..%SQLCODE < 0 {
		write !!,"[SQLCODE: <",..%SQLCODE,">:<",$$sqlcode^%apiSQL(..%SQLCODE),">]",!
		if ..%Message'="" { write "[%msg: <",..%Message,">]" }
	} else {
		try {
			while ..%Next(.sc) {
				if tColumns {
					set tValue = ..%GetData(1)
					if tValue [ $Char(10) {
						set tValue = $zu(144,1,tValue)
					}
					try {
						if tValue'="",$listvalid(tValue) { set tValue=$$Quote^%qcr(tValue) } }
					catch { }	// write out $list values in readable format
					write "| ",tValue, " "
					for tPtr = 2:1:tColumns {
						set tValue = ..%GetData(tPtr)
						if tValue [ $Char(10) { set tValue = $zu(144,1,tValue) }
						try {
							if tValue'="",$listvalid(tValue) {
								set tValue=$$Quote^%qcr(tValue)
							}
						} catch { }	// write out $list values in readable format
						write "| ",tValue, " "
					}
					write "|",!
				}
			}
		} catch e {
			set ..%SQLCODE = e.AsSQLCODE()
			set ..%Message = e.AsSQLMessage()
		}
		if ..%SQLCODE < 0 {
			write !!,"[SQLCODE: <",..%SQLCODE,">:<",$$sqlcode^%apiSQL(..%SQLCODE),">]",!
			if ..%Message'="" { write "[%msg: <",..%Message,">]" }
		}
	}
	write !,+(..%ROWCOUNT)," Rows(s) Affected"
}

///  %Print()
///  <p>Write the current row to the current device. An optional column delimiter can be
///  specified. No formatting is applied other than writing <var>pDelimiter</var> between
///  column values. This can be useful for exporting result set data to tab delimited files.</p>
///  <p>For example:</p><p></p>
///  <example>
///  set sql = "select name,home_street,home_city,home_state,home_zip from sample.person"
///  set rset = ##class(%ResultSet.SQL).%Prepare(.sql,.err,"")
///  if '$Isobject(err) {
///  	set file="c:\temp\names.asv"
///  	open file:"WNS"
///  	use file while rset.%Next() { do rset.%Print($char(9)) } 
///  	close file
///  }
///  </example>
///  <p><p>
///  Example data:
///  <table>
///  <tr><td>Cornell,Ezra M.</td><td>340 Franklin Court</td><td>Sarasota</td><td>NY</td><td>12866</td></tr>
///  <tr><td>Huff,Stephen A.</td><td>548 Washington Blvd</td><td>Brownfield Center</td><td>MD</td><td>53436</td></tr>
///  <tr><td>Sands,Jeep Q.</td><td>7298 Washington Drive</td><td>Xavier</td><td>WY</td><td>23685</td></tr>
///  </table>
Method %Print(pDelimiter As %String = " ", colAlign As %Integer = 0, ByRef metadata As %ArrayOfObjects) As %Status
{
	set tRSMD = ..%GetMetadata()
	set tColumns = tRSMD.columns.Count()
	if tColumns {
		set tValue = ..%GetData(1)
		if (tValue [ pDelimiter)  || (tValue [ $Char(10)) { set tValue = $zu(144,1,tValue) }
		try { if tValue'="",$listvalid(tValue) { set tValue=$$Quote^%qcr(tValue) } } catch { }	// write out $list values in readable format
		if colAlign>0 {	// --- Align Column Data ---
			set colDispLen=$LG(metadata(0,1),4)
			write tValue,$j("",colDispLen-$l(tValue))
		}
		else { write tValue }
		for tPtr = 2:1:tColumns {
			set tValue = ..%GetData(tPtr)
			if (tValue [ pDelimiter)  || (tValue [ $Char(10)) { set tValue = $zu(144,1,tValue) }
			try { if tValue'="",$listvalid(tValue) { set tValue=$$Quote^%qcr(tValue) } } catch { }	// write out $list values in readable format
			if colAlign>0 {	// --- Align Column Data ---
				set colDispLen=$LG(metadata(0,tPtr),4)
				write pDelimiter,tValue,$j("",colDispLen-$l(tValue))
			}
			else { write pDelimiter,tValue }
		}
		write !
	}
	quit $$$OK
}

///  <p>Display the contents of the result object. If formatted display is available then format the results
///  using the requested format and, if appropriate, open the formatted results using the host OS. The output
///  is directed to one or more files and messages are placed in a result set object. All file names used
///  are returned in an array.</p>
///  <br>
///  	<p>
///  		<h4>Parameters</h4><br>
///  		<table border="1" title="Parameters">
///  			<tr>
///  				<th>Name</th><th>Description</th>
///  			</tr>
///  			<tr>
///  				<td>pFormat</td>
///  				<td>
///  					<p>The format applied to the result content. This parameter is also used to determine the file name extension.</p>
/// 					<p>Supported formats are:<br>
///  						<table>
///  							<tr><td>-1</td><td>%Display() format</td></tr>
///  							<tr><td>0</td><td>XML</td></tr>
///  							<tr><td>1</td><td>HTML</td></tr>
///  							<tr><td>2</td><td>PDF (requires a renderer such as FOP)</td></tr>
///  							<tr><td>99</td><td>TXT</td></tr>
/// 							<tr><td>100</td><td>CSV</td></tr>
/// 						</table>
/// 					</p>
/// 					<p>If <var>pFormat</var> is specified as any number not listed above then it will default to TXT.</p>
/// 					<p><var>pFormat</var> can also be specified as XML, HTML, PDF, TXT or CSV.</p>
/// 					<p><i>NOTE: <var>pFormat</var> of CSV/100 is not a true comma separated value, but instead uses TAB separated values.</i></p>
///  				</td>
///  			</tr>
///  			<tr>
///  				<td>pFileName</td>
///  				<td>
///  					<p>The base file name to be used to generate actual file names used for output. If no value is specified
///  						then a file name will be generated, using the TEMP folder defined for the InterSystems IRIS instance.
///  						This value is not expected to include an extension. An extension is added to this value to form the actual
///  						file used. Also, if nested results exist then a number is appended to the file name specified to produce a unique
///  						name for each result.
///  					</p>
///  				</td>
///  			</tr>
///  			<tr>
///  				<td>pMessages</td>
///  				<td>
///  					<p>Instance of a system result set class. If no value is passed then the system message result class is instantiated.
///  						This parameter is passed by reference. It is up to the caller to process the result set oref that is returned.
///  						pMessages.Count() returns the number of messages contained in the result set. pMessages.%Display() will display the
///  						messages on the current device. pMessages.%DisplayFormatted() is also implemented and can be used to display the
///  						messages using the selected format.
///  					</p>
///  				</td>
///  			</tr>
///  			<tr>
///  				<td>pFilesUsed</td>
///  				<td>
///  					<p>This pass-by-reference parameter will contain the number of files used to display the result content and the name of
///  						each file. pFilesUsed is the number of files and pFilesUsed(<var>file_number</var>) is the name of the file. The
///  						sequence of the files is the same sequence as the results are processed. For simple result objects, there is a single
///  						file. For context objects that can contain result set sequences, the results are output in the order they are returned
///  						and the files used are present in pFilesUsed in that same order.
///  					</p>
///  				</td>
///  		</tr>
///  			<tr>
///  				<td>pTranslateTable</td>
///  				<td>
///  					<p>This is the translate table used for the output files when the format is CSV or TXT. This parameter is optional. 
///  					</p>
///  				</td>
///  		</tr>
///  			<tr>
///  				<td>pDelimiter</td>
///  				<td>
///  					<p>The delimiter to use between columns in the export file. This parameter is optional and defaults to tab character if not specified. 
///  					</p>
///  				</td>
///  		</tr>
///  		</table>
///  </p>
///  <br>
Method %DisplayFormatted(pFormat As %String = -1, ByRef pFileName As %String(MAXLEN="") = "", ByRef pMessages As %SQL.Manager.Messages = "", ByRef pFilesUsed As %String(MAXLEN="") = 0, pTranslateTable As %String(MAXLEN="") = "", pDelimiter As %String = {$c(9)})
{
#define NewFileRoot					$translate($zstrip($SYSTEM.Encryption.Base64Encode($system.Encryption.GenCryptRand(10)),">","="), "+/", "ab")
#define TempFilePath				##class(%File).NormalizeDirectory(##class(%ZEN.Report.reportPage).%GetTempDir())
	if '$IsObject(pMessages) { set pMessages = ##class(%SQL.Manager.Messages).%New() }
		// Convert a text pFormat to integer
	if +pFormat '= pFormat { set pFormat = $Case($$$ucase(pFormat),"XML":0,"HTML":1,"PDF":2,"CSV":100, "MD":101,:99) }
		// Get the OS. If the OS is not Windows or Unix then deliver the message that the file cannot
		// be automatically displayed.
	new %context,%count,%filter,%report
	set tFileOpen = 0
	try {
		set tExtension = $Case(pFormat,0: "xml", 1: "html", 2: "pdf", 100: "csv", "101": "md", :"txt")
		if pFileName '= "" { if '$Find("/\",$Extract(pFileName,*)) { set tFileName = pFileName _ "." _ tExtension } else { set tFileName = pFileName _ $$$NewFileRoot _ "." _ tExtension } }
		else { set tFileName = $$$TempFilePath _ $$$NewFileRoot _ "." _ tExtension }
		if ..%SQLCODE < 0 {
			do pMessages.Insert("[SQLCODE: <"_..%SQLCODE_">:<"_$$sqlcode^%apiSQL(..%SQLCODE)_">]")
			if ..%Message '= "" {do pMessages.Insert("[%msg: <" _ ..%Message _ ">]") }
		}
		if (pFormat < 99) && (pFormat '= -1) {
			set tClassDefinitionId = ##class(%SYS.SQLStatementCache).FormattedDisplayClassGet($classname())
			if tClassDefinitionId = "" { set tClassDefinitionId = ##class(%SQL.DynamicStatement).GenerateFormattedDisplay($this) }
			if tClassDefinitionId '= "" {
				set tReturn = 1
				set tReport = $classmethod(tClassDefinitionId,"%New")
				set pFilesUsed = pFilesUsed + 1, pFilesUsed(pFilesUsed) = tFileName
				set tReport.ResultSet = $this, tReport.ResultTitle = "Result #"_pFilesUsed
				do tReport.GenerateReport(tFileName,pFormat)
			}
			else {
				open tFileName:("WNS"_$Select(pTranslateTable="":"",1:"K\"_pTranslateTable_"\")):30 else  $$$ThrowStatus($$$ERROR($$$FileCanNotOpen,tFileName))
				set pFilesUsed = pFilesUsed + 1, pFilesUsed(pFilesUsed) = tFileName
				set tFileOpen = 1
				use tFileName
				do ..%Display(.pDelimiter)
				close tFileName
				set tFileOpen = 0
			}
		}
		else {
			open tFileName:("WNS"_$Select(pTranslateTable="":"",1:"K\"_pTranslateTable_"\")):30 else  $$$ThrowStatus($$$ERROR($$$FileCanNotOpen,tFileName))
			set pFilesUsed = pFilesUsed + 1, pFilesUsed(pFilesUsed) = tFileName
			set tFileOpen = 1
			use tFileName
			if pFormat = 100 {
				set sc=$$$OK
				#dim tMetadata as %SQL.StatementMetadata
				set tMetadata = ..%GetMetadata()
				set tRowType = tMetadata.GenerateRowType()
				if tRowType '= "" { write "--",tRowType,! }
				set tColumnCount = tMetadata.columnCount
				while ..%Next(.sc) { do ..%Print(.pDelimiter) }
				if $$$ISERR(sc) {
					set tSQLCODE=$system.Status.StatusToSQLCODE(sc,.message)
					do pMessages.Insert("[SQLCODE: <"_tSQLCODE_">:<"_$$sqlcode^%apiSQL(tSQLCODE)_">]")
					if message'="" {do pMessages.Insert("[%msg: <" _ message _ ">]") }
				}
			} elseif pFormat = 101 {
				do ..%DisplayMarkDown()
			}
			else { do ..%Display() }
			close tFileName
			set tFileOpen = 0
		}
		do pMessages.Insert(+(..%ROWCOUNT) _ " row(s) affected.")
	}
	catch tException {
		set tSQLCODE = tException.AsSQLCODE()
		if ..%Message = "" {
			set message = tException.AsSQLMessage()
		} else {
			set message = ..%Message
		}
		if '$IsObject($Get(pMessages)) {
			if $Get(tFileOpen) { use tFileName }
			write !!,"[SQLCODE: <",tSQLCODE,">:<",$$sqlcode^%apiSQL(tSQLCODE),">]",!
			if message'="" { write "[%msg: <",message,">]",! }
		} else {
			do pMessages.Insert("[SQLCODE: <"_tSQLCODE_">:<"_$$sqlcode^%apiSQL(tSQLCODE)_">]")
			if message'="" {do pMessages.Insert("[%msg: <" _ message _ ">]") }
		}
		if $Get(tFileOpen) { close tFileName }
	}
}

///  This method returns the rowtype metadata, serialized for transport to clients. Its structure is based
///  on the value of the public variable '%protocol' at the time the result set is instantiated.
Method %GetClientMetadata(ByRef pMetadata As %RawString = "") As %Status [ Final ]
{
	kill pMetadata
	if '$d(..%Metadata) {
		set status = ..%GetSerializedMetadata(.pMetadata)
		quit:$$$ISERR(status) status
		merge ..%Metadata = pMetadata
	} else {
		merge pMetadata = ..%Metadata
	}
	quit $$$OK
}

/// <b>DO NOT USE DIRECTLY</b> - use <method>%GetClientMetadata</method> instead
/// Builds the serialized metadata for this result set.
Method %GetSerializedMetadata(ByRef pMetadata As %RawString = "") As %Status [ Internal ]
{
	quit $$$OK
}

}
