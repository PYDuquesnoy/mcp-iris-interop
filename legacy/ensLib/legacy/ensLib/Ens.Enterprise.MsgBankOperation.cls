/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This operation and its configuration control archiving of events via TCP to a near-real-time MsgBank server running the production Ens.Enterprise.MsgBank.Production.
Class Ens.Enterprise.MsgBankOperation Extends (Ens.Enterprise.OperationBase, Ens.Util.XML.Reader) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "Ens.Enterprise.MsgBank.ClientTCPAdapter";

/// Send empty event submissions periodically if no conforming events need to be submitted
Property ForceKeepalives As %Boolean;

/* Override InitialExpression for inherited Setting */
/// How frequently should we check for conforming EventLog events that may need to be forwarded to the MsgBank Server. <br>
/// 0 means check only when messages are being forwarded.
Property EventLogInterval As %Numeric [ InitialExpression = 3 ];

Parameter SETTINGS = "EnableArchiving,ArchiveItems,EventLogInterval,ForceKeepalives";

/* Override InitialExpression for inherited Setting */
/// How long to keep retrying before giving up and returning an error code
Property FailureTimeout As %Numeric(MINVAL = -1) [ InitialExpression = -1 ];

Property StreamOut As %GlobalBinaryStream [ Internal ];

Property StreamIn As %GlobalBinaryStream [ Internal ];

Property %SearchTableMap [ Internal, MultiDimensional ];

Property %LastRetry As %Integer [ Internal ];

/// This user callback method is called just after %OnNew()
Method OnInit() As %Status
{
	Do ..StreamOutNewObject()
	Quit ##super()
}

/// The Adapter invokes the OnConnect() method to manage initialization of the connection
/// For multi job this is single threaded controlled by lock on ^Ens.MsgBank("LastEvtId")
Method OnConnect(pTimeout) As %Status
{
	Set $ZT="Trap", tSC=$$$OK, tLastEvtLocked=0
	Lock +^Ens.MsgBank("LastEvtId"):2 ; Could be here during transmission of data and not just initialising.
	If '$Test {
		/* Failed to  get lock. Repeat attempts unless need to be quiescent or terminate */
		Set tShouldBeQuiescent = ##class(Ens.Job).ShouldBeQuiescent()
		Set tTerminate=##class(Ens.Job).ShouldTerminate()
		While ('$Test&&'tShouldBeQuiescent&&'tTerminate) {
				Lock +^Ens.MsgBank("LastEvtId"):2
				If '$Test {
					Set tShouldBeQuiescent = ##class(Ens.Job).ShouldBeQuiescent()
					Set tTerminate=##class(Ens.Job).ShouldTerminate()
				}
		}
		If '$Test,(tShouldBeQuiescent||tTerminate) {
			Set tSC=$$$ERROR($$$EnsErrOutConnectException,"Multi threaded lock timeout during quiescence request.","TCP",2)
			Quit tSC
		}
	}
	Set tLastEvtLocked=1
	Do {
		Set tShake=##class(Ens.Enterprise.MsgBank.Handshake).%New()
		Set tShake.Node=$G(^Ens.MsgBank("NodeId"))
		Set tShake.RawNode=$zu(110)_"|"_$p($zu(86),"*",2)_"|"_$namespace
		If ""'=tShake.Node&&(tShake.RawNode'=tShake.Node) $$$LOGINFO("Handshaking with stored node name '"_tShake.Node_"' (indicating we have reset our MessageHeader Id or reported multiple IP addresses), not the fresh node name we would generate now: '"_tShake.RawNode_"'")
		Set tIPAddr=$P($zu(54,13,$zu(54,0)),",")
		Set tForceIPAddr=$G(^Ens.MsgBank("MyForceIPAddr"),tIPAddr)
		If tForceIPAddr'=tIPAddr && '$G(^Ens.MsgBank("MyForceIPAddr","warned",tForceIPAddr,tIPAddr)) {
			Set ^Ens.MsgBank("MyForceIPAddr","warned",tForceIPAddr,tIPAddr)=1
			$$$LOGINFO("Using forced client IP address ^Ens.MsgBank(""MyForceIPAddr"")="_tForceIPAddr_" instead of system reported local IP address "_tIPAddr)
		}
		Set tShake.IPAddress=tForceIPAddr_"|"_$G(^%SYS("SSPort"))
		Set Status=##Class(%Library.RoutineMgr).GetWebServerPort(.Port,.Server,.URLPrefix,.URL)
		Set tShake.WebServer=Server_"|"_Port_"|"_URLPrefix
		Set tShake.LastHdrId=$G(^Ens.MsgBank("LastHdrId"),0)
		Set tShake.CurrHdrId=$G(^Ens.MessageHeaderD,0)
		Set tShake.LastEvtId=$G(^Ens.MsgBank("LastEvtId"),0)
		Set tShake.CurrEvtId=..getMaxEventID()
		Set tShake.MirrorName=$S(($SYSTEM.Mirror.IsMember()&&$SYSTEM.Mirror.IsPrimary()):$SYSTEM.Mirror.MirrorName(),1:"")
		$$$sysTRACE("Exchanging Handshake messages to initialize/confirm our Node Id '"_tShake.Node_"'")
		Set tStreamOut=##class(%GlobalBinaryStream).%New()
		Do tShake.XMLExportToStream(tStreamOut)
		Set tSC=..Adapter.SendMessageStream(tStreamOut,.tStringIn,1)  Quit:$$$ISERR(tSC)
		Set tSC = ..ObjectFromString(.tShakeReply,tStringIn,"Ens.Enterprise.MsgBank.Handshake")

		If '$IsObject(tShakeReply) {
			#; Put together the best error code we can and then disconnect and quit
			Set tLine=$P(tStringIn,$C(13))
			If "<ERROR "=$E(tLine,1,$L("<ERROR ")) {
				Set tErr=$ZSTRIP($P($P(tLine,"'>",2),"</ERROR"),"<>WC")
				Set tSC=$$$ERROR($$$EnsErrGeneral,"MsgBank Handshake "_tLine_" : "_tErr)
			} ElseIf ""'=tLine {
				Set tSC=$$$ERROR($$$EnsErrGeneral,"MsgBank Handshake unrecognized response: '"_tStringIn_"'")
			} ElseIf $$$ISOK(tSC) {
				Set tSC=$$$ERROR($$$EnsErrGeneral,"MsgBank Handshake got empty XML response")
			}
			$$$LOGSTATUS(tSC)
			Do ..Adapter.Disconnect()
			Set tSC=$$$OK
			Quit
		}
		$$$sysTRACE("Got MsgBank Handshake response: "_tStringIn)
		If tShakeReply.Node'=tShake.Node {
			Set ^Ens.MsgBank("NodeId")=tShakeReply.Node
			$$$LOGINFO("MsgBank Server set local MsgBank Node Id from "_tShake.Node_"'' to '"_tShakeReply.Node_"'")
		}
		Set ^Ens.MsgBank=tShakeReply.RawNode
		Set ^Ens.MsgBank("IPAddr")=tShakeReply.IPAddress
		Set ^Ens.MsgBank("WebSvr")=tShakeReply.WebServer
		Set ^Ens.MsgBank("LastUpdate")=$$$timeUTC
	} While 0
Exit
	Lock:tLastEvtLocked -^Ens.MsgBank("LastEvtId")
	Quit tSC
Trap
	Set $ZT=""
	GoTo Exit
}

/// This is the default message handler.  All request types not declared in the message map are delivered here
Method OnMessage(pRequest As Ens.MessageHeader, Output pResponse As %Library.Persistent) As %Status
{
	Try {
		Set tSC = $$$OK
		Set (tBanked,tFlags)=0, tHdrId=pRequest.%Id(), tBodyId=pRequest.MessageBodyId, tOldBanked=pRequest.Banked
		Set tEventLocked = 0
		Set tStream=..StreamOut  Do ..StreamOut.Clear(), ..StreamIn.Clear()
		If ..%Flags = "" { ; The sender could only determine that the Header was enqueued, use current Banked flags for updates
			Set ..%Flags = tOldBanked
		}

		#; Construct header line attributes ; Header=1, Body=2, SearchTable=4, all=7
		$$$sysTRACE("Got pRequest header "_tHdrId_" with Banked="_tOldBanked)
		Set tHdrAttrs=" Id='"_tHdrId_"' Src='"_..%Source_"'"
		If $$$AND(..%Flags,$$$eMsgBankHeader) || $$$AND(tOldBanked,$$$eMsgBankHeader) { ; Header banking has been requested, or occurred previously
			If $$$AND(tOldBanked,$$$eMsgBankHeader) {
				Set tHdrAttrs=tHdrAttrs_" Status='"_pRequest.Status_"' Time='"_pRequest.TimeProcessed_"'"
				$$$catTRACE("archive","Updating banked header "_tHdrId_" with only status '"_pRequest.Status_"' for "_pRequest.MessageBodyClassName_" "_tBodyId)
			} Else {
				Set tFlags=$$$eMsgBankHeader
			}
			Set tBanked=tBanked+$$$eMsgBankHeader
		}
		If $$$AND(..%Flags,$$$eMsgBankBody) { ; Body
			If '$$$AND(tOldBanked,$$$eMsgBankBody) { ; don't re-archive bodies
				If pRequest.MessageBodyClassName="" {
					If ""=tBodyId {
						Set tBodyType="Empty"
						Set tHdrAttrs=tHdrAttrs_" BodyType='"_tBodyType_"' BodyClass='' BodyId=''"
						Set tFlags=tFlags+$$$eMsgBankBody
					} Else {
						Set tBodyType="String"
						Set tHdrAttrs=tHdrAttrs_" BodyType='"_tBodyType_"' BodyClass='' BodyId='@'"
						Set tFlags=tFlags+$$$eMsgBankBody
					}
				} ElseIf $classmethod(pRequest.MessageBodyClassName,"%Extends","%SerialObject") {
					Set tBodyType="Serial"
					Set tHdrAttrs=tHdrAttrs_" BodyType='"_tBodyType_"' BodyClass='"_pRequest.MessageBodyClassName_"' BodyId='@'"
					Set tFlags=tFlags+$$$eMsgBankBody
				} Else {
					Set tBody = $classmethod(pRequest.MessageBodyClassName,"%OpenId",tBodyId)
					If '$IsObject(tBody) {
						$$$LOGWARNING("Unable to instantiate and archive MessageBody for MessageHeader #"_tHdrId_" with body class "_pRequest.MessageBodyClassName_" and body Id "_tBodyId)
						Set tBodyType="Null"
					} Else {
						Set tBodyType=$S(
							tBody.%Extends("EnsLib.EDI.Document"):"VDoc"
							,tBody.%Extends("EnsLib.HTTP.GenericMessage"):"XML"
							,tBody.%Extends("Ens.StreamContainer"):"CData"
							,tBody.%Extends("%Stream.Object"):"SData"
							,tBody.%Extends("%XML.Adaptor"):"XML"
							,1:"Other")
						Set tHdrAttrs=tHdrAttrs_" BodyType='"_tBodyType_"' BodyClass='"_pRequest.MessageBodyClassName_"' BodyId='"_tBodyId_"'"
						Set tFlags=tFlags+$$$eMsgBankBody
					}
				}
			}
			Set tBanked=tBanked+$$$eMsgBankBody
		}
		If $$$AND(..%Flags,$$$eMsgBankSearchTable) { ; SearchTable
			If '$$$AND(tOldBanked,$$$eMsgBankSearchTable) { ; don't re-archive SearchTables
				If ""'=pRequest.MessageBodyClassName {
					Set tVDocSearch=$$$comMemberKeyGet(pRequest.MessageBodyClassName,$$$cCLASSparameter,"DEFSEARCHCLASS",$$$cPARAMdefault)
					If ""'=tVDocSearch {
						Do {
							Set tProd = ##class(Ens.Director).GetActiveProductionName()
							Set tSourceId = ##class(Ens.Config.Production).findItemIdByName(tProd,pRequest.SourceConfigName,"",.sc)  Quit:$$$ISERR(sc)
							Set tSource = ##class(Ens.Config.Item).%OpenId(tSourceId)
							Set tExists1 = tSource.GetModifiedSetting("SearchTableClass",.tSourceST)
							Set tTargetId = ##class(Ens.Config.Production).findItemIdByName(tProd,pRequest.TargetConfigName,"",.sc)  Quit:$$$ISERR(sc)
							Set tTarget = ##class(Ens.Config.Item).%OpenId(tTargetId)
							Set tExists2 = tTarget.GetModifiedSetting("SearchTableClass",.tTargetST)
							Set propQuery = "SELECT PropId FROM ENS_Config.SearchTableProp WHERE ClassExtent='"_tVDocSearch_"' AND (ClassDerivation = ? OR ClassDerivation %STARTSWITH ?)"
							Set rset=##class(%ResultSet).%New("%DynamicQuery:SQL")
							Set sc = rset.Prepare(propQuery)  Quit:$$$ISERR(sc)
							Set propIds = ","
							For tSearchTable=$G(tSourceST), $G(tTargetST) {
								CONTINUE:tSearchTable=""
								For {
									Set tSearchObj = ##class(%Dictionary.ClassDefinition).%OpenId(tSearchTable)
									Quit:'$IsObject(tSearchObj)
									Set sc = rset.Execute(tSearchTable,tSearchTable_"~")  Quit:$$$ISERR(sc) ;Added the '~' to StartsWith just in case one search table's name begins with that of another search table
									While rset.Next() {
										Set:(propIds'[(","_rset.Data("PropId")_",")) propIds = propIds_rset.Data("PropId")_"," ;the commas on both sides prevent mix-ups with other propId's containing the same characters
									}					
									Quit:$Case(tSearchTable,tVDocSearch:1,"":1,:0)
									Set tSearchTable = tSearchObj.Super
								}
							}
							Set:propIds="," propIds="(NULL)"
							Set $E(propIds) = "(", $E(propIds,*)=")" ;okay because first and last characters had been commas
						} While(0)
						
						Set tSearchTableSupertable=$G(..%SearchTableMap(tVDocSearch))
						If ""=tSearchTableSupertable {
							Set tSearchTableExtentSuper=##class(Ens.VDoc.SearchTableGenerator).GetExtentSuperclass(tVDocSearch)
							$$$comClassKeyGetLvar(tSearchTableSupertable,tSearchTableExtentSuper,$$$cCLASSsqlschemaname)
							Set tSearchTableSupertable = tSearchTableSupertable_"."_$$$comClassKeyGet(tSearchTableExtentSuper,$$$cCLASSsqltablename)
						}
						Set ..%SearchTableMap(tVDocSearch)=tSearchTableSupertable
						Set tCountSQL="Select Count(*) From "_tSearchTableSupertable_" Where DocId=?"_$S($D(propIds):" AND PropId IN "_propIds,1:"") 
						If tCountSQL'=..%lastCountSQL {
							Do ..%rsSearchCount.Close()
							Set tSC=..%rsSearchCount.Prepare(tCountSQL)  Quit:$$$ISERR(tSC)
							Set ..%lastCountSQL=tCountSQL
						}
						Set tSC=..%rsSearchCount.Execute(tBodyId)  Quit:$$$ISERR(tSC)
						Set tCount=0
						If ..%rsSearchCount.Next(.tSC) {
							Set tCount=..%rsSearchCount.GetData(1)
						}  Quit:$$$ISERR(tSC)
						If tCount {
							Set tHdrAttrs=tHdrAttrs_" SearchRows='"_tCount_"'"
							Set tFlags=tFlags+$$$eMsgBankSearchTable
						}
					}
				}
			}
			Set tBanked=tBanked+$$$eMsgBankSearchTable
		}
		Set tBanked=$$$OR(tBanked,tOldBanked)
		Set:$$$AND(..%Flags,$$$eMsgBankHeader) tBanked=tBanked_":"_pRequest.Status_":"_pRequest.TimeProcessed

		#; know here if not going to bank this message if already banked same information
		Set tNoMsgUpdate = ((tOldBanked=tBanked)&&'tFlags)

		/*	Output header line attributes and then the whole body
			If not updating message need to write the SUBMIT tag
			in case event(s) to bank
		*/
		Do tStream.WriteLine("<SUBMIT Flags='"_tFlags_"' HdrLen='"_$L(tHdrAttrs)_"'"_tHdrAttrs_">")

		If 'tNoMsgUpdate {
			If $$$AND(tFlags,$$$eMsgBankHeader) { ; Header
				$$$catTRACE("archive","Archiving header "_tHdrId_" for "_pRequest.MessageBodyClassName_" "_tBodyId)
				Do pRequest.XMLExportToStream(tStream)
			}
			If $$$AND(tFlags,$$$eMsgBankBody) { ; Body
				$$$catTRACE("archive","Archiving "_tBodyType_" "_pRequest.MessageBodyClassName_" "_tBodyId)
				If tBodyType="VDoc" {
					Do tStream.Write("<VDoc DocType='"_tBody.DocType_"'><![CDATA[")
					Set tSC=tBody.OutputToLibraryStream(tStream)  Quit:$$$ISERR(tSC)
					Do tStream.WriteLine("]]></VDoc>")
				} ElseIf tBodyType="CData" {
					Do tStream.Write("<CData Type='"_tBody.Type_"' Size='"_tBody.Stream.Size_"' Filename='"_$ZCVT(tBody.OriginalFilename,"O","XML")_"'><![CDATA[")
					Set tSC=tStream.CopyFrom(tBody.Stream)  Quit:$$$ISERR(tSC)
					Do tStream.WriteLine("]]></CData>")
				} ElseIf tBodyType="SData" {
					Do tStream.Write("<SData Size='"_tBody.Size_"'><![CDATA[")
					Set tSC=tStream.CopyFrom(tBody)  Quit:$$$ISERR(tSC)
					Do tStream.WriteLine("]]></SData>")
				} ElseIf tBodyType="XML" {
					Do tStream.Write("<XML><![CDATA[")
					Set tSC=tBody.XMLExportToStream(tStream)  Quit:$$$ISERR(tSC)
					Do tStream.WriteLine("]]></XML>")
				} ElseIf tBodyType="Serial" {
					Do tStream.Write("<Serial Size='"_$L(tBodyId)_"'><![CDATA[")
					Do tStream.Write(tBodyId)
					Do tStream.WriteLine("]]></Serial>")
				} ElseIf tBodyType="String" {
					Do tStream.Write("<String Size='"_$L(tBodyId)_"'><![CDATA[")
					Do tStream.Write(tBodyId)
					Do tStream.WriteLine("]]></String>")
				} ElseIf tBodyType'="Empty" {
					$$$LOGWARNING("Unsupported message type "_tBodyType_" - not archiving "_pRequest.MessageBodyClassName_" "_tBodyId)
					Do tStream.WriteLine("<NoExport/>")
				}
			}
			If $$$AND(tFlags,$$$eMsgBankSearchTable) { ; SearchTable
				$$$catTRACE("archive","Archiving "_tCount_" "_tSearchTableSupertable_" entries for "_pRequest.MessageBodyClassName_" "_tBodyId)
				Set tFetchSQL="Select DocId,PropId,PropValue From "_tSearchTableSupertable_" Where DocId=?"_$S($D(propIds):" AND PropId IN "_propIds,1:"")
				If tFetchSQL'=..%lastFetchSQL {
					Do:""'=..%lastFetchSQL ..%rsSearchFetch.Close()
					Set tSC=..%rsSearchFetch.Prepare(tFetchSQL)  Quit:$$$ISERR(tSC)
					Set ..%lastFetchSQL=tFetchSQL
				}
				Set tSC=..%rsSearchFetch.Execute(tBodyId)  Quit:$$$ISERR(tSC)
				Do tStream.WriteLine("<SearchTable Class='"_tVDocSearch_"'>")
				Set tNum=0 While ..%rsSearchFetch.Next(.tSC) { Set tNum=tNum+1
					Do tStream.WriteLine("<Row PropId='"_..%rsSearchFetch.Data("PropId")_"'><![CDATA["_..%rsSearchFetch.Data("PropValue")_"]]></Row>")
				}   Quit:$$$ISERR(tSC)
				For i=tNum+1:1:tCount {
					Do tStream.WriteLine("<Row PropId='0'><![CDATA[]]></Row>")
				}
				If tNum>tCount $$$catTRACE("archive","More "_tSearchTableSupertable_" Rows found than initially counted ("_tCount_").  Archived "_tNum_" entries for "_pRequest.MessageBodyClassName_" "_tBodyId)
				Do tStream.WriteLine("</SearchTable>")
			}
		}

		Set tLastEvtSent=""
		Set tLastEventProcessed=""
		If ..%anyEvents {
			// Allow short timeout if we don't have a message update to send
			// and single job
			Set tEventLockTO = $select(tNoMsgUpdate: $select(..%isSingleJob:0.2,1:0), 1: 0)
			Lock +^Ens.MsgBank("LastEvtId"):tEventLockTO
			If $test { // Have lock
				Set tEventLocked = 1
				Set tNow=..getMaxEventID(), tBefore=$G(^Ens.MsgBank("LastEvtId"),tNow)
				If tNow > tBefore {
					// Throttle event export
					Set tLastEvtSent = $select(tNow > (tBefore + 1000): tBefore + 1000, 1: tNow)
					Set tLastEventChecked = tBefore
					Set tSC=..exportEvents(..StreamOut,tBefore,.tLastEvtSent,,.tLastEventProcessed)  Quit:$$$ISERR(tSC)
				}
				Else {
					Lock -^Ens.MsgBank("LastEvtId")
					Set tEventLocked = 0
				}
			}
		}
		Quit:""=tLastEvtSent&&tNoMsgUpdate  ; skip send if no (status) change to report
		Do tStream.WriteLine("</SUBMIT>")

		#; Construct and send an archive submission
		Set tSC=..Adapter.SendMessageStream(tStream,.tStringIn)  Quit:$$$ISERR(tSC)
		Set tSC=..checkReply(tStringIn,tFlags,tHdrId,tLastEvtSent)  Quit:$$$ISERR(tSC)
		If ..RetryCount = 1 { // This message has gone through cleanly the first time so we can reset.
			Set ..%LastRetry = 0
		}
		Else {
			Set ..%LastRetry = tHdrId
		}

		If tOldBanked'=tBanked {
			$$$sysTRACE("Setting Banked flag for "_tHdrId_" from '"_tOldBanked_"' to '"_tBanked_"' (flags="_tFlags_")")
			Set ^Ens.MsgBank.Banked(tHdrId)=tBanked
			Lock -^Ens.MsgBank.Banked(tHdrId)  Set ..%hdrLocked=0 ; we've stored the Banked flag - now it's safe for another job to open the header object
		}
		If ..%anyEvents && tEventLocked {
			If tLastEventProcessed '= "" Set ^Ens.MsgBank("LastEvtId") = tLastEventProcessed
			Lock -^Ens.MsgBank("LastEvtId")
			Set tEventLocked = 0
		}
	}
	Catch ex {
		Set tSC = $$$EnsSystemError
	}
	If ..%hdrLocked && $$$ISOK(tSC) {
		// Keep the lock if the message wasn't banked; release after retries complete.
		Lock -^Ens.MsgBank.Banked(tHdrId)
		Set ..%hdrLocked = 0
	}
	If $g(tEventLocked) {
		Lock -^Ens.MsgBank("LastEvtId")
	}
	Quit tSC
}

Method OnKeepalive(pAdapterStatus As %Status) As %Status
{
	#; Check, filter and send new Events if any
	If $$$ISOK(pAdapterStatus)&&..%anyEvents {
		#; save and unlock now so a peer job can get to work on the next set
		Try {
			Set tEventLocked = 0
			Lock +^Ens.MsgBank("LastEvtId"):0.2
			If $Test {
				Set tEventLocked = 1
				Set tNow=..getMaxEventID(), tBefore=$G(^Ens.MsgBank("LastEvtId"),tNow)
				If tNow>tBefore {
					Set tLastId = $select(tNow > (tBefore + 10000): tBefore + 10000, 1: tNow)
					Set tLastEvtSent=tLastId
					Set tLastEventProcessed=tBefore
					Set pAdapterStatus=..exportEvents(..StreamOut,tBefore,.tLastEvtSent,1+..ForceKeepalives,.tLastEventProcessed)
					If $$$ISOK(pAdapterStatus) && (tLastEvtSent || ..ForceKeepalives) {
						Set pAdapterStatus=..Adapter.SendMessageStream(..StreamOut,.tStringIn)
						If $$$ISOK(pAdapterStatus) {
							Set pAdapterStatus=..checkReply(tStringIn,0,"",tLastEvtSent)
							If $$$ISOK(pAdapterStatus) {
								Set ^Ens.MsgBank("LastEvtId") = tLastEventProcessed
							}
						}
						If $$$ISERR(pAdapterStatus) {
							$$$LOGERROR("Failed to submit Event Log messages from Id "_(tBefore+1)_" through "_tLastId_" for archiving - "_$$$StatusDisplayString(pAdapterStatus))
							Set pAdapterStatus=$$$OK
						}
					} Else {
						If tLastEventProcessed > tBefore {
							Set ^Ens.MsgBank("LastEvtId") = tLastEventProcessed
						}
						$$$catTRACE("connwait","Found no Event Log messages to archive; current Event Log Id = "_tLastId)
					}
				}
				Lock -^Ens.MsgBank("LastEvtId")
				Set tEventLocked = 0
			}
		}
		Catch {
			Set pAdapterStatus = $$$EnsSystemError
			If tEventLocked Lock -^Ens.MsgBank("LastEvtId")
		}
	}
	Quit ##super(pAdapterStatus)
}

/// Archive all selected events since the last ID we checked
Method exportEvents(pStream As %GlobalBinaryStream, pPrevEventSent As %Integer, ByRef pLastEvtSent As %Integer, pWriteHeader As %Integer = 0, ByRef pLastEventProcessed As %Integer) As %Status
{
	Set tCount=0, tFirst=1, tNow=pLastEvtSent, pLastEvtSent="", tConfigName=..%ConfigName, pLastEventProcessed=$get(pLastEventProcessed)
	/* %events is populated with lower case item names hence use of LOWER function. tItem will be lowercase but it is only used here for %events array */
	&sql(Declare C1 Cursor For
		Select ID,LOWER(ConfigName),Type,TraceCat,SourceClass Into :tId,:tItem,:tType,:tCat,:tClass From Ens_Util.Log Where ID > :pPrevEventSent And ID <= :tNow And (ConfigName<>:tConfigName Or ConfigName Is Null) ORDER BY ID ASC)
	&sql(OPEN C1) For { &sql(FETCH C1)  Quit:SQLCODE
		Set pLastEventProcessed = tId
		Set:""=tItem tItem="."  Set:""=tCat tCat="."
		Set tDoEvt=$G(..%events(tItem,tType,tCat)
				,$G(..%events(tItem,tType)
				,$G(..%events(tItem)
				,$G(..%events("*",tType,tCat)
				,$G(..%events("*",tType)
				,$G(..%events("*"),0))))))
		If tDoEvt {
			Set tEvt=##class(Ens.Util.Log).%OpenId(tId)
			If tFirst { Set tFirst=0
				If pWriteHeader {
					Do pStream.Clear()
					Do pStream.WriteLine("<SUBMIT Flags='0' HdrLen=''>")
				}
				Do pStream.WriteLine("<LogEvents>")
			}
			Do tEvt.XMLExportToString(.tLogStr)
			Do pStream.Write("<Log Len='"_($L(tLogStr)+$L(tId))_"' Id='"_tId_"'>"_tLogStr_"</Log>")
			Set pLastEvtSent=tId
			Set tCount=tCount+1
		}
	} Set tSqlCode=SQLCODE  &sql(CLOSE C1)
	Quit:tSqlCode&&(tSqlCode'=100) $$$ERROR($$$EnsErrGeneral,"Archive error at ID "_$get(tId,"?")_"; SQLCODE = "_tSqlCode)
	If 'tFirst {
		Do pStream.WriteLine("</LogEvents>")
		Do:pWriteHeader pStream.WriteLine("</SUBMIT>")
		$$$catTRACE("msgbank","Archiving "_tCount_" LogEvents")
	} ElseIf pWriteHeader>1 {
		Do pStream.WriteLine("<SUBMIT Flags='0' HdrLen=''>")
		Do pStream.WriteLine("</SUBMIT>")
		$$$catTRACE("connwait","Sending empty keepalive <SUBMIT> element")
	}
	If tCount=0 {
		/*
			The callers of exportEvents limit the amount to send and therefore
			have to account for gaps in the event log that might not be banked
			or might have been purged.
			Check if there are no event log entries since the last event sent and before the tNow limit. 
		*/
		&sql(Select MIN(ID) Into :tMinId From Ens_Util.Log Where ID > :pPrevEventSent)
		Set tSqlCode=SQLCODE
		If tSqlCode,(tSqlCode'=100) {
			Quit $$$ERROR($$$EnsErrGeneral,"Archive error finding min ID for batch; SQLCODE = "_tSqlCode)
		}
		If (tMinId>tNow) {
			Set pLastEventProcessed = tMinId-1
			Quit $$$OK
		}
		/*
			Check that tNow valid by finding the maximum for the search and
			update pLastEventProcessed if no events match criteria.
		*/
		&sql(Select MAX(ID) Into :tMaxId From Ens_Util.Log Where ID > :pPrevEventSent AND ID <= :tNow)
		Set tSqlCode=SQLCODE
		If tSqlCode,(tSqlCode'=100) {
			Quit $$$ERROR($$$EnsErrGeneral,"Archive error finding max ID for batch; SQLCODE = "_tSqlCode)
		}
		If (tSqlCode||(tMaxId="")) Set tMaxId=tNow
		Set pLastEventProcessed = tMaxId
	}
	Quit $$$OK
}

Method checkReply(pReplyXML As %String, pFlags As %Integer, pHdrId As %Integer, pEvtId As %Integer) As %Status
{
	Set tSC = ..getReplyData(pReplyXML,.tFlags,.tLastHeader,.tLastEvent)
	If $$$ISERR(tSC) Quit tSC
	
	If (tFlags = pFlags) && (tLastHeader = pHdrId) && (tLastEvent = pEvtId) {
		Quit $$$OK
	}
	If (tLastHeader = ..%LastRetry) && ((tLastHeader '= pHdrId) || (tFlags '= pFlags)) { ; check for stale data from last resent message
		Set tMatched = 0
		Set tSC = $$$OK
		While ('tMatched) && (tLastHeader = ..%LastRetry) {
			Set tBanked = +$get(^Ens.MsgBank.Banked(tLastHeader),0)
			If $$$AND(tBanked,tFlags) || (tFlags = 0) {
				// We previously sent this message multiple times, but already processed at least one response.
				$$$LOGINFO("Discarding duplicate submission response for Header '"_tLastHeader_"' with Flags '"_tFlags_"'")
				Set tSC = ..Adapter.GetReplyString(.pReplyXML)
				If $$$ISERR(tSC) Quit
				Set tSC = ..getReplyData(pReplyXML,.tFlags,.tLastHeader,.tLastEvent)
				If $$$ISERR(tSC) Quit
				If (tFlags = pFlags) && (tLastHeader = pHdrId) && (tLastEvent = pEvtId) {
					Set tMatched = 1
				}
			}
			Else {
				Quit
			}
		}
		If $$$ISOK(tSC) && ('tMatched) Set tSC = $$$ERROR($$$EnsErrGeneral,"ID or flags mismatch in Archive submission response - got Flags "_tFlags_", expected "_pFlags_", Header "_tLastHeader_", expected "_pHdrId_", Event "_tLastEvent_", expected "_pEvtId)
		Quit tSC
	}
	Quit $$$ERROR($$$EnsErrGeneral,"ID or flags mismatch in Archive submission response - got Flags "_tFlags_", expected "_pFlags_", Header "_tLastHeader_", expected "_pHdrId_", Event "_tLastEvent_", expected "_pEvtId)
}

Method getReplyData(pReplyXML As %String, Output pFlags, Output pHeaderId, Output pEventId) As %Status
{
	Set tLine=$P(pReplyXML,$C(13))
	If "<REPLY Flags='"=$E(tLine,1,$L("<REPLY Flags='")) {
		Set pFlags=$P(tLine,"'",2)
		Set pHeaderId=$P($P(tLine,"ClientHdrId='",2),"'")
		Set pEventId=$P($P(tLine,"ClientEvtId='",2),"'")
		Quit $$$OK
	}
	#; Put together the best error code we can
	If "<ERROR "=$E(pReplyXML,1,$L("<ERROR ")) {
		Set tErr=$ZCVT($ZSTRIP($P($P(pReplyXML,"'>",2,99),"</ERROR"),"<>WC"),"I","XML")
		Set tSC=$$$ERROR($$$EnsErrGeneral,"Archive Submission attempt received error : "_tErr)
	} ElseIf ""'=pReplyXML {
		Set tSC=$$$ERROR($$$EnsErrGeneral,"Archive Submission unrecognized response: '"_pReplyXML_"'")
	} Else {
		Set tSC=$$$ERROR($$$EnsErrGeneral,"Archive Submission got empty XML response")
	}
	Quit tSC
}

Method getMaxEventID() As %String [ Internal, Private ]
{
	&sql(SELECT TOP 1 ID INTO :tMaxLogID FROM Ens_Util.Log ORDER BY ID DESC)
	#; If nothing found or error fall back to reporting last event id banked. It could be that all Events are purged.
	If SQLCODE Quit $G(^Ens.MsgBank("LastEvtId"),0)
	Quit tMaxLogID
}

}
