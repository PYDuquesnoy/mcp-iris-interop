/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This file stores the descriptive information for all fields in a file for a FileMan managed database.
/// <p>Note: The FileMan toolset is available and fully supported in InterSystems IRIS for existing FileMan users.
/// InterSystems recommends against starting new development projects using FileMan.</p>
Class %FileMan.Field Extends %Persistent [ Deprecated, Owner = {_SYSTEM}, SqlRowIdPrivate, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

Property CHARACTERISTICS As %String;

Property DESCRIPTION As list Of %String [ SqlListType = SUBNODE ];

Property NAME As %String;

Property NUMBER As %Numeric;

Index IdKey On NUMBER [ IdKey, PrimaryKey, Unique ];

Relationship FILE As %FileMan.File [ Cardinality = parent, Inverse = FIELDS ];

Query AllFields(file As %Library.String) As %SQLQuery [ SqlName = AllFields, SqlProc ]
{
SELECT NUMBER,NAME FROM %FileMan.Field
 WHERE "FILE" = :file OR :file IS NULL
 ORDER BY NUMBER
}

Query AllFieldsByName(file As %Library.String) As %SQLQuery [ SqlName = AllFieldsByName, SqlProc ]
{
SELECT NUMBER,NAME FROM %FileMan.Field
 WHERE "FILE" = :file OR :file IS NULL
 ORDER BY NAME
}

Storage SQLStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Data name="CHARACTERISTICS">
<Delimiter>"^"</Delimiter>
<Node>0</Node>
<Piece>2</Piece>
</Data>
<Data name="DESCRIPTION">
<RetrievalCode> new i set i=$piece($get(^DD({L1},{L2},21,0)),"^",3)
 set {DESCRIPTION}=""
 for i=1:1:i set {DESCRIPTION}={DESCRIPTION}_$listbuild($get(^DD({L1},{L2},21,i,0)))</RetrievalCode>
</Data>
<Data name="NAME">
<Delimiter>"^"</Delimiter>
<Node>0</Node>
<Piece>1</Piece>
</Data>
<Global>^DD</Global>
<Subscript name="1">
<Expression>{%FileMan.File.NUMBER}</Expression>
<Invalidcondition name="1">
<Expression>
<![CDATA[{L1}'>0]]></Expression>
</Invalidcondition>
<NextCode>	s:{L1}="" {L1}=0 s {L1}=$o(^({L1})) s:'{L1} {L1}=""
	;PREV
	s:{L1}="" {L1}=0 s {L1}=$o(^({L1}),-1) s:'{L1} {L1}=""</NextCode>
</Subscript>
<Subscript name="2">
<Expression>{NUMBER}</Expression>
<Invalidcondition name="1">
<Expression>
<![CDATA[{L1}'>0]]></Expression>
</Invalidcondition>
<NextCode>	s:{L2}="" {L2}=0 s {L2}=$o(^({L2})) s:'{L2} {L2}=""
	;PREV
	s:{L2}="" {L2}=0 s {L2}=$o(^({L2}),-1) s:'{L2} {L2}=""</NextCode>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%FileMan.FileS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
