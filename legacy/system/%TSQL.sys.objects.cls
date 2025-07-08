/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Contains one row for every column in every table and view, and a row for each parameter in a stored procedure. This table is in each database.
Class %TSQL.sys.objects Extends %Persistent [ SqlRowIdPrivate, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

/// Name of the schema the object resides in
Property schema As %String(MAXLEN = 128) [ SqlColumnNumber = 10 ];

/// Object name
Property name As %String(MAXLEN = 128) [ SqlColumnNumber = 2 ];

/// Parent Object name
/// Object name of the parent_obj.  If parent_obj = 0, parent_obj_name = name
Property parentobjname As %String(MAXLEN = 128) [ SqlColumnNumber = 11, SqlFieldName = parent_obj_name ];

/// Object id
Property id As %Integer [ SqlColumnNumber = 3 ];

/// Object identification number of parent object (for example, the table ID if a trigger or constraint).
Property parentobj As %Integer [ SqlColumnNumber = 5, SqlFieldName = parent_obj ];

/// Object type. Can be one of these values:
/// D = default
/// K = PRIMARY KEY or UNIQUE constraint 
/// L = log
/// P = procedure
/// PR = prepare objects (created by Dynamic SQL)
/// R = rule
/// RI = referential constraint
/// S = system table
/// TR = trigger
/// U = user table
/// V = view
/// XP = extended stored procedure
/// 
Property type As %String(MAXLEN = 2) [ SqlColumnNumber = 6 ];

/// Stored procedure ID of a delete trigger if the entry is a table. Table ID if the entry is a trigger.
Property deltrig As %Integer [ SqlColumnNumber = 7 ];

/// Stored procedure ID of a table's insert trigger if the entry is a table
Property instrig As %Integer [ SqlColumnNumber = 8 ];

/// Stored procedure ID of a table's update trigger if the entry is a table
Property updtrig As %Integer [ SqlColumnNumber = 9 ];

Index IDKEYIndex On id [ IdKey, PrimaryKey, Unique ];

Storage SQLStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Data name="deltrig">
<Piece>6</Piece>
</Data>
<Data name="instrig">
<Piece>7</Piece>
</Data>
<Data name="name">
<Piece>5</Piece>
</Data>
<Data name="parent_obj">
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
<Data name="updtrig">
<Piece>8</Piece>
</Data>
<Global>^oddTSQL</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>{id}</Expression>
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
<Type>index</Type>
</SQLMap>
<StreamLocation>^oddTSQLC</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
