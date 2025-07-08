/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Note: the use of this class is no longer recommended for accessing elements of a specific domain.
/// For those scenarios, <class>%iKnow.Tables.Utils</class> offers a more flexible and customizable
/// way of projecting iKnow domain data to SQL</p>
/// <p>This is a read-only object representation wrapping the internal iKnow data structures for CRC
/// Occurrences.</p>
/// <p>This class can be used from ObjectScript or SQL to access a single or small number of
/// entries, but the storage mappings are not meant to support elaborate or complex queries
/// targeting this SQL table.</p>
/// <p>Please use the predefined queries in <class>%iKnow.Queries.CrcAPI</class> and other query classes
/// to consult CRC data as the internal global structures are designed to optimize performance for
/// these queries rather than general-purpose access.</p>
///  <p>NOTE: This object assumes all underlying data structures are present. Use domain-specific
///  copies of these objects for domains where not all indices are built. See also the 
///  GenerateAllObjectsForDomain() method in <class>%iKnow.Objects.Utils</class>.</p>
Class %iKnow.Objects.CrcOccurrence Extends %Persistent [ Deprecated, StorageStrategy = iKnowStorage, System = 4 ]
{

Parameter READONLY = 1;

Property DomainId As %Integer;

Property CrcOccurrenceId As %Integer;

Property CrcUniId As %Integer;

Property HeadOccId As %Integer;

Property MasterOccId As %Integer [ Calculated, Deprecated, Internal, SqlComputeCode = { set {MasterOccId} = {HeadOccId} }, SqlComputed ];

Property RelationOccId As %Integer;

Property TailOccId As %Integer;

Property SlaveOccId As %Integer [ Calculated, Deprecated, Internal, SqlComputeCode = { set {SlaveOccId} = {TailOccId} }, SqlComputed ];

Property SentenceId As %Integer;

Property PosInSentence As %Integer;

Property CcUniId As %Integer [ Calculated, SqlComputeCode = { n crc  set crc = $g(^IRIS.IK.CrcUniId({DomainId},{CrcUniId})), {CcUniId} = $g(^IRIS.IK.CcUni({DomainId},$lg(crc,1,0),$lg(crc,3,0))) }, SqlComputed ];

Index PKINDEX On (DomainId, CrcOccurrenceId) [ IdKey, PrimaryKey, Unique ];

Property CrcUnique As %iKnow.Objects.CrcUnique [ Calculated, SqlComputeCode = { set {CrcUnique} = {DomainId} _"||"_ {CrcUniId} }, SqlComputed ];

Property CcUnique As %iKnow.Objects.CcUnique [ Calculated, SqlComputeCode = { set {CcUnique} = {DomainId} _"||"_ {CcUniId} }, SqlComputed ];

Property Sentence As %iKnow.Objects.Sentence [ Calculated, SqlComputeCode = {set {Sentence} = {DomainId} _ "||" _ {SentenceId}}, SqlComputed ];

Property SourceId As %Integer [ Calculated, SqlComputeCode = {set {SourceId} = ##class(%iKnow.Queries.SentenceAPI).GetSourceId({DomainId},{SentenceId}) }, SqlComputed ];

Storage iKnowStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="MainMap">
<Data name="CcUniId">
<Piece>7</Piece>
</Data>
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
<Global>^IRIS.IK.CrcOccId</Global>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{CrcOccurrenceId}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<SQLMap name="SentenceIdx">
<Global>^IRIS.IK.SentDetails</Global>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{SentenceId}</Expression>
</Subscript>
<Subscript name="3">
<AccessType>Other</AccessType>
<Expression>{CrcOccurrenceId}</Expression>
<Invalidcondition name="1">
<Expression>
<![CDATA[{S3}<=$lg({3D},6)]]></Expression>
</Invalidcondition>
<Invalidcondition name="2">
<Expression>{S3}]]($lg({3D},6)+$lg({3D},7))</Expression>
</Invalidcondition>
<Invalidcondition name="3">
<Expression>{S3}["."</Expression>
</Invalidcondition>
<NextCode>n d,b,h s d={3D},b=$lg(d,6),h=b+$lg(d,7)
i (h']]{S3})||'h s {S3}="" QUIT
s:b]]{S3} {S3}=b
s {S3}=$p({S3},".")+1</NextCode>
</Subscript>
<Type>index</Type>
</SQLMap>
<SQLMap name="SourceIdx">
<Global>^IRIS.IK.SrcDetails</Global>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{SourceId}</Expression>
</Subscript>
<Subscript name="3">
<AccessType>Other</AccessType>
<Expression>{CrcOccurrenceId}</Expression>
<Invalidcondition name="1">
<Expression>
<![CDATA[{S3}<=$lg({3D},5)]]></Expression>
</Invalidcondition>
<Invalidcondition name="2">
<Expression>{S3}]]($lg({3D},5)+$lg({3D},6))</Expression>
</Invalidcondition>
<Invalidcondition name="3">
<Expression>{S3}["."</Expression>
</Invalidcondition>
<NextCode>n d,b,h s d={3D},b=$lg(d,5),h=b+$lg(d,6)
i (h']]{S3})||'h s {S3}="" QUIT
s:b]]{S3} {S3}=b
s {S3}=$p({S3},".")+1</NextCode>
</Subscript>
<Type>index</Type>
</SQLMap>
<StreamLocation>^IRIS.IK.Objects.CrcOccurrenceS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
