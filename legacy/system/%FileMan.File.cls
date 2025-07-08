/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This file stores the descriptive information for all files in the FileMan managed database.
/// <p>Note: The FileMan toolset is available and fully supported in InterSystems IRIS for existing FileMan users.
/// InterSystems recommends against starting new development projects using FileMan.</p>
Class %FileMan.File Extends %Persistent [ Deprecated, Owner = {_SYSTEM}, SqlRowIdPrivate, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

/// FileMan Field Label: 'DATE'  FileMan Field Number: '21'
Property DATE As %Library.FilemanDate [ SqlFieldName = DATE ];

/// FileMan Field Label: 'GLOBAL NAME'  FileMan Field Number: '1'
Property GLOBALNAME As %Library.String(COLLATION = "EXACT", MAXLEN = 255, TRUNCATE = 0) [ SqlComputeCode = { set D0=$piece({%%ID},"||",1),{GLOBAL_NAME}=$S($D(^DIC(D0,0,"GL")):^("GL"),1:"")}, SqlComputed, SqlFieldName = GLOBAL_NAME, Transient ];

/// FileMan Field Label: 'NAME'  FileMan Field Number: '.01'
Property NAME As %Library.String(COLLATION = "EXACT", MAXLEN = 45, MINLEN = 3, TRUNCATE = 0) [ SqlFieldName = NAME ];

/// FileMan Field Label: 'NUMBER'  FileMan Field Number: '.001'
Property NUMBER As %Library.String(COLLATION = "EXACT", TRUNCATE = 0);

/// FileMan Field Label: 'VERSION'  FileMan Field Number: '51'
Property VERSION As %Library.String(COLLATION = "EXACT", MAXLEN = 255, TRUNCATE = 0) [ SqlComputeCode = { set U="^",D0=$piece({%%ID},"||",1),{VERSION}=$P($G(^DD(D0,0,"VR")),U)}, SqlComputed, SqlFieldName = VERSION, Transient ];

Index IDKeyIndex On NUMBER [ IdKey, PrimaryKey, Unique ];

Relationship FIELDS As %FileMan.Field [ Cardinality = children, Inverse = FILE ];

Query AllFiles() As %SQLQuery [ SqlName = AllFiles, SqlProc ]
{
SELECT NUMBER,NAME FROM %FileMan."File"
 WHERE NAME IS NOT NULL
 ORDER BY NUMBER
}

Query AllFilesByName() As %SQLQuery [ SqlName = AllFilesByName, SqlProc ]
{
SELECT NUMBER,NAME FROM %FileMan."File"
 WHERE NAME IS NOT NULL
 ORDER BY NAME
}

Query ListFilesByName(file As %Library.String) As %SQLQuery [ SqlName = ListFilesByName, SqlProc ]
{
SELECT NUMBER,NAME FROM %FileMan."File"
 WHERE "NAME" %STARTSWITH :file
 ORDER BY NAME
}

Storage SQLStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="FILEDataMap">
<Data name="DATE">
<Delimiter>"^"</Delimiter>
<Node>"%A"</Node>
<Piece>2</Piece>
</Data>
<Data name="NAME">
<Delimiter>"^"</Delimiter>
<Node>0</Node>
<Piece>1</Piece>
</Data>
<Global>^DIC</Global>
<Subscript name="1">
<Expression>{NUMBER}</Expression>
<Invalidcondition name="1">
<Expression>
<![CDATA[{L1}'>0]]></Expression>
</Invalidcondition>
<NextCode>	s:{L1}="" {L1}=0 s {L1}=$o(^({L1})) s:'{L1} {L1}=""
	;PREV
	s:{L1}="" {L1}=0 s {L1}=$o(^({L1}),-1) s:'{L1} {L1}=""</NextCode>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%FileMan.FileS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
