/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.Portal.SourceControl.IO Extends %RegisteredObject [ System = 4 ]
{

/// Capture mode indicating how the data should be stored.
Property Mode As %Integer(DISPLAYLIST = ",stream,array", VALUELIST = ",1,2");

/// Flag indicating whether newline translation should be used.
Property NewLineTranslation As %String(VALUELIST = ",,JS,HTML");

/// Flag to indicate whether a capture is underway.
Property InCapture As %Boolean [ InitialExpression = 0 ];

/// The name of the device from which data is being captured.
/// Note that this device will be used, and thus become the current device,
/// when redirection is started.
Property Device As %String;

/// Location for data storage
Property Data [ MultiDimensional, Private ];

/// Ensure that <property>Data</property> is correctly initialized
/// whenever <property>Mode</property> is changed.
Method ModeSet(pMode) As %Status
{
	Quit ..InitData(pMode, 0)
}

Method InitData(pMode As %Integer = 1, pForce As %Boolean = 0, pStream As %Stream.Object = "") As %Status [ Private ]
{
	Set tValid = ..ModeIsValid(pMode)
	If $$$ISERR(tValid) Quit tValid
	If (pMode '= ..Mode) || pForce {
		Kill ..Data
		Set ..Data = $case(pMode, 
							1: $select($IsObject(pStream): pStream, 1: ##class(%Stream.TmpBinary).%New()),
							: 0)
		Set i%Mode = pMode
	}
	Quit $$$OK
}

/// Initialize the class based on a capture mode specified by <var>pMode</var> and
/// a currently open device specified by <var>pDevice</var>. Note that the default mode
/// is 1 (i.e. "stream") and the default device is the current device (i.e. $IO)
Method %OnNew(pMode As %Integer = 1, pStream As %Stream.Object = "", pDevice As %String = {$IO}, pNewLineTranslation As %String = "") As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Set ..Device = pDevice
	Set ..NewLineTranslation = pNewLineTranslation
	Quit ..InitData(pMode, 1, pStream)
}

/// Initialize redirection and return the current <class>%CSP.Portal.SourceControl.IO</class>
/// instance in <var>pInstance</var>. <var>pMode</var> can take one of
/// two values, either "stream" or "array". <var>pDevice</var> defines the device which
/// should be used as the source for the data - note that the device must already be
/// open for the redirection to work.
ClassMethod Redirect(Output pInstance As %CSP.Portal.SourceControl.IO, pMode As %String = "stream", pStream As %Stream.Object = "", pDevice As %String = {$IO}, pNewLineTranslation As %String = "") As %Status
{
	Kill pInstance
	Set tMode = ..ModeDisplayToLogical(pMode)
	Set pInstance = ..%New(tMode, pStream, pDevice, pNewLineTranslation)
	Quit pInstance.StartRedirect()
}

/// Start the redirection using the current settings.
Method StartRedirect() As %Status [ ProcedureBlock = 0 ]
{
	New ex, tStatus
	Set tStatus = $$$OK
	Try {
		Use ..Device::("^"_$ZNAME)
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	If $$$ISERR(tStatus) Quit tStatus
	
	Set %ISCIO = $this
	Set ..InCapture = 1
	Do ##class(%Library.Device).ReDirectIO(1)
	Quit $$$OK
	; Public entry points for redirection
wstr(s) Do %ISCIO.WriteData(s) Quit
wchr(a) Do %ISCIO.WriteData($c(a)) Quit
wnl Do %ISCIO.WriteData($c(13,10)) Quit
wff Do %ISCIO.WriteData($c(13,10,13,10)) Quit
wtab(n) Quit
rstr(len,time) Quit ""
rchr(time) Quit ""
}

/// Stop the IO redirection, correct the state of <property>InCapture</property>
/// and clean up the %ISCIO variable
Method StopRedirect() As %Status
{
	Kill %ISCIO
	If ..InCapture && ##class(%Library.Device).ReDirectIO(0) Use ..Device
	Set ..InCapture = 0
	If ..Mode = 1 {
		Do ..Data.Rewind()
	}
	Quit $$$OK
}

/// Capture the data based on the current value of <property>Mode</property>.
Method WriteData(data As %String) As %Status
{
	If ..InCapture {
        If ..NewLineTranslation '= "" {
            #; Normalize newline characters
            Set data = $replace(data,$char(13,10),$char(10)), newData = ""
            For i=1:1:$length(data,$char(10)) {
                #; Escape non-newline characters
                Set newData = newData_$zconvert($piece(data,$char(10),i),"O",..NewLineTranslation)
                #; Translate the newline characters
                If i < $length(data,$char(10)) Set newData = newData_$CASE(..NewLineTranslation,"HTML":"<br/>",:"\n")
            }
            Set data = newData
        }
		If ..Mode = 1 {
			Quit ..Data.Write(data)
		}
		If ..Mode = 2 {
			If ..Data = 0 {
				Set ..Data = ..Data + 1
				Set ..Data(..Data) = data
			}
			Else {
				If ($length(..Data(..Data)) + $length(data)) <= $$$MaxLocalLength {
					Set ..Data(..Data) = ..Data(..Data) _ data
				}
				Else {
					Set ..Data = ..Data + 1
					Set ..Data(..Data) = data
				}
			}
			Quit $$$OK
		}
	}
	Quit $$$OK
}

Method ClearData(pReplacementStream As %Stream.Object = "") As %Status
{
	Quit ..InitData(..Mode, 1, pReplacementStream)
}

/// Get the data captured during the redirection.
/// <var>pData</var> will be a stream object if stream mode was specified,
Method GetData(Output pData) As %Status
{
	Kill pData
	If ..Mode = 1 {
		Set pData = ..Data
	}
	ElseIf ..Mode = 2 {
		Merge pData = ..Data
	}
	Quit $$$OK
}

/// Ensure that redirection is stopped when the object goes out of scope.
Method %OnClose() As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	If ..InCapture {
		Quit ..StopRedirect()
	}
	Quit $$$OK
}

}
