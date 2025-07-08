/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>Note: the use of this class is no longer recommended for accessing elements of a specific domain.
/// For those scenarios, <class>%iKnow.Tables.Utils</class> offers a more flexible and customizable
/// way of projecting iKnow domain data to SQL</p>
/// <p>This is a read-only object representation wrapping the internal iKnow data structures for 
/// Sources.</p>
/// <p>This class can be used from ObjectScript or SQL to access a single or small number of
/// entries, but the storage mappings are not meant to support elaborate or complex queries
/// targeting this SQL table.</p>
/// <p>Please use the predefined queries in <class>%iKnow.Queries.SourceAPI</class> and other query classes
/// to consult source data as the internal global structures are designed to optimize performance for
/// these queries rather than general-purpose access.</p>
///  <p>NOTE: This object assumes all underlying data structures are present. Use domain-specific
///  copies of these objects for domains where not all indices are built. See also the 
///  GenerateAllObjectsForDomain() method in <class>%iKnow.Objects.Utils</class>.</p>
Class %iKnow.Objects.Source Extends %Persistent [ Deprecated, StorageStrategy = iKnowStorage, System = 4 ]
{

Parameter READONLY = 1;

Property DomainId As %Integer;

Property SourceId As %Integer;

Property ListerId As %Integer;

Property GroupId As %Integer;

Property LocalReference As %String(MAXLEN = 1000);

Property FirstSentenceId As %Integer [ Calculated, SqlComputeCode = { set {FirstSentenceId} = $lg(^IRIS.IK.SrcDetails({DomainId},{SourceId}),1)+1 }, SqlComputed ];

Property SentenceCount As %Integer [ Calculated, SqlComputeCode = { set {SentenceCount} = $lg(^IRIS.IK.SrcDetails({DomainId},{SourceId}),2) }, SqlComputed ];

Property FirstPartId As %Integer [ Calculated, SqlComputeCode = { set {*} = $lg(^IRIS.IK.SrcDetails({DomainId},{SourceId}),3)+1 }, SqlComputed ];

/// This property is deprecated. Use <property>FirstPartId</property>
Property FirstEntityOccurrenceId As %Integer [ Calculated, Internal, SqlComputeCode = { set {FirstEntityOccurrenceId}= {FirstPartId}}, SqlComputed ];

Property PartCount As %Integer [ Calculated, SqlComputeCode = { set {*} = $lg(^IRIS.IK.SrcDetails({DomainId},{SourceId}),4) }, SqlComputed ];

Property EntityOccurrenceCount As %Integer [ Calculated, SqlComputeCode = { set {*} = ##class(%iKnow.Queries.EntityAPI).GetOccurrenceCountBySource({DomainId},$lb({SourceId}),,$$$ENTTYPEANY) }, SqlComputed ];

Property FirstCrcOccurrenceId As %Integer [ Calculated, SqlComputeCode = { set {FirstCrcOccurrenceId} = $lg(^IRIS.IK.SrcDetails({DomainId},{SourceId}),5)+1 }, SqlComputed ];

Property CrcOccurrenceCount As %Integer [ Calculated, SqlComputeCode = { set {CrcOccurrenceCount} = $lg(^IRIS.IK.SrcDetails({DomainId},{SourceId}),6) }, SqlComputed ];

Property FirstPathId As %Integer [ Calculated, SqlComputeCode = { set {FirstPathId} = $lg(^IRIS.IK.SrcDetails({DomainId},{SourceId}),7)+1 }, SqlComputed ];

Property PathCount As %Integer [ Calculated, SqlComputeCode = { set {PathCount} = $lg(^IRIS.IK.SrcDetails({DomainId},{SourceId}),8) }, SqlComputed ];

Property ExternalId As %String(MAXLEN = 2000) [ Calculated, SqlComputeCode = { set {ExternalId} = ##class(%iKnow.Queries.SourceAPI).GetExternalId({DomainId},{SourceId}) }, SqlComputed ];

Property FullText As %String(MAXLEN = "") [ Calculated, SqlComputeCode = { new txt,from,to,i,o,more  s txt = "", from=$lg(^IRIS.IK.SrcDetails({DomainId},{SourceId}),1)+1, to=from-1+$lg(^({SourceId}),2) for i = from:1:to { k o  set more = ##class(%iKnow.Queries.SentenceAPI).GetValue({DomainId},i,.o)  set o="" for { set o = $order(o(o),1,more) q:o=""  set txt = txt _ more _ " " } }  set {FullText} = $e(txt,1,*-1) }, SqlComputed ];

Storage iKnowStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="MainMap">
<Data name="GroupId">
<Piece>2</Piece>
</Data>
<Data name="ListerId">
<Piece>1</Piece>
</Data>
<Data name="LocalReference">
<Piece>3</Piece>
</Data>
<Global>^IRIS.IK.SrcId</Global>
<Structure>list</Structure>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{SourceId}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^IRIS.IK.Objects.SourceS</StreamLocation>
<Type>%Storage.SQL</Type>
}

Index PKINDEX On (DomainId, SourceId) [ IdKey, PrimaryKey, Unique ];

}
