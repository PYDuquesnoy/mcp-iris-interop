/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Returns one row for each FOREIGN KEY table constraint in the current namespace for tables that can be accessed by the current user in the current namespace.
/// The REFERENTIAL_CONSTRAINTS table has one row for each row in the TABLE_CONSTRAINTS table that has a CONSTRAINT_TYPE value of "FOREIGN KEY".
Class INFORMATION.SCHEMA.REFERENTIALCONSTRAINTS Extends %Library.Persistent [ ClassType = persistent, Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = REFERENTIAL_CONSTRAINTS, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

Index IDKeyIndex On (SchemaExact, TableExact, ConstraintExact) [ IdKey, Internal, Unique ];

Index PKeyIndex On (CONSTRAINTSCHEMA, CONSTRAINTTABLENAME, CONSTRAINTNAME) [ PrimaryKey ];

Property SchemaExact As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 20 ];

Property TableExact As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 21 ];

Property ConstraintExact As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 22 ];

/// Is the table a system table (1 or 0)
Property SystemTable As %Integer [ Calculated, Internal, Private, Required, SqlColumnNumber = 23, SqlComputeCode = { set {*}=$s($e({SchemaExact})="%"||({SchemaExact}="INFORMATION_SCHEMA"):1,1:0) }, SqlComputed ];

/// Catalog qualifier - always NULL in InterSystems IRIS.
Property CONSTRAINTCATALOG As %String(MAXLEN = 128) [ Calculated, SqlColumnNumber = 2, SqlComputeCode = { set {*}=""}, SqlComputed, SqlFieldName = CONSTRAINT_CATALOG ];

/// Name of schema that contains the foreign key constraint.
Property CONSTRAINTSCHEMA As %String(COLLATION = "Upper", MAXLEN = 128) [ SqlColumnNumber = 3, SqlFieldName = CONSTRAINT_SCHEMA ];

/// Name of the table that contains the foreign key constraint.
Property CONSTRAINTTABLENAME As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 4, SqlFieldName = CONSTRAINT_TABLE_NAME ];

/// Foreign key constraint name.
Property CONSTRAINTNAME As %String(COLLATION = "Upper", MAXLEN = 128) [ SqlColumnNumber = 5, SqlFieldName = CONSTRAINT_NAME ];

/// Unique Constraint qualifier - always NULL in InterSystems IRIS.
Property UNIQUECONSTRAINTCATALOG As %String(MAXLEN = 128) [ Calculated, SqlColumnNumber = 6, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = UNIQUE_CONSTRAINT_CATALOG ];

/// Name of the schema that contains the unique constraint the foreign key references.
Property UNIQUECONSTRAINTSCHEMA As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 7, SqlFieldName = UNIQUE_CONSTRAINT_SCHEMA ];

/// Name of the table that contains the unique constraint the foreign key references.
Property UNIQUECONSTRAINTTABLE As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 8, SqlFieldName = UNIQUE_CONSTRAINT_TABLE ];

/// Name of the unique constraint the foreign key constraint references.
Property UNIQUECONSTRAINTNAME As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 9, SqlFieldName = UNIQUE_CONSTRAINT_NAME ];

/// The values of MATCH_OPTION have the following meanings:
/// <br><ul>
/// 	<li>NONE - No match type was specified.</li>
/// 	<li>PARTIAL - A match type of partial was specified.</li>
/// 	<li>FULL - A match type of full was specified.</li>
/// </ul>
/// For InterSystems IRIS MATCH_OPTION is always NONE.
Property MATCHOPTION As %String(MAXLEN = 7, VALUELIST = ",NONE,PARTIAL,FULL") [ Calculated, SqlColumnNumber = 10, SqlComputeCode = { set {*}="NONE" }, SqlComputed, SqlFieldName = MATCH_OPTION ];

/// The values of UPDATE_RULE have the following meanings for foreign keys constraints:
/// <br><ul>
/// 	<li>NO ACTION - A referential action of NO ACTION was specified.</li>
/// 	<li>SET NULL - A referential action of SET NULL was specified.</li>
/// 	<li>SET DEFAULT - A referential action of SET DEFAULT was specified.</li>
/// 	<li>RESTRICT - A referential action of RESTRICT was specified.</li>
/// 	<li>CASCADE - A referential action of CASCADE was specified.</li>
/// </ul>
Property UPDATERULE As %String(MAXLEN = 11, VALUELIST = ",CASCADE,SET NULL,SET DEFAULT,RESTRICT,NO ACTION") [ Required, SqlColumnNumber = 11, SqlFieldName = UPDATE_RULE ];

/// The values of DELETE_RULE have the following meanings for foreign keys constraints:
/// <br><ul>
/// 	<li>NO ACTION - A referential action of NO ACTION was specified.</li>
/// 	<li>SET NULL - A referential action of SET NULL was specified.</li>
/// 	<li>SET DEFAULT - A referential action of SET DEFAULT was specified.</li>
/// 	<li>RESTRICT - A referential action of RESTRICT was specified.</li>
/// 	<li>CASCADE - A referential action of CASCADE was specified.</li>
/// </ul>
Property DELETERULE As %String(MAXLEN = 11, VALUELIST = ",CASCADE,SET NULL,SET DEFAULT,RESTRICT,NO ACTION") [ Required, SqlColumnNumber = 12, SqlFieldName = DELETE_RULE ];

/// 0 = KeyCascade, 1 = KeyRestrict, 2 = SetNull, 3 = NoAction, 4 = SetDefault
ClassMethod UPDATERULELogicalToStorage(%val As %String) As %Integer [ Internal ]
{
}

/// 0 = KeyCascade, 1 = KeyRestrict, 2 = SetNull, 3 = NoAction, 4 = SetDefault
ClassMethod UPDATERULEStorageToLogical(%val As %String) As %Integer [ Internal ]
{
}

/// 0 = KeyCascade, 1 = KeyRestrict, 2 = SetNull, 3 = NoAction, 4 = SetDefault
ClassMethod DELETERULELogicalToStorage(%val As %String) As %Integer [ Internal ]
{
}

/// 0 = KeyCascade, 1 = KeyRestrict, 2 = SetNull, 3 = NoAction, 4 = SetDefault
ClassMethod DELETERULEStorageToLogical(%val As %String) As %Integer [ Internal ]
{
}

Storage SQLStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Data name="CONSTRAINT_NAME">
<RetrievalCode> set {*}={L4}</RetrievalCode>
</Data>
<Data name="CONSTRAINT_SCHEMA">
<RetrievalCode> set {*}={L1}</RetrievalCode>
</Data>
<Data name="CONSTRAINT_TABLE_NAME">
<RetrievalCode> set {*}={L2}</RetrievalCode>
</Data>
<Data name="DELETE_RULE">
<Piece>6</Piece>
</Data>
<Data name="UNIQUE_CONSTRAINT_NAME">
<Piece>4</Piece>
</Data>
<Data name="UNIQUE_CONSTRAINT_SCHEMA">
<Piece>2</Piece>
</Data>
<Data name="UNIQUE_CONSTRAINT_TABLE">
<Piece>3</Piece>
</Data>
<Data name="UPDATE_RULE">
<Piece>5</Piece>
</Data>
<Global>^oddSQL</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>{SchemaExact}</Expression>
<Invalidcondition name="1">
<Expression>$e({L1},1,10)="IRIS_Shard"||($e({L1},1,20)="IRIS_MasterFederated")||($e({L1},1,14)="IRIS_Federated")</Expression>
</Invalidcondition>
<NextCode>set {L1} = $$GetNextSubscript^%SYS.SQLSEC("^oddSQL", {L1}) quit:{L1}=""
	goto:($e({L1},1,10)="IRIS_Shard"||($e({L1},1,20)="IRIS_MasterFederated")||($e({L1},1,14)="IRIS_Federated")) NEXT</NextCode>
</Subscript>
<Subscript name="2">
<Expression>{TableExact}</Expression>
<Invalidcondition name="1">
<Expression>'($d(^oddSQL({L1},{L2}))#2)</Expression>
</Invalidcondition>
<Invalidcondition name="2">
<Expression>'$$AnyPrivObj^%SYS.SQLSEC($li(^oddSQL({L1},{L2}),6),0)</Expression>
</Invalidcondition>
</Subscript>
<Subscript name="3">
<Expression>15</Expression>
</Subscript>
<Subscript name="4">
<Expression>{ConstraintExact}</Expression>
<Invalidcondition name="1">
<Expression>$lg($g(^oddSQL({L1},{L2},{L3},{L4})))'="f"</Expression>
</Invalidcondition>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^INFORMATIO862B.REFERENTIAL9E18S</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

