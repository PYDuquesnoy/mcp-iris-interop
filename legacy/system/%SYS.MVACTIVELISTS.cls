/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SYS.MVACTIVELISTS Extends %Persistent [ SqlTableName = MVACTIVELISTS, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

Property Item As %Integer [ Required ];

Property PieceCounter As %Integer [ Required ];

Property RecId As %String(TRUNCATE = 1) [ Required ];

Index IDKeyIndex On (Item, PieceCounter) [ IdKey, Unique ];

Storage SQLStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="MasterMap">
<Data name="RecId"/>
<Global>^IRIS.TempMV.ALD</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<AccessType>Sub</AccessType>
<Expression>$J</Expression>
</Subscript>
<Subscript name="2">
<AccessType>Sub</AccessType>
<Expression>%listId</Expression>
</Subscript>
<Subscript name="3">
<AccessType>Sub</AccessType>
<Expression>{Item}</Expression>
</Subscript>
<Subscript name="4">
<AccessType>Piece</AccessType>
<Delimiter>$c(254)</Delimiter>
<Expression>{PieceCounter}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%SYS.MVACTIVELISTSS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
