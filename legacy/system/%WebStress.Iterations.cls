/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Iterations Extends (%Persistent, %XML.Adaptor) [ Inheritance = right, Owner = {%Developer}, StorageStrategy = WebStress, System = 4 ]
{

Property RunID As %Integer;

Property TestID As %Integer;

Property ScriptID As %Integer;

Property Number As %Integer;

Property Seconds As %Integer;

Property SystemIdentifier As %String(MAXLEN = 200);

Index Main On (TestID, RunID, SystemIdentifier, ScriptID) [ IdKey, PrimaryKey, Unique ];

Storage WebStress
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Data name="Number">
<Delimiter>"^"</Delimiter>
<Node>"I"</Node>
<Piece>1</Piece>
</Data>
<Data name="Seconds">
<Delimiter>"^"</Delimiter>
<Node>"S"</Node>
<Piece>1</Piece>
</Data>
<Global>^WebStress.Iterations</Global>
<PopulationType>full</PopulationType>
<RowIdSpec name="1">
<Expression>{L1}</Expression>
<Field>TestID</Field>
</RowIdSpec>
<RowIdSpec name="2">
<Expression>{L2}</Expression>
<Field>RunID</Field>
</RowIdSpec>
<RowIdSpec name="3">
<Expression>{L3}</Expression>
<Field>SystemIdentifier</Field>
</RowIdSpec>
<RowIdSpec name="4">
<Expression>{L4}</Expression>
<Field>ScriptID</Field>
</RowIdSpec>
<Subscript name="1">
<Expression>{TestID}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{RunID}</Expression>
</Subscript>
<Subscript name="3">
<Expression>{SystemIdentifier}</Expression>
</Subscript>
<Subscript name="4">
<Expression>{ScriptID}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^WebStress.IterationsS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
