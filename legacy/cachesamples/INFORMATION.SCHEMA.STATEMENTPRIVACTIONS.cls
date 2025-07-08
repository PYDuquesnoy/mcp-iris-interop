/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Child class of INFORMATION.SCHEMA.STATEMENTPRIVOBJECTS, the privilege actions required for the parent SQL object for this statement
Class INFORMATION.SCHEMA.STATEMENTPRIVACTIONS Extends (%Library.Persistent, %XML.Adaptor) [ ClassType = persistent, Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = STATEMENT_PRIV_ACTIONS, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

Relationship Relation As INFORMATION.SCHEMA.STATEMENTPRIVOBJECTS [ Cardinality = parent, Inverse = Actions ];

/// SQL Privilege Object action for the parent priilege object for the statement
/// "s" for Select, "i" for Insert, "u" for Update, "d" for Delete
Property Action As %String(MAXLEN = 1) [ Required ];

Property Fields As %Library.List;

Index StatementRelationsIDKey On Action [ IdKey ];

Storage SQLStorage
{
<SQLMap name="Master">
<Data name="Fields"/>
<Global>^rINDEXSQL</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>"sqlidx"</Expression>
</Subscript>
<Subscript name="2">
<Expression>1</Expression>
</Subscript>
<Subscript name="3">
<Expression>{INFORMATION_SCHEMA.STATEMENTS.Hash}</Expression>
<Invalidcondition name="1">
<Expression>'$$StatementIndexPrivileged^%SYS.SQLSEC({L3})</Expression>
</Invalidcondition>
</Subscript>
<Subscript name="4">
<Expression>"priv"</Expression>
</Subscript>
<Subscript name="5">
<Expression>{INFORMATION_SCHEMA.STATEMENT_PRIV_OBJECTS.Relation}</Expression>
</Subscript>
<Subscript name="6">
<Expression>{Action}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^INFORMATIO862B.STATEMENTPRDB31S</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

