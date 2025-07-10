/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents a call to another business class, i.e. another
/// business process or a business operation. The 'class' attribute and the &lt;request> tag
/// are required. 
Class Ens.BPL.Call Extends Ens.BPL.Activity [ ClassType = "", ProcedureBlock, System = 3 ]
{

XData Example
{
<call name="CallBusinessOperation1" target="Demo.FloodMonitor.BusinessOperation" async="1">
<request type="Demo.FloodMonitor.WaterLevelRequest"/>
<response type="Demo.FloodMonitor.WaterLevelResponse"/>
</call>
}

/// This holds the name of the configured item (usually a class)
/// which will be called and receive the request
Property Target As %String;

/// This determines if the request should be made asynchronously
Property Async As %Boolean [ InitialExpression = 1 ];

/// This holds data transformation details for the request
Property Request As Ens.BPL.Request;

/// This holds data transformation details for the response
Property Response As Ens.BPL.Response;

/// This holds the timeout for synchronous requests
Property Timeout As %String;

Method GenerateCode(pCompiler As Ens.BPL.Compiler) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do pCompiler.ContextStack.Push(..%ClassName())
	do {
		
		/// Default to emmiting object when in Python mode
		Set tLanguage=$$$sysLangFromBPL(pCompiler.Language)
		If ..Disabled Quit
	
		If tLanguage=$$$objectscript {	
			$$$GC(" #; --- Begin Call "_..Name_" ---")
		} else {
			$$$GC("   ' --- Begin Call "_..Name_" ---")
		}
		
		#; Generate the response code first
		If $IsObject(..Response) {
			Set tSC=..Response.GenerateCode(pCompiler)
			If $$$ISERR(tSC) Quit
		}
		
		#; Then the request code
		Set tSC=..Request.GenerateCode(pCompiler) If $$$ISERR(tSC) Quit
		
		If tLanguage=$$$objectscript {	
			$$$GC(" #; --- End Call "_..Name_" ---")
		} else {
			$$$GC("   ' --- End Call "_..Name_" ---")
		}
		
		#; Auto-generate a Sync if the request is not asynchronous
		If ..Async = 0
		{
			#; Create a new instance of a sync
			Set tSync = ##class(Ens.BPL.Sync).%New()
			If '$IsObject(tSync) Set tSC=%objlasterror Quit
			
			#; Sync on just the name of the call, with user specified timeou
			Set tSync.Calls=..Name,tSync.Timeout=..Timeout
			
			#; Generate the code
			Set tSC=tSync.GenerateCode(pCompiler)
			If $$$ISERR(tSC) Quit
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
		Do pStream.Write("<call ")
		
		Do pStream.Write("name="_$$$EA(..Name))
		Do pStream.Write("target="_$$$EA(..Target))
		Do pStream.Write("async="_$$$EA(..Async))
		
		If ..Timeout'="" Do pStream.Write("timeout="_$$$EA(..Timeout))
		If ..LanguageOverride'="" Do pStream.Write("languageOverride="""_##class(Ens.BPL.UI.Diagram).EscapeForSVG(..LanguageOverride)_""" ")

		Set tSC=##super(pStream)
		If $$$ISERR(tSC) Quit
		
		Do pStream.WriteLine(">")
		
		If ..Annotation'="" {
			Do ..GenerateAnnotation(pStream)
		}
		
		// Request is mandatory
		Set tSC=..Request.GenerateXML(pStream)
		If $$$ISERR(tSC) Quit
		
		If $IsObject(..Response) {
			Set tSC=..Response.GenerateXML(pStream)
			If $$$ISERR(tSC) Quit
		}
		
		Do pStream.WriteLine("</call>")

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
		#; Must have Target
		If ..Target="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"target",..DisplayName()))
		}
		
		#; Async initial expression is 1
		If ..Async="" {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeValidation,"async",..DisplayName()))
		}
		
		#; Async calls hsould have their timeout specified on the <sync> tag
		If (..Async=1||(..Async="true"))&&(..Timeout'="") {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLASyncTimeoutMustBeOnSync))
		}
		
		If $IsObject(..Request) {
			Set tSC=..Request.Validate(.pStatus,pContext)
			If $$$ISERR(tSC) Quit
		} else {
			Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$EnsErrBPLNodeMissing,"Request",..DisplayName()))
		}
		
		If $IsObject(..Response) {
			Set tSC=..Response.Validate(.pStatus,pContext)
			If $$$ISERR(tSC) Quit
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
	Quit "Call"
}

/// Determine whether this Call should be made asynchronously
Method AsyncGet() As %Boolean
{
	If (i%Async="true"||(i%Async=1)) Quit 1
	Quit 0
}

}
