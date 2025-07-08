/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This is a read-only object representation wrapping the internal iKnow data structures for 
/// CRC Occurrences in a Virtual Source.</p>
/// <p>This class can be used from ObjectScript or SQL to access a single or small number of
/// entries, but the storage mappings are not meant to support elaborate or complex queries
/// targeting this SQL table.</p>
/// <p>Please use the predefined queries in <class>%iKnow.Queries.CrcAPI</class> and other query classes
/// to consult CRC data as the internal global structures are designed to optimize performance for
/// these queries rather than general-purpose access.</p>
Class %iKnow.Objects.VirtualCrcOccurrence Extends %Persistent [ Deprecated, StorageStrategy = iKnowStorage, System = 4 ]
{

Parameter READONLY = 1;

Property DomainId As %Integer;

Property VirtualSourceId As %Integer;

Property CrcOccurrenceId As %Integer;

Property CrcUniId As %Integer;

Property HeadOccId As %Integer;

Property MasterOccId As %Integer [ Calculated, Deprecated, Internal, SqlComputeCode = { set {MasterOccId} = {HeadOccId} }, SqlComputed ];

Property RelationOccId As %Integer;

Property TailOccId As %Integer;

Property SlaveOccId As %Integer [ Calculated, Deprecated, Internal, SqlComputeCode = { set {SlaveOccId} = {TailOccId} }, SqlComputed ];

Property SentenceId As %Integer;

Property PosInSentence As %Integer;

Index PKINDEX On (DomainId, VirtualSourceId, CrcOccurrenceId) [ IdKey, PrimaryKey, Unique ];

Property CrcUnique As %iKnow.Objects.VirtualCrcUnique [ Calculated, SqlComputeCode = { set {CrcUnique} = {DomainId} _"||"_ {VirtualSourceId} _"||"_ {CrcUniId} }, SqlComputed ];

Property Sentence As %iKnow.Objects.VirtualSentence [ Calculated, SqlComputeCode = {set {Sentence} = {DomainId} _"||"_ {VirtualSourceId} _ "||" _ {SentenceId}}, SqlComputed ];

Storage iKnowStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="MainMap">
<Data name="CrcUniId">
<Piece>1</Piece>
</Data>
<Data name="HeadOccId">
<Piece>2</Piece>
</Data>
<Data name="PosInSentence">
<Piece>6</Piece>
</Data>
<Data name="RelationOccId">
<Piece>3</Piece>
</Data>
<Data name="SentenceId">
<Piece>5</Piece>
</Data>
<Data name="TailOccId">
<Piece>4</Piece>
</Data>
<Global>^IRIS.IKV.CrcOccId</Global>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{VirtualSourceId}</Expression>
</Subscript>
<Subscript name="3">
<Expression>{CrcOccurrenceId}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^IRIS.IK.Objects.VirtCrcOccurrenceS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
