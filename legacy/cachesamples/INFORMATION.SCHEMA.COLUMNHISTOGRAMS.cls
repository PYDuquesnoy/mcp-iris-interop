/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class INFORMATION.SCHEMA.COLUMNHISTOGRAMS Extends %Persistent [ ClassType = persistent, Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = COLUMN_HISTOGRAMS, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

Index IDKeyIndex On (SchemaExact, TableExact, ORDINALPOSITION, BUCKETPOSITION) [ IdKey, Internal, Unique ];

Property SchemaExact As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 45 ];

Property TableExact As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 46 ];

/// Table qualifier - always NULL in InterSystems IRIS
Property TABLECATALOG As %String(MAXLEN = 128) [ Calculated, SqlColumnNumber = 2, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = TABLE_CATALOG ];

/// Name of schema that contains the table.
Property TABLESCHEMA As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 3, SqlFieldName = TABLE_SCHEMA ];

/// Name of the table.
Property TABLENAME As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 4, SqlFieldName = TABLE_NAME ];

/// Name of the column.
Property COLUMNNAME As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 5, SqlFieldName = COLUMN_NAME ];

/// Column's ordinal position within the table.
Property ORDINALPOSITION As %Integer [ Required, SqlColumnNumber = 6, SqlFieldName = ORDINAL_POSITION ];

Property BUCKETPOSITION As %Integer [ Required, SqlColumnNumber = 7, SqlFieldName = BUCKET_POSITION ];

Property BUCKETWIDTH As %Float [ SqlColumnNumber = 8, SqlFieldName = BUCKET_WIDTH ];

Property INTERPOLATABLE As %Boolean [ SqlColumnNumber = 9 ];

Property NULLBUCKETS As %Integer [ SqlColumnNumber = 10, SqlFieldName = NULL_BUCKETS ];

Property PERCENTILE As %Float [ SqlColumnNumber = 11 ];

Property VALUE As %String [ SqlColumnNumber = 12 ];

Storage SQLStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Data name="BUCKET_WIDTH">
<RetrievalCode>set {*} = $lg({1D3},1)</RetrievalCode>
</Data>
<Data name="COLUMN_NAME">
<RetrievalCode>set {*} = $lg({1D1},4)</RetrievalCode>
</Data>
<Data name="INTERPOLATABLE">
<RetrievalCode>set {*} = $lg({1D3},2)</RetrievalCode>
</Data>
<Data name="NULL_BUCKETS">
<RetrievalCode>set {*} = $lg({1D3},3)</RetrievalCode>
</Data>
<Data name="PERCENTILE">
<RetrievalCode>set {*} = ({L5}-1)*$lg({1D3},1)</RetrievalCode>
</Data>
<Data name="TABLE_NAME">
<RetrievalCode>set {*} = $lg({1D1},3)</RetrievalCode>
</Data>
<Data name="TABLE_SCHEMA">
<RetrievalCode>set {*} = $lg({1D1},2)</RetrievalCode>
</Data>
<Data name="VALUE">
<RetrievalCode>set {*} = $lg({1D4},{L5})</RetrievalCode>
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
<Expression>8</Expression>
</Subscript>
<Subscript name="4">
<Accessvar name="1">
<Code> s {1D1}=$g(^oddSQL({L1},{L2},{L3},{L4})) </Code>
<Variable>{1D1}</Variable>
</Accessvar>
<Accessvar name="2">
<Code> s {1D2}=$$$EXTSQLCOLsqlinfo($$$rEXT,$$$GetExtentNameFromTableName({L1},{L2}),$lg({1D1},4,-1)) </Code>
<Variable>{1D2}</Variable>
</Accessvar>
<Accessvar name="3">
<Code> n histogram
 s histogram = $$$SQLLocColHistogram({1D2}), {1D3}=""
 if (histogram'="") x ("(histogram) set histogram = "_histogram, .histogram) s {1D3}=histogram </Code>
<Variable>{1D3}</Variable>
</Accessvar>
<Accessvar name="4">
<Code> s {1D4}=$lg({1D3},4) </Code>
<Variable>{1D4}</Variable>
</Accessvar>
<Expression>{ORDINAL_POSITION}</Expression>
<Invalidcondition name="1">
<Expression>
<![CDATA['$$AnyPrivTable^%SYS.SQLSEC($li(^oddSQL({L1},{L2}),6),0)&&('$$AnyPrivField^%SYS.SQLSEC($li({3D},6),$li(^oddSQL({L1},{L2},8,{L4}),4),0))]]></Expression>
</Invalidcondition>
</Subscript>
<Subscript name="5">
<AccessType>Other</AccessType>
<Expression>{BUCKET_POSITION}</Expression>
<NextCode>
<![CDATA[ s {L5}=$i({L5})
  if {L5}>$ll($lg({1D3},4)) s {L5}="" QUIT]]></NextCode>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^INFORMATION.SCHEMA.TABLESS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

