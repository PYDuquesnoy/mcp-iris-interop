/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Note: the use of this class is no longer recommended for accessing elements of a specific domain.
/// For those scenarios, <class>%iKnow.Tables.Utils</class> offers a more flexible and customizable
/// way of projecting iKnow domain data to SQL</p>
/// <p>This is a read-only object representation wrapping the internal iKnow data structures for 
/// Metadata field values.</p>
/// <p>This class can be used from ObjectScript or SQL to access a single or small number of
/// entries, but the storage mappings are not meant to support elaborate or complex queries
/// targeting this SQL table.</p>
/// <p>Please use the predefined queries in <class>%iKnow.Queries.MetadataAPI</class> and other query classes
/// to consult metadata as the internal global structures are designed to optimize performance for
/// these queries rather than general-purpose access.</p>
Class %iKnow.Objects.MetadataValue Extends %Persistent [ Deprecated, StorageStrategy = iKnowStorage, System = 4 ]
{

Parameter READONLY = 1;

Property DomainId As %Integer;

Property FieldId As %Integer;

Property SourceId As %Integer;

Property ValueInternal As %String(MAXLEN = 2000) [ Internal, Private ];

Property Value As %String(MAXLEN = 2000) [ Calculated, SqlComputeCode = {set {Value} = $s($lg(^IRIS.IK.Mdt.FieldId({DomainId},{FieldId}),4)<=1:{ValueInternal}, 1:^IRIS.IK.Mdt.UniValueId({DomainId},{ValueInternal})) }, SqlComputed ];

Index PKINDEX On (DomainId, SourceId, FieldId) [ IdKey, PrimaryKey, Unique ];

Property Field As %iKnow.Objects.MetadataField [ Calculated, SqlComputeCode = {set {Field} = {DomainId} _"||"_ {FieldId} }, SqlComputed ];

Storage iKnowStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="MainMap">
<Data name="ValueInternal"/>
<Global>^IRIS.IK.Mdt.Values</Global>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{SourceId}</Expression>
</Subscript>
<Subscript name="3">
<Expression>{FieldId}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^IRIS.IK.Objects.Mdt.ValueS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
