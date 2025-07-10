/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Represents a request message to be sent to an business class.
Class Ens.BPL.Request Extends Ens.BPL.Message [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<request type="Demo.FloodMonitor.WaterLevelRequest"/>
}

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	do {
		/// Default to emitting object script when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)

		#; Don't try to instantiate the request class if it's abstract
		If $$$comClassKeyGet(..Type,$$$cCLASSabstract)=0 {
			
			If tLanguage=$$$objectscript {	
				$$$GC(" #; --- Begin Request ---")
				$$$GC(" Set callrequest=##class("_..Type_").%New()")
				$$$GC(" If '$IsObject(callrequest) Set status=%objlasterror Quit")
			} else {
				$$$GC("   ' --- Begin Request ---")
				$$$GC("   callrequest=new "_..Type)
				$$$GC("   If Not IsObject(callrequest) Then status=%objlasterror : Exit Do")
			}
		}
				
		Set tSC=..Activities.GenerateCode(pCompiler)
		If $$$ISERR(tSC) Quit
		
		#; Build request
		Set tName=..Parent.Name,tTarget=..Parent.Target,tAsync=..Parent.Async
		Set tTarget=$s($e(tTarget)="@":$e(tTarget,2,$l(tTarget)),1:""""_tTarget_"""")
		Set tName=$s($e(tName)="@":$e(tName,2,$l(tName)),1:$zu(144,1,tName))
	
		If $IsObject(..Parent.Response) {
			Set tResponseHandlerName=..Parent.Response.ResponseHandlerName,tResponseRequired=1
		} else {
			Set tResponseHandlerName="",tResponseRequired=0
		}
		
		If tLanguage=$$$objectscript {
			
			$$$GC(" Set status=..MakeAsyncCall("""_tResponseHandlerName_""","_tTarget_",callrequest,"_tName_","_tResponseRequired_",0,"_tName_","_('tAsync)_")")
			$$$GC(" If $$$ISERR(status) Quit")
			$$$GC(" Kill callrequest")	
			$$$GC(" #; --- End Request ---")
		} else {
			$$$GC("   status=Me.MakeAsyncCall("""_tResponseHandlerName_""","_tTarget_",callrequest,"_tName_","_tResponseRequired_",0,"_tName_","_('tAsync)_")")
			$$$GC("   If System.Status.IsError(status) Then Exit Do")
			$$$GC("   Set callrequest=""""")	
			$$$GC("   ' --- End Request ---")
		}
		
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
		
		Do pStream.Write("<request type="_$$$EA(..Type))
		
		If ..Activities.Count() {
			Do pStream.WriteLine(">")
			
			Set tSC=..Activities.GenerateXML(pStream)
			If $$$ISERR(tSC) Quit
			
			Do pStream.WriteLine("</request>")
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
		#; Must know the Type
		If ..Type="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"type",..DisplayName()))
		}
		
		#; Delegate to the activities
		Set tSC=..Activities.Validate(.pStatus,pContext)
		If $$$ISERR(tSC) Quit
				
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Provide a user readable string which names the activity
Method DisplayName() As %String
{
	Quit "Call->Request"
}

}
