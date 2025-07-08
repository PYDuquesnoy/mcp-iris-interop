/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, %cspBuild)

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.<p>
/// This class works in conjunction with the <i>CacheDWX.dll</i> 
/// and provides server-side  
/// DreamWeaver integration.
Class %CSP.DwxQuery Extends %RegisteredObject [ Not ProcedureBlock, System = 3 ]
{

/// Return 1 to indicate presence of this class.
ClassMethod Exists() As %Boolean [ Internal ]
{
	Quit 1
}

/// Get list of classes.
Query ClassList() As %Query(ROWSPEC = "ID:%String,ClassName:%String") [ SqlProc ]
{
}

/// Execute method for ClassList
ClassMethod ClassListExecute(ByRef QHandle As %Binary) As %Status [ Internal ]
{
 ; run the ClassInfo query and filter it

 New result

 Set result=##class(%ResultSet).%New("%Dictionary.CompiledClassQuery:Summary")
 Do result.Execute()

 ; qhandle is result
 Set QHandle=result

 Quit $$$OK
}

/// Close method for ClassList
ClassMethod ClassListClose(QHandle As %Binary) As %Status [ Internal ]
{
 ; close the result set
 New result
 Set result=QHandle
 Quit:result="" $$$ERROR(0)

 Kill QHandle
 Quit $$$OK
}

/// Fetch method for ClassList
ClassMethod ClassListFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
 If $System.Security.Check("%Development","USE")=0
 {
	 Set Row="",AtEnd=1 Quit $$$OK
 }
 
 New result,next,found
 Set Row="",AtEnd=0,found=0

 Set result=QHandle
 Quit:result="" $$$ERROR(0)

 ; loop until we find a non-system, persistent class
 While 'found {
	 Set next=result.Next()
	 If 'next Quit
	 If (result.GetDataByName("Persistent")=1) &&
	 	(result.GetDataByName("System")=0) &&
	 	(result.GetDataByName("Abstract")=0) {
		 Set found=1
	 }
 }

 Set:'next AtEnd=1,Row=""
 Set:next AtEnd=0,Row=$LB(result.GetDataByName("Name"),result.GetDataByName("Name"))

 Quit $$$OK
}

/// Get list of classes.
Query ClassQueryList() As %Query(ROWSPEC = "ID:%String,ClassName:%String") [ SqlProc ]
{
}

/// Execute method for ClassQueryList
ClassMethod ClassQueryListExecute(ByRef QHandle As %Binary) As %Status [ Internal ]
{
 ; run the ClassInfo query and filter it

 New result

 Set result=##class(%ResultSet).%New("%Dictionary.CompiledClassQuery:Summary")
 Do result.Execute()

 ; qhandle is result
 Set QHandle=result

 Quit $$$OK
}

/// Close method for ClassQueryList
ClassMethod ClassQueryListClose(QHandle As %Binary) As %Status [ Internal ]
{
 ; close the result set
 New result
 Set result=QHandle
 Quit:result="" $$$ERROR(0)

 Kill QHandle
 Quit $$$OK
}

/// Fetch method for ClassQueryList
ClassMethod ClassQueryListFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
 If $System.Security.Check("%Development","USE")=0
 {
	 Set Row="",AtEnd=1 Quit $$$OK
 }
 
 New result,next,found,name
 Set Row="",AtEnd=0,found=0

 Set result=QHandle
 Quit:result="" $$$ERROR(0)

 ; loop until we find a non-system class that is persistent or has a query
 While 'found {
	 Set next=result.Next()
	 If 'next Quit
	 Set name=result.GetDataByName("Name")
	 If (result.GetDataByName("System")=0) &&
	 	(result.GetDataByName("Abstract")=0) &&
	    ((result.GetDataByName("Persistent")=1) || ($$$comMemberNext(name,$$$cCLASSquery,"")'="")) {
		 Set found=1
	 }
 }

 Set:'next AtEnd=1,Row=""
 Set:next AtEnd=0,Row=$LB(name,name)

 Quit $$$OK
}

/// Get list of members that can be used by Wizard for a specific class.
Query MemberList(class As %String) As %Query(ROWSPEC = "ID:%String,MemberName:%String") [ SqlProc ]
{
}

/// Execute method for MemberList
ClassMethod MemberListExecute(ByRef QHandle As %Binary, class As %String) As %Status [ Internal ]
{
 ; run the Compiled Property query and filter it

 ; QHandle format: QHandle(1) = class
 ;                 QHandle(2) = prefix
 ;                 QHandle(3) = count
 ;                 QHandle(3,i) = result
 ; a list of nested result set objects--
 ; always fetch from the lowest level first.
 Set QHandle(1)=class,QHandle(2)="",QHandle(3)=0

 Quit $$$OK
}

/// Close method for MemberList
ClassMethod MemberListClose(QHandle As %Binary) As %Status [ Internal ]
{
 ; close all open result sets
 Kill QHandle
 
 Quit $$$OK
}

/// Fetch method for MemberList
ClassMethod MemberListFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
 If $System.Security.Check("%Development","USE")=0
 {
	 Set Row="",AtEnd=1 Quit $$$OK
 }
 
 New result,next,found,stack,prefix,prop,type,fullname
 Set Row="",AtEnd=0,prop=""

 ; get most deeply nested result set from QHandle
 Set prefix=$Get(QHandle(2))
 Merge stack=QHandle(3)

 If (stack=0) Do
 . ; We're at the beginning, return %Id() and set up for next call
 . Set prop="%Id()"
 . Set fullname=prop
 . Set result=##class(%ResultSet).%New("%CompiledProperty.PropertyInfo")
 . Do result.Execute($Get(QHandle(1)))
 . Set stack=1,stack(1)=result
 Else  Do
 . Set found=0
 . ; start at lowest level
 . Set result=$Get(stack(stack))
 . ; Get list of public properties; nest if we hit a serial property
 . For  Quit:((result="")!(found))  Do
 . . For  Quit:found  Set next=result.Next() Quit:'next  Do
 . . . Set found=1
 . . . Set prop=result.GetDataByName("Name")
 . . . Set type=result.GetDataByName("Type")
 . . . Set fullname=prefix_prop
 . . . If (result.GetDataByName("Serial")=1),(result.GetDataByName("Collection")="") Do
 . . . . ; go down a level
 . . . . Set result=##class(%ResultSet).%New("%CompiledProperty.PropertyInfo")
 . . . . Do result.Execute(type)
 . . . . Set prefix=prefix_prop_"."
 . . . . Set stack=stack+1,stack(stack)=result
 . . If ('found) Do
 . . . ; popup a level
 . . . Kill stack(stack) Set stack=stack-1
 . . . Set result=$Get(stack(stack))
 . . . Set prefix=$P(prefix,".",1,$L(prefix,".")-2)
 . . . Set:prefix'="" prefix=prefix_"."

 If (prop="") Set AtEnd=1,Row=""
 Else  Set AtEnd=0,Row=$LB(fullname,prop)

 Set QHandle(2)=prefix
 Kill QHandle(3)
 Merge QHandle(3)=stack

 Quit $$$OK
}

/// Get list of columns that can be used by Wizard for a specific query.
Query QueryColumnList(class As %String) As %Query(ROWSPEC = "ColumnName:%String") [ SqlProc ]
{
}

/// Execute method for QueryColumnList
ClassMethod QueryColumnListExecute(ByRef QHandle As %Binary, query As %String) As %Status [ Internal ]
{
 new sc,colinfo,paraminfo,idinfo,handle,i
 set QHandle=""
 if $length(query,":")'=2 Quit $$$OK
 set handle=""
 set sc=$classmethod($piece(query,":",1),$piece(query,":",2)_"GetInfo",.colinfo,.paraminfo,.idinfo,.handle)
 if $$$ISERR(sc) Quit $$$OK
 for i=1:1:$listlength(colinfo) set QHandle=QHandle_$select(QHandle="":"",1:",")_$list($list(colinfo,i))
 Quit $$$OK
}

/// Close method for QueryColumnList
ClassMethod QueryColumnListClose(QHandle As %Binary) As %Status [ Internal ]
{
 Quit $$$OK
}

/// Fetch method for QueryColumnList
ClassMethod QueryColumnListFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
 new cols
 set cols=QHandle
 if (cols'="") {
 	set AtEnd=0
 	set Row=$LB($piece(cols,",",1))
 	set QHandle=$piece(cols,",",2,$length(cols,","))
 } else {
 	set AtEnd=1
 	set Row=""
 }

 Quit $$$OK
}

/// Get list of CSP pages.
Query CSPList() As %Query(ROWSPEC = "PageName:%String,PageType:%String") [ SqlProc ]
{
}

/// Execute method for CSPList
ClassMethod CSPListExecute(ByRef QHandle As %Binary) As %Status [ Internal ]
{
	New files,url,app,path
	
	#; create collection of filenames in this directory
	Set files=##class(%ArrayOfDataTypes).%New()
	
	#; build the list of the csp files
	Do CSPFiles^%SYS.cspServer2(files)
	
	#; QHandle format QHandle(1)=collection QHandle(2)=index
	Set QHandle(1)=files,QHandle(2)=""
	
	Quit $$$OK
}

/// Get list of files for CSP path
ClassMethod CSPListDoDir(files As %ArrayOfDataTypes, url As %String, path As %String, recurse As %Boolean) [ Internal ]
{
 New tempnode,file,filename
 If $E(path,$L(path))'="/" Set path=path_"/"
 If $E(url,$L(url))'="/" Set url=url_"/"
 Set tempnode=$Increment(^IRIS.Temp)
 Kill ^IRIS.Temp(tempnode) Set %sc=$$GetFiles^%apiOBJ(path,"*.csp",tempnode)
 Set file="" For  Set file=$O(^IRIS.Temp(tempnode,file)) Quit:file=""  Do
 . Set filename=$TR(file,"\","/"),filename=$P(filename,"/",$L(filename,"/"))
 . Do files.SetAt("",url_filename)
 If recurse Do
 . Kill ^IRIS.Temp(tempnode) Set %sc=$$GetDirs^%apiOBJ(path,"*",tempnode)
 . Set file="" For  Set file=$O(^IRIS.Temp(tempnode,file)) Quit:file=""  Do
 . . Set filename=$TR(file,"\","/"),filename=$P(filename,"/",$L(filename,"/"))
 . . Do ..CSPListDoDir(files,url_filename,file,recurse)
 Kill ^IRIS.Temp(tempnode)
 Quit
}

/// Close method for CSPList
ClassMethod CSPListClose(QHandle As %Binary) As %Status [ Internal ]
{
 ; close the collection
 Kill QHandle
 
 Quit $$$OK
}

/// Fetch method for CSPList
ClassMethod CSPListFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
 If $System.Security.Check("%Development","USE")=0
 {
	 Set Row="",AtEnd=1 Quit $$$OK
 }
 
 New files,index,f
 Set Row="",AtEnd=0

 Set files=$Get(QHandle(1))
 Set index=$Get(QHandle(2))
 If (files="") Quit $$$ERROR(0)

 Set index=files.Next(index)
 Set QHandle(2)=index
 If index="" Set AtEnd=1 Quit $$$OK

 ; name,type,size,create,modify
 Set Row=$LB(index,$P(index,".",$L(index,".")))

 Quit $$$OK
}

}
