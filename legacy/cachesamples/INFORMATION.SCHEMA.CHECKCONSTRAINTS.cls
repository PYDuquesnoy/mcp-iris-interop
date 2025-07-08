/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Returns one row for each check constraint in the current namespace for tables that can be accessed by the current user in the current namespace.
/// Note that InterSystems IRIS does not currently support check constraints, this table exists for future use.
Class INFORMATION.SCHEMA.CHECKCONSTRAINTS Extends %Library.Persistent [ ClassType = persistent, Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = CHECK_CONSTRAINTS, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

Index IDKeyIndex On (SchemaExact, TableExact, ConstraintExact) [ IdKey, Internal, Unique ];

Property SchemaExact As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 10 ];

Property TableExact As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 11 ];

Property TableName As %String(COLLATION = "Upper", MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 12 ];

Property ConstraintExact As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 13 ];

/// Is the table a system table (1 or 0)
Property SystemTable As %Integer [ Calculated, Internal, Private, Required, SqlColumnNumber = 14, SqlComputeCode = { set {*}=$s($e({CONSTRAINT_SCHEMA})="%"||({CONSTRAINT_SCHEMA}="INFORMATION_SCHEMA"):1,1:0) }, SqlComputed ];

/// Constraint qualifier - always NULL in InterSystems IRIS.
Property CONSTRAINTCATALOG As %String(MAXLEN = 128) [ Calculated, SqlColumnNumber = 2, SqlComputeCode = { set {*}=""}, SqlComputed, SqlFieldName = CONSTRAINT_CATALOG ];

/// Name of schema that contains the constraint.  Always the same as the TABLE_SCHEMA.
Property CONSTRAINTSCHEMA As %String(COLLATION = "Upper", MAXLEN = 128) [ SqlColumnNumber = 3, SqlFieldName = CONSTRAINT_SCHEMA ];

/// Name of the constraint.
Property CONSTRAINTNAME As %String(COLLATION = "Upper", MAXLEN = 128) [ SqlColumnNumber = 4, SqlFieldName = CONSTRAINT_NAME ];

/// The search condition contained in the check constraint definition.
Property CHECKCLAUSE As %String(MAXLEN = 2048) [ Calculated, SqlColumnNumber = 5, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = CHECK_CLAUSE ];

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
<Data name="TableName">
<RetrievalCode> set {*}={L2}</RetrievalCode>
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
<Expression>$lg(^oddSQL({L1},{L2},15,{L4}))'="c"</Expression>
</Invalidcondition>
</Subscript>
<Type>data</Type>
</SQLMap>
<SQLMap name="rxIndex">
<Data name="CONSTRAINT_NAME">
<RetrievalCode> set {*}={L4}</RetrievalCode>
</Data>
<Data name="SchemaExact">
<RetrievalCode>set {*}=$p($lg(^rINDEXSQL("rv",{L2},{L3}),4),".",1,*-1)</RetrievalCode>
</Data>
<Data name="TableExact">
<RetrievalCode>set {*}=$tr($p($lg(^rINDEXSQL("rv",{L2},{L3}),4),".",*),$c(2),".")</RetrievalCode>
</Data>
<Global>^rINDEXSQL</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>"rv"</Expression>
</Subscript>
<Subscript name="2">
<Expression>$$UPPER({CONSTRAINT_SCHEMA})</Expression>
<Invalidcondition name="1">
<Expression>$e({L2},1,10)="IRIS_SHARD"||($e({L2},1,20)="IRIS_MASTERFEDERATED")||($e({L2},1,14)="IRIS_FEDERATED")</Expression>
</Invalidcondition>
<NextCode>set {L2} = $$GetNextSubscript^%SYS.SQLSEC("^rINDEXSQL(""rv"")", {L2}) quit:{L2}=""
    goto:($e({L2},1,10)="IRIS_SHARD"||($e({L2},1,20)="IRIS_MASTERFEDERATED")||($e({L2},1,14)="IRIS_FEDERATED")) NEXT</NextCode>
</Subscript>
<Subscript name="3">
<Accessvar name="1">
<Code> set {3D1}=$p($lg(^rINDEXSQL("rv",{L2},{L3}),4),".",1,*-1)</Code>
<Variable>{3D1}</Variable>
</Accessvar>
<Accessvar name="2">
<Code> set {3D2}=$tr($p($lg(^rINDEXSQL("rv",{L2},{L3}),4),".",*),$c(2),".")</Code>
<Variable>{3D2}</Variable>
</Accessvar>
<Expression>$$UPPER({TableName})</Expression>
<Invalidcondition name="1">
<Expression>'$$AnyPrivObj^%SYS.SQLSEC($li(^rINDEXSQL("rv",{L2},{L3}),3)_","_$li(^rINDEXSQL("rv",{L2},{L3}),4))</Expression>
</Invalidcondition>
</Subscript>
<Subscript name="4">
<AccessType>Sub</AccessType>
<DataAccess>^oddSQL({3D1},{3D2},15)</DataAccess>
<Expression>{ConstraintExact}</Expression>
<Invalidcondition name="1">
<Expression>$lg(^oddSQL({L1},{L2},15,{L4}))'="c"</Expression>
</Invalidcondition>
</Subscript>
<Type>index</Type>
</SQLMap>
<StreamLocation>^INFORMATIO862B.CHECKCONSTR701ES</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

