/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Returns one row for each table column that is used in a view where the view and view column can be accessed by the current user in the current namespace.
Class INFORMATION.SCHEMA.VIEWCOLUMNUSAGE Extends %Library.Persistent [ ClassType = persistent, Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = VIEW_COLUMN_USAGE, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

Index IDKeyIndex On (SchemaExact, ViewExact, ViewColumnName) [ IdKey, Internal, Unique ];

Property SchemaExact As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 10 ];

Property ViewExact As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 11 ];

Property ViewColumnName As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 12 ];

/// Is the view a system view (1 or 0)
Property SystemView As %Integer [ Calculated, Internal, Private, Required, SqlColumnNumber = 14, SqlComputeCode = { set {*}=$s($e({VIEW_SCHEMA})="%"||({VIEW_SCHEMA}="INFORMATION_SCHEMA"):1,1:0) }, SqlComputed ];

/// View qualifier - always NULL in InterSystems IRIS
Property VIEWCATALOG As %String(MAXLEN = 128) [ Calculated, SqlColumnNumber = 2, SqlComputeCode = { set {*}=""}, SqlComputed, SqlFieldName = VIEW_CATALOG ];

/// Name of schema that contains the view.
Property VIEWSCHEMA As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 3, SqlFieldName = VIEW_SCHEMA ];

/// Name of the view.
Property VIEWNAME As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 4, SqlFieldName = VIEW_NAME ];

/// Table qualifier - always NULL in InterSystems IRIS
Property TABLECATALOG As %String(MAXLEN = 128) [ Calculated, SqlColumnNumber = 5, SqlComputeCode = { set {*}=""}, SqlComputed, SqlFieldName = TABLE_CATALOG ];

/// Name of schema that contains the table.
Property TABLESCHEMA As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 6, SqlFieldName = TABLE_SCHEMA ];

/// Name of the table.
Property TABLENAME As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 7, SqlFieldName = TABLE_NAME ];

/// Name of the column.
Property COLUMNNAME As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 8, SqlFieldName = COLUMN_NAME ];

Storage SQLStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Data name="COLUMN_NAME">
<Piece>3</Piece>
</Data>
<Data name="TABLE_NAME">
<Piece>2</Piece>
</Data>
<Data name="TABLE_SCHEMA">
<Piece>1</Piece>
</Data>
<Data name="VIEW_NAME">
<RetrievalCode> set {*}={L2}</RetrievalCode>
</Data>
<Data name="VIEW_SCHEMA">
<RetrievalCode> set {*}={L1}</RetrievalCode>
</Data>
<Global>^oddSQL</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>{SchemaExact}</Expression>
<NextCode>set {L1} = $$GetNextSubscript^%SYS.SQLSEC("^oddSQL", {L1})</NextCode>
</Subscript>
<Subscript name="2">
<Expression>{ViewExact}</Expression>
<Invalidcondition name="1">
<Expression>'$d(^rINDEXSQL("VIEW",{L1},{L2}))</Expression>
</Invalidcondition>
<Invalidcondition name="2">
<Expression>'$d(^oddSQL({L1},{L2},16))</Expression>
</Invalidcondition>
<Invalidcondition name="3">
<Expression>'$$AnyPrivObj^%SYS.SQLSEC("3,"_$li(^rINDEXSQL("rv",$zconvert({L1},"u"),$zconvert({L2},"u")),4),0)</Expression>
</Invalidcondition>
</Subscript>
<Subscript name="3">
<Expression>16</Expression>
</Subscript>
<Subscript name="4">
<Expression>{ViewColumnName}</Expression>
<Invalidcondition name="1">
<Expression>
<![CDATA['$$AnyPrivTable^%SYS.SQLSEC($li(^oddSQL({L1},{L2}),6),0)&&('$$AnyPrivField^%SYS.SQLSEC($li({3D},6),$li(^oddSQL({L1},{L2},8,{L4}),4),0))]]></Expression>
</Invalidcondition>
</Subscript>
<Type>data</Type>
</SQLMap>
<SQLMap name="rxIndex">
<Data name="COLUMN_NAME">
<Piece>3</Piece>
</Data>
<Data name="SchemaExact">
<RetrievalCode>set {*}={3D2}</RetrievalCode>
</Data>
<Data name="TABLE_NAME">
<Piece>2</Piece>
</Data>
<Data name="TABLE_SCHEMA">
<Piece>1</Piece>
</Data>
<Data name="ViewExact">
<RetrievalCode>set {*}={3D3}</RetrievalCode>
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
<Code> set {3D1}=$li(^rINDEXSQL("rv",$zconvert({L2},"u"),$zconvert({L3},"u")),4)</Code>
<Variable>{3D1}</Variable>
</Accessvar>
<Accessvar name="2">
<Code> set {3D2}=$p({3D1},".",1,*-1)</Code>
<Variable>{3D2}</Variable>
</Accessvar>
<Accessvar name="3">
<Code> set {3D3}=$tr($p({3D1},".",*),$c(2),".")</Code>
<Variable>{3D3}</Variable>
</Accessvar>
<Expression>$$UPPER({VIEW_NAME})</Expression>
<Invalidcondition name="1">
<Expression>'$$AnyPrivObj^%SYS.SQLSEC("3,"_$li(^rINDEXSQL("rv",$zconvert({L2},"u"),$zconvert({L3},"u")),4),0)</Expression>
</Invalidcondition>
</Subscript>
<Subscript name="4">
<DataAccess>^oddSQL({3D2},{3D3},16)</DataAccess>
<Expression>{ViewColumnName}</Expression>
<Invalidcondition name="1">
<Expression>
<![CDATA['$$AnyPrivTable^%SYS.SQLSEC("3,"_{3D1},0)&&('$$AnyPrivField^%SYS.SQLSEC("3,"_{3D1},{L4},0))]]></Expression>
</Invalidcondition>
</Subscript>
<Type>index</Type>
</SQLMap>
<StreamLocation>^INFORMATIO862B.VIEWCOLUMNU6DBDS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

