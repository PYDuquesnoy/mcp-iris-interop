/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Represents a delay for a specified duration or until a specific instant
/// The duration is specifed in seconds and the until instant is specified
/// as an xsd:dateTime. The timezone portion of xsd:dateTime is NOT honored
Class Ens.BPL.Delay Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<sequence>
<delay until='"2005-10-19T10:10"'/>
<delay duration='"PT60S"'/>
</sequence>
}

/// This holds the instant to delay until
Property Until As %String;

/// This holds the duration to delay for
Property Duration As %String;

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	do {
		If ..Disabled Quit
		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)
		
		$$$EnterActivity($$$ActivityDelay,$$$SubActivityMain)
		
		If tLanguage=$$$objectscript {
			$$$GC(" Set %name="""",%alarmhandle=""""")
			$$$GC(" Set status=..%Process.MakeTimerCall(""_Delay"",.%name,"_$Select(..Duration'="":..Duration,1:..Until)_","""",.%alarmhandle,"""_..Name_""",0)")
			$$$GC(" If $$$ISERR(status) Quit")
		} else {
			$$$GC("   %name="""" : %alarmhandle=""""")
			$$$GC("   status=Me.%Process.MakeTimerCall(""_Delay"",%name,"_$Select(..Duration'="":..Duration,1:..Until)_","""",%alarmhandle,"""_..Name_""",0)")
			$$$GC("   If System.Status.IsError(status) Then Exit Do")
		}
		
		#; Synthesize a Sync
		Set tSync=##class(Ens.BPL.Sync).%New()
		$$$ASSERT($IsObject(tSync))
	
		#; Copy the name from the Delay tag
		Set tSync.Name=..Name,tSync.Calls="@%name"
		
		#; Generate the code
		Set tSC=tSync.GenerateCode(pCompiler)
		If $$$ISERR(tSC) Quit	
		
		$$$LeaveActivity($$$ActivityDelay,$$$SubActivityMain)
		
	} while (0)
Exit
	Do pCompiler.ContextStack.Pop()
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method GenerateXML(pStream As %BinaryStream) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		Do pStream.Write("<delay ")
		
		If ..Name'="" Do pStream.Write("name="_$$$EA(..Name))
		
		If ..Until'="" Do pStream.Write("until="_$$$EA(..Until))
		If ..Duration'="" Do pStream.Write("duration="_$$$EA(..Duration))
				
		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		
		If ..Annotation'="" {
			Do pStream.WriteLine(">")
			Do ..GenerateAnnotation(pStream)
			Do pStream.WriteLine("</delay>")
		} else {
			Do pStream.WriteLine("/>")
		}
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Perform a sanity check on the nodes in the parse tree
Method Validate(ByRef pStatus As %Status, pContext As Ens.BPL.ValidationContext) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Must have Duration or Until
		If (..Duration="")&&(..Until="") {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"'duration' and 'until'",..DisplayName()))
		}
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Provide a user readable string which names the activity
Method activityName() As %String [ Private ]
{
	Quit "Delay"
}

}
