/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// For internal use only
Class %Library.IJCDevice [ Abstract, System = 4 ]
{

ClassMethod iopen(type As %String = "Server", drain As %Boolean = 0) As %Status [ Internal, Private ]
{
	; Internal helper method, use Open()
	; 
	s IO=$I
	s $ZT="ERROR"
	// drain tells $$IjcOpen whether to read and discard any pending
	// data in the 'input channel'
	s status=$$IjcOpen^%Wprima(type,drain) ;Generates <NOTOPEN> error if in use
	use IO
	if +status quit $$$OK
	; error messages are of the form "0-<text>"
	s status=$P(status,"-",2,$L(status))
	do IjcClose^%Wprima(type)  ; try to close the device if there's an error
	use IO
	q $$$ERROR($$$UnexpectedError,"IjcOpen: status="_status)
	
ERROR ;IcjOpen can throw errors
	s $ZT=""
	do IjcClose^%Wprima(type)
	use IO
	if $ZE["<NOTOPEN>" quit $$$ERROR($$$CommDevInUse)
	q $$$ERROR($$$ObjectScriptError,$ZE)
}

ClassMethod iclose(type As %String, done As %Boolean = 0) As %Status [ Internal, Private ]
{
	; Internal helper method, use Close()
	; 
	; When you close a Server connection and done is 1, IjcClose sends
	; a message to tell the %Wcomm job that we've gone away. 1 is the
	; default if the parameter is not passed or is "". Here the default
	; for done (to Close) is 0 because we open and close the device
	; between each read/write/etc... call.
	s $ZT="ERROR"
	s rc=$$IjcClose^%Wprima(type,done)
	if +rc quit $$$OK
	; error messages are of the form "0-<text>"
	s rc=$P(rc,"-",2,$L(rc))
	q $$$ERROR($$$UnexpectedError,"IjcClose: rc="_rc)
ERROR 
	s $ZT=""
	q $$$ERROR($$$ObjectScriptError,$ZE)
}

ClassMethod Init(type As %String = "Server") As %Status
{
	/// Call this to Initialize a connection before the other side
	/// (eg. the jobbed job if this is a server) is started. This
	/// method tests to make sure the device is available and it
	/// removes any pending data from the device's I/O buffer which
	/// might be left over from a previous use.
	s IO=$I
	s rc=..iopen(type,1)  ;1 = drain any pending output 
	if '$$$ISERR(rc) do ..iclose(type)
	u IO
	q rc
}

ClassMethod Close(type As %String = "Server") As %Status
{
	/// Call this when you are finished with a connection either
	/// because the job has completed or because the status window
	/// is closing. Sends a message to the %Wcomm process that we're
	/// exiting & won't be reading any more data.
	s IO=$I,open=0
	s $ZT="ERROR"
	s rc=..iopen(type)
	if $$$ISERR(rc) u IO quit rc
	s open=1
	s rc=..iclose(type,1)  ;1 = notify %Wcomm we're shutting down
	u IO
	q rc
ERROR 
	s $ZT=""
	do:open ..iclose(type)
	use IO
	q $$$ERROR($$$ObjectScriptError,$ZE)
}

ClassMethod Read(type As %String = "Server", ByRef code As %String, ByRef msg As %String) As %Status
{
	/// Read a msg from the IJC device and take it apart.
	/// If there is no input then code and msg are null.
	/// If there is input then code is the 2 character message type
	/// and msg is the text. msg can be a scalar or an array.
	/// For codes, IB and MB, msg(1..3) are the 3 pieces of the text
	/// used to form the prompt. For DI, msg(1) and msg(2) have data.
	/// For all other message codes, msg is a scalar with the single 
	/// line of text.
	/// 
	/// msg is killed by this routine to reset it between reads.
	///  
	s IO=$I,open=0
	s $ZT="ERROR"
	k msg
	s code="",msg=""
	s rc=..iopen(type)
	if $$$ISERR(rc) u IO quit rc
	s open=1
	s text=""
	s rc=$$IjcRead^%Wprima(.text,type)
	do ..iclose(type)
	s open=0
	u IO
	if +rc=1 quit $$$OK  ;nothing read
	if +rc=2 {
		s code=$E(text,1,2)
		s msg=$E(text,3,$L(text)) 
		if (code="IB") || (code="MB") {
			s delim=$$del2^%Wprim
			f i=1:1:3 s msg(i)=$P(msg,delim,i)
			s msg=""
		} elseif (code = "DI") {
			s delim=$$del2^%Wprim
			f i=1:1:2 s msg(i)=$P(msg,delim,i)
			s msg=""
		}
		q $$$OK ; read msg
	}
	; anything else is an error
	s rc=$P(rc,"-",2,$L(rc))
	q $$$ERROR($$$UnexpectedError,"IjcRead: rc="_rc)

ERROR 
	s $ZT=""
	do:open ..iclose(type)
	use IO
	q $$$ERROR($$$ObjectScriptError,$ZE)
}

ClassMethod WriteMBResponse(type As %String = "Server", msg As %String) As %Status
{
	/// Send a response after receiving a MB (Message Box) message
	s IO=$I,open=0
	s $ZT="ERROR"
	s rc=..iopen(type)
	if $$$ISERR(rc) u IO quit rc
	s open=1
	s text=""
	s rc=$$IjcMBR^%Wprima(msg)
	do ..iclose(type)
	s open=0
	u IO
	if +rc=1 quit $$$OK
	s rc=$P(rc,"-",2,$L(rc))
	quit $$$ERROR($$$UnexpectedError,"IjcMBR: rc="_rc)

ERROR 
	s $ZT=""
	do:open ..iclose(type)
	use IO
	q $$$ERROR($$$ObjectScriptError,$ZE)
}

ClassMethod WriteIBResponse(type As %String = "Server", msg As %String) As %Status
{
	/// Send a response after receiving a IB (Input Box) message
	s IO=$I,open=0
	s $ZT="ERROR"
	s rc=..iopen(type)
	if $$$ISERR(rc) u IO quit rc
	s open=1
	s text=""
	s rc=$$IjcIBR^%Wprima(msg)
	do ..iclose(type)
	s open=0
	u IO
	if +rc=1 quit $$$OK
	s rc=$P(rc,"-",2,$L(rc))
	quit $$$ERROR($$$UnexpectedError,"IjcIBR: rc="_rc)

ERROR 
	s $ZT=""
	do:open ..iclose(type)
	use IO
	q $$$ERROR($$$ObjectScriptError,$ZE)
}

ClassMethod CancelJob(type As %String = "Server") As %Status
{
	/// Sends a cancel message to the jobbed job
	s IO=$I,open=0
	s $ZT="ERROR"
	s rc=..iopen(type)
	if $$$ISERR(rc) u IO quit rc
	s open=1
	s rc=$$IjcCan^%Wprima()
	do ..iclose(type)
	s open=0
	U IO
	if +rc=1 quit $$$OK
	; anything else is an error
	s rc=$P(rc,"-",2,$L(rc))
	quit $$$ERROR($$$UnexpectedError,"IjcCan: rc="_rc)
ERROR 
	s $ZT=""
	do:open ..iclose(type)
	use IO
	q $$$ERROR($$$ObjectScriptError,$ZE)
}

}
