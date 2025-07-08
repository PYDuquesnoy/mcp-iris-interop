/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The PARAMETERS table has one row for each SQL parameter of each SQL-invoked routine (procedure) described in the ROUTINES base table for which the current user has privileges for.
/// This includes all input, output, input-output, and return values.  It does not include result set columns for any result sets returned by the procedure.
Class INFORMATION.SCHEMA.PARAMETERS Extends %Library.Persistent [ ClassType = persistent, Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = PARAMETERS, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

Index IDKeyIndex On (SchemaUpper, ProcedureUpper, ordpos) [ IdKey, Internal, Unique ];

Index PKeyIndex On (SPECIFICSCHEMA, SPECIFICNAME, ORDINALPOSITION) [ PrimaryKey ];

Property SchemaUpper As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 60 ];

Property ProcedureUpper As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 61 ];

/// Is the table a system routine (1 or 0)
Property SystemRoutine As %Integer [ Calculated, Internal, Private, Required, SqlColumnNumber = 62, SqlComputeCode = { set {*}=$s($e({SPECIFIC_SCHEMA})="%"||({SPECIFIC_SCHEMA}="INFORMATION_SCHEMA"):1,1:0) }, SqlComputed ];

/// Reserved for future use.  Specific qualifier - always NULL in InterSystems IRIS.
Property SPECIFICCATALOG As %String(MAXLEN = 128) [ Calculated, SqlColumnNumber = 2, SqlComputeCode = { set {*}=""}, SqlComputed, SqlFieldName = SPECIFIC_CATALOG ];

/// Name of schema that contains the routine.
Property SPECIFICSCHEMA As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 3, SqlFieldName = SPECIFIC_SCHEMA ];

/// Name of the routine (procedure).
Property SPECIFICNAME As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 4, SqlFieldName = SPECIFIC_NAME ];

/// Parameter's ordinal position within the procedure method or query, starting with 1.  For the return value of a method/function, this is 0.
Property ORDINALPOSITION As %Integer [ Required, SqlColumnNumber = 5, SqlFieldName = ORDINAL_POSITION ];

/// Reserved for future use.  For InterSystems IRIS DTD_IDENTIFIER is always NULL.
Property DTDIDENTIFIER As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 6, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = DTD_IDENTIFIER ];

/// The values of PARAMETER_MODE have the following meanings:
/// <br><ul>
/// 	<li>IN - The SQL parameter being described is an input parameter.</li>
/// 	<li>OUT - The SQL parameter being described is an output parameter.</li>
/// 	<li>INOUT - he SQL parameter being described is an input parameter and an output parameter.</li>
/// </ul>
Property PARAMETERMODE As %String(MAXLEN = 5, VALUELIST = ",IN,OUT,INOUT") [ Required, SqlColumnNumber = 7, SqlFieldName = PARAMETER_MODE ];

/// The values of IS_RESULT have the following meanings:
/// <br><ul>
/// 	<li>YES - The parameter is the return result of a function.</li>
/// 	<li>NO - The parameter is not the return result of a function.</li>
/// </ul>
Property ISRESULT As %String(MAXLEN = 5, VALUELIST = ",YES,NO") [ Required, SqlColumnNumber = 8, SqlFieldName = IS_RESULT ];

/// Returns YES or NO based on if the parameter is a LOB oref value and not the actual data value of the LOB.
/// <br>AS_LOCATOR have the following meanings:
/// <br><ul>
/// 	<li>YES - The parameter being described is an stream oref.</li>
/// 	<li>NO - The parameter being described is not an stream oref.</li>
/// </ul>
/// For InterSystems IRIS, AS_LOCATOR is always null unless the return value is a stream, then it is YES.
Property ASLOCATOR As %String(MAXLEN = 3, VALUELIST = ",YES,NO") [ SqlColumnNumber = 9, SqlFieldName = AS_LOCATOR ];

/// Name of the parameter.
Property PARAMETERNAME As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 10, SqlFieldName = PARAMETER_NAME ];

/// Reserved for future use.  Always NULL in InterSystems IRIS.
Property FROMSQLSPECIFICCATALOG As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 11, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = FROM_SQL_SPECIFIC_CATALOG ];

/// Reserved for future use.  Always NULL in InterSystems IRIS.
Property FROMSQLSPECIFICSCHEMA As %String(MAXLEN = 3) [ Calculated, Required, SqlColumnNumber = 12, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = FROM_SQL_SPECIFIC_SCHEMA ];

/// Reserved for future use.  Always NULL in InterSystems IRIS.
Property FROMSQLSPECIFICNAME As %String(MAXLEN = 3) [ Calculated, Required, SqlColumnNumber = 13, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = FROM_SQL_SPECIFIC_NAME ];

/// Reserved for future use.  Always NULL in InterSystems IRIS.
Property TOSQLSPECIFICCATALOG As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 14, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = TO_SQL_SPECIFIC_CATALOG ];

/// Reserved for future use.  Always NULL in InterSystems IRIS.
Property TOSQLSPECIFICSCHEMA As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 15, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = TO_SQL_SPECIFIC_SCHEMA ];

/// Reserved for future use.  Always NULL in InterSystems IRIS.
Property TOSQLSPECIFICNAME As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 16, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = TO_SQL_SPECIFIC_NAME ];

/// Data type of the parameter
Property DATATYPE As %String(MAXLEN = 30) [ SqlColumnNumber = 17, SqlFieldName = DATA_TYPE ];

/// Maximum length in characters, if the return type is a varchar or varbinary type.  If not a character type, returns null.
Property CHARACTERMAXIMUMLENGTH As %Integer [ Calculated, SqlColumnNumber = 41, SqlComputeCode = {
	set {*}=""
	if $case(^oddPROC({SchemaUpper},{ProcedureUpper},"c",{ordpos},7),12:1,-3:1,:0) set {*}=$g(^oddPROC({SchemaUpper},{ProcedureUpper},"c",{ordpos},4))
	}, SqlComputed, SqlFieldName = CHARACTER_MAXIMUM_LENGTH ];

/// Reserved for future use.  For InterSystems IRIS, CHARACTER_OCTET_LENGTH is always NULL.
Property CHARACTEROCTETLENGTH As %Integer [ Calculated, SqlColumnNumber = 42, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = CHARACTER_OCTET_LENGTH ];

/// Numeric precision of the return value. For the nonnumeric types, returns NULL.
Property NUMERICPRECISION As %SmallInt [ Calculated, SqlColumnNumber = 43, SqlComputeCode = { 
	set {*}=""
	if $case(^oddPROC({SchemaUpper},{ProcedureUpper},"c",{ordpos},7),-6:1,-5:1,2:1,4:1,5:1,8:1,:0) set {*}=$g(^oddPROC({SchemaUpper},{ProcedureUpper},"c",{ordpos},9))
	}, SqlComputed, SqlFieldName = NUMERIC_PRECISION ];

/// Numeric precision radix of the return value. For nonnumeric types, returns NULL.
Property NUMERICPRECISIONRADIX As %Integer [ Calculated, SqlColumnNumber = 44, SqlComputeCode = { 
	set {*}=""
	if $case(^oddPROC({SchemaUpper},{ProcedureUpper},"c",{ordpos},7),-6:1,-5:1,2:1,4:1,5:1,8:1,:0) set {*}=$g(^oddPROC({SchemaUpper},{ProcedureUpper},"c",{ordpos},11))
	}, SqlComputed, SqlFieldName = NUMERIC_PRECISION_RADIX ];

/// Scale of the return value. For nonnumeric types, returns NULL.
Property NUMERICSCALE As %Integer [ Calculated, SqlColumnNumber = 45, SqlComputeCode = { 
	set {*}=""
	if $case(^oddPROC({SchemaUpper},{ProcedureUpper},"c",{ordpos},7),-6:1,-5:1,2:1,4:1,5:1,8:1,:0) set {*}=$g(^oddPROC({SchemaUpper},{ProcedureUpper},"c",{ordpos},13))
	}, SqlComputed, SqlFieldName = NUMERIC_SCALE ];

/// Reserved for future use.  For InterSystems IRIS, DATETIME_PRECISION is always NULL.
Property DATETIMEPRECISION As %Integer [ Calculated, SqlColumnNumber = 46, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = DATETIME_PRECISION ];

/// Reserved for future use.  For InterSystems IRIS, COLLATION_CATALOG is always NULL.
Property COLLATIONCATALOG As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 47, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = COLLATION_CATALOG ];

/// Reserved for future use.  For InterSystems IRIS, COLLATION_SCHEMA is always NULL.
Property COLLATIONSCHEMA As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 48, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = COLLATION_SCHEMA ];

/// Reserved for future use.  For InterSystems IRIS, COLLATION_NAME is always NULL.
Property COLLATIONNAME As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 49, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = COLLATION_NAME ];

/// Reserved for future use.  For InterSystems IRIS, CHARACTER_SET_CATALOG is always NULL.
Property CHARACTERSETCATALOG As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 50, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = CHARACTER_SET_CATALOG ];

/// Reserved for future use.  For InterSystems IRIS, CHARACTER_SET_SCHEMA is always NULL.
Property CHARACTERSETSCHEMA As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 51, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = CHARACTER_SET_SCHEMA ];

/// Reserved for future use.  For InterSystems IRIS, CHARACTER_SET_NAME is always NULL.
Property CHARACTERSETNAME As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 52, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = CHARACTER_SET_NAME ];

/// Parameter's ordinal position within the procedure method or query.
Property ordpos As %Integer [ Internal, Private, Required, SqlColumnNumber = 53, SqlFieldName = ordpos ];

Storage SQLStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Data name="AS_LOCATOR">
<RetrievalCode>set {*}=$case($g(^oddPROC({L1},{L2},"c",{L4},7)),-4:"YES",-1:"YES",:"NO")</RetrievalCode>
</Data>
<Data name="DATA_TYPE">
<RetrievalCode> set {*}=$zcvt($g(^oddPROC({L1},{L2},"c",{L4},8)),"L")</RetrievalCode>
</Data>
<Data name="IS_RESULT">
<RetrievalCode>set {*}=$case($g(^oddPROC({L1},{L2},"c",{L4},14)),5:"YES",:"NO")</RetrievalCode>
</Data>
<Data name="ORDINAL_POSITION">
<RetrievalCode>set {*}=$lg($g(^oddPROC({L1},{L2},"c",{L4},10)),18)</RetrievalCode>
</Data>
<Data name="PARAMETER_MODE">
<RetrievalCode>set {*}=$case($g(^oddPROC({L1},{L2},"c",{L4},14)),1:"IN",4:"INOUT",:"OUT")</RetrievalCode>
</Data>
<Data name="PARAMETER_NAME">
<Node>5</Node>
</Data>
<Data name="SPECIFIC_NAME">
<RetrievalCode>set {*}=$g(^oddPROC({L1},{L2},10))</RetrievalCode>
</Data>
<Data name="SPECIFIC_SCHEMA">
<RetrievalCode>set {*}=$g(^oddPROC({L1},{L2},20))</RetrievalCode>
</Data>
<Global>^oddPROC</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>{SchemaUpper}</Expression>
<NextCode>set {L1} = $$GetNextSubscript^%SYS.SQLSEC("^oddPROC", {L1})</NextCode>
</Subscript>
<Subscript name="2">
<Expression>{ProcedureUpper}</Expression>
<Invalidcondition name="1">
<Expression>$g(^oddPROC({L1},{L2},5))</Expression>
</Invalidcondition>
<Invalidcondition name="2">
<Expression>'$$ExecutePriv^%SYS.SQLSEC("9,"_$g(^oddPROC({L1},{L2},20))_"."_$tr($g(^oddPROC({L1},{L2},10)),".",$c(2)))</Expression>
</Invalidcondition>
</Subscript>
<Subscript name="3">
<Expression>"c"</Expression>
</Subscript>
<Subscript name="4">
<Expression>{ordpos}</Expression>
<Invalidcondition name="1">
<Expression>$g(^oddPROC({L1},{L2},"c",{L4},14))=3</Expression>
</Invalidcondition>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^INFORMATION.SCHEMA.PARAMETERSS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

