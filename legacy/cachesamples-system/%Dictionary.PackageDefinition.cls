/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents a specific <i>package</i> description contained within the 
/// <i>Class Dictionary.</i>
Class %Dictionary.PackageDefinition Extends (%Persistent, %Dictionary.PackageDefinitionQuery) [ Inheritance = right, StorageStrategy = custom, System = 2 ]
{

/// A string containing the name of the package.
Property Name As %RawString;

/// A string containing the client name for the package.
Property ClientName As %RawString;

/// A string containing the description of the package.
Property Description As %RawString;

/// A string containing the global prefix of the package, used for data, id, and index locations.
Property GlobalPrefix As %RawString;

/// A string containing the Owner's name of the package.
Property OwnerName As %RawString;

/// A string containing the routine prefix of the package.
Property RtnPrefix As %RawString;

/// A string containing the SQL name of the package.
Property SQLName As %RawString;

Property list As %ListOfDataTypes [ Transient ];

Method %OnNew(initvalue As %String) As %Status [ Private ]
{
 s i%Name=$g(initvalue)
 q $$$OK
}

Method %LoadData(id As %String) As %Status [ Private ]
{
#define LOADVSTRING(%ivar,%global) s %ivar=$g(%global)
	i '$d($$$PACKAGE(id)) q $$$ERROR($$$LoadObjectNotFound)
	If $isobject($get(%SourceControl)) Do  If $$$ISERR(rc) Quit rc
	. Set tmp=%SourceControl New %SourceControl Set rc=tmp.OnBeforeLoad(id_".PKG")
	s i%Name=id
	$$$LOADVSTRING(name,$$$PACKAGEname(i%Name)) i name'="" s i%Name=name
	$$$LOADVSTRING(i%ClientName,$$$PACKAGEclientname(i%Name))
	$$$LOADVSTRING(i%Description,$$$PACKAGEdescription(i%Name))
	$$$LOADVSTRING(i%GlobalPrefix,$$$PACKAGEglobalprefix(i%Name))
	$$$LOADVSTRING(i%OwnerName,$$$PACKAGEownername(i%Name))
	$$$LOADVSTRING(i%RtnPrefix,$$$PACKAGErtnprefix(i%Name))
	$$$LOADVSTRING(i%SQLName,$$$PACKAGEsqlname(i%Name))
	If $isobject($get(%SourceControl)) Do  If $$$ISERR(rc) Quit rc
	. Set tmp=%SourceControl New %SourceControl Set rc=tmp.OnAfterLoad(id_".PKG",$this)
	q $$$OK
}

Method %SaveData(id As %String) As %Status [ Private ]
{
#define SAVEOPTIONAL(%global,%ivar) s %global=%ivar k:%ivar="" %global
	i i%Name="" q $$$ERROR($$$PackageNameRequired)
	i id="" s sc=..%IdSet(i%Name) i $$$ISERR(sc) q sc
	If $isobject($get(%SourceControl)) Do  If $$$ISERR(rc) Quit rc
	. Set tmp=%SourceControl New %SourceControl Set rc=tmp.OnBeforeSave(i%Name_".PKG",$name(^oddPKG(i%Name)),$this)
	$$$SAVEOPTIONAL($$$PACKAGEname(i%Name),i%Name)
	$$$SAVEOPTIONAL($$$PACKAGEclientname(i%Name),i%ClientName)
	$$$SAVEOPTIONAL($$$PACKAGEdescription(i%Name),i%Description)
	$$$SAVEOPTIONAL($$$PACKAGEglobalprefix(i%Name),i%GlobalPrefix)
	$$$SAVEOPTIONAL($$$PACKAGEownername(i%Name),i%OwnerName)
	$$$SAVEOPTIONAL($$$PACKAGErtnprefix(i%Name),i%RtnPrefix)
	$$$SAVEOPTIONAL($$$PACKAGEsqlname(i%Name),i%SQLName)
	#; the top node is for system code to query
	s $$$PACKAGE(i%Name)=i%RtnPrefix
	If $isobject($get(%SourceControl)) Do  If $$$ISERR(rc) Quit rc
	. Set tmp=%SourceControl New %SourceControl Set rc=tmp.OnAfterSave(i%Name_".PKG",$this)
	q $$$OK
}

ClassMethod %DeleteData(id As %String, concurrency As %Integer) As %Status [ Private ]
{
	
	i id="" q $$$ERROR($$$PackageNameRequired)
	If $isobject($get(%SourceControl)) Do  If $$$ISERR(rc) Quit rc
	. Set tmp=%SourceControl New %SourceControl Set rc=tmp.OnBeforeDelete(id_".PKG")
	Set sc=$$DeletePackageDefinition^%apiOBJ(id,"-d")
	If $isobject($get(%SourceControl)) Do  If $$$ISERR(rc) Set sc=$$$ADDSC(sc,rc)
	. Set tmp=%SourceControl New %SourceControl Set rc=tmp.OnAfterDelete(id_".PKG")
	Quit sc
}

Method %OnValidateObject() As %Status [ Private ]
{
 i i%Name="" q $$$ERROR($$$PackageNameRequired)
 i $l(i%GlobalPrefix)>31 q $$$ERROR($$$PackageGlobalPrefixTooLong)
 q $$$OK
}

ClassMethod GetPackageList() As %ListOfDataTypes
{
	s tList=##class(%ListOfDataTypes).%New()
	$$$CheckRtnIndexExistsThrow
	s class="" 
	f  s class=$o(^rINDEXCLASS(class)) q:class=""  s package=$$$ClassPackageName(class) s:package'="" packagelist(package)=""
	s package="" 
	f  s package=$$$PACKAGEnext(package) q:package=""  s packagelist($zcvt(package,"u"))=""
	s package="" 
	f  s package=$o(packagelist(package)) q:package=""  d tList.Insert(package)
	q tList
}

Storage custom
{
<ExtentSize>100000</ExtentSize>
<StreamLocation>^%Diction.PackageDefinitionS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
