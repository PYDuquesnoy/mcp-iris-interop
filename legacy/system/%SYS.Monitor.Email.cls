/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syMonitor, %syPidtab, %sySystem)

/// Provides a simple way for the System Monitor to send alerts via email. May be used by user extensions
/// for Sensors, Subscribers or Notifiers to send configured email alerts by calling %New() and SendEmail().
/// Note that %New() can fail if the Server or Recipients are not correctly configured, so the caller
/// should check for this and report the error in %objlasterror.
Class %SYS.Monitor.Email Extends %RegisteredObject [ LegacyInstanceContext, ProcedureBlock, System = 3 ]
{

/// Mailer
Property Mailer As %Net.SMTP;

/// Mail message
Property Msg As %Net.MailMessage;

/// Initialize the email object using configured Server, Recipients, SSL Config, etc. May fail if missing configuration info, see %Status.
Method Initialize() As %Status
{
	s $zt="RunErr"

	// Set the email properties
	s recipients = ##class(%Monitor.Manager).AppRecipients()
	k port,ssl,usetls
	s server = ##class(%Monitor.Manager).AppSmtpServer(,.port,.ssl,.usetls)
	i (recipients = "") || (server = "") s $ze = "Email Server or Recipients not configured" goto RunErr
	s ..Mailer = ##class(%Net.SMTP).%New()
	s ..Mailer.smtpserver = server s:$g(port)'="" ..Mailer.port=port
	s ..Mailer.SSLConfiguration=$g(ssl),..Mailer.UseSTARTTLS=+$g(usetls)

	// Do smtp authorization if configured
	if ##class(%Monitor.Manager).AppSmtpUserName()'="" {
	set auth=##class(%Net.Authenticator).%New() ; use default authentication list
	set auth.UserName=##class(%Monitor.Manager).AppSmtpUserName()
	set pwd = ##class(%Monitor.Manager).AppSmtpPassword()
	if pwd'="" s pwd=$system.Encryption.Base64Decode(pwd)
	set auth.Password=pwd
	set ..Mailer.authenticator=auth
	}

	// Create a Message object and fill in From, To, Subject
	s charset="UTF-8"
	s ..Msg = ##class(%Net.MailMessage).%New(charset)
	s ..Msg.From=##class(%Monitor.Manager).AppEmailSender()

	f i=1:1:$ll(recipients) do ..Msg.To.Insert($list(recipients,i))

	Q $$$OK
RunErr
	s $zt=""
	Q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Sends message via configured email.
Method SendEmail(msg As %String) As %Status
{
	s $zt="RunErr"

	i '##class(%Monitor.Manager).AppEnableEmail() s $ze = "Email not enabled" goto RunErr
	s ..Msg.Subject = "IRIS Application Monitor Alert"
	s dt=$zdt($h,2)
	d ..Msg.TextData.Clear()
	// Add message content
	d ..Msg.TextData.WriteLine(msg)
	// Send the message and close objects
	d ..Mailer.Send(..Msg)
	Q $$$OK
RunErr
	s $zt=""
	Q $$$ERROR($$$ObjectScriptError,$ze)
}

/// Calls Initialize() to fetch email configuration (Server, Recipients, SSL Config). If %New() fails and
/// returns a null OREF, then the error will be in %objlasterror.
Method %OnNew(initval As %RawString = "") As %Status [ Private ]
{
	s status = ..Initialize()
 	Q status
}

}
