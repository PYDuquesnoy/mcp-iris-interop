/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Enterprise.MsgBank.TCPService Extends (Ens.BusinessService, Ens.Util.XML.Reader) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "Ens.Enterprise.MsgBank.BankTCPAdapter";

/// The name of a class that functions as a helper to process messages when requests are received that include a message body.
/// For each incoming message header, the service will call the OnBankMsg classmethod in the helper class with the following arguments:
/// <ul><li><var>pHeader</var> - the <class>Ens.Enterprise.MsgBank.MessageHeader</class> object being banked,</li>
/// <li><var>pFullHeaderID</var> - the full ID of the header,</li>
/// <li><var>pBody</var> - the message body object being banked,</li>
/// <li><var>pFullBodyID</var> - the full ID of the message body, and</li>
/// <li><var>pService</var> - the <class>Ens.Enterprise.MsgBank.TCPService</class> instance.</li></ul>
/// See the <class>Ens.Enterprise.MsgBank.BankHelperClass</class> for more details on the interface.
Property BankHelperClass As %String(MAXLEN = 100);

Parameter SETTINGS = "IgnoreIPChanges:Connection,BankHelperClass";

/// Our local server id for the node we are talking to
Property %NodeId As %Integer;

/// The version of the archive protocol we negotiated
Property %Version As %String;

/// Temp for parsing headers
/// Used to correlate MessageHeader XML data into Ens.Enterprise.MsgBank.MessageHeader class
/// Used to confirm Body CData exists if Body included (type not equal to Empty)
/// Used to confirm SearchTable data exists if SearchTable data declared to be included
/// Used to read SearchTable PropId,PropValue,DocId and save using SQL insert
/// This property is a GlobalCharacter so that XML Correlate can prepend Unicode BOM and XML version declaration
Property %HeaderStream As %Stream.GlobalCharacter [ Internal ];

/// ResultSet for inserting SearchTable rows
Property %rsSearchInsert As %ResultSet [ Internal ];

/// Most recent INSERT query for a given SearchTable family
Property %lastSearchSQL As %String [ Internal ];

/// Cached map from SearchTable class to table name
Property %SearchTableMap [ MultiDimensional ];

/// Ignore Client IP Changes<p>
/// For clients that are:
/// 	<li>not members of an InterSystems IRIS mirror and </li>
/// 	<li>might have different IP addresses after a restart and </li>
/// 	<li>it is not possible to specify the interface to connect to this service on so that it is the same IP each time</li>
/// <p>Enabling this setting prevents the Message Bank Service treating the change in client IP as a
/// new node if the node name is found and the message header IDs follow the last connection. <p>
/// This setting will apply to all clients that connect to this service that are not Mirror members. <p>
/// It is important to note that with this setting enabled the Message Bank Service may not be able to detect a different client.<p>
/// It is possible to have multiple Message Bank Services on different ports if this setting ought not to apply to all clients.<p>
/// The default setting is off.
Property IgnoreIPChanges As %Boolean [ InitialExpression = 0 ];

/// The Adapter invokes the OnConnect() method to manage initialization of the connection
Method OnConnect(pTimeout) As %Status
{
	#; Just in case we are not set to JobPerConnection
	Set ..%NodeId=""
	Set ..%rsSearchInsert=##class(%ResultSet).%New("%DynamicQuery:SQL")
	Quit $$$OK
}

Method OnProcessInput(pInput As %Stream.GlobalBinary, Output pOutput As %RegisteredObject) As %Status
{
	#dim tHandShakeLock As %Boolean = 0
	#dim tEntryCandidate As %String = ""
	#dim tJobPerConnection As %Boolean = (""'=$ZU(53))
	#dim tConnections As %Integer = 1
	
	If '$$$IsdefObject(pInput) $$$LOGWARNING("Received empty input packet - ignoring")  Quit $$$OK

	Set tLine=pInput.Read($L("<SUBMIT Flags='x'"),.tSC), (tId,tEvtId)=""
	If '..%NodeId {
		#; do the handshake
		If "<SHAKE Version="""=$E(tLine,1,$L("<SHAKE Version='")) {
			#;For job per connection need to handle one hand shake at a time
			If tJobPerConnection {
				Lock +$$$EnsMsgBankHandShake:$SYSTEM.SQL.GetProcessLockTimeout()
				If '$Test {
					$$$LOGWARNING("Timed out waiting to lock $$$EnsMsgBankHandShake")  Quit $$$OK
				}
				Set tHandShakeLock = 1
				#; Keep lock until Quit. From this point on tJobPerConnection will be the same value as tHandShakeLock
			}
			Do pInput.Rewind()
			Set tSC = ..ObjectFromStream(.tShake,pInput,"Ens.Enterprise.MsgBank.Handshake")
			If $$$ISOK(tSC)&&$IsObject(tShake) {
				If ","_tShake.Version_","'[",1.0," Set tSC=$$$ERROR($$$EnsErrGeneral,"Archive protocol 1.0 is the only version supported by this archive server")
				#; Loop searching for the right known client Node
				Set tCandidate=$S(""=tShake.Node:tShake.RawNode,1:tShake.Node)
				Set tNodeObj=$$$NULLOREF
				
				#;Increment connection count for Candidate [$$$EnsMsgBankConnections("Candidates" is removed at production startup and decremented on tear down.]
				If tJobPerConnection,(""'=tCandidate) {
					Set tConnections=$I($$$EnsMsgBankConnections("Candidates",tCandidate),1)
					Set $$$EnsJobLocal("MsgBank","Candidate")=tCandidate
				}
				
				While ""=..%NodeId&&$$$ISOK(tSC) {
					If ""=tCandidate Set tSC=$$$ERROR($$$EnsErrGeneral,"Node candidate not supplied")  Quit
					&sql(Select ID Into :tNodeId From Ens_Enterprise_MsgBank.Node Where Name=:tCandidate)
					If SQLCODE=100 {
						#; Node not found; use the one we have
						Set tNodeObj=##class(Ens.Enterprise.MsgBank.Node).%New(tCandidate)
						Set tSC=tNodeObj.%Save()
						If $$$ISOK(tSC) {
							Kill %objlasterror
							Set ..%NodeId=tNodeObj.%Id()
							Set:""=..%NodeId tSC=$G(%objlasterror,$$$ERROR($$$EnsErrGeneral,"Empty %Id()"))
						}
						If $$$ISERR(tSC) Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to create Node from candidate "_tCandidate_":"_$$$StatusDisplayString(tSC))  Quit
						#; Done
					} ElseIf SQLCODE {
						Set tSC=$$$ERROR($$$EnsErrGeneral,"Error querying for NodeId for "_tCandidate_"; SQLCODE="_SQLCODE)  Quit
					} Else {
						#; Found one (got SQLCODE=0) - check its numbers
						#; If the client's last header is lower than our last one we got from it and no other concurrent connections from same candidate, make a new node for it
						&sql(Select Top 1 ClientId Into :tTopId From Ens_Enterprise_MsgBank.MessageHeader Where NodeId=:tNodeId Order By ClientId Desc)
						If SQLCODE=100 Set tTopId=0, SQLCODE=0
						If SQLCODE Set tSC=$$$ERROR($$$EnsErrGeneral,"Error querying for top ClientId")  Quit		
						If tJobPerConnection {
							Set tEntryCandidate = tCandidate
							If (tShake.CurrHdrId<tTopId) {
								$$$LOGINFO("Detected lower client maximum header id in handshake request than current maximum in Message Bank for Node Id "_tNodeId_" ("_tShake.CurrHdrId_" compared to "_tTopId_"). "_$S((tConnections=1):"Calculating new Node Id.",1:"Ignoring since not first concurrent connection." ))
							}
						}
						If (tConnections=1),(tShake.CurrHdrId<tTopId) {
							#; Remote Namespace must have been re-initialized and restarted its HeaderId counter - give it a new name
							If tCandidate=tShake.Node&&(tCandidate'[tShake.RawNode) {
								Set tCandidate=tShake.RawNode
							} Else {
								Set $P(tCandidate,"|",4)=(1+$P(tCandidate,"|",4))
							}
						} Else {
							#; We found our node name and the numbers are OK; check if it's already in use by a
							#; different client with a different IP Address (multiple connections from the same client are OK)
							Set tIsMirrored = 0
							If (tShake.MirrorName'="") Set tIsMirrored = ($G(^Ens.MsgBankSvr("ClientIPs",tCandidate,"MirrorName"))=tShake.MirrorName)
							If 'tIsMirrored && $D(^Ens.MsgBankSvr("ClientIPs",tCandidate),tOtherIP) && '..IgnoreIPChanges {
								Set tIPAddr=..Adapter.IOAddr, tIPAddr=$P($P(tIPAddr,"<-",2),$S(tIPAddr["|":"|",1:":"))
								If tIPAddr'=tOtherIP {
									Set tDup=$P(tCandidate,"|",5)
									Set $P(tCandidate,"|",5)=$S(""=tDup:"A",1:$C(1+$A(tDup)))
									Continue
								}
							}
							Set ..%NodeId=tNodeId
						}
						If tJobPerConnection,(tEntryCandidate'=tCandidate) {
							If $I($$$EnsMsgBankConnections("Candidates",tEntryCandidate),-1) {}
							Set tConnections=$I($$$EnsMsgBankConnections("Candidates",tCandidate),1)
							Set $$$EnsJobLocal("MsgBank","Candidate")=tCandidate	
						}
					}
				}
				If $$$ISOK(tSC) {
					Set:'$IsObject(tNodeObj) tNodeObj=##class(Ens.Enterprise.MsgBank.Node).%OpenId(..%NodeId)
					$$$ASSERT($IsObject(tNodeObj)&&(tNodeObj.Name=tCandidate))
					If tNodeObj.IPAddress'=tShake.IPAddress || (tNodeObj.WebServer'=tShake.WebServer) {
						Set tNodeObj.IPAddress=tShake.IPAddress, tNodeObj.WebServer=tShake.WebServer
						Set tNodeObj.TimeUpdated=$$$timeUTC, tNodeObj.TimeConnected=tNodeObj.TimeUpdated
						Set tSC=tNodeObj.%Save()
					} Else {
						Set tUTC=$$$timeUTC
						&sql(Update Ens_Enterprise_MsgBank.Node Set TimeConnected=:tUTC)
					}
					Set tIPAddr=..Adapter.IOAddr, tIPAddr=$P($P(tIPAddr,"<-",2),$S(tIPAddr["|":"|",1:":"))
					Set tShakeReply=##class(Ens.Enterprise.MsgBank.Handshake).%New()
					Set tShakeReply.Node=tCandidate
					Set ^Ens.MsgBankSvr("ClientIPs",tCandidate)=tIPAddr
					If (tShake.MirrorName'="") Set ^Ens.MsgBankSvr("ClientIPs",tCandidate,"MirrorName")=tShake.MirrorName
					Set tMachine=$zu(110)
					Set tShakeReply.RawNode=tMachine_"|"_$p($zu(86),"*",2)_"|"_$namespace
					Set tShakeReply.IPAddress=$P($zu(54,13,$zu(54,0)),",")_"|"_$G(^%SYS("SSPort"))
					Set Status=##Class(%Library.RoutineMgr).GetWebServerPort(.Port,.Server,.URLPrefix,.URL)
					Set tWebServer=Server
					Set tShakeReply.WebServer=$S(""=tWebServer:tMachine,1:tWebServer)_"|"_Port_"|"_URLPrefix
					Set tSC=tShakeReply.XMLExportToString(.pOutput)
					Lock:tHandShakeLock -$$$EnsMsgBankHandShake
					Quit:$$$ISOK(tSC) tSC
				}
			} ElseIf $$$ISOK(tSC) {
				Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to get Handshake object from input '"_pInput.Read(1000)_"'")
			}
		} Else {
			Do pInput.Rewind()
			Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to find <SHAKE> element in '"_pInput.Read(1000)_"'")
		}
		Lock:tHandShakeLock -$$$EnsMsgBankHandShake
	} ElseIf "<SUBMIT Flags='" '= $E(tLine,1,$L("<SUBMIT Flags='")) {
		Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to find <SUBMIT> element in '"_tLine_"'")
	} Else { Do { ; <SUBMIT Flags='n' HdrLen='xx' Id='nn' [Status='abc']>
		#; Save the Archive stuff
		Set (tHeader,tBody,tReader)=$$$NULLOREF, (tHdrId,tFullId,tBodyId,tBankBodyId)=""

		#; Get a message header and/or body, hints & SearchTable if present
		Set tFlags=$P(tLine,"'",2) ; Header=1, Body=2, SearchTable=4, all=7
		Set tWork=pInput.Read($L(" HdrLen='")) If " HdrLen='"'=tWork Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to find HdrLen attribute in '"_tLine_tWork_"' with Flags="_tFlags)  Quit
		For { Set c=pInput.Read(1) Set tWork=tWork_c  Quit:$Case(c,"'":1,"":1,-1:1,:0) }
		Set tHdrLen=$P(tWork,"'",2) If tHdrLen'=+tHdrLen&&$L(tHdrLen) Set tSC=$$$ERROR($$$EnsErrGeneral,"HdrLen attribute '"_tHdrLen_"' is not a good number")  Quit
		Set tLine=tLine_tWork
		Set tWork=pInput.Read(tHdrLen+$L(">"))
		Set tLine=tLine_tWork

		If tHdrLen > 1 { ; not just Event Log
			If " Id='" '= $E(tWork,1,$L(" Id='")) Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to find Id attribute in '"_tLine_"'")  Quit
			Set tHdrId=$P(tWork,"'",2)  If tHdrId'=+tHdrId Set tSC=$$$ERROR($$$EnsErrGeneral,"Header Id attribute not a number in '"_tLine_"'")  Quit
			Set $E(tWork,1,$L(" Id=''")+$L(tHdrId))=""

			If " Src='"'=$E(tWork,1,$L(" Src='")) Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to find Src attribute in '"_tLine_"'")  Quit
			Set tSrc=$P(tWork,"'",2) If tSrc'=+tSrc Set tSC=$$$ERROR($$$EnsErrGeneral,"Header Src attribute not a number in '"_tLine_"'")  Quit
			Set $E(tWork,1,$L(" Src=''")+$L(tSrc))=""

			Set tName=$P(tWork,"'",1), tVal=$P(tWork,"'",2)
			If " Status="=tName {
				Set tStatus=tVal, $E(tWork,1,$L(tName)+$L(tVal)+2)=""
				Set tName=$P(tWork,"'",1), tVal=$P(tWork,"'",2)
				If " Time='"'=$E(tWork,1,$L(" Time='")) Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to find Time attribute in '"_tLine_"'")  Quit
				Set tTime=tVal, $E(tWork,1,$L(tName)+$L(tVal)+2)=""
				Set tName=$P(tWork,"'",1), tVal=$P(tWork,"'",2)
			} Else { Set (tStatus,tTime)="" }

			/* Used to indicate if banking a body and only banked header previously by source */
			Set tExistingHeaderObject = 0

			If $$$AND(tFlags,$$$eMsgBankHeader) { ; Header XML
				Do { Set $ZT="TrapHeader"
					Do ..%HeaderStream.Clear()
					If '..readUntil(pInput,..%HeaderStream,"</MessageHeader>",.tSC) {
						 Set:$$$ISOK(tSC) tSC=$$$ERROR($$$EnsErrGeneral,"Header XML not found")
					} Quit:$$$ISERR(tSC)
					Set tReader=##class(%XML.Reader).%New()  $$$ASSERT($IsObject(tReader))
					Set tSC=tReader.OpenStream(..%HeaderStream)  Quit:$$$ISERR(tSC)
					Do tReader.Correlate("MessageHeader","Ens.Enterprise.MsgBank.MessageHeader")
					Set tFound = tReader.Next(.tHeader,.tSC)  Quit:$$$ISERR(tSC)
					If 'tFound||'$IsObject(tHeader) Do pInput.Rewind() Set tSC=$$$ERROR($$$EnsErrNoObjFromStream,"MessageHeader","Ens.Enterprise.MsgBank.MessageHeader",pInput.Read(1000))  Quit
					Set tHeader.ClientBodyClassName=tHeader.MessageBodyClassName, tHeader.MessageBodyClassName="", tHeader.ClientBodyId=tHeader.MessageBodyId, tHeader.MessageBodyId=""
					//Set tSource=$Case(tSrc,0:"", 1:tHeader.SourceConfigName, 2:tHeader.TargetConfigName, 3:"?")
					Set tFullId=..%NodeId_tHdrId
					Quit
TrapHeader			Set tSC=$$$SystemError
				} While 0
				If $$$ISERR(tSC) Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to parse header: "_$$$StatusDisplayString(tSC))
			} ElseIf ""'=tStatus {
				Set tFullId=..%NodeId_tHdrId
				&sql(Update Ens_Enterprise_MsgBank.MessageHeader Set Status=:tStatus,TimeProcessed=:tTime Where ID=:tFullId)
				If SQLCODE {
					Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to store Status "_tStatus_" into header "_..%NodeId_":"_tHdrId_", SQLCODE="_SQLCODE)
				} ElseIf $$$AND(tFlags,$$$eMsgBankBody) {
					/* If banking body then we need to see if can get the header
						This can happen if source host only banks headers and a target banks bodies.
						If header does not exist then tHeader will be null oref and still obtain error.
					*/
					Set tHeader = ##class(Ens.Enterprise.MsgBank.MessageHeader).%OpenId(tFullId,,.tHdrSC)
					If $$$ISOK(tHdrSC) && $IsObject(tHeader) Set tExistingHeaderObject = 1
				}
			}

			If $$$AND(tFlags,$$$eMsgBankBody) { ; Body
				Do { Set $ZT="TrapBody", tSC1=$$$OK
					If " BodyType="'=tName Set tSC1=$$$ERROR($$$EnsErrGeneral,"Couldn't find BodyType attribute in "_tLine)  Quit
					Set tBodyType=tVal, $E(tWork,1,$L(tName)+$L(tVal)+2)=""
					Set tName=$P(tWork,"'",1), tVal=$P(tWork,"'",2)

					If " BodyClass="'=tName Set tSC1=$$$ERROR($$$EnsErrGeneral,"Couldn't find BodyClass attribute in "_tLine)  Quit
					Set tBodyClass=tVal, $E(tWork,1,$L(tName)+$L(tVal)+2)=""
					Set tName=$P(tWork,"'",1), tVal=$P(tWork,"'",2)

					If " BodyId="'=tName Set tSC1=$$$ERROR($$$EnsErrGeneral,"Couldn't find BodyId attribute in "_tLine)  Quit
					Set tBodyId=tVal, $E(tWork,1,$L(tName)+$L(tVal)+2)=""
					Set tName=$P(tWork,"'",1), tVal=$P(tWork,"'",2)

					If tBodyType'="Empty" {
						Do ..%HeaderStream.Clear()
						If '..readUntil(pInput,..%HeaderStream,"><![CDATA[",.tSC1) {
							 Set:$$$ISOK(tSC1) tSC1=$$$ERROR($$$EnsErrGeneral,"Body CData not found")
						} Quit:$$$ISERR(tSC1)
						Set tWork=..%HeaderStream.Read()
						If tWork'["<"_tBodyType Set tSC1=$$$ERROR($$$EnsErrGeneral,"Couldn't find body data element '<"_tBodyType_"' in "_tWork)  Quit
						Do ..%HeaderStream.Clear()

						If tBodyType="VDoc" {
							Set tStream=##class(%Stream.GlobalCharacter).%New()
							If '..readUntil(pInput,tStream,"]]></"_tBodyType_">",.tSC1,0) {
								 Set:$$$ISOK(tSC1) tSC1=$$$ERROR($$$EnsErrGeneral,"Body CData close not found")
							} Quit:$$$ISERR(tSC1)
							Do tStream.Rewind()
							If (tBodyClass="EnsLib.HL7.Message") {
								Set tBody=$classmethod(tBodyClass,"ImportFromLibraryStream",tStream,.tSC1,"class||EnsLib.HL7.Service.TCPService")
							} ElseIf (tBodyClass="EnsLib.EDI.ASTM.Document") {
								Set tStream.LineTerminator = $C(10)
								Set tBody=$classmethod(tBodyClass,"ImportFromLibraryStream",tStream,.tSC1)
							} Else {
								Set tBody=$classmethod(tBodyClass,"ImportFromLibraryStream",tStream,.tSC1)
							}
							If $$$ISERR(tSC1) Quit
							Set tBody.DocType=$P(tWork,"'",2)
						}
						ElseIf tBodyType="CData" { ; stream container
							Set tType=$P(tWork,"'",2)
							Set tBody=##class(Ens.StreamContainer).%New($S("C"=$E(tType,2):##class(%Stream.GlobalCharacter).%New(), 1:##class(%Stream.GlobalBinary).%New()))
							#;tWork is "<CData Type='"_tBody.Type_"' Size='"_tBody.Stream.Size_"' Filename='"_$ZCVT(tBody.Stream.OriginalFilename,"O","XML")_"'><![CDATA["
							Try {Set tBody.OriginalFilename=$ZCVT($P(tWork,"'",6),"I","XML")} Catch {}
							If '..readUntil(pInput,tBody.Stream,"]]></"_tBodyType_">",.tSC1,0) {
								 Set:$$$ISOK(tSC1) tSC1=$$$ERROR($$$EnsErrGeneral,"Body CData close not found")
							} Quit:$$$ISERR(tSC1)
						} ElseIf tBodyType="SData" { ; stream
							If '$IsObject(tHeader) Set tSC1=$$$ERROR($$$EnsErrGeneral,"Can't bank "_tBodyClass_" body if header is not also banked (flags="_tFlags_")")  Quit
							Set tBody=$S(tBodyClass["Character":##class(%Stream.GlobalCharacter).%New(), 1:##class(%Stream.GlobalBinary).%New())
							If '..readUntil(pInput,tBody,"]]></"_tBodyType_">",.tSC1,0) {
								 Set:$$$ISOK(tSC1) tSC1=$$$ERROR($$$EnsErrGeneral,"Body CData close not found")
							} Quit:$$$ISERR(tSC1)
						} ElseIf tBodyType="XML" { ; xml stream
							If '$IsObject(tHeader) Set tSC1=$$$ERROR($$$EnsErrGeneral,"Can't bank XML body if header is not also banked (flags="_tFlags_")")  Quit
							Set tBody=##class(%Stream.GlobalCharacter).%New()
							If '..readUntil(pInput,tBody,"]]></"_tBodyType_">",.tSC1,0) {
								 Set:$$$ISOK(tSC1) tSC1=$$$ERROR($$$EnsErrGeneral,"Body CData close not found")
							} Quit:$$$ISERR(tSC1)
						} Else {
							Set tSC1=$$$ERROR($$$EnsErrGeneral,"Unexpected body type '"_tBodyType_"' encountered for header "_..%NodeId_":"_tHdrId)  Quit
						}
						Set tSC1=tBody.%Save()  Quit:$$$ISERR(tSC1)
						Set tBankBodyId=tBody.%Id()
						Set:$IsObject(tHeader) tHeader.MessageBodyId=tBankBodyId, tHeader.MessageBodyClassName=$classname(tBody)
					}
					Quit
TrapBody			Set tSC1=$$$SystemError
				} While 0
				If $$$ISERR(tSC1) $$$LOGERROR("Failed to save body: "_$$$StatusDisplayString(tSC1))  Set tSC=$$$ADDSC(tSC,tSC1)
			}

			If $$$AND(tFlags,$$$eMsgBankSearchTable) { ; SearchTable
				Do { Set $ZT="TrapSearch", tSC1=$$$OK
					If " SearchRows="'=tName Set tSC1=$$$ERROR($$$EnsErrGeneral,"Couldn't find SearchRows attribute in "_tLine)  Quit
					Set tSearchRows=tVal, $E(tWork,1,$L(tName)+$L(tVal)+2)=""
					If ""=tBankBodyId {
						If ""'=tFullId {
							&sql(Select MessageBodyId,ClientBodyId Into :tBankBodyId,:tBodyId From Ens_Enterprise_MsgBank.MessageHeader Where Id = :tFullId)
							Set:SQLCODE tBankBodyId=""
						}
						If ""=tBankBodyId Set tSC1=$$$ERROR($$$EnsErrGeneral,"Can't bank SearchTable entry if message body is not also banked (flags="_tFlags_")")  Quit
					}
					Do ..%HeaderStream.Clear()
					If '..readUntil(pInput,..%HeaderStream,"<Row ",.tSC1) {
						 Set:$$$ISOK(tSC1) tSC1=$$$ERROR($$$EnsErrGeneral,"SearchTable Row element not found")
					} Quit:$$$ISERR(tSC1)
					Set tWork=..%HeaderStream.Read()
					If tWork'["<SearchTable Class='" Set tSC1=$$$ERROR($$$EnsErrGeneral,"Couldn't find element '<SearchTable Class=' in "_tWork)  Quit
					Set $P(tWork,"<SearchTable ",1)=""
					Set tName=$P(tWork,"'",1), tVal=$P(tWork,"'",2)
					Set tSearchClass=tVal, $E(tWork,1,$L(tName)+$L(tVal)+2)=""
					Set tSearchSupertable=$G(..%SearchTableMap(tSearchClass))
					Set:""=tSearchSupertable tSearchSupertable=$$$ClassSQLTable(##class(Ens.VDoc.SearchTableGenerator).GetExtentSuperclass(tSearchClass))
					If ""=tSearchSupertable Set tSC1=$$$ERROR($$$EnsErrGeneral,"Extent table not found for SearchTable class "_tSearchClass)  Quit
					Set ..%SearchTableMap(tSearchClass)=tSearchSupertable

					$$$catTRACE("archive","Archiving "_tSearchRows_" "_tSearchSupertable_" entries for client "_..%NodeId_" body "_tBodyId_" banked as "_tBankBodyId)
					For iRow=1:1 {
						Do ..%HeaderStream.Clear()
						If '..readUntil(pInput,..%HeaderStream,"]]></Row>",.tSC1) {
							 Set:$$$ISOK(tSC1) tSC1=$$$ERROR($$$EnsErrGeneral,"SearchTable Row CData end not found")
						} Quit:$$$ISERR(tSC1)
						Set tWork=tWork_..%HeaderStream.Read()

						Set tName=$P(tWork,"'",1), tVal=$P(tWork,"'",2)
						If tName'[" PropId=" Set tSC1=$$$ERROR($$$EnsErrGeneral,"Couldn't find SearchTable PropId attribute in "_tWork)  Quit
						Set tPropId=tVal, $E(tWork,1,$L(tName)+$L(tVal)+2)=""

						Set pos=$F(tWork,"<![CDATA["), tVal=$E(tWork,pos,*-$L("]]></Row>"))

						Continue:tPropId=0

						Set tUpdateSearchSQL="INSERT INTO "_tSearchSupertable_" (PropId,PropValue,DocId) VALUES(?,?,?)"
						If tUpdateSearchSQL'=..%lastSearchSQL {
							Do ..%rsSearchInsert.Close()
							Set tSC1=..%rsSearchInsert.Prepare(tUpdateSearchSQL)  Quit:$$$ISERR(tSC1)
							Set ..%lastSearchSQL=tUpdateSearchSQL
						}
						Set tSC1=..%rsSearchInsert.Execute(tPropId,tVal,tBankBodyId)  Set:$$$ISERR(tSC1)&&$$$StatusEquals(tSC1,$$$SQLCode)&&($$$StatusText(tSC1)["SQLCODE: -119") tSC1=$$$OK  Quit:$$$ISERR(tSC1)
						Set tWork=pInput.Read($L("..</SearchTable>"))
						Quit:tWork'["<Row "
					} Quit:$$$ISERR(tSC1)
					If iRow>tSearchRows $$$catTRACE("archive","More search table rows found than expected.  Archived "_iRow_" "_tSearchSupertable_" entries for client "_..%NodeId_" body "_tBodyId_" banked as "_tBankBodyId)
					If tWork'["</SearchTable" Set tSC1=$$$ERROR($$$EnsErrGeneral,"SearchTable end element not found in '"_tWork_"'")  Quit
					Set tWork=$P(tWork,"</SearchTable",2,99)
					Quit
TrapSearch			Set tSC1=$$$SystemError
				} While 0
				If $$$ISERR(tSC1) Set tSC1=$$$ERROR($$$EnsErrGeneral,"Failed to save SearchTable entries: "_$$$StatusDisplayString(tSC1))  Set tSC=$$$ADDSC(tSC,tSC1)
			}
			If $IsObject(tHeader) {
				/* do not want to update an existing one we opened */
				If '(tExistingHeaderObject) {
					Set tHeader.ID=tFullId
					If tHeader.%ExistsId(tFullId) {
						Set tExisting=tHeader.%OpenId(tFullId)
						Do tExisting.copyFrom(tHeader)
						Set tHeader=tExisting
					}
					Set:""'=tHeader.SessionId tHeader.SessionId=..%NodeId_tHeader.SessionId
					Set:""'=tHeader.CorrespondingMessageId tHeader.CorrespondingMessageId=..%NodeId_tHeader.CorrespondingMessageId
				} 
				Set tSC1=tHeader.%Save()
				If $$$ISERR(tSC1) Set tSC1=$$$ERROR($$$EnsErrGeneral,"Failed to store message bank header: "_$$$StatusDisplayString(tSC1))  Set tSC=$$$ADDSC(tSC,tSC1)
			}
		}
		#; Get event log events if present
		//<LogEvents>
		 //<LogEvent><SourceClass>EnsLib.TCP.CountedOutboundAdapter</SourceClass><SourceMethod>WriteCountedStream</SourceMethod><Text>Converted(10012) characters to (10012) output bytes using charset 'UTF-8', table 'UTF8'</Text><Type>5</Type><TimeLogged>2009-06-12 16:40:52.265</TimeLogged><ConfigName>Ens.Enterprise.MsgBankOperation</ConfigName><TraceCat>protocol</TraceCat><Job>7888</Job><MessageId>73205</MessageId></LogEvent>
		Set tWork=pInput.Read($L("..<LogEvents>"))  While $Case($E(tWork),$C(0):1," ":1,$C(9):1,$C(13):1,$C(10):1,">":1,:0) { Set $E(tWork)="" }
		If "<LogEvents>"=$E(tWork,1,$L("<LogEvents>")) {
			Set $E(tWork,1,$L("<LogEvents>"))=""
			Set $ZT="TrapLog",tSC1=$$$OK  While 1 {
				Set:$L(tWork)<$L("..<Log Len='32000'") tWork=tWork_pInput.Read($L("..<Log Len='32000'")-$L(tWork))  While $Case($E(tWork),$C(0):1," ":1,$C(9):1,$C(13):1,$C(10):1,">":1,:0) { Set $E(tWork)="" }
				Quit:"</LogEvents>"=$E(tWork,1,$L("</LogEvents>"))

				If "<Log Len='"'=$E(tWork,1,$L("<Log Len='")) Set tSC1=$$$ERROR($$$EnsErrGeneral,"Failed to find <Log> Len attribute in '"_tWork_"'")  Quit
				Set tLen=$P(tWork,"'",2)  If tLen'=+tLen Set tSC1=$$$ERROR($$$EnsErrGeneral,"<Log> Len attribute not a number in '"_tWork_"'")  Quit
				Set tFullLen=$L("<Log Len='' Id=''></Log>")+$L(tLen)+tLen ; note - Id len is already in
				Set:tFullLen>$L(tWork) tWork=tWork_pInput.Read(tFullLen-$L(tWork))
				If " Id="'=$P(tWork,"'",3) Set tSC1=$$$ERROR($$$EnsErrGeneral,"Failed to find <Log> Id attribute in '"_tWork_"'")  Quit
				Set tEvtId=$P(tWork,"'",4)  If tLen'=+tLen Set tSC1=$$$ERROR($$$EnsErrGeneral,"<Log> Id attribute not a number in '"_tWork_"'")  Quit
				//Set $E(tWork,1,$L("<Log Len='' Id=''>")+$L(tLen)+$L(tEvtId))=""
				Set:'$$$IsdefObject(tReader) tReader=##class(%XML.Reader).%New()  $$$ASSERT($IsObject(tReader))
				Try {
					Set tTR = 0, tSC1 = tReader.OpenString(tWork)
					If $$$ISERR(tSC1) {
						Set tTR = 1, tWork = $TR(tWork,$C(0,1,2,3,4,5,6,7,8,11,12,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31),"?????????????????????????????")
						Set tSC1 = tReader.OpenString(tWork)
					}
					If (tSC1) {
						Do tReader.Correlate("LogEvent","Ens.Enterprise.MsgBank.Log")
						Set tFound = tReader.Next(.tEvent,.tSC1)
					}
				} Catch e {
					Set tSC1 = $$$SystemError
				}
				If $$$ISERR(tSC1)||'tFound||'$IsObject(tEvent) {
					Set tEvent = ##class(Ens.Enterprise.MsgBank.Log).%New()
					Set tEvent.Text = "Failed to store Event Log entry: "_tWork_$S($$$ISERR(tSC1):" [Due to error"_$$$StatusDisplayString(tSC1)_"]",1:"")
					Set tEvent.Type = $$$eLogTypeError
					Set tSC1 = $$$OK
				} ElseIf tTR {
					Set tEvent.Text = tEvent.Text_" [replaced non XML chars with ?]"
				}
				Set tWork=$E(tWork,tFullLen+1,*)
				Set tFullEventId=..%NodeId_tEvtId

				Set tEvent.ID=tFullEventId
				Set:""'=tEvent.SessionId tEvent.SessionId=..%NodeId_tEvent.SessionId
				Set tSC2=tEvent.%Save()
				If $$$ISERR(tSC2) {
					If $system.Status.Equals(tSC2,$$$IDKeyNotUnique) {
						Set tOldEvent = ##class(Ens.Enterprise.MsgBank.Log).%OpenId(tFullEventId)
						If $IsObject(tOldEvent) {
							Set tSameEvent = 1
							For tProp = "SourceClass","SourceMethod","Text","Type","TimeLogged","SessionId","ConfigName","TraceCat","Job","MessageId" {
								If $property(tOldEvent,tProp) '= $property(tEvent,tProp) Set tSameEvent = 0 Quit
							}
							#; Check Stack separately
							If tSameEvent {
								If tOldEvent.Stack.Count() '= tEvent.Stack.Count() { Set tSameEvent = 0 }
								Else {
									For tEvtTmp=tEvent.Stack.Count():-1:1 {
										If tOldEvent.Stack.GetAt(tEvtTmp) '= tEvent.Stack.GetAt(tEvtTmp) Set tSameEvent = 0 Quit
									}
								}
							}
							#; If it's the same event, this is not an error, move on to the next event
							If tSameEvent Continue
						}
					}
					Set tSC2=$$$ERROR($$$EnsErrGeneral,"Failed to store message bank Event Log entry: "_$$$StatusDisplayString(tSC2)) Set tSC1=$$$ADDSC(tSC1,tSC2) Quit
				}
				Continue
TrapLog			Set tSC1=$$$SystemError
				If $$$ISERR(tSC1) Set tSC1=$$$ERROR($$$EnsErrGeneral,"Failed to parse Event Log entry: "_$$$StatusDisplayString(tSC1))
				Quit
			}
			If $$$ISERR(tSC1) Set tSC1=$$$ERROR($$$EnsErrGeneral,"Failed to store message bank header: "_$$$StatusDisplayString(tSC1))  Set tSC=$$$ADDSC(tSC,tSC1)
		}
	} While 0 }
	If $$$ISOK(tSC)&&$$$AND(tFlags,$$$eMsgBankBody) {
		If ""'=..BankHelperClass {
			TRY {		
				Set tSC=$classmethod(..BankHelperClass,"OnBankMsg",tHeader,tFullId,tBody,tBankBodyId,$this)
			} CATCH errobj { Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to invoke BankHelperClass method "_..BankHelperClass_".OnBankMsg() for header "_tHeader_" / "_tFullId_", body "_tBody_" / "_tBankBodyId_" : "_errobj.AsSystemError()) }
		}
	}
	If $$$ISOK(tSC) {
		$$$SyncCommitNow
		Set pOutput="<REPLY Flags='"_tFlags_
					"' ClientHdrId='"_tHdrId_
					"' ClientEvtId='"_tEvtId_
					"'/>"
	} Else {
		$$$LOGSTATUS(tSC)
		Set pOutput="<ERROR Source='"_$$$CurrentClass_"'>"_$C(13,10)_
			 $ZCVT($$$StatusDisplayString(tSC),"O","XML")_$C(13,10)_
			"</ERROR>"_$C(13,10)
	}
	Quit $$$OK
}

/// Read until target found in pStreamIn, copying all data read to pStreamOut
ClassMethod readUntil(pStreamIn, pStreamOut, pTarget, ByRef pSC, pIncludeTarget = 1) As %Boolean [ Internal ]
{
	#; Read in chunks using last char of pTarget as terminator
	Set pSC=$$$OK,tFound=0
	Set tOldTerm=pStreamIn.LineTerminator
	Set tC=$E(pTarget,*)
	Set pStreamIn.LineTerminator=tC
	Set tLine="" While $$$ISOK(pSC) && 'tFound && 'pStreamIn.AtEnd {
		Set tLen=32000-$L(pTarget)
		Set tLine=tLine_pStreamIn.ReadLine(.tLen,.pSC,.tEOL)
		Set:tEOL tLine=tLine_tC
		If tEOL && ($L(tLine)>=$L(pTarget)) && (pTarget=$E(tLine,*+1-$L(pTarget),*)) {
			Set tFound=1
			Do pStreamOut.Write($E(tLine,1,$L(tLine)-$L(pTarget))) Set $E(tLine,1,$L(tLine)-$L(pTarget))=""
		} Else {
			If $L(tLine)>$L(pTarget) Do pStreamOut.Write($E(tLine,1,$L(tLine)+1-$L(pTarget))) Set $E(tLine,1,$L(tLine)+1-$L(pTarget))=""
		}
	}
	Do:'tFound||pIncludeTarget pStreamOut.Write(tLine)
	Set pStreamIn.LineTerminator=tOldTerm
	Do:'tFound pStreamIn.Rewind()
	Quit tFound
}

ClassMethod copyPart(target, source, pSize) As %Status
{
	Quit:source=$$$NULLOREF $$$ERR($$$OrefInvalid)
	
	Set tSC=$$$OK, nLeft=pSize, nDone=0
	While 'source.AtEnd&&(nDone<pSize) { Set buf=source.Read(nLeft,.tSC)  Quit:$$$ISERR(tSC)  Set tSC=target.Write(buf)  Quit:$$$ISERR(tSC)  Set nDone=nDone+$L(buf), nLeft=pSize-nDone }
	Quit tSC
}

/// This method is for use on debugging systems only!
/// It will purge all MsgBank EventLog and MessageHeader objects and remove all configured clients and all recorded client nodes.
/// It will only function when the MsgBank Production is not running.
ClassMethod CleanMsgBank() As %Status [ Internal ]
{
	Set tSC=##class(Ens.Director).GetProductionStatus(.tProductionName,.tState)  Quit:$$$ISERR(tSC) tSC
	Set:""=tProductionName tProductionName=$G(^Ens.Configuration("csp","LastProduction"))
	Set $ZT="SubclassTrap"
	GoTo:$classmethod(tProductionName,"%Extends","Ens.Enterprise.MsgBank.Production") SubclassDone
SubclassTrap
	Quit $$$EnsError($$$EnsErrGeneral,"Cannot clean MsgBank because '"_tProductionName_"' is not a MsgBank Production")
SubclassDone  Set $ZT=""
	Quit:tState=$$$eProductionStateRunning&&$$$ISOK(tSC) $$$EnsError($$$EnsErrGeneral,"Cannot clean MsgBank while Production '"_tProductionName_"' is running")
	Set tSC=##class(Ens.Enterprise.MsgBank.MessageHeader).Purge(,0,0,1)  Quit:$$$ISERR(tSC) tSC
	Set tSC=##class(Ens.Enterprise.MsgBank.Log).Purge(,0)  Quit:$$$ISERR(tSC) tSC
	Set tSC=##class(Ens.Enterprise.MsgBank.Node).%DeleteExtent()  Quit:$$$ISERR(tSC) tSC
	Set tSC=##class(Ens.Enterprise.MonitorClient).%DeleteExtent()  Quit:$$$ISERR(tSC) tSC
	Kill ^Ens.MsgBankSvr
	//Kill ^Ens.MsgBank ; will not be defined if only the MsgBank production runs in this namespace
	//Kill ^Ens.MsgBank.Banked ; will not be defined if only the MsgBank production runs in this namespace
	Quit $$$OK
}

/// This user callback method is called from %OnClose()
Method OnTearDown() As %Status
{
	#;No $$$EnsJobLocal("MsgBank","Candidate") if not job per connection
	If $G($$$EnsMsgBankConnections("Candidates",$G($$$EnsJobLocal("MsgBank","Candidate"),"x")),0)>0 {
		If $I($$$EnsMsgBankConnections("Candidates",$G($$$EnsJobLocal("MsgBank","Candidate"),"x")),-1) {}
		Kill $$$EnsJobLocal("MsgBank","Candidate")
	}
	Quit ##super()
}

}
