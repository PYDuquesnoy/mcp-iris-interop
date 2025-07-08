/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Returns one row for each stored procedure and function that can be accessed by the current user in the current namespace.
Class INFORMATION.SCHEMA.ROUTINES Extends %Library.Persistent [ ClassType = persistent, Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = ROUTINES, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

Index IDKeyIndex On (SchemaUpper, TableUpper) [ IdKey, Internal, Unique ];

Property SchemaUpper As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 60 ];

Property TableUpper As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 61 ];

/// Is the table a system routine (1 or 0)
Property SystemRoutine As %Boolean [ Calculated, Internal, Private, Required, SqlColumnNumber = 62, SqlComputeCode = { set {*}=$s($e({ROUTINE_SCHEMA})="%"||({ROUTINE_SCHEMA}="INFORMATION_SCHEMA"):1,1:0) }, SqlComputed ];

/// Is the routine an Extent Query(1 or 0)
Property ExtentQuery As %Boolean [ Calculated, Internal, Private, Required, SqlColumnNumber = 63, SqlComputeCode = { set {*}=$s($$$PROCprocedure($$$pPROC,{SchemaUpper},{TableUpper})="Extent":1,1:0) }, SqlComputed ];

/// Reserved for future use.  Specific qualifier - always NULL in InterSystems IRIS.
Property SPECIFICCATALOG As %String(MAXLEN = 128) [ Calculated, SqlColumnNumber = 2, SqlComputeCode = { set {*}=""}, SqlComputed, SqlFieldName = SPECIFIC_CATALOG ];

/// Name of schema that contains the routine.
Property SPECIFICSCHEMA As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 3, SqlFieldName = SPECIFIC_SCHEMA ];

/// Specific name.
Property SPECIFICNAME As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 4, SqlFieldName = SPECIFIC_NAME ];

/// Reserved for future use.  Routine qualifier - always NULL in InterSystems IRIS.
Property ROUTINECATALOG As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 5, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = ROUTINE_CATALOG ];

/// Name of schema that contains the routine, same as SPECIFIC_SCHEMA.
Property ROUTINESCHEMA As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 6, SqlFieldName = ROUTINE_SCHEMA ];

/// Routine name, same as SPECIFIC_NAME.
Property ROUTINENAME As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 7, SqlFieldName = ROUTINE_NAME ];

/// Reserved for future use.  For InterSystems IRIS, MODULE_CATALOG is always NULL.
Property MODULECATALOG As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 8, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = MODULE_CATALOG ];

/// Reserved for future use.  For InterSystems IRIS, MODULE_SCHEMA is always NULL.
Property MODULESCHEMA As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 9, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = MODULE_SCHEMA ];

/// Reserved for future use.  For InterSystems IRIS, MODULE_NAME is always NULL.
Property MODULENAME As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 10, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = MODULE_NAME ];

/// Reserved for future use.  For InterSystems IRIS, USER_DEFINED_TYPE_CATALOG is always NULL.
Property USERDEFINEDTYPECATALOG As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 11, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = USER_DEFINED_TYPE_CATALOG ];

/// Reserved for future use.  For InterSystems IRIS, USER_DEFINED_TYPE_SCHEMA is always NULL.
Property USERDEFINEDTYPESCHEMA As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 12, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = USER_DEFINED_TYPE_SCHEMA ];

/// Reserved for future use.  For InterSystems IRIS, USER_DEFINED_TYPE_NAME is always NULL.
Property USERDEFINEDTYPENAME As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 13, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = USER_DEFINED_TYPE_NAME ];

/// The values of ROUTINE_TYPE have the following meanings:
/// <br><ul>
/// 	<li>PROCEDURE - The SQL-invoked routine is a query projected as a procedure.</li>
/// 	<li>FUNCTION - The SQL-invoked routine is a function (method) projected as a procedure.</li>
/// </ul>
Property ROUTINETYPE As %String(MAXLEN = 9, VALUELIST = ",PROCEDURE,FUNCTION") [ SqlColumnNumber = 14, SqlFieldName = ROUTINE_TYPE ];

/// Reserved for future use.  For InterSystems IRIS, DTD_IDENTIFIER is always NULL.
Property DTDIDENTIFIER As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 15, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = DTD_IDENTIFIER ];

/// The values of ROUTINE_BODY have the following meanings:
/// <br><ul>
/// 	<li>SQL - Means this routine is a class query with language SQL.</li>
/// 	<li>EXTERNAL - Means this is not a class query with language SQL.</li>
/// </ul>
Property ROUTINEBODY As %String(MAXLEN = 8, VALUELIST = ",SQL,EXTERNAL") [ Calculated, SqlColumnNumber = 16, SqlComputeCode = { 
	if {ROUTINE_TYPE}="FUNCTION" { set {*}="EXTERNAL" quit  }
	new tClass,tQuery,tSQL
	set tClass=$li($g(^oddPROC($$$UPPER({ROUTINE_SCHEMA}),$$$UPPER({ROUTINE_NAME}),21)),1)
	set tQuery=$li($g(^oddPROC($$$UPPER({ROUTINE_SCHEMA}),$$$UPPER({ROUTINE_NAME}),21)),2)
	set tSQL=$$$comMemberKeyGet(tClass,$$$cCLASSquery,tQuery,$$$cQUERYsqlquery)
	set {*}=$s(tSQL'="":"SQL",1:"EXTERNAL")
	}, SqlComputed, SqlFieldName = ROUTINE_BODY ];

/// /// The routine's query expression.  If longer than 8192 characters, or the routine is not an SQL class query, NULL is returned.
Property ROUTINEDEFINITION As %String(MAXLEN = 8192) [ Calculated, SqlColumnNumber = 17, SqlComputeCode = { 
	new tClass,tQuery
	set tClass=$li($g(^oddPROC($$$UPPER({ROUTINE_SCHEMA}),$$$UPPER({ROUTINE_NAME}),21)),1)
	set tQuery=$li($g(^oddPROC($$$UPPER({ROUTINE_SCHEMA}),$$$UPPER({ROUTINE_NAME}),21)),2)	// Query or method
	if {ROUTINE_TYPE}="FUNCTION" {
		new i,code set code=""
		for i=1:1:$$$defMemberKeyGet(tClass,$$$cCLASSmethod,tQuery,$$$cMETHimplementation) { set code=code_$$$NL_$$$defMemberArrayGet(tClass,$$$cCLASSmethod,tQuery,$$$cMETHimplementation,i) }
		set {*}=$e(code,$l($$$NL+1),8192)
		QUIT
	}
	new tSQL
	set tSQL=$$$comMemberKeyGet(tClass,$$$cCLASSquery,tQuery,$$$cQUERYsqlquery)
	set {*}=$s($l(tSQL)<8193:tSQL,1:$e(tSQL,1,8192))
	}, SqlComputed, SqlFieldName = ROUTINE_DEFINITION ];

/// Reserved for future use.  For InterSystems IRIS, EXTERNAL_NAME is always NULL.
Property EXTERNALNAME As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 18, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = EXTERNAL_NAME ];

/// Reserved for future use.  For InterSystems IRIS, EXTERNAL_LANGUAGE is always NULL.
Property EXTERNALLANGUAGE As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 19, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = EXTERNAL_LANGUAGE ];

/// Reserved for future use.  For InterSystems IRIS, PARAMETER_STYLE is always NULL.
Property PARAMETERSTYLE As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 20, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = PARAMETER_STYLE ];

/// Reserved for future use.  For InterSystems IRIS, IS_DETERMINISTIC is always NULL.
Property ISDETERMINISTIC As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 21, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = IS_DETERMINISTIC ];

/// SQL_DATA_ACCESS Returns one of the following values:
/// <br><ul>
/// 	<li>NO SQL = Function does not contain SQL.</li>
/// 	<li>CONTAINS SQL = Function possibly contains SQL.</li>
/// 	<li>READS SQL DATA = Function possibly reads SQL data.</li>
/// 	<li>MODIFIES SQL DATA = Function possibly modifies SQL data.</li>
/// </ul>
/// 	Returns CONTAINS SQL for all functions, and READS SQL DATA for all class query procedure.
Property SQLDATAACCESS As %String(MAXLEN = 17, VALUELIST = ",NO SQL,CONTAINS SQL,READS SQL DATA,MODIFIES SQL DATA") [ Calculated, SqlColumnNumber = 22, SqlComputeCode = { 
	if {ROUTINE_BODY}="SQL" { set {*}="READS SQL DATA" }
	else { set {*}="CONTAINS SQL" }
	}, SqlComputed, SqlFieldName = SQL_DATA_ACCESS ];

/// The values of IS_NULL_CALL have the following meanings:
/// <br><ul>
/// 	<li>YES - The routine is a function and returns null if any of its parameters are null.</li>
/// 	<li>NO - The routine is a function and its return value is determined by invoking the routine.</li>
/// 	<li>null - The routine being described is a class query procedure.</li>
/// </ul>
/// For InterSystems IRIS, if the routine is a function IS_NULL_CALL is always NO.
Property ISNULLCALL As %String(MAXLEN = 3, VALUELIST = ",YES,NO") [ Calculated, SqlColumnNumber = 23, SqlComputeCode = { set {*}=$s({ROUTINE_BODY}="SQL":"",1:"NO") }, SqlComputed, SqlFieldName = IS_NULL_CALL ];

/// Reserved for future use.  For InterSystems IRIS, SQL_PATH is always NULL.
Property SQLPATH As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 24, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = SQL_PATH ];

/// The values of SCHEMA_LEVEL_ROUTINE have the following meanings:
/// <br><ul>
/// 	<li>YES - If the routine is a schema-level routine.</li>
/// 	<li>NO - If the routine is not a schema-level routine.</li>
/// </ul>
/// For InterSystems IRIS, SCHEMA_LEVEL_ROUTINE is always YES.
Property SCHEMALEVELROUTINE As %String(MAXLEN = 3, VALUELIST = ",YES,NO") [ Calculated, Required, SqlColumnNumber = 25, SqlComputeCode = { set {*}="YES" }, SqlComputed, SqlFieldName = SCHEMA_LEVEL_ROUTINE ];

/// Reserved for future use.  For InterSystems IRIS, MAX_DYNAMIC_RESULT_SETS is always NULL.
Property MAXDYNAMICRESULTSETS As %SmallInt [ Calculated, SqlColumnNumber = 26, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = MAX_DYNAMIC_RESULT_SETS ];

/// The values of IS_USER_DEFINED_CAST have the following meanings:
/// <br><ul>
/// 	<li>YES - The routine is a function that is a user-defined cast function.</li>
/// 	<li>NO - The routine is a function that is not a user-defined cast function.</li>
/// 	<li>null - The routine being described is a class query procedure.</li>
/// </ul>
/// For InterSystems IRIS, if the routine is a function IS_USER_DEFINED_CAST is always NO.
Property ISUSERDEFINEDCAST As %String(MAXLEN = 3, VALUELIST = ",YES,NO") [ Calculated, SqlColumnNumber = 27, SqlComputeCode = { set {*}=$s({ROUTINE_BODY}="SQL":"",1:"NO") }, SqlComputed, SqlFieldName = IS_USER_DEFINED_CAST ];

/// The values of IS_IMPLICITLY_INVOCABLE have the following meanings:
/// <br><ul>
/// 	<li>YES - The user-defined cast function is implicitly invocable.</li>
/// 	<li>NO - The user-defined cast function is not implicitly invocable.</li>
/// 	<li>null - The routine is not a user-defined cast function.</li>
/// </ul>
/// Reserved for future use.  For InterSystems IRIS, IS_IMPLICITLY_INVOCABLE is always null.
Property ISIMPLICITLYINVOCABLE As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 28, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = IS_IMPLICITLY_INVOCABLE ];

/// The values of SECURITY_TYPE have the following meanings:
/// <br><ul>
/// 	<li>DEFINER - The routine has the security characteristic DEFINER.</li>
/// 	<li>INVOKER - The routine has the security characteristic INVOKER.</li>
/// 	<li>IMPLEMENTATION DEFINED - The external routine has the security characteristic IMPLEMENTATION DEFINED.</li>
/// 	<li>null - Unknown security type.</li>
/// </ul>
/// For InterSystems IRIS, SECURITY_TYPE is always null.
Property SECURITYTYPE As %String(MAXLEN = 22, VALUELIST = ",DEFINER,INVOKER,IMPLEMENTATION DEFINED") [ Calculated, SqlColumnNumber = 29, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = SECURITY_TYPE ];

/// Reserved for future use.  For InterSystems IRIS, TO_SQL_SPECIFIC_CATALOG is always NULL.
Property TOSQLSPECIFICCATALOG As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 30, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = TO_SQL_SPECIFIC_CATALOG ];

/// Reserved for future use.  For InterSystems IRIS, TO_SQL_SPECIFIC_SCHEMA is always NULL.
Property TOSQLSPECIFICSCHEMA As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 31, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = TO_SQL_SPECIFIC_SCHEMA ];

/// Reserved for future use.  For InterSystems IRIS, TO_SQL_SPECIFIC_NAME is always NULL.
Property TOSQLSPECIFICNAME As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 32, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = TO_SQL_SPECIFIC_NAME ];

/// Returns YES or NO based on if the return value of the function is a LOB oref value and not the actual data value of the LOB.
/// <br>AS_LOCATOR have the following meanings:
/// <br><ul>
/// 	<li>YES - The return value of the routine being described is an stream oref.</li>
/// 	<li>NO - The return value of the routine being described is not an stream oref.</li>
/// 	<li>null - The routine is a class query procedure.</li>
/// </ul>
/// For InterSystems IRIS, AS_LOCATOR is always null unless the return value is a stream, then it is YES.
Property ASLOCATOR As %String(MAXLEN = 3, VALUELIST = ",YES,NO") [ Calculated, SqlColumnNumber = 33, SqlComputeCode = { 
	set {*}=""
	new i,tColumns,tSchema,tName
	set tSchema=$$$UPPER({ROUTINE_SCHEMA}),tName=$$$UPPER({ROUTINE_NAME})
	If $d($$$PROCcolumn($$$pPROC,tSchema,tName),tColumns) {
		for i=1:1:tColumns {
			if $$$PROCCOLtype($$$pPROC,tSchema,tName,i)=5 { set {*}=$case($$$PROCCOLodbctype($$$pPROC,tSchema,tName,i),-4:"YES",-1:"YES",:"") quit  }
		}
	}
	}, SqlComputed, SqlFieldName = AS_LOCATOR ];

/// For InterSystems IRIS, CREATED is always NULL.
Property CREATED As %TimeStamp [ Calculated, SqlColumnNumber = 34, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = CREATED ];

/// For InterSystems IRIS, LAST_ALTERED is always NULL.
Property LASTALTERED As %TimeStamp [ Calculated, SqlColumnNumber = 35, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = LAST_ALTERED ];

/// Reserved for future use.  For InterSystems IRIS, NEW_SAVEPOINT_LEVEL is always NULL.
Property NEWSAVEPOINTLEVEL As %String(MAXLEN = 3, VALUELIST = ",YES,NO") [ Calculated, SqlColumnNumber = 36, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = NEW_SAVEPOINT_LEVEL ];

/// Reserved for future use.  For InterSystems IRIS, IS_UDT_DEPENDENT is always NULL.
Property ISUDTDEPENDENT As %String(MAXLEN = 3, VALUELIST = ",YES,NO") [ Calculated, SqlColumnNumber = 37, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = IS_UDT_DEPENDENT ];

/// Reserved for future use.  For InterSystems IRIS, RESULT_CAST_FROM_DTD_IDENTIFIER is always NULL.
Property RESULTCASTFROMDTDIDENTIFIER As %String(MAXLEN = 3) [ Calculated, SqlColumnNumber = 38, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = RESULT_CAST_FROM_DTD_IDENTIFIER ];

/// Reserved for future use.  For InterSystems IRIS, RESULT_CAST_AS_LOCATOR is always NULL.
Property RESULTCASTASLOCATOR As %String(MAXLEN = 3, VALUELIST = ",YES,NO") [ Calculated, SqlColumnNumber = 39, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = RESULT_CAST_AS_LOCATOR ];

/// Data type of the return value of the function.  Returns null if the procedure has no return value.
Property DATATYPE As %String(MAXLEN = 30) [ Calculated, SqlColumnNumber = 40, SqlComputeCode = { 
	set {*}=""
	new i,tColumns,tSchema,tName
	set tSchema=$$$UPPER({ROUTINE_SCHEMA}),tName=$$$UPPER({ROUTINE_NAME})
	If $d($$$PROCcolumn($$$pPROC,tSchema,tName),tColumns) {
		for i=1:1:tColumns {
			if $$$PROCCOLtype($$$pPROC,tSchema,tName,i)=5 { set {*}=$zcvt($g($$$PROCCOLodbctypename($$$pPROC,tSchema,tName,i)),"L") quit  }
		}
	}
	}, SqlComputed, SqlFieldName = DATA_TYPE ];

/// Maximum length in characters, if the return type is a character type.  If not a character type, returns null.
Property CHARACTERMAXIMUMLENGTH As %Integer [ Calculated, SqlColumnNumber = 41, SqlComputeCode = { 
	set {*}=""
	new i,tColumns,tSchema,tName
	set tSchema=$$$UPPER({ROUTINE_SCHEMA}),tName=$$$UPPER({ROUTINE_NAME})
	If $d($$$PROCcolumn($$$pPROC,tSchema,tName),tColumns) {
		for i=1:1:tColumns {
			if $$$PROCCOLtype($$$pPROC,tSchema,tName,i)=5 { 
				if $$$PROCCOLodbctype($$$pPROC,tSchema,tName,i)=12 set {*}=$g($$$PROCCOLlength($$$pPROC,tSchema,tName,i))
			 	quit
			 }
		}
	}
	}, SqlComputed, SqlFieldName = CHARACTER_MAXIMUM_LENGTH ];

/// Reserved for future use.  For InterSystems IRIS, CHARACTER_OCTET_LENGTH is always NULL.
Property CHARACTEROCTETLENGTH As %Integer [ Calculated, SqlColumnNumber = 42, SqlComputeCode = { set {*}="" }, SqlComputed, SqlFieldName = CHARACTER_OCTET_LENGTH ];

/// Numeric precision of the return value. For the nonnumeric types, returns NULL.
Property NUMERICPRECISION As %SmallInt [ Calculated, SqlColumnNumber = 43, SqlComputeCode = { 
	set {*}=""
	new i,tColumns,tSchema,tName
	set tSchema=$$$UPPER({ROUTINE_SCHEMA}),tName=$$$UPPER({ROUTINE_NAME})
	If $d($$$PROCcolumn($$$pPROC,tSchema,tName),tColumns) {
		for i=1:1:tColumns {
			if $$$PROCCOLtype($$$pPROC,tSchema,tName,i)=5 { 
				if $case($$$PROCCOLodbctype($$$pPROC,tSchema,tName,i),-6:1,-5:1,2:1,4:1,5:1,8:1,:0) set {*}=$g($$$PROCCOLprecision($$$pPROC,tSchema,tName,i))
			 	quit
			 }
		}
	}
	}, SqlComputed, SqlFieldName = NUMERIC_PRECISION ];

/// Numeric precision radix of the return value. For nonnumeric types, returns NULL.
Property NUMERICPRECISIONRADIX As %Integer [ Calculated, SqlColumnNumber = 44, SqlComputeCode = { 
	set {*}=""
	new i,tColumns,tSchema,tName
	set tSchema=$$$UPPER({ROUTINE_SCHEMA}),tName=$$$UPPER({ROUTINE_NAME})
	If $d($$$PROCcolumn($$$pPROC,tSchema,tName),tColumns) {
		for i=1:1:tColumns {
			if $$$PROCCOLtype($$$pPROC,tSchema,tName,i)=5 { 
				if $case($$$PROCCOLodbctype($$$pPROC,tSchema,tName,i),-6:1,-5:1,2:1,4:1,5:1,8:1,:0) set {*}=$g($$$PROCCOLradix($$$pPROC,tSchema,tName,i))
			 	quit
			 }
		}
	}
	}, SqlComputed, SqlFieldName = NUMERIC_PRECISION_RADIX ];

/// Scale of the return value. For nonnumeric types, returns NULL.
Property NUMERICSCALE As %Integer [ Calculated, SqlColumnNumber = 45, SqlComputeCode = { 
	set {*}=""
	new i,tColumns,tSchema,tName
	set tSchema=$$$UPPER({ROUTINE_SCHEMA}),tName=$$$UPPER({ROUTINE_NAME})
	If $d($$$PROCcolumn($$$pPROC,tSchema,tName),tColumns) {
		for i=1:1:tColumns {
			if $$$PROCCOLtype($$$pPROC,tSchema,tName,i)=5 { 
				if $case($$$PROCCOLodbctype($$$pPROC,tSchema,tName,i),-6:1,-5:1,2:1,4:1,5:1,8:1,:0) set {*}=$g($$$PROCCOLscale($$$pPROC,tSchema,tName,i))
			 	quit
			 }
		}
	}
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

/// Name of the class that projected the Stored Procedure
Property Classname As %String(MAXLEN = 255) [ SqlColumnNumber = 53, SqlFieldName = CLASSNAME ];

/// Name of the class method or class query that projected this procedure
Property MethodQueryName As %String(MAXLEN = 255) [ SqlColumnNumber = 54, SqlFieldName = METHOD_OR_QUERY_NAME ];

Storage SQLStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Data name="Classname">
<Node>1</Node>
</Data>
<Data name="METHOD_OR_QUERY_NAME">
<Node>14</Node>
</Data>
<Data name="ROUTINE_NAME">
<Node>10</Node>
</Data>
<Data name="ROUTINE_SCHEMA">
<Node>20</Node>
</Data>
<Data name="ROUTINE_TYPE">
<RetrievalCode> set {*}=$case($g(^oddPROC({L1},{L2},22)),"query":"PROCEDURE","function":"FUNCTION",:"")</RetrievalCode>
</Data>
<Data name="SPECIFIC_NAME">
<Node>10</Node>
</Data>
<Data name="SPECIFIC_SCHEMA">
<Node>20</Node>
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
<Expression>$g(^oddPROC({L1},{L2},5))</Expression>
</Invalidcondition>
<Invalidcondition name="2">
<Expression>'$$ExecutePriv^%SYS.SQLSEC("9,"_$g(^oddPROC({L1},{L2},20))_"."_$tr($g(^oddPROC({L1},{L2},10)),".",$c(2)))</Expression>
</Invalidcondition>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^INFORMATION.SCHEMA.ROUTINESS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

