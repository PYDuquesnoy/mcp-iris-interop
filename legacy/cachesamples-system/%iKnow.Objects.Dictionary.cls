/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p>Note: the use of this class is no longer recommended for accessing elements of a specific domain.
/// For those scenarios, <class>%iKnow.Tables.Utils</class> offers a more flexible and customizable
/// way of projecting iKnow domain data to SQL</p>
/// <p>This is a read-only object representation wrapping the internal iKnow data structures for
/// Dictionaries.</p>
/// <p>This class can be used from ObjectScript or SQL to access a single or small number of
/// entries, but the storage mappings are not meant to support elaborate or complex queries
/// targeting this SQL table.</p>
/// <p>Please use the predefined queries in <class>%iKnow.Matching.DictionaryAPI</class> and other query classes
/// to consult Dictionary data as the internal global structures are designed to optimize performance for
/// these queries rather than general-purpose access.</p>
Class %iKnow.Objects.Dictionary Extends %Persistent [ Deprecated, StorageStrategy = iKnowStorage, System = 4 ]
{

Parameter READONLY = 1;

Property DomainId As %Integer;

Property DictionaryId As %Integer;

Property Name As %String(MAXLEN = 1000);

Property Description As %String(MAXLEN = 2000);

Property DefaultLanguage As %String [ Calculated, SqlComputeCode = {set {DefaultLanguage} = $s({DefaultLanguageId}:$lg($$$IKLANGUAGES,+{DefaultLanguageId}), 1:"en") }, SqlComputed ];

Property DefaultLanguageId As %Integer;

Property DefaultProfileId As %Integer;

Index PKINDEX On (DomainId, DictionaryId) [ IdKey, PrimaryKey, Unique ];

Index DictNameIndex On (DomainId, Name) [ Unique ];

/// Returns a <class>%iKnow.Objects.Dictionary</class> object using the supplied identifiers,
/// resolving negative dictionary IDs to the appropriate coordinates for a cross-domain dictionary.
ClassMethod Open(pDomainId As %Integer, pDictionaryId As %Integer) As %iKnow.Objects.Dictionary
{
	set:pDictionaryId<0 pDomainId=0, pDictionaryId=-pDictionaryId
	quit ##class(%iKnow.Objects.Dictionary).PKINDEXOpen(pDomainId, pDictionaryId)
}

Storage iKnowStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="DictNameIndex">
<Data name="DictionaryId"/>
<Global>^IRIS.IK.Mat.Dict</Global>
<RowIdSpec name="1">
<Expression>{S1}</Expression>
<Field>DomainId</Field>
</RowIdSpec>
<RowIdSpec name="2">
<Expression>{DictionaryId}</Expression>
<Field>DictionaryId</Field>
</RowIdSpec>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>
<![CDATA[$s('{DomainId}||($lg($g(^IRIS.IK.Sys.DomainD({DomainId})),3)>=3):$$$UPPER({Name}), 1:{Name})]]></Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<SQLMap name="MainMap">
<Data name="DefaultLanguageId">
<Piece>3</Piece>
</Data>
<Data name="DefaultProfileId">
<Piece>4</Piece>
</Data>
<Data name="Description">
<Piece>2</Piece>
</Data>
<Data name="Name">
<Piece>1</Piece>
</Data>
<Global>^IRIS.IK.Mat.DictId</Global>
<Structure>list</Structure>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{DictionaryId}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^IRIS.IK.Objects.Mat.DictionaryS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
