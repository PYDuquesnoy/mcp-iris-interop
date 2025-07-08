/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This is a read-only object representation wrapping the internal iKnow data structures for 
/// Dictionary Matches in a Virtual Source.</p>
/// <p>This class can be used from ObjectScript or SQL to access a single or small number of
/// entries, but the storage mappings are not meant to support elaborate or complex queries
/// targeting this SQL table.</p>
/// <p>Please use the predefined queries in <class>%iKnow.Matching.MatchingAPI</class> and other query classes
/// to consult entity data as the internal global structures are designed to optimize performance for
/// these queries rather than general-purpose access.</p>
Class %iKnow.Objects.VirtualDictionaryMatch Extends %Persistent [ Deprecated, StorageStrategy = iKnowStorage, System = 4 ]
{

Parameter READONLY = 1;

Property DomainId As %Integer;

Property VirtualSourceId As %Integer;

Property DictionaryMatchId As %Integer;

Property DictionaryId As %Integer;

Property DictionaryItemId As %Integer;

Property DictionaryTermId As %Integer;

Property TargetType As %Integer;

Property TargetTypeString As %String [ Calculated, SqlComputeCode = { set {TargetTypeString} = $case({TargetType}, $$$DMTARGETENTITY:"entity", $$$DMTARGETCRC:"crc", $$$DMTARGETPATH:"path")}, SqlComputed ];

Property TargetId As %Integer;

Property MatchScore As %Numeric;

Property MatchedConceptCount As %Integer;

Property MatchedRelationCount As %Integer;

Property PartialMatchCount As %Integer;

Property FirstMatchedPositionInPath As %Integer;

Property LastMatchedPositionInPath As %Integer;

Property IsOrdered As %Boolean;

Property NegatedEntityCount As %Integer;

Index PKINDEX On (DomainId, VirtualSourceId, DictionaryMatchId) [ IdKey, PrimaryKey, Unique ];

Property MatchedEntityCount As %Integer [ Calculated, SqlComputeCode = {set {MatchedEntityCount} = {MatchedConceptCount} + {MatchedRelationCount} }, SqlComputed ];

Property MatchedPathSectionLength As %Integer [ Calculated, SqlComputeCode = {set {MatchedPathSectionLength} = {LastMatchedPositionInPath} - {FirstMatchedPositionInPath} + 1 }, SqlComputed ];

Property Dictionary As %iKnow.Objects.Dictionary [ Calculated, SqlComputeCode = {set {Dictionary} = $s({DictionaryId}<0:0, 1:{DomainId}) _"||"_ $zabs({DictionaryId})}, SqlComputed ];

Property DictionaryItem As %iKnow.Objects.DictionaryItem [ Calculated, SqlComputeCode = {set {DictionaryItem} = $s({DictionaryId}<0:0, 1:{DomainId}) _"||"_ $zabs({DictionaryItemId})}, SqlComputed ];

Property DictionaryTerm As %iKnow.Objects.DictionaryTerm [ Calculated, SqlComputeCode = {set {DictionaryTerm} = $s({DictionaryId}<0:0, 1:{DomainId}) _"||"_ $zabs({DictionaryTermId})}, SqlComputed ];

Property MatchedEntityOccurrence As %iKnow.Objects.VirtualEntityOccurrence [ Calculated, SqlComputeCode = {set {MatchedEntityOccurrence} = $s({TargetType}=0:{DomainId}_"||"_{VirtualSourceId}_"||"_{TargetId}, 1:"")}, SqlComputed ];

Property MatchedCrcOccurrence As %iKnow.Objects.VirtualCrcOccurrence [ Calculated, SqlComputeCode = {set {MatchedCrcOccurrence} = $s({TargetType}=1:{DomainId}_"||"_{VirtualSourceId}_"||"_{TargetId}, 1:"")}, SqlComputed ];

Index DictItemIndex On (DomainId, VirtualSourceId, DictionaryItemId);

Storage iKnowStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="DictItemIndex">
<Global>^IRIS.IKV.Mat.DictItemToMatch</Global>
<RowIdSpec name="1">
<Expression>{S1}</Expression>
<Field>DomainId</Field>
</RowIdSpec>
<RowIdSpec name="2">
<Expression>{S2}</Expression>
<Field>VirtualSourceId</Field>
</RowIdSpec>
<RowIdSpec name="3">
<Expression>{S4}</Expression>
<Field>DictionaryMatchId</Field>
</RowIdSpec>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{VirtualSourceId}</Expression>
</Subscript>
<Subscript name="3">
<Expression>{DictionaryItemId}</Expression>
</Subscript>
<Subscript name="4">
<Expression>{DictionaryMatchId}</Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<SQLMap name="MainMap">
<Data name="DictionaryId">
<Piece>1</Piece>
</Data>
<Data name="DictionaryItemId">
<Piece>2</Piece>
</Data>
<Data name="DictionaryTermId">
<Piece>3</Piece>
</Data>
<Data name="FirstMatchedPositionInPath">
<Piece>10</Piece>
</Data>
<Data name="IsOrdered">
<Piece>12</Piece>
</Data>
<Data name="LastMatchedPositionInPath">
<Piece>11</Piece>
</Data>
<Data name="MatchScore">
<Piece>6</Piece>
</Data>
<Data name="MatchedConceptCount">
<Piece>7</Piece>
</Data>
<Data name="MatchedRelationCount">
<Piece>8</Piece>
</Data>
<Data name="NegatedEntityCount">
<Piece>13</Piece>
</Data>
<Data name="PartialMatchCount">
<Piece>9</Piece>
</Data>
<Data name="TargetId">
<Piece>5</Piece>
</Data>
<Data name="TargetType">
<Piece>4</Piece>
</Data>
<Global>^IRIS.IKV.Mat.MatchId</Global>
<Structure>list</Structure>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{VirtualSourceId}</Expression>
</Subscript>
<Subscript name="3">
<Expression>{DictionaryMatchId}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^IRIS.IKV.Objects.Mat.MatchS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
