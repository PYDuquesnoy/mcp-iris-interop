/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Contains one row for every column in every table and view, and a row for each parameter in a stored procedure.
Class %TSQL.sys.constraints Extends %Persistent [ SqlRowIdPrivate, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

/// Name of the schema the column resides in
Property schema As %String(MAXLEN = 128) [ SqlColumnNumber = 9 ];

/// Parent Object name
/// Object name of the parent_obj.
Property parentobjname As %String(MAXLEN = 128) [ SqlColumnNumber = 10, SqlFieldName = parent_obj_name ];

/// Object ID of the constraint
Property constrid As %Integer [ SqlColumnNumber = 3 ];

/// Column number in the table
Property colid As %TinyInt [ SqlColumnNumber = 2 ];

/// ID of the table on which the constraint is declared
Property tableid As %Integer [ SqlColumnNumber = 4 ];

/// The type of constraint:
///  0x0040 = a referential constraint
///  0x0080 = a check constraint
Property status As %Integer [ SqlColumnNumber = 6 ];

Index IDKEYIndex On (tableid, constrid) [ IdKey, Unique ];

Storage SQLStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Data name="colid">
<Piece>3</Piece>
</Data>
<Data name="parent_obj_name">
<Piece>2</Piece>
</Data>
<Data name="schema">
<Piece>1</Piece>
</Data>
<Data name="status">
<Piece>4</Piece>
</Data>
<Global>^oddTSQL</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>{tableid}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"con"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{constrid}</Expression>
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
<Expression>{tableid}</Expression>
</Subscript>
<Subscript name="6">
<Expression>"con"</Expression>
</Subscript>
<Subscript name="7">
<Expression>{constrid}</Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<StreamLocation>^oddTSQLC</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
