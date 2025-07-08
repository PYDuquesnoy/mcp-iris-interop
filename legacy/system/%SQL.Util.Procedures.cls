/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements several utility methods that can be invoked either as class methods or
/// as an SQL procedure call (SQL invoked routine).
Class %SQL.Util.Procedures [ Abstract, System = 3 ]
{

/// <p>
/// <table border=1>
/// 	<tr>
/// 		<th colspan=3>
/// 			Parameters
/// 		</th>
/// 	</tr>
/// 	<tr>
/// 		<th>Name</th>
/// 		<th>Direction</th>
/// 		<th>Description</th>
/// 	</tr>
/// 	<tr>
/// 		<td>pSelectMode</td>
/// 		<td>Input</td>
/// 		<td>The select mode that defines the format of the data. Valid values are 0 - logical, 1 - ODBC, and 2 - Display.</td>
/// 	</tr>
/// 	<tr>
/// 		<td>pRowType</td>
/// 		<td>Input-Output</td>
/// 		<td>A comma-delimited list of comma specs as defined above. It is easier to access the data in the result 
/// 			set if the column names are also valid object identifiers. A row type descriptor can be embedded in
/// 			the input file. If the <var>pRowType</type> argument is not passed or is passed as null then the row type
/// 			is expected to be embedded in the input file. If <var>pRowType</var> is passed as a non-null value then any
/// 			embedded row type value will be ignored.
/// 		</td>
/// 	</tr>
/// 	<tr>
/// 		<td>pFileName</td>
/// 		<td>Input</td>
/// 		<td>
/// 			The name of the file containing the data. This can also be a stream oref. If this argument value 
/// 			is a stream oref then the referenced stream is used as the input data source. 
/// 		</td>
/// 	</tr>
/// 	<tr>
/// 		<td>pDelimiter</td>
/// 		<td>Input</td>
/// 		<td>
/// 			The csv delimiter character. The default is comma. 
/// 		</td>
/// 	</tr>
/// 	<tr>
/// 		<td>pQuote</td>
/// 		<td>Input</td>
/// 		<td>
/// 			The quote character. The default is a double quote. This is the character used to delimit values that might 
/// 			contain a value delimiter character or other control characters.
/// 		</td>
/// 	</tr>
/// 	<tr>
/// 		<td>pTranslateTable</td>
/// 		<td>Input</td>
/// 		<td>
/// 			The translate table to use for the input file. If not specified then the default translate table will be used. 
/// 			If <var>pFileName</var> is a stream oref then this argument is ignored. 
/// 		</td>
/// 	</tr>
/// </table>
/// </p>
/// <p>
/// This utility procedure/method instantiates a result set bound to a comma separated value (CSV) data source. The result set is returned as a 
/// dynamic result set in the procedure context object. Any records in the CSV source that begin with "--" are considered to be comments 
/// and are skipped. The columns from the data source form a result row. The structure of result row is defined as
/// a row type descriptor passed as the <var>pRowType</var> formal parameter. The format of a row type descriptor is a comma delimited list 
/// of field definitions where each field definition contains a field name and a datatype. Both the field name and datatype follow the rules used 
/// by field definitions in a CREATE TABLE statement. 
/// For example:</p>
/// <code>
/// 	ROW(StateFips VARCHAR(2),Zip_Code VARCHAR(5),State_Abbr VARCHAR(2),Name VARCHAR(200),Longitude_West Numeric(10,6),Latitude_North Numeric(10,6))
/// </code>
/// </p>
/// <p>
/// For the purposes of the CSV method/procedure, the ROW() is optional.
/// </p>
/// <p>
/// Row type descriptors do not normally allow missing (empty) field definitions but for the specific purpose of describing the records
/// of a CSV data source empty fields are allowed and indicate a skipped column in the data source.
/// In the example below, the first two columns and the fourth column are ignored:
/// </p>
/// <code>
/// 		ROW(,,Zip_Code VARCHAR(5),,Name VARCHAR(200),Longitude_West Numeric(10,6),Latitude_North Numeric(10,6))
/// </code>
/// <p>
/// It is not necessary to add additional commas to indicate columns skipped at the end of the record.
/// </p>
/// <p>
/// The row type descriptor can be embedded in the input file. Simply add a line at the beginning of the file as a comment containing the row type. 
/// For example: 
/// <pre>
/// 	--ROW(,,Zip_Code VARCHAR(5),,Name VARCHAR(200),Longitude_West Numeric(10,6),Latitude_North Numeric(10,6))
/// </pre>
/// <br>
/// It is important that this line be the first line in the input file. Otherwise, it will not be recognized as the row type. The embedded row type descriptor 
/// is not used if CSV is passed a row type by the caller. 
/// </p>
/// <p>
/// This utility can be invoked either as a class method or as a stored procedure. The parameters are described in the parameters table above. 
/// <br>
/// </p>
/// <p>
/// The result is returned in the procedure context object. This is normally %sqlcontext if the utility is invoked as a class method call. It is the result object if
/// the procedure is invoked using dynamic SQL. For example:
/// </p>
/// <p>
/// <code>
/// 	set rowtype = "StateFips VARCHAR(2),Zip_Code VARCHAR(5),State_Abbr VARCHAR(2),Name VARCHAR(200),Longitude_West Numeric(10,6),Latitude_North Numeric(10,6)"<br>
/// 	set filename = "/Users/test/Documents/zip.csv"<br>
/// 	set result = ##class(%SQL.Statement).%ExecDirect(,"call %SQL_Util.CSV(,?,?)",.rowtype,.filename)<br>
/// 		set resultSet = result.%NextResult()<br>
/// 	write resultSet.%Next()<br>
/// 		write resultSet.StateFips<br>
/// </code>
/// </p>
ClassMethod CSV(pSelectMode As %Integer = {$ZU(115,5)}, ByRef pRowType As %String(MAXLEN="") = "", pFileName As %String(MAXLEN=200), pDelimiter As %String = ",", pQuote As %String = """", pTranslateTable As %String = "") [ ReturnResultsets, SqlName = CSV, SqlProc ]
{
	#dim %sqlcontext as %Library.ProcedureContext
	try {
			// Establish the input stream
		if ($Isobject(pFileName)) {
			if pFileName.%IsA("%Stream.Object") {
				set tStream = pFileName
			} else {
					// Not an instance of %Stream.Object - can we assume the object supports the stream interface?
			}
		} elseif ##class(%Library.File).Exists(pFileName) {
			set tStream = ##class(%Stream.FileCharacter).%New()
			set tStream.Filename = pFileName
			set tStream.LineTerminator = $Char(13,10)
			if pTranslateTable '= "" { set tStream.TranslateTable = pTranslateTable }
		} else {
			throw ##class(%Exception.SQL).CreateFromSQLCODE(-400,"CSV Import utility - file '"_pFileName_"' does not exist.")
		}
		if pRowType = "" {
			set tRow = tStream.ReadLine()
			if $Extract(tRow,1,2) = "--" {
				set tRowType = $ZStrip($Extract(tRow,3,*),"<>W")
			} else {
					// We expect the row type to be a comment in the file. It doesn't start with "--".
				throw ##class(%Exception.SQL).CreateFromSQLCODE(-400,"CSV Import utility - no row type passed and the first line of the input isn't a valid row type, expected '--'")
			}
		} else {
			set tRowType = pRowType
		}
		set tPreparedStatement = ##class(%SQL.DynamicStatement).Prepare($system.Util.CreateGUID(),.tRowType,,,,,,"CSV")
		if $Isobject(tPreparedStatement) {
			set tResult = tPreparedStatement.%New(tPreparedStatement,,tStream,pDelimiter,pQuote)
			do %sqlcontext.AddResultSet(tResult)
		}
	}
	catch tException {
		set %sqlcontext.%SQLCODE = tException.AsSQLCODE()
		set %sqlcontext.%Message = tException.AsSQLMessage()
	}
}

/// <p>
/// <table border=1>
/// 	<tr>
/// 		<th colspan=3>
/// 			Parameters
/// 		</th>
/// 	</tr>
/// 	<tr>
/// 		<th>Name</th>
/// 		<th>Direction</th>
/// 		<th>Description</th>
/// 	</tr>
/// 	<tr>
/// 		<td>pSelectMode</td>
/// 		<td>Input</td>
/// 		<td>The select mode that defines the format of the data. Valid values are 0 - logical, 1 - ODBC, and 2 - Display.</td>
/// 	</tr>
/// 	<tr>
/// 		<td>pRowType</td>
/// 		<td>Input-Output</td>
/// 		<td>A comma-delimited list of comma specs as defined above. It is easier to access the data in the result 
/// 			set if the column names are also valid object identifiers. A row type descriptor can be embedded in
/// 			the input file. If the <var>pRowType</type> argument is not passed or is passed as null then the row type
/// 			is expected to be embedded in the input file. If <var>pRowType</var> is passed as a non-null value then any
/// 			embedded row type value will be ignored.
/// 		</td>
/// 	</tr>
/// 	<tr>
/// 		<td>pFileName</td>
/// 		<td>Input</td>
/// 		<td>
/// 			The name of the file containing the data. This can also be a stream oref. If this argument value 
/// 			is a stream oref then the referenced stream is used as the input data source. 
/// 		</td>
/// 	</tr>
/// 	<tr>
/// 		<td>pDelimiter</td>
/// 		<td>Input</td>
/// 		<td>
/// 			The csv delimiter character. The default is comma. 
/// 		</td>
/// 	</tr>
/// 	<tr>
/// 		<td>pQuote</td>
/// 		<td>Input</td>
/// 		<td>
/// 			The quote character. The default is a double quote. This is the character used to delimit values that might 
/// 			contain a value delimiter character or other control characters.
/// 		</td>
/// 	</tr>
/// 	<tr>
/// 		<td>pHeaderCount</td>
/// 		<td>Input</td>
/// 		<td>The number of records that are to be skipped at the beginning of the file.</td>
/// 	</tr>
/// 	<tr>
/// 		<td>pClassName</td>
/// 		<td>Input</td>
/// 		<td>
/// 			The name of the class where the data will be imported. If this class does not yet exist then 
/// 			it will be generated from the row type. If this class already exists then it is assumed that 
/// 			the class definition matches the row type and that the Import method is implemented.
/// 		</td>
/// 	</tr>
/// 	<tr>
/// 		<td>pTranslateTable</td>
/// 		<td>Input</td>
/// 		<td>
/// 			The translate table to use for the input file. If not specified then the default translate table will be used. 
/// 			If <var>pFileName</var> is a stream oref then this argument is ignored. 
/// 		</td>
/// 	</tr>
/// 	<tr>
/// 		<td>pTableName</td>
/// 		<td>Input</td>
/// 		<td>
/// 			The SQLTABLENAME to be defined in the generated class. SQLTABLENAME defaults to a value based on the classname is no 
/// 			value is passed. 
/// 		</td>
/// 	</tr>
/// </table>
/// </p>
/// Import a CSV document into a persistent class. The row type defines the property names and types. Refer
/// to <method>CSV</method> for more information on row types and row type embedding. The class will be generated if it does not already
/// exist. If the class does exist then it is expected to implement the Import method with an interface compatible
/// with the Import method generated by the utility. The easiest way to see the Import method interface is to generate
/// a class from a row type.
/// <p>
/// This utility can be invoked either as a class method or as a stored procedure. The parameters are described in the parameters table above. 
/// <br>
/// </p>
ClassMethod CSVTOCLASS(pSelectMode As %Integer = {$ZU(115,5)}, ByRef pRowType As %String(MAXLEN="") = "", pFileName As %String(MAXLEN=200), pDelimiter As %String = ",", pQuote As %String = """", pHeaderCount As %Integer = 0, pClassName As %String(MAXLEN=400), pTranslateTable As %String = "", pTableName As %String(MAXLEN="") = "") [ ReturnResultsets, SqlName = CSV_TO_CLASS, SqlProc ]
{
	try {
		if pRowType = "" {
			if ($Isobject(pFileName)) && (pFileName.%IsA("%Stream.Object")) {
				set tRow = pFileName.ReadLine()
				do pFileName.Rewind()
			}
			else {
				set tStream = ##class(%Stream.FileCharacter).%New()
				set tStream.Filename = pFileName
				set tStream.LineTerminator = $Char(13,10)
				if pTranslateTable '= "" { set tStream.TranslateTable = pTranslateTable }
				set tRow = tStream.ReadLine()
				kill tStream
			}
			if $Extract(tRow,1,2) = "--" { set pRowType = $ZStrip($Extract(tRow,3,*),"<>W") }
		}
		set tRowCount = 0
		if '##class(%Dictionary.ClassDefinition).%ExistsId(pClassName) { do ##class(%SQL.Util.RowType).GeneratePersistentClass(.pRowType,.pClassName,1,pTableName) }
		set tRowCount = $classmethod(pClassName,"Import",pSelectMode,.pFileName,.pDelimiter,.pQuote,.pHeaderCount)
		set %sqlcontext.%SQLCODE = 0, %sqlcontext.%Message = "", %sqlcontext.%ROWCOUNT = tRowCount
	}
	catch tException {
		#dim tException as %Exception.AbstractException
		set %sqlcontext.%SQLCODE = tException.AsSQLCODE(), %sqlcontext.%Message = tException.AsSQLMessage()
	}
}

}
