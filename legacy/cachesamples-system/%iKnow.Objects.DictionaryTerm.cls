/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p>Note: the use of this class is no longer recommended for accessing elements of a specific domain.
/// For those scenarios, <class>%iKnow.Tables.Utils</class> offers a more flexible and customizable
/// way of projecting iKnow domain data to SQL</p>
/// <p>This is a read-only object representation wrapping the internal iKnow data structures for 
/// Dictionary Terms.</p>
/// <p>This class can be used from ObjectScript or SQL to access a single or small number of
/// entries, but the storage mappings are not meant to support elaborate or complex queries
/// targeting this SQL table.</p>
/// <p>Please use the predefined queries in <class>%iKnow.Matching.DictionaryAPI</class> and other query classes
/// to consult Dictionary data as the internal global structures are designed to optimize performance for
/// these queries rather than general-purpose access.</p>
Class %iKnow.Objects.DictionaryTerm Extends %Persistent [ Deprecated, StorageStrategy = iKnowStorage, System = 4 ]
{

Parameter READONLY = 1;

Property DomainId As %Integer;

Property DictionaryTermId As %Integer;

Property DictionaryId As %Integer;

Property DictionaryItemId As %Integer;

Property String As %String(MAXLEN = 2000);

Property DefaultLanguage As %String [ Calculated, SqlComputeCode = {set {DefaultLanguage} = $s({DefaultLanguageId}:$lg($$$IKLANGUAGES,+{DefaultLanguageId}), 1:"") }, SqlComputed ];

Property DefaultLanguageId As %Integer;

Index PKINDEX On (DomainId, DictionaryTermId) [ IdKey, PrimaryKey, Unique ];

Property Dictionary As %iKnow.Objects.Dictionary [ Calculated, SqlComputeCode = {set {Dictionary} = {DomainId} _"||"_ {DictionaryId}}, SqlComputed ];

Property DictionaryItem As %iKnow.Objects.DictionaryItem [ Calculated, SqlComputeCode = {set {DictionaryItem} = {DomainId} _"||"_ {DictionaryItemId}}, SqlComputed ];

/// Returns a <class>%iKnow.Objects.DictionaryTerm</class> object using the supplied identifiers,
/// resolving negative dictionary Term IDs to the appropriate coordinates for a cross-domain
/// dictionary entry.
ClassMethod Open(pDomainId As %Integer, pDictionaryTermId As %Integer) As %iKnow.Objects.DictionaryTerm
{
	set:pDictionaryTermId<0 pDomainId=0, pDictionaryTermId=-pDictionaryTermId
	quit ##class(%iKnow.Objects.DictionaryTerm).PKINDEXOpen(pDomainId, pDictionaryTermId)
}

Storage iKnowStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="MainMap">
<Data name="DefaultLanguageId">
<Piece>4</Piece>
</Data>
<Data name="DictionaryId">
<Piece>1</Piece>
</Data>
<Data name="DictionaryItemId">
<Piece>2</Piece>
</Data>
<Data name="String">
<Piece>3</Piece>
</Data>
<Global>^IRIS.IK.Mat.DictTermId</Global>
<Structure>list</Structure>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{DictionaryTermId}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^IRIS.IK.Objects.Mat.DictTermS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
