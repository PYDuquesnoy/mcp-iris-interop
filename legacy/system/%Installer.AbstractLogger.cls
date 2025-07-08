/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Logging interface for the %Installer
Class %Installer.AbstractLogger Extends %RegisteredObject [ ServerOnly = 1, System = 3 ]
{

/// Flag to determine if WRITE's should be captured
Property CaptureIO As %Boolean [ InitialExpression = 0, Internal, Private ];

/// Counter of begin/end logging calls (to allow for nested installers)
Property LogDepth As %Integer [ InitialExpression = 0, Internal, Private ];

/// Prior redirect state $lb(redirec,mnemonic routine)
Property CurrentState As %String(MAXLEN = "") [ Internal, Private ];

/// Current line of output
Property CurrentLine As %String(MAXLEN = 32000) [ Internal, Private ];

/// Called to indicate that logging is going to start
Method BeginLogging() As %Status
{
	#dim tSC As %Status = $$$OK
	If (..LogDepth=0)&&(..CaptureIO) {
		Set tSC = ..enableIOCapture()
	}
	Set ..LogDepth = ..LogDepth + 1
	
	Quit tSC
}

/// Called to indicate when a manifest is done logging.
Method EndLogging() As %Status
{
	#dim tSC As %Status = $$$OK
	Set ..LogDepth = ..LogDepth - 1
	
	If (..LogDepth=0)&&(..CaptureIO) {
		Set tSC = ..disableIOCapture()
	}
	
	Quit tSC
}

/// Log a message to the install log
Method LogEntry(pLevel As %Integer, pTopic As %String, ByRef pArgs)
{
	// This default implementation writes the log message to $IO
	
	#dim i,tPfx As %String
	#dim tRedirect As %Boolean
	
	Set tPfx = $ZDT($H,3)_" "_pLevel_" "_pTopic_": "
	
	If ..CurrentState'="" {
		Set tRedirect=$ZU(82,12)
		Do:tRedirect $ZU(82,12,0)
	}
	
	For i=1:1:pArgs {
		Set:i=2 tPfx=$J("",$L(tPfx))		
		Write tPfx_pArgs(i),!
	}
	
	If ..CurrentState'=""{
		Do:tRedirect $ZU(82,12,1)
	}
	
	Quit
}

/// Initialize this logger
Method %OnNew(pCaptureIO As %Boolean = 0) As %Status [ Internal, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Set ..CaptureIO = pCaptureIO
	
	Quit $$$OK
}

/// Cleanup when this logger instance is closed.
Method %OnClose() As %Status [ Internal, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Quit $SELECT(..CaptureIO:..disableIOCapture(),1:$$$OK)
}

/// Enable I/O capture
Method enableIOCapture() As %Status [ Internal, Private, ProcedureBlock = 0 ]
{
	Set %InstallerLogText = ""
	Set %InstallerLogger  = $THIS
	Set ..CurrentState=$lb(zutil(82,12),$s($System.Device.GetMnemonicRoutine()="%X364":"",1:"^"_$System.Device.GetMnemonicRoutine()))
	
	Use 0::("^"_$ZNAME)
	
	Do $ZU(82,12,1)
	Quit $$$OK

	#dim s
	
wchr(s)	;
	Set %InstallerLogText = %InstallerLogText _ $CHAR(s)
	Do:%InstallerLogText[$C(13,10) %InstallerLogger.flushIO()
	Quit
wff()	;
	Set %InstallerLogText = %InstallerLogText _ $CHAR(12)
	Quit
wnl()	;
	Do %InstallerLogger.flushIO()
	Quit
	
wstr(s)	;
	New tLine
	Set %InstallerLogText = %InstallerLogText _ s
	Do:%InstallerLogText[$C(13,10) %InstallerLogger.flushIO(-1)
	Quit
wtab(s)	;
	Set:s>$L(%InstallerLogText) %InstallerLogText = %InstallerLogText _ $J("",s-$L(%InstallerLogText))
	Quit
}

/// Disable I/O capture
Method disableIOCapture() As %Status [ Internal, Private, ProcedureBlock = 0 ]
{
	Do ..flushIO()
	Do $ZU(82,12,$lg(..CurrentState))
	Use 0::($lg(..CurrentState,2))
	
	Kill %InstallerLogText,%InstallerLogger
	
	Quit $$$OK
}

/// Flush captured I/O to the log
Method flushIO(pLimit As %Integer = 0) [ Internal, ProcedureBlock = 0 ]
{
	If $GET(%InstallerLogText)'="" {
		#dim tArgs
		New tArgs,tLine,tLines
		Set tLines = $L(%InstallerLogText,$C(13,10))
		For tLine = 1:1:(tLines+pLimit) {
			Set tArgs($I(tArgs)) = $P(%InstallerLogText,$C(13,10),tLine)
		}
		Do ..LogEntry(1,"CONSOLE",.tArgs)
		Set %InstallerLogText = $P(%InstallerLogText,$C(13,10),tLine+1,tLines)
	}
}

}
