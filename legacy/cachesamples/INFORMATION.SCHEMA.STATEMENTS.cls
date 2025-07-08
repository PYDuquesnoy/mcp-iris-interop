/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Contains SQL Statement Index entries that can be accessed by the current user in the current namespace.
Class INFORMATION.SCHEMA.STATEMENTS Extends (%Library.Persistent, %XML.Adaptor) [ ClassType = persistent, Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = STATEMENTS, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

Index IDKeyIndex On Hash [ IdKey, Internal, Unique ];

/// Internal unique statement hash used as the ID for the statement.
Property Hash As %String(MAXLEN = 32) [ Required, SqlColumnNumber = 2 ];

/// SQL Compilation mode, Logical, Odbc, Display, Runtime, etc., when the statement was compiled
Property SqlComp As %String(MAXLEN = 32) [ SqlColumnNumber = 3 ];

/// Value of %defschema when the statement was compiled
Property DefaultSchema As %Library.List [ SqlColumnNumber = 4 ];

/// Value of %sqlSchemaPath when the statement was compiled
Property SQLSchemaPath As %Library.List [ SqlColumnNumber = 5 ];

/// Value of packages argument passed to SQL compiler when the statement was compiled
Property Packages As %Library.List [ SqlColumnNumber = 6 ];

/// Value of %switch when the statement was compiled
Property Switch As %String(MAXLEN = 32) [ SqlColumnNumber = 7 ];

/// 0/1/2/3 flag which defines if the statement plan Unfrozen (0), Frozen/Explicit (1), Frozen/Upgrade (2), or Unfrozen/Parallel (3)
Property Frozen As %Integer [ SqlColumnNumber = 8 ];

/// Timestamp value for when the plan was saved.
Property Timestamp As %TimeStamp [ SqlColumnNumber = 9 ];

/// $zversion string for when the plan was saved.
Property Version As %String(MAXLEN = 200) [ SqlColumnNumber = 10 ];

/// Error string recorded for this plan
Property Error As %String(MAXLEN = 4096) [ SqlColumnNumber = 11 ];

/// Query plan
Property Plan As %String(XMLPROJECTION = "NONE") [ Calculated, SqlColumnNumber = 12, SqlComputeCode = { new asl,mt,mts,pdict set {Plan}=$$nlizFromHash^%qaqplan({Hash}) }, SqlComputed ];

Property Statement As %String(COLLATION = "SQLSTRING", MAXLEN = 262144) [ SqlColumnNumber = 13 ];

/// Hash of this statement's parent statement.  Only defined if this is a recursive compile for %PARALLEL statements.  This references the root parent's hash.
Property ParentHash As %String(MAXLEN = 32) [ SqlColumnNumber = 14 ];

/// Version counter for internal statement version
Property StatementVersion As %Integer [ Internal, SqlColumnNumber = 15 ];

/// Total number of times we have recorded this query being run
Property StatCount As %Integer [ SqlColumnNumber = 16 ];

/// Total time spent running this query
Property StatTotal As %Double [ SqlColumnNumber = 17 ];

/// Variance in time from running this query
Property StatVariance As %Double [ SqlColumnNumber = 18 ];

/// First day we recorded statistics from running this query
Property StatFirst As %Date [ SqlColumnNumber = 19 ];

/// Set to true for 'natural' queries which are already maximally efficient and for which
/// we do not collect any statistics as the overhead of statistical collection would have a
/// significant impact on the statement performance.
Property NaturalQuery As %Boolean [ SqlColumnNumber = 20 ];

/// Average time spent running this query
Property StatAverage As %Double [ Calculated, SqlColumnNumber = 21, SqlComputeCode = { Set {StatAverage}=$s({StatCount}>0:{StatTotal}/{StatCount},1:"") }, SqlComputed, SqlComputeOnChange = (StatCount, StatTotal) ];

/// Standard deviation of the time measurement for this query
Property StatStdDev As %Double [ Calculated, SqlColumnNumber = 22, SqlComputeCode = { Set {StatStdDev}={StatVariance}**0.5 }, SqlComputed, SqlComputeOnChange = StatVariance ];

/// True if the frozen plan is different to what we would use if the plan was not frozen
Property FrozenDifferent As %Boolean [ SqlColumnNumber = 23 ];

/// Hash when we last scanned this statement to see if the frozen plan is different to the current plan
Property FrozenScanHash As %String [ Internal, SqlColumnNumber = 24 ];

/// InterSystems IRIS version from when we last scanned this statement to see if the frozen plan is differnet to the current plan
Property FrozenScanVersion As %String(MAXLEN = 200) [ Internal, SqlColumnNumber = 25 ];

/// Total %ROWCOUNT from running this query
Property StatRowCount As %Integer [ SqlColumnNumber = 26 ];

/// $username at the time the query was built
Property UserName As %String [ SqlColumnNumber = 27 ];

/// Client name at the time the query was built
Property ClientName As %String [ SqlColumnNumber = 28 ];

/// Client IP address at the time the query was built
Property ClientIP As %String [ SqlColumnNumber = 29 ];

/// Client application name at the time the query was built
Property ClientApp As %String [ SqlColumnNumber = 30 ];

/// Call stack at the time the query was built
Property CallStack As %List [ SqlColumnNumber = 31 ];

/// Total ObjectScript commands executed from running this query
Property StatCommands As %Integer [ SqlColumnNumber = 32 ];

/// A Unique SQL Statement Identifier which can be used to identify each SQL Statement that is stored in the SQL Statement Index (SSI)...
Property SQLStatementID As %Integer [ SqlColumnNumber = 33 ];

/// Machine Readable Query Plan
Property JSONPlan As %String(XMLPROJECTION = "NONE") [ Calculated, SqlColumnNumber = 34, SqlComputeCode = { new asl,mt,mts,pdict set {JSONPlan}=$$nlizFromHash^%qaqplan({Hash},1) }, SqlComputed ];

/// Binary Query plan
Property BinaryPlan As list Of %Binary(MAXLEN = 65536, XMLNAME = "Plan", XMLPROJECTION = "wrapped") [ Private, SqlColumnNumber = 35, SqlListType = SUBNODE ];

Relationship Children As INFORMATION.SCHEMA.STATEMENTCHILDREN [ Cardinality = children, Inverse = Statement ];

Relationship Relations As INFORMATION.SCHEMA.STATEMENTRELATIONS [ Cardinality = children, Inverse = Statement ];

Relationship Locations As INFORMATION.SCHEMA.STATEMENTLOCATIONS(XMLPROJECTION = "NONE") [ Cardinality = children, Inverse = Statement ];

Relationship PrivilegeRelations As INFORMATION.SCHEMA.STATEMENTPRIVOBJECTS [ Cardinality = children, Inverse = Statements ];

/// Breakdown of light weight SQL stats per day
Relationship Days As INFORMATION.SCHEMA.STATEMENTDAILYSTATS(XMLPROJECTION = "NONE") [ Cardinality = children, Inverse = Statement ];

Method GetBinaryPlan(plan) As %Status
{
}

/// Table qualifier - always NULL in InterSystems IRIS.
Storage SQLStorage
{
<Description>
<![CDATA[Table qualifier - always NULL in InterSystems IRIS.]]></Description>
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Data name="BinaryPlan">
<RetrievalCode> new planItm,plan set plan="" for planItm=1:1:$g(^rINDEXSQL({L1},{L2},{L3},"plan")) { set plan=plan_$lb($g(^rINDEXSQL({L1},{L2},{L3},"plan",planItm))) } set {*}=plan</RetrievalCode>
</Data>
<Data name="CallStack">
<Node>2</Node>
<Piece>5</Piece>
</Data>
<Data name="ClientApp">
<Node>2</Node>
<Piece>4</Piece>
</Data>
<Data name="ClientIP">
<Node>2</Node>
<Piece>3</Piece>
</Data>
<Data name="ClientName">
<Node>2</Node>
<Piece>2</Piece>
</Data>
<Data name="DefaultSchema">
<Node>0</Node>
<Piece>3</Piece>
</Data>
<Data name="Error">
<Node>"err"</Node>
</Data>
<Data name="Frozen">
<Node>"planinfo"</Node>
<Piece>1</Piece>
</Data>
<Data name="FrozenDifferent">
<Node>"planinfo"</Node>
<Piece>6</Piece>
</Data>
<Data name="FrozenScanHash">
<Node>"planinfo"</Node>
<Piece>7</Piece>
</Data>
<Data name="FrozenScanVersion">
<Node>"planinfo"</Node>
<Piece>8</Piece>
</Data>
<Data name="NaturalQuery">
<Node>"planinfo"</Node>
<Piece>5</Piece>
</Data>
<Data name="Packages">
<Node>0</Node>
<Piece>4</Piece>
</Data>
<Data name="ParentHash">
<Node>"planinfo"</Node>
<Piece>4</Piece>
</Data>
<Data name="SQLSchemaPath">
<Node>0</Node>
<Piece>2</Piece>
</Data>
<Data name="SQLStatementID">
<RetrievalCode> new SQLStatementID
 set SQLStatementID=$LG($g(^rINDEXSQL({L1},{L2},{L3},0)),6)
 $$$AddSQLStatementIDIfUnset(SQLStatementID,{L3})
 set {*}=SQLStatementID
 </RetrievalCode>
</Data>
<Data name="SqlComp">
<Node>0</Node>
<Piece>1</Piece>
</Data>
<Data name="StatCommands">
<Node>"stat"</Node>
<Piece>6</Piece>
</Data>
<Data name="StatCount">
<Node>"stat"</Node>
<Piece>1</Piece>
</Data>
<Data name="StatFirst">
<Node>"stat"</Node>
<Piece>4</Piece>
</Data>
<Data name="StatRowCount">
<Node>"stat"</Node>
<Piece>5</Piece>
</Data>
<Data name="StatTotal">
<Node>"stat"</Node>
<Piece>2</Piece>
</Data>
<Data name="StatVariance">
<Node>"stat"</Node>
<Piece>3</Piece>
</Data>
<Data name="Statement">
<RetrievalCode>new i,sql set sql="" for i=1:1:$g(^rINDEXSQL({L1},{L2},{L3},1)) { set sql=sql_" "_$g(^rINDEXSQL({L1},{L2},{L3},1,i)) } set {*}=sql</RetrievalCode>
</Data>
<Data name="StatementVersion">
<RetrievalCode>set {*}={3D}</RetrievalCode>
</Data>
<Data name="Switch">
<Node>0</Node>
<Piece>5</Piece>
</Data>
<Data name="Timestamp">
<Node>"planinfo"</Node>
<Piece>2</Piece>
</Data>
<Data name="UserName">
<Node>2</Node>
<Piece>1</Piece>
</Data>
<Data name="Version">
<Node>"planinfo"</Node>
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
<Expression>{Hash}</Expression>
<Invalidcondition name="1">
<Expression>'$$StatementIndexPrivileged^%SYS.SQLSEC({L3})</Expression>
</Invalidcondition>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^INFORMATION.SCHEMA.STATISTICSS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

