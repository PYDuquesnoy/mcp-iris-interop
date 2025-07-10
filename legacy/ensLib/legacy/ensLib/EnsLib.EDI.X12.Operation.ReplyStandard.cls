/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.X12.Operation.ReplyStandard Extends (EnsLib.EDI.X12.Operation.Standard, EnsLib.EDI.ServiceInterface) [ Abstract, ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// <p>A comma-separated list of codes specifying what action this Operation will take on receipt of various types of acknowledgement messages and other reply status conditions.
/// The format of the list is: <br/>&lt;code&gt;=&lt;action&gt;,&lt;code&gt;=&lt;action&gt;,... <br/>
/// A &lt;code&gt; value starting with a colon - e.g. :&lt;char&gt; represents a literal value found in field TA1:4,AK5:1,or AK9:1 of the response message.
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
/// the configured RetryInterval and FailureTimeout. The X12 TCP outbound adapter sets the operation's Retry property to true 
/// when there are network connection errors. </li></ul>
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

Property %Parser As EnsLib.EDI.X12.Parser;

/// If SearchTableClass is given, use it to index any replies (including ACKs unless IndexACKs=0 or OK and SaveOKACKs=0)
Parameter IndexReplies As %Boolean = 1;

/// Index ACKs if IndexReplies is also true and SearchTable class is given
Parameter IndexACKs As %Boolean = 0;

/// Save OK ACKs
Parameter SaveOKACKs As %Boolean = 0;

/// Set the DocType property of the reply message if possible
Parameter SetReplyDocType As %Boolean = 1;

/// parsed array property of ReplyCodeActions setting
Property %replyActionMap [ MultiDimensional ];

Method OnInit() As %Status
{
	Set ..%Parser=##class(EnsLib.EDI.X12.Parser).%New($this)
	If "*"=$E(..Framing,*) { Set ..%Parser.Framing="Flexible", ..Framing=$E(..Framing,1,*-1) }
	Else { Set ..%Parser.Framing=..Framing }
 // The default behavior is ':A=C,:E=WC,:P=WC,:*=S,:~=S,:I?=W'
	Set:""=..ReplyCodeActions ..ReplyCodeActions=":A=C,:E=WC,:P=WC,:*=S,:~=S,:I?=W"
	Do ..buildReplyActionMap()
	Quit ##super()
}

/// build parsed array property of ReplyCodeActions setting
Method buildReplyActionMap() As %Status
{
	Set nActions=$S(""=$ZStrip(..ReplyCodeActions,"<>W"):0, 1:$L(..ReplyCodeActions,","))
	Set (tFirst,tOther)=0
	For i=1:1:nActions { Set tType=$P(..ReplyCodeActions,",",i) Continue:""=tType
		Set tCode=$ZStrip($P(tType,"="),"<>W"), tCodeU=$ZCVT(tCode,"U")
		Set tAction=$ZCVT($ZStrip($P(tType,"=",2),"<>W"),"U")
		Continue:tCode_tAction=""
		If tOther { If tOther-tFirst>1 { Continue } Else { Set (tFirst,tOther)=0 Kill ..%replyActionMap /* loner; start again */ } }
		If ":"=$E(tCode)&&$Case(tCodeU,"E?":0,"R?":0,":I?":0,:1) { Set:'tFirst tFirst=i } Else { Set:("W"'=tAction)&&tFirst tOther=i  Continue }
		
		#; Now we are in a cluster of : values that we want to build a map from
		Set tCode=$E(tCode,2,*), tCodeU=$E(tCodeU,2,*)
		Continue:""=tCode&&$D(..%replyActionMap("_"))

		Set:""=tCode tCode="_"
		Set:"~"=tCode tCode="~NoACK"
		Set:tAction'?1.(1"C",1"W",1"R",1"S",1"D",1"F") tAction=$Case(tCodeU, "A":"C", :"S")
		Set:tAction?1."R" tAction="RF"
		Set ..%replyActionMap(tCodeU)=tAction
		If tCodeU?1(1"A",1"E",1"P",1"R",1"M",1"W",1"X") {
			Set ..%replyActionMap(tCodeU)=tAction
		} Else {
			Set ..%replyActionMap(tCode)=tAction
		}
	}
	#; optimization: use map if ':' conditions are grouped together
	Set tEnd=$S(tOther:tOther-1,1:nActions)
	Set:tFirst&&(tEnd-tFirst>0) ..%replyActionMap("%UseMapAt",tFirst)=tEnd
	Quit $$$OK
}

Method SendMessage(pMsgOut As EnsLib.EDI.X12.Document, Output pMsgIn As EnsLib.EDI.X12.Document) As %Status [ CodeMode = expression ]
{
$$$ERROR($$$EnsErrGeneral,"Subclass Responsibility")
}

Method OnMessage(pRequest As EnsLib.EDI.X12.Document, Output pResponse As EnsLib.EDI.X12.Document) As %Status
{
	Set pResponse=$$$NULLOREF
	
	Set tSC=$method($this,"validateAndIndex",pRequest) Quit:$$$ISERR(tSC) tSC
	
	#; Send the message and get reply if any
	Set tSC=$method($this,"SendMessage",pRequest,.tReplyDoc) Quit:$$$ISERR(tSC) tSC

	If $IsObject(tReplyDoc) {
		Set tReqId=pRequest.%Id(), tReplyDoc.Source=tReqId_$C(13,10)_..Adapter.GetAddress()
		#; Add on CorrespondingMessageId as 3rd piece.
		Try {Set tReplyDoc.Source=tReplyDoc.Source_$C(13,10)_..%RequestHeader.%Id()} Catch {}
	}
	Do $method($this,"OnReplyDocument",.tReplyDoc,pRequest)
	Quit:'$IsObject(tReplyDoc) tSC

	Set tReplyDoc.OriginalDocId=tReqId
	Set tReplyTypeName=tReplyDoc.Name, tReplyCategory=$S(""'=pRequest.DocTypeCategory:pRequest.DocTypeCategory,1:$P(pRequest.DocType,":"))
	Set tReplyDocType=##class(EnsLib.EDI.X12.Schema).ResolveSchemaTypeToDocType(tReplyCategory,tReplyTypeName)
	$$$sysTRACE("Got reply message "_tReplyDoc_" of type "_tReplyTypeName)
	If ..#SetReplyDocType
	 && ..%RequestHeader.needsReply()
	 && (""=tReplyDoc.DocType) && (""'=tReplyDocType) {
		Do tReplyDoc.PokeDocType(tReplyDocType)
	}
	Set tReplyDoc.IsMutable=0
	Kill ..%ActionHint  Set ..%ActionHint("ReplyType")=tReplyTypeName, ..%ActionHint("MsgType")="X12"
	Set:$$$ISOK(tSC) pResponse = tReplyDoc
	Quit tSC
}

/// Construct and return an Action string consisting of supported action code letters, based on qualities of the Request, Response, and Error Status.
Method OnGetReplyAction(pRequest As EnsLib.EDI.X12.Document, Output pResponse As EnsLib.EDI.X12.Document, ByRef pSC As %Status) As %String
{
	Set (tCode,tAckCode,tFullAction,tText)=""
	Set nActions=$S(""=$ZStrip(..ReplyCodeActions,"<>W"):0, 1:$L(..ReplyCodeActions,","))
	Set tUseMapAt=$O(..%replyActionMap("%UseMapAt",""),1,tLastI)  Set:""=tUseMapAt tUseMapAt=nActions+1
	For i=1:1:nActions { Set tType=$P(..ReplyCodeActions,",",i)  Continue:""=tType
		If ""'=tCode $$$LOGWARNING("Unrecognized reply code:'"_tCode_"'")
		Set tAction="", tCode=$ZStrip($P(tType,"="),"<>W"), tCodeU=$ZCVT(tCode,"U")
		Set tKnown=$Case($E(tCodeU)
						,"E":$Case($E(tCode,2)
								,"#":1
								,"*":1
								,"":1
								,:0)
						,"X":$Case($E(tCode,2),"":1,:0)
						,":":1
						,:0)
		Continue:'tKnown
		Set tMatch=$Case($E(tCodeU)
			,"":0
			,"E":$$$ISERR(pSC)
			,"X":'$$$IsdefObject(pResponse)
			,":":-1
			,:"")
		If tMatch>0 {
			Set tMatch=$Case($E(tCode,2)
							,"#":$$$StatusEquals(pSC,$E(tCode,3,*))
							,"*":$$$StatusText(pSC)[$E(tCode,3,*)
							,:1)
			If tMatch {
				If $E(tCodeU)="X" {
					#;If we have an error then ignore empty response match
					If $$$ISERR(pSC) {
						Set tMatch = 0
					} Else {
						Set tMatchText="Empty Response object matched ReplyCodeAction "_i_" : ':"_tCode_"'"
					}
				} Else {
					Set tMatchText="Status '"_$$$StatusDisplayString(pSC)_"' matched ReplyCodeAction "_i_" : '"_tCode_"'"
				}
			}
		} ElseIf tMatch<0 {
			Set tMatch=0
			If '$$$IsdefObject(pResponse) Set tCode="" Continue
			If ":I?"=tCode {
				Do:""=tAckCode ..getReplyAckCode(pResponse,.tAckCode,.tAckCodeU,.tAckControlId,.tSource)
				If ("~NoACK"'=tAckCode) {
					If ""=tAckControlId {
						Set tMatch=1, tMatchText="No TA1,AK1 or AK2 ControlId found in response message,"
					} Else {
						Set tSrcSeg=$P(tSource,":",5)
						If "Interchange"=pRequest.Name {
							Set tRequestControlID = pRequest.GetValueAt("1:"_$$$ISAInterchangeControlNumber)
							If "TA1"=tSrcSeg {
								If tAckControlId'=tRequestControlID {
									Set tMatch=1, tMatchText="TA1:1 ControlId '"_tAckControlId_"' does not match original message ISA ControlId '"_tRequestControlID_"'"
								} // else it's OK
							} ElseIf "AK1"=tSrcSeg {
								Set tMatch=1, tMatchText="AK1:2 Group ControlId '"_tAckControlId_"' can't be compared with ISA ControlId '"_tRequestControlID_"'"
							} Else {
								Set tMatch=1, tMatchText="AK2:2 TransactionSet ST ControlId '"_tAckControlId_"' can't be compared with ISA ControlId '"_tRequestControlID_"'"
							}
						} ElseIf "Group"=pRequest.Name {
							Set tRequestControlID = pRequest.GetValueAt("1:6")
							If "TA1"=tSrcSeg {
								Set tMatch=1, tMatchText="TA1:13 Interchange ControlId '"_tAckControlId_"' can't be compared with Group GS ControlId '"_tRequestControlID_"'"
							} ElseIf "AK1"=tSrcSeg {
								If tAckControlId'=tRequestControlID {
									Set tMatch=1, tMatchText="AK1:2 Group ControlId '"_tAckControlId_"' does not match original Group GS ControlId '"_tRequestControlID_"'"
								} // else it's OK
							} Else {
								Set tMatch=1, tMatchText="AK2:2 TransactionSet ST ControlId '"_tAckControlId_"' can't be compared with Group GS ControlId '"_tRequestControlID_"'"
							}
						} ElseIf "ST"=pRequest.GetValueAt("1:0") {
							Set tRequestControlID = pRequest.GetValueAt("1:2")
							If "TA1"=tSrcSeg {
								Set tMatch=1, tMatchText="TA1:13 Interchange ControlId '"_tAckControlId_"' can't be compared with TransactionSet ST ControlId '"_tRequestControlID_"'"
							} ElseIf "AK1"=tSrcSeg {
								Set tMatch=1, tMatchText="AK1:2 Group ControlId '"_tAckControlId_"' can't be compared with TransactionSet ST ControlId '"_tRequestControlID_"'"
							} Else {
								If tAckControlId'=tRequestControlID {
									Set tMatch=1, tMatchText="AK2:2 Group ControlId '"_tAckControlId_"' does not match original Group GS ControlId '"_tRequestControlID_"'"
								} // else it's OK
							}
						} Else {
							Set tMatch=1, tMatchText="ControlId '"_tAckControlId_"' can't be compared with any value from TransactionSet segment 1 of type '"_pRequest.GetValueAt("1:0")_"'"
						}
					}
				}
			} Else {
				#; Get Ack code if not already cached
				Do:""=tAckCode ..getReplyAckCode(pResponse,.tAckCode,.tAckCodeU,.tAckControlId,.tSource)
				#; Get action from the map, or test for a match the old fashioned way
				If i=tUseMapAt {
					#; Use map
					Set tAction=$G(..%replyActionMap(tAckCode))  If ""=tAction Set tAction=$G(..%replyActionMap(tAckCodeU))  If ""=tAction Set tAction=$G(..%replyActionMap("*"))
					Set tMatch=(""'=tAction)
					Set:tMatch tMatchText= "Ack code '"_tAckCode_"' matched ReplyCodeActions "_i_"-"_tLastI_" : '"_$P(..ReplyCodeActions,",",i,tLastI)_"'"
					Set i=tLastI ; skip other contiguous mapped ':' entries
				} Else {
					#; Don't use map; check it manually
					Set tCode=$E(tCode,2,*), tCodeU=$ZCVT(tCode,"U")
					If "_"=tCode { Set tMatch=("_"=tAckCode) }
					ElseIf "~"=tCode { Set tMatch=("~NoACK"=tAckCode) }
					ElseIf "*"=tCode { Set tMatch=("~NoACK"'=tAckCode) }
					ElseIf "*"=tCode { Set tMatch=("~NoACK"'=tAckCode) }
					ElseIf "*"=tCode { Set tMatch=("~NoACK"'=tAckCode) }
					ElseIf "E?"=tCode { Set tMatch=("A"'=tAckCodeU) }
					ElseIf "R?"=tCode { Set tMatch='(tAckCodeU?1(1"A",1"E",1"P")) }
					ElseIf tCodeU?1(1"A",1"E",1"P",1"R",1"M",1"W",1"X") { Set tMatch=(tAckCodeU=tCodeU) }
					Else {             Set tMatch=(tAckCode=tCode) }
					Set tSrc=$S(""=$P(tSource,":",2):"",1: " from seg "_$P(tSource,":",3)_":"_$P(tSource,":",4)_" ("_$P(tSource,":",2)_":"_$P(tSource,":",4)_")")
					Set:tMatch tMatchText="Ack code '"_tAckCode_"'"_tSrc_" matched ReplyCodeAction "_i_" : ':"_tCode_"'"
				}
			}
		}
		If tMatch {
			Set:""=tAction tAction=$ZCVT($ZStrip($P(tType,"=",2),"<>W"),"U")
			If ""=tAction Set tCode="" Continue
			Set:""'=tMatchText tText=tText_$S(""'=tText:" and ",1:"")_tMatchText
			#; Make sure tFullAction has no more than 1 'W' in it; Quit if it is not just 'W'
			Set:tAction["W" tFullAction=""
			Set tFullAction=tAction_$S(tAction["W":"",1:tFullAction)
			Quit:tFullAction'?1."W"
		} ElseIf tMatch'=0 {
			$$$LOGWARNING("Unrecognized reply code:'"_tCode_"'")
		} ; else it remains 0 and is not a match
		Set tCode=""
	}
	Set:""'=tText ..%ActionHint("CodeReason")=
		"X12 Message body "_pRequest_" / "_pRequest.%Id()_" because response "_
		$S('$IsObject(pResponse):"'"_pResponse_"'", 1:pResponse_$S(""=pResponse.%Id():"",1:" / "_pResponse.%Id()))_" "_
		tText_", resulting in Action code "_tFullAction_
		$TR($S('$IsObject(pResponse):pResponse,1:" : "_pResponse.RawContent),$C(13)," ")

	#; Save reply if it's special, or if we're built to save even ordinary OK ACKs
	If $IsObject(pResponse) {
		Do:""=tAckCode ..getReplyAckCode(pResponse,.tAckCode,.tAckCodeU,.tAckControlId,.tSource)
		If ..#SaveOKACKs || $Case(tAckCode,"A":0,:1) {
			#; Index reply if indexing and it's a non-ack or if we're built to index ACKs as well as other types of replies
			If ""'=..SearchTableClass && ..#IndexReplies && (..#IndexACKs || (tAckCode'="_")) {
				Set tSCStore=$classmethod(..SearchTableClass,"IndexDoc",pResponse)
				If $$$ISERR(tSCStore) $$$LOGWARNING("Failed to construct SearchTable instance for message "_pResponse_$S(""=pResponse.%Id():"",1:" / "_pResponse.%Id())_" with DocType='"_pResponse.DocType_"' using class '"_..SearchTableClass_"' "_$$$StatusDisplayString(tSCStore))
			} Else {
				Set tSCStore=pResponse.%Save()
				If $$$ISERR(tSCStore) $$$LOGERROR("Failed to save reply message "_pResponse_$S(""=pResponse.%Id():"",1:" / "_pResponse.%Id())_" with DocType='"_pResponse.DocType_"' "_$$$StatusDisplayString(tSCStore))
			}
		}
	}
	Quit tFullAction
}

ClassMethod getReplyAckCode(pReplyDoc As EnsLib.EDI.X12.Document, Output pAckCode As %String, Output pAckCodeU As %String, Output pAckControlId As %String, Output pSource As %String) [ Internal ]
{
	Set (pAckCode,pAckCodeU)="~NoACK", (pAckControlId,pSource,tCtlIdElem)=""
	#; loop over segments looking for a TA1 or Groups or AK5/AK9 from flat groups or flat 997 TransactionSets
	#; Find TA1 error reporting ISA/IEA problem
	Set nSegs=pReplyDoc.SegCount
	For i=1:1:nSegs { Set tSeg=pReplyDoc.getSegmentByIndex(i)  Continue:'$IsObject(tSeg)  Set tSegName=tSeg.Name
		If 'tSeg.IsChildHolder(.tRef) {
			Set tElem=$Case(tSegName
							,"TA1":$$$TA1InterchangeControlNumber
							,"AK1":2
							,"AK2":2
							,:"")
			Set:(""=pAckControlId)&&(""'=tElem) pAckControlId=tSeg.GetValueAt(tElem), tCtlIdElem=tElem, tCIDSeg=tSegName

			Set tElem=$Case(tSegName
							,"TA1":$$$TA1InterchangeAcknowledgmentCod
							,"AK5":$$$AK5TransactionSetAcknowledgment
							,"AK9":$$$AK9FunctionalGroupAcknowledgeCo
							,:"")
			If ""'=tElem {
				Set pAckCode=tSeg.GetValueAt(tElem), pAckCodeU=$ZCVT(pAckCode,"U")  Set:""=pAckCode pAckCode="_"
				Set pSource=pReplyDoc.Name_":"_tSegName_":"_i_":"_tElem_":"_tCIDSeg_":"_tCtlIdElem
			}
		} Else {
			Set tChild=$$$NULLOREF For { Set tChild=pReplyDoc.NextChild(tChild,tRef)  Quit:tChild=$$$NULLOREF
				Do ..getReplyAckCode(tChild,.pAckCode,.pAckCodeU,.pAckControlId,.pSource)
				Quit:pAckCode'="~NoACK"
			}
		}
		Do pReplyDoc.commitSegmentByIndex(i)
		Quit:pAckCode'="~NoACK" ; stop at the first code we get
	}
}

/// Override this method to modify or delete or log the reply (ACK) message document object
Method OnReplyDocument(ByRef pReplyDocument As EnsLib.EDI.X12.Document, pRequest As EnsLib.EDI.X12.Document)
{
	Quit
}

/// Return the segment terminator string that the Parser will use.
Method GetSegmentTerminator() As %String
{
	Quit $C(13) ; $C(##class(EnsLib.EDI.X12.Document).%GetParameter("SegTerminatorAscii"))
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
