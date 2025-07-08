/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Child table of INFORMATION_SCHEMA.STATEMENTS which contains each table or view entry use by the statement
Class INFORMATION.SCHEMA.STATEMENTRELATIONS Extends (%Library.Persistent, %XML.Adaptor) [ ClassType = persistent, Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = STATEMENT_RELATIONS, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

/// Reference to the INFORMATION_SCHEMA.STATEMENTS row this is a child of
Relationship Statement As INFORMATION.SCHEMA.STATEMENTS [ Cardinality = parent, Inverse = Relations ];

/// name of the table or view the statement references.  Note, the name of the relation is always stored in uppercase.
Property Relation As %String(MAXLEN = 128) [ Required ];

Index StatementRelationsIDKey On Relation [ IdKey ];

Storage SQLStorage
{
<SQLMap name="Master">
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
<Expression>"rel"</Expression>
</Subscript>
<Subscript name="5">
<Expression>{Relation}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<SQLMap name="RelationIndex">
<Global>^rINDEXSQL</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>"sqlidx"</Expression>
</Subscript>
<Subscript name="2">
<Expression>3</Expression>
</Subscript>
<Subscript name="3">
<Expression>{Relation}</Expression>
</Subscript>
<Subscript name="4">
<Expression>{INFORMATION_SCHEMA.STATEMENTS.Hash}</Expression>
<Invalidcondition name="1">
<Expression>'$$StatementIndexPrivileged^%SYS.SQLSEC({L4})</Expression>
</Invalidcondition>
</Subscript>
<Type>index</Type>
</SQLMap>
<StreamLocation>^INFORMATIO862B.STATEMENTRE3F7CS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

