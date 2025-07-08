/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Child class of INFORMATION.SCHEMA.STATEMENTS, the SQL Objects that have privileges required for this statement
Class INFORMATION.SCHEMA.STATEMENTPRIVOBJECTS Extends (%Library.Persistent, %XML.Adaptor) [ ClassType = persistent, Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = STATEMENT_PRIV_OBJECTS, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

/// Reference to the INFORMATION_SCHEMA.STATEMENTS row this is a child of
Relationship Statements As INFORMATION.SCHEMA.STATEMENTS [ Cardinality = parent, Inverse = PrivilegeRelations ];

Relationship Actions As INFORMATION.SCHEMA.STATEMENTPRIVACTIONS [ Cardinality = children, Inverse = Relation ];

/// SQL Privilege Object name for relatitions for this statement that will need privilege on to run.  Note, the name of the relation is always stored in uppercase.
/// This format is typically <table-type>,<iqn>  table-type is 1 for tables, 3 for views.  iqn is internal qualified name
Property Relation As %String(MAXLEN = 130) [ Required ];

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
<Expression>"priv"</Expression>
</Subscript>
<Subscript name="5">
<Expression>{Relation}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^INFORMATIO862B.STATEMENTPRFBBFS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

