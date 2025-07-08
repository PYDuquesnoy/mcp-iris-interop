/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Note: the use of this class is no longer recommended for accessing elements of a specific domain.
/// For those scenarios, <class>%iKnow.Tables.Utils</class> offers a more flexible and customizable
/// way of projecting iKnow domain data to SQL</p>
/// <p>This is a read-only object representation wrapping the internal iKnow data structures for 
/// Metadata fields.</p>
/// <p>This class can be used from ObjectScript or SQL to access a single or small number of
/// entries, but the storage mappings are not meant to support elaborate or complex queries
/// targeting this SQL table.</p>
/// <p>Please use the predefined queries in <class>%iKnow.Queries.MetadataAPI</class> and other query classes
/// to consult metadata as the internal global structures are designed to optimize performance for
/// these queries rather than general-purpose access.</p>
Class %iKnow.Objects.MetadataField Extends %Persistent [ Deprecated, StorageStrategy = iKnowStorage, System = 4 ]
{

Parameter READONLY = 1;

Property DomainId As %Integer;

Property FieldId As %Integer;

Property Name As %String(MAXLEN = 1000);

Property SupportedOperators As %String [ Calculated, SqlComputeCode = { set {SupportedOperators} = $lts($lg(^IRIS.IK.Mdt.FieldId({DomainId},{FieldId}),2))}, SqlComputed ];

Property HasBitstringStorage As %Boolean [ Calculated, SqlComputeCode = { set {HasBitstringStorage} = {StorageType}#2 }, SqlComputed ];

Property StorageType As %Integer;

Property DataType As %String;

Property IsCaseSensitive As %Boolean;

Property ListOfValuesId As %Integer;

Property ValidateListOfValues As %Boolean;

Property Hidden As %Boolean;

Index PKINDEX On (DomainId, FieldId) [ IdKey, PrimaryKey, Unique ];

Index NameIndex On (DomainId, Name) [ Unique ];

Storage iKnowStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="MainMap">
<Data name="DataType">
<Piece>3</Piece>
</Data>
<Data name="Hidden">
<Piece>8</Piece>
</Data>
<Data name="IsCaseSensitive">
<Piece>5</Piece>
</Data>
<Data name="ListOfValuesId">
<Piece>6</Piece>
</Data>
<Data name="Name">
<Piece>1</Piece>
</Data>
<Data name="StorageType">
<Piece>4</Piece>
</Data>
<Data name="ValidateListOfValues">
<Piece>7</Piece>
</Data>
<Global>^IRIS.IK.Mdt.FieldId</Global>
<Structure>list</Structure>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{FieldId}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<SQLMap name="NameIndex">
<Data name="FieldId"/>
<Global>^IRIS.IK.Mdt.Field</Global>
<RowIdSpec name="1">
<Expression>{S1}</Expression>
<Field>DomainId</Field>
</RowIdSpec>
<RowIdSpec name="2">
<Expression>{FieldId}</Expression>
<Field>FieldId</Field>
</RowIdSpec>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>
<![CDATA[$s($lg($g(^IRIS.IK.Sys.DomainD({DomainId})),3)>=3:$$$UPPER({Name}), 1:{Name})]]></Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<StreamLocation>^IRIS.IK.Objects.Mdt.FieldS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
