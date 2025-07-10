/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySystem, Ensemble)

Class EnsPortal.Dialog.ExportMessages Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

Parameter DOMAIN = "Ensemble";

Parameter APPLYBUTTON = 0;

/// Users must have USE permissions on the %Ens_MessageExport resource to use this page.
Parameter RESOURCE = "%Ens_MessageExport:USE";

Parameter XDEVBUFFERSIZEMAX = 128;

Parameter XDEVBUFFERSIZEMIN = 4;

/// This starts off being the id in IRIS.Temp.ResendIDs but is then
/// updated to be the id in SessionEvents to ensure it can be cleaned up when user logs out.
Property tempKey As %ZEN.Datatype.string(ZENURL = "KEY");

Property msgQuantity As %ZEN.Datatype.integer(ZENURL = "QUANTITY");

Property savedSearch As %ZEN.Datatype.string(ZENURL = "SAVEDSEARCH");

Property searchClass As %String [ InitialExpression = "EnsPortal.MsgFilter.SavedSearch", ReadOnly ];

Property queuedSessionId As %ZEN.Datatype.string;

Property cleanedUp As %ZEN.Datatype.string;

Property permittedForBackground As %ZEN.Datatype.boolean;

Property msgNotOK As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Not permitted. Please see the reason above.")} ];

/// This is the BP(L) that will process the background request
Parameter BACKGROUNDPROCESSOR = "EnsLib.Background.Process.ExportMessageSearch";

Parameter PRIVATE = 1;

/// This is the Workflow Role that will process the background request
Property BackgroundWFRole [ InitialExpression = "%ProductionMessageExport" ];

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<hgroup>
<spacer width="30"/>
<vgroup>
<spacer height="20"/>
<label id="exportInfo"/>
<spacer height="10"/>
<vgroup id = "settings">
<text id="DocName" label="Enter the name of the download file:" title="This name will be given to the browser" size="40" value="messages.txt"/>
<vgroup id="notes">
<spacer height="10"/>
<label id = "fileinfo" hidden = "true" containerStyle="font-size: .6em"/>
</vgroup>
<spacer height="10"/>
<select id="MsgSep" label="Message Separator:" title="Specifiy how the messages are separated.\n MLLP will include header and footer characters." showEmpty="false"/>
<spacer height="10"/>
<select id="Charset" label="Character set:" showEmpty="false"/>
<label id="exportCreation"/>
</vgroup>
<label id = "reason" hidden = "true"/>
</vgroup>
</hgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Export Messages")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Export Messages to browser.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {

		if (window._downloadTimer) {
			alert($$$Text("Export in progress"));
			return false;
		}

		var docName = zen("DocName").getValue();
		if (docName == "") {
			alert($$$Text("File name is empty. Please enter a file name for the export."));
			zen("DocName").focus();
			return false;
		}
		var charSet=zen("Charset").getValue();
		var msgSep=zen("MsgSep").getValue();

		if (zenPage.savedSearch) {
				var ok = zenPage.QueueSearchForExport()
				if (ok !='') {
					ok = $$$Text("There was an error queuing messages for Export.")+'\n'+$$$Text("Check the production is running.")+'\n\n'+ok;
					alert(ok);
				}
				else {
					alert("Export queued for processing via Session Id: "+zenPage.queuedSessionId)
				}
				return true;
		}


		zen('btnOK').setProperty('disabled',true);
		zen('btnOK').setProperty('controlClass','commandButtonDisabled');

		var numExported = zenPage.CreateTempFile(docName,zenPage.tempKey,charSet,msgSep);

		if (numExported>=0) {
			if (numExported != zenPage.msgQuantity) {
				alert($$$FormatText($$$Text("Not all selected messages exported."+"\n"+"%1 Selected. %2 Exported."),zenPage.msgQuantity,numExported));
			}
		} else {
			alert($$$Text("An error was encountered creating the export. See Event log warning entry.")); //user might receive a download file
		}

		if (numExported>0) {
			window._downloadTimer = window.setTimeout(function() {
				zenPage.CheckFileStatus(docName,zenPage.tempKey);
			}, 5);
		}

	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}

	/* Do not want to return true since want to remain open */
}

Method CheckFileStatus(pDocName, pKey) [ ZenMethod ]
{
	#; We build the server side temporary file name server side and based on pDocName and temp key.
	#dim tSC = $$$OK
	#dim tFilename = ..tempServerFilename(pDocName,pKey)

	#; try open
	Try {
		Set tF = ##class(%File).%New(tFilename)
		Set tSC = tF.Open("W")
		Kill tF ; We were just testing...
		If $$$ISOK(tSC) {
			&js<
				if (window._downloadTimer) {
					window.clearInterval(window._downloadTimer);
					window._downloadTimer = null;
					zenPage.doDownload();
				}
			>
		}
	} Catch {
	}
}

ClientMethod doDownload() [ Language = javascript ]
{
	var docName = zen("DocName").getValue();
	var charset = zen("Charset").getValue();
	var key = zenPage.tempKey;
	zenPage.DownloadStream(docName,charset,key);
	zen('btnCancel').setProperty('caption',$$$Text("Done"));
	zen('btnOK').setProperty('disabled',true);
	zen('btnOK').setProperty('controlClass','commandButtonDisabled');
	zen('btnCancel').focus();
}

ClassMethod DownloadStream(pDocName As %String, pCharSet As %String, pKey As %String) [ ZenMethod ]
{
	#dim tSC = $$$OK
	#dim tFilename
	Set tFilename = ..tempServerFilename(pDocName,pKey)

	Try {

		Set tStream = ##class(%FileBinaryStream).%New()
		Set tSC = tStream.LinkToFile(tFilename)
		If $$$ISERR(tSC) Quit
		Do tStream.SetAttribute("ContentDisposition","attachment; filename="_pDocName)
		Do tStream.SetAttribute("CharSet",pCharSet)
		Set tSC = tStream.%Save()
		If $$$ISERR(tSC) Quit
		#dim Oid = tStream.%Oid()
		&js<window.location="#url(%25CSP.StreamServer.cls?STREAMOID=#(..Encrypt(Oid))#)#";>

	} Catch { Set tSC = $$$SystemError}

	If $$$ISERR(tSC) {
		#dim tMsg = $ZCVT("Failed to link to download file.","O","JS")
		&js<alert(#(tMsg)#);>
	}
}

/// Draw contents of description box.
Method DrawInfo(pSeed As %String) As %Status
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

	} Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

ClassMethod tempServerFilename(pDocName, pKey, pUsername = {$username}) As %String
{
	#;If a parameter is passed in via javascript it is assigned empty string
	If pUsername = "" Set pUsername = $username
	/* Called multiple times and needs to be the same */
	#dim ext = $P(pDocName,".",*)
	Set:(ext="") ext = "tmp"
	#dim tTempDir = ..tempServerDirectory()
	#dim tTempFileName = $translate($zstrip($SYSTEM.Encryption.Base64Encode(pKey_pUsername_$namespace_pDocName),">","="), "+/", "ab")_"."_ext

	Quit tTempDir_tTempFileName
}

ClassMethod tempServerDirectory() As %String
{
	Quit $$$FileNormalizeDirectory($get(^%SYS("TempDir",$namespace),$get($$$SYSTempDir)))
}

Method %OnAfterCreatePage() As %Status
{
	#dim tInfo As %String = ""
	#dim tReason As %String = ""

	If ..savedSearch ="" {

		#; Messages will be downloaded synchronously
		If (..tempKey '= "") && $Data(^IRIS.Temp.ResendIDs(..tempKey)) {

			#; Move IRIS.Temp.ResendIDs to Session Temp node
			Set tInfo = $$$FormatTextHTML($$$Text("%1 messages selected to download"),..msgQuantity)
			#dim tSessionTempNode = ##class(EnsPortal.SessionEvents).GetTempNode()
			#dim tSessionTempGbl = ##class(EnsPortal.SessionEvents).GetReference(tSessionTempNode)
			Merge @tSessionTempGbl = ^IRIS.Temp.ResendIDs(..tempKey)
			Kill ^IRIS.Temp.ResendIDs(..tempKey)
			Set ..tempKey = tSessionTempNode

		} Else {

			Set ..tempKey = ""
			Set tInfo = $$$TextHTML("Unable to export. Please consult your administrator.")
			Set tReason = $$$TextHTML("Failed to obtain header IDs")

		}

	} Else {

		#; Check if user is configured in Workflow and allowed to use the particular processor

		If ..userPermittedForBackgroundRequest(.tReason) {

			Set tInfo = $$$TextHTML("The Export will be carried out in the background using the search criteria and will be available for download from your Workflow Inbox")
			Set ..permittedForBackground = 1

		} Else {

			#; disable OK button
			Set ..permittedForBackground = 0
			Set tInfo = $$$TextHTML("Unable to export. Please consult your administrator.")

		}

	}

	Set ..%GetComponentById("exportInfo").value = tInfo

	If ((..savedSearch ="") && (..tempKey '= "")) || ..permittedForBackground {

		#; Set Charset drop down list
		#dim DefCharList
		#dim CharList = $$GetIONames^%SYS.NLS(.DefCharList,1)
		#dim valueList = ""
		#dim tc,tint,displayList
		For tc = 1:1:$L(CharList,",") {
			Set tint = $P(CharList,",",tc)
			If tint="" Quit
			Set valueList = valueList_","_tint
		}
		Set displayList = valueList
		Set $Piece(displayList,",",1) = "<"_$$$Text("Device Default")_">"
		Set ..%GetComponentById("Charset").valueList = valueList
		Set ..%GetComponentById("Charset").displayList = displayList

		#; Set Message Separator options
		Set valueList = "CRLF,CR,LF,MLLP,Tab,None"
		Set displayList = "CRLF,CR,LF,MLLP,Tab,None"
		Set ..%GetComponentById("MsgSep").valueList = valueList
		Set ..%GetComponentById("MsgSep").displayList = displayList

		If (..savedSearch '="") || (..msgQuantity > 100) {
			#; Show file size limit in MB if background or sync > 100
			#dim tSC
			#dim tSizeLimit = $fn((..GetServerFileByteSizeLimit(,(..tempServerDirectory()_"x.x"),.tSC)/(1024*1024)),"",0)
			If $$$ISOK(tSC) {
				#dim tSizeInfo =$$$FormatTextHTML($$$Text("(file will be limited to a maximum size of %1 MB)"),tSizeLimit)
				Set ..%GetComponentById("fileinfo").value = tSizeInfo
				Set ..%GetComponentById("fileinfo").hidden = 0
			}
		}

	} Else {

		Set ..%GetComponentById("settings").hidden = 1
		Set ..%GetComponentById("reason").value = tReason
		Set ..%GetComponentById("reason").hidden = 0
		Set ..%GetComponentById("btnOK").hidden = 1
		#; Despite hidden change btnOK
		Set ..%GetComponentById("btnOK").onclick="alert('zenPage.msgNotOK');"
		Set ..%GetComponentById("btnOK").disabled = 1
		Set ..%GetComponentById("btnOK").controlClass="commandButtonDisabled"
		#; Remove SavedSearch in case user exits popup via X
		If ..savedSearch '="" Do ..DoSearchDelete()
	}

	Quit ##super()
}

/// This callback, if defined, is called when the user presses the Cancel button.
/// If this returns false, then the dialog is not cancelled.
ClientMethod ondialogCancel() [ Language = javascript ]
{
	var tmp=zenPage.CleanupExportIDs(zenPage.tempKey);
	var docName = zen("DocName").getValue();
	tmp=zenPage.CleanupTemporaryServerFile(docName,zenPage.tempKey);

	/* delete saved search if used */
	if (zenPage.savedSearch!="") {
		tmp = zenPage.DoSearchDelete()
		if (tmp != '') alert(tmp);
	}

	zenPage.cleanedUp = "OK"
	return true;
}

/// Cleanup temp of saved ids.
ClassMethod CleanupExportIDs(pKey As %String) As %String [ ZenMethod ]
{
	If (pKey '= "") && $Data(%session) Do ##class(EnsPortal.SessionEvents).KillTempNode(pKey)
	Quit 1
}

/// Cleanup temporary server side file
ClassMethod CleanupTemporaryServerFile(pDocName As %String, pKey As %String) As %Integer [ ZenMethod ]
{
	#dim tStatus = "ok"
	If pKey '= "" {
		#dim tFilename = ..tempServerFilename(pDocName,pKey)
		If ##class(%File).Exists(tFilename) Set tStatus = ##class(%File).Delete(tFilename)
	}
	Quit tStatus
}

/// This method is also called from background business process as well as SMP.
/// throws error if error status encountered
ClassMethod CreateTempFile(pDocName, pKey, pCharSet, pMsgSep, pRS, pUsername = {$username}) As %String [ ZenMethod ]
{
	#dim tSC = $$$OK
	#dim tUseResultSet = 0
	#dim tCountExported As %Integer = 0
	#dim tFileStream = ##class(%Stream.FileCharacter).%New()
	#dim tBrowserSession = $Data(%session)

	#;If a parameter is passed in via javascript it is assigned empty string
	If pUsername = "" Set pUsername = $username

	Try {

		If ($Data(pRS)#2) && ($IsObject(pRS)) {
			Set tUseResultSet = 1
		} Else {
			If ($Get(pKey)="") {
				Quit
			} Else {
				#dim tIDsTempGbl = ""
				If $Data(%session) {
					Set tIDsTempGbl = ##class(EnsPortal.SessionEvents).GetReference(pKey)
				}
				If (tIDsTempGbl = "")||($Order(@tIDsTempGbl@("")) = "") {
					Quit
				}
			}
		}

		#dim tStatus = 1
		#dim tServerSideFilename = ..tempServerFilename(pDocName,pKey,pUsername)
		#;Set temporary file name into session data if called from SMP so will be removed on logout if user clicks X out of popup
		Try {
			If tBrowserSession {
				#dim tSessionTempNode = ##class(EnsPortal.SessionEvents).GetTempNode()
				#dim tSessionTempGbl = ##class(EnsPortal.SessionEvents).GetReference(tSessionTempNode)
				Set @tSessionTempGbl@("TempMsgExportFile")=..Encrypt($LB(tServerSideFilename,pDocName,pKey))
			}
		} Catch {}

		If ##class(%File).Exists(tServerSideFilename) Set tStatus = ##class(%File).Delete(tServerSideFilename)
		If 'tStatus {
			Set tSC = $$$ERROR($$$GeneralError,$$$Text("Failed to delete previous server side temporary file"))
			Quit
		}

		#dim ex As %Exception.AbstractException
		#dim tMsgHeaderId = ""
		#dim tMsgHeaderObject As Ens.MessageHeader
		#dim tMsgBodyClassName
		#dim tMsgBodyId
		#dim tMsgBodyObj

		#dim tServerSideFileOpen As %Boolean = 0

		#dim tEntryIO = $IO
		#dim tXDEV="|XDEV|"_+$JOB

		#dim export = ""
		#dim tChunk As %String

		Set tFileStream.TranslateTable = pCharSet
		Set tSC = tFileStream.LinkToFile(tServerSideFilename)
		If $$$ISERR(tSC) quit

		Set tServerSideFileOpen = 1

		#dim tSource = $$$Text("Message Browser Export to user's browser")
		#dim tAudit As %Boolean = 0

		#dim tMsgSepCharacters = $Case(pMsgSep,
										"CRLF":$C(13,10),
										"CR":$C(13),
										"LF":$C(10),
										"MLLP":$C(28),
										"Tab":$C(9),
										:"")

		#dim tMaxServerFileSize = ..GetServerFileByteSizeLimit(pUsername,tServerSideFilename, .tSC)

		If $$$ISERR(tSC) Quit

		Set xdevBufferSize=..#XDEVBUFFERSIZEMIN  // 4 MB The Default for the XDev buffer
		Set isMoveNext=1  // Flag controling whether to "Move ResultSet to Next Record" or "Reprocess the Current message with a larger buffer"
		For {

			If tFileStream.Size > tMaxServerFileSize Quit

			Close tXDEV

			// Common handling for extending or resetting the buffer
			If (('isMoveNext)&&(xdevBufferSize<..#XDEVBUFFERSIZEMAX)) {
				// Trying: 4, 8, 16, 32, 64, 128
				$$$LOGINFO($$$FormatText("Extending Buffer Size from %1 MB",xdevBufferSize))
				Set xdevBufferSize=(xdevBufferSize*2)
				$$$LOGINFO($$$FormatText("New Buffer Size %1 MB",xdevBufferSize))
			} ElseIf (('isMoveNext)&&(xdevBufferSize>=..#XDEVBUFFERSIZEMAX)) {
				$$$LOGWARNING($$$FormatText("Permanently failed export attempt with buffer size %1 MB. Unable to export oversized message.",xdevBufferSize))
				Set isMoveNext=1
				Set xdevBufferSize=..#XDEVBUFFERSIZEMIN
				Set tSC=$$$OK
			} Else {
				// If previously sucessful for an oversized message, then attempt the next message with default 4MB Buffer
				Set xdevBufferSize=..#XDEVBUFFERSIZEMIN
			}

			Open tXDEV:($ZF(-6,$$$XSLTLibrary,12):xdevBufferSize:"S":/HOSTNAME="XSLT":/IOT="RAW":/IBU=16384:/OBU=16384)
			Use tXDEV

			If tMsgHeaderId = "" && (pMsgSep="MLLP") Write $C(11)
			If tMsgHeaderId '= "" Write tMsgSepCharacters

			// Should the code move to next record, OR retry exporting the previous message with a larger buffer
			If isMoveNext {
				If tUseResultSet {
					If 'pRS.Next() {
						Set tMsgHeaderId = ""
					} Else {
						Set tMsgHeaderId = pRS.Data("ID")
					}
				} Else {
					Set tMsgHeaderId = $Order(@tIDsTempGbl@(tMsgHeaderId))
				}
			}

			If (tMsgHeaderId = "") Quit
			Set tMsgHeaderObject = ##class(Ens.MessageHeader).%OpenId(tMsgHeaderId,0,.tSC)
			If $$$ISERR(tSC) Quit
			Set tMsgBodyClassName = tMsgHeaderObject.MessageBodyClassName
			Set tMsgBodyId = tMsgHeaderObject.MessageBodyId

			Kill tMsgHeaderObject

			If (tMsgBodyClassName="") || (tMsgBodyId="") || '$classmethod(tMsgBodyClassName,"%ExistsId",tMsgBodyId) Continue

			Set tAudit = 1

			Set tMsgBodyObj = $classmethod(tMsgBodyClassName,"%OpenId",tMsgBodyId,0,.tSC)
			If $$$ISERR(tSC) Quit

			// mod for try to export at given size
			Set tSC=$$$OK
			Try {
				Set isMoveNext=1
				If tMsgBodyObj.%Extends("EnsLib.EDI.Document") {

					If tMsgBodyObj.%Extends("EnsLib.EDI.XML.Document") {

						$$$LOGINFO($$$FormatText("Attempting %1 export with buffer size %2 MB.","XML.Document",xdevBufferSize))
						Set tSC=$method(tMsgBodyObj,"OutputToDevice","wt")
						If $$$ISERR(tSC) {
							$$$LOGWARNING($$$FormatText("Failed export attempt for %1 with buffer size %2 MB::%3","XML.Document",xdevBufferSize,$$$StatusDisplayString(tSC)))
							Set isMoveNext=0
							Quit
						}
					} Else {
						$$$LOGINFO($$$FormatText("Attempting %1 export with buffer size %2 MB.","EDI.Document",xdevBufferSize))
						Set tSC=$method(tMsgBodyObj,"OutputToDevice")
						If $$$ISERR(tSC) {
							$$$LOGWARNING($$$FormatText("Failed export attempt for %1 with buffer size %2 MB::%3","EDI.Document",xdevBufferSize,$$$StatusDisplayString(tSC)))
							Set isMoveNext=0
							Quit
						}
					}

				} ElseIf tMsgBodyObj.%Extends("%XML.Adaptor") {

					Set tWriter = ##class(%XML.Writer).%New()
					Set tWriter.Indent = 1
					Set tSC = tWriter.OutputToDevice()
					If $$$ISERR(tSC) Quit
					$$$LOGINFO($$$FormatText("Attempting %1 export with buffer size %2 MB.","XML.Adaptor",xdevBufferSize))
					Set tSC = tWriter.RootObject(tMsgBodyObj)
					If $$$ISERR(tSC) {
						$$$LOGWARNING($$$FormatText("Failed export attempt for %1 with buffer size %2 MB::%3","XML.Adaptor",xdevBufferSize,$$$StatusDisplayString(tSC)))
						Set isMoveNext=0
						Quit
					}
				} Else {
					// Object doesn't support EDI or XML output
					Set tAudit = 0
				}
			
				// flush buffer
				Write *-3
				
			} Catch {
				// Assume buffer got exhaused, so retry.
				Set isMoveNext=0
				Set tSC=$$$OK
			}
			// Tidy up
			Set tMsgBodyObj=""

			// Nothing to output if the Buffer was overfilled and retry is needed
			If (($$$ISERR(tSC))||(0=isMoveNext)) {
				Set isMoveNext=0
				Continue
			}

			Try {
				While (1) {
					Read tChunk:0
					If '$L(tChunk) Quit
					Do tFileStream.Write(tChunk)
				}
				// Sucessful readback from buffer.
				// Resetting isMoveNext and xdevBufferSize defaults for next message
				// ie: Move to next message = True AND bufferSize = 4MB
				Set isMoveNext=1
				Set xdevBufferSize=..#XDEVBUFFERSIZEMIN

			} Catch ex {
				If ("<READ>"=ex.Name) {
					Set isMoveNext=0
				} ElseIf (ex.Name '= "<ENDOFFILE>") {
					Throw ex
				}
			}

			// Buffer was overfilled and retry is needed
			// Prevents UI from over-reporting messages exported.
			If 'isMoveNext {
				continue
			}

			Use tEntryIO
			Close tXDEV

			Set tCountExported = tCountExported + 1

			If tAudit {

				Do $$$AuditViewMessage(tSource,tMsgHeaderId,tMsgBodyClassName,tMsgBodyId)

			}

		}

		If (pMsgSep="MLLP") Write $C(13)

		Write *-3
		While (1) {
			Read tChunk:0
			If '$L(tChunk) Quit
			Do tFileStream.Write(tChunk)
		}

	} Catch ex {
		If (ex.Name '= "<ENDOFFILE>") Set tSC = ex.AsStatus()
	}

	Use tEntryIO
	Close tXDEV

	#dim tSCSave = $$$OK
	If (tCountExported>0) {
		Set tSCSave = tFileStream.%Save()
		If $$$ISERR(tSCSave) Set tCountExported=0,tSC=$$$ADDSC(tSC,tSCSave)
	}
	If $$$ISERR(tSC) {
		#; If browser synchronous export or both BP and we did export message(s) record error information.
		If tBrowserSession || (tCountExported>0) {
			If tBrowserSession Set tCountExported=-1 // might have exported messages but need to indicate to user an error was recorded
			$$$LOGWARNING($$$FormatText("Error encountered during user export of messages: %1",$$$StatusDisplayString(tSC)))
		} Else {
			#; End the calling BP process since error and failed to export any messages 
			$$$ThrowStatus(tSC)
		}
	}

	Quit tCountExported
}

/// Server side method to delete the temporary search
Method DoSearchDelete() As %Status [ ZenMethod ]
{
	#dim tStatus = $$$OK
	#dim ex As %Exception.AbstractException

	Try {
		If ($Extract(..savedSearch,1,18)="z_QueuedForExport_") {
			Set tStatus = $classmethod(..searchClass,"%DeleteId",..savedSearch)
			If $system.Status.Equals(tStatus, $$$DeleteObjectNotFound) {
				Set tStatus = $$$OK
			}
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $$$ISERR(tStatus) {
		Quit $zconvert($system.Status.GetErrorText(tStatus),"O","JS")
	}
	Quit ""
}

Method QueueSearchForExport() As %Status [ ZenMethod ]
{
	#dim tStatus = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

		#; Make Background request
		#dim tRequest = ##class(Ens.Background.Request.ExportMessage).%New()
		Set tRequest.BackgroundProcessor = ..#BACKGROUNDPROCESSOR
		Set tRequest.RequestedByUsername = $Username
		Set tRequest.WorkFlowRole = ..BackgroundWFRole
		Set tRequest.LocalFilename =  ..%GetComponentById("DocName").value
		Set tRequest.CharSet =  ..%GetComponentById("Charset").value
		Set tRequest.MsgSeperators =  ..%GetComponentById("MsgSep").value
		Set tRequest.SearchClass =  ..searchClass
		Set tRequest.SavedSearch =  ..savedSearch

		#dim tSessionId As %String
		Set tStatus = ##class(EnsLib.Background.Service).SendBackgroundRequest(tRequest,,.tSessionId)
		If $$$ISOK(tStatus) && $Data(tSessionId)#2 Set ..queuedSessionId = tSessionId

	} Catch ex {

		Set tStatus = ex.AsStatus()

	}

	If $$$ISERR(tStatus) {
		Quit $zconvert($system.Status.GetErrorText(tStatus),"O","JS")
	}

	Quit ""
}

Method userPermittedForBackgroundRequest(Output pReason) As %Boolean
{
	Kill pReason
	#dim tPermitted = 0

	#dim tBackgroundWFRole = ..BackgroundWFRole

	#dim tSC As %Status = $$$OK
	#dim tProcessorHost=##class(Ens.Host).GetShadowInstance(..#BACKGROUNDPROCESSOR,.tSC)
	If $$$ISERR(tSC) {
		Set pReason = $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
		Quit tPermitted
	}

	If tProcessorHost.WorkFlowRole '= "" Set tBackgroundWFRole = tProcessorHost.WorkFlowRole
	Kill tProcessorHost

	If ##class(EnsLib.Workflow.UserDefinition).%ExistsId($USERNAME) {

		If ##class(EnsLib.Workflow.RoleMembership).%ExistsId(tBackgroundWFRole_"||"_$USERNAME) {

			Set tPermitted = 1

		} Else {

			Set pReason = $$$FormatTextHTML("Your username is not a Workflow member of Workflow Role %1",tBackgroundWFRole)

		}

	} Else {

		Set pReason = $$$FormatTextHTML("Your username needs to be a registered Workflow User and a member of Workflow Role %1",tBackgroundWFRole)

	}

	Quit tPermitted
}

ClassMethod GetServerFileByteSizeLimit(pUsername As %String = {$USERNAME}, pFilename As %String = "", Output pSC As %Status = {$$$OK}) As %Integer [ Internal ]
{
	/*
		Limit size temporary server file can be
			Upper limit is half of free space on drive given in tServerSideFilename
			Configurable for user for each namespace
	*/
	#dim tMaxServerByteFileSize = 104857600 ; default to 100 mb limit
	#dim tDirByteFreeSpace = 0

	Try {
		Set pSC = ##class(%Library.File).GetDirectorySpace(##class(%Library.File).GetDirectory(pFilename), .tDirByteFreeSpace,/*total space*/,0 /*bytes*/)
		If $$$ISERR(pSC) Quit

		#; Set tMaxServerByteFileSize to half of GetDirectorySpace
		Set tMaxServerByteFileSize = (0.5 * tDirByteFreeSpace)

		#dim tLookupTable = "EnsFileSizeLimitMB"
		#dim tEnsUserMBLimit = ##class(Ens.Util.FunctionSet).Lookup(tLookupTable,##class(%SYS.Ensemble).EnsembleUsername(),(tMaxServerByteFileSize/1024/1024))

		#dim tUserByteLimit = ##class(Ens.Util.FunctionSet).Lookup(tLookupTable,pUsername,tEnsUserMBLimit) * 1024 * 1024
		If tUserByteLimit < tMaxServerByteFileSize Set tMaxServerByteFileSize = tUserByteLimit

	} Catch {}

	Quit tMaxServerByteFileSize
}

}
