/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Daily parameter statistics of this SQL statement
Class INFORMATION.SCHEMA.STATEMENTPARAMETERSTATS Extends (%Persistent, %XML.Adaptor) [ Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = STATEMENT_PARAMETER_STATS, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

/// List of actual parameter values used in order
Property Values As %List [ Required, SqlColumnNumber = 2 ];

/// Internal hash for this list of parameter values
Property ValuesHash As %String [ Private, Required, SqlColumnNumber = 3 ];

/// Number of times this list of parameter values was used
Property Frequency As %Integer [ Required, SqlColumnNumber = 4 ];

/// Total runtime with this list of parameter values
Property TotalRuntime As %Double(SCALE = 3) [ Private, Required, SqlColumnNumber = 5 ];

/// Average runtime with this list of parameter values
Property AverageRuntime As %Double(SCALE = 3) [ Calculated, Required, SqlColumnNumber = 6, SqlComputeCode = { set {*}={TotalRuntime}/{Frequency} }, SqlComputed ];

Index StatementParameterStatsIDKey On ValuesHash [ IdKey ];

Relationship Day As INFORMATION.SCHEMA.STATEMENTDAILYSTATS [ Cardinality = parent, Inverse = Parameters ];

Storage SQLStorage
{
<SQLMap name="Master">
<Data name="Frequency">
<Piece>1</Piece>
</Data>
<Data name="TotalRuntime">
<Piece>2</Piece>
</Data>
<Data name="Values">
<RetrievalCode>set {*}=$g(^rINDEXSQL({L1},{L2},{L3},{L4},{L5},{L6},{L7},"value"))</RetrievalCode>
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
<Expression>"stat"</Expression>
</Subscript>
<Subscript name="5">
<Expression>{INFORMATION_SCHEMA.STATEMENT_DAILY_STATS.Day}</Expression>
</Subscript>
<Subscript name="6">
<Expression>"params"</Expression>
</Subscript>
<Subscript name="7">
<Expression>{ValuesHash}</Expression>
</Subscript>
<Subscript name="8">
<Expression>"stats"</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^INFORMATIO862B.STATEMENTHOD241S</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

