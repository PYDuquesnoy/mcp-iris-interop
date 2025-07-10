/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDIXML

Class EnsLib.EDI.XML.Service.Standard Extends (Ens.BusinessService, EnsLib.EDI.ServiceInterface) [ Abstract, ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter DOCCLASS As %String = "EnsLib.EDI.XML.Document";

/// Configuration items to which to send Documents
Property TargetConfigNames As %String(MAXLEN = 1000);

/// Store a set of searchable properties associated with each XML Document processed.<br>
/// These records will be stored in the named SearchTable class, if any.
Property SearchTableClass As %String [ InitialExpression = "EnsLib.EDI.XML.SearchTable" ];

/// This is 2-way interface; you can send outbound on it using a partner Business Operation. However if your target config item wishes to return an immediate response you can enable this by selecting ReplyMode='Application'.<br>
/// - Never : Do not send back any reply <br>
/// - Application : Wait for response from target config item and forward it back when it arrives
Property ReplyMode As %String(DISPLAYLIST = ",Never,Application", VALUELIST = ",Never,App") [ InitialExpression = "Never" ];

/// Category to apply to incoming XML document root node names to produce a complete DocType specification.<p/>
/// Combines with the document type name to produce a DocType assignment.
/// This setting may also contain multiple comma-separated type names followed by = and then a
/// DocTypeCategory or full DocType value to apply to documents declared as that type.<br>
/// A trailing asterisk (*) at the end of a given partial type Name will match any types with that beginning part.<p/>
/// An example: DocSchemaCategory='Qv3NL,QURX_IN990001NL=QURX_IN990001NL'; <br>
/// Note that a DocType assignment is be needed for Transformation, Validation or SearchTableClass indexing.
Property DocSchemaCategory As %String(MAXLEN = 1000);

/// Specifies types of Validation to perform <p>
/// Set to 1 to reject documents that don't pass DocType schema validation.
Property Validation As %String;

Parameter SETTINGS = "TargetConfigNames:Basic:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},SearchTableClass::selector?context={Ens.ContextSearch/SearchTableClasses?host=EnsLib.EDI.XML.Service.Standard},ReplyMode,DocSchemaCategory:Basic:selector?context={Ens.ContextSearch/SchemaCategories?host=EnsLib.EDI.XML.Service.Standard},Validation";

/// If SearchTableClass is set, use it to index any reply documents
Parameter IndexReplies As %Boolean = 0;

Method OnInit() As %Status
{
	Set:""=..ReplyMode ..ReplyMode="Never"
	Quit $$$OK
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

Method standardOnProcessInput(pDocIn As EnsLib.EDI.XML.Document, Output pDocOut As EnsLib.EDI.XML.Document) As %Status
{
	Set tSC=$$$OK, pDocOut=$$$NULLOREF
	$$$ASSERT($$$IsdefObject(pDocIn) && pDocIn.%IsA("EnsLib.EDI.XML.Document"))
	$$$sysTRACE("Got Document "_pDocIn_" / "_pDocIn.%Id())
	#; get accepted doc, resolve DocType
	Set tSCVal=..resolveAndIndex(pDocIn)
	Set tResponse=$$$NULLOREF

	If $$$ISOK(tSC)&&$$$ISOK(tSCVal)&&(""'=..TargetConfigNames) {
		Set pDocIn.IsMutable=0
		If $Case(..ReplyMode,"Never":1,:0) {
			$$$SyncCommitSet(tSyncCommit)
			For iTarget=1:1:$L(..TargetConfigNames, ",") { Set tOneTarget=$ZStrip($P(..TargetConfigNames,",",iTarget),"<>W")  Continue:""=tOneTarget
				$$$sysTRACE("Sending XML document "_pDocIn_"/"_pDocIn.%Id()_" from "_pDocIn.Source_" to '"_tOneTarget_"'")
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
			If '$IsObject(tResponse) { ; no reply message
				$$$sysTRACE("Not returning reply because SendRequestSync() of "_pDocIn_"/"_pDocIn.%Id()_" returned with no response object and status: "_$$$StatusDisplayString(tSC))
			} Else { 
				$$$sysTRACE("Returning reply document "_tResponse.%Id()_" ("_tResponse.Name_") received from document "_pDocIn.%Id()_" forwarded to "_..TargetConfigNames)
			}
		}
	} Else { ; not forwarding due to error or no target
		Set tSC=$$$ADDSC(tSC,tSCVal)
		If $Case(..ReplyMode,"Never":0,:1) {
			If $$$ISOK(tSC)&&$$$ISOK(tSCVal) {
			$$$SyncCommitSet(tSyncCommit)
				Set pDocIn.IsMutable=0, tSC=pDocIn.%Save() ; save the document because we're going to reply to it.
			$$$SyncCommitClear(tSyncCommit)
				If $$$ISERR(tSC) {
					$$$LOGERROR("Failed to save document "_pDocIn_" / "_pDocIn.%Id()_" : "_$$$StatusDisplayString(tSC))
				}
			}
			$$$sysTRACE("Returning reply but not forwarding document "_pDocIn_"/"_pDocIn.%Id()_$S($$$ISERR(tSC):" status "_$$$StatusDisplayString(tSC),1:""))
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

/// Accept only specified document names; resolve DocType and perform requested validation if any
Method resolveAndIndex(pDoc As EnsLib.EDI.Document) As %Status
{
	if '$IsObject(pDoc) Quit $$$EnsError($$$EnsErrGeneral, "Invalid Document ")
	Set tDocType=..resolveDocType(pDoc)
	Do pDoc.PokeDocType(tDocType)

	#; Do further validation if required
	Set tSC=$$$OK
	If ""'=..Validation||'..OnValidate(pDoc,..Validation,.tSC) {
		Set:""'=pDoc.DocType&&..Validation tSC=pDoc.Validate(..Validation)
	}
	Quit:$$$ISERR(tSC) tSC

	If ""'=..SearchTableClass {
		TRY {
			Set tSCStore=$classmethod(..SearchTableClass,"IndexDoc",pDoc)
			If $$$ISERR(tSCStore) $$$LOGWARNING("Failed to construct SearchTable entries for document "_pDoc_"/"_pDoc.%Id()_" with DocType='"_pDoc.DocType_"' using class '"_..SearchTableClass_"' "_$$$StatusDisplayString(tSCStore))
		} CATCH errobj { $$$LOGWARNING("Failed to invoke SearchTable method "_..SearchTableClass_".IndexDoc() for message "_pDoc_"/"_pDoc.%Id()_" with DocType='"_pDoc.DocType_"' : "_errobj.AsSystemError()) }
	}
	Quit tSC
}

/// Return the DocType that this service will assign to this document
Method resolveDocType(pDoc As EnsLib.EDI.XML.Document) As %String
{
	if '$IsObject(pDoc) {
		$$$sysTRACE("Invalid document, not an object.")
		quit ""
	}
	Set tDocType=pDoc.DocType
	If ""=tDocType {
		#; Match with the DocType specified if any in DocSchemaCategory for the received Document's type name
		Set tAcceptTypes=..DocSchemaCategory, tNameFound=pDoc.Name, tUNameFound=$ZCVT(tNameFound,"U")
		Set tLocalName=tNameFound  Set:tLocalName[":" tLocalName=$P(tLocalName,":",2)
		Set tULocalName=$ZCVT(tLocalName,"U")
		Set nTypes=$S(""=$ZStrip(tAcceptTypes,"<>W"):0, 1:$L(tAcceptTypes,","))
		Set (tVal,tDef)=""
		For i=1:1:nTypes { Set tType=$P(tAcceptTypes,",",i) Continue:""=tType
			Set tVal=$ZStrip($P(tType,"=",2),"<>W")
			Set tName=$ZStrip($P(tType,"=",1),"<>W"), tNameLen=$L(tName), tUName=$ZCVT(tName,"U")
			If ""=tVal {
				Set:""=tDef tDef=tName
			} Else {
				#; Quit on match; accept trailing wildcard also
				If $Case(tUName, tUNameFound:1, tULocalName:1, :0)
				 || ("*"=$E(tName,tNameLen) && $Case($E(tUName,1,tNameLen-1),$E(tUNameFound,1,tNameLen-1):1, $E(tULocalName,1,tNameLen-1):1, :0)) {
					If tVal[":" { Set tDocType=tVal }
					Else { Set tDocType=##class(EnsLib.EDI.XML.Schema).ResolveSchemaTypeToDocType(tVal,tLocalName,,pDoc) }
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
				Set tDocType=##class(EnsLib.EDI.XML.Schema).ResolveSchemaTypeToDocType(tDef,tLocalName,,pDoc)
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

Method reportReply(pOriginalDoc As EnsLib.EDI.Document, pReplyCode As %String = "", ByRef pSC As %Status) As EnsLib.EDI.Document
{
	If $IsObject(pReplyCode) {
		Set tReplyDoc=pReplyCode, pSC=$$$OK
		$$$sysTRACE("Reporting reply document "_tReplyDoc_" for document "_pOriginalDoc_$S('$IsObject(pOriginalDoc):"",1:" / "_pOriginalDoc.%Id()))
	} Else {Set tReplyDoc=""}
	If ""'=..SearchTableClass && $IsObject(tReplyDoc) && ..#IndexReplies {
		Set tSCStore=$classmethod(..SearchTableClass,"IndexDoc",tReplyDoc)
		If $$$ISERR(tSCStore) $$$LOGWARNING("Failed to construct SearchTable entries for reply document "_tReplyDoc_" / "_tReplyDoc.%Id()_" with DocType='"_tReplyDoc.DocType_"' using class '"_..SearchTableClass_"' "_$$$StatusDisplayString(tSCStore))
	}
	Quit:""=tReplyDoc $$$NULLOREF
	Do ..SendReply(tReplyDoc, pOriginalDoc)
	Quit $$$NULLOREF ; default behavior is not to return the reply doc from OnProcessInput()
}

Method SendReply(pReplyDocument As EnsLib.EDI.Document, pOriginalDoc As EnsLib.EDI.Document = {$$$NULLOREF}) As %Status
{
	Quit $$$EnsError($$$EnsErrGeneral, "Service does not support Reply; Document "_pReplyDocument)
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
