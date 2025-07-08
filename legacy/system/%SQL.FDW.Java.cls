/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%External.language, %occJava)

Class %SQL.FDW.Java Extends %SQL.FDW.Abstract [ System = 4 ]
{

/// Object representing instance of a specific connection to the external language server
Property Gateway As %External.Gateway;

/// Class in the Foreign Table package
Parameter JAVACLASS;

Property ReaderObject As %Net.Remote.Object;

/// Left in for Fetch(), which isn't how we codegen FT TVFs anyway
Property Ptr As %Integer;

Method %OnNew() As %Status
{
	set i%BufferPointer = 0, i%%AtEnd = 0, i%RemainingBuffers = 1, i%%IsOpened = 1
	RETURN $$$OK
}

/// Advance the result set cursor to the next row. Returns 0 if the cursor is at the end of the 
/// result set.. An optional argument contains a <class>%Library.Status</class> value on return. This %Status value
/// indicates success or failure of the %Next call. <property>%SQLCODE</property> is also set by %Next.
Method %Next(ByRef sc As %Library.Status = {$$$OK}) As %Library.Integer
{
	try {
		set localBufferPointer = i%BufferPointer
		if '$listnext(i%Buffer, localBufferPointer, row) { // there was no row left in the buffer
			set i%Buffer = ..ReaderObject.getRows(1000)
			if '$length(i%Buffer) { // no buffer was returned
				set i%%AtEnd = 1, i%%SQLCODE = 100
				RETURN 0
			}
			// Note: $listnext will reset localBufferPointer to 0 if it didn't find a row last time, which necessarily happened
			// to  get here
			// This if should never be true b/c at this point a buffer was returned and we don't just return an empty $lb() buffer
			// but you can't "do $listnext" anyway so might as well put the check in
			if '$listnext(i%Buffer,localBufferPointer,row) {
				set i%%AtEnd = 1, i%%SQLCODE = 100
				RETURN 0
			}
		}

		set i%BufferPointer = localBufferPointer

		// build %GetData
		set rowPtr = 0
		while $listnext(row,rowPtr,fieldValue) {
			set i%%GetData($i(colNumber)) = $s('$d(fieldValue):"", fieldValue="":$c(0), 1:fieldValue)
		}
		set i%%ROWCOUNT = i%%ROWCOUNT + 1
		RETURN 1
	} catch ex {
		try {
			set startReaderError = $find(ex.RawData,"CsvReader: ")
			if startReaderError > 0 {
				set endReaderError = $find(ex.RawData, $c(10), startReaderError) - 2 
				set readerError = $e(ex.RawData,startReaderError,endReaderError)
				set:readerError'="" ex.RemoteError = readerError
			}
		} catch ignore {
			// Exceptions originating from Java will have a RawData property but COS exceptions will not
			// and will throw a <PROPERTY NOT FOUND> exception. Move on an proceed to handling the original error
		}
		set sc = ex.AsStatus()
		set i%%SQLCODE = $SYSTEM.Status.StatusToSQLCODE(sc)
		set i%%Message = $SYSTEM.Status.GetErrorText(sc)
		RETURN 0
	}
		
	RETURN 1
}

Method Reset() As %Status
{
	set tSC = $$$OK
	try {
		do ..ReaderObject.beforeFirst()
		// At this point, we succeeded at resetting the wrapper in some capacity, so reset all the bookkeeping properties
		set i%BufferPointer = 0, i%%AtEnd = 0, i%RemainingBuffers = 1, i%%IsOpened = 1, i%%SQLCODE = 0, i%%ROWCOUNT = 0, i%Buffer=""
	} catch ex {
		try {
			set startReaderError = $find(ex.RawData,"CsvReader: ")
			if startReaderError > 0 {
				set endReaderError = $find(ex.RawData, $c(10), startReaderError) - 2 
				set readerError = $e(ex.RawData,startReaderError,endReaderError)
				set:readerError'="" ex.RemoteError = readerError
			}
		} catch ignore {
			// Exceptions originating from Java will have a RawData property but COS exceptions will not
			// and will throw a <PROPERTY NOT FOUND> exception. Move on an proceed to handling the original error
		}
		set tSC = ex.AsStatus()
		set i%%SQLCODE = $SYSTEM.Status.StatusToSQLCODE(tSC)
		set i%%Message = $SYSTEM.Status.GetErrorText(tSC)
	}
	
	RETURN tSC
}

/// Prepare the query for execute; since this is a Java FDW, that means opening the java gateway connection and getting an object to execute with
Method Prepare(Server As %String, FTClassName As %String, Query As %String, Parameters As %List = "") As %Status
{
	try {
		// get Java Gateway object
		set ..Gateway = $system.external.getJavaGateway()
		do ..SetUpClassPath()
		
		// CreateReaderObject() is implemented in %SQL.FDW.* subclasses and 
		// creates a reader object to place in ..ReaderObject
		set tSC = ..CreateReaderObject(Server,FTClassName)
		QUIT:'$$$ISOK(tSC)
		set i%%SQLCODE = 0
		
	} catch ex {
		try {
			set startReaderError = $find(ex.RawData,"CsvReader: ")
			if startReaderError > 0 {
				set endReaderError = $find(ex.RawData, $c(10), startReaderError) - 2 
				set readerError = $e(ex.RawData,startReaderError,endReaderError)
				set:readerError'="" ex.RemoteError = readerError
			}
		} catch ignore {
			// Exceptions originating from Java will have a RawData property but COS exceptions will not
			// and will throw a <PROPERTY NOT FOUND> exception. Move on an proceed to handling the original error
		}
		set tSC = ex.AsStatus()
	}
	
	RETURN tSC
}

/// Execute the query. For Java FDWs, this blends with the Prepare()
Method Execute(Parameters As %List = "") As %Status
{
	RETURN $$$OK
}

/// Creates an object of the class containing the functionality needed to access an external source. For now,
/// these will be Java objects (to read CSV/external DBs through JDBC).
/// 1) Create request string, which is used by the external code to connect to the relevant external
/// source.
/// 2) Instantiate the object, store it in ReaderObject property
/// Called by %SQL.FDW.Common:Execute()
Method CreateReaderObject(Server As %String, FTClassName As %String) As %Status
{
	set tSC = $$$OK
	try {
		set requestObj = ..GetRequestObject(Server, FTClassName)
		set ..ReaderObject = ..Gateway.new(..#JAVACLASS, requestObj.%ToJSON())
	} catch ex {
		try {
			set startReaderError = $find(ex.RawData,"CsvReader: ")
			if startReaderError > 0 {
				set endReaderError = $find(ex.RawData, $c(10), startReaderError) - 2 
				set readerError = $e(ex.RawData,startReaderError,endReaderError)
				set:readerError'="" ex.RemoteError = readerError
			}
		} catch ignore {
			// Exceptions originating from Java will have a RawData property but COS exceptions will not
			// and will throw a <PROPERTY NOT FOUND> exception. Move on an proceed to handling the original error
		}
		set tSC = ex.AsStatus()
	}
	
	quit tSC
}

/// Build and return request string used by Reader code for connecting to a database.
/// For a file, Server host = abs. path to directory, Table = filename+extension, port & user & pass are all N/A
Method GetRequestObject(Server As %String, FTClassName As %String) As %DynamicObject
{
	try {
		// we're going to construct a request object like the one that might come out of a LOAD DATA ... command
		// but manipulated for FTs. Then we send it to %SQL.Util.Loader:createLoadRequest() to turn it into
		// the request that would be expected by the java code.
		set requestObj = {}
		set requestObj.data = {}
		set using = $PARAMETER(FTClassName, "USING")
		if using '= "{}" {
			set requestObj.data.using = {}.%FromJSON(using)
		}
		set requestObj.data.into = {}
		set requestObj.data.from = {}
		set requestObj.data.from.loader = "$.foreigntable"
		set requestObj.data.from.file = {}
		set requestObj.data.from.file.fieldseparator = $select(($PARAMETER(FTClassName,"TABLE") ? .E1".csv"): ",", 1: $char(9))
		set requestObj.data.from.file.recordseparator = $select($zversion(1) = 2: $char(13,10), 1: $char(10))

		set dir = $PARAMETER(Server,"HOST")
		set:"/\"'[$e(dir,*) dir = dir_$select($$$isWINDOWS:"\",1:"/")
		set requestObj.data.from.file.file = dir_$PARAMETER(FTClassName, "TABLE")

		// Columns and Values are comma-separated lists, need to change them to JSON arrays
		set columnsList = $lfs($PARAMETER(FTClassName,"COLUMNS"),",",2), columnsArray = []
		set valuesList = $lfs($PARAMETER(FTClassName,"VALUES"),",",2), valuesArray = []
		set typesList = $lfs($PARAMETER(FTClassName,"COLUMNSTYPES"),",",2), typesArray = []
		set ptr = 0
		while $listnext(columnsList,ptr,value) {
			do columnsArray.%Push(value)
		}
		set requestObj.data.from.columns = columnsArray
		set ptr = 0
		while $listnext(valuesList,ptr,value) {
			do valuesArray.%Push(value)
		}
		set ptr = 0
		while $listnext(typesList,ptr,value) {
			do typesArray.%Push(value)
		}
		set requestObj.data.from.types = typesArray
		// TODO: Theoretically we could provide into types if needed, but right now createLoadRequest doesn't require them
		// and the java code doesn't make use of them...
		// Note that we have to modify %SQL.Util.Loader:getInto() to only check for into.values if it's parsing the into for 
		// a foreign table
		// Loader now expects from.select to set the names of the columns we are "selecting". This is just the external names, AKA values clause
		set requestObj.data.into.values = valuesArray, requestObj.data.from.select = valuesArray
		set loadRequest = ##class(%SQL.Util.Loader).createLoadRequest(requestObj)
		set loadRequest.from.loader = "$.foreigntable" // the loadrequest from 
	} catch ex {
		$$$ThrowStatus($$$ERROR($$$GeneralError,"Failed to create load request object"))
	}
	return loadRequest
}

Method GetSQLMetaData(Output metadata) As %Status
{
	kill metadata
	set metadata = ""
	RETURN $$$OK
}

}
