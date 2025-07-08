/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Per day light weight statistics of this SQL statement
Class INFORMATION.SCHEMA.STATEMENTDAILYSTATS Extends (%Persistent, %XML.Adaptor) [ Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = STATEMENT_DAILY_STATS, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

/// Day these stats were recorded on
Property Day As %Date [ Required, SqlColumnNumber = 2 ];

/// Total number of times we have recorded this query being run
Property StatCount As %Integer [ SqlColumnNumber = 3 ];

/// Total time spent running this query
Property StatTotal As %Double [ SqlColumnNumber = 4 ];

/// Variance in time from running this query
Property StatVariance As %Double [ SqlColumnNumber = 5 ];

/// Total %ROWCOUNT from running this query
Property StatRowCount As %Integer [ SqlColumnNumber = 6 ];

/// Total ObjectScript commands executed from running this query
Property StatCommands As %Integer [ SqlColumnNumber = 7 ];

Index StatementDailyStatsIDKey On Day [ IdKey ];

Relationship Statement As INFORMATION.SCHEMA.STATEMENTS [ Cardinality = parent, Inverse = Days ];

/// Breakdown of light weight SQL stats per hour within the day
Relationship Hours As INFORMATION.SCHEMA.STATEMENTHOURLYSTATS(XMLPROJECTION = "NONE") [ Cardinality = children, Inverse = Day ];

Relationship Parameters As INFORMATION.SCHEMA.STATEMENTPARAMETERSTATS(XMLPROJECTION = "NONE") [ Cardinality = children, Inverse = Day ];

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
<Expression>{Day}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^INFORMATIO862B.STATEMENTDA61DDS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

