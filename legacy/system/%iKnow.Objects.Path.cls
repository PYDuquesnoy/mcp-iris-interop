/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Note: the use of this class is no longer recommended for accessing elements of a specific domain.
/// For those scenarios, <class>%iKnow.Tables.Utils</class> offers a more flexible and customizable
/// way of projecting iKnow domain data to SQL</p>
/// <p>This is a read-only object representation wrapping the internal iKnow data structures for 
/// Paths.</p>
/// <p>This class can be used from ObjectScript or SQL to access a single or small number of
/// entries, but the storage mappings are not meant to support elaborate or complex queries
/// targeting this SQL table.</p>
/// <p>Please use the predefined queries in <class>%iKnow.Queries.PathAPI</class> and other query classes
/// to consult Path data as the internal global structures are designed to optimize performance for
/// these queries rather than general-purpose access.</p>
///  <p>NOTE: This object assumes all underlying data structures are present. Use domain-specific
///  copies of these objects for domains where not all indices are built. See also the 
///  GenerateAllObjectsForDomain() method in <class>%iKnow.Objects.Utils</class>.</p>
Class %iKnow.Objects.Path Extends %Persistent [ Deprecated, StorageStrategy = iKnowStorage, System = 4 ]
{

Parameter READONLY = 1;

Property DomainId As %Integer;

Property PathId As %Integer;

Property Entities As %List [ Calculated, SqlComputeCode = { set {Entities} = ##class(%iKnow.Queries.PathAPI).GetEntIds({DomainId},{PathId}) }, SqlComputed ];

Property EntityOccurrences As %List;

Index PKINDEX On (DomainId, PathId) [ IdKey, PrimaryKey, Unique ];

Property SentenceId As %Integer [ Calculated, SqlComputeCode = { set {SentenceId} = ##class(%iKnow.Queries.PathAPI).GetSentenceId({DomainId},{PathId})}, SqlComputed ];

Property Sentence As %iKnow.Objects.Sentence [ Calculated, SqlComputeCode = {set {Sentence} = {DomainId} _"||"_ $list(^IRIS.IK.PathToSent({DomainId}, $order(^IRIS.IK.PathToSent({DomainId}, {PathId}),-1)))}, SqlComputed ];

Property SourceId As %Integer [ Calculated, SqlComputeCode = { set {SourceId} = ##class(%iKnow.Queries.PathAPI).GetSourceId({DomainId},{PathId})}, SqlComputed ];

Property Source As %iKnow.Objects.Source [ Calculated, SqlComputeCode = {set {Source} = {DomainId} _"||"_ $list(^IRIS.IK.PathToSrc({DomainId}, $order(^IRIS.IK.PathToSrc({DomainId}, {PathId}),-1)))}, SqlComputed ];

Storage iKnowStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="MainMap">
<Data name="EntityOccurrences"/>
<Global>^IRIS.IK.PathToEntOcc</Global>
<Structure>list</Structure>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{PathId}</Expression>
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
<Expression>{PathId}</Expression>
<Invalidcondition name="1">
<Expression>
<![CDATA[{S3}<=$lg({3D},8)]]></Expression>
</Invalidcondition>
<Invalidcondition name="2">
<Expression>{S3}]]($lg({3D},8)+$lg({3D},9))</Expression>
</Invalidcondition>
<Invalidcondition name="3">
<Expression>{S3}["."</Expression>
</Invalidcondition>
<NextCode>n d,b,h s d={3D},b=$lg(d,8),h=b+$lg(d,9)
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
<Expression>{PathId}</Expression>
<Invalidcondition name="1">
<Expression>
<![CDATA[{S3}<=$lg({3D},7)]]></Expression>
</Invalidcondition>
<Invalidcondition name="2">
<Expression>{S3}]]($lg({3D},7)+$lg({3D},8))</Expression>
</Invalidcondition>
<Invalidcondition name="3">
<Expression>{S3}["."</Expression>
</Invalidcondition>
<NextCode>n d,b,h s d={3D},b=$lg(d,7),h=b+$lg(d,8)
i (h']]{S3})||'h s {S3}="" QUIT
s:b]]{S3} {S3}=b
s {S3}=$p({S3},".")+1</NextCode>
</Subscript>
<Type>index</Type>
</SQLMap>
<StreamLocation>^IRIS.IK.Objects.PathS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
