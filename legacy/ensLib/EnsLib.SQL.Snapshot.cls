/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %xmlDOM)

/// This class is a specialized result set used with the EnsLib.SQL.OutboundAdapter
/// Instances are returned as output from EnsLib.SQL.OutboundAdapter.ExecuteQuery().
/// The list of rows is a static snapshot as of the time when the query was executed
Class EnsLib.SQL.Snapshot Extends (%Persistent, %IResultSet, %XML.Adaptor) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

/// The index of the first row in this Snapshot. May be set on input when calling OutboundAdapter.ExecuteQuery() or ResultSet.GetSnapshot() to cause the first n-1 rows to be discarded before populating the Snapshot.
Property FirstRow As %Integer [ InitialExpression = 1 ];

/// The maximum number of rows to populate this Snapshot with. May be set on input to OutboundAdapter.ExecuteQuery() or ResultSet.GetSnapshot().
/// Set to -1 to get all rows no matter how many.
Property MaxRowsToGet As %Integer [ InitialExpression = 250 ];

/// Location of the storage for the fields of this Snapshot.
Property %GblRef As %String(MAXLEN = 80) [ InitialExpression = {$Name($$$EnsJobLocal($this))} ];

/// This holds the column count for this snapshot
Property ColCount As %Integer [ Calculated, ReadOnly, Transient ];

/// This holds the row count
Property RowCount As %Integer [ Calculated, ReadOnly, Transient ];

/// Are we at the last row?
Property AtEnd As %Boolean [ Calculated, ReadOnly, Transient ];

/// This is the index of the 'current' row in the Snapshot. Used by the Next(), Get(), GetData(), and Rewind() methods.
Property %CurrentRow As %Integer [ InitialExpression = 0, Transient ];

/* convert unused %AbstractResultSet properties to Transient */
Property %Message As %Library.String [ Transient ];

Property %Objects As %Library.String(MAXLEN = "") [ Internal, Transient ];

Property %Parameters As %Library.String(MAXLEN = "") [ Internal, Transient ];

Property %rsmd As %ResultSet.MetaData [ Internal, Private, Transient ];

Property %NextColumn As %RawString [ Private, Transient ];

Property %ROWCOUNT As %Library.Integer [ ReadOnly, Transient ];

Property %ROWID As %String(MAXLEN = "") [ Transient ];

Property %RuntimeMode As %Library.String [ Private, Transient ];

Property %SQLCODE As %Library.Integer [ Transient ];

Property %PrivateTables As array Of %XSQL.DS.TempTable [ Transient ];

Property %ResultColumnCount As %Library.Integer [ ReadOnly, Transient ];

Property RuntimeMode As %String [ Transient ];

Method Clean() As %Status
{
	$$$ASSERT(""=..%Id())

	#; first kill raw stream storage
	Set nRows=$G(@..%GblRef,0), nCols=$G(@..%GblRef@("ColIDs"),0) For r=1:1:nRows { For c=1:1:nCols {
		Kill:'$G(@..%GblRef@(r,c,"got"))&&$D(@..%GblRef@(r,c,"ref"),ref) @ref
	}}
	k @..%GblRef
	Set ..%CurrentRow=0
	Quit $$$OK
}

Method Rewind() As %Status
{
	Set ..%CurrentRow = 0
	Quit $$$OK
}

Method RowCountGet() As %Integer [ CodeMode = expression ]
{
$S(""=..%GblRef:0,1:$G(@..%GblRef,0))
}

Method %ROWCOUNTGet() As %Integer [ CodeMode = expression ]
{
..RowCountGet()
}

Method ColCountGet() As %Integer [ CodeMode = expression ]
{
$S(""=..%GblRef:0,1:$G(@..%GblRef@("ColIDs"),0))
}

/// Returns the number of columns in the result set
Method GetColumnCount() As %Integer [ CodeMode = expression ]
{
..ColCountGet()
}

Method AtEndGet() As %Integer [ CodeMode = expression ]
{
..%CurrentRow>..RowCount
}

/// Advance the result set cursor to the next row. Returns 0 if the cursor is at the end of the result set.
Method Next(ByRef pSC As %Status) As %Integer
{
	Set pSC=$$$OK
	Set ..%CurrentRow=..%CurrentRow+1
	Quit:..%CurrentRow'>..RowCount ..%CurrentRow
	Set ..%CurrentRow=..RowCount+1
	Quit 0
}

Method %Next(ByRef pSC As %Status) As %Integer [ CodeMode = call ]
{
..Next(.pSC)
}

/// Returns the name of column 'pColumn' in the result set.
Method GetColumnName(pColumn As %Integer = 0) As %String [ CodeMode = expression ]
{
$S(""=..%GblRef:"",1:$G(@..%GblRef@("ColNames",pColumn)))
}

Method SetColNames(pColName...) As %Status
{
	Quit:0'=..RowCount $$$ERROR($$$GeneralError,"Snapshot must have no rows when columns are set")
	Set (@..%GblRef@("ColNames"),@..%GblRef@("ColIDs"))=pColName
	For tI=1:1:pColName {
		Set @..%GblRef@("ColNames",tI)=pColName(tI)
		Set @..%GblRef@("ColIDs",$ZCVT(pColName(tI),"L"))=tI
	}
	Quit $$$OK
}

Method GetColumnID(pColName As %String) As %Integer [ CodeMode = expression ]
{
$S(""=..%GblRef:0,1:$G(@..%GblRef@("ColIDs",$ZCVT(pColName,"L")),0))
}

/// Returns the type name of column 'pColumn' in the result set.
Method GetColumnType(pColumn As %Integer = 0) As %String [ CodeMode = expression ]
{
$S(""=..%GblRef:"",1:$G(@..%GblRef@("ColTypes",pColumn)))
}

Method SetColTypes(pColType...) As %Status
{
	Quit:0'=..RowCount $$$ERROR($$$GeneralError,"Snapshot must have no rows when columns are set")
	Merge @..%GblRef@("ColTypes")=pColType
	Quit $$$OK
}

/// Returns the SQLtype integer of column 'pColumn' in the result set.
Method GetColumnSQLType(pColumn As %Integer = 0) As %Integer [ CodeMode = expression ]
{
$S(""=..%GblRef:"",1:$G(@..%GblRef@("ColTypes",pColumn,"int")))
}

/// Returns whether column 'pColumn' is a LOB (Stream) column.
Method GetColumnIsLOB(pColumn As %Integer = 0) As %Boolean [ CodeMode = expression ]
{
$S(""=..%GblRef:"",1:$G(@..%GblRef@("ColTypes",pColumn,"LOB"),0))
}

/// Returns whether column 'pColumn' contains binary data.
Method GetColumnIsBinary(pColumn As %Integer = 0) As %Boolean [ CodeMode = expression ]
{
$S(""=..%GblRef:"",1:$G(@..%GblRef@("ColTypes",pColumn,"bin"),0))
}

/// Returns the size of column 'pColumn' in the result set.
Method GetColumnSize(pColumn As %Integer = 0) [ CodeMode = expression ]
{
$S(""=..%GblRef:"",1:$G(@..%GblRef@("ColSizes",pColumn)))
}

Method SetColSizes(pColSize...) As %Status
{
	Quit:0'=..RowCount $$$ERROR($$$GeneralError,"Snapshot must have no rows when columns are set")
	Merge @..%GblRef@("ColSizes")=pColSize
	Quit $$$OK
}

/// Returns the scale of column 'pColumn' in the result set.
Method GetColumnScale(pColumn As %Integer = 0) [ CodeMode = expression ]
{
$S(""=..%GblRef:"",1:$G(@..%GblRef@("ColScales",pColumn),0))
}

Method SetColScales(pColScale...) As %Status
{
	Quit:0'=..RowCount $$$ERROR($$$GeneralError,"Snapshot must have no rows when columns are set")
	Merge @..%GblRef@("ColScales")=pColScale
	Quit $$$OK
}

/// Returns the isNullable of column 'pColumn' in the result set.
Method GetColumnisNullable(pColumn As %Integer = 0) [ CodeMode = expression ]
{
$S(""=..%GblRef:"",1:$G(@..%GblRef@("ColisNuls",pColumn),1))
}

Method SetColisNullable(pColisNul...) As %Status
{
	Quit:0'=..RowCount $$$ERROR($$$GeneralError,"Snapshot must have no rows when columns are set")
	Merge @..%GblRef@("ColisNuls")=pColisNul
	Quit $$$OK
}

/// Returns the LabelName of column 'pColumn' in the result set.
Method GetColumnLabelName(pColumn As %Integer = 0) [ CodeMode = expression ]
{
$S(""=..%GblRef:"",1:$G(@..%GblRef@("Collabels",pColumn),..GetColumnName(pColumn)))
}

Method SetColLabelName(pCollabel...) As %Status
{
	Quit:0'=..RowCount $$$ERROR($$$GeneralError,"Snapshot must have no rows when columns are set")
	Merge @..%GblRef@("Collabels")=pCollabel
	Quit $$$OK
}

/// Returns the Table of column 'pColumn' in the result set.
Method GetColumnTableName(pColumn As %Integer = 0) [ CodeMode = expression ]
{
$S(""=..%GblRef:"",1:$G(@..%GblRef@("Coltables",pColumn)))
}

Method SetColTableName(pColtable...) As %Status
{
	Quit:0'=..RowCount $$$ERROR($$$GeneralError,"Snapshot must have no rows when columns are set")
	Merge @..%GblRef@("Coltables")=pColtable
	Quit $$$OK
}

/// Returns the Schema name of column 'pColumn' in the result set.
Method GetColumnSchemaName(pColumn As %Integer = 0) [ CodeMode = expression ]
{
$S(""=..%GblRef:"",1:$G(@..%GblRef@("Colschemas",pColumn)))
}

Method SetColSchemaName(pColschema...) As %Status
{
	Quit:0'=..RowCount $$$ERROR($$$GeneralError,"Snapshot must have no rows when columns are set")
	Merge @..%GblRef@("Colschemas")=pColschema
	Quit $$$OK
}

/// Returns the Qualifier of column 'pColumn' in the result set.
Method GetColumnQualifier(pColumn As %Integer = 0) [ CodeMode = expression ]
{
$S(""=..%GblRef:"",1:$G(@..%GblRef@("Colqualifiers",pColumn)))
}

Method SetColQualifier(pColqualifier...) As %Status
{
	Quit:0'=..RowCount $$$ERROR($$$GeneralError,"Snapshot must have no rows when columns are set")
	Merge @..%GblRef@("Colqualifiers")=pColqualifier
	Quit $$$OK
}

/// Returns the Options of column 'pColumn' in the result set.
Method GetColumnOptions(pColumn As %Integer = 0) [ CodeMode = expression ]
{
$S(""=..%GblRef:"",1:$G(@..%GblRef@("Coloptions",pColumn),$C(0,1,0,1,0,0,0,0,0,0,0,0)))
}

Method SetColOptions(pColoptions...) As %Status
{
	Quit:0'=..RowCount $$$ERROR($$$GeneralError,"Snapshot must have no rows when columns are set")
	Merge @..%GblRef@("Coloptions")=pColoptions
	Quit $$$OK
}

/// Returns the value of the column with the name 'pColName' in the current row of the result set
/// Note: if the data exceeds the maximum string length then the return value will be the first 50 characters plus "..." and you should call GetStream() to get the full value.
Method Get(pColName As %String, pRow As %Integer = {..%CurrentRow}) As %String [ CodeMode = expression ]
{
$G(@..%GblRef@(pRow,$G(@..%GblRef@("ColIDs",$ZCVT(pColName,"L")),0)))
}

/// alias for Get in new result set interface
Method %Get(pColName As %String, pRow As %Integer) As %String [ CodeMode = expression ]
{
..Get(.pColName,.pRow)
}

/// Returns true if the named column in the current row contains stream data. In this case the complete value for the field can only be retrieved using the
/// GetStream() or GetDataStream() method. Otherwise the field contains simple string data that can be retrieved completely using the Get() or GetData() method.
Method HasStream(pColName As %String, pRow As %Integer = {..%CurrentRow}) As %Boolean [ CodeMode = expression ]
{
..HasDataStream($G(@..%GblRef@("ColIDs",$ZCVT(pColName,"L")),0),.pRow)
}

/// Returns as a Stream the full value of the column with the name 'pColName' in the current row of the result set.
/// If you pass a stream object in <var>pStream</var>, the data will be appended to that stream;
/// otherwise the data will be returned in a new %Stream.GlobalCharacter stream object.
/// Note that if this method creates a Stream object for you, the Stream data is already on disk
/// and you are responsible for calling stream.%Delete(stream.%Oid()) to delete the persistent storage for the new stream object
Method GetStream(pColName As %String, ByRef pStream As %Stream.Object = {$$$NULLOREF}, pRow As %Integer = {..%CurrentRow}) As %Stream.Object [ CodeMode = expression ]
{
..GetDataStream($G(@..%GblRef@("ColIDs",$ZCVT(pColName,"L")),0),.pStream,.pRow)
}

/// Deprecated - use <method>Get</method> method
Method GetDataByName(pColName As %String) As %String [ CodeMode = expression ]
{
..Get(.pColName)
}

/// Returns the value of column <var>pColumn</var> in the current row of the result set.
/// Note: if the data exceeds the maximum string length then the return value will be the first 50 characters plus "..." and you should call GetDataStream() to get the full value.<p/>
Method GetData(pColumn As %Integer, pRow As %Integer = {..%CurrentRow}) As %String [ CodeMode = expression ]
{
$G(@..%GblRef@(pRow,pColumn))
}

/// alias for GetData in new result set interface
Method %GetData(pColumn As %Integer, pRow As %Integer) As %String [ CodeMode = expression ]
{
..GetData(.pColumn,.pRow)
}

/// Returns true if the given field in the current row contains stream data. In this case the complete value for the field can only be retrieved using the
/// GetStream() or GetDataStream() method. Otherwise the field contains simple string data that can be retrieved completely using the Get() or GetData() method.
Method HasDataStream(pColumn As %Integer, pRow As %Integer = {..%CurrentRow}) As %Boolean [ CodeMode = expression ]
{
""'=$G(@..%GblRef@(pRow,pColumn,"ref"))
}

/// Returns as a Stream the full value of column <var>pColumn</var> in the current row of the result set.
/// If you pass a stream object in <var>pStream</var>, the data will be appended to that stream;
/// otherwise the data will be returned in a new %Stream.GlobalCharacter stream object.
/// Note that if this method creates a Stream object for you, the Stream data is already on disk
/// and you are responsible for calling stream.%Delete(stream.%Oid()) to delete the persistent storage for the new stream object
Method GetDataStream(pColumn As %Integer, ByRef pStream As %Stream.Object = {$$$NULLOREF}, pRow As %Integer = {..%CurrentRow}) As %Stream.Object
{
	Set tRef=$G(@..%GblRef@(pRow,pColumn,"ref"))
	If ""'=tRef {
		Set tSID=$P(tRef,"(",2), tSID=$E(tSID,1,*-1)
		Set tGCS=##class(%Stream.GlobalCharacter).%OpenId(tSID)
		Set tGCS=$S($G(@..%GblRef@("ColTypes",pColumn,"bin")):##class(%Stream.GlobalBinary).%OpenId(tSID), 1:##class(%Stream.GlobalCharacter).%OpenId(tSID))
		If $IsObject(pStream) { Do pStream.CopyFrom(tGCS), pStream.Rewind() }
		Else { Set pStream=tGCS  Set @..%GblRef@(pRow,pColumn,"got")=1 }
	} Else {
		Set:'$IsObject(pStream) pStream=$S($G(@..%GblRef@("ColTypes",pColumn,"bin")):##class(%Stream.GlobalBinary).%New(), 1:##class(%Stream.GlobalCharacter).%New())
		Do pStream.Write($Get(@..%GblRef@(pRow,pColumn))), pStream.Rewind()
	}
	Quit pStream
}

Method GetRowList() As %String
{
	Set tList=""  For tI=1:1:..ColCount {
		Set tList=tList_$LB(..GetData(tI))
	}
	Quit tList
}

Method %OnOpen() As %Status [ Private, ServerOnly = 1 ]
{
	Do ..GenerateIResultSetMetadata()
	Quit $$$OK
}

Method %OnClose() As %Status [ Private ]
{
	#; kill runtime appdata Table storage if not %Save'd
	If ""=..%Id() {
	    #; first kill raw stream storage
	    Set nRows=$G(@..%GblRef,0), nCols=$G(@..%GblRef@("ColIDs"),0) For r=1:1:nRows { For c=1:1:nCols {
		    Kill:'$G(@..%GblRef@(r,c,"got"))&&$D(@..%GblRef@(r,c,"ref"),ref) @ref
	    }}
		Kill @..%GblRef
	}
	Quit $$$OK
}

ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status
{
	#; first kill raw stream storage
	New %tID,%tGblRef  Set %tID=$$$oidPrimary(oid), %tGblRef=""
	&sql(Select %GblRef Into :%tGblRef From EnsLib_SQL.Snapshot Where ID=:%tID)
	If ""'=%tGblRef && 'SQLCODE {
		Set nRows=$G(@%tGblRef,0), nCols=$G(@%tGblRef@("ColIDs"),0) For r=1:1:nRows { For c=1:1:nCols {
			Kill:'$G(@%tGblRef@(r,c,"got"))&&$D(@%tGblRef@(r,c,"ref"),ref) @ref
		}}
	}
	#; kill appdata Table storage
	Kill @%tGblRef
	Quit $$$OK
}

Trigger OnDelete [ Event = DELETE ]
{
	#; first kill raw stream storage
	New %tID,%tGblRef  Set %tID={%%ID}, %tGblRef=""
	&sql(Select %GblRef Into :%tGblRef From EnsLib_SQL.Snapshot Where ID=:%tID)
	If ""'=%tGblRef && 'SQLCODE {
		Set nRows=$G(@%tGblRef,0), nCols=$G(@%tGblRef@("ColIDs"),0) For r=1:1:nRows { For c=1:1:nCols {
			Kill:'$G(@%tGblRef@(r,c,"got"))&&$D(@%tGblRef@(r,c,"ref"),ref) @ref
		}}
	}
	#; kill appdata Table storage
	Kill @%tGblRef
	Quit
}

Method %OnAfterSave(insert As %Boolean) As %Status [ Private ]
{
	Set tId = ..%Id()
	If ""'=tId && (..%GblRef'=$Name($$$EnsStaticAppData($$$CurrentClass,tId))) {
		#; Move contents from runtime appdata to static(id)
		Merge $$$EnsStaticAppData($$$CurrentClass,tId)=@..%GblRef  Kill @..%GblRef
		Set ..%GblRef=$Name($$$EnsStaticAppData($$$CurrentClass,tId))
		Do ..%Save(0)
	}
	Quit $$$OK
}

Method AddRow(pCol...) As %Status
{
	Quit:pCol>..ColCount $$$ERROR($$$GeneralError,"Too many column values")
	Set i=1+$G(@..%GblRef), @..%GblRef=i
	For j=1:1:..ColCount {
		Set @..%GblRef@(i,j)=$G(pCol(j))
	}
	Quit $$$OK
}

/// Creates a new Snapshot object and loads it with data from a table-formatted text file
ClassMethod CreateFromFile(pFilename As %String, pRowSeparator As %String, pColumnSeparator As %String, pColumnWidths As %String, pLineComment As %String, pStripPadChars As %String, pColNamesRow As %Integer, pFirstRow As %Integer, pMaxRowsToGet As %Integer, Output pStatus As %Status) As Snapshot
{
	Set tSS=..%New()  $$$ASSERT($IsObject(tSS))
	Set:$D(pMaxRowsToGet) tSS.MaxRowsToGet=pMaxRowsToGet
	Set:$D(pFirstRow) tSS.FirstRow=pFirstRow
	Set pStatus=tSS.ImportFile(pFilename,.pRowSeparator,.pColumnSeparator,.pColumnWidths,.pLineComment,.pStripPadChars,.pColNamesRow)
	Quit tSS
}

/// Creates a new Snapshot object and loads it with data from a table-formatted character stream
ClassMethod CreateFromStream(pIOStream As %IO.I.CharacterStream, pRowSeparator As %String, pColumnSeparator As %String, pColumnWidths As %String, pLineComment As %String, pStripPadChars As %String, pColNamesRow As %Integer, pFirstRow As %Integer, pMaxRowsToGet As %Integer, Output pStatus As %Status) As Snapshot
{
	Set tSS=..%New()  $$$ASSERT($IsObject(tSS))
	Set:$D(pMaxRowsToGet) tSS.MaxRowsToGet=pMaxRowsToGet
	Set:$D(pFirstRow) tSS.FirstRow=pFirstRow
	Set pStatus=tSS.ImportFromStream(pIOStream,.pRowSeparator,.pColumnSeparator,.pColumnWidths,.pLineComment,.pStripPadChars,.pColNamesRow)
	Quit tSS
}

Method ImportFile(pFilename As %String, pRowSeparator As %String = {$C(10)}, pColumnSeparator As %String = {$C(9)}, pColumnWidths As %String = "", pLineComment As %String = "", pStripPadChars As %String = {" "_$C(9)}, pColNamesRow As %Integer = 0) As %Status
{
#define ColIdToName(%icol)	$S(%icol\26:$C($A("a")-1+(%icol\26)),1:"")_$C($A("a")-1+(%icol#26))	
	Set tIOStream=##class(%IO.FileStream).%New(pFilename)
	if '$IsObject(tIOStream)||'tIOStream.IsOpen Quit $$$ERROR($$$EnsErrGeneral,"Unable to open "_pFilename)
	Quit ..ImportFromStream(tIOStream,.pRowSeparator,.pColumnSeparator,.pColumnWidths,.pLineComment,.pStripPadChars,.pColNamesRow)
}

/// Imports data from a table-formatted text file
/// - negative pRowSeparator means row length
/// - zero or negative pColumnSeparator means positional columns; negative pColumnSeparator gives # char columns to skip
/// - pColumnWidths means comma-separated list of char counts if positional, or integer column count if using column separator.
/// - pLineComment means a string after which the rest of a row should be ignored 
/// - pStripPadChars means characters to strip from the beginning and end of a field
/// - pColNamesRow means the index of a row that contains column names.
Method ImportFromStream(pIOStream As %IO.I.CharacterStream, pRowSeparator As %String = {$C(10)}, pColumnSeparator As %String = {$C(9)}, pColumnWidths As %String = "", pLineComment As %String = "", pStripPadChars As %String = {" "_$C(9)}, pColNamesRow As %Integer = 0) As %Status
{
#define ColIdToName(%icol)	$S(%icol\26:$C($A("a")-1+(%icol\26)),1:"")_$C($A("a")-1+(%icol#26))	
	Set:pIOStream.%Extends("%IO.I.CharacterStream") pIOStream=##Class(%IO.MetaCharacterStream).%New(pIOStream)

	Set:pRowSeparator>=0 pIOStream.LineTerminator=pRowSeparator
	Set tFirstRow=..FirstRow, tMaxRows=..MaxRowsToGet, tGblRef=..%GblRef

	#; Set up column widths and counts
	If pColumnSeparator=+pColumnSeparator&&(pColumnSeparator<=0) {
		Set (cols,pcols,maxcols)=$L(pColumnWidths,","), colPos=$S(0=pColumnSeparator:1,1:-pColumnSeparator)
		For columnId=1:1:cols {
			Set colWidths(columnId)=$P(pColumnWidths,",",columnId)
			Set:""=colWidths(columnId)&&(columnId<cols) colWidths(columnId)=1
		} Set colWidths=cols
	}
	Else { Set (pcols,maxcols)=+pColumnWidths, colWidths=0 }

	Set rowId=0  While 'pIOStream.AtEnd {
		If pRowSeparator<0 { set tLine=pIOStream.Read(-pRowSeparator) }
		Else { set tLine=pIOStream.ReadLine() }
		Continue:""=tLine
		Set rowId=rowId+1
		Set tStrip=$S(""=pStripPadChars:tLine,1:$ZStrip(tLine,"<>",pStripPadChars))
		Continue:(""'=pLineComment)&&(pLineComment=$E(tStrip,1,$L(pLineComment)))
		If rowId'=pColNamesRow {
			If rowId<=tFirstRow { If rowId=tFirstRow { Set tFirstRow=-1, rowId=1 } Else { Continue } }
			Quit:tMaxRows>=0&&(rowId>tMaxRows)
			Set ss=$I(@tGblRef)
		}
		Set:0=pcols cols=$L(tLine,pColumnSeparator) Set:cols>maxcols maxcols=cols
		Set f=0 For columnId=1:1:cols {
			If colWidths { Set tName=$E(tLine,colPos,$S(""'=colWidths(columnId):colPos+colWidths(columnId)-1,1:$L(tLine))), colPos=colPos+colWidths(columnId) }
			Else { Set tName=$P(tLine,pColumnSeparator,columnId) }

			If ""'=pLineComment Set f=$F(tName,pLineComment)  If f Set tName=$E(tName,1,f-$L(pLineComment)-1) Quit
			Set:pRowSeparator=$C(10)&&($E(tName,*)=$C(13)) $E(tName,$L(tName))=""
			Set:""'=pStripPadChars tName=$ZStrip(tName,"<>",pStripPadChars)
			If rowId'=pColNamesRow {
				Set @tGblRef@(ss,columnId)=tName, f=0
			} Else {
				Set:""=tName tName=$$$ColIdToName(columnId)
				Set tBase=$ZCVT(tName,"L")
				If 0=$D(@tGblRef@("ColIDs",tBase)) {
					Set @tGblRef@("ColIDs",tBase)=columnId
					Set @tGblRef@("ColNames",columnId)=tName
				} Else {
					Set tNI=2, tNameI=tBase_"_2"
					For { Quit:0=$D(@tGblRef@("ColIDs",tNameI))  Set tNI=tNI+1,tNameI=tBase_"_"_tNI }
					Set @tGblRef@("ColIDs",tBase_"_"_tNI)=columnId
					Set @tGblRef@("ColNames",columnId)=tName_"_"_tNI
				}
			}
		}
		If f {
			If rowId'=pColNamesRow {
				Set @tGblRef@(ss,columnId)=tName, f=0
			} Else {
				Set:""=tName tName=$$$ColIdToName(columnId)
				Set @tGblRef@("ColIDs",tName)=columnId, @tGblRef@("ColNames",columnId)=tName
			}
		}
	}
	If $D(@tGblRef@("ColIDs"))#10=0 { Set (@tGblRef@("ColIDs"),@tGblRef@("ColNames"))=maxcols }
	If $D(@tGblRef@("ColIDs"))\10=0 { For columnId=1:1:@tGblRef@("ColIDs") { Set tName=$$$ColIdToName(columnId), @tGblRef@("ColIDs",$ZCVT(tName,"L"))=columnId, @tGblRef@("ColNames",columnId)=tName } }
	Do ..GenerateIResultSetMetadata()
	Quit $$$OK
}

/// Deprecated - use <method>CreateFromResultSet</method> method
ClassMethod FromResultset(pRS As %ResultSet) As %Status [ CodeMode = expression ]
{
..%New().ImportFromResultSet(.pRS)
}

/// Creates a new Snapshot object and loads it with data from another resulset.
/// See <method>ImportFromResultSet</method> method.
ClassMethod CreateFromResultSet(pRS As %ResultSet, pLegacyMode As %Integer = 1, pODBCColumnType As %Boolean = 0, pFirstRow As %Integer, pMaxRowsToGet As %Integer, Output pStatus As %Status) As Snapshot
{
	Set tSS = ..%New()
	Set:$D(pMaxRowsToGet) tSS.MaxRowsToGet=pMaxRowsToGet
	Set:$D(pFirstRow) tSS.FirstRow=pFirstRow
	Set pStatus = tSS.ImportFromResultSet(.pRS,pLegacyMode,pODBCColumnType)
	Quit tSS
}

/// Import a result set into a Snapshot
/// ResultSet classes supported: EnsLib.SQL.GatewayResultSet, %Library.ResultSet, %ResultSet.* (%Library.IResultSet) as well as the result sets in %SQL package such as %SQL.StatementResult and %SQL.ISelectResult (%SQL.IResult)
/// If pLegacyMode is specified as 0 then attempt first to use %GetMetadata leading to different source of meta data for legacy ResultSet class
/// Default is 1 which maintains previous behavior while still supporting %SQL.* and %ResultSet.* classes.
/// If pODBCColumnType is set to 1 then ColumntType text is set to the ODBC type column type text and not the clientType.
Method ImportFromResultSet(pRS As %ResultSet, pLegacyMode As %Integer = 1, pODBCColumnType As %Boolean = 0) As %Status
{
	Quit:pRS.%IsA("EnsLib.SQL.GatewayResultSet") pRS.GetSnapshot($this)
	Set tSC = $$$OK
	#; Save metadata
	If (pLegacyMode = 1) {
		Try {
			Set nCols=pRS.GetColumnCount()
			Set tRSClassType = 1
		} Catch ex {
			Try {
				Set nCols = pRS.%GetMetadata().columns.Count()
				Set tRSClassType = 2
			} Catch ex2 {
				Set tSC = $$$ADDSC(ex2.AsStatus(),$$$ERROR($$$EnsErrGeneral,"Import class not supported"))
			}
		}
	} ElseIf (pLegacyMode = 0) {
		Try {
			Set nCols = pRS.%GetMetadata().columns.Count()
			Set tRSClassType = 2
		} Catch ex {
			Try {
				Set nCols=pRS.GetColumnCount()
				Set tRSClassType = 1
			} Catch ex2 {
				Set tSC = $$$ADDSC(ex2.AsStatus(),$$$ERROR($$$EnsErrGeneral,"Import class not supported"))
			}
		}
	} Else {
		Set tSC = $$$ERROR($$$EnsErrGeneral,"pLegacyMode Setting not supported"_": "_pLegacyMode)
	}
	Quit:$$$ISERR(tSC) tSC

	Set tGblRef=..%GblRef, @tGblRef@("ColNames")=nCols, @tGblRef@("ColIDs")=nCols, @tGblRef@("ColTypes")=nCols, @tGblRef@("ColSizes")=nCols
	For c = 1:1:nCols {
		Set tColumn = "",tOptionString = ""
		Try {
			If (tRSClassType = 1) {
				Set tName = pRS.GetColumnName(c)
			} Else {
				Set tColumn = pRS.%GetMetadata().columns.GetAt(c)
				Set tName = tColumn.colName
				Set tODBCType = tColumn.ODBCType
				Set @tGblRef@("ColTypes",c,"int") = tODBCType
				Set @tGblRef@("ColSizes",c) = tColumn.precision
				Set @tGblRef@("ColScales",c) = tColumn.scale
				Set @tGblRef@("ColisNuls",c) = tColumn.isNullable
				Set @tGblRef@("Collabels",c) = tColumn.label
				Set @tGblRef@("Coltables",c) = tColumn.tableName
				Set @tGblRef@("Colschemas",c) = tColumn.schemaName
				Set @tGblRef@("Colqualifiers",c) = tColumn.qualifier
				Set tOptionString = $Char($Select('tColumn.isAutoIncrement:0,1:1),$Select('tColumn.isCaseSensitive:0,1:1),$Select('tColumn.isCurrency:0,1:1))
				Set tOptionString = tOptionString_$Char($Select('tColumn.isReadOnly:0,1:1),$Select('tColumn.isRowVersion:0,1:1),$Select('tColumn.isUnique:0,1:1),$Select('tColumn.isAliased:0,1:1))
				Set tOptionString = tOptionString_$Char($Select('tColumn.isExpression:0,1:1),$Select('tColumn.isHidden:0,1:1),$Select('tColumn.isIdentity:0,1:1),$Select('tColumn.isKeyColumn:0,1:1),$Select('tColumn.isRowId:0,1:1))
				Set @tGblRef@("Coloptions",c) = tOptionString
			}
		} Catch ex {
			Set tSC = ex.AsStatus()
		}
		Quit:$$$ISERR(tSC)
		
		Set @tGblRef@("ColNames",c)=tName
		Set tBase=$ZCVT(tName,"L")
		If 0=$D(@tGblRef@("ColIDs",tBase)) {
			Set @tGblRef@("ColIDs",tBase)=c
		} Else {
			Set tNI=2, tNameI=tBase_"_2"
			For { Quit:0=$D(@tGblRef@("ColIDs",tNameI))  Set tNI=tNI+1,tNameI=tBase_"_"_tNI }
			Set @tGblRef@("ColIDs",tBase_"_"_tNI)=c
		}
		Try {
			If (tRSClassType = 1) {
		    	Set tColType = pRS.GetColumnType(c)
			} Else {
				Set tColType = tColumn.clientType
			}
		} Catch ex {
			Set tSC = ex.AsStatus()
		}
		Quit:$$$ISERR(tSC)

		If (pODBCColumnType = 1) {
			If ($G(tODBCType)'="") {
				Set tColTypeWord=$Case(tODBCType
					,-7:"BIT"
					,-6:"TINYINT"
					,-5:"BIGINT"
					,-4:"LONGVARBINARY"
					,-3:"VARBINARY"
					,-2:"BINARY"
					,-1:"LONGVARCHAR"
					,1:"CHAR"
					,2:"NUMERIC"
					,3:"DECIMAL"
					,4:"INTEGER"
					,5:"SMALLINT"
					,6:"FLOAT"
					,7:"REAL"
					,8:"DOUBLE"
					,9:"DATE"
					,91:"DATE"
					,10:"TIME"
					,92:"TIME"
					,11:"TIMESTAMP"
					,93:"TIMESTAMP"
					,12:"VARCHAR"
					,:"N/A:"_tODBCType)
			} Else { Set tColTypeWord = ""}
		} Else {
			Set tColTypeWord=$Case(tColType
				,1 :"BINARY"
				,2 :"DATE"
				,3 :"DOUBLE"
				,4 :"HANDLE"
				,5 :"INTEGER"
				,6 :"LIST"
				,7 :"LONGVARCHAR"
				,8 :"TIME"
				,9 :"TIMESTAMP"
				,10:"VARCHAR"
				,11:"STATUS"
				,12:"BINARYSTREAM"
				,13:"CHARACTERSTREAM"
				,14:"NUMERIC"
				,15:"CURRENCY"
				,16:"BOOLEAN"
				,17:"OID"
				,18:"BIGINT"
				,19:"FDATE"
				,20:"FTIMESTAMP"
				,:"N/A:"_tColType)
		}
		Set @tGblRef@("ColTypes",c) = $G(tColTypeWord)
		If (tRSClassType>1) {
			Try {Do pRS.%GetMetadata().columns.%UnSwizzleAt(c)} Catch ex {}
		}
	}
	Quit:$$$ISERR(tSC) tSC

	Try {
		If (tRSClassType=1) {
	    	Merge ..%Metadata=pRS.%Metadata ; shortcut for Do ..GenerateIResultSetMetadata()
		} Else {
			Do ..GenerateIResultSetMetadata()
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit:$$$ISERR(tSC) tSC

	#; Save data
	Set r=0  While pRS.%Next(.tSC) { Set r=r+1 For c = 1:1:nCols { Set @tGblRef@(r,c) = pRS.%GetData(c) } }
	Set @tGblRef=r
	Quit tSC
}

Method XMLExportInternal() As %Status [ ProcedureBlock = 0 ]
{
	//(topArg As %Library.String = "Snapshot", fmt As %Library.String, namespaces As %XML.Namespaces, attrsArg As %Library.String, createId As %Library.String, typeAttr As %Library.String, oreflist As %Library.String, idlist As %Library.String, currentIndent As %Library.String, local As %Library.Boolean)
	Set:""=$G(topArg) topArg="Snapshot"
	New nCols,nRows,tName,tType,tSize,c,r,tValue,tChunk
	Set nCols=..ColCount, nRows=..RowCount
	Write "<"_topArg_" Rows='"_nRows_"' FirstRow='"_..FirstRow_"'>",!
	If nCols {
		Write "<Columns Count='"_nCols_"'>"
		For c=1:1:nCols {
			Set tName=..GetColumnName(c), tType=..GetColumnType(c), tSize=..GetColumnSize(c)
			Write "<col ID='"_c_"' Name='"_tName_"'"_$S(""=tType:"",1:" Type='"_tType_"'")_$S(""=tSize:"",1:" Size='"_tSize_"'")_"/>"
		}
		Write "</Columns>",!

		#; Write rows
		For r=1:1:nRows {
			Write "<Row Num='"_r_"'>"
			For c=1:1:nCols { Write "<col ID='"_c_"'>"
				If ..HasDataStream(c,r) {
					Write "<![CDATA[" Do ..GetDataStream(c,r).OutputToDevice()  Write "]]>"
				} Else {
					Set tValue=..GetData(c,r)
					While ""'=tValue {
						Set tChunk=$E(tValue,1,1000), tValue=$E(tValue,1001,*)
						Write $ZCVT(tChunk,"O","XML")
					}
				}
				Write "</col>"
			}
			Write "</Row>",!
		}
	}
	Write "</"_topArg_">",!
	Quit $$$OK
}

Method XMLImportInternal() As %Status [ ProcedureBlock = 0 ]
{
 //(tag As %Library.String, fmt As %Library.String, namespace As %Library.String, handler As %XML.Document, nodeArg As %Library.Integer, idlist As %Library.String, keynameattr As %Library.String, list As %Library.ListOfObjects)
 New sc,node,nsIndex,child,ref,data
 Set sc=1
 Set $ztrap="XMLImportTrap"
 Set nsIndex=$select($get(namespace)="":"",1:$get(@tree@("ns",namespace)))
 If tag="" Set tag="Snapshot"
 If ($$$xmlGetNodeType(tree,nodeArg)'="e")||(tag'=@tree@(nodeArg)) Set ref=nodeArg Goto XMLImportMalformed
 If encoded {
   If $data(@tree@(nodeArg,"a","id")) Set idlist(nodeArg)=$this
 }
 If $get(@tree@(nodeArg,"nil"),0) Quit 1
 Set sc=$$XMLImportElements(nodeArg)
XMLImportExit Quit sc
XMLImportElements(node)
 Set child=""
XMLLOOP For  { Set child=$order(@tree@(node,"c",child)) If (child="")||($$$xmlGetNodeType(tree,child)'="w") Quit }
 If child="" {
	Do ..GenerateIResultSetMetadata()
	Quit sc
 }
 Set tag=@tree@(child)
 Set ref=child
 If $$$xmlGetNodeType(tree,ref)'="e" Goto XMLImportMalformed
 If tag="FirstRow" {
   If ($get(namespace)'="")&&'$case(@tree@(ref,"u"),"":1,nsIndex:1,:0) Goto XMLImportNS
   If encoded&&$$XMLImportId() {
     Set data=idlist(ref)
   } Else { Goto:'sc XMLImportExit
     If $get(@tree@(ref,"nil"),0) { Set data=""
     } Else {
           Set data=$order(@tree@(ref,"c",""))
           If $order(@tree@(ref,"c",data))'="" {
             Set data="" Goto XMLImportErr
           } ElseIf data'="" { Goto:$$$xmlGetNodeType(tree,data)="e" XMLImportErr Set data=@tree@(data) }
           Set data=$zstrip(data,"<>W",$c(13,10)) If data'="" /*Set data=##class(EnsLib.SQL.Snapshot).FirstRowXSDToLogical(data)*/ Goto:data="" XMLImportErr /*Goto:('##class(EnsLib.SQL.Snapshot).FirstRowIsValid(data)) XMLImportErr*/
     }
     If encoded&&($data(@tree@(ref,"a","id"))) Set idlist(ref)=data
   }
   Set i%FirstRow=data
   Goto XMLLOOP }
 If tag="MaxRowsToGet" {
   If ($get(namespace)'="")&&'$case(@tree@(ref,"u"),"":1,nsIndex:1,:0) Goto XMLImportNS
   If encoded&&$$XMLImportId() {
     Set data=idlist(ref)
   } Else { Goto:'sc XMLImportExit
     If $get(@tree@(ref,"nil"),0) { Set data=""
     } Else {
           Set data=$order(@tree@(ref,"c",""))
           If $order(@tree@(ref,"c",data))'="" {
             Set data="" Goto XMLImportErr
           } ElseIf data'="" { Goto:$$$xmlGetNodeType(tree,data)="e" XMLImportErr Set data=@tree@(data) }
           Set data=$zstrip(data,"<>W",$c(13,10)) If data'="" Set data=##class(EnsLib.SQL.Snapshot).MaxRowsToGetXSDToLogical(data) Goto:data="" XMLImportErr Goto:('##class(EnsLib.SQL.Snapshot).MaxRowsToGetIsValid(data)) XMLImportErr
     }
     If encoded&&($data(@tree@(ref,"a","id"))) Set idlist(ref)=data
   }
   Set i%MaxRowsToGet=data
   Goto XMLLOOP }
 If tag="_GblRef" {
   If ($get(namespace)'="")&&'$case(@tree@(ref,"u"),"":1,nsIndex:1,:0) Goto XMLImportNS
   If encoded&&$$XMLImportId() {
     Set data=idlist(ref)
   } Else { Goto:'sc XMLImportExit
     If $get(@tree@(ref,"nil"),0) { Set data=""
     } Else {
           Set data=$order(@tree@(ref,"c",""))
           If $order(@tree@(ref,"c",data))'="" {
             Set data="" If '##class(%XML.ImportHandler).SerializeNode(tree,ref,0,0,.data) Goto XMLImportErr
           } ElseIf data'="" { Goto:$$$xmlGetNodeType(tree,data)="e" XMLImportErr Set data=@tree@(data) }
           If data'="" Goto:('##class(EnsLib.SQL.Snapshot).%GblRefIsValid(data)) XMLImportErr
           If data="" Set data=$c(0)
     }
     If encoded&&($data(@tree@(ref,"a","id"))) Set idlist(ref)=data
   }
   Set i%%GblRef=data
   Goto XMLLOOP }
 If tag="ColCount" {
   If ($get(namespace)'="")&&'$case(@tree@(ref,"u"),"":1,nsIndex:1,:0) Goto XMLImportNS
   Goto XMLLOOP }
 If tag="RowCount" {
   If ($get(namespace)'="")&&'$case(@tree@(ref,"u"),"":1,nsIndex:1,:0) Goto XMLImportNS
   Goto XMLLOOP }
 If tag="AtEnd" {
   If ($get(namespace)'="")&&'$case(@tree@(ref,"u"),"":1,nsIndex:1,:0) Goto XMLImportNS
   Goto XMLLOOP }
 If tag="_CurrentRow" {
   If ($get(namespace)'="")&&'$case(@tree@(ref,"u"),"":1,nsIndex:1,:0) Goto XMLImportNS
   If encoded&&$$XMLImportId() {
     Set data=idlist(ref)
   } Else { Goto:'sc XMLImportExit
     If $get(@tree@(ref,"nil"),0) { Set data=""
     } Else {
           Set data=$order(@tree@(ref,"c",""))
           If $order(@tree@(ref,"c",data))'="" {
             Set data="" Goto XMLImportErr
           } ElseIf data'="" { Goto:$$$xmlGetNodeType(tree,data)="e" XMLImportErr Set data=@tree@(data) }
           Set data=$zstrip(data,"<>W",$c(13,10)) If data'="" /*Set data=##class(EnsLib.SQL.Snapshot).%CurrentRowXSDToLogical(data)*/ Goto:data="" XMLImportErr /*Goto:('##class(EnsLib.SQL.Snapshot).%CurrentRowIsValid(data)) XMLImportErr*/
     }
     If encoded&&($data(@tree@(ref,"a","id"))) Set idlist(ref)=data
   }
   Set i%%CurrentRow=data
   Goto XMLLOOP }
 Goto XMLImportBadTag
XMLImportBadTag Quit $$Error^%apiOBJ(6237,tag)
XMLImportBadType Quit $$Error^%apiOBJ(6277,class,tag)
XMLImportErr
 Set data=$order(@tree@(ref,"c",""))
 If (data'="") {
   If $$$xmlGetNodeType(tree,data)'="e" {
     Quit $$Error^%apiOBJ(6232,@tree@(ref),$extract(@tree@(data),1,200))
   } Else {
     Quit $$Error^%apiOBJ(6253,@tree@(ref),@tree@(data))
   }
 } Else {
   Quit $$Error^%apiOBJ(6252,@tree@(ref))
 }
XMLImportIdErr Set sc=$$Error^%apiOBJ(6236,id,@tree@(ref)) Quit sc
XMLImportMalformed Set sc=$$Error^%apiOBJ($select($$$xmlGetNodeType(tree,ref)="e":6233,1:6254),@tree@(ref)) Quit sc
XMLImportNS Set sc=$$Error^%apiOBJ(6235,@tree@(ref)) Quit sc
XMLImportTrap Set $ztrap=""
 If $ZE["<CLASS DOES NOT EXIST>" Goto XMLImportBadTag
 Quit $$Error^%apiOBJ(5002,$ZE)
XMLImportId() ;
 If $data(@(tree)@(ref,"a","href")) {
   Set id=$get(@(tree)@(ref,"a","href"))
   If $extract(id)="#" {
     Set tmp=$get(@(tree)@("id",$extract(id,2,*))) If tmp="" Goto XMLImportIdErr
     Set ref=tmp
   }
 } ElseIf $data(@(tree)@(ref,"a","ref")) , ($select($get(@(tree)@(ref,"a","ref","u"))="":"",1:$get(@(tree)@("ns#",@(tree)@(ref,"a","ref","u"))))="http://www.w3.org/2003/05/soap-encoding") {
   Set id=$get(@(tree)@(ref,"a","ref"))
   Set tmp=$get(@(tree)@("id",id)) If tmp="" Goto XMLImportIdErr
   Set ref=tmp
 } ElseIf '$data(@(tree)@(ref,"a","id")) {
   Quit 0
 }
 Quit $data(idlist(ref))
}

Method GenerateIResultSetMetadata()
{
 // %protocol version 41 metadata
	Set tColCount=..ColCount
	Set ..%Metadata = $LB(tColCount) // # of SELECT columns
	For i=1:1:tColCount {
		Set tName=..GetColumnName(i)
		Set ..%Metadata = ..%Metadata_$LB(tName				 // 			1) Name
										, ..GetColumnSQLType(i) // 			2) ODBC Type
										, ..GetColumnSize(i) // 			3) Precision
										, ..GetColumnScale(i) // 			4) Scale 
										, ..GetColumnisNullable(i) //		5) NULLABLE (integer) ;jgm
										, ..GetColumnLabelName(i) //		6) Column Label (same as Name)
 										, ..GetColumnTableName(i) //		7) Column Table Name
 										, ..GetColumnSchemaName(i) //		8) Column Schema Name
										, ..GetColumnQualifier(i) //		9) Column Qualifier Name - NULL
										, ..GetColumnOptions(i)  // 		10) $Char(1)/$Char(0) string / $Extract position:
										)
						 // 				1)  isAutoIncrement
						 // 				2)  isCaseSensitive
						 // 				3)  isCurrency
						 // 				4)  IsReadOnly
						 // 				5)  IsRowVersion
						 // 				6)  IsUnique
						 // 				7)  IsAliased
						 // 				8)  IsExpression
						 // 				9)  IsHidden
						 // 				10) IsIdentity
						 // 				11) IsKeyColumn
						 // 			    12) IsRowid		// DPV3092
	}
	Set ..%Metadata = ..%Metadata_$LB(0) // # of Parameters
 // 		j+1 - k:  <For each Parameter>
 // 			1) ODBC Type
 // 			2) Precision
 // 			3) Scale
 // 			4) NULLABLE
 // 				5) colName
 // 				6) colType
}

Method GetInfo(extoption) As %Status [ Private ]
{
	/*
	New %sc,colinfo,extinfo,i,idinfo,paraminfo,QHandle
	Merge QHandle=i%QHandle
	Set extoption=$Get(extoption,0),extinfo=""
	Set %sc=$zobjclassmethod(i%ClassName,i%QueryName_"GetInfo",.colinfo,.paraminfo,.idinfo,.QHandle,$Get(extoption,0),.extinfo)
	Kill i%QHandle,i%ColIndex Merge i%QHandle=QHandle
	If $$$ISERR(%sc) Set i%ColIndex=0,i%ColInfo="",i%ParamInfo="",i%IdInfo="",i%ColExtInfo="" Quit %sc
	Set i%ColInfo=colinfo,i%ParamInfo=paraminfo,i%IdInfo=idinfo,i%HasInfo=1,i%ColIndex=$listlength(colinfo)
	If $ll(extinfo) { Set i%ColExtInfo=$List(extinfo,2),i%StatementType=$List(extinfo,1) }
	Set:extoption i%HasExtInfo=1
	For i=1:1:i%ColIndex Set i%ColIndex(i)=$list($list(colinfo,i))
	Quit %sc
	*/
	Quit $$$OK
}

Method GetODBCInfo(ByRef colinfo As %List, ByRef parminfo As %List) As %Status
{
	/*
	Merge QHandle=i%QHandle
	Set sc=$zobjclassmethod(i%ClassName,i%QueryName_"GetODBCInfo",.colinfo,.parminfo,.QHandle)
	Kill i%QHandle Merge i%QHandle=QHandle
	Quit sc
	*/
	Quit 0
}

/// Returns the name of column <var>n</var> in the result set.
Method GetColumnExtInfo(n As %Integer) As %String [ CodeMode = expression ]
{
""
}

/// Returns true (1) if the ClassName and QueryName properties of this 
/// <nobr><b>%ResultSet</b></nobr> object refer to a valid class query. 
/// Otherwise it returns false (0).
Method QueryIsValid() As %Integer [ CodeMode = expression ]
{
0
}

Storage Default
{
<Data name="SnapshotDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>%Dummy</Value>
</Value>
<Value name="3">
<Value>%GblRef</Value>
</Value>
<Value name="4">
<Value>FirstRow</Value>
</Value>
<Value name="5">
<Value>MaxRowsToGet</Value>
</Value>
</Data>
<DataLocation>^EnsLib.S.SnapshotD</DataLocation>
<DefaultData>SnapshotDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^EnsLib.S.SnapshotD</IdLocation>
<IndexLocation>^EnsLib.S.SnapshotI</IndexLocation>
<StreamLocation>^EnsLib.S.SnapshotS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
