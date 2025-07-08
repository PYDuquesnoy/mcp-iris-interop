/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Returns one row location (routine, class) that has an SQL Statement.  This is a child table of INFORMATION_SCHEMA.STATEMENTS as a statement may be found in multiple locations.
Class INFORMATION.SCHEMA.STATEMENTLOCATIONS Extends (%Library.Persistent, %XML.Adaptor) [ ClassType = persistent, Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = STATEMENT_LOCATIONS, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

/// Parent reference to the SQL Statement
Relationship Statement As INFORMATION.SCHEMA.STATEMENTS [ Cardinality = parent, Inverse = Locations ];

/// Routine or classname the SQL Statement reside in
Property Location As %String(MAXLEN = 128) [ Required ];

/// Runtime location of SQL logic, for universal cached queries will be different to <property>Location</property>
Property RuntimeLocation As %String(MAXLEN = 128);

/// Type of location:  Class (CLS), Routine (RTN), etc.
Property Type As %String(MAXLEN = 10);

Index StatementRelationsIDKey On Location [ IdKey ];

Storage SQLStorage
{
<SQLMap name="LocationIndex">
<Global>^rINDEXSQL</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>"sqlidx"</Expression>
</Subscript>
<Subscript name="2">
<Expression>2</Expression>
</Subscript>
<Subscript name="3">
<Expression>{Location}</Expression>
</Subscript>
<Subscript name="4">
<Expression>{INFORMATION_SCHEMA.STATEMENTS.Hash}</Expression>
<Invalidcondition name="1">
<Expression>'$$StatementIndexPrivileged^%SYS.SQLSEC({L4})</Expression>
</Invalidcondition>
</Subscript>
<Type>index</Type>
</SQLMap>
<SQLMap name="Master">
<Data name="RuntimeLocation">
<Piece>2</Piece>
</Data>
<Data name="Type">
<Piece>1</Piece>
</Data>
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
<Expression>"rtn"</Expression>
</Subscript>
<Subscript name="5">
<Expression>{Location}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^INFORMATIO862B.STATEMENTRE3F7CS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

