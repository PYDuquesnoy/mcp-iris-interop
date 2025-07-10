/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIEDIFACT

Class EnsLib.EDI.EDIFACT.Service.Standard Extends (Ens.BusinessService, EnsLib.EDI.ServiceInterface) [ Abstract, ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter DOCCLASS As %String = "EnsLib.EDI.EDIFACT.Document";

/// Configuration items to which to send Documents
Property TargetConfigNames As %String(MAXLEN = 1000);

/// Store a set of searchable properties associated with each EDIFACT TransactionSet processed.<p>
/// These records will be stored in the named SearchTable class, if any.
Property SearchTableClass As %String [ InitialExpression = "EnsLib.EDI.EDIFACT.SearchTable" ];

/// Category to apply to incoming EDIFACT document type names to produce a complete DocType specification.<p>
/// Combines with the document type name to produce a DocType assignment.
/// This setting may also contain multiple comma-separated type names followed by = and then a
/// DocTypeCategory or full DocType value to apply to documents declared as that type.<br/>
/// A trailing asterisk (*) at the end of a given partial type Name will match any types with that beginning part.<p/>
/// An example: DocSchemaCategory='D96A, REC*=D04A, REQOTE=D05B' <br/>
/// Note that a DocType assignment may be needed for Validation or SearchTableClass indexing.
Property DocSchemaCategory As %String(MAXLEN = 1000);

/// Comma-separated string specifying types of Validation to perform <p>
/// Set to 1 to block documents that don't pass default validation. Default validation checks for DocType assignment and BuildMapStatus success.
/// This is equivalent to 'dm' <p>
/// 'd' - require DocType <br>
/// 'm' - require successful BuildMap status
Property Validation As %String;

/// Control of response handling - Send back reply documents immediately upon receipt of an Interchange: <br>
/// - Never : Do not send back any Immediate reply <br>
/// - All : Generate a reply for every TransactionSet in an Interchange <br>
/// - Errors : Only generate a reply for TransactionSets in which errors are detected <br>
/// - Success : Only generate a reply for TransactionSets in which are accepted without errors
Property ReplyMode As %String(DISPLAYLIST = ",Never,All,Errors,Success", VALUELIST = ",Never,All,Err,Succ") [ InitialExpression = "Never" ];

/// How to treat received batch Interchange documents: <br>
/// - Whole Batch : Don't process child documents individually; accumulate and send the whole batch as one composite document <br>
/// - Single-Session Batch : Forward each document in the batch as part of a single session, including a final parent document object containing the batch header and trailer segments <br>
/// - Multi-Session Batch : Forward each document in the batch in its own session, followed by the parent document object containing the batch header and trailer segments <br>
/// - Individual : Forward each child document in the batch in its own session; do not forward parent batch document objects
Property BatchHandling As %String(DISPLAYLIST = ",Whole Batch,Single-Session Batch,Multi-Session Batch,Individual", VALUELIST = ",Whole,1Session,MSession,Indiv") [ InitialExpression = "1Session", Required ];

/// Colon-separated Local ID:Qualifier codes representing this (receiving) facility and application <p>
/// These are used in constructing reply document headers.<p>
/// The '@' symbol represents using the corresponding field from the incoming message.<p>
/// If your ID must contain a literal @ symbol, escape it with backslash: '\@'
Property LocalApplicationID As %String(MAXLEN = 1000) [ InitialExpression = "EDIFACTService:ENS" ];

/// Process the file without error even if to enhance readability newlines have been added after or in place of segment terminators
Property TolerateNewlines As %Boolean [ InitialExpression = 1 ];

Parameter SETTINGS = "TargetConfigNames:Basic:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},SearchTableClass::selector?context={Ens.ContextSearch/SearchTableClasses?host=EnsLib.EDI.EDIFACT.Service.Standard},DocSchemaCategory:Basic:selector?context={Ens.ContextSearch/SchemaCategories?host=EnsLib.EDI.EDIFACT.Service.Standard},Validation,ReplyMode,BatchHandling,LocalApplicationID,TolerateNewlines";

/// For batch documents, don't process contained documents individually; accumulate and send the whole batch at once;
/// Do not begin processing TransactionSets until after validating the end of group and end of interchange segments.
Property %ForwardBatchWhole As %Boolean [ Internal ];

/// When processing child documents individually, forward batch header/trailer segment shell documents in addition to the child Message documents they contain
Property %ForwardBatchHeaders As %Boolean [ InitialExpression = 1, Internal ];

/// For Batch documents, forward every child document in the batch as part of a single session.
Property %SingleBatchSession As %Boolean [ Internal ];

/// Should this Service forward child documents as soon as it encounters them, or store them up until we know if the batch contained any errors
Property %DeferChildSend As %Boolean [ Internal ];

/// Stop processing a batch document if an error occurs. Otherwise accumulate all errors and report them as a group
Property %AbortBatchOnError As %Boolean [ InitialExpression = 0, Internal ];

/// Deprecated - Placeholder
Property %ApplicationReplyMode As %String [ InitialExpression = "Never", Internal ];

/// If SearchTableClass is set, use it to index any reply documents
Parameter IndexReplies As %Boolean = 0;

Property %Parser As EnsLib.EDI.EDIFACT.Parser;

/// This holds Reply Documents
///  As EnsLib.EDI.Document
Property %ReplyDocuments [ InitialExpression = 0, MultiDimensional ];

Property %Errors As %String [ MultiDimensional ];

/// Is the current message the first in a batch? (used for starting a new session on the first message in a batch)
Property isNewBatch As %Boolean [ InitialExpression = 1 ];

Method OnInit() As %Status
{
	Set ..%ReplyDocuments=0
	Set ..%Parser=##class(EnsLib.EDI.EDIFACT.Parser).%New($this)
	Set:..TolerateNewlines ..%Parser.Whitespace=$C(13,10)
	Set:""=..ReplyMode ..ReplyMode="Never"
	Set:""=..%ApplicationReplyMode ..%ApplicationReplyMode="Never"

	Set:""=..BatchHandling ..BatchHandling="Batch"
	Set ..%ForwardBatchWhole=$Case(..BatchHandling, "Whole":1, :0)
	Set ..%ForwardBatchHeaders=$Case(..BatchHandling, "1Session":1, "Batch":1, :0)
	Set ..%SingleBatchSession=$Case(..BatchHandling, "1Session":1, :0)
	Quit $$$OK
}

/// Note: pDocIn is not declared as EnsLib.EDI.EDIFACT.Document so that subclasses can handle other types and transform them before calling ##super().
Method OnProcessInput(pDocIn As %RegisteredObject, Output pDocOut As %RegisteredObject) As %Status
{
	$$$ASSERT(0_"Subclass Responsibility")
}

/// Override this method to implement your own custom method for validating an incoming Document
/// Return non-zero to prevent default validation of the message (if any);
Method OnValidate(pDoc As EnsLib.EDI.Document, pValSpec As %String, Output pStatus As %Status) As %Boolean
{
	Quit 0
}

/// Override this method to implement your own custom method for resolving the DocType of an incoming Message
/// Returning nonzero means you are overriding the framework's standard DocType resolution.
Method OnResolveDocType(pDoc As EnsLib.EDI.Document, ByRef pDocType As %String) As %Boolean
{
	Quit 0
}

Method standardOnProcessInput(pDocIn As EnsLib.EDI.EDIFACT.Document, Output pDocOut As EnsLib.EDI.EDIFACT.Document) As %Status
{
	Set tSC=$$$OK, pDocOut=$$$NULLOREF
	$$$ASSERT($$$IsdefObject(pDocIn) && pDocIn.%IsA("EnsLib.EDI.EDIFACT.Document"))
	$$$sysTRACE("Got Document "_pDocIn_" / "_pDocIn.%Id())
	#; get accepted doc, resolve DocType
	Set tSCVal=..resolveAndIndex(pDocIn)
	Set tResponse=$$$NULLOREF
	If $$$ISOK(tSC)&&$$$ISOK(tSCVal)&&(""'=..TargetConfigNames) {
		Set pDocIn.IsMutable=0
		If $Case(..%ApplicationReplyMode,"Never":1,"Immed":1,"ISA":'..getUNAAckRequested(pDocIn),:0) {
			$$$SyncCommitSet(tSyncCommit)
			For iTarget=1:1:$L(..TargetConfigNames, ",") { Set tOneTarget=$ZStrip($P(..TargetConfigNames,",",iTarget),"<>W")  Continue:""=tOneTarget
				$$$sysTRACE("Sending EDIFACT document "_pDocIn_"/"_pDocIn.%Id()_" from "_pDocIn.Source_" to '"_tOneTarget_"'")
				Set tSC1=..SendRequestAsync(tOneTarget,pDocIn)
				Set:$$$ISERR(tSC1) tSC=$$$ADDSC(tSC,tSC1)
			}
			$$$SyncCommitClear(tSyncCommit)
			If $$$ISOK(tSC) $$$sysTRACE("After async forwarding document "_pDocIn_"/"_pDocIn.%Id())
			If ..ReplyMode'="Never" {
				Set pDocOut=..reportReply(pDocIn,,.tSC)
			}
		} Else { ;  Application reply mode (either explicit or ISA-requested)
			If 1'=$L(..TargetConfigNames, ",") $$$LOGWARNING("More than one target config name specified for synchronous forwarding: "_..TargetConfigNames)
			$$$sysTRACE("Sending "_pDocIn_"/"_pDocIn.%Id()_" from "_pDocIn.Source_" to '"_..TargetConfigNames_"'")
			Set tSC=..SendRequestSync(..TargetConfigNames,pDocIn,.tResponse) Quit:$$$ISERR(tSC) tSC
			If '$IsObject(tResponse) { ; no reply message - we must construct one
				$$$LOGWARNING("Constructing reply because SendRequestSync() of "_pDocIn_"/"_pDocIn.%Id()_" returned with no response object and status: "_$$$StatusDisplayString(tSC))
				Set pDocOut=..reportReply(pDocIn,,.tSC)
			} Else { 
				$$$sysTRACE("Returning reply document "_tResponse.%Id()_" ("_tResponse.Name_") received from document "_pDocIn.%Id()_" forwarded to "_..TargetConfigNames)
			}
		}
	} Else { ; not forwarding due to error or no target
		If $Case(..ReplyMode,"Never":0,"ISA":..getUNAAckRequested(pDocIn),:1) {
			If $$$ISOK(tSC)&&$$$ISOK(tSCVal) {
				$$$SyncCommitSet(tSyncCommit)
				Set pDocIn.IsMutable=0, tSC=pDocIn.%Save() ; save the document because we're going to reply to it.
				$$$SyncCommitClear(tSyncCommit)
				If $$$ISERR(tSC) {
					$$$LOGERROR("Failed to save document "_pDocIn_" / "_pDocIn.%Id()_" : "_$$$StatusDisplayString(tSC))
				}
			}
			$$$sysTRACE("Returning reply but not forwarding document "_pDocIn_"/"_pDocIn.%Id()_$S($$$ISERR(tSC):" status "_$$$StatusDisplayString(tSC),1:""))
			Set tSC=$$$ADDSC(tSC,tSCVal)
			Set pDocOut=..reportReply(pDocIn,,.tSC)
		} Else {
			$$$sysTRACE("Not returning reply for document "_pDocIn_"/"_pDocIn.%Id()_"; ReplyMode="_..ReplyMode_$S($$$ISERR(tSC):" status "_$$$StatusDisplayString(tSC),1:""))
		}
	}
	If $IsObject(tResponse) {
		Set pDocOut=..reportReply(pDocIn,tResponse,.tSC)
	}
	Quit tSC
}

Method getReplyCode(pMSH As EnsLib.EDI.EDIFACT.Segment, pSC As %Status, pSCVal As %Status, pAppACK As %Boolean) As %String
{
	If pAppACK>-1&&$IsObject(pMSH) { Set tAckType=pMSH.GetValueAt($S(pAppACK:16,1:15)), tVersionID=pMSH.GetValueAt("12.1") }
	Else { Set (tAckType,tVersionID)="" }
	#; Choose the appropriate Status character
	Set tCode=$S($$$ISERR(pSCVal):"R", $$$ISERR(pSC):"E", 1:"A") ; Reject / Error / Accept
	#; Send no ACK if the MSH requests not to
	Quit:pAppACK>-1&&$Case(..ReplyMode,"Never":1,"Immed":pAppACK,"App":'pAppACK,"Msh":$Case(tAckType,"NE":1,"ER":(tCode="A"),"SU":(tCode'="A"),:0),:0) ""
	Quit "C"_tCode ; Commit / Application
}

/// Accept only specified document names; resolve DocType and perform requested validation if any
Method resolveAndIndex(pDoc As EnsLib.EDI.Document) As %Status
{
	Set tDocType=..resolveDocType(pDoc)
	Do pDoc.PokeDocType(tDocType)

	#; Do further validation if required
	Set tSC=$$$OK
	If ""=..Validation||'..OnValidate(pDoc,..Validation,.tSC) {
		#; no default validation
	}
	Quit:$$$ISERR(tSC) tSC

	If ""'=..SearchTableClass {
		TRY {		
			Set tSCStore=$zobjclassmethod(..SearchTableClass,"IndexDoc",pDoc)
			If $$$ISERR(tSCStore) $$$LOGWARNING("Failed to construct SearchTable entries for document "_pDoc_"/"_pDoc.%Id()_" with DocType='"_pDoc.DocType_"' using class '"_..SearchTableClass_"' "_$$$StatusDisplayString(tSCStore))
		} CATCH errobj { $$$LOGWARNING("Failed to invoke SearchTable method "_..SearchTableClass_".IndexDoc() for message "_pDoc_"/"_pDoc.%Id()_" with DocType='"_pDoc.DocType_"' : "_errobj.AsSystemError()) }
	}
	Quit tSC
}

/// Return the DocType that this service will assign to this document
Method resolveDocType(pDoc As EnsLib.EDI.EDIFACT.Document) As %String
{
	Set tDocType=pDoc.DocType
	If ""=tDocType {
		#; Match with the DocType specified if any in DocSchemaCategory for the received Document's type name
		Set tAcceptTypes=..DocSchemaCategory, tNameFound=pDoc.Name, tUNameFound=$ZCVT(tNameFound,"U")
		Set nTypes=$S(""=$ZStrip(tAcceptTypes,"<>W"):0, 1:$L(tAcceptTypes,","))
		Set (tVal,tDef)=""
		For i=1:1:nTypes { Set tType=$P(tAcceptTypes,",",i) Continue:""=tType
			Set tVal=$ZStrip($P(tType,"=",2),"<>W")
			Set tName=$ZStrip($P(tType,"=",1),"<>W"), tNameLen=$L(tName), tUName=$ZCVT(tName,"U")
			If ""=tVal {
				Set:""=tDef tDef=tName
			} Else {
				#; Quit on match; accept trailing wildcard also
				If tUNameFound=tUName
				 || ("*"=$E(tName,tNameLen) && ($E(tUName,1,tNameLen-1)=$E(tUNameFound,1,tNameLen-1))) {
					If tVal[":" { Set tDocType=tVal }
					Else { Set tDocType=tVal_":"_tNameFound }
					Quit
				}
				Set tVal=""
			}
		}
		If ""'=tDocType {
			If tVal[":" {
				$$$sysTRACE("Using DocType='"_tDocType_"' for type name '"_tNameFound_"' matching '"_tUName_"' in DocSchemaCategory list; calling OnResolveDocType()")
			} Else {
				$$$sysTRACE("Using DocType='"_tDocType_"' from schema category '"_tVal_"' for type name '"_tNameFound_"' matching '"_tUName_"' in DocSchemaCategory list; calling OnResolveDocType()")
			}
		} ElseIf ""'=tDef {
			If tDef[":" {
				Set tDocType=tDef
				$$$sysTRACE("Using default DocType='"_tDocType_"' from DocSchemaCategory list '"_tAcceptTypes_"'; type name '"_tNameFound_"' not matched specifically; calling OnResolveDocType()")
			} Else {
				Set tDocType=tDef_":"_tNameFound
				$$$sysTRACE("Using DocType='"_tDocType_"' from default schema category in DocSchemaCategory list '"_tAcceptTypes_"'; type name '"_tNameFound_"' not matched specifically; calling OnResolveDocType()")
			}
		} Else {
			$$$sysTRACE("No match or default DocType found for type name '"_tNameFound_"' in DocSchemaCategory list '"_tAcceptTypes_"'; calling OnResolveDocType()")
		}
	} Else {
		$$$sysTRACE("Accepted document with DocType='"_tDocType_"'; calling OnResolveDocType()")
	}
	Set ttDocType=tDocType  If ..OnResolveDocType(pDoc,.ttDocType) {
		Set tDocType=$Get(ttDocType)
		$$$sysTRACE("OnResolveDocType returned DocType="_tDocType)
	}
	Quit tDocType
}

ClassMethod getUNAAckRequested(pTxn As EnsLib.EDI.EDIFACT.Document) As %String
{
	Set tInterchange=pTxn.%OpenId(pTxn.TopParentId)
	If '$IsObject(tInterchange) { Quit:"Interchange"=pTxn.Name pTxn.GetValueAt("1:14")  Quit "" }
	Quit tInterchange.GetValueAt("1:14")
}

Method reportReply(pOriginalDoc As EnsLib.EDI.Document, pReplyCode As %String = "", ByRef pSC As %Status, pEarlyReply As %Integer = 0) As EnsLib.EDI.Document
{
	Set tSC=pSC
	If $IsObject(pReplyCode) {
		Set tReplyDoc=pReplyCode, pSC=$$$OK
		$$$sysTRACE("Reporting reply document "_tReplyDoc_" for document "_pOriginalDoc_$S('$IsObject(pOriginalDoc):"",1:" / "_pOriginalDoc.%Id()))
	} Else {
		Set tReplyDoc=..constructReply(pOriginalDoc,pReplyCode,.pSC,pEarlyReply)  If $$$ISERR(pSC) $$$LOGSTATUS(pSC)  Quit $$$NULLOREF
		$$$sysTRACE("Reporting reply document "_tReplyDoc_" for document "_pOriginalDoc_$S('$IsObject(pOriginalDoc):"",1:" / "_pOriginalDoc.%Id())_"; status: "_$$$StatusDisplayString(tSC))
	}
	If ""'=..SearchTableClass && $IsObject(tReplyDoc) && ..#IndexReplies {
		Set tSCStore=$zobjclassmethod(..SearchTableClass,"IndexDoc",tReplyDoc)
		If $$$ISERR(tSCStore) $$$LOGWARNING("Failed to construct SearchTable entries for reply document "_tReplyDoc_" / "_tReplyDoc.%Id()_" with DocType='"_tReplyDoc.DocType_"' using class '"_..SearchTableClass_"' "_$$$StatusDisplayString(tSCStore))
	}
	Quit:""=tReplyDoc $$$NULLOREF
	If ""'=pOriginalDoc.ParentId && '..%DeferChildSend {
		#; Save individual reply docs for final batch reply
		Set ..%ReplyDocuments=$G(..%ReplyDocuments)+1, ..%ReplyDocuments(..%ReplyDocuments)=tReplyDoc
	} ElseIf ..%DeferChildSend && $IsObject(tReplyDoc) && tReplyDoc.ChildCount {
		Set pSC=tReplyDoc.GetChildIdsArray(.tChildArray,tReplyDoc.%Id(),1)  If $$$ISERR(pSC) $$$LOGSTATUS(pSC)  Quit $$$NULLOREF
		Set i="" For { Set i=$O(tChildArray(i),1,tChildId)  Quit:""=i
			Set tReply=tReplyDoc.%OpenId(tChildId)
			Set pSC=..SendReply(tReply,pOriginalDoc) Quit:$$$ISERR(pSC)
		}
	} Else {
		Set pSC=..SendReply(tReplyDoc,pOriginalDoc)
	}
	If $$$ISERR(pSC) $$$LOGSTATUS(pSC)
	Quit $$$NULLOREF ; default behavior is not to return the reply doc from OnProcessInput()
}

Method constructReply(pOriginalDoc As EnsLib.EDI.Document, pReplyCode As %String, ByRef pSC As %Status, pEarlyReply As %Integer) As EnsLib.EDI.Document
{
	Set tSC=pSC, pSC=..OnConstructReply(.tReplyDoc, pOriginalDoc,.pReplyCode,.tSC,pEarlyReply)  If $$$ISERR(pSC) $$$LOGSTATUS(pSC) Quit $$$NULLOREF
	If '$D(tReplyDoc) {
		If $Case(pOriginalDoc.Name,"Interchange":1,"Group":1,:0) {
			If "" '= pOriginalDoc.ParentId { ; top doc
				Set tReplyDoc=$$$NULLOREF
			} Else {
				If ..%ForwardBatchWhole=1 { ; no need to check for ForwardBatchWhole>1 because this is runtime
					#; Make Reply documents for all children
					Set pSC=pOriginalDoc.GetChildIdsArray(.tChildArray,pOriginalDoc.%Id(),1)
					Set i="" For { Set i=$O(tChildArray(i),1,tChildId)  Quit:""=i
						Set tChild=pOriginalDoc.%OpenId(tChildId)
						Set tRepliesArray=i, tRepliesArray(i)=..constructReply(tChild,"AA",.pSC,pEarlyReply)  If $$$ISERR(pSC) $$$LOGSTATUS(pSC) Quit
					}
				} Else {
					Merge tRepliesArray=..%ReplyDocuments  Kill ..%ReplyDocuments  Set ..%ReplyDocuments=0
				} ; Else (If ..%ForwardBatchWhole>1) do nothing; this value means don't let Service process the document; we're in ImportFrom...()
				Set:$$$ISOK(pSC) tReplyDoc=..constructBatchReply(pOriginalDoc,.tRepliesArray,.pSC,pEarlyReply)
			}
		} Else {
			If pEarlyReply<0 {
				Set tReplyDoc=##class(EnsLib.EDI.EDIFACT.Segment).%New($LB("",1,"ISC_00405:000:TA1-15",$E(pOriginalDoc.Separators,1,3)_"TA1"))
				Set tReplyDoc=$S("A"=$E(pReplyCode,2):$C($$$SingleByteAcceptAscii),1:$C($$$SingleByteErrorAscii))
			} Else {
				Set tReplyDoc=pOriginalDoc.NewReplyDocument(,..LocalApplicationID)
				Set tReplyDoc.Source=pOriginalDoc.%Id()
				Set tAckMSA=##class(EnsLib.EDI.EDIFACT.Segment).%New($LB("",1))
				Set tAckMSA.Separators=tReplyDoc.Separators
				Do tAckMSA.SetValueAt("MSA",0)
				Do tAckMSA.SetValueAt(pReplyCode,1)
				Do tAckMSA.SetValueAt(pOriginalDoc.GetValueAt("1:10"),2)
				;Do tAckMSA.SetValueAt($$$StatusDisplayString(tSC),3) ; do not divulge internal state information in error messages
				#; Deprecated since v2.1 - Do tMSA.SetValueAt($S(pForwardMsg:"D",1:"F"),5//"DelayedAcknowledgmentType")
				Do tReplyDoc.AppendSegment(tAckMSA)
				Set tReplyDoc.IsMutable=0
			}
		}
	}
	Set:$IsObject(tReplyDoc) tReplyDoc.OriginalDocId=pOriginalDoc.%Id()
	$$$sysTRACE("Constructed reply document '"_tReplyDoc_$S('$$$IsdefObject(tReplyDoc):"'",1:"' of type '"_tReplyDoc.Name_"'")_" for original document "_pOriginalDoc_" / "_pOriginalDoc.%Id()_"; status: "_$$$StatusDisplayString(pSC))
	Quit $G(tReplyDoc,$$$NULLOREF)
}

/// Override this method to construct a customized reply document. Inputs are the original document and
///  the reply code and the status code that the framework produced in processing the original document.
///  If you change the status code but do not construct a reply document, the framework will use the new value to construct a standard reply document.
Method OnConstructReply(Output pReplyDoc As EnsLib.EDI.Document, pOriginalDoc As EnsLib.EDI.Document, ByRef pReplyCode As %String, ByRef pSC As %Status, pEarlyReply As %Boolean) As %Status
{
	Quit $$$OK
}

Method constructBatchReply(pOriginalDoc As EnsLib.EDI.Document, ByRef pChildArray, ByRef pSC As %Status, pEarlyReply As %Boolean) As EnsLib.EDI.Document
{
	Set tSC=pSC, pSC=..OnConstructBatchReply(.tReplyDoc,pOriginalDoc,.pChildArray,.tSC) If $$$ISERR(pSC) $$$LOGSTATUS(pSC) Quit $$$NULLOREF
	If '$D(tReplyDoc) {
		Quit:0=$G(pChildArray,0) $$$NULLOREF
		If (+pChildArray'=pChildArray) Set pSC=$$$ERROR($$$EnsErrGeneral,"Child Reply Document Array has unexpected top node: '"_pChildArray_"'")  Quit $$$NULLOREF
		Set tReply1=$G(pChildArray(1))
		Set:'$IsObject(tReply1) tReply1=##class(EnsLib.EDI.EDIFACT.Document).%OpenId(tReply1)
		Quit:'$IsObject(tReply1) $$$NULLOREF
		Set tNext=2
		#; construct Batch parent document
		Set tReplyDoc=##class(EnsLib.EDI.EDIFACT.Document).%New($LB("",tReply1.Separators,tReply1.Source))
		Set tFS=$E(tReply1.Separators), tCS=$E(tReply1.Separators,3)
		Set tGSType=tReply1.DocTypeCategory  Set:""'=tGSType tGSType=tCS_"GS"
		Set tGS=##class(EnsLib.EDI.EDIFACT.Segment).%New($LB("",1,tGSType,tReply1.Separators_"GS"_tFS))
		Do tReplyDoc.setSegmentByIndex(tGS,1,0)
		Set tHolder=##class(EnsLib.EDI.EDIFACT.Segment).%New($LB("",1,"",tReply1.Separators_"TransactionSetDocsRef"_tFS_2_tFS_$G(pChildArray)))
		Do tReplyDoc.setSegmentByIndex(tHolder,2,0)
		Set tGEType=tReply1.DocTypeCategory  Set:""'=tGEType tGEType=tCS_"GE"
		Set tGE=##class(EnsLib.EDI.EDIFACT.Segment).%New($LB("",1,tGEType,tReply1.Separators_"GE"_tFS_$G(pChildArray)))
		Do tReplyDoc.setSegmentByIndex(tGE,3,0)
		Set tReply1.ParentId=tReplyDoc.getId()
		Do tReply1.%Save()

		For i=tNext:1:pChildArray { Set tReply=pChildArray(i)
			Set:'$IsObject(tReply) tReply=##class(EnsLib.EDI.EDIFACT.Document).%OpenId(tReply)  $$$ASSERT($IsObject(tReply))
			Set tReply.ParentId=tReplyDoc.getId()_":2"
			Do tReply.%Save()
		}
		If pOriginalDoc.Name'="Interchange" {
			Do tReplyDoc.%Save()
		} Else {
			/*
			#; construct Interchange parent document
			Set tReply=tReplyDoc, tReplyDoc=##class(EnsLib.EDI.EDIFACT.Document).%New($LB("",tReply1.Separators,tReply1.Source))
			Set tISAType=tReply1.DocTypeCategory  Set:""'=tISAType tISAType=tCS_"ISA"
			Set tISA=##class(EnsLib.EDI.EDIFACT.Segment).%New($LB("",1,tISAType,tReply1.Separators_"ISA"_tFS))
			Do tReplyDoc.setSegmentByIndex(tISA,1,0)
			Set tHolder=##class(EnsLib.EDI.EDIFACT.Segment).%New($LB("",1,"",tReply1.Separators_"GSDocsRef"_tFS_2_tFS_1))
			Do tReplyDoc.setSegmentByIndex(tHolder,2,0)
			Set tIEAType=tReply1.DocTypeCategory  Set:""'=tIEAType tIEAType=tCS_"IEA"
			Set tIEA=##class(EnsLib.EDI.EDIFACT.Segment).%New($LB("",1,tIEAType,tReply1.Separators_"IEA"_tFS_1))
			Do tReplyDoc.setSegmentByIndex(tIEA,3,0)
			Do tReplyDoc.%Save()
			Set tReply.ParentId=tReplyDoc.%Id()_":2"
			Do tReply.%Save()
			*/
			Set tISA=pOriginalDoc.GetSegmentAt(1)
			
			#; Retrieve items from the current ISA which must be quoted in the returned TA1 Segment
			Set tAcknowledgmentRequested=tISA.GetValueAt($$$UNAAcknowledgmentRequested,,.pSC)  Quit:$$$ISERR(pSC) $$$NULLOREF
			#; If a transaction doesn't need to be created then quit
			If tAcknowledgmentRequested=0&&('$Data(..%Errors)) Quit $$$NULLOREF
	
			//Set tInterchangeDate=tISA.GetValueAt($$$UNAInterchangeDate,,.pSC)  Quit:$$$ISERR(pSC) $$$NULLOREF
			//Set tInterchangeTime=tISA.GetValueAt($$$UNAInterchangeTime,,.pSC)  Quit:$$$ISERR(pSC) $$$NULLOREF
			Set tControlVersionNum=tISA.GetValueAt($$$UNAInterchangeControlVersionNum,,.pSC)  Quit:$$$ISERR(pSC) $$$NULLOREF
			Set tInterchangeControlNumber=tISA.GetValueAt($$$UNAInterchangeControlNumber,,.pSC)  Quit:$$$ISERR(pSC) $$$NULLOREF
	
			#; Create the Reply Interchange
			Set tReplyInterchange=pOriginalDoc.NewReplyDocument(,..LocalApplicationID,.tSC)  If '$IsObject(tReplyInterchange) Set pSC=%objlasterror Quit $$$NULLOREF
			Set tReplyInterchange.Source=..%ConfigName
			
			Set tNumFunctionalGroups=0, tTA1=""
				
			#; If an Acknowledgment is requested or there are errors pertaining to the Interchange header/trailer
			#; then a TA1 segment should be included in the TA1 reply
	
			#; If there are errors
			If $Data(..%Errors)||..%ReplyDocuments {
				
				If ..%ReplyDocuments {
					For i=2:1:..%ReplyDocuments { Set tReply=%ReplyDocuments(i)
						Set:'$IsObject(tReply) tReply=##class(EnsLib.EDI.EDIFACT.Document).%OpenId(tReply)  $$$ASSERT($IsObject(tReply))
						If tReply.%IsA("EnsLib.EDIFACT.Segment") { Do tReplyInterchange.TA1s.Insert(tReply) }
						Else {
							Set tReply.ParentId=tReplyInterchange.getId()_":" //_iRef
						}
					}
				}
			} elseif tAcknowledgmentRequested { ; There are no errors, create a TA1 to report no errors
			} else {
				#; There are no errors and Ack not required, Don't Create a TA1 or anything else
			}
				
			#; If a TA1 has been generated, update the reply object
			If $IsObject(tTA1) {
				Set pSC=tReplyInterchange.TA1s.Insert(tTA1)  Quit:$$$ISERR(pSC) $$$NULLOREF
			}
			Set tReplyDoc=tReplyInterchange
		}
	}
	$$$sysTRACE("Constructed batch reply document '"_tReplyDoc_" / "_tReplyDoc.%Id()_"' for original document "_pOriginalDoc_" / "_pOriginalDoc.%Id()_"; status: "_$$$StatusDisplayString(pSC))
	Quit $G(tReplyDoc, $$$NULLOREF)
}

/// Override this method to construct a customized batch reply document. Inputs are the original document and
///  the child reply array and the status code that the framework produced in processing the original document.
Method OnConstructBatchReply(Output pReplyDoc As EnsLib.EDI.Document, pOriginalDoc As EnsLib.EDI.Document, ByRef pChildArray, ByRef pSC As %Status, pEarlyReply As %Boolean) As %Status
{
	Quit $$$OK
}

Method SendReply(pReplyDocument As EnsLib.EDI.Document, pOriginalDoc As EnsLib.EDI.Document) As %Status
{
	Quit $$$EnsError($$$EnsErrGeneral, "Service does not support Reply; Document "_pReplyDocument)
}

/// Callbacks from Parser:
/// 
/// Called by the Parser at the end of a document
Method OnDocumentEnd(pDocument As EnsLib.EDI.Document, pSource As %String, pStatus As %Status) As %Status
{
	Set tSC=$$$OK
	#;$$$ASSERT(pDocument=..%Parser.%CurrentDocument)
	#; Ignore bad status; let OnProcessInput() do what it can

	// Ignore errors; we use the default Reply Document object
	If ""=pDocument.ParentId { ; top parent ; Interchange
		If ..%ForwardBatchWhole=1 {
			If '..%PreserveSession {
				#; We do not want to clean %SuperSession if set before %SessionId
				If '..%SuperSessionCreatedBeforeSession  Set ..%SuperSession = ""
				Set ..%SessionId=""  Kill $$$JobSessionId
			}
			Set tSC=..standardOnProcessInput(pDocument,.tDocOut)
		} ElseIf '..%ForwardBatchWhole {
			Set tIsHdr=$Case(pDocument.Name, "Interchange":1, "Group":1, :0)
		If 'tIsHdr || ..%ForwardBatchHeaders {
				If tIsHdr {
					If '..%PreserveSession && ('..%SingleBatchSession || ..isNewBatch) {
						#; We do not want to clean %SuperSession if set before %SessionId
						If '..%SuperSessionCreatedBeforeSession  Set ..%SuperSession = ""
						Set ..%SessionId=""  Kill $$$JobSessionId
					}
				} Else {
					If '..%PreserveSession {
						#; We do not want to clean %SuperSession if set before %SessionId
						If '..%SuperSessionCreatedBeforeSession  Set ..%SuperSession = ""
						Set ..%SessionId=""  Kill $$$JobSessionId
					}
				}
				Set tSC=..standardOnProcessInput(pDocument,.tDocOut)
			}
			Else { Do ..reportReply(pDocument,"AA",.tSC) } ; top batch doc - reply but don't process
		} ; Else (If ..%ForwardBatchWhole>1) do nothing; this value means not run-time but ImportFrom...
		Set ..isNewBatch=1
	} ElseIf '..%ForwardBatchWhole && ($Case(pDocument.Name, "Interchange":0, "Group":0, :1) || ..%ForwardBatchHeaders) { ; Not top parent
		If '..%SingleBatchSession || ('..%PreserveSession && ..isNewBatch) {
			#; We do not want to clean %SuperSession if set before %SessionId
			If '..%SuperSessionCreatedBeforeSession  Set ..%SuperSession = ""
			Set ..%SessionId=""  Kill $$$JobSessionId
		}
		Set tSC=..standardOnProcessInput(pDocument,.tDocOut)
		Set ..isNewBatch=0
	}
	If $$$ISERR(tSC) && $$$StatusEquals(tSC,$$$EnsErrGeneral) Set pStatus=$$$ADDSC(pStatus,tSC) // !!! quit on fatal errors only
	Quit:'..%AbortBatchOnError&&$$$ISOK(tSC) $$$OK
	Quit pStatus
}

/// Return the segment terminator string that the Parser and the document.ImportFromIOStream() method will use.
Method GetSegmentTerminator() As %String
{
	Quit $$$EDIFACTDefSegTerminator ; not really used because ISA declares the terminator
}

ClassMethod GetRequestClassList() As %String [ CodeMode = objectgenerator, GenerateAfter = OnProcessInput ]
{
	Set tSignature=$$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"standardOnProcessInput",$$$cMETHformalspecparsed)
	Set tClass=$lg($lg(tSignature,1),2)
	Set tSignature=$$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"OnProcessInput",$$$cMETHformalspecparsed)
	Set tClass=tClass_""","""_$lg($lg(tSignature,1),2)
	Do %code.WriteLine(" Quit $lb("""_tClass_""")")
	Quit $$$OK
}

ClassMethod GetResponseClassList(pRequest As %String = "") As %String [ CodeMode = objectgenerator, GenerateAfter = OnProcessInput ]
{
	Set tSignature=$$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"standardOnProcessInput",$$$cMETHformalspecparsed)
	Set tRequest1=$lg($lg(tSignature,1),2)
	Set tClass1=$lg($lg(tSignature,2),2)
	Set tSignature=$$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"OnProcessInput",$$$cMETHformalspecparsed)
	Set tRequest2=$lg($lg(tSignature,1),2)
	Set tClass2=$lg($lg(tSignature,2),2)

	Set tClass12=tClass1_$S(tClass1=tClass2:"",1:""","""_tClass2)
	If tRequest1=tRequest2 {
		Set (tClass1,tClass2)=tClass12
	}
	Do %code.WriteLine(" Quit:pRequest="""" $lb("""_tClass12_""")")
	Do %code.WriteLine(" Quit:pRequest="""_tRequest1_""" $lb("""_tClass1_""")")
	Do %code.WriteLine(" Quit:pRequest="""_tRequest2_""" $lb("""_tClass2_""")")
	Do %code.WriteLine(" Quit $lb("""")")
	Quit $$$OK
}

/// Return an array of connections for drawing lines on the config diagram
ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
	Do ##super(.pArray,pItem)
	If pItem.GetModifiedSetting("TargetConfigNames",.tValue) {
		For i=1:1:$L(tValue,",") { Set tOne=$ZStrip($P(tValue,",",i),"<>W")  Continue:""=tOne  Set pArray(tOne)="" }
	}
}

/// Add discarded characters to IO Archive
Method IOLogDiscard(pSC As %Status, pNote As %String, pDiscard As %GlobalCharacterStream)
{
	Set tIOLogEntry = ..IOLogEntry, ..IOLogEntry=$$$NULLOREF ; Save a separate entry for the unexpected input
	$$$NEWINIOLOGENTRY(pSC,pNote,pDiscard)
	$$$CLOSEIOLOGENTRY($$$OK,"",$$$NULLOREF)
	Set ..IOLogEntry = tIOLogEntry
}

}
