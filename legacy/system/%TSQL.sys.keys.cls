/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// contains one row for each primary, foreign, or common key.
Class %TSQL.sys.keys Extends %Persistent [ SqlRowIdPrivate, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

/// Name of the schema the column resides in
Property schema As %String(MAXLEN = 128) [ SqlColumnNumber = 13 ];

/// Parent Object name
/// Object name of the parent_obj.
Property parentobjname As %String(MAXLEN = 128) [ SqlColumnNumber = 14, SqlFieldName = parent_obj_name ];

/// Number of non-NULL keys
Property keycnt As %Integer [ SqlColumnNumber = 4 ];

/// Column ID
Property key1 As %Integer [ SqlColumnNumber = 5 ];

/// Column ID
Property key2 As %Integer [ SqlColumnNumber = 6 ];

/// Column ID
Property key3 As %Integer [ SqlColumnNumber = 7 ];

/// Column ID
Property key4 As %Integer [ SqlColumnNumber = 8 ];

/// Column ID
Property key5 As %Integer [ SqlColumnNumber = 9 ];

/// Column ID
Property key6 As %Integer [ SqlColumnNumber = 10 ];

/// Column ID
Property key7 As %Integer [ SqlColumnNumber = 11 ];

/// Column ID
Property key8 As %Integer [ SqlColumnNumber = 12 ];

/// Object ID of the table this key belongs to
Property id As %Integer [ SqlColumnNumber = 2 ];

/// Object ID of the constraint this key belongs to
Property constrid As %Integer [ SqlColumnNumber = 15, SqlFieldName = constr_id ];

/// Record type
Property type As %SmallInt [ SqlColumnNumber = 3 ];

Index IDKEYIndex On (id, constrid) [ IdKey, Unique ];

Storage SQLStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Data name="key1">
<Piece>5</Piece>
</Data>
<Data name="key2">
<Piece>6</Piece>
</Data>
<Data name="key3">
<Piece>7</Piece>
</Data>
<Data name="key4">
<Piece>8</Piece>
</Data>
<Data name="key5">
<Piece>9</Piece>
</Data>
<Data name="key6">
<Piece>10</Piece>
</Data>
<Data name="key7">
<Piece>11</Piece>
</Data>
<Data name="key8">
<Piece>12</Piece>
</Data>
<Data name="keycnt">
<Piece>4</Piece>
</Data>
<Data name="parent_obj_name">
<Piece>2</Piece>
</Data>
<Data name="schema">
<Piece>1</Piece>
</Data>
<Data name="type">
<Piece>3</Piece>
</Data>
<Global>^oddTSQL</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>{id}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"key"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{constr_id}</Expression>
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
<Expression>{id}</Expression>
</Subscript>
<Subscript name="6">
<Expression>"key"</Expression>
</Subscript>
<Subscript name="7">
<Expression>{constr_id}</Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<StreamLocation>^oddTSQLC</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
