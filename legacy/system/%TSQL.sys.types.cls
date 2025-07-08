/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Contains one row for each system-supplied and each user-defined data type.
Class %TSQL.sys.types Extends %Persistent [ SqlRowIdPrivate, StorageStrategy = TypesStorage, System = 4 ]
{

/// Data type name.
Property name As %String(MAXLEN = 60) [ Required, SqlColumnNumber = 4 ];

/// Physical length of data type
Property length As %Integer [ SqlColumnNumber = 3, SqlComputeCode = { n dtparam,return,type,val 
 s type=1,dtparam("MAXLEN")=""
 s val=$$getodbc^%qadadt({name},.dtparam,.return,0) 
 s:$g(return)="" return="VARCHAR^12^255^255^0"
 s {*}=$p(return,"^",3)}, SqlComputed, Transient ];

/// User type ID
/// In Sybase this is a SMALLINT, but we'll have it a string because we do not have unique ID numbers for our types and classes.
Property usertype As %String(MAXLEN = 50) [ SqlColumnNumber = 2, SqlComputeCode = { s {*}={name}}, SqlComputed, Transient ];

Index nameIDKey On name [ IdKey, Unique ];

Storage TypesStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Global>^oddDEF</Global>
<PopulationType>full</PopulationType>
<RowIdSpec name="1">
<Expression>L1</Expression>
<Field>name</Field>
</RowIdSpec>
<Subscript name="1">
<Expression>{name}</Expression>
<Invalidcondition name="1">
<Expression>
<![CDATA[$e({L1})="%"&&($e({L1},1,9)'="%Library.")]]></Expression>
</Invalidcondition>
<Invalidcondition name="2">
<Expression>
<![CDATA[$s($d(^oddCOM({L1},23))#2:^(23),1:$s($d(^oddDEF({L1},23))#2:^(23),1:$g(^%qObjectKey(1,"c",23))))'="datatype"&&($s($d(^oddCOM({L1},23))#2:^(23),1:$s($d(^oddDEF({L1},23))#2:^(23),1:$g(^%qObjectKey(1,"c",23))))'="stream")]]></Expression>
</Invalidcondition>
<LoopInitValue>"%Library."</LoopInitValue>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%TSQL.sys.typesS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
