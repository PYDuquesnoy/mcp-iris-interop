/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.EDIFACT.Operation.ReplyStandard Extends (EnsLib.EDI.EDIFACT.Operation.Standard, EnsLib.EDI.ServiceInterface) [ Abstract, ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// <p>A comma-separated list of codes specifying what action this Operation will take on receipt of various types of acknowledgement messages and other reply status conditions.
/// The format of the list is: <br/>&lt;code&gt;=&lt;action&gt;,&lt;code&gt;=&lt;action&gt;,... <br/>
/// A &lt;code&gt; value starting with a colon - e.g. :&lt;char&gt; represents a literal value found in field TA1:4,AK5:1,or AK9:1 of the response message. <br/>
/// The expected values in these fields include: <br/>
/// <ul style="list-style-type: none;">
/// <li><b>:A</b> - Accepted <li/>
/// <li><b>:E</b> - Accepted, but Errors Were Noted <li/>
/// <li><b>:P</b> - Partially Accepted <li/>
/// <li><b>:R</b> - Rejected <li/>
/// <li><b>:M</b> - Rejected; Message Authentication Code (MAC) Failed <li/>
/// <li><b>:W</b> - Rejected; Failed Validity Tests <li/>
/// <li><b>:X</b> - Rejected; Content Decryption Failed <li/>
/// </ul></p>
/// Also, the following special code values may be used: <br/>
/// <ul style="list-style-type: none;">
/// <li><b>:~</b>  - matches replies that do not contain a TA1, AK5 or AK9 segment <li/>
/// <li><b>:_</b>  - matches replies with an empty value in the field <li/>
/// <li><b>:*</b>  - matches any value not matched otherwise <li/>
/// <li><b>:E?</b> - matches any literal value except :A <li/>
/// <li><b>:R?</b> - matches any literal value except :A, :E or :P <li/>
/// <li><b>:I?</b> - matches where the reply ControlId does not match the ControlId of the original message <li/>
/// </ul></p>
/// <p>The default behavior is ':A=C,:E=WC,:P=WC,:*=S,:~=S,:I?=W' <br/>
/// This means for responses with TA1 code E or P issue a warning, while all other codes except A suspend the current outbound
/// message and move on to the next.</p>
/// <p>Also, the following standard status conditions may be used:
/// <ul style="list-style-type: none;">
/// <li><b>E</b> - Error status returned from message handler</li>
/// <li><b>E#&lt;statuscode&gt;</b> - Error status returned from message handler has status code equal to &lt;statuscode&gt;</li>
/// <li><b>E*&lt;text&gt;</b> - Error status returned from message handler contains text string &lt;text&gt;</li>
/// <li><b>X</b> - there is no reply message at all</li>
/// </ul></p>
/// <p>The following values for &lt;actions&gt; may be used alone or in combinations: 
/// <ul style="list-style-type: none;">
/// <li><b>C</b> - Treat the message as Completed OK.</li>
/// <li><b>W</b> - Log a warning. If no other non-warning &lt;actions&gt; are triggered, the message will be treated as Completed OK.</li>
/// <li><b>R</b> - Retry the message according to the configured RetryInterval and FailureTimeout; finally Fail unless a 
/// different action is also specified. Note this setting is separate from the Retry property.</li>
/// <li><b>S</b> - Suspend the message, log an error, and move on to try the next message.</li>
/// <li><b>D</b> - Disable the Operation, log an error and restore the message to the front of the Operation's queue.</li>
/// <li><b>F</b> - Fail with an error and move on to try the next message from the Operation's queue subject to the <property>Retry</property>
/// property value set in the code. If the Retry property is set in the code then moving on to try the next message will be subject to 
/// the configured RetryInterval and FailureTimeout.</li></ul>
/// An example of a valid ReplyCodeActions specification is 'E#6301=R,E#&lt;Ens&gt;ErrGeneral=RD,E=F'. This specification will result in a 
/// retry when error code 6301 is encountered. When error code &lt;Ens&gt;ErrGeneral is encountered, the Operation first retries to send 
/// the message until FailureTimeout and then, if the error continues, it disables the Operation instead of failing. Any other errors will 
/// cause the Operation to fail processing of the current message and return the error status to the caller, without retrying first
/// unless the property Retry has been set to true by the operation code.</p>
/// <p>All codes where &lt;actions&gt; consists of only 'W' (for 'log a Warning') will be evaluated, and a warning will be
/// generated for each matching &lt;code&gt;. Other &lt;code&gt; values will be evaluated in left-to-right order, executing the
/// first matching &lt;code&gt; that has a non-warning &lt;actions&gt; value. As noted in the details for the 'W' flag, an error
/// that only triggers 'W' &lt;actions&gt; will be treated as Completed OK.</p>
Property ReplyCodeActions As %String(MAXLEN = 1000);

Parameter SETTINGS = "ReplyCodeActions,NoFailWhileDisconnected";

Property %Parser As EnsLib.EDI.EDIFACT.Parser;

/// If SearchTableClass is given, use it to index any replies (including ACKs unless IndexACKs=0 or OK and SaveOKACKs=0)
Parameter IndexReplies As %Boolean = 1;

/// Index ACKs if IndexReplies is also true and SearchTable class is given
Parameter IndexACKs As %Boolean = 0;

/// Save OK ACKs
Parameter SaveOKACKs As %Boolean = 0;

/// Log a Warning if the reply MSA:2 ControlId does not match the original message's control ID
/// (Deprecated - use Setting ReplyCodeActions instead of subclassing)
Parameter WarnACKControlId As %Boolean = 1;

/// Don't report an error for reply messages containing no MSA:1 field
/// (Deprecated - use Setting ReplyCodeActions instead of subclassing)
Parameter AllowNonMSA As %Boolean = 0;

/// Set the DocType and MessageTypeCategory properties of the reply message if possible
Parameter SetReplyDocType As %Boolean = 1;

/// parsed array property of ReplyCodeActions setting
Property %replyActionMap [ MultiDimensional ];

Method OnInit() As %Status
{
	Set ..%Parser=##class(EnsLib.EDI.EDIFACT.Parser).%New($this)
	Set:""=..ReplyCodeActions ..ReplyCodeActions="?E=S,?R=S,~="_$S(..#AllowNonMSA:"W",1:"S")_",I?="_$S(..#WarnACKControlId:"W",1:"C")_",T?=C"
	Do ..buildReplyActionMap()
	Quit ##super()
}

/// build parsed array property of ReplyCodeActions setting
Method buildReplyActionMap() As %Status
{
 	Set nActions=$S(""=$ZStrip(..ReplyCodeActions,"<>W"):0, 1:$L(..ReplyCodeActions,","))
	For i=1:1:nActions { Set tType=$P(..ReplyCodeActions,",",i) Continue:""=tType
		Set tErrCode=$ZStrip($P(tType,"="),"<>W")
		Set tAction=$ZCVT($ZStrip($P(tType,"=",2),"<>W"),"U")
		Continue:""=tErrCode&&$D(..%replyActionMap("_"))
		Set:""=tErrCode tErrCode="_"
		Set:"~"=tErrCode tErrCode="~NoSeg"
		Set:tAction'?1.(1"R",1"C",1"W",1"S",1"D",1"F") tAction=$Case($ZCVT(tErrCode,"U"), "A":"C", :"S")
		Set:tAction?1."R" tAction=tAction_"F"
		Set ..%replyActionMap(tErrCode)=tAction
	}
	Quit $$$OK
}

Method SendMessage(pMsgOut As EnsLib.EDI.EDIFACT.Document, Output pMsgIn As EnsLib.EDI.EDIFACT.Document) As %Status [ CodeMode = expression ]
{
$$$ERROR($$$EnsErrGeneral,"Subclass Responsibility")
}

Method OnMessage(pRequest As EnsLib.EDI.EDIFACT.Document, Output pResponse As EnsLib.EDI.EDIFACT.Document) As %Status
{
	Set pResponse=$$$NULLOREF
	
	Set tSC=$zobjmethod($this,"validateAndIndex",pRequest) Quit:$$$ISERR(tSC) tSC
	
	#; Send the message and get reply if any
	Set tSC=$zobjmethod($this,"SendMessage",pRequest,.tReplyMsg) Quit:$$$ISERR(tSC) tSC

	If $IsObject(tReplyMsg) {
		Set tReqId=pRequest.%Id(), tReplyMsg.Source=tReqId_$C(13,10)_..Adapter.GetAddress()
		#; Add on CorrespondingMessageId as 3rd piece.
		Try {Set tReplyDoc.Source=tReplyDoc.Source_$C(13,10)_..%RequestHeader.%Id()} Catch {}
	}
	Do $zobjmethod($this,"OnReplyDocument",.tReplyMsg,pRequest)
	Quit:'$IsObject(tReplyMsg) tSC
	
	Set tReplyMsg.OriginalDocId=tReqId
	Set tReplyName=tReplyMsg.Name, tReplyCategory=$S(""'=pRequest.MessageTypeCategory:pRequest.MessageTypeCategory,1:$P(pRequest.DocType,":"))
	Set tReplyDocType=##class(EnsLib.EDI.SEF.Schema).ResolveSchemaTypeToDocType(tReplyCategory,tReplyName)
	$$$sysTRACE("Got reply message "_tReplyMsg_" of type "_tReplyName)
	If ..#SetReplyDocType
	 && ..%RequestHeader.needsReply()
	 && (""=tReplyMsg.DocType) && (""'=tReplyDocType) {
		Do tReplyMsg.PokeDocType(tReplyDocType)
	}
	Set tReplyMsg.IsMutable=0
	Do ..getReplyAction(tReplyMsg,pRequest,tReplyName,.tAction,.tErrCode,.tCIdText,.tTypeText)
	If ..#SaveOKACKs || $Case(tReplyName,"Interchange":0,"Group":0,"997":0,:1) || $Case(tErrCode, "A":0, :1) {
		#; Save replies if they are odd or error ACKs or if we are built to save all
		If ""'=..SearchTableClass && ..#IndexReplies {
			Set tSCStore=$zobjclassmethod(..SearchTableClass,"IndexDoc",tReplyMsg)
			If $$$ISERR(tSCStore) $$$LOGWARNING("Failed to construct SearchTable instance for message "_tReplyMsg_$S(""=tReplyMsg.%Id():"",1:" / "_tReplyMsg.%Id())_" with DocType='"_tReplyMsg.DocType_"' using class '"_..SearchTableClass_"' "_$$$StatusDisplayString(tSCStore))
		} Else {
			Set tSCStore=tReplyMsg.%Save()
			If $$$ISERR(tSCStore) $$$LOGERROR("Failed to save reply message "_tReplyMsg_$S(""=tReplyMsg.%Id():"",1:" / "_tReplyMsg.%Id())_" with DocType='"_tReplyMsg.DocType_"' "_$$$StatusDisplayString(tSCStore))
		}
	}
	Set:tAction'="C" tSC=..doReplyAction(tAction,tErrCode,tCIdText,tTypeText,pRequest,tReplyMsg)
	Set:$$$ISOK(tSC) pResponse = tReplyMsg
	Quit tSC
}

Method getReplyAction(pReplyMsg As EnsLib.EDI.EDIFACT.Document, pRequest As EnsLib.EDI.EDIFACT.Document, pReplyName As %String, Output pAction As %String, Output pErrCode As %String, Output pCIdText As %String, Output pTypeText As %String)
{
	Set pErrCode="~NoSeg", pCIdText="", pTypeText=""
	If "Interchange"=pReplyName {
		#; Find TA1 error reporting ISA/IEA problem
		Set tTA1=pReplyMsg.GetSegmentAt(2)
		Set:$IsObject(tTA1)&&("TA1"=tTA1.GetValueAt(0)) pErrCode=$ZStrip(tTA1.GetValueAt(4),"<>W")
		Set:""=pErrCode pErrCode="_"
		If (("~NoSeg"'=pErrCode)&&(pRequestControlID'=tTA1.GetValueAt(1))) {
			Set pCIdText="TA1:1 ControlId '"_tTA1.GetValueAt(1)_"' does not match original message ControlId '"_pRequestControlID_"'"
		}
		#; Try nested groups
		Set tChild=$$$NULLOREF,iChild=0  For { Set tChild=pReplyMsg.NextChild(tChild)  Set tChildName=tChild.Name  Quit:'$IsObject(tChild)||("Group"'=tChildName)  Set iChild=iChild+1
			Do ..getGroupReplyAction(iChild, tChild, pRequest, tChildName, .pAction, .pErrCode, .pCIdText, .pTypeText)
		}
	} ElseIf "Group"=pReplyName {
		Do ..getGroupReplyAction(0, pReplyMsg, pRequest, pReplyName, .pAction, .pErrCode, .pCIdText, .pTypeText)
	} ElseIf "997"=pReplyName {
		Do ..getTSReplyAction(0, pReplyMsg, pRequest, pReplyName, .pAction, .pErrCode, .pCIdText, .pTypeText)
	}
	Set pAction=$G(..%replyActionMap(pErrCode))  If ""=pAction Set tErrUpper=$ZCVT(pErrCode,"U"), pAction=$G(..%replyActionMap(tErrUpper))  If ""=pAction Set pAction=$G(..%replyActionMap("*"))  Set:""=pAction pAction=$Case(tErrUpper,"A":"C",:"S")
	
	If pCIdText'="" {
		Set tCIdAction=$G(..%replyActionMap("I?"),$G(..%replyActionMap("*"),"S"))
		Set:"C"'=tCIdAction pAction=pAction_"/"_tCIdAction
	}
}

Method getGroupReplyAction(pPosition As %Integer, pReplyMsg As EnsLib.EDI.EDIFACT.Document, pRequest As EnsLib.EDI.EDIFACT.Document, pReplyName As %String, Output pAction As %String, Output pErrCode As %String, Output pCIdText As %String, Output pTypeText As %String)
{
	#; Find AK9 error reporting GS/GE problem
	Set tNumSegs=pReplyMsg.SegCount  For i=2:1:tNumSegs-1 { Set tSeg=pReplyMsg.GetSegmentAt(i)  Continue:'$IsObject(tSeg)
		Set tName=tSeg.GetValueAt(0)
		If "AK1"=tName&&("Group"=pRequest.Name)&&(tSeg.GetValueAt(2)=pRequest.GetValueAt("1:6")) {
			Set pCIdText=$S(""=pCIdText:"",1:pCIdText_" ; ")_"AK1:2 Group ControlId '"_tSeg.GetValueAt(2)_"' does not match original message GS:6 ControlId '"_pRequest.GetValueAt("1:6")_"'"
		}
		Continue:"AK9"'=tName
		Set tErr=$ZStrip(tSeg.GetValueAt(1),"<>W")
		Set:""=tErr tErr="_"
		Set:$Case(pErrCode, "~NoSeg":1, "_":1, "A":(tErr'="_"), "E":$Case(tErr,"_":0,"A":0,:1),:0) pErrCode=tErr

	}
	#; Try nested TransactionSets
	Set tChild=$$$NULLOREF,iChild=0  For { Set tChild=pReplyMsg.NextChild(tChild)  Set tChildName=tChild.Name  Quit:'$IsObject(tChild)||("Group"'=tChildName)  Set iChild=iChild+1
		Do ..getTSReplyAction(iChild, tChild, pRequest, tChildName, .pAction, .pErrCode, .pCIdText, .pTypeText)
	}
}

Method getTSReplyAction(pPosition As %Integer, pReplyMsg As EnsLib.EDI.EDIFACT.Document, pRequest As EnsLib.EDI.EDIFACT.Document, pReplyName As %String, Output pAction As %String, Output pErrCode As %String, Output pCIdText As %String, Output pTypeText As %String)
{
	#; Find AK5 error reporting TransactionSet problem
	Set tNumSegs=pReplyMsg.SegCount  For i=2:1:tNumSegs-1 { Set tSeg=pReplyMsg.GetSegmentAt(i)  Continue:'$IsObject(tSeg)
		Set tName=tSeg.GetValueAt(0)
		If "AK2"=tName&&("Group"'=pRequest.Name)&&("Interchange"'=pRequest.Name)&&(tSeg.GetValueAt(2)=pRequest.GetValueAt("1:2")) {
			Set pCIdText=$S(""=pCIdText:"",1:pCIdText_" ; ")_"AK2:2 TransactionSet ControlId '"_tMSA.GetValueAt(2)_"' does not match original message GS:6 ControlId '"_pRequest.GetValueAt("1:6")_"'"
		}
		Set:"AK5"=tSeg.GetValueAt(0) tErr=$ZStrip(tSeg.GetValueAt(1),"<>W")
		Set:""=tErr tErr="_"
		Set:$Case(pErrCode, "~NoSeg":1, "_":1, "A":(tErr'="_"), "E":$Case(tErr,"_":0,"A":0,:1),:0) pErrCode=tErr
	}
}

/// Construct and return an Action string consisting of supported action code letters, based on qualities of the Request, Response, and Error Status.
Method OnGetReplyAction(pRequest As EnsLib.EDI.EDIFACT.Document, Output pResponse As EnsLib.EDI.EDIFACT.Document, ByRef pSC As %Status) As %String
{
 	Set (tMSACode,tFullAction,tText)=""
 	Set nActions=$S(""=$ZStrip(..ReplyCodeActions,"<>W"):0, 1:$L(..ReplyCodeActions,","))
	Set tUseMapAt=$P($G(..%ActionHint("UseMapAt"),nActions+1),"-")
	Set tAckType=..%ActionHint("AckType")
	For i=1:1:nActions { Set tType=$P(..ReplyCodeActions,",",i) Continue:""=tType
		Set tAction="", tCode=$ZStrip($P(tType,"="),"<>W")
		Set tMatch=$Case($E(tCode)
			,"":0
			,"E":$$$ISERR(pSC)
			,":":-1
			,:""
			)
		If tMatch>0 {
			Set tMatch=$Case($E(tCode,2)
							,"#":$$$StatusEquals(pSC,$E(tCode,3,*))
							,"*":$$$StatusText(pSC)[$E(tCode,3,*)
							,:1)
		} ElseIf tMatch<0 {
			Set tMatch=0
			If ":I?"=tCode {
				Do:""=tMSACode getMSACode
				If ("~NoMSA"'=tMSACode)&&("1-byte "'=$E(tMSA.GetValueAt(3),1,$L("1-byte "))) {
					Set tReq=pRequest  While $Case(tReq.Name,"FHS":1,"BHS":1,:0) {
						Set tReq=tReq.NextChild()
						If '$IsObject(tReq) Set tReq=pRequest  Quit
					}
					Set tRequestControlID = tReq.GetValueAt("1:10")
					If (tRequestControlID'=tMSA.GetValueAt(2)) {
						Set tMatch=1, tMatchText="MSA:2 ControlId '"_tMSA.GetValueAt(2)_"' does not match original message ControlId '"_tRequestControlID_"'"
					}
				}
			} Else {
				#; Get MSA code if not already cached
				Do:""=tMSACode getMSACode
				#; Get action from the map, or test for a match the old fashioned way
				If i=tUseMapAt {
					#; Use map
					Set tAction=$G(..%replyActionMap(tMSACode))  If ""=tAction Set tAction=$G(..%replyActionMap(tMSACodeU))  If ""=tAction Set tAction=$G(..%replyActionMap("*"))
					Set tMatch=(""'=tAction)
					Set tLastI=$P(..%ActionHint("UseMapAt"),"-",2)
					Set:tMatch tMatchText= "MSA code '"_tMSACode_"' matched ReplyCodeActions "_i_"-"_tLastI_" : '"_$P(..ReplyCodeActions,",",i,tLastI)_"'"
					Set i=tLastI ; skip other contiguous mapped ':' entries
				} Else {
					#; Don't use map; check it manually
					Set tCode=$E(tCode,2,*)
					If "?"=$E(tCode) { Set tMatch=($E(tCode,2,*)=$E(tMSACode,2,*))||($E(tMSACodeU)?1(1"A",1"C")&&($E(tMSACodeU,2)=$E(tCode,2))) }
					ElseIf "_"=tCode { Set tMatch=("_"=tMSACode) }
					ElseIf "~"=tCode { Set tMatch=("~NoMSA"=tMSACode) }
					ElseIf "*"=tCode { Set tMatch=("~NoMSA"'=tMSACode) }
					Else {             Set tMatch=(tMSACode=tCode) }
					Set:tMatch tMatchText="MSA code '"_tMSACode_"' matched ReplyCodeAction "_i_" : ':"_tCode_"'"
				}
			}
		}
		If tMatch {
			Set:""=tAction tAction=$ZCVT($ZStrip($P(tType,"=",2),"<>W"),"U")
			Continue:""=tAction
			Set:""'=tMatchText tText=tText_$S(""'=tText:" and ",1:"")_tMatchText
			Set:tAction["W" tFullAction=""
			Set tFullAction=tAction_$S(tAction["W":"",1:tFullAction)
			Quit:tFullAction'?1."W"
		} ElseIf tMatch'=0 {
			$$$LOGWARNING("Unrecognized reply code:'"_tCode_"'")
		} ; else it remains "" and is unrecognized
	}
	Set:""'=tText ..%ActionHint("CodeReason")=
		"EDIFACT Message body "_pRequest_" / "_pRequest.%Id()_
		" because response "_pResponse_$S(""=pResponse.%Id():"",1:" / "_pResponse.%Id())_" "_
		tText_" resulting in Action code "_tFullAction_
		" : "_$TR(pResponse.RawContent,$C(13)," ")

	#; Save reply if it's special, or if we're built to save even ordinary OK ACKs
	Do:""=tMSACode&&'(..#SaveOKACKs || ("ACK"'=tAckType)) getMSACode
	If ..#SaveOKACKs || ("ACK"'=tAckType) || $Case(tMSACode,"AA":0,"CA":0,:1) {
		#; Index reply if indexing and it's a non-ack or if we're built to index ACKs as well as other types of replies
		If ""'=..SearchTableClass && ..#IndexReplies && (..#IndexACKs || ("ACK"'=tAckType)) {
			Set tSCStore=$zobjclassmethod(..SearchTableClass,"IndexDoc",pResponse)
			If $$$ISERR(tSCStore) $$$LOGWARNING("Failed to construct SearchTable instance for message "_pResponse_$S(""=pResponse.%Id():"",1:" / "_pResponse.%Id())_" with DocType='"_pResponse.DocType_"' using class '"_..SearchTableClass_"' "_$$$StatusDisplayString(tSCStore))
		} Else {
			Set tSCStore=pResponse.%Save()
			If $$$ISERR(tSCStore) $$$LOGERROR("Failed to save reply message "_pResponse_$S(""=pResponse.%Id():"",1:" / "_pResponse.%Id())_" with DocType='"_pResponse.DocType_"' "_$$$StatusDisplayString(tSCStore))
		}
	}
	Quit tFullAction
getMSACode
	#; Get MSA code if not already cached
	Set tReplyMsg=pResponse
	While $Case(tReplyMsg.Name,"FHS":1,"BHS":1,:0) {
		Set tReplyMsg=tReplyMsg.NextChild()
		If '$IsObject(tReplyMsg) Set tReplyMsg=pResponse  Quit
	}
	Set tMSA=tReplyMsg.GetSegmentAt(2)

	Set tMSACode=$S($IsObject(tMSA)&&("MSA"=tMSA.GetValueAt(0)):$ZStrip(tMSA.GetValueAt(1),"<>W"), 1:"~NoMSA")
	Set:""=tMSACode tMSACode="_"
	Set tMSACodeU=$ZCVT(tMSACode,"U")
	Quit
}

/// Override this method to modify or delete or log the reply (ACK) message document object
Method OnReplyDocument(ByRef pReplyDocument As EnsLib.EDI.EDIFACT.Document, pRequest As EnsLib.EDI.EDIFACT.Document)
{
	Quit
}

/// Return the segment terminator string that the Parser will use.
Method GetSegmentTerminator() As %String
{
	Quit $C(13) ; $C(##class(EnsLib.EDI.EDIFACT.Document).%GetParameter("SegTerminatorAscii"))
}

/// Add discarded characters to IO Archive
Method IOLogDiscard(pSC As %Status, pNote As %String, pDiscard As %GlobalCharacterStream)
{
	Set tIOLogEntry = ..IOLogEntry, ..IOLogEntry=$$$NULLOREF ; Save a separate entry for the unexpected input
	$$$NEWOUTIOLOGENTRY(pSC,pNote,$$$CurrentMethod,"%GlobalCharacterStream")
	$$$CLOSEIOLOGENTRY($$$OK,"",pDiscard)
	Set ..IOLogEntry = tIOLogEntry
}

}
