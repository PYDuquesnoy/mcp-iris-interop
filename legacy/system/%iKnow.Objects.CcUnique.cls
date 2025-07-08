/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p>Note: the use of this class is no longer recommended for accessing elements of a specific domain.
/// For those scenarios, <class>%iKnow.Tables.Utils</class> offers a more flexible and customizable
/// way of projecting iKnow domain data to SQL</p>
///  <p>This is a read-only object representation wrapping the internal iKnow data structures for 
///  unique CCs.</p>
///  <p>This class can be used from ObjectScript or SQL to access a single or small number of
///  entries, but the storage mappings are not meant to support elaborate or complex queries
///  targeting this SQL table.</p>
///  <p>Please use the predefined queries in <class>%iKnow.Queries.CcAPI</class> and other query classes
///  to consult CC data as the internal global structures are designed to optimize performance for
///  these queries rather than general-purpose access.</p>
///  <p>NOTE: This object assumes all underlying data structures are present. Use domain-specific
///  copies of these objects for domains where not all indices are built. See also the 
///  GenerateAllObjectsForDomain() method in <class>%iKnow.Objects.Utils</class>.</p>
Class %iKnow.Objects.CcUnique Extends %Persistent [ Deprecated, StorageStrategy = iKnowStorage, System = 4 ]
{

Parameter READONLY = 1;

Property DomainId As %Integer;

Property CcUniId As %Integer;

Property HeadId As %Integer;

Property MasterId As %Integer [ Calculated, Deprecated, Internal, SqlComputeCode = { set {MasterId} = {HeadId} }, SqlComputed ];

Property TailId As %Integer;

Property SlaveId As %Integer [ Calculated, Deprecated, Internal, SqlComputeCode = { set {SlaveId} = {TailId}}, SqlComputed ];

Property CorpusFrequency As %Integer [ Calculated, SqlComputeCode = { set {CorpusFrequency} = $lg(^IRIS.IK.CcUniDet({DomainId},{CcUniId}),1) }, SqlComputed ];

Property CorpusSpread As %Integer [ Calculated, SqlComputeCode = { set {CorpusSpread} = $lg(^IRIS.IK.CcUniDet({DomainId},{CcUniId}),2) }, SqlComputed ];

Index PKINDEX On (DomainId, CcUniId) [ IdKey, PrimaryKey, Unique ];

Property Head As %iKnow.Objects.EntityUnique [ Calculated, SqlComputeCode = { set {Head} = {DomainId} _"||"_ {HeadId} }, SqlComputed ];

Property Master As %iKnow.Objects.EntityUnique [ Calculated, Deprecated, Internal, SqlComputeCode = { set {Master} = {DomainId} _"||"_ {MasterId} }, SqlComputed ];

Property Tail As %iKnow.Objects.EntityUnique [ Calculated, SqlComputeCode = { set {Tail} = {DomainId} _"||"_ {TailId} }, SqlComputed ];

Property Slave As %iKnow.Objects.EntityUnique [ Calculated, Deprecated, Internal, SqlComputeCode = { set {Slave} = {DomainId} _"||"_ {SlaveId} }, SqlComputed ];

Index CcUni On (DomainId, HeadId, TailId) [ Unique ];

Index CcUniIdFreq On (DomainId, CorpusFrequency);

Index CcUniIdSpread On (DomainId, CorpusSpread);

Storage iKnowStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="CcUni">
<Data name="CcUniId"/>
<Global>^IRIS.IK.CcUni</Global>
<RowIdSpec name="1">
<Expression>{S1}</Expression>
<Field>DomainId</Field>
</RowIdSpec>
<RowIdSpec name="2">
<Expression>{CcUniId}</Expression>
<Field>CcUniId</Field>
</RowIdSpec>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{HeadId}</Expression>
</Subscript>
<Subscript name="3">
<Expression>{TailId}</Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<SQLMap name="CcUniIdFreq">
<Global>^IRIS.IK.CcUniIdFreq</Global>
<RowIdSpec name="1">
<Expression>{S1}</Expression>
<Field>DomainId</Field>
</RowIdSpec>
<RowIdSpec name="2">
<Expression>{S3}</Expression>
<Field>CcUniId</Field>
</RowIdSpec>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>-{CorpusFrequency}</Expression>
</Subscript>
<Subscript name="3">
<Expression>{CcUniId}</Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<SQLMap name="CcUniIdSpread">
<Global>^IRIS.IK.CcUniIdSpread</Global>
<RowIdSpec name="1">
<Expression>{S1}</Expression>
<Field>DomainId</Field>
</RowIdSpec>
<RowIdSpec name="2">
<Expression>{S3}</Expression>
<Field>CcUniId</Field>
</RowIdSpec>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>-{CorpusSpread}</Expression>
</Subscript>
<Subscript name="3">
<Expression>{CcUniId}</Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<SQLMap name="MainMap">
<Data name="HeadId">
<Piece>1</Piece>
</Data>
<Data name="TailId">
<Piece>2</Piece>
</Data>
<Global>^IRIS.IK.CcUniId</Global>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{CcUniId}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^IRIS.IK.Objects.CcUniqueS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
