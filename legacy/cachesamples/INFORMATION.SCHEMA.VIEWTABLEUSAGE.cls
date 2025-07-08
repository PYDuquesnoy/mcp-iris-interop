/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Returns one row for each table in the current namespace where the table is used by a view, and the current user has privileges for the table and view.
Class INFORMATION.SCHEMA.VIEWTABLEUSAGE Extends %Library.Persistent [ ClassType = persistent, Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = VIEW_TABLE_USAGE, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

Index IDKeyIndex On (SchemaExact, ViewExact, TableExtent) [ IdKey, Internal, Unique ];

Index PKeyIndex On (VIEWSCHEMA, VIEWNAME, TABLESCHEMA, TABLENAME) [ PrimaryKey ];

Property SchemaExact As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 20 ];

Property ViewExact As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 21 ];

Property TableExtent As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 22 ];

/// Is the table a system table (1 or 0)
Property SystemTable As %Integer [ Calculated, Internal, Private, Required, SqlColumnNumber = 23, SqlComputeCode = { set {*}=$s($e({TABLE_SCHEMA})="%"||({TABLE_SCHEMA}="INFORMATION_SCHEMA"):1,1:0) }, SqlComputed ];

/// View qualifier - always NULL in InterSystems IRIS.
Property VIEWCATALOG As %String(MAXLEN = 128) [ Calculated, SqlColumnNumber = 2, SqlComputeCode = { set {*}=""}, SqlComputed, SqlFieldName = VIEW_CATALOG ];

/// Name of schema that contains the view.
Property VIEWSCHEMA As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 3, SqlFieldName = VIEW_SCHEMA ];

/// Name of the view.
Property VIEWNAME As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 4, SqlFieldName = VIEW_NAME ];

/// Table qualifier - always NULL in InterSystems IRIS.
Property TABLECATOLOG As %String(MAXLEN = 128) [ Calculated, SqlColumnNumber = 5, SqlComputeCode = { set {*}=""}, SqlComputed, SqlFieldName = TABLE_CATALOG ];

/// Name of schema that contains the table.
Property TABLESCHEMA As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 6, SqlFieldName = TABLE_SCHEMA ];

/// Name of the table.
Property TABLENAME As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 7, SqlFieldName = TABLE_NAME ];

Storage SQLStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Data name="TABLE_NAME">
<RetrievalCode> set {*}=$lg(^oddEXTR({L4},91),2)</RetrievalCode>
</Data>
<Data name="TABLE_SCHEMA">
<RetrievalCode> set {*}=$lg(^oddEXTR({L4},91),1)</RetrievalCode>
</Data>
<Data name="VIEW_NAME">
<RetrievalCode> set {*}={L3}</RetrievalCode>
</Data>
<Data name="VIEW_SCHEMA">
<RetrievalCode> set {*}={L2}</RetrievalCode>
</Data>
<Global>^rINDEXSQL</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>"VIEW"</Expression>
</Subscript>
<Subscript name="2">
<Expression>{SchemaExact}</Expression>
<NextCode>set {L2} = $$GetNextSubscript^%SYS.SQLSEC("^rINDEXSQL(""VIEW"")", {L2})</NextCode>
</Subscript>
<Subscript name="3">
<Accessvar name="1">
<Code> set {3D1}=$li(^rINDEXSQL("rv",$zconvert({L2},"u"),$zconvert({L3},"u")),2)</Code>
<Variable>{3D1}</Variable>
</Accessvar>
<Expression>{ViewExact}</Expression>
<Invalidcondition name="1">
<Expression>'$$AnyPrivObj^%SYS.SQLSEC("3,"_$li(^rINDEXSQL("rv",$zconvert({L2},"u"),$zconvert({L3},"u")),4),0)</Expression>
</Invalidcondition>
</Subscript>
<Subscript name="4">
<DataAccess>^oddEXTR({3D1},"spec",96)</DataAccess>
<Expression>{TableExtent}</Expression>
<Invalidcondition name="1">
<Expression>{L4}="%TSQL.sys.snf"</Expression>
</Invalidcondition>
<Invalidcondition name="2">
<Expression>'$$AnyPrivObj^%SYS.SQLSEC("1,"_$li(^rINDEXSQL("rv",$zconvert($lg(^oddEXTR({L4},91),1),"u"),$zconvert($lg(^oddEXTR({L4},91),2),"u")),4),0)</Expression>
</Invalidcondition>
</Subscript>
<Type>data</Type>
</SQLMap>
<SQLMap name="rxIndex">
<Data name="SchemaExact">
<RetrievalCode>set {*}=$p($lg(^rINDEXSQL("rv",{L2},{L3}),4),".",1,*-1)</RetrievalCode>
</Data>
<Data name="TABLE_NAME">
<RetrievalCode> set {*}=$lg(^oddEXTR({L4},91),2)</RetrievalCode>
</Data>
<Data name="TABLE_SCHEMA">
<RetrievalCode> set {*}=$lg(^oddEXTR({L4},91),1)</RetrievalCode>
</Data>
<Data name="ViewExact">
<RetrievalCode>set {*}=$tr($p($lg(^rINDEXSQL("rv",{L2},{L3}),4),".",*),$c(2),".")</RetrievalCode>
</Data>
<Global>^rINDEXSQL</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>"rv"</Expression>
</Subscript>
<Subscript name="2">
<Expression>$$UPPER({VIEW_SCHEMA})</Expression>
<NextCode>set {L2} = $$GetNextSubscript^%SYS.SQLSEC("^rINDEXSQL(""rv"")", {L2})</NextCode>
</Subscript>
<Subscript name="3">
<Accessvar name="1">
<Code> set {3D1}=$li(^rINDEXSQL("rv",$zconvert({L2},"u"),$zconvert({L3},"u")),2)</Code>
<Variable>{3D1}</Variable>
</Accessvar>
<Expression>$$UPPER({VIEW_NAME})</Expression>
<Invalidcondition name="1">
<Expression>'$$AnyPrivObj^%SYS.SQLSEC("3,"_$li(^rINDEXSQL("rv",$zconvert({L2},"u"),$zconvert({L3},"u")),4),0)</Expression>
</Invalidcondition>
</Subscript>
<Subscript name="4">
<DataAccess>^oddEXTR({3D1},"spec",96)</DataAccess>
<Expression>{TableExtent}</Expression>
<Invalidcondition name="1">
<Expression>{L4}="%TSQL.sys.snf"</Expression>
</Invalidcondition>
<Invalidcondition name="2">
<Expression>'$$AnyPrivObj^%SYS.SQLSEC("1,"_$li(^rINDEXSQL("rv",$zconvert($lg(^oddEXTR({L4},91),1),"u"),$zconvert($lg(^oddEXTR({L4},91),2),"u")),4),0)</Expression>
</Invalidcondition>
</Subscript>
<Type>index</Type>
</SQLMap>
<StreamLocation>^INFORMATION862B.VIEWTABLEUSAGES</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

