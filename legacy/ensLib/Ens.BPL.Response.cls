/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Represents a request message to be sent to an business class.
Class Ens.BPL.Response Extends Ens.BPL.Message [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<response type="Demo.FloodMonitor.WaterLevelResponse"/>
}

/// This holds the name of the designated response handler
Property ResponseHandlerName As %String;

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	do {

		#; If there are no activities, don't bother to generate a response handler
		If ..Activities.Count()=0 Quit
		
		#; Generate an inline response handler method which will be called 
		#; when the this response is received
		Set ..ResponseHandlerName=pCompiler.MethodCounter.Next()
		
		#; Response handlers are expressed on the 'Context' class, no compiler thread is
		#; available
		Set tSC=pCompiler.StartMethod(..ResponseHandlerName,$$$NULLOREF,0,pCompiler.Context)
		If $$$ISERR(tSC) Quit
		
		#; Get the process node
		Set tParseNode=$this
		While tParseNode.%ClassName()'="Process" {
			Set tParseNode=tParseNode.Parent
		}
		
		$$$ASSERT($IsObject(tParseNode))
		
		Set tRequestType=tParseNode.Request,tResponseType=tParseNode.Response
		Set tCallRequestType=..Parent.Request.Type,tCallResponseType=..Type
		
		Set pCompiler.CurrentMethod.Description="Response Handler for call to "_..Parent.Target_" for pCompiler.CurrentMethod "_pCompiler.CurrentMethod.parent.Name
		Set pCompiler.CurrentMethod.FormalSpec="process:Ens.BusinessProcess,context:Ens.BP.Context,request:"_tRequestType_",response:"_tResponseType_",callrequest:"_tCallRequestType_",callresponse:"_tCallResponseType_",callname:%String"
		
		Set tSC=..Activities.GenerateCode(pCompiler)
		If $$$ISERR(tSC) Quit
		
		Do pCompiler.EndResponseMethod()
					
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
		Do pStream.Write("<response type="_$$$EA(..Type))
		
		If ..Activities.Count() {
			Do pStream.WriteLine(">")
			
			Set tSC=..Activities.GenerateXML(pStream)
			If $$$ISERR(tSC) Quit
			
			Do pStream.WriteLine("</response>")
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
	Quit "Call->Response"
}

}
