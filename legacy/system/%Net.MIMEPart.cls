/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on using this class</b>, see
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=CLASSES+%25Net.MIMEPart">MIME Messages</a>.</p>
/// %Net.MIMEPart holds a MIME message part.
Class %Net.MIMEPart Extends %RegisteredObject [ System = 4 ]
{

/// Parts of a multipart message.
/// Either Parts must contain MIMEParts or Body must be specified, but not both.
Property Parts As list Of %Net.MIMEPart;

/// The body of the attachment as a stream.
/// Either Parts must contain MIMEParts or Body must be specified, but not both.
Property Body As %RegisteredObject;

/// If PartOwnedStream is true, then the part owns the stream and should cleasr it when 
/// the part is deleted.
Property PartOwnedStream As %Boolean;

/// Set the body of the attachment to a stream.
/// If the stream contains a Headers attribute, this attribute is used to
/// initialize the headers of the MIME part.
/// The %CSP.BinaryStream that is returned by the CSP engine is an example of such
/// a stream with Headers attribute. 
Method BodySet(body As %CSP.BinaryStream = "") As %Status
{
	If $isobject(body) {
		Try {
			Set headers=$tr(body.GetAttribute("Headers"),$c(13),"")
		} Catch {
			Set headers=""
		}
		If headers'="" {
			Set sc=..Headers.Clear()
			If $$$ISERR(sc) Quit sc
			Set len=$length(headers,$c(10))
			For i=1:1:len {
				Set header=$piece(headers,$c(10),i)
				Set name=$zstrip($piece(header,":",1),"<>W")
				Set value=$zstrip($piece(header,":",2,len),"<>W")
				Do ..SetHeader(name,value)
			}
		}
	} ElseIf body'="" {
		Set body=##class(%SOAP.BufferedStream).%New(body)
	}

	Set r%Body=body

	Quit $$$OK
}

/// Optionally initialize the body (and possibly the headers) during construction.
Method %OnNew(body As %CSP.BinaryStream = "") As %Status
{
	If body'="" Set ..Body=body
	
	Quit $$$OK
}

/// Make sure stream is Clear'ed when this part is closed
Method %OnClose() As %Status [ Private, ServerOnly = 1 ]
{
	If ..PartOwnedStream,$isobject(..Body) Do ..Body.Clear()
	
	Quit $$$OK
}

/// The MIME headers for this attachment.
/// The key is the header name in upper case.
/// The stored value is $lb(headerName,headerValue) where<br>
/// <var>headerName</var> is the user specified header name.<br>
/// <var>headerValue</var> is the header value stripped of leading and trailing whitespace.
Property Headers As array Of %List [ Internal, Private ];

/// Add a header to the MIME part. The basic Content headers that you may want are covered by 
/// properties of this class:  Content-Type, Content-Transfer-Encoding, Content-Id and Content-Location.
Method SetHeader(name As %String, value As %String)
{
	Set uname=$zcvt(name,"U")
	// Do not save MIME-Version header, since always fixed.
	If uname="MIME-VERSION" Quit
	Set value=$zstrip(value,"<>W")
	Do ..Headers.SetAt($lb(name,value),uname)
	If uname="CONTENT-ID" {
		Set i%ContentId=..NormalizeContentId(value)
	} ElseIf uname="CONTENT-LOCATION" {
		Set i%ContentLocation=..NormalizeContentLocation(value)
	} ElseIf uname="CONTENT-TYPE" {
		Do ..ParseContentType(value)
	}
}

/// Remove a header to the MIME part.
Method RemoveHeader(name As %String)
{
	Set uname=$zcvt(name,"U")
	Do ..Headers.RemoveAt(uname)
	If uname="CONTENT-ID" {
		Set i%ContentId=""
	} ElseIf uname="CONTENT-LOCATION" {
		Set i%ContentLocation=""
	} ElseIf uname="CONTENT-TYPE" {
		Kill ..ContentTypeAttributes
		Set i%Boundary=""
	}
}

/// Lookup a previously set header.  The lookup is not case sensitive.  
/// However, the original name is returned.
Method GetHeader(name As %String, Output originalName As %String) As %String
{
	If name '="" {
		Set uname=$zcvt(name,"U")
		Set val=..Headers.GetAt(uname)
		Set originalName=$listget(val,1)
		Quit $listget(val,2)
	} Else {
		Set originalName=""
		Quit ""
	}
}

/// Get the next header based on the upper case key used to store the headers.
Method NextHeader(name As %String) As %String [ CodeMode = expression ]
{
..Headers.Next($zcvt(name,"U"))
}

/// Clear the list of headers
Method ClearHeaders() As %Status [ CodeMode = expression ]
{
..Headers.Clear()
}

/// Sets/gets the 'Content-Type:' MIME header.  A Content-Type specifies the media type 
/// of the <PROPERTY>Body</PROPERTY> data. A Content-Transfer-Encoding header may be used 
/// to indicate any additional content coding applied to the type.
Property ContentType As %String(MAXLEN = "") [ Calculated ];

Method ContentTypeGet() As %String [ CodeMode = expression ]
{
$listget(..Headers.GetAt("CONTENT-TYPE"),2)
}

Method ContentTypeSet(contenttype As %String) As %Status
{
	Do ..SetHeader("CONTENT-TYPE",contenttype)
	
	Quit $$$OK
}

/// Attributes of Content-Type header stored in multidimensional array.
Property ContentTypeAttributes As %String [ Internal, MultiDimensional, Private ];

/// Parse the Content-Type header into its attributes
Method ParseContentType(value As %String) [ Internal, Private ]
{
	Kill ..ContentTypeAttributes
	For i=2:1:$length(value,";") {
		Set attr=$piece(value,";",i)
		Set name=$zconvert($zstrip($piece(attr,"=",1),"<>W"),"U")
		If name="" Continue
		Set attrvalue=$zstrip($piece(attr,"=",2,30000),"<>W")
		If $extract(attrvalue)="""" {
			For c=2:1:$length(attrvalue) {
				if $extract(attrvalue,c)="\" {
					Set c=c+1
				} ElseIf $extract(attrvalue,c)="""" {
					Set ..ContentTypeAttributes(name)=$extract(attrvalue,2,c-1)
					Quit
				}
			}
		} Else {
			Set ..ContentTypeAttributes(name)=$zstrip($piece(attrvalue,"(",1),"<>W")
		}
	}
	If $get(..ContentTypeAttributes("BOUNDARY"))'="" {
		Set ..Boundary=..ContentTypeAttributes("BOUNDARY")
	}
}

/// Return an attribute of a previously stored Content-Type.
Method GetContentTypeAttribute(name As %String) [ CodeMode = expression ]
{
$get(..ContentTypeAttributes($zconvert(name,"U")))
}

/// If the <PROPERTY>ContentType</PROPERTY> starts with 'text/' then this is the
/// charset to encode the contents with. This is actually specified in the MIME
/// Content-Type header with something like:<p>
/// 
/// Content-Type: text/html; charset=UTF-8<p>
/// 
/// You must set this property after you set the <property>ContentType</property>
/// or it will overwrite this value.
Property ContentCharset As %String(MAXLEN = "") [ Calculated ];

Method ContentCharsetGet() As %String [ CodeMode = expression ]
{
$piece($piece($listget(..Headers.GetAt("CONTENT-TYPE"),2),"charset=",2),";")
}

Method ContentCharsetSet(charset As %String) As %Status
{
	Set content=$zcvt($zstrip(..ContentType,"<>W"),"l")
	If content["charset=" {
		Set end=$piece($piece(content,"charset=",2,*),";",2,*)
		If end'="" Set end=";"_end
		Set content=$piece(content,"charset=")_"charset="_charset_end
	} Else {
		If $extract(content,*)'=";" Set content=content_";"
		Set content=content_" charset="_charset
	}
	Set ..ContentType=content
	Quit $$$OK
}

/// Content-Transfer-Encoding header. Can be one of "base64", "quoted-printable", "7bit", "8bit", "binary".
Property ContentTransferEncoding As %String(VALUELIST = ",base64,quoted-printable,7bit,8bit,binary");

Method ContentTransferEncodingSet(value As %String) As %Status
{
	if $case($zconvert(value,"L"),"":1,"base64":1,"quoted-printable":1,"7bit":1,"8bit":1,"binary":1,:0) {
		Do ..Headers.SetAt($lb("Content-Transfer-Encoding",value),"CONTENT-TRANSFER-ENCODING")
		Quit $$$OK
	} Else {
		Quit $$$ERROR($$$MimeContentTransferEncoding,value)
	}
}

Method ContentTransferEncodingGet() As %String [ CodeMode = expression ]
{
$listget(..Headers.GetAt("CONTENT-TRANSFER-ENCODING"),2)
}

/// The normalized content-location.
/// Any leading or trailing whitespace and comments are removed.
Property ContentLocation As %String(MAXLEN = "");

Method ContentLocationSet(value As %String) As %Status
{
	Set i%ContentLocation=value
	If value'="" {
		Do ..Headers.SetAt($lb("Content-Location",value),"CONTENT-LOCATION")
	} Else {
		Do ..Headers.RemoveAt("CONTENT-LOCATION")
	}
	Quit $$$OK
}

/// The normalized content-id.
/// Any leading or trailing whitespace and enclosing <> are removed.
Property ContentId As %String(MAXLEN = "");

Method ContentIdSet(value As %String) As %Status
{
	Set i%ContentId=value
	If value'="" {
		Do ..Headers.SetAt($lb("Content-Id","<"_value_">"),"CONTENT-ID")
	} Else {
		Do ..Headers.RemoveAt("CONTENT-ID")
	}
	Quit $$$OK
}

/// Boundary to used to separate parts of the message.
/// If none is specified, a default is created.
Property Boundary As %String(MAXLEN = "");

Method BoundaryGet() As %String
{
	If i%Boundary'="" Quit i%Boundary
	
 	#; create boundary string using random number generator
 	Set rnd1=$random(100000)/17,rnd2=$random(100000)/17
 	Set boundary="--boundary"_$zstrip(rnd1,"<>W")_$zstrip(rnd2,"<>W")_"--"
 	Set i%Boundary=boundary
 	Quit boundary
}

/// Strip enclosing <> from Content-Id header.
/// Input must already be stripped of lleading and trailing whitespace
ClassMethod NormalizeContentId(contentId As %String) As %String [ CodeMode = expression ]
{
$select(($extract(contentId,1)="<")&&($extract(contentId,*)=">"):$zstrip($extract(contentId,2,*-1),"<>W"),1:contentId)
}

/// Strip whitespace and comments from the Content-Location header.
/// Input must already be stripped of lleading and trailing whitespace
ClassMethod NormalizeContentLocation(contentLocation As %String) As %String
{
	// Strip () enclosed comments.
	While $extract(contentLocation)="(" {
		Set len=$length(contentLocation,")")
		If len<2 Quit
		Set contentLocation=$piece(contentLocation,")",2,len)
		Set contentLocation=$zstrip(contentLocation,"<>W")
	}
	While $extract(contentLocation,*)=")" {
		Set len=$length(contentLocation,"(")
		If len<2 Quit
		Set contentLocation=$piece(contentLocation,"(",1,len-1)
		Set contentLocation=$zstrip(contentLocation,"<>W")
	}
	Quit contentLocation
}

}
