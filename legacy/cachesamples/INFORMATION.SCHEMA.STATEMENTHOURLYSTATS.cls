/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Per hour light weight statistics of this SQL statement
Class INFORMATION.SCHEMA.STATEMENTHOURLYSTATS Extends (%Persistent, %XML.Adaptor) [ Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = STATEMENT_HOURLY_STATS, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

/// Hour these stats were recorded on, this is an integer 0-23 so 0 is after midnight up to 1am and 1 is from 1am up to 2am, etc.
Property Hour As %Integer [ Required, SqlColumnNumber = 2 ];

/// Total number of times we have recorded this query being run
Property StatCount As %Integer [ SqlColumnNumber = 3 ];

/// Total time spent running this query
Property StatTotal As %Double [ SqlColumnNumber = 4 ];

/// Variance in time from running this query
Property StatVariance As %Double [ SqlColumnNumber = 5 ];

/// Total %ROWCOUNT from running this query
Property StatRowCount As %Integer [ SqlColumnNumber = 6 ];

/// Total ObjectScript commands from running this query
Property StatCommands As %Integer [ SqlColumnNumber = 7 ];

Index StatementHourlyStatsIDKey On Hour [ IdKey ];

/// Reference to the daily stats class
Relationship Day As INFORMATION.SCHEMA.STATEMENTDAILYSTATS [ Cardinality = parent, Internal, Inverse = Hours ];

/// Day these stats were recorded on
Property Date As %Date [ Calculated, SqlColumnNumber = 8, SqlComputeCode = {set {*} = $p({Day},"||",2)}, SqlComputed ];

Storage SQLStorage
{
<SQLMap name="Master">
<Data name="StatCommands">
<Piece>5</Piece>
</Data>
<Data name="StatCount">
<Piece>1</Piece>
</Data>
<Data name="StatRowCount">
<Piece>4</Piece>
</Data>
<Data name="StatTotal">
<Piece>2</Piece>
</Data>
<Data name="StatVariance">
<Piece>3</Piece>
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
<Expression>{Hour}</Expression>
<Invalidcondition name="2">
<Expression>'$isvalidnum({L6})</Expression>
</Invalidcondition>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^INFORMATIO862B.STATEMENTHOD241S</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

