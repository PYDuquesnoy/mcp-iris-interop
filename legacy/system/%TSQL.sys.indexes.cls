/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// sysindexes contains one row for each clustered index (IDKey index), 
/// one row for each nonclustered index (all other indexes), 
/// one row for each table that has no clustered index, 
/// and one row for each table that contains text or image columns.
/// 
Class %TSQL.sys.indexes Extends %Persistent [ SqlRowIdPrivate, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

/// Name of the schema the column resides in
Property schema As %String(MAXLEN = 128) [ SqlColumnNumber = 10 ];

/// Parent Object name
/// Object name of the parent_obj.
Property parentobjname As %String(MAXLEN = 128) [ SqlColumnNumber = 11, SqlFieldName = parent_obj_name ];

/// Number of keys for a clustered index on an allpages-locked table; number of keys, plus 1 for all other indexes
Property keycnt As %SmallInt [ SqlColumnNumber = 9 ];

/// ID of a table, or ID of table to which index belongs
Property id As %Integer [ SqlColumnNumber = 3 ];

/// Index or table name
Property name As %String(MAXLEN = 128) [ SqlColumnNumber = 2 ];

/// 0 if a table; 1 if a clustered index on an allpages-locked table; 
/// >1 if a nonclustered index or a clustered index on a data-only-locked table; 
/// 255 if text, image or Java off-row structure (LOB structure)
Property indid As %SmallInt [ SqlColumnNumber = 4 ];

/// Page number for the object allocation map of a table
Property doampg As %Integer [ SqlColumnNumber = 5 ];

/// Page number for the allocation map of an index or (LOB structure)
Property ioampg As %Integer [ SqlColumnNumber = 6 ];

/// Internal system status information
/// 	 Decimal	Hex	Status
/// 	   1		0x1	Index supports foreign key constraint
/// 	   2		0x2	Index supports primary key/unique declarative constraint
/// 	   4		0x4	Index includes an IDENTITY column
/// 	   8		0x8	Constraint name not specified
/// 	   16		0x10	Large I/Os (prefetch) not enabled for table, index, or text chain
/// 	   32		0x20	MRU cache strategy not enabled for table, index, or text chain
/// 	   64		0x40	Ascending inserts turned on for the table
/// 	   256		0x0100	Index is presorted and does not need to be copied to new extents
/// 	   512		0x0200	Table is a data-only-locked table with a clustered index
/// 	   8192		0x2000	Index on a data-only-locked table is suspect
Property status As %SmallInt [ SqlColumnNumber = 8 ];

/// Internal system status information
/// 	 Decimal	Hex	Status
///  	   1		0x1	Abort current command or trigger if attempt to insert duplicate key
///  	   2		0x2	Unique index
///  	   4		0x4	Abort current command or trigger if attempt to insert duplicate row; always 0 for data-only-locked tables
///  	   16		0x10	Clustered index
///  	   64		0x40	Index allows duplicate rows, if an allpages-locked table; always 0 for data-only-locked tables
///  	   128		0x80	Sorted object; not set for tables without clustered indexes or for text objects
///  	   512		0x200	sorted data option used in create index statement
///  	   2048		0x800	Index on primary key
///  	   32768	0x8000	Suspect index; index was created under another sort order
Property status2 As %Integer [ SqlColumnNumber = 7 ];

/// List of fields in the index.  NULL for indid = 0 and 255
Property indexfields As list Of %String(MAXLEN = 128) [ SqlColumnNumber = 12, SqlFieldName = index_fields ];

Index IDKEYIndex On (id, indid) [ IdKey, Unique ];

Storage SQLStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Data name="doampg">
<Piece>4</Piece>
</Data>
<Data name="index_fields">
<Piece>9</Piece>
</Data>
<Data name="ioampg">
<Piece>5</Piece>
</Data>
<Data name="keycnt">
<Piece>8</Piece>
</Data>
<Data name="name">
<Piece>3</Piece>
</Data>
<Data name="parent_obj_name">
<Piece>2</Piece>
</Data>
<Data name="schema">
<Piece>1</Piece>
</Data>
<Data name="status">
<Piece>7</Piece>
</Data>
<Data name="status2">
<Piece>6</Piece>
</Data>
<Global>^oddTSQL</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>{id}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"idx"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{indid}</Expression>
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
<Expression>"idx"</Expression>
</Subscript>
<Subscript name="7">
<Expression>{indid}</Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<StreamLocation>^oddTSQLC</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
