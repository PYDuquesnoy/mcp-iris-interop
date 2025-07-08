/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements SASchema which is loaded from an OS file
Class %Studio.SASchemaFile Extends %Studio.SASchema [ System = 4 ]
{

/// The filename is passed in as <var>pParameter</var>.<br>
/// <var>pChecksum</var> is set to the file's modified time.
ClassMethod OutputToStream(pStream As %Stream.Object, Output pChecksum As %String, pParameter As %String = "") As %Status
{
	if pParameter="" quit $$$ERROR($$$FileNameRequired)
	set tFilename=..getFilename(pParameter)
	set tStream=##class(%FileCharacterStream).%New()
	set tSC=tStream.LinkToFile(tFilename) quit:$$$ISERR(tSC) tSC
	set tSC=pStream.CopyFrom(tStream) quit:$$$ISERR(tSC) tSC
	set pChecksum=##class(%File).GetFileDateModified(tFilename)
	quit $$$OK
}

/// return true if the file has not been modified
ClassMethod IsUpToDate(pChecksum As %String, pParameter As %String) As %Boolean
{
	set tFilename=..getFilename(pParameter)
	quit pChecksum=##class(%File).GetFileDateModified(tFilename)
}

ClassMethod getFilename(pParameter) As %String
{
	for  {
		set f=$f(pParameter,"<CacheRoot>") quit:f=0
		set $e(pParameter,f-11,f-1)=$e($SYSTEM.Util.InstallDirectory(),1,*-1)
	}
	quit pParameter
}

}
