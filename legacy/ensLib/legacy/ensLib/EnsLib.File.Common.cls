/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// A helper class for File and FTP adapters defining properties that are common to all
Class EnsLib.File.Common Extends Ens.Util.File [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/* The descriptions here are for the File Outbound adapter. Other adapters override these properties in order to define appropriate descriptions. */
/// The operating system directory where output files should be deposited. Does not include a filename specifier - see Filename. May be prepended with @AgentName:.
Property FilePath As %String(MAXLEN = 1000) [ Required ];

/// Character encoding scheme used for translating output to files. For binary output, use 'Binary'.
/// Other choices include: <br/>
///  Native - the default character encoding of the installed locale of the InterSystems IRIS server <br/>
///  latin1 - the ISO Latin1 8-bit encoding <br/>
///  ISO-8859-1 - the ISO Latin1 8-bit encoding <br/>
///  UTF-8 - the Unicode 8-bit encoding <br/>
///  Unicode - the Unicode 16-bit encoding  (Little-Endian) <br/>
///  UnicodeBig - the Unicode 16-bit encoding (Big-Endian) <br/>
///  @&lt;ttable&gt; - &lt;ttable&gt; means a raw InterSystems character translation table name. A prefix of '@' means to use the named table.
Property Charset As %String [ InitialExpression = "Native" ];

/// Flag controlling logging of files processed
Property %logTransfers As %Boolean [ InitialExpression = 1 ];

/// ResultSet handle kept instantiated for the life of the Adapter and used in the FileList Query
Property %innerRS As %ResultSet [ Internal ];

/// ResultSet handle kept instantiated for the life of the Adapter and used in the DeepList Query
Property %fileRS As %ResultSet [ Internal ];

/// This query is a shadow of the FileSet query in %Library.File, using an interface to the Adapter and skipping directories
/// The dirsOrNoDirs argument if 0 (the default) will exclude directory entries, or if 1 will return directory entries only.
Query FileList(adapter As Ens.Adapter, directory As %String(MAXLEN=""), wildcards As %String, dirsOrNoDirs As %Boolean = 0, semaphoreSpec As %String = "") As %Query(ROWSPEC = "Name:%String,Type:%String,Size:%BigInt,DateCreated:%TimeStamp,DateModified:%TimeStamp,ItemName:%String,ItemDir:%String,SemaphoreName:%String") [ SqlProc ]
{
}

ClassMethod FileListExecute(ByRef QHandle As %Binary, adapter As Ens.Adapter, directory As %String, wildcards As %String, dirsOrNoDirs As %Boolean = 0, semaphoreSpec As %String = "") As %Status
{
	Set QHandle=adapter
	Set QHandle("dirsOrNoDirs")=dirsOrNoDirs
	Set QHandle("semaphoreSpec")=semaphoreSpec
	Set:'$IsObject(QHandle.%innerRS) QHandle.%innerRS=##class(%ResultSet).%New("%File:FileSet")
	$$$ASSERT($IsObject(QHandle.%innerRS))
	Quit QHandle.%innerRS.Execute(directory,wildcards,"DateModified",dirsOrNoDirs)
}

ClassMethod FileListFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	#; find the next non-directory filename
	Set dirsOrNoDirs=QHandle("dirsOrNoDirs")
	For {
		If 'QHandle.%innerRS.Next(.tSC) {
			#; Done iterating the ResultSet for the current query execution - clean it up
			Do QHandle.%innerRS.Close()
			Kill QHandle.%innerRS.Data ; clean it out so next loop iteration will re-Execute the query
			Set Row="", AtEnd=1
			Quit
		}
		Set tType=QHandle.%innerRS.Data("Type")
		If 'dirsOrNoDirs=("D"'=tType) { ; skip directories or non-directories
			Set tName=QHandle.%innerRS.Data("Name"), tItemName=QHandle.%innerRS.Data("ItemName")
			#;Don't check semaphoreSpec if a directory.
			If (QHandle("semaphoreSpec")="")||("D"=tType) {
				Set AtEnd=0, Row=$LB(tName, tType, QHandle.%innerRS.Data("Size"), QHandle.%innerRS.Data("DateCreated"), QHandle.%innerRS.Data("DateModified"), tItemName, $E(tName,1,*-$L(tItemName)-($$$isVMS&&(tName["]"))),"")
				Quit
			} Else {
				Set tFileNameToCheck=tItemName,tDirectoryForCheck=$E(tName,1,*-$L(tItemName)-($$$isVMS&&(tName["]")))
				Set tHaveSemaphore=##class(Ens.Util.File).CorrespondingSemaphoreExists(tFileNameToCheck, QHandle("semaphoreSpec"),tDirectoryForCheck,.tSemaphoreFile,.tSC)
				#;Check in case there is a single semaphore file that appears mid poll and need to wait. Hash to avoid long subscripts.
				If 'tHaveSemaphore,$G(tSemaphoreFile)'="" Set QHandle("semaphoreSpec","wait",$system.Encryption.SHA1Hash(tDirectoryForCheck_tSemaphoreFile))=""
				#;Only process a file for a semaphore if don't have a previous waiter from this cycle
				If tHaveSemaphore,'$D(QHandle("semaphoreSpec","wait",$system.Encryption.SHA1Hash(tDirectoryForCheck_tSemaphoreFile))) {
					Set AtEnd=0, Row=$LB(tName, tType, QHandle.%innerRS.Data("Size"), QHandle.%innerRS.Data("DateCreated"), QHandle.%innerRS.Data("DateModified"), tItemName, $E(tName,1,*-$L(tItemName)-($$$isVMS&&(tName["]"))),tSemaphoreFile)
					Quit
				} 
			}
		}
	}
	Quit tSC
}

ClassMethod FileListClose(QHandle As %Binary) As %Status
{
	Kill QHandle
	Set QHandle=""
	Quit $$$OK
}

/// This query is a shadow of the one of the same name in %Library.File, using an interface to the Adapter and skipping directories
/// The recurseSubdirs argument will cause files from subdirectories also to be returned up to the specified integer depth of subdirectory levels.
Query DeepList(adapter As Ens.Adapter, directory As %String(MAXLEN=""), wildcards As %String, recurseSubdirs As %Integer = 0, listQuery As %String = "FileList", semaphoreSpec As %String = "") As %Query(ROWSPEC = "Name:%String,Type:%String,Size:%BigInt,DateCreated:%TimeStamp,DateModified:%TimeStamp,ItemName:%String,ItemDir:%String,SemaphoreName:%String") [ SqlProc ]
{
}

ClassMethod DeepListExecute(ByRef QHandle As %Binary, adapter As Ens.Adapter, directory As %String, wildcards As %String, recurseSubdirs As %Integer = 0, listQuery As %String = "FileList", semaphoreSpec As %String = "") As %Status
{
	Set QHandle=adapter
	Set QHandle("recurseSubdirs")=recurseSubdirs, QHandle("wildcards")=wildcards
	Set QHandle("SubLevel")=0, QHandle("SubLevel",0)=$$$NULLOREF, QHandle("directory",0)=directory
	Set QHandle("semaphoreSpec")=semaphoreSpec
	Set:'$IsObject(QHandle.%fileRS) QHandle.%fileRS=##class(%ResultSet).%New($$$CurrentClass_":"_listQuery)
	$$$ASSERT($IsObject(QHandle.%fileRS))
	Quit QHandle.%fileRS.Execute(adapter,directory,wildcards,,semaphoreSpec)
}

ClassMethod DeepListFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	#; find the next non-directory filename
	For {
		If QHandle.%fileRS.Next(.tSC) {
			Set AtEnd=0, Row=$LB(QHandle.%fileRS.Data("Name"), QHandle.%fileRS.Data("Type"), QHandle.%fileRS.Data("Size"), QHandle.%fileRS.Data("DateCreated"), QHandle.%fileRS.Data("DateModified"), QHandle.%fileRS.Data("ItemName"), QHandle.%fileRS.Data("ItemDir"),$G(QHandle.%fileRS.Data("SemaphoreName")))
			Quit
		}
		#; Done iterating the ResultSet for the current query execution - clean it up
		Do QHandle.%fileRS.Close()
		Kill QHandle.%fileRS.Data ; clean it out so next loop iteration will re-Execute the query
		
		#; Now try for subdirectories at current level dir
		Set tSubDir=""
		If QHandle("SubLevel")<QHandle("recurseSubdirs") {
			Set tSC=QHandle.%fileRS.Execute(QHandle,QHandle("directory",QHandle("SubLevel")),"_",1)
			Set:$$$ISOK(tSC)&&QHandle.%fileRS.Next(.tSC) tSubDir=QHandle.%fileRS.Data("Name")
			Quit:$$$ISERR(tSC)
		}
		If ""'=tSubDir {
			#; Get the rest of the subdirs and remember them for later (because we can't have more than one RS iterating simultaneously)
			Set iSub=0  While QHandle.%fileRS.Next(.tSC) { Quit:$$$ISERR(tSC)
				Set tNextSub=QHandle.%fileRS.Data("Name")
				Set:""'=tNextSub iSub=iSub+1, QHandle("SubLevel",QHandle("SubLevel"),iSub)=tNextSub
			}
			#; Done iterating the ResultSet for the current subdirectories - clean it up
			Do QHandle.%fileRS.Close()
			Kill QHandle.%fileRS.Data ; clean it out so next loop iteration will re-Execute the query
			Set QHandle("SubLevel",QHandle("SubLevel"))=(iSub>0)
			Quit:$$$ISERR(tSC)

			#; Found a subdir - get files from it
			Set QHandle("SubLevel")=QHandle("SubLevel")+1
			Set QHandle("directory",QHandle("SubLevel"))=tSubDir
			Set tSC=QHandle.%fileRS.Execute(QHandle,tSubDir, QHandle("wildcards"),,QHandle("semaphoreSpec"))  Quit:$$$ISERR(tSC)
			Continue
		} Else {
			#; No subdir at this level - try for a fresh one at a previous level
			While QHandle("SubLevel") {
				Kill QHandle("SubLevel",QHandle("SubLevel")), QHandle("directory",QHandle("SubLevel"))
				Set QHandle("SubLevel")=QHandle("SubLevel")-1

				Set iSub=QHandle("SubLevel",QHandle("SubLevel"))
				If iSub && $D(QHandle("SubLevel",QHandle("SubLevel"),iSub),tSubDir) {
					Set QHandle("SubLevel",QHandle("SubLevel"))=iSub+1
				}
				Quit:""'=tSubDir
			}
			If ""'=tSubDir {
				#; Found a subdir - get files from it
				Set QHandle("SubLevel")=QHandle("SubLevel")+1
				Set QHandle("directory",QHandle("SubLevel"))=tSubDir
				Set tSC=QHandle.%fileRS.Execute(QHandle,tSubDir, QHandle("wildcards"),,QHandle("semaphoreSpec"))  Quit:$$$ISERR(tSC)
				Continue
			}
			#; No more subdirs - we're done
			Set Row="", AtEnd=1
			Quit
		}
	}
	Quit tSC
}

ClassMethod DeepListClose(QHandle As %Binary) As %Status
{
	Kill QHandle
	Set QHandle=""
	Quit $$$OK
}

}
