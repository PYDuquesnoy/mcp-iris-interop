/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsSQLTypes)

/// This class is a specialized result set used with the SQLGatewayOutboundAdapter
/// Instances are returned as output from the SQLGatewayOutboundAdapter ExecuteQuery()
/// method. The result set is only valid while the SQL.OutboundAdapter's connection
/// is connected
Class EnsLib.SQL.GatewayResultSet Extends (%RegisteredObject, %AbstractResultSet) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// This holds the SQL Query statement associated with this resultset
Property QueryStatement As %String(MAXLEN = "") [ Internal, ReadOnly ];

/// This holds the connected Adapter object
Property %Adapter As EnsLib.SQL.OutboundAdapter [ Internal, ReadOnly ];

/// This holds the connected SQLGateway or JDBC connection
Property %Connection As %RegisteredObject [ Internal, ReadOnly ];

/// This holds the maximum string length for the current job (gotten from $$$MaxLocalLength)
Property MaxString As %Integer [ ReadOnly ];

/// This holds the Handle of the statement associated with the result set
Property %HS As %String [ Internal, ReadOnly ];

/// This marks the ResultSet as being the last object holding open the Connection.
Property %Final As %Boolean [ Internal, ReadOnly ];

/// This holds the column descriptions for this query
Property ColName [ Internal, MultiDimensional, ReadOnly ];

/// This maps the column names to the column IDs (case-insensitive)
Property ColID [ Internal, MultiDimensional, ReadOnly ];

/// This maps the column datatypes
Property ColType [ Internal, MultiDimensional, ReadOnly ];

/// This maps the column sizes
Property ColSize [ Internal, MultiDimensional, ReadOnly ];

/// This holds the column count for this resultset
Property ColCount As %Integer [ Calculated, Internal, ReadOnly, Transient ];

/// This is a multi-dimensional property that contains the data of the current row
Property Data [ MultiDimensional, ReadOnly ];

/// Indicates support for LOB optimization. 1 means we count on GetData() returning 1 (SqlSuccessWithInfo) when there is more data; 0 means we always loop until GetData() returns 100 (SqlNoMoreData).<br/>
/// 1 optimizes for speed with single non-LOB fetches if we can count on LOBs being reported properly, 1 always checks in a loop in case a field might have extra data, even though it means twice as many ODBC calls for non-LOB fields.
/// 0 also means support ODBC returning an error instead of SQLCODE 100 when there is no more data.
Parameter LOBSUCCESSWITHINFO = 1;

Method ColCountGet() As %Integer [ CodeMode = expression ]
{
$G(..ColName,0)
}

/// To be called by EnsLib.SQL.OutboundAdapter to set up the initial state
Method Initialize(pQueryStatement As %String, pAdapter As EnsLib.SQL.OutboundAdapter, pHS As %String, pFinal As %Boolean, pMoreIndex As %Integer) As %Status
{
#define QueryColumnsTable(%query)	$$$EnsRuntimeAppData(pAdapter.BusinessHost.%ConfigName,"%QCols",%query)
#dim ex As %Exception.AbstractException

	Set $ZT="Trap",tSC=$$$OK
	Set i%QueryStatement=pQueryStatement,r%%Adapter=pAdapter,r%%Connection=pAdapter.%Connection,i%%HS=pHS,i%%Final=pFinal
	
	#; Look for cached columns description for this statement (this iteration of it if it's a multi-resultset SP statement)
	#; pMoreIndex = -1 means do not use cached data
	#dim tGetMetatData As %Boolean = 1
	If (pMoreIndex'=-1) {
		#dim tTableKey As %String
		Set tTableKey=$S($L(pQueryStatement)<=230:pQueryStatement, 1:$E(pQueryStatement,1,210)_".x"_$$$NUM($ZHex($ZCRC($E(pQueryStatement,211,*),7)),8))_"_"_pMoreIndex
		Try {
			If $D($$$QueryColumnsTable(tTableKey),tCols) {
				Set tSC=$$$OK, tColCount=$LG($LG(tCols)), tGetMetatData=0
				$$$sysTRACE("Using cached "_tColCount_" DescribeColumns values ; key="_tTableKey)
			}
		} Catch ex {
			If (ex.Name'="<SUBSCRIPT>") {throw ex}
			Set tTableKey = $system.Encryption.Base64Encode($system.Encryption.SHA1Hash(tTableKey))
			If $D($$$QueryColumnsTable(tTableKey),tCols) {
				Set tSC=$$$OK, tColCount=$LG($LG(tCols)), tGetMetatData=0
				$$$sysTRACE("Using cached "_tColCount_" DescribeColumns values ; key="_tTableKey)
			}
		}
	}
	If tGetMetatData {
		#; Ask the gateway to describe the columns for this statement
		Set tSC=..%Connection.DescribeColumns(..%HS,.tCols)
		Quit:$$$ISERR(tSC) tSC
		#; Determine the number of columns in the query result (there is a headers list element, so $LL(tCols)=ColCount+1
		Set tColCount=$LG($LG(tCols))
		$$$ASSERT($LL(tCols)-1=tColCount)
		Set:pMoreIndex'=-1 $$$QueryColumnsTable(tTableKey)=tCols
		$$$sysTRACE("DescribeColumns returned "_tColCount_$S(pMoreIndex'=-1:" ; cacheing with key="_tTableKey, 1:""))
	}
	#; Walk through the column list and save the info into instance property arrays
	Quit:tColCount<1 $$$ERROR($$$EnsErrNoSQLColumns,..QueryStatement)
	Set (i%ColName,i%ColID)=tColCount
	Set tIsJDBC = ..%Connection.%Extends("EnsLib.SQL.CommonJ")
	#; Set maximum string length for determining LOB detection for VarChar
	Try {
		#dim tMaxVarCharLengthAsString = pAdapter.MaxVarCharLengthAsString
	} Catch {
		#; If the adapter does not support this property then use default in %isLOB
		Kill tMaxVarCharLengthAsString
	}
	For tI=1:1:i%ColName { Set tColInfo=$LG(tCols,tI+1)
		Set tName=$LG(tColInfo,1)  Set:""=tName tName="xCol_"_tI
		Set tBase=$ZCVT(tName,"L")
		If 0=$D(i%ColID(tBase)) {
			Set i%ColID(tBase)=tI
			Set i%ColName(tI)=tName
		} Else {
			Set tNI=2, tNameI=tBase_"_2"
			For { Quit:0=$D(i%ColID(tNameI))  Set tNI=tNI+1,tNameI=tBase_"_"_tNI }
			Set i%ColID(tBase_"_"_tNI)=tI
			Set i%ColName(tI)=tName_"_"_tNI
		}
		Set tSize=$LG(tColInfo,3)  Set:""=tSize tSize=50
		/* If JDBC and Precision is 0 then set tSize to DisplaySize */
		Set:((tSize=0)&&tIsJDBC) tSize = $LG(tColInfo,7)
		Set i%ColSize(tI)=tSize
		Set tType=$LG(tColInfo,6)  Set:""=tType tType="unknown"
		Set i%ColType(tI)=tType
		Set tIType=$LG(tColInfo,2)
		Set i%ColType(tI,"int")=tIType
		Set tUType=$ZCVT(tType,"U")
		#; tMaxVarCharLengthAsString might not exist so pass by reference
		Set:..%isLOB(tUType,tIType,tSize,tIsJDBC,.tMaxVarCharLengthAsString) i%ColType(tI,"LOB")=1
		Set:..%isBin(tUType,tIType) i%ColType(tI,"bin")=1
	}
	Set i%MaxString=$$$MaxLocalLength
	Quit tSC
Trap
	Set $ZT="",tZE=$ZE  Quit $$$SystemError
}

/// Advance the result set cursor to the next row and cache the row data. Returns 0 if the cursor is at the end of the result set.
Method Next(ByRef pSC As %Status) As %Integer
{
	Quit:'..SkipNext(.pSC) 0

	Set nCols=..ColCount  For col=1:1:nCols {
		#; first kill raw stream storage
		Kill:'$G(..Data(col,"got"))&&$D(..Data(col,"ref"),ref) @ref
		Kill i%Data(col)  Set i%Data(col)="", tBin=$G(..ColType(col,"bin")), tLOB=$G(..ColType(col,"LOB")), tSubsc=0, col1=col_$S(tLOB:".",1:"")
		For {
			If ..%Adapter.IsUnicodeDLL&&'tBin { Set pSC=..%Connection.GetDataW(..%HS,.col1,$$$SqlCWChar,.tValue) }
			Else { Set pSC=..%Connection.GetData(..%HS,.col1,$S(tBin:$$$SqlCBinary,1:$$$SqlCChar),.tValue) }
#If ..#LOBSUCCESSWITHINFO=0
			If ""=tValue&&(-1=..%Connection.sqlcode) Set pSC=$$$OK Quit ; old ODBC driver just returns error for no more data; never returns non-error sqlcode
#EndIf
			Quit:..%Connection.sqlcode=100||$$$ISERR(pSC)
			If 'tSubsc {
				Set tRoom=..MaxString-$L(..Data(col))
				If tRoom>=$L(tValue) {
					Set i%Data(col)=..Data(col)_tValue
				} Else { ; Move the data to a stream global
					Set id=$I(^CacheStream), ref=$Name(^CacheStream(id)), tLen=$L(i%Data(col)), @ref@(1)=i%Data(col), i%Data(col)=$E(i%Data(col),1,50)_"..."
					Set i%Data(col,"ref")=ref, tSubsc=2, @ref@(0)=tLen, tChunk=tValue
				}
			} Else { ; Keep filling the stream global, but to avoid excessive journaling only write whole chunks
				Set tRoom=..MaxString-$L(tChunk)
				If tRoom>=$L(tValue) {
					Set tChunk=tChunk_tValue
				} Else {
					Set @ref@(tSubsc)=tChunk, @ref@(0)=@ref@(0)+$L(tChunk)
					Set tSubsc=tSubsc+1, tChunk=tValue
				}
			}			
			Quit:..%Connection.sqlcode<..#LOBSUCCESSWITHINFO
		}
		Quit:$$$ISERR(pSC)
		Set:tSubsc @ref@(tSubsc)=tChunk, @ref@(0)=@ref@(0)+$L(tChunk)
	} 
	If ..%Connection.sqlcode=100 Set pSC=$$$OK,..%Connection.sqlcode=0
	Quit:$$$ISOK(pSC) 1
	Set tNetErr=..%Adapter.isNetErr($$$StatusText(pSC))
	Set:""'=..%HS pSC=..%Adapter.addErrorList(pSC,..%HS,.tNetErr)
	Do:tNetErr ..%Adapter.Disconnect()
	Quit 0
}

Method %Next(ByRef pSC As %Status) As %Integer [ CodeMode = call ]
{
..Next(.pSC)
}

/// Advance the result set cursor to the next row. Returns 0 if the cursor is at the end of the result set
Method SkipNext(ByRef pSC As %Status) As %Boolean
{
	Set pSC=..%Connection.Fetch(..%HS)  If 100=..%Connection.sqlcode Set pSC=$$$OK  Quit 0
	Quit:$$$ISOK(pSC) 1
	Set tNetErr=..%Adapter.isNetErr($$$StatusText(pSC))
	Set:""'=..%HS pSC=..%Adapter.addErrorList(pSC,..%HS,.tNetErr)
	Do:tNetErr ..%Adapter.Disconnect()
	Quit 0
}

ClassMethod %isLOB(pUType As %String, pIType As %Integer, pSize As %String, pIsJDBC As %Boolean = 0, ByRef pMaxVarCharLengthAsString As %Integer = 32767) As %Boolean [ Internal ]
{
	Set:+pUType=pUType&&$Case(pIType,"":1,$$$SqlUnknownType:1,:0) pIType=+pUType
	Set tIs=$Case(pIType
	,$$$SqlLongVarBinary:1
	,$$$SqlLongVarchar:1
	,$$$SqlWLongVarchar:1
	,$$$SqlJLongNVarchar:1
	,$$$SqlJBLOB:1
	,$$$SqlJCLOB:1
	,$$$SqlJNCLOB:1
	,$$$SqlJSQLXML:1
	,$$$SqlDB2BLOB:1
	,$$$SqlDB2CLOB:1
	,$$$SqlDB2DBCLOB:1
	,$$$SqlDB2XML:1

	,$$$SqlBinary:"+"
	,$$$SqlVarBinary:"+"
	,$$$SqlChar:"+"
	,$$$SqlVarchar:"+"
	,$$$SqlWChar:"+"
	,$$$SqlWVarchar:"+"

	,$$$SqlJDataLink:""
	,:$S(+pIType=pIType&&(pIType>-40)&&(pIType<100):0, 1:"")) ; all other ordinary types are not LOBs
	If ((pMaxVarCharLengthAsString = -1) || (pMaxVarCharLengthAsString > $$$MaxStringLength)) {
		Set pMaxVarCharLengthAsString = $$$MaxStringLength
	}
	Quit:"+"=tIs (+pSize=pSize&&((pSize<=0)||(pSize>pMaxVarCharLengthAsString))&&('pIsJDBC||(pSize '= 0))) ; declarable-size types
	Quit:""'=tIs tIs ; we already know. Otherwise test the text type
	Quit (
	 ((pUType["LONG")
	  && (("LONG"=pUType)||(pUType["LONGBIN")||(pUType["LONGVAR")||(pUType["LONGCH")||(pUType["LONGNVAR")||(pUType["LONGNCH")||(pUType["LONG VARGRAPHIC")))
	 || ("BLOB"=pUType)||("RAW"=pUType)||("IMAGE"=pUType)
	 || ("CLOB"=pUType)||("NCLOB"=pUType)||("DBCLOB"=pUType)
	 || ("TEXT"=pUType)||("NTEXT"=pUType)||("XML"=pUType)
	 || (pUType["(MAX)")
	 || (((pUType["BIN")||(pUType["CHAR")||(pUType["GRAPHIC"))
	  && (+pSize=pSize&&((pSize<=0)||(pSize>pMaxVarCharLengthAsString)))&&('pIsJDBC||(pSize '= 0)))
	 )
}

ClassMethod %isBin(pUType As %String, pIType As %Integer) As %Boolean [ CodeMode = expression, Internal ]
{
$Case($S(+pUType=pUType&&$Case(pIType,"":1,$$$SqlUnknownType:1,:0):+pUType,1:pIType)
	,$$$SqlLongVarBinary:1
	,$$$SqlJBLOB:1
	,$$$SqlBinary:1
	,$$$SqlVarBinary:1
	,$$$SqlDB2BLOB:1
	,:$S(+pIType=pIType&&(pIType>-40)&&(pIType<100):0, 1:((pUType["BIN")||("BLOB"=pUType)||("RAW"=pUType)||("IMAGE"=pUType))))
}

/// Returns the number of columns in the result set
Method GetColumnCount() As %Integer [ CodeMode = expression ]
{
..ColCount
}

/// Returns the name of column <var>pColumn</var> in the result set.
Method GetColumnName(pColumn As %Integer = 0) As %String [ CodeMode = expression ]
{
$Get(..ColName(pColumn))
}

Method GetColumnID(pColName As %String) As %Integer [ CodeMode = expression ]
{
$G(..ColID($ZCVT(pColName,"L")),0)
}

/// Returns the type name of column 'pColumn' in the result set.
Method GetColumnType(pColumn As %Integer = 0) As %String [ CodeMode = expression ]
{
$Get(..ColType(pColumn))
}

/// Returns the SQLtype integer of column 'pColumn' in the result set.
Method GetColumnSQLType(pColumn As %Integer = 0) As %Integer [ CodeMode = expression ]
{
$Get(..ColType(pColumn,"int"))
}

/// Returns whether column 'pColumn' is a LOB (Stream) column.
Method GetColumnIsLOB(pColumn As %Integer = 0) As %Boolean [ CodeMode = expression ]
{
$Get(..ColType(pColumn,"LOB"),0)
}

/// Returns whether column 'pColumn' contains binary data.
Method GetColumnIsBinary(pColumn As %Integer = 0) As %Boolean [ CodeMode = expression ]
{
$Get(..ColType(pColumn,"bin"),0)
}

/// Returns the size (precision) of column 'pColumn' in the result set.
Method GetColumnSize(pColumn As %Integer = 0) [ CodeMode = expression ]
{
$Get(..ColSize(pColumn))
}

/// Returns the value of the column with the name 'pColName' in the current row of the result set
/// Note: if the data exceeds the maximum string length then the return value will be the first 50 characters plus "..." and you should call GetStream() to get the full value.
Method Get(pColName As %String) As %String [ CodeMode = expression ]
{
$Get(..Data($Get(..ColID($ZCVT(pColName,"L")),0)))
}

/// alias for Get in new result set interface
Method %Get(pColName As %String) As %String [ CodeMode = expression ]
{
..Get(.pColName)
}

/// Returns true if the named column in the current row contains stream data. In this case the complete value for the field can only be retrieved using the
/// GetStream() or GetDataStream() method. Otherwise the field contains simple string data that can be retrieved completely using the Get() or GetData() method.
Method HasStream(pColName As %String) As %Boolean [ CodeMode = expression ]
{
..HasDataStream($Get(..ColID($ZCVT(pColName,"L")),0))
}

/// Returns as a Stream the full value of the column with the name 'pColName' in the current row of the result set.
/// If you pass a stream object in <var>pStream</var>, the data will be appended to that stream;
/// otherwise the data will be returned in a new %Stream.GlobalCharacter stream object.
/// Note that if this method creates a Stream object for you, the Stream data is already on disk
/// and you are responsible for calling stream.%Delete(stream.%Oid()) to delete the persistent storage for the new stream object
Method GetStream(pColName As %String, ByRef pStream As %Stream.Object = {$$$NULLOREF}) As %Stream.Object [ CodeMode = expression ]
{
..GetDataStream($Get(..ColID($ZCVT(pColName,"L")),0),.pStream)
}

/// Deprecated - use <method>Get</method> method
Method GetDataByName(pColName As %String) As %String [ CodeMode = expression ]
{
..Get(.pColName)
}

/// Returns the value of column <var>pColumn</var> in the current row of the result set.
/// Note: if the data exceeds the maximum string length then the return value will be the first 50 characters plus "..." and you should call GetStream() to get the full value.<p/>
Method GetData(pColumn As %Integer) As %String [ CodeMode = expression ]
{
$Get(..Data(pColumn))
}

/// alias for GetData in new result set interface
Method %GetData(pColumn As %Integer) As %String [ CodeMode = expression ]
{
..GetData(.pColumn)
}

/// Returns true if the given field in the current row contains stream data. In this case the complete value for the field can only be retrieved using the
/// GetStream() or GetDataStream() method. Otherwise the field contains simple string data that can be retrieved completely using the Get() or GetData() method.
Method HasDataStream(pColumn As %Integer) As %Boolean [ CodeMode = expression ]
{
""'=$G(..Data(pColumn,"ref"))
}

/// Returns as a Stream the full value of column <var>pColumn</var> in the current row of the result set.
/// If you pass a stream object in <var>pStream</var>, the data will be appended to that stream;
/// otherwise the data will be returned in a new %Stream.GlobalCharacter stream object.<p/>
/// Note that if this method creates a Stream object for you, the Stream data is already on disk
/// and you are responsible for calling stream.%Delete(stream.%Oid()) to delete the persistent storage for the new stream object
Method GetDataStream(pColumn As %Integer, ByRef pStream As %Stream.Object = {$$$NULLOREF}) As %Stream.Object
{
	Set tRef=$G(..Data(pColumn,"ref"))
	If ""'=tRef {
		Set tSID=$P(tRef,"(",2), tSID=$E(tSID,1,*-1)
		Set tGCS=$S($G(..ColType(pColumn,"bin")):##class(%Stream.GlobalBinary).%OpenId(tSID), 1:##class(%Stream.GlobalCharacter).%OpenId(tSID))
		If $IsObject(pStream) { Do pStream.CopyFrom(tGCS), pStream.Rewind() }
		Else { Set pStream=tGCS  Set i%Data(pColumn,"got")=1 }
	} Else {
		Set:'$IsObject(pStream) pStream=$S($G(..ColType(pColumn,"bin")):##class(%Stream.GlobalBinary).%New(), 1:##class(%Stream.GlobalCharacter).%New())
		Do pStream.Write($Get(..Data(pColumn))), pStream.Rewind()
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

Method %OnClose() As %Status [ Private ]
{
	#dim tSC=$$$OK

	#; first kill raw stream storage
	#dim nCols=..ColCount
	#dim c,ref

	For c=1:1:nCols { Kill:'$G(..Data(c,"got"))&&$D(..Data(c,"ref"),ref) @ref }

	#; Check for the adapter this instance points to being valid - ie not already/in process of being destructed
	If ..%HS'="" && ..%Final {
		If ($IsObject(..%Connection)=1) {
			Set tSC=..%Connection.DropStatement(..%HS)
			If $$$ISERR(tSC) && ($IsObject(..%Adapter)=1){
				If ##class(EnsLib.SQL.Common).isNetErr($$$StatusText(tSC)) {
					Do ..%Adapter.Disconnect()
					Set:(($IsObject(..%Adapter.BusinessHost)=1) && (..%Adapter.BusinessHost.%Extends("Ens.BusinessOperation"))) ..%Adapter.BusinessHost.Retry=1
				}
			}
		}
	}
	Do:..%Final&&($IsObject(..%Adapter)=1)&&'..%Adapter.StayConnected ..%Adapter.Disconnect()
	Quit tSC
}

/// Deprecated - use GetSnapshot()
Method ConvertToListOfDataTypes(Output pList As %ListOfDataTypes, ByRef pMaxRows As %Integer = 250) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Set pList = ##class(%ListOfDataTypes).%New()
		$$$ASSERT($IsObject(pList))
		
		Set iRow=0
		Do {
			If ..Next()=0 Quit
			Do pList.Insert(..GetRowList())
			Set iRow=iRow+1
		} while (iRow<pMaxRows)
		
		Set pMaxRows=iRow
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/* Inherited from %IResultSet:
 /// Copy all rows from the current position to the end of the cursor into a temporary
 /// global. Fetch <var>rowCount</var> rows into a temporary global. If the <var>rowCount</var> is -1 then all rows are fetched
 %CreateSnapshot(.storageOffset,.lastRow,.pRuntimeMode)
*/
/// Populate an EnsLib.SQL.Snapshot object. If you pass one in, it will be populated using the values in its
/// FirstRow and MaxRowsToGet properties. Otherwise, GetSnapshot will construct a new one and use its default
/// values for FirstRow and MaxRowsToGet.
Method GetSnapshot(ByRef pSnap As EnsLib.SQL.Snapshot, pFetchAll As %Boolean = 0) As %Status
{
	Set $ZT="Trap", tSC=$$$OK, tNetDone=0
	Do {
		If '$$$IsdefObject(pSnap) { Set pSnap = ##class(EnsLib.SQL.Snapshot).%New()  $$$ASSERT($IsObject(pSnap)) }
		Else {
			$$$ASSERT(pSnap.%IsA("EnsLib.SQL.Snapshot"))
			Do pSnap.Clean()
		}
		Set tMaxRows = pSnap.MaxRowsToGet, tFirstRow = pSnap.FirstRow
		
		Set tGblRef = pSnap.%GblRef
		Merge @tGblRef@("ColNames") = ..ColName
		Merge @tGblRef@("ColIDs") = ..ColID
		Merge @tGblRef@("ColTypes") = ..ColType
		Merge @tGblRef@("ColSizes") = ..ColSize
		Do pSnap.GenerateIResultSetMetadata()

		#; Fast SkipNext() loop
		If tFirstRow>1 {
			For i=1:1:tFirstRow-1 {
				Set tSC=..%Connection.Fetch(..%HS)  If 100=..%Connection.sqlcode Set tSC=$$$OK Quit
				Quit:$$$ISERR(tSC)
			}
			Quit:100=..%Connection.sqlcode||$$$ISERR(tSC) 
		}
		#; Next()/GetData() loop
		For i=1:1 { Quit:tMaxRows>=0&&(i>tMaxRows)
			Set tNetDone='..Next(.tSC)  Quit:tNetDone
			Merge @tGblRef@(i)=..Data
			Set nCols=..ColCount  For c=1:1:nCols { Set:$D(i%Data(c,"ref")) i%Data(c,"got")=1 }
			Set @tGblRef = $G(@tGblRef)+1
		} Quit:tNetDone

		#; Fast SkipNext() loop for remainder (in case of multi-RS SP calls)
		If tMaxRows>=0&&pFetchAll {
			For {
				Set tSC=..%Connection.Fetch(..%HS)  If 100=..%Connection.sqlcode Set tSC=$$$OK Quit
				Quit:$$$ISERR(tSC)
			}
		}
	} While 0
Exit
	If 'tNetDone&&$$$ISERR(tSC) {
		Set tNetErr=..%Adapter.isNetErr($$$StatusText(tSC))
		Set:..%HS'="" tSC=..%Adapter.addErrorList(tSC,..%HS,.tNetErr)
		Do:tNetErr ..%Adapter.Disconnect()
	}
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Closes the current result set cursor.
Method Close() As %Status
{
	#; first kill raw stream storage
	Set nCols=..ColCount  For c=1:1:nCols { Kill:'$G(..Data(c,"got"))&&$D(..Data(c,"ref"),ref) @ref }
	Set tSC=$$$OK
	If ..%HS'="" {
		Set tSC=..%Connection.DropStatement(..%HS)
		If $$$ISERR(tSC) {
			Set tNetErr=##class(EnsLib.SQL.Common).isNetErr($$$StatusText(tSC))
			If tNetErr Set i%%HS=""  If $IsObject(..%Adapter) Do ..%Adapter.Disconnect()  Set:..%Adapter.BusinessHost.%Extends("Ens.BusinessOperation") ..%Adapter.BusinessHost.Retry=1
		} Else {
			Set i%%HS=""
		}
	}
	Quit tSC
}

/// alias for new result set interface
Method %CloseCursor() As %Status [ CodeMode = call ]
{
..Close()
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

}
