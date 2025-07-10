/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Helper base class for BusinessService and BusinessOperation for raw IO logging
Class Ens.Util.IOLogger Extends Ens.Settings [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// If set, the Adapter will log in the InterSystems IRIS I/O archive each input and output communication it has with its external system.
Property ArchiveIO As %Boolean [ InitialExpression = 0 ];

Parameter SETTINGS = "ArchiveIO:Dev";

/// This is the current entry in the IO Log, if any.
Property IOLogEntry As Ens.Util.IOLog;

Method NewIOLogEntry(pIsIncoming As %Boolean, pSC As %Status, pAnnotation As %String, pSourceMethod As %String, pSessionId As %Integer, pObj As %RegisteredObject) As %Boolean
{
#define MAXCLASSNAME	(189+60)
	If '$IsObject(..IOLogEntry) {
		Set tParam=$S('$IsObject(..Adapter):"",1:..Adapter.%GetParameter("IOLOGENTRYCLASSNAME"))
		Set tDecl = $$$comMemberKeyGet($classname(),$$$cCLASSproperty,"IOLogEntry",$$$cPROPtype)
		Set tObjClassname=$S($IsObject(pObj):$classname(pObj), $L(pObj)<$$$MAXCLASSNAME:pObj, 1:"")
		If ""=tObjClassname||('$IsObject(pObj)&&'##class(%Dictionary.CompiledClass).%ExistsId(pObj)) {
			Set tObjClassname="%GlobalBinaryStream", tObj1=##class(%GlobalBinaryStream).%New()
			If $IsObject(tObj1) { Do tObj1.Write(pObj) Set pObj=tObj1 } Else { Set pObj=$$$NULLOREF }
		}
		Set tEntryClassname=$S(""'=tParam&&("Ens.Util.IOLog"'=tParam):tParam
								,"Ens.Util.IOLog"'=tDecl:tDecl
								,""=tObjClassname:"Ens.Util.IOLogStream"
								,$classmethod(tObjClassname,"%Extends","%FileStreamAdaptor"):"Ens.Util.IOLogFile"
								,$classmethod(tObjClassname,"%Extends","%Stream.Object"):"Ens.Util.IOLogStream"
								,$classmethod(tObjClassname,"%Extends","%IO.I.Stream"):"Ens.Util.IOLogStream"
								,$classmethod(tObjClassname,"%Extends","EnsLib.EDI.Segmented"):"Ens.Util.IOLogSegmentedObj"
								,$classmethod(tObjClassname,"%IsA","%Persistent"):"Ens.Util.IOLogObj"
								,1:"Ens.Util.IOLogXMLObj")
		If tEntryClassname=tDecl { Do ..IOLogEntryNewObject() }
		Else { Set ..IOLogEntry = $classmethod(tEntryClassname,"%New") }
		$$$ASSERT($IsObject(..IOLogEntry))

		Set ..IOLogEntry.IsInbound = pIsIncoming
		Set ..IOLogEntry.SourceMethod = pSourceMethod
		Set ..IOLogEntry.AdapterClass = $S($IsObject(..Adapter):$classname(..Adapter),1:"")
		Set ..IOLogEntry.HostClass = $classname()
		Set ..IOLogEntry.ConfigName = ..%ConfigName
		Set ..IOLogEntry.Job = $Job
		Set ..IOLogEntry.TimeReceived=$$$timeUTC
		If $IsObject(pObj) {
			If pObj.%Extends("%IO.I.Stream")||(pObj.%Extends("%Stream.Object")&&'pObj.%Extends("%GlobalBinaryStream")) {
				If pIsIncoming { Do ..IOLogEntry.InObject.CopyFrom(pObj) }
				Else  { Do ..IOLogEntry.OutObject.CopyFrom(pObj) }
				Do pObj.Rewind()
			} Else {
				If pIsIncoming { Set ..IOLogEntry.InObject = pObj }
				Else  { Set ..IOLogEntry.OutObject = pObj }
			}
		}
		#; Record the separators used for the initial document
		If ..IOLogEntry.%Extends("Ens.Util.IOLogSegmentedObj") {
			Try {
				#; For received documents, we use the Separators as recorded in the document; note that the object may not exist yet
				If pIsIncoming { Set ..IOLogEntry.InObjectSeparators = $select($IsObject(..IOLogEntry.InObject): ..IOLogEntry.InObject.Separators, 1: "") }
				#; Use $property() to guard against possible compilation errors in subclasses
				Else { Set ..IOLogEntry.OutObjectSeparators = $property($this,"Separators") }
			}
			Catch {}
		}
		Set:'pIsIncoming ..IOLogEntry.SessionId=pSessionId
		Set tCreated=1
	} Else { Set tCreated=0 }
	Set:$$$ISERR(pSC) ..IOLogEntry.Status=$$$ADDSC(..IOLogEntry.Status,pSC)
	Set:""'=pAnnotation ..IOLogEntry.Annotation = $S(""=..IOLogEntry.Annotation:"",1:..IOLogEntry.Annotation_" | ")_pAnnotation
	// No %Save() yet
	Quit tCreated
}

Method SaveIOLogEntry(pSC As %Status, pAnnotation As %String, pObj As %RegisteredObject)
{
	Set:$$$ISERR(pSC) ..IOLogEntry.Status=$$$ADDSC(..IOLogEntry.Status,pSC)
	Set:""'=pAnnotation ..IOLogEntry.Annotation = $S(""=..IOLogEntry.Annotation:"",1:..IOLogEntry.Annotation_" | ")_pAnnotation
	Set:""=..IOLogEntry.SessionId ..IOLogEntry.SessionId=..%SessionId
	Set:""=..IOLogEntry.CorrespondingRequestId&&$IsObject(..%RequestHeader) ..IOLogEntry.CorrespondingRequestId = ..%RequestHeader.%Id()
	If $IsObject(pObj) {
		If pObj.%Extends("%IO.I.Stream")||(pObj.%Extends("%Stream.Object")&&'pObj.%Extends("%GlobalBinaryStream")) {
			If ..IOLogEntry.IsInbound { Do ..IOLogEntry.OutObject.CopyFrom(pObj) }
			Else { Do ..IOLogEntry.OutObject.CopyFrom(pObj) }
			Do pObj.Rewind()
		} Else {
			If ..IOLogEntry.IsInbound { Set:'$IsObject(..IOLogEntry.OutObject) ..IOLogEntry.OutObject = pObj }
			Else { Set:'$IsObject(..IOLogEntry.InObject) ..IOLogEntry.InObject = pObj }
		}
	}
	Set:$IsObject(..IOLogEntry.InObject) ..IOLogEntry.InObjectClass = $classname(..IOLogEntry.InObject)
	Set:$IsObject(..IOLogEntry.OutObject) ..IOLogEntry.OutObjectClass = $classname(..IOLogEntry.OutObject)
	If ..IOLogEntry.IsEmpty(){
		Set tEmptyNote="Empty Log Entry, "_
			$S(..IOLogEntry.IsInbound:"perhaps your Service called OnProcessInput() with a NULL input.",
							1:"perhaps the Outbound Adapter in use doesn't implement IO Logging.")
		Set ..IOLogEntry.Annotation = $S(""=..IOLogEntry.Annotation:"",1:..IOLogEntry.Annotation_" | ")_tEmptyNote
	}
	#; Record the separators used for the response document
	ElseIf ..IOLogEntry.%Extends("Ens.Util.IOLogSegmentedObj") {
		Try {
			#; For services, we don't have a Separators property, so use Separators on document; also check
			If ..IOLogEntry.IsInbound {
				If $IsObject(..IOLogEntry.OutObject) { Set ..IOLogEntry.OutObjectSeparators = ..IOLogEntry.OutObject.Separators }
				If $IsObject(..IOLogEntry.InObject) && ("" = ..IOLogEntry.InObjectSeparators) { Set ..IOLogEntry.InObjectSeparators = ..IOLogEntry.InObject.Separators }
			}
			#; For received documents, we use the Separators as recorded in the document
			Else {
				If $IsObject(..IOLogEntry.InObject) { Set ..IOLogEntry.InObjectSeparators = ..IOLogEntry.InObject.Separators }
				If $IsObject(..IOLogEntry.OutObject) && ("" = ..IOLogEntry.OutObjectSeparators) { Set ..IOLogEntry.OutObjectSeparators = $property($this,"Separators") }
			}
		}
		Catch {}
	}
	Set ..IOLogEntry.TimeResponded=$$$timeUTC
	Do ..IOLogEntry.%Save()
}

Method CloseIOLogEntry(pSC As %Status, pAnnotation As %String, pObj As %RegisteredObject)
{
	Do ..SaveIOLogEntry(pSC, pAnnotation, pObj)
	Set ..IOLogEntry=$$$NULLOREF
}

}
