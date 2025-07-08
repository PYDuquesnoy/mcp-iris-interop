/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Contains one row for every column in every table and view, and a row for each parameter in a stored procedure.
Class %TSQL.sys.columns Extends %Persistent [ SqlRowIdPrivate, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

/// Name of the schema the column resides in
Property schema As %String(MAXLEN = 128) [ SqlColumnNumber = 21 ];

/// Parent Object name
/// Object name of the parent_obj.
Property parentobjname As %String(MAXLEN = 128) [ SqlColumnNumber = 22, SqlFieldName = parent_obj_name ];

/// Name of the column or procedure parameter.
Property name As %String(MAXLEN = 128) [ SqlColumnNumber = 12 ];

/// Object ID of the table to which this column belongs, or the ID of the stored procedure with which this parameter is associated.
Property id As %Integer [ SqlColumnNumber = 2 ];

/// Maximum physical storage length from systypes.
Property length As %Integer [ SqlColumnNumber = 7 ];

/// Column or parameter ID.
Property colid As %SmallInt [ SqlColumnNumber = 4 ];

/// ID of the default for this column.
/// ID of the procedure that generates default value for this column
Property cdefault As %Integer [ SqlColumnNumber = 10 ];

/// Subprocedure number when the procedure is grouped (0 for nonprocedure entries).
Property number As %SmallInt [ InitialExpression = 0, SqlColumnNumber = 3 ];

/// Bitmap used to describe a property of the column or the parameter: 
/// Bits 0-2 (values 1, 2, and 4) indicate bit positioning if the column uses the bit datatype. If the column uses the text/image datatype, bits 0 and 1 indicate replication status as follows:
///   01 = always replicate
///   10 = replicate only if changed
///   00 = never replicate
/// Bit 3 (value 8) indicates whether NULL values are legal in this column.
/// Bit 4 (value 16) indicates whether more than one check constraint exists for the column.
/// Bits 5 and 6 are used internally.
/// Bit 7 (value 128) indicates an identity column.
/// Bit 8 is unused.
/// 
Property status As %SmallInt [ SqlColumnNumber = 5 ];

/// ID of user-defined data type from systypes.
Property usertype As %Library.String(MAXLEN = 256) [ SqlColumnNumber = 9 ];

/// Level of precision for this column.  Number of significant digits.
Property prec As %SmallInt [ SqlColumnNumber = 14 ];

/// Scale for this column.  Number of digits to the right of the decimal point
Property scale As %Integer [ SqlColumnNumber = 15 ];

Index IDKEYIndex On (id, colid) [ IdKey, Unique ];

Storage SQLStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Data name="cdefault">
<Piece>4</Piece>
</Data>
<Data name="length">
<Piece>3</Piece>
</Data>
<Data name="name">
<Piece>6</Piece>
</Data>
<Data name="number">
<Piece>5</Piece>
</Data>
<Data name="parent_obj_name">
<Piece>2</Piece>
</Data>
<Data name="prec">
<Piece>9</Piece>
</Data>
<Data name="scale">
<Piece>10</Piece>
</Data>
<Data name="schema">
<Piece>1</Piece>
</Data>
<Data name="status">
<Piece>7</Piece>
</Data>
<Data name="usertype">
<Piece>8</Piece>
</Data>
<Global>^oddTSQL</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>{id}</Expression>
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
<Expression>{id}</Expression>
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
