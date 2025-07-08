/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %cspBuild

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.<p>
/// Provide two queries to enumerate the CSP applications in this namespace, and
/// then to enumerate the files and directories for each of these applications.
Class %CSP.Apps Extends %RegisteredObject [ System = 3 ]
{

/// Query to enumerate CSP applications.
Query CSPAppList() As %Query(ROWSPEC = "AppUrl:%String") [ Internal, SqlProc ]
{
}

/// Execute method for query to enumerate CSP applications.
ClassMethod CSPAppListExecute(ByRef QHandle As %Binary) As %Status [ Internal ]
{
	Set QHandle=""
	Do CSPAppList^%SYS.cspServer2(.tmp)
	Set tmp=$order(tmp(""))
	While tmp'="" {
		Set QHandle=QHandle_$listbuild(tmp)
		Set tmp=$order(tmp(tmp))
	}
	
	#; Qhandle is $listbuild(collection,index)
	Set QHandle=$listbuild(QHandle,"")
	
	Quit $$$OK
}

/// Close method for query to enumerate CSP applications.
ClassMethod CSPAppListClose(QHandle As %Binary) As %Status [ Internal ]
{
	#; close the collection
	Set QHandle=""
	Quit $$$OK
}

/// Fetch method for query to enumerate CSP applications.
ClassMethod CSPAppListFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
	Set Row="",AtEnd=0
	
	Set apps=$listget(QHandle)
	Set index=$listget(QHandle,2)+1
	If apps="" Quit $$$ERROR($$$CSPAppFetch)
	
	Set $list(QHandle,2)=index
	If index=""||(index>$listlength(apps)) Set AtEnd=1 Quit $$$OK
	
	Set Row=$listbuild($list(apps,index))
	
	Quit $$$OK
}

/// Query to enumerate CSP files and directories.
Query CSPFileSet(directory As %String) As %Query(ROWSPEC = "Name:%String,Type:%String,Size:%Integer,DateCreated:%TimeStamp,DateModified:%TimeStamp") [ Internal, SqlProc ]
{
}

/// Execute method for query to enumerate CSP files and directories.
ClassMethod CSPFileSetExecute(ByRef QHandle As %Binary, url As %String) As %Status [ Internal ]
{
	Set QHandle=""
	If $E(url,$L(url))="/"!($E(url,$L(url))="\") Set url=$E(url,1,$L(url)-1)
	Set setting=$$getapp^%SYS.cspServer(url_"/",.path)
	If setting="" Quit $$$ERROR($$$CSPApplicationDoesNotExist,url)
	Set recurse=+$$$GetSecurityApplicationsRecurse(setting)
	Set dir=##class(%File).NormalizeDirectory($$GetFilename^%apiCSP(url_"/"))
	If '##class(%File).DirectoryExists(dir) Quit $$$ERROR($$$CSPAppDirDoesNotExist,dir,url)
	
	Set f=$zsearch(dir_"*")
	While f'="" {
		Set isdir=##class(%File).DirectoryExists(f)
		#; Do not show directories if this application does not recurse
		If 'recurse,isdir Set f=$zsearch("") Continue
		#; Do not show the '.' and '..' entries
		If isdir,$extract($translate(f,"\","/"),$length(f)-2,*)="/.."||($extract($translate(f,"\","/"),$length(f)-1,*)="/.") Set f=$zsearch("") Continue
		Set ext=$zconvert($piece($piece(f,".",$length(f,".")),";"),"l")
		#; Only store CSP, CSR files and directories
		If ext="csp"||(ext="csr")||isdir Set QHandle=QHandle_$listbuild(f)
		Set f=$zsearch("")
	}
	
	#; qhandle is $LB(QHandle,index,dirlen)
	Set QHandle=$LB(QHandle,0,$L(dir)+1)
	
	Quit $$$OK
}

/// Close method for query to enumerate CSP files and directories.
ClassMethod CSPFileSetClose(QHandle As %Binary) As %Status [ Internal ]
{
	#; close the collection
	Set QHandle=""
	Quit $$$OK
}

/// Fetch method for query to enumerate CSP files and directories.
ClassMethod CSPFileSetFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal ]
{
	Set Row="",AtEnd=0
	
	Set files=$listget(QHandle),index=$listget(QHandle,2),dirlen=$listget(QHandle,3)
	If (files="")||(index="") Quit $$$ERROR(0)
	
	Set index=index+1
	Set $list(QHandle,2)=index
	If index>$listlength(files) Set AtEnd=1 Quit $$$OK
	
	Set f=$list(files,index)
	
	#; name,type,size,create,modify
	Set dt=$zu(140,3,f)
	Set crdate=$select(dt>0:$zdt(dt,3),1:"")
	Set dt=$zu(140,2,f)
	Set mddate=$select(dt>0:$zdt(dt,3),1:"")
	Set Row=$LB($E(f,dirlen,*),$S(##class(%File).DirectoryExists(f):"D",1:"F"),$zu(140,1,f),crdate,mddate)
	
	Quit $$$OK
}

}
