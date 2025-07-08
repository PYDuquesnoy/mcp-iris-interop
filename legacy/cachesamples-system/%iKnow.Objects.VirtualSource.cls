/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This is a read-only object representation wrapping the internal iKnow data structures for 
/// Virtual Sources.</p>
/// <p>This class can be used from ObjectScript or SQL to access a single or small number of
/// entries, but the storage mappings are not meant to support elaborate or complex queries
/// targeting this SQL table.</p>
/// <p>Please use the predefined queries in <class>%iKnow.Queries.SourceAPI</class> and other query classes
/// to consult source data as the internal global structures are designed to optimize performance for
/// these queries rather than general-purpose access.</p>
Class %iKnow.Objects.VirtualSource Extends %Persistent [ Deprecated, StorageStrategy = iKnowStorage, System = 4 ]
{

Parameter READONLY = 1;

Property DomainId As %Integer;

Property VirtualSourceId As %Integer;

Property SourceId As %Integer [ Calculated, SqlComputeCode = { set {SourceId} = -{VirtualSourceId} }, SqlComputed ];

Property ListerId As %Integer [ Calculated, SqlComputeCode = { set {ListerId} = $lg($lg(^IRIS.IKV.SrcId({DomainId},{VirtualSourceId}),4),1) }, SqlComputed ];

Property GroupId As %Integer [ Calculated, SqlComputeCode = { set {GroupId} = $lg($lg(^IRIS.IKV.SrcId({DomainId},{VirtualSourceId}),4),2) }, SqlComputed ];

Property LocalReference As %String(MAXLEN = 1000) [ Calculated, SqlComputeCode = { set {LocalReference} = $lg($lg(^IRIS.IKV.SrcId({DomainId},{VirtualSourceId}),4),3) }, SqlComputed ];

Property FirstSentenceId As %Integer [ Calculated, SqlComputeCode = { set {FirstSentenceId} = $lg(^IRIS.IKV.SrcDetails({DomainId},{VirtualSourceId}),1)+1 }, SqlComputed ];

Property SentenceCount As %Integer;

Property FirstEntityOccurrenceId As %Integer [ Calculated, SqlComputeCode = { set {FirstEntityOccurrenceId} = $lg(^IRIS.IKV.SrcDetails({DomainId},{VirtualSourceId}),3)+1 }, SqlComputed ];

Property EntityOccurrenceCount As %Integer;

Property FirstCrcOccurrenceId As %Integer [ Calculated, SqlComputeCode = { set {FirstCrcOccurrenceId} = $lg(^IRIS.IKV.SrcDetails({DomainId},{VirtualSourceId}),5)+1 }, SqlComputed ];

Property CrcOccurrenceCount As %Integer;

Property FirstPathId As %Integer [ Calculated, SqlComputeCode = { set {FirstPathId} = $lg(^IRIS.IKV.SrcDetails({DomainId},{VirtualSourceId}),7)+1 }, SqlComputed ];

Property PathCount As %Integer;

Property ExternalId As %String(MAXLEN = 2000) [ Calculated, SqlComputeCode = { set {ExternalId} = ##class(%iKnow.Queries.SourceAPI).GetExternalId({DomainId},-{VirtualSourceId}) }, SqlComputed ];

Property FullText As %String(MAXLEN = "") [ Calculated, SqlComputeCode = { new txt,to,i,o,more  s txt = "", to=$lg(^IRIS.IKV.SrcDetails({DomainId},{VirtualSourceId}),2) for i = 1:1:to { k o  set more = ##class(%iKnow.Queries.SentenceAPI).GetValue({DomainId},i,.o,{VirtualSourceId})  set o="" for { set o = $order(o(o),1,more) q:o=""  set txt = txt _ more _ " " } }  set {FullText} = $e(txt,1,*-1) }, SqlComputed ];

Index PKINDEX On (DomainId, VirtualSourceId) [ IdKey, PrimaryKey, Unique ];

Storage iKnowStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="MainMap">
<Data name="CrcOccurrenceCount">
<Piece>6</Piece>
</Data>
<Data name="EntityOccurrenceCount">
<Piece>4</Piece>
</Data>
<Data name="PathCount">
<Piece>8</Piece>
</Data>
<Data name="SentenceCount">
<Piece>2</Piece>
</Data>
<Global>^IRIS.IKV.SrcDetails</Global>
<Structure>list</Structure>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{VirtualSourceId}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^IRIS.IK.Objects.VSourceS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
