/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Util.Auditing [ ClassType = "", System = 4 ]
{

Parameter DOMAIN = "Ensemble";

/// Generates an audit event for viewing the contents of a message.
/// The first argument is the source for this event, that is, where the message was viewed from.
/// Source may be for example "EDI/HL7 Manager" or "Message Browser".
/// The second argument is the message header ID (if the viewing is via Header Id).
/// If the message body class and message body ID are known they can be passed as the third and fourth arguments,
/// otherwise this information is pulled from the message header if it is passed in otherwise an error is returned.<br>
/// How to use:  [Set status = ] $$$auditViewMessage([%source], %headerId [,%bodyClass, %bodyId]) 
ClassMethod AuditViewMessage(pSource As %String = "", pHeaderId As %String = "", pBodyClass As %String = "", pBodyId As %String = "") As %Status
{
	If pHeaderId="" && ((pBodyClass="") || (pBodyId="")) Quit $$$ERROR($$$EnsErrGeneral, $$$Text("Missing message body identification"))

	Set tSC = $$$OK

	If (pBodyClass="") || (pBodyId="") {
		// Get these from the message header
		Try {
			Set tHdr = ##class(Ens.MessageHeader).%OpenId(pHeaderId)
			If $IsObject(tHdr) {
				Set pBodyClass = tHdr.MessageBodyClassName, pBodyId = tHdr.MessageBodyId
			}
			Else {
				Set tSC = $$$ERROR($$$EnsErrGeneral, $$$FormatText($$$Text("Can't open message header ID '%1'"), pHeaderId))
			}
		}
		Catch {
			Set tSC = $$$SystemError
		}
	}
	If $$$ISERR(tSC) Quit tSC

	Set EventData = $$$FormatText($$$Text("Message identification: MessageHeaderId = %1, MessageBodyClassName = %2, MessageBodyId = %3"), pHeaderId, pBodyClass, pBodyId)

	Do ..addToEventData(.EventData, pHeaderId, pBodyClass, pBodyId)

	Set Description = $S(pSource'="":pSource, 1:$$$Text("Source not provided"))
	Try {
		Set e = $$$auditViewMessageContents
		Do $system.Security.Audit($P(e,"/",1), $P(e,"/",2), $P(e,"/",3), EventData, Description)
	}
	Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

/// For a given message body class and ID, return the first 10K of message body data and the
/// message description composed of the message header id plus the message body class and id).
ClassMethod GetMessageContents(pMsgClass As %String, pMsgId As %String, Output pMsgData As %String) As %Status
{
	If $G(pMsgClass)="" Quit $$$ERROR($$$EnsErrGeneral, "Missing message body class")
	If $G(pMsgId)="" Quit $$$ERROR($$$EnsErrGeneral, "Missing message body ID")

	Set pMsgData = ""
	Set tSC = $$$OK
	Set oMsg = $$$NULLOREF
	Set %objlasterror = ""

	Try {
		Set oMsg = $ClassMethod(pMsgClass,"%OpenId",pMsgId)
	}
	Catch {
		Set oMsg = $$$NULLOREF
	}

	If $IsObject(oMsg), %objlasterror=""
	Else  Quit $$$ERROR($$$EnsErrGeneral, "Can't open message object ID = '"_pMsgId_"' class '"_pMsgClass_"'")

	If ##class(Ens.VDoc.Utils).IsVirtualDocument(pMsgClass) {
		Set pMsgData = $E(oMsg.RawContent,1,10000)
	}
	ElseIf oMsg.%Extends("%XML.Adaptor") {
		Set tSC = oMsg.XMLExportToStream(.tStream)
		If tSC, tStream.%IsA("%Stream.Object") {
			Do tStream.Rewind()
			Set pMsgData = tStream.Read(10000)
		}
		Else {
			Set pMsgData = "The following error occurred while retrieving the message contents for auditing: "_$system.Status.GetOneErrorText(tSC)
		}
		Do tStream.Clear()
		Set tStream = ""
	}
	Else {
 		Set pMsgData = "There is no content viewer defined for this message type"
	}
	Quit tSC
}

/// Generates an audit event for resending a message.
/// The first argument is the message header ID.  The message body class and message body ID 
/// will be pulled from the message header. <br>
/// How to use:  [Set status = ] $$$auditResendMessage(%headerId) 
ClassMethod AuditResendMessage(pHeaderId As %String = "") As %Status
{
	If pHeaderId="" Quit $$$ERROR($$$EnsErrGeneral, $$$Text("Missing message header ID"))

	Set tSC = $$$OK

	// Get the Message body class and Id from the header
	Try {
		Set tHdr = ##class(Ens.MessageHeader).%OpenId(pHeaderId)
		If $IsObject(tHdr) {
			Set pBodyClass = tHdr.MessageBodyClassName, pBodyId = tHdr.MessageBodyId
		}
		Else {
			Set tSC = $$$ERROR($$$EnsErrGeneral, $$$FormatText($$$Text("Can't open message header ID '%1'"), pHeaderId))
		}
	}
	Catch {
		Set tSC = $$$SystemError
	}
	If $$$ISERR(tSC) Quit tSC

	// If this was called from a CSP page, find the page name:
	Set tSource = ""
	If $IsObject($Get(%request)) {
		Set tSource = %request.PageName
		// If this was a hyperevent, find the real page name from the HTTP Referer
		If tSource = "%CSP.Broker.cls" {
			Set tSource = $Piece($Piece($Get(%request.CgiEnvs("HTTP_REFERER")),"/",*),"?",1)
		}
	}
	
	Set EventData = ""
	If tSource'="" {
		Set EventData = $$$FormatText($$$Text("Page: %1"),tSource) _ $C(13,10)
	}
	Set EventData = EventData _ $$$FormatText($$$Text("Message identification: MessageHeaderId = %1, MessageBodyClassName = %2, MessageBodyId = %3"), pHeaderId, pBodyClass, pBodyId)
	Do ..addToEventData(.EventData, pHeaderId, pBodyClass, pBodyId)
		
	Set Description = $$$Text("Resend Message")
	
	Try {
		Set e = $$$auditResendMessage
		Do $system.Security.Audit($P(e,"/",1), $P(e,"/",2), $P(e,"/",3), EventData, Description)
	}
	Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

/// Generates an audit event for starting or stopping a Production.
/// The first argument is the Production class.
/// The second argument is the action which can be either "start" or "stop".
/// How to use:  [Set status = ] $$$auditStartStopProduction(%prod, "start" | "stop")
ClassMethod AuditStartStopProduction(pProduction As %String = "", pAction As %String = "") As %Status
{
	If pProduction="" Quit $$$ERROR($$$EnsErrGeneral, $$$Text("Missing Production class name"))
	If pAction="" Quit $$$ERROR($$$EnsErrGeneral, $$$Text("Missing action"))

	Set tSC = $$$OK
	Set EventData = pAction
	Set Description = pProduction
	Try {
		Set e = $$$auditStartStopProduction
		Do $system.Security.Audit($P(e,"/",1), $P(e,"/",2), $P(e,"/",3), EventData, Description)
	}
	Catch {
		Set tSC = $$$SystemError
	}

	Quit tSC
}

/// Generates an audit event for modifications made to a Production configuration.
/// The first argument is the Production class.
/// The second argument is the configuration item name.
/// The third argument is a string and/or an array of actions. <br>
/// How to use:  [Set status = ] $$$auditStartStopProduction(%prod, %item, .%actions)
ClassMethod AuditModifyProductionConfig(pProduction As %String = "", pItem As %String = "", ByRef pActions As %String) As %Status
{
	If pProduction="" Quit $$$ERROR($$$EnsErrGeneral, $$$Text("Missing Production class name"))
	If '$D(pActions) Quit $$$ERROR($$$EnsErrGeneral, $$$Text("Missing actions"))

	Set tSC = $$$OK
	Set EventData = $G(pActions)
	Set tAction = ""
	For {
		Set tAction = $O(pActions(tAction))
		Quit:tAction=""
		Set:EventData'="" EventData = EventData_", "
		Set EventData = EventData_tAction
		Set:$G(pActions(tAction))'="" EventData = EventData_":"_pActions(tAction)
	}
	Set Description = $S(pItem'="":"item "_pItem_" of ",1:"")_pProduction
	Try {
		Set e = $$$auditModifyProductionConfig
		Do $system.Security.Audit($P(e,"/",1), $P(e,"/",2), $P(e,"/",3), EventData, Description)
	}
	Catch {
		Set tSC = $$$SystemError
	}

	Quit tSC
}

/// Generates an audit event for modifications made to a System Default Setting.
/// The first argument is the Id of the Default Setting, or the Production name if the action is "DELETE ALL".
/// The second argument is an array of the modified fields.
/// The third argument is action: "INSERT", "UPDATE", "DELETE" or "DELETE ALL".
/// How to use:  [Set status = ] $$$AuditModifyDefaultSetting(%id, .%fields, %action)
ClassMethod AuditModifyDefaultSetting(pId As %String, pEventData As %String, pAction As %String) As %Status
{
	If $Length(pId,"||")'=4,pAction'="DELETE ALL" Quit $$$ERROR($$$EnsErrGeneral, $$$Text("Invalid id"))
	If ",INSERT,UPDATE,DELETE,DELETE ALL,"'[(","_pAction_",") Quit $$$ERROR($$$EnsErrGeneral, $$$Text("Invalid action"))
	
	Set tSC = $$$OK
	Set Description = $Case(pAction, "INSERT":$$$Text("Create System Default Setting:"), 
					  				 "UPDATE":$$$Text("Modify System Default Setting"), 
					  				 "DELETE":$$$Text("Delete System Default Setting"),
		  			          				 :$$$Text("Bulk Delete System Default Settings"))
												          
	If pAction="DELETE ALL" {
		if pId="" {
			Set EventData = $$$Text("Delete all System Default Settings")
		}
		Else {
			Set EventData = $$$FormatText($$$Text("Delete all System Default Settings for Production: %1"),pId)	
		}
	} Else {
		Set NL = $C(13,10)
		Set EventData = Description _ NL _ NL 
		Set EventData = EventData _ "ProductionName: " _ $Piece(pId,"||",1) _ NL
		Set EventData = EventData _ "ItemName: " _ $Piece(pId,"||",2) _ NL
		Set EventData = EventData _ "HostClassName: " _ $Piece(pId,"||",3) _ NL
		Set EventData = EventData _ "SettingName: " _ $Piece(pId,"||",4) _ NL _ NL
		If $D(pEventData) {
			Set tField = ""
			For {
				Set tField = $O(pEventData(tField),1,tValue)
				Quit:tField=""
				
				If $Data(pEventData(tField,1),tOld)#2 {
					Set EventData = EventData _ $$$FormatText($$$Text("%1 modified:"),tField) _ NL
					Set EventData = EventData _ $$$FormatText($$$Text("New value: %1"),tValue) _ NL
					Set EventData = EventData _ $$$FormatText($$$Text("Old value: %1"),tOld) _ NL _ NL
				} 
				Else {
					Set EventData = EventData _ tField _": "_tValue _ NL
				}
			}
		}
	}
	Try {
		Set e = $$$auditModifyDefaultSetting
		Do $system.Security.Audit($P(e,"/",1), $P(e,"/",2), $P(e,"/",3), EventData, Description)
	}
	Catch {
		Set tSC = $$$SystemError
	}
	
	Quit tSC
}

/// Generates an audit event for modifications made to a Schema.
/// The first argument is the Schema name.
/// The second argument is a string and/or an array of actions.
/// How to use:  [Set status = ] $$$auditStartStopProduction(%schema, .%actions)
ClassMethod AuditModifySchema(pSchema As %String = "", ByRef pActions As %String) As %Status
{
	If pSchema="" Quit $$$ERROR($$$EnsErrGeneral, $$$Text("Missing Schema name"))
	If '$D(pActions) Quit $$$ERROR($$$EnsErrGeneral, $$$Text("Missing actions"))

	Set tSC = $$$OK
	Set EventData = $G(pActions)
	Set tAction = ""
	For {
		Set tAction = $O(pActions(tAction))
		Quit:tAction=""
		Set:EventData'="" EventData = EventData_", "
		Set EventData = EventData_tAction
		Set:$G(pActions(tAction))'="" EventData = EventData_":"_pActions(tAction)
	}
	Set Description = pSchema
	Try {
		Set e = $$$auditModifySchema
		Do $system.Security.Audit($P(e,"/",1), $P(e,"/",2), $P(e,"/",3), EventData, Description)
	}
	Catch {
		Set tSC = $$$SystemError
	}

	Quit tSC
}

ClassMethod addToEventData(ByRef pEventData, pHeaderId As %String, pBodyClassName As %String, pBodyId As %String)
{
	Try {

		#; This might be the value assigned to header Id, pBodyClassName or body Id
		#dim tNA = $$$Text("N/A")

		#; Obtain message body object 
		#dim status
		#dim bodyAsSource
		#; If pHeaderId is tNA then viewing via the EDI Document viewer - need to identify body classname
		If (pHeaderId=tNA) {
			/*
				pBodyClassName might be tNA or body.Name
				pBodyId might be body id or tNA_text
			*/
			#; Cannot open body
			If $Extract(pBodyId,1,$Length(tNA))=tNA Quit
			#; If the body being viewed is an HL7 then we can proceed - just known pBodyId and the body Name
			Set bodyAsSource = $classmethod("EnsLib.HL7.Message","%OpenId",pBodyId,0,.status)
			If $$$ISERR(status) Quit
			If bodyAsSource.Name '= pBodyClassName Quit

		} Else {

			Set bodyAsSource = $classmethod(pBodyClassName,"%OpenId",pBodyId,0,.status)
			If $$$ISERR(status) Quit

		}

		#; Obtain message header or provide blank. pHeaderId might be empty string, 0 or valid Id
		#dim headerAsAux = ""
		If (pHeaderId'=tNA)&&(+pHeaderId'=0) {
			Set headerAsAux = ##class(Ens.MessageHeader).%OpenId(pHeaderId,0,.status)
		}
		#; If header ID not provided or we get an error opening provide a blank to ensure object for aux parameter
		If '$IsObject(headerAsAux) Set headerAsAux = ##class(Ens.MessageHeader).%New()

		#; Select DTL Class - try to use custom class first
		#dim tDTLClass = "EnsCustom.Util.DTL.Audit.MessageView"
		If '##class(%Dictionary.CompiledClass).%ExistsId("EnsCustom.DTL.Audit.MessageView") || $$$ISERR(##class(Ens.Util.DTL).ValidateDTL(tDTLClass)) {
			Set tDTLClass = "Ens.Util.DTL.Audit.MessageView"
		}

		#dim extraTextAsTarget As Ens.StringContainer
		Set status=$classmethod(tDTLClass,"Transform", bodyAsSource, .extraTextAsTarget, headerAsAux)
		If $$$ISERR(status) Quit

		#;Concatenate
		Set pEventData = pEventData_extraTextAsTarget.StringValue

	} Catch {}
}

}
