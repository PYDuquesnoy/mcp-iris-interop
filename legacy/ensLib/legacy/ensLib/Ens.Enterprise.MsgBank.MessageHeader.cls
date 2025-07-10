/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occSAX

/// Subclass of Ens.MessageHeader that lives only on the Message Bank Server, incorporating the original header from the client plus a record of the client node it came from
Class Ens.Enterprise.MsgBank.MessageHeader Extends (%Persistent, Ens.MessageHeaderBase, %XML.Adaptor, %Library.IndexBuilder) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter INDEXBUILDERFILTER = "NodeIdTime,NodeId,NTrg,NSrc";

Parameter XMLTYPE = "MsgBankHeader";

Parameter EXTENTSIZE = 20000000;

Property ID As %Integer(MINVAL = 1, XMLPROJECTION = "NONE");

Index ID On ID [ IdKey ];

Index Extent [ Extent, Type = bitmap ];

Index TimeCreated On TimeCreated;

Index Status On Status [ Type = bitmap ];

Index SourceConfigName On SourceConfigName [ Type = bitmap ];

Index TargetConfigName On TargetConfigName [ Type = bitmap ];

Index SessionId On SessionId;

/// This index is being used by Ens.Enterprise.Portal.MsgFilter.Assistant
Index MessageBodyClassName On MessageBodyClassName [ Type = bitmap ];

Index MessageBodyId On MessageBodyId;

Index TimeBanked On TimeBanked;

Property TimeBanked As Ens.DataType.UTC(XMLPROJECTION = "NONE") [ InitialExpression = {$ZDT($ZTS,3,,3)} ];

Property ClientBodyClassName As %String(MAXLEN = 128, XMLPROJECTION = "NONE");

Property ClientBodyId As %String(COLLATION = "EXACT", MAXLEN = "", XMLPROJECTION = "NONE");

/// Message Bank Client
Property NodeId As %Integer(MAXVAL = 999, MINVAL = 100, XMLPROJECTION = "NONE") [ Calculated, ReadOnly, SqlComputeCode = { Set {NodeId}=$E({ID},1,3) }, SqlComputed ];

Property ClientId As %Integer(MINVAL = 1, XMLPROJECTION = "NONE") [ Calculated, ReadOnly, SqlComputeCode = { Set {ClientId}=$E({ID},4,*) }, SqlComputed ];

Property ClientCorrespondingMessageId As %Integer(MINVAL = 1, XMLPROJECTION = "NONE") [ Calculated, ReadOnly, SqlComputeCode = { Set {ClientCorrespondingMessageId}=$E({CorrespondingMessageId},4,*) }, SqlComputed, Transient ];

Property ClientSessionId As %Integer(MINVAL = 1, XMLPROJECTION = "NONE") [ Calculated, ReadOnly, SqlComputeCode = { Set {ClientSessionId}=$E({SessionId},4,*) }, SqlComputed, Transient ];

Index NodeClientId On (NodeId, ClientId);

Index NodeIdTime On (NodeId, TimeCreated);

/// This index is being used by Ens.Enterprise.Portal.MsgFilter.Assistant
Index NodeId On NodeId [ Type = bitmap ];

/// This index is being used by Ens.Enterprise.Portal.MsgFilter.Assistant
Index NTrg On (NodeId, TargetConfigName) [ Type = bitmap ];

/// This index is being used by Ens.Enterprise.Portal.MsgFilter.Assistant
Index NSrc On (NodeId, SourceConfigName) [ Type = bitmap ];

/// Used to find DISTINCT NodeId for the SourceConfigName during query pre-processing.
Index SrcN On (SourceConfigName, NodeId) [ Type = bitmap ];

/// Used to find DISTINCT NodeId for the TargetConfigName during query pre-processing.
Index TrgN On (TargetConfigName, NodeId) [ Type = bitmap ];

/// Used in SearchTable queries.
/// A tuple of these three columns uniquely identifies a message body.
Index MessageBodyNode On (MessageBodyId, MessageBodyClassName, NodeId);

/// Used in multi-node searching.
/// This index is being used by Ens.Enterprise.Portal.MsgFilter.Assistant
Index NodeSourceTime On (NodeId, SourceConfigName, TimeCreated);

/// Used in multi-node searching.
/// This index is being used by Ens.Enterprise.Portal.MsgFilter.Assistant
Index NodeTargetTime On (NodeId, TargetConfigName, TimeCreated);

Method NodeIdGet() As %Integer [ CodeMode = expression ]
{
$E(..%Id(),1,3)
}

Method ClientIdGet() As %Integer [ CodeMode = expression ]
{
$E(..%Id(),4,*)
}

Method ClientCorrespondingMessageIdGet() As %Integer [ CodeMode = expression ]
{
$E(..CorrespondingMessageId,4,*)
}

Method ClientSessionIdGet() As %Integer [ CodeMode = expression ]
{
$E(..SessionId,4,*)
}

/// Called from Client Node's Resend SOAP Service (%CSP.Monitor.Server) only
ClassMethod ClientResend(pBankHeaderId As %Integer, pOriginalHeader As %Stream.Object, Output pNewHeaderId As %String, pNewTarget As %String, pNewBody As %Stream.Object, pNewSource As %String, pHeadOfQueue As %Boolean, pBodyUseOriginalNode As %String) As %Status [ Internal ]
{
	Set pNewHeaderId="", tFound=0, tNewHdr=$$$NULLOREF
	If '##class(Ens.Director).IsProductionRunning() Quit $$$ERROR($$$EnsErrProductionNotRunning)

	Set tReader=##class(%XML.Reader).%New()
	Set tSC=tReader.OpenStream(pOriginalHeader)
	If $$$ISOK(tSC) {
		Do tReader.Correlate("MsgBankHeader","Ens.MessageHeader")
		Set tFound = tReader.Next(.tNewHdr,.tSC)
	}
	If 'tFound||'$IsObject(tNewHdr)||$$$ISERR(tSC) Do pOriginalHeader.Rewind() Quit $$$ERROR($$$EnsErrNoObjFromStream,"MsgBankHeader","Ens.MessageHeader"_$S($$$ISERR(tSC):" ="_$$$StatusDisplayString(tSC),1:""),pOriginalHeader.Read(1000))

	Set tNewHdr.TimeCreated = $$$timeUTC
	Set tBodyClass=tNewHdr.MessageBodyClassName

	If tNewHdr.Type = $$$eMessageTypeRequest {
		Set tNewHdr.CorrespondingMessageId = ""
		Set:""'=pNewTarget tNewHdr.TargetConfigName=pNewTarget
		Set tNewHdr.TargetQueueName=$G($$$ConfigQueueName($G($$$DispatchNameToConfigName(tNewHdr.TargetConfigName),0)))
		Quit:""=tNewHdr.TargetQueueName $$$ERROR($$$EnsErrGeneral,"Target config item '"_tNewHdr.TargetConfigName_"' is not running")
		Set tNewHdr.TargetBusinessType=$$$ConfigBusinessType(tNewHdr.TargetConfigName)
	} Else {
		Quit:""'=pNewTarget $$$ERROR($$$EnsErrGeneral,"Can not send response messages to new target")
		Quit:'##class(Ens.Queue).Exists(tNewHdr.TargetQueueName) $$$ERROR($$$EnsErrGeneral,"Target reply queue '"_tNewHdr.TargetQueueName_"' no longer exists")
	}
	If ""'=pNewSource {
		Quit:""'=tNewHdr.ReturnQueueName $$$ERROR($$$EnsErrGeneral,"Cannot override source for synchronous request message "_pBankHeaderId)
		Set tNewHdr.SourceConfigName = pNewSource
		Set tNewHdr.SourceBusinessType = $$$ConfigBusinessType(pNewSource)
		Set:""=tNewHdr.SourceBusinessType tNewHdr.SourceBusinessType=$$$eHostTypeService
		Set tNewHdr.BusinessProcessId = ""
	}
	Set:""=tNewHdr.SessionId tNewHdr.SessionId=tNewHdr.MessageId()
	
	Set tUseOriginalBody=("+"=$E(pBodyUseOriginalNode))
	If tUseOriginalBody {
		Set $E(pBodyUseOriginalNode)=""
		If (pBodyUseOriginalNode="") || (pBodyUseOriginalNode'=$G(^Ens.MsgBank("NodeId"))) {
			$$$LOGWARNING("Not using original message body object because original client Node "_pBodyUseOriginalNode_" does not match current Node "_$G(^Ens.MsgBank("NodeId"))_"; using streamed body instead")
			Set tUseOriginalBody=0
		} Else {
			Set tOriginalBodyExists = 1
			Try {
				If (""'=tNewHdr.MessageBodyClassName && '$classmethod(tNewHdr.MessageBodyClassName,"%ExistsId",tNewHdr.MessageBodyId)) {
					Set tOriginalBodyExists = 0
				}
			}
			Catch {	Set tOriginalBodyExists = 0 }
			If 'tOriginalBodyExists {
				$$$LOGWARNING("Unable to use original message body object "_tNewHdr.MessageBodyClassName_":"_tNewHdr.MessageBodyId_" because it longer exists; using streamed body instead")
				Set tUseOriginalBody = 0
			}
		}
	}
	If 'tUseOriginalBody {
		If $IsObject(pNewBody) {
			Set tWork=pNewBody.Read(200)  Do pNewBody.Rewind()
			Set tWork=$P($P(tWork,"<",2),">")
			Set tBodyType=$P($P(tWork,"/")," ")
			Set tHeadAttrs=$E(tWork,$L(tBodyType)+1,*)
		} Else { Set tBodyType="NULL", tWork="" }
		
		Set tEmptyStream=$Case(tBodyType,"NULL":1,"NoExport":1,"Empty":1,"Serial":1,"String":1,:0)
		If tEmptyStream {
			If ""'=tWork {
				Quit $$$ERROR($$$EnsErrGeneral,"For message type "_tNewHdr.MessageBodyClassName_" with supposedly empty body object, found stream content: '"_pNewBody.Read(1000)_"'")
			}
			If ""'=tNewHdr.MessageBodyClassName&&(""'=tNewHdr.MessageBodyId)&&("Serial"'=tBodyType) {
				Quit $$$ERROR($$$EnsErrGeneral,"Unable to reconstruct message body of class "_tNewHdr.MessageBodyClassName_" from stream: "_pNewBody.Read(1000))
			}
			#; Else no need to instantiate - the header has it all
		} Else {
			Set tStuff=pNewBody.Read($L(tWork)+$L("<><![CDATA[")) ; skip into CData
			If "><![CDATA[" '= $E(tStuff,*-$L("><![CDATA[")+1,*) {
				 Quit $$$ERROR($$$EnsErrGeneral,"Can't resend - body CData not found in header "_tStuff)
			}
			If tBodyType = "XML" {
				Set tStream=##class(%Stream.GlobalCharacter).%New()
			} Else {
				Set tStream=##class(%GlobalBinaryStream).%New()
			}
			Set tSC=##class(Ens.Enterprise.MsgBank.TCPService).copyPart(tStream,pNewBody,pNewBody.Size-$L(tWork_"<><![CDATA[]]></>.."_tBodyType))  Quit:$$$ISERR(tSC) tSC
			
			Set tStuff=pNewBody.Read(200) ; skip end CData
			#; if missing trailing whitespace, it means we read too few into the stream
			Do:$Case($E(tStuff,*),  $C(0):0," ":0,$C(9):0,$C(13):0,$C(10):0,:1) tStream.Write($E(tStuff,2))
			Do:$Case($E(tStuff,*-1),$C(0):0," ":0,$C(9):0,$C(13):0,$C(10):0,:1) tStream.Write($E(tStuff,1))
			While $Case($E(tStuff,*),$C(0):1," ":1,$C(9):1,$C(13):1,$C(10):1,:0) { Set tStuff=$E(tStuff,1,*-1) }
			If "]]></"_tBodyType_">" '= tStuff {
				 Quit $$$ERROR($$$EnsErrGeneral,"Can't resend - body CData close not found in header tail '"_tStuff_"'")
			}
			If tBodyType="VDoc" {
				Set tBody=$classmethod(tBodyClass,"ImportFromLibraryStream",tStream,.tSC)  Quit:$$$ISERR(tSC) tSC
				Set tBody.DocType=$P(tWork,"'",2)
			} ElseIf tBodyType="CData" {
				Set tType=$P(tWork,"'",2)
				If "C"=$E(tType,2) { Set tTemp=tStream, tStream=##class(%GlobalCharacterStream).%New()  Do tStream.CopyFrom(tTemp) }
				Set tBody=##class(Ens.StreamContainer).%New(tStream)
				#;tWork is "<CData Type='"_tBody.Type_"' Size='"_tBody.Stream.Size_"' Filename='"_$ZCVT(tBody.Stream.OriginalFilename,"O","XML")_"'><![CDATA["
				Try {Set tBody.OriginalFilename=$ZCVT($P(tWork,"'",6),"I","XML")} Catch {}
			} ElseIf tBodyType="SData" {
				Set tBody=tStream
			} ElseIf tBodyType="XML" {
				Set tFound=0, tSC=tReader.OpenStream(tStream)
				If $$$ISOK(tSC) {
					Set tHeadTag=$$$GetClassParameter(tBodyClass,"XMLNAME")
					Set:""=tHeadTag tHeadTag=$P(tBodyClass,".",$L(tBodyClass,"."))
					Do tReader.Correlate(tHeadTag,tBodyClass)
					Set tFound = tReader.Next(.tBody,.tSC)
				}
				If 'tFound||'$IsObject(tBody)||$$$ISERR(tSC) Do tStream.Rewind()  Set tSC1=$$$ERROR($$$EnsErrNoObjFromStream,$$$GetClassParameter(tBodyClass,"XMLNAME"),tBodyClass,tStream.Read(1000))  Quit $$$ADDSC(tSC1,tSC)
			} Else {
				Quit $$$ERROR($$$EnsErrGeneral,"Unexpected body type '"_tBodyType_"' encountered in Resend")
			}
			If $IsObject(tBody) {
				Set tSC=tBody.%Save()
				If $$$ISERR(tSC) Quit $$$ERROR($$$EnsErrGeneral,"Failed to save Bank Resend message body of type "_tBodyType_" / "_tNewHdr.MessageBodyClassName_" for header "_pBankHeaderId_":"_$$$StatusDisplayString(tSC))
				Set tNewHdr.MessageBodyId=tBody.%Id()
			}
		}
	}
	Set tNewHdr.Description="BankResent "_pBankHeaderId_$S(""=tNewHdr.Description:"", "BankResent "=$E(tNewHdr.Description,1,$L("BankResent ")):","_$E(tNewHdr.Description,$L("BankResent ")+1,*), 1:": "_tNewHdr.Description)
	Set pNewHeader=tNewHdr

	Set tSC = ##class(Ens.Queue).EnQueue(tNewHdr,.pHeadOfQueue)  Quit:$$$ISERR(tSC) $$$EnsError($$$EnsErrGeneral,"Error from EnQueue(); not resending MsgBank message '"_pBankHeaderId_"' : "_$$$StatusDisplayString(tSC))
	Set pNewHeaderId=$G(^Ens.MsgBank("NodeId"))_","_tNewHdr.%Id()
	$$$sysTRACE("Message Bank resent a copy of header "_pBankHeaderId_" with message body of type "_tBodyType_" / "_tNewHdr.MessageBodyClassName)
	$$$SyncCommitNow
	Quit $$$OK
}

/// Called from MsgBank server side only. Invoke a SOAP call to resend a message on the chosen MsgBank client node / SOAP Resend service provider.
/// There must exist a MonitorClient configured that matches the WebAddress of the chosen NodeId
ClassMethod ResendDuplicatedMessage(ByRef pWSClientObjs, pBankHeaderId As %String, Output pNewHeaderId As %String, pNewTarget As %String = "", pNewBody As %RegisteredObject = {$$$NULLOREF}, pNewSource As %String = "", pHeadOfQueue As %Boolean = 0, pUseOriginalClientBody As %Boolean = 0) As %Status
{
	Set tSC=$$$OK, pNewHeaderId=""
	Set tHeader=..%OpenId(pBankHeaderId,,.tSC)
	If '$IsObject(tHeader) Quit $$$ERROR($$$EnsErrGeneral,"Can not open banked message header "_pBankHeaderId_"; status "_$$$StatusDisplayString(tSC))

	Set tCli=$P(pNewTarget,"|",1,$L(pNewTarget,"|")-1)
	Set tTarg=$P(pNewTarget,"|",$L(pNewTarget,"|"))

	If tHeader.Type = $$$eMessageTypeRequest {
		Set tHeader.CorrespondingMessageId = ""
	} Else {
		Quit:""'=tTarg $$$ERROR($$$EnsErrGeneral,"Cannot send response messages to new target")
	}
	Quit:""'=pNewSource&&(""'=tHeader.ReturnQueueName) $$$ERROR($$$EnsErrGeneral,"Cannot override source for synchronous request message "_pBankHeaderId)

	If ""'=tCli {
		Set tSameNode=(tCli=$G(^Ens.MsgBankSvr("nodemap",tHeader.NodeId)))
	} Else { 
		Set tCli=$G(^Ens.MsgBankSvr("nodemap",tHeader.NodeId)), tSameNode=1
		Quit:""=tCli $$$ERROR($$$EnsErrGeneral,"No configured client found for node "_tHeader.NodeId_" in attempt to resend MsgBank message "_pBankHeaderId)
	}
	Set tOldSessionId = tHeader.SessionId
	#; Resent messages from Message Bank start a fresh session regardless whether resending from the same node they originated on
	Set tHeader.SessionId = ""
	Set tHeader.CorrespondingMessageId = ""

	#; Get cached WebService client object or construct a new one
	Set tWSClient=$G(pWSClientObjs(tCli))  If '$IsObject(tWSClient) {
		Set tClient=##class(Ens.Enterprise.MonitorClient).%OpenId(tCli)
		Set tWSClient=##class(%CSP.Monitor.Client).%New()
		Set tWSClient.Location=tClient.GetURLPath(1)_"_CSP.Monitor.Server.cls"
		Set tSC=##Class(Ens.Config.Credentials).GetCredentialsObj(.tCredObj,$$$CurrentClass,"Ens.Config.Credentials",tClient.SOAPCredentials)  Quit:$$$ISERR(tSC) tSC
		#;Set:$IsObject(tCredObj) pWSClient.HttpUsername=tCredObj.Username, pWSClient.HttpPassword=tCredObj.Password
		Do:$IsObject(tCredObj)&&(""'=tCredObj.Username) tWSClient.WSSecurityLogin(tCredObj.Username,tCredObj.Password)
		Set tWSClient.SSLConfiguration=tClient.SSLConfig
		Set tWSClient.SSLCheckServerIdentity=tClient.SSLCheckServerIdentity
		Set pWSClientObjs(tCli)=tWSClient, pWSClientObjs(tCli,"creds")=tClient.SOAPCredentials, pWSClientObjs(tCli,"webip")=tClient.WebIPAddress
	} Else {
		Set tSC=##Class(Ens.Config.Credentials).GetCredentialsObj(.tCredObj,$$$CurrentClass,"Ens.Config.Credentials",$G(pWSClientObjs(tCli,"creds")))  Quit:$$$ISERR(tSC) tSC
		#;Set:$IsObject(tCredObj) pWSClient.HttpUsername=tCredObj.Username, pWSClient.HttpPassword=tCredObj.Password
		Do:$IsObject(tCredObj)&&(""'=tCredObj.Username) tWSClient.WSSecurityLogin(tCredObj.Username,tCredObj.Password)
	}
	#; If we are asking the MsgBank client's web service to use the original body object, we provide the original node name as a safety check
	Set tNodeName=##class(Ens.Enterprise.MsgBank.Node).GetNodeName(tHeader.NodeId)
	Set tNodeClientId=tHeader.ClientId
	Set tUseOriginalNodeRef = tHeader.NodeId
	If tSameNode {
		If pUseOriginalClientBody {
			#; Prefix node ID with "+" so client system can check whether the node IDs match for resend
			Set tUseOriginalNodeRef = "+"_tHeader.NodeId
		}
	} Else {
		Set tNodeClientId=tNodeName_":"_tNodeClientId
	}
	#; Use new body if provided
	If ""'=pNewBody {
		If '$IsObject(pNewBody) {
			Set tHeader.MessageBodyClassName=""
			Set tHeader.MessageBodyId=pNewBody
		} Else {
			Set tHeader.MessageBodyClassName=$classname(pNewBody)
			If pNewBody.%IsA("%Library.Persistent")||pNewBody.%IsA("%Stream.Object") Set tSC=pNewBody.%Save()
			If $$$ISOK(tSC) Set tSC=pNewBody.%GetSwizzleObject(0,.tOID)
			Quit:$$$ISERR(tSC) tSC
			Set tHeader.MessageBodyId=$$$oidPrimary(tOID)
		}
	}
	Set tBodyClass=tHeader.MessageBodyClassName, tBodyId=tHeader.MessageBodyId
	If tHeader.MessageBodyClassName="" {
		If ""=tHeader.MessageBodyId {
			Set tBodyType="Empty"
		} Else {
			Set tBodyType="String"
		}
	} ElseIf $classmethod(tBodyClass,"%Extends","%SerialObject") {
		Set tBodyType="Serial"
	} Else {
		Set tBody = $classmethod(tBodyClass,"%OpenId",tBodyId)
		Quit:'$IsObject(tBody) $$$ERROR($$$EnsErrGeneral,"Unable to instantiate banked MessageBody for banked Header #"_pBankHeaderId_" with body class "_tBodyClass_" and body Id "_tBodyId)
		Set tBodyType=$S(
			tBody.%Extends("EnsLib.EDI.Document"):"VDoc"
			,tBody.%Extends("Ens.StreamContainer"):"CData"
			,tBody.%Extends("%Stream.Object"):
				$S(tHeader.ClientBodyClassName=tBodyClass:"SData",1:"XMLStream")
			,tBody.%Extends("%XML.Adaptor"):"XML"
			,1:"Other")
	}
	$$$sysTRACE("Resending banked message "_pBankHeaderId_" with body "_tBodyId_" of type "_tBodyType_"/"_tBodyClass_$S(tHeader.ClientBodyClassName=tBodyClass:"",1:"/"_tHeader.ClientBodyClassName)_" from client system '"_tCli_"' at address "_$G(pWSClientObjs(tCli,"webip"))_" with credentials '"_$G(pWSClientObjs(tCli,"creds"))_"'")
	
	#; Fix up the banked header's properties and XMLExport it (we won't save the changes we make to it)
	Set tHeader.MessageBodyClassName=tHeader.ClientBodyClassName
	Set tHeader.MessageBodyId=tHeader.ClientBodyId
	Set tSC=tHeader.XMLExportToStream(.xmlHeader)  Quit:""=tSC tSC	

	Set tStream=##class(%GlobalBinaryStream).%New()
	If tBodyType="VDoc" {
		Do tStream.Write("<VDoc DocType='"_tBody.DocType_"'><![CDATA[")
		Set tSC=tBody.OutputToLibraryStream(tStream)  Quit:$$$ISERR(tSC) tSC
		Do tStream.WriteLine("]]></VDoc>")
	} ElseIf tBodyType="CData" {
		Do tStream.Write("<CData Type='"_tBody.Type_"' Size='"_tBody.Stream.Size_"' Filename='"_$ZCVT(tBody.OriginalFilename,"O","XML")_"'><![CDATA[")
		Set tSC=tStream.CopyFrom(tBody.Stream)  Quit:$$$ISERR(tSC) tSC
		Do tStream.WriteLine("]]></CData>")
	} ElseIf tBodyType="SData" {
		Do tStream.Write("<SData Size='"_tBody.Size_"'><![CDATA[")
		Set tSC=tStream.CopyFrom(tBody)  Quit:$$$ISERR(tSC) tSC
		Do tStream.WriteLine("]]></SData>")
	} ElseIf tBodyType="XMLStream" {
		Do tStream.Write("<XML Size='"_tBody.Size_"'><![CDATA[")

		/*	Check to see if has XML declaration. If so leave. If not add and convert to UTF-8
			Check code based on %XML.SAX.StreamAdapter
		*/
		Do tBody.Rewind()
	 	#dim tXMLDeclaration = tBody.Read(100)
	 	Do tBody.Rewind()		
		#; If has BOM or begins <?xml leave as is
		If ($Ascii(tXMLDeclaration)=$$$UNIVAL) ||
			($Extract(tXMLDeclaration,1,3)=$$$UTF8BOM) ||
			($Extract(tXMLDeclaration,1,5)="<?xml" ) {
				Set tSC=tStream.CopyFrom(tBody)  Quit:$$$ISERR(tSC) tSC
		} Else {
			Do tStream.Write("<?xml version='1.0' encoding='UTF-8'?>")
			While 'tBody.AtEnd {
    			Do tStream.Write($ZCVT(tBody.Read(10000),"O","UTF8"))
  			}
  			Do tBody.Rewind()
		}
		
		Do tStream.WriteLine("]]></XML>")
	} ElseIf tBodyType="XML" {
		Do tStream.Write("<XML><![CDATA[")
		Set tSC=tBody.XMLExportToStream(tStream)  Quit:$$$ISERR(tSC) tSC
		Do tStream.WriteLine("]]></XML>")
	} ElseIf tBodyType="Serial" {
		Do tStream.Write("<Serial Size='"_$L(tBodyId)_"'/>")
	} ElseIf tBodyType="String" {
		Do tStream.Write("<String/>")
	} ElseIf tBodyType="Empty" {
		Do tStream.Write("<Empty/>")
	} Else {
		$$$LOGWARNING("Unsupported message type "_tBodyType_" - not resending "_tHeader.MessageBodyClassName_" "_tBodyId)
		Do tStream.WriteLine("<NoExport/>")
	}
	#; Call the Resend WebService
	Try {
		Set tNewHeaderId=tWSClient.ResendDuplicatedMessage(tNodeClientId, xmlHeader, tTarg, tStream, pNewSource, pHeadOfQueue, tUseOriginalNodeRef)
		Set tNode=$P(tNewHeaderId,","), tNewHeaderId=$P(tNewHeaderId,",",2,99)
		&sql(Select ID Into :tNodeId From Ens_Enterprise_MsgBank.Node Where Name=:tNode)
		If SQLCODE'=0 { ; Handle case where nothing found
			;Set:SQLCODE tNodeId=tHeader.NodeId
			Set tNodeId=-99
		}
		Set pNewHeaderId=tNodeId_tNewHeaderId
		// Interlink child and parent sessions; note client ID for children
		Set ^Ens.MsgBank.Sessions("child",tOldSessionId,pNewHeaderId)=tCli
		Set ^Ens.MsgBank.Sessions("parent",pNewHeaderId,tOldSessionId)=""		
	} Catch errobj {
		Set errText=$S("<ZSOAP>"=errobj.Name:$$$StatusDisplayString(%objlasterror), 1:errobj.AsSystemError())
		Set tSC=$$$ERROR($$$EnsErrGeneral,errText)
 	}
	Quit tSC
}

ClassMethod Purge(Output pDeletedCount As %Integer, pDaysToKeep As %Integer = 7, pKeepIntegrity As %Boolean = 1, pBodiesToo As %Boolean = 1, pBitmapPurgeRunLimit As %Integer = 600) As %Status
{
	New %tDoNotDeleteDate,%tID,%tBodyId,%tBodyClassname Set %tID="", %tDoNotDeleteDate = ##class(Ens.Purge).GetDoNotDeleteDate(pDaysToKeep)
	If '$data($$$EnsJobLocal) New $$$EnsJobLocal Set $$$EnsJobLocal = ""
	If $G(^Ens.Config("Enterprise","Purge","StreamSearchTable")) {
		#; Initialise the cache -- all stream classes use %Stream.Object as the "extent"
		Do ##class(Ens.DocClassMap).UpdateCache("%Stream.Object")
	}
	Set tSC=$$$OK, SQLCODE=0, pDeletedCount=0, pDeletedCount("bodies")=0
	#; Log purging errors in Event log but no more than $$$ensPurgeMaxWarn per type (body, search table & header)
	#dim tPurgeErrorWarningsArray = $$$ensPurgeMaxWarn
	If pBodiesToo {
		If pKeepIntegrity {
			&sql(DECLARE C1 CURSOR FOR
				Select TOP 100000000 ID,MessageBodyId,MessageBodyClassName Into :%tID,:%tBodyId,:%tBodyClassname From Ens_Enterprise_MsgBank.MessageHeader h
					Where (TimeCreated < :%tDoNotDeleteDate)
						And 0 = ( Select Count(*) From Ens_Enterprise_MsgBank.MessageHeader
									Where (SessionId = h.SessionId)
										And (Status<>$$$eMessageStatusCompleted)
										And (Status<>$$$eMessageStatusAborted)
										And (Status<>$$$eMessageStatusError)
										And (Status<>$$$eMessageStatusDiscarded) )
					Order By TimeCreated
				)
			&sql(OPEN C1)
		 	For { &sql(FETCH C1)  Quit:SQLCODE
				If %tBodyId'="" {
					#; Delete body if body class exists and is persistent
					Set:""=%tBodyClassname&&(%tBodyId=+%tBodyId) %tBodyClassname="Ens.MessageBody"
					If ""'=%tBodyClassname {
						Set tExists=$G(aClass(%tBodyClassname))
						If 0'=tExists {
							If ""=tExists&&'($$$comClassDefined(%tBodyClassname)&&($classmethod(%tBodyClassname,"%IsA","%Persistent")||$classmethod(%tBodyClassname,"%IsA","%Stream.Object"))) {
								Set aClass(%tBodyClassname)=0
							} Else {
								try {
									Set tSC1=$classmethod(%tBodyClassname,"%DeleteId",%tBodyId)
									Set:""=tExists aClass(%tBodyClassname)=1, tExists=1 ; , aClass(%tBodyClassname,"extent")=##class(Ens.VDoc.SearchTableGenerator).GetExtentSuperclass(%tBodyClassname)
								} catch {
									Set tSC1 = $$$SystemError
								}
								If $$$ISOK(tSC1) || $$$StatusEquals(tSC1,$$$DeleteObjectNotFound,$$$FileCanNotDelete,$$$NotAnInstanceError) {
									Set tSC2 = ##class(Ens.SearchTableBase).RemoveSearchTableEntries(%tBodyClassname,%tBodyId,1)
									If $$$ISERR(tSC2)&&'$G(aClass(%tBodyClassname,"doneErrST")) && '$$$StatusEquals(tSC2,$$$DeleteObjectNotFound,$$$FileCanNotDelete,$$$NotAnInstanceError) { ; || ($$$StatusEquals(tSC2,$$$NotAnInstanceError) && '$classmethod(aClass(%tBodyClassname,"extent"),"%ExistsId",%tBodyId))
										Set tMsg = "Failed to purge SearchTable entries for deleted body with BodyClassname='"_%tBodyClassname_"', BodyId='"_%tBodyId_"' from header "_%tID_" :"_$$$StatusDisplayString(tSC2)
										Set tSC = ##class(Ens.MessageHeader).ReportPurgeError($$$ensPurgeST,tMsg,tSC,tSC2,.tPurgeErrorWarningsArray)
										#; If error purging search table but body purged/already deleted then carry on
									}
								} Else {
									Set tMsg = "Failed to purge body for header "_%tID_", BodyClassname='"_%tBodyClassname_"':"_$$$StatusDisplayString(tSC1)
									Set tSC = ##class(Ens.MessageHeader).ReportPurgeError($$$ensPurgeBody,tMsg,tSC,tSC1,.tPurgeErrorWarningsArray)
									#; If protect error purging body continue to next message and do not try to delete message header
									If (tMsg["<PROTECT>") Continue
								}
								Set pDeletedCount("bodies")=pDeletedCount("bodies")+$$$ISOK(tSC1)
							}
						}
					}
		 		}
				&sql(DELETE From Ens_Enterprise_MsgBank.MessageHeader Where ID = :%tID)
				Set pDeletedCount=pDeletedCount+%ROWCOUNT
				If SQLCODE {
					Set tMsg = "Failed to purge message header "_%tID_": SQLCODE="_SQLCODE Set:$G(%msg)'="" tMsg = tMsg_", %msg="_%msg
					Set tSC = ##class(Ens.MessageHeader).ReportPurgeError($$$ensPurgeHdr,tMsg,tSC,$$$ERROR($$$EnsErrGeneral,tMsg),.tPurgeErrorWarningsArray)
					/*	If protect error when trying to delete message header quit purge completely
						as all message header purges will encounter protect
					*/
					If (tMsg["<PROTECT>") Quit
				}
			} Set tCode=SQLCODE &sql(CLOSE C1) Set:'SQLCODE SQLCODE=tCode
		} Else {
			&sql(DECLARE C2 CURSOR FOR
				Select ID,MessageBodyId,MessageBodyClassName Into :%tID,:%tBodyId,:%tBodyClassname From Ens_Enterprise_MsgBank.MessageHeader
					Where (TimeCreated < :%tDoNotDeleteDate))
			&sql(OPEN C2)
		 	For { &sql(FETCH C2)  Quit:SQLCODE
		 		If %tBodyId'="" {
					#; Delete body if body class exists and is persistent
					Set:""=%tBodyClassname&&(%tBodyId=+%tBodyId) %tBodyClassname="Ens.MessageBody"
					If ""'=%tBodyClassname {
						Set tExists=$G(aClass(%tBodyClassname))
						If 0'=tExists {
							If ""=tExists&&'($$$comClassDefined(%tBodyClassname)&&($classmethod(%tBodyClassname,"%IsA","%Persistent")||$classmethod(%tBodyClassname,"%IsA","%Stream.Object"))) {
								Set aClass(%tBodyClassname)=0
							} Else {
								try {
									Set tSC1=$classmethod(%tBodyClassname,"%DeleteId",%tBodyId)
									Set:""=tExists aClass(%tBodyClassname)=1, tExists=1 ;, aClass(%tBodyClassname,"extent")=##class(Ens.VDoc.SearchTableGenerator).GetExtentSuperclass(%tBodyClassname)
								} catch {
									Set tSC1 = $$$SystemError
								}
								If $$$ISOK(tSC1) || $$$StatusEquals(tSC1,$$$DeleteObjectNotFound,$$$FileCanNotDelete,$$$NotAnInstanceError) {
									Set tSC2 = ##class(Ens.SearchTableBase).RemoveSearchTableEntries(%tBodyClassname,%tBodyId,1)
									If $$$ISERR(tSC2)&&'$G(aClass(%tBodyClassname,"doneErrST")) && '$$$StatusEquals(tSC2,$$$DeleteObjectNotFound,$$$FileCanNotDelete,$$$NotAnInstanceError) { ; || ($$$StatusEquals(tSC2,$$$NotAnInstanceError) && '$classmethod(aClass(%tBodyClassname,"extent"),"%ExistsId",%tBodyId))
										Set tMsg = "Failed to purge SearchTable entries for deleted body with BodyClassname='"_%tBodyClassname_"', BodyId='"_%tBodyId_"' from header "_%tID_" :"_$$$StatusDisplayString(tSC2)
										Set tSC = ##class(Ens.MessageHeader).ReportPurgeError($$$ensPurgeST,tMsg,tSC,tSC2,.tPurgeErrorWarningsArray)
										#; If error purging search table but body purged/already deleted then carry on
									}
								} Else {
									Set tMsg = "Failed to purge body for header "_%tID_", BodyClassname='"_%tBodyClassname_"':"_$$$StatusDisplayString(tSC1)
									Set tSC = ##class(Ens.MessageHeader).ReportPurgeError($$$ensPurgeBody,tMsg,tSC,tSC1,.tPurgeErrorWarningsArray)
									#; If protect error purging body continue to next message and do not try to delete message header
									If (tMsg["<PROTECT>") Continue
								}
								Set pDeletedCount("bodies")=pDeletedCount("bodies")+$$$ISOK(tSC1)
							}
						}
					}
		 		}
				&sql(DELETE From Ens_Enterprise_MsgBank.MessageHeader Where ID = :%tID)
				Set pDeletedCount=pDeletedCount+%ROWCOUNT
				If SQLCODE {
					Set tMsg = "Failed to purge message header "_%tID_": SQLCODE="_SQLCODE Set:$G(%msg)'="" tMsg = tMsg_", %msg="_%msg
					Set tSC = ##class(Ens.MessageHeader).ReportPurgeError($$$ensPurgeHdr,tMsg,tSC,$$$ERROR($$$EnsErrGeneral,tMsg),.tPurgeErrorWarningsArray)
					/*	If protect error when trying to delete message header quit purge completely
						as all message header purges will encounter protect
					*/
					If (tMsg["<PROTECT>") Quit
				}
			} Set tCode=SQLCODE &sql(CLOSE C2) Set:'SQLCODE SQLCODE=tCode
		}
	} Else {
		If pKeepIntegrity {
			&sql(DECLARE C3 CURSOR FOR
				Select TOP 100000000 ID Into :%tID From Ens_Enterprise_MsgBank.MessageHeader h
					Where TimeCreated < :%tDoNotDeleteDate
				        And 0 = ( Select Count(*) From Ens_Enterprise_MsgBank.MessageHeader
								Where (SessionId = h.SessionId)
									And (Status<>$$$eMessageStatusCompleted)
									And (Status<>$$$eMessageStatusAborted)
									And (Status<>$$$eMessageStatusError)
									And (Status<>$$$eMessageStatusDiscarded) )
					Order By TimeCreated
				)
			&sql(OPEN C3) For { &sql(FETCH C3)  Quit:SQLCODE
				&sql(Delete From Ens_Enterprise_MsgBank.MessageHeader Where ID=:%tID)
				Set pDeletedCount=pDeletedCount+%ROWCOUNT
				If SQLCODE {
					Set tMsg = "Failed to purge message header "_%tID_": SQLCODE="_SQLCODE Set:$G(%msg)'="" tMsg = tMsg_", %msg="_%msg
					Set tSC = ##class(Ens.MessageHeader).ReportPurgeError($$$ensPurgeHdr,tMsg,tSC,$$$ERROR($$$EnsErrGeneral,tMsg),.tPurgeErrorWarningsArray)
					/*	If protect error when trying to delete message header quit purge completely
						as all message header purges will encounter protect
					*/
					If (tMsg["<PROTECT>") Quit
				}
			} Set tCode=SQLCODE &sql(CLOSE C3) Set:'SQLCODE SQLCODE=tCode
		} Else {
			&sql(DECLARE C4 CURSOR FOR
				Select ID Into :%tID From Ens_Enterprise_MsgBank.MessageHeader Where TimeCreated < :%tDoNotDeleteDate)
			&sql(OPEN C4) For { &sql(FETCH C4)  Quit:SQLCODE
				Set %ROWCOUNT=0
				&sql(Delete From Ens_Enterprise_MsgBank.MessageHeader Where ID=:%tID)
				Set pDeletedCount=pDeletedCount+%ROWCOUNT
				If SQLCODE {
					Set tMsg = "Failed to purge message header "_%tID_": SQLCODE="_SQLCODE Set:$G(%msg)'="" tMsg = tMsg_", %msg="_%msg
					Set tSC = ##class(Ens.MessageHeader).ReportPurgeError($$$ensPurgeHdr,tMsg,tSC,$$$ERROR($$$EnsErrGeneral,tMsg),.tPurgeErrorWarningsArray)
					/*	If protect error when trying to delete message header quit purge completely
						as all message header purges will encounter protect
					*/
					If (tMsg["<PROTECT>") Quit
				}
			} Set tCode=SQLCODE &sql(CLOSE C4) Set:'SQLCODE SQLCODE=tCode
		}
	}
	Set:SQLCODE&&(SQLCODE'=100) tSC=$$$ADDSC(tSC,$$$ERROR($$$EnsErrGeneral,"Purge error at ID "_$G(%tID)_"; SQLCODE = "_SQLCODE))
	Kill %streamSrchTabClasses
	Quit tSC
}

/// Deprecated. No longer used by InterSystems Code.
/// Replaced by ReportPurgeError in Ens.MessageHeader
/// Log a warning in the Event Log; add to tSC status; set error/warning in a temp global as below: <br>
/// Total error count is in subscript 0. <br>
/// Errors while deleting message headers are in subscript 1. <br>
/// Errors while deleting message bodies are in subscript 2. <br>
/// Errors while deleting search table entries are in subscript 3.
ClassMethod PurgeSetTemp(pType As %Integer, pMsg As %String, pSC As %Status, pSC2 As %Status) As %Status
{
	$$$LOGWARNING(pMsg)
	Set tCount0 = $I(^IRIS.Temp.EnsPurgeMessage($Job,0))
	Set tCount = $I(^IRIS.Temp.EnsPurgeMessage($Job,pType))
	Set:$G(%tID)'="" ^IRIS.Temp.EnsPurgeMessage($Job,pType,%tID) = pMsg
	If tCount0<11 {
		Set pSC = $$$ADDSC(pSC,pSC2)
	}
	ElseIf tCount0=11 {
		Set pSC = $$$ADDSC(pSC,$$$ERROR($$$GeneralError,"There are more errors and/or warnings, see the Ensemble Event Log and ^IRIS.Temp.EnsPurgeMessage("_$Job_") for the full list"))
	}
	Else {
		// do not put into pSC more than 10 messages
	}
	Quit pSC
}

Method copyFrom(tSrc As Ens.Enterprise.MsgBank.MessageHeader) [ Internal ]
{
	Set i%Type=tSrc.Type
	Set i%Priority=tSrc.Priority
	Set i%Invocation=tSrc.Invocation
	Set i%TimeCreated=tSrc.TimeCreated
	Set i%TimeProcessed=tSrc.TimeProcessed
	Set i%Status=tSrc.Status
	Set i%IsError=tSrc.IsError
	Set i%ErrorStatus=tSrc.ErrorStatus
	Set i%CorrespondingMessageId=tSrc.CorrespondingMessageId
	Set i%SessionId=tSrc.SessionId
	Set i%SourceConfigName=tSrc.SourceConfigName
	Set i%TargetConfigName=tSrc.TargetConfigName
	Set i%ClientBodyClassName=tSrc.ClientBodyClassName
	Set i%ClientBodyId=tSrc.ClientBodyId
	Set i%BusinessProcessId=tSrc.BusinessProcessId
	Set i%TargetQueueName=tSrc.TargetQueueName
	Set i%ReturnQueueName=tSrc.ReturnQueueName
	Set i%MessageBodyClassName=tSrc.MessageBodyClassName
	Set i%MessageBodyId=tSrc.MessageBodyId
	Set i%Description=tSrc.Description
	Set i%SourceBusinessType=tSrc.SourceBusinessType
	Set i%TargetBusinessType=tSrc.TargetBusinessType
	#; Don't override this one - Set i%TimeBanked=tSrc.TimeBanked
}

/// Called to clean up local session-matching index
ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private, ServerOnly = 1 ]
{
	Set tId = $$$oidPrimary(oid)
	
	&sql(SELECT SessionId INTO :tSessionId FROM Ens_Enterprise_MsgBank.MessageHeader WHERE %ID=:tId)
	Set:SQLCODE=100 SQLCODE=0
	If SQLCODE Quit $$$ERROR($$$ObjectScriptError,"Unable to identify related sessions: SQLCODE='"_SQLCODE_"'; %msg='"_$g(%msg)_"'")
	
	If (tSessionId="")||('$D(^Ens.MsgBank.Sessions("parent",tSessionId))&&'$D(^Ens.MsgBank.Sessions("child",tSessionId))) Quit $$$OK
	
	&sql(SELECT MIN(ID) INTO :tIDMin FROM Ens_Enterprise_MsgBank.MessageHeader WHERE SessionId = :tSessionId)
	If (SQLCODE'=0) {
		If (SQLCODE'=100) {
			Quit $$$ERROR($$$ObjectScriptError,"Unable to identify related sessions: SQLCODE='"_SQLCODE_"'; %msg='"_$g(%msg)_"'")
		} Else {
			Quit $$$OK
		}
	}
	&sql(SELECT MAX(ID) INTO :tIDMax FROM Ens_Enterprise_MsgBank.MessageHeader WHERE SessionId = :tSessionId)
	If (SQLCODE'=0) {
		If (SQLCODE'=100) {
			Quit $$$ERROR($$$ObjectScriptError,"Unable to identify related sessions: SQLCODE='"_SQLCODE_"'; %msg='"_$g(%msg)_"'")
		} Else {
			Quit $$$OK
		}
	}
	
	If (tIDMin'=tIDMax) Quit $$$OK
	
	Quit ..cleanSessionLinks(tSessionId)
}

Trigger OnDelete [ Event = DELETE ]
{
	If ({SessionId}="")||('$D(^Ens.MsgBank.Sessions("parent",{SessionId}))&&'$D(^Ens.MsgBank.Sessions("child",{SessionId}))) Quit

	New tSessionId, tIDMin, tIDMax
	Set tSessionId = {SessionId}
	&sql(SELECT MIN(ID) INTO :tIDMin FROM Ens_Enterprise_MsgBank.MessageHeader WHERE SessionId = :tSessionId)
	If (SQLCODE'=0) Quit
	&sql(SELECT MAX(ID) INTO :tIDMax FROM Ens_Enterprise_MsgBank.MessageHeader WHERE SessionId = :tSessionId)
	If (SQLCODE'=0) Quit

	If (tIDMin=tIDMax) Do ##class(Ens.Enterprise.MsgBank.MessageHeader).cleanSessionLinks({SessionId})

	Quit
}

ClassMethod cleanSessionLinks(pSessionId As %String) As %Status [ Internal ]
{
	; clean up parent(s)
	Set tParSessId = ""
	For {
		Set tParSessId = $order(^Ens.MsgBank.Sessions("parent",pSessionId,tParSessId))
		Quit:tParSessId=""
		Kill ^Ens.MsgBank.Sessions("parent",pSessionId,tParSessId)
		If $data(^Ens.MsgBank.Sessions("parent",pSessionId))=1 Kill ^Ens.MsgBank.Sessions("parent",pSessionId)
		Kill ^Ens.MsgBank.Sessions("child",tParSessId,pSessionId)
		If $data(^Ens.MsgBank.Sessions("child",tParSessId))=1 Kill ^Ens.MsgBank.Sessions("child",tParSessId)
	}
	; clean up children(s)
	Set tChildSessId = ""
	For {
		Set tChildSessId = $order(^Ens.MsgBank.Sessions("child",pSessionId,tChildSessId))
		Quit:tChildSessId=""
		Kill ^Ens.MsgBank.Sessions("child",pSessionId,tChildSessId)
		If $data(^Ens.MsgBank.Sessions("child",pSessionId))=1 Kill ^Ens.MsgBank.Sessions("child",pSessionId)
		Kill ^Ens.MsgBank.Sessions("parent",tChildSessId,pSessionId)
		If $data(^Ens.MsgBank.Sessions("parent",tChildSessId))=1 Kill ^Ens.MsgBank.Sessions("parent",tParSessId)
	}
	Quit $$$OK
}

Storage Default
{
<Data name="MessageHeaderDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Type</Value>
</Value>
<Value name="3">
<Value>Priority</Value>
</Value>
<Value name="4">
<Value>Invocation</Value>
</Value>
<Value name="5">
<Value>TimeCreated</Value>
</Value>
<Value name="6">
<Value>TimeProcessed</Value>
</Value>
<Value name="7">
<Value>Status</Value>
</Value>
<Value name="8">
<Value>IsError</Value>
</Value>
<Value name="9">
<Value>ErrorStatus</Value>
</Value>
<Value name="10">
<Value>CorrespondingMessageId</Value>
</Value>
<Value name="11">
<Value>SessionId</Value>
</Value>
<Value name="12">
<Value>SourceConfigName</Value>
</Value>
<Value name="13">
<Value>TargetConfigName</Value>
</Value>
<Value name="14">
<Value>ClientBodyClassName</Value>
</Value>
<Value name="15">
<Value>ClientBodyId</Value>
</Value>
<Value name="16">
<Value>BusinessProcessId</Value>
</Value>
<Value name="17">
<Value>TargetQueueName</Value>
</Value>
<Value name="18">
<Value>ReturnQueueName</Value>
</Value>
<Value name="19">
<Value>MessageBodyClassName</Value>
</Value>
<Value name="20">
<Value>MessageBodyId</Value>
</Value>
<Value name="21">
<Value>Description</Value>
</Value>
<Value name="22">
<Value>SourceBusinessType</Value>
</Value>
<Value name="23">
<Value>TargetBusinessType</Value>
</Value>
<Value name="24">
<Value>TimeBanked</Value>
</Value>
<Value name="25">
<Value>SuperSession</Value>
</Value>
<Value name="26">
<Value>Resent</Value>
</Value>
</Data>
<DataLocation>^Ens.EntMsgBank.MessageHeaderD</DataLocation>
<DefaultData>MessageHeaderDefaultData</DefaultData>
<ExtentSize>20000000</ExtentSize>
<IdLocation>^Ens.EntMsgBank.MessageHeaderD</IdLocation>
<IndexLocation>^Ens.EntMsgBank.MessageHeaderI</IndexLocation>
<StreamLocation>^Ens.EntMsgBank.MessageHeaderS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
