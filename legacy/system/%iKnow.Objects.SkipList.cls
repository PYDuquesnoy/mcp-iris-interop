/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Note: the use of this class is no longer recommended for accessing elements of a specific domain.
/// For those scenarios, <class>%iKnow.Tables.Utils</class> offers a more flexible and customizable
/// way of projecting iKnow domain data to SQL</p>
/// <p>This is a read-only object representation wrapping the internal iKnow data structures for 
/// skiplists.</p>
/// <p>This class can be used from ObjectScript or SQL to access a single or small number of
/// entries, but the storage mappings are not meant to support elaborate or complex queries
/// targeting this SQL table.</p>
/// <p>Please use the predefined queries in <class>%iKnow.Utils.MaintenanceAPI</class> and other query classes
/// to consult skiplist data as the internal global structures are designed to optimize performance for
/// these queries rather than general-purpose access.</p>
Class %iKnow.Objects.SkipList Extends %Persistent [ Deprecated, StorageStrategy = iKnowStorage, System = 4 ]
{

Parameter READONLY = 1;

Property DomainId As %Integer;

Property SkipListId As %Integer;

Property Name As %String;

Property Description As %String(MAXLEN = "");

Property ManagerClass As %String(MAXLEN = 256);

Index PKINDEX On (DomainId, SkipListId) [ IdKey, PrimaryKey, Unique ];

Storage iKnowStorage
{
<SQLMap name="MainMap">
<Data name="Description">
<Piece>2</Piece>
</Data>
<Data name="ManagerClass">
<Piece>3</Piece>
</Data>
<Data name="Name">
<Piece>1</Piece>
</Data>
<Global>^IRIS.IK.BlackListId</Global>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{SkipListId}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^IRIS.IK.Objects.BlackListS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
