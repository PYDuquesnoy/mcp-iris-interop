/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %SYS.DBSRV

/// A Static result set is one where the original data source (a result set object) is copied to a process
/// private global upon instantiation. Future data requests then use that snapshot instead of the original
/// data.
Class %ResultSet.Static Extends %Library.IResultSet [ System = 4 ]
{

Property %storageOffset As %Integer [ Private ];

Property %currentRow As %Integer [ Private ];

Property %columnCount As %Integer [ Private ];

/// %Data is a multidimensional property of column values for the current row. It is subscripted by column
/// number.
Property %Data As %String(MAXLEN = "") [ MultiDimensional, Private ];

Property %hasStreams As %Integer [ InitialExpression = 0, Private ];

Property %streams As %String [ Internal, MultiDimensional ];

Property %streamColumns As %String(MAXLEN = "") [ Internal ];

Property %lastRow As %Integer [ Private ];

/// %RowCount for a static result set is always the number of rows in the static set.
Method %ROWCOUNTGet() As %Integer [ CodeMode = expression ]
{
i%%lastRow
}

Method %OnNew(initvalue As %RawString, pRuntimeMode As %Integer = {$zu(115,5)}) As %Status [ Private, ProcedureBlock = 1, PublicList = SQLCODE, ServerOnly = 1 ]
{
		#; allocate storage
	new SQLCODE
	set i%%storageOffset = $Increment($$$tFileRoot)
	kill $$$tFile(i%%storageOffset)
	set $$$tFile(i%%storageOffset) = 0
		#; Take the snapshot
	if $isobject(initvalue) {
			#; Grab the result set data and metadata from the donor result set
		set lastRow = 0, status = initvalue.%CreateSnapshot(i%%storageOffset,.lastRow,.tRuntimeMode,$this), i%%lastRow = lastRow, ..%RuntimeMode = tRuntimeMode,..%Objects = initvalue.%Objects
			#; This class only recognizes a single node of metadata
		merge tMetadata = initvalue.%Metadata
		if $Get(tMetadata) = "" { set tMetadata = tMetadata($Order(tMetadata(""))) }
		set ..%Metadata = tMetadata
			#; The result set will only return an error status if something went wrong. Otherwise we can assume that all rows are in the snapshot
		if $$$ISOK(status) { set i%%columnCount = $List(..%Metadata,1) } else { set ..%SQLCODE = initvalue.%SQLCODE, ..%Message = "error encountered while taking result set snapshot" }
	}
	elseif initvalue {
			#; must be a straight xDBC statement - probably SELECT or a query procedure
		new %qacn,%qHandle
		set %qacn = initvalue
		if $G($$$SPName) '= "" {
				#; query stored procedure
			Merge %qHandle=$$$SPHandle Set %sqlcontext=$$$SPContext If '$isobject(%sqlcontext) { set ..%SQLCODE = -430, ..%Message = "Context object invalid" Goto Error }
			set i%%columnCount = $Get($$$ColumnCount)
				#; We'll take runtime mode from the parameter list
			set ..%RuntimeMode = pRuntimeMode
			set sc=$classmethod($$$SPClassName,$$$SPName_"Fetch",.%qHandle,.row)
			set columnCount=i%%columnCount,rowPtr=0, storageOffset = i%%storageOffset
			while ($$$ISOK(sc))&&(row'="") {
				set rowPtr = rowPtr + 1
				set ptr = 0, column = 0
				while $listnext(row,ptr,data) {
					If column = 0 {
						Set $$$tFile(storageOffset,rowPtr,$increment(column)) = data
					} Else {
						Set ^($increment(column)) = data
					}
				}
				set sc=$classmethod($$$SPClassName,$$$SPName_"Fetch",.%qHandle,.row)
			}
			if $$$ISERR(sc) {  set ..%SQLCODE = -400, ..%Message = "error encountered while taking result set snapshot" }
			set i%%lastRow = rowPtr, $$$tFile(i%%storageOffset) = rowPtr
			set qrc = $classmethod($$$SPClassName,$$$SPName_"Close",.%qHandle)
			kill $$$LastPce, $$$FetchStatus,%sqlcontext,$$$SPHandle
		}
		else {
				#; %RuntimeMode should really be the SELECTMODE of the donor select statement but I don't know how to get it.
				#; Let's assume it is ODBC
			set ..%RuntimeMode = 1
				#; probably a select statement
				#; cq oref should have been defined in Prepare^%SYS.SQLSRV earlier
			if $G($$$FetchStatus) {
				do $$$CQoref.%OnClose() set qrc=SQLCODE  // %OnClose implicitly sets SQLCODE
				if qrc set ..%SQLCODE = -qrc, ..%Message = "error closing cursor from previous fetch in while taking result set snapshot"
				kill $$$FetchStatus
			}
			new %col	// %col is used in the cached query as the INTO array.  New it here, then it could be set in %Open and FetchRows without needing to be new'd or killed in the cached query
			set $$$CQoref=$$$CQoref.Query(,0)
			set qrc=$$$CQoref.%Open()	// This Opens the SQL Query
			if qrc set ..%SQLCODE = -qrc, ..%Message = "error opening cached query object to take result set snapshot"
			set qrc = $$$CQoref.FetchRows(i%%storageOffset)
			if $d($$$srv),$$$logging {
				do ##class(%SYS.DBSRV).logappend("%ResultSet.Static.%OnNew:  "_$$$CQoref_".FetchRows called - storage offset = "_i%%storageOffset)
				do ##class(%SYS.DBSRV).logappend("qrc: "_qrc_", ColumnCount: "_$Get($$$ColumnCount)_", last row: "_$$$tFile(i%%storageOffset))
			}
				#; A normal return is qrc = 100 - all other values, including 0, indicate that something is wrong. Of course, 0 should never be returned since we are asking for all rows
			if qrc = 100 { set i%%columnCount = $Get($$$ColumnCount), i%%lastRow = $$$tFile(i%%storageOffset) } else { set ..%SQLCODE = -qrc, ..%Message = "error encountered while taking result set snapshot" }
			do $$$CQoref.%OnClose() set qrc=SQLCODE
			kill $$$FetchStatus
		}
	}
	else { set ..%SQLCODE = -400, ..%Message = "no current statement or result set to create snapshot from" }
	set i%%hasStreams = $Find(i%%streamColumns,$Char(1))
		#; always return ok - we want the object. The object state will reflect any status information that the caller may need
	quit $$$OK
Error	set $ZTRAP= ""
	quit $$$OK
}

Method %OnClose() As %Status [ Private ]
{
	if i%%storageOffset { kill $$$tFile(i%%storageOffset) }
	quit $$$OK
}

Method %SendRows() As %Integer
{
	set qrc = 0, from = $$$ReadNext, nrows = $$$ReadNext, to = from + nrows - 1
	if $d($$$srv),$$$logging { do ##class(%SYS.DBSRV).logappend("%SendRows - requested: from="_from_", nrows="_nrows) }
		#; get last row request
	if from = 0 { set from = i%%lastRow, to = from set:'to qrc = 100 }
	elseif i%%lastRow '> to { set to = i%%lastRow, qrc = 100 }
	set a = to - from + 1 set:a<0 a = 0
	set b = from set:qrc=100 b = i%%lastRow
	set b = $Select(from'>i%%lastRow:from,1:i%%lastRow)
	$$$WriteData(b)
	if to > 0 {
		#; number of rows processed
		$$$WriteData(a)
		set columnCount=i%%columnCount,storageOffset=i%%storageOffset
		if $d($$$srv),$$$logging { do ##class(%SYS.DBSRV).logappend("%SendRows - tFile="_$name($$$tFile(storageOffset))_", columnCount="_columnCount) }
		for row = from:1:to {
			set tRow = $Get($$$tFile(storageOffset,row)), tPtr = 0
			for tColumn=1:1 { quit:'$Listnext(tRow,tPtr,tValue)  $$$WriteData(tValue) }
			if tColumn '> columnCount {
				$$$WriteData($Get($$$tFile(storageOffset,row,tColumn)))
				for tColumnOv = tColumn+1:1:columnCount $$$WriteData($Get(^(tColumnOv)))
			}
		}
	}
	else { $$$WriteData(0) }
	if $d($$$srv),$$$logging { do ##class(%SYS.DBSRV).logappend("%SendRows - sent: from="_from_", to="_to) }
	quit qrc
}

/// Fetch and send a series of rows for the ODBC/JDBC server. For internal use only.
Method %SendODBC() As %Library.Integer
{
	new %row
		#; process any orphans
	if ..%NextColumn {	// Should only be TRUE if %protocol<51 or there are stream columns
		for ptr=..%NextColumn:1:i%%columnCount {
			if '($Ascii(i%%streamColumns,ptr)) { set tVal = i%%Data(ptr) } 
			else { set tVal = $Get(i%%streams(i%%currentRow,ptr)) if $Isobject(tVal) { set:$Get(%qacn) %qobjhandle(%qacn,tVal) = tVal set tVal = tVal _ "" } }
			goto:$zobjexport(tVal,7) Done
		}
	}
	set ..%NextColumn = 0
Fetch2
	if ..%Next(.sc) {
		if %protocol>50,'i%%hasStreams {
				// Can't send $name(i%%Data) to $zobjexport, so move it into a public array() and then send the row
			merge %row=i%%Data
			quit:$zobjexport($name(%row),56) 0	// Buffer full, SQLCODE=0
			goto Fetch2	// Get another row to put in this buffer
		}
		for ptr=1:1:i%%columnCount {
			set tVal = i%%Data(ptr)
			if ($Ascii(i%%streamColumns,ptr)) && ($Isobject(tVal)) { set:$Get(%qacn) %qobjhandle(%qacn,tVal) = tVal set tVal = tVal _ "" }
			if $zobjexport(tVal,7) Goto Done
		}
		Goto Fetch2
	}
	else {	// ..%Next returned FALSE
		set SQLCODE=100
		if $d(sc)#2,('sc) { 
			if SQLCODE=0||(SQLCODE=100) { set SQLCODE=-400,%msg=$$GetErrorText^%apiOBJ(sc) }
		}
		QUIT SQLCODE
	}
Done set ..%NextColumn=ptr Quit 0
}

/// Advance the result set cursor to the next row. Returns 0 if the cursor is at the end of the 
/// result set.
/// The global structure consists of a base $list with individual nodes for columns. The base $list() can contain zero or more column
/// values. Additional column values are stored in the global subscripted by column number and equal to the column value.
Method %Next(ByRef sc As %Library.Status = {$$$OK}) As %Library.Integer
{
	
	set tRowPtr=$increment(i%%currentRow)
	if tRowPtr > i%%lastRow Quit 0
	set storageOffset=i%%storageOffset
	set tRow = $Get($$$tFile(storageOffset,tRowPtr)), tPtr = 0
	for tColumn=1:1 { quit:'$Listnext(tRow,tPtr,tValue)  set i%%Data(tColumn) = tValue }
	if tColumn '> i%%columnCount {
		set i%%Data(tColumn)=$Get($$$tFile(storageOffset,tRowPtr,tColumn))
		for tColumnOv = tColumn+1:1:i%%columnCount set i%%Data(tColumnOv) = $Get(^(tColumnOv))
	}
	if i%%hasStreams {
		set tPtr = i%%hasStreams
		do {
			set tColumn = tPtr - 1
			if $Data(i%%streams(tRowPtr,tColumn)) { set i%%Data(tColumn) = i%%streams(tRowPtr,tColumn) }
			set tPtr = $Find(i%%streamColumns,$Char(1),tPtr)
		} while tPtr
	}
	quit 1
}

/// Returns the value of the column with the name <var>name</var> in the current row of the result set.
/// <p>If <var>name</var> is not a valid column name, this method returns an empty string.
Method %Get(colname As %String = "") As %Library.String
{
	set tRSMD = ..%GetMetaData()
	set tCOLUMNNAME = $$$ucase(colname)
	if $Data(tRSMD.columnIndex(tCOLUMNNAME)) { set rReturnValue = $Get(i%%Data($List(tRSMD.columnIndex(tCOLUMNNAME),1))) }
	else { $$$ThrowPropertyDoesNotExistError(colname) }
	quit rReturnValue
}

/// Returns the value of column <var>colnbr</var> in the current row of the result set.
Method %GetData(colnbr As %Integer = 0) As %Library.String
{
	if colnbr '> i%%columnCount { set rReturnValue = $Get(i%%Data(colnbr)) }
	else { $$$ThrowPropertyDoesNotExistError("Column #: "_colnbr) }
	quit rReturnValue
}

Method %SetIterator(pRowNumber As %Library.Integer = 0) As %Library.Integer
{
	if pRowNumber '> i%%lastRow { set i%%currentRow = pRowNumber } else { set i%%currentRow = i%%lastRow }
	quit i%%currentRow
}

}
