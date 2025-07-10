/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, Ensemble)

Class Ens.Archive.Manager [ Abstract, System = 4 ]
{

ClassMethod DoArchive() As %Status
{
	set tNamespace=$get(^Ens.ArchiveManager("Namespace"))
	if tNamespace="" quit $$$ERROR($$$GeneralError,"Archive Namespace is not set")
	;
	lock +^Ens.ArchiveManager("lock"):1
	else  quit $$$ERROR($$$GeneralError,"Can not acquire lock to start archiving")
	;
	kill ^Ens.ArchiveManager("run")
	set ^Ens.ArchiveManager("run","start")=$zdatetime($H,3)
	set ^Ens.ArchiveManager("run","first")=$o(^Ens.MessageHeaderD(""))
	;
#define logARCHIVEERROR(%sc) set ^Ens.ArchiveManager("run","error",$i(^Ens.ArchiveManager("run","error")))=$lb(%sc,$$$timeUTC,$g(tHeaderId))
	;
	Set $ZT="Trap",tSC=$$$OK
	do {
		set tHeaderId="" for  {
			set tHeaderId=$o(^Ens.MessageHeaderD(tHeaderId)) q:tHeaderId=""
			;
			set $ZT="TrapOne"
			;
			set ^Ens.ArchiveManager("run","current")=tHeaderId
			if $i(^Ens.ArchiveManager("run","count","processed"))
			;
			set tHeaderObj=##class(Ens.MessageHeader).%OpenId(tHeaderId)
			set tBodyClassName=tHeaderObj.MessageBodyClassName
			set tBodyId=tHeaderObj.MessageBodyId
			if tBodyClassName="",tBodyId'="" set tBodyClassName="Ens.MessageBody"
			set tBodyObj=$s(tBodyClassName'="":$zobjclassmethod(tBodyClassName,"%OpenId",tBodyId),1:$$$NULLOREF)
			;
			set tSC1=..OnMessageHeader(.tAction,tHeaderObj,tBodyObj)
			if $$$ISERR(tSC1) $$$logARCHIVEERROR(tSC1) continue
			;
			if $zboolean(tAction,$$$archiveArchiveData,1) {
				set tSC1=..ArchiveOne(tNamespace,tHeaderObj,tBodyObj)
				if $$$ISERR(tSC1) $$$logARCHIVEERROR(tSC1) continue
				if $i(^Ens.ArchiveManager("run","count","archived"))
			}
			if $zboolean(tAction,$$$archivePurgeHeader,1) {
				set tSC1=##class(Ens.MessageHeader).%DeleteId(tHeaderId)
				if $$$ISERR(tSC1) $$$logARCHIVEERROR(tSC1) continue
				if $i(^Ens.ArchiveManager("run","count","deleted-header"))
			}
			if $zboolean(tAction,$$$archivePurgeBody,1)&&(tBodyClassName'="") {
				set tSC1=$zobjclassmethod(tBodyClassName,"%DeleteId",tBodyId)
				if $$$ISERR(tSC1),'$$$StatusEquals(tSC1,$$$DeleteObjectNotFound,$$$FileCanNotDelete,$$$NotAnInstanceError) $$$logARCHIVEERROR(tSC1) continue
				if $i(^Ens.ArchiveManager("run","count","deleted-body"))
			}
			;
			continue
			;
TrapOne		set $ZT="",tSC1=$$$ERROR($$$ObjectScriptError,$ZE)
			$$$logARCHIVEERROR(tSC1)
		}
		;
	} while (0)
Exit
	set ^Ens.ArchiveManager("run","stop")=$zdatetime($H,3)
	lock -^Ens.ArchiveManager("lock")
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod OnMessageHeader(pAction, pHeader, pBody) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		set tDaysToKeep=$get(^Ens.ArchiveManager("DaysToArchive"),30)
		Set tDoNotDeleteDate = ##class(Ens.Purge).GetDoNotDeleteDate(tDaysToKeep)
		if tDoNotDeleteDate ] pHeader.TimeCreated {
			set pAction=$$$archiveArchiveData+$$$archivePurgeHeader+$$$archivePurgeBody
		} else {
			set pAction=0
		}
		;
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod ArchiveOne(pNameSpace, pHeaderObj, pBodyObj) As %Status
{
	Set tSC=$$$OK
	Try {
		New $namespace
		;
		set tNewBodyObj=##class(Ens.Archive.MessageBody).%New()
		set tNewBodyObj.OriginalMessageNamespace=$namespace
		set tNewBodyObj.OriginalMessageBodyClassname=pHeaderObj.MessageBodyClassName
		set tNewBodyObj.OriginalMessageBodyId=pHeaderObj.MessageBodyId
		#; Use temp stream to avoid write to globals in wrong namespace for tNewBodyObj.OriginalMessageBodyStream
		set tBodyStream=##class(%Stream.TmpCharacter).%New()
		;
		if (pBodyObj'=$$$NULLOREF)&&(pBodyObj.%Extends("EnsLib.EDI.Document")) {
			set tSC=pBodyObj.OutputToLibraryStream(tBodyStream)
			quit:$$$ISERR(tSC)
		} elseif (pBodyObj'=$$$NULLOREF)&&(pBodyObj.%Extends("%XML.Adaptor")) {
			set tSC=pBodyObj.XMLExportToStream(tBodyStream)
			quit:$$$ISERR(tSC)
		} else {
			set tSC=tBodyStream.WriteLine(pHeaderObj.MessageBodyClassName_"::"_pHeaderObj.MessageBodyId)
			quit:$$$ISERR(tSC)
		}
		;
		set $namespace = pNameSpace
		;
		set tSC=tNewBodyObj.OriginalMessageBodyStream.CopyFrom(tBodyStream)
		quit:$$$ISERR(tSC)
		set tSC=tNewBodyObj.%Save()
		quit:$$$ISERR(tSC)
		set pHeaderObj.MessageBodyClassName="Ens.Archive.MessageBody"
		set pHeaderObj.MessageBodyId=tNewBodyObj.%Id()
		set tSC=pHeaderObj.%Save()
		;
	}
	Catch {
		set tSC = $$$EnsSystemError
	}
	Quit tSC
}

ClassMethod GetArchiveParameters(pNamespace, pClassname, pDaysToArchive) As %Status
{
	set pNamespace=$get(^Ens.ArchiveManager("Namespace"))
	set pClassname=$get(^Ens.ArchiveManager("Classname"),"Ens.Archive.Manager")
	set pDaysToArchive=$get(^Ens.ArchiveManager("DaysToArchive"),30)
	quit $$$OK
}

ClassMethod SetArchiveParameters(pNamespace, pClassname, pDaysToArchive) As %Status
{
	set tSC = $$$OK
	if '$zname(pClassname,4) {
		set tSC = $System.Status.Error($$$ClassNameInvalid,pClassname)
	}
	if '$isValidNum(pDaysToArchive,0,0) || (pDaysToArchive'=(pDaysToArchive\1)) {
		set tSC = $System.Status.AppendStatus(tSC,$System.Status.Error($$$DTNotNum,pDaysToArchive))
	}
	
	if $$$ISOK(tSC) {	
		if $get(pNamespace)="" {
			kill ^Ens.ArchiveManager("Namespace")
		} else {
			set ^Ens.ArchiveManager("Namespace")=pNamespace
		}
		
		if $get(pClassname)="" {
			kill ^Ens.ArchiveManager("Classname")
		} else {
			set ^Ens.ArchiveManager("Classname")=pClassname
		}
		
		if $get(pDaysToArchive)="" {
			kill ^Ens.ArchiveManager("DaysToArchive")
		} else {
			set ^Ens.ArchiveManager("DaysToArchive")=pDaysToArchive
		}
	}
	
	quit tSC
}

ClassMethod GetRunningStatus() As %String
{
	lock +^Ens.ArchiveManager("lock"):0 set locktest=$T lock -^Ens.ArchiveManager("lock")
	;
	if locktest=0 quit "running"
	quit "idle"
}

ClassMethod GetRunningPercentage() As %Integer
{
	if ..GetRunningStatus()'="running" quit 100
	;
	set first=$get(^Ens.ArchiveManager("run","first"))
	set current=$get(^Ens.ArchiveManager("run","current"))
	set last=$get(^Ens.MessageHeaderD)
	;
	if (first="")||(current="")||(last="") quit -1
	;
	quit (current-first)*100\(last-first)
}

ClassMethod GetRunningCount() As %String
{
	quit (+$get(^Ens.ArchiveManager("run","count","processed")))_","_(+$get(^Ens.ArchiveManager("run","count","archived")))_","_(+$get(^Ens.ArchiveManager("run","count","deleted-header")))_","_(+$get(^Ens.ArchiveManager("run","count","deleted-body")))_","_(+$g(^Ens.ArchiveManager("run","error")))
}

ClassMethod GetRunningStartTime() As %String
{
	quit $get(^Ens.ArchiveManager("run","start"))
}

ClassMethod GetRunningStopTime() As %String
{
	quit $get(^Ens.ArchiveManager("run","stop"))
}

Query Errors() As %Query(ROWSPEC = "ErrorNumber:%String,Time:%String,Description:%String,MessageId:%String")
{
}

ClassMethod ErrorsExecute(ByRef qHandle As %Binary) As %Status
{
 	Set qHandle=""
	Quit $$$OK
}

ClassMethod ErrorsClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = ErrorsExecute ]
{
 	Set qHandle=""
	Quit $$$OK
}

ClassMethod ErrorsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = ErrorsExecute ]
{
	set $ZT="Trap",tSC=$$$OK
	do {
		set Row="",AtEnd=0
		set qHandle = $order(^Ens.ArchiveManager("run","error",qHandle),1,data)
		if qHandle = "" set AtEnd = 1 quit
		set tStatusCode = $lg(data,1)
		set tTimeUTC = $lg(data,2)
		set tMessageId = $lg(data,3)
		set Row=$lb(qHandle,$$$timeUTCtoLocal(tTimeUTC),$SYSTEM.Status.GetErrorText(tStatusCode),tMessageId)
	} While (0)
Exit
	Quit tSC
Trap
 	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

}
