/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Represent the package information used by the class compiler.
Class %Studio.Package Extends %Persistent [ System = 3 ]
{

/// Lock an individual package definition.
/// If <var>lock</var> is true it is locked and if it is false then
/// it is unlocked.
ClassMethod LockItem(name As %String, lock As %Boolean = 1) As %Status
{
	If $$CheckProtect^%occSAX($zconvert(name,"U")_".pkg") Quit $$$ERROR($$$RoutineProtect,name_".pkg")
	If $data(^oddPKG($zconvert(name,"U"))),$get(^oddPKG($zconvert(name,"U"),"name"))'="",^oddPKG($zconvert(name,"U"),"name")'=name Quit $$$ERROR($$$IncorrectPackageName,name,^oddPKG($zconvert(name,"U"),"name"))
	If lock,$isobject($get(%SourceControl)) {
		Set edit=0,isinsourcecontrol=0,ischeckedout=0,user=""
		Do
		. Set tmp=%SourceControl New %SourceControl Set sc=tmp.GetStatus(name_".PKG",.isinsourcecontrol,.edit,.ischeckedout,.user)
		If $$$ISERR(sc) Quit sc
		If 'edit Quit ##class(%RoutineMgr).ConstructEditError(name_".PKG",isinsourcecontrol,ischeckedout,user)
		If lock {
			Quit ##Class(%SYS.GlobalQuery).Lock("oddPKG",name,name_".pkg")
		} else {
			Quit ##Class(%SYS.GlobalQuery).UnLock("oddPKG",name,0)
		}
	} Else {
		If lock {
			Quit ##Class(%SYS.GlobalQuery).Lock("oddPKG",name,name_".pkg")
		} else {
			Quit ##Class(%SYS.GlobalQuery).UnLock("oddPKG",name,0)
		}
	}
	Quit $$$OK
}

/// Return true if this package information already exists and false otherwise
ClassMethod Exists(name As %String) As %Boolean
{
	Quit ''$data(^oddPKG($zconvert(name,"U")))
}

Storage Default
{
<Data name="PackageDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^%Studio.PackageD</DataLocation>
<DefaultData>PackageDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%Studio.PackageD</IdLocation>
<IndexLocation>^%Studio.PackageI</IndexLocation>
<StreamLocation>^%Studio.PackageS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
