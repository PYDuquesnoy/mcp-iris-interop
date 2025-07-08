/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Returns one row for each column that can be accessed by the current user in the current namespace.
Class INFORMATION.SCHEMA.COLUMNS Extends %Library.Persistent [ ClassType = persistent, Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = COLUMNS, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

Index IDKeyIndex On (SchemaExact, TableExact, ORDINALPOSITION) [ IdKey, Internal, Unique ];

Property SchemaExact As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 45 ];

Property TableExact As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 46 ];

/// Is the table a system table (1 or 0)
Property SystemTable As %Integer [ Calculated, Internal, Private, Required, SqlColumnNumber = 47, SqlComputeCode = { set {*}=$s($e({TABLE_SCHEMA})="%"||({TABLE_SCHEMA}="INFORMATION_SCHEMA"):1,1:0) }, SqlComputed ];

/// Table qualifier - always NULL in InterSystems IRIS
Property TABLECATALOG As %String(MAXLEN = 128) [ Calculated, SqlColumnNumber = 2, SqlComputeCode = { set {*}=""}, SqlComputed, SqlFieldName = TABLE_CATALOG ];

/// Name of schema that contains the table.
Property TABLESCHEMA As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 3, SqlFieldName = TABLE_SCHEMA ];

/// Name of the table.
Property TABLENAME As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 4, SqlFieldName = TABLE_NAME ];

/// Name of the column.
Property COLUMNNAME As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 5, SqlFieldName = COLUMN_NAME ];

/// Column's ordinal position within the table.
Property ORDINALPOSITION As %Integer [ Required, SqlColumnNumber = 6, SqlFieldName = ORDINAL_POSITION ];

/// Reserved for future use.  For InterSystems IRIS DTD_IDENTIFIER is always NULL.
Property DTDIDENTIFIER As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 7, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = DTD_IDENTIFIER ];

/// Reserved for future use.  For InterSystems IRIS DOMAIN_CATALOG is always NULL.
Property DOMAINCATALOG As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 8, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = DOMAIN_CATALOG ];

/// Reserved for future use.  For InterSystems IRIS DOMAIN_SCHEMA is always NULL.
Property DOMAINSCHEMA As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 9, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = DOMAIN_SCHEMA ];

/// Reserved for future use.  For InterSystems IRIS DOMAIN_NAME is always NULL.
Property DOMAINNAME As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 10, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = DOMAIN_NAME ];

/// Default value for the column.
Property COLUMNDEFAULT As %String(MAXLEN = 4000) [ SqlColumnNumber = 11, SqlFieldName = COLUMN_DEFAULT ];

/// If the column allows a NULL value, IS_NULLABLE returns YES, otherwise NO.
Property ISNULLABLE As %String(MAXLEN = 3, VALUELIST = ",YES,NO") [ SqlColumnNumber = 12, SqlFieldName = IS_NULLABLE ];

/// Reserved for future use.  For InterSystems IRIS IS_SELF_REFERENCING is always NULL.
Property ISSELFREFERENCING As %String(MAXLEN = 3, VALUELIST = ",YES,NO") [ Calculated, SqlColumnNumber = 13, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = IS_SELF_REFERENCING ];

/// If this column is an IDENTITY column IS_IDENTITY returns YES, otherwise NO.
Property ISIDENTITY As %String(MAXLEN = 3, VALUELIST = ",YES,NO") [ SqlColumnNumber = 14, SqlFieldName = IS_IDENTITY ];

/// Reserved for future use.  For InterSystems IRIS IDENTITY_GENERATION is always NULL.
Property IDENTITYGENERATION As %String(MAXLEN = 10, VALUELIST = ",ALWAYS,BY DEFAULT") [ Calculated, SqlColumnNumber = 15, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = IDENTITY_GENERATION ];

/// Reserved for future use.  For InterSystems IRIS IDENTITY_START is always NULL.
Property IDENTITYSTART As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 16, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = IDENTITY_START ];

/// Reserved for future use.  For InterSystems IRIS IDENTITY_INCREMENT is always NULL.
Property IDENTITYINCREMENT As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 17, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = IDENTITY_INCREMENT ];

/// Reserved for future use.  For InterSystems IRIS IDENTITY_MAXIMUM is always NULL.
Property IDENTITYMAXIMUM As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 18, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = IDENTITY_MAXIMUM ];

/// Reserved for future use.  For InterSystems IRIS IDENTITY_MINIMUM is always NULL.
Property IDENTITYMINIMUM As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 19, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = IDENTITY_MINIMUM ];

/// Reserved for future use.  For InterSystems IRIS IDENTITY_CYCLE is always NULL.
Property IDENTITYCYCLE As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 20, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = IDENTITY_CYCLE ];

/// If the column is an SqlComputed column IS_GENERATED returns YES, otherwise NO.
Property ISGENERATED As %String(MAXLEN = 3) [ SqlColumnNumber = 21, SqlFieldName = IS_GENERATED ];

/// Reserved for future use.  For InterSystems IRIS GENERATION_EXPRESSION is always NULL.
Property GENERATIONEXPRESSION As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 22, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = GENERATION_EXPRESSION ];

/// Returns YES if the column is updatable, otherwise NO.
/// <br>All base tables are updatable and every column of a base table is updatable.
/// <br>A view colum's updatability depends on the view's updatablity.
Property ISUPDATABLE As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 23, SqlComputeCode = { new tType set tType=$lg(^oddSQL({SchemaExact},{TableExact}),4)
if tType["TABLE" { set {*}="YES" }
else { new tExtent set tExtent=$lg($g(^rINDEXSQL("rv",$zconvert({TABLE_SCHEMA},"u"),$zconvert({TABLE_NAME},"u"))),2) set {*}=$s($lg(^oddEXTR(tExtent,91),30)=1:"YES",1:"NO") }

 }, SqlComputed, SqlFieldName = IS_UPDATABLE ];

/// Name of the ODBC type for this column.
Property DATATYPE As %String(MAXLEN = 128) [ SqlColumnNumber = 24, SqlFieldName = DATA_TYPE ];

/// Number of the ODBC type for this column.
Property odbctype As %Integer [ Internal, SqlColumnNumber = 50 ];

/// Column's maximum length, in characters, for binary or character data.
Property CHARACTERMAXIMUMLENGTH As %Integer [ Calculated, SqlColumnNumber = 25, SqlComputeCode = { if $case({odbctype},-4:1,-3:1,-1:1,12:1,:0) { set {*}=$lg(^oddSQL({SchemaExact},{TableExact},8,{ORDINAL_POSITION}),8) set:({*}=-1)||({*}=$c(2)) {*}=$$$ODBCVarcharMaxlen} else { set {*}="" }}, SqlComputed, SqlFieldName = CHARACTER_MAXIMUM_LENGTH ];

/// Column's maximum length, in bytes, for binary or character data.  For InterSystems IRIS this is the same as CHARACTER_MAXIMUM_LENGTH.
Property CHARACTEROCTETLENGTH As %Integer [ Calculated, SqlColumnNumber = 26, SqlComputeCode = { if $case({odbctype},-4:1,-3:1,-1:1,12:1,:0) { set {*}=$lg(^oddSQL({SchemaExact},{TableExact},8,{ORDINAL_POSITION}),8) set:({*}=-1)||({*}=$c(2)) {*}=$$$ODBCVarcharMaxlen} else { set {*}="" }}, SqlComputed, SqlFieldName = CHARACTER_OCTET_LENGTH ];

/// Column's precision for fields of datatype TINYINT, SMALLINT, INTEGER, BIGINT, NUMERIC, and DOUBLE. Otherwise, NULL is returned.
Property NUMERICPRECISION As %Library.TinyInt [ Calculated, SqlColumnNumber = 27, SqlComputeCode = { if $case({odbctype},-6:1,-5:1,2:1,4:1,5:1,8:1,:0) { set {*}=$lg(^oddSQL({SchemaExact},{TableExact},8,{ORDINAL_POSITION}),7) } else { set {*}="" }}, SqlComputed, SqlFieldName = NUMERIC_PRECISION ];

/// Column's precision radix for fields of datatype TINYINT, SMALLINT, INTEGER, BIGINT, NUMERIC, and DOUBLE. Otherwise, NULL is returned.
Property NUMERICPRECISIONRADIX As %Library.SmallInt [ Calculated, SqlColumnNumber = 28, SqlComputeCode = { if $case({odbctype},-6:1,-5:1,2:1,4:1,5:1,8:1,:0) { set {*}=$lg(^oddSQL({SchemaExact},{TableExact},8,{ORDINAL_POSITION}),10) } else { set {*}="" }}, SqlComputed, SqlFieldName = NUMERIC_PRECISION_RADIX ];

/// Column's numeric scale for fields of datatype TINYINT, SMALLINT, INTEGER, BIGINT, NUMERIC, and DOUBLE. Otherwise, NULL is returned.
Property NUMERICSCALE As %Integer [ Calculated, SqlColumnNumber = 29, SqlComputeCode = { if $case({odbctype},-6:1,-5:1,2:1,4:1,5:1,8:1,:0) { set {*}=$lg(^oddSQL({SchemaExact},{TableExact},8,{ORDINAL_POSITION}),9) } else { set {*}="" }}, SqlComputed, SqlFieldName = NUMERIC_SCALE ];

/// Reserved for future use.  For InterSystems IRIS DATETIME_PRECISION is always NULL.
Property DATETIMEPRECISION As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 30, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = DATETIME_PRECISION ];

/// Reserved for future use.  For InterSystems IRIS CHARACTER_SET_CATALOG is always NULL.
Property CHARACTERSETCATALOG As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 31, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = CHARACTER_SET_CATALOG ];

/// Reserved for future use.  For InterSystems IRIS CHARACTER_SET_SCHEMA is always NULL.
Property CHARACTERSETSCHEMA As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 32, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = CHARACTER_SET_SCHEMA ];

/// Reserved for future use.  For InterSystems IRIS CHARACTER_SET_NAME is always NULL.
Property CHARACTERSETNAME As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 33, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = CHARACTER_SET_NAME ];

/// Reserved for future use.  For InterSystems IRIS COLLATION_CATALOG is always NULL.
Property COLLATIONCATALOG As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 34, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = COLLATION_CATALOG ];

/// Reserved for future use.  For InterSystems IRIS COLLATION_SCHEMA is always NULL.
Property COLLATIONSCHEMA As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 35, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = COLLATION_SCHEMA ];

/// Reserved for future use.  For InterSystems IRIS COLLATION_NAME is always NULL.
Property COLLATIONNAME As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 36, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = COLLATION_NAME ];

/// Description of the column from the class definition.  Returns NULL if the column is not from a table.
Property DESCRIPTION As %String(MAXLEN = 8192) [ Calculated, SqlColumnNumber = 37, SqlComputeCode = { 
	new tType set tType=$lg(^oddSQL({SchemaExact},{TableExact}),4)
	set {*}=""
	if tType["TABLE" {
		new tExtent,tProperty
		set tExtent=$lg($g(^rINDEXSQL("rv",$zconvert({TABLE_SCHEMA},"u"),$zconvert({TABLE_NAME},"u"))),2) QUIT:tExtent=""
		set tProperty=$lg($g(^oddEXTR(tExtent,"b",{COLUMN_NAME},91)),28) QUIT:tProperty=""
		set {*}=$s($d(^oddCOM(tExtent,"a",tProperty,4))#2:^(4),$d(^oddCOM($g(^(2),tExtent),"a",tProperty,4))#2:^(4),1:$s($d(^oddDEF($g(^oddCOM(tExtent,"a",tProperty,2),tExtent),"a",tProperty,4))#2:^(4),1:""))
	}
	}, SqlComputed, SqlFieldName = DESCRIPTION ];

/// If this column increments automatically upon insert, AUTO_INCREMENT returns YES, otherwise NO.
Property AUTOINCREMENT As %String(MAXLEN = 3, VALUELIST = ",YES,NO") [ SqlColumnNumber = 38, SqlFieldName = AUTO_INCREMENT ];

/// If this column in the sole column in a unique constraint, UNIQUE_COLUMN returns YES, otherwise NO.
Property UNIQUECOLUMN As %String(MAXLEN = 3, VALUELIST = ",YES,NO") [ SqlColumnNumber = 39, SqlFieldName = UNIQUE_COLUMN ];

/// If this column appears in the primary key constraint for this table, PRIMARY_KEY returns YES, otherwise NO.
Property PRIMARYKEY As %String(MAXLEN = 3, VALUELIST = ",YES,NO") [ SqlColumnNumber = 40, SqlFieldName = PRIMARY_KEY ];

/// The class property name projected to this column
Property PROPERTYNAME As %String(MAXLEN = 128) [ Calculated, Private, SqlColumnNumber = 41, SqlComputeCode = { set {*} = $$$SQLLocColPropertyName($$$EXTSQLCOLsqlinfo($$$rEXT,$$$GetExtentNameFromTableName({TABLE_SCHEMA},{TABLE_NAME}),{COLUMN_NAME})) }, SqlComputed, SqlFieldName = PROPERTY_NAME ];

/// The SqlComputeCode for this column
Property COMPUTECODE As %String(MAXLEN = 3200) [ Calculated, Private, SqlColumnNumber = 42, SqlComputeCode = { new c set c = $$$GetClassNameFromTableName({TABLE_SCHEMA},{TABLE_NAME}), {*} = $$$defMemberKeyGet(c,$$$cCLASSproperty,{PROPERTY_NAME},$$$cPROPsqlcomputecode) }, SqlComputed, SqlFieldName = COMPUTE_CODE ];

/// This field expresses whether the column's value is actually persisted, meaning nor calculated nor transient
Property ISPERSISTED As %String(MAXLEN = 3) [ Calculated, Private, SqlColumnNumber = 43, SqlComputeCode = { new c set c = $$$GetClassNameFromTableName({TABLE_SCHEMA},{TABLE_NAME}), {*} = $s($$$defMemberKeyGet(c,$$$cCLASSproperty,{PROPERTY_NAME},$$$cPROPtransient):"NO", $$$defMemberKeyGet(c,$$$cCLASSproperty,{PROPERTY_NAME},$$$cPROPcalculated):"NO", 1:"YES") }, SqlComputed, SqlFieldName = IS_PERSISTED ];

Storage SQLStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Data name="AUTO_INCREMENT">
<Piece>23</Piece>
</Data>
<Data name="COLUMN_DEFAULT">
<Piece>13</Piece>
</Data>
<Data name="COLUMN_NAME">
<Piece>4</Piece>
</Data>
<Data name="DATA_TYPE">
<RetrievalCode> set {*}=$zcvt($lg({%row},6),"L")</RetrievalCode>
</Data>
<Data name="IS_GENERATED">
<Piece>24</Piece>
</Data>
<Data name="IS_IDENTITY">
<Piece>25</Piece>
</Data>
<Data name="IS_NULLABLE">
<Piece>18</Piece>
</Data>
<Data name="PRIMARY_KEY">
<Piece>27</Piece>
</Data>
<Data name="TABLE_NAME">
<Piece>3</Piece>
</Data>
<Data name="TABLE_SCHEMA">
<Piece>2</Piece>
</Data>
<Data name="UNIQUE_COLUMN">
<Piece>26</Piece>
</Data>
<Data name="odbctype">
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
<Expression>8</Expression>
</Subscript>
<Subscript name="4">
<Expression>{ORDINAL_POSITION}</Expression>
<Invalidcondition name="1">
<Expression>
<![CDATA['$$AnyPrivTable^%SYS.SQLSEC($li(^oddSQL({L1},{L2}),6),0)&&('$$AnyPrivField^%SYS.SQLSEC($li({3D},6),$li(^oddSQL({L1},{L2},8,{L4}),4),0))]]></Expression>
</Invalidcondition>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^INFORMATION.SCHEMA.TABLESS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

