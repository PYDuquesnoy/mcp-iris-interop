/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.EDIFACT.Operation.BatchStandard Extends EnsLib.EDI.EDIFACT.Operation.Standard [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// Name of file to output the document(s) to. May include timestamp specifiers. The %f specifier if present will be
/// replaced with the name of the document's original source stream. (stripped of characters illegal in filenames).<p>
/// See the method Ens.Util.File.CreateTimestamp() for documentation of timestamping options.
Property Filename As %String(MAXLEN = 1000, MINLEN = 1) [ InitialExpression = "%f_%Q", Required ];

/// When writing a message that has a batch parent, output the batch headers first, and follow up with
///  the batch trailers when triggered by the final batch parent header message or by a file name change.<p>
/// All child messages of a batch parent message will be written out unless already written previously while AutoBatchParentSegs=true.
Property AutoBatchParentSegs As %Boolean [ InitialExpression = 1 ];

Parameter SETTINGS As %String = "Filename:Basic,AutoBatchParentSegs";

/* (override default for Setting inherited from base class) */
/// This method is for File and FTP Operations: per-message batch output with no reply. TCP and HTTP Operations
/// receive reply messages and only support entire batch output.
Method OnMessage(pRequest As EnsLib.EDI.EDIFACT.Document, Output pResponse As EnsLib.EDI.EDIFACT.Document) As %Status
{
	#def1arg Files(%k) $$$EnsStaticAppData(..%ConfigName,"Files",%k)
	#def1arg Count(%k) $$$EnsStaticAppData(..%ConfigName,"Count",%k)
	#def1arg Parents(%k) $$$EnsStaticAppData(..%ConfigName,"Parents",%k)

	Set pResponse=$$$NULLOREF
	Set tSC=..validateAndIndex(pRequest)  Quit:$$$ISERR(tSC) tSC

	Set tParentRef=pRequest.ParentId, tId=pRequest.%Id()
	Set tDoParent=tParentRef&&..AutoBatchParentSegs&&'..Adapter.Overwrite
	If 'tDoParent {
		Set tKey=tId, tOldFilename=$G($$$Files(tKey))
		If ""'=tOldFilename { ; we've already done output for this batch; finish it out now.
			Set tSC=..outputHeaders(tKey,$$$Parents(tKey),"")
			Kill $$$Files(tKey),$$$Parents(tKey),$$$Count(tKey)
			Quit tSC
		}
		Set tFilename=..Adapter.CreateFilename(##class(%File).GetFilename($P(pRequest.Source,$C(13))),..Filename)
		Set tSeparators=$S(""'=..Separators:..Separators, 1:pRequest.Separators)
	} Else {
		#; Get the filename and output appropriate header and trailer segments
		Set tParentIds=pRequest.ParentIds, tNumParents=$LL(tParentIds)
		Set tKey=$P($LI(tParentIds,tNumParents),":")
		Set tTopParent=##class(EnsLib.EDI.EDIFACT.Document).%OpenId(tKey)

		Set tFilename=..Adapter.CreateFilename(##class(%File).GetFilename($P(tTopParent.Source,$C(13))),..Filename)
		Set tOldFilename=$G($$$Files(tKey))

		If tOldFilename'=tFilename {
			#; New output; finish previous Batch if any
			If ""'=tOldFilename {
				$$$catTRACE("file","Finishing old file "_tOldFilename_" using key "_tKey_", parents '"_$G($$$Parents(tKey))_"'")
				Set tSC=..outputHeaders(tKey,$G($$$Parents(tKey)),"")
				If $$$ISERR(tSC) $$$LOGSTATUS(tSC)  Set tSC=$$$OK ; not fatal; start the new one anyway
				Kill $$$Files(tKey),$$$Parents(tKey),$$$Count(tKey)
			}
			#; Output starting Batch headers up to the current segment
			Quit:'pRequest.SegCount tSC
			$$$catTRACE("file","Starting "_tFilename_" using key "_tKey_", parents "_tParentIds)
			Set tSeparators=$S(""'=..Separators:..Separators, 1:tTopParent.Separators)
			Set $$$Files(tKey)=tFilename, $$$Files(tKey,"seps")=tSeparators
			Set tSC=..outputHeaders(tKey,"",tParentIds)  Quit:$$$ISERR(tSC) tSC
		} ElseIf tParentIds'=$G($$$Parents(tKey)) {
			#; Output intermediate Batch trailers/headers

			#; Ignore any batch parent whose children we already have done output for, or empty message
			Set tLastCountRefHavingMyId=$O($$$Count(tKey,tId+1_":"),-1)
			Set tChildrenDone=$S(+tId'=+tLastCountRefHavingMyId:0, 1:$G($$$Count(tKey,tLastCountRefHavingMyId)))

			$$$catTRACE("file","Continuing file "_tFilename_" using key "_tKey_", old parents '"_$G($$$Parents(tKey))_"', parents '"_tParentIds_"'")
			Set tSC=..outputHeaders(tKey,$$$Parents(tKey),tParentIds)  Quit:$$$ISERR(tSC) tSC
			If ""=tParentIds {
				Kill $$$Files(tKey),$$$Parents(tKey),$$$Count(tKey)
				Quit tSC
			}
			If +tChildrenDone||'pRequest.SegCount {
				Set $$$Parents(tKey)=tParentIds
				Quit tSC
			}
		}
		Set tSeparators=$$$Files(tKey,"seps")
	}	
	#; Output the main Document
	Set tSC=..outputDocument(tFilename,pRequest,tSeparators)  Quit:$$$ISERR(tSC) tSC	
	If 'tDoParent {
		$$$sysTRACE("After writing document "_pRequest_"/"_tId_" to file "_tFilename)
	} Else {
		Set $$$Parents(tKey)=tParentIds
		Set tCount=$S($D($$$Count(tKey,tParentRef),tCount):tCount+1, 1:1), $$$Count(tKey,tParentRef)=tCount
		$$$sysTRACE("After writing message "_tCount_" at level "_tNumParents_" "_pRequest_"/"_tId_" to file "_tFilename_" using key "_tKey)
	}
	Quit tSC
}

Method outputHeaders(pKey As %String, pOldParents As %String, pParents As %String) As %Status
{
	#def1arg Files(%k) $$$EnsStaticAppData(..%ConfigName,"Files",%k)
	#def1arg Count(%k) $$$EnsStaticAppData(..%ConfigName,"Count",%k)

	#; Output group header(s) - walk up the parents ladder
	Set tNumOld=$LL(pOldParents), tNum=$LL(pParents)
	
	#; Find first non-matching parent level
	If tNum {
		For i=1:1:tNum { Set tOldParentRef=$LG(pOldParents,tNumOld+1-i), tParentRef=$LI(pParents,tNum+1-i)  Quit:tOldParentRef'=tParentRef }
	} Else {
		Quit:'tNumOld $$$OK
		Set i=1, tParentRef="", tOldParentRef=$LG(pOldParents,tNumOld)
	}
	Set tOldId=$P(tOldParentRef,":"), tNewId=$P(tParentRef,":"), tNewSeg=$P(tParentRef,":",2)
	
	#; Output trailer(s) for previous group
	Set tSC=$$$OK, tParentRef=""
	For j=1:1:tNumOld+1-i { Set tChild=tParentRef, tParentRef=$LG(pOldParents,j)
		Set tId=$P(tParentRef,":"), tSeg=$P(tParentRef,":",2), tCount=$G($$$Count(pKey,tParentRef))
		Set:""'=tId tParent=##class(EnsLib.EDI.EDIFACT.Document).%OpenId(tId)
		Set tEndSeg=$S(""=tId||((tId=tNewId)&&+tNewSeg):tNewSeg-1, 1:tParent.SegCount) ; same level, different DocsRef segments
		For s=tSeg+1:1:tEndSeg {
			Set tSC=..outputSegment($$$Files(pKey),tParent.GetSegmentAt(s),$$$Files(pKey,"seps"),tCount)  Quit:$$$ISERR(tSC)
		}
		Kill:""'=tChild $$$Count(pKey,tChild) ; kill count now that we've written the terminal segment(s)
	}
	#; Output header(s) for new group
	Set tParentRef=$S(i<2:"",1:$LG(pParents,tNum+2-i))
	For j=tNum+1-i:-1:1 { Set tGrampa=tParentRef, tParentRef=$LI(pParents,j)
		#; record the count of intermediate parents too
		Set:""'=tGrampa $$$Count(pKey,tGrampa)=$G($$$Count(pKey,tGrampa))+1 ; increment count for this parent level at grandparent node
		Set tId=$P(tParentRef,":"), tSeg=$P(tParentRef,":",2)
		Continue:tId=tOldId ; we already did these in the trailers loop
		Set tParent=##class(EnsLib.EDI.EDIFACT.Document).%OpenId(tId)
		Set:'tSeg tSeg=tParent.SegCount
		For s=1:1:tSeg-1 {
			Set tSC=..outputSegment($$$Files(pKey),tParent.GetSegmentAt(s),$$$Files(pKey,"seps"),"")  Quit:$$$ISERR(tSC)
		}
	}
	Quit tSC
}

}
