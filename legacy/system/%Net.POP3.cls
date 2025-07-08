/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on using this class</b>, see
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=CLASSES+%25Net.POP3">Sending and Receiving Email</a>.</p>
/// <P>Implements <CLASS>%Net.FetchMailProtocol</CLASS></P>
Class %Net.POP3 Extends %Net.FetchMailProtocol [ System = 3 ]
{

/// The port of the POP3 server, the default is 110 for plain text and 995 for SSL. 
Property port As %Integer;

/// Default port is 110 for plain text and 995 for SSL.
Method portGet() As %Integer [ CodeMode = expression, Internal ]
{
$select(i%port'="":i%port,1:$select('..UseSTARTTLS&&(..SSLConfiguration'=""):995,1:110))
}

/// The read timeout in seconds to use when communicating with the POP3 server
Property timeout As %Integer [ InitialExpression = 30 ];

/// The name of the activated TLS/SSL configuration to use for pop3s requests.
Property SSLConfiguration As %String;

/// If true then the STARTTLS extension to POP3 (RFC 2595) should be used to authenticate 
/// to the POP3 server on the normal POP3 port.
/// The SSLConfiguration must be specified.
Property UseSTARTTLS As %Boolean;

/// If IgnoreInvalidBase64Chars is true, then unexpected characters will be ignored during base64 decoding.
/// RFC 2045 is ambiguous about whether unexpected characters should be ignored or result in an error
/// during base64 decoding.
/// The default is false.
Property IgnoreInvalidBase64Chars As %Boolean [ InitialExpression = 0 ];

/// When making an SSL connection check the server identity in the server certificate matches the name of the system we are connecting to.
/// This defaults to being on and matches based on the rules layed out in section 3.1 of RFC 2818.
Property SSLCheckServerIdentity As %Boolean [ InitialExpression = 0 ];

/// TCP device actually used for communicating with the POP3 server.
Property dev As %String [ Internal ];

/// Branch of the temp global that stores the message.
Property Branch As %Integer [ Internal, Private ];

/// Cleanup the temp global used to store the message.
Method %OnClose() As %Status [ ProcedureBlock = 1, ServerOnly = 1 ]
{
	If ..Branch'="" Kill ^||%netTemp(..Branch)
	Quit $$$OK
}

/// <P>see <CLASS>%Net.FetchMailProtocol</CLASS> <METHOD>Connect</METHOD></P>
Method Connect(PopServer As %String, UserName As %String, Password As %String = "", AccessToken As %String = "") As %Status [ CodeMode = expression ]
{
..ConnectPort(PopServer,..port,UserName,Password,AccessToken)
}

/// <P>see <CLASS>%Net.FetchMailProtocol</CLASS> <METHOD>Connect</METHOD></P>
Method ConnectPort(PopServer As %String, PopPort As %Integer = 110, UserName As %String, Password As %String, AccessToken As %String = "") As %Status
{
 if ..Connected quit $$$ERROR($$$ConnectedError)
 
 if ..UseSTARTTLS,..SSLConfiguration="" quit $$$ERROR($$$STARTTLSConfigRequired)

 set opened=0
 set checkServerIdentity=0
 set iosave=$io
 set $ZTrap="ConnectError"

 set dev="|TCP|110"
 set timeout=..timeout
 if '..UseSTARTTLS,..SSLConfiguration'="" {
	if ..SSLCheckServerIdentity {
		open dev:(PopServer:PopPort:"CST":/TLS=..SSLConfiguration_"||"_PopServer):timeout
		set checkServerIdentity=1
	} else {
		open dev:(PopServer:PopPort:"CST":/TLS=..SSLConfiguration):timeout
	}
 } else {
 	open dev:(PopServer:PopPort:"CST"):timeout
 }
 else  quit $$$ERROR($$$POP3NoResponse,PopServer)
 set opened=1
 use dev
 do $zu(96,18,2,"RAW")  ; always input in RAW mode - conversions to be done later.
 read line:timeout
 if $P(line," ")'="+OK" use iosave close dev quit ..MailError(line)
 
 if ..UseSTARTTLS {
	write "STLS",!
	read line:timeout
	if $P(line," ")'="+OK" use iosave close dev quit ..MailError(line)
	if ..SSLCheckServerIdentity {
		use dev:(::/TLS=..SSLConfiguration_"||"_PopServer)
		set checkServerIdentity=1
	} else {
		use dev:(::/TLS=..SSLConfiguration)
	}
	do $zu(96,18,2,"RAW")  ; always input in RAW mode - conversions to be done later.
 }

 // if there is an access token, use OAuth
 if AccessToken'="" {
	write "AUTH XOAUTH2",!
	read line:timeout
	if $P(line, " ")'="+" use iosave close dev quit ..MailError(line)

	if checkServerIdentity {
		set sc=##class(%Net.HttpRequest).CheckSSLCN(PopServer)
		if $$$ISERR(sc) {
			use iosave
			close dev
			quit sc
		}
	}

	set oauthmessage = "user="_UserName_$c(1)_"auth=Bearer "_AccessToken_$c(1)_$c(1)
	write $system.Encryption.Base64Encode(oauthmessage,1),!
	read line:timeout
	if $P(line, " ")'="+OK" use iosave close dev quit ..MailError(line)

 }
 // if no access token, use basic auth
 else {
	write "USER "_UserName,!
	read line:timeout
	if $P(line," ")'="+OK" use iosave close dev quit ..MailError(line)

	if checkServerIdentity {
		set sc=##class(%Net.HttpRequest).CheckSSLCN(PopServer)
		if $$$ISERR(sc) {
			use iosave
			close dev
			quit sc
		}
	}

	write "PASS "_Password,!
	read line:timeout
	if $P(line," ")'="+OK" use iosave close dev quit ..MailError(line)
 }

 set ..dev=dev
 set ..Connected=1
 use iosave
 quit $$$OK
ConnectError
 set $ZTrap=""
 set sslerror=""
 if (..SSLConfiguration'="") {
	// Capture a description of the SSL/TLS error encountered, if any, during the most 
	// recent SSL/TLS operation over the current device.
 	try {
 		set sslerror=$System.Security.Users.SSLGetLastError()
 	} catch {}
 }
 if opened use iosave close dev
 if sslerror'="" {
	set sc=$$$ERROR($$$HttpRequestSSLError,..SSLConfiguration,sslerror)
 } else {
	set sc = $$$ERROR($$$ConnectionFailed)
 }

 quit sc
}

/// <P>see <CLASS>%Net.FetchMailProtocol</CLASS> <METHOD>GetMailBoxStatus</METHOD></P>
Method GetMailBoxStatus(ByRef NumberOfMessages As %Integer, ByRef NumberOfBytes As %Integer) As %Status
{
 if '..Connected quit $$$ERROR($$$NotConnectedError) ;'

 set iosave=$io
 set $ZTrap="GetMailBoxStatusError"
 use ..dev 
 write "STAT",!
 read line:..timeout 
 if $P(line," ")'="+OK" use iosave quit ..MailError(line)
 set NumberOfMessages=$P(line," ",2)
 set NumberOfBytes=$P(line," ",3)
 use iosave
 quit $$$OK
GetMailBoxStatusError
 set $ZTrap=""
 set ..Connected=0
 if ..dev'="" close ..dev
 set ..dev=0
 use iosave
 quit $$$ERROR($$$ConnectionTerminated)
}

/// <P>see <CLASS>%Net.FetchMailProtocol</CLASS> <METHOD>GetSizeOfMessages</METHOD></P>
Method GetSizeOfMessages(MessageNumber As %String = "", ByRef ListOfSizes As %ArrayOfDataTypes) As %Status
{
 if '..Connected quit $$$ERROR($$$NotConnectedError) ;'

 set iosave=$io
 set $ZTrap="GetSizeOfMessagesError"
 set ListOfSizes=##class(%ArrayOfDataTypes).%New()
 set timeout=..timeout
 use ..dev 
 if MessageNumber="" {
	write "LIST",!
	read line:timeout
	if $P(line," ")'="+OK"  use iosave quit ..MailError(line)
	while line'="." {
		read line:timeout
		if line'="." do ListOfSizes.SetAt($P(line," ",2),$P(line," ",1)) ;'
	}
 } else {
	write "LIST "_MessageNumber,!
	read line:timeout
	if $P(line," ")'="+OK"  use iosave quit ..MailError(line)
	do ListOfSizes.SetAt($P(line," ",3),$P(line," ",2))
 }
 use iosave
 quit $$$OK

GetSizeOfMessagesError
 set $ZTrap=""
 set ..Connected=0
 if ..dev'="" close ..dev
 set ..dev=0
 use iosave
 quit $$$ERROR($$$ConnectionTerminated)
}

/// <P>see <CLASS>%Net.FetchMailProtocol</CLASS> <METHOD>GetMessageUIDArray</METHOD></P>		
Method GetMessageUIDArray(MessageNumber As %String = "", ByRef ListOfUniqueIDs As %ArrayOfDataTypes) As %Status
{
 if '..Connected quit $$$ERROR($$$NotConnectedError) ;'

 set iosave=$io
 set $ZTrap="GetMessageUIDArrayError"
 set ListOfUniqueIDs=##class(%ArrayOfDataTypes).%New()
 set timeout=..timeout
 use ..dev
 if MessageNumber="" {
	write "UIDL",!
	read line:timeout
	if $P(line," ")'="+OK" use iosave quit ..MailError(line)
	while line'="." {
		read line:timeout
		if line'="." do ListOfUniqueIDs.SetAt($P(line," ",2),$P(line," ",1)) ;'
	}
 } else {
	write "UIDL "_MessageNumber,!
	read line:timeout
	if $P(line," ")'="+OK" use iosave quit ..MailError(line)
	do ListOfUniqueIDs.SetAt($P(line," ",3),$P(line," ",2))
 }

 use iosave
 quit $$$OK
GetMessageUIDArrayError
 set $ZTrap=""
 set ..Connected=0
 if ..dev'="" close ..dev
 set ..dev=0
 use iosave
 quit $$$ERROR($$$ConnectionTerminated)
}

/// <P>see <CLASS>%Net.FetchMailProtocol</CLASS> <METHOD>GetMessageUID</METHOD></P>		
Method GetMessageUID(MessageNumber As %Integer, ByRef UniqueID As %String) As %Status
{
 if $get(MessageNumber)="" quit $$$ERROR($$$POP3MessageNumber)
 if '..Connected quit $$$ERROR($$$NotConnectedError) ;'

 set iosave=$io
 set $ZTrap="GetMessageUIDError"
 set timeout=..timeout
 use ..dev 
 write "UIDL "_MessageNumber,!
 read line:timeout
 if $P(line," ")'="+OK" use iosave quit ..MailError(line)
 set UniqueID=$P(line," ",3)
 use iosave
 quit $$$OK
GetMessageUIDError
 set $ZTrap=""
 set ..Connected=0
 if ..dev'="" close ..dev
 set ..dev=0
 use iosave
 quit $$$ERROR($$$ConnectionTerminated)
}

/// <P>see <CLASS>%Net.FetchMailProtocol</CLASS> <METHOD>Fetch</METHOD></P>
Method Fetch(MessageNumber As %Integer, ByRef MailMsg As %Net.MailMessage, Delete As %Boolean = 0, messageStream As %BinaryStream) As %Status
{
 if $get(MessageNumber)="" quit $$$ERROR($$$POP3MessageNumber)
 if '..Connected quit $$$ERROR($$$NotConnectedError) ;'

 set iosave=$io
 set $ZTrap="FetchMessageError"
 new %timeout set %timeout=..timeout
 if ..Branch'="" kill ^||%netTemp(..Branch)
 set ..Branch=$i(^||%netTemp)
 set glv="^||%netTemp("_..Branch_")"
 kill foo ; no logging
 set MessageSize=0 ; need to get back from %apiPOP3
 set success=$$message^%apiPOP3(MessageNumber,glv,"foo",.MessageSize)
 use iosave
 set $ZTrap="FetchUnexpectedError"
 if +success=0 quit ..MailError($piece(success,"^",2))
 
 If $data(messageStream) {
	 do toStream^%apiPOP3(messageStream,glv,"foo")
 }

 set sc=..GetMailMessage(glv,1,.MailMsg)
 set MailMsg.MessageSize=MessageSize
 if $$$ISERR(sc) quit sc

 if Delete quit ..DeleteMessage(MessageNumber)
 quit $$$OK

FetchMessageError
 set $ZTrap=""
 set ..Connected=0
 if ..dev'="" close ..dev
 set ..dev=0
 use iosave
 quit $$$ERROR($$$ConnectionTerminated)
FetchUnexpectedError
 set $ZTrap=""
 quit $$$ERROR($$$POP3UnexpectedError,$ze)
}

/// <P>see <CLASS>%Net.FetchMailProtocol</CLASS> <METHOD>FetchFromStream</METHOD></P>
Method FetchFromStream(messageStream As %BinaryStream, ByRef MailMsg As %Net.MailMessage) As %Status
{
 set $ZTrap="FetchFromStreamError"
 if ..Branch'="" kill ^||%netTemp(..Branch)
 set ..Branch=$i(^||%netTemp)
 set glv="^||%netTemp("_..Branch_")"
 kill foo ; no logging
 set MessageSize=0 ; need to get back from %apiPOP3
 set success=$$messageStream^%apiPOP3(messageStream,glv,"foo",.MessageSize)
 if +success=0 quit ..MailError($piece(success,"^",2))
 
 set sc=..GetMailMessage(glv,1,.MailMsg)
 set MailMsg.MessageSize=MessageSize

 quit sc

FetchFromStreamError
 set $ZTrap=""
 quit $$$ERROR($$$POP3UnexpectedError,$ze)
}

/// <P>see <CLASS>%Net.FetchMailProtocol</CLASS> <METHOD>FetchMessage</METHOD></P>
Method FetchMessage(MessageNumber As %Integer, ByRef From As %String, ByRef To As %String, ByRef Date As %String, ByRef Subject As %String, ByRef MessageSize As %Integer, ByRef MsgHeaders As %ArrayOfDataTypes, ByRef MailMsg As %Net.MailMessage, Delete As %Boolean = 0) As %Status
{
 set status=..Fetch($get(MessageNumber),.MailMsg,Delete)
 quit:$$$ISERR(status) status

 set MsgHeaders=MailMsg.Headers
 set To=MsgHeaders.GetAt("to")
 set From=MailMsg.From
 set Date=MailMsg.Date
 set Subject=MailMsg.Subject
 set MessageSize=MailMsg.MessageSize

 quit $$$OK
}

/// Convert a part that represents an email message to %Net.MailMessage object
Method GetMailMessage(glv As %String, part As %Integer, Output mailmsg As %Net.MailMessage) As %Status [ Internal, Private, ProcedureBlock = 1 ]
{
 set sc=$$$OK
 set mailmsg=##class(%Net.MailMessage).%New()

 set $ZTrap="GetMailUnexpectedError"

 ; walk glv global and build all message parts
 do ..WalkParts(glv,part,mailmsg)

GetMailExit
 set msgheaders=mailmsg.Headers
 do ..SetDestList(mailmsg.To,msgheaders.GetAt("to"))
 do ..SetDestList(mailmsg.Cc,msgheaders.GetAt("cc"))
 do ..SetDestList(mailmsg.Bcc,msgheaders.GetAt("bcc"))
 set mailmsg.From=msgheaders.GetAt("from")
 set mailmsg.Date=msgheaders.GetAt("date")
 set mailmsg.Subject=msgheaders.GetAt("subject")
 set mailmsg.Sender=msgheaders.GetAt("sender")
 set mailmsg.ReplyTo=msgheaders.GetAt("reply-to")
 
 quit sc

GetMailUnexpectedError
 set $ZTrap=""
 set sc=$$$ERROR($$$POP3UnexpectedError,$ze)
 goto GetMailExit
}

/// Convert the text of an attached email (Content-Type: message/rfc822) to a %Net.mailMessage.
Method GetAttachedEmail(msgpart As %Net.MailMessagePart, Output mailmsg As %Net.MailMessage) As %Status [ ProcedureBlock = 1 ]
{
 // If not an attached email return ""
 if msgpart.ContentType'="message/rfc822" quit ""

 // If already converted to %Net.MailMessage, then just return it.
 if msgpart.Parts.GetAt(1)'="" quit msgpart.Parts.GetAt(1)
 
 // Fetch must have been previously called
 If ..Branch="" Quit $$$ERROR($$$POP3NoFetch)

 // Find location of attached email and parse it.
 set glv="^||%netTemp("_..Branch_")"
 set descriptor=@glv@(msgpart.PartIndex)
 set first=$piece(descriptor," ",3)
 set last=$piece(descriptor," ",4)
 set partindex=$$parseMessage^%apiPOP3(glv,first,last)
 
 // Return the attached mail message
 quit ..GetMailMessage(glv,partindex,.mailmsg)
}

Method WalkParts(glv As %String, part As %Integer, msgpart As %Net.MailMessagePart) [ Internal, Private ]
{
 ;  message(part)   numbers separated by spaces:
 ;                  1. First header line #
 ;                  2. Last  header line # + 1
 ;                  3. First message body line #
 ;                  4. Last  message body line # + 1
 ;                  5+ Message part indices
 ;                  (for MIME multipart content-type only)
 ;
 ;              message(1,name) value of a header field;
 ;                              name in the second subscript
 ;                              is CONVERTED to lower case;
 ;                              multiple values of the same field
 ;                              are delimited by CRLF
 ; fetch headers
 set index=$order(@glv@(part,""))
 while index'="" {
	do msgpart.Headers.SetAt(##class(%Net.MIMEReader).DecodeHeader(@glv@(part,index)),index)
	set index=$order(@glv@(part,index))
 }
 
 ; process rest of part
 set descriptor=@glv@(part)
 set type=$zcvt($$GetContentType^%apiPOP3(glv,part),"L")
 set messageparts=$P(descriptor," ",5,$L(descriptor," "))
 if messageparts'="" {  ;' this is a multipart message
	set msgpart.IsMultiPart=1
	if $zstrip($piece(type,";"),"<>W")="multipart/alternative" set msgpart.IsAlternative=1
	set i=1
	set p=$P(messageparts," ",1)
	while p'="" {
		set m=##class(%Net.MailMessagePart).%New()
		set m.PartIndex=p
		do msgpart.Parts.SetAt(m,i)
		do ..WalkParts(glv,p,m)
		set i=i+1
		set p=$P(messageparts," ",i)
	}
 } else {  ; this is not multipart
	; find out if binary or non-binary and write to appropriate stream
	set msgpart.ContentTransferEncoding=$$GetContentEncoding^%apiPOP3(glv,part)
	if (type="") && (msgpart.ContentTransferEncoding="") set msgpart.ContentTransferEncoding="7bit"
	set msgpart.ContentType=$zstrip($piece(type,";"),"<>W")
	set charset=""
	if (type'="") && $case($piece(type,"/",1),"text":0,"message":0,:1) {
		set stream=msgpart.BinaryData
		set msgpart.IsBinary=1
	} else {
		set msgpart.IsBinary=0
		set msgpart.IsHTML=($piece(type,";",1)="text/html")
		set charset=$zcvt($$GetCharset^%apiPOP3(glv,part),"L")
		; always write file as RAW to copy message from POP# server
		set stream=msgpart.TextData
		set stream.TranslateTable="RAW"
	}

	set bAttach=0
	set contentDisposition=$zcvt($piece(msgpart.Headers.GetAt("content-disposition"),";",1),"L")
	if $case(contentDisposition,"attachment":1,"inline":1,:0) {
		set filename=##class(%Net.MIMEReader).DecodeHeader($$GetFileName^%apiPOP3(glv,part))
		if filename="" set filename=##class(%Net.MIMEReader).DecodeHeader($$GetContentFileName^%apiPOP3(glv,part))
		if (..StoreAttachToFile && (contentDisposition="attachment")) ||
		   (..StoreInlineToFile && (contentDisposition="inline")) {
			set dir=##class(%File).NormalizeDirectory(..AttachDir)
			if filename="" {
				#; create a reasonable short filename based on current time
				do {
					set t=$ztimestamp
					set t=(((t-58211)*86400)+$p(t,",",2))*100000000\1+$R(100000)
					set filename="" for  set filename=filename_$c((t#32)+65),t=t\32 quit:'t
					set filename=$reverse($tr(filename,$c(91,92,93,94,95,96),"234689"))
					set filename="ATT"_filename_".dat"
				} while ##class(%File).Exists(dir_filename)
			}
			set path=dir_filename
			do ##class(%File).Delete(path)
			do stream.LinkToFile(path)
			set bAttach=1
		}

		set msgpart.FileName=filename
	}
	
	set success=$$fetchPart^%apiPOP3(glv,part,stream,..IgnoreInvalidBase64Chars)
	
	if ..StoreAttachToFile && bAttach {
		do stream.SaveStream()
	}
	
	#; Don't set Charset until last to avoid character conversions.
	if charset'="" set msgpart.Charset=charset
 }
}

Method FetchMessageInfo(MessageNumber As %Integer, Lines As %Integer, ByRef From As %String, ByRef To As %String, ByRef Date As %String, ByRef Subject As %String, ByRef MessageSize As %Integer, ByRef MsgHeaders As %ArrayOfDataTypes, ByRef MessageText As %String) As %Status
{
 if $get(MessageNumber)="" quit $$$ERROR($$$POP3MessageNumber)
 if '..Connected quit $$$ERROR($$$NotConnectedError) ;'

 set iosave=$io
 set $ZTrap="FetchMessageInfoError"
 set timeout=..timeout
 use ..dev 
 write "TOP "_MessageNumber_" "_Lines,!
 read line:timeout
 if $P(line," ")'="+OK" use iosave quit ..MailError(line)
 if line="" use iosave quit $$$ERROR($$$POP3BlankLine)
 set status=..GetHeadersAndBody(.From,.To,.Date,.Subject,.MsgHeaders,.MessageText) 
 if $$$ISOK(status) {
	write "LIST "_MessageNumber,!
	read line:timeout
	if $P(line," ")="+OK" {
		set MessageSize=$P(line," ",3)
	} else {
		set status=$$$ERROR($$$POP3CommandError,"LIST",line)
	}
 }
 use iosave
 quit status
FetchMessageInfoError
 set $ZTrap=""
 set ..Connected=0
 if ..dev'="" close ..dev
 set ..dev=0
 use iosave
 quit $$$ERROR($$$ConnectionTerminated)
}

/// Assumes current device is TCP socket to POP3 server.
Method GetHeadersAndBody(ByRef From As %String, ByRef To As %String, ByRef Date As %String, ByRef Subject As %String, ByRef MsgHeaders As %ArrayOfDataTypes, MessageText As %String) As %Status [ Internal, Private ]
{
 ; In RFC822 (non-MIME) and in MIME the message text is separated from
 ; the headers by a blank line
 set timeout=..timeout
 set MsgHeaders=##class(%ArrayOfDataTypes).%New()
 set MessageText=""
 set headerNum=0
 do {
	read line:timeout
	if line'="" {
		if ..BeginsWithSpace(line)&&(headerNum>0) {
			set strippedLine=$zstrip(line,"<W")
			set sep=" "
			set word=$piece($tr(strippedLine,$c(9)," ")," ",1)
			if ($length(word,"?=")>1) && ($extract($piece(word,"?",5))="=") set sep=""
			set headerLines(headerNum)=headerLines(headerNum)_sep_strippedLine
		} else {
			set headerNum=headerNum+1
			set headerLines(headerNum)=line
		}
	}
 } while line'=""
 set done=0
 while 'done {
	read line:timeout
	if $extract(line)="." {
		set $extract(line)=""
		set:line="" done=1
	}
	set:line'="" MessageText=MessageText_line_$C(13,10)
 }

 ; set headers we have gathered at beginning
 set $ZTrap="FetchMessageInfoUnexpectedError"
 set headerIndex=$o(headerLines(""))
 while headerIndex'="" {
	set headerLine=headerLines(headerIndex)
	if headerLine'="" {
		set hdr=$zconvert($piece(headerLine,":",1),"L")
		set line=##class(%Net.MIMEReader).DecodeHeader($zstrip($extract(headerLine,$length(hdr)+2,$length(headerLine)),"<W"))
		if MsgHeaders.GetAt(hdr)="" {
			do MsgHeaders.SetAt(line,hdr)
		} else {	
			do MsgHeaders.SetAt(MsgHeaders.GetAt(hdr)_$C(13,10)_line,hdr)
		}
	}
	set headerIndex=$o(headerLines(headerIndex))
 }
 set To=MsgHeaders.GetAt("to") ;
 set From=MsgHeaders.GetAt("from") ;
 set Date=MsgHeaders.GetAt("date") ;
 set Subject=MsgHeaders.GetAt("subject") ;

 quit $$$OK
FetchMessageInfoUnexpectedError
 set $ZTrap=""
 quit $$$ERROR($$$POP3UnexpectedError,$ze)
}

/// <P>see <CLASS>%Net.FetchMailProtocol</CLASS> <METHOD>FetchMessageHeaders</METHOD></P>		
Method FetchMessageHeaders(MessageNumber As %Integer, ByRef MsgHeadersArray As %String) As %Status
{
 if $get(MessageNumber)="" quit $$$ERROR($$$POP3MessageNumber)
 if '..Connected quit $$$ERROR($$$NotConnectedError) ;'

 set iosave=$io
 set $ZTrap="FetchMessageHeadersError"
 set timeout=..timeout
 use ..dev 
 write "TOP "_MessageNumber_" 0",!
 read line:timeout
 if $P(line," ")'="+OK" use iosave quit ..MailError(line)
 if line="" use iosave quit $$$ERROR($$$POP3BlankLine)
 set status=..GetHeadersArray(.MsgHeadersArray)
 use iosave
 quit status
FetchMessageHeadersError
 set $ZTrap=""
 set ..Connected=0
 if ..dev'="" close ..dev
 set ..dev=0
 use iosave
 quit $$$ERROR($$$ConnectionTerminated)
}

/// Assumes current device is TCP socket to POP3 server.
Method GetHeadersArray(Output MsgHeadersArray As %String) As %Status [ Internal ]
{
 ; In RFC822 (non-MIME) and in MIME the message text is separated from
 ; the headers by a blank line
 Kill MsgHeadersArray
 set timeout=..timeout
 set headerNum=0
 do {
	 read line:timeout
	 if line'="" {
		 if ..BeginsWithSpace(line)&&(headerNum>0) {
			 set strippedLine=$zstrip(line,"<W") 
			 set sep=" "
			 set word=$piece($tr(strippedLine,$c(9)," ")," ",1)
			 if ($length(word,"?=")>1) && ($extract($piece(word,"?",5))="=") set sep=""
			 set headerLines(headerNum)=headerLines(headerNum)_sep_strippedLine
		 } else {
			 set headerNum=headerNum+1
			 set headerLines(headerNum)=line
		 }
	 }
 } while line'=""
 set done=0
 while 'done {
	 read line:timeout
	 if $extract(line)="." {
		 set $extract(line)=""
		 set:line="" done=1
	 }
	 ;set:line'="" MessageText=MessageText_line_$C(13,10)
 }
 ; set headers we have gathered at beginning
 set $ZTrap="FetchMessageHeadersUnexpected"
 set headerIndex=$o(headerLines(""))
 while headerIndex'="" {
	 set headerLine=headerLines(headerIndex)
	 if headerLine'="" {
		 set hdr=$zconvert($piece(headerLine,":",1),"L")
		 set line=##class(%Net.MIMEReader).DecodeHeader($zstrip($extract(headerLine,$length(hdr)+2,$length(headerLine)),"<W"))
		 if $Get(MsgHeadersArray(hdr))="" {
			 Set MsgHeadersArray(hdr)=line
		 } else {	
			 Set MsgHeadersArray(hdr)=MsgHeadersArray(hdr)_$C(13,10)_line
		 }
	 }
	 set headerIndex=$o(headerLines(headerIndex))
 }
 quit $$$OK
FetchMessageHeadersUnexpected
 set $ZTrap=""
 quit $$$ERROR($$$POP3UnexpectedError,$ze)
}

/// <P>see <CLASS>%Net.FetchMailProtocol</CLASS> <METHOD>DeleteMessage</METHOD></P>		
Method DeleteMessage(MessageNumber As %Integer) As %Status
{
 if $get(MessageNumber)="" quit $$$ERROR($$$POP3MessageNumber)
 if '..Connected quit $$$ERROR($$$NotConnectedError) ;'

 set iosave=$io
 set timeout=..timeout
 set $ZTrap="DeleteMessageError"
 use ..dev 
 write "DELE "_MessageNumber,!
 read line:timeout
 if $P(line," ")'="+OK" use iosave q ..MailError(line)
 use iosave
 quit $$$OK
DeleteMessageError
 set $ZTrap=""
 set ..Connected=0
 if ..dev'="" close ..dev
 set ..dev=0
 use iosave
 quit $$$ERROR($$$ConnectionTerminated)
}

/// <P>see <CLASS>%Net.FetchMailProtocol</CLASS> <METHOD>RollbackDeletes</METHOD></P>		
Method RollbackDeletes() As %Status
{
 if '..Connected quit $$$ERROR($$$NotConnectedError) ;'

 set iosave=$io
 set $ZTrap="RollbackDeletesError"
 set timeout=..timeout
 use ..dev
 write "RSET",!
 read line:timeout
 if $P(line," ")'="+OK" use iosave quit ..MailError(line)
 use iosave
 quit $$$OK
RollbackDeletesError
 set $ZTrap=""
 set ..Connected=0
 if ..dev'="" close ..dev
 set ..dev=0
 use iosave
 quit $$$ERROR($$$ConnectionTerminated)
}

/// <P>see <CLASS>%Net.FetchMailProtocol</CLASS> <METHOD>QuitAndCommit</METHOD></P>
Method QuitAndCommit() As %Status
{
 if '..Connected quit $$$ERROR($$$NotConnectedError) ;'

 set iosave=$io
 set $ZTrap="QuitAndCommitError"
 set sc=$$$OK
 set timeout=..timeout
 use ..dev 
 write "QUIT",!
 read line:timeout
 if $P(line," ")'="+OK" set sc=..MailError(line)
 goto QuitAndCommitExit
QuitAndCommitError
 set $ZTrap=""
 set sc=$$$ERROR($$$ConnectionTerminated)
QuitAndCommitExit
 close ..dev
 set ..Connected=0
 set ..dev=0
 use iosave
 quit sc
}

/// <P>see <CLASS>%Net.FetchMailProtocol</CLASS> <METHOD>QuitAndRollback</METHOD></P>
Method QuitAndRollback() As %Status
{
 if '..Connected quit $$$ERROR($$$NotConnectedError) ;'

 set iosave=$io
 set sc=..RollbackDeletes()
 goto:$$$ISERR(sc) QuitAndRollbackExit
 set $ZTrap="QuitAndRollbackError"
 use ..dev 
 write "QUIT",!
 set sc=$$$OK
 goto QuitAndRollbackExit
QuitAndRollbackError
 set $ZTrap=""
 set sc=$$$ERROR($$$POP3TCPError,$ZE)
QuitAndRollbackExit
 close ..dev
 set ..Connected=0
 set ..dev=0
 use iosave
 quit sc
}

/// <P>see <CLASS>%Net.FetchMailProtocol</CLASS> <METHOD>Ping</METHOD></P>
Method Ping() As %Status
{
 if '..Connected quit $$$ERROR($$$NotConnectedError) ;'

 s iosave=$io
 set $ZTrap="PingError"
 use ..dev 
 set timeout=..timeout
 write "NOOP",!
 read line:timeout
 if $P(line," ")'="+OK"  use iosave quit ..MailError(line) ;'
 use iosave
 quit $$$OK
PingError
 set $ZTrap=""
 set ..Connected=0
 if ..dev'="" close ..dev
 set ..dev=0
 use iosave
 quit $$$ERROR($$$ConnectionTerminated)
}

Method SetDestList(destlist As %ListOfDataTypes, dests As %String) [ Internal, Private ]
{
 set count=$length(dests,",")
 for i=1:1:count {
	set address=$zstrip($piece(dests,",",i),"<>W")
	if address'="" do destlist.Insert(address)
 }
 quit
}

ClassMethod BeginsWithSpace(x As %String) As %Integer [ Internal, Private ]
{
 quit ($extract(x,1)=" ")!($extract(x,1)=$char(9))
}

ClassMethod MailError(line As %String) As %String [ Internal, Private ]
{
 quit $$$ERROR($$$POP3Error,line)
}

}
