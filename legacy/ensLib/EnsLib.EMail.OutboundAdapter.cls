/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Adapter that sends email messages via SMTP.
Class EnsLib.EMail.OutboundAdapter Extends (Ens.Util.OAuth2.Settings, Ens.OutboundAdapter) [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// The IP address of the SMTP server to send mail to. (Note: the timeouts for connecting and sending mail can be more than 10 minutes).
Property SMTPServer As %String(MAXLEN = 100);

/// The IP Port on the SMTP server to send mail to. If left blank, the adapter will use port 25 for plain text and port 465 for SSL/TLS.
Property SMTPPort As %Integer;

/// This is the ID name of the set of credentials values to be used to access the server
Property Credentials As %String;

/// The email address(es) of a recipient or a comma and/or semicolon separated list of recipients that will be added to the To: list of each mail message sent.
Property Recipient As %String(MAXLEN = 2000);

/// The email address(es) of a recipient or a comma and/or semicolon separated list of recipients that will be added to the Cc: list of each mail message sent.
Property Cc As %String(MAXLEN = 2000);

/// The email address(es) of a recipient or a comma and/or semicolon separated list of recipients that will be added to the Bcc: list of each mail message sent.
Property Bcc As %String(MAXLEN = 2000);

/// The default From: address to put in sent mail messages. May be overridden by the Operation implementation code.
Property From As %String(MAXLEN = 200);

/// To use email with Secure Socket Layer / Transport Layer Security,
/// the SSLConfig field must contain the name of 
/// an existing SSL/TLS Configuration of the Client type. You can create one using the 
/// System Management Portal [Security Management] > [SSL/TLS Configurations] page.
/// <p>If your SSL Configuration requires you to supply a password for the local private key file, specify it in 
/// the Private key password property of the SSL/TLS Configuration.
/// <p>When you specify a value in the SSLConfig field, the normal case is that
/// outbound email will open a socket on default port 465 and use SMTP over TLS/SSL.
/// <p>The SSLConfig field also supports the special case when you want the server interaction 
/// to begin on a normal TCP socket and then switch to SSL/TLS on the same port as the 
/// normal socket. (RFC3207 provides the details.) In this case the default port is 25 for SMTP.   
/// To use this convention, append '*' to your entry in the SSLConfig field; 
/// for example:<br/>MySSLItem*<br/>
Property SSLConfig As %String;

/// When using email with Secure Socket Layer / Transport Layer Security, check the server identity in the certificate matches the name of the system we are connecting to.
/// This defaults to being OFF but it is recommended to enable. <br>
/// If enabled it matches based on the rules layed out in section 3.1 of RFC 2818.<br>
Property SSLCheckServerIdentity As %Boolean [ InitialExpression = 0 ];

/// If true, sending the email will continue if a send fails and failed email
/// addresses will be logged in the event log. The default is true.
Property ContinueAfterBadSend As %Boolean [ InitialExpression = 1 ];

Parameter SETTINGS As %String = "SMTPServer:Basic,SMTPPort:Basic,Credentials:Basic:credentialsSelector,SSLConfig:Connection:sslConfigSelector,SSLCheckServerIdentity:Connection,Recipient,Cc,Bcc,From,ContinueAfterBadSend";

Property SMTP As %Net.SMTP;

Method SMTPServerSet(%val As %String) As %Status
{
	Set i%SMTPServer=%val
	Set:$IsObject(..SMTP)&&(%val'=..SMTP.smtpserver) ..SMTP.smtpserver=%val
	Quit $$$OK
}

Method SMTPPortSet(%val As %Integer) As %Status
{
	Set i%SMTPPort=%val
	Set:$IsObject(..SMTP)&&(%val'=..SMTP.port) ..SMTP.port=%val
	Quit $$$OK
}

Method ContinueAfterBadSendSet(%val As %Integer) As %Status
{
	Set i%ContinueAfterBadSend=%val
	Set:$IsObject(..SMTP)&&(%val'=..SMTP.ContinueAfterBadSend) ..SMTP.ContinueAfterBadSend=%val
	Quit $$$OK
}

Method CredentialsSet(pInVal As %String) As %Status
{
	Set tSC=##super(pInVal)  Quit:$$$ISERR(tSC) tSC
	Quit:'$IsObject(..SMTP) tSC

	#; Set the authenticator to be used to connect on demand
	Set tHasUsername=$IsObject(..%CredentialsObj)&&(""'=..%CredentialsObj.Username)
	Set tIsXOAUTH2=(..OAuth2ApplicationName'="")
	If '$$$XOR(tHasUsername,$IsObject(..SMTP.authenticator)) {
		#; If authenticator and credentials exist...
		Set:tHasUsername ..SMTP.authenticator.UserName=..%CredentialsObj.Username,..SMTP.authenticator.Password=..%CredentialsObj.Password
		#; Clear access token which will be reset on Send
		Set:tIsXOAUTH2 ..SMTP.authenticator.AccessToken = ""
	} Else {
		#; If authenticator needs to be instantiated or destroyed...
		If tHasUsername||tIsXOAUTH2 {
			Do ..SMTP.authenticatorNewObject()  $$$ASSERT($IsObject(..SMTP.authenticator))
			If tHasUsername {
				Set ..SMTP.authenticator.UserName=..%CredentialsObj.Username
				Set ..SMTP.authenticator.Password = ..%CredentialsObj.Password
			}
			#; AccessToken set on send
			Set:tIsXOAUTH2 ..SMTP.authenticator.MechanismList="XOAUTH2"
		} Else {
			Set ..SMTP.authenticator=$$$NULLOREF
		}
	}
	Quit $$$OK
}

Method OnInit() As %Status
{
	Do ..SMTPNewObject() $$$ASSERT($IsObject(..SMTP))
	Set ..SMTP.smtpserver = ..SMTPServer
	Set ..SMTP.ContinueAfterBadSend = ..ContinueAfterBadSend

	#; If there is an SSL Configuration identified, see if it also wants to use STARTTLS (look for the '*')
	Set ..SSLConfig = $ZSTRIP(..SSLConfig,"<>WC")
	If (""'=..SSLConfig) { 
		Set ..SMTP.SSLConfiguration = $S("*"=$E(..SSLConfig,*):$E(..SSLConfig,1,*-1),1:..SSLConfig)
		Set ..SMTP.UseSTARTTLS = ("*"=$E(..SSLConfig,*))
		Set ..SMTP.SSLCheckServerIdentity = ..SSLCheckServerIdentity
		$$$EnsCheckSSLConfig(..SSLConfig)
	}
	#; if no port is set, %Net.SMTP will use port 25 for plain text, port 465 for SSL/TLS, or port 25 for SSL with STARTTLS
	Set ..SMTP.port = ..SMTPPort 

	/* Configure SMTP authenticator if Credentials and/or use of SASL XOAUTH */
	Set tHasUsername=$IsObject(..%CredentialsObj)&&(""'=..%CredentialsObj.Username)
	Set tIsXOAUTH2=(..OAuth2ApplicationName'="")
	If tHasUsername||tIsXOAUTH2 {
		Do ..SMTP.authenticatorNewObject()  $$$ASSERT($IsObject(..SMTP.authenticator))
		Set:tHasUsername ..SMTP.authenticator.UserName = ..%CredentialsObj.Username
		If tIsXOAUTH2 {
			#; AccessToken set on send
			Set ..SMTP.authenticator.MechanismList="XOAUTH2"
		} Else {
			Set ..SMTP.authenticator.Password = ..%CredentialsObj.Password
		}
	}

	Quit ##super()
}

Method SendMail(pMailMessage As %Net.MailMessage, Output pFailedRecipients As %ListOfDataTypes) As %Status
{
	Kill pFailedRecipients
	Set tSC = $$$OK, pFailedRecipients = $$$NULLOREF

	// Add configured recipients to the mail message
	If (""'=..Recipient)||(""'=..Cc)||(""'=..Bcc) {
		Set tmpTable = pMailMessage.TextData.TranslateTable // !save & restore because Clone() doesn't...
		Set tMsg = pMailMessage.%ConstructClone(1) // clone in case of retry - don't re-duplicate the lists
		Set tMsg.TextData.TranslateTable=tmpTable
		If ""'=..Recipient Set tSC = ..AddRecipients(tMsg,..Recipient)  Quit:$$$ISERR(tSC) tSC
		If ""'=..Cc Set tSC = ..AddCcRecipients(tMsg,..Cc)  Quit:$$$ISERR(tSC) tSC
		If ""'=..Bcc Set tSC = ..AddBccRecipients(tMsg,..Bcc)  Quit:$$$ISERR(tSC) tSC
	} Else { set tMsg = pMailMessage }
	Set:""=tMsg.From tMsg.From = ..From
	$$$sysTRACE("Msg.From="_tMsg.From_", ..From="_..From)

	If (0=tMsg.To.Size) && (0=tMsg.Cc.Size) && (0=tMsg.Bcc.Size) {
		$$$LOGWARNING( "No Recipients for mail message")
	}
	#dim tOAuth2AccessToken = ""
	If ..OAuth2ApplicationName'="" {
		/* SASL XOAuth2 support */
		#dim tOAuth2IsAuthorized = 0
		#dim tOAuth2HostShouldRetry = 0
		/* Get AccessToken if not already set or this is a retry since the retry may be due to OAuth2 access token
			needing to be refreshed.
		*/
		If (..SMTP.authenticator.AccessToken="")||(..BusinessHost.RetryCount>1) {
			Set tSC = $classmethod(..OAuth2CallBackHandler,"OnGetAccessToken",$this, ..OAuth2GrantType, ..OAuth2ApplicationName, ..OAuth2SessionId, ..%CredentialsObj.Username, ..OAuth2Scope, ..OAuth2AuthProperties, ..OAuth2GrantTypeSpecific, .tOAuth2IsAuthorized, .tOAuth2AccessToken, .tOAuth2HostShouldRetry)
    	    If $$$ISERR(tSC) {
        	    Set ..BusinessHost.Retry = tOAuth2HostShouldRetry
            	Return tSC
        	} Else {
            	Set ..SMTP.authenticator.AccessToken = tOAuth2AccessToken
        	}
		}
	}

	$$$sysTRACE("Trying SMTP server "_..SMTPServer_":"_..SMTPPort)
	Set tSC = ..SMTP.Send(tMsg)

	Set pFailedRecipients = ..SMTP.FailedSend
	For i=1:1:pFailedRecipients.Count() {
		$$$LOGERROR("Failed send to "_pFailedRecipients.GetAt(i))
	}
	If $$$ISOK(tSC) { $$$LOGINFO("Email sent via "_..SMTPServer_":"_..SMTPPort) }
	Else { 
		Set:$$$StatusEquals(tSC,$$$SMTPTimeout,$$$SMTPOpen,$$$SMTPConnectionFailed) ..BusinessHost.Retry = 1
		#; Clear AccessToken on any OAuth2 Send error and retry if error during SMTP Login
		If (..OAuth2ApplicationName'="") {
			Set ..SMTP.authenticator.AccessToken=""
			Set:$$$StatusEquals(tSC,$$$SMTPAUTHFailed) ..BusinessHost.Retry = 1
		}
	}
	Quit tSC
}

ClassMethod AddRecipients(pMailMessage As %Net.MailMessage, pRecipients As %String)
{
	// Parse comma and/or semicolon separated list of recipients and insert in message To: list
	Set tSC = $$$OK
	For i=1:1:$Length(pRecipients,",") {
		Set tRecipComma = $Piece(pRecipients,",",i)
		For j=1:1:$Length(tRecipComma,";") {
			Set tRecip = $ZStrip($Piece(tRecipComma,";",j),"<>WC")
			If ""'=tRecip {
				Set tSC = pMailMessage.To.Insert(tRecip)  Quit:$$$ISERR(tSC)
				$$$sysTRACE("Added recipient: "_tRecip)
			}
		}
		Quit:$$$ISERR(tSC)
	}
	If $$$ISERR(tSC) $$$LOGSTATUS(tSC)
	Quit tSC
}

ClassMethod AddCcRecipients(pMailMessage As %Net.MailMessage, pRecipients As %String)
{
	// Parse comma and/or semicolon separated list of recipients and insert in message Cc: list
	Set tSC = $$$OK
	For i=1:1:$Length(pRecipients,",") {
		Set tRecipComma = $Piece(pRecipients,",",i)
		For j=1:1:$Length(tRecipComma,";") {
			Set tRecip = $ZStrip($Piece(tRecipComma,";",j),"<>WC")
			If ""'=tRecip {
				Set tSC = pMailMessage.Cc.Insert(tRecip)  Quit:$$$ISERR(tSC)
				$$$sysTRACE("Added Cc recipient: "_tRecip)
			}
		}
		Quit:$$$ISERR(tSC)
	}
	If $$$ISERR(tSC) $$$LOGSTATUS(tSC)
	Quit tSC
}

ClassMethod AddBccRecipients(pMailMessage As %Net.MailMessage, pRecipients As %String)
{
	// Parse comma and/or semicolon separated list of recipients and insert in message Bcc: list
	Set tSC = $$$OK
	For i=1:1:$Length(pRecipients,",") {
		Set tRecipComma = $Piece(pRecipients,",",i)
		For j=1:1:$Length(tRecipComma,";") {
			Set tRecip = $ZStrip($Piece(tRecipComma,";",j),"<>WC")
			If ""'=tRecip {
				Set tSC = pMailMessage.Bcc.Insert(tRecip)  Quit:$$$ISERR(tSC)
				$$$sysTRACE("Added Bcc recipient: "_tRecip)
			}
		}
		Quit:$$$ISERR(tSC)
	}
	If $$$ISERR(tSC) $$$LOGSTATUS(tSC)
	Quit tSC
}

}
