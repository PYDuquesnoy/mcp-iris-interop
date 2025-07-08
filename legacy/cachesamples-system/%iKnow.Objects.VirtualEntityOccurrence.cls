/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This is a read-only object representation wrapping the internal iKnow data structures for 
/// Entity Occurrences in a Virtual Source.</p>
/// <p>This class can be used from ObjectScript or SQL to access a single or small number of
/// entries, but the storage mappings are not meant to support elaborate or complex queries
/// targeting this SQL table.</p>
/// <p>Please use the predefined queries in <class>%iKnow.Queries.EntityAPI</class> and other query classes
/// to consult entity data as the internal global structures are designed to optimize performance for
/// these queries rather than general-purpose access.</p>
Class %iKnow.Objects.VirtualEntityOccurrence Extends %Persistent [ Deprecated, StorageStrategy = iKnowStorage, System = 4 ]
{

Parameter READONLY = 1;

Property DomainId As %Integer;

Property VirtualSourceId As %Integer;

Property EntOccId As %Integer;

Property EntUniId As %Integer;

Property EntTypeId As %Integer;

Property SentenceId As %Integer;

Property PosInSentence As %Integer;

Property CrcOccurrenceIdM As %Integer;

Property CrcOccurrenceIdR As %Integer;

Property CrcOccurrenceIdS As %Integer;

Property PathId As %Integer;

Property PosInPath As %Integer;

Index PKINDEX On (DomainId, VirtualSourceId, EntOccId) [ IdKey, PrimaryKey, Unique ];

Property Entity As %iKnow.Objects.VirtualEntityUnique [ Calculated, SqlComputeCode = {set {Entity} = {DomainId} _"||"_ {VirtualSourceId} _ "||" _ {EntUniId}}, SqlComputed ];

Property Sentence As %iKnow.Objects.VirtualSentence [ Calculated, SqlComputeCode = {set {Sentence} = {DomainId} _"||"_ {VirtualSourceId} _ "||" _ {SentenceId}}, SqlComputed ];

Storage iKnowStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="MainMap">
<Data name="CrcOccurrenceIdM">
<Piece>5</Piece>
</Data>
<Data name="CrcOccurrenceIdR">
<Piece>6</Piece>
</Data>
<Data name="CrcOccurrenceIdS">
<Piece>7</Piece>
</Data>
<Data name="EntTypeId">
<Piece>2</Piece>
</Data>
<Data name="EntUniId">
<Piece>1</Piece>
</Data>
<Data name="PathId">
<Piece>8</Piece>
</Data>
<Data name="PosInPath">
<Piece>9</Piece>
</Data>
<Data name="PosInSentence">
<Piece>4</Piece>
</Data>
<Data name="SentenceId">
<Piece>3</Piece>
</Data>
<Global>^IRIS.IKV.EntOccId</Global>
<Structure>list</Structure>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{VirtualSourceId}</Expression>
</Subscript>
<Subscript name="3">
<Expression>{EntOccId}</Expression>
<Invalidcondition name="1">
<Expression>$lg($g(^IRIS.IKV.EntOccId({L1},{L2},{L3})),2)=2</Expression>
</Invalidcondition>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^IRIS.IK.Objects.VirtEntOccS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
