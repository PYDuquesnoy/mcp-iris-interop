/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A serializable subclass of %Net.MIMEPart
Class %Net.MIMESerialPart Extends (%Net.MIMEPart, %SerialObject, %XML.Adaptor) [ ClassType = serial, Inheritance = right, System = 4 ]
{

/// The body of the attachment as a stream.
/// Either Parts must contain MIMEParts or Body must be specified, but not both.
Property Body As %Stream.GlobalBinary;

/// Set the body of the attachment to a stream.
/// If the stream contains a Headers attribute, this attribute is used to
/// initialize the headers of the MIME part.
/// The %CSP.BinaryStream that is returned by the CSP engine is an example of such
/// a stream with Headers attribute. 
Method BodySet(body As %CSP.BinaryStream = "") As %Status
{
	If $isobject(body) && body.%IsA("%Stream.GlobalBinary") {
		// We do this to allow objects to be constructed, otherwise we can't instantiate ..Body
		Set (r%Body,oref) = body
	} Else {
		// Grab the existing body
		Set oref=..Body
	}
	
	If $isobject(body) {
		// Only old AbstractStreams support attributes
		If body.%IsA("%AbstractStream") {
			Set headers=$tr(body.GetAttribute("Headers"),$c(13),"")
			If headers'="" {
				Set sc=..ClearHeaders()
				If $$$ISERR(sc) Quit sc
				Set len=$length(headers,$c(10))
				For i=1:1:len {
					Set header=$piece(headers,$c(10),i)
					Set name=$zstrip($piece(header,":",1),"<>W")
					Set value=$zstrip($piece(header,":",2,len),"<>W")
					Do ..SetHeader(name,value)
				}
			}
		}
		Do body.Rewind()
		Do oref.Rewind()
		Do oref.CopyFrom(body)
	} ElseIf body'="" {
		// body is just a scalar
		Do oref.Write(body)
	}
	
	Quit $$$OK
}

/// Clonesa regular %Net.MIMEPart into a serializable %Net.MIMESerialPart
ClassMethod CloneFromMIMEPart(pPart As %Net.MIMEPart) As %Net.MIMESerialPart
{
	#dim tSerial       As %Net.MIMESerialPart
	#dim tHeader       As %String
	#dim tOriginalName As %String
	#dim tValue        As %String
	
	Set tSerial = ##class(%Net.MIMESerialPart).%New()
	Set tSerial.Boundary = pPart.Boundary
	Set tHeader = ""
	For {
		// Iterate over the header names
		Set (tHeader,tOriginalName) = pPart.NextHeader(tHeader)
		Quit:tHeader=""
		
		// Copy header values (and the original names)
		Set tValue = pPart.GetHeader(tHeader,.tOriginalName)
		Do tSerial.SetHeader(tOriginalName, tValue)
	}
	
	// And finally copy the body/parts
	If $IsObject(pPart.Parts) && (pPart.Parts.Count() > 0) {
		
		#dim tKey
		#dim tItem As %Net.MIMEPart
		
		Set tKey=""
		For {
			Set tItem = pPart.Parts.GetNext(.tKey)
			Quit:tKey=""
			
			// Clone this item
			Set tItem = ..CloneFromMIMEPart(tItem)
			Do tSerial.Parts.Insert(tItem)
		}
	} Else {
		
		Set tSerial.Body = pPart.Body
		
	}
	
	Quit tSerial
}

Storage Default
{
<Data name="MIMESerialPartState">
<Value name="1">
<Value>Body</Value>
</Value>
<Value name="2">
<Value>ContentTransferEncoding</Value>
</Value>
<Value name="3">
<Value>ContentLocation</Value>
</Value>
<Value name="4">
<Value>ContentId</Value>
</Value>
<Value name="5">
<Value>Boundary</Value>
</Value>
<Value name="6">
<Value>Parts</Value>
</Value>
<Value name="7">
<Value>Headers</Value>
</Value>
<Value name="8">
<Value>PartOwnedStream</Value>
</Value>
</Data>
<State>MIMESerialPartState</State>
<StreamLocation>^CacheStream</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
