/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsebXML)

/// ebXML Message instance
Class EnsLib.ebXML.MessageWithPayload Extends (EnsLib.ebXML.Message, %XML.Adaptor) [ ClassType = persistent, System = 4 ]
{

/// ebXML Manifest
Property Manifest As EnsLib.ebXML.schema.msg.Manifest;

/// MIME Parts keyed by content id
Property MIMEParts As array Of %Net.MIMESerialPart;

/// Construct an instance of the ebXML Manifest type (EnsLib.ebXML.schema.msg.Manifest)
Method CreateManifestWithReferences(pReference As %ListOfObjects(ELEMENTTYPE="EnsLib.ebXML.schema.msg.Reference"))
{
	Set ..Manifest           = $ZOBJCLASSMETHOD(..#SCHEMAPACKAGE_".msg.Manifest","%New")
	Set ..Manifest.Reference = pReference
	Set ..Manifest.version   = $$$EnsebXMLVersion
}

/// Validate a Manifest
Method ValidateManifest() As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="ItsATrap"
	Do {
		
		#dim tMIMEMap As %Boolean
		#dim tKey     As %String
		#dim tErrors  As %Status
		
		Set tErrors = $$$OK
		
		Set tKey = ""
		For {
			#dim tMIMEPart  As %Net.MIMESerialPart
			#dim tContentId As %String

			Set tMIMEPart = ..MIMEParts.GetNext(.tKey)
			Quit:tKey=""
		
			// Grab the content id
			Set tContentId = tMIMEPart.ContentId
			
			// Add it to our map
			If $INCREMENT(tMIMEMap(tContentId))>1 {
				// Duplicate MIME part
				Set tErrors = $$$ADDSC(tErrors,$$$ERROR($$$EnsebXMLErrDuplicatePayload,tContentId))
				Continue
			}
		}
		
		// Now, loop over the Manifest and validate that against tMIMEMap
		Set tKey = ""
		For {
			#dim tRef As EnsLib.ebXML.schema.msg.Reference
			
			Set tRef = ..Manifest.Reference.GetNext(.tKey)
			Quit:tKey=""
			
			If $P(tRef.href,":")="cid" {
				Set tContentId = $P(tRef.href,":",2,$L(tRef.href,":"))
				
				// Now, check the map for the corresponding MIME part
				If '$D(tMIMEMap(tContentId)) {
					// Content reference not found in MIME parts
					Set tErrors = $$$ADDSC(tErrors,$$$ERROR($$$EnsebXMLErrUnsatisfiedReference,tContentId))
					Continue
				}
				
				// Otherwise, looks good, decrement our usage count
				If $INCREMENT(tMIMEMap(tContentId),-1)
			}
		}
		
		// Finally, check the map for non-zero entries
		Set tKey = ""
		For {
			Set tKey = $ORDER(tMIMEMap(tKey))
			Quit:tKey=""
			
			// Found an unreferenced MIME part
			If tMIMEMap(tKey)>0 {
				// Unreferenced MIME part
				Set tErrors = $$$ADDSC(tErrors,$$$ERROR($$$EnsebXMLErrUnreferencedPayload,tKey))
				Continue
			}
		}
		
		If $$$ISERR(tErrors) {
			// Badly formed ebXML message (report the problems as an embedded status)
			Set tSC = $$$EMBEDSC($$$ERROR($$$EnsebXMLErrBadlyFormedMessage),tErrors)
		}
		
	} While (0)
Exit
	Quit tSC
ItsATrap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Returns array of properties that make up the <i>contents</i>
/// of this object.<br>
/// This method in implemented within the document class.<br>
/// The content array is in the form:<br>
/// 	pContents(n,"type")="%String"<br>
/// 	pContents(n,"name")="Field"<br>
/// 	pContents(n,"alias")=alias code<br>
/// If pContents(n) is non-zero then the property is a composite type with<br>
/// sub-properties.  The sub-properties are indexed with a similar structure under<br>
///     pContents(n,m) where m is the index of the subtype property.<br>
ClassMethod GetContentArray(Output pContents, pMode As %String = "source", pDocType As %String = "", pLevel As %Integer = 0, pIncludeBase As %Boolean = 0) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		Set tSC = ##super(.pContents,pMode,pDocType,pLevel)
		Quit:$$$ISERR(tSC)
	
		Set tSC = ..GetContentArrayForClass($NAME(@pContents),"EnsLib.ebXML.schema.msg.Manifest")
		Quit:$$$ISERR(tSC)

		Set @pContents@($I(@pContents),"type")="%ArrayOfObjects"
		Set @pContents@(@pContents,"name")="MIMEParts"

		Set tSC = ..GetContentArrayForClass($NAME(@pContents@(@pContents)),"%Net.MIMEPart")
		Quit:$$$ISERR(tSC)
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// HTML display helper method to add links for properties not 
/// defined in <class>EnsLib.ebXML.Message</class>.
Method showTopLinks()
{
	Do ##super()
	
	&html<<a href="#manifestDiv">Manifest</a>&nbsp;&nbsp;&nbsp;>
	
	If $IsObject(..MIMEParts.GetNext("")) {
		&html<<a href="#mimeDiv">MIME Parts</a>&nbsp;&nbsp;&nbsp;>
	}
}

/// HTML display helper method to add properties not defined in
/// <class>EnsLib.ebXML.Message</class>.
Method showContents()
{
	Do ##super()

	&html<<div id="manifestDiv" class="divBlock"><h2>Manifest</h2><pre>>
	Set tStream = ##class(%Stream.TmpCharacter).%New()
	If $IsObject(..Manifest) {
		Set tWriter = ##class(%XML.Writer).%New()
		Set tWriter.NoXMLDeclaration = 1
		Do tWriter.AddInstanceNamespace()
		Do tWriter.AddSchemaNamespace()
		Set tWriter.Indent = 1
		Do tWriter.OutputToStream(tStream)
		Do tWriter.RootObject(..Manifest)
	}
	Do ..escapeXMLStream(tStream)
	&html<</pre></div>>
	
	If $IsObject(..MIMEParts.GetNext("")) {
		&html<<div id="mimeDiv" class="divBlock"><h2>MIME Parts</h2>>
		Set tKey = ""
		For i=1:1:..MIMEParts.Count() {
			Set tMime = ..MIMEParts.GetNext(.tKey)
			&html<<a href="#mimePart#(i)#">MIME Part #(i)#</a>>
		}
		
		#dim tMime As %Net.MIMESerialPart
		Set tKey = ""
		For i=1:1:..MIMEParts.Count() {
			Set tMime = ..MIMEParts.GetNext(.tKey)
			&html<<div id="mimePart#(i)#" class="divBlock"><h3>Part #(i)#: Content-Id = #(tMime.ContentId)#</h3>&nbsp;<a href="#">Top</a>&nbsp;&nbsp;&nbsp;<a href="#mimeDiv">MIME Parts</a><pre id="mimePre#(i)#">>
			Do ..escapeXMLStream(tMime.Body)
			&html<</pre></div>>
		}
		&html<</div>>
	}
	Quit
}

Storage Default
{
<Data name="MIMEParts">
<Attribute>MIMEParts</Attribute>
<Structure>subnode</Structure>
<Subscript>"EnsLib.ebXML.MessageWithPayload.MIMEParts"</Subscript>
</Data>
<Data name="MessageWithPayloadDefaultData">
<Subscript>"MessageWithPayload"</Subscript>
<Value name="1">
<Value>Manifest</Value>
</Value>
</Data>
<DefaultData>MessageWithPayloadDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
