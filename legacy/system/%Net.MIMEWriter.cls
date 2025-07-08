/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%systemInclude, %soap)

/// <p><b>For information on using this class</b>, see
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=CLASSES+%25Net.MIMEWriter">MIME Messages</a>.</p>
/// %Net.MIMEWriter outputs a MIME document as represented by a top-level <class>%Net.MIMEPart</class>
/// with multiple parts specified.
Class %Net.MIMEWriter Extends %RegisteredObject [ System = 4 ]
{

Method %Write(text As %String) [ Internal, Private ]
{
 //:#define MIMETRACE
#ifdef MIMETRACE
#define TraceInit kill ^MIMETrace
#define TraceNext(%line) set ^MIMETrace($increment(^MIMETrace))=%line
#else
#define TraceInit
#define TraceNext(%line)
#endif

#define WriteText(%text) $$$TraceNext(">>"_%text) Do ..%Write(%text)
#define WriteLine(%text) $$$WriteText(%text_$c(13,10))

	Set stream=..OutputStream
	If stream="" {
		Write text
	} ElseIf stream=0 {
		$$$XMLSetBuffer(text)
		$$$XMLWriteRAW
	} Else {
		Do stream.Write(text)
	}
}

/// Destination for %Net.MIMEWriter output.
/// Possible values are "file", "stream" and "device".
Property OutputDestination As %String [ InitialExpression = "device", Private ];

/// Stream for output to stream or file.
/// Will store a stream, 
///   but declare as %RegisteredObject to prevent auto create of serial object.
Property OutputStream As %RawString [ Private ];

/// <method>OutputToDevice</method> sets output to the current device which
/// is the default if no output method is specified.
Method OutputToDevice() As %Status
{
	Set ..OutputDestination="device"
	Set ..OutputStream=""
	Quit $$$OK
}

/// <method>OutputToStream</method> sets output to be directed to a stream.
/// <var>export</var> is the exported stream.  
/// If <var>export</var> is the oref of a stream, the MIME document will
/// be written to this existing stream at the current position.
/// If <var>export</var> is "", then a new %GlobalBinaryStream will be
/// created to contain the MIME document and its oref returned.
/// In this case, <var>export</var> must be passed by reference.
Method OutputToStream(ByRef export As %BinaryStream) As %Status
{
	If $get(export)="" Set export=##class(%GlobalBinaryStream).%New()
	Set ..OutputStream=export
	Set ..OutputDestination="stream"
	Quit $$$OK
}

/// <method>OutputToFile</method> sets output to be directed to a
/// new file, named <var>filename</var>.
/// The file is created with parameters "WNS".
Method OutputToFile(filename As %String) As %Status
{
	Set ..OutputDestination="file"
	Set ..OutputStream=##class(%FileBinaryStream).%New()
	Set ..OutputStream.Filename=filename
	Quit $$$OK
}

/// <method>WriteMIMEMessage</method> outputs a MIME message.
Method WriteMIMEMessage(message As %Net.MIMEPart) As %Status
{
	If message.Parts.Count()>0 $$$WriteLine("MIME-Version: 1.0")
	
	Set sc=..WritePart(message)

	If ..OutputDestination="file"  do ..OutputStream.SaveStream()

	Quit sc
}

/// <method>WriteMIMEBody</method> outputs the body of a MIME multipart message.
/// If the message is multipart, the caller is expected to output needed headers.
/// If the message, is not multipart, then headers are output.
Method WriteMIMEBody(message As %Net.MIMEPart) As %Status
{
	Set sc=..WriteBody(message)

	If ..OutputDestination="file"  do ..OutputStream.SaveStream()

	Quit sc
}

/// Write the body.
Method WriteBody(message As %Net.MIMEPart) As %Status [ Internal, Private ]
{
	If (message.Parts.Count()>0) ||
	   ($zcvt($piece($piece($zstrip(message.ContentType,"<W"),";"),"/"),"L")="multipart") {
		Set boundary=message.Boundary
		For i=1:1:message.Parts.Count() {
			$$$WriteLine("--"_boundary)
			do ..WritePart(message.Parts.GetAt(i))
		}
		$$$WriteLine("--"_boundary_"--")
	} Else {
		Do ..WritePart(message)
	}
	If ..OutputDestination="file"  do ..OutputStream.SaveStream()

	Quit $$$OK
}

/// Write a MIME part
Method WritePart(part As %Net.MIMEPart) As %Status [ Internal, Private ]
{
	Set sc=$$$OK

	// Write out the headers
	Set header=part.NextHeader("")
	While header'="" {
		Set value=part.GetHeader(header,.name)
		Do ..WriteHeader(name,value)
		Set header=part.NextHeader(header)
	}
	
	// Write blank line to separate headers from body
	$$$WriteLine("")
	
	// Write the body
	If part.Parts.Count()>0 {
		Set sc= ..WriteBody(part)
	} Else {
		Set data=part.Body
		If data'="" {
			Set charstream=data.%IsA("%Library.FileCharacterStream")
			If charstream {
		 		Set originalTable=data.TranslateTable
		 		Set data.TranslateTable="RAW"
			}
	
			Set contentEncoding=$ZCONVERT(part.GetHeader("CONTENT-TRANSFER-ENCODING"),"l")
			If contentEncoding="base64" {
				Set sc=..EncodeStreamBase64(data)
			} Elseif contentEncoding="quoted-printable" {
				Set sc=..EncodeStreamQuotedPrintable(data)
			} Else {
				Set sc=..OutputNoEncoding(data)
			}

			If charstream {
		 		Set data.TranslateTable=originalTable
			}
		}
	}
	
	Quit sc
}

/// Write a header
Method WriteHeader(name As %String, value As %String)
{
	$$$WriteLine(name_": "_value)
}

/// Write stream -- base64 encoded
Method EncodeStreamBase64(stream As %Stream.Object) As %Status [ Internal, Private ]
{
	; process stream in groups of 1023 - 
	; number arbitrary but must be divisible by 3 and 57=76/4*3
	Set out=""
	Do stream.Rewind()
	While 'stream.AtEnd {
		Set len=513		; text must be divisible by 3 and 76
		Set text=stream.Read(.len)
		If len'>0 quit
		$$$WriteLine($system.Encryption.Base64Encode(text))
	}
	Quit $$$OK
}

/// Write stream -- quoted printable encoded
Method EncodeStreamQuotedPrintable(stream As %Stream.Object) As %Status [ Internal, Private ]
{
	set sc=$$$OK
	; Following flags to defer processing until end of line
	set readlen=4000
	set out=""
	set bCR=0 ; true if CR was encountered.
	set aWS=0 ; 9 or 32 if whitespace encountered.
	set bLineOutput=0
	do stream.Rewind()
	while 'stream.AtEnd && $$$ISOK(sc) {
		set len=readlen
		set line=stream.Read(.len)
	 	if len'>0 quit
	 	for i=1:1:$length(line) do  quit:$$$ISERR(sc)
	 	. set a=$ascii(line,i)
	 	. if bCR do
	 	. . if a=10 do  ; EOL since LF follows CR
	 	. . . ; preserve trailing spaces
	 	. . . if aWS do ..AppendToOutput(.out,"="_..pad2($zhex(aWS)))
	 	. . . do ..ProcessLine(out) set out="" set bLineOutput=1
	 	. . if a'=10 do
	 	. . . if aWS do ..AppendToOutput(.out,$char(aWS))
	 	. . . do ..AppendToOutput(.out,"=0D") ; output CR without LF
	 	. . set bCR=0 set aWS=0
	 	. if bLineOutput set bLineOutput=0 quit  ; if line just output get next char
	 	. if aWS,a'=13 do ..AppendToOutput(.out,$char(aWS)) set aWS=0
	 	. ; process the current character
	 	. if a=13 set bCR=1 quit
	 	. set aWS=0 if (a=9)!(a=32) set aWS=a quit
	 	. if a>255 set sc=$$$ERROR($$$SMTPQuotedPrintable) quit
	 	. if a=46,out="" set out="." ; double period at start of line
	 	. if (a<33)!(a>126)!(a=61) do
	 	. . do ..AppendToOutput(.out,"="_..pad2($zhex(a)))
	 	. else  do ..AppendToOutput(.out,$char(a))
	}
	if $$$ISOK(sc) {
		if bCR do:aWS ..AppendToOutput(.out,$char(aWS)) do ..AppendToOutput(.out,"=0D")
		if 'bCR&aWS do ..AppendToOutput(.out,"="_..pad2($zhex(aWS)))
		do ..ProcessLine(out)
	}
	quit sc
}

/// Write stream - not encoded
Method OutputNoEncoding(stream As %Stream.Object) [ Internal, Private ]
{
	Do stream.Rewind()
	While 'stream.AtEnd {
		Set len=10000
		Set line=stream.Read(.len)
		If len<0 quit
		$$$WriteText(line)
	}
	$$$WriteLine("")
	Quit $$$OK
}

/// Return integer or hex padded to 2 place with leading zeros 
Method pad2(n As %String) As %String [ CodeMode = expression, Internal, Private ]
{
$select($length(n)=1:"0"_n,1:n)
}

/// Append encoded data to output buffer
Method AppendToOutput(ByRef out As %String, str As %String) [ Internal, Private ]
{
	If $length(out)+$length(str)>75 {
		Do ..ProcessLine(out_"=")
		Set out=str
		Set:$extract(str,1)="." out="."_out
	} Else {
		Set out=out_str
	}
}

/// Output buffered output
Method ProcessLine(line As %String) [ Internal, Private ]
{
	// send as many lines together as will fit in 512 byte buffer
	// If ..bufcount=6 $$$WriteLine(line) set ..bufcount=1 quit
	$$$WriteText(line_$C(13,10))
	// Set ..bufcount=..bufcount+1
}

}
