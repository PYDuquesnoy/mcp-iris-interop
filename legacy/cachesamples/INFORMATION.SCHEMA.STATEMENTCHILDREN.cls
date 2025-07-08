/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Child table of INFORMATION_SCHEMA.STATEMENTS which contains hash of the root parallel statement if this is a parallel "child" statement
Class INFORMATION.SCHEMA.STATEMENTCHILDREN Extends (%Library.Persistent, %XML.Adaptor) [ ClassType = persistent, Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = STATEMENT_CHILDREN, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

/// Reference to the INFORMATION_SCHEMA.STATEMENTS row this is a child of
Relationship Statement As INFORMATION.SCHEMA.STATEMENTS [ Cardinality = parent, Inverse = Children ];

/// Hash for the parallel root parent
Property ParentHash As %String(MAXLEN = 128) [ Required ];

Index StatementRelationsIDKey On ParentHash [ IdKey ];

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
<Expression>"child"</Expression>
</Subscript>
<Subscript name="5">
<Expression>{ParentHash}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^INFORMATIO862B.STATEMENTCH4F45S</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

