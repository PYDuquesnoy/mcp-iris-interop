/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Note: the use of this class is no longer recommended for accessing elements of a specific domain.
/// For those scenarios, <class>%iKnow.Tables.Utils</class> offers a more flexible and customizable
/// way of projecting iKnow domain data to SQL</p>
/// <p>This is a read-only object representation wrapping the internal iKnow data structures for 
/// Entity Occurrences.</p>
/// <p>This class can be used from ObjectScript or SQL to access a single or small number of
/// entries, but the storage mappings are not meant to support elaborate or complex queries
/// targeting this SQL table.</p>
/// <p>Please use the predefined queries in <class>%iKnow.Queries.EntityAPI</class> and other query classes
/// to consult entity data as the internal global structures are designed to optimize performance for
/// these queries rather than general-purpose access.</p>
///  <p>NOTE: This object assumes all underlying data structures are present. Use domain-specific
///  copies of these objects for domains where not all indices are built. See also the 
///  GenerateAllObjectsForDomain() method in <class>%iKnow.Objects.Utils</class>.</p>
Class %iKnow.Objects.EntityOccurrence Extends %Persistent [ Deprecated, StorageStrategy = iKnowStorage, System = 4 ]
{

Parameter READONLY = 1;

Property DomainId As %Integer;

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

/// If the domain has stemming enabled, this points to the stemmed entity's ID
Property StemmedEntUniId As %Integer [ Calculated, SqlComputeCode = {new d  set {StemmedEntUniId} = $s($ld(^IRIS.IK.EntOccId({DomainId},{EntOccId}),10,d):d, 1:{EntUniId}) }, SqlComputed ];

Index PKINDEX On (DomainId, EntOccId) [ IdKey, PrimaryKey, Unique ];

Property Entity As %iKnow.Objects.EntityUnique [ Calculated, SqlComputeCode = { set {Entity} = {DomainId} _"||"_ {EntUniId}}, SqlComputed ];

Property Sentence As %iKnow.Objects.Sentence [ Calculated, SqlComputeCode = { set {Sentence} = {DomainId} _"||"_ {SentenceId}}, SqlComputed ];

Property Literal As %String(MAXLEN = 1000) [ Calculated, SqlComputeCode = { set {Literal} = ##class(%iKnow.Queries.EntityAPI).GetLiteral({DomainId},{EntOccId}) }, SqlComputed ];

Property SourceId As %Integer [ Calculated, SqlComputeCode = {set {SourceId} = ##class(%iKnow.Queries.SentenceAPI).GetSourceId({DomainId},{SentenceId}) }, SqlComputed ];

Property StemmedEntity As %iKnow.Objects.EntityUnique [ Calculated, SqlComputeCode = { set {StemmedEntity} = {DomainId} _"||"_ {StemmedEntUniId} }, SqlComputed ];

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
<Global>^IRIS.IK.EntOccId</Global>
<Structure>list</Structure>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{EntOccId}</Expression>
<Invalidcondition name="1">
<Expression>$lg($g(^IRIS.IK.EntOccId({L1},{L2})),2)=2</Expression>
</Invalidcondition>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^IRIS.IK.Objects.EntOccS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
