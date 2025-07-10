/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

IncludeGenerator %occInclude

Class Ens.MessageHeader Extends (%Persistent, Ens.MessageHeaderBase, %XML.Adaptor) [ CompileAfter = Ens.SuperSessionIndex, System = 4 ]
{

Parameter EXTENTSIZE = 20000000;

Index Extent [ Extent, Type = bitmap ];

Index TimeCreated On TimeCreated;

Index Status On Status [ Type = bitmap ];

Index SourceConfigName On SourceConfigName [ Type = bitmap ];

Index TargetConfigName On TargetConfigName [ Type = bitmap ];

Index SessionId On SessionId;

Index MessageBodyClassName On MessageBodyClassName [ Type = bitmap ];

Index MessageBodyId On MessageBodyId;

/// <example>
/// Enterprise Message Bank status of:
///   this header,
///   its MessageBody,
///   possible SearchTable.
/// 
/// Possible values:
///   0, 8 or #:#:DateTime
/// where:
///   0 banking not requested
///   8 is banking requested
///   #:#:DateTime is:
///     First # indicates what has been banked:
///       Sum of 8 and a combination of Header=1, Body=2, SearchTable=4
///     Second #:
///       Last Message Header Status value
///     DateTime:
///       Last Message Header TimeProcessed value
/// </example>
Property Banked As %Integer(XMLPROJECTION = "NONE") [ Calculated, ReadOnly, SqlComputeCode = { Set {Banked}=$S(""={ID}:"",1:$G(^Ens.MsgBank.Banked({ID}),0)) }, SqlComputed, Transient ];

Method BankedGet() As %Integer
{
	Set tID=..%Id()  Quit:""=tID ""  Quit $G(^Ens.MsgBank.Banked(tID),0)
}

/// Create a new request header
ClassMethod NewRequestMessage(ByRef pHeader As Ens.MessageHeader, pMessageBody As %Library.Persistent, ByRef pSessionId As %String, ByRef pSuperSession As %String) As %Status
{
	Set tSC=$$$OK
	If $IsObject(pMessageBody) {
		Set:pMessageBody.%IsA("%Library.Persistent")||pMessageBody.%IsA("%Stream.Object") tSC=pMessageBody.%Save()
		Set:$$$ISOK(tSC) tSC=pMessageBody.%GetSwizzleObject(0,.tOID)
		If $$$ISERR(tSC) $$$LOGSTATUS(tSC)  Set pHeader=$$$NULLOREF  Quit tSC
	}
	Set:'$$$IsdefObject(pHeader)||(""'=pHeader.TimeCreated) pHeader = ##class(Ens.MessageHeader).%New()  $$$ASSERT($IsObject(pHeader))
	Set pHeader.TimeCreated = $$$timeUTC
	Set pHeader.Type = $$$eMessageTypeRequest
	Set pHeader.Priority = $$$eMessagePriorityAsync
	Set pHeader.CorrespondingMessageId = ""
	If $G(pSessionId)="" Set pSessionId=pHeader.MessageId()
	Set pHeader.SessionId = pSessionId
	If $G(pSuperSession)'="" Set pHeader.SuperSession = pSuperSession
	If '$IsObject(pMessageBody) {
		Set pHeader.MessageBodyClassName=""
		Set pHeader.MessageBodyId=pMessageBody
	} Else {
		Set pHeader.MessageBodyClassName=$classname(pMessageBody)
		Set pHeader.MessageBodyId=$$$oidPrimary(tOID)
	}
	Quit tSC
}

/// Create a response message header from a request message header
Method NewResponseMessage(Output pHeader As Ens.MessageHeader, pMessageBody As %Library.Persistent, pSuperSession As %String = "") As %Status
{
	Set tSC=$$$OK
	#dim tSaveThis As %Boolean = 0
	If $IsObject(pMessageBody) {
		Set:pMessageBody.%IsA("%Library.Persistent")||pMessageBody.%IsA("%Stream.Object") tSC=pMessageBody.%Save()
		Set:$$$ISOK(tSC) tSC=pMessageBody.%GetSwizzleObject(0,.tOID)
		If $$$ISERR(tSC) $$$LOGSTATUS(tSC)  Quit ..NewErrorResponse(.pHeader,tSC)
	}
	Set pHeader = ##class(Ens.MessageHeader).%New()  $$$ASSERT($IsObject(pHeader))
	Set pHeader.TimeCreated = $$$timeUTC
	Set pHeader.Type = $$$eMessageTypeResponse
	Set pHeader.SourceConfigName = ..TargetConfigName
	Set pHeader.TargetConfigName = ..SourceConfigName
	Set pHeader.SourceBusinessType = ..TargetBusinessType
	Set pHeader.TargetBusinessType = ..SourceBusinessType
	Set pHeader.BusinessProcessId = ..BusinessProcessId
	Set pHeader.Priority = ..Priority
	Set pHeader.Invocation = ..Invocation
	Set pHeader.TargetQueueName = ..ReturnQueueName
	Set pHeader.ReturnQueueName = ""
	Set pHeader.SessionId = ..SessionId

	#; If SuperSession generated after request received update.
	If (..SuperSession="") && (pSuperSession'="") Set ..SuperSession = pSuperSession, tSaveThis = 1     
	Set pHeader.SuperSession = ..SuperSession

	If pHeader.TargetQueueName'="" {
		Set pHeader.CorrespondingMessageId = ..MessageId()
		Set ..CorrespondingMessageId = pHeader.MessageId(), tSaveThis = 1
	}

	If tSaveThis {Set tSC = ..%Save()  $$$ASSERT(tSC=$$$OK)}

	If '$IsObject(pMessageBody) {
		Set pHeader.MessageBodyClassName=""
		Set pHeader.MessageBodyId=pMessageBody
	} Else {
		Set pHeader.MessageBodyClassName=$classname(pMessageBody)
		Set pHeader.MessageBodyId=$$$oidPrimary(tOID)
	}
	Quit tSC
}

/// creates an error message response header from a request message header
Method NewErrorResponse(Output pHeader As Ens.MessageHeader, pStatus As %Status) As %Status
{
	Set tSC = ..NewResponseMessage(.pHeader,$$$NULLOREF)  Quit:$$$ISERR(tSC) tSC
	Set pHeader.IsError=1
	Set pHeader.ErrorStatus=pStatus
	Quit $$$OK
}

/// set and immediately save the status field of this object
Method SetStatus(pStatus As Ens.DataType.MessageStatus)
{
	Set tTimeUtc=$$$timeUTC
	#; no need to update or queue for optional archiving if nothing changed
	If (..Status=pStatus)&&(..TimeProcessed=tTimeUtc) Return

	New %tId, %tStatus, %tTimeUtc  Set %tId=..%Id(), %tStatus=pStatus, %tTimeUtc=tTimeUtc
	#; Note: SetStatus is called from Ens.Director:moveEnsRuntimeToEnsSuspended() inside a transaction hence check for SkipTLevelCheck
	If $TLevel>0&&'$G($$$EnsJobLocal("SkipTLevelCheck")) Set tTL=$TLevel  While $TLevel>0 { TCommit } $$$LOGWARNING(tTL_" open user transaction"_$S(tTL>1:"s",1:"")_" found; committing before SetStatus("_%tId_")")
	&sql(UPDATE Ens.MessageHeader Set Status = :%tStatus, TimeProcessed = :%tTimeUtc where %ID = :%tId)
	If 'SQLCODE {
		Set ..Status=%tStatus, ..TimeProcessed=%tTimeUtc
		#; Bank the status change if we're configured for banking headers, or if this header was previously banked and needs its status updated
		#; (Bank other stuff too if we're configured for it)
		Set tFlags=$$$DoArchive,tBank=0
		If ('tFlags&&(0'=tFlags))||(tFlags&&'$$$AND(tFlags,$$$eMsgBankHeader)) {
			Set tBanked=..BankedGet()
			If $$$AND(tBanked,$$$eMsgBankHeader) { Set tFlags=tFlags+$$$eMsgBankHeader }
			ElseIf $$$AND(tBanked,$$$eMsgBankFlagged) { Set tBank=1 If 'tFlags Set tFlags="" } // Ensure we clear tFlags if Banking
		}
		If tFlags {
			If '$D(tBanked) Set tBanked=..BankedGet()
			If '$$$AND(tBanked,$$$eMsgBankFlagged) Set ^(%tId)=tBanked+$$$eMsgBankFlagged
		}
		Do:tFlags||tBank ##class(Ens.Queue).EnQueueId(tFlags_"_"_$Case($$$JobConfigName,..SourceConfigName:1,..TargetConfigName:2,"":0,:3)_"_"_%tId,"Ens.Enterprise.MsgBankOperation")
	}
}

Method %OnAfterSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	#dim tFlags As %String
	Set tFlags=$$$DoArchive  If tFlags {Set:'..Banked ^Ens.MsgBank.Banked(..%Id())=$$$eMsgBankFlagged  Do ##class(Ens.Queue).EnQueueId(tFlags_"_"_$Case($$$JobConfigName,..SourceConfigName:1,..TargetConfigName:2,"":0,:3)_"_"_..%Id(),"Ens.Enterprise.MsgBankOperation")}

	/* 
		Update the SuperSession Index table.
		This index table is used for viewing messages by Super Session.
		If there is an error we do not want to abort saving the message header.
		Account for SuperSession changing after initial insert.
	*/
	If ..SuperSession '= "" {
		Try {
			#dim tSuperSessionIndex As Ens.SuperSessionIndex = $$$NULLOREF
			If insert {
				Set tSuperSessionIndex = ##class(Ens.SuperSessionIndex).%New()
				Set tSuperSessionIndex.MessageHeader = $this
				Set tSuperSessionIndex.SuperSession = ..SuperSession
			} Else {
				/* look to find if have a SuperSession Index already saved and if different */
				#dim tHeaderId As %String = ..%Id()
				&sql(SELECT SuperSession, ID INTO :tPreviousSuperSession, :tSuperSessionIndexID FROM Ens.SuperSessionIndex WHERE MessageHeader = :tHeaderId)
				If SQLCODE = 100 {
					Set tSuperSessionIndex = ##class(Ens.SuperSessionIndex).%New()
					Set tSuperSessionIndex.MessageHeader = $this
					Set tSuperSessionIndex.SuperSession = ..SuperSession
				} ElseIf 'SQLCODE {
					If tPreviousSuperSession'=..SuperSession {
						#dim tSC As %Status = $$$OK
						Set tSuperSessionIndex = ##class(Ens.SuperSessionIndex).%OpenId(tSuperSessionIndexID,,.tSC)
						If $$$ISOK(tSC) {
							Set tSuperSessionIndex.SuperSession = ..SuperSession
						} Else {
							Quit
						}
					} Else {
						Quit
					}
				}
			}
			Do tSuperSessionIndex.%Save()
		} Catch {}
	}

	Quit $$$OK
}

/// The same as %Id(), but works even if the object hasn't been saved already
Method MessageId() As %String [ CodeMode = generator ]
{
	$$$GENERATE(" If ..%Id()="""" Do ..%IdSet($increment("_$$$EXTidlocation($$$pEXT,%class)_"))")
	$$$GENERATE(" Quit ..%Id()")
	Quit $$$OK
}

/// Deprecated - use ResendDuplicatedMessage() or ResubmitMessage()
ClassMethod ResendMessage(pHeaderId As %String) As %Status [ CodeMode = expression, Internal ]
{
..ResubmitMessage(.pHeaderId)
}

/// Resubmit the message header identified by <var>pHeaderId</var> to its target queue.
/// Optional arguments <var>pNewTarget</var> and <var>pNewBody</var> specify replacement values for key header properties.
/// If these are given, the Description property is updated with annotations giving the previous values.
/// Finally the boolean <var>pHeadOfQueue</var> argument specifies whether the header should be resubmitted at the end of the target queue or at the head of the line.
ClassMethod ResubmitMessage(pHeaderId As %String, pNewTarget As %String, pNewBody As %RegisteredObject, pHeadOfQueue As %Boolean) As %Status
{
	Set tSC=..PrepareResubmitMessage(.tHeaderObj,.pHeaderId,.pNewTarget,.pNewBody)  Quit:$$$ISERR(tSC) tSC
	Set tSC = ##class(Ens.Queue).EnQueue(tHeaderObj,.pHeadOfQueue)  Quit:$$$ISERR(tSC) $$$EnsError($$$EnsErrGeneral,"Error from EnQueue(); not resubmitting message '"_pHeaderId_"' : "_$$$StatusDisplayString(tSC))
	Set tSC = $$$AuditResendMessage(pHeaderId)
	Quit tSC
}

ClassMethod PrepareResubmitMessage(Output pHeaderObj As Ens.MessageHeader, pHeaderId As %String, pNewTarget As %String = "", pNewBody As %RegisteredObject = {$$$NULLOREF}) As %Status [ Internal ]
{
	Set pHeaderObj=$$$NULLOREF, tSC=$$$OK
	If '##class(Ens.Director).IsProductionRunning() Quit $$$EnsError($$$EnsErrGeneral,"ProductionNotRunning; not resubmitting message '"_pHeaderId_"'")
	Set tHdr = ##class(Ens.MessageHeader).%OpenId(pHeaderId,,.tSC)
	Quit:'$IsObject(tHdr) $$$EnsError($$$EnsErrGeneral,"Not resubmitting; can not open message header '"_pHeaderId_"' : "_$$$StatusDisplayString(tSC))

	Set:pNewTarget=tHdr.TargetConfigName pNewTarget=""
	Set:""'=pNewTarget tOldTarget=tHdr.TargetConfigName_"( "_tHdr.TargetBusinessType_") / "_tHdr.TargetQueueName, tHdr.TargetConfigName=pNewTarget
	Set tHdr.TargetQueueName=$G($$$ConfigQueueName($G($$$DispatchNameToConfigName(tHdr.TargetConfigName),0)))
	Quit:""=tHdr.TargetQueueName $$$ERROR($$$EnsErrGeneral,"Target config item '"_tHdr.TargetConfigName_"' is not running")
	Set tHdr.TargetBusinessType=$$$ConfigBusinessType(tHdr.TargetConfigName)
	If ""'=pNewBody {
		Set tOldClass=tHdr.MessageBodyClassName, tOldBodyId=tHdr.MessageBodyId
		If '$IsObject(pNewBody) {
			Set tHdr.MessageBodyClassName=""
			Set tHdr.MessageBodyId=pNewBody
		} Else {
			Set tHdr.MessageBodyClassName=$classname(pNewBody)
			Set:pNewBody.%IsA("%Library.Persistent")||pNewBody.%IsA("%Stream.Object") tSC=pNewBody.%Save()
			Set:$$$ISOK(tSC) tSC=pNewBody.%GetSwizzleObject(0,.tOID)
			If $$$ISERR(tSC) Set tHdr.MessageBodyId=""  Quit tSC
			Set tHdr.MessageBodyId=$$$oidPrimary(tOID)
		}
	}
	Set tHdr.Description="Resubmitted"_$S(""=pNewTarget:"",1:"; old Target = "_tOldTarget)_$S(""=pNewBody:"",1:"; old body = '"_tOldClass_" : "_tOldBodyId_"'")_$S(""=tHdr.Description:"", "Resubmitted"=$E(tHdr.Description,1,$L("Resubmitted")):","_$E(tHdr.Description,$L("Resubmitted")+1,*), 1:": "_tHdr.Description)
	Kill ^Ens.MsgBank.Banked(pHeaderId) ; resubmit to the MsgBank too, if banking is active
	Set pHeaderObj = tHdr
	Quit tSC
}

/// Resend the message header identified by <var>pOriginalHeaderId</var> by constructing a copy of it and submitting the copy to its target queue.
/// Optional arguments <var>pNewTarget</var>, <var>pNewBody</var> and <var>pNewSource</var> specify replacement values for key header properties.
/// The Description property is updated with an annotation giving the original header ID.
/// Finally the boolean <var>pHeadOfQueue</var> argument specifies whether the new header should be submitted at the end of the target queue or at the head of the line.
ClassMethod ResendDuplicatedMessage(pOriginalHeaderId As %String, Output pNewHeaderId As %String, pNewTarget As %String, pNewBody As %RegisteredObject, pNewSource As %String, pHeadOfQueue As %Boolean) As %Status
{
	Set pNewHeaderId="", tSC=..NewDuplicatedMessage(.tNewHeader,.pOriginalHeaderId,.pNewTarget,.pNewBody,.pNewSource)  Quit:$$$ISERR(tSC) tSC
	Set tSC = ##class(Ens.Queue).EnQueue(tNewHeader,.pHeadOfQueue)  Quit:$$$ISERR(tSC) $$$EnsError($$$EnsErrGeneral,"Error from EnQueue(); not resending copy of original message '"_pOriginalHeaderId_"' : "_$$$StatusDisplayString(tSC))
	Set pNewHeaderId=tNewHeader.%Id()
	Set tSC = $$$AuditResendMessage(pNewHeaderId)
	Quit tSC
}

ClassMethod NewDuplicatedMessage(Output pNewHeader As Ens.MessageHeader, pOriginalHeaderId As %String, pNewTarget As %String = "", pNewBody As %RegisteredObject = {$$$NULLOREF}, pNewSource As %String = "") As %Status [ Internal ]
{
	Set pNewHeader=$$$NULLOREF, tSC=$$$OK
	If '##class(Ens.Director).IsProductionRunning() Quit $$$ERROR($$$EnsErrProductionNotRunning)

	Set tOldHdr = ##class(Ens.MessageHeader).%OpenId(pOriginalHeaderId)
	If '$IsObject(tOldHdr) Quit $G(%objlasterror,$$$ERROR($$$EnsErrGeneral,"Can not open message header "_pOriginalHeaderId))

	Set tNewHdr=tOldHdr.%ConstructClone() $$$ASSERT($IsObject(tNewHdr))
	Set tNewHdr.TimeCreated = $$$timeUTC

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
		Quit:""'=tOldHdr.ReturnQueueName $$$ERROR($$$EnsErrGeneral,"Cannot override source for synchronous request message "_pOriginalHeaderId)
		Set tNewHdr.SourceConfigName = pNewSource
		Set tNewHdr.SourceBusinessType = $$$ConfigBusinessType(pNewSource)
		Set:""=tNewHdr.SourceBusinessType tNewHdr.SourceBusinessType=$$$eHostTypeService
		Set tNewHdr.BusinessProcessId = ""
	}
	If ""'=pNewBody {
		If '$IsObject(pNewBody) {
			Set tNewHdr.MessageBodyClassName=""
			Set tNewHdr.MessageBodyId=pNewBody
		} Else {
			Set tNewHdr.MessageBodyClassName=$classname(pNewBody)
			Set:pNewBody.%IsA("%Library.Persistent")||pNewBody.%IsA("%Stream.Object") tSC=pNewBody.%Save()
			Set:$$$ISOK(tSC) tSC=pNewBody.%GetSwizzleObject(0,.tOID)
			If $$$ISERR(tSC) Set tNewHdr.MessageBodyId=""  Quit tSC
			Set tNewHdr.MessageBodyId=$$$oidPrimary(tOID)
		}
	}
	Set tNewHdr.Description="Resent "_pOriginalHeaderId_$S(""=tOldHdr.Description:"", "Resent "=$E(tOldHdr.Description,1,$L("Resent ")):","_$E(tOldHdr.Description,$L("Resent ")+1,*), 1:": "_tOldHdr.Description)
	Set pNewHeader=tNewHdr
	Quit tSC
}

/// Replacement multi threaded capable method available in <CLASS>Ens.Util.MessagePurge</CLASS>
/// 
ClassMethod Purge(Output pDeletedCount As %Integer, pDaysToKeep As %Integer = 7, pKeepIntegrity As %Boolean = 1, pBodiesToo As %Boolean = 0, pBitmapPurgeRunLimit As %Integer = 600) As %Status
{
	Set:'$TLEVEL tTransactionSuspendedSwitch = ##class(Ens.Util.Purge.SuspendTransaction).%New($$$EnsPurgeJournalOldDataGet)

	New %tDoNotDeleteDate,%tID,%tBodyId,%tBodyClassname Set %tID="", %tDoNotDeleteDate = ##class(Ens.Purge).GetDoNotDeleteDate(pDaysToKeep)
	If '$data($$$EnsJobLocal) New $$$EnsJobLocal Set $$$EnsJobLocal = ""
	Set tSC=$$$OK, SQLCODE=0, pDeletedCount=0, pDeletedCount("bodies")=0
	Set tSC1 = ##class(%SYS.Monitor.Interop.DatabaseImpact.Utils).LogDatabaseSizes(0)
	If $$$ISERR(tSC1) {
		$$$LOGWARNING("Error encountered logging database impact metrics: "_$system.Status.GetErrorText(tSC1))
	}
	#; Log purging errors in Event log but no more than $$$ensPurgeMaxWarn per type (body, search table & header)
	#dim tPurgeErrorWarningsArray = $$$ensPurgeMaxWarn
	If pBodiesToo {
		If pKeepIntegrity {
			&sql(DECLARE C1 CURSOR FOR
				Select TOP 100000000 ID,MessageBodyId,MessageBodyClassName Into :%tID,:%tBodyId,:%tBodyClassname From Ens.MessageHeader h
					Where (TimeCreated < :%tDoNotDeleteDate)
						And 0 = ( Select Count(*) From Ens.MessageHeader
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
					#; Delete body if body class exists and is persistent and ENSPURGE is NOT explicitly set to 0 (i.e. ENSPURGE=1 by default)
					Set:""=%tBodyClassname&&(%tBodyId=+%tBodyId) %tBodyClassname="Ens.MessageBody"
					If ""'=%tBodyClassname {
						Set tExists=$G(aClass(%tBodyClassname))
						If 0'=tExists {
							If ""=tExists&&'($$$comClassDefined(%tBodyClassname)&&($classmethod(%tBodyClassname,"%IsA","%Persistent")||$classmethod(%tBodyClassname,"%IsA","%Stream.Object")))||($parameter(%tBodyClassname,"ENSPURGE")=0) {
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
										Set tSC = ..ReportPurgeError($$$ensPurgeST,tMsg,tSC,tSC2,.tPurgeErrorWarningsArray)
										#; If error purging search table but body purged/already deleted then carry on
									}
								} Else {
									Set tMsg = "Failed to purge body for header "_%tID_", BodyClassname='"_%tBodyClassname_"':"_$$$StatusDisplayString(tSC1)
									Set tSC = ..ReportPurgeError($$$ensPurgeBody,tMsg,tSC,tSC1,.tPurgeErrorWarningsArray)
									#; If protect error purging body continue to next message and do not try to delete message header
									If (tMsg["<PROTECT>") Continue
								}
								Set pDeletedCount("bodies")=pDeletedCount("bodies")+$$$ISOK(tSC1)
							}
						}
					}
				}
				&sql(DELETE From Ens.MessageHeader Where ID = :%tID)
				Set pDeletedCount=pDeletedCount+%ROWCOUNT
				If SQLCODE {
					Set tMsg = "Failed to purge message header "_%tID_": SQLCODE="_SQLCODE Set:$G(%msg)'="" tMsg = tMsg_", %msg="_%msg
					Set tSC = ..ReportPurgeError($$$ensPurgeHdr,tMsg,tSC,$$$ERROR($$$EnsErrGeneral,tMsg),.tPurgeErrorWarningsArray)
					/*	If protect error when trying to delete message header quit purge completely
						as all message header purges will encounter protect
					*/
					If (tMsg["<PROTECT>") Quit
				}
			} Set tCode=SQLCODE &sql(CLOSE C1) Set:'SQLCODE SQLCODE=tCode
		} Else {
			&sql(DECLARE C2 CURSOR FOR
				Select ID,MessageBodyId,MessageBodyClassName Into :%tID,:%tBodyId,:%tBodyClassname From Ens.MessageHeader
					Where (TimeCreated < :%tDoNotDeleteDate))
			&sql(OPEN C2)
			For { &sql(FETCH C2)  Quit:SQLCODE
				If %tBodyId'="" {
					#; Delete body if body class exists and is persistent and ENSPURGE is NOT explicitly set to 0 (i.e. ENSPURGE=1 by default)
					Set:""=%tBodyClassname&&(%tBodyId=+%tBodyId) %tBodyClassname="Ens.MessageBody"
					If ""'=%tBodyClassname {
						Set tExists=$G(aClass(%tBodyClassname))
						If 0'=tExists {
							If ""=tExists&&'($$$comClassDefined(%tBodyClassname)&&($classmethod(%tBodyClassname,"%IsA","%Persistent")||$classmethod(%tBodyClassname,"%IsA","%Stream.Object")))||($parameter(%tBodyClassname,"ENSPURGE")=0) {
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
										Set tSC = ..ReportPurgeError($$$ensPurgeST,tMsg,tSC,tSC2,.tPurgeErrorWarningsArray)
										#; If error purging search table but body purged/already deleted then carry on
									}
								} Else {
									Set tMsg = "Failed to purge body for header "_%tID_", BodyClassname='"_%tBodyClassname_"':"_$$$StatusDisplayString(tSC1)
									Set tSC = ..ReportPurgeError($$$ensPurgeBody,tMsg,tSC,tSC1,.tPurgeErrorWarningsArray)
									#; If protect error purging body continue to next message and do not try to delete message header
									If (tMsg["<PROTECT>") Continue
								}
								Set pDeletedCount("bodies")=pDeletedCount("bodies")+$$$ISOK(tSC1)
							}
						}
					}
				}
				&sql(DELETE From Ens.MessageHeader Where ID = :%tID)
				Set pDeletedCount=pDeletedCount+%ROWCOUNT
				If SQLCODE {
					Set tMsg = "Failed to purge message header "_%tID_": SQLCODE="_SQLCODE Set:$G(%msg)'="" tMsg = tMsg_", %msg="_%msg
					Set tSC = ..ReportPurgeError($$$ensPurgeHdr,tMsg,tSC,$$$ERROR($$$EnsErrGeneral,tMsg),.tPurgeErrorWarningsArray)
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
				Select TOP 100000000 ID Into :%tID From Ens.MessageHeader h
					Where TimeCreated < :%tDoNotDeleteDate
						And 0 = ( Select Count(*) From Ens.MessageHeader
								Where (SessionId = h.SessionId)
									And (Status<>$$$eMessageStatusCompleted)
									And (Status<>$$$eMessageStatusAborted)
									And (Status<>$$$eMessageStatusError)
									And (Status<>$$$eMessageStatusDiscarded) )
					Order By TimeCreated
				)
			&sql(OPEN C3) For { &sql(FETCH C3)  Quit:SQLCODE
				&sql(Delete From Ens.MessageHeader Where ID=:%tID)
				Set pDeletedCount=pDeletedCount+%ROWCOUNT
				If SQLCODE {
					Set tMsg = "Failed to purge message header "_%tID_": SQLCODE="_SQLCODE Set:$G(%msg)'="" tMsg = tMsg_", %msg="_%msg
					Set tSC = ..ReportPurgeError($$$ensPurgeHdr,tMsg,tSC,$$$ERROR($$$EnsErrGeneral,tMsg),.tPurgeErrorWarningsArray)
					/*	If protect error when trying to delete message header quit purge completely
						as all message header purges will encounter protect
					*/
					If (tMsg["<PROTECT>") Quit
				}
			} Set tCode=SQLCODE &sql(CLOSE C3) Set:'SQLCODE SQLCODE=tCode
		} Else {
			&sql(DECLARE C4 CURSOR FOR
				Select ID Into :%tID From Ens.MessageHeader Where TimeCreated < :%tDoNotDeleteDate)
			&sql(OPEN C4) For { &sql(FETCH C4)  Quit:SQLCODE
				Set %ROWCOUNT=0
				&sql(Delete From Ens.MessageHeader Where ID=:%tID)
				Set pDeletedCount=pDeletedCount+%ROWCOUNT
				If SQLCODE {
					Set tMsg = "Failed to purge message header "_%tID_": SQLCODE="_SQLCODE Set:$G(%msg)'="" tMsg = tMsg_", %msg="_%msg
					Set tSC = ..ReportPurgeError($$$ensPurgeHdr,tMsg,tSC,$$$ERROR($$$EnsErrGeneral,tMsg),.tPurgeErrorWarningsArray)
					/*	If protect error when trying to delete message header quit purge completely
						as all message header purges will encounter protect
					*/
					If (tMsg["<PROTECT>") Quit
				}
			} Set tCode=SQLCODE &sql(CLOSE C4) Set:'SQLCODE SQLCODE=tCode
		}
	}
	Set:SQLCODE&&(SQLCODE'=100) tSC=$$$ADDSC(tSC,$$$ERROR($$$EnsErrGeneral,"Purge error at ID "_$G(%tID)_"; SQLCODE = "_SQLCODE))
	Set tBitmapSC = ..PurgeBitmaps(pBitmapPurgeRunLimit,.tDeletedChunks)
	Merge pDeletedCount("bitmaps") = tDeletedChunks

	Kill tTransactionSuspendedSwitch
	Set tSC1 = ##class(%SYS.Monitor.Interop.DatabaseImpact.Utils).LogDatabaseSizes(0)
	If $$$ISERR(tSC1) {
		$$$LOGWARNING("Error encountered logging database impact metrics: "_$system.Status.GetErrorText(tSC1))
	}

	Quit $$$ADDSC(tSC,tBitmapSC)
}

/// Internal method used by this class and Ens.EnterpriseMsgBank.MessageHeader
ClassMethod ReportPurgeError(pType As %Integer, pMsg As %String, pSC As %Status, pSC2 As %Status, ByRef pPurgeErrorWarningsArray) As %Status [ Internal ]
{
	#dim tThisTypeCount As %Integer = $Increment(pPurgeErrorWarningsArray(pType))
	If (tThisTypeCount <= $Get(pPurgeErrorWarningsArray,$$$ensPurgeMaxWarn)) {
		$$$LOGWARNING(pMsg)
		#; No matter the # of errors to log in event log cap error concatenation to 10 as was the case for PurgeSetTemp
		If (tThisTypeCount < $$$ensPurgeMaxStatus) {
			Set pSC = $$$ADDSC(pSC,pSC2)
		}
	} ElseIf (tThisTypeCount = ($G(pPurgeErrorWarningsArray,$$$ensPurgeMaxWarn) + 1)) {
		#; may not get here due to quitting on certain errors but report only once per data type.
		$$$LOGERROR("No longer reporting purge failures related to "_$Case(pType,$$$ensPurgeBody:"message bodies",$$$ensPurgeST:"search tables",:"message headers"))
	}
	Return pSC
}

/// Deprecated. No longer used by InterSystems Code.
/// Replaced by ReportPurgeError
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

Method needsReply() As %Boolean [ CodeMode = expression ]
{
(""'=..ReturnQueueName) || (..Priority<=$$$eMessagePrioritySync)
}

ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private ]
{
	Set tID=$$$oidPrimary(oid)
	Kill:""'=tID ^Ens.MsgBank.Banked(tID)
	Quit $$$OK
}

Trigger OnDelete [ Event = DELETE ]
{
	New tID
	Set tID={%%ID}
	Kill ^Ens.MsgBank.Banked(tID)
	Quit
}

XData FormDefinition
{
<FieldDefinition>
	<field property="SessionId"/>
	<field property="TargetConfigName"/>
	<field property="SourceConfigName"/>
	<field property="MessageBodyClassName"/>
	<field property="MessageBodyId"/>
	<field property="TimeCreated"/>
	<field property="TimeProcessed"/>
	<field property="Type"/>
	<field property="Priority"/>
	<field property="SourceBusinessType"/>
	<field property="TargetQueueName"/>
	<field property="TargetBusinessType"/>
	<field property="ReturnQueueName"/>
	<field property="CorrespondingMessageId"/>
	<field property="BusinessProcessId"/>
	<field property="Description"/>
	<field property="Invocation"/>
	<field property="SuperSession"/>
	<field property="Resent"/>
	<field property="Status"/>
	<field property="IsError"/>
	<field property="ErrorStatus"/>
	<field property="Banked"/>
</FieldDefinition>
}

Storage Default
{
<Data name="MessageHeaderDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>BusinessProcessId</Value>
</Value>
<Value name="3">
<Value>Category</Value>
</Value>
<Value name="4">
<Value>CorrespondingMessageId</Value>
</Value>
<Value name="5">
<Value>ErrorStatus</Value>
</Value>
<Value name="6">
<Value>Invocation</Value>
</Value>
<Value name="7">
<Value>IsError</Value>
</Value>
<Value name="8">
<Value>MessageBody</Value>
</Value>
<Value name="9">
<Value>Priority</Value>
</Value>
<Value name="10">
<Value>ReturnQueueName</Value>
</Value>
<Value name="11">
<Value>SessionId</Value>
</Value>
<Value name="12">
<Value>SourceConfigName</Value>
</Value>
<Value name="13">
<Value>Status</Value>
</Value>
<Value name="14">
<Value>TargetConfigName</Value>
</Value>
<Value name="15">
<Value>TargetQueueName</Value>
</Value>
<Value name="16">
<Value>TimeCreated</Value>
</Value>
<Value name="17">
<Value>TimeProcessed</Value>
</Value>
<Value name="18">
<Value>Type</Value>
</Value>
<Value name="19">
<Value>MessageBodyId</Value>
</Value>
<Value name="20">
<Value>SourceBusinessType</Value>
</Value>
<Value name="21">
<Value>TargetBusinessType</Value>
</Value>
<Value name="22">
<Value>MessageBodyClassName</Value>
</Value>
<Value name="23">
<Value>Description</Value>
</Value>
<Value name="24">
<Value>SuperSession</Value>
</Value>
<Value name="25">
<Value>Resent</Value>
</Value>
</Data>
<DataLocation>^Ens.MessageHeaderD</DataLocation>
<DefaultData>MessageHeaderDefaultData</DefaultData>
<ExtentSize>20000000</ExtentSize>
<IdLocation>^Ens.MessageHeaderD</IdLocation>
<IndexLocation>^Ens.MessageHeaderI</IndexLocation>
<Property name="MessageBodyClassName">
<Selectivity>10%</Selectivity>
</Property>
<Property name="MessageBodyId">
<Selectivity>0.0001%</Selectivity>
</Property>
<Property name="Priority">
<Selectivity>20%</Selectivity>
</Property>
<Property name="SessionId">
<Selectivity>20</Selectivity>
</Property>
<Property name="SourceConfigName">
<Selectivity>5%</Selectivity>
</Property>
<Property name="Status">
<Selectivity>11%</Selectivity>
</Property>
<Property name="TargetConfigName">
<Selectivity>5%</Selectivity>
</Property>
<Property name="TimeCreated">
<Selectivity>5</Selectivity>
</Property>
<Property name="TimeProcessed">
<Selectivity>5</Selectivity>
</Property>
<StreamLocation>^Ens.MessageHeaderS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
