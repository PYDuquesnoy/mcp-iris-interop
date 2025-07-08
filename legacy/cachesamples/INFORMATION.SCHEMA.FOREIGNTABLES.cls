/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This table has one row for each Foreign Table the users is privileged for in the current namespace
Class INFORMATION.SCHEMA.FOREIGNTABLES Extends %Library.Persistent [ ClassType = persistent, Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = FOREIGN_TABLES, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

Index IDKeyIndex On (ServerSchemaId, ServerNameId, FullTableExact) [ IdKey, Internal, Unique ];

Property SERVERSCHEMA As %String(COLLATION = "UPPER", MAXLEN = 128) [ Required, SqlColumnNumber = 3, SqlFieldName = SERVER_SCHEMA ];

Property SERVERNAME As %String(COLLATION = "UPPER", MAXLEN = 128) [ Required, SqlColumnNumber = 4, SqlFieldName = SERVER_NAME ];

Property FullTableExact As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 22 ];

/// Name of schema that contains the foreign server for this table
Property ServerSchemaId As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 20 ];

/// Name of the foreign server for this table.
Property ServerNameId As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 21 ];

/// Name of schema that contains the foreign table.
Property TABLESCHEMA As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 5, SqlFieldName = TABLE_SCHEMA ];

/// Name of the foreign table.
Property TABLENAME As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 6, SqlFieldName = TABLE_NAME ];

/// Name of the class that projects this foreign table
Property ClassName As %String(MAXLEN = 256) [ Required, SqlColumnNumber = 7, SqlFieldName = CLASSNAME ];

Property ParameterString As %String(MAXLEN = 3200) [ Calculated, SqlColumnNumber = 8, SqlComputeCode = { new p,l  set (l,p)=""  for { set p = $$$defMemberNext({CLASSNAME},$$$cCLASSparameter,p)  quit:p=""  continue:(p="USING")||(p="NUMFIELDS")||(p="PREDICATEPUSHDOWN")||(p="SERVER")  set l = l _ ", " _ p _ "=""" _ $$$defMemberKeyGet({CLASSNAME},$$$cCLASSparameter,p,$$$cPARAMdefault) _ """" }  set {*} = $e(l,3,*) }, SqlComputed, SqlFieldName = PARAMETERS ];

Property UsingString As %String(MAXLEN = 3200) [ Calculated, SqlColumnNumber = 9, SqlComputeCode = { set {*} = $$$defMemberKeyGet({CLASSNAME},$$$cCLASSparameter,"USING",$$$cPARAMdefault) }, SqlComputed, SqlFieldName = USING ];

Property Description As %String(MAXLEN = 256) [ Calculated, SqlColumnNumber = 10, SqlComputeCode = { set {*} = $$$defClassKeyGet({CLASSNAME},$$$cCLASSdescription)}, SqlComputed, SqlFieldName = DESCRIPTION ];

Property Owner As %String(MAXLEN = 256) [ Calculated, SqlColumnNumber = 11, SqlComputeCode = { set {*} = $$$defClassKeyGet({CLASSNAME},$$$cCLASSowner)}, SqlComputed, SqlFieldName = OWNER ];

ForeignKey FKForeignServer(ServerSchemaId,ServerNameId) References INFORMATION.SCHEMA.FOREIGNSERVERS();

Storage SQLStorage
{
<SQLMap name="Master">
<Data name="CLASSNAME">
<RetrievalCode> new m   set m = $s($SYSTEM.SQL.Schema.TableExists({L5}, .m):m, 1:""), {*} = $lg(m,3) </RetrievalCode>
</Data>
<Data name="SERVER_NAME">
<RetrievalCode> set {*} = {L3} </RetrievalCode>
</Data>
<Data name="SERVER_SCHEMA">
<RetrievalCode> set {*} = {L2} </RetrievalCode>
</Data>
<Data name="TABLE_NAME">
<RetrievalCode> set {*} = $$$TableFromIQN({L5}) </RetrievalCode>
</Data>
<Data name="TABLE_SCHEMA">
<RetrievalCode> set {*} = $$$SchemaFromIQN({L5}) </RetrievalCode>
</Data>
<Global>^rINDEXSQL</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Accessvar name="1">
<Code>set {1D1} = 0</Code>
<Variable>{1D1}</Variable>
</Accessvar>
<Expression>"SERVER"</Expression>
</Subscript>
<Subscript name="2">
<Expression>{ServerSchemaId}</Expression>
<NextCode>if '{1D1} do updateForeignServerIndex^%SYS.SQLSEC set {1D1}=1 GOTO NEXT
        set {L2} = $$GetNextSubscript^%SYS.SQLSEC("^rINDEXSQL(""SERVER"")", {L2})</NextCode>
</Subscript>
<Subscript name="3">
<Expression>{ServerNameId}</Expression>
</Subscript>
<Subscript name="4">
<Expression>1</Expression>
</Subscript>
<Subscript name="5">
<Expression>{FullTableExact}</Expression>
<Invalidcondition name="1">
<Expression>'$$AnyPrivObj^%SYS.SQLSEC("1,"_{L5})</Expression>
</Invalidcondition>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^INFORMATION862B.FOREIGNSERVERSS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

