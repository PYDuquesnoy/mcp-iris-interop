/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Utils.Version Extends %Persistent [ Owner = {%Developer}, System = 4 ]
{

/// This is the date that the data was changed/saved on.
Property SavedDate As %Date [ Final ];

/// This is the time that the data was changed/saved on.
Property SavedTime As %Time [ Final ];

/// This is the version number of the saved object. This is used to synchronise across systems
Property Version As %Integer;

/// This property is used to ensure that the version is not incremented when synchronisation takes place
Property SyncSave As %Boolean [ Transient ];

Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ CodeMode = generator, Private, ProcedureBlock = 1 ]
{
	$$$GENERATE("	if '..SyncSave {")
	$$$GENERATE("		if '..SavedDateIsModified() set ..SavedDate=+$h")
	$$$GENERATE("		if '..SavedTimeIsModified() set ..SavedTime=$piece($h,"","",2)")
	$$$GENERATE("		if '..VersionIsModified() set ..Version=..Version+1")
	set rs=##class(%ResultSet).%New("%Dictionary.CompiledPropertyQuery:Summary")
	do rs.Execute(%classname)
	while rs.Next() {
		set name=rs.GetData(1)
		if $extract(name,1)'="%" {
			set objProp=##class(%Dictionary.CompiledProperty).%OpenId(%classname_"||"_name,0)
			if (objProp.Relationship=1)&&(objProp.Cardinality="parent") {
				$$$GENERATE("	if ('.."_name_".VersionIsModified())&&('.."_name_".SyncSave) set .."_name_".Version=.."_name_".Version+1")
			}
		}
	}
	do rs.Close()
	kill rs,name
	$$$GENERATE("	}")
	$$$GENERATE("	Quit $$$OK")
	quit $$$OK
}

Storage Default
{
<Data name="VersionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>SavedDate</Value>
</Value>
<Value name="3">
<Value>SavedTime</Value>
</Value>
<Value name="4">
<Value>SyncSave</Value>
</Value>
<Value name="5">
<Value>Version</Value>
</Value>
</Data>
<DataLocation>^WebStress.Utils.VersionD</DataLocation>
<DefaultData>VersionDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^WebStress.Utils.VersionD</IdLocation>
<IndexLocation>^WebStress.Utils.VersionI</IndexLocation>
<StreamLocation>^WebStress.Utils.VersionS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
