/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, Ensemble)

Class Ens.Util.MessageBodyMethods [ Abstract, ClassType = "", System = 4 ]
{

/// To prevent possible <PROTECT> errors for AutoFormGeneration of 
/// custom classes the DOMAIN needs to be not specified.
Parameter DOMAIN;

/// Default indentation for JSON formatter
Parameter JSONINDENT = 2;

/// Used to prevent trying conversion to one or
/// more formats. <br>
/// System code checks for "JSON". <br>
Parameter UNSUPPORTEDFORMATS;

/// This method is called by the Management Portal to determine
/// the content type that will be returned by the <method>%ShowContents</method>
/// method.
/// The return value is a string containing an HTTP content type.
Method %GetContentType() As %String
{
	If (..%Extends("%XML.Adaptor")) {
		Quit "text/xml"
	} ElseIf (..%Extends("%JSON.Adaptor")) {
		Quit "application/json"
	}
	Quit "text/html"
}

/// This method is called by the Management Portal to 
/// display a message-specific content viewer for messages that 
/// extend %XML.Adaptor or %JSON.Adaptor or where JSON 
/// has been requested explicitly.<br>
/// This method displays its content by writing out to the current device. <br>
/// For XML content , non XML characters are suppressed and there is an optional 
/// size limit of output. <br>
/// The content should match the type returned by the 
/// <method>%GetContentType</method> method or in the case of JSON explicitly to
/// %response.ContentType.<br>
/// This method is called from EnsPortal.MessageContents when: <br>
/// <li> class extends both %XML.Adaptor and Ens.Util.MessageBodyMethods </li>
/// <li> class neither extends %XML.Adaptor nor %Stream.Object </li>
/// <li> class extends %JSON.Adaptor and Ens.Util.MessageBodyMethods and 
/// <parameter>UNSUPPORTEDFORMATS</parameter> does not include JSON </li>
/// In all cases the parameter, pZenOutput is passed in as 1.<br>
/// This method can be overridden. <br>
/// This method calls OnShowJSONContents() and OnShowXMLContents()
/// which can also be overridden. <br>
Method %ShowContents(pZenOutput As %Boolean = 0)
{
	Set tSC = $$$OK
	If (%response.ContentType="application/json") {
		#; any Error shown via OnShowJSONContents()
		Do ..OnShowJSONContents(pZenOutput)
	} ElseIf (..%Extends("%XML.Adaptor")) {
		#; any Error shown via OnShowXMLContents()
		Do ..OnShowXMLContents(pZenOutput)
	} Else {
		#; advise no default then try generic JSON
		&html<<div>There is no default content viewer defined for this message type.</div> <br/>>
		Do ..OnShowJSONContents(pZenOutput)
	}
}

/// Override to customize JSON output. <br>
/// This does not truncate data by size. </br>
Method OnShowJSONContents(pZenOutput As %Boolean = 0)
{
	Set tSC = $$$OK
	Try {
		Set tJSONStreamOrAET = ""
		If ..%Extends("%JSON.Adaptor") {
			Set tAET = {}
			Set tAET."_class" = $classname($this)
			Set tAET."_id" = ..%Id()
			Set tJSONStream = ##class(%Stream.TmpCharacter).%New()
			Set tSC = ..%JSONExportToStream(.tJSONStream)
			If $$$ISERR(tSC) Quit
			Set $property(tAET,..%ClassName(0)) = {}.%FromJSON(tJSONStream)
			Set tHTMLInfo = $$$FormatTextHTML("JSON generated using %JSON.Adaptor for type: %1, id: %2",$classname($this),..%Id())
		} Else {
			#; this will throw an error and be reported in the viewer
			Set tAET = ..GenerateGenericDAOFromObject($this)
			Set tHTMLInfo = $$$FormatTextHTML("JSON generated from class properties for type: %1, id: %2",$classname($this),..%Id())
		}
		If %response.ContentType '= "application/json" {
			/* we might be trying this as fallback after failing
				to find default content viewer
			*/
			Write tHTMLInfo
			&html<<br/><br/><pre>>
		}
		If $$$ISOK(tSC) && $IsObject(tAET) {
			Do ..OutputFormattedJSON(tAET)
			If %response.ContentType '= "application/json" {&html<</pre>>}
		} ElseIf tAET=-1 {
			Do ..WriteNoJSONFormat($this,tSC)
			Set tSC = $$$OK
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) Do ..WriteNoJSONFormat($this,tSC)
}

/// Override to customize XML output
Method OnShowXMLContents(pZenOutput As %Boolean = 0)
{
	Set tSC = $$$OK
	Set tLimitOutput = 0
	#; When %EnsContentData("LimitOutput") is defined then tLimitOutput will be that value not 0.
	If '$Data(%EnsContentData("LimitOutput"),tLimitOutput) && $$$IsdefObject(%request) {
		#; User input for determining if try to limit output. Ensure number
		Try {
			Set tLimitOutput = +$get(%request.Data("LIMITSIZE",1))
			If tLimitOutput < 0 Set tLimitOutput = 0
		} Catch {
			Set tLimitOutput = 0
		}
	}
	Set tBrowserStyle = $get(%request.Data("BrowserStyle",1))||(+$get(%request.Data("RAW",1))&&..%Extends("%XML.Adaptor"))
	// show contents as XML but suppress non XML characters.
	&html<<?xml version="1.0" ?>>
	If 'tBrowserStyle &html<<?xml-stylesheet href="ensemble/Ensemble_XMLDisplay.xsl" type="text/xsl" ?>>
	&html<<!-- type: #($classname())#  id: #(..%Id())# -->
	>
	Set tSC = ##class(EnsPortal.MessageContents).writewithoutNonXMLChars(.tWriter,$this,.tControlChars,tLimitOutput)
	If $$$ISERR(tSC) {
		// need to include an xml tag for error message to display
		Write "<!-- "_$$$FormatTextHTML("Error trying to display message contents: %1",##class(%CSP.Page).EscapeHTML($$$StatusDisplayString(tSC)))_" --><error></error>"
	} ElseIf $$$ISOK(tSC) && tControlChars {
		Write "<!-- "_$zcvt("Characters that could not be shown were removed for viewing purposes only","O","HTML")_" -->"
	}
}

/// This method is called by the Management Portal to 
/// display a message-specific content viewer.<br>
ClassMethod %DrawHTMLTable(pObj As %RegisteredObject, ByRef pID As %String) As %Status
{
	Quit ##class(%CSP.Util.AutoFormDynamic).DrawHTMLTable(pObj, .pID)
}

/// This method is called by the Management Portal to 
/// display a message-specific content editor.<br>
ClassMethod %DrawHTMLForm(pObj As %RegisteredObject, ByRef pID As %String, pActionURL As %String = "", ByRef pButtons As %CSP.Util.FormButton, pTarget As %String = "") As %Status
{
	Quit ##class(%CSP.Util.AutoFormDynamic).DrawHTMLForm(pObj, .pID, pActionURL, .pButtons, pTarget)
}

/// This method is called by the Management Portal to 
/// display a message-specific content editor.<br>
ClassMethod %ProcessSubmit(pRequest As %CSP.Request, ByRef pID As %String = "", Output pErrorMsg As %String) As %RegisteredObject
{
	#; construct body clone and get an id for it
	Merge tID=pID Set tObjId=$G(tID(1))
	If ""'=tObjId {
		Set tOldBody=..%OpenId(tObjId,,.tSC)  If $$$ISERR(tSC) Set pErrorMsg=$$$StatusDisplayString(tSC)  Quit $$$NULLOREF
		Set tOldBody=tOldBody.%ConstructClone()
		If tOldBody.%IsA("%Library.Persistent")||tOldBody.%IsA("%Stream.Object") Set tSC=tOldBody.%Save()  If $$$ISERR(tSC) Set pErrorMsg=$$$StatusDisplayString(tSC)  Quit $$$NULLOREF
		Set tSC=tOldBody.%GetSwizzleObject(0,.tOID)  If $$$ISERR(tSC) Set pErrorMsg=$$$StatusDisplayString(tSC)  Quit $$$NULLOREF
		Set tID(1)=$$$oidPrimary(tOID)
	}
	Quit ##class(%CSP.Util.AutoFormDynamic).ProcessSubmit(pRequest, .tID, .pErrorMsg, 0)
}

ClassMethod %CompareContents(pMsg1 As Ens.MessageBody, pMsg2 As Ens.MessageBody)
{
	&html<<frameset id="frameset" cols="50%,50%" frameborder=yes frameborder=1 border=2" >>
	&html<<frame src="#(##class(%CSP.Page).Link("EnsPortal.MessageContents.cls?HeaderClass="_##class(%CSP.Page).escapeURL($classname())_"&HeaderId="_$S($IsObject(pMsg1):##class(%CSP.Page).escapeURL(pMsg1.%Id()),1:"")))#" name="Left" MARGINWIDTH="0" MARGINHEIGHT="0" FRAMESPACING="0" FRAMEBORDER="1" SCROLLING="yes" >>
	&html<<frame src="#(##class(%CSP.Page).Link("EnsPortal.MessageContents.cls?HeaderClass="_##class(%CSP.Page).escapeURL($classname())_"&HeaderId="_$S($IsObject(pMsg2):##class(%CSP.Page).escapeURL(pMsg2.%Id()),1:"")))#" name="Right" MARGINWIDTH="0" MARGINHEIGHT="0" FRAMESPACING="0" FRAMEBORDER="1" SCROLLING="yes" >>
	&html<</frameset>>
}

/// This method is called by the Management Portal to 
/// display a portion of the HEAD section of a
/// message-specific content viewer.<br>
Method %ShowContentsHead(pZenOutput As %Boolean = 0)
{
}

/// This method is called when this message has timed out
/// The time out moment happens when the timer response arrives, 
/// and the request is being removed from pending request list.
/// The timeout moment is not when the response arrives and is being marked as "discarded"
Method %OnTimeout() As %Status
{
	Quit $$$OK
}

/// This method is used to provide the Statistics Site Dimension if not already set
/// Override and implement as needed.
Method GetStatsDimension() As %String
{
	Quit $$$StatsDefaultDimension
}

/// This method is used by OnShowJSONContents() to output that JSON format not avalaible
/// and to report any error if attempted JSON serialization.
ClassMethod WriteNoJSONFormat(pObject As %RegisteredObject, pStatusToReport As %Status = {$$$OK})
{
	If '$Data(%response) && '$IsObject(%response) Return
	Set tErrorMsg = $$$FormatTextHTML("JSON format not available for class %1",$classname(pObject))
	If %response.ContentType '= "application/json" {
		Write tErrorMsg,!
	} Else {
		Set tAET = {}
		Set tAET.error = tErrorMsg
		If $$$ISERR(pStatusToReport) Set tAET.errorCode = $$$FormatTextHTML("Error trying to display message contents: %1",##class(%CSP.Page).EscapeHTML($$$StatusDisplayString(pStatusToReport)))
		Do ..OutputFormattedJSON(tAET)
	}
	Return
}

/// Helper method to use the JSON formatter
ClassMethod OutputFormattedJSON(pJSONStreamOrAET)
{
	Set tSC = $$$OK
	Try {
		Set tFormatter = ##class(%JSON.Formatter).%New()
		Set tFormatter.Indent = ..#JSONINDENT
		Set tSC = tFormatter.Format(pJSONStreamOrAET)
	} Catch ex {
		Set tSC = ex.AsStatus()
		Set tError = {}
		Set tError.error = $zcvt("Error outputting formatting JSON","O","HTML")
		Do tError.%ToJSON()
	}
	Return tSC
}

/// Wrapper method for Generic dynamic object generator API used to 
/// serialize as JSON
ClassMethod GenerateGenericDAOFromObject(pObject As %RegisteredObject) As %Library.DynamicAbstractObject
{
	Return ##class(%ZEN.Auxiliary.altJSONProvider).%ObjectToAET(pObject)
}

}
