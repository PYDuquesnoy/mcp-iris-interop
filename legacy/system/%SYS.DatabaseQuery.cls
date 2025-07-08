/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

///  Provides database queries from other namespaces than %SYS.<br>
///  <br>
/// 
Class %SYS.DatabaseQuery Extends %SYSTEM.Help [ Abstract, System = 4 ]
{

///  Default Localization Domain
Parameter DOMAIN = "%Utility";

///  Calculate remaining free space in a database.<br><br>
///  Parameters:<br>
///  Directory - Physical directory of the database.<br>
///  Freespace - (byref) Returned # of MB of freespace in the directory.<br><br>
///  Note: This requires %Admin_Operate:USE permission
ClassMethod GetDatabaseFreeSpace(Directory As %String, ByRef FreeSpace As %Float) As %Status
{
 s $zt="ERROR"
 i '$SYSTEM.Security.Check($$$AdminOperateResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminOperateResourceName_":"_$$$PermUseName)
 $$$AddAllRoleTemporary ; verified 9/26/16 STC
 n $namespace
 s $namespace="%SYS"
 q ##Class(SYS.Database).GetDatabaseFreeSpace(Directory,.FreeSpace)
ERROR s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

///  Calculate remaining free space in a database.<br><br>
///  Parameters:<br>
///  Directory - Physical directory of the database.<br>
///  Freespace - (byref) Returned # of MB of freespace in the directory.<br>
///  FreeBlocks - (byref) Returned # of blocks of freespace in the directory.<br><br>
///  Note: This requires %Admin_Operate:USE permission
ClassMethod GetFreeSpace(Directory As %String, ByRef FreeSpace As %Float, ByRef FreeBlocks As %Integer) As %Status
{
 s $zt="ERROR"
 i '$SYSTEM.Security.Check($$$AdminOperateResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminOperateResourceName_":"_$$$PermUseName)
 $$$AddAllRoleTemporary ; verified 9/26/16 STC
 n $namespace
 s $namespace="%SYS"
 q ##Class(SYS.Database).GetFreeSpace(Directory,.FreeSpace,.FreeBlocks)
ERROR s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

///  Provides a freespace list of all local databases mounted in this configuration.
///  <br><br>
///  Note that calculating the free space may take a while.<br>
///  Parameters:<br>
///  Mask="*" or $lb(directory1,directory2,...)<br>
///  For the FreeSpace Report, You can also enter the following in order to select by database name:<br>
///  <var>"String,String1"</var> - Any name matching one of these elements<br>
///  <var>"String*"</var> - Any Name starting with "String"<br>
///  <var>"String,String1*,String2"</var> - Any Name matching one of these elements, or starting with "String1"<br>
///  Notes:
///  Databases which are not mounted are not returned by this query.<br>
///  This requires %Admin_Operate:USE permission
Query FreeSpace(Mask As %String = "*") As %Query(ROWSPEC = "DatabaseName:%String,Directory:%String,MaxSize:%String,Size:%String,ExpansionSize:%String,Available:%String,Free:%String:% Free,DiskFreeSpace:%String,Status:%String,SizeInt:%Integer,AvailableNum:%String,DiskFreeSpaceNum:%Integer,ReadOnly:%Boolean") [ SqlProc ]
{
}

ClassMethod FreeSpaceExecute(ByRef qHandle As %Binary, Mask As %String = "*") As %Status [ Internal ]
{
 s $zt="ERROR"
 i '$SYSTEM.Security.Check($$$AdminOperateResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminOperateResourceName_":"_$$$PermUseName)
 $$$AddAllRoleTemporary ; verified 9/26/16 STC
 n $namespace
 s $namespace="%SYS"
 q ##class(SYS.Database).ListExecute(.qHandle,Mask,0,1)
ERROR s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

ClassMethod FreeSpaceFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
 s $zt="ERROR"
 i '$SYSTEM.Security.Check($$$AdminOperateResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminOperateResourceName_":"_$$$PermUseName)
 $$$AddAllRoleTemporary ; verified 9/26/16 STC
 n $namespace
 s $namespace="%SYS"
 q ##class(SYS.Database).ListFetch(.qHandle,.Row,.AtEnd)
ERROR s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

ClassMethod FreeSpaceClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = FreeSpaceExecute ]
{
 s $zt="ERROR"
 $$$AddAllRoleTemporary ; verified 9/26/16 STC
 n $namespace
 s $namespace="%SYS"
 q ##class(SYS.Database).ListClose(.qHandle)
ERROR s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

}
