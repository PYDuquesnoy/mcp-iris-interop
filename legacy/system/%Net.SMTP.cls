/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on using this class</b>, see
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=CLASSES+%25Net.SMTP">Sending and Receiving Email</a>.</p>
/// Send a SMTP mail message
/// <p>
/// The <property>Charset</property> property of each <class>%Net.MailMessagePart</class>
/// determines the charset 	for text MIME parts.  The charset property is ignored unless 
/// <property>ContentType</property>=text/...
/// <property>Charset</property> sets the Character Set for the content-type header.
/// IMPORTANT:  Charset must be set before any data is written to the TextData
/// stream associated with this <class>%Net.MailMessagePart</class>.
/// The Charset may also be initialized when the message 
/// is created by ##Class(%Net.MailMessagePart).%New(charset) or ##Class(%Net.MailMessage).%New(charset).  
/// For Unicode locale, the default Charset for ##Class(%Net.SMTP).%New() is utf-8.<p>
/// <EXAMPLE>
/// #include %occOptions
/// #include %occStatus
/// 
/// testmailsend3 ;
/// ;  Replace information marked with [[ ]]
/// 
/// new attached,err,m,nestedm,s,status
/// set s=##class(%Net.SMTP).%New()
/// set s.smtpserver=[["SMTP server name"]]
/// set s.timezone=[["-0400"]]  may remove this line to get Universal Time
/// set m=##class(%Net.MailMessage).%New()
/// set m.From=[["test@company.com"]]
/// // Either address with name or just email address supported.
/// do m.To.Insert([["receiver@another.com"]])
/// do m.To.Insert([["Joe Smith <jsmith@another.com>"]])
/// write !,"s.port="_s.port
/// write !,"s.localhost="_s.localhost
/// set m.Subject="Sent by InterSystems IRIS mail"
/// set m.Charset="iso-8859-1"
/// set status=m.TextData.Write("This is the main body.")
/// if $$$ISERR(status) do $system.OBJ.DisplayError(status) quit
/// set status=m.TextData.Write($char(13,10))
/// if $$$ISERR(status) do $system.OBJ.DisplayError(status) quit
/// set status=m.TextData.Write("This is the second line.")
/// if $$$ISERR(status) do $system.OBJ.DisplayError(status) quit
/// set status=m.TextData.Write($char(13,10))
/// if $$$ISERR(status) do $system.OBJ.DisplayError(status) quit
/// set status=m.AttachFile("c:\winnt","notepad.exe")
/// if $$$ISERR(status) do $system.OBJ.DisplayError(status) quit
/// // Attach a text file with charset=iso-8859-1
/// set status=m.AttachFile("d:\temp","test.txt",0,"iso-8859-1")
/// if $$$ISERR(status) do $system.OBJ.DisplayError(status) quit
/// set nestedm=m.AttachNewMessage()
/// // Attach a binary file
/// set status=nestedm.AttachFile("c:\irissys\bin","test.bin")
/// if $$$ISERR(status) do $system.OBJ.DisplayError(status) quit
/// write !,"m.Parts.Count()="_m.Parts.Count()
/// write !,"m.Parts.GetAt(3).Parts.GetAt(1).FileName="_m.Parts.GetAt(3).Parts.GetAt(1).FileName
/// write !,"m.Parts.GetAt(3).Parts.Count()="_m.Parts.GetAt(3).Parts.Count()
/// set status=s.Send(m)
/// if $$$ISERR(status) do $system.OBJ.DisplayError(status)
/// quit
/// 
/// </EXAMPLE>
Class %Net.SMTP Extends %RegisteredObject [ System = 3 ]
{

/// The sending host, default is $ZU(110). 
Property localhost As %String(TRUNCATE = 1) [ InitialExpression = {$ZU(110)} ];

/// The port of the SMTP server, the default is 25 for plain text and 465 for SSL. 
Property port As %String(MAXLEN = 100, TRUNCATE = 1);

/// Default port is 25 for plain text and 465 for SSL.
Method portGet() As %String [ CodeMode = expression, Internal ]
{
$select(i%port'="":i%port,1:$select('..UseSTARTTLS&&(..SSLConfiguration'=""):465,1:25))
}

/// the name of the SMTP server 
Property smtpserver As %String(MAXLEN = 100, TRUNCATE = 1);

/// The name of the activated TLS/SSL configuration to use for smpts requests.
Property SSLConfiguration As %String;

/// If true then the STARTTLS extension to SMTP (RFC 3207) should be used to authenticate 
/// to the SMTP server on the normal SMTP port.
/// The SSLConfiguration must be specified.
Property UseSTARTTLS As %Boolean;

/// When making an SSL connection check the server identity in the server certificate matches the name of the system we are connecting to.
/// This defaults to being on and matches based on the rules layed out in section 3.1 of RFC 2818.
Property SSLCheckServerIdentity As %Boolean [ InitialExpression = 1 ];

/// If false (as is the default), Send() will fail if there is an authenticator present but authentication with the server fails.
/// If true, Send() will ignore a failure to authenticate and proceed with sending without authentication.
/// If no authenticator is present, authentication is never attempted and so this property is ignored.
Property IgnoreFailedAuth As %Boolean [ InitialExpression = 0 ];

/// timezone as specified by RFC822, for example "EST", "PDT", "-0400".
/// If timezone is "LOCAL", then the local timezone expressed as "+nnnn" or "-nnnn" is used.
/// If timezone is not set, then "UT" is used for the timezone and
/// universal time is used in the message.
Property timezone As %String(MAXLEN = 100, TRUNCATE = 1);

/// If ShowBcc = true (1), then Bcc headers will be written to the email message.
/// The Bcc headers will usually be filtered out by the SMTP server.
Property ShowBcc As %Boolean;

/// To do SMTP authentication with the SMTP server (as defined by RFC 2554),
/// instantiate a <class>%Net.Authenticator</class> object, set UserName 
/// and Password properties of the authenticator and assign it to this property.
/// An example of the use of authenticator follows.
/// <EXAMPLE>
/// #include %occOptions
/// #include %occStatus
/// 
/// authtestmailsend ;
/// ;  Replace information marked with [[ ]]
/// 
/// new auth,m,s,status
/// set s=##class(%Net.SMTP).%New()
/// set auth=##class(%Net.Authenticator).%New() ; use default authentication list
/// set auth.UserName=[["myUser"]]
/// set auth.Password=[["myPassword"]]
/// set s.authenticator=auth
/// set s.smtpserver=[["SMTP server name"]]
/// set s.timezone=[["-0400"]]  may remove this line to get Universal Time
/// set m=##class(%Net.MailMessage).%New()
/// set m.From=[["test@company.com"]]
/// do m.To.Insert([["receiver@another.com"]])
/// do m.To.Insert([["Joe Smith <jsmith@another.com>"]])
/// set m.Subject="Sent by InterSystems IRIS mail"
/// set m.Charset="iso-8859-1"
/// do m.TextData.Write("This message has been sent using an SMTP server with Authentication.")
/// set status=s.Send(m)
/// if $$$ISERR(status) do $system.OBJ.DisplayError(status)
/// quit
/// 
/// </EXAMPLE>
Property authenticator As %Net.Authenticator;

/// <property>AuthFrom</property> specifies the address to be used for the
/// AUTH parameter of the MAIL FROM SMTP command for SMTP authenticated session.
/// If specified, this property will be the argument of the AUTH= extension to the
/// MAIL FROM command.  This property may be specified as "&lt;&gt;" to indicate that the
/// original submitter of the messge is not known.
Property AuthFrom As %String(MAXLEN = 255, TRUNCATE = 1);

/// If true, the <method>Send</method> method will encode non-ASCII header
/// text according to the rules specified by RFC 2047.  This is the default.
/// Some mail readers do not accept the encoding specified by RFC 2047 and
/// thus we allow disabling this encoding by setting AllowHeaderEncoding=false.
Property AllowHeaderEncoding As %Boolean [ InitialExpression = 1 ];

/// If Send is called and returns an error status, the error
/// message is in the Error property.
Property Error As %String(MAXLEN = 255, TRUNCATE = 1);

/// If true, sending the email will continue if a send fails and failed email
/// addresses will be added to the FailedSend list.
Property ContinueAfterBadSend As %Boolean [ InitialExpression = 0 ];

/// A list of email addresses for which the Send failed.
/// If the Send for any address is successful, then a %Status of $$$OK
/// is returned by Send and this list contains any failed addresses.
/// If Send is not successful for any email address, then an %Status of
/// $$$SMTPNoSend and all address on this list.
/// Use (sender.FailedSend.Count()=0) to test if all sends succeeded.
Property FailedSend As list Of %String(MAXLEN = 8000, TRUNCATE = 1);

/// <property>IPVersion</property> specifies the versin of IP address to be used
/// to connect SMTP server. The valid values are:<br>
/// 0 - Try to connect with IPV4 first if failed then try it again with IPV6.<br>
/// 4 - Connect to SMTP server with IPV4 address.<br>
/// 6 - Connect to SMTP server with IPV6 address.<br>
/// All other values are treated as 0.<br>
Property IPVersion As %Integer [ InitialExpression = 0 ];

/// The %Status to be returned by send.
/// Do not set directly, use SetStatus.
Property Status As %Status [ Internal, Private ];

/// The charset to be used for header fields
Property HeaderCharset As %String(TRUNCATE = 1) [ Internal, Private ];

/// The translate table to be used for header fields
Property HeaderTable As %String(TRUNCATE = 1) [ Internal, Private ];

Property bufcount As %Integer [ InitialExpression = 1 ];

Property Debug As %Integer [ InitialExpression = 0 ];

/// A mapping of SMTP commands to the timeouts (in seconds) used for them.<br>
/// By default, timeouts based on RFC 1123 guidelines are used. <br>
/// <p>The keys "EHLO", "HELO", "MAIL, "RCPT", "DATA", "AUTH", "STARTTLS", "QUIT", and "RSET" are supported
/// to specify the timeout when waiting for a server response to the corresponding commands. The following special values are also supported:</p>
/// <ul>
/// <li>"_initial" - Set the timeout used when waiting for the initial greeting from the server</li>
/// <li>"_data termination" - Set the timeout used when waiting for the server response to the termination of the message data</li>
/// </ul>
/// If a negative timeout value is specified, it will be ignored and the default will be used instead. <br>
/// 
/// Below is an example of how to use this property to configure the timeouts. 
/// <EXAMPLE>
/// set s=##class(%Net.SMTP).%New()
/// set s.Timeouts("EHLO") = 100 ; use a 100s timeout when waiting for a response to the EHLO command
/// set s.Timeouts("MAIL") = 200 ; use a 200s timeout when waiting for a response to the MAIL command
/// </EXAMPLE>
Property Timeouts [ MultiDimensional ];

/// The key used to get the timeout when waiting for the initial server greeting. 
Parameter TimeoutKeyInitial [ Internal ] = "_initial";

/// The key used to get the timeout when waiting for the server response to the termination of the message data
Parameter TimeoutKeyDataTermination [ Internal ] = "_data termination";

Parameter Base64Seq = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

Parameter PrintableAscii = " !""""#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~";

Method WriteText(text As %String, logMessage As %String = "From client") [ Internal, Private ]
{
	$$$SysLog(3, "SMTP", logMessage, text)
	write text
}

Method WriteLine(text As %String, logMessage As %String = "From client") [ Internal, Private ]
{
	do ..WriteText(text, logMessage)
	write !
}

/// Get response to mail command.  Use timeout as specified by RFC1123. 
Method GetResponse(timeout As %Integer, ByRef responseArray As %String) As %String [ Internal, Private ]
{
 kill responseArray
 set line=""
 do {
 	read line:timeout
 	else  do ..SetStatus($$$ERROR($$$SMTPTimeout)) set line=""
 	set responseArray($increment(responseArray))=line
	$$$SysLog(3, "SMTP", "Response from server", line)
 } while $extract(line,4)="-"
 quit line
}

/// Get the email part of a full address.
Method GetEmail(s As %String) As %String [ Internal, Private ]
{
 set s=$extract(s,$find(s,"<"),$length(s))
 set end=$find(s,">")
 if end'=0 set s=$extract(s,1,end-2)
 quit $zstrip(s,"<>W")
}

/// Used to send msg to SMTP server.
/// <p>Returns a %Status to indicate success or failure.
/// <p>The <method>send</method> supports the following small subset of permissible
/// message header fields. Set the corresponding MailMessage properties before
/// invoking send. 
/// <ul>
/// <li>Date - set from msg.Date; will be set to the current date and time if not specified</li>
/// <li>From - set from msg.From</li>
/// <li>Subject - set from msg.Subject</li>
/// <li>To - set from msg.To by converting to "," separated list</li>
/// <li>Cc - optionally set from msg.Cc by converting to "," separated list</li>
/// <li>Bcc - optionally set from msg.Bcc by converting to "," separated list</li>
/// <li>Sender - optionally set from msg.Sender</li>
/// <li>Reply-To - optionally set from msg.ReplyTo</li>
/// </ul>
/// <p>The "MAIL FROM:" SMTP command uses the Sender field if specified, otherwise the From field.
/// <br>The "RCPT TO:" SMTP command uses the To and Cc lists joined by commas.
/// <br>simple e-mail address must be passed to MAIL and RCPT.
/// Therefore if the address is of the form <i>name &lt;email&gt;</i>,
/// the value passed to the SMTP command is just <i>email</i>.
/// <p>
Method Send(msg As %Net.MailMessage) As %Status [ ProcedureBlock = 1 ]
{
 set ..FailedSend=""
 set sends=0
 set sc=$$$OK
 if msg.From="" {
 	set sc=$$$ERROR($$$SMTPProperty,"From")
 } elseif +msg.To.Count()+msg.Cc.Count()+msg.Bcc.Count()=0 {
	set sc=$$$ERROR($$$SMTPProperty,"To or Cc or Bcc")
 } elseif ..smtpserver="" {
 	set sc=$$$ERROR($$$SMTPProperty,"smtpserver")
 } elseif ..UseSTARTTLS,..SSLConfiguration="" {
	 set sc=$$$ERROR($$$STARTTLSConfigRequired)
 }

 do ..SetStatus(sc)
 if $$$ISERR(sc) quit ..GetStatus()

 set io=$IO
 set $ZTrap="SendError"
 do {
 	#; Start by opening connection to SMTP server
 	set cmd="connect"
 	#; Setup useipv6, 0 - no /USEIPV6 need to be specified, 1 - /USEIPV6=0, 2 - /USEIPV6=1.
 	set useipv6=$case(..IPVersion,4:0,6:1,:-1)
 	if '..UseSTARTTLS,..SSLConfiguration'="" {
	 	if ..SSLCheckServerIdentity {
		 	if useipv6>=0 {
	 			open "|TCP|25":(..smtpserver:..port:"CST":/USEIPV6=useipv6:/TLS=..SSLConfiguration_"||"_..smtpserver):5
		 	} else {
	 			open "|TCP|25":(..smtpserver:..port:"CST":/TLS=..SSLConfiguration_"||"_..smtpserver):5
		 	}
	 	} else {
		 	if useipv6>=0 {
	 			open "|TCP|25":(..smtpserver:..port:"CST":/USEIPV6=useipv6:/TLS=..SSLConfiguration):5
		 	} else {
	 			open "|TCP|25":(..smtpserver:..port:"CST":/TLS=..SSLConfiguration):5
		 	}
	 	}
 	} else {
	 	if useipv6>=0 {
	 		open "|TCP|25":(..smtpserver:..port:"CST":/USEIPV6=useipv6):5
	 	} else {
	 		open "|TCP|25":(..smtpserver:..port:"CST"):5
	 	}
 	}
 	else  do ..SetStatus($$$ERROR($$$SMTPOpen)) quit
 	set cmd="init"
 	use "|TCP|25"
 	; always output in RAW mode - conversions already done.
	do SetIO^%SYS.NLS("RAW")
 	#; SMTP server sends initial message saying it is ready to accept messages
 	set response=..GetResponse(..GetTimeout(..#TimeoutKeyInitial)) Quit:..Error'=""  ;'
 	if +$g(response)\100'=2 do ..SetStatus($$$ERROR($$$SMTPFirst,response)) quit  ;'
 	#; Tell the server who this machine is
 	do ..Login(.authenticated) Quit:..Error'=""
	#; Check that if authentication was attempted, it succeeded
	if '..IgnoreFailedAuth {
		if 'authenticated && (..authenticator'="") {
			do ..SetStatus($$$ERROR($$$SMTPAUTHFailed))
			quit
		}
	}
 	#; Now it needs to know the message is from so it can send it back if something goes wrong
 	set cmd="MAIL FROM"
 	set auth=""
 	if authenticated && (..AuthFrom'="") set auth=" AUTH="_..EncodeXtext(..AuthFrom)
 	if msg.Sender'="" do ..WriteLine("MAIL FROM: <"_..GetEmail(msg.Sender)_">"_auth, "MAIL FROM")
 	if msg.Sender="" do ..WriteLine("MAIL FROM: <"_..GetEmail(msg.From)_">"_auth, "MAIL FROM")
 	set response=..GetResponse(..GetTimeout("MAIL")) quit:..Error'=""  ;'
 	if +response\100'=2 do ..UnexpectedResponse("MAIL FROM",response) quit  ;'
 	#;
 	#; Write all the people this message it To
 	set cmd="RCPT TO"
 	set to=""
 	For index=1:1:msg.To.Count() {
 		do ..WriteLine("RCPT TO: <"_..GetEmail(msg.To.GetAt(index))_">", "RCPT TO")
 		set to=to_msg.To.GetAt(index)_", "
 		set response=..GetResponse(..GetTimeout("RCPT")) quit:..Error'=""  ;'
 		if +response\100=2 {
 			set sends=sends+1
 		} else {
 			if '..ContinueAfterBadSend do ..UnexpectedResponse("RCPT TO",response) quit
 			do ..FailedSend.Insert(msg.To.GetAt(index))
 		}
 	}
 	if ..Error'="" quit  ;'
 	set to=$E(to,1,$L(to)-2)
 	#; Write all the people on the Cc list
 	Set cc=""
 	for index=1:1:msg.Cc.Count() {
 		do ..WriteLine("RCPT TO: <"_..GetEmail(msg.Cc.GetAt(index))_">", "RCPT TO")
 		set cc=cc_msg.Cc.GetAt(index)_", "
 		set response=..GetResponse(..GetTimeout("RCPT"))
 		if +response\100=2 {
 			set sends=sends+1
 		} else {
 			if '..ContinueAfterBadSend do ..UnexpectedResponse("RCPT TO",response) quit
 			do ..FailedSend.Insert(msg.Cc.GetAt(index))
 		}
 	}
 	if ..Error'="" Quit  ;'
 	set cc=$E(cc,1,$L(cc)-2)
 	#; Write all the people on the Bcc list
 	Set bcc=""
 	for index=1:1:msg.Bcc.Count() {
 		do ..WriteLine("RCPT TO: <"_..GetEmail(msg.Bcc.GetAt(index))_">", "RCPT TO")
 		set bcc=bcc_msg.Bcc.GetAt(index)_", "
 		set response=..GetResponse(..GetTimeout("RCPT"))
 		if +response\100=2 {
 			set sends=sends+1
 		} else {
 			if '..ContinueAfterBadSend do ..UnexpectedResponse("RCPT TO",response) quit
 			do ..FailedSend.Insert(msg.Bcc.GetAt(index))
 		}
 	}
 	if ..Error'="" Quit  ;'
 	set bcc=$E(bcc,1,$L(bcc)-2)
 	If sends=0 {
 		do ..WriteLine("RSET", "RSET")
 		read response:..GetTimeout("RSET")
 		do ..SetStatus($$$ERROR($$$SMTPNoSend))
 		quit
 	}
 	#; Now start of the real message
 	set cmd="DATA"
 	do ..WriteLine("DATA", "DATA")
 	set response=..GetResponse(..GetTimeout("DATA")) quit:..Error'=""  ;'
 	if +response\100'=3 do ..UnexpectedResponse("DATA",response) quit  ;'
 	#; Write the message headers and body
 	if msg.Date="" {
 		set zn=..zone()
 		set dt=$select(zn="UT":$ztimestamp,1:$h)
 		set msg.Date=$zd(dt,11,,,,,,,,1)_", "_$zdt(dt,2,1,,,,,,,,,1)_" "_zn
 	}
 	do ..SendMessage(msg)
 	#; End of data symbol
 	do ..WriteLine($c(13,10)_".")
 	set response=..GetResponse(..GetTimeout(..#TimeoutKeyDataTermination)) quit:..Error'=""  ;'
 	if +response\100'=2 do ..UnexpectedResponse("message headers",response) quit  ;'
 } while 0

 if cmd'="connect" {
 	if cmd'="init" {
		do ..WriteLine("QUIT", "QUIT")
 		read response:..GetTimeout("QUIT")
 		if (..Error="") && (+response\100'=2) do ..UnexpectedResponse("QUIT",response)
 	}
 	close "|TCP|25"
 }

 ; Restore IO device
 use io
 quit ..GetStatus()
SendError
 set $ZTrap=""
 set sslerror = "",sc = $$$OK
 if (..SSLConfiguration'="") {
	#; Capture a description of the SSL/TLS error encountered, if any, during the most 
	#; recent SSL/TLS operation over the current device.
	try {
		set sslerror = $System.Security.Users.SSLGetLastError()
		if sslerror '= "" {
			Set sc=$$$ERROR($$$HttpRequestSSLError,..SSLConfiguration,sslerror)
		}
	} catch {}
 }
 if cmd="connect" {
 	if sc {
		set sc = $$$ERROR($$$ConnectionFailed)
	}
 	do ..SetStatus(sc)
 } else {
 	set sc = $$$ADDSC(sc,$$$ERROR($$$SMTPConnectionFailed,cmd,$ze))
 	do ..SetStatus(sc)
 	close "|TCP|25"
 }
 use io
 quit ..GetStatus()
}

/// Send the mail message data to the SMTP server
Method SendMessage(msg As %Net.MailMessage) [ Internal, Private ]
{
 	do ..SetHeaderCharset(msg)
 
 	if msg.Date'="" do ..WriteLine("Date: "_msg.Date, "Date")
 	if msg.From'="" do ..WriteHeader("From",msg.From)
 	if msg.Subject'="" do ..WriteHeader("Subject",msg.Subject)
 	if msg.Sender'="" do ..WriteHeader("Sender",msg.Sender)
 	if msg.ReplyTo'="" do ..WriteHeader("Reply-To",msg.ReplyTo)
 	
 	set to=""
 	for index=1:1:msg.To.Count() set to=to_msg.To.GetAt(index)_", "
 	set to=$E(to,1,$L(to)-2)
 	if to'="" do ..WriteHeader("To",to)

 	Set cc=""
 	for index=1:1:msg.Cc.Count() set cc=cc_msg.Cc.GetAt(index)_", "
 	set cc=$E(cc,1,$L(cc)-2)
 	if cc'="" do ..WriteHeader("Cc",cc)  ;'

 	Set bcc=""
 	for index=1:1:msg.Bcc.Count() set bcc=bcc_msg.Bcc.GetAt(index)_", "
 	set bcc=$E(bcc,1,$L(bcc)-2)
 	if (bcc'="") && ..ShowBcc do ..WriteHeader("Bcc",bcc)  ;'

 	do ..SendMultiPart(msg,"")
}

/// Setup session with the SMTP server.
/// We will use the EHLO command and SMTP authentication as supplied 
/// by the authenticator property where possible.  
/// If EHLO is not accepted or authentication fails, we will
/// attempt to use the HELO command.
Method Login(ByRef authenticated As %Boolean) [ ProcedureBlock = 1 ]
{
 set authenticated=0
 #; Try to connect with EHLO
 set cmd="EHLO"
 do ..WriteLine("EHLO "_..localhost, "EHLO")
 set response=..GetResponse(..GetTimeout("EHLO"),.extensionList) Quit:..Error'=""  ;'
 if +response\100=5 {
 	#; If EHLO not recognized try HELO
 	set cmd="HELO"
 	do ..WriteLine("HELO "_..localhost, "HELO")
 	set response=..GetResponse(..GetTimeout("HELO")) Quit:..Error'=""  ;'
 	if +response\100'=2 do ..UnexpectedResponse("HELO",response) quit  ;'
 }
 if +response\100'=2 do ..UnexpectedResponse("EHLO",response) quit  ;'
 
 #; Check if STARTTLS supported and desired.
 if ..UseSTARTTLS {
	if cmd'="EHLO" {
		do ..SetStatus($$$ERROR($$$STARTTLSNotSupported,"EHLO not supported"))
		quit 
	}
	set extension=""
	for i=2:1:extensionList {
		set extension=$zcvt($piece($extract(extensionList(i),5,$length(extensionList(i)))," ",1),"U")
		if extension="STARTTLS" quit
	}
	if extension="" {
		do ..SetStatus($$$ERROR($$$STARTTLSNotSupported,"STARTTLS not supported"))
		quit 
	}
	set cmd="STARTTLS"
	do ..WriteLine("STARTTLS", "STARTTLS")
	set response=..GetResponse(..GetTimeout("STARTTLS")) Quit:..Error'=""  ;'
	if +$g(response)\10'=22 do ..SetStatus($$$ERROR($$$STARTTLSNotSupported,"Unexpected response "_response)) quit  ;'
	if ..SSLCheckServerIdentity {
		use "|TCP|25":(::/TLS=..SSLConfiguration_"||"_..smtpserver)
	} else {
		use "|TCP|25":(::/TLS=..SSLConfiguration)
	}
	; always output in RAW mode - conversions already done.
	do SetIO^%SYS.NLS("RAW")
	 set cmd="EHLO"
	 do ..WriteLine("EHLO "_..localhost, "EHLO")
	 set response=..GetResponse(..GetTimeout("EHLO"), .extensionList) Quit:..Error'=""  ;'
	 if +response\100'=2 do ..UnexpectedResponse("EHLO",response) quit  ;'
 }

 if ..SSLCheckServerIdentity,..SSLConfiguration'="" {
	set sc=##class(%Net.HttpRequest).CheckSSLCN(..smtpserver)
	if $$$ISERR(sc) {
		do ..SetStatus(sc)
		quit
	}
 }

 if ..authenticator="" quit

 #; If we have an authenticator, try to authenticate
 set ..authenticator.ServiceName="smtp"
 set extension=""
 for i=2:1:extensionList {
 	set extension=$zcvt($piece($extract(extensionList(i),5,$length(extensionList(i)))," ",1),"U")
 	if extension="AUTH" quit
 }

 #; If the server doesn't support authentication, quit
 if extension'="AUTH" {
	if '..IgnoreFailedAuth {
		do ..SetStatus($$$ERROR($$$SMTPAUTHNotSupported))
	}
	quit
 }

 #; SMTP authentication supported
 set authlist=$piece(extensionList(i)," ",2,$length(extensionList(i)," "))
 if ..authenticator.Start(authlist,.method,.response) {
	$$$SysLog(2, "SMTP", "[%Net.SMTP::Login]", "MECHANISM="_..authenticator.Mechanism.MechanismName)
 	set cmd="AUTH"
 	if response'="" set response=" "_..EncodeB(response)
 	do ..WriteLine("AUTH "_method_response, "AUTH")
 	set continue=1
 	set challenge=..GetResponse(..GetTimeout("AUTH")) quit:..Error'=""  ;'
 	while +challenge'=235 {
 		if +challenge'=334 quit  ;' authentication failed, error be reported by MAIL command
 		set decoded=$system.Encryption.Base64Decode($extract(challenge,5,$length(challenge)))
 		set continue=..authenticator.Next(decoded,.response)
 		if 'continue quit
 		do ..WriteLine(..EncodeB(response))
 		set challenge=..GetResponse(..GetTimeout("AUTH")) quit:..Error'=""  ;'
 	}
 	if ..Error'="" quit
 	if 'continue {
 		do ..WriteLine("*")
 		do ..GetResponse(..GetTimeout("AUTH")) quit:..Error'=""  ;'
 	} else {
 		set authenticated=(+challenge=235)
 	}
 }
}

/// Encode headers according to rules in RFC 2045.
Method WriteHeader(name As %String, text As %String) [ Internal, Private ]
{
 set header=name_":"
 set name=$zcvt(name,"L")
 if 'i%AllowHeaderEncoding {
 	// Header encoding is disabled
 	set header=header_" "_text
 } elseif name?1(1"cc",1"bcc",1"from",1"sender",1"to",1"reply-to",1"resent-from",1"resent-sender",1"resent-to",1"resent-cc",1"resent-bcc",1"keywords") {
 	// Structured messages
 	set header=..EncodeStructuredHeader(header,text,name="keywords")
 } elseif name?1(1"content-type",1"content-transfer-encoding",1"content-disposition") {
 	set header=..EncodeQuotedHeader(header,text)
 } elseif name'?1(1"resent-date",1"return-path",1"received") {
 	// Unstructured messages including messages not defined in RFC2045
 	set header=..EncodeHeaderPart(header,text,"",1,"")
 } else {
 	// The structured headers that we don't encode
 	set header=header_" "_text
 }

 set header=header_$c(13,10)
 for i=1:1:$length(header,$c(13,10))-1 {
 	do ..WriteLine($piece(header,$c(13,10),i))
 }
}

/// Handle of large subset of encoding required for structured headers in RFC 2045.<br>
/// Return the encoded header.<br>
/// The following formats are supported:<br>
/// <ul>
/// <li>address comma separated list:  display [&lt;addr&gt;],...</li>
/// <li>message id (not comma separated list: &lt;addr&gt; ..</li>
/// <li>keyword comma separated list: display, ...</li>
/// </ul>
/// keyword list is different from address list because display part<br>
/// of address list part is considered an address if no address is
/// specified.<br>
/// Parenthesized comments are not supported for any of these formats.
Method EncodeStructuredHeader(header As %String, input As %String, keywords As %Boolean) As %String [ Internal, Private ]
{
 set first=1
 set text=input

 // Loop over parts of the header
 while text'="" {
 	// Find next part up to comma
 	set display="",addr=""
 	set quoted=0,parens=0,found=0
 	// Scan each character
 	for i=1:1:$Length(text) {
 		Set e=$Extract(text,i)
 		if parens=0 {
 			// Skip "\" quoted characters.
 			while e="\" {
 				set i=i+2
 				Set e=$Extract(text,i)
 			}
 			// Ignore special characters in quoted string.
 			if e="""" set quoted='quoted
 			if 'quoted {
 				if e="(" {
 					set parens=1
 				} elseif (e=",")||(('keywords)&&(e=";")) {
 					// Look for <address> ouside of quoted string or comment.
 					if keywords {
 						set display=$extract(text,1,i-1)
 						set addr=""
 					} else {
 						set addr=$extract(text,1,i-1)
 						set display=""
 					}
 					set $extract(text,1,i)=""
 					set found=1
 					quit
 				} elseif ('keywords)&&(e=":") {
 					// Display name for a group
 					set display=$extract(text,1,i-1)
 					set addr=""
 					set $extract(text,1,i)=""
 					set found=1
 					quit
 				} elseif ('keywords)&&(e="<") {
 					// Display name with address in <>
 					set end=$find(text,">",i+1)
 					if end'=0 {
 						set addr=$extract(text,i+1,end-2)
 						set addr="<"_$zstrip(addr,"<>W",$C(13,10))_">"
 						set display=$extract(text,1,i-1)
 						set $extract(text,1,end-1)=""
 						set e=$extract($zstrip(text,"<W",$C(13,10)))
 						if (e=",")||(e=";") {
 							set text=$piece(text,e,2,$length(text,e))
 						} else {
 							set e=""
 						}
 						set found=1
 						quit
 					}
 				}
 			}
 		} else {
 			// Ignore special characters in nested parentheses
 			// outside of quoted string.  This is minimal support
 			// for comments.
 			if e="(" set parens=parens+1
 			if e=")" set parens=parens-1
 		}
 	}

 	// Handle last token
 	if 'found {
 		if keywords {
 			set display=text
 			set addr=""
 		} else {
 			set addr=text
 			set display=""
 		}
 		set text="",e=""
 	}

 	set header=..EncodeHeaderPart(header,display,addr,first,e)
 	set first=0
 }

 quit header
}

/// Handle the structured headers in RFC 2045 that contain quoted strings
/// which may be encoded, but no other part of the header is encoded.<br>
/// Return the encoded header.<br>
Method EncodeQuotedHeader(header As %String, input As %String) As %String [ Internal, Private ]
{
	set input=header_" "_input

	if $length(input)<77 {
		set header=..EncodeQuotedHeaderPart(input)
	} else {
		set len=$length(input,";")
		set part=$piece(input,";",1)
		if len>1 set part=part_";"
		set header=..EncodeQuotedHeaderPart(part)
		for partIndex=2:1:len {
			set part=" "_$piece(input,";",partIndex)
			if partIndex'=len set part=part_";"
			set header=header_$c(13,10)_..EncodeQuotedHeaderPart(part)
		}
	}
	quit header
}

/// Handle the ; separated parts of the structured headers in RFC 2045 that contain quoted strings
/// which may be encoded, but no other part of the header is encoded.<br>
/// Return the encoded header part.<br>
Method EncodeQuotedHeaderPart(input As %String) As %String [ Internal, Private ]
{
	set inQuotes=0
	set pos=1
	set header=""

	while pos'=0 {
		set end=$find(input,"""",pos)
		if inQuotes&&(end'=0) {
			set inQuotes=0
			set header=..EncodeHeaderPart(header,$extract(input,pos,end-2),"",1,"","")
			set header=header_""""
		} else {
			set inQuotes=1
			set last=$select(end=0:$length(input),1:end-1)
			set header=header_$extract(input,pos,last)
		}
		set pos=end
	}
	quit header
}

Method EncodeHeaderPart(header As %String, part As %String, addr As %String, first As %Boolean, termChar As %String, sepChar As %String = " ") As %String [ Private ]
{
 set newline=$C(13,10)_$select(sepChar="":" ",1:"")
 set text=$zstrip(part,"<>W",$C(13,10))
 set addr=$zstrip(addr,"<>W",$C(13,10))

 set textlen=$length(text)
 set addrlen=$length(addr)
 if addrlen+textlen=0 quit header

 if addrlen>0 set addrlen=addrlen+1
 set num8bit=$length($tr(part,..#PrintableAscii))

 set originalText=text
 if (textlen>0)&&(num8bit>0) {
 	if i%HeaderTable'="" set text=$zcvt(text,"O",i%HeaderTable)
 	set isJIS=(i%HeaderTable="JIS")
 	if isJIS {
	 	set JIStext=..endJISInASCII(text)
 		set text=..EncodeB(JIStext)
 		set encoding="B"
 	} elseif (textlen+(2*num8bit))>((textlen*4)/3) {
 		set text=..EncodeB(text)
 		set encoding="B"
 	} else {
 		set text=..EncodeQ(text)
 		set encoding="Q"
 	}
 	set textlen=$length(text)
 	set prefix="=?"_$zcvt(i%HeaderCharset,"L")_"?"_encoding_"?"
 	set suffix="?="
 } else {
 	set prefix=""
 	set suffix=""
 	Set encoding=""
 }
 
 set textlen=$length(prefix)+textlen+$length(suffix)
 if textlen>0 set textlen=textlen+1
 // Treat terminating character as part of address
 set addrlen=addrlen+$length(termChar)
 set addr=addr_termChar

 set lastlen=$length($piece(header,$C(13,10),$length(header,$C(13,10))))
 if 'first {
 	if lastlen+textlen+addrlen<77 {
 		if text'="" set header=header_sepChar_prefix_text_suffix
 		if addr'="" set header=header_sepChar_addr
 	} else {
 		set header=header_newline
 		set first=1
 		set lastlen=0
 	}
 }
 if first {
 	if (textlen>0) {
 		if (num8bit=0)||(lastlen+textlen<77) {
 			set header=header_sepChar_prefix_text_suffix
 		} else {
 			set extralen=$length(prefix)+$length(suffix)
 			if lastlen+extralen+4>76 set header=header_newline,lastlen=0
 			while text'="" {
 				set tlen=$length(text)
 				set len=76-lastlen-extralen-1
 				if isJIS {
					set len=len\4*4
					set segment=..extractJIStext(len,.text,.JIStext)
 				} else {
	 				set segment=$extract(text,1,len)
	 				if len<tlen {
		 				if encoding="Q" {
	 						do ..CleanQEncodedHeaderSegment(.segment)
	 						set len=$length(segment)
	 					} elseif encoding="B" {
	 						set len=len\4*4
	 						set segment=$extract(text,1,len)
	 						set unencodedSegment=$system.Encryption.Base64Decode(segment)
	 						set extraChars=""
	 						if i%HeaderTable'="" set unencodedSegment=$zcvt(unencodedSegment,"I",i%HeaderTable,extraChars)
	 						if extraChars'="" {
		 						// Handle the case of segment not containing complete encoded characters.
		 						// Remove extra and fix up everything
		 						set segment=unencodedSegment
		 						if i%HeaderTable'="" set segment=$zcvt(segment,"O",i%HeaderTable)
		 						set segment=$system.Encryption.Base64Encode(segment,1)
		 						set $extract(originalText,1,$length(unencodedSegment))=""
		 						set text=originalText
		 						if i%HeaderTable'="" set text=$zcvt(text,"O",i%HeaderTable)
		 						set text=$system.Encryption.Base64Encode(text,1)
		 						// Set len=0 to not further strip base64 encoded text.
		 						set len=0
	 						} else {
	 							set $extract(originalText,1,$length(unencodedSegment))=""
	 						}
	 					}
	 				} else {
	 					set len=tlen
	 				}
 					if len>0 set $extract(text,1,len)=""
 				}
 				set header=header_sepChar_prefix_segment_suffix
 				if text'="" set header=header_newline,lastlen=0
 			}
 		}
 	}

 	if addrlen>0 {
 		set lastlen=$length($piece(header,$C(13,10),$length(header,$C(13,10))))
 		if (lastlen>0)&&(lastlen+addrlen>76) set header=header_newline
 		set header=header_sepChar_addr
 	}
 }

 quit header
}

Method CleanQEncodedHeaderSegment(ByRef segment As %String) [ Internal, Private ]
{
	if $length($piece(segment,"=",*))<2 {
		// Never break quoted printable in middle of =hh.
		set segment=$piece(segment,"=",1,*-1)
	} 
	set len=$length(segment)

	// If this segment does not end with an encoded byte of the form =hh, then we don't need to do anything else
	if (len>=3) && ($extract(segment, len - 2) '= "=") {
		return
	}

	// If the segment does end with an encoded byte, then try to decode the entire segment. 
	// If the ending cannot be decoded, then it means that the segment ends with an 
	// incompletely encoded character which should be removed so that it can go on the next line. 
	// A single character's encoding should not span multiple lines
	set indexByteEncodingStart = 1
	set segmentPartiallyDecoded = ""
	while indexByteEncodingStart <= $length(segment) {
		if $extract(segment, indexByteEncodingStart) = "=" {
			set hexString = $extract(segment, indexByteEncodingStart+1, indexByteEncodingStart + 2) 
			set segmentPartiallyDecoded = segmentPartiallyDecoded _ $char($zhex(hexString))
			set indexByteEncodingStart = indexByteEncodingStart + 3
		} else {
			set segmentPartiallyDecoded = segmentPartiallyDecoded _ $extract(segment, indexByteEncodingStart)
			set indexByteEncodingStart = indexByteEncodingStart + 1
		}
	}
	set segmentDecoded = $zcvt(segmentPartiallyDecoded, "I", i%HeaderTable, undecodable)

	if $length(undecodable) > 0 {
		set numEncodedBytesToDrop = $length(undecodable)
		set segment = $piece(segment, "=", 1, * - numEncodedBytesToDrop)
	}
}

/// Force JIS string to end in ASCII mode per RFC 1468.
Method endJISInASCII(input As %String) As %String [ Internal, Private ]
{
	set ESC=$c(27)
	set ascii=1
	set pos=1
	while pos'=0 {
		set pos=$find(input,ESC,pos)
		if pos'=0 {
			if $extract(input,pos,pos+1)="(B" {
				set ascii=1
			} else {
				set ascii=0
			}
		}
	}
	quit input_$select('ascii:ESC_"(B",1:"")
}

/// Extract and base64 encode enough JIS text to fill out the available space on this line.
Method extractJIStext(len As %Integer, ByRef text As %String, ByRef JIStext As %String) As %String [ Internal, Private ]
{
	if len>=$length(text) {
		set segment=text
		set JIStext=""
		set text=""
		quit segment
	}
	
	set ESC=$c(27)
	set asciiShift=ESC_"(B"
	set lastShift=asciiShift
	set JISlen=len\4*3
	set singleByte=1
	set segment=""
	for {
		set pos=$find(JIStext,ESC)
		if pos=0 quit
		set JISseglen=pos-2
		if JISseglen>0 {
			if JISlen<JISseglen set JISseglen=JISlen
			if singleByte {
				set segment=segment_$extract(JIStext,1,JISseglen)
				set $extract(JIStext,1,JISseglen)=""
				set JISlen=JISlen-JISseglen
				if JISlen<2 quit
			} else {
				if JISlen<5 quit // Need double byte,ESC,(,B
				if (JISlen-3)<JISseglen set JISseglen=JISlen-3
				set JISseglen=JISseglen\2*2
				set segment=segment_$extract(JIStext,1,JISseglen)
				set $extract(JIStext,1,JISseglen)=""
				set JISlen=JISlen-JISseglen
				if JISlen<5 quit
			}
		}
		if ($extract(JIStext,2)="(") && $case($extract(JIStext,3),"B":1,"J":1,:0) {
			if 'singleByte {
				set segment=segment_$extract(JIStext,1,3)
				set JISlen=JISlen-3
				set singleByte=1
			}
			if lastShift'=$extract(JIStext,1,3) {
				set lastShift=$extract(JIStext,1,3)
				set $extract(JIStext,1,3)=""
			}
		} elseif ($extract(JIStext,2,3)="$(") && $case($extract(JIStext,4),"C":1,"D":1,:0) {
			if singleByte {
				if JISlen<8 quit // Need ESC,$,B,double byte,ESC,(,B
				set JISlen=JISlen-4
				set singleByte=0
			}
			if lastShift'=$extract(JIStext,1,4) {
				set segment=segment_$extract(JIStext,1,4)
				set lastShift=$extract(JIStext,1,4)
			}
			set $extract(JIStext,1,4)=""
		} elseif (($extract(JIStext,2)="$") && $case($extract(JIStext,3),"B":1,"@":1,"A":1,:0)) ||
				 (($extract(JIStext,2)=".") && $case($extract(JIStext,3),"A":1,"F":1,:0)) {
			if singleByte {
				if JISlen<8 quit // Need ESC,$,B,double byte,ESC,(,B
				set JISlen=JISlen-3
				set singleByte=0
			}
			if lastShift'=$extract(JIStext,1,3) {
				set segment=segment_$extract(JIStext,1,3)
				set lastShift=$extract(JIStext,1,3)
			}
			set $extract(JIStext,1,3)=""
		} Else {
			set segment=segment_$extract(JIStext,1,1)
			set $extract(JIStext,1,1)=""
		}
	}
	if (lastShift'=asciiShift) && (JIStext'="") set JIStext=lastShift_JIStext
	set text=$select(JIStext'="":..EncodeB(JIStext),1:"")
	quit ..EncodeB(segment_$select('singleByte:asciiShift,1:""))
}

/// Encode header using special quoted printable encoding
/// defined in RFC 2045 for header fields.
Method EncodeQ(input As %String) As %String [ Internal, Private ]
{
 set out=input
 for i=$length(input):-1:1 {
 	set a=$ascii($extract(input,i))
 	// Encode space as underline "_"
 	if a=32 {
 		set $extract(out,i,i)="_"
 		// Encode non printable ascii, 8 bit chars, "=", "?" and "_"
 	} elseif (a<33)!(a>126)!(a=61)!(a=63)!(a=95) {
 		if a>255 {
 			do:..Error="" ..SetStatus($$$ERROR($$$SMTPQuotedPrintable))
 		} else {
 			set $extract(out,i,i)="="_..pad2($zhex(a))
 		}
 	}
 }
 quit out
}

/// Encode header using base64 encoding
Method EncodeB(input As %String) As %String [ CodeMode = expression, Internal, Private ]
{
$system.Encryption.Base64Encode(input,1)
}

/// Find the translate table for any non ASCII headers
Method SetHeaderCharset(msg As %Net.MailMessagePart) [ Internal, Private ]
{
 set i%HeaderCharset=msg.Charset

 if i%HeaderCharset="" {
 	set i%HeaderCharset=##class(%Net.Charset).GetDefaultCharset()
 	if i%HeaderCharset="" set i%HeaderTable="" quit
 }

 if ##class(%Net.Charset).TranslateTableExists(i%HeaderCharset,.table) {
 	set i%HeaderTable=table
 } else {
 	do ..SetStatus($$$ERROR($$$SMTPCharset,i%HeaderCharset))
 	set i%HeaderCharset=""
 	set i%HeaderTable=""
 }

 quit
}

/// Generate message for unexpected response.
Method UnexpectedResponse(msg As %String, response As %String) As %String [ Internal, Private ]
{
 do ..SetStatus($$$ERROR($$$SMTPResponse,msg,response))
 quit
}

/// Return timezone converted to RFC822 format 
Method zone() As %String
{
 If ..timezone="" Quit "UT"

 If $zcvt(..timezone,"U")="LOCAL" {
 	Set h=##class(%Net.MailMessage).HToSeconds($h)
 	Set z=##class(%Net.MailMessage).HToSeconds($ztimestamp)
 	If h>z {
 		Set minutes=((h-z)+30)\60
 		Set sign="+"
 	} Else {
 		Set minutes=((z-h)+30)\60
 		Set sign="-"
 	}
 	Quit sign_$extract(minutes\60+100,2,3)_$extract(minutes#60+100,2,3)
 }

 Quit ..timezone
}

/// Return integer or hex padded to 2 place with leading zeros 
Method pad2(n As %String) As %String [ CodeMode = expression, Internal, Private ]
{
$select($length(n)=1:"0"_n,1:n)
}

/// Return %Status object
Method GetStatus() As %Status [ CodeMode = expression, Internal, Private ]
{
i%Status
}

/// Set Status for Send function. 
Method SetStatus(status As %Status) [ Internal, Private ]
{
 Set i%Status=status
 if $$$ISOK(status) {
 	set i%Error=""
 } Else {
 	do DecomposeStatus^%apiOBJ(status,.errorlist)
 	set i%Error=errorlist(1)
 }
 quit
}

/// Error trap
Method zzErrorTrap() As %String [ CodeMode = generator, Private ]
{
 Set %code=0
 $$$GENERATE("ErrorTrap ; Trap send errors")
 $$$GENERATE(" Do ..SetStatus($$$ERROR($$$ObjectScriptError,$ZE))")
 $$$GENERATE(" Quit ..GetStatus()")
}

/// Output stream to SMTP server with no encoding
Method OutputNoEncoding(stream As %Stream.Object) [ Internal, Private ]
{
 do stream.Rewind()
 while 'stream.AtEnd {
 	set len=998
 	set line=stream.ReadLine(.len)
 	if $extract(line,1)="." set line="."_line
 	if len<0 quit
 	do ..WriteLine(line)
 }
 quit
}

/// Output stream to SMTP server with base64 encoding
Method EncodeStreamBase64(stream As %Stream.Object) [ Internal, Private ]
{
 ; process stream in groups of 1023 - number arbitrary but must be divisible by 3
 set out=""
 do stream.Rewind()
 while 'stream.AtEnd {
 	set len=1023		; line must be divisible by 3
 	set line=stream.Read(.len)
 	if len'>0 quit
 	set remainder=len#3
 	set len3=len-remainder
 	; process line in groups of 3
 	for i=1:3:len3 {
 		set b1=$ascii(line,i)
 		set b2=$ascii(line,i+1)
 		set b3=$ascii(line,i+2)
 		set out4=..Base64Encode(b1,b2,b3) ; convert to 4 bytes
 		set out=out_out4
 		if $L(out)>72 do ..ProcessLine(out) s out=""
 	}
 	; we have processed line in group of 3 process rest
 	if len3'<0 {
 		if remainder=1 {
 			set out4=..Base64Encode($a(line,len3+1),0,0) 
 			set out=out_$e(out4,1,2)_"==" ;'
 		}
 		if remainder=2 {
 			set out4=..Base64Encode($a(line,len3+1),$a(line,len3+2),0) 
 			set out=out_$e(out4,1,3)_"=" ;'
 		}
 	}
 	; we have processed remainder, anything left to go out?
 	if $length(out)>0 do ..ProcessLine(out) set out=""
 }
 quit
}

/// Base64 encode a string.
Method Base64Encode(b1 As %String, b2 As %String, b3 As %String) As %String [ Internal, Private ]
{
 ; 4 is two bits
 ; 16 is four bits
 ; 64 is six bits
 set b01to06=b1\4
 set b07to08=b1#4
 set b09to12=b2\16
 set b13to16=b2#16
 set b17to18=b3\64
 set b19to24=b3#64
 set i1=b01to06
 set i2=b07to08*16+b09to12
 set i3=b13to16*4+b17to18
 set i4=b19to24
 quit $e(..#Base64Seq,i1+1)_$e(..#Base64Seq,i2+1)_$e(..#Base64Seq,i3+1)_$e(..#Base64Seq,i4+1)
}

/// Send as many lines together as will fit in 512 byte buffer
Method ProcessLine(line As %String) [ Internal, Private ]
{
 if ..bufcount=6 do ..WriteLine(line) set ..bufcount=1 quit
 do ..WriteText(line_$C(13,10))
 set ..bufcount=..bufcount+1
 quit
}

/// Send a, possibly multi-part, message part,
Method SendMultiPart(msg As %Net.MailMessagePart, boundary As %String) [ Internal, Private ]
{
 #; Write all additional headers
 set index=""
 set index=msg.Headers.Next("")
 while index'="" {
	set name=$zstrip(index,"<>W")
	if $zcvt(name,"L")'?1(1"from",1"bcc",1"cc",1"to",1"date",1"subject",1"sender",1"reply-to",1"mime-version") {
		do ..WriteHeader(name,msg.Headers.GetAt(index))
	}
	set index=msg.Headers.Next(index)
 }
 // Write MIME-Version header for top level
 If boundary="" do ..WriteLine("MIME-Version: 1.0", "Header")

 if msg.IsMultiPart=1 {
	if msg.ContentType="message/rfc822" {
		if (msg.Parts.Count()'=1) || 'msg.Parts.GetAt(1).%IsA("%Net.MailMessage") {
			do ..SetStatus($$$ERROR($$$SMTPRFC822))
		} else {
			set mailmsg=msg.Parts.GetAt(1)
			set contentEncoding=mailmsg.ContentTransferEncoding
			if contentEncoding="" set contentEncoding="7bit"
			if (contentEncoding'="7bit") && (contentEncoding'="8bit") {
				do ..SetStatus($$$ERROR($$$SMTPRFC822Encoding))
			} else {
				do ..WriteLine("Content-Type: message/rfc822", "Header")
				do ..WriteLine("Content-Transfer-Encoding: "_contentEncoding, "Header")
				#; Blank line between message headers and message body
				do ..WriteLine("")
				do ..SendMessage(mailmsg)
			}
		}
	} Else {
		#; create boundary string using random number generator
		set rnd1=$random(100000)/17 s rnd2=$random(100000)/17
		set boundary="--Boundary"_$zstrip(rnd1,"<>W")_$zstrip(rnd2,"<>W")_"--"
		#; indicate we are MIME multipart
		do ..WriteLine("Content-Type: multipart/"_$S(""'=msg.MultiPartType:msg.MultiPartType,1:"mixed")_"; boundary="""_boundary_"""", "Header")
		#; Blank line between message headers and message body
		do ..WriteLine("")
		#;
		do ..WriteLine("This message is in MIME format.  If you see this text then your mail reader is not able to correctly parse MIME format and you may not be able to read all of this message.")
		if '..IsPartEmpty(msg) {  ; if text specified, send it as a part.
			do ..WriteLine("--"_boundary)
			do ..SendMessagePart(msg)
		}
		for i=1:1:msg.Parts.Count() {
			do ..WriteLine("--"_boundary)
			do ..SendMultiPart(msg.Parts.GetAt(i),boundary)
		}
		do ..WriteLine("--"_boundary_"--")
	}
 } else {
	do ..SendMessagePart(msg)
 }
 quit
}

/// Check if message part is empty 
Method IsPartEmpty(msg As %Net.MailMessagePart) As %Boolean [ Internal, Private ]
{
 if msg.IsBinary {
 	do msg.BinaryData.Rewind() 
 	quit msg.BinaryData.AtEnd
 } else {
 	do msg.TextData.Rewind() 
 	quit msg.TextData.AtEnd
 }
}

/// Send a single (non multi-part message part.
Method SendMessagePart(msg As %Net.MailMessagePart) [ Internal, Private ]
{
 do ..SetHeaderCharset(msg)
 
 if msg.ContentType'="" {
 	set msg.IsBinary=($P(msg.ContentType,"/")'="text")
 } else {
 	if msg.IsBinary {
 		set msg.ContentType="application/octet-stream"
 	} else {
 		set msg.ContentType="text/"_$select(msg.IsHTML=1:"html",1:"plain")
 	}
 }

 set contentType=msg.ContentType

 if msg.IsBinary {
 	set data=msg.BinaryData
 } else {
 	if msg.Charset="" {
 		if ..IsAscii(msg.TextData) {
 			set msg.Charset="us-ascii"
 		} elseif ##class(%Net.Charset).IsLocaleUnicode() {
 			do ..SetStatus($$$ERROR($$$SMTPUnicodeCharset))
 		} else {
 			set msg.Charset=##class(%Net.Charset).GetDefaultCharset()
 		}
 	} elseif ($zcvt(msg.Charset,"L")="utf-8") && ..IsAscii(msg.TextData) {
 		set msg.Charset="us-ascii"
 	}

 	if msg.Charset'="" set contentType=contentType_"; charset="""_msg.Charset_""""
 	; translate table to RAW for reading stream
 	set table=msg.TextData.TranslateTable
 	if (table="")&&(msg.Charset'="") do ..SetStatus($$$ERROR($$$SMTPCharset,msg.Charset))
 	set msg.TextData.TranslateTable="RAW"
 	set data=msg.TextData
 }
 if (msg.FileName'="")&&(msg.Debug'["NoCTN") set contentType=contentType_"; name="""_msg.FileName_""""
 if msg.Debug'["NoContentType" do ..WriteHeader("Content-Type",contentType)

 ; Default to using base64 encoding for binary files.
 set contentEncoding=msg.ContentTransferEncoding
 if contentEncoding="" set contentEncoding=$select(msg.IsBinary:"base64",1:"quoted-printable")
 if msg.Debug'["NoContentEncoding" do ..WriteHeader("Content-Transfer-Encoding",contentEncoding)

 if msg.FileName'="" {
	set attachment=$select(msg.InlineAttachment:"inline",1:"attachment")
	if msg.Debug'["NoCDF" Set attachment=attachment_"; filename="""_msg.FileName_""""
	do ..WriteHeader("Content-Disposition",attachment)
 } ElseIf msg.InlineAttachment {
	do ..WriteHeader("Content-Disposition","inline")
 }
 do ..WriteLine("")

 if contentEncoding="base64" {
 	do ..EncodeStreamBase64(data)
 } elseif contentEncoding="quoted-printable" {
 	do ..EncodeStreamQuotedPrintable(data)
 } else {
	do ..OutputNoEncoding(data)
 }

 ; restore translate table
 if 'msg.IsBinary set msg.TextData.TranslateTable=table

 quit
}

/// Encode a stream as quoted printable and output the stream.
Method EncodeStreamQuotedPrintable(stream As %Stream.Object) [ Internal, Private ]
{
 ; Following flags to defer processing until end of line
 set readlen=4000
 set out=""
 set bCR=0 ; true if CR was encountered.
 set aWS=0 ; 9 or 32 if whitespace encountered.
 set bLineOutput=0
 do stream.Rewind()
 while 'stream.AtEnd {
 	set len=readlen
 	set line=stream.Read(.len)
 	if len'>0 quit
 	for i=1:1:$length(line) do
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
 	. if a>255 do:..Error="" ..SetStatus($$$ERROR($$$SMTPQuotedPrintable)) quit
 	. ; period at start of line encoded as well as usual characters to encode to deal with
 	. ; problems of period at start of line for some servers.
 	. if (a<33) || (a>126) || (a=61) || ((a=46) && (out="")) do
 	. . do ..AppendToOutput(.out,"="_..pad2($zhex(a)))
 	. else  do ..AppendToOutput(.out,$char(a))
 }
 if bCR do:aWS ..AppendToOutput(.out,$char(aWS)) do ..AppendToOutput(.out,"=0D")
 if 'bCR&aWS do ..AppendToOutput(.out,"="_..pad2($zhex(aWS)))
 do ..ProcessLine(out)
 quit
}

/// xtext encoding is defined in RFC 1891 as:<p>
/// "xtext" is formally defined as follows:<br>
/// xtext = *( xchar / hexchar )<br>
/// xchar = any ASCII CHAR between "!" (33) and "~" (126) inclusive,
/// except for "+" and "=".<br>
/// ;"hexchar"s are intended to encode octets that cannot appear<br>
/// ;as ASCII characters within an esmtp-value.
/// hexchar = ASCII "+" immediately followed by two upper case hexadecimal digits
Method EncodeXtext(text As %String) As %String [ ProcedureBlock = 1 ]
{
 set out=""
 for i=1:1:$length(text) {
 	set a=$ascii(text,i)
 	If (a<33) || (a>126) || (a=43) || (a=61) {
 		set out=out_"+"_..pad2($zhex(a))
 	} else {
 		set out=out_$char(a)
 	}
 }
 quit out
}

/// Append to current output line.
/// If the line becomes longer than 75 charcaters, then start a new line.
Method AppendToOutput(ByRef out As %String, str As %String) [ Internal, Private ]
{
 if $length(out)+$length(str)>75 {
 	do ..ProcessLine(out_"=")
 	set out=str
 	set:$extract(str,1)="." out="."_out
 } else {
 	set out=out_str
 }
 quit
}

/// Scan text to see if any non-ascii chars
ClassMethod IsAscii(stream As %Stream.Object) As %Integer [ Internal, Private ]
{
 set rc=1
 do stream.Rewind()
 for  set len=32763,s=stream.Read(.len) d  quit:rc=0  quit:stream.AtEnd
 . for i=1:1:$length(s) if $ascii(s,i)>127 set rc=0 quit
 quit rc
}

/// Get the timeout to use when waiting for a response to the specified command
Method GetTimeout(command As %String) As %Integer [ Internal ]
{
	Set timeout = $NUMBER($GET(..Timeouts(command)),"", 0)
	If timeout '= "" {
		Return timeout
	} ElseIf command = "DATA" {
		Return 120 
	} ElseIf command = ..#TimeoutKeyDataTermination {
		Return 600
	} Else {
		Return 300
	}
}

}
