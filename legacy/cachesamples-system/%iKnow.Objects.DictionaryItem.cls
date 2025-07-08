/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p>Note: the use of this class is no longer recommended for accessing elements of a specific domain.
/// For those scenarios, <class>%iKnow.Tables.Utils</class> offers a more flexible and customizable
/// way of projecting iKnow domain data to SQL</p>
/// <p>This is a read-only object representation wrapping the internal iKnow data structures for 
/// Dictionary Items.</p>
/// <p>This class can be used from ObjectScript or SQL to access a single or small number of
/// entries, but the storage mappings are not meant to support elaborate or complex queries
/// targeting this SQL table.</p>
/// <p>Please use the predefined queries in <class>%iKnow.Matching.DictionaryAPI</class> and other query classes
/// to consult Dictionary data as the internal global structures are designed to optimize performance for
/// these queries rather than general-purpose access.</p>
Class %iKnow.Objects.DictionaryItem Extends %Persistent [ Deprecated, StorageStrategy = iKnowStorage, System = 4 ]
{

Parameter READONLY = 1;

Property DomainId As %Integer;

Property DictionaryItemId As %Integer;

Property DictionaryId As %Integer;

Property Name As %String(MAXLEN = 1000);

Property URI As %String(MAXLEN = 1000);

Property DefaultLanguage As %String [ Calculated, SqlComputeCode = {set {DefaultLanguage} = $s({DefaultLanguageId}:$lg($$$IKLANGUAGES,+{DefaultLanguageId}), 1:"") }, SqlComputed ];

Property DefaultLanguageId As %Integer;

Index PKINDEX On (DomainId, DictionaryItemId) [ IdKey, PrimaryKey, Unique ];

Property Dictionary As %iKnow.Objects.Dictionary [ Calculated, SqlComputeCode = {set {Dictionary} = {DomainId} _"||"_ {DictionaryId}}, SqlComputed ];

Index DictIdIndex On (DomainId, DictionaryId);

Index DictItemURIIndex On (DomainId, URI) [ Unique ];

/// Returns a <class>%iKnow.Objects.DictionaryItem</class> object using the supplied identifiers,
/// resolving negative dictionary Item IDs to the appropriate coordinates for a cross-domain
/// dictionary entry.
ClassMethod Open(pDomainId As %Integer, pDictionaryItemId As %Integer) As %iKnow.Objects.DictionaryItem
{
	set:pDictionaryItemId<0 pDomainId=0, pDictionaryItemId=-pDictionaryItemId
	quit ##class(%iKnow.Objects.DictionaryItem).PKINDEXOpen(pDomainId, pDictionaryItemId)
}

Storage iKnowStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="DictIdIndex">
<Global>^IRIS.IK.Mat.DictToItem</Global>
<RowIdSpec name="1">
<Expression>{S1}</Expression>
<Field>DomainId</Field>
</RowIdSpec>
<RowIdSpec name="2">
<Expression>{S3}</Expression>
<Field>DictionaryItemId</Field>
</RowIdSpec>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{DictionaryId}</Expression>
</Subscript>
<Subscript name="3">
<Expression>{DictionaryItemId}</Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<SQLMap name="DictItemURIIndex">
<Data name="DictionaryItemId"/>
<Global>^IRIS.IK.Mat.DictItemURI</Global>
<RowIdSpec name="1">
<Expression>{S1}</Expression>
<Field>DomainId</Field>
</RowIdSpec>
<RowIdSpec name="2">
<Expression>{DictionaryItemId}</Expression>
<Field>DictionaryItemId</Field>
</RowIdSpec>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{URI}</Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<SQLMap name="MainMap">
<Data name="DefaultLanguageId">
<Piece>4</Piece>
</Data>
<Data name="DictionaryId">
<Piece>1</Piece>
</Data>
<Data name="Name">
<Piece>2</Piece>
</Data>
<Data name="URI">
<Piece>3</Piece>
</Data>
<Global>^IRIS.IK.Mat.DictItemId</Global>
<Structure>list</Structure>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{DictionaryItemId}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^IRIS.IK.Objects.Mat.DictItemS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
