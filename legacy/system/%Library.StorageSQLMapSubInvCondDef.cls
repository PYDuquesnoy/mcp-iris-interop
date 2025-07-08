/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Contains SQL subscript Invalid Condition information for a storage definition for a class within the 
/// <i>Class Dictionary</i>.
Class %Library.StorageSQLMapSubInvCondDef Extends %AbstractDefinition [ Not ProcedureBlock, StorageStrategy = custom, System = 3 ]
{

Property ClassName As %RawString;

Property StorageName As %RawString;

Property MapName As %RawString;

Property SubscriptName As %RawString;

Property Name As %RawString;

Property Expression As %RawString;

Method %OnNew(initvalue As %String) As %Status [ Private ]
{
 i initvalue[":"
 i  s i%ClassName=$p(initvalue,":",1),i%StorageName=$p(initvalue,":",2),i%MapName=$p(initvalue,":",3),i%SubscriptName=$p(initvalue,":",4),i%Name=$p(initvalue,":",5)
 e  n len s len=$l(initvalue,"."),i%ClassName=$p(initvalue,".",1,len-4),i%StorageName=$p(initvalue,".",len-3),i%MapName=$p(initvalue,".",len-2),i%SubscriptName=$p(initvalue,".",len-1),i%Name=$p(initvalue,".",len)
 i i%ClassName="" q $$$ERROR($$$ClassNameRequired)
 i i%StorageName="" q $$$ERROR($$$StorageNameRequired)
 i i%MapName="" q $$$ERROR($$$StorageSQLMapNameRequired)
 i i%SubscriptName="" q $$$ERROR($$$StorageSQLMapSubscriptNameRequired)
 i i%Name="" q $$$ERROR($$$StorageSQLMapSubscriptNameRequired)
 ;
 q $$$OK
}

Method %OnValidateObject() As %Status [ Private ]
{
 i i%ClassName="" q $$$ERROR($$$ClassNameRequired)
 i i%StorageName="" q $$$ERROR($$$StorageNameRequired)
 i i%MapName="" q $$$ERROR($$$StorageSQLMapNameRequired)
 i i%SubscriptName="" q $$$ERROR($$$StorageSQLMapSubscriptNameRequired)
 i i%Name="" q $$$ERROR($$$StorageSQLMapSubscriptNameRequired)
 q $$$OK
}

Method %LoadData(id As %String) As %Status [ Private ]
{
 n classname,storagename,mapname,subsname,condname
 i id[":"
 i  s classname=$p(id,":",1),storagename=$p(id,":",2),mapname=$p(id,":",3),subsname=$p(id,":",4),condname=$p(id,":",5)
 e  n len s len=$l(id,"."),classname=$p(id,".",1,len-4),storagename=$p(id,".",len-3),mapname=$p(id,".",len-2),subsname=$p(id,".",len-1),condname=$p(id,".",len)

 s i%ClassName=classname
 s i%StorageName=storagename
 s i%MapName=mapname
 s i%SubscriptName=subsname
 s i%Name=condname
 s i%Expression=$$$defStorageSubSubSubMemberKeyGet(classname,$$$cCLASSstorage,storagename,$$$cSDEFsqlmap,mapname,$$$cSDEFSQLMAPsubscript,subsname,$$$cSDEFSQLMAPSUBinvalidcondition,condname,$$$cSDEFSQLMAPSUBINVCONDexpression)
 q $$$OK
}

Method %SaveData(id As %String) As %Status [ Private ]
{
 i i%ClassName="" q $$$ERROR($$$ClassNameRequired)
 i i%StorageName="" q $$$ERROR($$$StorageNameRequired)
 i i%MapName="" q $$$ERROR($$$StorageSQLMapNameRequired)
 i i%SubscriptName="" q $$$ERROR($$$StorageSQLMapSubscriptNameRequired)
 i i%Name="" q $$$ERROR($$$StorageSQLMapSubscriptNameRequired)
 ;
 n classname,storagename,mapname,subsname,condname
 s classname=i%ClassName
 s storagename=i%StorageName
 s mapname=i%MapName
 s subsname=i%SubscriptName
 s condname=i%Name

 i id="" n sc s sc=..%IdSet(classname_":"_storagename_":"_mapname_":"_subsname_":"_condname) i $$$ISERR(sc) QUIT sc

 #define SAVESUBSUBSUBKEYWORD(%class,%kind,%member,%keyword,%submember,%subkey,%subsubmember,%subsubkey,%subsubsubmember,%subsubsubkey,%value) i %value'=$$$tableDefaultGet(%subsubkey,%subsubsubkey) { $$$defStorageSubSubSubMemberKeySet(%class,%kind,%member,%keyword,%submember,%subkey,%subsubmember,%subsubkey,%subsubsubmember,%subsubsubkey,%value) } Else { $$$defStorageSubSubSubMemberKeyKill(%class,%kind,%member,%keyword,%submember,%subkey,%subsubmember,%subsubkey,%subsubsubmember,%subsubsubkey) }

 $$$SAVESUBSUBSUBKEYWORD(classname,$$$cCLASSstorage,storagename,$$$cSDEFsqlmap,mapname,$$$cSDEFSQLMAPsubscript,subsname,$$$cSDEFSQLMAPSUBinvalidcondition,condname,$$$cSDEFSQLMAPSUBINVCONDexpression,i%Expression)

 q $$$OK
}

ClassMethod %DeleteData(id As %String, concurrency As %Integer) As %Status [ Private ]
{
 n classname,storagename,mapname,subsname,condname
 s classname=$p(id,":",1)
 s storagename=$p(id,":",2)
 s mapname=$p(id,":",3)
 s subsname=$p(id,":",4)
 s condname=$p(id,":",5)
 i classname="" q $$$ERROR($$$ClassNameRequired)
 i storagename="" q $$$ERROR($$$StorageNameRequired)
 i mapname="" q $$$ERROR($$$StorageSQLMapNameRequired)
 i subsname="" q $$$ERROR($$$StorageSQLMapSubscriptNameRequired)
 i condname="" q $$$ERROR($$$StorageSQLMapSubscriptNameRequired)
 $$$defStorageSubSubSubMemberKill(classname,$$$cCLASSstorage,storagename,$$$cSDEFsqlmap,mapname,$$$cSDEFSQLMAPsubscript,subsname,$$$cSDEFSQLMAPSUBinvalidcondition,condname)
 $$$defClassKeySet(classname,$$$cCLASStimechanged,$H)
 q $$$OK
}

Storage custom
{
<ExtentSize>100000</ExtentSize>
<StreamLocation>^%Library.StorageSQLMapSubInvCoS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
