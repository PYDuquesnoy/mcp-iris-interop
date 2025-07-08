/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Contains one row for every column in every table and view, and a row for each parameter in a stored procedure.
Class %XSQL.Catalog.Informix.syscolumns Extends %Persistent [ SqlRowIdPrivate, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

/// Name of the column
Property colname As %String(MAXLEN = 128) [ SqlColumnNumber = 2 ];

/// Object ID of the table to which this column belongs
Property tabid As %Integer [ SqlColumnNumber = 3 ];

/// Column number sequentially assigned by the system (from left to right within each table)
Property colno As %SmallInt [ SqlColumnNumber = 4, SqlComputeCode = {Set {colno}=$Listget($Get(^oddEXTR({extentname},"b",{colname},91)),1)}, SqlComputed, Transient ];

/// Code (identifier) for column data type:
/// 	0 = CHAR	14 = INTERVAL
/// 	1 = SMALLINT	15 = NCHAR
/// 	2 = INTEGER	16 = NVARCHAR
/// 	3 = FLOAT	17 = INT8
/// 	4 = SMALLFLOAT	18 = SERIAL8*
/// 	5 = DECIMAL	19 = SET
/// 	6 = SERIAL*	20 = MULTISET
/// 	7 = DATE	21 = LIST
/// 	8 = MONEY	22 = ROW
/// 	9 = NULL	23 = COLLECTION
/// 	10 = DATETIME	24 = ROWREF
/// 	11 = BYTE	40 = Variable-length opaque type
/// 	12 = TEXT	41 = Fixed-length opaque type
/// 	13 = VARCHAR	4118 = Named row type 
Property coltype As %SmallInt [ SqlColumnNumber = 5, SqlComputeCode = {New data Set data=$ListGet($Get(^oddEXTR({extentname},"b",{colname},91)),9)
Set {coltype}=$Case(data,"TINYINT":1,"SMALLINT":1,"BIGINT":5,"NUMERIC":5,"INTEGER":2,"DOUBLE":3,"DATE":7,"TIME":10,"TIMESTAMP":10,:13)}, SqlComputed, Transient ];

/// Maximum column length (in bytes)
Property maxlen As %Integer [ SqlColumnNumber = 10 ];

/// Name of the schema the column resides in
Property schema As %String(MAXLEN = 128) [ Private, SqlColumnNumber = 12 ];

/// Internal Column id value
Property colid As %Integer [ Private, SqlColumnNumber = 13 ];

/// Parent Object name
/// Object name of the parent_obj.
Property parentobjname As %String(MAXLEN = 128) [ Private, SqlColumnNumber = 14, SqlFieldName = parent_obj_name ];

/// Name of the extent that projected this table
Property extentname As %String(MAXLEN = 128) [ Internal, Private, SqlColumnNumber = 15, SqlComputeCode = { Set {extentname}=$ListGet($Get(^rINDEXSQL("rv",$zcvt($Listget($Get(^oddTSQL({tabid}))),"U"),$zcvt($Listget($Get(^oddTSQL({tabid})),2),"U"))),2)}, SqlComputed, Transient ];

Index IDKEYIndex On (tabid, colid) [ IdKey, Unique ];

Storage SQLStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Data name="colname">
<Piece>6</Piece>
</Data>
<Data name="colno">
<Piece>5</Piece>
</Data>
<Data name="maxlen">
<Piece>3</Piece>
</Data>
<Data name="parent_obj_name">
<Piece>2</Piece>
</Data>
<Data name="schema">
<Piece>1</Piece>
</Data>
<Global>^oddTSQL</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>{tabid}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"col"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{colid}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<SQLMap name="SchemaNameIndex">
<Global>^oddSQL</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>{schema}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{parent_obj_name}</Expression>
</Subscript>
<Subscript name="3">
<Expression>"tsql"</Expression>
</Subscript>
<Subscript name="4">
<Expression>1</Expression>
</Subscript>
<Subscript name="5">
<Expression>{tabid}</Expression>
</Subscript>
<Subscript name="6">
<Expression>"col"</Expression>
</Subscript>
<Subscript name="7">
<Expression>{colid}</Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<StreamLocation>^oddTSQLC</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
