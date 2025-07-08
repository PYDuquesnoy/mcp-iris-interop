/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Note: the use of this class is no longer recommended for accessing elements of a specific domain.
/// For those scenarios, <class>%iKnow.Tables.Utils</class> offers a more flexible and customizable
/// way of projecting iKnow domain data to SQL</p>
/// <p>This is a read-only object representation wrapping the internal iKnow data structures for 
/// Sentences.</p>
/// <p>This class can be used from ObjectScript or SQL to access a single or small number of
/// entries, but the storage mappings are not meant to support elaborate or complex queries
/// targeting this SQL table.</p>
/// <p>Please use the predefined queries in <class>%iKnow.Queries.SentenceAPI</class> and other query classes
/// to consult sentence data as the internal global structures are designed to optimize performance for
/// these queries rather than general-purpose access.</p>
///  <p>NOTE: This object assumes all underlying data structures are present. Use domain-specific
///  copies of these objects for domains where not all indices are built. See also the 
///  GenerateAllObjectsForDomain() method in <class>%iKnow.Objects.Utils</class>.</p>
Class %iKnow.Objects.Sentence Extends %Persistent [ Deprecated, StorageStrategy = iKnowStorage, System = 4 ]
{

Parameter READONLY = 1;

Property DomainId As %Integer;

Property SentenceId As %Integer;

Property SentenceValue As %String(MAXLEN = 32000) [ Calculated, SqlComputeCode = {set {SentenceValue} = ##class(%iKnow.Queries.SentenceAPI).GetValue({DomainId},{SentenceId})}, SqlComputed ];

Property Position As %Integer [ Calculated, SqlComputeCode = {set {Position} = ##class(%iKnow.Queries.SentenceAPI).GetPosition({DomainId},{SentenceId}) }, SqlComputed ];

Property LanguageId As %Integer;

Property LanguageConfidence As %Numeric;

Property SummaryRelevance As %Numeric;

Index PKINDEX On (DomainId, SentenceId) [ IdKey, PrimaryKey, Unique ];

Property SourceId As %Integer [ Calculated, SqlComputeCode = {set {SourceId} = ##class(%iKnow.Queries.SentenceAPI).GetSourceId({DomainId},{SentenceId})}, SqlComputed ];

Property Source As %iKnow.Objects.Source [ Calculated, SqlComputeCode = {set {Source} = {DomainId} _"||"_ ##class(%iKnow.Queries.SentenceAPI).GetSourceId({DomainId},{SentenceId})}, SqlComputed ];

Storage iKnowStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="MainMap">
<Data name="LanguageConfidence">
<Piece>2</Piece>
</Data>
<Data name="LanguageId">
<Piece>1</Piece>
</Data>
<Data name="SummaryRelevance">
<Piece>3</Piece>
</Data>
<Global>^IRIS.IK.SentDetails</Global>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{SentenceId}</Expression>
</Subscript>
<Type>data</Type>
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
<Expression>{SentenceId}</Expression>
<Invalidcondition name="1">
<Expression>
<![CDATA[{S3}<=$lg({3D},1)]]></Expression>
</Invalidcondition>
<Invalidcondition name="2">
<Expression>{S3}]]($lg({3D},1)+$lg({3D},2))</Expression>
</Invalidcondition>
<Invalidcondition name="3">
<Expression>{S3}["."</Expression>
</Invalidcondition>
<NextCode>n d,b,h s d={3D},b=$lg(d,1),h=b+$lg(d,2)
i (h']]{S3})||'h s {S3}="" QUIT
s:b]]{S3} {S3}=b
s {S3}=$p({S3},".")+1</NextCode>
</Subscript>
<Type>index</Type>
</SQLMap>
<StreamLocation>^IRIS.IK.Objects.SentenceS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
