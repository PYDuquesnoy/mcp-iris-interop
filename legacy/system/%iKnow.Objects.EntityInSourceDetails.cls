/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p>Note: the use of this class is no longer recommended for accessing elements of a specific domain.
/// For those scenarios, <class>%iKnow.Tables.Utils</class> offers a more flexible and customizable
/// way of projecting iKnow domain data to SQL</p>
///  <p>This is a read-only object representation wrapping the internal iKnow data structures for 
///  Unique Entities, occurring in a specific source. This class groups the aggregated frequency
///  and dominance information of a particular entity in a particular source.</p>
///  <p>This class can be used from ObjectScript or SQL to access a single or small number of
///  entries, but the storage mappings are not meant to support elaborate or complex queries
///  targeting this SQL table.</p>
///  <p>Please use the predefined queries in <class>%iKnow.Queries.EntityAPI</class>,
///  <class>%iKnow.Semantics.DominanceAPI</class> and other query classes
///  to consult Entity data as the internal global structures are designed to optimize performance for
///  these queries rather than general-purpose access.</p>
///  <p>NOTE: This object assumes all underlying data structures are present. Use domain-specific
///  copies of these objects for domains where not all indices are built. See also the 
///  GenerateAllObjectsForDomain() method in <class>%iKnow.Objects.Utils</class>.</p>
Class %iKnow.Objects.EntityInSourceDetails Extends %Persistent [ Deprecated, StorageStrategy = iKnowStorage, System = 4 ]
{

Parameter READONLY = 1;

Property DomainId As %Integer;

Property SourceId As %Integer;

Property EntUniId As %Integer;

Property FrequencyAsConcept As %Integer;

Property FrequencyAsRelation As %Integer;

Property DominanceAsConcept As %Numeric [ Calculated, SqlComputeCode = { set {DominanceAsConcept} = ##class(%iKnow.Semantics.DominanceAPI).GetSourceValue({DomainId},{SourceId},{EntUniId},$$$SDCONCEPT)}, SqlComputed ];

Property DominanceAsRelation As %Numeric [ Calculated, SqlComputeCode = { set {DominanceAsRelation} = ##class(%iKnow.Semantics.DominanceAPI).GetSourceValue({DomainId},{SourceId},{EntUniId},$$$SDRELATION)}, SqlComputed ];

Property Entity As %iKnow.Objects.EntityUnique [ Calculated, SqlComputeCode = {set {Entity} = {DomainId} _"||"_ {EntUniId}}, SqlComputed ];

Property Source As %iKnow.Objects.Source [ Calculated, SqlComputeCode = {set {Source} = {DomainId} _"||"_ {SourceId}}, SqlComputed ];

Index PKINDEX On (DomainId, SourceId, EntUniId) [ IdKey, PrimaryKey, Unique ];

Storage iKnowStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="MainMap">
<Data name="FrequencyAsConcept">
<Piece>1</Piece>
</Data>
<Data name="FrequencyAsRelation">
<Piece>2</Piece>
</Data>
<Global>^IRIS.IK.EntSrcDetails</Global>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{SourceId}</Expression>
</Subscript>
<Subscript name="3">
<Expression>{EntUniId}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^IRIS.IK.Objects.EntInSourceS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
