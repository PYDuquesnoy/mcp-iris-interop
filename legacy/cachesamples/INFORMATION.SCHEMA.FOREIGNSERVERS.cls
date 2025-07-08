/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This table has one row for each Foreign Server the users is privileged for in the current namespace
Class INFORMATION.SCHEMA.FOREIGNSERVERS Extends %Library.Persistent [ ClassType = persistent, Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = FOREIGN_SERVERS, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

Index IDKeyIndex On (ServerSchemaId, ServerNameId) [ IdKey, Internal, Unique ];

Property ServerSchema As %String(COLLATION = "UPPER", MAXLEN = 128) [ Required, SqlColumnNumber = 2, SqlFieldName = SERVER_SCHEMA ];

Property ServerName As %String(COLLATION = "UPPER", MAXLEN = 128) [ Required, SqlColumnNumber = 3, SqlFieldName = SERVER_NAME ];

Property ServerSchemaId As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 10, SqlFieldName = SERVER_SCHEMA_ID ];

Property ServerNameId As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 11, SqlFieldName = SERVER_NAME_ID ];

Property ClassName As %String(MAXLEN = 256) [ Required, SqlColumnNumber = 4, SqlFieldName = CLASSNAME ];

Property ForeignDataWrapper As %String(MAXLEN = 256) [ Calculated, SqlColumnNumber = 5, SqlComputeCode = { set {*} = $$$FTFDWFromFSClass({CLASSNAME}) }, SqlComputed, SqlFieldName = FOREIGN_DATA_WRAPPER ];

Property ParameterString As %String(MAXLEN = 3200) [ Calculated, SqlColumnNumber = 6, SqlComputeCode = { new p,l  set (l,p)=""  for { set p = $$$defMemberNext({CLASSNAME},$$$cCLASSparameter,p)  quit:p=""  continue:p="FDWNAME"  set l = l _ ", " _ p _ "=""" _ $$$defMemberKeyGet({CLASSNAME},$$$cCLASSparameter,p,$$$cPARAMdefault) _ """" }  set {*} = $e(l,3,*) }, SqlComputed, SqlFieldName = PARAMETERS ];

Property Description As %String(MAXLEN = 256) [ Calculated, SqlColumnNumber = 7, SqlComputeCode = { set {*} = $$$defClassKeyGet({CLASSNAME},$$$cCLASSdescription)}, SqlComputed, SqlFieldName = DESCRIPTION ];

Property Owner As %String(MAXLEN = 256) [ Calculated, SqlColumnNumber = 8, SqlComputeCode = { set {*} = $$$defClassKeyGet({CLASSNAME},$$$cCLASSowner)}, SqlComputed, SqlFieldName = OWNER ];

Storage SQLStorage
{
<SQLMap name="Master">
<Data name="CLASSNAME">
<Piece>1</Piece>
</Data>
<Data name="SERVER_NAME">
<RetrievalCode>set {*} = {L3}</RetrievalCode>
</Data>
<Data name="SERVER_SCHEMA">
<RetrievalCode>set {*} = {L2}</RetrievalCode>
</Data>
<Global>^rINDEXSQL</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Accessvar name="1">
<Code> s {1D1}=0 </Code>
<Variable>{1D1}</Variable>
</Accessvar>
<Expression>"SERVER"</Expression>
</Subscript>
<Subscript name="2">
<Expression>{SERVER_SCHEMA_ID}</Expression>
<NextCode>if '{1D1} do updateForeignServerIndex^%SYS.SQLSEC() set {1D1}=1 GOTO NEXT
        set {L2} = $$GetNextSubscript^%SYS.SQLSEC("^rINDEXSQL(""SERVER"")", {L2})</NextCode>
</Subscript>
<Subscript name="3">
<Expression>{SERVER_NAME_ID}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^INFORMATION862B.FOREIGNSERVERSS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

