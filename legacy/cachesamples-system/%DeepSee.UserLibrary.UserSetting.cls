/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.UserLibrary.UserSetting Extends (%Persistent, %DeepSee.UserLibrary.UserData)
{

Parameter XMLNAME = "userSetting";

Property FullName As %String(MAXLEN = 2000, XMLPROJECTION = "attribute") [ SqlComputeCode = { Set {FullName} = {Name}_"."_$$$DSUSExt }, SqlComputed, Transient ];

Property Name As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property Comment As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property Context As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Property Value As %String(MAXLEN = 2000, XMLPROJECTION = "attribute");

Index Idx On Name [ IdKey ];

Method getIdentifier() As %String
{
	Quit ..Name
}

Method getFullName() As %String
{
	Quit ..getIdentifier()_"."_$$$DSUSExt
}

Storage Default
{
<Data name="NamedFilterDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<Data name="UserSettingsData1">
<Attribute>Context</Attribute>
<Structure>subnode</Structure>
<Subscript>"context"</Subscript>
</Data>
<Data name="UserSettingsData2">
<Attribute>Comment</Attribute>
<Structure>subnode</Structure>
<Subscript>"comment"</Subscript>
</Data>
<Data name="UserSettingsData3">
<Attribute>Value</Attribute>
<Structure>subnode</Structure>
<Subscript>"value"</Subscript>
</Data>
<DataLocation>^DeepSee.User.Settings</DataLocation>
<DefaultData>NamedFilterDefaultData</DefaultData>
<IdLocation>^%DeepSee.UserLB70D.NamedFilterD</IdLocation>
<IndexLocation>^%DeepSee.UserLB70D.NamedFilterI</IndexLocation>
<StreamLocation>^%DeepSee.UserLB70D.NamedFilterS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
