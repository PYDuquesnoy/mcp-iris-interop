/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Returns one row for each user defined aggregate that can be accessed by the current user in the current namespace.
Class INFORMATION.SCHEMA.USERDEFINEDAGGREGATES Extends %Library.Persistent [ ClassType = persistent, Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = USER_DEFINED_AGGREGATES, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

Index IDKeyIndex On (SchemaUpper, TableUpper) [ IdKey, Internal, Unique ];

Property SchemaUpper As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 60 ];

Property TableUpper As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 61 ];

/// Name of the schema that contains the user defined aggregate
Property AGGREGATECHEMA As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 2, SqlFieldName = AGGREGATE_SCHEMA ];

/// Aggregate name
Property AGGREGATENAME As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 3, SqlFieldName = AGGREGATE_NAME ];

/// The datatype of the value returned by the User Defined Aggregate
Property RETURNTYPE As %String(MAXLEN = 128) [ SqlColumnNumber = 4, SqlFieldName = RETURN_TYPE ];

/// The parameters and types of the User Defined Aggregate
Property PARAMETERLIST As %String(MAXLEN = 512) [ SqlColumnNumber = 5, SqlFieldName = PARAMETER_LIST ];

/// The owner of the User Defined Aggregate
Property OWNER As %String(MAXLEN = 160) [ SqlColumnNumber = 6, SqlFieldName = OWNER ];

/// The Initialize Function of the User Defined Aggregate
Property INITIALIZEFUNCTION As %String(MAXLEN = 257) [ SqlColumnNumber = 7, SqlFieldName = INITIALIZE_FUNCTION ];

/// The Iterate Function of the User Defined Aggregate
Property ITERATEFUNCTION As %String(MAXLEN = 257) [ SqlColumnNumber = 8, SqlFieldName = ITERATE_FUNCTION ];

/// The Merge Function of the User Defined Aggregate
Property MERGEFUNCTION As %String(MAXLEN = 257) [ SqlColumnNumber = 9, SqlFieldName = MERGE_FUNCTION ];

/// The Finalize Function of the User Defined Aggregate
Property FINALIZEFUNCTION As %String(MAXLEN = 257) [ SqlColumnNumber = 10, SqlFieldName = FINALIZE_FUNCTION ];

Storage SQLStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Data name="AGGREGATE_NAME">
<Node>10</Node>
</Data>
<Data name="AGGREGATE_SCHEMA">
<Node>20</Node>
</Data>
<Data name="FINALIZE_FUNCTION">
<RetrievalCode> set {*}=$s($d(^oddPROC({L1},{L2},34)):$lg($g(^oddPROC({L1},{L2},34)),3)_"."_$lg($g(^oddPROC({L1},{L2},34)),4),1:"")</RetrievalCode>
</Data>
<Data name="INITIALIZE_FUNCTION">
<RetrievalCode> set {*}=$s($d(^oddPROC({L1},{L2},31)):$lg($g(^oddPROC({L1},{L2},31)),3)_"."_$lg($g(^oddPROC({L1},{L2},31)),4),1:"")</RetrievalCode>
</Data>
<Data name="ITERATE_FUNCTION">
<RetrievalCode> set {*}=$s($d(^oddPROC({L1},{L2},32)):$lg($g(^oddPROC({L1},{L2},32)),3)_"."_$lg($g(^oddPROC({L1},{L2},32)),4),1:"")</RetrievalCode>
</Data>
<Data name="MERGE_FUNCTION">
<RetrievalCode> set {*}=$s($d(^oddPROC({L1},{L2},33)):$lg($g(^oddPROC({L1},{L2},33)),3)_"."_$lg($g(^oddPROC({L1},{L2},33)),4),1:"")</RetrievalCode>
</Data>
<Data name="OWNER">
<Node>36</Node>
</Data>
<Data name="PARAMETER_LIST">
<Node>37</Node>
</Data>
<Data name="RETURN_TYPE">
<Node>35</Node>
</Data>
<Global>^oddPROC</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>{SchemaUpper}</Expression>
<NextCode>set {L1} = $$GetNextSubscript^%SYS.SQLSEC("^oddPROC", {L1})</NextCode>
</Subscript>
<Subscript name="2">
<Expression>{TableUpper}</Expression>
<Invalidcondition name="1">
<Expression>$g(^oddPROC({L1},{L2},22))'="udaf"</Expression>
</Invalidcondition>
<Invalidcondition name="2">
<Expression>'$$ExecutePriv^%SYS.SQLSEC("9,"_$g(^oddPROC({L1},{L2},20))_"."_$tr($g(^oddPROC({L1},{L2},10)),".",$c(2)))</Expression>
</Invalidcondition>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^INFORMATIO862B.USERDEFINED6EADS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

