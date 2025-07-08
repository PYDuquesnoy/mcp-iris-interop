/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Contains one row for each user-defined data type.
Class %TSQL.sys.usertypes Extends %Persistent [ Final, SqlRowIdName = usertype, System = 4 ]
{

Property name As %String [ Required ];

Property type As %String [ Required ];

Property ident As %TinyInt;

Property allownulls As %Boolean;

/// Physical length of data type
Property length As %Integer [ SqlComputeCode = {
	new dtparam,return,type,val 
 	set type=1,dtparam("MAXLEN")=""
 	set val=$$getodbc^%qadadt({name},.dtparam,.return,0) 
 	set:$g(return)="" return="VARCHAR^12^255^255^0"
 	set {*}=$p(return,"^",3)}, SqlComputed, Transient ];

Property uid As %String;

Index NameIndex On name [ Data = name, Unique ];

ClassMethod GetIRISDatatype(systype As %String, ByRef identity As %TinyInt, allownulls As %TinyInt) As %String [ Final, Language = objectscript ]
{
	&sql(select type, ident, allownulls into :type, :identity, :allownulls from %TSQL_sys.usertypes where name = :systype)
	if SQLCODE'=0 { set identity="",allownulls="" RETURN "" }
	RETURN $$GetDatatype^%qaqpDDLParser(type)
}

Storage Default
{
<Data name="usertypesDefaultData">
<Value name="1">
<Value>name</Value>
</Value>
<Value name="2">
<Value>type</Value>
</Value>
<Value name="3">
<Value>ident</Value>
</Value>
<Value name="4">
<Value>allownulls</Value>
</Value>
<Value name="5">
<Value>uid</Value>
</Value>
</Data>
<DataLocation>^rINDEXSQL("tsql","systypes",1)</DataLocation>
<DefaultData>usertypesDefaultData</DefaultData>
<IdLocation>^rINDEXSQL("tsql","systypes")</IdLocation>
<IndexLocation>^rINDEXSQL("tsql","systypes")</IndexLocation>
<StreamLocation>^%TSQL.sys.usertypesS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
