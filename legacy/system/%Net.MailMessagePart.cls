/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on using this class</b>, see
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=CLASSES+%25Net.MailMessagePart">Sending and Receiving Email</a>.</p>
/// Send an SMTP mail message or receive a MIME message using POP3.
Class %Net.MailMessagePart Extends %SerialObject [ System = 3 ]
{

/// If set, this message part (which may be the entire message) is made up out of parts 
/// which you need to process.
/// If 0, then message consists of a single part and either has text data or binary data 
Property IsMultiPart As %Boolean [ InitialExpression = 0 ];

/// Type of MultiPart to declare, e.g. "related","alternative"; default="mixed"
Property MultiPartType As %String;

/// The IsAlternative property is only meaningful for multipart messages (IsMultiPart=1).
/// If IsAlternative=1, then Content-Type: multipart/alternative, 
/// otherwise Content-Type: multipart/mixed.
/// IsAlternative is deprecated.  Use MultiPartType
Property IsAlternative As %Boolean [ Calculated, Deprecated ];

Method IsAlternativeGet() As %Boolean [ CodeMode = expression ]
{
$select(i%MultiPartType="":"", 1:($ZCvt(i%MultiPartType,"L")="alternative"))
}

Method IsAlternativeSet(value As %Boolean) As %Status
{
	If value {
		Set i%MultiPartType="alternative"
	} Else {
		If i%MultiPartType="alternative" Set i%MultiPartType=""
	}
}

/// If message is NOT multipart, this indicates whether message has text or binary data 
Property IsBinary As %Boolean;

/// If message is NOT multipart, this indicates whether message to be sent 
/// will be encoded as Base64 or quoted-printable.<br>
/// When sending the message and Is7bit="", the encoding (IsBase64) defaults to 1
/// if IsBinary, else to 0.
/// IsBase64 is deprecated.  Use ContentTransferEncoding.
Property IsBase64 As %Boolean [ Calculated, Deprecated ];

Method IsBase64Get() As %Boolean [ CodeMode = expression ]
{
$select(i%ContentTransferEncoding="":"",1:(i%ContentTransferEncoding="base64"))
}

Method IsBase64Set(value As %Boolean) As %Status
{
	If value {
		Set i%ContentTransferEncoding="base64"
	} ElseIf value=0 {
		If (i%ContentTransferEncoding="") || (i%ContentTransferEncoding="base64") {
			Set i%ContentTransferEncoding="quoted-printable"
		}
	} Else {
		If i%ContentTransferEncoding="base64" Set i%ContentTransferEncoding=""
	}
}

/// If message is NOT multipart, this indicates whether message to be sent 
/// will be treated as a 7bit message that does not need encoding.
/// All body text must already be 7bit data and all lines must < 998 bytes in lenght.<br>
/// When sending the message and IsBase64=1, then Is7bit is ignored.
/// Is7bit is deprecated.  Use ContentTransferEncoding.
Property Is7bit As %Boolean [ Calculated, Deprecated ];

Method Is7bitGet() As %Boolean [ CodeMode = expression ]
{
$select(i%ContentTransferEncoding="":"",1:(i%ContentTransferEncoding="7bit"))
}

Method Is7bitSet(value As %Boolean) As %Status
{
	If value {
		Set i%ContentTransferEncoding="7bit"
	} Else {
		If i%ContentTransferEncoding="7bit" Set i%ContentTransferEncoding=""
	}
}

/// if message is NOT multipart and is text, this indicates whether message is in HTML format 
Property IsHTML As %Boolean;

/// Sets the Content-Type header.
/// If IsBinary, defaults to "application/octet-stream"
/// If 'IsBinary &amp;&amp; isHTML, defaults to "text/html"
/// If 'IsBinary &amp;&amp; 'isHTML, defaults to "text/plain"
Property ContentType As %String(MAXLEN = 1024);

/// Content-Transfer-Encoding header. Can be one of "base64", "quoted-printable", "7bit", "8bit".
/// Default is "base64 if IsBinary is true, toherwise default is "quoted-printable".
Property ContentTransferEncoding As %String(VALUELIST = ",base64,quoted-printable,7bit,8bit");

Method ContentTransferEncodingSet(value As %String) As %Status
{
	if $case(value,"":1,"base64":1,"quoted-printable":1,"7bit":1,"8bit":1,:0) {
		Set i%ContentTransferEncoding=value
		Quit $$$OK
	} Else {
		Set i%ContentTransferEncoding=""
		Quit $$$ERROR($$$MimeContentTransferEncoding,value)
	}
}

/// text data if message is NOT binary and is NOT multipart 
Property TextData As %FileCharacterStream;

/// binary data if message is BINARY and is NOT multipart 
Property BinaryData As %FileBinaryStream;

/// If IsMultiPart=1 (true), Parts is an array of the parts of a multipart messsage.
/// Normally each of these parts is a %Net.MailMessagePart.<br><br>
/// However, if ContentType="message/rfc822", then Parts may only have one entry
/// which is a %Net.MailMessage object that represents an attached email message.
/// This attached message may be converted to a %Net.MailMessage object using the 
/// GetAttachedEmail method of %Net.POP3.
Property Parts As array Of %Net.MailMessagePart;

/// directory for attachments 
Property Dir As %String(MAXLEN = 4096);

/// Filename if message is associated with attached file
Property FileName As %String(MAXLEN = 4096);

/// If Filename specified and InlineAttachment property is true, then attachment will have
/// a content-disposition header with value inline.
Property InlineAttachment As %Boolean;

/// Array of header names and their values.
/// Note that Content-Transfer-Encoding, Content-Type and Content-Disposition are
/// automatically created and should not be included in the Headers array.
Property Headers As array Of %String(MAXLEN = 4096);

/// Then default is utf-8 on Unicode systems and the system default on 8-bit systems.<br><br>
/// <property>Charset</property> determines the charset of the mail message part. 
/// <class>%Net.SMTP</class> and <class>%Net.POP3</class> handle <property>Charset</property> 
/// differently -- see the appropriate class definition.
Property Charset As %String;

Method CharsetSet(charset As %String) As %Status
{
 set i%Charset=charset
 if (charset'="") && ##class(%Net.Charset).TranslateTableExists(charset) {
 set ..TextData.TranslateTable=##class(%Net.Charset).GetTranslateTable(charset)
 } else {
 set ..TextData.TranslateTable="RAW"
 }
 Quit $$$OK
}

Property Debug As %String [ Internal ];

/// Internal part index of this message part.
Property PartIndex As %Integer [ Internal ];

Method %OnNew(charset As %String = "") As %Status
{
 set i%Charset=$select(charset'="":charset,1:##class(%Net.Charset).GetDefaultCharset())
 set ..TextData.TranslateTable=##class(%Net.Charset).GetTranslateTable(i%Charset)
 Quit $$$OK
}

/// Attach file to this message as another MIME part.
/// All files are sent as binary attachments by default.
/// However, a text file may be attached by passing the third
/// argument, <i>isBinary</i>, as 0.  For text files, the <i>charset</i> 
/// may be passed as the fourth argument.<br>
/// The position in the Parts array of the message part that holds the file 
/// is returned in the <i>count</i> reference argument.  This count may be used to set
/// additional characteristics of the file such as Charset, 
/// e.g. set msg.Parts.GetAt(count).Charset="iso-8859-1".<br>
/// 
/// For example to send the file as a text file in charset iso-8859-2:
/// <EXAMPLE>
/// set status=message.AttachFile("d:\temp","test.txt",0,"iso-8859-1",.count)
/// if $$$ISERR(status) do handleError .....
/// </EXAMPLE>
/// Note that setting the Charset does not translate the file.  Rather it just
/// specifies the charset that already describes the file's data.
Method AttachFile(Dir As %String, File As %String, isBinary As %Boolean = 1, charset As %String = "", ByRef count As %Integer) As %Status
{
 set msg=##class(%Net.MailMessagePart).%New()
 if isBinary {
	set msg.IsBinary=1
	set stream=msg.BinaryData
 } else {
	set msg.IsBinary=0
	set stream=msg.TextData
	set msg.Charset=""   ; charset of file unknown
	set ..TextData.TranslateTable="RAW"
 }

 ; link the file to stream
 set Dir=##class(%File).NormalizeDirectory(Dir)  ; normalize directory
 set status=stream.LinkToFile(Dir_File)
 if $$$ISERR(status) quit status
 if stream.AtEnd quit $$$ERROR($$$FileCanNotOpen,Dir_File)

 set count=..Parts.Count()+1
 set msg.Dir=Dir
 set msg.FileName=File
 do ..Parts.SetAt(msg,count)
 set ..IsMultiPart=1

 if ('isBinary) && (charset'="") set msg.Charset=charset

 quit $$$OK
}

/// Attach the contents of a stream to this message as another MIME part.
/// The attachment is considered a file attachment if <var>Filename</var> is specified.
/// Otherwise it is considered an inline attachment.
/// All attachments are sent as binary attachments by default.
/// However, a text attached may be attached by passing the third
/// argument, <i>isBinary</i>, as 0.  For text attachments, the <i>charset</i> 
/// may be passed as the fourth argument.<br>
/// The position in the Parts array of the message part that holds the file 
/// is returned in the <i>count</i> reference argument.  This count may be used to set
/// additional characteristics of the file such as Charset, 
/// e.g. set msg.Parts.GetAt(count).Charset="iso-8859-1".<br>
/// 
/// For example to send the attachememt as a text file in charset iso-8859-2:
/// <EXAMPLE>
/// set status=message.AttachFile(myCharacterStream,"test.txt",0,"iso-8859-1",.count)
/// if $$$ISERR(status) do handleError .....
/// </EXAMPLE>
/// Note that setting the Charset does not translate the attachment.  Rather it just
/// specifies the charset that already describes the file's data.
Method AttachStream(stream As %Stream.Object, Filename As %String, isBinary As %Boolean = 1, charset As %String = "", ByRef count As %Integer) As %Status
{
 set msg=##class(%Net.MailMessagePart).%New()
 if isBinary {
	set msg.IsBinary=1
	set status=msg.BinaryData.CopyFrom(stream)
 } else {
	set msg.IsBinary=0
	set msg.Charset=""   ; charset of file unknown
	set ..TextData.TranslateTable="RAW"
	set status=msg.TextData.CopyFrom(stream)
 }
 if $$$ISERR(status) quit status

 set count=..Parts.Count()+1
 set msg.FileName=Filename
 do ..Parts.SetAt(msg,count)
 set ..IsMultiPart=1
 set msg.InlineAttachment=(Filename="")

 if ('isBinary) && (charset'="") set msg.Charset=charset

 quit $$$OK
}

/// If message is associated with an attached file, get the filename 
Method GetFileName() As %String [ CodeMode = expression ]
{
..FileName
}

/// Attach message to current message. 
/// Return oref of attached message, so more things can be attached to the attachment 
Method AttachNewMessage() As %Net.MailMessagePart
{
 set msg=##class(%Net.MailMessagePart).%New()
 set count=..Parts.Count()+1
 do ..Parts.SetAt(msg,count)
 set ..IsMultiPart=1
 quit msg
}

/// Attach email message to current message. 
Method AttachEmail(mailmsg As %Net.MailMessage)
{
 set msg=..AttachNewMessage()
 do msg.Parts.SetAt(mailmsg,1)
 set msg.ContentType="message/rfc822"
 set msg.IsMultiPart=1
}

/// <P>Call this method with a header value, for example, "content-disposition" and 
/// the name of an attribute, for example, "filename" 
/// to obtain the value of the MIME attribute for this message part.</P>
/// <P>This only works after a message has been received in POP3 not when a message 
/// is being composed in SMTP.</P> 
Method GetAttribute(header As %String, name As %String) As %String
{
 quit $$getAttribute^%apiPOP3($$parseMimeField^%apiPOP3(..Headers.GetAt(header)),name)
}

Storage Default
{
<Data name="MailMessagePartState">
<Value name="1">
<Value>BinaryData</Value>
</Value>
<Value name="2">
<Value>Charset</Value>
</Value>
<Value name="3">
<Value>ContentType</Value>
</Value>
<Value name="4">
<Value>Dir</Value>
</Value>
<Value name="5">
<Value>FileName</Value>
</Value>
<Value name="6">
<Value>Headers</Value>
</Value>
<Value name="7">
<Value>IsBase64</Value>
</Value>
<Value name="8">
<Value>IsBinary</Value>
</Value>
<Value name="9">
<Value>IsHTML</Value>
</Value>
<Value name="10">
<Value>IsMultiPart</Value>
</Value>
<Value name="11">
<Value>Parts</Value>
</Value>
<Value name="12">
<Value>TextData</Value>
</Value>
<Value name="13">
<Value>ContentTransferEncoding</Value>
</Value>
<Value name="14">
<Value>Debug</Value>
</Value>
<Value name="15">
<Value>MultiPartType</Value>
</Value>
<Value name="16">
<Value>PartIndex</Value>
</Value>
<Value name="17">
<Value>InlineAttachment</Value>
</Value>
</Data>
<State>MailMessagePartState</State>
<StreamLocation>^%Net.MailMessagePartS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
