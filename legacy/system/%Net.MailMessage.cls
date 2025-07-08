/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on using this class</b>, see
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=CLASSES+%25Net.MailMessage">Sending and Receiving Email</a>.</p>
/// Send an SMTP mail message or receive a MIME message using POP3.
Class %Net.MailMessage Extends %Net.MailMessagePart [ Not ProcedureBlock, System = 3 ]
{

/// Cc for message, list of names to which message will be sent (SMTP) or was sent (POP3) 
Property Cc As list Of %String(MAXLEN = 8000);

/// Bcc for message, list of names to which message will be sent (SMTP) or was sent (POP3) 
Property Bcc As list Of %String(MAXLEN = 8000);

/// Who the message is from 
Property From As %String(MAXLEN = 1000);

/// Subject of message 
Property Subject As %String(MAXLEN = 1000);

/// To for message, list of names to which message will be sent (SMTP) or was sent (POP3) 
Property To As list Of %String(MAXLEN = 8000);

/// The date/time that the message was retrieved as reported by POP3,
/// or date/time to be included in the message sent via %Net.SMTP.
/// If Date is not specified, then %Net.SMTP will set it to the current date and time.
Property Date As %String;

/// Who actually sent the message 
Property Sender As %String(MAXLEN = 1000);

/// The Reply-To header field of the message 
Property ReplyTo As %String(MAXLEN = 1000);

/// The total length of the message.
/// The MessageSize property is not set for attached emails.
Property MessageSize As %Integer;

/// Return the date/time that the message was retrieved converted to 
/// UTC in $H format.  An empty string is returned if the date format
/// is invalid.
Method GetUTCDateTime() As %String
{
	New seconds
	Set seconds=..GetUTCSeconds()
	If seconds="" Quit ""
	Quit ..SecondsToH(seconds)
}

/// Return the date/time that the message was retrieved converted to 
/// local time in $H format.  An empty string is returned if the date format
/// is invalid.
Method GetLocalDateTime() As %String
{
	New seconds,h,z,adjust
	Set seconds=..GetUTCSeconds()
	If seconds="" Quit ""
	Set h=..HToSeconds($h)
	Set z=..HToSeconds($ztimestamp)
	If h>z {
		Set adjust=(h-z)+59\60*60
	} Else {
		Set adjust=-((z-h)+59\60*60)
	}
	Quit ..SecondsToH(seconds + adjust)
}

/// Return the date/time that the message was retrieved converted to 
/// UTC in seconds since 12/31/1840.  
/// An empty string is returned if the date format is invalid.
Method GetUTCSeconds() As %Integer
{
	New dt,tz,jj,seconds,adjust,c,begin,end
	Set dt=$zstrip($tr(..Date,$c(9,13,10),"   "),"<>W")
	For  set jj=$find(dt,"  ") Quit:'jj  Set $extract(dt,jj-1)=""
	Set tz=$zcvt($piece(dt," ",$length(dt," ")),"U")
	Set dt=$zstrip($piece(dt,",",$length(dt,",")),"<>W")
	Set dt=$piece(dt," ",1,$length(dt," ")-1)
	Set begin=$zdateh("1950-01-01",3)
	Set end=$zdateh("2049-12-31",3)
	Set seconds=..HToSeconds($zdatetimeh(dt,2,1,,3,begin,end,,,""))
	If seconds="" Quit ""
	If tz="" Quit ""
	If tz="UT" Quit seconds
	If tz="GMT" Quit seconds
		If $length(tz)=5 {
		If ($extract(tz,1)="+")||($extract(tz,1)="-") {
			Set adjust=$extract(tz,2,3)*60 + $extract(tz,4,5)
			If $extract(tz,1)="-" Set adjust=-adjust
		} Else {
			Quit ""
		}
	} ElseIf $length(tz)=3 {
		If $extract(tz,3)'="T" Quit ""
		Set c=$extract(tz,2)
		If c="S" {
			Set adjust=0
		} ElseIf c="D" {
			Set adjust=60
		} Else {
			Quit ""
		}
		Set c=$extract(tz,1)
		If c="E" {
			Set adjust=adjust-300
		} ElseIf c="C" {
			Set adjust=adjust-360
		} ElseIf c="M" {
			Set adjust=adjust-420
		} ElseIf c="P" {
			Set adjust=adjust-480
		} Else {
			Quit ""
		}
	} ElseIf $length(tz)=1 {
		If tz="J" Quit ""
		If tz="Z" Quit seconds
		If $ascii(tz)<78 {
			Set adjust=-60*($ascii(tz)-64)
			If $ascii(tz)>74 Set adjust=adjust+60
		} Else {
			Set adjust=60*($ascii(tz)-77)
		}
	} Else {
		Quit ""
	}
	Quit seconds-(60*adjust)
}

/// Convert the specified number of seconds since 12/31/1840 to $h format.
ClassMethod SecondsToH(seconds As %Integer) As %String [ CodeMode = expression ]
{
(seconds\86400)_","_(seconds#86400)
}

/// Convert $h format to the number of seconds since 12/31/1840.
ClassMethod HToSeconds(h As %String) As %Integer [ CodeMode = expression ]
{
$select(h="":"",1:($piece(h,",",1)*86400)+($piece(h,",",2)\1))
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
<Value>Bcc</Value>
</Value>
<Value name="14">
<Value>Cc</Value>
</Value>
<Value name="15">
<Value>Date</Value>
</Value>
<Value name="16">
<Value>From</Value>
</Value>
<Value name="17">
<Value>MessageSize</Value>
</Value>
<Value name="18">
<Value>ReplyTo</Value>
</Value>
<Value name="19">
<Value>Sender</Value>
</Value>
<Value name="20">
<Value>Subject</Value>
</Value>
<Value name="21">
<Value>To</Value>
</Value>
<Value name="22">
<Value>ContentTransferEncoding</Value>
</Value>
<Value name="23">
<Value>Debug</Value>
</Value>
<Value name="24">
<Value>MultiPartType</Value>
</Value>
<Value name="25">
<Value>PartIndex</Value>
</Value>
<Value name="26">
<Value>InlineAttachment</Value>
</Value>
</Data>
<Type>%Storage.Serial</Type>
}

}
