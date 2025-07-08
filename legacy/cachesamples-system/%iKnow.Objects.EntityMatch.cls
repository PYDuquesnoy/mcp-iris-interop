/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Note: the use of this class is no longer recommended for accessing elements of a specific domain.
/// For those scenarios, <class>%iKnow.Tables.Utils</class> offers a more flexible and customizable
/// way of projecting iKnow domain data to SQL</p>
/// <p>This is a read-only object representation wrapping the internal iKnow data structures for 
/// unique entity-level matches. These are <b>NOT</b> the actual matching results, which are
/// exposed through <class>%iKnow.Objects.DictionaryMatch</class></p>
/// <p>This class can be used from ObjectScript or SQL to access a single or small number of
/// entries, but the storage mappings are not meant to support elaborate or complex queries
/// targeting this SQL table.</p>
/// <p>Please use the predefined queries in <class>%iKnow.Matching.MatchingAPI</class> and other query classes
/// to consult matchig results as the internal global structures are designed to optimize performance for
/// these queries rather than general-purpose access.</p>
Class %iKnow.Objects.EntityMatch Extends %Persistent [ Deprecated, StorageStrategy = iKnowStorage, System = 4 ]
{

Parameter READONLY = 1;

Property DomainId As %Integer;

Property EntUniId As %Integer;

Property DictElemId As %Integer;

Property MatchScore As %Numeric;

Property MatchedWordBits As %String;

Property MatchedWords As %String [ Calculated, SqlComputeCode = { new i  set {MatchedWords} = ""  for i=1:1:$bitcount({MatchedWordBits}) { set {MatchedWords} = {MatchedWords} _ $bit({MatchedWordBits},i) } }, SqlComputed ];

Property IsScattered As %Boolean;

Property FormatOutput As %String;

Property Entity As %iKnow.Objects.EntityUnique [ Calculated, SqlComputeCode = {set {Entity} = {DomainId} _"||"_ {EntUniId}}, SqlComputed ];

Property DictionaryElement As %iKnow.Objects.DictionaryElement [ Calculated, SqlComputeCode = {set {DictionaryElement} = $s({DictElemId}<0:0, 1:{DomainId}) _"||"_ $zabs({DictElemId}) }, SqlComputed ];

Index PKINDEX On (DomainId, EntUniId, DictElemId) [ IdKey, PrimaryKey, Unique ];

Storage iKnowStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="MainMap">
<Data name="FormatOutput">
<Piece>4</Piece>
</Data>
<Data name="IsScattered">
<Piece>3</Piece>
</Data>
<Data name="MatchScore">
<Piece>1</Piece>
</Data>
<Data name="MatchedWordBits">
<Piece>2</Piece>
</Data>
<Global>^IRIS.IK.Mat.EntUniToDictElem</Global>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{EntUniId}</Expression>
</Subscript>
<Subscript name="3">
<Expression>{DictElemId}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^IRIS.IK.Objects.EntMatchS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
